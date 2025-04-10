import Foundation
import RealmSwift
import Combine
import CloudKit

// MARK: - 词典模块数据模型

// 搜索类型枚举
enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

// 词典版本模型
class DictionaryVersion: Object {
    @Persisted(primaryKey: true) var id: String = "dictionary_version"
    @Persisted var version: String
    @Persisted var updateDate: Date
    @Persisted var wordCount: Int
}

// 词条模型
class DictEntry: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var word: String              // 单词
    @Persisted var reading: String           // 读音
    @Persisted var partOfSpeech: String      // 词性
    @Persisted var definitions: List<Definition> // 释义列表
    @Persisted var examples: List<Example>   // 例句列表
    @Persisted var jlptLevel: String?        // JLPT等级
    @Persisted var commonWord: Bool = false  // 是否为常用词
}

// 释义模型
class Definition: EmbeddedObject {
    @Persisted var meaning: String           // 中文释义
    @Persisted var notes: String?            // 注释
    
    init(meaning: String, notes: String? = nil) {
        self.meaning = meaning
        self.notes = notes
    }
}

// 例句模型
class Example: EmbeddedObject {
    @Persisted var sentence: String          // 日语例句
    @Persisted var translation: String       // 中文翻译
    
    init(sentence: String, translation: String) {
        self.sentence = sentence
        self.translation = translation
    }
}

// 搜索历史项
class SearchHistoryItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String            // 关联的词条ID
    @Persisted var word: String              // 搜索的单词
    @Persisted var reading: String?          // 读音
    @Persisted var searchDate: Date          // 搜索日期
}

// MARK: - 收藏模块数据模型

// 同步状态枚举
enum SyncStatusType: Int {
//    case synced = 0        // 已同步
//    case pendingUpload = 1 // 待上传
//    case pendingDelete = 2 // 待删除
//    case conflict = 3      // 冲突
     case synced            // 已同步
     case pendingUpload     // 待上传
     case pendingDownload   // 待下载
     case pendingDelete     // 待删除
     case conflict          // 冲突
     case error             // 错误
}

// 收藏夹模型
class Folder: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String                  // 收藏夹名称
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var items: List<FavoriteItem>     // 收藏项目
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
    @Persisted var lastModified: Date = Date()   // 最后修改时间
    @Persisted var isDefault: Bool = false       // 是否为默认收藏夹
}

// 收藏项目
class FavoriteItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String                // 词条ID
    @Persisted var word: String                  // 单词
    @Persisted var reading: String               // 读音
    @Persisted var meaning: String               // 简要释义
    @Persisted var note: String?                 // 个人笔记
    @Persisted var addedAt: Date = Date()        // 添加时间
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
    @Persisted var lastModified: Date = Date()   // 最后修改时间
    
    // 反向链接到所属文件夹，不存储在Realm中
    // var linkingObjects = LinkingObjects(fromType: Folder.self, property: "items")
    @Persisted(originProperty: "items") var folder: LinkingObjects<Folder>
    
    var folderObject: Folder? {
        return folder.first
    }
}

// MARK: - 用户模块数据模型

// 用户模型
class User: Object {
    @Persisted(primaryKey: true) var id: String  // Apple ID标识符
    @Persisted var nickname: String?             // 昵称
    @Persisted var email: String?                // 邮箱
    @Persisted var settings: UserSettings?       // 用户设置
    @Persisted var lastSyncTime: Date?           // 最后同步时间
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
}

// 用户设置
class UserSettings: EmbeddedObject {
    @Persisted var darkMode: Bool = false        // 深色模式
    @Persisted var fontSize: Int = 2             // 字体大小
    @Persisted var autoSync: Bool = true         // 自动同步
    @Persisted var notificationsEnabled: Bool = true // 通知开关
    @Persisted var syncFrequency: Int = 1        // 同步频率（小时）
}

// 认证令牌
class AuthToken: Object {
    @Persisted(primaryKey: true) var id: String = "auth_token"
    @Persisted var identityToken: Data?          // 身份令牌
    @Persisted var authorizationCode: String?    // 授权码
    @Persisted var expiresAt: Date?              // 过期时间
    @Persisted var refreshToken: String?         // 刷新令牌
}

// MARK: - 同步模块数据模型

// enum SyncType: Int {
//     case full = 0       // 全量同步
//     case favorites = 1  // 仅同步收藏
//     case settings = 2   // 仅同步设置
// }

// // 同步操作类型枚举
// enum SyncOperationType: Int {
//     case full = 0          // 全量同步
//     case incremental = 1   // 增量同步
//     case upload = 2        // 仅上传
//     case download = 3      // 仅下载
// }

// // 冲突解决策略枚举
// enum ConflictResolution: Int {
//     case useLocal = 0      // 使用本地版本
//     case useRemote = 1     // 使用远程版本
//     case merge = 2         // 合并两个版本
//     case manual = 3        // 手动解决
// }

// // 同步操作记录
// class SyncOperation: Object {
//     @Persisted(primaryKey: true) var id: String = UUID().uuidString
//     @Persisted var type: Int                     // 同步类型 (对应SyncOperationType的rawValue)
//     @Persisted var startTime: Date = Date()      // 开始时间
//     @Persisted var endTime: Date?                // 结束时间
//     @Persisted var status: String = "pending"    // 状态：pending, running, completed, failed
//     @Persisted var progress: Double = 0.0        // 进度：0.0-1.0
//     @Persisted var itemsProcessed: Int = 0       // 已处理项目数
//     @Persisted var totalItems: Int = 0           // 总项目数
//     @Persisted var errorMessage: String?         // 错误信息
// }

// // 同步冲突记录
// class SyncConflict: Object {
//     @Persisted(primaryKey: true) var id: String = UUID().uuidString
//     @Persisted var recordType: String            // 记录类型：folder, favorite, user
//     @Persisted var recordId: String              // 记录ID
//     @Persisted var localModified: Date           // 本地修改时间
//     @Persisted var remoteModified: Date          // 远程修改时间
//     @Persisted var resolved: Bool = false        // 是否已解决
//     @Persisted var resolution: Int?              // 解决方式
//     @Persisted var localData: Data?              // 本地数据（JSON）
//     @Persisted var remoteData: Data?             // 远程数据（JSON）
//     @Persisted var detectedAt: Date = Date()     // 检测时间
// }

// // 同步状态记录
// class SyncStatus: Object {
//     @Persisted(primaryKey: true) var id: String = "sync_status"
//     @Persisted var lastSyncTime: Date?           // 最后同步时间
//     @Persisted var lastOperation: SyncOperation? // 最后同步操作
//     @Persisted var pendingChanges: Int = 0       // 待同步变更数
//     @Persisted var availableOffline: Bool = true // 是否可离线使用
//     @Persisted var autoSyncEnabled: Bool = true  // 是否启用自动同步
//     @Persisted var currentOperation: SyncOperation? // 当前同步操作
//     @Persisted var syncFrequency: Int = 60       // 同步频率（分钟）
//     @Persisted var lastError: String?            // 最后错误信息
//     @Persisted var cloudKitAvailable: Bool = false // CloudKit是否可用
//     @Persisted var serverChangeTokenData: Data?  // CloudKit服务器变更令牌
// }

// // 同步记录标记
// class SyncRecord: Object {
//     @Persisted(primaryKey: true) var id: String  // 记录ID（与原记录ID相同）
//     @Persisted var recordType: String            // 记录类型：folder, favorite, user
//     @Persisted var lastSynced: Date?             // 最后同步时间
//     @Persisted var cloudKitRecordID: String?     // CloudKit记录ID
//     @Persisted var cloudKitRecordChangeTag: String? // CloudKit变更标签
//     @Persisted var deleted: Bool = false         // 是否已删除
// }

 // 同步错误类型
 enum SyncError: Error {
     case repositoryError(Error)
     case notAvailable
     case operationInProgress
     case operationNotFound
     case unknown
 }

 // 同步状态信息
 struct SyncStatusInfo {
     let lastSyncTime: Date?
     let isCloudKitAvailable: Bool
     let isAutoSyncEnabled: Bool
     let currentOperation: SyncOperationInfo?
 }

 // 同步操作信息
 struct SyncOperationInfo {
     let id: String
     let type: String
     let status: String
     let startTime: Date
     let endTime: Date?
     let progress: Double
     let itemsProcessed: Int
     let totalItems: Int
     let errorMessage: String?
 }

// 同步状态
class SyncStatus: Object {
    @Persisted(primaryKey: true) var id: String = "sync_status"
    @Persisted var lastSyncTime: Date?
    @Persisted var cloudKitAvailable: Bool = false
    @Persisted var autoSyncEnabled: Bool = true
    @Persisted var serverChangeTokenData: Data?
    @Persisted var currentOperation: SyncOperation?
    @Persisted var lastOperation: SyncOperation?
}

// 同步操作
class SyncOperation: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var type: String = "full"
    @Persisted var status: String = "pending"
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date?
    @Persisted var progress: Double = 0.0
    @Persisted var itemsProcessed: Int = 0
    @Persisted var totalItems: Int = 0
    @Persisted var errorMessage: String?
}

// 同步记录
class SyncRecord: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var recordType: String = ""
    @Persisted var lastSynced: Date = Date()
    @Persisted var cloudKitRecordID: String?
    @Persisted var cloudKitRecordChangeTag: String?
    @Persisted var deleted: Bool = false
}

// 同步冲突
class SyncConflict: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var recordId: String = ""
    @Persisted var recordType: String = ""
    @Persisted var localData: Data?
    @Persisted var remoteData: Data?
    @Persisted var localModified: Date = Date()
    @Persisted var remoteModified: Date = Date()
    @Persisted var resolved: Bool = false
    @Persisted var resolutionType: String?
}

// 同步状态类型
// enum SyncStatusType: String {
//     case synced = "synced"               // 已同步
//     case pendingUpload = "pendingUpload" // 待上传
//     case conflict = "conflict"           // 冲突
// }

// 在文件末尾添加以下模型定义

// MARK: - 业务层模型

// 搜索结果模型
struct SearchResult {
    let query: String
    let totalCount: Int
    let items: [WordListItem]
}

// 词条列表项
struct WordListItem {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

// 词条详情
struct WordDetails {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [Definition]
    let examples: [Example]
    let tags: [String]
    let isFavorited: Bool
}

// 搜索历史项（业务层）
// struct SearchHistoryDTO {
//     let id: String
//     let word: String
//     let timestamp: Date
    
//     init(id: String = UUID().uuidString, word: String, timestamp: Date = Date()) {
//         self.id = id
//         self.word = word
//         self.timestamp = timestamp
//     }
    
//     // 从数据层模型转换
//     init(from model: SearchHistoryItem) {
//         self.id = model.id
//         self.word = model.word
//         self.timestamp = model.searchDate
//     }
// }

// MARK: - 词典服务错误类型
enum DictionaryError: Error {
    case notFound
    case invalidQuery
    case databaseError(Error)
    case audioError
    case networkError
    case unknown
    case searchFailed
    case pronunciationFailed
    
    var localizedDescription: String {
        switch self {
        case .notFound:
            return "未找到相关词条"
        case .invalidQuery:
            return "无效的搜索查询"
        case .databaseError(let error):
            return "数据库错误: \(error.localizedDescription)"
        case .audioError:
            return "音频处理错误"
        case .networkError:
            return "网络连接错误"
        case .unknown:
            return "未知错误"
        case .searchFailed:
            return "搜索错误"
        case .pronunciationFailed:
            return "发音错误"
        }
    }
}

// 音频服务错误
enum AudioError: Error {
    case synthesisError
    case fileError
    case playbackError
}


// MARK: - 收藏服务错误类型
enum FavoriteError: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError(Error)
    case syncError
    case unknown
}


// MARK: - 收藏服务数据模型
struct FolderSummary {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatusType
}

struct FolderContent {
    let total: Int
    let items: [FavoriteItemDetail]
}

struct FavoriteItemDetail {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatusType
}

// enum SyncStatus {
//     case synced        // 已同步
//     case pendingUpload // 待上传
//     case pendingDownload // 待下载
//     case conflict      // 冲突
//     case error         // 错误
// }


// MARK: - 用户服务错误类型
enum UserError: Error {
    case authenticationFailed
    case userNotFound
    case networkError
    case databaseError(Error)
    case syncError
    case unknown
}

// MARK: - 用户服务数据模型
struct UserProfile {
    let userId: String
    let nickname: String?
    let settings: UserPreferences
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferences {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}


// 如果DataModels.swift中尚未定义以下模型，则需要添加

// MARK: - 搜索视图模型数据类型

// 搜索历史DTO
struct SearchHistoryDTO {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let searchDate: Date

    init(id: String, wordId: String, word: String, reading: String, searchDate: Date) {
        self.id = id
        self.wordId = wordId
        self.word = word
        self.reading = reading
        self.searchDate = searchDate
    }
}

// 单词摘要
// struct WordSummary {
//     let id: String
//     let word: String
//     let reading: String
//     let partOfSpeech: String
//     let briefMeaning: String
// }

// 搜索结果
// struct SearchResult {
//     let total: Int
//     let items: [WordSummary]
// }
