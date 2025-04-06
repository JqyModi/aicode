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
    // MARK: - 属性
    private let realmManager: RealmManager
    private let bundledDictionaryName = "japanese_dictionary"
    private let bundledDictionaryExtension = "json"
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared) {
        self.realmManager = realmManager
    }
    
    // MARK: - DictionaryRepositoryProtocol 实现
    
    /// 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error> {
        return Future<[DictEntry], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2001, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 如果查询为空，返回空数组
            if query.isEmpty {
                promise(.success([]))
                return
            }
            
            var results: Results<DictEntry>
            
            // 根据搜索类型执行不同的查询
            switch type {
            case .auto:
                // 自动识别：尝试匹配单词、读音或释义
                let wordResults = realm.objects(DictEntry.self).filter("word CONTAINS[c] %@", query)
                let readingResults = realm.objects(DictEntry.self).filter("reading CONTAINS[c] %@", query)
                
                // 合并结果（去重）
                let combinedResults = Array(Set(wordResults).union(Set(readingResults)))
                
                // 应用分页
                let paginatedResults = combinedResults
                    .sorted { $0.word < $1.word }
                    .dropFirst(offset)
                    .prefix(limit)
                
                promise(.success(Array(paginatedResults)))
                return
                
            case .word:
                // 按单词查询
                results = realm.objects(DictEntry.self).filter("word CONTAINS[c] %@", query)
                
            case .reading:
                // 按读音查询
                results = realm.objects(DictEntry.self).filter("reading CONTAINS[c] %@", query)
                
            case .meaning:
                // 按释义查询（这需要特殊处理，因为释义在嵌套对象中）
                // 注意：这种查询可能较慢，因为需要遍历所有释义
                let allEntries = realm.objects(DictEntry.self)
                let matchingEntries = allEntries.filter { entry in
                    for definition in entry.definitions {
                        if definition.meaning.localizedCaseInsensitiveContains(query) {
                            return true
                        }
                    }
                    return false
                }
                
                // 应用分页
                let paginatedResults = matchingEntries
                    .sorted { $0.word < $1.word }
                    .dropFirst(offset)
                    .prefix(limit)
                
                promise(.success(Array(paginatedResults)))
                return
            }
            
            // 应用排序和分页
            let sortedResults = results.sorted(byKeyPath: "word")
            let paginatedResults = sortedResults.freeze()
                .dropFirst(offset)
                .prefix(limit)
            
            promise(.success(Array(paginatedResults)))
        }.eraseToAnyPublisher()
    }
    
    /// 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error> {
        return Future<DictEntry?, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2002, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查询指定ID的词条
            let entry = realm.object(ofType: DictEntry.self, forPrimaryKey: id)
            promise(.success(entry))
        }.eraseToAnyPublisher()
    }
    
    /// 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error> {
        return Future<[SearchHistoryItem], Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2003, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查询搜索历史，按搜索时间降序排列
            let historyItems = realm.objects(SearchHistoryItem.self)
                .sorted(byKeyPath: "searchedAt", ascending: false)
                .prefix(limit)
            
            promise(.success(Array(historyItems)))
        }.eraseToAnyPublisher()
    }
    
    /// 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error> {
        return realmManager.write { realm in
            // 检查是否已存在相同的搜索历史
            let existingItem = realm.objects(SearchHistoryItem.self)
                .filter("wordId == %@", word.id)
                .first
            
            if let existingItem = existingItem {
                // 如果已存在，更新搜索时间
                existingItem.searchedAt = Date()
            } else {
                // 如果不存在，创建新的搜索历史项
                let historyItem = SearchHistoryItem(
                    wordId: word.id,
                    word: word.word,
                    reading: word.reading
                )
                realm.add(historyItem)
            }
            
            // 限制搜索历史数量（保留最近100条）
            let allHistoryItems = realm.objects(SearchHistoryItem.self)
                .sorted(byKeyPath: "searchedAt", ascending: false)
            
            if allHistoryItems.count > 100 {
                let itemsToDelete = allHistoryItems.suffix(from: 100)
                realm.delete(itemsToDelete)
            }
        }
    }
    
    /// 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        return realmManager.write { realm in
            let allHistoryItems = realm.objects(SearchHistoryItem.self)
            realm.delete(allHistoryItems)
        }
    }
    
    /// 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2004, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 检查词库是否已初始化
            let existingEntries = realm.objects(DictEntry.self)
            if !existingEntries.isEmpty {
                // 词库已存在，不需要初始化
                promise(.success(()))
                return
            }
            
            // 从Bundle中加载词库JSON文件
            guard let url = Bundle.main.url(forResource: self.bundledDictionaryName, withExtension: self.bundledDictionaryExtension) else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2005, userInfo: [NSLocalizedDescriptionKey: "找不到词库文件"])))
                return
            }
            
            do {
                // 读取JSON数据
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // 解码JSON数据为词条数组
                // 注意：这里假设JSON结构与DictEntry模型兼容
                // 实际应用中可能需要中间模型进行转换
                let dictionaryEntries = try decoder.decode([DictionaryEntryDTO].self, from: data)
                
                // 在事务中批量添加词条
                try realm.write {
                    for entryDTO in dictionaryEntries {
                        let entry = DictEntry(word: entryDTO.word, reading: entryDTO.reading, partOfSpeech: entryDTO.partOfSpeech)
                        
                        // 添加释义
                        for definitionDTO in entryDTO.definitions {
                            let definition = Definition(meaning: definitionDTO.meaning, notes: definitionDTO.notes)
                            entry.definitions.append(definition)
                        }
                        
                        // 添加例句
                        for exampleDTO in entryDTO.examples {
                            let example = Example(sentence: exampleDTO.sentence, translation: exampleDTO.translation)
                            entry.examples.append(example)
                        }
                        
                        realm.add(entry)
                    }
                    
                    // 更新词库版本信息
                    let version = DictionaryVersion(version: "1.0.0", wordCount: dictionaryEntries.count)
                    realm.add(version, update: .modified)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error> {
        return Future<DictionaryVersion, Error> { promise in
            guard let realm = self.realmManager.getRealm() else {
                promise(.failure(NSError(domain: "DictionaryRepository", code: 2006, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            // 查询词库版本信息
            if let version = realm.object(ofType: DictionaryVersion.self, forPrimaryKey: "dictionary_version") {
                promise(.success(version))
            } else {
                // 如果不存在版本信息，创建默认版本
                do {
                    let defaultVersion = DictionaryVersion(version: "1.0.0", wordCount: 0)
                    try realm.write {
                        realm.add(defaultVersion)
                    }
                    promise(.success(defaultVersion))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - 数据传输对象 (DTO)
// 用于JSON解析的中间模型

struct DictionaryEntryDTO: Codable {
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDTO]
    let examples: [ExampleDTO]
}

struct DefinitionDTO: Codable {
    let meaning: String
    let notes: String?
}

struct ExampleDTO: Codable {
    let sentence: String
    let translation: String
}