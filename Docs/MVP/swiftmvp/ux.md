# 日语学习应用高保真原型设计
根据您提供的UIUX规范，我将为您设计一款日语学习应用的高保真原型。我会遵循SwiftUI的最佳实践，并确保代码结构清晰、组件化，同时实现您要求的交互效果。

## 项目结构设计
首先，我们需要建立一个清晰的项目结构，遵循MVVM架构：
```
JapaneseApp/
├── App/
│   └── JapaneseAppApp.swift
├── Models/
│   ├── DictEntry.swift
│   ├── Folder.swift
│   ├── User.swift
│   └── SearchHistory.swift
├── ViewModels/
│   ├── SearchViewModel.swift
│   ├── DetailViewModel.swift
│   ├── FavoriteViewModel.swift
│   └── UserViewModel.swift
├── Views/
│   ├── Components/
│   │   ├── WordCard.swift
│   │   ├── SearchBar.swift
│   │   ├── FloatingLearningCenter.swift
│   │   ├── PronunciationButton.swift
│   │   └── ...
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── ...
│   ├── Search/
│   │   ├── SearchView.swift
│   │   └── ...
│   ├── Detail/
│   │   ├── WordDetailView.swift
│   │   └── ...
│   ├── Favorites/
│   │   ├── FavoritesView.swift
│   │   └── ...
│   └── Settings/
│       ├── SettingsView.swift
│       └── ...
└── Utils/
    ├── Constants.swift
    ├── Extensions.swift
    └── ...
```
## 核心代码实现
### 1. 首先定义颜色和样式常量
### 2. 添加颜色扩展
### 3. 定义模型
### 4. 实现ViewModel
### 5. 实现组件

输出过长，请输入“继续”后获得更多结果。

## JqyModi
复制

删除

继续

## Trae AI
使用了 1 个参考

我将继续为您提供日语学习应用的高保真原型设计代码。接下来我们将实现更多的组件和主要视图。

### 继续实现组件
```swift
import SwiftUI

struct WordCard: View {
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    var isFavorited: Bool = false
    var onTap: () -> Void
    var onFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word)
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(reading)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onFavorite) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .foregroundColor(isFavorited ? AppColors.warning : AppColors.darkGray)
                        .font(.system(size: 20))
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            HStack {
                Text(partOfSpeech)
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.hintText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.lightGray)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(meaning)
                .font(AppFonts.body)
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

struct WordCard_Previews: PreviewProvider {
    static var previews: some View {
        WordCard(
            word: "食べる",
            reading: "たべる",
            meaning: "吃；咽下",
            partOfSpeech: "動詞",
            isFavorited: false,
            onTap: {},
            onFavorite: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
 ```
```

```swift
import SwiftUI

struct FloatingLearningCenter: View {
    @Binding var isExpanded: Bool
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 44, y: UIScreen.main.bounds.height - 120)
    
    var onDictionaryTap: () -> Void
    var onFavoritesTap: () -> Void
    var onLearningTap: () -> Void
    
    var body: some View {
        ZStack {
            // 展开的菜单
            if isExpanded {
                VStack(spacing: 16) {
                    Button(action: onDictionaryTap) {
                        CircleButton(
                            icon: "book.fill",
                            color: AppColors.info,
                            size: 50
                        )
                    }
                    
                    Button(action: onFavoritesTap) {
                        CircleButton(
                            icon: "star.fill",
                            color: AppColors.warning,
                            size: 50
                        )
                    }
                    
                    Button(action: onLearningTap) {
                        CircleButton(
                            icon: "graduationcap.fill",
                            color: AppColors.success,
                            size: 50
                        )
                    }
                }
                .offset(y: -180)
                .opacity(isExpanded ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
            }
            
            // 主按钮
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 16, x: 0, y: 4)
                    
                    Image(systemName: isExpanded ? "xmark" : "lightbulb.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        self.dragOffset = value.translation
                    }
                    .onEnded { value in
                        self.position.x += value.translation.width
                        self.position.y += value.translation.height
                        self.dragOffset = .zero
                        
                        // 边缘吸附
                        let screenWidth = UIScreen.main.bounds.width
                        let screenHeight = UIScreen.main.bounds.height
                        
                        if self.position.x < screenWidth / 2 {
                            self.position.x = 44
                        } else {
                            self.position.x = screenWidth - 44
                        }
                        
                        // 确保不超出屏幕边界
                        self.position.y = max(44, min(self.position.y, screenHeight - 120))
                    }
            )
            .onLongPressGesture(minimumDuration: 0.5) {
                // 长按显示快捷操作
                HapticFeedback.impact(style: .medium)
                // 这里可以实现长按菜单
            }
        }
    }
}

struct CircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 2)
            
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
    }
}

struct HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

struct FloatingLearningCenter_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
            
            FloatingLearningCenter(
                isExpanded: .constant(true),
                onDictionaryTap: {},
                onFavoritesTap: {},
                onLearningTap: {}
            )
        }
    }
}
 ```
```

```swift
import SwiftUI

struct PronunciationButton: View {
    var isPlaying: Bool
    var action: () -> Void
    
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                if isPlaying {
                    // 播放动画
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                            .scaleEffect(animationScale)
                            .opacity(2 - animationScale)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.4),
                                value: animationScale
                            )
                    }
                    .onAppear {
                        animationScale = 2.0
                    }
                }
                
                Image(systemName: isPlaying ? "pause.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primary)
            }
        }
        .buttonPressAnimation()
    }
}

struct PronunciationButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PronunciationButton(isPlaying: false, action: {})
            PronunciationButton(isPlaying: true, action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
 ```

### 实现主要视图
```swift
import SwiftUI

struct HomeView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var isLearningCenterExpanded = false
    @State private var showingSettings = false
    @State private var showingSearch = false
    @State private var showingWordDetail = false
    @State private var selectedWordId: String? = nil
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部区域
                    HStack {
                        Button(action: {
                            // 显示用户信息
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 28))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Spacer()
                        
                        Text(getGreeting())
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 24))
                                .foregroundColor(AppColors.darkGray)
                        }
                    }
                    .padding(.horizontal, AppSpacing.standard)
                    .padding(.top, AppSpacing.standard)
                    .padding(.bottom, AppSpacing.compact)
                    
                    // 搜索区域
                    Button(action: {
                        showingSearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(AppColors.darkGray)
                            
                            Text("搜索日语单词、短语或例句")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.hintText)
                            
                            Spacer()
                            
                            Image(systemName: "mic")
                                .foregroundColor(AppColors.darkGray)
                        }
                        .padding()
                        .background(AppColors.lightGray)
                        .cornerRadius(10)
                        .padding(.horizontal, AppSpacing.standard)
                        .padding(.bottom, AppSpacing.standard)
                    }
                    
                    // 学习流区域
                    VStack(spacing: AppSpacing.standard) {
                        // 每日学习建议
                        DailyLearningCard()
                            .padding(.horizontal, AppSpacing.standard)
                        
                        // 最近查询词汇
                        RecentSearchesSection(
                            items: searchViewModel.searchHistory,
                            onItemTap: { item in
                                selectedWordId = item.id
                                showingWordDetail = true
                            }
                        )
                        
                        // 学习进度卡片
                        LearningProgressCard()
                            .padding(.horizontal, AppSpacing.standard)
                        
                        // 收藏夹快速访问
                        FavoriteFoldersSection()
                            .padding(.bottom, AppSpacing.wide)
                    }
                    .padding(.bottom, 100) // 为浮动按钮留出空间
                }
            }
            .background(Color.white)
            
            // 浮动学习中心
            FloatingLearningCenter(
                isExpanded: $isLearningCenterExpanded,
                onDictionaryTap: {
                    showingSearch = true
                    isLearningCenterExpanded = false
                },
                onFavoritesTap: {
                    // 导航到收藏页面
                    isLearningCenterExpanded = false
                },
                onLearningTap: {
                    // 导航到学习页面
                    isLearningCenterExpanded = false
                }
            )
        }
        .sheet(isPresented: $showingSearch) {
            SearchView(viewModel: searchViewModel)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingWordDetail) {
            if let id = selectedWordId {
                WordDetailView(wordId: id)
            }
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "早上好"
        } else if hour < 18 {
            return "下午好"
        } else {
            return "晚上好"
        }
    }
}

// 每日学习建议卡片
struct DailyLearningCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppColors.primary)
                
                Text("每日学习建议")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Text("查看全部")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.primary)
            }
            
            Divider()
            
            Text("今天建议学习以下内容：")
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondaryText)
            
            HStack(spacing: AppSpacing.compact) {
                ForEach(0..<3) { i in
                    VStack {
                        Text(["食", "勉", "美"][i])
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [AppColors.primary, AppColors.primaryDark]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(8)
                        
                        Text(["食べる", "勉強", "美しい"][i])
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.primaryText)
                    }
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.standard)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 最近搜索区域
struct RecentSearchesSection: View {
    let items: [SearchHistoryItem]
    let onItemTap: (SearchHistoryItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            HStack {
                Text("最近查询")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button(action: {}) {
                    Text("查看全部")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.compact) {
                    ForEach(items) { item in
                        Button(action: {
                            onItemTap(item)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.word)
                                    .font(AppFonts.body)
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(1)
                                
                                Text(item.reading)
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineLimit(1)
                            }
                            .padding(AppSpacing.standard)
                            .frame(width: 120)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.standard)
            }
        }
    }
}

// 学习进度卡片
struct LearningProgressCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(AppColors.accent)
                
                Text("学习进度")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("本周已学习")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("32个单词")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("连续学习")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("5天")
                        .font(AppFonts.title)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.lightGray)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [AppColors.primary, AppColors.accent]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.65, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.top, 8)
        }
        .padding(AppSpacing.standard)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 收藏夹快速访问
struct FavoriteFoldersSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.compact) {
            HStack {
                Text("收藏夹")
                    .font(AppFonts.subtitle)
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button(action: {}) {
                    Text("查看全部")
                        .font(AppFonts.caption)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, AppSpacing.standard)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.compact) {
                    ForEach(Folder.samples) { folder in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(AppColors.primary)
                                
                                Spacer()
                                
                                Text("\(folder.itemCount)")
                                    .font(AppFonts.caption)
                                    .foregroundColor(AppColors.hintText)
                            }
                            
                            Spacer()
                            
                            Text(folder.name)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryText)
                                .lineLimit(1)
                        }
                        .padding(AppSpacing.standard)
                        .frame(width: 140, height: 100)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, AppSpacing.standard)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
 ```
```

```swift
import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingWordDetail = false
    @State private var selectedWordId: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(
                    text: $viewModel.searchQuery,
                    placeholder: "搜索日语单词、短语或例句",
                    onSearch: {
                        viewModel.search()
                    },
                    onClear: {
                        viewModel.clearSearch()
                    }
                )
                .padding(.vertical, 8)
                
                // 搜索类型选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SearchTypeButton(
                            title: "自动",
                            isSelected: viewModel.searchType == .auto,
                            action: { viewModel.searchType = .auto }
                        )
                        
                        SearchTypeButton(
                            title: "单词",
                            isSelected: viewModel.searchType == .word,
                            action: { viewModel.searchType = .word }
                        )
                        
                        SearchTypeButton(
                            title: "读音",
                            isSelected: viewModel.searchType == .reading,
                            action: { viewModel.searchType = .reading }
                        )
                        
                        SearchTypeButton(
                            title: "释义",
                            isSelected: viewModel.searchType == .meaning,
                            action: { viewModel.searchType = .meaning }
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                
                Divider()
                
                if viewModel.isSearching {
                    // 加载指示器
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.5)
                        Text("正在搜索...")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else if !viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty {
                    // 无结果
                    VStack {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.mediumGray)
                        Text("未找到相关结果")
                            .font(AppFonts.subtitle)
                            .foregroundColor(AppColors.secondaryText)
                            .padding(.top, 16)
                        Spacer()
                    }
                } else if !viewModel.searchResults.isEmpty {
                    // 搜索结果
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { result in
                                WordCard(
                                    word: result.word,
                                    reading: result.reading,
                                    meaning: result.briefMeaning,
                                    partOfSpeech: result.partOfSpeech,
                                    onTap: {
                                        selectedWordId = result.id
                                        showingWordDetail = true
                                    },
                                    onFavorite: {
                                        // 收藏操作
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            // 加载更多按钮
                            if viewModel.searchResults.count >= 10 {
                                Button(action: {
                                    viewModel.loadMoreResults()
                                }) {
                                    HStack {
                                        Text("加载更多")
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.primary)
                                        
                                        if viewModel.isSearching {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                                                .scaleEffect(0.8)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                } else {
                    // 搜索历史和建议
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !viewModel.searchHistory.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("搜索历史")
                                            .font(AppFonts.subtitle)
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.clearHistory()
                                        }) {
                                            Text("清除")
                                                .font(AppFonts.caption)
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    
                                    ForEach(viewModel.searchHistory) { item in
                                        Button(action: {
                                            viewModel.searchQuery = item.word
                                            viewModel.search()
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.word)
                                                        .font(AppFonts.body)
                                                        .foregroundColor(AppColors.primaryText)
                                                    
                                                    Text(item.reading)
                                                        .font(AppFonts.caption)
                                                        .foregroundColor(AppColors.secondaryText)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "arrow.up.left")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.darkGray)
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        
                                        if item.id != viewModel.searchHistory.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                                .padding(.horizontal, 16)
                            }
                            
                            if !viewModel.suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("搜索建议")
                                        .font(AppFonts.subtitle)
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            viewModel.searchQuery = suggestion
                                            viewModel.search()
                                        }) {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.darkGray)
                                                
                                                Text(suggestion)
                                                    .font(AppFonts.body)
                                                    .foregroundColor(AppColors.primaryText)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        
                                        if suggestion != viewModel.suggestions.last {
                                            Divider()
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color:
 ```
```

输出过长，请输入“继续”后获得更多结果。

## Trae AI
使用了 1 个参考

uiux_v2.md 131-131

我将继续为您提供日语学习APP的UI/UX设计实现方案。接下来，我们将实现设置页面和用户个人资料页面，这些是用户体验中的重要组成部分。

### 设置页面实现
```swift
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 用户信息区域
                Section {
                    if viewModel.isLoggedIn {
                        NavigationLink(destination: ProfileView()) {
                            HStack(spacing: AppSpacing.standard) {
                                UserAvatarView(imageURL: viewModel.userProfile.avatarURL, size: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.userProfile.username)
                                        .font(AppFonts.subtitle.bold())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text(viewModel.userProfile.email)
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.mediumGray)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        Button(action: {
                            viewModel.showLogin()
                        }) {
                            HStack(spacing: AppSpacing.standard) {
                                Circle()
                                    .fill(AppColors.lightGray)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppColors.mediumGray)
                                    )
                                
                                Text("登录/注册")
                                    .font(AppFonts.subtitle.bold())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.mediumGray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                // 学习设置
                Section(header: Text("学习设置").font(AppFonts.body)) {
                    NavigationLink(destination: DailyGoalSettingView()) {
                        SettingRow(icon: "target", title: "每日学习目标", detail: viewModel.dailyGoalText)
                    }
                    
                    NavigationLink(destination: NotificationSettingView()) {
                        SettingRow(icon: "bell.badge", title: "学习提醒", detail: viewModel.reminderText)
                    }
                    
                    Toggle(isOn: $viewModel.autoPlayPronunciation) {
                        SettingRow(icon: "speaker.wave.2", title: "自动播放发音", detail: "")
                    }
                }
                
                // 应用设置
                Section(header: Text("应用设置").font(AppFonts.body)) {
                    NavigationLink(destination: AppearanceSettingView()) {
                        SettingRow(icon: "paintbrush", title: "外观", detail: viewModel.appearanceText)
                    }
                    
                    NavigationLink(destination: LanguageSettingView()) {
                        SettingRow(icon: "globe", title: "语言", detail: viewModel.languageText)
                    }
                    
                    Toggle(isOn: $viewModel.reducedMotion) {
                        SettingRow(icon: "hand.raised", title: "减少动画", detail: "")
                    }
                }
                
                // 数据与隐私
                Section(header: Text("数据与隐私").font(AppFonts.body)) {
                    NavigationLink(destination: DataManagementView()) {
                        SettingRow(icon: "arrow.down.doc", title: "数据管理", detail: "")
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingRow(icon: "lock.shield", title: "隐私政策", detail: "")
                    }
                    
                    if viewModel.isLoggedIn {
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            SettingRow(icon: "arrow.right.square", title: "退出登录", detail: "")
                                .foregroundColor(AppColors.error)
                        }
                    }
                }
                
                // 关于
                Section(header: Text("关于").font(AppFonts.body)) {
                    NavigationLink(destination: AboutAppView()) {
                        SettingRow(icon: "info.circle", title: "关于应用", detail: "")
                    }
                    
                    NavigationLink(destination: FeedbackView()) {
                        SettingRow(icon: "envelope", title: "反馈与建议", detail: "")
                    }
                    
                    Button(action: {
                        viewModel.rateApp()
                    }) {
                        SettingRow(icon: "star", title: "评分鼓励", detail: "")
                    }
                    
                    NavigationLink(destination: VersionHistoryView()) {
                        SettingRow(icon: "clock.arrow.circlepath", title: "版本历史", detail: viewModel.versionText)
                    }
                }
                
                // 底部版本信息
                Section(footer: Text("版本 \(viewModel.appVersion)").font(AppFonts.caption).foregroundColor(AppColors.hintText)) {
                    EmptyView()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("设置", displayMode: .large)
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.darkGray)
            })
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("退出登录"),
                    message: Text("确定要退出当前账号吗？"),
                    primaryButton: .destructive(Text("退出")) {
                        viewModel.logout()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
}

// 设置行
struct SettingRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primary)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(AppFonts.body)
            
            Spacer()
            
            if !detail.isEmpty {
                Text(detail)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}

// 用户头像
struct UserAvatarView: View {
    let imageURL: String?
    let size: CGFloat
    
    var body: some View {
        if let imageURL = imageURL, !imageURL.isEmpty {
            // 在实际应用中，这里应该使用网络图片加载
            Image("placeholder_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppColors.lightGray)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(AppColors.mediumGray)
                )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
 ```
```

```swift
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userProfile: UserProfile = UserProfile(username: "", email: "", avatarURL: nil)
    @Published var autoPlayPronunciation: Bool = true
    @Published var reducedMotion: Bool = false
    
    // 应用设置
    private var dailyGoal: Int = 20
    private var reminderTime: Date = Date()
    private var appearance: AppearanceMode = .system
    private var language: AppLanguage = .chinese
    
    var appVersion: String {
        return "1.0.0"
    }
    
    var dailyGoalText: String {
        return "\(dailyGoal)个单词/天"
    }
    
    var reminderText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: reminderTime)
    }
    
    var appearanceText: String {
        switch appearance {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
    
    var languageText: String {
        switch language {
        case .chinese: return "简体中文"
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }
    
    var versionText: String {
        return "v\(appVersion)"
    }
    
    init() {
        // 模拟加载用户数据
        loadUserData()
    }
    
    private func loadUserData() {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 随机模拟登录状态
            self.isLoggedIn = Bool.random()
            
            if self.isLoggedIn {
                self.userProfile = UserProfile(
                    username: "日语学习者",
                    email: "user@example.com",
                    avatarURL: nil
                )
            }
        }
    }
    
    func showLogin() {
        // 显示登录界面
        print("显示登录界面")
    }
    
    func logout() {
        // 退出登录
        isLoggedIn = false
        userProfile = UserProfile(username: "", email: "", avatarURL: nil)
    }
    
    func rateApp() {
        // 跳转到App Store评分
        print("跳转到App Store评分")
    }
}

// 用户资料模型
struct UserProfile {
    let username: String
    let email: String
    let avatarURL: String?
}

// 外观模式
enum AppearanceMode {
    case light
    case dark
    case system
}

// 应用语言
enum AppLanguage {
    case chinese
    case english
    case japanese
}
 ```
```

### 用户个人资料页面
```swift
import SwiftUI

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingEditUsername = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.standard) {
                // 头像区域
                VStack(spacing: AppSpacing.standard) {
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        ZStack {
                            UserAvatarView(imageURL: viewModel.profile.avatarURL, size: 100)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .fill(AppColors.primary)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                )
                                .position(x: 75, y: 75)
                        }
                    }
                    
                    Button(action: {
                        showingEditUsername = true
                    }) {
                        HStack(spacing: 8) {
                            Text(viewModel.profile.username)
                                .font(AppFonts.title.bold())
                                .foregroundColor(AppColors.primaryText)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.primary)
                        }
                    }
                    
                    Text(viewModel.profile.email)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(AppSpacing.standard)
                .frame(maxWidth: .infinity)
                
                // 学习统计
                VStack(alignment: .leading, spacing: AppSpacing.standard) {
                    Text("学习统计")
                        .font(AppFonts.subtitle.bold())
                        .foregroundColor(AppColors.primaryText)
                    
                    HStack(spacing: AppSpacing.standard) {
                        StatisticCard(
                            icon: "calendar",
                            value: "\(viewModel.statistics.learningDays)",
                            title: "学习天数"
                        )
                        
                        StatisticCard(
                            icon: "flame",
                            value: "\(viewModel.statistics.streak)",
                            title: "连续学习"
                        )
                    }
                    
                    HStack(spacing: AppSpacing.standard) {
                        StatisticCard(
                            icon: "book.closed",
                            value: "\(viewModel.statistics.learnedWords)",
                            title: "已学单词"
                        )
                        
                        StatisticCard(
                            icon: "checkmark.circle",
                            value: "\(viewModel.statistics.masteredWords)",
                            title: "已掌握"
                        )
                    }
                }
                .padding(AppSpacing.standard)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppSpacing.standard)
                
                // 成就徽章
                VStack(alignment: .leading, spacing: AppSpacing.standard) {
                    Text("成就徽章")
                        .font(AppFonts.subtitle.bold())
                        .foregroundColor(AppColors.primaryText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.standard) {
                        ForEach(viewModel.achievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                }
                .padding(AppSpacing.standard)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppSpacing.standard)
                
                // 学习记录
                VStack(alignment: .leading, spacing: AppSpacing.standard) {
                    Text("学习记录")
                        .font(AppFonts.subtitle.bold())
                        .foregroundColor(AppColors.primaryText)
                    
                    // 学习热力图
                    VStack(alignment: .leading, spacing: AppSpacing.compact) {
                        Text("过去30天")
                            .font(AppFonts.caption)
                            .foregroundColor(AppColors.secondaryText)
                        
                        HeatmapCalendarView(data: viewModel.learningHeatmap)
                            .frame(height: 180)
                    }
                }
                .padding(AppSpacing.standard)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppSpacing.standard)
                
                // 账号安全
                VStack(alignment: .leading, spacing: AppSpacing.standard) {
                    Text("账号安全")
                        .font(AppFonts.subtitle.bold())
                        .foregroundColor(AppColors.primaryText)
                    
                    Button(action: {
                        viewModel.changePassword()
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 28, height: 28)
                            
                            Text("修改密码")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                        }
                        .padding(AppSpacing.standard)
                        .background(AppColors.lightGray.opacity(0.5))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        viewModel.bindEmail()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primary)
                                .frame(width: 28, height: 28)
                            
                            Text("绑定邮箱")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.primaryText)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.mediumGray)
                        }
                        .padding(AppSpacing.standard)
                        .background(AppColors.lightGray.opacity(0.5))
                        .cornerRadius(12)
                    }
                }
                .padding(AppSpacing.standard)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppSpacing.standard)
            }
            .padding(.bottom, AppSpacing.standard)
        }
        .navigationBarTitle("个人资料", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 18))
                .foregroundColor(AppColors.darkGray)
        })
        .sheet(isPresented: $showingImagePicker) {
            Text("图片选择器")
                .font(AppFonts.title)
                .padding()
        }
        .alert(isPresented: $showingEditUsername) {
            Alert(
                title: Text("修改用户名"),
                message: Text("请输入新的用户名"),
                primaryButton: .default(Text("确定")) {
                    // 更新用户名
                },
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .onAppear {
            viewModel.loadProfile()
        }
    }
}

// 统计卡片
struct StatisticCard: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.primary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.primaryText)
            
            Text(title)
                .font(AppFonts.caption)
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.standard)
        .background(AppColors.lightGray.opacity(0.5))
        .cornerRadius(12)
    }
}

// 成就徽章
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : AppColors.lightGray)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? achievement.color : AppColors.mediumGray)
            }
            
            Text(achievement.name)
                .font(AppFonts.caption)
                .foregroundColor(achievement.isUnlocked ? AppColors.primaryText : AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(height: 100)
    }
}

// 热力图日历视图
struct HeatmapCalendarView: View {
    let data: [Double]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    let rows = 5
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<data.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForValue(data[index]))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
    
    private func colorForValue(_ value: Double) -> Color {
        if value <= 0 {
            return AppColors.lightGray
        } else if value < 0.3 {
            return AppColors.primary.opacity(0.3)
        } else if value < 0.6 {
            return AppColors.primary.opacity(0.6)
        } else {
            return AppColors.primary
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
 ```
```

```swift
import SwiftUI
import Combine

// 成就模型
struct Achievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
}

// 学习统计模型
struct LearningStatistics {
    let learningDays: Int
    let streak: Int
    let learnedWords: Int
    let masteredWords: Int
}

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile(username: "", email: "", avatarURL: nil)
    @Published var statistics: LearningStatistics = LearningStatistics(learningDays: 0, streak: 0, learnedWords: 0, masteredWords: 0)
    @Published var achievements: [Achievement] = []
    @Published var learningHeatmap: [Double] = []
    
    func loadProfile() {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.profile = UserProfile(
                username: "日语学习者",
                email: "user@example.com",
                avatarURL: nil
            )
            
            self.statistics = LearningStatistics(
                learningDays: 42,
                streak: 7,
                learnedWords: 358,
                masteredWords: 215
            )
            
            self.achievements = [
                Achievement(
                    id: "1",
                    name: "初学者",
                    icon: "star.fill",
                    color: AppColors.primary,
                    isUnlocked: true
                ),
                Achievement(
                    id: "2",
                    name: "连续学习7天",
                    icon: "flame.fill",
                    color: AppColors.warning,
                    isUnlocked: true
                ),
                Achievement(
                    id: "3",
                    name: "词汇达人",
                    icon: "book.fill",
                    color: AppColors.info,
                    isUnlocked: true
                ),
                Achievement(
                    id: "4",
                    name: "完美记忆",
                    icon: "brain",
                    color: AppColors.success,
                    isUnlocked: false
                ),
                Achievement(
                    id: "5",
                    name: "日语达人",
                    icon: "crown.fill",
                    color: Color(hex: "#FFD700"),
                    isUnlocked: false
                ),
                Achievement(
                    id: "6",
                    name: "学习狂人",
                    icon: "bolt.fill",
                    color: AppColors.error,
                    isUnlocked: false
                )
            ]
            
            // 生成随机热力图数据
            self.learningHeatmap = Array(repeating: 0.0, count: 35).map { _ in
                Double.random(in: 0...1)
            }
        }
    }
    
    func changePassword() {
        // 修改密码
        print("修改密码")
    }
    
    func bindEmail() {
        // 绑定邮箱
        print("绑定邮箱")
    }
}
 ```
```

这些实现包含了设置页面和用户个人资料页面的完整UI和功能。设置页面提供了用户可自定义的各种选项，包括学习设置、应用设置、数据与隐私等。个人资料页面则展示了用户的基本信息、学习统计、成就徽章和学习记录等内容，使用户能够直观地了解自己的学习情况。

这些页面的设计遵循了文档中定义的UI/UX设计规范，包括色彩系统、排版系统、间距与布局等，确保整个应用的视觉风格统一一致。同时，我们也注意到了文档中提到的图标规范，使用了18pt大小的主色图标，保持了设计的一致性。