//
//  HomeView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var userViewModel: UserViewModel
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var selectedTab = 0
    @State private var animateGradient = false
    
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
        LinearGradient(
            colors: [Color("Primary"), Color("Primary").opacity(0.7)],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // 背景层
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部区域
                topSection
                    .ignoresSafeArea()
                
                // 主内容区域
                ScrollView {
                    VStack(spacing: 25) {
                        // 搜索区域
                        searchSection
                        
                        // 学习建议卡片
                        learningRecommendationCard
                        
                        // 学习进度卡片
                        learningProgressCard
                        
                        // 最近查询词汇
                        recentSearchesCard
                        
                        // 收藏夹快速访问
                        favoritesCard
                        
                        // 学习建议
                        learningTipsCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80) // 为浮动按钮留出空间
                }
            }
            
            // 浮动学习中心按钮
            floatingActionButton
        }
        .onAppear {
            // 启动渐变动画
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    // 顶部区域
    private var topSection: some View {
        HStack {
            // 用户头像
            Button(action: { /* 用户资料操作 */ }) {
                Image(systemName: userViewModel.isLoggedIn ? "person.crop.circle.fill" : "person.crop.circle")
                    .font(.system(size: 28))
                    .foregroundColor(Color("Primary"))
            }
            
            Spacer()
            
            // 动态问候语
            Text(greetingText)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color("Primary"))
            
            Spacer()
            
            // 设置入口
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22))
                    .foregroundColor(Color("Primary"))
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // 搜索区域
    private var searchSection: some View {
        VStack(spacing: 15) {
            Text("学习日语")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color("Primary"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color("Primary"))
                
                TextField("搜索单词、语法、例句", text: $searchText)
                    .font(.system(size: 16))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                } else {
                    // 语音输入按钮
                    Button(action: { /* 语音输入功能 */ }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(Color("Primary"))
                    }
                    
                    // 手写识别按钮
                    Button(action: { /* 手写识别功能 */ }) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color("Primary"))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color("Primary").opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, 10)
    }
    
    // 学习建议卡片
    private var learningRecommendationCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(themeGradient)
            
            VStack(alignment: .leading, spacing: 15) {
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
            .padding()
        }
        .frame(height: 180)
        .shadow(color: Color("Primary").opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // 学习进度卡片
    private var learningProgressCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("学习进度")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    // 单词学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: 0.65)
                                .stroke(Color("Primary"), lineWidth: 8)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("65%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("Primary"))
                        }
                        
                        Text("单词")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 语法学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: 0.4)
                                .stroke(Color("Primary"), lineWidth: 8)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("40%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("Primary"))
                        }
                        
                        Text("语法")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // 阅读学习进度
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 70, height: 70)
                            
                            Circle()
                                .trim(from: 0, to: 0.25)
                                .stroke(Color("Primary"), lineWidth: 8)
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(-90))
                            
                            Text("25%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("Primary"))
                        }
                        
                        Text("阅读")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(height: 200)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // 最近查询词汇
    private var recentSearchesCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("最近搜索")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                    
                    Button(action: { /* 查看全部 */ }) {
                        Text("全部")
                            .font(.caption)
                            .foregroundColor(Color("Primary"))
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(recentSearches, id: \.self) { word in
                            Button(action: {
                                searchText = word
                                searchViewModel.searchQuery = word
                            }) {
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
            .padding()
        }
        .frame(height: 130)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // 收藏夹快速访问
    private var favoritesCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
            
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(Color("Primary"))
                    
                    Text("收藏夹")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("Primary"))
                    
                    Spacer()
                    
                    Button(action: { /* 查看全部 */ }) {
                        Text("全部")
                            .font(.caption)
                            .foregroundColor(Color("Primary"))
                    }
                }
                
                if userViewModel.isLoggedIn {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 2), spacing: 15) {
                        ForEach(["日常对话", "JLPT N3", "拟态语", "旅行"], id: \.self) { category in
                            Button(action: { /* 查看分类 */ }) {
                                HStack {
                                    Text(category)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color("Primary"))
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color("Primary").opacity(0.7))
                                }
                                .padding()
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
                } else {
                    Button(action: { /* 登录操作 */ }) {
                        Text("登录以显示收藏内容")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("Primary"))
                            )
                    }
                }
            }
            .padding()
        }
        .frame(height: userViewModel.isLoggedIn ? 220 : 150)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // 浮动学习中心按钮
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: { /* 打开学习中心 */ }) {
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
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// 学习建议卡片
private var learningTipsCard: some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(UIColor.secondarySystemBackground))
        
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(Color("Primary"))
                
                Text("学习提示")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Primary"))
                
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
        .padding()
    }
    .frame(height: 130)
    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
}

// 预览
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
        let userService = UserService(userRepository: UserAuthDataRepository())
        
        HomeView(
            searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
            userViewModel: UserViewModel(userService: userService)
        )
    }
}
