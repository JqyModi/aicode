import Foundation

// MARK: - 同步模块业务层模型

// 同步状态业务模型
struct SyncStatusDomain {
    let lastSyncTime: Date?
    let isCloudKitAvailable: Bool
    let isAutoSyncEnabled: Bool
    let currentOperation: SyncOperationDomain?
    let lastOperation: SyncOperationDomain?
    
    // 转换为数据层模型
    func toData() -> DBSyncStatus {
        let dbStatus = DBSyncStatus()
        dbStatus.lastSyncTime = self.lastSyncTime
        dbStatus.cloudKitAvailable = self.isCloudKitAvailable
        dbStatus.autoSyncEnabled = self.isAutoSyncEnabled
        
        if let currentOp = self.currentOperation {
            dbStatus.currentOperation = currentOp.toData()
        }
        
        if let lastOp = self.lastOperation {
            dbStatus.lastOperation = lastOp.toData()
        }
        
        return dbStatus
    }
    
    // 转换为表现层模型
    func toUI() -> SyncStatusInfoUI {
        return SyncStatusInfoUI(
            lastSyncTime: self.lastSyncTime,
            isCloudKitAvailable: self.isCloudKitAvailable,
            isAutoSyncEnabled: self.isAutoSyncEnabled,
            currentOperation: self.currentOperation?.toUI()
        )
    }
}

// 同步操作业务模型
struct SyncOperationDomain {
    let id: String
    let type: String
    let status: String
    let startTime: Date
    let endTime: Date?
    let progress: Double
    let itemsProcessed: Int
    let totalItems: Int
    let errorMessage: String?
    
    // 转换为数据层模型
    func toData() -> DBSyncOperation {
        let dbOperation = DBSyncOperation()
        dbOperation.id = self.id
        dbOperation.type = self.type
        dbOperation.status = self.status
        dbOperation.startTime = self.startTime
        dbOperation.endTime = self.endTime
        dbOperation.progress = self.progress
        dbOperation.itemsProcessed = self.itemsProcessed
        dbOperation.totalItems = self.totalItems
        dbOperation.errorMessage = self.errorMessage
        return dbOperation
    }
    
    // 转换为表现层模型
    func toUI() -> SyncOperationInfoUI {
        return SyncOperationInfoUI(
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

// 同步记录业务模型
struct SyncRecordDomain {
    let id: String
    let recordType: String
    let lastSynced: Date
    let cloudKitRecordID: String?
    let cloudKitRecordChangeTag: String?
    let deleted: Bool
    
    // 转换为数据层模型
    func toData() -> DBSyncRecord {
        let dbRecord = DBSyncRecord()
        dbRecord.id = self.id
        dbRecord.recordType = self.recordType
        dbRecord.lastSynced = self.lastSynced
        dbRecord.cloudKitRecordID = self.cloudKitRecordID
        dbRecord.cloudKitRecordChangeTag = self.cloudKitRecordChangeTag
        dbRecord.deleted = self.deleted
        return dbRecord
    }
}

// 同步冲突业务模型
struct SyncConflictDomain {
    let id: String
    let recordId: String
    let recordType: String
    let localData: Data?
    let remoteData: Data?
    let localModified: Date
    let remoteModified: Date
    let resolved: Bool
    let resolutionType: String?
    
    // 转换为数据层模型
    func toData() -> DBSyncConflict {
        let dbConflict = DBSyncConflict()
        dbConflict.id = self.id
        dbConflict.recordId = self.recordId
        dbConflict.recordType = self.recordType
        dbConflict.localData = self.localData
        dbConflict.remoteData = self.remoteData
        dbConflict.localModified = self.localModified
        dbConflict.remoteModified = self.remoteModified
        dbConflict.resolved = self.resolved
        dbConflict.resolutionType = self.resolutionType
        return dbConflict
    }
}

// 同步错误类型
enum SyncError: Error {
    case repositoryError(Error)
    case notAvailable
    case operationInProgress
    case operationNotFound
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .repositoryError(let error):
            return "仓库错误: \(error.localizedDescription)"
        case .notAvailable:
            return "同步服务不可用"
        case .operationInProgress:
            return "同步操作正在进行中"
        case .operationNotFound:
            return "未找到同步操作"
        case .unknown:
            return "未知错误"
        }
    }
}