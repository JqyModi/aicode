//
//  ViewModelProtocols.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import SwiftUI
import Combine

// MARK: - 搜索视图模型协议
protocol SearchViewModelProtocol: ObservableObject {
    // 输入属性
    var searchQuery: String { get set }
    var searchType: SearchType { get set }
    
    // 输出属性
    var searchResults: [WordSummary] { get }
    var searchHistory: [SearchHistoryItem] { get }
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
    var wordDetails: WordDetails? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isFavorited: Bool { get }
    
    // 方法
    func loadWordDetails(id: String)
    func playPronunciation(speed: Float)
    func toggleFavorite()
    func addNote(note: String)
}

// MARK: - 收藏视图模型协议
protocol FavoriteViewModelProtocol: ObservableObject {
    // 输出属性
    var folders: [FolderSummary] { get }
    var selectedFolder: FolderSummary? { get }
    var folderItems: [FavoriteItemDetail] { get }
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
    var userProfile: UserProfile? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userSettings: UserPreferences { get }
    
    // 方法
    func signInWithApple()
    func signOut()
    func loadUserProfile()
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool)
}