import Foundation
import Combine

protocol SearchResultsViewModelProtocol: ObservableObject {
    var searchResults: [WordListItem] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func playPronunciation(for entry: WordListItem)
    func toggleFavorite(_ entry: WordListItem)
    func isFavorited(_ id: String) -> Bool
}

class SearchResultsViewModel: ObservableObject, SearchResultsViewModelProtocol {
    // MARK: - 输出属性
    @Published private(set) var searchResults: [WordListItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - 依赖
    private let dictionaryViewModel: DictionaryViewModel
    private let detailViewModel: DetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(dictionaryViewModel: DictionaryViewModel, detailViewModel: DetailViewModel) {
        self.dictionaryViewModel = dictionaryViewModel
        self.detailViewModel = detailViewModel
        
        // 订阅字典视图模型的搜索结果
        dictionaryViewModel.$searchResults
            .assign(to: &$searchResults)
        
        // 订阅加载状态
        dictionaryViewModel.$isLoading
            .combineLatest(detailViewModel.$isLoading)
            .map { dict, detail in
                return dict || detail
            }
            .assign(to: &$isLoading)
        
        // 订阅错误消息
        dictionaryViewModel.$errorMessage
            .combineLatest(detailViewModel.$errorMessage)
            .map { dict, detail in
                return dict ?? detail
            }
            .assign(to: &$errorMessage)
    }
    
    // MARK: - 公共方法
    
    /// 播放发音
    func playPronunciation(for entry: WordListItem) {
        dictionaryViewModel.playPronunciation(for: entry)
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ entry: WordListItem) {
        if isFavorited(entry.id) {
            dictionaryViewModel.removeFromFavorites(entry)
        } else {
            dictionaryViewModel.addToFavorites(entry)
        }
    }
    
    /// 检查是否已收藏
    func isFavorited(_ id: String) -> Bool {
        // 使用字典视图模型的方法
        guard let entry = searchResults.first(where: { $0.id == id }) else {
            return false
        }
        return dictionaryViewModel.isInFavorites(entry)
    }
}