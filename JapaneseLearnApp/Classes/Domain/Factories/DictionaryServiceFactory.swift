import Foundation

class DictionaryServiceFactory {
    static func createDictionaryService() -> DictionaryServiceProtocol {
        let dictionaryRepository = DictionaryRepositoryFactory.createDictionaryRepository()
        let audioService = AudioService()
        return DictionaryService(dictionaryRepository: dictionaryRepository, audioService: audioService)
    }
}

class DictionaryRepositoryFactory {
    static func createDictionaryRepository() -> DictionaryRepositoryProtocol {
        return DictionaryRepository()
    }
}