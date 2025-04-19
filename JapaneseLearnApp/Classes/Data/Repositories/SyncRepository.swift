//
//  SyncRepository.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine
import RealmSwift
import CloudKit

class SyncRepository: SyncRepositoryProtocol {
    
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let container: CKContainer
    private let database: CKDatabase
    
    init() {
        do {
            self.realm = try Realm()
            self.container = CKContainer.default()
            self.database = container.privateCloudDatabase
        } catch {
            fatalError("无法初始化Realm: \(error)")
        }
    }
    
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error> {
        return Future<SyncStatus, Error> { promise in
            // 检查是否有待同步的项目
            let pendingFolders = self.realm.objects(Folder.self)
                .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
            
            let pendingItems = self.realm.objects(FavoriteItem.self)
                .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
            
            let pendingUsers = self.realm.objects(User.self)
                .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
            
            // 获取最后同步时间
            let lastSyncTime = self.userDefaults.object(forKey: "lastSyncTime") as? Date
            
            // 创建同步状态
            let status = SyncStatus()
            status.pendingChanges = pendingFolders.count + pendingItems.count + pendingUsers.count
            status.lastSyncTime = lastSyncTime
            status.availableOffline = true
            
            if status.pendingChanges > 0 {
                status.status = "pending_changes"
            } else {
                status.status = "synced"
            }
            
            promise(.success(status))
        }.eraseToAnyPublisher()
    }
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            do {
                // 创建同步操作记录
                let operation = SyncOperation()
                operation.type = type.rawValue
                operation.status = "in_progress"
                operation.startedAt = Date()
                
                // 获取当前用户ID
                if let userId = self.userDefaults.string(forKey: "currentUserId") {
                    operation.userId = userId
                }
                
                try self.realm.write {
                    self.realm.add(operation)
                }
                
                // 创建同步进度记录
                let progress = SyncProgress()
                progress.operationId = operation.id
                progress.progress = 0.0
                progress.totalItems = 0 // 这里应该计算需要同步的总项目数
                
                try self.realm.write {
                    self.realm.add(progress)
                }
                
                // 启动异步同步过程
                self.performSync(operation: operation, type: type)
                
                promise(.success(operation))
            } catch {
                promise(.failure(SyncError.syncInProgress))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgress, Error> {
        return Future<SyncProgress, Error> { promise in
            guard let progress = self.realm.object(ofType: SyncProgress.self, forPrimaryKey: operationId) else {
                promise(.failure(SyncError.syncInProgress))
                return
            }
            
            promise(.success(progress))
        }.eraseToAnyPublisher()
    }
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                guard let conflict = self.realm.object(ofType: SyncConflict.self, forPrimaryKey: conflictId) else {
                    promise(.failure(SyncError.conflictDetected))
                    return
                }
                
                try self.realm.write {
                    switch resolution {
                    case .useLocal:
                        conflict.resolution = 1
                    case .useRemote:
                        conflict.resolution = 2
                    case .merge:
                        conflict.resolution = 3
                    }
                    
                    conflict.resolved = true
                }
                
                // 应用解决方案
                self.applyConflictResolution(conflict: conflict, resolution: resolution)
                
                promise(.success(true))
            } catch {
                promise(.failure(SyncError.conflictDetected))
            }
        }.eraseToAnyPublisher()
    }
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                guard let userId = self.userDefaults.string(forKey: "currentUserId"),
                      let user = self.realm.object(ofType: User.self, forPrimaryKey: userId) else {
                    promise(.failure(UserError.userNotFound))
                    return
                }
                
                try self.realm.write {
                    if let settings = user.settings {
                        settings.autoSync = enabled
                    } else {
                        let settings = UserSettings()
                        settings.autoSync = enabled
                        user.settings = settings
                    }
                }
                
                promise(.success(enabled))
            } catch {
                promise(.failure(UserError.settingsUpdateFailed))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - 私有辅助方法
    
    // 执行同步操作
    private func performSync(operation: SyncOperation, type: SyncType) {
        // 这里应该实现实际的同步逻辑，与CloudKit交互
        // 为了示例，我们只是模拟同步过程
        
        DispatchQueue.global().async {
            do {
                // 模拟同步延迟
                Thread.sleep(forTimeInterval: 2.0)
                
                try self.realm.write {
                    // 更新同步操作状态
                    operation.status = "completed"
                    operation.completedAt = Date()
                    
                    // 更新同步进度
                    if let progress = self.realm.object(ofType: SyncProgress.self, forPrimaryKey: operation.id) {
                        progress.progress = 1.0
                        progress.itemsSynced = progress.totalItems
                    }
                    
                    // 更新最后同步时间
                    self.userDefaults.set(Date(), forKey: "lastSyncTime")
                    
                    // 根据同步类型更新相应数据的同步状态
                    switch type {
                    case .full:
                        // 更新所有数据的同步状态
                        let folders = self.realm.objects(Folder.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for folder in folders {
                            folder.syncStatus = UISyncStatus.synced.rawValue
                        }
                        
                        let items = self.realm.objects(FavoriteItem.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for item in items {
                            item.syncStatus = UISyncStatus.synced.rawValue
                        }
                        
                        let users = self.realm.objects(User.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for user in users {
                            user.syncStatus = UISyncStatus.synced.rawValue
                        }
                        
                    case .favorites:
                        // 只更新收藏相关数据的同步状态
                        let folders = self.realm.objects(Folder.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for folder in folders {
                            folder.syncStatus = UISyncStatus.synced.rawValue
                        }
                        
                        let items = self.realm.objects(FavoriteItem.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for item in items {
                            item.syncStatus = UISyncStatus.synced.rawValue
                        }
                        
                    case .settings:
                        // 只更新设置相关数据的同步状态
                        let users = self.realm.objects(User.self)
                            .filter("syncStatus == %@", UISyncStatus.pendingUpload.rawValue)
                        
                        for user in users {
                            user.syncStatus = UISyncStatus.synced.rawValue
                        }
                    }
                }
            } catch {
                // 处理同步错误
                do {
                    try self.realm.write {
                        operation.status = "failed"
                        operation.error = error.localizedDescription
                    }
                } catch {
                    print("无法更新同步操作状态: \(error)")
                }
            }
        }
    }
    
    // 应用冲突解决方案
    private func applyConflictResolution(conflict: SyncConflict, resolution: ConflictResolution) {
        do {
            try self.realm.write {
                switch conflict.entityType {
                case "folder":
                    if let folder = self.realm.object(ofType: Folder.self, forPrimaryKey: conflict.entityId) {
                        switch resolution {
                        case .useLocal:
                            // 保持本地版本，只更新同步状态
                            folder.syncStatus = UISyncStatus.synced.rawValue
                        case .useRemote:
                            // 使用远程版本
                            // 修改这里的解码方式
                            if let remoteData = conflict.remoteData.data(using: .utf8),
                               let jsonDict = try? JSONSerialization.jsonObject(with: remoteData) as? [String: Any],
                               let name = jsonDict["name"] as? String {
                                folder.name = name
                                folder.syncStatus = UISyncStatus.synced.rawValue
                            }
                        case .merge:
                            // 合并版本
                            folder.syncStatus = UISyncStatus.synced.rawValue
                        }
                    }
                    
                case "favorite_item":
                    if let item = self.realm.object(ofType: FavoriteItem.self, forPrimaryKey: conflict.entityId) {
                        switch resolution {
                        case .useLocal:
                            // 保持本地版本，只更新同步状态
                            item.syncStatus = UISyncStatus.synced.rawValue
                        case .useRemote:
                            // 使用远程版本
                            // 修改这里的解码方式，使用 JSONSerialization 替代 JSONDecoder
                            if let remoteData = conflict.remoteData.data(using: .utf8),
                               let jsonDict = try? JSONSerialization.jsonObject(with: remoteData) as? [String: Any],
                               let note = jsonDict["note"] as? String {
                                item.note = note
                                item.syncStatus = UISyncStatus.synced.rawValue
                            }
                        case .merge:
                            // 合并版本（在这个简单例子中，我们只保留本地笔记但标记为已同步）
                            item.syncStatus = UISyncStatus.synced.rawValue
                        }
                    }
                    
                case "user_settings":
                    if let userId = self.userDefaults.string(forKey: "currentUserId"),
                       let user = self.realm.object(ofType: User.self, forPrimaryKey: userId),
                       let settings = user.settings {
                        
                        switch resolution {
                        case .useLocal:
                            // 保持本地版本，只更新同步状态
                            user.syncStatus = UISyncStatus.synced.rawValue
                        case .useRemote:
                            // 使用远程版本
                            // 修改这里的解码方式，使用 JSONSerialization 替代 JSONDecoder
                            if let remoteData = conflict.remoteData.data(using: .utf8),
                               let jsonDict = try? JSONSerialization.jsonObject(with: remoteData) as? [String: Any] {
                                
                                if let darkMode = jsonDict["darkMode"] as? Bool {
                                    settings.darkMode = darkMode
                                }
                                
                                if let fontSize = jsonDict["fontSize"] as? Int {
                                    settings.fontSize = fontSize
                                }
                                
                                if let autoSync = jsonDict["autoSync"] as? Bool {
                                    settings.autoSync = autoSync
                                }
                                
                                user.syncStatus = UISyncStatus.synced.rawValue
                            }
                        case .merge:
                            // 合并版本（在这个简单例子中，我们只保留本地设置但标记为已同步）
                            user.syncStatus = UISyncStatus.synced.rawValue
                        }
                    }
                    
                default:
                    break
                }
            }
        } catch {
            print("应用冲突解决方案失败: \(error)")
        }
    }
}
