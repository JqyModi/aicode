import Foundation
import Combine
import SwiftUI

// 搜索视图模型协议
protocol SearchViewModelProtocol: ObservableObject {
    // 输入属性
    var searchQuery: String { get set }
    var searchType: SearchType { get set }
    
    // 输出属性
    var searchResults: [WordListItem] { get }
    var searchHistory: [SearchHistoryDTO] { get }
    var suggestions: [String] { get }
    var isSearching: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func search()
    func clearSearch()
    func selectWord(id: String)
    func clearHistory()
    func loadMoreResults()
}

// MARK: - 搜索视图模型
class SearchViewModel: ObservableObject, SearchViewModelProtocol {
    // MARK: - 输入属性
    @Published var searchQuery: String = ""
    @Published var searchType: SearchType = .auto
    
    // MARK: - 输出属性
    @Published private(set) var searchResults: [WordListItem] = []
    @Published private(set) var searchHistory: [SearchHistoryDTO] = []
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - 分页属性
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    private var hasMoreResults: Bool = true
    
    // MARK: - 依赖
    private let dictionaryService: DictionaryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(dictionaryService: DictionaryServiceProtocol) {
        self.dictionaryService = dictionaryService
        
        // 监听搜索查询变化，提供搜索建议
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.provideSuggestions(for: query)
            }
            .store(in: &cancellables)
        
        // 加载初始搜索历史
        loadSearchHistory()
    }
    
    // MARK: - 公共方法
    
    /// 执行搜索
    func search() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "请输入搜索内容"
            return
        }
        
        isSearching = true
        errorMessage = nil
        currentPage = 0
        hasMoreResults = true
        
        performSearch(query: searchQuery, page: currentPage)
    }
    
    /// 清除搜索
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        suggestions = []
        errorMessage = nil
        currentPage = 0
        hasMoreResults = true
    }
    
    /// 选择单词
    func selectWord(id: String) {
        // 查找选中的单词
        guard let selectedWord = searchResults.first(where: { $0.id == id }) else {
            return
        }
        
        // 添加到搜索历史
        let historyItem = SearchHistoryDTO(
            id: UUID().uuidString,
            wordId: selectedWord.id,
            word: selectedWord.word,
            reading: selectedWord.reading,
            searchDate: Date()
        )
        
        dictionaryService.addSearchHistory(item: historyItem)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "无法添加搜索历史: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.loadSearchHistory()
                }
            )
            .store(in: &cancellables)
    }
    
    /// 清除历史记录
    func clearHistory() {
        dictionaryService.clearSearchHistory()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "无法清除搜索历史: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.searchHistory = []
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载更多结果
    func loadMoreResults() {
        guard !isSearching && hasMoreResults else {
            return
        }
        
        currentPage += 1
        performSearch(query: searchQuery, page: currentPage, isLoadingMore: true)
    }
    
    // MARK: - 私有方法
    
    /// 执行搜索操作
    private func performSearch(query: String, page: Int, isLoadingMore: Bool = false) {
        let offset = page * pageSize
        
        dictionaryService.searchWords(query: query, type: searchType, limit: pageSize, offset: offset)
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
                    
                    if isLoadingMore {
                        // 加载更多时追加结果
                        self.searchResults.append(contentsOf: result.items)
                    } else {
                        // 新搜索时替换结果
                        self.searchResults = result.items
                    }
                    
                    // 判断是否还有更多结果
                    self.hasMoreResults = result.items.count == self.pageSize
                    
                    // 如果是新搜索且有结果，添加到搜索历史
                    if !isLoadingMore && !result.items.isEmpty {
                        self.addToSearchHistory(query: query)
                    }
                    
                    self.isSearching = false
                }
            )
            .store(in: &cancellables)
    }
    
    /// 提供搜索建议
    private func provideSuggestions(for query: String) {
        // 简单实现：根据历史记录提供建议
        // 实际应用中可能需要更复杂的逻辑，如从词典中查找相似词等
        let filteredHistory = searchHistory
            .filter { $0.word.lowercased().contains(query.lowercased()) }
            .prefix(5)
            .map { $0.word }
        
        suggestions = Array(filteredHistory)
    }
    
    /// 加载搜索历史
    private func loadSearchHistory() {
        dictionaryService.getSearchHistory(limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "无法加载搜索历史: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] history in
                    self?.searchHistory = history
                }
            )
            .store(in: &cancellables)
    }
    
    /// 添加到搜索历史
    private func addToSearchHistory(query: String) {
        // 如果搜索结果为空，不添加到历史
        guard !searchResults.isEmpty else { return }
        
        // 使用第一个搜索结果作为历史记录
        let firstResult = searchResults[0]
        let historyItem = SearchHistoryDTO(
            id: UUID().uuidString,
            wordId: firstResult.id,
            word: firstResult.word,
            reading: firstResult.reading,
            searchDate: Date()
        )
        
        dictionaryService.addSearchHistory(item: historyItem)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] _ in
                    self?.loadSearchHistory()
                }
            )
            .store(in: &cancellables)
    }
}
