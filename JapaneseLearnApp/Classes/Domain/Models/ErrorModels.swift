//
//  ErrorModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation

// MARK: - 通用错误基类
enum AppError: Error {
    case unknown
    case networkError
    case databaseError(String)
    case validationError(String)
    case authenticationError
    case syncError(String)
}

// MARK: - 词典错误
enum DictionaryError: Error {
    case notFound
    case searchFailed
    case databaseError
    case pronunciationFailed
    case networkError
}

// MARK: - 收藏错误
enum FavoriteError: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError
    case syncError
}

// MARK: - 用户错误
enum UserError: Error {
    case authenticationFailed
    case userNotFound
    case settingsUpdateFailed
    case signOutFailed
}

// MARK: - 同步错误
enum SyncError: Error {
    case networkUnavailable
    case cloudKitError
    case authenticationRequired
    case conflictDetected
    case syncInProgress
}

// MARK: - 错误处理
extension AppError {
    static func dictionary(_ error: DictionaryError) -> AppError {
        switch error {
        case .notFound:
            return .validationError("单词未找到")
        case .searchFailed:
            return .databaseError("搜索失败")
        case .databaseError:
            return .databaseError("数据库错误")
        case .pronunciationFailed:
            return .unknown
        case .networkError:
            return .networkError
        }
    }
    
    static func favorite(_ error: FavoriteError) -> AppError {
        switch error {
        case .folderNotFound:
            return .validationError("收藏夹未找到")
        case .itemNotFound:
            return .validationError("收藏项未找到")
        case .duplicateName:
            return .validationError("收藏夹名称重复")
        case .databaseError:
            return .databaseError("数据库错误")
        case .syncError:
            return .syncError("同步错误")
        }
    }
}

// MARK: - 错误处理协议
protocol ErrorHandling {
    func handle(_ error: Error) -> String
    func logError(_ error: Error, file: String, line: Int, function: String)
}

// MARK: - 错误处理器
class AppErrorHandler: ErrorHandling {
    func handle(_ error: Error) -> String {
        // 将各种错误转换为用户友好的消息
        if let appError = error as? AppError {
            switch appError {
            case .unknown:
                return "发生未知错误"
            case .networkError:
                return "网络连接错误，请检查网络设置"
            case .databaseError(let message):
                return "数据访问错误: \(message)"
            case .validationError(let message):
                return message
            case .authenticationError:
                return "认证失败，请重新登录"
            case .syncError(let message):
                return "同步错误: \(message)"
            }
        }
        return "操作失败，请稍后重试"
    }
    
    func logError(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        // 记录错误日志
        print("Error: \(error.localizedDescription), File: \(file), Line: \(line), Function: \(function)")
        // 在实际应用中，可以将错误发送到日志服务
    }
}