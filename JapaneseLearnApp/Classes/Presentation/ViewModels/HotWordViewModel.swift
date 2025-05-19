//
//  HotWordViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2024/4/27.
//

import Foundation
import Combine

class HotWordViewModel: HotWordViewModelProtocol {
    @Published private(set) var hotWords: [WordCloudWord] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil

    private let hotWordService: HotWordServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(hotWordService: HotWordServiceProtocol) {
        self.hotWordService = hotWordService
        self.loadHotWords()
    }

    func loadHotWords() {
        isLoading = true
        errorMessage = nil
        hotWordService.getHotWords(limit: 15)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "获取热门词汇失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] words in
                    self?.hotWords = words
                }
            )
            .store(in: &cancellables)
    }
}
