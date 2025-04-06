import Foundation
import RealmSwift
import Combine

// MARK: - 词条模型
class DictEntry: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var word: String              // 单词
    @Persisted var reading: String           // 读音
    @Persisted var partOfSpeech: String      // 词性
    @Persisted var definitions: List<Definition> // 释义列表
    @Persisted var examples: List<Example>   // 例句列表
    @Persisted var createdAt: Date = Date()  // 创建时间
    @Persisted var updatedAt: Date = Date()  // 更新时间
    
    convenience init(word: String, reading: String, partOfSpeech: String) {
        self.init()
        self.id = UUID().uuidString
        self.word = word
        self.reading = reading
        self.partOfSpeech = partOfSpeech
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 释义模型
class Definition: EmbeddedObject {
    @Persisted var meaning: String           // 中文释义
    @Persisted var notes: String?            // 注释
    
    convenience init(meaning: String, notes: String? = nil) {
        self.init()
        self.meaning = meaning
        self.notes = notes
    }
}

// MARK: - 例句模型
class Example: EmbeddedObject {
    @Persisted var sentence: String          // 日语例句
    @Persisted var translation: String       // 中文翻译
    
    convenience init(sentence: String, translation: String) {
        self.init()
        self.sentence = sentence
        self.translation = translation
    }
}

// MARK: - 搜索历史模型
class SearchHistoryItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String            // 词条ID
    @Persisted var word: String              // 单词
    @Persisted var reading: String           // 读音
    @Persisted var searchedAt: Date = Date() // 搜索时间
    
    convenience init(wordId: String, word: String, reading: String) {
        self.init()
        self.id = UUID().uuidString
        self.wordId = wordId
        self.word = word
        self.reading = reading
        self.searchedAt = Date()
    }
}

// MARK: - 词库版本模型
class DictionaryVersion: Object {
    @Persisted(primaryKey: true) var id: String = "dictionary_version"
    @Persisted var version: String           // 版本号
    @Persisted var lastUpdated: Date         // 最后更新时间
    @Persisted var wordCount: Int            // 词条数量
    
    convenience init(version: String, wordCount: Int) {
        self.init()
        self.version = version
        self.lastUpdated = Date()
        self.wordCount = wordCount
    }
}

// MARK: - 搜索类型枚举
enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}