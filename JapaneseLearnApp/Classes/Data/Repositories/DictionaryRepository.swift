//
//  DictionaryRepository.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/20.
//

import Foundation
import Combine
import RealmSwift

class DictionaryRepository: DictionaryRepositoryProtocol {
    
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    
    init() throws {
        self.realm = try Realm()
    }
    
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error> {
        return Future<[DictEntry], Error> { promise in
            do {
                var predicate: NSPredicate
                
                switch type {
                case .auto:
                    // 自动识别搜索类型
                    predicate = NSPredicate(format: "word CONTAINS[c] %@ OR reading CONTAINS[c] %@", query, query)
                case .word:
                    predicate = NSPredicate(format: "word CONTAINS[c] %@", query)
                case .reading:
                    predicate = NSPredicate(format: "reading CONTAINS[c] %@", query)
                case .meaning:
                    // 搜索释义
                    predicate = NSPredicate(format: "ANY definitions.meaning CONTAINS[c] %@", query)
                }
                
                let results = self.realm.objects(DictEntry.self)
                    .filter(predicate)
                    .sorted(byKeyPath: "word")
                
                let paginatedResults = Array(results.suffix(from: offset).prefix(limit))
                promise(.success(paginatedResults))
            } catch {
                promise(.failure(DictionaryError.searchFailed))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error> {
        return Future<DictEntry?, Error> { promise in
            do {
                let entry = self.realm.object(ofType: DictEntry.self, forPrimaryKey: id)
                promise(.success(entry))
            } catch {
                promise(.failure(DictionaryError.notFound))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error> {
        return Future<[SearchHistoryItem], Error> { promise in
            do {
                let results = self.realm.objects(SearchHistoryItem.self)
                    .sorted(byKeyPath: "searchedAt", ascending: false)
                    .prefix(limit)
                
                promise(.success(Array(results)))
            } catch {
                promise(.failure(DictionaryError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                try self.realm.write {
                    // 检查是否已存在相同的搜索历史
                    let existingItems = self.realm.objects(SearchHistoryItem.self)
                        .filter("wordId == %@", word.id)
                    
                    if let existingItem = existingItems.first {
                        // 更新搜索时间
                        existingItem.searchDate = Date()
                    } else {
                        // 创建新的搜索历史
                        let historyItem = SearchHistoryItem()
                        historyItem.wordId = word.id
                        historyItem.word = word.word
                        historyItem.reading = word.reading
                        historyItem.meaning = word.definitions.first?.meaning ?? ""
                        historyItem.searchedAt = Date()
                        
                        self.realm.add(historyItem)
                    }
                }
                promise(.success(()))
            } catch {
                promise(.failure(DictionaryError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            do {
                try self.realm.write {
                    let allHistory = self.realm.objects(SearchHistoryItem.self)
                    self.realm.delete(allHistory)
                }
                promise(.success(()))
            } catch {
                promise(.failure(DictionaryError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            // 这里应该实现从本地JSON或远程API加载词典数据的逻辑
            // 为了示例，这里只创建一个简单的版本记录
            do {
                try self.realm.write {
                    let version = DictionaryVersion()
                    version.version = "1.0.0"
                    version.updateDate = Date()
                    version.description1 = "初始词典数据"
                    
                    self.realm.add(version, update: .modified)
                }
                promise(.success(()))
            } catch {
                promise(.failure(DictionaryError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error> {
        return Future<DictionaryVersion, Error> { promise in
            let versions = self.realm.objects(DictionaryVersion.self)
                .sorted(byKeyPath: "updateDate", ascending: false)
            
            if let latestVersion = versions.first {
                promise(.success(latestVersion))
            } else {
                promise(.failure(DictionaryError.databaseError))
            }
        }.eraseToAnyPublisher()
    }
}
