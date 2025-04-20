//
//  ServiceProtocols.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

// MARK: - 词典服务协议
protocol DictionaryServiceProtocol {
    // 搜索单词
    func searchWords(query: String, type: SearchTypeDomain?, limit: Int, offset: Int) -> AnyPublisher<SearchResultDomain, DictionaryErrorDomain>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetailsDomain, DictionaryErrorDomain>
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryErrorDomain>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemDomain], DictionaryErrorDomain>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryErrorDomain>
}

// MARK: - 收藏服务协议
protocol FavoriteServiceProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummaryDomain], FavoriteErrorDomain>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteErrorDomain>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContentDomain, FavoriteErrorDomain>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteErrorDomain>
}

// MARK: - 用户服务协议
protocol UserServiceProtocol {
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfileDomain, UserErrorDomain>
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfileDomain, UserErrorDomain>
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferencesDomain) -> AnyPublisher<UserPreferencesDomain, UserErrorDomain>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserErrorDomain>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

// MARK: - 同步服务协议
protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfoDomain, SyncErrorDomain>
    
    // 触发同步
    func startSync(type: SyncTypeDomain) -> AnyPublisher<SyncOperationInfoDomain, SyncErrorDomain>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfoDomain, SyncErrorDomain>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionDomain) -> AnyPublisher<Bool, SyncErrorDomain>
}

// MARK: - 业务层枚举和数据模型
enum SearchTypeDomain {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

enum SyncStatusDomain: String {
    case synced = "synced"        // 已同步
    case pendingUpload = "pendingUpload" // 待上传
    case pendingDownload = "pendingDownload" // 待下载
    case conflict = "conflict"      // 冲突
    case error = "error"         // 错误
    case none = "none"          // 无状态
}

enum SyncTypeDomain {
    case full       // 全量同步
    case favorites  // 仅同步收藏
    case settings   // 仅同步设置
}

enum ConflictResolutionDomain {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}

// MARK: - 业务层错误类型
enum DictionaryErrorDomain: Error {
    case notFound
    case searchFailed
    case databaseError
    case pronunciationFailed
    case networkError
}

enum FavoriteErrorDomain: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError
    case syncError
}

enum UserErrorDomain: Error {
    case authenticationFailed
    case userNotFound
    case settingsUpdateFailed
    case signOutFailed
}

enum SyncErrorDomain: Error {
    case networkUnavailable
    case cloudKitError
    case authenticationRequired
    case conflictDetected
    case syncInProgress
}

// MARK: - 业务层数据模型
struct SearchResultDomain {
    let total: Int
    let items: [WordSummaryDomain]
}

struct WordSummaryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

struct WordDetailsDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
    let relatedWords: [WordSummaryDomain]
    let isFavorited: Bool
}

struct DefinitionDomain {
    let meaning: String
    let notes: String?
}

struct ExampleDomain {
    let sentence: String
    let translation: String
}

struct SearchHistoryItemDomain {
    let id: String
    let word: String
    let timestamp: Date
}

struct FolderSummaryDomain {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatusDomain
}

struct FolderContentDomain {
    let total: Int
    let items: [FavoriteItemDetailDomain]
}

struct FavoriteItemDetailDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatusDomain
}

struct UserProfileDomain {
    let userId: String
    let nickname: String?
    let settings: UserPreferencesDomain
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferencesDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

struct SyncStatusInfoDomain {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: String
    let availableOffline: Bool
}

struct SyncOperationInfoDomain {
    let syncId: String
    let startedAt: Date
    let status: String
    let estimatedTimeRemaining: Int?
}

struct SyncProgressInfoDomain {
    let syncId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
}