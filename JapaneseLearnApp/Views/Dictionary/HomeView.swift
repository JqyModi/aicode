import SwiftUI

struct HomeView: View {
    @ObservedObject var dictionaryViewModel: DictionaryViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var showLearningCenter: Bool = false
    @State private var selectedEntry: DictEntry? = nil
    
    // 获取当前时间段的问候语
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "晚上好"
        case 6..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    // 主内容区域
    private var mainContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    // 搜索区域
                    SearchBar(text: $searchText, isSearching: $isSearching)
                        .padding(.horizontal, 16)
                    
                    // 根据搜索状态显示不同内容
                    if !isSearching {
                        learningContentSection
                    } else {
                        searchResultsSection
                    }
                }
                .padding(.bottom, 80) // 为浮动学习中心留出空间
            }
            
            // 浮动学习中心按钮
            LearningCenterButton(isExpanded: $showLearningCenter)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchViewModel.searchQuery = newValue
                searchViewModel.search()
                isSearching = true
            } else {
                isSearching = false
            }
        }
        .navigationBarHidden(true)
        .background(navigationLinks)
    }
    
    // 头部区域
    private var headerSection: some View {
        HStack {
            // 用户头像
            Button(action: {
                // 进入设置页面
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color(hex: "00D2DD"))
            }
            
            // 问候语
            VStack(alignment: .leading) {
                Text(greetingText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                if let user = dictionaryViewModel.userProfile {
                    Text("今天学习3个新词")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "5D6D7E"))
                } else {
                    Text("今天学习日语的好日子")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "5D6D7E"))
                }
            }
            
            Spacer()
            
            // 设置按钮
            Button(action: {
                // 进入设置页面
            }) {
                Image(systemName: "gearshape")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(Color(hex: "8A9199"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // 学习内容区域
    private var learningContentSection: some View {
        VStack(spacing: 24) {
            // 学习进度卡片
            LearningProgressCard(progress: dictionaryViewModel.learningProgress)
                .padding(.horizontal, 16)
            
            // 最近查询词汇
            if !dictionaryViewModel.recentSearches.isEmpty {
                RecentSearchesCard(entries: dictionaryViewModel.recentSearches) { historyItem in
                    // 使用 historyItem.wordId 加载详情
                    dictionaryViewModel.loadWordDetails(id: historyItem.wordId)
                }
                .padding(.horizontal, 16)
            }
            
            // 收藏夹快速访问
            if !dictionaryViewModel.favoriteCategories.isEmpty {
                FavoriteCategoriesCard(categories: dictionaryViewModel.favoriteCategories)
                    .padding(.horizontal, 16)
            }
            
            // 个性化词云
            if !dictionaryViewModel.wordCloudItems.isEmpty {
                WordCloudCard(items: dictionaryViewModel.wordCloudItems) { word in
                    searchText = word
                    isSearching = true
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // 搜索结果区域
    private var searchResultsSection: some View {
        // 创建 SearchResultsViewModel 实例
        let searchResultsViewModel = SearchResultsViewModel(
            dictionaryViewModel: dictionaryViewModel,
            detailViewModel: DetailViewModel(
                dictionaryService: DependencyContainer.shared.dictionaryService,
                favoriteService: DependencyContainer.shared.favoriteService
            )
        )
        
        return SearchResultsView(
            viewModel: searchResultsViewModel,
            onSelectEntry: { wordItem in
                // 不能直接赋值，需要通过 wordId 加载详情
                dictionaryViewModel.loadWordDetails(id: wordItem.id) { entry in
                    if let entry = entry {
                        selectedEntry = entry
                    }
                }
            }
        )
    }
    
    // 导航链接
    private var navigationLinks: some View {
        NavigationLink(
            destination: Group {
                if let entry = selectedEntry {
                    EntryDetailView(
                        viewModel: DetailViewModel(
                            dictionaryService: DependencyContainer.shared.dictionaryService,
                            favoriteService: DependencyContainer.shared.favoriteService
                        ),
                        entry: entry
                    )
                }
            },
            isActive: Binding(
                get: { selectedEntry != nil },
                set: { if !$0 { selectedEntry = nil } }
            )
        ) {
            EmptyView()
        }
    }
}

// 搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(hex: "8A9199"))
                    .padding(.leading, 12)
                
                TextField("搜索日语单词或句子...", text: $text)
                    .padding(.vertical, 12)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .onChange(of: isFocused) { newValue in
                        isSearching = newValue || !text.isEmpty
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        isSearching = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(hex: "8A9199"))
                    }
                    .padding(.trailing, 12)
                }
            }
            .background(Color(hex: "F5F7FA"))
            .cornerRadius(10)
            
            if isSearching {
                Button("取消") {
                    text = ""
                    isSearching = false
                    isFocused = false
                }
                .foregroundColor(Color(hex: "00D2DD"))
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
}

// 学习进度卡片
struct LearningProgressCard: View {
    let progress: LearningProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日学习计划")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(progress.completedCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "00D2DD"))
                    Text("已学单词")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "5D6D7E"))
                }
                
                VStack {
                    Text("\(progress.targetCount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "00D2DD"))
                    Text("目标")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "5D6D7E"))
                }
                
                VStack {
                    Text("\(progress.streakDays)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "00D2DD"))
                    Text("连续天数")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "5D6D7E"))
                }
            }
            
            // 进度条
            ProgressBar(value: Float(progress.completedCount) / Float(progress.targetCount))
                .frame(height: 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 进度条组件
struct ProgressBar: View {
    var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.1)
                    .foregroundColor(Color(hex: "00D2DD"))
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color(hex: "00D2DD"))
                    .animation(.linear, value: value)
            }
            .cornerRadius(4)
        }
    }
}

// 最近搜索卡片
struct RecentSearchesCard: View {
    let entries: [SearchHistoryDTO]  // 修改为 SearchHistoryDTO 类型
    let onSelect: (SearchHistoryDTO) -> Void  // 修改为 SearchHistoryDTO 类型
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近学习")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            VStack(spacing: 8) {
                ForEach(entries.prefix(3), id: \.id) { entry in
                    Button(action: {
                        onSelect(entry)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "2C3E50"))
                                
                                Text(entry.reading)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "5D6D7E"))
                                
                                // 简化显示，因为 SearchHistoryDTO 没有 definitions
                                Text("最近搜索")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8A9199"))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // 发音按钮
                            Button(action: {
                                // 播放发音
                            }) {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(Color(hex: "00D2DD"))
                                    .padding(8)
                                    .background(Color(hex: "00D2DD").opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                    }
                }
            }
            
            Button(action: {
                // 查看更多
            }) {
                Text("查看全部")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "00D2DD"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 收藏分类卡片
struct FavoriteCategoriesCard: View {
    let categories: [FavoriteCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个性化词汇云")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(categories, id: \.id) { category in
                    Button(action: {
                        // 进入分类
                    }) {
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundColor(Color.white)
                                .padding(8)
                                .background(Color(hex: "00D2DD"))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(category.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Color(hex: "2C3E50"))
                                
                                Text("\(category.count)个单词")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "8A9199"))
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 词云卡片
struct WordCloudCard: View {
    let items: [WordCloudItem]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("个性化词汇云")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.word) { item in
                    Button(action: {
                        onSelect(item.word)
                    }) {
                        Text(item.word)
                            .font(.system(size: CGFloat(item.size)))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "00D2DD"))
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 流式布局组件
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
        
        height = y + maxHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

// 浮动学习中心按钮
struct LearningCenterButton: View {
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "00D2DD"), Color(hex: "00A8B3")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: Color(hex: "00D2DD").opacity(0.25), radius: 16, x: 0, y: 4)
                        
                        Image(systemName: isExpanded ? "xmark" : "book.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .overlay(
            Group {
                if isExpanded {
                    LearningCenterMenu()
                        .offset(y: -120)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        )
    }
}

// 学习中心菜单
struct LearningCenterMenu: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Button(action: {
                        // 进入词典
                    }) {
                        LearningCenterMenuItem(
                            icon: "book.fill",
                            title: "词典",
                            color: "00D2DD"
                        )
                    }
                    
                    Button(action: {
                        // 进入收藏
                    }) {
                        LearningCenterMenuItem(
                            icon: "heart.fill",
                            title: "收藏",
                            color: "FF6B6B"
                        )
                    }
                    
                    Button(action: {
                        // 进入学习
                    }) {
                        LearningCenterMenuItem(
                            icon: "graduationcap.fill",
                            title: "学习",
                            color: "4CD964"
                        )
                    }
                }
            }
        }
    }
}

// 学习中心菜单项
struct LearningCenterMenuItem: View {
    let icon: String
    let title: String
    let color: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Image(systemName: icon)
                .foregroundColor(Color.white)
                .padding(12)
                .background(Color(hex: color))
                .clipShape(Circle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
