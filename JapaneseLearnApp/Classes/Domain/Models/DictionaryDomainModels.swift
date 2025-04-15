import Foundation
import Combine

// MARK: - 词典模块业务层模型

// 搜索类型枚举
enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}

// 词典版本业务模型
struct DictionaryVersionDomain {
    let version: String
    let updateDate: Date
    let wordCount: Int
    
    // 转换为数据层模型
    func toData() -> DBDictionaryVersion {
        let dbVersion = DBDictionaryVersion()
        dbVersion.version = self.version
        dbVersion.updateDate = self.updateDate
        dbVersion.wordCount = self.wordCount
        return dbVersion
    }
    
    // 转换为表现层模型
    func toUI() -> DictionaryVersionUI {
        return DictionaryVersionUI(
            version: self.version,
            updateDate: self.updateDate,
            wordCount: self.wordCount
        )
    }
}

// 词条业务模型
struct DictEntryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
    let jlptLevel: String?
    let commonWord: Bool
    
    // 转换为数据层模型
    func toData() -> DBDictEntry {
        let dbEntry = DBDictEntry()
        dbEntry.id = self.id
        dbEntry.word = self.word
        dbEntry.reading = self.reading
        dbEntry.partOfSpeech = self.partOfSpeech
        dbEntry.jlptLevel = self.jlptLevel
        dbEntry.commonWord = self.commonWord
        
        // 转换释义
        let dbDefinitions = List<DBDefinition>()
        for definition in self.definitions {
            let dbDefinition = definition.toData()
            dbDefinitions.append(dbDefinition)
        }
        dbEntry.definitions = dbDefinitions
        
        // 转换例句
        let dbExamples = List<DBExample>()
        for example in self.examples {
            let dbExample = example.toData()
            dbExamples.append(dbExample)
        }
        dbEntry.examples = dbExamples
        
        return dbEntry
    }
    
    // 转换为表现层模型
    func toUI(isFavorited: Bool = false, relatedWords: [WordListItemUI] = []) -> WordDetailsUI {
        return WordDetailsUI(
            id: self.id,
            word: self.word,
            reading: self.reading,
            partOfSpeech: self.partOfSpeech,
            definitions: self.definitions.map { $0.toUI() },
            examples: self.examples.map { $0.toUI() },
            tags: self.jlptLevel != nil ? [self.jlptLevel!] : [],
            isFavorited: isFavorited,
            relatedWords: relatedWords
        )
    }
}

// 释义业务模型
struct DefinitionDomain {
    let meaning: String
    let notes: String?
    
    // 转换为数据层模型
    func toData() -> DBDefinition {
        return DBDefinition(meaning: self.meaning, notes: self.notes)
    }
    
    // 转换为表现层模型
    func toUI() -> DefinitionUI {
        return DefinitionUI(meaning: self.meaning, notes: self.notes)
    }
}

// 例句业务模型
struct ExampleDomain {
    let sentence: String
    let translation: String
    
    // 转换为数据层模型
    func toData() -> DBExample {
        return DBExample(sentence: self.sentence, translation: self.translation)
    }
    
    // 转换为表现层模型
    func toUI() -> ExampleUI {
        return ExampleUI(sentence: self.sentence, translation: self.translation)
    }
}

// 搜索结果业务模型
struct SearchResultDomain {
    let query: String
    let totalCount: Int
    let items: [WordListItemDomain]
    
    // 转换为表现层模型
    func toUI() -> SearchResultUI {
        return SearchResultUI(
            query: self.query,
            totalCount: self.totalCount,
            items: self.items.map { $0.toUI() }
        )
    }
}

// 词条列表项业务模型
struct WordListItemDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
    
    // 转换为表现层模型
    func toUI() -> WordListItemUI {
        return WordListItemUI(
            id: self.id,
            word: self.word,
            reading: self.reading,
            partOfSpeech: self.partOfSpeech,
            briefMeaning: self.briefMeaning
        )
    }
}

// 搜索历史业务模型
struct SearchHistoryItemDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String?
    let searchDate: Date
    
    // 转换为数据层模型
    func toData() -> DBSearchHistoryItem {
        let dbItem = DBSearchHistoryItem()
        dbItem.id = self.id
        dbItem.wordId = self.wordId
        dbItem.word = self.word
        dbItem.reading = self.reading
        dbItem.searchDate = self.searchDate
        return dbItem
    }
    
    // 转换为表现层模型
    func toUI() -> SearchHistoryItemUI {
        return SearchHistoryItemUI(
            id: self.id,
            wordId: self.wordId,
            word: self.word,
            reading: self.reading,
            searchDate: self.searchDate
        )
    }
}

// 词典服务错误类型
enum DictionaryError: Error {
    case notFound
    case invalidQuery
    case databaseError(Error)
    case audioError
    case networkError
    case unknown
    case searchFailed
    case pronunciationFailed
    
    var localizedDescription: String {
        switch self {
        case .notFound:
            return "未找到相关词条"
        case .invalidQuery:
            return "无效的搜索查询"
        case .databaseError(let error):
            return "数据库错误: \(error.localizedDescription)"
        case .audioError:
            return "音频处理错误"
        case .networkError:
            return "网络连接错误"
        case .unknown:
            return "未知错误"
        case .searchFailed:
            return "搜索错误"
        case .pronunciationFailed:
            return "发音错误"
        }
    }
}