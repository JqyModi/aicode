//
//  SyncDataRepository.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import RealmSwift

class SyncDataRepository: SyncDataRepositoryProtocol {
    // MARK: - 属性
    private let realmManager: RealmManager
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared, networkManager: NetworkManager = NetworkManager.shared) {
        self.realmManager = realmManager
        self.networkManager = networkManager
    }
    
    // MARK: - SyncDataRepositoryProtocol 实现
    func getSyncStatus() -> AnyPublisher<SyncStatusEntity, Error> {
        return Future<SyncStatusEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 获取当前用户
                guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
                      let user = realm.object(ofType: DBUser.self, forPrimaryKey: currentUserId) else {
                    promise(.failure(NSError(domain: "SyncDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])))
                    return
                }
                
                // 获取待同步的项目数量
                let pendingFolders = realm.objects(DBFolder.self).filter("syncStatus == 1").count
                let pendingFavorites = realm.objects(DBFavoriteItem.self).filter("syncStatus == 1").count
                let pendingChanges = pendingFolders + pendingFavorites
                
                // 检查网络状态
                let isOnline = self.networkManager.isNetworkAvailable()
                
                let syncStatus = SyncStatusEntity(
                    lastSyncTime: user.lastSyncTime,
                    pendingChanges: pendingChanges,
                    syncStatus: isOnline ? "ready" : "offline",
                    availableOffline: true
                )
                
                promise(.success(syncStatus))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func startSync(type: SyncTypeEntity) -> AnyPublisher<SyncOperationEntity, Error> {
        return Future<SyncOperationEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            // 检查网络状态
            guard self.networkManager.isNetworkAvailable() else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "网络不可用"])))
                return
            }
            
            // 检查用户登录状态
            guard UserDefaults.standard.string(forKey: "currentUserId") != nil else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])))
                return
            }
            
            // 创建同步操作记录
            let syncOperation = DBSyncOperation()
            syncOperation.syncId = UUID().uuidString
            syncOperation.startedAt = Date()
            syncOperation.status = "in_progress"
            syncOperation.syncType = self.getSyncTypeString(type)
            
            do {
                let realm = try self.realmManager.realm()
                
                try realm.write {
                    realm.add(syncOperation)
                }
                
                // 启动同步过程（这里简化处理，实际应用中需要实现真正的同步逻辑）
                self.performSync(syncId: syncOperation.syncId, type: type)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &self.cancellables)
                
                let operationEntity = SyncOperationEntity(
                    syncId: syncOperation.syncId,
                    startedAt: syncOperation.startedAt,
                    status: syncOperation.status,
                    estimatedTimeRemaining: 60 // 假设需要1分钟
                )
                
                promise(.success(operationEntity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressEntity, Error> {
        return Future<SyncProgressEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查找同步操作
                guard let syncOperation = realm.object(ofType: DBSyncOperation.self, forPrimaryKey: operationId) else {
                    promise(.failure(NSError(domain: "SyncDataRepository", code: 3, userInfo: [NSLocalizedDescriptionKey: "同步操作未找到"])))
                    return
                }
                
                let progressEntity = SyncProgressEntity(
                    syncId: syncOperation.syncId,
                    progress: syncOperation.progress,
                    status: syncOperation.status,
                    itemsSynced: syncOperation.itemsSynced,
                    totalItems: syncOperation.totalItems,
                    estimatedTimeRemaining: syncOperation.estimatedTimeRemaining
                )
                
                promise(.success(progressEntity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionEntity) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查找冲突记录
                guard let conflict = realm.object(ofType: DBSyncConflict.self, forPrimaryKey: conflictId) else {
                    promise(.failure(NSError(domain: "SyncDataRepository", code: 4, userInfo: [NSLocalizedDescriptionKey: "冲突记录未找到"])))
                    return
                }
                
                // 根据解决方案处理冲突
                switch resolution {
                case .useLocal:
                    // 使用本地版本，将本地数据标记为待上传
                    try self.resolveConflictWithLocalData(conflict: conflict)
                case .useRemote:
                    // 使用远程版本，更新本地数据
                    try self.resolveConflictWithRemoteData(conflict: conflict)
                case .merge:
                    // 合并两个版本（这里简化处理，实际应用中可能需要更复杂的合并逻辑）
                    try self.resolveConflictWithMerge(conflict: conflict)
                }
                
                // 删除冲突记录
                try realm.write {
                    realm.delete(conflict)
                }
                
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 获取当前用户
                guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
                      let user = realm.object(ofType: DBUser.self, forPrimaryKey: currentUserId) else {
                    promise(.failure(NSError(domain: "SyncDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])))
                    return
                }
                
                try realm.write {
                    if user.settings == nil {
                        user.settings = DBUserSettings()
                    }
                    user.settings?.autoSync = enabled
                }
                
                promise(.success(enabled))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - 私有辅助方法
    private func performSync(syncId: String, type: SyncTypeEntity) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            // 模拟同步过程
            DispatchQueue.global().async {
                do {
                    let realm = try self.realmManager.realm()
                    guard let syncOperation = realm.object(ofType: DBSyncOperation.self, forPrimaryKey: syncId) else {
                        promise(.failure(NSError(domain: "SyncDataRepository", code: 3, userInfo: [NSLocalizedDescriptionKey: "同步操作未找到"])))
                        return
                    }
                    
                    // 获取需要同步的项目总数
                    var totalItems = 0
                    switch type {
                    case .full:
                        totalItems = realm.objects(DBFolder.self).count + realm.objects(DBFavoriteItem.self).count
                    case .favorites:
                        totalItems = realm.objects(DBFolder.self).count + realm.objects(DBFavoriteItem.self).count
                    case .settings:
                        totalItems = 1 // 只有用户设置
                    }
                    
                    try realm.write {
                        syncOperation.totalItems = totalItems
                    }
                    
                    // 模拟同步进度更新
                    var itemsSynced = 0
                    let updateInterval = 0.5 // 每0.5秒更新一次进度
                    
                    while itemsSynced < totalItems {
                        Thread.sleep(forTimeInterval: updateInterval)
                        
                        // 每次更新同步5个项目
                        let newItemsSynced = min(itemsSynced + 5, totalItems)
                        let progress = Double(newItemsSynced) / Double(totalItems)
                        let remainingItems = totalItems - newItemsSynced
                        let estimatedTimeRemaining = Int(updateInterval * Double(remainingItems) / 5.0)
                        
                        try realm.write {
                            syncOperation.itemsSynced = newItemsSynced
                            syncOperation.progress = progress
                            syncOperation.estimatedTimeRemaining = estimatedTimeRemaining
                        }
                        
                        itemsSynced = newItemsSynced
                    }
                    
                    // 同步完成，更新状态
                    try realm.write {
                        syncOperation.status = "completed"
                        syncOperation.progress = 1.0
                        syncOperation.estimatedTimeRemaining = 0
                        
                        // 更新用户的最后同步时间
                        if let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
                           let user = realm.object(ofType: DBUser.self, forPrimaryKey: currentUserId) {
                            user.lastSyncTime = Date()
                        }
                        
                        // 更新已同步项目的状态
                        if type == .full || type == .favorites {
                            let folders = realm.objects(DBFolder.self).filter("syncStatus == 1")
                            for folder in folders {
                                folder.syncStatus = 0 // 已同步
                            }
                            
                            let favoriteItems = realm.objects(DBFavoriteItem.self).filter("syncStatus == 1")
                            for item in favoriteItems {
                                item.syncStatus = 0 // 已同步
                            }
                        }
                    }
                    
                    promise(.success(true))
                } catch {
                    // 同步失败，更新状态
                    do {
                        let realm = try self.realmManager.realm()
                        if let syncOperation = realm.object(ofType: DBSyncOperation.self, forPrimaryKey: syncId) {
                            try realm.write {
                                syncOperation.status = "failed"
                            }
                        }
                    } catch {
                        print("更新同步状态失败: \(error)")
                    }
                    
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func getSyncTypeString(_ type: SyncTypeEntity) -> String {
        switch type {
        case .full:
            return "full"
        case .favorites:
            return "favorites"
        case .settings:
            return "settings"
        }
    }
    
    private func resolveConflictWithLocalData(conflict: DBSyncConflict) throws {
        let realm = try self.realmManager.realm()
        
        try realm.write {
            // 根据冲突类型处理
            switch conflict.itemType {
            case "folder":
                if let folder = realm.object(ofType: DBFolder.self, forPrimaryKey: conflict.itemId) {
                    folder.syncStatus = 1 // 标记为待上传
                }
            case "favorite":
                if let favorite = realm.object(ofType: DBFavoriteItem.self, forPrimaryKey: conflict.itemId) {
                    favorite.syncStatus = 1 // 标记为待上传
                }
            default:
                break
            }
        }
    }
    
    private func resolveConflictWithRemoteData(conflict: DBSyncConflict) throws {
        let realm = try self.realmManager.realm()
        
        // 这里简化处理，实际应用中需要从服务器获取远程数据
        let remoteData = conflict.remoteData
        
        try realm.write {
            // 根据冲突类型处理
            switch conflict.itemType {
            case "folder":
                if let folder = realm.object(ofType: DBFolder.self, forPrimaryKey: conflict.itemId),
                   let folderData = remoteData as? [String: Any],
                   let name = folderData["name"] as? String {
                    folder.name = name
                    folder.syncStatus = 0 // 已同步
                }
            case "favorite":
                if let favorite = realm.object(ofType: DBFavoriteItem.self, forPrimaryKey: conflict.itemId),
                   let favoriteData = remoteData as? [String: Any],
                   let note = favoriteData["note"] as? String {
                    favorite.note = note
                    favorite.syncStatus = 0 // 已同步
                }
            default:
                break
            }
        }
    }
    
    private func resolveConflictWithMerge(conflict: DBSyncConflict) throws {
        // 这里简化处理，实际应用中可能需要更复杂的合并逻辑
        // 对于简单的情况，我们可以采用"最新胜出"策略
        let realm = try self.realmManager.realm()
        
        try realm.write {
            // 根据冲突类型处理
            switch conflict.itemType {
            case "folder":
                if let folder = realm.object(ofType: DBFolder.self, forPrimaryKey: conflict.itemId),
                   let folderData = conflict.remoteData as? [String: Any],
                   let name = folderData["name"] as? String,
                   let remoteUpdatedAt = folderData["updatedAt"] as? Date {
                    
                    // 比较本地和远程的更新时间，选择最新的
                    if let localUpdatedAt = folder.updatedAt, localUpdatedAt > remoteUpdatedAt {
                        // 本地更新时间更新，保留本地数据并标记为待上传
                        folder.syncStatus = 1
                    } else {
                        // 远程更新时间更新，使用远程数据
                        folder.name = name
                        folder.syncStatus = 0
                    }
                }
            case "favorite":
                if let favorite = realm.object(ofType: DBFavoriteItem.self, forPrimaryKey: conflict.itemId),
                   let favoriteData = conflict.remoteData as? [String: Any],
                   let note = favoriteData["note"] as? String,
                   let remoteUpdatedAt = favoriteData["updatedAt"] as? Date {
                    
                    // 比较本地和远程的更新时间，选择最新的
                    if let localUpdatedAt = favorite.updatedAt, localUpdatedAt > remoteUpdatedAt {
                        // 本地更新时间更新，保留本地数据并标记为待上传
                        favorite.syncStatus = 1
                    } else {
                        // 远程更新时间更新，使用远程数据
                        favorite.note = note
                        favorite.syncStatus = 0
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: - 同步相关数据库模型
class DBSyncOperation: Object {
    @objc dynamic var syncId: String = ""
    @objc dynamic var startedAt: Date = Date()
    @objc dynamic var status: String = "" // in_progress, completed, failed
    @objc dynamic var syncType: String = "" // full, favorites, settings
    @objc dynamic var progress: Double = 0.0
    @objc dynamic var itemsSynced: Int = 0
    @objc dynamic var totalItems: Int = 0
    @objc dynamic var estimatedTimeRemaining: Int = 0
    
    override static func primaryKey() -> String? {
        return "syncId"
    }
}

class DBSyncConflict: Object {
    @objc dynamic var conflictId: String = ""
    @objc dynamic var itemId: String = ""
    @objc dynamic var itemType: String = "" // folder, favorite
    @objc dynamic var detectedAt: Date = Date()
    @objc dynamic var remoteData: Any? = nil
    
    override static func primaryKey() -> String? {
        return "conflictId"
    }
    
    override class func ignoredProperties() -> [String] {
        return ["remoteData"]
    }
}
