import Foundation
import RealmSwift

// MARK: - 同步模块数据模型

// 同步状态
class DBSyncStatus: Object {
    @Persisted(primaryKey: true) var id: String = "sync_status"
    @Persisted var lastSyncTime: Date?
    @Persisted var cloudKitAvailable: Bool = false
    @Persisted var autoSyncEnabled: Bool = true
    @Persisted var serverChangeTokenData: Data?
    @Persisted var currentOperation: DBSyncOperation?
    @Persisted var lastOperation: DBSyncOperation?
    
    // 转换为领域模型
    func toDomain() -> SyncStatusDomain {
        return SyncStatusDomain(
            lastSyncTime: self.lastSyncTime,
            isCloudKitAvailable: self.cloudKitAvailable,
            isAutoSyncEnabled: self.autoSyncEnabled,
            currentOperation: self.currentOperation?.toDomain(),
            lastOperation: self.lastOperation?.toDomain()
        )
    }
}

// 同步操作
class DBSyncOperation: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var type: String = "full"
    @Persisted var status: String = "pending"
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date?
    @Persisted var progress: Double = 0.0
    @Persisted var itemsProcessed: Int = 0
    @Persisted var totalItems: Int = 0
    @Persisted var errorMessage: String?
    
    // 转换为领域模型
    func toDomain() -> SyncOperationDomain {
        return SyncOperationDomain(
            id: self.id,
            type: self.type,
            status: self.status,
            startTime: self.startTime,
            endTime: self.endTime,
            progress: self.progress,
            itemsProcessed: self.itemsProcessed,
            totalItems: self.totalItems,
            errorMessage: self.errorMessage
        )
    }
}

// 同步记录
class DBSyncRecord: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var recordType: String = ""
    @Persisted var lastSynced: Date = Date()
    @Persisted var cloudKitRecordID: String?
    @Persisted var cloudKitRecordChangeTag: String?
    @Persisted var deleted: Bool = false
    
    // 转换为领域模型
    func toDomain() -> SyncRecordDomain {
        return SyncRecordDomain(
            id: self.id,
            recordType: self.recordType,
            lastSynced: self.lastSynced,
            cloudKitRecordID: self.cloudKitRecordID,
            cloudKitRecordChangeTag: self.cloudKitRecordChangeTag,
            deleted: self.deleted
        )
    }
}

// 同步冲突
class DBSyncConflict: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var recordId: String = ""
    @Persisted var recordType: String = ""
    @Persisted var localData: Data?
    @Persisted var remoteData: Data?
    @Persisted var localModified: Date = Date()
    @Persisted var remoteModified: Date = Date()
    @Persisted var resolved: Bool = false
    @Persisted var resolutionType: String?
    
    // 转换为领域模型
    func toDomain() -> SyncConflictDomain {
        return SyncConflictDomain(
            id: self.id,
            recordId: self.recordId,
            recordType: self.recordType,
            localData: self.localData,
            remoteData: self.remoteData,
            localModified: self.localModified,
            remoteModified: self.remoteModified,
            resolved: self.resolved,
            resolutionType: self.resolutionType
        )
    }
}