import Foundation

// MARK: - 用户模块业务层模型

// 用户资料业务模型
struct UserProfileDomain {
    let userId: String
    let nickname: String?
    var settings: UserPreferencesDomain
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
    
    // 转换为数据层模型
    func toData() -> DBUser {
        let dbUser = DBUser()
        dbUser.id = self.userId
        dbUser.nickname = self.nickname
        dbUser.lastSyncTime = self.lastSyncTime
        dbUser.createdAt = Date()
        dbUser.syncStatus = SyncStatusType.pendingUpload.rawValue
        
        // 转换设置
        let dbSettings = DBUserSettings()
        dbSettings.darkMode = self.settings.darkMode
        dbSettings.fontSize = self.settings.fontSize
        dbSettings.autoSync = self.settings.autoSync
        dbUser.settings = dbSettings
        
        return dbUser
    }
    
    // 转换为表现层模型
    func toUI() -> UserProfileUI {
        return UserProfileUI(
            userId: self.userId,
            nickname: self.nickname,
            settings: self.settings.toUI(),
            lastSyncTime: self.lastSyncTime,
            favoriteCount: self.favoriteCount,
            folderCount: self.folderCount
        )
    }
}

// 用户偏好业务模型
struct UserPreferencesDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
    
    init(darkMode: Bool = false, fontSize: Int = 2, autoSync: Bool = true) {
        self.darkMode = darkMode
        self.fontSize = fontSize
        self.autoSync = autoSync
    }
    
    // 转换为表现层模型
    func toUI() -> UserPreferencesUI {
        return UserPreferencesUI(
            darkMode: self.darkMode,
            fontSize: self.fontSize,
            autoSync: self.autoSync
        )
    }
}

// 认证令牌业务模型
struct AuthTokenDomain {
    let identityToken: Data?
    let authorizationCode: String?
    let expiresAt: Date?
    let refreshToken: String?
    
    // 转换为数据层模型
    func toData() -> DBAuthToken {
        let dbToken = DBAuthToken()
        dbToken.identityToken = self.identityToken
        dbToken.authorizationCode = self.authorizationCode
        dbToken.expiresAt = self.expiresAt
        dbToken.refreshToken = self.refreshToken
        return dbToken
    }
}

// 用户服务错误类型
enum UserError: Error {
    case authenticationFailed
    case userNotFound
    case settingsUpdateFailed
    case signOutFailed
    case networkError
    case databaseError(Error)
    case syncError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            return "认证失败"
        case .userNotFound:
            return "未找到用户"
        case .settingsUpdateFailed:
            return "设置更新失败"
        case .signOutFailed:
            return "退出登录失败"
        case .networkError:
            return "网络连接错误"
        case .databaseError(let error):
            return "数据库错误: \(error.localizedDescription)"
        case .syncError:
            return "同步错误"
        case .unknown:
            return "未知错误"
        }
    }
}