//
//  ModelConverter.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation

// MARK: - 数据转换工具
class ModelConverter {
    
    // MARK: - 数据层到业务层的转换
    
    // DictEntry -> DictEntryDomain
    static func toDomain(from entry: DictEntry) -> DictEntryDomain {
        return DictEntryDomain(
            id: entry.id,
            word: entry.word,
            reading: entry.reading,
            partOfSpeech: entry.partOfSpeech,
            definitions: entry.definitions.map { toDomain(from: $0) },
            examples: entry.examples.map { toDomain(from: $0) }
        )
    }
    
    // Definition -> DefinitionDomain
    static func toDomain(from definition: Definition) -> DefinitionDomain {
        return DefinitionDomain(
            meaning: definition.meaning,
            notes: definition.notes
        )
    }
    
    // Example -> ExampleDomain
    static func toDomain(from example: Example) -> ExampleDomain {
        return ExampleDomain(
            sentence: example.sentence,
            translation: example.translation
        )
    }
    
    // User -> UserDomain
    static func toDomain(from user: User) -> UserDomain {
        return UserDomain(
            id: user.id,
            nickname: user.nickname,
            settings: toDomain(from: user.settings ?? UserSettings()),
            lastSyncTime: user.lastSyncTime
        )
    }
    
    // UserSettings -> UserSettingsDomain
    static func toDomain(from settings: UserSettings) -> UserSettingsDomain {
        return UserSettingsDomain(
            darkMode: settings.darkMode,
            fontSize: settings.fontSize,
            autoSync: settings.autoSync
        )
    }
    
    // Folder -> FolderDomain
    static func toDomain(from folder: Folder, items: [FavoriteItem] = []) -> FolderDomain {
        return FolderDomain(
            id: folder.id,
            name: folder.name,
            createdAt: folder.createdAt,
            items: items.map { toDomain(from: $0) },
            syncStatus: folder.syncStatus
        )
    }
    
    // FavoriteItem -> FavoriteItemDomain
    static func toDomain(from item: FavoriteItem) -> FavoriteItemDomain {
        return FavoriteItemDomain(
            id: item.id,
            wordId: item.wordId,
            word: item.word,
            reading: item.reading,
            meaning: item.meaning,
            note: item.note,
            addedAt: item.addedAt,
            syncStatus: item.syncStatus
        )
    }
    
    // MARK: - 同步模型转换
    
    // 将SyncOperation转换为领域模型SyncOperationDomain
    static func toDomain(from operation: SyncOperation) -> SyncOperationDomain {
        return SyncOperationDomain(
            id: operation.id,
            type: operation.type,
            startedAt: operation.startedAt,
            completedAt: operation.completedAt,
            status: operation.status
        )
    }
    
    // 将SyncProgress转换为领域模型SyncProgressDomain
    static func toDomain(from progress: SyncProgress) -> SyncProgressDomain {
        return SyncProgressDomain(
            operationId: progress.operationId,
            progress: progress.progress,
            itemsSynced: progress.itemsSynced,
            totalItems: progress.totalItems,
            estimatedTimeRemaining: progress.estimatedTimeRemaining
        )
    }
    
    // 将SyncConflict转换为领域模型SyncConflictDomain
    static func toDomain(from conflict: SyncConflict) -> SyncConflictDomain {
        return SyncConflictDomain(
            id: conflict.id,
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            localData: conflict.localData,
            remoteData: conflict.remoteData,
            detectedAt: conflict.detectedAt,
            resolved: conflict.resolved
        )
    }
    
    // MARK: - 业务层到表现层的转换
    
    // DictEntryDomain -> WordDetails
    static func toWordDetails(from domain: DictEntryDomain, isFavorited: Bool) -> WordDetails {
        return WordDetails(
            id: domain.id,
            word: domain.word,
            reading: domain.reading,
            partOfSpeech: domain.partOfSpeech,
            definitions: domain.definitions.map { 
                UIDefinition(meaning: $0.meaning, notes: $0.notes) 
            },
            examples: domain.examples.map { 
                UIExample(sentence: $0.sentence, translation: $0.translation) 
            },
            relatedWords: [], // 需要另外填充
            isFavorited: isFavorited
        )
    }
    
    // DictEntryDomain -> WordSummary
    static func toWordSummary(from domain: DictEntryDomain) -> WordSummary {
        return WordSummary(
            id: domain.id,
            word: domain.word,
            reading: domain.reading,
            partOfSpeech: domain.partOfSpeech,
            briefMeaning: domain.definitions.first?.meaning ?? ""
        )
    }
    
    // FolderDomain -> FolderSummary
    static func toFolderSummary(from domain: FolderDomain, itemCount: Int = 0) -> FolderSummary {
        return FolderSummary(
            id: domain.id,
            name: domain.name,
            createdAt: domain.createdAt,
            itemCount: itemCount > 0 ? itemCount : domain.items.count,
            syncStatus: UISyncStatus(rawValue: domain.syncStatus) ?? .synced
        )
    }
    
    // FavoriteItemDomain -> FavoriteItemDetail
    static func toFavoriteItemDetail(from domain: FavoriteItemDomain) -> FavoriteItemDetail {
        return FavoriteItemDetail(
            id: domain.id,
            wordId: domain.wordId,
            word: domain.word,
            reading: domain.reading,
            meaning: domain.meaning,
            note: domain.note,
            addedAt: domain.addedAt,
            syncStatus: UISyncStatus(rawValue: domain.syncStatus) ?? .synced
        )
    }
    
    // UserDomain -> UserProfile
    static func toUserProfile(from domain: UserDomain, favoriteCount: Int, folderCount: Int) -> UserProfile {
        return UserProfile(
            userId: domain.id,
            nickname: domain.nickname,
            settings: UserPreferences(
                darkMode: domain.settings.darkMode,
                fontSize: domain.settings.fontSize,
                autoSync: domain.settings.autoSync
            ),
            lastSyncTime: domain.lastSyncTime,
            favoriteCount: favoriteCount,
            folderCount: folderCount
        )
    }
    
    // 将SyncOperationDomain转换为SyncOperationInfo
    static func toSyncOperationInfo(from domain: SyncOperationDomain) -> SyncOperationInfo {
        return SyncOperationInfo(
            syncId: domain.id,
            startedAt: domain.startedAt,
            status: domain.status,
            estimatedTimeRemaining: nil
        )
    }
    
    // 将SyncProgressDomain转换为SyncProgressInfo
    static func toSyncProgressInfo(from domain: SyncProgressDomain) -> SyncProgressInfo {
        return SyncProgressInfo(
            syncId: domain.operationId,
            progress: domain.progress,
            status: "in_progress",
            itemsSynced: domain.itemsSynced,
            totalItems: domain.totalItems,
            estimatedTimeRemaining: domain.estimatedTimeRemaining
        )
    }
}