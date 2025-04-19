//
//  UserAuthRepository.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine
import RealmSwift
import AuthenticationServices

class UserAuthRepository: UserAuthRepositoryProtocol {
    
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let userIdKey = "currentUserId"
    
    init() {
        do {
            self.realm = try Realm()
        } catch {
            fatalError("无法初始化Realm: \(error)")
        }
    }
    
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error> {
        return Future<User, Error> { promise in
            do {
                // 检查用户是否已存在
                let existingUsers = self.realm.objects(User.self)
                    .filter("appleUserId == %@", userIdentifier)
                
                let user: User
                
                try self.realm.write {
                    if let existingUser = existingUsers.first {
                        // 更新现有用户
                        user = existingUser
                        user.lastLoginAt = Date()
                        
                        // 如果用户之前没有设置昵称，并且这次提供了名字，则更新昵称
                        if user.nickname == nil || user.nickname?.isEmpty == true,
                           let givenName = fullName?.givenName {
                            user.nickname = givenName
                        }
                        
                        // 如果用户之前没有设置邮箱，并且这次提供了邮箱，则更新邮箱
                        if user.email == nil || user.email?.isEmpty == true,
                           let newEmail = email, !newEmail.isEmpty {
                            user.email = newEmail
                        }
                    } else {
                        // 创建新用户
                        user = User()
                        user.appleUserId = userIdentifier
                        user.nickname = fullName?.givenName
                        user.email = email
                        user.createdAt = Date()
                        user.lastLoginAt = Date()
                        
                        // 创建默认设置
                        let settings = UserSettings()
                        settings.darkMode = false
                        settings.fontSize = 16
                        settings.autoSync = true
                        
                        user.settings = settings
                        
                        self.realm.add(user)
                    }
                }
                
                // 保存当前用户ID
                self.userDefaults.set(user.id, forKey: self.userIdKey)
                
                promise(.success(user))
            } catch {
                promise(.failure(UserError.authenticationFailed))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error> {
        return Future<User?, Error> { promise in
            guard let userId = self.userDefaults.string(forKey: self.userIdKey) else {
                promise(.success(nil))
                return
            }
            
            let user = self.realm.object(ofType: User.self, forPrimaryKey: userId)
            promise(.success(user))
        }.eraseToAnyPublisher()
    }
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error> {
        return Future<UserSettings, Error> { promise in
            do {
                guard let userId = self.userDefaults.string(forKey: self.userIdKey),
                      let user = self.realm.object(ofType: User.self, forPrimaryKey: userId) else {
                    promise(.failure(UserError.userNotFound))
                    return
                }
                
                try self.realm.write {
                    if let existingSettings = user.settings {
                        existingSettings.darkMode = settings.darkMode
                        existingSettings.fontSize = settings.fontSize
                        existingSettings.autoSync = settings.autoSync
                    } else {
                        user.settings = settings
                    }
                    
                    user.syncStatus = UISyncStatus.pendingUpload.rawValue
                }
                
                promise(.success(user.settings ?? settings))
            } catch {
                promise(.failure(UserError.settingsUpdateFailed))
            }
        }.eraseToAnyPublisher()
    }
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            self.userDefaults.removeObject(forKey: self.userIdKey)
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool {
        return userDefaults.string(forKey: userIdKey) != nil
    }
}