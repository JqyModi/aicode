//
//  CompleteRichTextView.swift
//  JapaneseLearnApp
//
//  Created by AI Assistant on 2023-10-01
//

import SwiftUI
import UIKit
import CoreText

// MARK: - 完整富文本视图
struct CompleteRichTextView: UIViewRepresentable {
    let htmlString: String
    let onWordTapped: (String, String, String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        
        // 设置富文本内容
        updateTextView(textView)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 更新视图
        updateTextView(uiView)
    }
    
    private func updateTextView(_ textView: UITextView) {
        if let attributedText = parseJapaneseHTML(htmlString) {
            textView.attributedText = attributedText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 协调器处理点击事件
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CompleteRichTextView
        // 当前高亮的文本范围
        private var currentHighlightRange: NSRange?
        // 当前高亮的背景视图
        private var highlightView: UIView?
        
        init(_ parent: CompleteRichTextView) {
            self.parent = parent
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // 处理点击事件，获取被点击的单词信息
            if URL.scheme == "word" {
                // 移除之前的高亮效果
                removeHighlight()
                
                // 添加新的高亮效果
                addHighlight(textView: textView, range: characterRange)
                
                let components = URL.absoluteString.components(separatedBy: "?")
                if components.count > 1 {
                    let queryItems = components[1].components(separatedBy: "&")
                    var word = ""
                    var lemma = ""
                    var furigana = ""
                    
                    for item in queryItems {
                        let keyValue = item.components(separatedBy: "=")
                        if keyValue.count == 2 {
                            let key = keyValue[0]
                            let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                            
                            switch key {
                            case "word":
                                word = value
                            case "lemma":
                                lemma = value
                            case "furigana":
                                furigana = value
                            default:
                                break
                            }
                        }
                    }
                    
                    parent.onWordTapped(word, lemma, furigana)
                } else {
                    // 兼容旧格式
                    let word = URL.host ?? ""
                    parent.onWordTapped(word, "", "")
                }
            }
            return false
        }
        
        // 添加高亮效果
        private func addHighlight(textView: UITextView, range: NSRange) {
            // 保存当前高亮范围
            currentHighlightRange = range
            
            // 获取文本范围的位置信息
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            
            var glyphRange = NSRange()
            layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
            
            let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            
            // 创建高亮背景视图
            let highlightView = UIView()
            highlightView.backgroundColor = UIColor(Color("Primary")).withAlphaComponent(0.3)
            highlightView.layer.cornerRadius = 3
            highlightView.alpha = 0 // 初始透明度为0，用于淡入效果
            textView.addSubview(highlightView)
            
            // 设置高亮视图的位置和大小
            highlightView.frame = boundingRect
            
            // 保存高亮视图的引用
            self.highlightView = highlightView
            
            // 添加淡入动画
            UIView.animate(withDuration: 0.3, animations: {
                highlightView.alpha = 1
            }) { _ in
                // 淡入完成后，延迟一段时间后淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.fadeOutHighlight()
                }
            }
        }
        
        // 淡出高亮效果
        private func fadeOutHighlight() {
            guard let highlightView = self.highlightView else { return }
            
            UIView.animate(withDuration: 0.5, animations: {
                highlightView.alpha = 0
            }) { _ in
                self.removeHighlight()
            }
        }
        
        // 移除高亮效果
        private func removeHighlight() {
            // 移除高亮视图
            highlightView?.removeFromSuperview()
            highlightView = nil
            currentHighlightRange = nil
        }
    }
    
    // 解析日语HTML文本
    private func parseJapaneseHTML(_ html: String) -> NSAttributedString? {
        // 创建一个NSMutableAttributedString来构建富文本
        let attributedString = NSMutableAttributedString()
        
        // 使用正则表达式匹配不同类型的标签
        do {
            // 1. 匹配ruby标签
            let rubyPattern = "<ruby[^>]*>\\s*<rb>([^<]+)</rb>\\s*<rp>\\([^<]*</rp>\\s*<rt[^>]*roma=\"([^\"]*)\"\\s*hiragana=\"([^\"]*)\"\\s*lemma=\"([^\"]*)\"[^>]*></rt>\\s*<rp>[^<]*</rp>\\s*</ruby>"
            let rubyRegex = try NSRegularExpression(pattern: rubyPattern, options: [])
            
            // 2. 匹配span标签
            let spanPattern = "<span[^>]*lemma=\"([^\"]+)\"[^>]*>([^<]+)</span>"
            let spanRegex = try NSRegularExpression(pattern: spanPattern, options: [])
            
            // 创建一个临时的字符串用于处理
            var tempString = html
            
            // 处理所有ruby标签
            while let match = rubyRegex.firstMatch(in: tempString, options: [], range: NSRange(location: 0, length: tempString.utf16.count)) {
                if let wordRange = Range(match.range(at: 1), in: tempString),
                   let romaRange = Range(match.range(at: 2), in: tempString),
                   let furiganaRange = Range(match.range(at: 3), in: tempString),
                   let lemmaRange = Range(match.range(at: 4), in: tempString),
                   let fullMatchRange = Range(match.range, in: tempString) {
                    
                    let word = String(tempString[wordRange])
                    let roma = String(tempString[romaRange])
                    let furigana = String(tempString[furiganaRange])
                    let lemma = String(tempString[lemmaRange])
                    
                    // 创建带有注音的富文本
                    let wordAttr = createRubyAttributedString(word: word, furigana: furigana, lemma: lemma, roma: roma)
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
            
            // 处理剩余的纯文本
            if !tempString.isEmpty {
                let plainAttr = NSAttributedString(string: tempString, attributes: [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ])
                attributedString.append(plainAttr)
            }
            
            return attributedString
        } catch {
            print("正则表达式错误: \(error)")
            return nil
        }
    }
    
    // 创建带有Ruby注释的富文本
    private func createRubyAttributedString(word: String, furigana: String, lemma: String, roma: String) -> NSAttributedString {
        // 构建URL查询参数
        var urlComponents = URLComponents(string: "word://example.com")
        urlComponents?.queryItems = [
            URLQueryItem(name: "word", value: word),
            URLQueryItem(name: "lemma", value: lemma),
            URLQueryItem(name: "furigana", value: furigana),
            URLQueryItem(name: "roma", value: roma)
        ]
        
        let url = urlComponents?.url ?? URL(string: "word://example.com")!
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
            .link: url,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
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
        // 构建URL查询参数
        var urlComponents = URLComponents(string: "word://example.com")
        urlComponents?.queryItems = [
            URLQueryItem(name: "word", value: text),
            URLQueryItem(name: "lemma", value: lemma)
        ]
        
        // 安全地创建URL，避免强制解包
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // 只有当URL成功创建时才添加链接属性
        if let url = urlComponents?.url {
            attributes[.link] = url
        }
        
        return NSAttributedString(string: text, attributes: attributes)
    }
}