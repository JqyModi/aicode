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
        // 简化的冲突检测逻辑：如果本地和远程都有修改，且修改时间接近，则认为有冲突
        let timeDifference = abs(localModified.timeIntervalSince(remoteModified))
        
        // 如果修改时间相差不到1小时，认为可能存在冲突
        return timeDifference < 3600
    }
    
    // 创建冲突记录
    func createConflictRecord(recordType: String, recordId: String, localObject: Object, remoteData: [String: Any], localModified: Date, remoteModified: Date) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            // 创建冲突记录
            let conflict = SyncConflict()
            conflict.id = UUID().uuidString
            conflict.recordId = recordId
            conflict.recordType = recordType
            conflict.localModified = localModified
            conflict.remoteModified = remoteModified
            conflict.resolved = false
            
            // 序列化本地对象
            if let localData = try? JSONSerialization.data(withJSONObject: localObject.dictionaryWithValues(forKeys: Array(remoteData.keys)), options: []) {
                conflict.localData = localData
            }
            
            // 序列化远程数据
            if let remoteDataSerialized = try? JSONSerialization.data(withJSONObject: remoteData, options: []) {
                conflict.remoteData = remoteDataSerialized
            }
            
            realm.add(conflict)
            return true
        }
    }
    
    // 解决冲突
    func resolveConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            guard let conflict = realm.object(ofType: SyncConflict.self, forPrimaryKey: conflictId) else {
                throw NSError(domain: "SyncConflictResolver", code: 404, userInfo: [NSLocalizedDescriptionKey: "冲突记录不存在"])
            }
            
            // 标记为已解决
            conflict.resolved = true
            conflict.resolutionType = resolution.rawValue
            
            // 根据冲突类型获取对应的对象
            switch conflict.recordType {
            case "folder":
                if let folder = realm.object(ofType: Folder.self, forPrimaryKey: conflict.recordId) {
                    self.applyResolution(object: folder, conflict: conflict, resolution: resolution, realm: realm)
                }
            case "favorite":
                if let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: conflict.recordId) {
                    self.applyResolution(object: item, conflict: conflict, resolution: resolution, realm: realm)
                }
            case "user":
                if let user = realm.object(ofType: User.self, forPrimaryKey: conflict.recordId) {
                    self.applyResolution(object: user, conflict: conflict, resolution: resolution, realm: realm)
                }
            default:
                break
            }
            
            return true
        }
    }
    
    // 应用解决方案
    private func applyResolution(object: Object, conflict: SyncConflict, resolution: ConflictResolution, realm: Realm) {
        switch resolution {
        case .useLocal:
            // 保持本地版本，不需要操作
            object.setValue(SyncStatusType.pendingUpload.rawValue, forKey: "syncStatus")
            
        case .useRemote:
            // 使用远程版本
            if let remoteData = conflict.remoteData,
               let remoteDict = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [String: Any] {
                
                // 应用远程数据到本地对象
                for (key, value) in remoteDict {
                    object.setValue(value, forKey: key)
                }
                
                object.setValue(SyncStatusType.synced.rawValue, forKey: "syncStatus")
            }
            
        case .merge:
            // 简化版本：使用远程版本，但保留本地的某些字段
            // 在实际应用中，这里应该有更复杂的合并逻辑
            if let remoteData = conflict.remoteData,
               let remoteDict = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [String: Any] {
                
                // 应用远程数据到本地对象，但保留某些本地字段
                for (key, value) in remoteDict {
                    // 这里可以添加特定字段的合并逻辑
                    object.setValue(value, forKey: key)
                }
                
                object.setValue(SyncStatusType.pendingUpload.rawValue, forKey: "syncStatus")
            }
        }
    }
}

// 冲突解决策略
enum ConflictResolution: String {
    case useLocal = "useLocal"       // 使用本地版本
    case useRemote = "useRemote"     // 使用远程版本
    case merge = "merge"             // 合并两个版本
}