import Foundation
import RealmSwift

// MARK: - 收藏模块数据模型

// 同步状态枚举
enum SyncStatusType: Int {
     case synced            // 已同步
     case pendingUpload     // 待上传
     case pendingDownload   // 待下载
     case pendingDelete     // 待删除
     case conflict          // 冲突
     case error             // 错误
}

// 收藏夹模型
class DBFolder: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String                  // 收藏夹名称
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var items: List<DBFavoriteItem>     // 收藏项目
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
    @Persisted var lastModified: Date = Date()   // 最后修改时间
    @Persisted var isDefault: Bool = false       // 是否为默认收藏夹
    
    // 转换为领域模型
    func toDomain() -> FolderDomain {
        let domainItems = items.map { $0.toDomain() }
        
        return FolderDomain(
            id: self.id,
            name: self.name,
            createdAt: self.createdAt,
            items: domainItems,
            syncStatus: SyncStatusType(rawValue: self.syncStatus) ?? .pendingUpload,
            lastModified: self.lastModified,
            isDefault: self.isDefault
        )
    }
    
    // 创建摘要领域模型
    func toSummaryDomain() -> FolderSummaryDomain {
        return FolderSummaryDomain(
            id: self.id,
            name: self.name,
            createdAt: self.createdAt,
            itemCount: self.items.count,
            syncStatus: SyncStatusType(rawValue: self.syncStatus) ?? .pendingUpload
        )
    }
}

// 收藏项目
class DBFavoriteItem: Object {
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
    @Persisted(originProperty: "items") var folder: LinkingObjects<DBFolder>
    
    var folderObject: DBFolder? {
        return folder.first
    }
    
    // 转换为领域模型
    func toDomain() -> FavoriteItemDomain {
        return FavoriteItemDomain(
            id: self.id,
            wordId: self.wordId,
            word: self.word,
            reading: self.reading,
            meaning: self.meaning,
            note: self.note,
            addedAt: self.addedAt,
            syncStatus: SyncStatusType(rawValue: self.syncStatus) ?? .pendingUpload,
            lastModified: self.lastModified,
            folderId: self.folderObject?.id
        )
    }
}

// 收藏分类模型
class DBFavoriteCategory: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String              // 分类名称
    @Persisted var iconName: String          // 图标名称
    @Persisted var count: Int = 0            // 包含的单词数量
    @Persisted var createdAt: Date = Date()  // 创建时间
    @Persisted var updatedAt: Date = Date()  // 更新时间
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
    
    // 便捷初始化方法
    convenience init(name: String, iconName: String) {
        self.init()
        self.name = name
        self.iconName = iconName
    }
    
    // 转换为领域模型
    func toDomain() -> FavoriteCategoryDomain {
        return FavoriteCategoryDomain(
            id: self.id,
            name: self.name,
            iconName: self.iconName,
            count: self.count,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            syncStatus: SyncStatusType(rawValue: self.syncStatus) ?? .pendingUpload
        )
    }
}