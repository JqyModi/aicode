import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    // 服务
    lazy var dictionaryService: DictionaryServiceProtocol = DictionaryService(dictionaryRepository: DictionaryRepository(), audioService: AudioService())
    lazy var favoriteService: FavoriteServiceProtocol = FavoriteService(favoriteRepository: FavoriteRepository(), dictionaryRepository: DictionaryRepository())
    lazy var userService: UserServiceProtocol = UserService(userAuthRepository: UserAuthRepository(), favoriteRepository: FavoriteRepository())
    
    // 视图模型
    lazy var searchViewModel: SearchViewModel = SearchViewModel(dictionaryService: dictionaryService)
    lazy var detailViewModel: DetailViewModel = DetailViewModel(
        dictionaryService: dictionaryService,
        favoriteService: favoriteService
    )
    lazy var userViewModel: UserViewModel = UserViewModel(userService: userService)
    
    // 新增的 DictionaryViewModel
    lazy var dictionaryViewModel: DictionaryViewModel = DictionaryViewModel(
        dictionaryService: dictionaryService,
        favoriteService: favoriteService,
        userService: userService,
        searchViewModel: searchViewModel,
        detailViewModel: detailViewModel
    )
    
    private init() {}
}
