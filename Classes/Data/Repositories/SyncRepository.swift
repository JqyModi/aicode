import Foundation
import RealmSwift
import Combine
import CloudKit

protocol SyncRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error>
    
    // 触发同步（只保留全量同步）
    func startSync() -> AnyPublisher<SyncOperation, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncOperation, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}

class SyncRepository: SyncRepositoryProtocol {
    private let realmManager: RealmManager
    private let cloudKitService: CloudKitService
    
    // 同步进度发布者
    private let syncProgressSubject = PassthroughSubject<SyncOperation, Never>()
    private var syncProgressPublisher: AnyPublisher<SyncOperation, Never> {
        return syncProgressSubject.eraseToAnyPublisher()
    }
    
    // 同步操作队列
    private let syncQueue = DispatchQueue(label: "com.aicode.syncQueue", qos: .utility)
    
    // 当前同步操作
    private var currentSyncOperation: SyncOperation?
    private var syncCancellables = Set<AnyCancellable>()
    
    // 初始化
    init(realmManager: RealmManager = RealmManager.shared,
         cloudKitService: CloudKitService = CloudKitService.shared) {
        self.realmManager = realmManager
        self.cloudKitService = cloudKitService
    }
    
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error> {
        return Future<SyncStatus, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                
                // 获取或创建同步状态
                let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status") ?? {
                    let newStatus = SyncStatus()
                    try? realm.write {
                        realm.add(newStatus)
                    }
                    return newStatus
                }()
                
                // 检查CloudKit可用性
                self.cloudKitService.checkCloudKitAvailability()
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { isAvailable in
                            try? realm.write {
                                syncStatus.cloudKitAvailable = isAvailable
                            }
                            promise(.success(syncStatus))
                        }
                    )
                    .store(in: &self.syncCancellables)
                
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 触发同步（只保留全量同步）
    func startSync() -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            // 检查是否有正在进行的同步
            if self.currentSyncOperation != nil {
                promise(.failure(NSError(domain: "SyncRepository", code: 409, userInfo: [NSLocalizedDescriptionKey: "同步操作正在进行中"])))
                return
            }
            
            // 创建同步操作记录
            self.realmManager.writeAsync { realm in
                let operation = SyncOperation()
                operation.type = "full"
                operation.status = "running"
                
                // 更新同步状态
                if let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status") {
                    syncStatus.currentOperation = operation
                } else {
                    let newStatus = SyncStatus()
                    newStatus.currentOperation = operation
                    realm.add(newStatus)
                }
                
                self.currentSyncOperation = operation
                return operation
            }
            .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                // 执行同步操作
                self.performSync(operation: operation)
                    .handleEvents(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                // 同步失败，更新操作状态
                                self.updateSyncOperationStatus(operation.id, status: "failed", errorMessage: error.localizedDescription)
                                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                                    .store(in: &self.syncCancellables)
                            }
                        }
                    )
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { operation in
                    promise(.success(operation))
                }
            )
            .store(in: &self.syncCancellables)
        }.eraseToAnyPublisher()
    }
    
    // 执行同步操作
    private func performSync(operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            self.syncQueue.async {
                // 检查CloudKit可用性
                self.cloudKitService.checkCloudKitAvailability()
                    .flatMap { isAvailable -> AnyPublisher<SyncOperation, Error> in
                        guard isAvailable else {
                            return Fail(error: NSError(domain: "SyncRepository", code: 503, userInfo: [NSLocalizedDescriptionKey: "CloudKit服务不可用"])).eraseToAnyPublisher()
                        }
                        
                        // 执行全量同步
                        return self.performFullSync(operation)
                    }
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { operation in
                            // 同步完成，清除当前操作
                            self.currentSyncOperation = nil
                            promise(.success(operation))
                        }
                    )
                    .store(in: &self.syncCancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 全量同步
    private func performFullSync(_ operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        // 1. 上传本地更改
        return self.uploadPendingChanges(operation)
            .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                // 2. 下载远程更改
                return self.downloadRemoteChanges(operation)
            }
            .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                // 3. 更新同步状态
                return self.updateSyncStatus(operation)
            }
            .eraseToAnyPublisher()
    }
    
        // 上传待处理的更改
    private func uploadPendingChanges(_ operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        return realmManager.writeAsync { realm in
            // 获取待上传的文件夹
            let pendingFolders = realm.objects(Folder.self).filter("syncStatus = %@", SyncStatusType.pendingUpload.rawValue)
            
            // 获取待上传的收藏项
            let pendingItems = realm.objects(FavoriteItem.self).filter("syncStatus = %@", SyncStatusType.pendingUpload.rawValue)
            
            // 获取待上传的用户
            let pendingUsers = realm.objects(User.self).filter("syncStatus = %@", SyncStatusType.pendingUpload.rawValue)
            
            // 获取待删除的记录
            let pendingDeletes = realm.objects(SyncRecord.self).filter("deleted = true")
            
            // 更新操作信息
            operation.totalItems = pendingFolders.count + pendingItems.count + pendingUsers.count + pendingDeletes.count
            operation.itemsProcessed = 0
            operation.progress = 0.0
            
            // 保存待上传的对象引用
            let foldersToUpload = Array(pendingFolders)
            let itemsToUpload = Array(pendingItems)
            let usersToUpload = Array(pendingUsers)
            let recordsToDelete = Array(pendingDeletes)
            
            return (operation, foldersToUpload, itemsToUpload, usersToUpload, recordsToDelete)
        }
        .flatMap { result -> AnyPublisher<SyncOperation, Error> in
            // 解构元组
            let (operation, foldersToUpload, itemsToUpload, usersToUpload, recordsToDelete) = result
            
            // 如果没有待上传的项目，直接返回
            if operation.totalItems == 0 {
                return self.updateSyncOperationStatus(operation.id, status: "completed", progress: 1.0)
            }
            
            // 上传文件夹
            return self.uploadFolders(foldersToUpload)
                .flatMap { _ -> AnyPublisher<[CKRecord], Error> in
                    // 上传收藏项
                    return self.uploadFavoriteItems(itemsToUpload)
                }
                .flatMap { _ -> AnyPublisher<[CKRecord], Error> in
                    // 上传用户
                    return self.uploadUsers(usersToUpload)
                }
                .flatMap { _ -> AnyPublisher<[CKRecord.ID], Error> in
                    // 删除记录
                    return self.deleteRecords(recordsToDelete)
                }
                .flatMap { _ -> AnyPublisher<SyncOperation, Error> in
                    // 更新操作状态
                    return self.updateSyncOperationStatus(operation.id, status: "completed", progress: 1.0)
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // 上传文件夹
    private func uploadFolders(_ folders: [Folder]) -> AnyPublisher<[CKRecord], Error> {
        guard !folders.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return Future<[CKRecord], Error> { promise in
            var uploadedRecords: [CKRecord] = []
            var remainingFolders = folders.count
            
            for folder in folders {
                // 创建CloudKit记录
                let record = CKRecord(recordType: "Folder", recordID: CKRecord.ID(recordName: folder.id))
                record["name"] = folder.name as CKRecordValue
                record["lastModified"] = folder.lastModified as CKRecordValue
                record["isDefault"] = folder.isDefault as CKRecordValue
                
                // 上传记录
                self.cloudKitService.saveRecord(record)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { savedRecord in
                            uploadedRecords.append(savedRecord)
                            
                            // 更新本地同步状态
                            self.realmManager.writeAsync { realm in
                                if let localFolder = realm.object(ofType: Folder.self, forPrimaryKey: folder.id) {
                                    localFolder.syncStatus = SyncStatusType.synced.rawValue
                                }
                                
                                // 创建或更新同步记录
                                let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: folder.id) ?? SyncRecord()
                                syncRecord.id = folder.id
                                syncRecord.recordType = "folder"
                                syncRecord.lastSynced = Date()
                                syncRecord.cloudKitRecordID = savedRecord.recordID.recordName
                                syncRecord.cloudKitRecordChangeTag = savedRecord.recordChangeTag
                                syncRecord.deleted = false
                                
                                if realm.object(ofType: SyncRecord.self, forPrimaryKey: folder.id) == nil {
                                    realm.add(syncRecord)
                                }
                                
                                return true
                            }
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: { _ in
                                    remainingFolders -= 1
                                    if remainingFolders == 0 {
                                        promise(.success(uploadedRecords))
                                    }
                                }
                            )
                            .store(in: &self.syncCancellables)
                        }
                    )
                    .store(in: &self.syncCancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 上传收藏项
    private func uploadFavoriteItems(_ items: [FavoriteItem]) -> AnyPublisher<[CKRecord], Error> {
        guard !items.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return Future<[CKRecord], Error> { promise in
            var uploadedRecords: [CKRecord] = []
            var remainingItems = items.count
            
            for item in items {
                // 创建CloudKit记录
                let record = CKRecord(recordType: "FavoriteItem", recordID: CKRecord.ID(recordName: item.id))
                record["word"] = item.word as CKRecordValue
                record["reading"] = item.reading as CKRecordValue
                record["meaning"] = item.meaning as CKRecordValue
                if let note = item.note {
                    record["note"] = note as CKRecordValue
                }
                record["lastModified"] = item.lastModified as CKRecordValue
                
                // 设置文件夹引用
                if let folder = item.folderObject {
                    let folderReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: folder.id), action: .deleteSelf)
                    record["folder"] = folderReference
                }
                
                // 上传记录
                self.cloudKitService.saveRecord(record)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { savedRecord in
                            uploadedRecords.append(savedRecord)
                            
                            // 更新本地同步状态
                            self.realmManager.writeAsync { realm in
                                if let localItem = realm.object(ofType: FavoriteItem.self, forPrimaryKey: item.id) {
                                    localItem.syncStatus = SyncStatusType.synced.rawValue
                                }
                                
                                // 创建或更新同步记录
                                let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: item.id) ?? SyncRecord()
                                syncRecord.id = item.id
                                syncRecord.recordType = "favorite"
                                syncRecord.lastSynced = Date()
                                syncRecord.cloudKitRecordID = savedRecord.recordID.recordName
                                syncRecord.cloudKitRecordChangeTag = savedRecord.recordChangeTag
                                syncRecord.deleted = false
                                
                                if realm.object(ofType: SyncRecord.self, forPrimaryKey: item.id) == nil {
                                    realm.add(syncRecord)
                                }
                                
                                return true
                            }
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: { _ in
                                    remainingItems -= 1
                                    if remainingItems == 0 {
                                        promise(.success(uploadedRecords))
                                    }
                                }
                            )
                            .store(in: &self.syncCancellables)
                        }
                    )
                    .store(in: &self.syncCancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 上传用户
    private func uploadUsers(_ users: [User]) -> AnyPublisher<[CKRecord], Error> {
        guard !users.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return Future<[CKRecord], Error> { promise in
            var uploadedRecords: [CKRecord] = []
            var remainingUsers = users.count
            
            for user in users {
                // 创建CloudKit记录
                let record = CKRecord(recordType: "User", recordID: CKRecord.ID(recordName: user.id))
                if let nickname = user.nickname {
                    record["nickname"] = nickname as CKRecordValue
                }
                if let email = user.email {
                    record["email"] = email as CKRecordValue
                }
                if let lastSyncTime = user.lastSyncTime {
                    record["lastSyncTime"] = lastSyncTime as CKRecordValue
                }
                
                // 序列化设置
                if let settings = user.settings {
                    let settingsDict: [String: Any] = [
                        "darkMode": settings.darkMode,
                        "fontSize": settings.fontSize,
                        "autoSync": settings.autoSync,
                        "notificationsEnabled": settings.notificationsEnabled,
                        "syncFrequency": settings.syncFrequency
                    ]
                    
                    if let settingsData = try? JSONSerialization.data(withJSONObject: settingsDict, options: []) {
                        record["settings"] = settingsData as CKRecordValue
                    }
                }
                
                // 上传记录
                self.cloudKitService.saveRecord(record)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { savedRecord in
                            uploadedRecords.append(savedRecord)
                            
                            // 更新本地同步状态
                            self.realmManager.writeAsync { realm in
                                if let localUser = realm.object(ofType: User.self, forPrimaryKey: user.id) {
                                    localUser.syncStatus = SyncStatusType.synced.rawValue
                                }
                                
                                // 创建或更新同步记录
                                let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: user.id) ?? SyncRecord()
                                syncRecord.id = user.id
                                syncRecord.recordType = "user"
                                syncRecord.lastSynced = Date()
                                syncRecord.cloudKitRecordID = savedRecord.recordID.recordName
                                syncRecord.cloudKitRecordChangeTag = savedRecord.recordChangeTag
                                syncRecord.deleted = false
                                
                                if realm.object(ofType: SyncRecord.self, forPrimaryKey: user.id) == nil {
                                    realm.add(syncRecord)
                                }
                                
                                return true
                            }
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: { _ in
                                    remainingUsers -= 1
                                    if remainingUsers == 0 {
                                        promise(.success(uploadedRecords))
                                    }
                                }
                            )
                            .store(in: &self.syncCancellables)
                        }
                    )
                    .store(in: &self.syncCancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 删除记录
    private func deleteRecords(_ records: [SyncRecord]) -> AnyPublisher<[CKRecord.ID], Error> {
        guard !records.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return Future<[CKRecord.ID], Error> { promise in
            var deletedRecordIDs: [CKRecord.ID] = []
            var remainingRecords = records.count
            
            for record in records {
                guard let cloudKitRecordID = record.cloudKitRecordID else {
                    remainingRecords -= 1
                    if remainingRecords == 0 {
                        promise(.success(deletedRecordIDs))
                    }
                    continue
                }
                
                let recordID = CKRecord.ID(recordName: cloudKitRecordID)
                
                // 删除CloudKit记录
                self.cloudKitService.deleteRecord(recordID: recordID)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { _ in
                            deletedRecordIDs.append(recordID)
                            
                            // 删除本地同步记录
                            self.realmManager.writeAsync { realm in
                                if let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: record.id) {
                                    realm.delete(syncRecord)
                                }
                                return true
                            }
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: { _ in
                                    remainingRecords -= 1
                                    if remainingRecords == 0 {
                                        promise(.success(deletedRecordIDs))
                                    }
                                }
                            )
                            .store(in: &self.syncCancellables)
                        }
                    )
                    .store(in: &self.syncCancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 下载远程更改
    private func downloadRemoteChanges(_ operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            // 获取上次同步令牌
            self.getServerChangeToken()
                .flatMap { token -> AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), Error> in
                    // 获取文件夹变更
                    return self.cloudKitService.fetchChanges(recordType: "Folder", since: token)
                }
                .flatMap { result -> AnyPublisher<SyncOperation, Error> in
                    // 处理文件夹变更
                    return self.processDownloadedRecords(result.records, deletedRecordIDs: result.deletedRecordIDs, token: result.token, operation: operation)
                }
                .flatMap { operation -> Publishers.FlatMap<AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), any Error>, AnyPublisher<CKServerChangeToken?, any Error>> in
                    // 获取收藏项变更
                    return self.getServerChangeToken()
                        .flatMap { token -> AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), Error> in
                            return self.cloudKitService.fetchChanges(recordType: "FavoriteItem", since: token)
                        }
                }
                .flatMap { result -> AnyPublisher<SyncOperation, Error> in
                    // 处理收藏项变更
                    return self.processDownloadedRecords(result.records, deletedRecordIDs: result.deletedRecordIDs, token: result.token, operation: operation)
                }
                .flatMap { operation -> Publishers.FlatMap<AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), any Error>, AnyPublisher<CKServerChangeToken?, any Error>> in
                    // 获取用户变更
                    return self.getServerChangeToken()
                        .flatMap { token -> AnyPublisher<(records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?), Error> in
                            return self.cloudKitService.fetchChanges(recordType: "User", since: token)
                        }
                }
                .flatMap { result -> AnyPublisher<SyncOperation, Error> in
                    // 处理用户变更
                    return self.processDownloadedRecords(result.records, deletedRecordIDs: result.deletedRecordIDs, token: result.token, operation: operation)
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { operation in
                        // 更新操作状态
                        self.updateSyncOperationStatus(operation.id, status: "completed", progress: 1.0)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { updatedOperation in
                                    promise(.success(updatedOperation))
                                }
                            )
                            .store(in: &self.syncCancellables)
                    }
                )
                .store(in: &self.syncCancellables)
        }.eraseToAnyPublisher()
    }
    
    // 处理下载的记录
    private func processDownloadedRecords(_ records: [CKRecord], deletedRecordIDs: [CKRecord.ID], token: CKServerChangeToken?, operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            // 更新操作信息
            self.updateSyncOperationStatus(operation.id, totalItems: operation.totalItems + records.count + deletedRecordIDs.count)
                .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                    // 处理新增和更新的记录
                    return self.processUpdatedRecords(records, operation: operation)
                }
                .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                    // 处理删除的记录
                    return self.processDeletedRecords(deletedRecordIDs, operation: operation)
                }
                .flatMap { operation -> AnyPublisher<SyncOperation, Error> in
                    // 保存服务器变更令牌
                    if let token = token {
                        return self.saveServerChangeToken(token)
                            .map { _ in operation }
                            .eraseToAnyPublisher()
                    } else {
                        return Just(operation).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                }
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { operation in
                        promise(.success(operation))
                    }
                )
                .store(in: &self.syncCancellables)
        }.eraseToAnyPublisher()
    }
    
    // 处理更新的记录
    private func processUpdatedRecords(_ records: [CKRecord], operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        guard !records.isEmpty else {
            return Just(operation).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return realmManager.writeAsync { realm in
            var processedCount = 0
            
            for record in records {
                // 根据记录类型处理
                switch record.recordType {
                case "Folder":
                    self.processFolder(record, realm: realm)
                case "FavoriteItem":
                    self.processFavoriteItem(record, realm: realm)
                case "User":
                    self.processUser(record, realm: realm)
                default:
                    break
                }
                
                processedCount += 1
                
                // 更新进度
                if let op = realm.object(ofType: SyncOperation.self, forPrimaryKey: operation.id) {
                    op.itemsProcessed += 1
                    op.progress = Double(op.itemsProcessed) / Double(op.totalItems)
                }
            }
            
            return realm.object(ofType: SyncOperation.self, forPrimaryKey: operation.id) ?? operation
        }
    }
    
    // 处理删除的记录
    private func processDeletedRecords(_ recordIDs: [CKRecord.ID], operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        guard !recordIDs.isEmpty else {
            return Just(operation).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        return realmManager.writeAsync { realm in
            var processedCount = 0
            
            for recordID in recordIDs {
                // 查找对应的同步记录
                let syncRecords = realm.objects(SyncRecord.self).filter("cloudKitRecordID = %@", recordID.recordName)
                
                for syncRecord in syncRecords {
                    // 根据记录类型删除对应的本地对象
                    switch syncRecord.recordType {
                    case "folder":
                        if let folder = realm.object(ofType: Folder.self, forPrimaryKey: syncRecord.id) {
                            realm.delete(folder)
                        }
                    case "favorite":
                        if let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: syncRecord.id) {
                            realm.delete(item)
                        }
                    case "user":
                        if let user = realm.object(ofType: User.self, forPrimaryKey: syncRecord.id) {
                            realm.delete(user)
                        }
                    default:
                        break
                    }
                    
                    // 删除同步记录
                    realm.delete(syncRecord)
                }
                
                processedCount += 1
                
                // 更新进度
                if let op = realm.object(ofType: SyncOperation.self, forPrimaryKey: operation.id) {
                    op.itemsProcessed += 1
                    op.progress = Double(op.itemsProcessed) / Double(op.totalItems)
                }
            }
            
            return realm.object(ofType: SyncOperation.self, forPrimaryKey: operation.id) ?? operation
        }
    }
    
    // 处理文件夹记录
    private func processFolder(_ record: CKRecord, realm: Realm) {
        let recordID = record.recordID.recordName
        
        // 检查是否已存在
        if let existingFolder = realm.object(ofType: Folder.self, forPrimaryKey: recordID) {
            // 更新本地记录
            if let name = record["name"] as? String {
                existingFolder.name = name
            }
            
            if let lastModified = record["lastModified"] as? Date {
                existingFolder.lastModified = lastModified
            }
            
            if let isDefault = record["isDefault"] as? Bool {
                existingFolder.isDefault = isDefault
            }
            
            existingFolder.syncStatus = SyncStatusType.synced.rawValue
        } else {
            // 创建新文件夹
            let folder = self.cloudKitService.createFolder(from: record)
            realm.add(folder)
        }
        
        // 更新同步记录
        let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) ?? SyncRecord()
        syncRecord.id = recordID
        syncRecord.recordType = "folder"
        syncRecord.lastSynced = Date()
        syncRecord.cloudKitRecordID = record.recordID.recordName
        syncRecord.cloudKitRecordChangeTag = record.recordChangeTag
        syncRecord.deleted = false
        
        if realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) == nil {
            realm.add(syncRecord)
        }
    }
    
    // 处理收藏项记录
    private func processFavoriteItem(_ record: CKRecord, realm: Realm) {
        let recordID = record.recordID.recordName
        
        // 检查是否已存在
        if let existingItem = realm.object(ofType: FavoriteItem.self, forPrimaryKey: recordID) {
            // 更新本地记录
            if let word = record["word"] as? String {
                existingItem.word = word
            }
            
            if let reading = record["reading"] as? String {
                existingItem.reading = reading
            }
            
            if let meaning = record["meaning"] as? String {
                existingItem.meaning = meaning
            }
            
            if let note = record["note"] as? String {
                existingItem.note = note
            }
            
            if let lastModified = record["lastModified"] as? Date {
                existingItem.lastModified = lastModified
            }
            
            existingItem.syncStatus = SyncStatusType.synced.rawValue
        } else {
            // 创建新收藏项
            let item = self.cloudKitService.createFavoriteItem(from: record)
            
            // 处理文件夹关系
            if let folderReference = record["folder"] as? CKRecord.Reference {
                let folderID = folderReference.recordID.recordName
                if let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderID) {
                    folder.items.append(item)
                }
            }
            
            realm.add(item)
        }
        
        // 更新同步记录
        let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) ?? SyncRecord()
        syncRecord.id = recordID
        syncRecord.recordType = "favorite"
        syncRecord.lastSynced = Date()
        syncRecord.cloudKitRecordID = record.recordID.recordName
        syncRecord.cloudKitRecordChangeTag = record.recordChangeTag
        syncRecord.deleted = false
        
        if realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) == nil {
            realm.add(syncRecord)
        }
    }
    
    // 处理用户记录
    private func processUser(_ record: CKRecord, realm: Realm) {
        let recordID = record.recordID.recordName
        
        // 检查是否已存在
        if let existingUser = realm.object(ofType: User.self, forPrimaryKey: recordID) {
            // 更新本地记录
            if let nickname = record["nickname"] as? String {
                existingUser.nickname = nickname
            }
            
            if let email = record["email"] as? String {
                existingUser.email = email
            }
            
            if let lastSyncTime = record["lastSyncTime"] as? Date {
                existingUser.lastSyncTime = lastSyncTime
            }
            
            // 处理设置
            if let settingsData = record["settings"] as? Data,
               let settingsDict = try? JSONSerialization.jsonObject(with: settingsData, options: []) as? [String: Any],
               let settings = existingUser.settings {
                
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
            
            existingUser.syncStatus = SyncStatusType.synced.rawValue
        } else {
            // 创建新用户
            let user = self.cloudKitService.createUser(from: record)
            realm.add(user)
        }
        
        // 更新同步记录
        let syncRecord = realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) ?? SyncRecord()
        syncRecord.id = recordID
        syncRecord.recordType = "user"
        syncRecord.lastSynced = Date()
        syncRecord.cloudKitRecordID = record.recordID.recordName
        syncRecord.cloudKitRecordChangeTag = record.recordChangeTag
        syncRecord.deleted = false
        
        if realm.object(ofType: SyncRecord.self, forPrimaryKey: recordID) == nil {
            realm.add(syncRecord)
        }
    }
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncOperation, Error> {
        return Future<SyncOperation, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                
                if let operation = realm.object(ofType: SyncOperation.self, forPrimaryKey: operationId) {
                    promise(.success(operation))
                } else {
                    promise(.failure(NSError(domain: "SyncRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "同步操作不存在"])))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            if let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status") {
                syncStatus.autoSyncEnabled = enabled
            } else {
                let newStatus = SyncStatus()
                newStatus.autoSyncEnabled = enabled
                realm.add(newStatus)
            }
            return enabled
        }
    }

    // 更新同步操作状态
    private func updateSyncOperationStatus(_ operationId: String, status: String? = nil, progress: Double? = nil, errorMessage: String? = nil, totalItems: Int? = nil) -> AnyPublisher<SyncOperation, Error> {
        return realmManager.writeAsync { realm in
            guard let operation = realm.object(ofType: SyncOperation.self, forPrimaryKey: operationId) else {
                throw NSError(domain: "SyncRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "同步操作不存在"])
            }
            
            if let status = status {
                operation.status = status
            }
            
            if let progress = progress {
                operation.progress = progress
            }
            
            if let errorMessage = errorMessage {
                operation.errorMessage = errorMessage
            }
            
            if let totalItems = totalItems {
                operation.totalItems = totalItems
            }
            
            if status == "completed" || status == "failed" {
                operation.endTime = Date()
            }
            
            return operation
        }
    }
    
    // 更新同步进度
    private func updateSyncProgress(_ operation: SyncOperation, processed: Int, total: Int) {
        do {
            let realm = try realmManager.realm()
            try realm.write {
                if let op = realm.object(ofType: SyncOperation.self, forPrimaryKey: operation.id) {
                    op.itemsProcessed = processed
                    op.progress = Double(processed) / Double(total)
                }
            }
            
            // 发布进度更新
            syncProgressSubject.send(operation)
        } catch {
            print("更新同步进度失败: \(error.localizedDescription)")
        }
    }
    
    // 获取服务器变更令牌
    private func getServerChangeToken() -> AnyPublisher<CKServerChangeToken?, Error> {
        return Future<CKServerChangeToken?, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                
                if let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status"),
                   let tokenData = syncStatus.serverChangeTokenData,
                   let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData) {
                    promise(.success(token))
                } else {
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 保存服务器变更令牌
    private func saveServerChangeToken(_ token: CKServerChangeToken) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            do {
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                
                if let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status") {
                    syncStatus.serverChangeTokenData = tokenData
                } else {
                    let newStatus = SyncStatus()
                    newStatus.serverChangeTokenData = tokenData
                    realm.add(newStatus)
                }
                
                return true
            } catch {
                throw error
            }
        }
    }
    
    // 更新同步状态
    private func updateSyncStatus(_ operation: SyncOperation) -> AnyPublisher<SyncOperation, Error> {
        return realmManager.writeAsync { realm in
            // 更新用户的最后同步时间
            if let user = realm.objects(User.self).first {
                user.lastSyncTime = Date()
            }
            
            // 更新同步状态
            if let syncStatus = realm.object(ofType: SyncStatus.self, forPrimaryKey: "sync_status") {
                syncStatus.lastSyncTime = Date()
                syncStatus.currentOperation = nil
            } else {
                let newStatus = SyncStatus()
                newStatus.lastSyncTime = Date()
                realm.add(newStatus)
            }
            
            return operation
        }
    }
}
