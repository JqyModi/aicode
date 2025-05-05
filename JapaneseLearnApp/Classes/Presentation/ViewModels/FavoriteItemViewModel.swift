//
//  FavoriteItemViewModel.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import Foundation

/// 收藏项视图模型
struct FavoriteItemViewModel: Identifiable {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let type: String // 类型：单词、语法、例句等
    let note: String?
    let addedAt: Date
    
    // 从领域模型转换
    static func fromDomain(_ domain: FavoriteItemDetailDomain) -> FavoriteItemViewModel {
        return FavoriteItemViewModel(
            id: domain.id,
            wordId: domain.wordId,
            word: domain.word,
            reading: domain.reading,
            meaning: domain.meaning,
            type: determineType(domain.word, domain.meaning),
            note: domain.note,
            addedAt: domain.addedAt
        )
    }
    
    // 根据内容确定类型
    private static func determineType(_ word: String, _ meaning: String) -> String {
        // 简单的类型判断逻辑
        if word.contains("〜") || word.contains("「") {
            return "语法"
        } else if word.count > 10 {
            return "例句"
        } else {
            return "单词"
        }
    }
}