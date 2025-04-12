import Foundation
import Combine
import SwiftUI
import AVFoundation

protocol DetailViewModelProtocol: ObservableObject {
    // 输出属性
    var wordDetails: WordDetails? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isFavorited: Bool { get }
    var relatedWords: [WordListItem] { get }  // 添加相关词汇属性
    
    // 方法
    func loadWordDetails(id: String)
    func playPronunciation(speed: Float)
    func toggleFavorite()
    func addNote(note: String)
}

// MARK: - 详情视图模型
class DetailViewModel: ObservableObject, DetailViewModelProtocol {
    // MARK: - 输出属性
    @Published private(set) var wordDetails: WordDetails?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isFavorited: Bool = false
    @Published private(set) var relatedWords: [WordListItem] = []  // 添加相关词汇属性
    
    // MARK: - 私有属性
    private var currentWordId: String?
    private var audioPlayer: AVAudioPlayer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 依赖
    private let dictionaryService: DictionaryServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    
    // MARK: - 初始化
    init(dictionaryService: DictionaryServiceProtocol, favoriteService: FavoriteServiceProtocol) {
        self.dictionaryService = dictionaryService
        self.favoriteService = favoriteService
    }
    
    // MARK: - 公共方法
    
    /// 加载单词详情
    func loadWordDetails(id: String) {
        guard id != currentWordId || wordDetails == nil else {
            return
        }
        
        currentWordId = id
        isLoading = true
        errorMessage = nil
        
        // 创建一个组合发布者来同时获取详情和相关词汇
        Publishers.Zip(
            dictionaryService.getWordDetails(id: id),
            dictionaryService.getRelatedWords(id: id)
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] details, related in
                var updatedDetails = details
                updatedDetails.relatedWords = related  // 更新相关词汇
                self?.wordDetails = updatedDetails
                self?.relatedWords = related
                self?.isFavorited = details.isFavorited
            }
        )
        .store(in: &cancellables)
    }
    
    /// 播放单词发音
    func playPronunciation(speed: Float = 1.0) {
        guard let id = currentWordId else {
            errorMessage = "没有选中的单词"
            return
        }
        
        isLoading = true
        
        dictionaryService.getWordPronunciation(id: id, speed: speed)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] audioURL in
                    self?.playAudio(from: audioURL)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 切换收藏状态
    func toggleFavorite() {
        guard let wordDetails = wordDetails, let id = currentWordId else {
            errorMessage = "没有选中的单词"
            return
        }
        
        if isFavorited {
            // 查找并移除收藏
            findAndRemoveFavorite(wordId: id)
        } else {
            // 添加到默认收藏夹
            addToDefaultFolder(wordDetails: wordDetails)
        }
    }
    
    /// 添加笔记
    func addNote(note: String) {
        guard let wordDetails = wordDetails, let id = currentWordId, isFavorited else {
            errorMessage = "请先收藏单词"
            return
        }
        
        // 查找收藏项并更新笔记
        findFavoriteAndUpdateNote(wordId: id, note: note)
    }
    
    // MARK: - 私有方法
    
    /// 播放音频
    private func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            errorMessage = "无法播放发音: \(error.localizedDescription)"
        }
    }
    
    /// 处理错误
    private func handleError(_ error: Error) {
        if let dictError = error as? DictionaryError {
            switch dictError {
            case .notFound:
                errorMessage = "未找到单词"
            case .pronunciationFailed:
                errorMessage = "获取发音失败"
            case .searchFailed:
                errorMessage = "搜索失败"
            case .databaseError:
                errorMessage = "数据库错误"
            case .networkError:
                errorMessage = "网络错误"
            default:
                errorMessage = dictError.localizedDescription
            }
        } else if let favError = error as? FavoriteError {
            switch favError {
            case .folderNotFound:
                errorMessage = "收藏夹不存在"
            case .itemNotFound:
                errorMessage = "收藏项不存在"
            case .duplicateName:
                errorMessage = "收藏夹名称重复"
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
    
    /// 查找并移除收藏
    private func findAndRemoveFavorite(wordId: String) {
        // 先获取所有收藏夹
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folders in
                    guard let self = self else { return }
                    self.searchInFoldersAndRemove(folders: folders, wordId: wordId)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 在所有收藏夹中查找并删除收藏项
    private func searchInFoldersAndRemove(folders: [FolderSummary], wordId: String) {
        guard !folders.isEmpty else {
            return
        }
        
        // 创建一个组来跟踪所有查询
        let group = DispatchGroup()
        var foundItemId: String? = nil
        
        // 遍历每个收藏夹查找目标单词
        for folder in folders {
            group.enter()
            
            favoriteService.getFolderItems(folderId: folder.id, limit: 100, offset: 0)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        group.leave()
                    },
                    receiveValue: { content in
                        if let item = content.items.first(where: { $0.wordId == wordId }) {
                            foundItemId = item.id
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        // 当所有查询完成后，删除找到的收藏项
        group.notify(queue: .main) { [weak self] in
            guard let self = self, let itemId = foundItemId else { return }
            
            self.favoriteService.deleteFavorite(id: itemId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.handleError(error)
                        }
                    },
                    receiveValue: { [weak self] success in
                        if success {
                            self?.isFavorited = false
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /// 添加到默认收藏夹
    private func addToDefaultFolder(wordDetails: WordDetails) {
        // 获取所有收藏夹
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folders in
                    guard let self = self else { return }
                    
                    // 查找或创建默认收藏夹
                    if let defaultFolder = folders.first {
                        self.addToFolder(wordDetails: wordDetails, folder: defaultFolder)
                    } else {
                        // 创建默认收藏夹
                        self.createDefaultFolderAndAddWord(wordDetails: wordDetails)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 创建默认收藏夹并添加单词
    private func createDefaultFolderAndAddWord(wordDetails: WordDetails) {
        favoriteService.createFolder(name: "默认收藏夹")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folder in
                    guard let self = self else { return }
                    self.addToFolder(wordDetails: wordDetails, folder: folder)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 添加单词到指定收藏夹
    private func addToFolder(wordDetails: WordDetails, folder: FolderSummary) {
        favoriteService.addFavorite(
            wordId: wordDetails.id,
            folderId: folder.id,
            note: nil
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] _ in
                self?.isFavorited = true
            }
        )
        .store(in: &cancellables)
    }
    
    /// 查找收藏项并更新笔记
    private func findFavoriteAndUpdateNote(wordId: String, note: String) {
        // 先获取所有收藏夹
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] folders in
                    guard let self = self else { return }
                    self.searchInFoldersAndUpdateNote(folders: folders, wordId: wordId, note: note)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 在所有收藏夹中查找并更新笔记
    private func searchInFoldersAndUpdateNote(folders: [FolderSummary], wordId: String, note: String) {
        guard !folders.isEmpty else {
            return
        }
        
        // 创建一个组来跟踪所有查询
        let group = DispatchGroup()
        var foundItemId: String? = nil
        
        // 遍历每个收藏夹查找目标单词
        for folder in folders {
            group.enter()
            
            favoriteService.getFolderItems(folderId: folder.id, limit: 100, offset: 0)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        group.leave()
                    },
                    receiveValue: { content in
                        if let item = content.items.first(where: { $0.wordId == wordId }) {
                            foundItemId = item.id
                        }
                    }
                )
                .store(in: &cancellables)
        }
        
        // 当所有查询完成后，更新找到的收藏项笔记
        group.notify(queue: .main) { [weak self] in
            guard let self = self, let itemId = foundItemId else { return }
            
            self.favoriteService.updateFavoriteNote(id: itemId, note: note)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.handleError(error)
                        }
                    },
                    receiveValue: { _ in
                        // 笔记更新成功
                    }
                )
                .store(in: &self.cancellables)
        }
    }
}
