//
//  CompleteJapaneseTextParserDemo.swift
//  JapaneseLearnApp
//
//  Created by AI Assistant on 2023-10-01
//

import SwiftUI
import UIKit

// MARK: - 完整的日语文本解析器示例
struct CompleteJapaneseTextParserDemo: View {
    @State private var selectedWord: String = ""
    @State private var selectedLemma: String = ""
    @State private var selectedFurigana: String = ""
    //    @State private var inputText: String = "<ruby ><rb>債務</rb><rp>(</rp><rt roma=\"saimu\" hiragana=\"さいむ\" lemma=\"債務\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"を\" lemma-t=\"\">を</span><ruby n1><rb>返済</rb><rp>(</rp><rt roma=\"hensai\" hiragana=\"へんさい\" lemma=\"返済\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"為る\" lemma-t=\"\">する</span><span class=\"moji-toolkit-org\"  lemma=\"。\" lemma-t=\"\">。</span>"
    @State private var inputText: String = "<span class=\"moji-toolkit-org\" n5 lemma=\"其の\" lemma-t=\"\">その</span><ruby n3><rb>借金</rb><rp>(</rp><rt roma=\"shakkin\" hiragana=\"しゃっきん\" lemma=\"借金\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"の\" lemma-t=\"\">の</span><ruby n1><rb>返済</rb><rp>(</rp><rt roma=\"hensai\" hiragana=\"へんさい\" lemma=\"返済\" lemma-t=\"\"></rt><rp>)</rp></ruby><ruby n3><rb>期限</rb><rp>(</rp><rt roma=\"kigen\" hiragana=\"きげん\" lemma=\"期限\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"は\" lemma-t=\"\">は</span><ruby n5><rb>今月</rb><rp>(</rp><rt roma=\"kongetsu\" hiragana=\"こんげつ\" lemma=\"今月\" lemma-t=\"\"></rt><rp>)</rp></ruby><ruby n3><rb>末</rb><rp>(</rp><rt roma=\"matsu\" hiragana=\"まつ\" lemma=\"末\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"だ\" lemma-t=\"\">だ</span><span class=\"moji-toolkit-org\"  lemma=\"。\" lemma-t=\"\">。</span>"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("完整日语富文本解析示例")
                .font(.title)
                .padding(.top, 20)
            
            // 输入区域
            VStack(alignment: .leading) {
                Text("HTML输入:")
                    .font(.headline)
                TextEditor(text: $inputText)
                    .frame(height: 100)
                    .font(.system(size: 14, design: .monospaced))
                    .border(Color.gray, width: 1)
                
                Button("解析文本") {
                    // 重置选中状态
                    selectedWord = ""
                    selectedLemma = ""
                    selectedFurigana = ""
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // 富文本展示区域
            VStack(alignment: .leading) {
                Text("解析结果:")
                    .font(.headline)
                
                CompleteRichTextView(htmlString: inputText) { word, lemma, furigana in
                    self.selectedWord = word
                    self.selectedLemma = lemma
                    self.selectedFurigana = furigana
                }
                .frame(width: 180, height: 150)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // 显示选中的单词信息
            if !selectedWord.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("选中的单词信息:")
                        .font(.headline)
                    
                    HStack {
                        Text("单词:")
                            .fontWeight(.bold)
                        Text(selectedWord)
                    }
                    
                    if !selectedLemma.isEmpty {
                        HStack {
                            Text("词元:")
                                .fontWeight(.bold)
                            Text(selectedLemma)
                        }
                    }
                    
                    if !selectedFurigana.isEmpty {
                        HStack {
                            Text("假名:")
                                .fontWeight(.bold)
                            Text(selectedFurigana)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
}
// MARK: - 预览
struct CompleteJapaneseTextParserDemo_Previews: PreviewProvider {
    static var previews: some View {
        CompleteJapaneseTextParserDemo()
    }
}
