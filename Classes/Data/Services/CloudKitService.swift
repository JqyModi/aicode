import Foundation
import CloudKit
import Combine

class CloudKitService {
    // 单例模式
    static let shared = CloudKitService()
    
    // CloudKit容器和数据库
    private let container: CKContainer
    private let privateDB: CKDatabase
    private let sharedDB: CKDatabase
    
    // 记录类型常量
    private struct RecordType {
        static let folder = "Folder"
        static let favoriteItem = "FavoriteItem"
        static let user = "User"
        static let syncStatus = "SyncStatus"
    }
    
    // 初始化
    private init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
    }
    
    // 检查CloudKit可用性
    func checkCloudKitAvailability() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.container.accountStatus { status, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                switch status {
                case .available:
                    promise(.success(true))
                case .noAccount, .restricted, .couldNotDetermine:
                    promise(.success(false))
                @unknown default:
                    promise(.success(false))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 保存记录
    func saveRecord(_ record: CKRecord) -> AnyPublisher<CKRecord, Error> {
        return Future<CKRecord, Error> { promise in
            self.privateDB.save(record) { savedRecord, error in
                if let error = error {
                    promise(.failure(error))
                } else if let savedRecord = savedRecord {
                    promise(.success(savedRecord))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "未知错误"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 批量保存记录
    func saveRecords(_ records: [CKRecord]) -> AnyPublisher<[CKRecord], Error> {
        return Future<[CKRecord], Error> { promise in
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            
            var savedRecords: [CKRecord] = []
            
            operation.perRecordCompletionBlock = { record, error in
                if error == nil {
                    savedRecords.append(record)
                }
            }
            
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(savedRecords))
                }
            }
            
            self.privateDB.add(operation)
        }.eraseToAnyPublisher()
    }
    
    // 获取记录
    func fetchRecord(recordID: CKRecord.ID) -> AnyPublisher<CKRecord, Error> {
        return Future<CKRecord, Error> { promise in
            self.privateDB.fetch(withRecordID: recordID) { record, error in
                if let error = error {
                    promise(.failure(error))
                } else if let record = record {
                    promise(.success(record))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "记录不存在"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 查询记录
    func queryRecords(recordType: String, predicate: NSPredicate = NSPredicate(value: true), sortDescriptors: [NSSortDescriptor]? = nil) -> AnyPublisher<[CKRecord], Error> {
        return Future<[CKRecord], Error> { promise in
            let query = CKQuery(recordType: recordType, predicate: predicate)
            query.sortDescriptors = sortDescriptors
            
            self.privateDB.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    promise(.failure(error))
                } else if let records = records {
                    promise(.success(records))
                } else {
                    promise(.success([]))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 删除记录
    func deleteRecord(recordID: CKRecord.ID) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.privateDB.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 批量删除记录
    func deleteRecords(recordIDs: [CKRecord.ID]) -> AnyPublisher<[CKRecord.ID], Error> {
        return Future<[CKRecord.ID], Error> { promise in
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
            
            var deletedRecordIDs: [CKRecord.ID] = []
            
            operation.perRecordCompletionBlock = { recordID, error in
                if error == nil {
                    deletedRecordIDs.append(recordID.recordID)
                }
            }
            
            operation.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
                if let error = error {
                    promise(.failure(error))
                } else if let deletedRecordIDs = deletedRecordIDs {
                    promise(.success(deletedRecordIDs))
                } else {
                    promise(.success([]))
                }
            }
            
            self.privateDB.add(operation)
        }.eraseToAnyPublisher()
    }
    
    // 获取变更
    func fetchChanges(recordType: String, since token: CKServerChangeToken?) -> AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), Error> {
        return Future<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), Error> { promise in
            let operation = CKFetchRecordZoneChangesOperation()
            
            // 创建记录区域ID
            let zoneID = CKRecordZone.ID(zoneName: "defaultZone", ownerName: CKCurrentUserDefaultName)
            
            // 配置选项
            let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
            options.previousServerChangeToken = token
            
            operation.recordZoneIDs = [zoneID]
            operation.configurationsByRecordZoneID = [zoneID: options]
            operation.fetchAllChanges = true
            
            var changedRecords: [CKRecord] = []
            var deletedRecordIDs: [CKRecord.ID] = []
            var newToken: CKServerChangeToken?
            
            operation.recordChangedBlock = { record in
                changedRecords.append(record)
            }
            
            operation.recordWithIDWasDeletedBlock = { recordID, _ in
                deletedRecordIDs.append(recordID)
            }
            
            operation.recordZoneChangeTokensUpdatedBlock = { _, token, _ in
                newToken = token
            }
            
            operation.recordZoneFetchCompletionBlock = { _, token, _, _, error in
                if error == nil {
                    newToken = token
                }
            }
            
            operation.fetchRecordZoneChangesCompletionBlock = { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success((records: changedRecords, deletedRecordIDs: deletedRecordIDs, token: newToken)))
                }
            }
            
            self.privateDB.add(operation)
        }.eraseToAnyPublisher()
    }
    
    // 创建文件夹记录
    func createFolderRecord(from folder: Folder) -> CKRecord {
        let recordID = CKRecord.ID(recordName: folder.id)
        let record = CKRecord(recordType: RecordType.folder, recordID: recordID)
        
        record["name"] = folder.name as CKRecordValue
        record["createdAt"] = folder.createdAt as CKRecordValue
        record["lastModified"] = folder.lastModified as CKRecordValue
        record["isDefault"] = folder.isDefault as CKRecordValue
        
        return record
    }
    
    // 创建收藏项记录
    func createFavoriteItemRecord(from item: FavoriteItem) -> CKRecord {
        let recordID = CKRecord.ID(recordName: item.id)
        let record = CKRecord(recordType: RecordType.favoriteItem, recordID: recordID)
        
        record["wordId"] = item.wordId as CKRecordValue
        record["word"] = item.word as CKRecordValue
        record["reading"] = item.reading as CKRecordValue
        record["meaning"] = item.meaning as CKRecordValue
        
        if let note = item.note {
            record["note"] = note as CKRecordValue
        }
        
        record["addedAt"] = item.addedAt as CKRecordValue
        record["lastModified"] = item.lastModified as CKRecordValue
        
        // 设置与文件夹的关系
        if let folder = item.linkingObjects.first {
            let folderReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: folder.id), action: .deleteSelf)
            record["folder"] = folderReference
        }
        
        return record
    }
    
    // 创建用户记录
    func createUserRecord(from user: User) -> CKRecord {
        let recordID = CKRecord.ID(recordName: user.id)
        let record = CKRecord(recordType: RecordType.user, recordID: recordID)
        
        if let nickname = user.nickname {
            record["nickname"] = nickname as CKRecordValue
        }
        
        if let email = user.email {
            record["email"] = email as CKRecordValue
        }
        
        if let settings = user.settings {
            // 将设置转换为JSON数据
            let settingsDict: [String: Any] = [
               "darkMode": settings.darkMode,
               "fontSize": settings.fontSize,
               "autoSync": settings.autoSync,
               "notificationsEnabled": settings.notificationsEnabled,
               "syncFrequency": settings.syncFrequency
           ]
           
           if let settingsData = try? JSONSerialization.data(withJSONObject: settingsDict) {
                record["settings"] = settingsData as CKRecordValue
            }
        }
        
        if let lastSyncTime = user.lastSyncTime {
            record["lastSyncTime"] = lastSyncTime as CKRecordValue
        }
        
        record["createdAt"] = user.createdAt as CKRecordValue
        
        return record
    }
    
    // 从CloudKit记录创建文件夹对象
    func createFolder(from record: CKRecord) -> Folder {
        let folder = Folder()
        folder.id = record.recordID.recordName
        folder.name = record["name"] as? String ?? "未命名文件夹"
        folder.createdAt = record["createdAt"] as? Date ?? Date()
        folder.lastModified = record["lastModified"] as? Date ?? Date()
        folder.isDefault = record["isDefault"] as? Bool ?? false
        folder.syncStatus = SyncStatusType.synced.rawValue
        
        return folder
    }
    
    // 从CloudKit记录创建收藏项对象
    func createFavoriteItem(from record: CKRecord) -> FavoriteItem {
        let item = FavoriteItem()
        item.id = record.recordID.recordName
        item.wordId = record["wordId"] as? String ?? ""
        item.word = record["word"] as? String ?? ""
        item.reading = record["reading"] as? String ?? ""
        item.meaning = record["meaning"] as? String ?? ""
        item.note = record["note"] as? String
        item.addedAt = record["addedAt"] as? Date ?? Date()
        item.lastModified = record["lastModified"] as? Date ?? Date()
        item.syncStatus = SyncStatusType.synced.rawValue
        
        return item
    }
    
    // 从CloudKit记录创建用户对象
    func createUser(from record: CKRecord) -> User {
        let user = User()
        user.id = record.recordID.recordName
        user.nickname = record["nickname"] as? String
        user.email = record["email"] as? String
        user.lastSyncTime = record["lastSyncTime"] as? Date
        user.createdAt = record["createdAt"] as? Date ?? Date()
        user.syncStatus = SyncStatusType.synced.rawValue
        
        // 从JSON数据恢复设置
        if let settingsData = record["settings"] as? Data,
           let settingsDict = try? JSONSerialization.jsonObject(with: settingsData, options: []) as? [String: Any] {
            let settings = UserSettings()
            settings.darkMode = settingsDict["darkMode"] as? Bool ?? false
            settings.fontSize = settingsDict["fontSize"] as? Int ?? 2
            settings.autoSync = settingsDict["autoSync"] as? Bool ?? true
            settings.notificationsEnabled = settingsDict["notificationsEnabled"] as? Bool ?? true
            settings.syncFrequency = settingsDict["syncFrequency"] as? Int ?? 1
            
            user.settings = settings
        }
        
        return user
    }
    
    // 处理CloudKit错误
    func handleCloudKitError(_ error: Error) -> Error {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkFailure, .networkUnavailable:
                return NSError(domain: "CloudKitService", code: 2001, userInfo: [NSLocalizedDescriptionKey: "网络连接不可用，请检查网络设置"])
            case .notAuthenticated:
                return NSError(domain: "CloudKitService", code: 2002, userInfo: [NSLocalizedDescriptionKey: "未登录iCloud账户，请在设置中登录"])
            case .quotaExceeded:
                return NSError(domain: "CloudKitService", code: 2003, userInfo: [NSLocalizedDescriptionKey: "iCloud存储空间已满，请清理空间"])
            case .serverResponseLost, .serviceUnavailable:
                return NSError(domain: "CloudKitService", code: 2004, userInfo: [NSLocalizedDescriptionKey: "iCloud服务暂时不可用，请稍后再试"])
            case .zoneBusy, .requestRateLimited:
                return NSError(domain: "CloudKitService", code: 2005, userInfo: [NSLocalizedDescriptionKey: "请求过于频繁，请稍后再试"])
            case .changeTokenExpired:
                return NSError(domain: "CloudKitService", code: 2006, userInfo: [NSLocalizedDescriptionKey: "同步令牌已过期，需要重新同步"])
            default:
                return NSError(domain: "CloudKitService", code: 2000, userInfo: [NSLocalizedDescriptionKey: "iCloud同步错误：\(ckError.localizedDescription)"])
            }
        }
        return error
    }
}
