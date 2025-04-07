//
//  FavoriteManagementUseCase.swift
//  JapaneseApp
//
//  Created by Trae AI on 2025/04/07.
//

import Foundation
import Combine

// MARK: - 收藏项管理用例协议
public protocol FavoriteManagementUseCaseProtocol {
    // 添加收藏
    func addFavorite(wordId: String, word: String, reading: String, meaning: String, folderId: String?, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 更新收藏笔记
    func updateNote(favoriteId: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 删除收藏
    func removeFavorite(favoriteId: String) -> AnyPublisher<Bool, FavoriteError>
    
    // 移动收藏到其他收藏夹
    func moveFavoriteToFolder(favoriteId: String, targetFolderId: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 批量删除收藏
    func removeFavorites(favoriteIds: [String]) -> AnyPublisher<Int, FavoriteError>
    
    // 批量移动收藏
    func moveFavoritesToFolder(favoriteIds: [String], targetFolderId: String) -> AnyPublisher<Int, FavoriteError>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, FavoriteError>
}

// MARK: - 收藏项管理用例实现
public class FavoriteManagementUseCase: FavoriteManagementUseCaseProtocol {
    private let favoriteService: FavoriteServiceProtocol
    private let folderUseCase: FolderManagementUseCaseProtocol
    
    public init(favoriteService: FavoriteServiceProtocol, folderUseCase: FolderManagementUseCaseProtocol) {
        self.favoriteService = favoriteService
        self.folderUseCase = folderUseCase
    }
    
    // 添加收藏
    public func addFavorite(wordId: String, word: String, reading: String, meaning: String, folderId: String?, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        // 如果没有指定收藏夹，则使用默认收藏夹
        if let folderId = folderId {
            return favoriteService.addFavorite(wordId: wordId, folderId: folderId, note: note)
                .eraseToAnyPublisher()
        } else {
            return folderUseCase.getDefaultFolder()
                .flatMap { defaultFolder in
                    return self.favoriteService.addFavorite(wordId: wordId, folderId: defaultFolder.id, note: note)
                }
                .eraseToAnyPublisher()
        }
    }
    
    // 更新收藏笔记
    public func updateNote(favoriteId: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        return favoriteService.updateFavoriteNote(id: favoriteId, note: note)
            .eraseToAnyPublisher()
    }
    
    // 删除收藏
    public func removeFavorite(favoriteId: String) -> AnyPublisher<Bool, FavoriteError> {
        return favoriteService.deleteFavorite(id: favoriteId)
            .eraseToAnyPublisher()
    }
    
    // 移动收藏到其他收藏夹
    public func moveFavoriteToFolder(favoriteId: String, targetFolderId: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError> {
        // 这个功能需要先获取收藏项，然后删除原收藏项，再在目标收藏夹中创建新收藏项
        // 由于数据层没有直接提供移动功能，我们需要在业务层实现这个逻辑
        
        // 获取所有收藏夹内容，找到包含该收藏项的收藏夹
        return favoriteService.getAllFolders()
            .flatMap { folders -> AnyPublisher<(FolderContent, FolderSummary), FavoriteError> in
                // 为每个收藏夹获取内容
                let contentPublishers = folders.map { folder in
                    self.favoriteService.getFolderItems(folderId: folder.id, limit: 1000, offset: 0)
                        .map { content in (content, folder) }
                }
                
                // 合并所有结果
                return Publishers.MergeMany(contentPublishers)
                    .first { folderWithContent in
                        // 找到包含该收藏项的收藏夹
                        folderWithContent.0.items.contains { $0.id == favoriteId }
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { folderContent, sourceFolder -> AnyPublisher<FavoriteItemDetail, FavoriteError> in
                // 找到收藏项
                guard let favoriteItem = folderContent.items.first(where: { $0.id == favoriteId }) else {
                    return Fail(error: FavoriteError.itemNotFound).eraseToAnyPublisher()
                }
                
                // 如果源收藏夹和目标收藏夹相同，则不需要移动
                if sourceFolder.id == targetFolderId {
                    return Just(favoriteItem)
                        .setFailureType(to: FavoriteError.self)
                        .eraseToAnyPublisher()
                }
                
                // 删除原收藏项，然后在目标收藏夹中创建新收藏项
                return self.favoriteService.deleteFavorite(id: favoriteId)
                    .flatMap { _ -> AnyPublisher<FavoriteItemDetail, FavoriteError> in
                        return self.favoriteService.addFavorite(
                            wordId: favoriteItem.wordId,
                            folderId: targetFolderId,
                            note: favoriteItem.note
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // 批量删除收藏
    public func removeFavorites(favoriteIds: [String]) -> AnyPublisher<Int, FavoriteError> {
        // 为每个收藏项创建删除操作
        let deleteOperations = favoriteIds.map { favoriteId in
            favoriteService.deleteFavorite(id: favoriteId)
                .map { success -> Int in
                    return success ? 1 : 0
                }
                .catch { error -> AnyPublisher<Int, FavoriteError> in
                    // 忽略单个删除失败，继续处理其他项
                    return Just(0)
                        .setFailureType(to: FavoriteError.self)
                        .eraseToAnyPublisher()
                }
        }
        
        // 合并所有删除操作的结果
        return Publishers.MergeMany(deleteOperations)
            .collect()
            .map { results in
                // 返回成功删除的数量
                return results.reduce(0, +)
            }
            .eraseToAnyPublisher()
    }
    
    // 批量移动收藏
    public func moveFavoritesToFolder(favoriteIds: [String], targetFolderId: String) -> AnyPublisher<Int, FavoriteError> {
        // 为每个收藏项创建移动操作
        let moveOperations = favoriteIds.map { favoriteId in
            moveFavoriteToFolder(favoriteId: favoriteId, targetFolderId: targetFolderId)
                .map { _ -> Int in
                    return 1
                }
                .catch { error -> AnyPublisher<Int, FavoriteError> in
                    // 忽略单个移动失败，继续处理其他项
                    return Just(0)
                        .setFailureType(to: FavoriteError.self)
                        .eraseToAnyPublisher()
                }
        }
        
        // 合并所有移动操作的结果
        return Publishers.MergeMany(moveOperations)
            .collect()
            .map { results in
                // 返回成功移动的数量
                return results.reduce(0, +)
            }
            .eraseToAnyPublisher()
    }
    
    // 检查单词是否已收藏
    public func isWordFavorited(wordId: String) -> AnyPublisher<Bool, FavoriteError> {
        // 这里需要调用数据层的接口，但FavoriteServiceProtocol中没有直接提供这个方法
        // 我们可以通过获取所有收藏夹内容，然后检查是否包含该单词来实现
        
        return favoriteService.getAllFolders()
            .flatMap { folders -> AnyPublisher<Bool, FavoriteError> in
                // 如果没有收藏夹，则肯定没有收藏
                if folders.isEmpty {
                    return Just(false)
                        .setFailureType(to: FavoriteError.self)
                        .eraseToAnyPublisher()
                }
                
                // 为每个收藏夹获取内容
                let contentPublishers = folders.map { folder in
                    self.favoriteService.getFolderItems(folderId: folder.id, limit: 1000, offset: 0)
                        .map { content in
                            // 检查该收藏夹中是否包含该单词
                            content.items.contains { $0.wordId == wordId }
                        }
                }
                
                // 合并所有结果，只要有一个为true，就表示已收藏
                return Publishers.MergeMany(contentPublishers)
                    .contains(true)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}