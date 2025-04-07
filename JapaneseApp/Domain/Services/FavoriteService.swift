//
//  FavoriteService.swift
//  JapaneseApp
//
//  Created by Trae AI on 2025/04/07.
//

import Foundation
import Combine

// MARK: - 收藏服务协议
public protocol FavoriteServiceProtocol {
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
}

// MARK: - 数据层仓库协议
public protocol FavoriteRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItem], Error>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItem, Error>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹中的项目总数
    func getFolderItemCount(folderId: String) -> AnyPublisher<Int, Error>
}

// MARK: - 收藏服务实现
public class FavoriteService: FavoriteServiceProtocol {
    private let repository: FavoriteRepositoryProtocol
    
    public init(repository: FavoriteRepositoryProtocol) {
        self.repository = repository
    }
    
    // 获取所有收藏夹
    public func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError> {
        return repository.getAllFolders()
            .flatMap { folders -> AnyPublisher<[FolderSummary], Error> in
                let folderIds = folders.map { $0.id }
                
                // 为每个收藏夹获取项目数量
                let countPublishers = folderIds.map { folderId in
                    self.repository.getFolderItemCount(folderId: folderId)
                        .map { count in (folderId, count) }
                }
                
                // 合并所有计数结果
                return Publishers.MergeMany(countPublishers)
                    .collect()
                    .map { countResults in
                        // 创建ID到计数的映射
                        let countMap = Dictionary(uniqueKeysWithValues: countResults)
                        
                        // 转换为FolderSummary对象
                        return folders.map { folder in
                            FolderSummary(
                                id: folder.id,
                                name: folder.name,
                                createdAt: folder.createdAt,
                                itemCount: countMap[folder.id] ?? 0,
                                syncStatus: SyncStatus(rawValue: folder.syncStatus) ?? .synced
                            )
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 创建收藏夹
    public func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        return repository.createFolder(name: name)
            .map { folder in
                FolderSummary(
                    id: folder.id,
                    name: folder.name,
                    createdAt: folder.createdAt,
                    itemCount: 0,
                    syncStatus: SyncStatus(rawValue: folder.syncStatus) ?? .pendingUpload
                )
            }
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 更新收藏夹
    public func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        return repository.updateFolder(id: id, name: name)
            .flatMap { folder -> AnyPublisher<FolderSummary, Error> in
                return self.repository.getFolderItemCount(folderId: folder.id)
                    .map { count in
                        FolderSummary(
                            id: folder.id,
                            name: folder.name,
                            createdAt: folder.createdAt,
                            itemCount: count,
                            syncStatus: SyncStatus(rawValue: folder.syncStatus) ?? .pendingUpload
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 删除收藏夹
    public func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError> {
        return repository.deleteFolder(id: id)
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 获取收藏夹内容
    public func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContent, FavoriteError> {
        return Publishers.Zip(
            repository.getFolderItems(folderId: folderId, limit: limit, offset: offset),
            repository.getFolderItemCount(folderId: folderId)
        )
        .map { (items, total) in
            let favoriteItems = items.map { item in
                FavoriteItemDetail(
                    id: item.id,
                    wordId: item.wordId,
                    word: item.word,
                    reading: item.reading,
                    meaning: item.meaning,
                    note: item.note,
                    addedAt: item.addedAt,
                    syncStatus: SyncStatus(rawValue: item.syncStatus) ?? .synced
                )
            }
            return FolderContent(total: total, items: favoriteItems)
        }
        .mapError { self.mapError($0) }
        .eraseToAnyPublisher()
    }
    
    // 添加收藏
    public func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        return repository.addFavorite(wordId: wordId, folderId: folderId, note: note)
            .map { item in
                FavoriteItemDetail(
                    id: item.id,
                    wordId: item.wordId,
                    word: item.word,
                    reading: item.reading,
                    meaning: item.meaning,
                    note: item.note,
                    addedAt: item.addedAt,
                    syncStatus: SyncStatus(rawValue: item.syncStatus) ?? .pendingUpload
                )
            }
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 更新收藏笔记
    public func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        return repository.updateFavoriteNote(id: id, note: note)
            .map { item in
                FavoriteItemDetail(
                    id: item.id,
                    wordId: item.wordId,
                    word: item.word,
                    reading: item.reading,
                    meaning: item.meaning,
                    note: item.note,
                    addedAt: item.addedAt,
                    syncStatus: SyncStatus(rawValue: item.syncStatus) ?? .pendingUpload
                )
            }
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 删除收藏
    public func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteError> {
        return repository.deleteFavorite(id: id)
            .mapError { self.mapError($0) }
            .eraseToAnyPublisher()
    }
    
    // 错误映射
    private func mapError(_ error: Error) -> FavoriteError {
        if let favoriteError = error as? FavoriteError {
            return favoriteError
        }
        
        // 根据错误类型映射到业务层错误
        let nsError = error as NSError
        if nsError.domain == "io.realm" {
            return .databaseError(nsError.localizedDescription)
        } else if nsError.domain == "com.apple.cloudkit" {
            return .syncError(nsError.localizedDescription)
        } else if nsError.code == 404 {
            return .itemNotFound
        } else if nsError.code == 409 {
            return .duplicateName
        }
        
        return .databaseError(error.localizedDescription)
    }
}