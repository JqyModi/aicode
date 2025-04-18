//
//  UserModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import RealmSwift

// MARK: - 用户
class User: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var appleUserId: String = ""
    @objc dynamic var nickname: String? = nil
    @objc dynamic var email: String? = nil
    @objc dynamic var lastLoginDate: Date = Date()
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var settings: UserSettings? = nil
    @objc dynamic var lastSyncTime: Date? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 用户设置
class UserSettings: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var userId: String = ""
    @objc dynamic var darkMode: Bool = false
    @objc dynamic var fontSize: Int = 16
    @objc dynamic var autoSync: Bool = true
    @objc dynamic var lastModified: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}