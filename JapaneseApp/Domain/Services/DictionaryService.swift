//
//  DictionaryService.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import Combine

/// 词典服务协议实现
public class DictionaryService: DictionaryServiceProtocol {
    
    // MARK: - 依赖
    
    /// 词典数据仓库
    private let repository: DictionaryRepositoryProtocol
    
    /// 收藏仓库，用于检查单词是否已收藏
    private let favoriteRepository: FavoriteRepositoryProtocol
    
    // MARK: - 初始化
    
    /// 初始化词典服务
    /// - Parameters:
    ///   - repository: 词典数据仓库
    ///   - favoriteRepository: 收藏仓库
    public init(repository: DictionaryRepositoryProtocol, favoriteRepository: FavoriteRepositoryProtocol) {
        self.repository = repository
        self.favoriteRepository = favoriteRepository
    }
    
    // MARK: - DictionaryServiceProtocol 实现
    
    /// 搜索单词
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - type: 搜索类型（可选，默认为自动）
    ///   - limit: 结果数量限制
    ///   - offset: 结果偏移量（用于分页）
    /// - Returns: 搜索结果发布者
    public func searchWords(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError> {
        let searchType = type ?? .auto
        
        return repository.searchWords(query: query, type: searchType, limit: limit, offset: offset)
            .map { entries -> SearchResult in
                let wordSummaries = entries.map { entry in
                    self.convertToWordSummary(entry)
                }
                return SearchResult(total: entries.count, items: wordSummaries)
            }
            .mapError { error -> DictionaryError in
                print("搜索错误: \(error.localizedDescription)")
                return .searchFailed
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取单词详情
    /// - Parameter id: 单词ID
    /// - Returns: 单词详情发布者
    public func getWordDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError> {
        // 1. 获取词条详情
        let detailsPublisher = repository.getWordDetails(id: id)
            .mapError { _ -> DictionaryError in
                return .notFound
            }
        
        // 2. 检查是否已收藏
        let favoriteStatusPublisher = favoriteRepository.isWordFavorited(wordId: id)
            .mapError { _ -> DictionaryError in
                return .databaseError
            }
        
        // 3. 组合两个请求结果
        return Publishers.CombineLatest(detailsPublisher, favoriteStatusPublisher)
            .compactMap { entry, isFavorited -> WordDetails? in
                guard let entry = entry else {
                    return nil
                }
                
                // 转换为业务层模型
                let definitions = entry.definitions.map { Definition(meaning: $0.meaning, notes: $0.notes) }
                let examples = entry.examples.map { Example(sentence: $0.sentence, translation: $0.translation) }
                
                // 相关词汇（实际项目中可能需要额外查询）
                let relatedWords: [WordSummary] = []
                
                return WordDetails(
                    id: entry.id,
                    word: entry.word,
                    reading: entry.reading,
                    partOfSpeech: entry.partOfSpeech,
                    definitions: definitions,
                    examples: examples,
                    relatedWords: relatedWords,
                    isFavorited: isFavorited
                )
            }
            .mapError { error -> DictionaryError in
                if case .notFound = error {
                    return .notFound
                }
                return .databaseError
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取单词发音
    /// - Parameters:
    ///   - id: 单词ID
    ///   - speed: 发音速度（0.0-1.0）
    /// - Returns: 发音文件URL发布者
    public func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError> {
        // 获取单词详情
        return repository.getWordDetails(id: id)
            .flatMap { entry -> AnyPublisher<URL, Error> in
                guard let entry = entry else {
                    return Fail(error: DictionaryError.notFound).eraseToAnyPublisher()
                }
                
                // 使用AVFoundation生成发音（实际实现可能更复杂）
                return self.generatePronunciation(text: entry.word, speed: speed)
            }
            .mapError { error -> DictionaryError in
                if let dictError = error as? DictionaryError {
                    return dictError
                }
                return .pronunciationFailed
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取搜索历史
    /// - Parameter limit: 结果数量限制
    /// - Returns: 搜索历史列表发布者
    public func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], DictionaryError> {
        return repository.getSearchHistory(limit: limit)
            .map { historyItems in
                return historyItems.map { item in
                    return SearchHistoryItem(
                        id: item.id,
                        word: item.word,
                        timestamp: item.timestamp
                    )
                }
            }
            .mapError { _ -> DictionaryError in
                return .databaseError
            }
            .eraseToAnyPublisher()
    }
    
    /// 清除搜索历史
    /// - Returns: 操作结果发布者
    public func clearSearchHistory() -> AnyPublisher<Bool, DictionaryError> {
        return repository.clearSearchHistory()
            .map { _ in true }
            .mapError { _ -> DictionaryError in
                return .databaseError
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 辅助方法
    
    /// 将数据层词条模型转换为业务层词条摘要模型
    /// - Parameter entry: 数据层词条模型
    /// - Returns: 业务层词条摘要模型
    private func convertToWordSummary(_ entry: DictEntry) -> WordSummary {
        return WordSummary(
            id: entry.id,
            word: entry.word,
            reading: entry.reading,
            partOfSpeech: entry.partOfSpeech,
            briefMeaning: entry.definitions.first?.meaning ?? ""
        )
    }
    
    /// 生成单词发音（示例实现）
    /// - Parameters:
    ///   - text: 要发音的文本
    ///   - speed: 发音速度
    /// - Returns: 发音文件URL发布者
    private func generatePronunciation(text: String, speed: Float) -> AnyPublisher<URL, Error> {
        // 实际项目中，这里可能会使用AVSpeechSynthesizer或预先录制的音频文件
        // 这里仅作为示例，返回一个模拟的URL
        
        // 模拟异步操作
        return Future<URL, Error> { promise in
            DispatchQueue.global().async {
                do {
                    // 创建临时文件URL
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = "\(text)_\(speed).m4a"
                    let fileURL = tempDir.appendingPathComponent(fileName)
                    
                    // 实际项目中，这里应该生成真实的音频文件
                    // 这里仅创建一个空文件作为示例
                    try Data().write(to: fileURL)
                    
                    promise(.success(fileURL))
                } catch {
                    promise(.failure(DictionaryError.pronunciationFailed))
                }
            }
        }.eraseToAnyPublisher()
    }
}