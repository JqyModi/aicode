//
//  SearchViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class SearchViewModel: SearchViewModelProtocol {
    // MARK: - 依赖注入
    private let dictionaryService: DictionaryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 输入属性
    @Published var searchQuery: String = ""
    @Published var searchType: SearchTypeViewModel = .auto
    
    // MARK: - 输出属性
    @Published private(set) var searchResults: [WordSummaryViewModel] = []
    @Published private(set) var searchHistory: [SearchHistoryItemViewModel] = []
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - 分页控制
    private var currentOffset: Int = 0
    private var hasMoreResults: Bool = true
    private let pageSize: Int = 20
    
    // MARK: - 初始化
    init(dictionaryService: DictionaryServiceProtocol) {
        self.dictionaryService = dictionaryService
        loadSearchHistory()
        setupBindings()
    }
    
    // MARK: - 私有方法
    private func setupBindings() {
        // 实现搜索建议的防抖动
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.updateSuggestions(for: query)
            }
            .store(in: &cancellables)
    }
    
    private func updateSuggestions(for query: String) {
        // 这里可以实现根据输入获取搜索建议的逻辑
        // 例如从历史记录中筛选或调用API获取
        let filteredSuggestions = searchHistory
            .filter { $0.word.lowercased().contains(query.lowercased()) }
            .map { $0.word }
            .prefix(5)
        
        suggestions = Array(filteredSuggestions)
    }
    
    private func loadSearchHistory() {
        dictionaryService.getSearchHistory(limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "无法加载搜索历史: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] historyItems in
                    self?.searchHistory = historyItems.map { self?.mapToSearchHistoryItemViewModel($0) ?? SearchHistoryItemViewModel(id: "", word: "", timestamp: Date()) }
                }
            )
            .store(in: &cancellables)
    }
    
    private func mapToSearchTypeEntity(_ type: SearchTypeViewModel) -> SearchTypeDomain {
        switch type {
        case .auto: return .auto
        case .word: return .word
        case .reading: return .reading
        case .meaning: return .meaning
        }
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
    
    private func mapToSearchHistoryItemViewModel(_ domain: SearchHistoryItemDomain) -> SearchHistoryItemViewModel {
        return SearchHistoryItemViewModel(
            id: domain.id,
            word: domain.word,
            timestamp: domain.timestamp
        )
    }
    
    // MARK: - 公开方法
    func search() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        currentOffset = 0
        hasMoreResults = true
        
        dictionaryService.searchWords(query: searchQuery, type: mapToSearchTypeEntity(searchType), limit: pageSize, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "搜索失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    self.searchResults = result.items.map { self.mapToWordSummaryViewModel($0) }
                    self.hasMoreResults = result.total > self.searchResults.count
                    self.currentOffset = self.searchResults.count
                }
            )
            .store(in: &cancellables)
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        suggestions = []
        errorMessage = nil
        currentOffset = 0
        hasMoreResults = true
    }
    
    func selectWord(id: String) {
        // 这里可以实现选择单词后的逻辑，例如添加到历史记录
        // 实际应用中可能需要获取单词详情后再添加到历史
        if let selectedWord = searchResults.first(where: { $0.id == id }) {
            // 这里简化处理，实际应用中应该调用服务层添加历史记录
            let historyItem = SearchHistoryItemViewModel(
                id: UUID().uuidString,
                word: selectedWord.word,
                timestamp: Date()
            )
            
            // 避免重复添加
            if !searchHistory.contains(where: { $0.word == selectedWord.word }) {
                searchHistory.insert(historyItem, at: 0)
                // 限制历史记录数量
                if searchHistory.count > 10 {
                    searchHistory.removeLast()
                }
            }
        }
    }
    
    func clearHistory() {
        dictionaryService.clearSearchHistory()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "清除历史失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.searchHistory = []
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadMoreResults() {
        guard !isSearching && hasMoreResults else { return }
        
        isSearching = true
        
        dictionaryService.searchWords(query: searchQuery, type: mapToSearchTypeEntity(searchType), limit: pageSize, offset: currentOffset)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载更多结果失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    let newResults = result.items.map { self.mapToWordSummaryViewModel($0) }
                    self.searchResults.append(contentsOf: newResults)
                    self.hasMoreResults = result.total > self.searchResults.count
                    self.currentOffset = self.searchResults.count
                }
            )
            .store(in: &cancellables)
    }
}