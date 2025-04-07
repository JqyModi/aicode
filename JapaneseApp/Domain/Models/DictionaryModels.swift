//
//  DictionaryModels.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation

// MARK: - 搜索相关模型

/// 搜索类型枚举
public enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

/// 搜索结果模型
public struct SearchResult {
    /// 总结果数
    public let total: Int
    /// 当前页结果项
    public let items: [WordSummary]
    
    public init(total: Int, items: [WordSummary]) {
        self.total = total
        self.items = items
    }
}

/// 搜索历史项
public struct SearchHistoryItem {
    /// 历史记录ID
    public let id: String
    /// 搜索的单词
    public let word: String
    /// 搜索时间
    public let timestamp: Date
    
    public init(id: String, word: String, timestamp: Date) {
        self.id = id
        self.word = word
        self.timestamp = timestamp
    }
}

// MARK: - 词条相关模型

/// 词条摘要信息
public struct WordSummary {
    /// 词条ID
    public let id: String
    /// 单词
    public let word: String
    /// 读音
    public let reading: String
    /// 词性
    public let partOfSpeech: String
    /// 简要释义
    public let briefMeaning: String
    
    public init(id: String, word: String, reading: String, partOfSpeech: String, briefMeaning: String) {
        self.id = id
        self.word = word
        self.reading = reading
        self.partOfSpeech = partOfSpeech
        self.briefMeaning = briefMeaning
    }
}

/// 词条详细信息
public struct WordDetails {
    /// 词条ID
    public let id: String
    /// 单词
    public let word: String
    /// 读音
    public let reading: String
    /// 词性
    public let partOfSpeech: String
    /// 释义列表
    public let definitions: [Definition]
    /// 例句列表
    public let examples: [Example]
    /// 相关词汇
    public let relatedWords: [WordSummary]
    /// 是否已收藏
    public let isFavorited: Bool
    
    public init(id: String, word: String, reading: String, partOfSpeech: String, 
                definitions: [Definition], examples: [Example], relatedWords: [WordSummary], 
                isFavorited: Bool) {
        self.id = id
        self.word = word
        self.reading = reading
        self.partOfSpeech = partOfSpeech
        self.definitions = definitions
        self.examples = examples
        self.relatedWords = relatedWords
        self.isFavorited = isFavorited
    }
}

/// 释义模型
public struct Definition {
    /// 中文释义
    public let meaning: String
    /// 注释说明
    public let notes: String?
    
    public init(meaning: String, notes: String?) {
        self.meaning = meaning
        self.notes = notes
    }
}

/// 例句模型
public struct Example {
    /// 日语例句
    public let sentence: String
    /// 中文翻译
    public let translation: String
    
    public init(sentence: String, translation: String) {
        self.sentence = sentence
        self.translation = translation
    }
}

// MARK: - 错误类型

/// 词典服务错误类型
public enum DictionaryError: Error {
    /// 未找到词条
    case notFound
    /// 搜索失败
    case searchFailed
    /// 数据库错误
    case databaseError
    /// 发音获取失败
    case pronunciationFailed
    /// 网络错误
    case networkError
    
    /// 用户友好的错误描述
    public var localizedDescription: String {
        switch self {
        case .notFound:
            return "未找到相关词条"
        case .searchFailed:
            return "搜索失败，请重试"
        case .databaseError:
            return "数据库访问错误"
        case .pronunciationFailed:
            return "获取发音失败"
        case .networkError:
            return "网络连接错误"
        }
    }
}