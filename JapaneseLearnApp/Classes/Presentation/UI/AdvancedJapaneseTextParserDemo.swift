//
//  AdvancedJapaneseTextParserDemo.swift
//  JapaneseLearnApp
//
//  Created by AI Assistant on 2023-10-01
//

import SwiftUI
import UIKit

// MARK: - 高级日语文本解析器示例
struct AdvancedJapaneseTextParserDemo: View {
    @State private var selectedWord: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("高级日语富文本解析示例")
                .font(.title)
                .padding(.top, 20)
            
            // 富文本展示区域
            AdvancedRichTextView(htmlString: sampleJapaneseText) { word in
                self.selectedWord = word
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // 显示选中的单词
            if !selectedWord.isEmpty {
                Text("选中的单词: \(selectedWord)")
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // 说明文本
            Text("点击上方文本中的单词查看效果，使用原生Ruby注释实现")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 10)
            
            Spacer()
        }
        .padding()
    }
    
    // 示例日语文本
    private let sampleJapaneseText = "<ruby ><rb>債務</rb><rp>(</rp><rt roma=\"saimu\" hiragana=\"さいむ\" lemma=\"債務\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"を\" lemma-t=\"\">を</span><ruby n1><rb>返済</rb><rp>(</rp><rt roma=\"hensai\" hiragana=\"へんさい\" lemma=\"返済\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"為る\" lemma-t=\"\">する</span><span class=\"moji-toolkit-org\"  lemma=\"。\" lemma-t=\"\">。</span>"
}

// MARK: - 高级富文本视图
struct AdvancedRichTextView: UIViewRepresentable {
    let htmlString: String
    let onWordTapped: (String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        
        // 设置富文本内容
        if let attributedText = parseJapaneseHTML(htmlString) {
            textView.attributedText = attributedText
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 更新视图（如果需要）
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 协调器处理点击事件
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AdvancedRichTextView
        
        init(_ parent: AdvancedRichTextView) {
            self.parent = parent
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // 处理点击事件，获取被点击的单词
            if URL.scheme == "word" {
                let word = URL.host ?? ""
                parent.onWordTapped(word)
            }
            return false
        }
    }
    
    // 解析日语HTML文本
    private func parseJapaneseHTML(_ html: String) -> NSAttributedString? {
        // 创建一个NSMutableAttributedString来构建富文本
        let attributedString = NSMutableAttributedString()
        
        // 使用正则表达式匹配不同类型的标签
        do {
            // 1. 匹配ruby标签
            let rubyPattern = "<ruby[^>]*>\\s*<rb>([^<]+)</rb>\\s*<rp>\\([^<]*</rp>\\s*<rt[^>]*hiragana=\"([^\"]+)\"[^>]*></rt>\\s*<rp>[^<]*</rp>\\s*</ruby>"
            let rubyRegex = try NSRegularExpression(pattern: rubyPattern, options: [])
            
            // 2. 匹配span标签
            let spanPattern = "<span[^>]*lemma=\"([^\"]+)\"[^>]*>([^<]+)</span>"
            let spanRegex = try NSRegularExpression(pattern: spanPattern, options: [])
            
            // 创建一个临时的字符串用于处理
            var tempString = html
            
            // 处理所有ruby标签
            while let match = rubyRegex.firstMatch(in: tempString, options: [], range: NSRange(location: 0, length: tempString.utf16.count)) {
                if let wordRange = Range(match.range(at: 1), in: tempString),
                   let furiganaRange = Range(match.range(at: 2), in: tempString),
                   let fullMatchRange = Range(match.range, in: tempString) {
                    
                    let word = String(tempString[wordRange])
                    let furigana = String(tempString[furiganaRange])
                    
                    // 创建带有注音的富文本（使用原生Ruby注释）
                    let wordAttr = createRubyAttributedString(word: word, furigana: furigana)
                    attributedString.append(wordAttr)
                    
                    // 从临时字符串中移除已处理的部分
                    tempString.removeSubrange(fullMatchRange)
                }
            }
            
            // 处理所有span标签
            while let match = spanRegex.firstMatch(in: tempString, options: [], range: NSRange(location: 0, length: tempString.utf16.count)) {
                if let lemmaRange = Range(match.range(at: 1), in: tempString),
                   let textRange = Range(match.range(at: 2), in: tempString),
                   let fullMatchRange = Range(match.range, in: tempString) {
                    
                    let lemma = String(tempString[lemmaRange])
                    let text = String(tempString[textRange])
                    
                    // 创建普通文本的富文本
                    let spanAttr = createSpanAttributedString(text: text, lemma: lemma)
                    attributedString.append(spanAttr)
                    
                    // 从临时字符串中移除已处理的部分
                    tempString.removeSubrange(fullMatchRange)
                }
            }
            
            return attributedString
        } catch {
            print("正则表达式错误: \(error)")
            return nil
        }
    }
    
    // 创建带有Ruby注释的富文本（使用NSAttributedString.Key.ruby）
    private func createRubyAttributedString(word: String, furigana: String) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // 安全地创建URL，避免强制解包
        if let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
           let url = URL(string: "word://\(encodedWord)") {
            attributes[.link] = url
        }
        
        let attributedString = NSMutableAttributedString(string: word, attributes: attributes)
        
        // 使用Ruby注释（iOS 8及以上支持）
        if #available(iOS 8.0, *) {
            // 创建Ruby注释
            let rubyAnnotation = CTRubyAnnotationCreateWithAttributes(
                .auto, // 对齐方式
                .auto, // 位置
                .before, // 保留
                furigana as CFString, // 注音文本
                [kCTRubyAnnotationSizeFactorAttributeName: 0.5] as CFDictionary // 大小因子
            )
            
            // 应用Ruby注释到整个文本
            attributedString.addAttribute(
                NSAttributedString.Key(kCTRubyAnnotationAttributeName as String),
                value: rubyAnnotation,
                range: NSRange(location: 0, length: word.count)
            )
        }
        
        return attributedString
    }
    
    // 创建普通文本的富文本
    private func createSpanAttributedString(text: String, lemma: String) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // 安全地创建URL，避免强制解包
        if let encodedLemma = lemma.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
           let url = URL(string: "word://\(encodedLemma)") {
            attributes[.link] = url
        }
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}

// MARK: - 预览
struct AdvancedJapaneseTextParserDemo_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedJapaneseTextParserDemo()
    }
}