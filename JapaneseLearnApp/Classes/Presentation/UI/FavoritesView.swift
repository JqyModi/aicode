//
//  FavoritesView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct FavoritesView: View {
    // MARK: - 属性
    @ObservedObject var favoriteViewModel: DetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var animateGradient = false
    @State private var selectedCategory = 0
    @State private var searchText = ""
    @State private var showWordDetail = false
    @State private var selectedWordId: String? = nil
    @State private var showCreateFolder = false
    @State private var newFolderName = ""
    @State private var isEditMode = false
    @State private var selectedItems = Set<String>()
    @State private var selectedFolderId: String? = nil  // 添加这一行来跟踪选中的文件夹
    
    // 初始选中的收藏夹ID
    var initialFolderId: String? = nil
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [AppTheme.Colors.primary, AppTheme.Colors.primaryLight],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // 分类选项
    private let categories = ["全部", "单词", "语法", "例句", "笔记"]
    
    // 收藏夹数据
    @State private var folders: [(String, String, Int)] = [] // (id, name, itemCount)
    
    // 收藏项数据
    @State private var favoriteItems: [FavoriteItemViewModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // 过滤后的收藏内容
    private var filteredFavorites: [FavoriteItemViewModel] {
        let categoryFiltered = selectedCategory == 0 ?
            favoriteItems :
            favoriteItems.filter { $0.type == categories[selectedCategory] }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.meaning.localizedCaseInsensitiveContains(searchText) ||
                $0.reading.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景层
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if isLoading {
                // 加载中视图
                ProgressView("加载中...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            } else if let error = errorMessage {
                // 错误视图
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { loadFavoriteData() }) {
                        Text("重试")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(AppTheme.Colors.primary))
                    }
                }
            } else {
                VStack(spacing: 0) {
                    // 顶部导航栏
                    topNavigationBar
                    
                    // 主内容区域
                    ScrollView {
                        VStack(spacing: 15) {
                            // 搜索栏
                            searchBar
                                .padding(.horizontal)
                                .padding(.top, 10)
                                .padding(.bottom, 5)
                            
                            // 分类选择器
                            categorySelector
                                .padding(.horizontal)
                                .padding(.vertical, 5)
                            
                            // 收藏夹横向滚动
                            foldersScrollView
                                .padding(.top, 5)
                            
                            // 收藏内容列表
                            if filteredFavorites.isEmpty {
                                emptyStateView
                            } else {
                                favoriteItemsList
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    
                    // 编辑模式下的底部操作栏
                    if isEditMode {
                        bottomActionBar
                    }
                }
            }

            // 弹窗（全屏遮罩+卡片）
            if showCreateFolder {
                CreateFolderDialog(
                    isPresented: $showCreateFolder,
                    folderName: $newFolderName,
                    title: "新建收藏夹",
                    onCreate: {
                        if !newFolderName.isEmpty {
                            favoriteViewModel.createFolder(name: newFolderName) { success in
                                if success {
                                    newFolderName = ""
                                    showCreateFolder = false
                                    
                                    loadFavoriteData()
                                }
                            }
                        }
                    },
                    onCancel: {
                        newFolderName = ""
                        showCreateFolder = false
                    },
                    isLoading: favoriteViewModel.isLoading,
                    errorMessage: favoriteViewModel.errorMessage
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            
            // 加载收藏数据
            loadFavoriteData()
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
    
    // MARK: - 加载收藏数据
    private func loadFavoriteData() {
        isLoading = true
        errorMessage = nil
        
        // 加载收藏夹
        favoriteViewModel.favoriteService.getAllFolders()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.errorMessage = "加载收藏夹失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { folderSummaries in
                    // 更新收藏夹数据
                    self.folders = folderSummaries.map { ($0.id, $0.name, $0.itemCount) }
                    
                    // 如果有初始指定的收藏夹ID，则加载该收藏夹内容
                    if let initialId = self.initialFolderId, let folder = folderSummaries.first(where: { $0.id == initialId }) {
                        self.loadFolderItems(folderId: folder.id)
                    }
                    // 否则，如果有收藏夹，加载第一个收藏夹的内容
                    else if let firstFolder = folderSummaries.first {
                        self.loadFolderItems(folderId: firstFolder.id)
                    } else {
                        self.isLoading = false
                        self.favoriteItems = []
                    }
                }
            )
            .store(in: &favoriteViewModel.cancellables)
        
        // 默认选择第一项
        folderSelected(folderId: self.folders.first?.0 ?? "")
    }
    
    // 加载收藏夹内容
    private func loadFolderItems(folderId: String) {
        favoriteViewModel.favoriteService.getFolderItems(folderId: folderId, limit: 100, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = "加载收藏内容失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { folderContent in
                    // 将领域模型转换为视图模型
                    self.favoriteItems = folderContent.items.map { FavoriteItemViewModel.fromDomain($0) }
                }
            )
            .store(in: &favoriteViewModel.cancellables)
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
            Text("我的收藏")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.Colors.primary)
            
            Spacer()
            
            // 编辑按钮
            Button(action: { isEditMode.toggle() }) {
                Text(isEditMode ? "完成" : "编辑")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 60, height: 36)
                    .background(
                        Capsule()
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.primary)
            
            TextField("搜索收藏内容", text: $searchText)
                .font(.system(size: 16))
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - 分类选择器
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedCategory = index
                        }
                    }) {
                        Text(categories[index])
                            .font(.system(size: 15, weight: selectedCategory == index ? .semibold : .regular))
                            .foregroundColor(selectedCategory == index ? .white : AppTheme.Colors.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == index ? AppTheme.Colors.primary : Color(UIColor.secondarySystemBackground))
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 收藏夹横向滚动
    private func folderSelected(folderId: String) {
        // 点击加载该收藏夹内容
        self.selectedFolderId = folderId
        self.loadFolderItems(folderId: folderId)
    }
    
    var foldersScrollView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("收藏夹")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showCreateFolder = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                        Text("新建")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(folders, id: \.0) { folder in
                        Button(action: {
                            folderSelected(folderId: folder.0)
                        }) {
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(themeGradient)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                                
                                Text(folder.1)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .padding(.leading)
                                    .padding(.trailing)
                                
                                Text("\(folder.2)项")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 140)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedFolderId == folder.0 ? AppTheme.Colors.primary : Color.clear, lineWidth: 1)
                                    .padding(.vertical, 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 收藏内容列表
    private var favoriteItemsList: some View {
        LazyVStack(spacing: 15) {
            ForEach(filteredFavorites) { item in
                Button(action: {
                    if isEditMode {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    } else {
                        selectedWordId = item.wordId
                        showWordDetail = true
                    }
                }) {
                    HStack {
                        // 选择指示器（编辑模式）
                        if isEditMode {
                            Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(selectedItems.contains(item.id) ? AppTheme.Colors.primary : .gray)
                                .padding(.trailing, 5)
                        }
                        
                        // 内容类型标签
                        Text(item.type)
                            .font(.system(size: 12))
                            .lineLimit(3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(categoryColor(for: item.type))
                            )
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.word)
                                .font(.system(size: 18, weight: .medium))
                                .lineLimit(2)
                                .foregroundColor(.primary)
                            
                            Text(item.reading)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(item.meaning)
                            .font(.system(size: 16))
                            .lineLimit(3)
                            .foregroundColor(.secondary)
                        
                        if !isEditMode {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedItems.contains(item.id) && isEditMode ? AppTheme.Colors.primary : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button(action: {
                        // 移动到其他收藏夹
                    }) {
                        Label("移动到", systemImage: "folder")
                    }
                    
                    Button(action: {
                        // 添加笔记
                    }) {
                        Label("添加笔记", systemImage: "note.text")
                    }
                    
                    Button(action: {
                        // 取消收藏
                    }) {
                        Label("取消收藏", systemImage: "star.slash")
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primaryLighter)
                .padding(.top, 40)
            
            Text("暂无收藏内容")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("在学习过程中点击星标收藏喜欢的内容")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("返回学习")
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
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - 底部操作栏（编辑模式）
    private var bottomActionBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                // 移动到其他收藏夹
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "folder")
                        .font(.system(size: 22))
                    Text("移动到")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedItems.isEmpty ? .gray : AppTheme.Colors.primary)
                .frame(maxWidth: .infinity)
            }
            .disabled(selectedItems.isEmpty)
            
            Button(action: {
                // 取消收藏
            }) {
                VStack(spacing: 5) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 22))
                    Text("取消收藏")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedItems.isEmpty ? .gray : .red)
                .frame(maxWidth: .infinity)
            }
            .disabled(selectedItems.isEmpty)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -3)
        )
//        .padding(.bottom, 30) // 为底部安全区域留出空间
    }
    
    // MARK: - 辅助方法
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "单词":
            return Color.blue
        case "语法":
            return Color.purple
        case "例句":
            return Color.green
        case "笔记":
            return Color.orange
        default:
            return Color.gray
        }
    }
}

// MARK: - 预览
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(
            favoriteViewModel: DetailViewModel(
                dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository()), wordId: "1989103009"
            )
        )
    }
}

// MARK: - 扩展
extension View {
    // 空状态视图辅助方法
    func emptyStateView(message: String, icon: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primaryLighter)
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
    }
}
