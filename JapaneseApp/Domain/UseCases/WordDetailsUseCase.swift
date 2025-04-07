//
//  WordDetailsUseCase.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import Combine

/// 词条详情用例协议
public protocol WordDetailsUseCaseProtocol {
    /// 获取词条详情
    /// - Parameter id: 词条ID
    /// - Returns: 词条详情发布者
    func getDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError>
    
    /// 获取词条发音
    /// - Parameters:
    ///   - id: 词条ID
    ///   - speed: 发音速度
    /// - Returns: 发音文件URL发布者
    func getPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError>
    
    /// 获取相关词汇
    /// - Parameter id: 词条ID
    /// - Returns: 相关词汇列表发布者
    func getRelatedWords(id: String) -> AnyPublisher<[WordSummary], DictionaryError>
    
    /// 记录查看历史
    /// - Parameter id: 词条ID
    /// - Returns: 操作结果发布者
    func recordViewHistory(id: String) -> AnyPublisher<Void, DictionaryError>
}

/// 词条详情用例实现
public class WordDetailsUseCase: WordDetailsUseCaseProtocol {
    
    // MARK: - 依赖
    
    /// 词典服务
    private let dictionaryService: DictionaryServiceProtocol
    
    /// 词典仓库
    private let dictionaryRepository: DictionaryRepositoryProtocol
    
    // MARK: - 初始化
    
    /// 初始化词条详情用例
    /// - Parameters:
    ///   - dictionaryService: 词典服务
    ///   - dictionaryRepository: 词典仓库
    public init(dictionaryService: DictionaryServiceProtocol, dictionaryRepository: DictionaryRepositoryProtocol) {
        self.dictionaryService = dictionaryService
        self.dictionaryRepository = dictionaryRepository
    }
    
    // MARK: - WordDetailsUseCaseProtocol 实现
    
    /// 获取词条详情
    public func getDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError> {
        return dictionaryService.getWordDetails(id: id)
            .flatMap { [weak self] details -> AnyPublisher<WordDetails, DictionaryError> in
                // 获取相关词汇
                guard let self = self else {
                    return Just(details).setFailureType(to: DictionaryError.self).eraseToAnyPublisher()
                }
                
                return self.getRelatedWords(id: id)
                    .map { relatedWords -> WordDetails in
                        // 创建包含相关词汇的新详情对象
                        return WordDetails(
                            id: details.id,
                            word: details.word,
                            reading: details.reading,
                            partOfSpeech: details.partOfSpeech,
                            definitions: details.definitions,
                            examples: details.examples,
                            relatedWords: relatedWords,
                            isFavorited: details.isFavorited
                        )
                    }
                    .catch { _ in
                        // 如果获取相关词汇失败，仍返回原始详情
                        return Just(details).setFailureType(to: DictionaryError.self)
                    }
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // 记录查看历史
                self?.recordViewHistory(id: id)
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in }
                    )
                    .cancel()
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取词条发音
    public func getPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError> {
        // 验证速度参数
        let validSpeed = min(max(speed, 0.5), 2.0)
        return dictionaryService.getWordPronunciation(id: id, speed: validSpeed)
    }
    
    /// 获取相关词汇
    public func getRelatedWords(id: String) -> AnyPublisher<[WordSummary], DictionaryError> {
        // 实际项目中，这里可能需要基于词性、含义等进行相关词汇查询
        // 这里简化实现，返回与当前词条相同词性的其他词条
        
        return dictionaryRepository.getWordDetails(id: id)
            .flatMap { entry -> AnyPublisher<[DictEntry], Error> in
                guard let entry = entry else {
                    return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                
                // 查询相同词性的其他词条（示例实现）
                // 实际项目中可能需要更复杂的查询逻辑
                return self.dictionaryRepository.searchWords(
                    query: entry.partOfSpeech,
                    type: .meaning,
                    limit: 5,
                    offset: 0
                )
                .map { entries in
                    // 过滤掉当前词条
                    return entries.filter { $0.id != id }
                }
                .eraseToAnyPublisher()
            }
            .map { entries -> [WordSummary] in
                // 转换为WordSummary
                return entries.map { entry in
                    return WordSummary(
                        id: entry.id,
                        word: entry.word,
                        reading: entry.reading,
                        partOfSpeech: entry.partOfSpeech,
                        briefMeaning: entry.definitions.first?.meaning ?? ""
                    )
                }
            }
            .mapError { _ -> DictionaryError in
                return .databaseError
            }
            .eraseToAnyPublisher()
    }
    
    /// 记录查看历史
    public func recordViewHistory(id: String) -> AnyPublisher<Void, DictionaryError> {
        return dictionaryRepository.getWordDetails(id: id)
            .flatMap { entry -> AnyPublisher<Void, Error> in
                guard let entry = entry else {
                    return Fail(error: DictionaryError.notFound).eraseToAnyPublisher()
                }
                return self.dictionaryRepository.addSearchHistory(word: entry)
            }
            .mapError { error -> DictionaryError in
                if let dictError = error as? DictionaryError {
                    return dictError
                }
                return .databaseError
            }
            .eraseToAnyPublisher()
    }
}