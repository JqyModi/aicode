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
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [Color("Primary"), Color("Primary").opacity(0.7)],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // 分类选项
    private let categories = ["全部", "单词", "语法", "例句", "笔记"]
    
    // 模拟收藏夹数据
    private let folders = [
        ("默认收藏夹", 42),
        ("N5词汇", 28),
        ("常用会话", 15),
        ("旅行必备", 8)
    ]
    
    // 模拟收藏单词数据
    private let favoriteWords = [
        ("こんにちは", "你好", "konnichiwa", "1", "单词"),
        ("ありがとう", "谢谢", "arigatou", "2", "单词"),
        ("さようなら", "再见", "sayounara", "3", "单词"),
        ("お願いします", "拜托了", "onegaishimasu", "4", "单词"),
        ("すみません", "对不起/打扰了", "sumimasen", "5", "单词"),
        ("「〜てください」", "请~（请求）", "te kudasai", "6", "语法"),
        ("「〜ています」", "正在~（进行时）", "te imasu", "7", "语法"),
        ("明日は晴れるでしょう", "明天可能会放晴", "ashita wa hareru deshou", "8", "例句")
    ]
    
    // 过滤后的收藏内容
    private var filteredFavorites: [(String, String, String, String, String)] {
        let categoryFiltered = selectedCategory == 0 ?
            favoriteWords :
            favoriteWords.filter { $0.4 == categories[selectedCategory] }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.0.localizedCaseInsensitiveContains(searchText) ||
                $0.1.localizedCaseInsensitiveContains(searchText) ||
                $0.2.localizedCaseInsensitiveContains(searchText)
            }
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
                    favoritesList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 启动渐变动画
            withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
        .sheet(isPresented: $showWordDetail) {
            // 单词详情页面
            if let wordId = selectedWordId {
                WordDetailView(
                    detailViewModel: DetailViewModel(
                        dictionaryService: DictionaryService(dictionaryRepository: DictionaryDataRepository()),
                        favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository())
                    ),
                    wordId: wordId
                )
            }
        }
        .sheet(isPresented: $showCreateFolder) {
            createFolderView
        }
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            // 返回按钮
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
            
            // 页面标题
            Text("我的收藏")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Color("Primary"))
            
            Spacer()
            
            // 编辑按钮
            Button(action: { isEditMode.toggle() }) {
                Text(isEditMode ? "完成" : "编辑")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("Primary"))
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
                .foregroundColor(Color("Primary"))
            
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
                            .foregroundColor(selectedCategory == index ? .white : Color("Primary"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == index ? Color("Primary") : Color(UIColor.secondarySystemBackground))
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - 收藏夹横向滚动
    private var foldersScrollView: some View {
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
                    .foregroundColor(Color("Primary"))
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(folders, id: \.0) { folder in
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(themeGradient)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            
                            Text(folder.0)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Text("\(folder.1)项")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 90)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 收藏内容列表
    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(filteredFavorites, id: \.0) { item in
                    Button(action: {
                        if isEditMode {
                            if selectedItems.contains(item.3) {
                                selectedItems.remove(item.3)
                            } else {
                                selectedItems.insert(item.3)
                            }
                        } else {
                            selectedWordId = item.3
                            showWordDetail = true
                        }
                    }) {
                        HStack {
                            // 选择指示器（编辑模式）
                            if isEditMode {
                                Image(systemName: selectedItems.contains(item.3) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedItems.contains(item.3) ? Color("Primary") : .gray)
                                    .padding(.trailing, 5)
                            }
                            
                            // 内容类型标签
                            Text(item.4)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(categoryColor(for: item.4))
                                )
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.0)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(item.2)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(item.1)
                                .font(.system(size: 16))
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
                                .stroke(selectedItems.contains(item.3) && isEditMode ? Color("Primary") : Color.clear, lineWidth: 2)
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
            }
            .padding()
            .padding(.bottom, 30)
            
            // 编辑模式下的底部操作栏
            if isEditMode {
                bottomActionBar
            }
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(Color("Primary").opacity(0.5))
            
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
                            .fill(Color("Primary"))
                    )
            }
            .padding(.top, 10)
            
            Spacer()
        }
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
                .foregroundColor(selectedItems.isEmpty ? .gray : Color("Primary"))
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
        .padding(.bottom, 30) // 为底部安全区域留出空间
    }
    
    // MARK: - 创建收藏夹视图
    private var createFolderView: some View {
        VStack(spacing: 20) {
            Text("新建收藏夹")
                .font(.headline)
                .padding(.top, 20)
            
            TextField("收藏夹名称", text: $newFolderName)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: { showCreateFolder = false }) {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    // 创建收藏夹逻辑
                    showCreateFolder = false
                    newFolderName = ""
                }) {
                    Text("创建")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Primary"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newFolderName.isEmpty)
                .opacity(newFolderName.isEmpty ? 0.6 : 1)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(height: 250)
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
                favoriteService: FavoriteService(favoriteRepository: FavoriteDataRepository())
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
                .foregroundColor(Color("Primary").opacity(0.5))
            
            Text(message)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
    }
}