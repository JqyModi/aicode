//
//  RepositoryProtocols.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine
import RealmSwift

// MARK: - 搜索类型
enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

// MARK: - 冲突解决策略
enum ConflictResolution {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}

// 使用SyncModels.swift中定义的SyncType
// import SyncType

// MARK: - 词典仓库协议
protocol DictionaryRepositoryProtocol {
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error>
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error>
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error>
}

// MARK: - 收藏管理仓库协议
protocol FavoriteRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItem], Error>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItem, Error>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
}

// MARK: - 用户认证仓库协议
protocol UserAuthRepositoryProtocol {
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error>
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error>
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

// MARK: - 云同步仓库协议
protocol SyncRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperation, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgress, Error>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}
