//
//  DictionaryModels.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import RealmSwift

// MARK: - 词典版本
class DictionaryVersion: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var version: String = ""
    @objc dynamic var updateDate: Date = Date()
    @objc dynamic var description1: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 词典条目
class DictEntry: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var word: String = ""
    @objc dynamic var reading: String = ""
    @objc dynamic var partOfSpeech: String = ""
    let definitions = List<Definition>()
    let examples = List<Example>()
    @objc dynamic var createdAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    // 从DBWord转换的便利初始化方法
    convenience init(from dbWord: DBWord) {
        self.init()
        self.id = dbWord.objectId
        self.word = dbWord.spell ?? ""
        self.reading = dbWord.pron ?? ""
        
        // 处理词性
        if let detail = dbWord.details.first {
            let pos = detail.partOfSpeech
            if !pos.isEmpty {
                self.partOfSpeech = String(pos.first ?? 0)
            }
        }
        
        // 处理释义和例句
        // 这里需要根据实际数据结构进行适配
        for example in dbWord.examples {
            let newExample = Example()
            newExample.sentence = example.title
            newExample.translation = example.notationTitle ?? ""
            self.examples.append(newExample)
        }
    }
}

// MARK: - 释义
class Definition: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var meaning: String = ""
    @objc dynamic var notes: String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 例句
class Example: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var sentence: String = ""
    @objc dynamic var translation: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - 搜索历史
class SearchHistoryItem: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var wordId: String = ""
    @objc dynamic var word: String = ""
    @objc dynamic var reading: String = ""
    @objc dynamic var meaning: String = ""  // 添加这个属性
    @objc dynamic var searchedAt: Date = Date()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
