//
//  UserProfileView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct UserProfileView: View {
    // MARK: - 属性
    @ObservedObject var userViewModel: UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var animateGradient = false
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var selectedTab = 0
    @State private var showWordDetail = false
    @State private var selectedWordId: String? = nil
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // 标签选项
    private let tabs = ["收藏", "历史", "成就"]
    
    // 模拟数据 - 实际应用中应从ViewModel获取
    private let learningStats = [
        ("学习天数", "42", "calendar"),
        ("掌握单词", "328", "checkmark.circle"),
        ("收藏单词", "156", "star.fill")
    ]
    
    private let achievements = [
        ("初学者", "完成首次学习", "graduationcap.fill", true),
        ("勤奋学习", "连续学习7天", "flame.fill", true),
        ("词汇达人", "掌握100个单词", "text.book.closed.fill", true),
        ("语法专家", "完成所有语法课程", "doc.text.fill", false),
        ("会话高手", "完成10次对话练习", "bubble.left.and.bubble.right.fill", false)
    ]
    
    // 模拟收藏单词数据
    private let favoriteWords = [
        ("こんにちは", "你好", "konnichiwa", "1"),
        ("ありがとう", "谢谢", "arigatou", "2"),
        ("さようなら", "再见", "sayounara", "3"),
        ("お願いします", "拜托了", "onegaishimasu", "4"),
        ("すみません", "对不起/打扰了", "sumimasen", "5")
    ]
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景层
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 用户信息卡片
                        userInfoCard
                        
                        // 学习统计卡片
                        learningStatsCard
                        
                        // 标签选择器
                        tabSelector
                        
                        // 标签内容
                        tabContent
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            
            // 加载用户数据
            userViewModel.loadUserProfile()
        }
        .sheet(isPresented: $showEditProfile) {
            // 编辑个人资料视图（占位）
            Text("编辑个人资料")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showSettings) {
            // 设置视图（占位）
            if #available(iOS 16.4, *) {
                settingsView
                    .presentationCompactAdaptation(.fullScreenCover)
            } else {
                settingsView
            }
        }
        .sheet(isPresented: $showWordDetail) {
            // 单词详情页面
            if let wordId = selectedWordId {
                WordDetailView(
                    detailViewModel: DetailViewModel(
                        dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                        favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: wordId
                    )
                )
            }
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
            Text("个人中心")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            // 设置按钮
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
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
    
    // MARK: - 用户信息卡片
    private var userInfoCard: some View {
        ZStack {
            // 背景渐变
            RoundedRectangle(cornerRadius: 20)
                .fill(themeGradient)
            
            // 背景装饰元素
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 150)
                .offset(x: 100, y: -50)
                .blur(radius: 15)
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .offset(x: -100, y: 50)
                .blur(radius: 10)
            
            // 内容
            VStack(spacing: 20) {
                // 用户头像和名称
                VStack(spacing: 15) {
                    // 头像
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: userViewModel.isLoggedIn ? "person.crop.circle.fill" : "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(AppTheme.Colors.primary)
                        
                        // 头像框装饰
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 100, height: 100)
                    }
                    
                    // 用户名和等级
                    VStack(spacing: 5) {
                        Text(userViewModel.userProfile?.nickname ?? "未登录")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        HStack {
                            // 等级标签
                            Text("Lv.3 初级学习者")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                }
                
                // 编辑资料按钮
                if userViewModel.isLoggedIn {
                    Button(action: { showEditProfile = true }) {
                        Text("编辑资料")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                } else {
                    Button(action: { userViewModel.signInWithApple() }) {
                        Text("登录")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                }
            }
            .padding(25)
        }
        .frame(height: 280)
        .shadow(color: AppTheme.Colors.primaryLightest, radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 学习统计卡片
    private var learningStatsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习统计")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 15) {
                ForEach(learningStats, id: \.0) { stat in
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.primaryLightest)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: stat.2)
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                        
                        Text(stat.1)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(stat.0)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 标签选择器
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? AppTheme.Colors.primary : .secondary)
                        
                        // 下划线指示器
                        Rectangle()
                            .fill(selectedTab == index ? AppTheme.Colors.primary : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 5)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - 标签内容
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                // 收藏内容
                favoritesContent
            case 1:
                // 历史内容
                historyContent
            case 2:
                // 成就内容
                achievementsContent
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - 收藏内容
    private var favoritesContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("收藏单词")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink(destination: FavoritesView(
                    favoriteViewModel: DetailViewModel(
                        dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                        favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: ""
                    )
                )) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            if favoriteWords.isEmpty {
                emptyStateView(message: "暂无收藏单词", icon: "star.slash")
            } else {
                VStack(spacing: 12) {
                    ForEach(favoriteWords.prefix(3), id: \.0) { word in
                        Button(action: {
                            selectedWordId = word.3
                            showWordDetail = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(word.0)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(word.2)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(word.1)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 历史内容
    private var historyContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("学习历史")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { /* 查看全部 */ }) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            // 学习曲线图表
            learningChart
                .frame(height: 200)
                .padding(.vertical, 10)
            
            // 最近学习记录
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("学习了20个单词")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Text("2025年4月(6-index)日 20:30")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("+10分")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 成就内容
    private var achievementsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("学习成就")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 成就进度
            HStack {
                Text("已获得 3/5 个成就")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("60%")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.primary)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(AppTheme.Colors.primary)
                        .frame(width: geometry.size.width * 0.6, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .padding(.bottom, 10)
            
            // 成就列表
            VStack(spacing: 12) {
                ForEach(achievements, id: \.0) { achievement in
                    HStack {
                        // 成就图标
                        ZStack {
                            Circle()
                                .fill(achievement.3 ? AppTheme.Colors.primary : Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: achievement.2)
                                .font(.system(size: 24))
                                .foregroundColor(achievement.3 ? .white : .gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(achievement.0)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(achievement.3 ? .primary : .secondary)
                            
                            Text(achievement.1)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if achievement.3 {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 学习曲线图表
    private var learningChart: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    let height = [0.3, 0.5, 0.7, 0.4, 0.8, 0.6, 0.9][index]
                    
                    VStack(spacing: 8) {
                        // 柱状图
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLighter]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 150 * height)
                            .cornerRadius(8)
                        
                        // 日期标签
                        Text("4/\(index+1)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // 图表说明
            HStack {
                Circle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: 8, height: 8)
                
                Text("每日学习单词数")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("本周平均: 25词/天")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - 空状态视图
    private func emptyStateView(message: String, icon: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - 设置视图
    private var settingsView: some View {
        NavigationView {
            List {
                Section(header: Text("外观")) {
                    Toggle("深色模式", isOn: .constant(userViewModel.userSettings.darkMode))
                    
                    HStack {
                        Text("字体大小")
                        Spacer()
                        Text("(userViewModel.userSettings.fontSize)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("数据")) {
                    Toggle("自动同步", isOn: .constant(userViewModel.userSettings.autoSync))
                    
                    Button(action: { /* 同步数据 */ }) {
                        Text("立即同步")
                    }
                    
                    Button(action: { /* 清除缓存 */ }) {
                        Text("清除缓存")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("账户")) {
                    if userViewModel.isLoggedIn {
                        Button(action: { userViewModel.signOut() }) {
                            Text("退出登录")
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { userViewModel.signInWithApple() }) {
                            Text("登录")
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { /* 隐私政策 */ }) {
                        Text("隐私政策")
                    }
                    
                    Button(action: { /* 用户协议 */ }) {
                        Text("用户协议")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("完成") {
                showSettings = false
            })
        }
    }
}

// MARK: - 预览
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            userViewModel: UserViewModel(
                userService: UserService(userRepository: UserAuthDataRepository())
            )
        )
    }
}

// MARK: - 扩展
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        return Path(path.cgPath)
//    }
//}
