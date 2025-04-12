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
    
    // 将 DBWord 转换为 DictEntry
    private func convertDBWordToDictEntry(_ dbWord: DBWord) -> DictEntry {
        let entry = DictEntry()
        entry.id = dbWord.objectId
        entry.word = dbWord.spell ?? ""
        entry.reading = dbWord.pron ?? ""
        
        // 设置词性
        if let detail = dbWord.details.first, !detail.partOfSpeech.isEmpty {
            let pos = detail.partOfSpeech.map { String($0) }.joined(separator: ",")
            entry.partOfSpeech = convertPartOfSpeech(pos)
        }
        
        // 转换释义
        for subdetail in dbWord.subdetails {
            if subdetail.lang == "zh" {
                let definition = Definition()
                definition.meaning = subdetail.title
                entry.definitions.append(definition)
            }
        }
        
        // 转换例句
        for example in dbWord.examples {
            if example.lang == "ja" {
                // 查找对应的中文翻译
                let chineseExample = dbWord.examples.first { $0.relaId == example.objectId && $0.lang == "zh" }
                
                let exampleObj = Example()
                exampleObj.sentence = example.title
                exampleObj.translation = chineseExample?.title ?? ""
                entry.examples.append(exampleObj)
            }
        }
        
        // 设置常用词标记
        entry.commonWord = dbWord.type.value != nil && dbWord.type.value! > 0
        
        return entry
    }
    
    // 将数字词性转换为文本描述
    private func convertPartOfSpeech(_ posCode: String) -> String {
        let posMap: [String: String] = [
            "1": "名词",
            "2": "动词",
            "3": "形容词",
            "4": "副词",
            "5": "连体词",
            "6": "助词",
            "7": "叹词",
            "8": "连词",
            "9": "数词",
            "10": "代词",
            "11": "接头词",
            "12": "接尾词"
        ]
        
        let posCodes = posCode.split(separator: ",")
        let posTexts = posCodes.compactMap { posMap[String($0)] }
        return posTexts.joined(separator: "、")
    }
    
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error> {
        return Future<[DictEntry], Error> { promise in
            do {
                let realm = try self.realmManager.realm()
                var results: Results<DBWord>
                
                // 根据搜索类型构建查询
                switch type {
                case .auto:
                    // 自动识别：尝试匹配单词、读音或释义
                    results = realm.objects(DBWord.self)
                        .filter("spell CONTAINS[c] %@ OR pron CONTAINS[c] %@ OR ANY subdetails.title CONTAINS[c] %@", 
                               query, query, query)
                case .word:
                    // 按单词查询
                    results = realm.objects(DBWord.self)
                        .filter("spell CONTAINS[c] %@", query)
                case .reading:
                    // 按读音查询
                    results = realm.objects(DBWord.self)
                        .filter("pron CONTAINS[c] %@", query)
                case .meaning:
                    // 按释义查询
                    results = realm.objects(DBWord.self)
                        .filter("ANY subdetails.title CONTAINS[c] %@", query)
                }
                
                // 应用分页和排序
                let paginatedResults = results.sorted(byKeyPath: "type", ascending: false)
                    .sorted(byKeyPath: "spell", ascending: true)
                
                // 转换为数组
                var entries: [DictEntry] = []
                let startIndex = min(offset, paginatedResults.count)
                let endIndex = min(offset + limit, paginatedResults.count)
                
                for i in startIndex..<endIndex {
                    let dbWord = paginatedResults[i]
                    let entry = self.convertDBWordToDictEntry(dbWord)
                    entries.append(entry)
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
                if let dbWord = realm.object(ofType: DBWord.self, forPrimaryKey: id) {
                    let entry = self.convertDBWordToDictEntry(dbWord)
                    promise(.success(entry))
                } else {
                    promise(.success(nil))
                }
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
//                let res = realm.objects(DBWord.self).filter({$0.relatedWord != nil})
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
