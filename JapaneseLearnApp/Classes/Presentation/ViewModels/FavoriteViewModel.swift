import Foundation
import Combine
import SwiftUI

protocol FavoriteViewModelProtocol: ObservableObject {
    // 输出属性
    var folders: [FolderSummary] { get }
    var selectedFolder: FolderSummary? { get }
    var folderItems: [FavoriteItemDetail] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadFolders()
    func createFolder(name: String)
    func renameFolder(id: String, newName: String)
    func deleteFolder(id: String)
    func selectFolder(id: String)
    func loadFolderItems(folderId: String)
    func updateNote(itemId: String, note: String)
    func removeFromFavorites(itemId: String)
    func loadMoreItems()
}

class FavoriteViewModel: ObservableObject, FavoriteViewModelProtocol {
    // MARK: - 输出属性
    @Published var folders: [FolderSummary] = []
    @Published var selectedFolder: FolderSummary?
    @Published var folderItems: [FavoriteItemDetail] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    private let favoriteService: FavoriteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var hasMoreItems: Bool = true
    
    // MARK: - 初始化
    init(favoriteService: FavoriteServiceProtocol) {
        self.favoriteService = favoriteService
    }
    
    // MARK: - 公共方法
    /// 加载所有收藏夹
    func loadFolders() {
        isLoading = true
        errorMessage = nil
        
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folders in
                    self?.folders = folders
                    // 如果有收藏夹且没有选中的收藏夹，则选择第一个
                    if !folders.isEmpty && self?.selectedFolder == nil {
                        self?.selectedFolder = folders[0]
                        self?.loadFolderItems(folderId: folders[0].id)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 创建收藏夹
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
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folder in
                    guard let self = self else { return }
                    // 添加新创建的收藏夹到列表
                    self.folders.append(folder)
                    // 选中新创建的收藏夹
                    self.selectedFolder = folder
                    // 清空当前项目列表，因为是新收藏夹
                    self.folderItems = []
                    self.currentPage = 0
                    self.hasMoreItems = true
                }
            )
            .store(in: &cancellables)
    }
    
    /// 重命名收藏夹
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
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedFolder in
                    guard let self = self else { return }
                    // 更新收藏夹列表中的对应项
                    if let index = self.folders.firstIndex(where: { $0.id == id }) {
                        self.folders[index] = updatedFolder
                    }
                    // 如果当前选中的是被重命名的收藏夹，也更新选中的收藏夹
                    if self.selectedFolder?.id == id {
                        self.selectedFolder = updatedFolder
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 删除收藏夹
    func deleteFolder(id: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.deleteFolder(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self = self, success else { return }
                    // 从列表中移除被删除的收藏夹
                    self.folders.removeAll { $0.id == id }
                    
                    // 如果删除的是当前选中的收藏夹，则重置选中状态
                    if self.selectedFolder?.id == id {
                        self.selectedFolder = self.folders.first
                        if let newSelected = self.selectedFolder {
                            self.loadFolderItems(folderId: newSelected.id)
                        } else {
                            self.folderItems = []
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 选择收藏夹
    func selectFolder(id: String) {
        guard let folder = folders.first(where: { $0.id == id }) else {
            errorMessage = "收藏夹不存在"
            return
        }
        
        selectedFolder = folder
        // 重置分页状态
        currentPage = 0
        hasMoreItems = true
        folderItems = []
        // 加载选中收藏夹的内容
        loadFolderItems(folderId: id)
    }
    
    /// 加载收藏夹内容
    func loadFolderItems(folderId: String) {
        guard hasMoreItems else { return }
        
        isLoading = true
        errorMessage = nil
        
        favoriteService.getFolderItems(folderId: folderId, limit: pageSize, offset: currentPage * pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] content in
                    guard let self = self else { return }
                    
                    // 如果是第一页，则替换现有内容；否则追加
                    if self.currentPage == 0 {
                        self.folderItems = content.items
                    } else {
                        self.folderItems.append(contentsOf: content.items)
                    }
                    
                    // 更新分页状态
                    self.currentPage += 1
                    self.hasMoreItems = self.folderItems.count < content.total
                }
            )
            .store(in: &cancellables)
    }
    
    /// 更新收藏笔记
    func updateNote(itemId: String, note: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.updateFavoriteNote(id: itemId, note: note)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedItem in
                    guard let self = self else { return }
                    // 更新列表中的对应项
                    if let index = self.folderItems.firstIndex(where: { $0.id == itemId }) {
                        self.folderItems[index] = updatedItem
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 从收藏中移除
    func removeFromFavorites(itemId: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.deleteFavorite(id: itemId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    guard let self = self, success else { return }
                    // 从列表中移除被删除的收藏项
                    self.folderItems.removeAll { $0.id == itemId }
                    
                    // 如果当前选中的收藏夹存在，更新其计数
                    if let selectedFolder = self.selectedFolder,
                       let index = self.folders.firstIndex(where: { $0.id == selectedFolder.id }) {
                        // 创建一个新的FolderSummary对象，itemCount减1
                        let updatedFolder = FolderSummary(
                            id: selectedFolder.id,
                            name: selectedFolder.name,
                            createdAt: selectedFolder.createdAt,
                            itemCount: max(0, selectedFolder.itemCount - 1),
                            syncStatus: selectedFolder.syncStatus
                        )
                        self.folders[index] = updatedFolder
                        self.selectedFolder = updatedFolder
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载更多项目
    func loadMoreItems() {
        guard let selectedFolder = selectedFolder else { return }
        loadFolderItems(folderId: selectedFolder.id)
    }
    
    // MARK: - 私有方法
    /// 处理错误
    private func handleError(_ error: Error) {
        if let favoriteError = error as? FavoriteError {
            switch favoriteError {
            case .folderNotFound:
                errorMessage = "收藏夹不存在"
            case .itemNotFound:
                errorMessage = "收藏项不存在"
            case .duplicateName:
                errorMessage = "收藏夹名称已存在"
            case .databaseError:
                errorMessage = "数据库错误"
            case .syncError:
                errorMessage = "同步错误"
            case .unknown:
                errorMessage = "未知错误"
            }
        } else {
            errorMessage = "发生错误: \(error.localizedDescription)"
        }
    }
}