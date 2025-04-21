//
//  HomeView.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI
import Combine

/// 首页视图，实现UI/UX设计规范文档中的首页设计
struct HomeView: View {
    // MARK: - 属性
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var userViewModel: UserViewModel
    
    @State private var isLearningCenterExpanded = false
    @State private var showSettings = false
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 主内容
            VStack(spacing: DesignSystem.Spacing.standard) {
                // 顶部区域
                topSection
                
                // 搜索区域
                searchSection
                
                // 学习流区域
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.relaxed) {
                        // 每日学习建议
                        dailyLearningCard
                        
                        // 最近查询词汇
                        recentSearchesCard
                        
                        // 学习进度卡片
                        learningProgressCard
                        
                        // 收藏夹快速访问
                        favoritesCard
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenEdge)
                    .padding(.bottom, 80) // 为浮动按钮留出空间
                }
            }
            
            // 浮动学习中心
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    learningCenterButton
                        .padding(.trailing, DesignSystem.Spacing.screenEdge)
                        .padding(.bottom, DesignSystem.Spacing.screenEdge)
                }
            }
            
            // 学习中心展开菜单
            if isLearningCenterExpanded {
                learningCenterMenu
            }
        }
        .sheet(isPresented: $showSettings) {
            Text("设置页面")
                .font(DesignSystem.Typography.title)
        }
    }
    
    // MARK: - 顶部区域
    private var topSection: some View {
        HStack {
            // 用户头像
            Button(action: { showSettings = true }) {
                if let _ = userViewModel.userProfile {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.primaryHex)
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 32))
                        .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                }
            }
            
            // 问候语
            Text(greetingMessage)
                .font(DesignSystem.Typography.subtitle)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
            
            Spacer()
            
            // 设置入口
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenEdge)
        .padding(.top, DesignSystem.Spacing.standard)
    }
    
    // MARK: - 搜索区域
    private var searchSection: some View {
        Components.InputFields.SearchField(
            text: $searchViewModel.searchQuery,
            placeholder: "搜索日语单词、假名或中文",
            onSubmit: searchViewModel.search
        )
        .padding(.horizontal, DesignSystem.Spacing.screenEdge)
    }
    
    // MARK: - 每日学习建议卡片
    private var dailyLearningCard: some View {
        Components.Cards.StandardCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                Text("每日学习建议")
                    .font(DesignSystem.Typography.subtitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Text("今天建议学习这些单词")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                
                // 示例单词列表
                VStack(spacing: DesignSystem.Spacing.compact) {
                    dailyWordRow(word: "食べる", reading: "たべる", meaning: "吃")
                    dailyWordRow(word: "飲む", reading: "のむ", meaning: "喝")
                    dailyWordRow(word: "見る", reading: "みる", meaning: "看")
                }
                .padding(.top, DesignSystem.Spacing.compact)
            }
        }
    }
    
    // 每日单词行
    private func dailyWordRow(word: String, reading: String, meaning: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Text(reading)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
            }
            
            Spacer()
            
            Text(meaning)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
            
            Components.SpecialComponents.PronunciationButton {
                // 播放发音
                print("播放发音: \(word)")
            }
        }
    }
    
    // MARK: - 最近搜索卡片
    private var recentSearchesCard: some View {
        Components.Cards.StandardCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                Text("最近搜索")
                    .font(DesignSystem.Typography.subtitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                if searchViewModel.searchHistory.isEmpty {
                    Text("暂无搜索历史")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                        .padding(.vertical, DesignSystem.Spacing.compact)
                } else {
                    // 最近搜索列表
                    VStack(spacing: DesignSystem.Spacing.compact) {
                        ForEach(searchViewModel.searchHistory.prefix(3)) { item in
                            Button(action: {
                                searchViewModel.searchQuery = item.word
                                searchViewModel.search()
                            }) {
                                HStack {
                                    Text(item.word)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(item.timestamp))
                                        .font(DesignSystem.Typography.footnote)
                                        .foregroundColor(DesignSystem.Colors.textHintHex)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                if !searchViewModel.searchHistory.isEmpty {
                    Button("清除历史") {
                        searchViewModel.clearHistory()
                    }
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.primaryHex)
                    .padding(.top, DesignSystem.Spacing.compact)
                }
            }
        }
    }
    
    // MARK: - 学习进度卡片
    private var learningProgressCard: some View {
        Components.Cards.StandardCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                Text("学习进度")
                    .font(DesignSystem.Typography.subtitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("今日学习")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                        
                        Spacer()
                        
                        Text("10/20词")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 8)
                                .foregroundColor(DesignSystem.Colors.neutralLightHex)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .frame(width: geometry.size.width * 0.5, height: 8)
                                .foregroundColor(DesignSystem.Colors.primaryHex)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.top, DesignSystem.Spacing.compact)
                
                // 继续学习按钮
                Components.Buttons.PrimaryButton(title: "继续学习", action: {
                    // 继续学习操作
                    print("继续学习")
                })
                .padding(.top, DesignSystem.Spacing.compact)
            }
        }
    }
    
    // MARK: - 收藏夹卡片
    private var favoritesCard: some View {
        Components.Cards.StandardCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                Text("收藏夹")
                    .font(DesignSystem.Typography.subtitle)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Text("快速访问您收藏的单词")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                
                // 示例收藏夹
                HStack(spacing: DesignSystem.Spacing.standard) {
                    folderButton(name: "常用词汇", count: 42)
                    folderButton(name: "N5单词", count: 28)
                    folderButton(name: "旅行用语", count: 15)
                }
                .padding(.top, DesignSystem.Spacing.compact)
            }
        }
    }
    
    // 收藏夹按钮
    private func folderButton(name: String, count: Int) -> some View {
        Button(action: {
            // 打开收藏夹
            print("打开收藏夹: \(name)")
        }) {
            VStack(spacing: 4) {
                Text(name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .lineLimit(1)
                
                Text("\(count)个词")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.compact)
            .background(DesignSystem.Colors.neutralLightHex)
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
    }
    
    // MARK: - 浮动学习中心按钮
    private var learningCenterButton: some View {
        Components.SpecialComponents.FloatingLearningCenterButton {
            withAnimation(.spring()) {
                isLearningCenterExpanded.toggle()
            }
        }
    }
    
    // MARK: - 学习中心菜单
    private var learningCenterMenu: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isLearningCenterExpanded = false
                    }
                }
            
            // 菜单内容
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.standard) {
                        // 菜单选项
                        learningCenterMenuItem(icon: "book.fill", title: "词典", action: {
                            // 打开词典
                            print("打开词典")
                            isLearningCenterExpanded = false
                        })
                        
                        learningCenterMenuItem(icon: "star.fill", title: "收藏", action: {
                            // 打开收藏
                            print("打开收藏")
                            isLearningCenterExpanded = false
                        })
                        
                        learningCenterMenuItem(icon: "graduationcap.fill", title: "学习", action: {
                            // 打开学习
                            print("打开学习")
                            isLearningCenterExpanded = false
                        })
                        
                        // 浮动按钮
                        learningCenterButton
                    }
                    .padding(.trailing, DesignSystem.Spacing.screenEdge)
                    .padding(.bottom, DesignSystem.Spacing.screenEdge)
                }
            }
        }
    }
    
    // 学习中心菜单项
    private func learningCenterMenuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.compact) {
                Text(title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, DesignSystem.Spacing.standard)
            .padding(.vertical, DesignSystem.Spacing.compact)
            .background(DesignSystem.Colors.primaryHex)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadowStyle(DesignSystem.Shadow.medium)
        }
    }
    
    // MARK: - 辅助方法
    // 获取问候语
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "夜深了"
        case 6..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - 预览
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService1()
        let userService = UserService1()
        
        HomeView(
            searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
            userViewModel: UserViewModel(userService: userService)
        )
    }
}

// 临时服务实现，仅用于预览
class DictionaryService1: DictionaryServiceProtocol {
    func searchWords(query: String, type: SearchTypeDomain?, limit: Int, offset: Int) -> AnyPublisher<SearchResultDomain, DictionaryErrorDomain> {
        return Just(SearchResultDomain(total: 0, items: []))
            .setFailureType(to: DictionaryErrorDomain.self)
            .eraseToAnyPublisher()
    }
    
    func getWordDetails(id: String) -> AnyPublisher<WordDetailsDomain, DictionaryErrorDomain> {
        return Fail(error: DictionaryErrorDomain.notFound).eraseToAnyPublisher()
    }
    
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryErrorDomain> {
        return Fail(error: DictionaryErrorDomain.pronunciationFailed).eraseToAnyPublisher()
    }
    
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItemDomain], DictionaryErrorDomain> {
        return Just([]).setFailureType(to: DictionaryErrorDomain.self).eraseToAnyPublisher()
    }
    
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryErrorDomain> {
        return Just(true).setFailureType(to: DictionaryErrorDomain.self).eraseToAnyPublisher()
    }
}

class UserService1: UserServiceProtocol {
    func signInWithApple() -> AnyPublisher<UserProfileDomain, UserErrorDomain> {
        return Fail(error: UserErrorDomain.authenticationFailed).eraseToAnyPublisher()
    }
    
    func getUserProfile() -> AnyPublisher<UserProfileDomain, UserErrorDomain> {
        return Fail(error: UserErrorDomain.userNotFound).eraseToAnyPublisher()
    }
    
    func updateUserSettings(settings: UserPreferencesDomain) -> AnyPublisher<UserPreferencesDomain, UserErrorDomain> {
        return Fail(error: UserErrorDomain.settingsUpdateFailed).eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Bool, UserErrorDomain> {
        return Just(true).setFailureType(to: UserErrorDomain.self).eraseToAnyPublisher()
    }
    
    func isUserLoggedIn() -> Bool {
        return false
    }
}
