//
//  SyncModels.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import CloudKit
import RealmSwift

// 同步状态枚举
enum SyncStatus: Int, Codable {
    case synced = 0        // 已同步
    case pendingUpload = 1 // 待上传
    case pendingDownload = 2 // 待下载
    case conflict = 3      // 冲突
    case error = 4         // 错误
    
    var description: String {
        switch self {
        case .synced: return "已同步"
        case .pendingUpload: return "待上传"
        case .pendingDownload: return "待下载"
        case .conflict: return "冲突"
        case .error: return "错误"
        }
    }
}

// 同步类型枚举
enum SyncType: Int, Codable {
    case full = 0       // 全量同步
    case favorites = 1  // 仅同步收藏
    case settings = 2   // 仅同步设置
    
    var description: String {
        switch self {
        case .full: return "全量同步"
        case .favorites: return "收藏同步"
        case .settings: return "设置同步"
        }
    }
}

// 冲突解决策略枚举
enum ConflictResolution: Int, Codable {
    case useLocal = 0   // 使用本地版本
    case useRemote = 1  // 使用远程版本
    case merge = 2      // 合并两个版本
    
    var description: String {
        switch self {
        case .useLocal: return "使用本地版本"
        case .useRemote: return "使用远程版本"
        case .merge: return "合并两个版本"
        }
    }
}

// 同步操作模型
class SyncOperation: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var type: Int // SyncType的原始值
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date?
    @Persisted var status: String = "pending" // pending, in_progress, completed, failed
    @Persisted var errorMessage: String?
    @Persisted var itemsToSync: Int = 0
    @Persisted var itemsSynced: Int = 0
    
    convenience init(type: SyncType) {
        self.init()
        self.type = type.rawValue
    }
    
    var syncType: SyncType {
        return SyncType(rawValue: type) ?? .full
    }
    
    var progress: Double {
        guard itemsToSync > 0 else { return 0 }
        return Double(itemsSynced) / Double(itemsToSync)
    }
    
    var estimatedTimeRemaining: Int? {
        guard status == "in_progress" && itemsSynced > 0 && itemsToSync > itemsSynced else {
            return nil
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let timePerItem = elapsedTime / Double(itemsSynced)
        let remainingItems = itemsToSync - itemsSynced
        
        return Int(timePerItem * Double(remainingItems))
    }
}

// 同步进度模型
struct SyncProgress {
    let operationId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
    let errorMessage: String?
    
    init(operation: SyncOperation) {
        self.operationId = operation.id
        self.progress = operation.progress
        self.status = operation.status
        self.itemsSynced = operation.itemsSynced
        self.totalItems = operation.itemsToSync
        self.estimatedTimeRemaining = operation.estimatedTimeRemaining
        self.errorMessage = operation.errorMessage
    }
}

// 同步状态信息模型
struct SyncStatusInfo {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: SyncStatus
    let availableOffline: Bool
    let currentOperation: SyncOperation?
    
    var statusDescription: String {
        return syncStatus.description
    }
}

// 同步冲突模型
class SyncConflict: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var recordType: String // "folder", "favorite", "user"
    @Persisted var recordId: String
    @Persisted var localModificationTime: Date
    @Persisted var remoteModificationTime: Date
    @Persisted var resolved: Bool = false
    @Persisted var resolution: Int? // ConflictResolution的原始值
    @Persisted var localDataJson: String
    @Persisted var remoteDataJson: String
    @Persisted var createdAt: Date = Date()
    
    var conflictResolution: ConflictResolution? {
        guard let res = resolution else { return nil }
        return ConflictResolution(rawValue: res)
    }
}

// 可同步对象协议
protocol SyncableObject {
    var syncStatus: Int { get set }
    var lastModified: Date { get set }
    var cloudKitSystemFields: Data? { get set }
    
    func toCloudKitRecord() -> CKRecord
    static func fromCloudKitRecord(_ record: CKRecord) -> Self?
}

// 同步元数据模型
class SyncMetadata: Object {
    @Persisted(primaryKey: true) var id: String = "sync_metadata"
    @Persisted var lastSyncTime: Date?
    @Persisted var serverChangeToken: Data?
    @Persisted var autoSyncEnabled: Bool = true
    @Persisted var pendingChangesCount: Int = 0
    @Persisted var syncInterval: Int = 3600 // 默认1小时同步一次
    @Persisted var currentOperationId: String?
}

// 记录变更类型
enum RecordChangeType {
    case created
    case updated
    case deleted
}

// 记录变更模型
struct RecordChange {
    let recordType: String
    let recordId: String
    let changeType: RecordChangeType
    let record: CKRecord?
}