import Foundation
import RealmSwift
import Combine

protocol FavoriteRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹中的所有单词
    func getFavoriteItems(folderId: String) -> AnyPublisher<[FavoriteItem], Error>
    
    // 添加单词到收藏夹
    func addFavoriteItem(folderId: String, word: DictEntry, note: String?) -> AnyPublisher<FavoriteItem, Error>
    
    // 更新收藏单词的笔记
    func updateFavoriteItemNote(itemId: String, note: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 从收藏夹中移除单词
    func removeFavoriteItem(itemId: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
    
    // 获取单词所在的所有收藏夹
    func getFoldersContainingWord(wordId: String) -> AnyPublisher<[Folder], Error>
}

class FavoriteRepository: FavoriteRepositoryProtocol {
    private let realmManager: RealmManager
    
    init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
        createDefaultFolderIfNeeded()
    }
    
    // 创建默认收藏夹（如果不存在）
    private func createDefaultFolderIfNeeded() {
        do {
            let realm = try realmManager.realm()
            let defaultFolders = realm.objects(Folder.self).filter("isDefault == true")
            
            if defaultFolders.isEmpty {
                try realm.write {
                    let defaultFolder = Folder()
                    defaultFolder.name = "默认收藏夹"
                    defaultFolder.isDefault = true
                    realm.add(defaultFolder)
                }
            }
        } catch {
            print("创建默认收藏夹失败: \(error)")
        }
    }
    
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                let folders = realm.objects(Folder.self).sorted(byKeyPath: "createdAt", ascending: false)
                promise(.success(Array(folders)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error> {
        return realmManager.writeAsync { realm in
            let folder = Folder()
            folder.name = name
            folder.createdAt = Date()
            folder.lastModified = Date()
            folder.syncStatus = SyncStatus.pendingUpload.rawValue
            
            realm.add(folder)
            return folder
        }
    }
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error> {
        return realmManager.writeAsync { realm in
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])
            }
            
            folder.name = name
            folder.lastModified = Date()
            folder.syncStatus = SyncStatus.pendingUpload.rawValue
            
            return folder
        }
    }
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])
            }
            
            // 不允许删除默认收藏夹
            if folder.isDefault {
                throw NSError(domain: "FavoriteRepository", code: 403, userInfo: [NSLocalizedDescriptionKey: "不能删除默认收藏夹"])
            }
            
            // 删除收藏夹中的所有项目
            realm.delete(folder.items)
            
            // 删除收藏夹
            realm.delete(folder)
            
            return true
        }
    }
    
    // 获取收藏夹中的所有单词
    func getFavoriteItems(folderId: String) -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                    throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])
                }
                
                let items = folder.items.sorted(byKeyPath: "addedAt", ascending: false)
                promise(.success(Array(items)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 添加单词到收藏夹
    func addFavoriteItem(folderId: String, word: DictEntry, note: String?) -> AnyPublisher<FavoriteItem, Error> {
        return realmManager.writeAsync { realm in
            guard let folder = realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏夹不存在"])
            }
            
            // 检查是否已经收藏
            let existingItems = folder.items.filter("wordId == %@", word.id)
            if let existingItem = existingItems.first {
                // 如果已收藏且有新笔记，则更新笔记
                if let newNote = note, existingItem.note != newNote {
                    existingItem.note = newNote
                    existingItem.lastModified = Date()
                    existingItem.syncStatus = SyncStatus.pendingUpload.rawValue
                }
                return existingItem
            }
            
            // 创建新收藏项
            let item = FavoriteItem()
            item.wordId = word.id
            item.word = word.word
            item.reading = word.reading
            
            // 获取第一个释义作为简要释义
            if let firstDefinition = word.definitions.first {
                item.meaning = firstDefinition.meaning
            } else {
                item.meaning = "无释义"
            }
            
            item.note = note
            item.addedAt = Date()
            item.lastModified = Date()
            item.syncStatus = SyncStatus.pendingUpload.rawValue
            
            // 添加到收藏夹
            folder.items.append(item)
            folder.lastModified = Date()
            folder.syncStatus = SyncStatus.pendingUpload.rawValue
            
            return item
        }
    }
    
    // 更新收藏单词的笔记
    func updateFavoriteItemNote(itemId: String, note: String) -> AnyPublisher<FavoriteItem, Error> {
        return realmManager.writeAsync { realm in
            guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏项不存在"])
            }
            
            item.note = note
            item.lastModified = Date()
            item.syncStatus = SyncStatus.pendingUpload.rawValue
            
            // 更新所属文件夹的修改时间和同步状态
            if let folder = item.linkingObjects.first {
                folder.lastModified = Date()
                folder.syncStatus = SyncStatus.pendingUpload.rawValue
            }
            
            return item
        }
    }
    
    // 从收藏夹中移除单词
    func removeFavoriteItem(itemId: String) -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            guard let item = realm.object(ofType: FavoriteItem.self, forPrimaryKey: itemId) else {
                throw NSError(domain: "FavoriteRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "收藏项不存在"])
            }
            
            // 更新所属文件夹的修改时间和同步状态
            if let folder = item.linkingObjects.first {
                folder.lastModified = Date()
                folder.syncStatus = SyncStatus.pendingUpload.rawValue
            }
            
            // 删除收藏项
            realm.delete(item)
            
            return true
        }
    }
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                let items = realm.objects(FavoriteItem.self).filter("wordId == %@", wordId)
                promise(.success(!items.isEmpty))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取单词所在的所有收藏夹
    func getFoldersContainingWord(wordId: String) -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                let items = realm.objects(FavoriteItem.self).filter("wordId == %@", wordId)
                
                var folders: [Folder] = []
                for item in items {
                    if let folder = item.linkingObjects.first, !folders.contains(where: { $0.id == folder.id }) {
                        folders.append(folder)
                    }
                }
                
                promise(.success(folders))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
