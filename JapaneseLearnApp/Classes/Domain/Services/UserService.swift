//
//  UserService.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class UserService: UserServiceProtocol {
    // MARK: - 属性
    private let userRepository: UserAuthDataRepositoryProtocol
    
    // MARK: - 初始化
    init(userRepository: UserAuthDataRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    // MARK: - UserServiceProtocol 实现
    func signInWithApple() -> AnyPublisher<UserProfileDomain, UserErrorDomain> {
        // 注意：这里简化了Apple登录流程，实际应用中需要处理ASAuthorizationController
        // 这里假设Apple登录的令牌和授权码已经在UI层获取并传递给数据层
        return userRepository.getCurrentUser()
            .flatMap { user -> AnyPublisher<UserEntity, Error> in
                if let user = user {
                    return Just(user)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "用户未登录"]))
                        .eraseToAnyPublisher()
                }
            }
            .map { entity -> UserProfileDomain in
                return self.mapToUserProfileDomain(from: entity)
            }
            .mapError { error -> UserErrorDomain in
                return self.mapToUserError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getUserProfile() -> AnyPublisher<UserProfileDomain, UserErrorDomain> {
        return userRepository.getCurrentUser()
            .flatMap { user -> AnyPublisher<UserEntity, Error> in
                if let user = user {
                    return Just(user)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "用户未找到"]))
                        .eraseToAnyPublisher()
                }
            }
            .map { entity -> UserProfileDomain in
                return self.mapToUserProfileDomain(from: entity)
            }
            .mapError { error -> UserErrorDomain in
                return self.mapToUserError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func updateUserSettings(settings: UserPreferencesDomain) -> AnyPublisher<UserPreferencesDomain, UserErrorDomain> {
        let entitySettings = mapToUserSettingsEntity(from: settings)
        
        return userRepository.updateUserSettings(settings: entitySettings)
            .map { entity -> UserPreferencesDomain in
                return self.mapToUserPreferencesDomain(from: entity)
            }
            .mapError { error -> UserErrorDomain in
                return self.mapToUserError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Bool, UserErrorDomain> {
        return userRepository.signOut()
            .mapError { error -> UserErrorDomain in
                return self.mapToUserError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func isUserLoggedIn() -> Bool {
        return userRepository.isUserLoggedIn()
    }
    
    // MARK: - 私有映射方法
    private func mapToUserProfileDomain(from entity: UserEntity) -> UserProfileDomain {
        return UserProfileDomain(
            userId: entity.id,
            nickname: entity.nickname,
            settings: mapToUserPreferencesDomain(from: entity.settings),
            lastSyncTime: entity.lastSyncTime,
            favoriteCount: 0, // 这些数据可能需要从其他仓库获取
            folderCount: 0
        )
    }
    
    private func mapToUserPreferencesDomain(from entity: UserSettingsEntity) -> UserPreferencesDomain {
        return UserPreferencesDomain(
            darkMode: entity.darkMode,
            fontSize: entity.fontSize,
            autoSync: entity.autoSync
        )
    }
    
    private func mapToUserSettingsEntity(from domain: UserPreferencesDomain) -> UserSettingsEntity {
        return UserSettingsEntity(
            darkMode: domain.darkMode,
            fontSize: domain.fontSize,
            autoSync: domain.autoSync
        )
    }
    
    private func mapToUserError(_ error: Error) -> UserErrorDomain {
        // 根据错误类型映射到业务层错误
        if error.localizedDescription.contains("authentication") || error.localizedDescription.contains("登录") {
            return .authenticationFailed
        } else if error.localizedDescription.contains("not found") || error.localizedDescription.contains("未找到") {
            return .userNotFound
        } else if error.localizedDescription.contains("settings") || error.localizedDescription.contains("设置") {
            return .settingsUpdateFailed
        } else if error.localizedDescription.contains("sign out") || error.localizedDescription.contains("登出") {
            return .signOutFailed
        }
        
        // 默认返回认证失败
        return .authenticationFailed
    }
}