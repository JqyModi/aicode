//
//  CompleteRichTextView.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/18.
//

import SwiftUI

// MARK: - 完整富文本视图
struct CompleteRichTextView: UIViewRepresentable {
    let htmlString: String
    let onWordTapped: (String, String, String) -> Void

    // 新增：用于缓存上一次的内容
    class TextViewWrapper: UITextView {
        var lastHtmlString: String?
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = TextViewWrapper()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.showsVerticalScrollIndicator = false

        // 设置富文本内容
        updateTextView(textView)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // 只在内容变化时才更新
        if let textView = uiView as? TextViewWrapper {
            if textView.lastHtmlString != htmlString {
                updateTextView(textView)
                textView.lastHtmlString = htmlString
            }
        } else {
            updateTextView(uiView)
        }
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
        private var originalAttributedText: NSAttributedString?
        private var currentHighlightRange: NSRange?
    
        init(_ parent: CompleteRichTextView) {
            self.parent = parent
        }
    
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            // 处理点击事件，获取被点击的单词信息
            if URL.scheme == "word" {
                // 保存原始文本
                originalAttributedText = textView.attributedText
    
                // 添加高亮
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
    
        private func addHighlight(textView: UITextView, range: NSRange) {
            guard let original = textView.attributedText.mutableCopy() as? NSMutableAttributedString else { return }
            original.addAttribute(.backgroundColor, value: UIColor.red.withAlphaComponent(0.3), range: range)
            textView.attributedText = original
            currentHighlightRange = range
    
            // 1.5秒后移除高亮
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.removeHighlight(textView: textView)
            }
        }
    
        private func removeHighlight(textView: UITextView) {
            if let original = originalAttributedText {
                textView.attributedText = original
            }
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
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = 32 // 可根据字体大小调整
            paragraphStyle.lineSpacing = 4        // 适当增加行间
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))
            
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

// MARK: - UITextView布局管理器扩展
extension NSLayoutManager {
    // 获取文本范围的位置信息
    func textRange(for range: NSRange, in textView: UITextView) -> CGRect? {
        guard let textContainer = textContainers.first else { return nil }
        
        // 获取字形范围
        let glyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        
        // 计算字形范围的边界矩形（相对于textContainer）
        var boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // 考虑textContainer的原点偏移
        boundingRect.origin.x += textView.textContainerInset.left
        boundingRect.origin.y += textView.textContainerInset.top
        
        // 考虑文本视图的滚动位置
        boundingRect.origin.x -= textView.contentOffset.x
        boundingRect.origin.y -= textView.contentOffset.y
        
        // 为了更好的视觉效果，稍微扩大高亮区域
        boundingRect.size.width += 4
        boundingRect.size.height += 4
        boundingRect.origin.x -= 2
        boundingRect.origin.y -= 2
        
        return boundingRect
    }
}
