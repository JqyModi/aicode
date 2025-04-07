//
//  SearchUseCase.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import Combine

/// 搜索用例协议
public protocol SearchUseCaseProtocol {
    /// 执行搜索
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - type: 搜索类型
    ///   - limit: 结果数量限制
    ///   - offset: 结果偏移量
    /// - Returns: 搜索结果发布者
    func execute(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError>
    
    /// 获取搜索建议
    /// - Parameter query: 搜索关键词
    /// - Returns: 搜索建议列表发布者
    func getSuggestions(query: String) -> AnyPublisher<[String], DictionaryError>
    
    /// 获取搜索历史
    /// - Parameter limit: 结果数量限制
    /// - Returns: 搜索历史列表发布者
    func getHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], DictionaryError>
    
    /// 清除搜索历史
    /// - Returns: 操作结果发布者
    func clearHistory() -> AnyPublisher<Bool, DictionaryError>
    
    /// 记录搜索历史
    /// - Parameter wordId: 单词ID
    /// - Returns: 操作结果发布者
    func recordSearch(wordId: String) -> AnyPublisher<Void, DictionaryError>
}

/// 搜索用例实现
public class SearchUseCase: SearchUseCaseProtocol {
    
    // MARK: - 依赖
    
    /// 词典服务
    private let dictionaryService: DictionaryServiceProtocol
    
    /// 词典仓库（用于直接访问某些数据层功能）
    private let dictionaryRepository: DictionaryRepositoryProtocol
    
    // MARK: - 初始化
    
    /// 初始化搜索用例
    /// - Parameters:
    ///   - dictionaryService: 词典服务
    ///   - dictionaryRepository: 词典仓库
    public init(dictionaryService: DictionaryServiceProtocol, dictionaryRepository: DictionaryRepositoryProtocol) {
        self.dictionaryService = dictionaryService
        self.dictionaryRepository = dictionaryRepository
    }
    
    // MARK: - SearchUseCaseProtocol 实现
    
    /// 执行搜索
    public func execute(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError> {
        // 参数验证
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Fail(error: DictionaryError.searchFailed).eraseToAnyPublisher()
        }
        
        // 使用词典服务执行搜索
        return dictionaryService.searchWords(query: query, type: type, limit: limit, offset: offset)
            .handleEvents(receiveOutput: { [weak self] result in
                // 如果有结果，记录第一个结果到搜索历史
                if let firstItem = result.items.first {
                    self?.dictionaryRepository.getWordDetails(id: firstItem.id)
                        .flatMap { entry -> AnyPublisher<Void, Error> in
                            guard let entry = entry else {
                                return Fail(error: DictionaryError.notFound).eraseToAnyPublisher()
                            }
                            return self?.dictionaryRepository.addSearchHistory(word: entry) ?? Empty().eraseToAnyPublisher()
                        }
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { _ in }
                        )
                        .cancel()
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 获取搜索建议
    public func getSuggestions(query: String) -> AnyPublisher<[String], DictionaryError> {
        // 参数验证
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Just([]).setFailureType(to: DictionaryError.self).eraseToAnyPublisher()
        }
        
        // 简单实现：使用搜索结果的前5个作为建议
        // 实际项目中可能需要更复杂的逻辑
        return dictionaryService.searchWords(query: query, type: .auto, limit: 5, offset: 0)
            .map { result in
                return result.items.map { $0.word }
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取搜索历史
    public func getHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], DictionaryError> {
        return dictionaryService.getSearchHistory(limit: limit)
    }
    
    /// 清除搜索历史
    public func clearHistory() -> AnyPublisher<Bool, DictionaryError> {
        return dictionaryService.clearSearchHistory()
    }
    
    /// 记录搜索历史
    public func recordSearch(wordId: String) -> AnyPublisher<Void, DictionaryError> {
        return dictionaryRepository.getWordDetails(id: wordId)
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