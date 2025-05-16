//
//  DetailView.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI
import Combine

/// 单词详情页面，实现与HTML原型1:1还原的UI设计
struct DetailView: View {
    // MARK: - 属性
    @ObservedObject var viewModel: DetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showNoteEditor = false
    @State private var noteText = ""
    @State private var selectedPronunciationSpeed: Float = 1.0
    @State private var showRelatedWords = false
    
    // 单词ID参数，用于初始加载
    let wordId: String
    
    // MARK: - 初始化
    init(viewModel: DetailViewModel, wordId: String) {
        self.viewModel = viewModel
        self.wordId = wordId
    }
    
    // MARK: - 视图
    var body: some View {
        ZStack {
            // 背景色
            DesignSystem.Colors.neutralLightHex.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let details = viewModel.wordDetails {
                    // 详情内容
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.relaxed) {
                            // 单词卡片
                            wordCard(details)
                            
                            // 定义列表
                            definitionsCard(details)
                            
                            // 例句卡片
                            examplesCard(details)
                            
                            // 相关词汇
                            if !details.relatedWords.isEmpty {
                                relatedWordsCard(details)
                            }
                            
                            // 底部间距
                            Spacer().frame(height: DesignSystem.Spacing.relaxed)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.standard)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadWordDetails()
        }
        .sheet(isPresented: $showNoteEditor) {
            noteEditorView
        }
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
            
            Spacer()
            
            // 收藏按钮
            Button(action: { viewModel.toggleFavorite() }) {
                Image(systemName: viewModel.isFavorited ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.isFavorited ? DesignSystem.Colors.accentHex : DesignSystem.Colors.textPrimaryHex)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(20)
            }
            
            // 笔记按钮
            Button(action: {
                if viewModel.isFavorited {
                    showNoteEditor = true
                }
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(20)
                    .opacity(viewModel.isFavorited ? 1.0 : 0.5)
            }
            .disabled(!viewModel.isFavorited)
            
            // 分享按钮
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
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
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - 单词卡片
    private func wordCard(_ details: WordDetailsViewModel) -> some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // 单词和读音
            VStack(spacing: DesignSystem.Spacing.compact) {
                Text(details.word)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                    .multilineTextAlignment(.center)
                
                Text(details.reading)
                    .font(DesignSystem.Typography.subtitle)
                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    .multilineTextAlignment(.center)
                
                // 词性标签
                Text(details.partOfSpeech)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textHintHex)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.neutralMediumHex)
                    .cornerRadius(DesignSystem.CornerRadius.small)
                    .padding(.top, 4)
            }
            
            // 发音控制
            HStack(spacing: DesignSystem.Spacing.standard) {
                // 慢速发音
                Button(action: { viewModel.playPronunciation(speed: 0.75) }) {
                    VStack {
                        Image(systemName: "tortoise.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                        
                        Text("慢速")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    }
                    .frame(width: 60, height: 60)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
                // 正常发音
                Button(action: { viewModel.playPronunciation(speed: 1.0) }) {
                    VStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                        
                        Text("播放")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    }
                    .frame(width: 80, height: 80)
                    .background(DesignSystem.Colors.primaryLightHex.opacity(0.3))
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                
                // 快速发音
                Button(action: { viewModel.playPronunciation(speed: 1.25) }) {
                    VStack {
                        Image(systemName: "hare.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                        
                        Text("快速")
                            .font(DesignSystem.Typography.largeTitle)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                    }
                    .frame(width: 60, height: 60)
                    .background(DesignSystem.Colors.neutralLightHex)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                }
            }
        }
        .padding(DesignSystem.Spacing.standard)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
        .padding(.top, DesignSystem.Spacing.standard)
    }
    
    // MARK: - 定义卡片
    private func definitionsCard(_ details: WordDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            // 标题
            Text("释义")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            
            // 定义列表
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.relaxed) {
                ForEach(Array(details.definitions.enumerated()), id: \.offset) { index, definition in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                        // 序号和释义
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.compact) {
                            Text("\(index + 1).")
                                .font(DesignSystem.Typography.body.bold())
                                .foregroundColor(DesignSystem.Colors.primaryHex)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(definition.meaning)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // 注释（如果有）
                        if let notes = definition.notes, !notes.isEmpty {
                            Text(notes)
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                                .padding(.leading, 24)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.standard)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - 例句卡片
    private func examplesCard(_ details: WordDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            // 标题
            Text("例句")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            
            // 例句列表
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.relaxed) {
                if details.examples.isEmpty {
                    Text("暂无例句")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(DesignSystem.Spacing.standard)
                } else {
                    ForEach(Array(details.examples.enumerated()), id: \.offset) { index, example in
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                            // 日语例句
                            Text(example.sentence)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // 中文翻译
                            Text(example.translation)
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(DesignSystem.Spacing.standard)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.neutralLightHex)
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                }
            }
            .padding(DesignSystem.Spacing.standard)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - 相关词汇卡片
    private func relatedWordsCard(_ details: WordDetailsViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.standard) {
            // 标题和展开按钮
            HStack {
                Text("相关词汇")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Spacer()
                
                Button(action: { showRelatedWords.toggle() }) {
                    HStack(spacing: 4) {
                        Text(showRelatedWords ? "收起" : "展开")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                        
                        Image(systemName: showRelatedWords ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.primaryHex)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.standard)
            
            // 相关词汇列表
            if showRelatedWords {
                VStack(spacing: DesignSystem.Spacing.compact) {
                    ForEach(details.relatedWords) { relatedWord in
                        Button(action: {
                            // 加载相关词汇的详情
                            viewModel.loadWordDetails()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(relatedWord.word)
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                                    
                                    Text(relatedWord.reading)
                                        .font(DesignSystem.Typography.footnote)
                                        .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                                }
                                
                                Spacer()
                                
                                Text(relatedWord.briefMeaning)
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.neutralDarkHex)
                            }
                            .padding(DesignSystem.Spacing.standard)
                            .background(DesignSystem.Colors.neutralLightHex)
                            .cornerRadius(DesignSystem.CornerRadius.small)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.standard)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - 笔记编辑器
    private var noteEditorView: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // 标题
            HStack {
                Text("添加学习笔记")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                
                Spacer()
                
                Button(action: { showNoteEditor = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.neutralDarkHex)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.standard)
            .padding(.top, DesignSystem.Spacing.standard)
            
            // 文本编辑器
            TextEditor(text: $noteText)
                .font(DesignSystem.Typography.body)
                .padding(DesignSystem.Spacing.compact)
                .frame(minHeight: 200)
                .background(DesignSystem.Colors.neutralLightHex)
                .cornerRadius(DesignSystem.CornerRadius.small)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            
            // 保存按钮
            Button(action: {
                viewModel.addNote(note: noteText)
                showNoteEditor = false
            }) {
                Text("保存笔记")
                    .font(DesignSystem.Typography.body.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.standard)
                    .background(DesignSystem.Colors.primaryHex)
                    .cornerRadius(DesignSystem.CornerRadius.small)
            }
            .padding(.horizontal, DesignSystem.Spacing.standard)
            .padding(.bottom, DesignSystem.Spacing.standard)
        }
        .background(Color.white)
    }
    
    // MARK: - 加载中视图
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primaryHex))
            Text("正在加载...")
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
            Text("加载失败")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                .padding(.bottom, DesignSystem.Spacing.compact)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.standard)
            Button(action: { viewModel.loadWordDetails() }) {
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
}

// MARK: - 预览
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
        let favoriteService = FavoriteService(favoriteRepository: FavoriteDataRepository())
        let viewModel = DetailViewModel(dictionaryService: dictionaryService, favoriteService: favoriteService, wordId: "1989103009")
        
        return DetailView(viewModel: viewModel, wordId: "1989103009")
    }
}
