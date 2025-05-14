//
//  HotWordService.swift
//  JapaneseLearnApp
//
//  Created by AI on 2024/4/27.
//

import Foundation
import Combine

class HotWordService: HotWordServiceProtocol {
    private let hotWordRepository: HotWordDataRepositoryProtocol

    init(hotWordRepository: HotWordDataRepositoryProtocol) {
        self.hotWordRepository = hotWordRepository
    }

    func getHotWords(limit: Int) -> AnyPublisher<[WordCloudWord], Error> {
        // 这里假设热门词汇通过某种统计方式获得，简化为取最近搜索历史的单词
        return hotWordRepository.getHotWords(limit: limit)
            .map { entities in
                entities
            }
            .eraseToAnyPublisher()
    }
}
