//
//  LearningProgressTestView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

// 这是一个测试视图，用于演示学习目标设置与首页进度卡片的数据同步功能
struct LearningProgressTestView: View {
    @State private var learningGoal: LearningGoal = LearningGoal.defaultGoal
    private let learningGoalService = LearningGoalService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("学习进度测试")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.Colors.primary)
            
            // 当前目标显示
            VStack(alignment: .leading, spacing: 10) {
                Text("当前学习目标")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.primary)
                
                HStack {
                    Text("单词: \(learningGoal.wordGoal)")
                    Spacer()
                    Text("周期: \(learningGoal.isPeriodDaily ? "每日" : "每周")")
                }
                
                HStack {
                    Text("语法: \(learningGoal.grammarGoal)")
                    Spacer()
                    Text("阅读: \(learningGoal.readingGoal)")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // 当前进度显示
            VStack(alignment: .leading, spacing: 10) {
                Text("当前学习进度")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.primary)
                
                HStack {
                    Text("单词: \(learningGoal.wordProgress)/\(learningGoal.wordGoal)")
                    Spacer()
                    Text("\(Int(learningGoal.wordProgressPercentage * 100))%")
                }
                
                HStack {
                    Text("语法: \(learningGoal.grammarProgress)/\(learningGoal.grammarGoal)")
                    Spacer()
                    Text("\(Int(learningGoal.grammarProgressPercentage * 100))%")
                }
                
                HStack {
                    Text("阅读: \(learningGoal.readingProgress)/\(learningGoal.readingGoal)")
                    Spacer()
                    Text("\(Int(learningGoal.readingProgressPercentage * 100))%")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // 进度更新测试按钮
            VStack(spacing: 15) {
                Button(action: {
                    // 增加单词进度
                    let newProgress = min(learningGoal.wordProgress + 1, learningGoal.wordGoal)
                    learningGoalService.updateProgress(wordProgress: newProgress)
                }) {
                    Text("增加单词进度")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // 增加语法进度
                    let newProgress = min(learningGoal.grammarProgress + 1, learningGoal.grammarGoal)
                    learningGoalService.updateProgress(grammarProgress: newProgress)
                }) {
                    Text("增加语法进度")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // 增加阅读进度
                    let newProgress = min(learningGoal.readingProgress + 1, learningGoal.readingGoal)
                    learningGoalService.updateProgress(readingProgress: newProgress)
                }) {
                    Text("增加阅读进度")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // 重置进度
                    learningGoalService.updateProgress(wordProgress: 0, grammarProgress: 0, readingProgress: 0)
                }) {
                    Text("重置进度")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // 订阅学习目标变化
            learningGoalService.goalPublisher
                .sink { updatedGoal in
                    self.learningGoal = updatedGoal
                }
                .store(in: &cancellables)
        }
    }
}

struct LearningProgressTestView_Previews: PreviewProvider {
    static var previews: some View {
        LearningProgressTestView()
    }
}
