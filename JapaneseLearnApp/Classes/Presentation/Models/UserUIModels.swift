import Foundation
import SwiftUI

// MARK: - 用户模块表现层模型

// 用户资料UI模型
struct UserProfileUI: Identifiable {
    var id: String { userId }
    let userId: String
    let nickname: String?
    let settings: UserPreferencesUI
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

// 用户偏好UI模型
struct UserPreferencesUI {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}