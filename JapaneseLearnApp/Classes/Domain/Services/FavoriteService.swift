//
//  FavoriteService.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class FavoriteService: FavoriteServiceProtocol {
    // MARK: - 属性
    private let favoriteRepository: FavoriteDataRepositoryProtocol
    
    // MARK: - 初始化
    init(favoriteRepository: FavoriteDataRepositoryProtocol) {
        self.favoriteRepository = favoriteRepository
    }
    
    // MARK: - FavoriteServiceProtocol 实现
    func getAllFolders() -> AnyPublisher<[FolderSummaryDomain], FavoriteErrorDomain> {
        return favoriteRepository.getAllFolders()
            .map { entities -> [FolderSummaryDomain] in
                return entities.map { self.mapToFolderSummaryDomain(from: $0) }
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func createFolder(name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain> {
        return favoriteRepository.createFolder(name: name)
            .map { entity -> FolderSummaryDomain in
                return self.mapToFolderSummaryDomain(from: entity)
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain> {
        return favoriteRepository.updateFolder(id: id, name: name)
            .map { entity -> FolderSummaryDomain in
                return self.mapToFolderSummaryDomain(from: entity)
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteErrorDomain> {
        return favoriteRepository.deleteFolder(id: id)
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContentDomain, FavoriteErrorDomain> {
        return favoriteRepository.getFolderItems(folderId: folderId, limit: limit, offset: offset)
            .map { entities -> FolderContentDomain in
                let items = entities.map { self.mapToFavoriteItemDetailDomain(from: $0) }
                return FolderContentDomain(total: items.count, items: items)
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain> {
        return favoriteRepository.addFavorite(wordId: wordId, folderId: folderId, note: note)
            .map { entity -> FavoriteItemDetailDomain in
                return self.mapToFavoriteItemDetailDomain(from: entity)
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain> {
        return favoriteRepository.updateFavoriteNote(id: id, note: note)
            .map { entity -> FavoriteItemDetailDomain in
                return self.mapToFavoriteItemDetailDomain(from: entity)
            }
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteErrorDomain> {
        return favoriteRepository.deleteFavorite(id: id)
            .mapError { error -> FavoriteErrorDomain in
                return self.mapToFavoriteError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 私有映射方法
    private func mapToFolderSummaryDomain(from entity: FolderEntity) -> FolderSummaryDomain {
        let syncStatus: SyncStatusDomain = mapToSyncStatusDomain(from: entity.syncStatus)
        
        return FolderSummaryDomain(
            id: entity.id,
            name: entity.name,
            createdAt: entity.createdAt,
            itemCount: entity.itemCount, // 使用从数据库查询的实际项目数量
            syncStatus: syncStatus
        )
    }
    
    private func mapToFavoriteItemDetailDomain(from entity: FavoriteItemEntity) -> FavoriteItemDetailDomain {
        let syncStatus: SyncStatusDomain = mapToSyncStatusDomain(from: entity.syncStatus)
        
        return FavoriteItemDetailDomain(
            id: entity.id,
            wordId: entity.wordId,
            word: entity.word,
            reading: entity.reading,
            meaning: entity.meaning,
            note: entity.note,
            addedAt: entity.addedAt,
            syncStatus: syncStatus
        )
    }
    
    private func mapToSyncStatusDomain(from statusCode: Int) -> SyncStatusDomain {
        switch statusCode {
        case 0:
            return .synced
        case 1:
            return .pendingUpload
        case 2:
            return .pendingDownload
        case 3:
            return .conflict
        case 4:
            return .error
        default:
            return .none
        }
    }
    
    private func mapToFavoriteError(_ error: Error) -> FavoriteErrorDomain {
        // 根据错误类型映射到业务层错误
        if error.localizedDescription.contains("not found") || error.localizedDescription.contains("未找到") {
            if error.localizedDescription.contains("folder") || error.localizedDescription.contains("收藏夹") {
                return .folderNotFound
            } else {
                return .itemNotFound
            }
        } else if error.localizedDescription.contains("duplicate") || error.localizedDescription.contains("重复") {
            return .duplicateName
        } else if error.localizedDescription.contains("sync") || error.localizedDescription.contains("同步") {
            return .syncError
        }
        
        // 默认返回数据库错误
        return .databaseError
    }
}