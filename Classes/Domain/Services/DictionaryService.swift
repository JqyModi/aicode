import Foundation
import Combine
import RealmSwift

// MARK: - 词典服务协议
protocol DictionaryServiceProtocol {
    // 搜索单词
    func searchWords(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError>
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryDTO], DictionaryError>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryError>
    
    // 添加搜索历史
    func addSearchHistory(item: SearchHistoryDTO) -> AnyPublisher<Bool, DictionaryError>
}

// MARK: - 词典服务实现
class DictionaryService: DictionaryServiceProtocol {
    private let dictionaryRepository: DictionaryRepositoryProtocol
    private let audioService: AudioServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(dictionaryRepository: DictionaryRepositoryProtocol, audioService: AudioServiceProtocol) {
        self.dictionaryRepository = dictionaryRepository
        self.audioService = audioService
    }
    
    // 搜索单词
    func searchWords(query: String, type: SearchType? = .auto, limit: Int = 20, offset: Int = 0) -> AnyPublisher<SearchResult, DictionaryError> {
        return dictionaryRepository.searchWords(query: query, type: type ?? .auto, limit: limit, offset: offset)
            .map { entries in
                let items = entries.map { entry in
                    return WordListItem(
                        id: entry.id,
                        word: entry.word,
                        reading: entry.reading,
                        partOfSpeech: entry.partOfSpeech,
                        briefMeaning: entry.definitions.first?.meaning ?? ""
                    )
                }
                
                return SearchResult(
                    query: query,
                    totalCount: items.count,
                    items: items
                )
            }
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError> {
        return dictionaryRepository.getWordDetails(id: id)
            .map { entry -> WordDetails? in
                guard let entry = entry else {
                    return nil
                }
                
                let definitions = entry.definitions.map { def in
                    return Definition(meaning: def.meaning, notes: def.notes)
                }
                
                let examples = entry.examples.map { ex in
                    return Example(sentence: ex.sentence, translation: ex.translation)
                }
                
                return WordDetails(
                    id: entry.id,
                    word: entry.word,
                    reading: entry.reading,
                    partOfSpeech: entry.partOfSpeech,
                    definitions: Array(definitions),
                    examples: Array(examples),
                    tags: []
                )
            }
            .tryMap { wordDetails -> WordDetails in
                guard let wordDetails = wordDetails else {
                    throw DictionaryError.notFound
                }
                return wordDetails
            }
            .mapError { error in
                if let dictError = error as? DictionaryError {
                    return dictError
                }
                if let realmError = error as? Realm.Error {
                    return .databaseError(realmError)
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float = 1.0) -> AnyPublisher<URL, DictionaryError> {
        return dictionaryRepository.getWordDetails(id: id)
            .flatMap { entry -> AnyPublisher<URL, Error> in
                return self.audioService.getAudioForWord(word: entry?.word ?? "", speed: speed)
            }
            .mapError { error in
                return .audioError
            }
            .eraseToAnyPublisher()
    }
    
    // 获取搜索历史
    func getSearchHistory(limit: Int = 10) -> AnyPublisher<[SearchHistoryDTO], DictionaryError> {
        return dictionaryRepository.getSearchHistory(limit: limit)
            .map { items in
                return items.map { item in
                    return SearchHistoryDTO(
                        id: item.id,
                        word: item.word,
                        timestamp: item.searchDate
                    )
                }
            }
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryError> {
        return dictionaryRepository.clearSearchHistory()
            .map { _ in
                return true
            }
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 添加搜索历史
    func addSearchHistory(item: SearchHistoryDTO) -> AnyPublisher<Bool, DictionaryError> {
        // 首先获取词条信息
        return dictionaryRepository.getWordDetails(id: item.id)
            .flatMap { entry -> AnyPublisher<Void, Error> in
                guard let entry = entry else {
                    return Fail(error: DictionaryError.notFound).eraseToAnyPublisher()
                }
                return self.dictionaryRepository.addSearchHistory(word: entry)
            }
            .map { _ in
                return true
            }
            .mapError { error in
                return .databaseError(error)
            }
            .eraseToAnyPublisher()
    }
}
