//
//  JapaneseTextParserViewController.swift
//  JapaneseLearnApp
//
//  Created by AI Assistant on 2023-10-01
//

import UIKit
import SwiftUI

// MARK: - 日语文本解析器视图控制器
class JapaneseTextParserViewController: UIViewController {
    
    // MARK: - UI组件
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "日语富文本解析器示例"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private let resultLabel: UILabel = {
        let label = UILabel()
        label.text = "点击上方文本中的单词查看效果"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.backgroundColor = .systemGray5
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "本示例展示了如何解析HTML格式的日语文本并实现点击交互"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 示例日语文本
    private let sampleJapaneseText = "<ruby ><rb>債務</rb><rp>(</rp><rt roma=\"saimu\" hiragana=\"さいむ\" lemma=\"債務\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"を\" lemma-t=\"\">を</span><ruby n1><rb>返済</rb><rp>(</rp><rt roma=\"hensai\" hiragana=\"へんさい\" lemma=\"返済\" lemma-t=\"\"></rt><rp>)</rp></ruby><span class=\"moji-toolkit-org\"  lemma=\"為る\" lemma-t=\"\">する</span><span class=\"moji-toolkit-org\"  lemma=\"。\" lemma-t=\"\">。</span>"
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTextView()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加UI组件
        view.addSubview(titleLabel)
        view.addSubview(textView)
        view.addSubview(resultLabel)
        view.addSubview(descriptionLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            resultLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resultLabel.heightAnchor.constraint(equalToConstant: 50),
            
            descriptionLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - 设置文本视图
    private func setupTextView() {
        textView.delegate = self
        
        // 解析HTML并设置富文本
        if let attributedText = parseJapaneseHTML(sampleJapaneseText) {
            textView.attributedText = attributedText
        }
    }
    
    // MARK: - 解析日语HTML文本
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
                    
                    // 创建带有注音的富文本
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
    
    // MARK: - 创建带有Ruby注释的富文本
    private func createRubyAttributedString(word: String, furigana: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.black,
            .link: URL(string: "word://\(word)")!,
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
    
    // MARK: - 创建普通文本的富文本
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
    
    // MARK: - 处理单词点击
    private func handleWordTapped(_ word: String) {
        resultLabel.text = "选中的单词: \(word)"
        print("被点击的单词: \(word)")
    }
}

// MARK: - UITextViewDelegate
extension JapaneseTextParserViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        // 处理点击事件，获取被点击的单词
        if URL.scheme == "word" {
            let word = URL.host ?? ""
            handleWordTapped(word)
        }
        return false
    }
}

// MARK: - SwiftUI预览
struct JapaneseTextParserViewController_Preview: PreviewProvider {
    static var previews: some View {
        UIViewControllerPreview {
            JapaneseTextParserViewController()
        }
    }
}

// MARK: - UIViewController预览辅助结构
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
    let viewController: () -> ViewController
    
    init(_ viewController: @escaping () -> ViewController) {
        self.viewController = viewController
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        return viewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // 不需要更新
    }
}