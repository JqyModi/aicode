import Foundation
import Combine
import RealmSwift


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
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, FavoriteError>
}

// MARK: - 收藏服务实现
class FavoriteService: FavoriteServiceProtocol {
    private let favoriteRepository: FavoriteRepositoryProtocol
    private let dictionaryRepository: DictionaryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(favoriteRepository: FavoriteRepositoryProtocol, dictionaryRepository: DictionaryRepositoryProtocol) {
        self.favoriteRepository = favoriteRepository
        self.dictionaryRepository = dictionaryRepository
    }
    
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError> {
        return favoriteRepository.getAllFolders()
            .map { folders in
                return folders.map { folder in
                    return FolderSummary(
                        id: folder.id,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        itemCount: folder.items.count,
                        syncStatus: self.mapSyncStatus(folder.syncStatus)
                    )
                }
            }
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        return favoriteRepository.createFolder(name: name)
            .map { folder in
                return FolderSummary(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    itemCount: folder.items.count,
                    syncStatus: self.mapSyncStatus(folder.syncStatus)
                )
            }
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" {
                    if nsError.code == 409 {
                        return .duplicateName
                    }
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        return favoriteRepository.updateFolder(id: id, name: name)
            .map { folder in
                return FolderSummary(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    itemCount: folder.items.count,
                    syncStatus: self.mapSyncStatus(folder.syncStatus)
                )
            }
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" {
                    if nsError.code == 404 {
                        return .folderNotFound
                    } else if nsError.code == 409 {
                        return .duplicateName
                    }
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError> {
        return favoriteRepository.deleteFolder(id: id)
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" {
                    if nsError.code == 404 {
                        return .folderNotFound
                    } else if nsError.code == 403 {
                        return .unknown
                    }
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContent, FavoriteError> {
        return favoriteRepository.getFavoriteItems(folderId: folderId)
            .map { items in
                let favoriteItems = items.map { item in
                    return FavoriteItemDetail(
                        id: item.id,
                        wordId: item.wordId,
                        word: item.word,
                        reading: item.reading,
                        meaning: item.meaning,
                        note: item.note,
                        addedAt: item.addedAt,
                        syncStatus: self.mapSyncStatus(item.syncStatus)
                    )
                }
                
                // 应用分页
                let startIndex = min(offset, favoriteItems.count)
                let endIndex = min(startIndex + limit, favoriteItems.count)
                let paginatedItems = Array(favoriteItems[startIndex..<endIndex])
                
                return FolderContent(
                    total: favoriteItems.count,
                    items: paginatedItems
                )
            }
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" && nsError.code == 404 {
                    return .folderNotFound
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 添加收藏
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        // 先获取词条信息
        return dictionaryRepository.getWordDetails(id: wordId)
            .flatMap { dictEntry -> AnyPublisher<FavoriteItemDetail, Error> in
                guard let entry = dictEntry else {
                    return Fail(error: NSError(domain: "FavoriteService", code: 404, userInfo: [NSLocalizedDescriptionKey: "词条不存在"])).eraseToAnyPublisher()
                }
                
                // 从 Realm 对象中提取必要的数据，使用现有的 WordListItem 结构体
                let wordItem = WordListItem(
                    id: entry.id,
                    word: entry.word,
                    reading: entry.reading,
                    partOfSpeech: entry.partOfSpeech,
                    briefMeaning: entry.definitions.first?.meaning ?? ""
                )
                
                // 直接返回转换后的非Realm对象
                return self.favoriteRepository.addFavoriteItemAndConvert(folderId: folderId, wordItem: wordItem, note: note)
            }
            .mapError { error in
                if let nsError = error as NSError? {
                    if nsError.domain == "FavoriteRepository" && nsError.code == 404 {
                        return .folderNotFound
                    } else if nsError.domain == "FavoriteService" && nsError.code == 404 {
                        return .itemNotFound
                    }
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        return favoriteRepository.updateFavoriteItemNote(itemId: id, note: note)
            .map { item in
                return FavoriteItemDetail(
                    id: item.id,
                    wordId: item.wordId,
                    word: item.word,
                    reading: item.reading,
                    meaning: item.meaning,
                    note: item.note,
                    addedAt: item.addedAt,
                    syncStatus: self.mapSyncStatus(item.syncStatus)
                )
            }
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" && nsError.code == 404 {
                    return .itemNotFound
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteError> {
        return favoriteRepository.removeFavoriteItem(itemId: id)
            .mapError { error in
                if let nsError = error as NSError?, nsError.domain == "FavoriteRepository" && nsError.code == 404 {
                    return .itemNotFound
                }
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, FavoriteError> {
        return favoriteRepository.isWordFavorited(wordId: wordId)
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 辅助方法：将数字状态映射为枚举状态
    private func mapSyncStatus(_ status: Int) -> SyncStatusType {
        switch status {
        case 0:
            return .synced
        case 1:
            return .pendingUpload
        case 2:
            return .pendingDownload
        case 3:
            return .conflict
        default:
            return .error
        }
    }
}
