import Foundation
import SwiftUI

// MARK: - 同步模块表现层模型

// 同步状态UI模型
struct SyncStatusInfoUI {
    let lastSyncTime: Date?
    let isCloudKitAvailable: Bool
    let isAutoSyncEnabled: Bool
    let currentOperation: SyncOperationInfoUI?
}

// 同步操作UI模型
struct SyncOperationInfoUI: Identifiable {
    let id: String
    let type: String
    let status: String
    let startTime: Date
    let endTime: Date?
    let progress: Double
    let itemsProcessed: Int
    let totalItems: Int
    let errorMessage: String?
    
    // 计算属性：进度百分比文本
    var progressText: String {
        return "\(Int(progress * 100))%"
    }
    
    // 计算属性：状态文本
    var statusText: String {
        switch status {
        case "pending":
            return "等待中"
        case "running":
            return "同步中"
        case "completed":
            return "已完成"
        case "failed":
            return "失败"
        default:
            return status
        }
    }
    
    // 计算属性：类型文本
    var typeText: String {
        switch type {
        case "full":
            return "全量同步"
        case "incremental":
            return "增量同步"
        case "upload":
            return "上传"
        case "download":
            return "下载"
        default:
            return type
        }
    }
}