//
//  FavoriteDataRepository.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import RealmSwift

class FavoriteDataRepository: FavoriteDataRepositoryProtocol {
    // MARK: - 属性
    private let realmManager: RealmManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
    }
    
    // MARK: - FavoriteDataRepositoryProtocol 实现
    func getAllFolders() -> AnyPublisher<[FolderEntity], Error> {
        return Future<[FolderEntity], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                let folders = realm.objects(DBFolder.self).sorted(byKeyPath: "createdAt", ascending: false)
                
                let entities = folders.map { folder in
                    // 获取该收藏夹中的项目数量
                    let itemCount = realm.objects(DBFavoriteItem.self).filter("folderId == %@", folder.objectId).count
                    
                    return FolderEntity(
                        id: folder.objectId,
                        name: folder.name,
                        createdAt: folder.createdAt,
                        syncStatus: folder.syncStatus,
                        itemCount: itemCount
                    )
                }
                
                promise(.success(Array(entities)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func createFolder(name: String) -> AnyPublisher<FolderEntity, Error> {
        return Future<FolderEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 检查是否存在同名文件夹
                let existingFolders = realm.objects(DBFolder.self).filter("name == %@", name)
                if !existingFolders.isEmpty {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称已存在"])))                    
                    return
                }
                
                let folder = DBFolder()
                folder.objectId = UUID().uuidString
                folder.name = name
                folder.createdAt = Date()
                folder.syncStatus = 1 // 待上传状态
                
                try realm.write {
                    realm.add(folder)
                }
                
                let entity = FolderEntity(
                    id: folder.objectId,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    syncStatus: folder.syncStatus,
                    itemCount: 0 // 新创建的收藏夹没有项目
                )
                
                promise(.success(entity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderEntity, Error> {
        return Future<FolderEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 检查是否存在同名文件夹
                let existingFolders = realm.objects(DBFolder.self).filter("name == %@ AND objectId != %@", name, id)
                if !existingFolders.isEmpty {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "收藏夹名称已存在"])))
                    return
                }
                
                // 查找要更新的文件夹
                guard let folder = realm.object(ofType: DBFolder.self, forPrimaryKey: id) else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "收藏夹未找到"])))
                    return
                }
                
                try realm.write {
                    folder.name = name
                    folder.syncStatus = 1 // 待上传状态
                }
                
                let entity = FolderEntity(
                    id: folder.objectId,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    syncStatus: folder.syncStatus,
                    itemCount: 0 // 新创建的收藏夹没有项目
                )
                
                promise(.success(entity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查找要删除的文件夹
                guard let folder = realm.object(ofType: DBFolder.self, forPrimaryKey: id) else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "收藏夹未找到"])))
                    return
                }
                
                // 查找该文件夹下的所有收藏项
                let favoriteItems = realm.objects(DBFavoriteItem.self).filter("folderId == %@", id)
                
                try realm.write {
                    // 先删除收藏项
                    realm.delete(favoriteItems)
                    // 再删除文件夹
                    realm.delete(folder)
                }
                
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItemEntity], Error> {
        return Future<[FavoriteItemEntity], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 检查文件夹是否存在
                guard realm.object(ofType: DBFolder.self, forPrimaryKey: folderId) != nil else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "收藏夹未找到"])))
                    return
                }
                
                // 查询该文件夹下的收藏项
                let favoriteItems = realm.objects(DBFavoriteItem.self)
                    .filter("folderId == %@", folderId)
                    .sorted(byKeyPath: "addedAt", ascending: false)
                
                // 分页处理
                let paginatedItems = favoriteItems.suffix(from: offset).prefix(limit)
                
                let entities = paginatedItems.map { item in
                    FavoriteItemEntity(
                        id: item.objectId,
                        wordId: item.wordId,
                        word: item.word,
                        reading: item.reading,
                        meaning: item.meaning,
                        note: item.note,
                        addedAt: item.addedAt,
                        syncStatus: item.syncStatus
                    )
                }
                
                promise(.success(Array(entities)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemEntity, Error> {
        return Future<FavoriteItemEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 检查文件夹是否存在
                guard realm.object(ofType: DBFolder.self, forPrimaryKey: folderId) != nil else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "收藏夹未找到"])))
                    return
                }
                
                // 检查单词是否存在
                guard let word = realm.object(ofType: DBWord.self, forPrimaryKey: wordId) else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 3, userInfo: [NSLocalizedDescriptionKey: "单词未找到"])))
                    return
                }
                
                // 检查是否已收藏到该文件夹
                let existingItems = realm.objects(DBFavoriteItem.self)
                    .filter("wordId == %@ AND folderId == %@", wordId, folderId)
                
                if !existingItems.isEmpty {
                    // 已存在，更新笔记
                    try realm.write {
                        let existingItem = existingItems.first!
                        existingItem.note = note
                        existingItem.syncStatus = 1 // 待上传状态
                    }
                    
                    let entity = FavoriteItemEntity(
                        id: existingItems.first!.objectId,
                        wordId: existingItems.first!.wordId,
                        word: existingItems.first!.word,
                        reading: existingItems.first!.reading,
                        meaning: existingItems.first!.meaning,
                        note: existingItems.first!.note,
                        addedAt: existingItems.first!.addedAt,
                        syncStatus: existingItems.first!.syncStatus
                    )
                    
                    promise(.success(entity))
                    return
                }
                
                // 创建新收藏项
                let favoriteItem = DBFavoriteItem()
                favoriteItem.objectId = UUID().uuidString
                favoriteItem.wordId = wordId
                favoriteItem.folderId = folderId
                favoriteItem.word = word.spell ?? ""
                favoriteItem.reading = word.pron ?? ""
                favoriteItem.meaning = word.excerpt ?? ""
                favoriteItem.note = note
                favoriteItem.addedAt = Date()
                favoriteItem.syncStatus = 1 // 待上传状态
                
                try realm.write {
                    realm.add(favoriteItem)
                }
                
                let entity = FavoriteItemEntity(
                    id: favoriteItem.objectId,
                    wordId: favoriteItem.wordId,
                    word: favoriteItem.word,
                    reading: favoriteItem.reading,
                    meaning: favoriteItem.meaning,
                    note: favoriteItem.note,
                    addedAt: favoriteItem.addedAt,
                    syncStatus: favoriteItem.syncStatus
                )
                
                promise(.success(entity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemEntity, Error> {
        return Future<FavoriteItemEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查找收藏项
                guard let favoriteItem = realm.object(ofType: DBFavoriteItem.self, forPrimaryKey: id) else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 4, userInfo: [NSLocalizedDescriptionKey: "收藏项未找到"])))
                    return
                }
                
                try realm.write {
                    favoriteItem.note = note
                    favoriteItem.syncStatus = 1 // 待上传状态
                }
                
                let entity = FavoriteItemEntity(
                    id: favoriteItem.objectId,
                    wordId: favoriteItem.wordId,
                    word: favoriteItem.word,
                    reading: favoriteItem.reading,
                    meaning: favoriteItem.meaning,
                    note: favoriteItem.note,
                    addedAt: favoriteItem.addedAt,
                    syncStatus: favoriteItem.syncStatus
                )
                
                promise(.success(entity))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查找收藏项
                guard let favoriteItem = realm.object(ofType: DBFavoriteItem.self, forPrimaryKey: id) else {
                    promise(.failure(NSError(domain: "FavoriteDataRepository", code: 4, userInfo: [NSLocalizedDescriptionKey: "收藏项未找到"])))
                    return
                }
                
                try realm.write {
                    realm.delete(favoriteItem)
                }
                
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FavoriteDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查询是否有包含该单词的收藏项
                let favoriteItems = realm.objects(DBFavoriteItem.self).filter("wordId == %@", wordId)
                
                promise(.success(!favoriteItems.isEmpty))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - 收藏相关数据库模型
class DBFolder: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var syncStatus: Int = 0 // 0: 已同步, 1: 待上传, 2: 待下载, 3: 冲突, 4: 错误
    @objc dynamic var updatedAt: Date? = nil
    
    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBFavoriteItem: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var wordId: String = ""
    @objc dynamic var folderId: String = ""
    @objc dynamic var word: String = ""
    @objc dynamic var reading: String = ""
    @objc dynamic var meaning: String = ""
    @objc dynamic var note: String? = nil
    @objc dynamic var addedAt: Date = Date()
    @objc dynamic var syncStatus: Int = 0 // 0: 已同步, 1: 待上传, 2: 待下载, 3: 冲突, 4: 错误
    @objc dynamic var updatedAt: Date? = nil
    
    override static func primaryKey() -> String? {
        return "objectId"
    }
}