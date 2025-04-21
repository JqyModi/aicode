//
//  HomeView.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI
import Combine

/// 首页视图，实现现代化日式风格的UI设计
struct HomeView: View {
    // MARK: - 属性
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var userViewModel: UserViewModel
    
    @State private var isLearningCenterExpanded = false
    @State private var showSettings = false
    @State private var animateBackground = false
    @State private var selectedTab = 0
    @State private var cardOffsets: [CGFloat] = [0, 0, 0, 0]
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景图案
            ZStack {
                // 日式波浪图案背景
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        HStack(spacing: 0) {
                            ForEach(0..<3) { j in
                                Circle()
                                    .fill(DesignSystem.Colors.primaryLightHex.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                    .offset(x: animateBackground ? 5 : -5, y: animateBackground ? 5 : -5)
                                    .blur(radius: 15)
                            }
                        }
                    }
                }
                .rotationEffect(.degrees(45))
                .offset(x: -100, y: -200)
                .opacity(0.6)
                
                // 樱花图案
                ForEach(0..<8) { i in
                    Image(systemName: "sakura")
                        .foregroundColor(DesignSystem.Colors.accentHex.opacity(0.2))
                        .font(.system(size: 20 + CGFloat(i * 5)))
                        .position(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                  y: CGFloat.random(in: 0...UIScreen.main.bounds.height))
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        .opacity(animateBackground ? 0.7 : 0.3)
                        .animation(Animation.easeInOut(duration: 3).repeatForever().delay(Double(i) * 0.2), value: animateBackground)
                }
            }
            .ignoresSafeArea()
            
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
                            .offset(x: cardOffsets[0])
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                                    cardOffsets[0] = 0
                                }
                            }
                        
                        // 最近查询词汇
                        recentSearchesCard
                            .offset(x: cardOffsets[1])
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                                    cardOffsets[1] = 0
                                }
                            }
                        
                        // 学习进度卡片
                        learningProgressCard
                            .offset(x: cardOffsets[2])
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                                    cardOffsets[2] = 0
                                }
                            }
                        
                        // 收藏夹快速访问
                        favoritesCard
                            .offset(x: cardOffsets[3])
                            .onAppear {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                                    cardOffsets[3] = 0
                                }
                            }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.screenEdge)
                    .padding(.bottom, 100) // 为底部导航栏留出空间
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
        .overlay(alignment: .bottom) {
            bottomTabBar
        }
        .onAppear {
            // 初始化卡片偏移量，用于入场动画
            cardOffsets = [UIScreen.main.bounds.width, UIScreen.main.bounds.width, UIScreen.main.bounds.width, UIScreen.main.bounds.width]
            
            // 启动背景动画
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
        }
    }
    
    // MARK: - 顶部区域
    private var topSection: some View {
        HStack {
            // 用户头像 - 现代化设计
            Button(action: { showSettings = true }) {
                ZStack {
                    if let _ = userViewModel.userProfile {
                        Circle()
                            .fill(DesignSystem.Colors.primaryHex)
                            .frame(width: 40, height: 40)
                            .shadowStyle(DesignSystem.Shadow.medium)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(DesignSystem.Colors.primaryHex, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "person")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                    }
                }
            }
            
            // 问候语 - 带有日式风格
            VStack(alignment: .leading, spacing: 2) {
                Text("こんにちは")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.accentHex)
                
                Text(greetingMessage)
                    .font(DesignSystem.Typography.subtitle.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
            }
            
            Spacer()
            
            // 设置入口 - 更现代的设计
            Button(action: { showSettings = true }) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .fill(DesignSystem.Colors.neutralLightHex)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primaryHex)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.screenEdge)
        .padding(.top, DesignSystem.Spacing.standard)
    }
    
    // MARK: - 搜索区域
    private var searchSection: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.primaryHex)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("搜索日语单词、假名或中文", text: $searchViewModel.searchQuery)
                    .font(DesignSystem.Typography.body)
                    .onSubmit(searchViewModel.search)
                
                if !searchViewModel.searchQuery.isEmpty {
                    Button(action: { searchViewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textHintHex)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(Color.white)
                    .shadowStyle(DesignSystem.Shadow.small)
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.screenEdge)
    }
    
    // MARK: - 每日学习建议卡片
    private var dailyLearningCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
            HStack {
                // 日式风格标题
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(DesignSystem.Colors.accentHex)
                        .frame(width: 4, height: 20)
                    
                    Text("每日学习建议")
                        .font(DesignSystem.Typography.subtitle.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                }
                
                Spacer()
                
                // 刷新按钮
                Button(action: {
                    // 刷新每日建议
                    print("刷新每日建议")
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primaryHex)
                        .padding(8)
                        .background(DesignSystem.Colors.neutralLightHex)
                        .clipShape(Circle())
                }
            }
            
            Text("今天建议学习这些单词")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
            
            // 示例单词列表 - 现代卡片式设计
            VStack(spacing: DesignSystem.Spacing.standard) {
                dailyWordRow(word: "食べる", reading: "たべる", meaning: "吃")
                dailyWordRow(word: "飲む", reading: "のむ", meaning: "喝")
                dailyWordRow(word: "見る", reading: "みる", meaning: "看")
            }
            .padding(.top, DesignSystem.Spacing.compact)
        }
        .padding(DesignSystem.Spacing.standard)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                .fill(Color.white)
                .shadowStyle(DesignSystem.Shadow.medium)
        )
    }
    
    // 每日单词行 - 现代卡片式设计
    private func dailyWordRow(word: String, reading: String, meaning: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.standard) {
            // 单词指示器
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryLightHex)
                    .frame(width: 40, height: 40)
                
                Text(word.prefix(1))
                    .font(DesignSystem.Typography.subtitle.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.primaryHex)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(word)
                    .font(DesignSystem.Typography.body.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Text(reading)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(meaning)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                
                Button(action: {
                    // 播放发音
                    print("播放发音: \(word)")
                }) {
                    HStack(spacing: 4) {
                        Text("发音")
                            .font(DesignSystem.Typography.footnote)
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(DesignSystem.Colors.primaryHex)
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
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
    
    // MARK: - 底部导航栏
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "house.fill", title: "首页", index: 0)
            tabBarItem(icon: "book.fill", title: "词典", index: 1)
            
            // 中间的学习中心按钮
            Button(action: {
                withAnimation(.spring()) {
                    isLearningCenterExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryHex)
                        .frame(width: 56, height: 56)
                        .shadow(color: DesignSystem.Colors.primaryHex.opacity(0.3), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -20)
            
            tabBarItem(icon: "star.fill", title: "收藏", index: 2)
            tabBarItem(icon: "person.fill", title: "我的", index: 3)
        }
        .padding(.horizontal, DesignSystem.Spacing.standard)
        .padding(.top, 12)
        .padding(.bottom, 8 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // 底部导航栏项
    private func tabBarItem(icon: String, title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: selectedTab == index ? 20 : 18))
                    .foregroundColor(selectedTab == index ? DesignSystem.Colors.primaryHex : DesignSystem.Colors.textSecondaryHex)
                
                Text(title)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(selectedTab == index ? DesignSystem.Colors.primaryHex : DesignSystem.Colors.textSecondaryHex)
            }
            .frame(maxWidth: .infinity)
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
            
            // 菜单内容 - 现代化设计
            VStack {
                Spacer()
                
                VStack(spacing: DesignSystem.Spacing.standard) {
                    Text("学习中心")
                        .font(DesignSystem.Typography.title.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, DesignSystem.Spacing.standard)
                    
                    // 菜单选项网格
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.standard) {
                        learningCenterGridItem(icon: "book.fill", title: "词典", color: DesignSystem.Colors.primaryHex, action: {
                            print("打开词典")
                            isLearningCenterExpanded = false
                        })
                        
                        learningCenterGridItem(icon: "star.fill", title: "收藏", color: DesignSystem.Colors.accentHex, action: {
                            print("打开收藏")
                            isLearningCenterExpanded = false
                        })
                        
                        learningCenterGridItem(icon: "graduationcap.fill", title: "学习", color: DesignSystem.Colors.infoHex, action: {
                            print("打开学习")
                            isLearningCenterExpanded = false
                        })
                        
                        learningCenterGridItem(icon: "chart.bar.fill", title: "统计", color: DesignSystem.Colors.successHex, action: {
                            print("打开统计")
                            isLearningCenterExpanded = false
                        })
                    }
                    .padding(.horizontal, DesignSystem.Spacing.standard)
                    
                    // 关闭按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            isLearningCenterExpanded = false
                        }
                    }) {
                        Text("关闭")
                            .font(DesignSystem.Typography.body.weight(.medium))
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                            .padding(.vertical, DesignSystem.Spacing.compact)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.standard)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                )
                .padding(.horizontal, DesignSystem.Spacing.standard)
            }
        }
    }
    
    // 学习中心网格项
    private func learningCenterGridItem(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.compact) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.body.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.standard)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
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
