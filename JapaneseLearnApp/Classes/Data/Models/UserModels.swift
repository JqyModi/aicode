import Foundation
import RealmSwift

// MARK: - 用户模块数据模型

// 用户模型
class DBUser: Object {
    @Persisted(primaryKey: true) var id: String  // Apple ID标识符
    @Persisted var nickname: String?             // 昵称
    @Persisted var email: String?                // 邮箱
    @Persisted var settings: DBUserSettings?       // 用户设置
    @Persisted var lastSyncTime: Date?           // 最后同步时间
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var syncStatus: Int = SyncStatusType.pendingUpload.rawValue // 同步状态
    
    // 转换为领域模型
    func toDomain() -> UserProfileDomain {
        return UserProfileDomain(
            userId: self.id,
            nickname: self.nickname,
            settings: self.settings?.toDomain() ?? UserPreferencesDomain(),
            lastSyncTime: self.lastSyncTime,
            favoriteCount: 0, // 这个值需要从其他地方获取
            folderCount: 0    // 这个值需要从其他地方获取
        )
    }
}

// 用户设置
class DBUserSettings: EmbeddedObject {
    @Persisted var darkMode: Bool = false        // 深色模式
    @Persisted var fontSize: Int = 2             // 字体大小
    @Persisted var autoSync: Bool = true         // 自动同步
    @Persisted var notificationsEnabled: Bool = true // 通知开关
    @Persisted var syncFrequency: Int = 1        // 同步频率（小时）
    
    // 转换为领域模型
    func toDomain() -> UserPreferencesDomain {
        return UserPreferencesDomain(
            darkMode: self.darkMode,
            fontSize: self.fontSize,
            autoSync: self.autoSync
        )
    }
}

// 认证令牌
class DBAuthToken: Object {
    @Persisted(primaryKey: true) var id: String = "auth_token"
    @Persisted var identityToken: Data?          // 身份令牌
    @Persisted var authorizationCode: String?    // 授权码
    @Persisted var expiresAt: Date?              // 过期时间
    @Persisted var refreshToken: String?         // 刷新令牌
    
    // 转换为领域模型
    func toDomain() -> AuthTokenDomain {
        return AuthTokenDomain(
            identityToken: self.identityToken,
            authorizationCode: self.authorizationCode,
            expiresAt: self.expiresAt,
            refreshToken: self.refreshToken
        )
    }
}