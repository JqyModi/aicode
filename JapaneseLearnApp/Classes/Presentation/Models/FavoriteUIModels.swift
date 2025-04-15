import Foundation
import SwiftUI

// MARK: - 收藏模块表现层模型

// 收藏夹UI模型
struct FolderUI: Identifiable {
    let id: String
    let name: String
    let createdAt: Date
    let items: [FavoriteItemUI]
    let syncStatus: SyncStatusType
    let lastModified: Date
    let isDefault: Bool
}

// 收藏项UI模型
struct FavoriteItemUI: Identifiable {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatusType
}

// 收藏夹摘要UI模型
struct FolderSummaryUI: Identifiable {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatusType
}

// 收藏分类UI模型
struct FavoriteCategoryUI: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let count: Int
    let createdAt: Date
    let updatedAt: Date
    let syncStatus: SyncStatusType
}