//
//  DictionaryService.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class DictionaryService: DictionaryServiceProtocol {
    // MARK: - 属性
    private let dictionaryRepository: DictionaryDataRepositoryProtocol
    
    // MARK: - 初始化
    init(dictionaryRepository: DictionaryDataRepositoryProtocol) {
        self.dictionaryRepository = dictionaryRepository
    }
    
    // MARK: - DictionaryServiceProtocol 实现
    func searchWords(query: String, type: SearchTypeDomain?, limit: Int, offset: Int) -> AnyPublisher<SearchResultDomain, DictionaryErrorDomain> {
        let entityType: SearchTypeEntity = type.map { mapToSearchTypeEntity(from: $0) } ?? .auto
        
        return dictionaryRepository.searchWords(query: query, type: entityType, limit: limit, offset: offset)
            .map { entities -> SearchResultDomain in
                let items = entities.map { self.mapToWordSummaryDomain(from: $0) }
                return SearchResultDomain(total: entities.count, items: items)
            }
            .mapError { error -> DictionaryErrorDomain in
                return self.mapToDictionaryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getWordDetails(id: String) -> AnyPublisher<WordDetailsDomain, DictionaryErrorDomain> {
        return dictionaryRepository.getWordDetails(id: id)
            .flatMap { entity -> AnyPublisher<WordDetailsDomain, Error> in
                if let entity = entity {
                    return self.dictionaryRepository.isWordFavorited(wordId: id)
                        .map { isFavorited -> WordDetailsDomain in
                            var details = self.mapToWordDetailsDomain(from: entity)
                            details = WordDetailsDomain(
                                id: details.id,
                                word: details.word,
                                reading: details.reading,
                                partOfSpeech: details.partOfSpeech,
                                definitions: details.definitions,
                                examples: details.examples,
                                relatedWords: details.relatedWords,
                                isFavorited: isFavorited
                            )
                            return details
                        }
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "单词未找到"]))
                        .eraseToAnyPublisher()
                }
            }
            .mapError { error -> DictionaryErrorDomain in
                return self.mapToDictionaryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryErrorDomain> {
        // 这里假设有一个API可以获取发音URL
        // 实际实现可能需要调用外部服务或本地音频文件
        let baseURL = "https://api.example.com/pronunciation"
        let urlString = "\(baseURL)/\(id)?speed=\(speed)"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: DictionaryErrorDomain.pronunciationFailed)
                .eraseToAnyPublisher()
        }
        
        return Just(url)
            .setFailureType(to: DictionaryErrorDomain.self)
            .eraseToAnyPublisher()
    }
    
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemDomain], DictionaryErrorDomain> {
        return dictionaryRepository.getSearchHistory(limit: limit)
            .map { entities -> [SearchHistoryItemDomain] in
                return entities.map { self.mapToSearchHistoryItemDomain(from: $0) }
            }
            .mapError { error -> DictionaryErrorDomain in
                return self.mapToDictionaryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryErrorDomain> {
        return dictionaryRepository.clearSearchHistory()
            .map { _ in true }
            .mapError { error -> DictionaryErrorDomain in
                return self.mapToDictionaryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 私有映射方法
    private func mapToSearchTypeEntity(from domainType: SearchTypeDomain) -> SearchTypeEntity {
        switch domainType {
        case .auto:
            return .auto
        case .word:
            return .word
        case .reading:
            return .reading
        case .meaning:
            return .meaning
        }
    }
    
    private func mapToWordSummaryDomain(from entity: DictEntryEntity) -> WordSummaryDomain {
        return WordSummaryDomain(
            id: entity.id,
            word: entity.word,
            reading: entity.reading,
            partOfSpeech: entity.partOfSpeech,
            briefMeaning: entity.definitions.first?.meaning ?? ""
        )
    }
    
    private func mapToWordDetailsDomain(from entity: DictEntryEntity) -> WordDetailsDomain {
        let definitions = entity.definitions.map { mapToDefinitionDomain(from: $0) }
        let examples = entity.examples.map { mapToExampleDomain(from: $0) }
        
        // 相关词汇可能需要额外查询，这里简化处理
        let relatedWords: [WordSummaryDomain] = []
        
        return WordDetailsDomain(
            id: entity.id,
            word: entity.word,
            reading: entity.reading,
            partOfSpeech: entity.partOfSpeech,
            definitions: definitions,
            examples: examples,
            relatedWords: relatedWords,
            isFavorited: false // 默认值，实际应从收藏服务获取
        )
    }
    
    private func mapToDefinitionDomain(from entity: DefinitionEntity) -> DefinitionDomain {
        return DefinitionDomain(
            meaning: entity.meaning,
            notes: entity.notes
        )
    }
    
    private func mapToExampleDomain(from entity: ExampleEntity) -> ExampleDomain {
        return ExampleDomain(
            sentence: entity.sentence,
            translation: entity.translation
        )
    }
    
    private func mapToSearchHistoryItemDomain(from entity: SearchHistoryItemEntity) -> SearchHistoryItemDomain {
        return SearchHistoryItemDomain(
            id: entity.id,
            word: entity.word,
            timestamp: entity.timestamp
        )
    }
    
    private func mapToDictionaryError(_ error: Error) -> DictionaryErrorDomain {
        // 根据错误类型映射到业务层错误
        if error.localizedDescription.contains("not found") || error.localizedDescription.contains("未找到") {
            return .notFound
        } else if error.localizedDescription.contains("search") || error.localizedDescription.contains("搜索") {
            return .searchFailed
        } else if error.localizedDescription.contains("database") || error.localizedDescription.contains("数据库") {
            return .databaseError
        } else if error.localizedDescription.contains("pronunciation") || error.localizedDescription.contains("发音") {
            return .pronunciationFailed
        } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("网络") {
            return .networkError
        }
        
        // 默认返回搜索失败
        return .searchFailed
    }
}

// MARK: - 扩展FavoriteDataRepositoryProtocol以支持检查单词是否已收藏
extension DictionaryDataRepositoryProtocol {
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error> {
        // 这是一个默认实现，实际应用中可能需要依赖FavoriteRepository
        return Just(false)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}