//
//  DomainModels.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation

// MARK: - 业务层数据模型

// MARK: - 主页内容域模型
struct HomePageContentDomain {
    let todayWord: TodayWordDomain?
    let hotWordsRanking: [HotWordRankingDomain]
    let featuredWords: [FeaturedWordDomain]
    let seasonalWords: [SeasonalWordDomain]
    let categories: [WordCategoryDomain]
}

// MARK: - 词汇分类域模型
struct WordCategoryDomain {
    let id: String
    let name: String
    let description: String?
    let wordCount: Int
}

// MARK: - 分类内容域模型
struct CategoryContentDomain {
    let category: WordCategoryDomain
    let words: [CategorizedWordDomain]
    let totalCount: Int
    let hasMore: Bool
}

// MARK: - 分类词汇域模型
struct CategorizedWordDomain {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let categoryId: String
}

// MARK: - 推荐词汇域模型
struct RecommendedWordDomain {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let reason: String?
    let score: Double
}

// MARK: - 智能推荐域模型
struct SmartRecommendationDomain {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let relationToSource: String
    let similarityScore: Double
}

// MARK: - 推荐分类域模型
struct RecommendationCategoryDomain {
    let id: String
    let name: String
    let description: String?
    let words: [RecommendedWordDomain]
}

// MARK: - 推荐偏好域模型
struct RecommendationPreferencesDomain {
    let enablePersonalization: Bool
    let preferredCategories: [String]
    let difficultyLevel: Int
    let includeNewWords: Bool
    let includeRecentlyViewed: Bool
}

// MARK: - 内容分类域模型
struct ContentCategoryDomain {
    let id: String
    let name: String
    let description: String?
    let iconName: String?
    let itemCount: Int
}

// MARK: - 内容过滤域模型
struct ContentFiltersDomain {
    let categories: [String]?
    let difficulty: Int?
    let sortBy: ContentSortOption
    let includeExamples: Bool
}

// MARK: - 内容搜索结果域模型
struct ContentSearchResultDomain {
    let query: String
    let totalResults: Int
    let items: [ContentItemDomain]
    let filters: ContentFiltersDomain
    let hasMore: Bool
}

// MARK: - 内容项域模型
struct ContentItemDomain {
    let id: String
    let title: String
    let description: String?
    let categoryId: String
    let difficulty: Int
    let createdAt: Date
}

// MARK: - 内容排序选项枚举
enum ContentSortOption {
    case relevance
    case newest
    case popularity
    case difficulty
}

// MARK: - 用户行为域模型
struct UserBehaviorDomain {
    let userId: String
    let word: String
    let action: UserActionDomain
    let timestamp: Date
}

// MARK: - 用户行为类型枚举
enum UserActionDomain {
    case view      // 查看词汇
    case search    // 搜索词汇
    case favorite  // 收藏词汇
    case practice  // 练习词汇
    case share     // 分享词汇
}