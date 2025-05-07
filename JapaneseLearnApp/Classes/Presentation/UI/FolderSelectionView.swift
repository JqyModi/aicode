//
//  FolderSelectionView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

struct FolderSelectionView: View {
    // MARK: - 属性
    @ObservedObject var viewModel: DetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var newFolderName = ""
    @State private var showCreateFolder = false
    @State private var animateGradient = false
    
    // 当前单词ID
    let wordId: String
    
    // 主题色渐变
    private var themeGradient: LinearGradient {
        LinearGradient(
            colors: [Color("Primary"), Color("Primary").opacity(0.7)],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
    }
    
    // MARK: - 视图
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题区域
                VStack(spacing: 15) {
                    Text("选择收藏夹")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color("Primary"))
                    
                    Text("请选择要将单词添加到的收藏夹")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // 收藏夹列表
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.folders.isEmpty {
                    emptyFoldersView
                } else {
                    folderListView
                }
                
                // 底部按钮区域
                VStack(spacing: 15) {
                    // 创建新收藏夹按钮
                    Button(action: { showCreateFolder = true }) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 16))
                            Text("创建新收藏夹")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color("Primary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("Primary"), lineWidth: 1.5)
                        )
                    }
                    
                    // 取消按钮
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(UIColor.secondarySystemBackground))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
            .navigationBarHidden(true)
            .onAppear {
                // 启动渐变动画
                withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
                
                // 加载收藏夹列表 - 仅在文件夹为空时加载，避免循环调用
                if viewModel.folders.isEmpty {
                    viewModel.loadFolders()
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                createFolderView
            }
        }
    }
    
    // MARK: - 收藏夹列表视图
    private var folderListView: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.folders, id: \.id) { folder in
                    // 收藏夹项
                    Button(action: {
                        viewModel.addToFolder(wordId: wordId, folderId: folder.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 15) {
                            // 收藏夹图标
                            Image(systemName: "folder.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color("Primary"))
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("Primary").opacity(0.1))
                                )
                            
                            // 收藏夹名称
                            VStack(alignment: .leading, spacing: 4) {
                                Text(folder.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("\(folder.itemCount) 个单词")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // 选择指示器
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - 空收藏夹视图
    private var emptyFoldersView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("暂无收藏夹")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text("创建一个收藏夹来整理你的单词")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 创建收藏夹视图
    private var createFolderView: some View {
        VStack(spacing: 20) {
            // 标题
            Text("创建新收藏夹")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("Primary"))
            
            // 输入框
            TextField("收藏夹名称", text: $newFolderName)
                .font(.system(size: 16))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            
            // 按钮区域
            HStack(spacing: 15) {
                // 取消按钮
                Button(action: {
                    newFolderName = ""
                    showCreateFolder = false
                }) {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                }
                
                // 创建按钮
                Button(action: {
                    if !newFolderName.isEmpty {
                        viewModel.createFolder(name: newFolderName) { success in
                            if success {
                                newFolderName = ""
                                showCreateFolder = false
                            }
                        }
                    }
                }) {
                    Text("创建")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(newFolderName.isEmpty ? Color("Primary").opacity(0.5) : Color("Primary"))
                        )
                }
                .disabled(newFolderName.isEmpty)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("Primary")))
                .padding()
            Text("加载中...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // MARK: - 错误视图
    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("出错了")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: { viewModel.loadFolders() }) {
                Text("重试")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)
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
}