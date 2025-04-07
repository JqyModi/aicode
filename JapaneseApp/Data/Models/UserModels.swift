import Foundation
import RealmSwift

// 用户模型
class User: Object {
    @Persisted(primaryKey: true) var id: String  // Apple ID标识符
    @Persisted var nickname: String?             // 昵称
    @Persisted var settings: UserSettings?       // 用户设置
    @Persisted var lastSyncTime: Date?           // 最后同步时间
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var updatedAt: Date = Date()      // 更新时间
    @Persisted var email: String?                // 用户邮箱（可能为空）
    @Persisted var syncStatus: Int = 0           // 同步状态
    
    convenience init(id: String, nickname: String? = nil, email: String? = nil) {
        self.init()
        self.id = id
        self.nickname = nickname
        self.email = email
        self.settings = UserSettings()
    }
}

// 用户设置
class UserSettings: EmbeddedObject {
    @Persisted var darkMode: Bool = false        // 深色模式
    @Persisted var fontSize: Int = 2             // 字体大小（1-小，2-中，3-大）
    @Persisted var autoSync: Bool = true         // 自动同步
    @Persisted var notificationsEnabled: Bool = true  // 通知开关
    @Persisted var studyReminderTime: Date? = nil     // 学习提醒时间
    
    convenience init(darkMode: Bool = false, fontSize: Int = 2, autoSync: Bool = true) {
        self.init()
        self.darkMode = darkMode
        self.fontSize = fontSize
        self.autoSync = autoSync
    }
}

// 用户认证状态枚举
enum AuthStatus: Int {
    case notAuthenticated = 0  // 未认证
    case authenticated = 1     // 已认证
    case failed = 2            // 认证失败
}

// 同步状态枚举（与API文档保持一致）
enum SyncStatus: Int {
    case synced = 0            // 已同步
    case pendingUpload = 1     // 待上传
    case pendingDownload = 2   // 待下载
    case conflict = 3          // 冲突
    case error = 4             // 错误
}