//
//  SearchView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct SearchView: View {
    // MARK: - 属性
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var hotWordViewModel: HotWordViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var showVoiceInput = false
    @State private var showHandwritingInput = false
    @State private var selectedSearchType: SearchTypeViewModel = .auto
    @State private var showFilterOptions = false
    @State private var animateGradient = false
    @State private var selectedWordId: String? = nil
    @State private var showWordDetail = false
    
    // 使用计算属性获取ViewModel的搜索状态
    private var isSearching: Bool {
        return searchViewModel.isSearching
    }
    
    // 初始搜索文本，用于从HomeView传递
    var initialSearchText: String = ""
    
    // 搜索类型选项
    private let searchTypes: [(type: SearchTypeViewModel, name: String, icon: String)] = [
        (.auto, "自动", "sparkles"),
        (.word, "单词", "character"),
        (.reading, "读音", "textformat.alt"),
        (.meaning, "释义", "text.book.closed")
    ]
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // MARK: - 私有方法
    private func loadSearch() {
        if !searchText.isEmpty {
            searchViewModel.searchQuery = searchText
            searchViewModel.searchType = selectedSearchType
            searchViewModel.search()
        }
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
                
                // 搜索区域
                searchArea
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                
                // 搜索结果或历史记录
                if searchText.isEmpty {
                    // 历史记录和建议
                    historyAndSuggestionsView
                } else if isSearching {
                    // 加载中
                    loadingView
                } else if let error = searchViewModel.errorMessage {
                    // 错误信息
                    errorView(message: error)
                } else if searchViewModel.searchResults.isEmpty {
                    // 无结果
                    emptyResultsView
                } else {
                    // 搜索结果
                    searchResultsView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
//            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
//                animateGradient.toggle()
//            }
            
            // 如果有初始搜索文本，则自动执行搜索
            if !initialSearchText.isEmpty {
                searchText = initialSearchText
                loadSearch()
            }
        }
        .sheet(isPresented: $showVoiceInput) {
            // 语音输入视图（占位）
            Text("语音输入功能")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showHandwritingInput) {
            // 手写输入视图（占位）
            Text("手写输入功能")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showWordDetail) {
            // 单词详情页面
            if let wordId = selectedWordId {
                let detailVM = DetailViewModel(
                    dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                    favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: wordId
                )
                
                if #available(iOS 16.4, *) {
                    WordDetailView(
                        detailViewModel: detailVM
                    )
                    .presentationCompactAdaptation(.fullScreenCover)
                } else {
                    WordDetailView(
                        detailViewModel: detailVM
                    )
                }
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
            Text("搜索查词")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            // 清除历史按钮
            Button(action: { searchViewModel.clearHistory() }) {
                Image(systemName: "trash")
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
    
    // MARK: - 搜索区域
    private var searchArea: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack(spacing: 12) {
                // 搜索图标
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.Colors.primary)
                
                // 搜索输入框
                TextField("搜索日语单词、短语或例句", text: $searchText)
                    .font(.system(size: 16))
                    .onChange(of: searchText, perform: { newValue in
                        loadSearch()
                    })
                    .onSubmit {
                        loadSearch()
                    }
                
                // 清除按钮
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        searchViewModel.clearSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                } else {
                    // 语音输入按钮
                    Button(action: { showVoiceInput = true }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    // 手写识别按钮
                    Button(action: { showHandwritingInput = true }) {
                        Image(systemName: "scribble")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            
            // 搜索类型选择器
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(searchTypes, id: \.type) { searchType in
                        Button(action: {
                            selectedSearchType = searchType.type
                            loadSearch()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: searchType.icon)
                                    .font(.system(size: 12))
                                Text(searchType.name)
                                    .font(.system(size: 14))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundColor(selectedSearchType == searchType.type ? .white : AppTheme.Colors.primary)
                            .background(
                                Capsule()
                                    .fill(selectedSearchType == searchType.type ? AppTheme.Colors.primary : AppTheme.Colors.primaryLightest)
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - 历史记录和建议视图
    private var historyAndSuggestionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 搜索建议卡片
                if !searchViewModel.suggestions.isEmpty {
                    suggestionsCard
                }
                
                // 历史记录卡片
                if !searchViewModel.searchHistory.isEmpty {
                    historyCard
                }
                
                // 热门搜索卡片（模拟数据）
                trendingSearchesCard
                
                // 学习提示卡片
                learningTipsCard
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - 搜索建议卡片
    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("搜索建议")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(searchViewModel.suggestions, id: \.self) { suggestion in
                Button(action: {
                    searchText = suggestion
                    loadSearch()
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(suggestion)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    .padding(.vertical, 8)
                }
                
                if suggestion != searchViewModel.suggestions.last {
                    Divider()
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
    
    // MARK: - 历史记录卡片
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("最近搜索")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { searchViewModel.clearHistory() }) {
                    Text("清除")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            ForEach(searchViewModel.searchHistory.prefix(5), id: \.id) { historyItem in
                Button(action: {
                    searchText = historyItem.word
                    loadSearch()
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(historyItem.word)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatDate(historyItem.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
                
                if historyItem.id != searchViewModel.searchHistory.prefix(5).last?.id {
                    Divider()
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
    
    // MARK: - 热门搜索卡片
    private var trendingSearchesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("热门搜索")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // 热门搜索标签云
//            FlowLayout(spacing: 2) {
//                // 模拟数据
//                let hotArr = ["こんにちは", "ありがとう", "日本語", "勉強", "学校", "先生", "友達", "美味しい", "楽しい"]
//                ForEach(hotArr, id: \.self) { word in
//                    Button(action: {
//                        searchText = word
//                        searchViewModel.searchQuery = searchText
//                        searchViewModel.search()
//                    }) {
//                        Text(word)
//                            .font(.system(size: 14))
//                            .padding(.horizontal, 8)
//                            .padding(.vertical, 8)
//                            .background(
//                                Capsule()
//                                    .fill(AppTheme.Colors.primaryLightest)
//                            )
//                            .foregroundColor(AppTheme.Colors.primary)
//                    }
//                }
//            }
//            .frame(minHeight: 150)
            
            WordCloudView(words: hotWordViewModel.hotWords, shape: .ellipse, tapItem: { text in
                self.searchText = text
                loadSearch()
            })
//            .frame(width: .infinity, height: 170)
                .frame(width: 300, height: 160)
        }
        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(UIColor.secondarySystemBackground))
//        )
//        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 学习提示卡片
    private var learningTipsCard: some View {
        ZStack {
            // 背景渐变
            RoundedRectangle(cornerRadius: 16)
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
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("学习小贴士")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("搜索时可以使用日语假名、汉字或中文进行查询。尝试使用不同的搜索类型以获得更精确的结果。")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: { /* 学习更多 */ }) {
                    Text("了解更多搜索技巧")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.top, 5)
            }
            .padding(20)
        }
        .frame(height: 200)
        .shadow(color: AppTheme.Colors.primaryLightest, radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 搜索结果视图
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(searchViewModel.searchResults, id: \.id) { result in
                    wordResultCard(result)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWordId = result.id
                            searchViewModel.selectWord(id: result.id)
                            // 确保在显示详情页面前已设置好ID
                            DispatchQueue.main.async {
                                showWordDetail = true
                            }
                        }
                }
                
                // 加载更多按钮
                if !searchViewModel.searchResults.isEmpty {
                    Button(action: { searchViewModel.loadMoreResults() }) {
                        if searchViewModel.isSearching {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .frame(height: 30)
                        } else {
                            Text("加载更多结果")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.primary)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    
    // MARK: - 单词结果卡片
    private func wordResultCard(_ result: WordSummaryViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // 单词和读音
                VStack(alignment: .leading, spacing: 5) {
                    Text(result.word)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(result.reading)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 词性标签
                Text(result.partOfSpeech)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.primaryLightest)
                    )
            }
            
            // 分隔线
            Divider()
            
            // 简要释义
            Text(result.briefMeaning)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // 查看详情按钮
            HStack {
                Spacer()
                
                Button(action: {
                    selectedWordId = result.id
                    searchViewModel.selectWord(id: result.id)
                    // 确保在显示详情页面前已设置好ID
                    DispatchQueue.main.async {
                        showWordDetail = true
                    }
                }) {
                    HStack(spacing: 5) {
                        Text("查看详情")
                            .font(.system(size: 14, weight: .medium))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppTheme.Colors.primary)
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
    
    // MARK: - 加载中视图
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("正在搜索...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 错误视图
    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("搜索出错")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                searchViewModel.search()
            }) {
                Text("重试")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.primary)
                    )
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 无结果视图
    private var emptyResultsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.primaryLight)
            
            Text("未找到结果")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("尝试使用不同的关键词或搜索类型")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { searchText = "" }) {
                Text("返回")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(AppTheme.Colors.primary)
                    )
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 辅助函数
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - FlowLayout 组件
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            content()
                .padding(.all, spacing)
                .alignmentGuide(.leading) { dimension in
                    if width + dimension.width > geometry.size.width {
                        width = 0
                        height -= dimension.height
                    }
                    let result = width
                    if width != 0 {
                        width -= spacing
                    }
                    width += dimension.width + spacing
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if width == 0 {
                        height -= spacing
                    }
                    return result
                }
        }
        .frame(width: geometry.size.width, height: height)
    }
}

// MARK: - 预览
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(searchViewModel: SearchViewModel(dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository())), hotWordViewModel: HotWordViewModel(hotWordService: HotWordService(hotWordRepository: HotWordDataRepository())))
    }
}
