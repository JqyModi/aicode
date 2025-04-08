import Foundation
import RealmSwift
import Combine

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
}

// 例句模型
class Example: EmbeddedObject {
    @Persisted var sentence: String          // 日语例句
    @Persisted var translation: String       // 中文翻译
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
enum SyncStatus: Int {
    case synced = 0        // 已同步
    case pendingUpload = 1 // 待上传
    case pendingDelete = 2 // 待删除
    case conflict = 3      // 冲突
}

// 收藏夹模型
class Folder: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String                  // 收藏夹名称
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var items: List<FavoriteItem>     // 收藏项目
    @Persisted var syncStatus: Int = SyncStatus.pendingUpload.rawValue // 同步状态
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
    @Persisted var syncStatus: Int = SyncStatus.pendingUpload.rawValue // 同步状态
    @Persisted var lastModified: Date = Date()   // 最后修改时间
    
    // 反向链接到所属文件夹，不存储在Realm中
    var linkingObjects = LinkingObjects(fromType: Folder.self, property: "items")
}
