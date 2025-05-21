//
//  LearningGoalSettingsView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct LearningGoalSettingsView: View {
    // MARK: - 属性
    @Environment(\.presentationMode) var presentationMode
    @State private var animateGradient = false
    @State private var wordGoal: Double = 20
    @State private var grammarGoal: Double = 10
    @State private var readingGoal: Double = 5
    @State private var goalPeriod: GoalPeriod = .daily
    @State private var showConfetti = false
    
    // 学习目标服务
    private let learningGoalService = LearningGoalService.shared
    
    // 目标周期选项
    enum GoalPeriod: String, CaseIterable, Identifiable {
        case daily = "每日"
        case weekly = "每周"
        
        var id: String { self.rawValue }
    }
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景层
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // 目标周期选择
                        goalPeriodSelector
                        
                        // 单词学习目标
                        goalSettingCard(
                            title: "单词学习目标",
                            icon: "character.book.closed",
                            value: $wordGoal,
                            range: 1...100,
                            step: 1,
                            color: AppTheme.Colors.primary,
                            description: "\(goalPeriod.rawValue)学习的单词数量"
                        )
                        
                        // 语法学习目标
                        goalSettingCard(
                            title: "语法学习目标",
                            icon: "doc.text",
                            value: $grammarGoal,
                            range: 1...50,
                            step: 1,
                            color: AppTheme.Colors.primary,
                            description: "\(goalPeriod.rawValue)学习的语法点数量"
                        )
                        
                        // 阅读学习目标
                        goalSettingCard(
                            title: "阅读学习目标",
                            icon: "book",
                            value: $readingGoal,
                            range: 1...30,
                            step: 1,
                            color: AppTheme.Colors.primary,
                            description: "\(goalPeriod.rawValue)阅读的文章数量"
                        )
                        .padding(.bottom, 16)
                        
                        // 目标总结卡片
                        goalSummaryCard
                        
                        // 保存按钮
                        saveButton
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
//            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
//                animateGradient.toggle()
//            }
            
            // 加载已保存的目标设置（这里使用模拟数据）
            loadSavedGoals()
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
            
            Spacer()
            
            // 页面标题
            Text("学习目标设置")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            // 重置按钮
            Button(action: resetGoals) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - 目标周期选择器
    private var goalPeriodSelector: some View {
        VStack(alignment: .leading, spacing: 0) {
//            Text("目标周期")
//                .font(.headline)
//                .foregroundColor(AppTheme.Colors.primary)
            
            HStack(spacing: 15) {
//                Spacer()
                ForEach(GoalPeriod.allCases) { period in
                    Button(action: { goalPeriod = period }) {
                        Text(period.rawValue)
                            .font(.system(size: 16))
                            .fontWeight(goalPeriod == period ? .semibold : .regular)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(goalPeriod == period ? themeGradient : LinearGradient(colors: [Color(UIColor.secondarySystemBackground)], startPoint: .leading, endPoint: .trailing))
                            )
                            .foregroundColor(goalPeriod == period ? .white : AppTheme.Colors.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
//                Spacer()
            }
        }
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color(UIColor.secondarySystemBackground))
//        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 目标设置卡片
    private func goalSettingCard(
        title: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: Color,
        description: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题和图标
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                // 当前值显示
                Text("\(Int(value.wrappedValue))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            // 描述文本
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // 滑块
            HStack(spacing: 15) {
                // 减少按钮
                Button(action: {
                    if value.wrappedValue > range.lowerBound {
                        value.wrappedValue -= step
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                // 滑块
                Slider(value: value, in: range, step: step)
                    .accentColor(color)
                
                // 增加按钮
                Button(action: {
                    if value.wrappedValue < range.upperBound {
                        value.wrappedValue += step
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
            
            // 数值指示器
            HStack {
                Spacer()
                    .frame(width: 12)
                Text("\(Int(range.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                    .frame(width: 5)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 目标总结卡片
    private var goalSummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(themeGradient)
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("目标总结")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Divider()
                    .background(Color.white.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("你的\(goalPeriod.rawValue)学习计划:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 5) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("学习 \(Int(wordGoal)) 个新单词")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 5) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("掌握 \(Int(grammarGoal)) 个语法点")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    HStack(spacing: 5) {
                        Text("•")
                            .foregroundColor(.white)
                        Text("阅读 \(Int(readingGoal)) 篇文章")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("坚持学习，你将在 \(calculateEstimatedDays()) 天内达到N3水平！")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 5)
                }
            }
            .padding()
        }
        .frame(height: 200)
        .shadow(color: AppTheme.Colors.primaryLightest, radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 保存按钮
    private var saveButton: some View {
        Button(action: saveGoals) {
            Text("保存学习目标")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(themeGradient)
                )
                .shadow(color: AppTheme.Colors.primaryLightest, radius: 10, x: 0, y: 5)
        }
        .padding(.top, 10)
    }
    
    // MARK: - 功能方法
    
    // 加载已保存的目标设置
    private func loadSavedGoals() {
        // 从LearningGoalService加载已保存的目标设置
        let savedGoal = learningGoalService.currentGoal
        
        // 更新UI状态
        wordGoal = Double(savedGoal.wordGoal)
        grammarGoal = Double(savedGoal.grammarGoal)
        readingGoal = Double(savedGoal.readingGoal)
        goalPeriod = savedGoal.isPeriodDaily ? .daily : .weekly
    }
    
    // 保存目标设置
    private func saveGoals() {
        // 创建新的学习目标对象
        let newGoal = LearningGoal(
            wordGoal: Int(wordGoal),
            grammarGoal: Int(grammarGoal),
            readingGoal: Int(readingGoal),
            isPeriodDaily: goalPeriod == .daily,
            wordProgress: learningGoalService.currentGoal.wordProgress,
            grammarProgress: learningGoalService.currentGoal.grammarProgress,
            readingProgress: learningGoalService.currentGoal.readingProgress
        )
        
        // 保存到LearningGoalService
        learningGoalService.saveGoal(goal: newGoal)
        
        // 显示成功动画
        withAnimation {
            showConfetti = true
        }
        
        // 显示成功提示并返回
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // 重置目标设置
    private func resetGoals() {
        wordGoal = 20
        grammarGoal = 10
        readingGoal = 5
    }
    
    // 计算预估达到N3水平的天数
    private func calculateEstimatedDays() -> Int {
        // 这里使用一个简单的算法来估算
        // 实际应用中可以使用更复杂的算法
        let dailyWordGoal = goalPeriod == .daily ? wordGoal : wordGoal / 7
        let dailyGrammarGoal = goalPeriod == .daily ? grammarGoal : grammarGoal / 7
        
        // N3大约需要掌握3000个单词和300个语法点
        let wordsNeeded = 3000.0
        let grammarNeeded = 300.0
        
        let wordDays = dailyWordGoal > 0 ? wordsNeeded / dailyWordGoal : 0
        let grammarDays = dailyGrammarGoal > 0 ? grammarNeeded / dailyGrammarGoal : 0
        
        // 取较长的时间作为估计
        return Int(max(wordDays, grammarDays))
    }
}

// MARK: - 预览
struct LearningGoalSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        LearningGoalSettingsView()
    }
}
