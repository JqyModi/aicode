import Foundation
import RealmSwift

// MARK: - 词典模块数据模型

// 词典版本模型
class DBDictionaryVersion: Object {
    @Persisted(primaryKey: true) var id: String = "dictionary_version"
    @Persisted var version: String
    @Persisted var updateDate: Date
    @Persisted var wordCount: Int
    
    // 转换为领域模型
    func toDomain() -> DictionaryVersionDomain {
        return DictionaryVersionDomain(
            version: self.version,
            updateDate: self.updateDate,
            wordCount: self.wordCount
        )
    }
}

// 搜索历史项
class DBSearchHistoryItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String            // 关联的词条ID
    @Persisted var word: String              // 搜索的单词
    @Persisted var reading: String?          // 读音
    @Persisted var searchDate: Date          // 搜索日期
    
    // 转换为领域模型
    func toDomain() -> SearchHistoryItemDomain {
        return SearchHistoryItemDomain(
            id: self.id,
            wordId: self.wordId,
            word: self.word,
            reading: self.reading,
            searchDate: self.searchDate
        )
    }
}

// 词条模型 - 用于从DBWord转换后存储
class DBDictEntry: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var word: String              // 单词
    @Persisted var reading: String           // 读音
    @Persisted var partOfSpeech: String      // 词性
    @Persisted var definitions: List<DBDefinition> // 释义列表
    @Persisted var examples: List<DBExample>   // 例句列表
    @Persisted var jlptLevel: String?        // JLPT等级
    @Persisted var commonWord: Bool = false  // 是否为常用词
    
    // 转换为领域模型
    func toDomain() -> DictEntryDomain {
        let domainDefinitions = definitions.map { $0.toDomain() }
        let domainExamples = examples.map { $0.toDomain() }
        
        return DictEntryDomain(
            id: self.id,
            word: self.word,
            reading: self.reading,
            partOfSpeech: self.partOfSpeech,
            definitions: domainDefinitions,
            examples: domainExamples,
            jlptLevel: self.jlptLevel,
            commonWord: self.commonWord
        )
    }
}

// 释义模型
class DBDefinition: EmbeddedObject {
    @Persisted var meaning: String           // 中文释义
    @Persisted var notes: String?            // 注释
    
    // 添加无参数初始化器
    override init() {
        super.init()
    }
    
    init(meaning: String, notes: String? = nil) {
        super.init()
        self.meaning = meaning
        self.notes = notes
    }
    
    // 转换为领域模型
    func toDomain() -> DefinitionDomain {
        return DefinitionDomain(
            meaning: self.meaning,
            notes: self.notes
        )
    }
}

// 例句模型
class DBExample: EmbeddedObject {
    @Persisted var sentence: String          // 日语例句
    @Persisted var translation: String       // 中文翻译
    
    // 添加无参数初始化器
    override init() {
        super.init()
    }
    
    init(sentence: String, translation: String) {
        super.init()
        self.sentence = sentence
        self.translation = translation
    }
    
    // 转换为领域模型
    func toDomain() -> ExampleDomain {
        return ExampleDomain(
            sentence: self.sentence,
            translation: self.translation
        )
    }
}