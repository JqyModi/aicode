//
//  DictionaryDataRepository.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import RealmSwift

class DictionaryDataRepository: DictionaryDataRepositoryProtocol {
    // MARK: - 属性
    private let realmManager: RealmManager
    private let networkManager: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    init(realmManager: RealmManager = RealmManager.shared, networkManager: NetworkManager = NetworkManager.shared) {
        self.realmManager = realmManager
        self.networkManager = networkManager
    }
    
    // MARK: - DictionaryDataRepositoryProtocol 实现
    func searchWords(query: String, type: SearchTypeEntity, limit: Int, offset: Int) -> AnyPublisher<[DictEntryEntity], Error> {
        return Future<[DictEntryEntity], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DictionaryDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                var predicate: NSPredicate
                
                // 根据搜索类型构建查询条件
                switch type {
                case .auto:
                    // 自动模式：同时搜索单词、读音和释义
                    predicate = NSPredicate(format: "spell CONTAINS[c] %@ OR pron CONTAINS[c] %@ OR excerpt CONTAINS[c] %@", query, query, query)
                case .word:
                    // 单词模式：仅搜索单词
                    predicate = NSPredicate(format: "spell CONTAINS[c] %@", query)
                case .reading:
                    // 读音模式：仅搜索读音
                    predicate = NSPredicate(format: "pron CONTAINS[c] %@", query)
                case .meaning:
                    // 释义模式：仅搜索释义
                    predicate = NSPredicate(format: "excerpt CONTAINS[c] %@", query)
                }
                
                // 执行查询
                let results = realm.objects(DBWord.self).filter(predicate)
                    .sorted(byKeyPath: "spell")
                
                // 分页处理
                let paginatedResults = results.suffix(from: offset).prefix(limit)
                
                // 转换为实体模型
                let entities = paginatedResults.map { self.mapToDictEntryEntity(from: $0) }
                
                // 添加搜索历史（如果有结果）
                if let firstResult = entities.first {
                    self.addSearchHistory(word: firstResult)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &self.cancellables)
                }
                
                promise(.success(Array(entities)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getWordDetails(id: String) -> AnyPublisher<DictEntryEntity?, Error> {
        return Future<DictEntryEntity?, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DictionaryDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 查询单词
                if let word = realm.object(ofType: DBWord.self, forPrimaryKey: id) {
                    let entity = self.mapToDictEntryEntity(from: word)
                    promise(.success(entity))
                } else {
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemEntity], Error> {
        return Future<[SearchHistoryItemEntity], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DictionaryDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 这里假设我们有一个SearchHistory表来存储搜索历史
                // 实际实现可能需要创建这个表
                let searchHistoryItems = realm.objects(DBSearchHistory.self)
                    .sorted(byKeyPath: "timestamp", ascending: false)
                    .prefix(limit)
                
                let entities = searchHistoryItems.map { item in
                    SearchHistoryItemEntity(
                        id: item.objectId,
                        word: item.word,
                        timestamp: item.timestamp
                    )
                }
                
                promise(.success(Array(entities)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func addSearchHistory(word: DictEntryEntity) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DictionaryDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                // 检查是否已存在相同的搜索记录
                let existingItems = realm.objects(DBSearchHistory.self).filter("wordId == %@", word.id)
                
                try realm.write {
                    // 如果已存在，则更新时间戳
                    if let existingItem = existingItems.first {
                        existingItem.timestamp = Date()
                    } else {
                        // 否则创建新记录
                        let searchHistoryItem = DBSearchHistory()
                        searchHistoryItem.objectId = UUID().uuidString
                        searchHistoryItem.wordId = word.id
                        searchHistoryItem.word = word.word
                        searchHistoryItem.timestamp = Date()
                        
                        realm.add(searchHistoryItem)
                    }
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func clearSearchHistory() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "DictionaryDataRepository", code: 0, userInfo: [NSLocalizedDescriptionKey: "实例已被释放"])))
                return
            }
            
            do {
                let realm = try self.realmManager.realm()
                
                let searchHistoryItems = realm.objects(DBSearchHistory.self)
                
                try realm.write {
                    realm.delete(searchHistoryItems)
                }
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func initializeDictionary() -> AnyPublisher<Void, Error> {
        // 这个方法可能涉及从远程服务器下载词典数据或从本地资源加载
        // 这里简化为检查并更新数据库
        return checkDictionaryVersion()
            .flatMap { versionEntity -> AnyPublisher<Void, Error> in
                // 如果需要更新，则执行更新操作
                if versionEntity.version != "1.0.0" { // 假设当前版本是1.0.0
                    // 执行更新操作，这里简化处理
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersionEntity, Error> {
        return Future<DictionaryVersionEntity, Error> { promise in
            // 这里应该从本地或远程获取词典版本信息
            // 简化处理，返回一个固定的版本信息
            let versionEntity = DictionaryVersionEntity(
                version: "1.0.0",
                updateDate: Date(),
                wordCount: 10000
            )
            promise(.success(versionEntity))
        }.eraseToAnyPublisher()
    }
    
    // MARK: - 私有辅助方法
    private func mapToDictEntryEntity(from dbWord: DBWord) -> DictEntryEntity {
        // 转换定义
        let definitions = dbWord.details.flatMap { detail -> [DefinitionEntity] in
            // 这里简化处理，实际应根据数据库模型结构进行转换
            return [DefinitionEntity(
                meaning: dbWord.excerpt ?? "",
                notes: nil
            )]
        }
        
        // 转换例句 - 按relaId分组并配对日语例句和中文翻译
        // 首先按relaId分组所有例句
        let examplesByRelaId = Dictionary(grouping: dbWord.examples) { $0.relaId }
        
        // 然后为每组创建ExampleEntity，正确配对日语例句和中文翻译
        let examples = examplesByRelaId.compactMap { (relaId, exampleGroup) -> ExampleEntity? in
            // 查找日语例句
            let jaExample = exampleGroup.first { $0.lang == "ja" }
            // 查找中文翻译
            let zhExample = exampleGroup.first { $0.lang == "zh-CN" }
            
            // 只有当同时找到日语例句和中文翻译时才创建ExampleEntity
            if let jaExample = jaExample {
                return ExampleEntity(
                    sentence: jaExample.notationTitle ?? jaExample.title,
                    translation: zhExample?.title ?? ""
                )
            }
            return nil
        }
        
        // 转换关联词
        var relatedWords: [RelatedWordEntity] = []
        if let relatedWord = dbWord.relatedWord {
            // 添加同义词
            let synonyms = relatedWord.synonyms.map { synonym -> RelatedWordEntity in
                return RelatedWordEntity(
                    id: synonym.objectId,
                    word: synonym.spell,
                    reading: synonym.pron,
                    type: .synonym
                )
            }
            
            // 添加近义词
            let paronyms = relatedWord.paronyms.map { paronym -> RelatedWordEntity in
                return RelatedWordEntity(
                    id: paronym.objectId,
                    word: paronym.spell,
                    reading: paronym.pron,
                    type: .paronym
                )
            }
            
            // 添加多音词
            let polyphonics = relatedWord.polyphonics.map { polyphonic -> RelatedWordEntity in
                return RelatedWordEntity(
                    id: polyphonic.objectId,
                    word: polyphonic.spell,
                    reading: polyphonic.pron,
                    type: .polyphonic
                )
            }
            
            relatedWords.append(contentsOf: synonyms)
            relatedWords.append(contentsOf: paronyms)
            relatedWords.append(contentsOf: polyphonics)
        }
        
        return DictEntryEntity(
            id: dbWord.objectId,
            word: dbWord.spell ?? "",
            reading: dbWord.pron ?? "",
            partOfSpeech: "名词", // 简化处理，实际应根据数据库中的词性信息转换
            definitions: Array(definitions),
            examples: Array(examples),
            relatedWords: relatedWords
        )
    }
}

// MARK: - 搜索历史数据库模型
class DBSearchHistory: Object {
    @objc dynamic var objectId: String = ""
    @objc dynamic var wordId: String = ""
    @objc dynamic var word: String = ""
    @objc dynamic var timestamp: Date = Date()
    
    override static func primaryKey() -> String? {
        return "objectId"
    }
}
