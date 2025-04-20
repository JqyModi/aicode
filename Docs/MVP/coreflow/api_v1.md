# 基于本地数据层的API接口文档设计
根据技术架构文档中的数据层设计，我们采用了"无后端"架构，主要依靠Realm本地数据库、CloudKit云同步和AppleAuth用户认证。针对这种情况，我们需要设计一套内部API接口文档，主要描述应用内各层之间的交互方式。

## 1. 接口设计思路
在无后端架构下，API接口主要是指：

1. 业务层(Domain)与数据层(Data)之间的接口
2. 表现层(Presentation)与业务层(Domain)之间的接口
3. 数据层内部组件之间的接口
这些接口将以Swift协议(Protocol)和函数(Function)的形式定义，而非传统的HTTP REST API。

## 2. 数据层接口设计
### 2.1 RealmManager接口
```swift
protocol DictionaryDataRepositoryProtocol {
    // 查询单词
    func searchWords(query: String, type: SearchTypeEntity, limit: Int, offset: Int) -> AnyPublisher<[DictEntryEntity], Error>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntryEntity?, Error>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemEntity], Error>
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntryEntity) -> AnyPublisher<Void, Error>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error>
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersionEntity, Error>
}

enum SearchTypeEntity {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}
```

### 2.2 收藏管理接口
```swift
protocol FavoriteDataRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderEntity], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderEntity, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderEntity, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItemEntity], Error>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemEntity, Error>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemEntity, Error>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
}
```

### 2.3 用户认证接口
```swift
protocol UserAuthDataRepositoryProtocol {
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<UserEntity, Error>
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<UserEntity?, Error>
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettingsEntity) -> AnyPublisher<UserSettingsEntity, Error>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

```

### 2.4 云同步接口
```swift
protocol SyncDataRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusEntity, Error>
    
    // 触发同步
    func startSync(type: SyncTypeEntity) -> AnyPublisher<SyncOperationEntity, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressEntity, Error>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionEntity) -> AnyPublisher<Bool, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}

enum SyncTypeDomain {
    case full       // 全量同步
    case favorites  // 仅同步收藏
    case settings   // 仅同步设置
}

enum ConflictResolutionDomain {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}

```

## 3. 业务层接口设计
### 3.1 词典服务接口
```swift
protocol DictionaryServiceProtocol {
    // 搜索单词
    func searchWords(query: String, type: SearchTypeDomain?, limit: Int, offset: Int) -> AnyPublisher<SearchResultDomain, DictionaryErrorDomain>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetailsDomain, DictionaryError>
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryErrorDomain>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemDomain], DictionaryError>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryErrorDomain>
}

struct SearchResultDomain {
    let total: Int
    let items: [WordSummaryDomain]
}

struct WordSummaryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

struct WordDetailsDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
    let relatedWords: [WordSummaryDomain]
    let isFavorited: Bool
}

enum DictionaryErrorDomain: Error {
    case notFound
    case searchFailed
    case databaseError
    case pronunciationFailed
    case networkError
}

```

### 3.2 收藏服务接口
```swift
protocol FavoriteServiceProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummaryDomain], FavoriteErrorDomain>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummaryDomain, FavoriteErrorDomain>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteErrorDomain>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContentDomain, FavoriteErrorDomain>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetailDomain, FavoriteErrorDomain>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteError>
}

struct FolderSummaryDomain {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatusDomain
}

struct FolderContentDomain {
    let total: Int
    let items: [FavoriteItemDetailDomain]
}

struct FavoriteItemDetailDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatusDomain
}

enum FavoriteErrorDomain: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError
    case syncError
}

enum SyncStatusDomain {
    case synced        // 已同步
    case pendingUpload // 待上传
    case pendingDownload // 待下载
    case conflict      // 冲突
    case error         // 错误
}

```

### 3.3 用户服务接口
```swift
protocol UserServiceProtocol {
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfileDomain, UserErrorDomain>
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfileDomain, UserErrorDomain>
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferencesDomain) -> AnyPublisher<UserPreferencesDomain, UserErrorDomain>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserErrorDomain>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

struct UserProfileDomain {
    let userId: String
    let nickname: String?
    let settings: UserPreferencesDomain
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferencesDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

enum UserErrorDomain: Error {
    case authenticationFailed
    case userNotFound
    case settingsUpdateFailed
    case signOutFailed
}

```

### 3.4 同步服务接口
```swift
protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfoDomain, SyncErrorDomain>
    
    // 触发同步
    func startSync(type: SyncTypeDomain) -> AnyPublisher<SyncOperationInfoDomain, SyncErrorDomain>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfoDomain, SyncErrorDomain>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionDomain) -> AnyPublisher<Bool, SyncErrorDomain>
}

struct SyncStatusInfoDomain {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: String
    let availableOffline: Bool
}

struct SyncOperationInfoDomain {
    let syncId: String
    let startedAt: Date
    let status: String
    let estimatedTimeRemaining: Int?
}

struct SyncProgressInfoDomain {
    let syncId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
}

enum SyncErrorDomain: Error {
    case networkUnavailable
    case cloudKitError
    case authenticationRequired
    case conflictDetected
    case syncInProgress
}

```

## 4. 表现层接口设计
### 4.1 SearchViewModel接口
```swift
protocol SearchViewModelProtocol: ObservableObject {
    // 输入属性
    var searchQuery: String { get set }
    var searchType: SearchTypeViewModel { get set }
    
    // 输出属性
    var searchResults: [WordSummaryViewModel] { get }
    var searchHistory: [SearchHistoryItemViewModel] { get }
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
```


### 4.2 DetailViewModel接口
```swift
protocol DetailViewModelProtocol: ObservableObject {
    // 输出属性
    var wordDetails: WordDetailsViewModel? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isFavorited: Bool { get }
    
    // 方法
    func loadWordDetails(id: String)
    func playPronunciation(speed: Float)
    func toggleFavorite()
    func addNote(note: String)
}


### 4.3 FavoriteViewModel接口
```swift
protocol FavoriteViewModelProtocol: ObservableObject {
    // 输出属性
    var folders: [FolderSummaryViewModel] { get }
    var selectedFolder: FolderSummaryViewModel? { get }
    var folderItems: [FavoriteItemDetailViewModel] { get }
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


### 4.4 UserViewModel接口
```swift
protocol UserViewModelProtocol: ObservableObject {
    // 输出属性
    var userProfile: UserProfileViewModel? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userSettings: UserPreferencesViewModel { get }
    
    // 方法
    func signInWithApple()
    func signOut()
    func loadUserProfile()
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool)
}


## 5. 数据模型
### 5.1 领域模型
这些模型是业务层使用的，与数据层的Realm模型相分离：

```swift
// 词典领域模型 - 业务层模型
struct DictEntryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
}

struct DefinitionDomain {
    let meaning: String
    let notes: String?
}

struct ExampleDomain {
    let sentence: String
    let translation: String
}

struct SearchHistoryItemDomain {
    let id: String
    let word: String
    let timestamp: Date
}

// 用户领域模型 - 业务层模型
struct UserDomain {
    let id: String
    let nickname: String?
    let settings: UserSettingsDomain
    let lastSyncTime: Date?
}

struct UserSettingsDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

// 收藏领域模型 - 业务层模型
struct FolderDomain {
    let id: String
    let name: String
    let createdAt: Date
    let items: [FavoriteItemDomain]
    let syncStatus: Int
}

struct FavoriteItemDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: Int
}


## 6. 错误处理
### 6.1 错误类型定义
```swift
// 通用错误基类
enum AppError: Error {
    case unknown
    case networkError
    case databaseError(String)
    case validationError(String)
    case authenticationError
    case syncError(String)
}

// 特定功能错误
extension AppError {
    static func dictionary(_ error: DictionaryErrorDomain) -> AppError {
        switch error {
        case .notFound:
            return .validationError("单词未找到")
        case .searchFailed:
            return .databaseError("搜索失败")
        case .databaseError:
            return .databaseError("数据库错误")
        case .pronunciationFailed:
            return .unknown
        case .networkError:
            return .networkError
        }
    }
    
    static func favorite(_ error: FavoriteErrorDomain) -> AppError {
        switch error {
        case .folderNotFound:
            return .validationError("收藏夹未找到")
        case .itemNotFound:
            return .validationError("收藏项未找到")
        case .duplicateName:
            return .validationError("收藏夹名称重复")
        case .databaseError:
            return .databaseError("数据库错误")
        case .syncError:
            return .syncError("同步错误")
        }
    }
}


### 6.2 错误处理策略
```swift
protocol ErrorHandling {
    func handle(_ error: Error) -> String
    func logError(_ error: Error, file: String, line: Int, function: String)
}

class AppErrorHandler: ErrorHandling {
    func handle(_ error: Error) -> String {
        // 将各种错误转换为用户友好的消息
        if let appError = error as? AppError {
            switch appError {
            case .unknown:
                return "发生未知错误"
            case .networkError:
                return "网络连接错误，请检查网络设置"
            case .databaseError(let message):
                return "数据访问错误: \(message)"
            case .validationError(let message):
                return message
            case .authenticationError:
                return "认证失败，请重新登录"
            case .syncError(let message):
                return "同步错误: \(message)"
            }
        }
        return "操作失败，请稍后重试"
    }
    
    func logError(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        // 记录错误日志
        print("Error: \(error.localizedDescription), File: \(file), Line: \(line), Function: \(function)")
        // 在实际应用中，可以将错误发送到日志服务
    }
}

```

## 7. 数据转换
### 7.1 数据层到业务层的转换
```swift
// Realm模型到领域模型的转换
extension DictEntryEntity {
    func toDomain() -> DictEntryDomain {
        return DictEntryDomain(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            definitions: definitions.map { $0.toDomain() },
            examples: examples.map { $0.toDomain() }
        )
    }
}

extension DefinitionEntity {
    func toDomain() -> DefinitionDomain {
        return DefinitionDomain(
            meaning: meaning,
            notes: notes
        )
    }
}

extension ExampleEntity {
    func toDomain() -> ExampleDomain {
        return ExampleDomain(
            sentence: sentence,
            translation: translation
        )
    }
}


### 7.2 业务层到表现层的转换
```swift
// 领域模型到视图模型的转换
extension DictEntryDomain {
    func toViewModel(isFavorited: Bool) -> WordDetailsViewModel {
        return WordDetailsViewModel(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            definitions: definitions.map { 
                DefinitionViewModel(meaning: $0.meaning, notes: $0.notes) 
            },
            examples: examples.map { 
                ExampleViewModel(sentence: $0.sentence, translation: $0.translation) 
            },
            relatedWords: [], // 需要另外填充
            isFavorited: isFavorited
        )
    }
    
    func toSummaryViewModel() -> WordSummaryViewModel {
        return WordSummaryViewModel(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            briefMeaning: definitions.first?.meaning ?? ""
        )
    }
}


## 8. 实现注意事项
### 8.1 离线优先策略
- 所有数据操作首先在本地Realm数据库执行
- 操作成功后，标记为待同步状态
- 当网络可用且用户已登录iCloud时，后台执行CloudKit同步
- 同步冲突时，根据策略自动解决或提示用户选择
### 8.2 性能考量
- 使用Realm的异步查询API
- 实现分页加载机制，避免一次加载大量数据
- 对频繁访问的数据实现内存缓存
- 使用Combine框架的防抖动操作优化搜索性能
### 8.3 安全考量
- 使用Realm加密功能保护本地数据
- 敏感用户数据存储在钥匙串(Keychain)中
- 利用CloudKit的内置安全机制保护云端数据
- 实现适当的错误处理，避免敏感信息泄露
## 9. 接口使用示例
### 9.1 词典查询示例
```swift
class SearchViewModel: SearchViewModelProtocol {
    private let dictionaryService: DictionaryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // 实现协议属性
    @Published var searchQuery: String = ""
    @Published var searchType: SearchType = .auto
    @Published private(set) var searchResults: [WordSummaryViewModel] = []
    @Published private(set) var searchHistory: [SearchHistoryItemViewModel] = []
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    init(dictionaryService: DictionaryServiceProtocol) {
        self.dictionaryService = dictionaryService
        loadSearchHistory()
    }
    
    func search() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        dictionaryService.searchWords(query: searchQuery, type: searchType, limit: 20, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = AppErrorHandler().handle(error)
                    }
                },
                receiveValue: { [weak self] result in
                    self?.searchResults = result.items
                }
            )
            .store(in: &cancellables)
    }
    
    // 其他方法实现...
}

```

### 9.2 收藏操作示例
```swift
class DetailViewModel: DetailViewModelProtocol {
    private let dictionaryService: DictionaryServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // 实现协议属性
    @Published private(set) var wordDetails: WordDetailsViewModel? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var isFavorited: Bool = false
    
    init(dictionaryService: DictionaryServiceProtocol, favoriteService: FavoriteServiceProtocol) {
        self.dictionaryService = dictionaryService
        self.favoriteService = favoriteService
    }
    
    func loadWordDetails(id: String) {
        isLoading = true
        errorMessage = nil
        
        dictionaryService.getWordDetails(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = AppErrorHandler().handle(error)
                    }
                },
                receiveValue: { [weak self] details in
                    self?.wordDetails = details
                    self?.isFavorited = details.isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFavorite() {
        guard let wordDetails = wordDetails else { return }
        
        if isFavorited {
            // 查找并删除收藏
            // 实际实现需要先查询收藏项ID
            // 这里简化处理
        } else {
            // 添加到默认收藏夹
            favoriteService.addFavorite(wordId: wordDetails.id, folderId: "default", note: nil)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.errorMessage = AppErrorHandler().handle(error)
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.isFavorited = true
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // 其他方法实现...
}

```

## 10. 总结
本API接口文档设计基于无后端架构，主要通过Swift协议定义了应用内各层之间的交互接口。这种设计有以下优势：

1. 符合离线优先策略 ：所有操作首先在本地执行，确保离线可用
2. 利用原生能力 ：充分利用Realm、CloudKit和AppleAuth的原生能力
3. 清晰的责任分离 ：各层之间通过接口通信，降低耦合度
4. 易于测试 ：接口抽象便于编写单元测试和模拟测试
5. 扩展性好 ：如果未来需要添加后端服务，只需实现相同的接口即可
通过这套接口设计，我们可以实现MVP阶段所需的全部功能，同时为后续功能扩展提供良好的架构基础。