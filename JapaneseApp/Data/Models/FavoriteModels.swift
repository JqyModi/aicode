import Foundation
import RealmSwift
import Combine

// MARK: - 收藏夹模型
class Folder: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String                  // 收藏夹名称
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var updatedAt: Date = Date()      // 更新时间
    @Persisted var items: List<FavoriteItem>     // 收藏项目
    @Persisted var syncStatus: Int = 0           // 同步状态 (0: 未同步, 1: 已同步, 2: 同步失败)
    @Persisted var isDefault: Bool = false       // 是否为默认收藏夹
    @Persisted var sortOrder: Int = 0            // 排序顺序
    
    convenience init(name: String, isDefault: Bool = false) {
        self.init()
        self.id = UUID().uuidString
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.syncStatus = 0
        self.isDefault = isDefault
        self.sortOrder = 0
    }
}

// MARK: - 收藏项目模型
class FavoriteItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String                // 词条ID
    @Persisted var word: String                  // 单词
    @Persisted var reading: String               // 读音
    @Persisted var meaning: String               // 简要释义
    @Persisted var note: String?                 // 个人笔记
    @Persisted var addedAt: Date = Date()        // 添加时间
    @Persisted var updatedAt: Date = Date()      // 更新时间
    @Persisted var syncStatus: Int = 0           // 同步状态 (0: 未同步, 1: 已同步, 2: 同步失败)
    @Persisted(originProperty: "items") var folder: LinkingObjects<Folder>
    
    convenience init(wordId: String, word: String, reading: String, meaning: String, note: String? = nil) {
        self.init()
        self.id = UUID().uuidString
        self.wordId = wordId
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.note = note
        self.addedAt = Date()
        self.updatedAt = Date()
        self.syncStatus = 0
    }
}

// MARK: - 同步状态枚举
enum SyncStatus: Int {
    case notSynced = 0    // 未同步
    case synced = 1       // 已同步
    case syncFailed = 2   // 同步失败
    case pendingDelete = 3 // 待删除
}

// MARK: - 收藏操作结果枚举
enum FavoriteResult {
    case success           // 操作成功
    case alreadyExists     // 已存在
    case notFound          // 未找到
    case limitExceeded     // 超出限制
    case error(Error)      // 错误
}

// MARK: - 收藏夹排序方式枚举
enum FolderSortType {
    case nameAsc           // 按名称升序
    case nameDesc          // 按名称降序
    case dateAsc           // 按日期升序
    case dateDesc          // 按日期降序
    case custom            // 自定义排序
}

// MARK: - 收藏项排序方式枚举
enum FavoriteItemSortType {
    case wordAsc           // 按单词升序
    case wordDesc          // 按单词降序
    case dateAsc           // 按日期升序
    case dateDesc          // 按日期降序
}