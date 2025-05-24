//
//  DataRepositoryProtocols.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import AuthenticationServices

// MARK: - 词典数据仓库协议
protocol DictionaryDataRepositoryProtocol {
    // 查询单词
    func searchWords(query: String, type: SearchTypeEntity, limit: Int, offset: Int) -> AnyPublisher<[DictEntryEntity], Error>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntryEntity?, Error>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemEntity], Error>
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntryEntity) -> AnyPublisher<Void, Error>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error>
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersionEntity, Error>
}

// MARK: - 收藏数据仓库协议
protocol FavoriteDataRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderEntity], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderEntity, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderEntity, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItemEntity], Error>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemEntity, Error>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemEntity, Error>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
}

// MARK: - 用户认证数据仓库协议
protocol UserAuthDataRepositoryProtocol {
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<UserEntity, Error>
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<UserEntity?, Error>
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettingsEntity) -> AnyPublisher<UserSettingsEntity, Error>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

// MARK: - 云同步数据仓库协议
protocol SyncDataRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusEntity, Error>
    
    // 触发同步
    func startSync(type: SyncTypeEntity) -> AnyPublisher<SyncOperationEntity, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressEntity, Error>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionEntity) -> AnyPublisher<Bool, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}


// MARK: - 热门词汇服务协议
protocol HotWordDataRepositoryProtocol {
    /// 获取热门词汇列表
    func getHotWords(limit: Int) -> AnyPublisher<[WordCloudWord], Error>
    
    /// 获取Weblio主页内容
    func getWeblioHomeContent() -> AnyPublisher<WeblioHomeContent, Error>
}

// MARK: - 数据层枚举类型
enum SearchTypeEntity {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

enum SyncTypeEntity {
    case full       // 全量同步
    case favorites  // 仅同步收藏
    case settings   // 仅同步设置
}

enum ConflictResolutionEntity {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}
