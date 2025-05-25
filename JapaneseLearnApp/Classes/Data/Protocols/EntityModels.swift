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
    let relatedWords: [RelatedWordEntity]
}

struct RelatedWordEntity {
    let id: String
    let word: String
    let reading: String?
    let type: RelatedWordType
}

enum RelatedWordType {
    case synonym    // 同义词
    case paronym    // 近义词
    case polyphonic // 多音词
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
    let itemCount: Int
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

// MARK: - 热词排行榜实体
struct HotWordRankingEntity {
    let rank: Int            // 排名
    let word: String         // 词汇内容
    let frequency: Int       // 热度分数
}

// MARK: - 今日词汇实体
struct TodayWordEntity {
    let date: Date           // 日期
    let word: String         // 今日词汇
    let reading: String?     // 读音
    let meaning: String?     // 释义
    let example: String?     // 例句
    let source: String?      // 来源
}

// MARK: - 季节词汇实体
struct SeasonalWordEntity {
    let season: SeasonType   // 季节类型
    let word: String         // 词汇
    let meaning: String?     // 释义
    let description: String? // 说明
}

// MARK: - 注目词汇实体
struct FeaturedWordEntity {
    let category: FeaturedCategory // 注目类别
    let word: String              // 词汇
    let meaning: String?          // 释义
    let description: String?      // 说明
}

// MARK: - 词汇分类实体
struct WordCategoryEntity {
    let id: String           // 分类ID
    let name: String         // 分类名称
    let description: String? // 分类描述
}

// MARK: - 分类词汇实体
struct CategorizedWordEntity {
    let categoryId: String   // 分类ID
    let word: String         // 词汇
    let meaning: String?     // 释义
}

// MARK: - 主页配置实体
struct HomePageConfigEntity {
    let showSearchBar: Bool
    let showHotWords: Bool
    let showTodayWord: Bool
    let showFeaturedWords: Bool
    let showSeasonalWords: Bool
    let showCategories: Bool
}

// MARK: - 推荐词汇实体
struct RecommendedWordEntity {
    let word: String         // 推荐词汇
    let reason: String?      // 推荐理由
}

// MARK: - 注目类别枚举
/// 注目词汇的类别，如“新词”、“流行语”、“学术词汇”等
enum FeaturedCategory {
    case trending      // 流行
    case newWord      // 新词
    case academic     // 学术
    case slang        // 俚语
    case idiom        // 成语
    case other        // 其他
}

// MARK: - 用户行为实体
/// 用于推荐系统记录用户行为
struct UserBehaviorEntity {
    let userId: String
    let word: String
    let action: UserActionType
    let timestamp: Date
}

// MARK: - 用户行为类型枚举
enum UserActionType {
    case search      // 搜索
    case view       // 查看详情
    case favorite   // 收藏
    case share      // 分享
    case other      // 其他
}