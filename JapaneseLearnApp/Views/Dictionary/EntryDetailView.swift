import SwiftUI

// 添加返回按钮组件
struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text("返回")
                    .font(.system(size: 17))
            }
            .foregroundColor(Color(hex: "00D2DD"))
        }
    }
}

// 选项卡按钮
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(hex: "00D2DD") : Color(hex: "5D6D7E"))
                
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? Color(hex: "00D2DD") : Color.clear)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// 释义行
struct DefinitionRow: View {
    let index: Int
    let definition: Definition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(index)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.white)
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "00D2DD"))
                    .cornerRadius(12)
                
                Text(definition.meaning)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let notes = definition.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "8A9199"))
                    .padding(.leading, 36)
            }
            
            Divider()
                .padding(.vertical, 8)
        }
    }
}

// 例句行
struct ExampleRow: View {
    let example: Example
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(example.sentence)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Spacer()
                
                // 发音按钮
                Button(action: {
                    // 播放例句发音
                }) {
                    Image(systemName: "speaker.wave.2")
                        .foregroundColor(Color(hex: "00D2DD"))
                        .padding(8)
                        .background(Color(hex: "00D2DD").opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Text(example.translation)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "5D6D7E"))
            
            Divider()
                .padding(.vertical, 8)
        }
    }
}

// 变形视图
struct ConjugationView: View {
    let word: String
    
    // 这里简化处理，实际应从API或本地数据获取
    private var conjugations: [(String, String)] {
        return [
            ("现在肯定", "\(word)る"),
            ("现在否定", "\(word)ない"),
            ("过去肯定", "\(word)た"),
            ("过去否定", "\(word)なかった")
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("动词变形")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(conjugations, id: \.0) { form, conjugated in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(form)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "8A9199"))
                        
                        Text(conjugated)
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "2C3E50"))
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "F5F7FA"))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// 添加一个相关词汇部分
struct RelatedWordsSection: View {
    let relatedWords: [DictEntry]
    let onSelect: (DictEntry) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("相关词汇")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedWords, id: \.id) { entry in
                        Button(action: {
                            onSelect(entry)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.word)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(hex: "2C3E50"))
                                
                                Text(entry.reading)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "5D6D7E"))
                                
                                if let definition = entry.definitions.first {
                                    Text(definition.meaning)
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "8A9199"))
                                        .lineLimit(1)
                                }
                            }
                            .padding(12)
                            .frame(width: 160)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 添加学习状态部分
struct LearningStatusSection: View {
    @State private var isLearned: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("学习状态")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                Button(action: {
                    isLearned.toggle()
                }) {
                    HStack {
                        Image(systemName: isLearned ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isLearned ? Color(hex: "4CD964") : Color(hex: "8A9199"))
                        
                        Text(isLearned ? "已学会" : "标记为已学")
                            .font(.system(size: 15))
                            .foregroundColor(isLearned ? Color(hex: "4CD964") : Color(hex: "2C3E50"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isLearned ? Color(hex: "4CD964") : Color(hex: "E1E5EA"), lineWidth: 1)
                    )
                }
                
                Button(action: {
                    // 添加到学习计划
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(Color(hex: "00D2DD"))
                        
                        Text("加入学习计划")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "00D2DD"))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "00D2DD"), lineWidth: 1)
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// 更新EntryDetailView以包含新添加的组件
struct EntryDetailView: View {
    let entry: DictEntry
    @State private var isFavorite: Bool = false
    @State private var selectedTab: Int = 0
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DictionaryViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 顶部区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.word)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Spacer()
                        
                        // 发音按钮
                        Button(action: {
                            viewModel.playPronunciation(for: entry)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(Color.white)
                                .padding(10)
                                .background(Color(hex: "00D2DD"))
                                .clipShape(Circle())
                        }
                        
                        // 收藏按钮
                        Button(action: {
                            isFavorite.toggle()
                            if isFavorite {
                                viewModel.addToFavorites(entry)
                            } else {
                                viewModel.removeFromFavorites(entry)
                            }
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(Color.white)
                                .padding(10)
                                .background(Color(hex: isFavorite ? "FF6B6B" : "8A9199"))
                                .clipShape(Circle())
                        }
                    }
                    
                    Text(entry.reading)
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: "5D6D7E"))
                    
                    Text(entry.partOfSpeech)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A9199"))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color(hex: "F5F7FA"))
                        .cornerRadius(4)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                
                // 选项卡
                HStack {
                    TabButton(title: "释义", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "例句", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    
                    TabButton(title: "变形", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                }
                .padding(.horizontal, 16)
                
                // 内容区域
                VStack(alignment: .leading, spacing: 16) {
                    if selectedTab == 0 {
                        // 释义
                        ForEach(entry.definitions.indices, id: \.self) { index in
                            DefinitionRow(index: index + 1, definition: entry.definitions[index])
                        }
                    } else if selectedTab == 1 {
                        // 例句
                        ForEach(entry.examples.indices, id: \.self) { index in
                            ExampleRow(example: entry.examples[index])
                        }
                    } else {
                        // 变形
                        ConjugationView(word: entry.word)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                
                // 学习状态
                LearningStatusSection()
                
                // 相关词汇
                if !viewModel.relatedWords.isEmpty {
                    RelatedWordsSection(relatedWords: viewModel.relatedWords) { relatedEntry in
                        viewModel.selectEntry(relatedEntry)
                    }
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: BackButton {
            presentationMode.wrappedValue.dismiss()
        })
        .onAppear {
            // 检查是否已收藏
            isFavorite = viewModel.isInFavorites(entry)
            // 加载相关词汇
            viewModel.loadRelatedWords(for: entry)
        }
    }
}
