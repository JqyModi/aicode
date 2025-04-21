//
//  ContentView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct ContentView: View {
    // 存储查询结果和状态
    @State private var searchResults: [DictEntryEntity] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchQuery: String = "日本"
    @State private var selectedSearchType: SearchTypeEntity = .auto
    
    // 用于存储订阅
    @State private var cancellables = Set<AnyCancellable>()
    
    // 创建仓库实例
    private let repository = DictionaryDataRepository()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("DictionaryDataRepository测试")
                .font(.headline)
            
            // 搜索输入框
            TextField("输入搜索词", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            // 搜索类型选择器
            Picker("搜索类型", selection: $selectedSearchType) {
                Text("自动").tag(SearchTypeEntity.auto)
                Text("单词").tag(SearchTypeEntity.word)
                Text("读音").tag(SearchTypeEntity.reading)
                Text("释义").tag(SearchTypeEntity.meaning)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // 搜索按钮
            Button(action: performSearch) {
                Text("搜索")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            .disabled(isLoading)
            
            if isLoading {
                ProgressView("搜索中...")
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else {
                // 结果列表
                List {
                    ForEach(searchResults, id: \.id) { result in
                        VStack(alignment: .leading) {
                            Text(result.word)
                                .font(.headline)
                            Text(result.reading)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if !result.definitions.isEmpty {
                                Text(result.definitions[0].meaning)
                                    .font(.body)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            // 视图出现时自动执行一次搜索
            performSearch()
        }
    }
    
    // 执行搜索
    private func performSearch() {
        isLoading = true
        errorMessage = nil
        
        // 取消之前的订阅
        cancellables.removeAll()
        
        // 调用仓库的searchWords方法
        repository.searchWords(query: searchQuery, type: selectedSearchType, limit: 10, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "搜索失败: \(error.localizedDescription)"
                    }
                },
                receiveValue: { results in
                    searchResults = results
                    if results.isEmpty {
                        errorMessage = "未找到匹配的单词"
                    }
                }
            )
            .store(in: &cancellables)
    }
}

#Preview {
    ContentView()
}
