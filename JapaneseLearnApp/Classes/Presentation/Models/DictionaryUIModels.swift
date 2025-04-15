import Foundation
import SwiftUI

// MARK: - 词典模块表现层模型

// 词典版本UI模型
struct DictionaryVersionUI {
    let version: String
    let updateDate: Date
    let wordCount: Int
}

// 词条详情UI模型
struct WordDetailsUI {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionUI]
    let examples: [ExampleUI]
    let tags: [String]
    let isFavorited: Bool
    let relatedWords: [WordListItemUI]
}

// 释义UI模型
struct DefinitionUI {
    let meaning: String
    let notes: String?
}

// 例句UI模型
struct ExampleUI {
    let sentence: String
    let translation: String
}

// 搜索结果UI模型
struct SearchResultUI {
    let query: String
    let totalCount: Int
    let items: [WordListItemUI]
}

// 词条列表项UI模型
struct WordListItemUI: Identifiable {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

// 搜索历史UI模型
struct SearchHistoryItemUI: Identifiable {
    let id: String
    let wordId: String
    let word: String
    let reading: String?
    let searchDate: Date
}

// 词云项UI模型
struct WordCloudItemUI: Identifiable {
    var id: String { word }
    var word: String
    var size: Int
    var frequency: Int
}