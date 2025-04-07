import Foundation
import RealmSwift
import Combine
import AuthenticationServices

protocol UserAuthRepositoryProtocol {
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error>
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error>
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

class UserAuthRepository: UserAuthRepositoryProtocol {
    
    private let realm: Realm
    private let appleAuthService: AppleAuthService
    private let userDefaults = UserDefaults.standard
    private let currentUserIdKey = "currentUserId"
    
    init(realm: Realm? = nil, appleAuthService: AppleAuthService = AppleAuthService()) {
        do {
            self.realm = try realm ?? Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
        self.appleAuthService = appleAuthService
    }
    
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 验证令牌（在实际应用中可能需要与服务器验证）
            self.appleAuthService.validateToken(identityToken: identityToken) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // 令牌验证成功，创建或更新用户
                    do {
                        try self.realm.write {
                            // 检查用户是否已存在
                            if let existingUser = self.realm.object(ofType: User.self, forPrimaryKey: userIdentifier) {
                                // 更新现有用户
                                existingUser.updatedAt = Date()
                                if let email = email, !email.isEmpty {
                                    existingUser.email = email
                                }
                                if let fullName = fullName, let givenName = fullName.givenName {
                                    existingUser.nickname = givenName
                                }
                                promise(.success(existingUser))
                            } else {
                                // 创建新用户
                                let nickname = fullName?.givenName
                                let newUser = User(id: userIdentifier, nickname: nickname, email: email)
                                self.realm.add(newUser)
                                promise(.success(newUser))
                            }
                            
                            // 保存当前用户ID
                            self.userDefaults.set(userIdentifier, forKey: self.currentUserIdKey)
                        }
                    } catch {
                        promise(.failure(error))
                    }
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 从UserDefaults获取当前用户ID
            guard let userId = self.userDefaults.string(forKey: self.currentUserIdKey) else {
                // 没有登录用户
                promise(.success(nil))
                return
            }
            
            // 从Realm获取用户对象
            let user = self.realm.object(ofType: User.self, forPrimaryKey: userId)
            promise(.success(user))
        }.eraseToAnyPublisher()
    }
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error> {
        return Future<UserSettings, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 获取当前用户ID
            guard let userId = self.userDefaults.string(forKey: self.currentUserIdKey),
                  let user = self.realm.object(ofType: User.self, forPrimaryKey: userId) else {
                promise(.failure(NSError(domain: "UserAuthRepository", code: -2, userInfo: [NSLocalizedDescriptionKey: "No logged in user found"])))
                return
            }
            
            do {
                try self.realm.write {
                    // 更新用户设置
                    if user.settings == nil {
                        user.settings = settings
                    } else {
                        user.settings?.darkMode = settings.darkMode
                        user.settings?.fontSize = settings.fontSize
                        user.settings?.autoSync = settings.autoSync
                        user.settings?.notificationsEnabled = settings.notificationsEnabled
                        user.settings?.studyReminderTime = settings.studyReminderTime
                    }
                    user.updatedAt = Date()
                    user.syncStatus = SyncStatus.pendingUpload.rawValue
                    
                    promise(.success(user.settings!))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Repository instance is nil"])))
                return
            }
            
            // 清除当前用户ID
            self.userDefaults.removeObject(forKey: self.currentUserIdKey)
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool {
        return userDefaults.string(forKey: currentUserIdKey) != nil
    }
}