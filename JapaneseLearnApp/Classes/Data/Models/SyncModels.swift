//
//  SyncModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import RealmSwift

// MARK: - 同步操作
class SyncOperation: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var type: Int = SyncType.full.rawValue
    @objc dynamic var startedAt: Date = Date()
    @objc dynamic var completedAt: Date? = nil
    @objc dynamic var status: String = "pending" // pending, in_progress, completed, failed
    @objc dynamic var error: String? = nil
    @objc dynamic var userId: String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 同步进度
class SyncProgress: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var operationId: String = ""
    @objc dynamic var progress: Double = 0.0
    @objc dynamic var itemsSynced: Int = 0
    @objc dynamic var totalItems: Int = 0
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var estimatedTimeRemaining: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 同步冲突
class SyncConflict: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var entityType: String = ""
    @objc dynamic var entityId: String = ""
    @objc dynamic var localData: String = ""
    @objc dynamic var remoteData: String = ""
    @objc dynamic var detectedAt: Date = Date()
    @objc dynamic var resolved: Bool = false
    @objc dynamic var resolution: Int = 0  // 添加这个属性：0: 未解决, 1: 使用本地, 2: 使用远程, 3: 合并
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 同步类型枚举
enum SyncType: Int {
    case full = 0       // 全量同步
    case favorites = 1  // 仅同步收藏
    case settings = 2   // 仅同步设置
}


// MARK: - 同步状态
class SyncStatus: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var pendingChanges: Int = 0
    @objc dynamic var lastSyncTime: Date? = nil
    @objc dynamic var availableOffline: Bool = true
    @objc dynamic var status: String = "synced"
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
