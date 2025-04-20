//
//  UserViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import SwiftUI

class UserViewModel: UserViewModelProtocol {
    // MARK: - 属性
    @Published private(set) var userProfile: UserProfileViewModel?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var userSettings: UserPreferencesViewModel = UserPreferencesViewModel(darkMode: false, fontSize: 16, autoSync: true)
    
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 计算属性
    var isLoggedIn: Bool {
        return userService.isUserLoggedIn()
    }
    
    // MARK: - 初始化
    init(userService: UserServiceProtocol) {
        self.userService = userService
        loadUserProfile()
    }
    
    // MARK: - 公共方法
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        userService.signInWithApple()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "登录失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] profile in
                self?.updateUserProfile(from: profile)
            }
            .store(in: &cancellables)
    }
    
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        userService.signOut()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "登出失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.userProfile = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        guard isLoggedIn else { return }
        
        isLoading = true
        errorMessage = nil
        
        userService.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "获取用户信息失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] profile in
                self?.updateUserProfile(from: profile)
            }
            .store(in: &cancellables)
    }
    
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool) {
        isLoading = true
        errorMessage = nil
        
        let newSettings = UserPreferencesDomain(darkMode: darkMode, fontSize: fontSize, autoSync: autoSync)
        
        userService.updateUserSettings(settings: newSettings)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "更新设置失败: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] updatedSettings in
                self?.userSettings = UserPreferencesViewModel(
                    darkMode: updatedSettings.darkMode,
                    fontSize: updatedSettings.fontSize,
                    autoSync: updatedSettings.autoSync
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 私有方法
    private func updateUserProfile(from domainProfile: UserProfileDomain) {
        userProfile = UserProfileViewModel(
            userId: domainProfile.userId,
            nickname: domainProfile.nickname,
            lastSyncTime: domainProfile.lastSyncTime,
            favoriteCount: domainProfile.favoriteCount,
            folderCount: domainProfile.folderCount
        )
        
        userSettings = UserPreferencesViewModel(
            darkMode: domainProfile.settings.darkMode,
            fontSize: domainProfile.settings.fontSize,
            autoSync: domainProfile.settings.autoSync
        )
    }
}