//
//  FavoriteModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import RealmSwift

// MARK: - 收藏夹
class Folder: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var name: String = ""
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var userId: String = ""
    @objc dynamic var syncStatus: Int = SyncStatus.synced.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 收藏项
class FavoriteItem: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var wordId: String = ""
    @objc dynamic var folderId: String = ""
    @objc dynamic var word: String = ""
    @objc dynamic var reading: String = ""
    @objc dynamic var meaning: String = ""
    @objc dynamic var note: String? = nil
    @objc dynamic var addedAt: Date = Date()
    @objc dynamic var updatedAt: Date = Date()
    @objc dynamic var syncStatus: Int = SyncStatus.synced.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 同步状态枚举
enum SyncStatus: Int {
    case synced = 0        // 已同步
    case pendingUpload = 1 // 待上传
    case pendingDownload = 2 // 待下载
    case conflict = 3      // 冲突
    case error = 4         // 错误
}