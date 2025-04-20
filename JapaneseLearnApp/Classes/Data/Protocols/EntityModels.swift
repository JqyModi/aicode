//
//  EntityModels.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation

// MARK: - 数据层实体模型
// 这些模型是数据层使用的，与业务层的Domain模型相分离

// 词典实体模型
struct DictEntryEntity {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionEntity]
    let examples: [ExampleEntity]
}

struct DefinitionEntity {
    let meaning: String
    let notes: String?
}

struct ExampleEntity {
    let sentence: String
    let translation: String
}

struct SearchHistoryItemEntity {
    let id: String
    let word: String
    let timestamp: Date
}

struct DictionaryVersionEntity {
    let version: String
    let updateDate: Date
    let wordCount: Int
}

// 用户实体模型
struct UserEntity {
    let id: String
    let nickname: String?
    let settings: UserSettingsEntity
    let lastSyncTime: Date?
}

struct UserSettingsEntity {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

// 收藏实体模型
struct FolderEntity {
    let id: String
    let name: String
    let createdAt: Date
    let syncStatus: Int
}

struct FavoriteItemEntity {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: Int
}

// 同步实体模型
struct SyncStatusEntity {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: String
    let availableOffline: Bool
}

struct SyncOperationEntity {
    let syncId: String
    let startedAt: Date
    let status: String
    let estimatedTimeRemaining: Int?
}

struct SyncProgressEntity {
    let syncId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
}