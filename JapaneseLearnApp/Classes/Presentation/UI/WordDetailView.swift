//
//  WordDetailView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine
import UIKit
import CoreText

struct WordDetailView: View {
    // MARK: - 属性
    @ObservedObject var detailViewModel: DetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showNoteEditor = false
    @State private var showFolderSelection = false
    @State private var noteText = ""
    @State private var animateGradient = false
    @State private var showAllExamples = false
    @State private var showAllDefinitions = false
    @State private var selectedTab = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 250
    
    // 单词ID参数，用于初始加载
//    let wordId: String
    
    // 用于动画过渡的命名空间
    @Namespace private var namespace
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // 标签选项
    private let tabs = ["释义", "例句", "相关词"]
    
    // MARK: - 初始化
    init(detailViewModel: DetailViewModel) {
        self.detailViewModel = detailViewModel
//        self.wordId = wordId
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
                                // 单词卡片 - 修改视差效果，确保初始状态可见
                                wordCard(details)
//                                    .offset(y: min(0, -scrollOffset * 0.1))
//                                    .scaleEffect(
//                                        scrollOffset > 0 ? 1 : max(0.95, 1 - scrollOffset.magnitude / 500),  // 调整最小缩放比例
//                                        anchor: .center
//                                    )
//                                    .opacity(scrollOffset > 120 ? 0.3 : 1)
//                                    .animation(.easeOut(duration: 0.2), value: scrollOffset)
                                
                                // 内容选项卡
                                tabView
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(25, corners: [.topLeft, .topRight])
                                    .offset(y: -25)
                                    .padding(.top, AppTheme.Spacing.tiny)
                                    .padding(.bottom, AppTheme.Spacing.tiny)
                                
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
//                        .overlay(
//                            Text(String(format: "Scroll Offset: %.0f", scrollOffset))
//                                .padding()
//                                .background(.ultraThinMaterial)
//                                .cornerRadius(12)
//                                .padding(),
//                            alignment: .topTrailing
//                        )
                    }
                }
                
                // 浮动收藏按钮
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
//            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
//                animateGradient.toggle()
//            }
        }
        // 使用task修饰符确保在视图出现前就开始加载数据
        .task {
            // 加载单词详情
//            detailViewModel.loadWordDetails(id: wordId)
        }
        .sheet(isPresented: $showNoteEditor) {
            noteEditorView
        }
        
        // 收藏夹选择视图
        .sheet(isPresented: $showFolderSelection) {
            FolderSelectionView(
                viewModel: detailViewModel,
                wordId: detailViewModel.wordId
            )
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            // 返回按钮 - 圆形背景
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
            
            // 页面标题 - 动态显示
            if scrollOffset < 67 {
                Text(detailViewModel.wordDetails?.word ?? "")
                    .font(AppTheme.Fonts.title2)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.primary)
                    .transition(.opacity)
                    .animation(.easeInOut, value: scrollOffset < 67)
            }
            
            Spacer()
            
            // 分享按钮 - 圆形背景
            Button(action: { /* 分享功能 */ }) {
                Image(systemName: "square.and.arrow.up")
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
    
    // MARK: - 单词卡片
    private func wordCard(_ details: WordDetailsViewModel) -> some View {
        VStack(spacing: 20) {
            // 单词和读音
            VStack(spacing: 8) {
                Text(details.word)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(details.reading)
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                
                HStack {
                    // 词性标签
                    Text(details.partOfSpeech)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.primaryLightest)
                        )
                    
                    // 发音按钮
                    Button(action: { detailViewModel.playPronunciation(speed: 1.0) }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .stroke(AppTheme.Colors.primary, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
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
                            .foregroundColor(selectedTab == index ? AppTheme.Colors.primary : .gray)
                        
                        // 选中指示器
                        ZStack {
                            if selectedTab == index {
                                Capsule()
                                    .fill(AppTheme.Colors.primary)
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
                                    .fill(AppTheme.Colors.primary)
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
                                        .fill(AppTheme.Colors.primary)
                                )
                            
                            Rectangle()
                                .fill(AppTheme.Colors.primaryLightest)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                        .padding(.top, 5)
                        
                        // 例句文本 - 使用CompleteRichTextView替换普通Text
                        VStack(alignment: .leading, spacing: 12) {
                            // 富文本例句展示
                            CompleteRichTextView(htmlString: example.sentence) { word, lemma, furigana in
                                // 处理单词点击事件
                                print("点击了单词: \(word), 词元: \(lemma), 假名: \(furigana)")
                                // 将点击事件传递给ViewModel处理
                                detailViewModel.handleWordTapped(word: word, lemma: lemma, furigana: furigana)
                            }
//                            .frame(width: 120)
                            .frame(minHeight: 50) // 设置最小高度，允许根据内容自动扩展
//                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(8)
                            
                            // 中文翻译
                            Text(example.translation)
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                            
                            // 播放按钮 - 更现代的设计
                            Button(action: { detailViewModel.playPronunciation(speed: 1.0) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "speaker.wave.1.fill")
                                        .font(.system(size: 12))
                                    Text("播放例句")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.Colors.primaryLightest)
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
                            detailViewModel.loadWordDetails()
                        }) {
                            // 相关词汇卡片 - 更现代的设计
                            VStack(alignment: .leading, spacing: 8) {
                                Text(relatedWord.word)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(relatedWord.reading)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text(relatedWord.briefMeaning)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.Colors.primaryLightest, lineWidth: 1)
                                    )
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
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("学习提示")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.primary)
                
                Spacer()
            }
            
            Text("尝试将这个单词与相似的词汇联系起来，或者创建一个包含这个单词的短句来加深记忆。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 浮动收藏按钮
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // 编辑按钮 - 位置调整
                Button(action: { showNoteEditor = true }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .padding(.trailing, 15)
                
                // 收藏按钮
                Button(action: {
                    if detailViewModel.isFavorited {
                        // 如果已收藏，则取消收藏
                        detailViewModel.toggleFavorite()
                    } else {
                        // 如果未收藏，显示收藏夹选择视图
                        showFolderSelection = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(themeGradient)
                            .frame(width: 56, height: 56)
                            .shadow(color: AppTheme.Colors.primaryLightest, radius: 8, x: 0, y: 3)
                        
                        Image(systemName: detailViewModel.isFavorited ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
//            .offset(y: scrollOffset > 0 ? min(0, -scrollOffset * 0.5) : 0) // 滚动时调整位置
        }
    }
    
    // MARK: - 加载中视图
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 10)
            Spacer()
        }
    }
    
    // MARK: - 错误视图
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("加载失败")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { detailViewModel.loadWordDetails() }) {
                Text("重试")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - 笔记编辑器视图
    private var noteEditorView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { showNoteEditor = false }) {
                    Text("取消")
                        .foregroundColor(AppTheme.Colors.primary)
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
                        .foregroundColor(AppTheme.Colors.primary)
                        .fontWeight(.bold)
                }
            }
            .padding()
            
            TextEditor(text: $noteText)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .frame(minHeight: 200)
            
            Spacer()
        }
        .padding()
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
                favoriteService: favoriteService, wordId: "1989103009"
            )
        )
    }
}
