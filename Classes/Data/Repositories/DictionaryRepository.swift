import Foundation
import RealmSwift
import Combine

protocol DictionaryRepositoryProtocol {
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error>
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error>
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error>
}

class DictionaryRepository: DictionaryRepositoryProtocol {
    private let realmManager: RealmManager
    
    init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
    }
    
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error> {
        return Future<[DictEntry], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                var results: Results<DictEntry>
                
                // 根据搜索类型构建查询
                switch type {
                case .auto:
                    // 自动识别：尝试匹配单词、读音或释义
                    results = realm.objects(DictEntry.self)
                        .filter("word CONTAINS[c] %@ OR reading CONTAINS[c] %@ OR ANY definitions.meaning CONTAINS[c] %@", 
                               query, query, query)
                case .word:
                    // 按单词查询
                    results = realm.objects(DictEntry.self)
                        .filter("word CONTAINS[c] %@", query)
                case .reading:
                    // 按读音查询
                    results = realm.objects(DictEntry.self)
                        .filter("reading CONTAINS[c] %@", query)
                case .meaning:
                    // 按释义查询
                    results = realm.objects(DictEntry.self)
                        .filter("ANY definitions.meaning CONTAINS[c] %@", query)
                }
                
                // 应用分页
                let paginatedResults = results.sorted(byKeyPath: "commonWord", ascending: false)
                    .sorted(byKeyPath: "word", ascending: true)
                
                // 转换为数组
                var entries: [DictEntry] = []
                let startIndex = min(offset, paginatedResults.count)
                let endIndex = min(offset + limit, paginatedResults.count)
                
                for i in startIndex..<endIndex {
                    entries.append(paginatedResults[i])
                }
                
                promise(.success(entries))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error> {
        return Future<DictEntry?, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                let entry = realm.object(ofType: DictEntry.self, forPrimaryKey: id)
                promise(.success(entry))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error> {
        return Future<[SearchHistoryItem], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                let history = realm.objects(SearchHistoryItem.self)
                    .sorted(byKeyPath: "searchDate", ascending: false)
                
                let limitedHistory = Array(history.prefix(limit))
                promise(.success(limitedHistory))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error> {
        return realmManager.writeAsync { realm in
            // 检查是否已存在相同的历史记录
            let existingHistory = realm.objects(SearchHistoryItem.self)
                .filter("wordId == %@", word.id)
            
            if let existing = existingHistory.first {
                // 更新搜索日期
                existing.searchDate = Date()
            } else {
                // 创建新的历史记录
                let historyItem = SearchHistoryItem()
                historyItem.wordId = word.id
                historyItem.word = word.word
                historyItem.reading = word.reading
                historyItem.searchDate = Date()
                
                realm.add(historyItem)
            }
        }
    }
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        return realmManager.deleteAll(SearchHistoryItem.self)
    }
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            // 这里应该实现从本地JSON文件加载初始词库的逻辑
            // 在实际应用中，可能需要从应用包中读取预置的词库文件
            
            // 模拟实现：检查是否已有词库，如果没有则创建示例数据
            do {
                let realm = try self.realmManager.realm()
                let count = realm.objects(DictEntry.self).count
                
                if count == 0 {
                    try realm.write {
                        // 创建一些示例词条
                        for i in 1...10 {
                            let entry = DictEntry()
                            entry.id = UUID().uuidString
                            entry.word = "示例单词\(i)"
                            entry.reading = "れいたんご\(i)"
                            entry.partOfSpeech = "名词"
                            
                            let definition = Definition()
                            definition.meaning = "示例释义\(i)"
                            entry.definitions.append(definition)
                            
                            let example = Example()
                            example.sentence = "これは示例単語\(i)です。"
                            example.translation = "这是示例单词\(i)。"
                            entry.examples.append(example)
                            
                            realm.add(entry)
                        }
                        
                        // 创建词库版本信息
                        let version = DictionaryVersion()
                        version.version = "1.0.0"
                        version.updateDate = Date()
                        version.wordCount = 10
                        
                        realm.add(version, update: .modified)
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error> {
        return Future<DictionaryVersion, Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                if let version = realm.object(ofType: DictionaryVersion.self, forPrimaryKey: "dictionary_version") {
                    promise(.success(version))
                } else {
                    // 如果没有版本信息，创建一个默认版本
                    try realm.write {
                        let version = DictionaryVersion()
                        version.version = "1.0.0"
                        version.updateDate = Date()
                        version.wordCount = 0
                        
                        realm.add(version)
                        promise(.success(version))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
