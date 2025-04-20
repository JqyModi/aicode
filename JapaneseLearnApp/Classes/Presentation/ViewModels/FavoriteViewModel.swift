//
//  FavoriteViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class FavoriteViewModel: FavoriteViewModelProtocol {
    // MARK: - 依赖注入
    private let favoriteService: FavoriteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 分页控制
    private let pageSize = 20
    private var currentOffset = 0
    private var hasMoreItems = true
    
    // MARK: - 输出属性
    @Published private(set) var folders: [FolderSummaryViewModel] = []
    @Published private(set) var selectedFolder: FolderSummaryViewModel? = nil
    @Published private(set) var folderItems: [FavoriteItemDetailViewModel] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - 初始化
    init(favoriteService: FavoriteServiceProtocol) {
        self.favoriteService = favoriteService
    }
    
    // MARK: - 公开方法
    func loadFolders() {
        isLoading = true
        errorMessage = nil
        
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取收藏夹列表失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] folders in
                    self?.folders = folders.map { self?.mapToFolderSummaryViewModel($0) ?? FolderSummaryViewModel(id: "", name: "", createdAt: Date(), itemCount: 0, syncStatus: "none") }
                    // 如果有收藏夹且没有选中的收藏夹，则默认选中第一个
                    if self?.selectedFolder == nil, let firstFolder = self?.folders.first {
                        self?.selectFolder(id: firstFolder.id)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createFolder(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "收藏夹名称不能为空"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        favoriteService.createFolder(name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "创建收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] folder in
                    let newFolder = self?.mapToFolderSummaryViewModel(folder) ?? FolderSummaryViewModel(id: "", name: "", createdAt: Date(), itemCount: 0, syncStatus: "none")
                    self?.folders.append(newFolder)
                    self?.selectFolder(id: newFolder.id)
                }
            )
            .store(in: &cancellables)
    }
    
    func renameFolder(id: String, newName: String) {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "收藏夹名称不能为空"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        favoriteService.updateFolder(id: id, name: newName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "重命名收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] folder in
                    guard let self = self else { return }
                    if let index = self.folders.firstIndex(where: { $0.id == id }) {
                        self.folders[index] = self.mapToFolderSummaryViewModel(folder)
                    }
                    
                    // 更新选中的收藏夹
                    if self.selectedFolder?.id == id {
                        self.selectedFolder = self.mapToFolderSummaryViewModel(folder)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteFolder(id: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.deleteFolder(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "删除收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self = self, success else { return }
                    
                    // 从列表中移除
                    self.folders.removeAll { $0.id == id }
                    
                    // 如果删除的是当前选中的收藏夹，则选择第一个收藏夹（如果有）
                    if self.selectedFolder?.id == id {
                        self.selectedFolder = self.folders.first
                        if let newSelectedFolder = self.selectedFolder {
                            self.loadFolderItems(folderId: newSelectedFolder.id)
                        } else {
                            self.folderItems = []
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func selectFolder(id: String) {
        guard let folder = folders.first(where: { $0.id == id }) else {
            errorMessage = "收藏夹不存在"
            return
        }
        
        selectedFolder = folder
        loadFolderItems(folderId: id)
    }
    
    func loadFolderItems(folderId: String) {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMoreItems = true
        folderItems = []
        
        favoriteService.getFolderItems(folderId: folderId, limit: pageSize, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取收藏夹内容失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] content in
                    guard let self = self else { return }
                    self.folderItems = content.items.map { self.mapToFavoriteItemDetailViewModel($0) }
                    self.currentOffset += content.items.count
                    self.hasMoreItems = content.items.count >= self.pageSize && content.total > self.currentOffset
                }
            )
            .store(in: &cancellables)
    }
    
    func updateNote(itemId: String, note: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.updateFavoriteNote(id: itemId, note: note)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "更新笔记失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] updatedItem in
                    guard let self = self else { return }
                    if let index = self.folderItems.firstIndex(where: { $0.id == itemId }) {
                        self.folderItems[index] = self.mapToFavoriteItemDetailViewModel(updatedItem)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func removeFromFavorites(itemId: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.deleteFavorite(id: itemId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "删除收藏失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self = self, success else { return }
                    self.folderItems.removeAll { $0.id == itemId }
                    
                    // 更新收藏夹的计数
                    if let selectedFolder = self.selectedFolder,
                       let index = self.folders.firstIndex(where: { $0.id == selectedFolder.id }) {
                        var updatedFolder = self.folders[index]
                        updatedFolder = FolderSummaryViewModel(
                            id: updatedFolder.id,
                            name: updatedFolder.name,
                            createdAt: updatedFolder.createdAt,
                            itemCount: max(0, updatedFolder.itemCount - 1),
                            syncStatus: updatedFolder.syncStatus
                        )
                        self.folders[index] = updatedFolder
                        
                        if self.selectedFolder?.id == updatedFolder.id {
                            self.selectedFolder = updatedFolder
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMoreItems() {
        guard let selectedFolder = selectedFolder, !isLoading, hasMoreItems else { return }
        
        isLoading = true
        errorMessage = nil
        
        favoriteService.getFolderItems(folderId: selectedFolder.id, limit: pageSize, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载更多收藏项失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] content in
                    guard let self = self else { return }
                    let newItems = content.items.map { self.mapToFavoriteItemDetailViewModel($0) }
                    self.folderItems.append(contentsOf: newItems)
                    self.currentOffset += content.items.count
                    self.hasMoreItems = content.items.count >= self.pageSize && content.total > self.currentOffset
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 私有方法 - 数据模型转换
    private func mapToFolderSummaryViewModel(_ domain: FolderSummaryDomain) -> FolderSummaryViewModel {
        return FolderSummaryViewModel(
            id: domain.id,
            name: domain.name,
            createdAt: domain.createdAt,
            itemCount: domain.itemCount,
            syncStatus: domain.syncStatus.rawValue
        )
    }
    
    private func mapToFavoriteItemDetailViewModel(_ domain: FavoriteItemDetailDomain) -> FavoriteItemDetailViewModel {
        return FavoriteItemDetailViewModel(
            id: domain.id,
            wordId: domain.wordId,
            word: domain.word,
            reading: domain.reading,
            meaning: domain.meaning,
            note: domain.note,
            addedAt: domain.addedAt,
            syncStatus: domain.syncStatus.rawValue
        )
    }
}