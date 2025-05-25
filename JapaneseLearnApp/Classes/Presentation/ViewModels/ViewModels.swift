//
//  ViewModels.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import SwiftUI

// MARK: - 主页视图模型

// MARK: - 今日词汇视图模型
struct TodayWordViewModel: Identifiable {
    let id: String
    let date: Date
    let word: String
    let reading: String
    let meaning: String
    let example: String?
    let imageUrl: String?
}

// MARK: - 热词排行榜视图模型
struct HotWordRankingViewModel: Identifiable {
    let id: String
    let rank: Int
    let word: String
    let reading: String?
    let searchCount: Int
    let trend: TrendViewModel
}

// MARK: - 注目词汇视图模型
struct FeaturedWordViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let category: FeaturedCategoryViewModel
    let featuredReason: String
}

// MARK: - 季节词汇视图模型
struct SeasonalWordViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let season: SeasonViewModel
    let relevanceScore: Double
}

// MARK: - 推荐视图模型

// MARK: - 推荐词汇视图模型
struct RecommendedWordViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let reason: String?
    let score: Double
}

// MARK: - 智能推荐视图模型
struct SmartRecommendationViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let relationToSource: String
    let similarityScore: Double
}

// MARK: - 推荐分类视图模型
struct RecommendationCategoryViewModel: Identifiable {
    let id: String
    let name: String
    let description: String?
    let words: [RecommendedWordViewModel]
}

// MARK: - 推荐偏好视图模型
struct RecommendationPreferencesViewModel {
    let enablePersonalization: Bool
    let preferredCategories: [String]
    let difficultyLevel: Int
    let includeNewWords: Bool
    let includeRecentlyViewed: Bool
}

// MARK: - 分类浏览视图模型

// MARK: - 词汇分类视图模型
struct WordCategoryViewModel: Identifiable {
    let id: String
    let name: String
    let description: String?
    let wordCount: Int
    let iconName: String?
}

// MARK: - 分类词汇视图模型
struct CategorizedWordViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let meaning: String
    let categoryId: String
}

// MARK: - 枚举类型

// MARK: - 趋势类型视图模型
enum TrendViewModel {
    case up, down, stable, new
}

// MARK: - 季节类型视图模型
enum SeasonViewModel {
    case spring, summer, autumn, winter
}

// MARK: - 注目类别视图模型
enum FeaturedCategoryViewModel {
    case trending, educational, cultural, business
}