//
//  ServiceProtocols.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine

// MARK: - 词典服务协议
protocol DictionaryServiceProtocol {
    // 搜索单词
    func searchWords(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError>
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], DictionaryError>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryError>
}

// MARK: - 收藏服务协议
protocol FavoriteServiceProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContent, FavoriteError>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteError>
}

// MARK: - 用户服务协议
protocol UserServiceProtocol {
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfile, UserError>
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfile, UserError>
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferences) -> AnyPublisher<UserPreferences, UserError>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserError>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

// MARK: - 同步服务协议
protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfo, SyncError>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperationInfo, SyncError>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfo, SyncError>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, SyncError>
}