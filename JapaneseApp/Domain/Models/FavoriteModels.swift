//
//  FavoriteModels.swift
//  JapaneseApp
//
//  Created by Trae AI on 2025/04/07.
//

import Foundation

// MARK: - 错误类型
public enum FavoriteError: Error, LocalizedError {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError(String)
    case syncError(String)
    
    public var errorDescription: String? {
        switch self {
        case .folderNotFound:
            return "收藏夹未找到"
        case .itemNotFound:
            return "收藏项未找到"
        case .duplicateName:
            return "收藏夹名称已存在"
        case .databaseError(let message):
            return "数据库错误: \(message)"
        case .syncError(let message):
            return "同步错误: \(message)"
        }
    }
}

// MARK: - 同步状态
public enum SyncStatus: Int, Codable {
    case synced = 0        // 已同步
    case pendingUpload = 1 // 待上传
    case pendingDownload = 2 // 待下载
    case conflict = 3      // 冲突
    case error = 4         // 错误
    
    public var description: String {
        switch self {
        case .synced: return "已同步"
        case .pendingUpload: return "待上传"
        case .pendingDownload: return "待下载"
        case .conflict: return "同步冲突"
        case .error: return "同步错误"
        }
    }
}

// MARK: - 收藏夹摘要
public struct FolderSummary: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let createdAt: Date
    public let itemCount: Int
    public let syncStatus: SyncStatus
    
    public init(id: String, name: String, createdAt: Date, itemCount: Int, syncStatus: SyncStatus) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.itemCount = itemCount
        self.syncStatus = syncStatus
    }
    
    public static func == (lhs: FolderSummary, rhs: FolderSummary) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 收藏夹内容
public struct FolderContent {
    public let total: Int
    public let items: [FavoriteItemDetail]
    
    public init(total: Int, items: [FavoriteItemDetail]) {
        self.total = total
        self.items = items
    }
}

// MARK: - 收藏项详情
public struct FavoriteItemDetail: Identifiable, Equatable {
    public let id: String
    public let wordId: String
    public let word: String
    public let reading: String
    public let meaning: String
    public let note: String?
    public let addedAt: Date
    public let syncStatus: SyncStatus
    
    public init(id: String, wordId: String, word: String, reading: String, meaning: String, note: String?, addedAt: Date, syncStatus: SyncStatus) {
        self.id = id
        self.wordId = wordId
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.note = note
        self.addedAt = addedAt
        self.syncStatus = syncStatus
    }
    
    public static func == (lhs: FavoriteItemDetail, rhs: FavoriteItemDetail) -> Bool {
        return lhs.id == rhs.id
    }
}