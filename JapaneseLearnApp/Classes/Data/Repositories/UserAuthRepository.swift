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
    func checkAuthStatus() -> AnyPublisher<Bool, Error>
    
    // 获取用户设置
    func getUserSettings() -> AnyPublisher<UserSettings?, Error>
}

class UserAuthRepository: UserAuthRepositoryProtocol {
    private let realmManager: RealmManager
    private let appleAuthService: AppleAuthService
    
    init(realmManager: RealmManager = RealmManager.shared, 
         appleAuthService: AppleAuthService = AppleAuthService.shared) {
        self.realmManager = realmManager
        self.appleAuthService = appleAuthService
    }
    
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error> {
        // 首先验证身份令牌
        return appleAuthService.verifyIdentityToken(identityToken)
            .flatMap { isValid -> AnyPublisher<User, Error> in
                guard isValid else {
                    return Fail(error: NSError(domain: "UserAuthRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "无效的身份令牌"])).eraseToAnyPublisher()
                }
                
                // 保存或更新用户信息
                return self.realmManager.writeAsync { realm in
                    // 检查用户是否已存在
                    let existingUser = realm.object(ofType: User.self, forPrimaryKey: userIdentifier)
                    
                    if let user = existingUser {
                        // 更新现有用户
                        if let email = email {
                            user.email = email
                        }
                        
                        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                            if user.nickname == nil {
                                user.nickname = "\(familyName)\(givenName)"
                            }
                        }
                        
                        user.lastSyncTime = Date()
                        user.syncStatus = SyncStatusType.pendingUpload.rawValue
                        
                        // 保存认证令牌
                        let token = AuthToken()
                        token.identityToken = identityToken
                        token.authorizationCode = authorizationCode
                        token.expiresAt = Calendar.current.date(byAdding: .day, value: 180, to: Date())
                        
                        realm.add(token, update: .modified)
                        
                        return user
                    } else {
                        // 创建新用户
                        let newUser = User()
                        newUser.id = userIdentifier
                        newUser.email = email
                        
                        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                            newUser.nickname = "\(familyName)\(givenName)"
                        }
                        
                        // 创建默认设置
                        let settings = UserSettings()
                        newUser.settings = settings
                        
                        // 保存认证令牌
                        let token = AuthToken()
                        token.identityToken = identityToken
                        token.authorizationCode = authorizationCode
                        token.expiresAt = Calendar.current.date(byAdding: .day, value: 180, to: Date())
                        
                        realm.add(newUser)
                        realm.add(token, update: .modified)
                        
                        return newUser
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                
                // 获取认证令牌
                guard let token = realm.object(ofType: AuthToken.self, forPrimaryKey: "auth_token"),
                      let identityToken = token.identityToken,
                      let userInfo = try? self.extractUserInfo(from: identityToken) else {
                    // 没有有效的令牌，返回nil
                    promise(.success(nil))
                    return
                }
                
                // 检查令牌是否过期
                if let expiresAt = token.expiresAt, expiresAt < Date() {
                    // 令牌已过期，返回nil
                    promise(.success(nil))
                    return
                }
                
                // 获取用户信息
                if let userId = userInfo["sub"] as? String,
                   let user = realm.object(ofType: User.self, forPrimaryKey: userId) {
                    promise(.success(user))
                } else {
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error> {
        return getCurrentUser()
            .flatMap { user -> AnyPublisher<UserSettings, Error> in
                guard let user = user else {
                    return Fail(error: NSError(domain: "UserAuthRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])).eraseToAnyPublisher()
                }
                
                return self.realmManager.writeAsync { realm in
                    // 更新用户设置
                    if let existingSettings = user.settings {
                        existingSettings.darkMode = settings.darkMode
                        existingSettings.fontSize = settings.fontSize
                        existingSettings.autoSync = settings.autoSync
                        existingSettings.notificationsEnabled = settings.notificationsEnabled
                        existingSettings.syncFrequency = settings.syncFrequency
                        
                        user.syncStatus = SyncStatusType.pendingUpload.rawValue
                        
                        return existingSettings
                    } else {
                        // 如果用户没有设置，创建新设置
                        let newSettings = settings
                        user.settings = newSettings
                        user.syncStatus = SyncStatusType.pendingUpload.rawValue
                        
                        return newSettings
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error> {
        return realmManager.writeAsync { realm in
            // 删除认证令牌
            if let token = realm.object(ofType: AuthToken.self, forPrimaryKey: "auth_token") {
                realm.delete(token)
            }
            
            return true
        }
    }
    
    // 检查登录状态
    func checkAuthStatus() -> AnyPublisher<Bool, Error> {
        return getCurrentUser()
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    // 获取用户设置
    func getUserSettings() -> AnyPublisher<UserSettings?, Error> {
        return getCurrentUser()
            .map { $0?.settings }
            .eraseToAnyPublisher()
    }
    
    // 从JWT令牌中提取用户信息
    private func extractUserInfo(from identityToken: Data) throws -> [String: Any] {
        guard let jwt = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "UserAuthRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解码身份令牌"])
        }
        
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else {
            throw NSError(domain: "UserAuthRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的JWT格式"])
        }
        
        let base64String = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padded = base64String.padding(toLength: ((base64String.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: padded) else {
            throw NSError(domain: "UserAuthRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解码JWT负载"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "UserAuthRepository", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析JWT负载"])
        }
        
        return json
    }
}
