import Foundation
import RealmSwift
import Combine

class SyncConflictResolver {
    // 单例模式
    static let shared = SyncConflictResolver()
    
    private let realmManager: RealmManager
    
    private init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
    }
    
    // 检测冲突
    func detectConflict(localObject: Object, remoteData: [String: Any], localModified: Date, remoteModified: Date) -> Bool {
        // 如果远程修改时间晚于本地修改时间，且本地对象已被修改，则存在冲突
        return remoteModified > localModified && hasPendingChanges(localObject)
    }
    
    // 检查对象是否有待同步的更改
    private func hasPendingChanges(_ object: Object) -> Bool {
        if let folder = object as? Folder {
            return folder.syncStatus == SyncStatusType.pendingUpload.rawValue
        } else if let item = object as? FavoriteItem {
            return item.syncStatus == SyncStatusType.pendingUpload.rawValue
        } else if let user = object as? User {
            return user.syncStatus == SyncStatusType.pendingUpload.rawValue
        }
        return false
    }
    
    // 创建冲突记录
    func createConflictRecord(recordType: String, recordId: String, localObject: Object, remoteData: [String: Any], localModified: Date, remoteModified: Date) -> AnyPublisher<SyncConflict, Error> {
        return realmManager.writeAsync { realm in
            let conflict = SyncConflict()
            conflict.recordType = recordType
            conflict.recordId = recordId
            conflict.localModified = localModified
            conflict.remoteModified = remoteModified
            conflict.resolved = false
            
            // 序列化本地对象
            if let localData = try? self.serializeObject(localObject) {
                conflict.localData = localData
            }
            
            // 序列化远程数据
            if let remoteData = try? JSONSerialization.data(withJSONObject: remoteData, options: []) {
                conflict.remoteData = remoteData
            }
            
            realm.add(conflict)
            return conflict
        }
    }
    
    // 解决冲突
    func resolveConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            guard let conflict = realm.object(ofType: SyncConflict.self, forPrimaryKey: conflictId) else {
                throw NSError(domain: "SyncConflictResolver", code: 404, userInfo: [NSLocalizedDescriptionKey: "冲突记录不存在"])
            }
            
            // 标记冲突为已解决
            conflict.resolved = true
            conflict.resolution = resolution.rawValue
            
            // 根据解决策略应用更改
            switch resolution {
            case .useLocal:
                // 保持本地版本，不需要额外操作
                break
                
            case .useRemote:
                // 使用远程版本
                try self.applyRemoteChanges(conflict, realm: realm)
                
            case .merge:
                // 合并两个版本
                try self.mergeChanges(conflict, realm: realm)
                
            case .manual:
                // 手动解决，由用户在UI中选择
                // 这里不做任何操作，等待用户选择
                break
            }
            
            return true
        }
    }
    
    // 应用远程更改
    private func applyRemoteChanges(_ conflict: SyncConflict, realm: Realm) throws {
        guard let remoteData = conflict.remoteData,
              let remoteDict = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [String: Any] else {
            throw NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程数据"])
        }
        
        switch conflict.recordType {
        case "folder":
            if let folder = realm.object(ofType: Folder.self, forPrimaryKey: conflict.recordId) {
                try updateFolder(folder, with: remoteDict)
            }
            
        case "favorite":
            if let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: conflict.recordId) {
                try updateFavoriteItem(item, with: remoteDict)
            }
            
        case "user":
            if let user = realm.object(ofType: User.self, forPrimaryKey: conflict.recordId) {
                try updateUser(user, with: remoteDict)
            }
            
        default:
            throw NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "不支持的记录类型"])
        }
    }
    
    // 合并更改
    private func mergeChanges(_ conflict: SyncConflict, realm: Realm) throws {
        guard let localData = conflict.localData,
              let localDict = try? JSONSerialization.jsonObject(with: localData, options: []) as? [String: Any],
              let remoteData = conflict.remoteData,
              let remoteDict = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [String: Any] else {
            throw NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突数据"])
        }
        
        switch conflict.recordType {
        case "folder":
            if let folder = realm.object(ofType: Folder.self, forPrimaryKey: conflict.recordId) {
                try mergeFolderChanges(folder, localDict: localDict, remoteDict: remoteDict)
            }
            
        case "favorite":
            if let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: conflict.recordId) {
                try mergeFavoriteItemChanges(item, localDict: localDict, remoteDict: remoteDict)
            }
            
        case "user":
            if let user = realm.object(ofType: User.self, forPrimaryKey: conflict.recordId) {
                try mergeUserChanges(user, localDict: localDict, remoteDict: remoteDict)
            }
            
        default:
            throw NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "不支持的记录类型"])
        }
    }
    
    // 更新文件夹
    private func updateFolder(_ folder: Folder, with remoteDict: [String: Any]) throws {
        if let name = remoteDict["name"] as? String {
            folder.name = name
        }
        
        if let lastModified = remoteDict["lastModified"] as? Date {
            folder.lastModified = lastModified
        }
        
        if let isDefault = remoteDict["isDefault"] as? Bool {
            folder.isDefault = isDefault
        }
        
        folder.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 更新收藏项
    private func updateFavoriteItem(_ item: FavoriteItem, with remoteDict: [String: Any]) throws {
        if let word = remoteDict["word"] as? String {
            item.word = word
        }
        
        if let reading = remoteDict["reading"] as? String {
            item.reading = reading
        }
        
        if let meaning = remoteDict["meaning"] as? String {
            item.meaning = meaning
        }
        
        if let note = remoteDict["note"] as? String {
            item.note = note
        }
        
        if let lastModified = remoteDict["lastModified"] as? Date {
            item.lastModified = lastModified
        }
        
        item.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 更新用户
    private func updateUser(_ user: User, with remoteDict: [String: Any]) throws {
        if let nickname = remoteDict["nickname"] as? String {
            user.nickname = nickname
        }
        
        if let email = remoteDict["email"] as? String {
            user.email = email
        }
        
        if let lastSyncTime = remoteDict["lastSyncTime"] as? Date {
            user.lastSyncTime = lastSyncTime
        }
        
        if let settingsDict = remoteDict["settings"] as? [String: Any],
           let settings = user.settings {
            if let darkMode = settingsDict["darkMode"] as? Bool {
                settings.darkMode = darkMode
            }
            
            if let fontSize = settingsDict["fontSize"] as? Int {
                settings.fontSize = fontSize
            }
            
            if let autoSync = settingsDict["autoSync"] as? Bool {
                settings.autoSync = autoSync
            }
            
            if let notificationsEnabled = settingsDict["notificationsEnabled"] as? Bool {
                settings.notificationsEnabled = notificationsEnabled
            }
            
            if let syncFrequency = settingsDict["syncFrequency"] as? Int {
                settings.syncFrequency = syncFrequency
            }
        }
        
        user.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 合并文件夹更改
    private func mergeFolderChanges(_ folder: Folder, localDict: [String: Any], remoteDict: [String: Any]) throws {
        // 保留本地名称，除非本地名称未修改
        let originalName = localDict["name"] as? String
        let remoteName = remoteDict["name"] as? String
        
        if folder.name == originalName, let remoteName = remoteName {
            folder.name = remoteName
        }
        
        // 使用最新的修改时间
        if let remoteLastModified = remoteDict["lastModified"] as? Date,
           remoteLastModified > folder.lastModified {
            folder.lastModified = remoteLastModified
        }
        
        // 默认文件夹状态以远程为准
        if let isDefault = remoteDict["isDefault"] as? Bool {
            folder.isDefault = isDefault
        }
        
        folder.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 合并收藏项更改
    private func mergeFavoriteItemChanges(_ item: FavoriteItem, localDict: [String: Any], remoteDict: [String: Any]) throws {
        // 基本信息以远程为准
        if let word = remoteDict["word"] as? String {
            item.word = word
        }
        
        if let reading = remoteDict["reading"] as? String {
            item.reading = reading
        }
        
        if let meaning = remoteDict["meaning"] as? String {
            item.meaning = meaning
        }
        
        // 笔记合并策略：如果本地和远程都有修改，则合并两者
        let originalNote = localDict["note"] as? String
        let remoteNote = remoteDict["note"] as? String
        
        if let remoteNote = remoteNote {
            if item.note != originalNote && item.note != nil && originalNote != nil {
                // 本地有修改，合并两者
                item.note = "【本地】\(item.note ?? "")\n\n【远程】\(remoteNote)"
            } else {
                // 本地无修改，使用远程版本
                item.note = remoteNote
            }
        }
        
        // 使用最新的修改时间
        if let remoteLastModified = remoteDict["lastModified"] as? Date,
           remoteLastModified > item.lastModified {
            item.lastModified = remoteLastModified
        }
        
        item.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 合并用户更改
    private func mergeUserChanges(_ user: User, localDict: [String: Any], remoteDict: [String: Any]) throws {
        // 用户基本信息合并
        if let nickname = remoteDict["nickname"] as? String {
            user.nickname = nickname
        }
        
        if let email = remoteDict["email"] as? String {
            user.email = email
        }
        
        // 设置合并
        if let remoteSettingsDict = remoteDict["settings"] as? [String: Any],
           let localSettingsDict = localDict["settings"] as? [String: Any],
           let settings = user.settings {
            
            // 深色模式：保留本地设置
            if let remoteDarkMode = remoteSettingsDict["darkMode"] as? Bool,
               let localDarkMode = localSettingsDict["darkMode"] as? Bool {
                if settings.darkMode != localDarkMode {
                    // 本地有修改，保留本地
                } else {
                    // 本地无修改，使用远程
                    settings.darkMode = remoteDarkMode
                }
            }
            
            // 字体大小：保留本地设置
            if let remoteFontSize = remoteSettingsDict["fontSize"] as? Int,
               let localFontSize = localSettingsDict["fontSize"] as? Int {
                if settings.fontSize != localFontSize {
                    // 本地有修改，保留本地
                } else {
                    // 本地无修改，使用远程
                    settings.fontSize = remoteFontSize
                }
            }
            
            // 自动同步：使用远程设置
            if let autoSync = remoteSettingsDict["autoSync"] as? Bool {
                settings.autoSync = autoSync
            }
            
            // 通知：使用远程设置
            if let notificationsEnabled = remoteSettingsDict["notificationsEnabled"] as? Bool {
                settings.notificationsEnabled = notificationsEnabled
            }
            
            // 同步频率：使用远程设置
            if let syncFrequency = remoteSettingsDict["syncFrequency"] as? Int {
                settings.syncFrequency = syncFrequency
            }
        }
        
        // 使用最新的同步时间
        if let remoteLastSyncTime = remoteDict["lastSyncTime"] as? Date {
            user.lastSyncTime = remoteLastSyncTime
        }
        
        user.syncStatus = SyncStatusType.synced.rawValue
    }
    
    // 序列化对象为JSON数据
    private func serializeObject(_ object: Object) throws -> Data {
        var dict: [String: Any] = [:]
        
        if let folder = object as? Folder {
            dict["id"] = folder.id
            dict["name"] = folder.name
            dict["createdAt"] = folder.createdAt
            dict["lastModified"] = folder.lastModified
            dict["isDefault"] = folder.isDefault
            dict["syncStatus"] = folder.syncStatus
        } else if let item = object as? FavoriteItem {
            dict["id"] = item.id
            dict["wordId"] = item.wordId
            dict["word"] = item.word
            dict["reading"] = item.reading
            dict["meaning"] = item.meaning
            dict["note"] = item.note
            dict["addedAt"] = item.addedAt
            dict["lastModified"] = item.lastModified
            dict["syncStatus"] = item.syncStatus
        } else if let user = object as? User {
            dict["id"] = user.id
            dict["nickname"] = user.nickname
            dict["email"] = user.email
            dict["lastSyncTime"] = user.lastSyncTime
            dict["createdAt"] = user.createdAt
            dict["syncStatus"] = user.syncStatus
            
            if let settings = user.settings {
                dict["settings"] = [
                    "darkMode": settings.darkMode,
                    "fontSize": settings.fontSize,
                    "autoSync": settings.autoSync,
                    "notificationsEnabled": settings.notificationsEnabled,
                    "syncFrequency": settings.syncFrequency
                ]
            }
        } else {
            throw NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "不支持的对象类型"])
        }
        
        return try JSONSerialization.data(withJSONObject: dict, options: [])
    }
}
