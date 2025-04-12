import Foundation
import Combine
import SwiftUI
import RealmSwift

protocol DictionaryViewModelProtocol: ObservableObject {
    // 输出属性
    var searchResults: [WordListItem] { get }
    var recentSearches: [SearchHistoryDTO] { get }
    var relatedWords: [WordListItem] { get }
    var favoriteCategories: [FavoriteCategory] { get }
    var learningProgress: LearningProgress { get }
    var wordCloudItems: [WordCloudItem] { get }
    var userProfile: UserProfile? { get }  // 修改为 UserProfile 类型
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadInitialData()
    func selectEntry(_ entry: WordListItem)
    func loadRelatedWords(for entry: WordListItem)
    func addToFavorites(_ entry: WordListItem)
    func removeFromFavorites(_ entry: WordListItem)
    func isInFavorites(_ entry: WordListItem) -> Bool
    func playPronunciation(for entry: WordListItem)
    func loadWordDetails(id: String)
}

class DictionaryViewModel: ObservableObject, DictionaryViewModelProtocol {
    func loadWordDetails(id: String) {
        detailViewModel.loadWordDetails(id: id)
    }
    
    // MARK: - 输出属性
    @Published private(set) var searchResults: [WordListItem] = []
    @Published private(set) var recentSearches: [SearchHistoryDTO] = []
    @Published private(set) var relatedWords: [WordListItem] = []
    @Published private(set) var favoriteCategories: [FavoriteCategory] = []
    @Published private(set) var learningProgress: LearningProgress = LearningProgress()
    @Published private(set) var wordCloudItems: [WordCloudItem] = []
    @Published private(set) var userProfile: UserProfile?  // 修改为 UserProfile 类型
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - 依赖
    private let dictionaryService: DictionaryServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    private let userService: UserServiceProtocol
    private let searchViewModel: SearchViewModel
    private let detailViewModel: DetailViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(
        dictionaryService: DictionaryServiceProtocol,
        favoriteService: FavoriteServiceProtocol,
        userService: UserServiceProtocol,
        searchViewModel: SearchViewModel,
        detailViewModel: DetailViewModel
    ) {
        self.dictionaryService = dictionaryService
        self.favoriteService = favoriteService
        self.userService = userService
        self.searchViewModel = searchViewModel
        self.detailViewModel = detailViewModel
        
        // 订阅搜索视图模型的搜索结果
        searchViewModel.$searchResults
            .sink { [weak self] results in
                self?.searchResults = results
            }
            .store(in: &cancellables)
        
        // 订阅搜索历史
        searchViewModel.$searchHistory
            .sink { [weak self] history in
                self?.recentSearches = history
            }
            .store(in: &cancellables)
        
        loadInitialData()
    }
    
    // MARK: - 公共方法
    
    /// 加载初始数据
    func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        // 并行加载多个数据源
        let group = DispatchGroup()
        
        // 加载用户信息
        group.enter()
        userService.getUserProfile()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                    group.leave()
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                }
            )
            .store(in: &cancellables)
        
        // 加载学习进度
        group.enter()
        loadLearningProgress { group.leave() }
        
        // 加载收藏分类
        group.enter()
        loadFavoriteCategories { group.leave() }
        
        // 加载词云数据
        group.enter()
        loadWordCloud { group.leave() }
        
        // 加载搜索历史 - 修改为使用搜索视图模型的公共接口
        // 由于 SearchViewModel 已经在初始化时加载了搜索历史
        // 且我们已经订阅了其 searchHistory 属性的变化
        // 这里不需要额外的操作，直接离开 DispatchGroup
        group.enter()
        DispatchQueue.main.async {
            group.leave()
        }
        
        // 所有数据加载完成
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    /// 选择词条
    func selectEntry(_ entry: WordListItem) {
        // 使用搜索视图模型的选择词条方法
        searchViewModel.selectWord(id: entry.id)
    }
    
    /// 加载相关词汇
    func loadRelatedWords(for entry: WordListItem) {
        isLoading = true
        errorMessage = nil
        
        dictionaryService.getRelatedWords(id: entry.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] words in
                    self?.relatedWords = words
                }
            )
            .store(in: &cancellables)
    }
    
    /// 添加到收藏
    func addToFavorites(_ entry: WordListItem) {
        // 使用详情视图模型的收藏方法
        // 先加载词条详情
        detailViewModel.loadWordDetails(id: entry.id)
        
        // 使用组合发布者等待详情加载完成后再添加收藏
        detailViewModel.$wordDetails
            .filter { $0 != nil }
            .first()
            .sink { [weak self] details in
                guard let details = details else { return }
                self?.detailViewModel.toggleFavorite()
            }
            .store(in: &cancellables)
    }
    
    /// 从收藏中移除
    func removeFromFavorites(_ entry: WordListItem) {
        // 使用详情视图模型的取消收藏方法
        // 先加载词条详情
        detailViewModel.loadWordDetails(id: entry.id)
        
        // 使用组合发布者等待详情加载完成后再移除收藏
        detailViewModel.$wordDetails
            .filter { $0 != nil }
            .first()
            .sink { [weak self] details in
                guard let details = details, self?.detailViewModel.isFavorited == true else { return }
                self?.detailViewModel.toggleFavorite()
            }
            .store(in: &cancellables)
    }
    
    /// 检查是否已收藏
    func isInFavorites(_ entry: WordListItem) -> Bool {
        // 这里需要查询收藏服务
        // 由于是同步方法，我们需要使用一个简单的方法来检查
        var result = false
        
        let semaphore = DispatchSemaphore(value: 0)
        
        favoriteService.isWordFavorited(wordId: entry.id)
            .sink(
                receiveCompletion: { _ in
                    semaphore.signal()
                },
                receiveValue: { isFavorited in
                    result = isFavorited
                }
            )
            .store(in: &cancellables)
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        return result
    }
    
    /// 播放发音
    func playPronunciation(for entry: WordListItem) {
        // 使用详情视图模型的播放发音方法
        detailViewModel.loadWordDetails(id: entry.id)
        
        detailViewModel.$wordDetails
            .filter { $0 != nil }
            .first()
            .sink { [weak self] _ in
                self?.detailViewModel.playPronunciation(speed: 1.0)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 私有方法
    
    /// 加载学习进度
    private func loadLearningProgress(completion: @escaping () -> Void) {
        // 从数据库加载学习进度
        // 这里使用模拟数据
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let progress = LearningProgress()
            progress.completedCount = 3
            progress.targetCount = 10
            progress.streakDays = 5
            
            self.learningProgress = progress
            completion()
        }
    }
    
    /// 加载收藏分类
    private func loadFavoriteCategories(completion: @escaping () -> Void) {
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    if case .failure(let error) = result {
                        self?.handleError(error)
                    }
                    completion()
                },
                receiveValue: { [weak self] folders in
                    guard let self = self else { return }
                    
                    // 将收藏夹转换为分类
                    let categories = folders.map { folder -> FavoriteCategory in
                        let category = FavoriteCategory(name: folder.name, iconName: "book")
                        category.count = folder.itemCount
                        return category
                    }
                    
                    self.favoriteCategories = categories
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载词云数据
    private func loadWordCloud(completion: @escaping () -> Void) {
        // 从数据库加载词云数据
        // 这里使用模拟数据
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let words = ["食べる", "飲む", "行く", "来る", "見る", "聞く", "話す", "読む", "書く", "寝る"]
            self.wordCloudItems = words.map { WordCloudItem(word: $0, frequency: Int.random(in: 1...14)) }
            
            completion()
        }
    }

    func loadWordDetails(id: String, completion: @escaping (DictEntry?) -> Void) {
        isLoading = true
        
        dictionaryService.getWordDetails(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    if case .failure(let error) = result {
                        self?.errorMessage = error.localizedDescription
                        completion(nil)
                    }
                },
                receiveValue: { wordDetails in
                    // 将 WordDetails 转换为 DictEntry
                    // 这里需要根据你的数据模型进行适当的转换
                    let entry = DictEntry()
                    entry.id = wordDetails.id
                    entry.word = wordDetails.word
                    entry.reading = wordDetails.reading
                    entry.partOfSpeech = wordDetails.partOfSpeech
                    // 转换其他属性...
                    
                    completion(entry)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 处理错误
    private func handleError(_ error: Error) {
        if let dictError = error as? DictionaryError {
            errorMessage = dictError.localizedDescription
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
        } else if let userError = error as? UserError {
            switch userError {
            case .userNotFound:
                errorMessage = "用户不存在"
            case .authenticationFailed:
                errorMessage = "认证失败"
            case .networkError:
                errorMessage = "网络错误"
            default:
                errorMessage = "用户服务错误"
            }
        } else {
            errorMessage = "发生错误: \(error.localizedDescription)"
        }
    }
}



