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

    // TextViewWrapper 保持不变，其 attributedText.didSet 中的 invalidateIntrinsicContentSize() 是正确的
    class TextViewWrapper: UITextView {
        var lastHtmlString: String?
        private var lastKnownWidth: CGFloat = 0 // 新增：用于跟踪上一次已知的宽度

        override var attributedText: NSAttributedString! {
            didSet {
                if oldValue != attributedText {
                    // 当文本内容变化时，通知系统固有内容大小已更改
                    self.invalidateIntrinsicContentSize()
                }
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // 如果 UITextView 的宽度发生变化，并且是一个有效值，
            // 则记录新宽度并使固有内容大小无效，以便 SwiftUI 重新查询。
            if self.bounds.width > 0 && self.bounds.width != lastKnownWidth {
                lastKnownWidth = self.bounds.width
                self.invalidateIntrinsicContentSize()
            }
        }
        
        override var intrinsicContentSize: CGSize {
            // 如果宽度仍然未定义或为0（可能在初始布局阶段），
            // 返回 .noIntrinsicMetric。layoutSubviews 中的逻辑将确保在宽度确定后重新计算。
            if bounds.width <= 0 {
                // 移除之前的 print(UIView.noIntrinsicMetric) 以减少控制台噪音，
                // 因为在宽度确定前，这个路径被执行是正常的。
                return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
            }

            // 使用当前已确定的 bounds.width 来计算内容所需的大小。
            // sizeThatFits 是 UITextView 计算其内容大小的推荐方法。
            let constrainingSize = CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
            var calculatedSize = self.sizeThatFits(constrainingSize)
            
            // 确保即使内容为空，也有一个最小高度，例如基于字体行高。
            // parseJapaneseHTML 中设置的 minimumLineHeight (32) 应该会被 sizeThatFits 尊重。
            // 此处额外处理 htmlString 为空，导致 attributedText 为空的情况。
            if attributedText.length == 0 {
                let minHeightBasedOnFont = self.font?.lineHeight ?? 18 // 如果字体未设置，则默认为18
                if calculatedSize.height < minHeightBasedOnFont {
                    calculatedSize.height = minHeightBasedOnFont
                }
            }
            
            // 对于宽度，我们返回 UIView.noIntrinsicMetric，因为 SwiftUI 会根据其约束来控制宽度。
            // 对于高度，我们返回基于内容计算出的高度。
            // print("intrinsicContentSize - calculatedSize: \(calculatedSize) for width: \(bounds.width)") // 调试日志
            return CGSize(width: UIView.noIntrinsicMetric, height: calculatedSize.height)
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = TextViewWrapper()
        textView.isEditable = false
        textView.isSelectable = true // 允许选择文本以触发链接
        textView.isScrollEnabled = false // 关键：禁用滚动以实现内容自适应高度
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.showsVerticalScrollIndicator = false
//        textView.backgroundColor = .red
        textView.tintColor = UIColor(AppTheme.Colors.primary)

        // 移除文本容器的内边距和行片段边距，确保精确计算内容大小
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        // 设置内容拥抱和抗压缩优先级，帮助 SwiftUI 正确处理动态高度
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)

        // updateTextView(textView) // 初始内容设置将由 updateUIView 首次调用时处理
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard let textView = uiView as? TextViewWrapper else { return }

        // 仅当 htmlString 实际更改时才更新文本
        if textView.lastHtmlString != htmlString {
            if let newAttributedText = parseJapaneseHTML(htmlString) {
                textView.attributedText = newAttributedText
            } else {
                textView.attributedText = NSAttributedString(string: "")
            }
            textView.lastHtmlString = htmlString
            // attributedText 的 didSet 中已经调用了 invalidateIntrinsicContentSize()，
            // 所以这里通常不需要再次调用。
            // textView.invalidateIntrinsicContentSize() // 可以移除或注释掉
        }
        // 移除这里的 sizeToFit()，让 SwiftUI 和 intrinsicContentSize 处理尺寸。
        // textView.sizeToFit() // REMOVE THIS LINE
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
            
            // 移除这里的日志，因为它在 intrinsicContentSize 中使用 bounds.width 更为关键
            // let size2 = attributedString.boundingRect(with: CGSize(width: 120, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
            // print("size2: \(size2)") 
            
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

#Preview(body: {
    let inputText: String = "<span class=\"moji-toolkit-org\" n5 lemma=\"其の\" lemma-t=\"\">その</span><ruby n3><rb>借金</rb><rp>(</rp><rt roma=\"shakkin\" hiragana=\"しゃっきん\" lemma=\"借金\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"の\" lemma-t=\"\">の</span><ruby n1><rb>返済</rb><rp>(</rp><rt roma=\"hensai\" hiragana=\"へんさい\" lemma=\"返済\" lemma-t=\"\"></rt><rp>)</rp></ruby><ruby n3><rb>期限</rb><rp>(</rp><rt roma=\"kigen\" hiragana=\"きげん\" lemma=\"期限\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"は\" lemma-t=\"\">は</span><ruby n5><rb>今月</rb><rp>(</rp><rt roma=\"kongetsu\" hiragana=\"こんげつ\" lemma=\"今月\" lemma-t=\"\"></rt><rp>)</rp></ruby><ruby n3><rb>末</rb><rp>(</rp><rt roma=\"matsu\" hiragana=\"まつ\" lemma=\"末\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"だ\" lemma-t=\"\">だ</span><span class=\"moji-toolkit-org\"  lemma=\"。\" lemma-t=\"\">。</span>"
    VStack(alignment: .leading, spacing: 12) {
        CompleteRichTextView(htmlString: inputText) { word, lemma, furigana in
            // 处理单词点击事件
            print("点击了单词: \(word), 词元: \(lemma), 假名: \(furigana)")
        }
        // 将 frame 修饰符直接应用于 CompleteRichTextView，而不是其父 VStack，以便更直接地传递宽度约束
        .frame(maxWidth: 100) //  <-- 尝试将宽度约束直接应用在这里
//        .frame(width: 120)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        
        Text("点击 console 输出日志，查看单词点击事件。")
        Spacer()
    }
//     .frame(maxWidth: 200, maxHeight: .infinity) // 如果上面已经对 CompleteRichTextView 设置了 maxWidth，这里的 VStack frame 可能不需要再限制宽度
    .padding() // 给 VStack 一些边距，使其内容不会紧贴屏幕边缘
})
