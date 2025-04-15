import Foundation

// MARK: - 收藏模块业务层模型

// 收藏夹业务模型
struct FolderDomain {
    let id: String
    let name: String
    let createdAt: Date
    let items: [FavoriteItemDomain]
    let syncStatus: SyncStatusType
    let lastModified: Date
    let isDefault: Bool
    
    // 转换为数据层模型
    func toData() -> DBFolder {
        let dbFolder = DBFolder()
        dbFolder.id = self.id
        dbFolder.name = self.name
        dbFolder.createdAt = self.createdAt
        dbFolder.syncStatus = self.syncStatus.rawValue
        dbFolder.lastModified = self.lastModified
        dbFolder.isDefault = self.isDefault
        
        // 转换收藏项
        let dbItems = List<DBFavoriteItem>()
        for item in self.items {
            let dbItem = item.toData()
            dbItems.append(dbItem)
        }
        dbFolder.items = dbItems
        
        return dbFolder
    }
    
    // 转换为表现层模型
    func toUI() -> FolderUI {
        return FolderUI(
            id: self.id,
            name: self.name,
            createdAt: self.createdAt,
            items: self.items.map { $0.toUI() },
            syncStatus: self.syncStatus,
            lastModified: self.lastModified,
            isDefault: self.isDefault
        )
    }
}

// 收藏项业务模型
struct FavoriteItemDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatusType
    let lastModified: Date
    let folderId: String?
    
    // 转换为数据层模型
    func toData() -> DBFavoriteItem {
        let dbItem = DBFavoriteItem()
        dbItem.id = self.id
        dbItem.wordId = self.wordId
        dbItem.word = self.word
        dbItem.reading = self.reading
        dbItem.meaning = self.meaning
        dbItem.note = self.note
        dbItem.addedAt = self.addedAt
        dbItem.syncStatus = self.syncStatus.rawValue
        dbItem.lastModified = self.lastModified
        return dbItem
    }
    
    // 转换为表现层模型
    func toUI() -> FavoriteItemUI {
        return FavoriteItemUI(
            id: self.id,
            wordId: self.wordId,
            word: self.word,
            reading: self.reading,
            meaning: self.meaning,
            note: self.note,
            addedAt: self.addedAt,
            syncStatus: self.syncStatus
        )
    }
}

// 收藏夹摘要业务模型
struct FolderSummaryDomain {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatusType
    
    // 转换为表现层模型
    func toUI() -> FolderSummaryUI {
        return FolderSummaryUI(
            id: self.id,
            name: self.name,
            createdAt: self.createdAt,
            itemCount: self.itemCount,
            syncStatus: self.syncStatus
        )
    }
}

// 收藏分类业务模型
struct FavoriteCategoryDomain {
    let id: String
    let name: String
    let iconName: String
    let count: Int
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: SyncStatusType
    
    // 转换为数据层模型
    func toData() -> DBFavoriteCategory {
        let dbCategory = DBFavoriteCategory()
        dbCategory.id = self.id
        dbCategory.name = self.name
        dbCategory.iconName = self.iconName
        dbCategory.count = self.count
        dbCategory.createdAt = self.createdAt
        dbCategory.updatedAt = self.updatedAt
        dbCategory.syncStatus = self.syncStatus.rawValue
        return dbCategory
    }
    
    // 转换为表现层模型
    func toUI() -> FavoriteCategoryUI {
        return FavoriteCategoryUI(
            id: self.id,
            name: self.name,
            iconName: self.iconName,
            count: self.count,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            syncStatus: self.syncStatus
        )
    }
}

// 收藏服务错误类型
enum FavoriteError: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError(Error)
    case syncError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .folderNotFound:
            return "未找到收藏夹"
        case .itemNotFound:
            return "未找到收藏项"
        case .duplicateName:
            return "收藏夹名称重复"
        case .databaseError(let error):
            return "数据库错误: \(error.localizedDescription)"
        case .syncError:
            return "同步错误"
        case .unknown:
            return "未知错误"
        }
    }
}