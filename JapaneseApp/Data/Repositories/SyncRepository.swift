//
//  SyncRepository.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import CloudKit
import RealmSwift
import Combine

protocol SyncRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperation, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgress, Error>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}

class SyncRepository: SyncRepositoryProtocol {
    // MARK: - Properties
    
    private let cloudKitService: CloudKitService
    private let conflictResolver: SyncConflictResolver
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    
    // 同步相关的常量
    private let databaseTokenKey = "cloudkit_database_change_token"
    private let zoneTokensKey = "cloudkit_zone_change_tokens"
    private let syncMetadataId = "sync_metadata"
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitService, conflictResolver: SyncConflictResolver, realm: Realm? = nil) {
        self.cloudKitService = cloudKitService
        self.conflictResolver = conflictResolver
        
        // 如果没有提供Realm实例，则创建一个默认的
        if let realm = realm {
            self.realm = realm
        } else {
            do {
                self.realm = try Realm()
            } catch {
                fatalError("无法初始化Realm: \(error)")
            }
        }
    }
    
    // MARK: - SyncRepositoryProtocol Implementation
    
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error> {
        return Future<SyncStatus, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 检查iCloud账户状态
            self.cloudKitService.checkAccountStatus()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(self.cloudKitService.handleCloudKitError(error)))
                        }
                    },
                    receiveValue: { accountStatus in
                        switch accountStatus {
                        case .available:
                            // 账户可用，检查本地同步状态
                            let metadata = self.getSyncMetadata()
                            
                            // 检查是否有当前正在进行的同步操作
                            if let operationId = metadata.currentOperationId,
                               let operation = self.getSyncOperation(id: operationId),
                               operation.status == "in_progress" {
                                promise(.success(.pendingUpload)) // 有正在进行的同步
                            } else if metadata.pendingChangesCount > 0 {
                                promise(.success(.pendingUpload)) // 有待上传的更改
                            } else {
                                // 检查是否有未解决的冲突
                                let conflicts = self.realm.objects(SyncConflict.self).filter("resolved == false")
                                if conflicts.count > 0 {
                                    promise(.success(.conflict)) // 有未解决的冲突
                                } else {
                                    promise(.success(.synced)) // 已同步
                                }
                            }
                        case .noAccount:
                            promise(.failure(NSError(domain: "SyncRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录iCloud账户"])))
                        case .restricted:
                            promise(.failure(NSError(domain: "SyncRepository", code: 403, userInfo: [NSLocalizedDescriptionKey: "iCloud访问受限"])))
                        case .couldNotDetermine:
                            promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "无法确定iCloud账户状态"])))
                        @unknown default:
                            promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "未知的iCloud账户状态"])))
                        }
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func startSync(type: SyncType) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 检查是否有正在进行的同步操作
            let metadata = self.getSyncMetadata()
            if let operationId = metadata.currentOperationId,
               let operation = self.getSyncOperation(id: operationId),
               operation.status == "in_progress" {
                promise(.failure(NSError(domain: "SyncRepository", code: 409, userInfo: [NSLocalizedDescriptionKey: "已有同步操作正在进行"])))
                return
            }
            
            // 创建新的同步操作
            let operation = SyncOperation(type: type)
            operation.status = "in_progress"
            
            // 保存同步操作到Realm
            try? self.realm.write {
                self.realm.add(operation)
                metadata.currentOperationId = operation.id
                self.realm.add(metadata, update: .modified)
            }
            
            // 根据同步类型执行不同的同步操作
            switch type {
            case .full:
                self.performFullSync(operation: operation)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                try? self.realm.write {
                                    operation.status = "failed"
                                    operation.errorMessage = error.localizedDescription
                                    operation.endTime = Date()
                                    self.realm.add(operation, update: .modified)
                                    
                                    // 清除当前操作ID
                                    metadata.currentOperationId = nil
                                    self.realm.add(metadata, update: .modified)
                                }
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { _ in
                            try? self.realm.write {
                                operation.status = "completed"
                                operation.endTime = Date()
                                self.realm.add(operation, update: .modified)
                                
                                // 更新同步元数据
                                metadata.lastSyncTime = Date()
                                metadata.pendingChangesCount = 0
                                metadata.currentOperationId = nil
                                self.realm.add(metadata, update: .modified)
                            }
                            promise(.success(operation))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case .favorites:
                self.performFavoritesSync(operation: operation)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                try? self.realm.write {
                                    operation.status = "failed"
                                    operation.errorMessage = error.localizedDescription
                                    operation.endTime = Date()
                                    self.realm.add(operation, update: .modified)
                                    
                                    // 清除当前操作ID
                                    metadata.currentOperationId = nil
                                    self.realm.add(metadata, update: .modified)
                                }
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { _ in
                            try? self.realm.write {
                                operation.status = "completed"
                                operation.endTime = Date()
                                self.realm.add(operation, update: .modified)
                                
                                // 更新同步元数据
                                metadata.lastSyncTime = Date()
                                // 只清除收藏相关的待同步计数
                                metadata.pendingChangesCount = self.countPendingChanges(excludingFavorites: true)
                                metadata.currentOperationId = nil
                                self.realm.add(metadata, update: .modified)
                            }
                            promise(.success(operation))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case .settings:
                self.performSettingsSync(operation: operation)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                try? self.realm.write {
                                    operation.status = "failed"
                                    operation.errorMessage = error.localizedDescription
                                    operation.endTime = Date()
                                    self.realm.add(operation, update: .modified)
                                    
                                    // 清除当前操作ID
                                    metadata.currentOperationId = nil
                                    self.realm.add(metadata, update: .modified)
                                }
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { _ in
                            try? self.realm.write {
                                operation.status = "completed"
                                operation.endTime = Date()
                                self.realm.add(operation, update: .modified)
                                
                                // 更新同步元数据
                                metadata.lastSyncTime = Date()
                                // 只清除设置相关的待同步计数
                                metadata.pendingChangesCount = self.countPendingChanges(excludingSettings: true)
                                metadata.currentOperationId = nil
                                self.realm.add(metadata, update: .modified)
                            }
                            promise(.success(operation))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgress, Error> {
        return Future<SyncProgress, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 获取同步操作
            guard let operation = self.getSyncOperation(id: operationId) else {
                promise(.failure(NSError(domain: "SyncRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "同步操作不存在"])))
                return
            }
            
            // 创建同步进度对象
            let progress = SyncProgress(operation: operation)
            promise(.success(progress))
        }.eraseToAnyPublisher()
    }
    
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 获取冲突
            guard let conflict = self.realm.object(ofType: SyncConflict.self, forPrimaryKey: conflictId) else {
                promise(.failure(NSError(domain: "SyncRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "冲突不存在"])))
                return
            }
            
            // 使用冲突解决器解决冲突
            self.conflictResolver.resolveConflict(conflict: conflict, resolution: resolution)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { success in
                        // 标记冲突为已解决
                        try? self.realm.write {
                            conflict.resolved = true
                            conflict.resolution = resolution.rawValue
                            self.realm.add(conflict, update: .modified)
                        }
                        
                        promise(.success(success))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 更新同步元数据
            let metadata = self.getSyncMetadata()
            
            try? self.realm.write {
                metadata.autoSyncEnabled = enabled
                self.realm.add(metadata, update: .modified)
            }
            
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func getSyncMetadata() -> SyncMetadata {
        // 获取或创建同步元数据
        if let metadata = realm.object(ofType: SyncMetadata.self, forPrimaryKey: syncMetadataId) {
            return metadata
        } else {
            let metadata = SyncMetadata()
            try? realm.write {
                realm.add(metadata)
            }
            return metadata
        }
    }
    
    private func getSyncOperation(id: String) -> SyncOperation? {
        return realm.object(ofType: SyncOperation.self, forPrimaryKey: id)
    }
    
    private func performFullSync(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 检查iCloud账户状态
            self.cloudKitService.checkAccountStatus()
                .flatMap { accountStatus -> AnyPublisher<Void, Error> in
                    guard accountStatus == .available else {
                        return Fail(error: NSError(domain: "SyncRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "iCloud账户不可用"])).eraseToAnyPublisher()
                    }
                    
                    // 执行全量同步
                    return self.syncAllData(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    private func performFavoritesSync(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 检查iCloud账户状态
            self.cloudKitService.checkAccountStatus()
                .flatMap { accountStatus -> AnyPublisher<Void, Error> in
                    guard accountStatus == .available else {
                        return Fail(error: NSError(domain: "SyncRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "iCloud账户不可用"])).eraseToAnyPublisher()
                    }
                    
                    // 执行收藏同步
                    return self.syncFavorites(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    private func performSettingsSync(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 检查iCloud账户状态
            self.cloudKitService.checkAccountStatus()
                .flatMap { accountStatus -> AnyPublisher<Void, Error> in
                    guard accountStatus == .available else {
                        return Fail(error: NSError(domain: "SyncRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "iCloud账户不可用"])).eraseToAnyPublisher()
                    }
                    
                    // 执行设置同步
                    return self.syncSettings(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    private func syncAllData(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 同步所有数据：收藏夹、收藏项、用户设置
        return Publishers.Zip3(
            syncFavorites(operation: operation),
            syncSettings(operation: operation),
            syncUserData(operation: operation)
        )
        .map { _, _, _ in () }
        .eraseToAnyPublisher()
    }
    
    private func syncFavorites(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 1. 上传本地待同步的收藏夹和收藏项
            self.uploadPendingFavorites(operation: operation)
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // 2. 下载远程更新的收藏夹和收藏项
                    return self.downloadRemoteFavorites(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    private func syncSettings(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 1. 上传本地待同步的设置
            self.uploadPendingSettings(operation: operation)
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // 2. 下载远程更新的设置
                    return self.downloadRemoteSettings(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    private func syncUserData(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 1. 上传本地待同步的用户数据
            self.uploadPendingUserData(operation: operation)
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // 2. 下载远程更新的用户数据
                    return self.downloadRemoteUserData(operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(()))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 上传待同步的收藏夹和收藏项
    private func uploadPendingFavorites(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现上传逻辑
        // 1. 查询所有待上传的收藏夹和收藏项
        // 2. 转换为CloudKit记录
        // 3. 批量上传
        // 4. 更新本地同步状态
        
        // 这里是简化实现，实际项目中需要根据具体的数据模型进行实现
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 下载远程更新的收藏夹和收藏项
    private func downloadRemoteFavorites(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现下载逻辑
        // 1. 获取上次同步后的变更
        // 2. 处理新增、更新和删除的记录
        // 3. 处理冲突
        
        // 这里是简化实现，实际项目中需要根据具体的数据模型进行实现
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 上传待同步的设置
    private func uploadPendingSettings(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现上传逻辑
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 下载远程更新的设置
    private func downloadRemoteSettings(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现下载逻辑
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 上传待同步的用户数据
    private func uploadPendingUserData(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现上传逻辑
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 下载远程更新的用户数据
    private func downloadRemoteUserData(operation: SyncOperation) -> AnyPublisher<Void, Error> {
        // 实现下载逻辑
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // 计算待同步的变更数量
    private func countPendingChanges(excludingFavorites: Bool = false, excludingSettings: Bool = false) -> Int {
        // 实现计算逻辑
        // 这里是简化实现，实际项目中需要根据具体的数据模型进行实现
        return 0
    }
}