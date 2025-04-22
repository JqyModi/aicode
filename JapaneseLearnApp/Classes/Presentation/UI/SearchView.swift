//
//  SearchView.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI
import Combine

/// 搜索结果页面，实现与HTML原型1:1还原的UI设计
struct SearchView: View {
    // MARK: - 属性
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSearchType: SearchTypeViewModel = .auto
    @State private var showFilterOptions = false
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景色
            DesignSystem.Colors.neutralLightHex.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                // 搜索类型选择器
                searchTypeSelector
                
                // 搜索结果列表
                if viewModel.isSearching {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.searchResults.isEmpty {
                    emptyResultsView
                } else {
                    searchResultsList
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 顶部导航栏
    private var topNavigationBar: some View {
        HStack {
            // 返回按钮
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(20)
            }
            
            // 搜索框
            Components.InputFields.SearchField(
                text: $viewModel.searchQuery,
                placeholder: "搜索日语单词或句子...",
                onSubmit: { viewModel.search() }//,
//                onClear: { viewModel.clearSearch() }
            )
            
            // 筛选按钮
            Button(action: { showFilterOptions.toggle() }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.standard)
        .padding(.vertical, DesignSystem.Spacing.compact)
        .background(Color.white)
    }
    
    // MARK: - 搜索类型选择器
    private var searchTypeSelector: some View {
        HStack(spacing: DesignSystem.Spacing.compact) {
            searchTypeButton(.auto, title: "自动")
            searchTypeButton(.word, title: "单词")
            searchTypeButton(.reading, title: "读音")
            searchTypeButton(.meaning, title: "释义")
        }
        .padding(.horizontal, DesignSystem.Spacing.standard)
        .padding(.vertical, DesignSystem.Spacing.compact)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private func searchTypeButton(_ type: SearchTypeViewModel, title: String) -> some View {
        Button(action: {
            selectedSearchType = type
            viewModel.searchType = type
            if !viewModel.searchQuery.isEmpty {
                viewModel.search()
            }
        }) {
            Text(title)
                .font(DesignSystem.Typography.body)
                .foregroundColor(selectedSearchType == type ? .white : DesignSystem.Colors.textPrimaryHex)
                .padding(.horizontal, DesignSystem.Spacing.standard)
                .padding(.vertical, DesignSystem.Spacing.compact)
                .background(
                    selectedSearchType == type ?
                    DesignSystem.Colors.primaryHex :
                    DesignSystem.Colors.neutralMediumHex
                )
                .cornerRadius(DesignSystem.CornerRadius.small)
        }
    }
    
    // MARK: - 搜索结果列表
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { result in
                    searchResultRow(result)
                }
                
                // 加载更多按钮
                if !viewModel.searchResults.isEmpty {
                    Button(action: { viewModel.loadMoreResults() }) {
                        HStack {
                            Text("加载更多结果")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.primaryHex)
                            
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.primaryHex)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.standard)
                        .background(Color.white)
                    }
                }
            }
            .background(DesignSystem.Colors.neutralLightHex)
        }
    }
    
    private func searchResultRow(_ result: WordSummaryViewModel) -> some View {
        Button(action: { viewModel.selectWord(id: result.id) }) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                HStack(alignment: .top) {
                    // 单词和读音
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.word)
                            .font(DesignSystem.Typography.subtitle)
                            .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                        
                        Text(result.reading)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    }
                    
                    Spacer()
                    
                    // 词性标签
                    Text(result.partOfSpeech)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.textHintHex)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.neutralMediumHex)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                }
                
                // 简短释义
                Text(result.briefMeaning)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(DesignSystem.Spacing.standard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            .padding(.horizontal, DesignSystem.Spacing.standard)
            .padding(.vertical, DesignSystem.Spacing.compact)
        }
    }
    
    // MARK: - 加载中视图
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryHex))
            Text("正在搜索...")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                .padding(.top, DesignSystem.Spacing.standard)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.neutralLightHex)
    }
    
    // MARK: - 错误视图
    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.warningHex)
                .padding(.bottom, DesignSystem.Spacing.standard)
            Text("搜索出错")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                .padding(.bottom, DesignSystem.Spacing.compact)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            Button(action: { viewModel.search() }) {
                Text("重试")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.relaxed)
                    .padding(.vertical, DesignSystem.Spacing.compact)
                    .background(DesignSystem.Colors.primaryHex)
                    .cornerRadius(DesignSystem.CornerRadius.small)
            }
            .padding(.top, DesignSystem.Spacing.standard)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.neutralLightHex)
    }
    
    // MARK: - 空结果视图
    private var emptyResultsView: some View {
        VStack {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(DesignSystem.Colors.neutralDarkHex)
                .padding(.bottom, DesignSystem.Spacing.standard)
            Text("未找到结果")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                .padding(.bottom, DesignSystem.Spacing.compact)
            Text("尝试使用不同的关键词或搜索类型")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.neutralLightHex)
    }
}

// MARK: - 预览
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService1()
        let viewModel = SearchViewModel(dictionaryService: dictionaryService)
        
        // 模拟数据
        viewModel.searchQuery = "食べる"
        
        return SearchView(viewModel: viewModel)
    }
}
