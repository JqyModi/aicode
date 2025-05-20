//
//  UserAuthDataRepository.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import RealmSwift
import AuthenticationServices

class UserAuthDataRepository: UserAuthDataRepositoryProtocol {
    // MARK: - 属性
    private let realmManager: RealmManager
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared, networkManager: NetworkManager = NetworkManager.shared) {
        self.realmManager = realmManager
        self.networkManager = networkManager
    }
    
    // MARK: - UserAuthDataRepositoryProtocol 实现
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<UserEntity, Error> {
        return Future<UserEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            // 将Apple ID登录信息发送到服务器验证
            // 这里简化处理，实际应用中需要与后端API交互
            let tokenString = String(data: identityToken, encoding: .utf8) ?? ""
            
            // 模拟网络请求
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                do {
                    let realm = try self.realmManager.realm()
                    
                    // 检查用户是否已存在
                    let existingUsers = realm.objects(DBUser.self).filter("appleUserId == %@", userIdentifier)
                    
                    if let existingUser = existingUsers.first {
                        // 用户已存在，更新登录信息
                        try realm.write {
                            existingUser.lastLoginAt = Date()
                        }
                        
                        let userSettings = existingUser.settings ?? DBUserSettings()
                        let settingsEntity = UserSettingsEntity(
                            darkMode: userSettings.darkMode,
                            fontSize: userSettings.fontSize,
                            autoSync: userSettings.autoSync
                        )
                        
                        let userEntity = UserEntity(
                            id: existingUser.objectId,
                            nickname: existingUser.nickname,
                            settings: settingsEntity,
                            lastSyncTime: existingUser.lastSyncTime
                        )
                        
                        // 保存当前用户ID到UserDefaults
                        UserDefaults.standard.set(existingUser.objectId, forKey: "currentUserId")
                        UserDefaults.standard.synchronize()
                        
                        promise(.success(userEntity))
                    } else {
                        // 创建新用户
                        let newUser = DBUser()
                        newUser.objectId = UUID().uuidString
                        newUser.appleUserId = userIdentifier
                        newUser.email = email
                        newUser.nickname = fullName?.givenName ?? "用户"
                        newUser.createdAt = Date()
                        newUser.lastLoginAt = Date()
                        
                        // 创建默认设置
                        let userSettings = DBUserSettings()
                        userSettings.darkMode = false
                        userSettings.fontSize = 16
                        userSettings.autoSync = true
                        
                        newUser.settings = userSettings
                        
                        try realm.write {
                            realm.add(newUser)
                        }
                        
                        let settingsEntity = UserSettingsEntity(
                            darkMode: userSettings.darkMode,
                            fontSize: userSettings.fontSize,
                            autoSync: userSettings.autoSync
                        )
                        
                        let userEntity = UserEntity(
                            id: newUser.objectId,
                            nickname: newUser.nickname,
                            settings: settingsEntity,
                            lastSyncTime: nil
                        )
                        
                        // 保存当前用户ID到UserDefaults
                        UserDefaults.standard.set(newUser.objectId, forKey: "currentUserId")
                        UserDefaults.standard.synchronize()
                        
                        promise(.success(userEntity))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<UserEntity?, Error> {
        return Future<UserEntity?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 获取当前登录用户
                // 实际应用中可能需要从UserDefaults或钥匙串中获取当前用户ID
                let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
                
                if let userId = currentUserId, let user = realm.object(ofType: DBUser.self, forPrimaryKey: userId) {
                    let userSettings = user.settings ?? DBUserSettings()
                    let settingsEntity = UserSettingsEntity(
                        darkMode: userSettings.darkMode,
                        fontSize: userSettings.fontSize,
                        autoSync: userSettings.autoSync
                    )
                    
                    let userEntity = UserEntity(
                        id: user.objectId,
                        nickname: user.nickname,
                        settings: settingsEntity,
                        lastSyncTime: user.lastSyncTime
                    )
                    
                    promise(.success(userEntity))
                } else {
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateUserSettings(settings: UserSettingsEntity) -> AnyPublisher<UserSettingsEntity, Error> {
        return Future<UserSettingsEntity, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "UserAuthDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 获取当前用户ID
                guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
                      let user = realm.object(ofType: DBUser.self, forPrimaryKey: currentUserId) else {
                    promise(.failure(NSError(domain: "UserAuthDataRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户未登录"])))
                    return
                }
                
                try realm.write {
                    if user.settings == nil {
                        user.settings = DBUserSettings()
                    }
                    
                    user.settings?.darkMode = settings.darkMode
                    user.settings?.fontSize = settings.fontSize
                    user.settings?.autoSync = settings.autoSync
                }
                
                promise(.success(settings))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard self != nil else {
                promise(.failure(NSError(domain: "UserAuthDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            // 清除当前用户信息
            UserDefaults.standard.removeObject(forKey: "currentUserId")
            UserDefaults.standard.synchronize()
            
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    func isUserLoggedIn() -> Bool {
        return UserDefaults.standard.string(forKey: "currentUserId") != nil
    }
}

// MARK: - 用户相关数据库模型
class DBUser: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var appleUserId: String = ""
    @objc dynamic var email: String? = nil
    @objc dynamic var nickname: String? = nil
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var lastLoginAt: Date = Date()
    @objc dynamic var lastSyncTime: Date? = nil
    @objc dynamic var settings: DBUserSettings? = nil
    
    override static func primaryKey() -> String? {
        return "objectId"
    }
}

class DBUserSettings: Object {
    @objc dynamic var darkMode: Bool = false
    @objc dynamic var fontSize: Int = 16
    @objc dynamic var autoSync: Bool = true
}
