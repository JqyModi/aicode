//
//  ViewModelProtocols.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 搜索视图模型协议
protocol SearchViewModelProtocol: ObservableObject {
    // 输入属性
    var searchQuery: String { get set }
    var searchType: SearchTypeViewModel { get set }
    
    // 输出属性
    var searchResults: [WordSummaryViewModel] { get }
    var searchHistory: [SearchHistoryItemViewModel] { get }
    var suggestions: [String] { get }
    var isSearching: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func search()
    func clearSearch()
    func selectWord(id: String)
    func clearHistory()
    func loadMoreResults()
}

// MARK: - 详情视图模型协议
protocol DetailViewModelProtocol: ObservableObject {
    // 输出属性
    var wordDetails: WordDetailsViewModel? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isFavorited: Bool { get }
    
    // 方法
//    func loadWordDetails(id: String)
    func loadWordDetails()
    func playPronunciation(speed: Float)
    func toggleFavorite()
    func addNote(note: String)
}

// MARK: - 收藏视图模型协议
protocol FavoriteViewModelProtocol: ObservableObject {
    // 输出属性
    var folders: [FolderSummaryViewModel] { get }
    var selectedFolder: FolderSummaryViewModel? { get }
    var folderItems: [FavoriteItemDetailViewModel] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadFolders()
    func createFolder(name: String)
    func renameFolder(id: String, newName: String)
    func deleteFolder(id: String)
    func selectFolder(id: String)
    func loadFolderItems(folderId: String)
    func updateNote(itemId: String, note: String)
    func removeFromFavorites(itemId: String)
    func loadMoreItems()
}

// MARK: - 用户视图模型协议
protocol UserViewModelProtocol: ObservableObject {
    // 输出属性
    var userProfile: UserProfileViewModel? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userSettings: UserPreferencesViewModel { get }
    
    // 方法
    func signInWithApple()
    func signOut()
    func loadUserProfile()
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool)
}


// MARK: - 热门词汇视图模型协议
protocol HotWordViewModelProtocol: ObservableObject {
    var hotWords: [WordCloudWord] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    func loadHotWords()
}

// MARK: - 主页视图模型协议
protocol HomeViewModelProtocol: ObservableObject {
    // 输出属性
    var todayWord: TodayWordViewModel? { get }
    var hotWordsRanking: [HotWordRankingViewModel] { get }
    var featuredWords: [FeaturedWordViewModel] { get }
    var seasonalWords: [SeasonalWordViewModel] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadHomeContent()
    func refreshContent()
    func selectWord(id: String)
    func viewAllHotWords()
    func viewAllFeaturedWords()
}

// MARK: - 推荐视图模型协议
protocol RecommendationViewModelProtocol: ObservableObject {
    // 输出属性
    var personalizedRecommendations: [RecommendedWordViewModel] { get }
    var smartRecommendations: [SmartRecommendationViewModel] { get }
    var recommendationCategories: [RecommendationCategoryViewModel] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadRecommendations()
    func loadSmartRecommendations(basedOn wordId: String)
    func updatePreferences(preferences: RecommendationPreferencesViewModel)
    func dismissRecommendation(id: String)
}

// MARK: - 分类浏览视图模型协议
protocol CategoryBrowseViewModelProtocol: ObservableObject {
    // 输出属性
    var categories: [WordCategoryViewModel] { get }
    var selectedCategory: WordCategoryViewModel? { get }
    var categoryWords: [CategorizedWordViewModel] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadCategories()
    func selectCategory(id: String)
    func loadCategoryWords(categoryId: String)
    func loadMoreWords()
}


// MARK: - 表现层枚举类型
enum SearchTypeViewModel {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

// MARK: - 表现层数据模型
struct WordSummaryViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

struct WordDetailsViewModel: Identifiable {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionViewModel]
    let examples: [ExampleViewModel]
    let relatedWords: [WordSummaryViewModel]
    let isFavorited: Bool
}

struct DefinitionViewModel {
    let meaning: String
    let notes: String?
}

struct ExampleViewModel {
    let sentence: String
    let translation: String
}

struct SearchHistoryItemViewModel: Identifiable {
    let id: String
    let word: String
    let timestamp: Date
}

struct FolderSummaryViewModel: Identifiable {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: String
}

struct FavoriteItemDetailViewModel: Identifiable {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: String
}

struct UserProfileViewModel {
    let userId: String
    let nickname: String?
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferencesViewModel {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}
