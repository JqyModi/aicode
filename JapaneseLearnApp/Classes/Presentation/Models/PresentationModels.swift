//
//  PresentationModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation

// MARK: - 词典表现模型
struct SearchResult {
    let total: Int
    let items: [WordSummary]
}

struct WordSummary {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

struct WordDetails {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [UIDefinition]
    let examples: [UIExample]
    let relatedWords: [WordSummary]
    let isFavorited: Bool
}

struct UIDefinition {
    let meaning: String
    let notes: String?
}

struct UIExample {
    let sentence: String
    let translation: String
}

// MARK: - 收藏表现模型
struct FolderSummary {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: UISyncStatus
}

struct FolderContent {
    let total: Int
    let items: [FavoriteItemDetail]
}

struct FavoriteItemDetail {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: UISyncStatus
}

// MARK: - 用户表现模型
struct UserProfile {
    let userId: String
    let nickname: String?
    let settings: UserPreferences
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferences {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

// MARK: - 同步表现模型
struct SyncStatusInfo {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: String
    let availableOffline: Bool
}

struct SyncOperationInfo {
    let syncId: String
    let startedAt: Date
    let status: String
    let estimatedTimeRemaining: Int?
}

struct SyncProgressInfo {
    let syncId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
}

// MARK: - 同步状态枚举
enum UISyncStatus: Int {
    case synced        // 已同步
    case pendingUpload // 待上传
    case pendingDownload // 待下载
    case conflict      // 冲突
    case error         // 错误
}
