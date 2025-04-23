//
//  WordDetailView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct WordDetailView: View {
    // MARK: - 属性
    @ObservedObject var detailViewModel: DetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showNoteEditor = false
    @State private var noteText = ""
    @State private var animateGradient = false
    @State private var showAllExamples = false
    @State private var showAllDefinitions = false
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 250
    
    // 单词ID参数，用于初始加载
    let wordId: String
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [Color("Primary"), Color("Primary").opacity(0.7)],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // 标签选项
    private let tabs = ["释义", "例句", "相关词"]
    
    // MARK: - 初始化
    init(detailViewModel: DetailViewModel, wordId: String) {
        self.detailViewModel = detailViewModel
        self.wordId = wordId
    }
    
    // MARK: - 视图
    var body: some View {
        ZStack(alignment: .top) {
            // 背景层
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if detailViewModel.isLoading {
                loadingView
            } else if let error = detailViewModel.errorMessage {
                errorView(message: error)
            } else if let details = detailViewModel.wordDetails {
                // 主内容
                VStack(spacing: 0) {
                    // 顶部导航栏 - 半透明效果
                    topNavigationBar
                        .background(
                            Color(UIColor.systemBackground)
                                .opacity(scrollOffset > 30 ? 0.9 : 0)
                                .animation(.easeInOut(duration: 0.3), value: scrollOffset > 30)
                        )
                        .zIndex(1)
                    
                    // 内容区域
                    GeometryReader { geometry in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                // 单词卡片 - 视差效果
                                wordCard(details)
                                    .offset(y: min(0, -scrollOffset * 0.5))
                                    .scaleEffect(
                                        scrollOffset > 0 ? 1 : max(0.8, 1 - scrollOffset.magnitude / 500),
                                        anchor: .center
                                    )
                                    .opacity(scrollOffset > 100 ? 0.3 : 1)
                                    .animation(.easeOut(duration: 0.2), value: scrollOffset)
                                
                                // 内容选项卡
                                tabView
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(25, corners: [.topLeft, .topRight])
                                    .offset(y: -25)
                                
                                // 选项卡内容
                                tabContent(details)
                                    .padding(.top, -15)
                                    .padding(.bottom, 100) // 为浮动按钮留出空间
                            }
                            .background(GeometryReader { proxy -> Color in
                                DispatchQueue.main.async {
                                    scrollOffset = proxy.frame(in: .global).minY - geometry.safeAreaInsets.top
                                }
                                return Color.clear
                            })
                        }
                    }
                }
                
                // 浮动收藏按钮
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            
            // 加载单词详情
            detailViewModel.loadWordDetails(id: wordId)
        }
        .sheet(isPresented: $showNoteEditor) {
            noteEditorView
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            // 返回按钮 - 圆形背景
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("Primary"))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
            
            Spacer()
            
            // 页面标题 - 动态显示
            if scrollOffset < -50 {
                Text("单词详情")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("Primary"))
                    .transition(.opacity)
                    .animation(.easeInOut, value: scrollOffset < -50)
            }
            
            Spacer()
            
            // 分享按钮 - 圆形背景
            Button(action: { /* 分享功能 */ }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color("Primary"))
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
    
    // MARK: - 单词卡片
    private func wordCard(_ details: WordDetailsViewModel) -> some View {
        ZStack {
            // 背景渐变
            themeGradient
                .ignoresSafeArea()
            
            // 背景装饰元素
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .offset(x: 150, y: -100)
                .blur(radius: 20)
            
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 150, height: 150)
                .offset(x: -150, y: 50)
                .blur(radius: 15)
            
            // 内容
            VStack(spacing: 25) {
                // 单词和读音
                VStack(spacing: 10) {
                    Text(details.word)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                    
                    Text(details.reading)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // 词性标签 - 胶囊形状
                    Text(details.partOfSpeech)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        )
                }
                .padding(.top, 20)
                
                // 发音控制 - 创意布局
                HStack(spacing: 25) {
                    // 慢速发音
                    Button(action: { detailViewModel.playPronunciation(speed: 0.75) }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "tortoise.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Text("慢速")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    // 正常发音 - 突出显示
                    Button(action: { detailViewModel.playPronunciation(speed: 1.0) }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 65, height: 65)
                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text("播放")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 快速发音
                    Button(action: { detailViewModel.playPronunciation(speed: 1.25) }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "hare.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Text("快速")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .padding()
        }
        .frame(height: 280)
    }
    
    // MARK: - 选项卡视图
    private var tabView: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .bold : .regular))
                            .foregroundColor(selectedTab == index ? Color("Primary") : .gray)
                        
                        // 选中指示器
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(Color("Primary"))
                                    .frame(width: 30, height: 4)
                                    .matchedGeometryEffect(id: "TAB", in: namespace)
                            } else {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(width: 30, height: 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 15)
        .padding(.bottom, 5)
    }
    
    // 用于动画过渡的命名空间
    @Namespace private var namespace
    
    // MARK: - 选项卡内容
    private func tabContent(_ details: WordDetailsViewModel) -> some View {
        VStack {
            switch selectedTab {
            case 0:
                // 释义内容
                definitionsContent(details)
                    .transition(.opacity)
            case 1:
                // 例句内容
                examplesContent(details)
                    .transition(.opacity)
            case 2:
                // 相关词汇内容
                relatedWordsContent(details)
                    .transition(.opacity)
            default:
                EmptyView()
            }
            
            // 学习提示卡片 - 所有选项卡都显示
            learningTipsCard
                .padding(.horizontal)
                .padding(.top, 20)
        }
        .animation(.easeInOut, value: selectedTab)
    }
    
    // MARK: - 释义内容
    private func definitionsContent(_ details: WordDetailsViewModel) -> some View {
        VStack(spacing: 20) {
            ForEach(Array(details.definitions.enumerated()), id: \.offset) { index, definition in
                // 释义卡片 - 更现代的设计
                VStack(alignment: .leading, spacing: 12) {
                    // 序号和释义
                    HStack(alignment: .top, spacing: 15) {
                        // 序号圆形背景
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color("Primary"))
                            )
                        
                        // 释义文本
                        Text(definition.meaning)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 注释信息
                    if let notes = definition.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.leading, 43)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 例句内容
    private func examplesContent(_ details: WordDetailsViewModel) -> some View {
        VStack(spacing: 20) {
            ForEach(Array(details.examples.enumerated()), id: \.offset) { index, example in
                // 例句卡片 - 更有层次感的设计
                VStack(alignment: .leading, spacing: 15) {
                    // 日语例句
                    HStack(alignment: .top) {
                        // 序号标签 - 垂直设计
                        VStack {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color("Primary"))
                                )
                            
                            Rectangle()
                                .fill(Color("Primary").opacity(0.3))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        .padding(.top, 5)
                        
                        // 例句文本
                        VStack(alignment: .leading, spacing: 12) {
                            Text(example.sentence)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // 中文翻译
                            Text(example.translation)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // 播放按钮 - 更现代的设计
                            Button(action: { detailViewModel.playPronunciation(speed: 1.0) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .font(.system(size: 12))
                                    Text("播放例句")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(Color("Primary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("Primary").opacity(0.1))
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.leading, 10)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 相关词汇内容
    private func relatedWordsContent(_ details: WordDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if details.relatedWords.isEmpty {
                // 无相关词汇时显示
                VStack(spacing: 15) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.5))
                    
                    Text("暂无相关词汇")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            } else {
                // 相关词汇网格布局
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(details.relatedWords) { relatedWord in
                        Button(action: {
                            // 加载相关词汇的详情
                            detailViewModel.loadWordDetails(id: relatedWord.id)
                        }) {
                            // 相关词汇卡片 - 更现代的设计
                            VStack(alignment: .leading, spacing: 8) {
                                Text(relatedWord.word)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(relatedWord.reading)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Divider()
                                    .padding(.vertical, 4)
                                
                                Text(relatedWord.briefMeaning)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                                    .frame(height: 40, alignment: .top)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("Primary").opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 学习提示卡片
    private var learningTipsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            // 标题区域 - 更有创意的设计
            HStack {
                // 灯泡图标带背景
                ZStack {
                    Circle()
                        .fill(Color("Primary").opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color("Primary"))
                }
                
                Text("学习提示")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("Primary"))
                
                Spacer()
                
                // 添加一个小装饰
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color("Primary").opacity(0.7))
            }
            
            // 提示内容
            VStack(alignment: .leading, spacing: 12) {
                Text("记忆技巧")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("Primary"))
                
                Text("尝试将这个单词与相似的词汇联系起来，或者创建一个包含这个单词的短句来加深记忆。")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }
    
    // MARK: - 浮动收藏按钮
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // 收藏按钮 - 更有创意的设计
                Button(action: { detailViewModel.toggleFavorite() }) {
                    ZStack {
                        // 主按钮背景
                        Circle()
                            .fill(themeGradient)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color("Primary").opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // 星星图标
                        Image(systemName: detailViewModel.isFavorited ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                        
                        // 动画效果 - 收藏时显示
                        if detailViewModel.isFavorited {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                .frame(width: 70, height: 70)
                                .scaleEffect(animateGradient ? 1.1 : 1.0)
                        }
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                
                // 添加笔记按钮 - 小一些的辅助按钮
                Button(action: { showNoteEditor = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 45, height: 45)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                        
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18))
                            .foregroundColor(Color("Primary"))
                    }
                }
                .offset(x: -70, y: -15)
                .opacity(scrollOffset < 100 ? 1 : 0)
                .animation(.easeInOut, value: scrollOffset < 100)
            }
        }
    }
    
    // MARK: - 加载中视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 自定义加载动画
            ZStack {
                Circle()
                    .stroke(Color("Primary").opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color("Primary"), lineWidth: 8)
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: animateGradient ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: animateGradient)
            }
            
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(Color("Primary"))
            
            Spacer()
        }
        .onAppear {
            animateGradient = true
        }
    }
    
    // MARK: - 错误视图
    private func errorView(message: String) -> some View {
        VStack(spacing: 25) {
            Spacer()
            
            // 错误图标
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .padding()
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 120, height: 120)
                )
            
            Text("加载失败")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.gray)
            
            // 重试按钮
            Button(action: { detailViewModel.loadWordDetails(id: wordId) }) {
                Text("重试")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color("Primary"))
                    )
                    .shadow(color: Color("Primary").opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - 笔记编辑器视图
    private var noteEditorView: some View {
        VStack(spacing: 20) {
            // 顶部栏
            HStack {
                Button(action: { showNoteEditor = false }) {
                    Text("取消")
                        .foregroundColor(Color("Primary"))
                }
                
                Spacer()
                
                Text("添加笔记")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    detailViewModel.addNote(note: noteText)
                    showNoteEditor = false
                }) {
                    Text("保存")
                        .foregroundColor(Color("Primary"))
                        .fontWeight(.bold)
                }
            }
            .padding()
            
            // 编辑区域
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text("在这里添加你的学习笔记...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                
                TextEditor(text: $noteText)
                    .padding(5)
                    .background(Color.clear)
            }
            .padding()
            .frame(minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 预览
struct WordDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
        let favoriteService = FavoriteService(favoriteRepository: FavoriteDataRepository())
        
        WordDetailView(
            detailViewModel: DetailViewModel(
                dictionaryService: dictionaryService,
                favoriteService: favoriteService
            ),
            wordId: "198922179"
        )
    }
}
