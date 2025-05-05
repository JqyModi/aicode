//
//  LearningGoalService.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import Foundation
import Combine

// 学习目标数据模型
struct LearningGoal: Codable {
    var wordGoal: Int
    var grammarGoal: Int
    var readingGoal: Int
    var isPeriodDaily: Bool // true为每日，false为每周
    
    // 学习进度（实际应用中应该从学习记录中计算）
    var wordProgress: Int
    var grammarProgress: Int
    var readingProgress: Int
    
    // 计算属性：进度百分比
    var wordProgressPercentage: Double {
        return wordGoal > 0 ? min(Double(wordProgress) / Double(wordGoal), 1.0) : 0
    }
    
    var grammarProgressPercentage: Double {
        return grammarGoal > 0 ? min(Double(grammarProgress) / Double(grammarGoal), 1.0) : 0
    }
    
    var readingProgressPercentage: Double {
        return readingGoal > 0 ? min(Double(readingProgress) / Double(readingGoal), 1.0) : 0
    }
    
    // 默认值
    static let defaultGoal = LearningGoal(
        wordGoal: 20,
        grammarGoal: 10,
        readingGoal: 5,
        isPeriodDaily: true,
        wordProgress: 13,
        grammarProgress: 4,
        readingProgress: 1
    )
}

// 学习目标服务
class LearningGoalService {
    // 单例模式
    static let shared = LearningGoalService()
    
    // UserDefaults键
    private let learningGoalKey = "learningGoal"
    
    // 发布者
    private let goalSubject = CurrentValueSubject<LearningGoal, Never>(LearningGoal.defaultGoal)
    var goalPublisher: AnyPublisher<LearningGoal, Never> {
        return goalSubject.eraseToAnyPublisher()
    }
    
    // 当前目标
    var currentGoal: LearningGoal {
        return goalSubject.value
    }
    
    private init() {
        // 从UserDefaults加载数据
        loadGoal()
    }
    
    // 保存学习目标
    func saveGoal(goal: LearningGoal) {
        if let encoded = try? JSONEncoder().encode(goal) {
            UserDefaults.standard.set(encoded, forKey: learningGoalKey)
            goalSubject.send(goal)
        }
    }
    
    // 加载学习目标
    private func loadGoal() {
        if let savedGoal = UserDefaults.standard.data(forKey: learningGoalKey),
           let decodedGoal = try? JSONDecoder().decode(LearningGoal.self, from: savedGoal) {
            goalSubject.send(decodedGoal)
        }
    }
    
    // 更新学习进度（实际应用中应该根据用户学习行为自动更新）
    func updateProgress(wordProgress: Int? = nil, grammarProgress: Int? = nil, readingProgress: Int? = nil) {
        var updatedGoal = currentGoal
        
        if let wordProgress = wordProgress {
            updatedGoal.wordProgress = wordProgress
        }
        
        if let grammarProgress = grammarProgress {
            updatedGoal.grammarProgress = grammarProgress
        }
        
        if let readingProgress = readingProgress {
            updatedGoal.readingProgress = readingProgress
        }
        
        saveGoal(goal: updatedGoal)
    }
    
    // 重置学习目标为默认值
    func resetGoal() {
        saveGoal(goal: LearningGoal.defaultGoal)
    }
}