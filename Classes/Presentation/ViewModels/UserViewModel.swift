import Foundation
import Combine
import SwiftUI

protocol UserViewModelProtocol: ObservableObject {
    // 输出属性
    var userProfile: UserProfile? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userSettings: UserPreferences { get }
    
    // 方法
    func signInWithApple()
    func signOut()
    func loadUserProfile()
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool)
}

class UserViewModel: ObservableObject, UserViewModelProtocol {
    // MARK: - 输出属性
    @Published var userProfile: UserProfile?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userSettings: UserPreferences = UserPreferences(darkMode: false, fontSize: 16, autoSync: true)
    
    // MARK: - 私有属性
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(userService: UserServiceProtocol) {
        self.userService = userService
        checkLoginStatus()
    }
    
    // MARK: - 公共方法
    /// Apple ID登录
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        userService.signInWithApple()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                    self?.isLoggedIn = true
                    self?.userSettings = profile.settings
                }
            )
            .store(in: &cancellables)
    }
    
    /// 登出
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        userService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        self?.userProfile = nil
                        self?.isLoggedIn = false
                        // 重置为默认设置
                        self?.userSettings = UserPreferences(darkMode: false, fontSize: 16, autoSync: true)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载用户信息
    func loadUserProfile() {
        isLoading = true
        errorMessage = nil
        
        userService.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                    self?.userSettings = profile.settings
                }
            )
            .store(in: &cancellables)
    }
    
    /// 更新用户设置
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool) {
        isLoading = true
        errorMessage = nil
        
        let newSettings = UserPreferences(darkMode: darkMode, fontSize: fontSize, autoSync: autoSync)
        
        userService.updateUserSettings(settings: newSettings)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] updatedSettings in
                    self?.userSettings = updatedSettings
                    // 如果用户资料存在，更新其中的设置
                    if var profile = self?.userProfile {
                        profile.settings = updatedSettings
                        self?.userProfile = profile
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 私有方法
    /// 检查登录状态
    private func checkLoginStatus() {
        isLoggedIn = userService.isUserLoggedIn()
        
        if isLoggedIn {
            loadUserProfile()
        }
    }
    
    /// 处理错误
    private func handleError(_ error: Error) {
        if let userError = error as? UserError {
            switch userError {
            case .authenticationFailed:
                errorMessage = "认证失败，请重试"
            case .userNotFound:
                errorMessage = "用户不存在"
            case .settingsUpdateFailed:
                errorMessage = "设置更新失败"
            case .signOutFailed:
                errorMessage = "登出失败"
            default:
                errorMessage = "登出错误"
            }
        } else {
            errorMessage = "发生错误: \(error.localizedDescription)"
        }
    }
}
