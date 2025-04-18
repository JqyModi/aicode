//
//  DomainModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation

// MARK: - 词典领域模型
struct DictEntryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
}

struct DefinitionDomain {
    let meaning: String
    let notes: String?
}

struct ExampleDomain {
    let sentence: String
    let translation: String
}

// MARK: - 用户领域模型
struct UserDomain {
    let id: String
    let nickname: String?
    let settings: UserSettingsDomain
    let lastSyncTime: Date?
}

struct UserSettingsDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

// MARK: - 收藏领域模型
struct FolderDomain {
    let id: String
    let name: String
    let createdAt: Date
    let items: [FavoriteItemDomain]
    let syncStatus: Int
}

struct FavoriteItemDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: Int
}

// MARK: - 同步领域模型
struct SyncOperationDomain {
    let id: String
    let type: Int
    let startedAt: Date
    let completedAt: Date?
    let status: String
}

struct SyncProgressDomain {
    let operationId: String
    let progress: Double
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int
}

struct SyncConflictDomain {
    let id: String
    let entityType: String
    let entityId: String
    let localData: String
    let remoteData: String
    let detectedAt: Date
    let resolved: Bool
}