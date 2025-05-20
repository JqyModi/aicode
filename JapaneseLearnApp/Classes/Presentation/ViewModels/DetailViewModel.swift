//
//  DetailViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import AVFoundation

class DetailViewModel: DetailViewModelProtocol {
    // MARK: - 依赖注入
    private let dictionaryService: DictionaryServiceProtocol
    public let favoriteService: FavoriteServiceProtocol
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - 音频播放器
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - 输出属性
    @Published private(set) var wordDetails: WordDetailsViewModel? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var isFavorited: Bool = false
    @Published var folders: [FolderSummaryDomain] = []
    
    // MARK: - 当前单词ID
    private var currentWordId: String? = nil
    
    public var wordId: String {
        currentWordId ?? ""
    }
    
    // MARK: - 初始化
    init(dictionaryService: DictionaryServiceProtocol, favoriteService: FavoriteServiceProtocol, wordId: String) {
        self.dictionaryService = dictionaryService
        self.favoriteService = favoriteService
        
        self.currentWordId = wordId
        self.loadWordDetails()
    }
    
    // MARK: - 公开方法
    func loadWordDetails() {
        guard let id = currentWordId else { return }
        
        isLoading = true
        errorMessage = nil
        currentWordId = id
        
        dictionaryService.getWordDetails(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取单词详情失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] details in
                    guard let self = self else { return }
                    self.wordDetails = self.mapToWordDetailsViewModel(details)
                    self.isFavorited = details.isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    func playPronunciation(speed: Float) {
        guard let wordId = currentWordId else {
            errorMessage = "无法播放发音：单词ID不存在"
            return
        }
        
        isLoading = true
        
        dictionaryService.getWordPronunciation(id: wordId, speed: speed)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取发音失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] audioURL in
                    self?.playAudio(from: audioURL)
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFavorite() {
        guard let wordId = currentWordId, let _ = wordDetails else {
            errorMessage = "无法收藏：单词详情不存在"
            return
        }
        
        if isFavorited {
            // 从收藏中删除
            isLoading = true
            favoriteService.deleteFavorite(id: wordId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = "取消收藏失败: \(error.localizedDescription)"
                        }
                    },
                    receiveValue: { [weak self] success in
                        if success {
                            self?.isFavorited = false
                        }
                    }
                )
                .store(in: &cancellables)
        } else {
            // 显示收藏夹选择视图，让用户选择要收藏到的文件夹
            // 这部分逻辑在WordDetailView中实现
        }
    }
    
    // MARK: - 收藏夹相关方法
    func loadFolders() {
        isLoading = true
        errorMessage = nil
        
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] folders in
                    self?.folders = folders
                    
                    // 如果没有收藏夹，创建一个默认收藏夹
                    if folders.isEmpty {
                        self?.createDefaultFolder()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createFolder(name: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.createFolder(name: name)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionStatus in
                    self?.isLoading = false
                    if case .failure(let error) = completionStatus {
                        self?.errorMessage = "创建收藏夹失败: \(error.localizedDescription)"
                        completion(false)
                    }
                },
                receiveValue: { [weak self] folder in
                    self?.folders.append(folder)
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    private func createDefaultFolder() {
        favoriteService.createFolder(name: "默认收藏夹")
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "创建默认收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] folder in
                    self?.folders.append(folder)
                }
            )
            .store(in: &cancellables)
    }
    
    func addToFolder(wordId: String, folderId: String) {
        isLoading = true
        errorMessage = nil
        
        favoriteService.addFavorite(wordId: wordId, folderId: folderId, note: nil)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "添加收藏失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.isFavorited = true
                }
            )
            .store(in: &cancellables)
    }
    
    func addNote(note: String) {
        guard let wordId = currentWordId, isFavorited else {
            errorMessage = "无法添加笔记：单词未收藏"
            return
        }
        
        isLoading = true
        
        // 注意：这里简化处理，实际应用中需要先获取收藏项ID
        // 这里假设favoriteService有一个方法可以通过wordId更新笔记
        favoriteService.updateFavoriteNote(id: wordId, note: note)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "添加笔记失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 单词交互
    func handleWordTapped(word: String, lemma: String, furigana: String) {
        // 处理用户点击单词的交互
        print("DetailViewModel - 处理单词点击: 单词=\(word), 词元=\(lemma), 假名=\(furigana)")
        
        // 这里可以实现更多功能，例如：
        // 1. 查询点击的单词详情
        // if !lemma.isEmpty {
        //    dictionaryService.searchWord(lemma)
        //        .receive(on: DispatchQueue.main)
        //        .sink(...)
        //        .store(in: &cancellables)
        // }
        
        // 2. 添加到生词本
        // favoriteService.addToVocabulary(word: word, reading: furigana)
        
        // 3. 显示单词释义弹窗
        // 可以通过NotificationCenter或回调函数通知UI层显示弹窗
        
        // 4. 播放单词发音
        // 可以调用现有的playPronunciation方法
    }
    
    // MARK: - 私有方法
    private func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            errorMessage = "播放发音失败: \(error.localizedDescription)"
        }
    }
    
    private func mapToWordDetailsViewModel(_ domain: WordDetailsDomain) -> WordDetailsViewModel {
        return WordDetailsViewModel(
            id: domain.id,
            word: domain.word,
            reading: domain.reading,
            partOfSpeech: domain.partOfSpeech,
            definitions: domain.definitions.map { mapToDefinitionViewModel($0) },
            examples: domain.examples.map { mapToExampleViewModel($0) },
            relatedWords: domain.relatedWords.map { mapToWordSummaryViewModel($0) },
            isFavorited: domain.isFavorited
        )
    }
    
    private func mapToDefinitionViewModel(_ domain: DefinitionDomain) -> DefinitionViewModel {
        return DefinitionViewModel(
            meaning: domain.meaning,
            notes: domain.notes
        )
    }
    
    private func mapToExampleViewModel(_ domain: ExampleDomain) -> ExampleViewModel {
        return ExampleViewModel(
            sentence: domain.sentence,
            translation: domain.translation
        )
    }
    
    private func mapToWordSummaryViewModel(_ domain: WordSummaryDomain) -> WordSummaryViewModel {
        return WordSummaryViewModel(
            id: domain.id,
            word: domain.word,
            reading: domain.reading,
            partOfSpeech: domain.partOfSpeech,
            briefMeaning: domain.briefMeaning
        )
    }
}
