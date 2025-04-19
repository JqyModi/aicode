//
//  FavoriteRepository.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine
import RealmSwift

class FavoriteRepository: FavoriteRepositoryProtocol {
    
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    
    init() throws {
        self.realm = try Realm()
    }
    
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error> {
        return Future<[Folder], Error> { promise in
            let folders = self.realm.objects(Folder.self)
                .sorted(byKeyPath: "createdAt", ascending: false)
            
            promise(.success(Array(folders)))
        }.eraseToAnyPublisher()
    }
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error> {
        return Future<Folder, Error> { promise in
            do {
                // 检查是否存在同名文件夹
                let existingFolders = self.realm.objects(Folder.self)
                    .filter("name == %@", name)
                
                if !existingFolders.isEmpty {
                    promise(.failure(FavoriteError.duplicateName))
                    return
                }
                
                let folder = Folder()
                folder.name = name
                folder.createdAt = Date()
                folder.syncStatus = UISyncStatus.pendingUpload.rawValue
                
                try self.realm.write {
                    self.realm.add(folder)
                }
                
                promise(.success(folder))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error> {
        return Future<Folder, Error> { promise in
            do {
                // 检查是否存在同名文件夹
                let existingFolders = self.realm.objects(Folder.self)
                    .filter("name == %@ AND id != %@", name, id)
                
                if !existingFolders.isEmpty {
                    promise(.failure(FavoriteError.duplicateName))
                    return
                }
                
                guard let folder = self.realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                    promise(.failure(FavoriteError.folderNotFound))
                    return
                }
                
                try self.realm.write {
                    folder.name = name
                    folder.syncStatus = UISyncStatus.pendingUpload.rawValue
                }
                
                promise(.success(folder))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                guard let folder = self.realm.object(ofType: Folder.self, forPrimaryKey: id) else {
                    promise(.failure(FavoriteError.folderNotFound))
                    return
                }
                
                // 获取该文件夹下的所有收藏项
                let items = self.realm.objects(FavoriteItem.self)
                    .filter("folderId == %@", id)
                
                try self.realm.write {
                    // 删除所有收藏项
                    self.realm.delete(items)
                    // 删除文件夹
                    self.realm.delete(folder)
                }
                
                promise(.success(true))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItem], Error> {
        return Future<[FavoriteItem], Error> { promise in
            do {
                guard self.realm.object(ofType: Folder.self, forPrimaryKey: folderId) != nil else {
                    promise(.failure(FavoriteError.folderNotFound))
                    return
                }
                
                let items = self.realm.objects(FavoriteItem.self)
                    .filter("folderId == %@", folderId)
                    .sorted(byKeyPath: "addedAt", ascending: false)
                
                let paginatedItems = Array(items.suffix(from: offset).prefix(limit))
                promise(.success(paginatedItems))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItem, Error> {
        return Future<FavoriteItem, Error> { promise in
            do {
                // 检查文件夹是否存在
                guard let folder = self.realm.object(ofType: Folder.self, forPrimaryKey: folderId) else {
                    promise(.failure(FavoriteError.folderNotFound))
                    return
                }
                
                // 检查单词是否存在
                guard let word = self.realm.object(ofType: DictEntry.self, forPrimaryKey: wordId) else {
                    promise(.failure(FavoriteError.itemNotFound))
                    return
                }
                
                // 检查是否已经收藏过
                let existingItems = self.realm.objects(FavoriteItem.self)
                    .filter("wordId == %@ AND folderId == %@", wordId, folderId)
                
                if !existingItems.isEmpty {
                    // 已经收藏过，返回现有项
                    promise(.success(existingItems.first!))
                    return
                }
                
                // 创建新的收藏项
                let item = FavoriteItem()
                item.wordId = wordId
                item.folderId = folderId
                item.word = word.word
                item.reading = word.reading
                item.meaning = word.definitions.first?.meaning ?? ""
                item.note = note
                item.addedAt = Date()
                item.syncStatus = UISyncStatus.pendingUpload.rawValue
                
                try self.realm.write {
                    self.realm.add(item)
                }
                
                promise(.success(item))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItem, Error> {
        return Future<FavoriteItem, Error> { promise in
            do {
                guard let item = self.realm.object(ofType: FavoriteItem.self, forPrimaryKey: id) else {
                    promise(.failure(FavoriteError.itemNotFound))
                    return
                }
                
                try self.realm.write {
                    item.note = note
                    item.syncStatus = UISyncStatus.pendingUpload.rawValue
                }
                
                promise(.success(item))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            do {
                guard let item = self.realm.object(ofType: FavoriteItem.self, forPrimaryKey: id) else {
                    promise(.failure(FavoriteError.itemNotFound))
                    return
                }
                
                try self.realm.write {
                    self.realm.delete(item)
                }
                
                promise(.success(true))
            } catch {
                promise(.failure(FavoriteError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let items = self.realm.objects(FavoriteItem.self)
                .filter("wordId == %@", wordId)
            
            promise(.success(!items.isEmpty))
        }.eraseToAnyPublisher()
    }
}