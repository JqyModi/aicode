//
//  UserViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import SwiftUI
import AuthenticationServices

class UserViewModel: NSObject, UserViewModelProtocol, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
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
        
        super.init()
        loadUserProfile()
    }
    
    // MARK: - 公共方法
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let identityToken = appleIDCredential.identityToken,
                  let authorizationCode = appleIDCredential.authorizationCode else {
                self.errorMessage = "登录失败: 无法获取必要的授权信息"
                self.isLoading = false
                return
            }
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            userService.signInWithApple(identityToken: identityToken, authorizationCode: authorizationCode, fullName: fullName, email: email, userIdentifier: userIdentifier)
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
        } else {
            self.errorMessage = "登录失败: 不支持的授权类型"
            self.isLoading = false
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.isLoading = false
        self.errorMessage = "登录失败: \(error.localizedDescription)"
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 获取当前窗口作为呈现锚点
        // 注意：在SwiftUI中，这需要通过UIApplication.shared.windows或UIApplication.shared.connectedScenes获取
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("无法获取窗口场景")
        }
        return window
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
