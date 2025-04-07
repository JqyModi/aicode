import Foundation
import RealmSwift
import Combine

protocol FavoriteRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders(sortBy: FolderSortType) -> AnyPublisher<[Folder], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Void, Error>
    
    // 获取收藏夹中的所有单词
    func getFavoriteItems(folderId: String, sortBy: FavoriteItemSortType, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItem], Error>
    
    // 添加单词到收藏夹
    func addFavoriteItem(folderId: String, wordId: String, word: String, reading: String, meaning: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 更新收藏项笔记
    func updateFavoriteItemNote(itemId: String, note: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 从收藏夹中移除单词
    func removeFavoriteItem(itemId: String) -> AnyPublisher<Void, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
    
    // 获取单词所在的收藏夹
    func getFoldersContainingWord(wordId: String) -> AnyPublisher<[Folder], Error>
    
    // 获取默认收藏夹
    func getDefaultFolder() -> AnyPublisher<Folder, Error>
    
    // 合并收藏夹
    func mergeFolders(sourceId: String, targetId: String) -> AnyPublisher<Void, Error>
    
    // 获取收藏夹中的单词数量
    func getFavoriteItemCount(folderId: String) -> AnyPublisher<Int, Error>
    
    // 获取总收藏数量
    func getTotalFavoriteItemCount() -> AnyPublisher<Int, Error>
}

class FavoriteRepository: FavoriteRepositoryProtocol {
    // MARK: - 属性
    private let realmManager: RealmManager
    private let defaultFolderName = "我的收藏"
    private let maxFolderCount = 50
    private let maxItemsPerFolder = 10000
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
        
        // 确保默认收藏夹存在
        ensureDefaultFolderExists()
    }
    
    // MARK: - 私有方法
    
    /// 确保默认收藏夹存在
    private func ensureDefaultFolderExists() {
        guard let realm = realmManager.getRealm() else { return }
        
        // 检查是否已存在默认收藏夹
        let defaultFolders = realm.objects(Folder.self).filter("isDefault == true")
        
        if defaultFolders.isEmpty {
            // 创建默认收藏夹
            try? realm.write {
                let defaultFolder = Folder(name: defaultFolderName, isDefault: true)
                realm.add(defaultFolder)
            }
        }
    }
    
    // MARK: - FavoriteRepositoryProtocol 实现
    
    /// 获取所有收藏夹
    func getAllFolders(sortBy: FolderSortType = .custom) -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3001, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 获取所有收藏夹
            var folders = realm.objects(Folder.self)
            
            // 根据排序方式进行排序
            switch sortBy {
            case .nameAsc:
                folders = folders.sorted(byKeyPath: "name", ascending: true)
            case .nameDesc:
                folders = folders.sorted(byKeyPath: "name", ascending: false)
            case .dateAsc:
                folders = folders.sorted(byKeyPath: "createdAt", ascending: true)
            case .dateDesc:
                folders = folders.sorted(byKeyPath: "createdAt", ascending: false)
            case .custom:
                folders = folders.sorted(byKeyPath: "sortOrder", ascending: true)
            }
            
            // 将默认收藏夹置顶
            let defaultFolders = folders.filter("isDefault == true")
            let nonDefaultFolders = folders.filter("isDefault == false")
            
            var result: [Folder] = []
            result.append(contentsOf: defaultFolders)
            result.append(contentsOf: nonDefaultFolders)
            
            promise(.success(Array(result)))
        }.eraseToAnyPublisher()
    }
    
    /// 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error> {
        return Future<Folder, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3002, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 检查收藏夹数量是否超出限制
            let folderCount = realm.objects(Folder.self).count
            if folderCount >= self.maxFolderCount {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3003, userInfo: [NSLocalizedDescriptionKey: "收藏夹数量已达上限"])))
                return
            }
            
            // 检查名称是否为空
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3004, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称不能为空"])))
                return
            }
            
            // 检查名称长度
            if name.count > 20 {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3005, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称不能超过20个字符"])))
                return
            }
            
            // 检查是否已存在同名收藏夹
            let existingFolder = realm.objects(Folder.self).filter("name == %@", name).first
            if existingFolder != nil {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3006, userInfo: [NSLocalizedDescriptionKey: "已存在同名收藏夹"])))
                return
            }
            
            do {
                // 创建新收藏夹
                let folder = Folder(name: name)
                folder.sortOrder = folderCount // 设置排序顺序为当前收藏夹数量
                
                try realm.write {
                    realm.add(folder)
                }
                
                promise(.success(folder))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error> {
        return Future<Folder, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3007, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 检查名称是否为空
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3008, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称不能为空"])))
                return
            }
            
            // 检查名称长度
            if name.count > 20 {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3009, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称不能超过20个字符"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3010, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            // 检查是否为默认收藏夹
            if folder.isDefault && folder.name != name {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3011, userInfo: [NSLocalizedDescriptionKey: "默认收藏夹不能重命名"])))
                return
            }
            
            // 检查是否已存在同名收藏夹
            let existingFolder = realm.objects(Folder.self).filter("name == %@ AND id != %@", name, id).first
            if existingFolder != nil {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3012, userInfo: [NSLocalizedDescriptionKey: "已存在同名收藏夹"])))
                return
            }
            
            do {
                try realm.write {
                    folder.name = name
                    folder.updatedAt = Date()
                    folder.syncStatus = SyncStatus.notSynced.rawValue
                }
                
                promise(.success(folder))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3013, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3014, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            // 检查是否为默认收藏夹
            if folder.isDefault {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3015, userInfo: [NSLocalizedDescriptionKey: "默认收藏夹不能删除"])))
                return
            }
            
            do {
                try realm.write {
                    // 删除收藏夹中的所有收藏项
                    realm.delete(folder.items)
                    
                    // 删除收藏夹
                    realm.delete(folder)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 获取收藏夹中的所有单词
    func getFavoriteItems(folderId: String, sortBy: FavoriteItemSortType = .dateDesc, limit: Int = 100, offset: Int = 0) -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3016, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3017, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            // 获取收藏夹中的所有收藏项
            var items = folder.items
            
            // 根据排序方式进行排序
            switch sortBy {
            case .wordAsc:
                items = items.sorted(byKeyPath: "word", ascending: true)
            case .wordDesc:
                items = items.sorted(byKeyPath: "word", ascending: false)
            case .dateAsc:
                items = items.sorted(byKeyPath: "addedAt", ascending: true)
            case .dateDesc:
                items = items.sorted(byKeyPath: "addedAt", ascending: false)
            }
            
            // 应用分页
            let paginatedItems = items.freeze()
                .dropFirst(offset)
                .prefix(limit)
            
            promise(.success(Array(paginatedItems)))
        }.eraseToAnyPublisher()
    }
    
    /// 添加单词到收藏夹
    func addFavoriteItem(folderId: String, wordId: String, word: String, reading: String, meaning: String) -> AnyPublisher<FavoriteItem, Error> {
        return Future<FavoriteItem, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3018, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3019, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            // 检查收藏项数量是否超出限制
            if folder.items.count >= self.maxItemsPerFolder {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3020, userInfo: [NSLocalizedDescriptionKey: "收藏夹已满"])))
                return
            }
            
            // 检查是否已收藏该单词
            let existingItem = folder.items.filter("wordId == %@", wordId).first
            if existingItem != nil {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3021, userInfo: [NSLocalizedDescriptionKey: "该单词已收藏"])))
                return
            }
            
            do {
                // 创建新收藏项
                let item = FavoriteItem(wordId: wordId, word: word, reading: reading, meaning: meaning)
                
                try realm.write {
                    folder.items.append(item)
                    folder.updatedAt = Date()
                    folder.syncStatus = SyncStatus.notSynced.rawValue
                }
                
                promise(.success(item))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 更新收藏项笔记
    func updateFavoriteItemNote(itemId: String, note: String) -> AnyPublisher<FavoriteItem, Error> {
        return Future<FavoriteItem, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3022, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏项
            guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3023, userInfo: [NSLocalizedDescriptionKey: "收藏项不存在"])))
                return
            }
            
            // 检查笔记长度
            if note.count > 1000 {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3024, userInfo: [NSLocalizedDescriptionKey: "笔记长度不能超过1000个字符"])))
                return
            }
            
            do {
                try realm.write {
                    item.note = note
                    item.updatedAt = Date()
                    item.syncStatus = SyncStatus.notSynced.rawValue
                    
                    // 更新所属收藏夹的更新时间和同步状态
                    if let folder = item.folder.first {
                        folder.updatedAt = Date()
                        folder.syncStatus = SyncStatus.notSynced.rawValue
                    }
                }
                
                promise(.success(item))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 从收藏夹中移除单词
    func removeFavoriteItem(itemId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3025, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏项
            guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3026, userInfo: [NSLocalizedDescriptionKey: "收藏项不存在"])))
                return
            }
            
            do {
                try realm.write {
                    // 更新所属收藏夹的更新时间和同步状态
                    if let folder = item.folder.first {
                        folder.updatedAt = Date()
                        folder.syncStatus = SyncStatus.notSynced.rawValue
                    }
                    
                    // 删除收藏项
                    realm.delete(item)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3027, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找所有包含该单词的收藏项
            let items = realm.objects(FavoriteItem.self).filter("wordId == %@", wordId)
            
            promise(.success(!items.isEmpty))
        }.eraseToAnyPublisher()
    }
    
    /// 获取单词所在的收藏夹
    func getFoldersContainingWord(wordId: String) -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3028, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找所有包含该单词的收藏项
            let items = realm.objects(FavoriteItem.self).filter("wordId == %@", wordId)
            
            // 获取这些收藏项所在的收藏夹
            var folders: [Folder] = []
            for item in items {
                if let folder = item.folder.first, !folders.contains(where: { $0.id == folder.id }) {
                    folders.append(folder)
                }
            }
            
            promise(.success(folders))
        }.eraseToAnyPublisher()
    }
    
    /// 获取默认收藏夹
    func getDefaultFolder() -> AnyPublisher<Folder, Error> {
        return Future<Folder, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3029, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找默认收藏夹
            guard let defaultFolder = realm.objects(Folder.self).filter("isDefault == true").first else {
                // 如果不存在默认收藏夹，创建一个
                do {
                    let folder = Folder(name: self.defaultFolderName, isDefault: true)
                    
                    try realm.write {
                        realm.add(folder)
                    }
                    
                    promise(.success(folder))
                } catch {
                    promise(.failure(error))
                }
                return
            }
            
            promise(.success(defaultFolder))
        }.eraseToAnyPublisher()
    }
    
    /// 合并收藏夹
    func mergeFolders(sourceId: String, targetId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3030, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找源收藏夹
            guard let sourceFolder = realm.object(ofType: Folder.self, forPrimaryKey: sourceId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3031, userInfo: [NSLocalizedDescriptionKey: "源收藏夹不存在"])))
                return
            }
            
            // 查找目标收藏夹
            guard let targetFolder = realm.object(ofType: Folder.self, forPrimaryKey: targetId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3032, userInfo: [NSLocalizedDescriptionKey: "目标收藏夹不存在"])))
                return
            }
            
            // 检查是否为同一个收藏夹
            if sourceId == targetId {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3033, userInfo: [NSLocalizedDescriptionKey: "不能合并到同一个收藏夹"])))
                return
            }
            
            // 检查目标收藏夹是否有足够空间
            if targetFolder.items.count + sourceFolder.items.count > self.maxItemsPerFolder {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3034, userInfo: [NSLocalizedDescriptionKey: "目标收藏夹空间不足"])))
                return
            }
            
            do {
                try realm.write {
                    // 获取源收藏夹中的所有收藏项
                    let sourceItems = Array(sourceFolder.items)
                    
                    // 将源收藏夹中的收藏项添加到目标收藏夹
                    for item in sourceItems {
                        // 检查目标收藏夹中是否已存在该单词
                        let existingItem = targetFolder.items.filter("wordId == %@", item.wordId).first
                        
                        if existingItem == nil {
                            // 创建新收藏项并添加到目标收藏夹
                            let newItem = FavoriteItem(wordId: item.wordId, word: item.word, reading: item.reading, meaning: item.meaning, note: item.note)
                            targetFolder.items.append(newItem)
                        }
                    }
                    
                    // 更新目标收藏夹的更新时间和同步状态
                    targetFolder.updatedAt = Date()
                    targetFolder.syncStatus = SyncStatus.notSynced.rawValue
                    
                    // 删除源收藏夹中的所有收藏项
                    realm.delete(sourceFolder.items)
                    
                    // 如果源收藏夹不是默认收藏夹，则删除源收藏夹
                    if !sourceFolder.isDefault {
                        realm.delete(sourceFolder)
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
        /// 获取收藏夹中的单词数量
    func getFavoriteItemCount(folderId: String) -> AnyPublisher<Int, Error> {
        return Future<Int, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3035, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3036, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            // 获取收藏项数量
            let count = folder.items.count
            
            promise(.success(count))
        }.eraseToAnyPublisher()
    }
    
    /// 获取总收藏数量
    func getTotalFavoriteItemCount() -> AnyPublisher<Int, Error> {
        return Future<Int, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3037, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 获取所有收藏项数量
            let count = realm.objects(FavoriteItem.self).count
            
            promise(.success(count))
        }.eraseToAnyPublisher()
    }
    
    /// 获取收藏夹排序
    func updateFolderOrder(folderIds: [String]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3038, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            do {
                try realm.write {
                    // 更新每个收藏夹的排序顺序
                    for (index, folderId) in folderIds.enumerated() {
                        if let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) {
                            folder.sortOrder = index
                            folder.updatedAt = Date()
                            folder.syncStatus = SyncStatus.notSynced.rawValue
                        }
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 批量移动收藏项到另一个收藏夹
    func moveItemsToFolder(itemIds: [String], targetFolderId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3039, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找目标收藏夹
            guard let targetFolder = realm.object(ofType: Folder.self, forPrimaryKey: targetFolderId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3040, userInfo: [NSLocalizedDescriptionKey: "目标收藏夹不存在"])))
                return
            }
            
            // 检查目标收藏夹是否有足够空间
            if targetFolder.items.count + itemIds.count > self.maxItemsPerFolder {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3041, userInfo: [NSLocalizedDescriptionKey: "目标收藏夹空间不足"])))
                return
            }
            
            do {
                try realm.write {
                    for itemId in itemIds {
                        // 查找收藏项
                        guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                            continue
                        }
                        
                        // 检查目标收藏夹中是否已存在该单词
                        let existingItem = targetFolder.items.filter("wordId == %@", item.wordId).first
                        
                        if existingItem == nil {
                            // 从原收藏夹中移除
                            if let sourceFolder = item.folder.first {
                                let index = sourceFolder.items.index(matching: NSPredicate(format: "id == %@", itemId))
                                if let idx = index {
                                    sourceFolder.items.remove(at: idx)
                                    sourceFolder.updatedAt = Date()
                                    sourceFolder.syncStatus = SyncStatus.notSynced.rawValue
                                }
                            }
                            
                            // 创建新收藏项并添加到目标收藏夹
                            let newItem = FavoriteItem(wordId: item.wordId, word: item.word, reading: item.reading, meaning: item.meaning, note: item.note)
                            targetFolder.items.append(newItem)
                            
                            // 删除原收藏项
                            realm.delete(item)
                        }
                    }
                    
                    // 更新目标收藏夹的更新时间和同步状态
                    targetFolder.updatedAt = Date()
                    targetFolder.syncStatus = SyncStatus.notSynced.rawValue
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 批量删除收藏项
    func deleteFavoriteItems(itemIds: [String]) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3042, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            do {
                try realm.write {
                    for itemId in itemIds {
                        // 查找收藏项
                        guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                            continue
                        }
                        
                        // 更新所属收藏夹的更新时间和同步状态
                        if let folder = item.folder.first {
                            folder.updatedAt = Date()
                            folder.syncStatus = SyncStatus.notSynced.rawValue
                        }
                        
                        // 删除收藏项
                        realm.delete(item)
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 搜索收藏项
    func searchFavoriteItems(query: String, limit: Int = 100, offset: Int = 0) -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3043, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 搜索收藏项
            let items = realm.objects(FavoriteItem.self)
                .filter("word CONTAINS[c] %@ OR reading CONTAINS[c] %@ OR meaning CONTAINS[c] %@", query, query, query)
                .sorted(byKeyPath: "addedAt", ascending: false)
            
            // 应用分页
            let paginatedItems = items.freeze()
                .dropFirst(offset)
                .prefix(limit)
            
            promise(.success(Array(paginatedItems)))
        }.eraseToAnyPublisher()
    }
    
    /// 获取最近添加的收藏项
    func getRecentFavoriteItems(limit: Int = 10) -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3044, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 获取最近添加的收藏项
            let items = realm.objects(FavoriteItem.self)
                .sorted(byKeyPath: "addedAt", ascending: false)
                .prefix(limit)
            
            promise(.success(Array(items)))
        }.eraseToAnyPublisher()
    }
    
    /// 更新收藏项的同步状态
    func updateFavoriteItemSyncStatus(itemId: String, syncStatus: SyncStatus) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3045, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏项
            guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3046, userInfo: [NSLocalizedDescriptionKey: "收藏项不存在"])))
                return
            }
            
            do {
                try realm.write {
                    item.syncStatus = syncStatus.rawValue
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 更新收藏夹的同步状态
    func updateFolderSyncStatus(folderId: String, syncStatus: SyncStatus) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3047, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查找收藏夹
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3048, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])))
                return
            }
            
            do {
                try realm.write {
                    folder.syncStatus = syncStatus.rawValue
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 获取需要同步的收藏夹
    func getFoldersNeedSync() -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3049, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 获取需要同步的收藏夹
            let folders = realm.objects(Folder.self)
                .filter("syncStatus != %@", SyncStatus.synced.rawValue)
            
            promise(.success(Array(folders)))
        }.eraseToAnyPublisher()
    }
    
    /// 获取需要同步的收藏项
    func getFavoriteItemsNeedSync() -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "FavoriteRepository", code: 3050, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 获取需要同步的收藏项
            let items = realm.objects(FavoriteItem.self)
                .filter("syncStatus != %@", SyncStatus.synced.rawValue)
            
            promise(.success(Array(items)))
        }.eraseToAnyPublisher()
    }
}