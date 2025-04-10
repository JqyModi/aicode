import Foundation
import Combine
import AuthenticationServices
import RealmSwift

// MARK: - 用户服务协议
protocol UserServiceProtocol {
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfile, UserError>
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfile, UserError>
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferences) -> AnyPublisher<UserPreferences, UserError>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserError>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

// MARK: - 用户服务实现
class UserService: NSObject, UserServiceProtocol {
    private let userAuthRepository: UserAuthRepositoryProtocol
    private let favoriteRepository: FavoriteRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userAuthRepository: UserAuthRepositoryProtocol, favoriteRepository: FavoriteRepositoryProtocol) {
        self.userAuthRepository = userAuthRepository
        self.favoriteRepository = favoriteRepository
        super.init()
    }
    
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfile, UserError> {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        
        return Future<ASAuthorization, Error> { promise in
            let delegate = AppleSignInDelegate(completion: promise)
            authorizationController.delegate = delegate
            authorizationController.presentationContextProvider = delegate
            authorizationController.performRequests()
            
            // 保持delegate引用，直到授权完成
            self.appleSignInDelegate = delegate
        }
        .flatMap { authorization -> AnyPublisher<User, Error> in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let authorizationCode = appleIDCredential.authorizationCode else {
                return Fail(error: UserError.authenticationFailed).eraseToAnyPublisher()
            }
            
            return self.userAuthRepository.signInWithApple(
                identityToken: identityToken,
                authorizationCode: String(data: authorizationCode, encoding: .utf8) ?? "",
                fullName: appleIDCredential.fullName,
                email: appleIDCredential.email,
                userIdentifier: appleIDCredential.user
            )
        }
        .flatMap { user -> AnyPublisher<(User, Int, Int), Error> in
            // 获取收藏夹和收藏项数量
            return self.getFavoriteStats()
                .map { (folderCount, itemCount) in
                    return (user, folderCount, itemCount)
                }
                .eraseToAnyPublisher()
        }
        .map { user, folderCount, itemCount in
            return self.mapUserToProfile(user: user, folderCount: folderCount, favoriteCount: itemCount)
        }
        .mapError { error in
            return self.mapError(error)
        }
        .eraseToAnyPublisher()
    }
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfile, UserError> {
        return userAuthRepository.getCurrentUser()
            .flatMap { user -> AnyPublisher<(User?, Int, Int), Error> in
                guard let user = user else {
                    return Fail(error: UserError.userNotFound).eraseToAnyPublisher()
                }
                
                // 获取收藏夹和收藏项数量
                return self.getFavoriteStats()
                    .map { (folderCount, itemCount) in
                        return (user, folderCount, itemCount)
                    }
                    .eraseToAnyPublisher()
            }
            .tryMap { user, folderCount, itemCount in
                guard let user = user else {
                    throw UserError.userNotFound
                }
                return self.mapUserToProfile(user: user, folderCount: folderCount, favoriteCount: itemCount)
            }
            .mapError { error in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferences) -> AnyPublisher<UserPreferences, UserError> {
        let userSettings = UserSettings()
        userSettings.darkMode = settings.darkMode
        userSettings.fontSize = settings.fontSize
        userSettings.autoSync = settings.autoSync
        
        return userAuthRepository.updateUserSettings(settings: userSettings)
            .map { updatedSettings in
                return UserPreferences(
                    darkMode: updatedSettings.darkMode,
                    fontSize: updatedSettings.fontSize,
                    autoSync: updatedSettings.autoSync
                )
            }
            .mapError { error in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserError> {
        return userAuthRepository.signOut()
            .mapError { error in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool {
        var isLoggedIn = false
        
        userAuthRepository.checkAuthStatus()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { status in
                    isLoggedIn = status
                }
            )
            .store(in: &cancellables)
        
        return isLoggedIn
    }
    
    // MARK: - 私有辅助方法
    
    // 获取收藏统计数据
    private func getFavoriteStats() -> AnyPublisher<(Int, Int), Error> {
        return favoriteRepository.getAllFolders()
            .map { folders -> (Int, Int) in
                let folderCount = folders.count
                let itemCount = folders.reduce(0) { $0 + $1.items.count }
                return (folderCount, itemCount)
            }
            .eraseToAnyPublisher()
    }
    
    // 将User模型映射为UserProfile
    private func mapUserToProfile(user: User, folderCount: Int, favoriteCount: Int) -> UserProfile {
        let preferences = UserPreferences(
            darkMode: user.settings?.darkMode ?? false,
            fontSize: user.settings?.fontSize ?? 2,
            autoSync: user.settings?.autoSync ?? true
        )
        
        return UserProfile(
            userId: user.id,
            nickname: user.nickname,
            settings: preferences,
            lastSyncTime: user.lastSyncTime,
            favoriteCount: favoriteCount,
            folderCount: folderCount
        )
    }
    
    // 错误映射
    private func mapError(_ error: Error) -> UserError {
        if let userError = error as? UserError {
            return userError
        }
        
        if let nsError = error as NSError? {
            if nsError.domain == "AuthenticationServices" {
                return .authenticationFailed
            } else if nsError.domain == "NSURLErrorDomain" {
                return .networkError
            } else if nsError.domain.contains("Realm") {
                return .databaseError(error)
            }
        }
        
        return .unknown
    }
    
    // MARK: - Apple Sign In 代理
    private var appleSignInDelegate: AppleSignInDelegate?
}

// MARK: - Apple Sign In 代理类
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 获取当前活跃的窗口
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        return window ?? UIWindow()
    }
}