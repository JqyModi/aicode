//
//  FolderManagementUseCase.swift
//  JapaneseApp
//
//  Created by Trae AI on 2025/04/07.
//

import Foundation
import Combine

// MARK: - 收藏夹管理用例协议
public protocol FolderManagementUseCaseProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError>
    
    // 获取收藏夹内容
    func getFolderContent(folderId: String, page: Int, pageSize: Int) -> AnyPublisher<FolderContent, FavoriteError>
    
    // 获取默认收藏夹
    func getDefaultFolder() -> AnyPublisher<FolderSummary, FavoriteError>
}

// MARK: - 收藏夹管理用例实现
public class FolderManagementUseCase: FolderManagementUseCaseProtocol {
    private let favoriteService: FavoriteServiceProtocol
    private let defaultFolderName = "默认收藏夹"
    
    public init(favoriteService: FavoriteServiceProtocol) {
        self.favoriteService = favoriteService
    }
    
    // 获取所有收藏夹
    public func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError> {
        return favoriteService.getAllFolders()
            .map { folders in
                // 确保默认收藏夹始终排在第一位
                var sortedFolders = folders
                if let defaultIndex = folders.firstIndex(where: { $0.name == self.defaultFolderName }) {
                    let defaultFolder = sortedFolders.remove(at: defaultIndex)
                    sortedFolders.insert(defaultFolder, at: 0)
                }
                return sortedFolders
            }
            .eraseToAnyPublisher()
    }
    
    // 创建收藏夹
    public func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        // 验证收藏夹名称
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Fail(error: FavoriteError.duplicateName).eraseToAnyPublisher()
        }
        
        // 检查是否与默认收藏夹同名
        if name.trimmingCharacters(in: .whitespacesAndNewlines) == defaultFolderName {
            return Fail(error: FavoriteError.duplicateName).eraseToAnyPublisher()
        }
        
        // 创建收藏夹
        return favoriteService.createFolder(name: name)
            .eraseToAnyPublisher()
    }
    
    // 更新收藏夹
    public func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError> {
        // 验证收藏夹名称
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Fail(error: FavoriteError.duplicateName).eraseToAnyPublisher()
        }
        
        // 获取所有收藏夹，检查是否存在同名收藏夹
        return favoriteService.getAllFolders()
            .flatMap { folders -> AnyPublisher<FolderSummary, FavoriteError> in
                // 检查是否为默认收藏夹
                if let folder = folders.first(where: { $0.id == id }),
                   folder.name == self.defaultFolderName {
                    return Fail(error: FavoriteError.duplicateName).eraseToAnyPublisher()
                }
                
                // 检查是否与其他收藏夹同名
                if folders.contains(where: { $0.name == name && $0.id != id }) {
                    return Fail(error: FavoriteError.duplicateName).eraseToAnyPublisher()
                }
                
                // 更新收藏夹
                return self.favoriteService.updateFolder(id: id, name: name)
            }
            .eraseToAnyPublisher()
    }
    
    // 删除收藏夹
    public func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError> {
        // 获取所有收藏夹，检查是否为默认收藏夹
        return favoriteService.getAllFolders()
            .flatMap { folders -> AnyPublisher<Bool, FavoriteError> in
                // 检查是否为默认收藏夹
                if let folder = folders.first(where: { $0.id == id }),
                   folder.name == self.defaultFolderName {
                    return Fail(error: FavoriteError.folderNotFound).eraseToAnyPublisher()
                }
                
                // 删除收藏夹
                return self.favoriteService.deleteFolder(id: id)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取收藏夹内容
    public func getFolderContent(folderId: String, page: Int, pageSize: Int) -> AnyPublisher<FolderContent, FavoriteError> {
        let offset = max(0, page - 1) * pageSize
        return favoriteService.getFolderItems(folderId: folderId, limit: pageSize, offset: offset)
            .eraseToAnyPublisher()
    }
    
    // 获取默认收藏夹
    public func getDefaultFolder() -> AnyPublisher<FolderSummary, FavoriteError> {
        return favoriteService.getAllFolders()
            .flatMap { folders -> AnyPublisher<FolderSummary, FavoriteError> in
                // 查找默认收藏夹
                if let defaultFolder = folders.first(where: { $0.name == self.defaultFolderName }) {
                    return Just(defaultFolder)
                        .setFailureType(to: FavoriteError.self)
                        .eraseToAnyPublisher()
                }
                
                // 如果不存在默认收藏夹，则创建一个
                return self.favoriteService.createFolder(name: self.defaultFolderName)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}