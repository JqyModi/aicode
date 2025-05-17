//
//  HomeView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

// 导入主题样式系统
import Foundation

// 确保可以访问AppTheme
@available(*, deprecated, message: "请使用AppTheme中定义的样式")
typealias DeprecatedStyles = Never

// 这里我们假设AppTheme.swift在同一模块中，不需要额外导入
// 如果AppTheme在不同模块，则需要导入对应模块

struct HomeView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var hotWordViewModel: HotWordViewModel
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var animateGradient = false
    @State private var isShowWordDetailView = false
    @State private var isShowProgressTestView = false
    
    // 学习目标数据
    @State private var learningGoal: LearningGoal = LearningGoal.defaultGoal
    private let learningGoalService = LearningGoalService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    // 获取当前时间段的问候语
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }
    
    // 获取最近搜索词汇
    private var recentSearches: [String] {
        return searchViewModel.searchHistory.prefix(5).map { $0.word }
    }
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        AppTheme.Gradients.primaryGradient(animate: animateGradient)
    }
    
    var body: some View {
        ZStack {
            // 背景层
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部区域
                topSection
//                    .ignoresSafeArea()
                
                // 主内容区域
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // 搜索区域
                        searchSection
                        
                        // 学习建议卡片
                        learningRecommendationCard
                        
                        // 学习进度卡片
                        learningProgressCard
                        
                        if !recentSearches.isEmpty {
                            // 最近查询词汇
                            recentSearchesCard
                        }
                        
                        if !userFolders.isEmpty {
                            // 收藏夹快速访问
                            NavigationLink(destination: FavoritesView(
                                favoriteViewModel: DetailViewModel(
                                    dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                                    favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: "" // #warning 补充逻辑
                                )
                            )) {
                                favoritesCard
                            }
                        }
                        
                        
                        // 学习建议
                        learningTipsCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.screenPadding)
                .padding(.bottom, 80) // 为浮动按钮留出空间
                }
            }
            
            // 浮动学习中心按钮
            floatingActionButton
        }
        .onAppear {
            // 启动渐变动画
            withAnimation(AppTheme.Animations.gradientAnimation) {
                animateGradient.toggle()
            }
            
            // 订阅学习目标变化
            learningGoalService.goalPublisher
                .sink { updatedGoal in
                    self.learningGoal = updatedGoal
                }
                .store(in: &cancellables)
            
            // 加载用户收藏夹数据
            if userViewModel.isLoggedIn {
                loadUserFolders()
            }
        }
        .sheet(isPresented: $isShowWordDetailView) {
            WordDetailView(detailViewModel: DetailViewModel(dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()), favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: "1989103009"))
//            CompleteJapaneseTextParserDemo()
//            JapaneseTextParserDemo()
//            AdvancedJapaneseTextParserDemo()
//            UIViewControllerPreview {
//                JapaneseTextParserViewController()
//            }
        }
        .sheet(isPresented: $isShowProgressTestView) {
            // 学习进度测试视图
            LearningProgressTestView()
        }
    }
    
    // 顶部区域
    private var topSection: some View {
        HStack {
            // 用户头像 - 导航到个人页面
            NavigationLink(destination: UserProfileView(userViewModel: userViewModel)) {
                Image(systemName: userViewModel.isLoggedIn ? "person.crop.circle.fill" : "person.crop.circle")
                    .font(.system(size: AppTheme.Sizes.largeIcon))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            Spacer()
            
            // 动态问候语
            Text(greetingText)
                .font(AppTheme.Fonts.title2)
                .fontWeight(AppTheme.FontWeights.medium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            // 设置入口
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: AppTheme.Sizes.mediumIcon))
                    .foregroundColor(AppTheme.Colors.primary)
            }
        }
        .padding(AppTheme.Spacing.cardPadding)
//        .background(
//            Rectangle()
//                .fill(Color(UIColor.secondarySystemBackground))
//                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//        )
    }
    
    // 搜索区域
    private var searchSection: some View {
        VStack(spacing: 15) {
//            Text("学习日语")
//                .font(.title)
//                .fontWeight(.bold)
//                .foregroundColor(Color("Primary"))
//                .frame(maxWidth: .infinity, alignment: .leading)
            
            NavigationLink(destination: SearchView(searchViewModel: searchViewModel, hotWordViewModel: hotWordViewModel, initialSearchText: searchText)) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color("Primary"))
                    
                    Text(searchText.isEmpty ? "搜索单词、语法、例句" : searchText)
                        .font(.system(size: 16))
                        .foregroundColor(searchText.isEmpty ? .gray : .primary)
                    
                    Spacer()
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    } else {
                        // 语音输入按钮
                        Button(action: { /* 语音输入功能 */ }) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        // 手写识别按钮
                        Button(action: { /* 手写识别功能 */ }) {
                            Image(systemName: "pencil")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                .padding(AppTheme.Spacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .fill(AppTheme.Colors.secondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .stroke(AppTheme.Colors.primaryLightest, lineWidth: AppTheme.Borders.thin)
                )
            }
        }
        .padding(.top, 10)
    }
    
    // 学习建议卡片
    private var learningRecommendationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
                .fill(themeGradient)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("今日推荐")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(Color.white.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("N3语法: 〜ようになる")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("表示状态变化或能力获得的表达")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("例: 我能说日语了。")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
        .frame(height: AppTheme.Sizes.recommendationCardHeight)
        .shadow(color: AppTheme.Shadows.large.color, radius: AppTheme.Shadows.large.radius, x: AppTheme.Shadows.large.x, y: AppTheme.Shadows.large.y)
    }
    
    // 学习进度卡片
    private var learningProgressCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
                .fill(AppTheme.Colors.secondaryBackground)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("学习进度")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                    
                    NavigationLink(destination: LearningGoalSettingsView()) {
                        Text("设置目标")
                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.vertical, AppTheme.Spacing.tiny)
                            .background(
                                Capsule()
                                    .stroke(AppTheme.Colors.primaryLighter, lineWidth: AppTheme.Borders.thin)
                            )
                    }
                }
                
                HStack(spacing: 32) {
                    // 单词学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(learningGoal.wordProgressPercentage))
                                .stroke(Color("Primary"), lineWidth: 4)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(learningGoal.wordProgressPercentage * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.bottom, 8)
                        
                        Text("单词 \(learningGoal.wordProgress)/\(learningGoal.wordGoal)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 语法学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(learningGoal.grammarProgressPercentage))
                                .stroke(Color("Primary"), lineWidth: 4)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(learningGoal.grammarProgressPercentage * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.bottom, 8)
                        
                        Text("语法 \(learningGoal.grammarProgress)/\(learningGoal.grammarGoal)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 阅读学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(learningGoal.readingProgressPercentage))
                                .stroke(Color("Primary"), lineWidth: 4)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(learningGoal.readingProgressPercentage * 100))%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        .padding(.bottom, 8)
                        
                        Text("阅读 \(learningGoal.readingProgress)/\(learningGoal.readingGoal)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
        .frame(height: AppTheme.Sizes.progressCardHeight)
        .shadow(color: AppTheme.Shadows.medium.color, radius: AppTheme.Shadows.medium.radius, x: AppTheme.Shadows.medium.x, y: AppTheme.Shadows.medium.y)
    }
    
    // 最近查询词汇
    private var recentSearchesCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
                .fill(AppTheme.Colors.secondaryBackground)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("最近搜索")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                    
                    NavigationLink(destination: SearchView(searchViewModel: searchViewModel, hotWordViewModel: hotWordViewModel)) {
                        Text("全部")
                            .font(.caption)
                            .foregroundColor(Color("Primary"))
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(recentSearches, id: \.self) { word in
                            NavigationLink(destination: SearchView(searchViewModel: searchViewModel, hotWordViewModel: hotWordViewModel, initialSearchText: word)) {
                                Text(word)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(UIColor.systemBackground))
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color("Primary").opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
        .frame(height: AppTheme.Sizes.searchCardHeight)
        .shadow(color: AppTheme.Shadows.medium.color, radius: AppTheme.Shadows.medium.radius, x: AppTheme.Shadows.medium.x, y: AppTheme.Shadows.medium.y)
    }
    
    // 收藏夹数据
    @State private var userFolders: [(String, String, Int)] = [] // (id, name, itemCount)
    @State private var isFoldersLoading = false
    @State private var folderErrorMessage: String? = nil
    private let favoriteService = FavoriteService(favoriteRepository: FavoriteDataRepository())
    
    // 加载用户收藏夹数据
    private func loadUserFolders() {
        isFoldersLoading = true
        folderErrorMessage = nil
        
        favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isFoldersLoading = false
                    if case .failure(let error) = completion {
                        self.folderErrorMessage = "加载收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { folderSummaries in
                    // 更新收藏夹数据
                    self.userFolders = folderSummaries.map { ($0.id, $0.name, $0.itemCount) }
                }
            )
            .store(in: &cancellables)
    }
    
    // 收藏夹快速访问
    private var favoritesCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
                .fill(AppTheme.Colors.secondaryBackground)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("收藏夹")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                    
                    NavigationLink(destination: FavoritesView(
                        favoriteViewModel: DetailViewModel(
                            dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                            favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: "" // #warning 补充逻辑
                        )
                    )) {
                        VStack {
                            Text("全部")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                
                if userViewModel.isLoggedIn {
                    if isFoldersLoading {
                        // 加载中状态
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.0)
                            Spacer()
                        }
                        .frame(height: 100)
                    } else if let error = folderErrorMessage {
                        // 错误状态
                        VStack(spacing: 10) {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { loadUserFolders() }) {
                                Text("重试")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color("Primary")))
                            }
                        }
                        .frame(height: 100)
                    } else if userFolders.isEmpty {
                        // 空状态
                        HStack {
//                            Text("暂无收藏夹")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
                            Spacer()
                            NavigationLink(destination: FavoritesView(
                                favoriteViewModel: DetailViewModel(
                                    dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                                    favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: "1989103009"
                                )
                            )) {
                                Text("创建收藏夹")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color("Primary")))
                            }
                            Spacer()
                        }
//                        .frame(height: 100)
                    } else {
                        // 显示收藏夹
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                            ForEach(userFolders, id: \.0) { folder in
                                NavigationLink(destination: FavoritesView(
                                    favoriteViewModel: DetailViewModel(
                                        dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                                        favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: ""
                                    ),
                                    initialFolderId: folder.0 // 传递收藏夹ID
                                )) {
                                    HStack {
                                        Text(folder.1) // 文件夹名称
                                            .font(.system(size: 16))
                                            .foregroundColor(AppTheme.Colors.primary)
                                        
                                        Spacer()
                                        
                                        Text("\(folder.2)")
                                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.Colors.primaryLight)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(Color("Primary").opacity(0.1))
                                            )
                                        
                                        Image(systemName: "chevron.right")
                                            .font(AppTheme.Fonts.caption)
                            .foregroundColor(AppTheme.Colors.primaryLight)
                                    }
                                    .padding(AppTheme.Spacing.cardPadding)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.systemBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color("Primary").opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                } else {
                    Button(action: { /* 登录操作 */ }) {
                        Text("登录以显示收藏内容")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(AppTheme.Spacing.cardPadding)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("Primary"))
                            )
                    }
                }
            }
            .padding(AppTheme.Spacing.cardPadding)
        }
//        .frame(height: userViewModel.isLoggedIn ? 220 : 150)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // 浮动学习中心按钮
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // 学习进度测试按钮（长按触发）
                Button(action: {
                    /* 打开学习中心 */
                    isShowWordDetailView.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(themeGradient)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color("Primary").opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .onEnded { _ in
                            // 长按打开学习进度测试视图
                            isShowWordDetailView = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isShowProgressTestView = true
                            }
                        }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// 学习建议卡片

// 学习建议卡片
private var learningTipsCard: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(UIColor.secondarySystemBackground))
        
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(AppTheme.Fonts.title2)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("学习提示")
                    .font(AppTheme.Fonts.title3)
                    .fontWeight(AppTheme.FontWeights.bold)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("每天15分钟的学习让你进步")
                    .font(.headline)
                    .foregroundColor(Color("Primary"))
                
                Text("坚持就是力量！定期复习很重要。")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 5)
        }
        .padding(AppTheme.Spacing.cardPadding)
    }
    .frame(height: 130)
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
}

// 预览
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
        let userService = UserService(userRepository: UserAuthDataRepository())
        let hotWordService = HotWordService(hotWordRepository: HotWordDataRepository())
        
        NavigationView {
            HomeView(
                searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
                userViewModel: UserViewModel(userService: userService), hotWordViewModel: HotWordViewModel(hotWordService: hotWordService)
            )
        }
    }
}
