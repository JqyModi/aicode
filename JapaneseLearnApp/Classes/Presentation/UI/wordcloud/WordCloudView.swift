//
//  WordCloudView.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/12.
//

//import UIKit
//import SwiftUI
//
//struct WordCloudWord {
//    let text: String
//    let frequency: Int
//}
//
//class WordCloudView: UIView {
//    var words: [WordCloudWord] = []
//    var wordTapped: ((String) -> Void)? // 点击回调
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        // 只生成一次
//        if self.subviews.isEmpty && !bounds.isEmpty {
//            generateWordCloud()
//        }
//    }
//    
//    func generateWordCloud() {
//        // 先清理旧 labels
//        self.subviews.forEach { $0.removeFromSuperview() }
//
//        // 如果尺寸还没定，暂不布局
//        guard !bounds.isEmpty else { return }
//
//        let maxFreq = words.map { $0.frequency }.max() ?? 1
//        let minFontSize: CGFloat = 12
//        let maxFontSize: CGFloat = 40
//        var placedFrames: [CGRect] = []
//
//        for word in words.shuffled() {
//            let fontSize = minFontSize + CGFloat(word.frequency) / CGFloat(maxFreq) * (maxFontSize - minFontSize)
//            let label = UILabel()
//            label.text = word.text
//            label.font = .systemFont(ofSize: fontSize, weight: .bold)
//            label.textColor = randomColor()
//            label.sizeToFit()
//
//            // 🛠️ 跳过太大的词
//            if label.bounds.width > bounds.width || label.bounds.height > bounds.height {
//                continue
//            }
//
//            var placed = false
//            for _ in 0..<100 {
//                let x = CGFloat.random(in: 0...(bounds.width - label.bounds.width))
//                let y = CGFloat.random(in: 0...(bounds.height - label.bounds.height))
//                let frame = CGRect(x: x, y: y, width: label.bounds.width, height: label.bounds.height)
//
//                if !placedFrames.contains(where: { $0.intersects(frame.insetBy(dx: -4, dy: -4)) }) {
//                    label.frame = frame
//                    placedFrames.append(frame)
//                    placed = true
//                    break
//                }
//            }
//
//            if placed {
//                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
//                label.isUserInteractionEnabled = true
//                label.addGestureRecognizer(tap)
//                self.addSubview(label)
//            }
//        }
//    }
//
//    
//    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
//        if let label = gesture.view as? UILabel, let text = label.text {
//            wordTapped?(text)
//        }
//    }
//    
//    private func randomColor() -> UIColor {
//        return UIColor(
//            hue: CGFloat.random(in: 0...1),
//            saturation: 0.5 + CGFloat.random(in: 0...0.5),
//            brightness: 0.7 + CGFloat.random(in: 0...0.3),
//            alpha: 1.0
//        )
//    }
//}
//
//struct WordCloudViewRepresentable: UIViewRepresentable {
//    let words: [WordCloudWord]
//    let onWordTap: (String) -> Void
//    
//    func makeUIView(context: Context) -> WordCloudView {
//        let view = WordCloudView()
//        view.wordTapped = onWordTap
//        return view
//    }
//    
//    func updateUIView(_ uiView: WordCloudView, context: Context) {
//        uiView.words = words
//        uiView.generateWordCloud()
//    }
//}
//
//struct WordCloudUIView: View {
//    @State private var tappedWord: String? = nil
//    
//    let words = [
//        WordCloudWord(text: "表格", frequency: 15),
//        WordCloudWord(text: "文档", frequency: 12),
//        WordCloudWord(text: "云盘", frequency: 10),
//        WordCloudWord(text: "分享", frequency: 8),
//        WordCloudWord(text: "笔记", frequency: 6),
//        WordCloudWord(text: "思维", frequency: 11),
//        WordCloudWord(text: "喜欢", frequency: 9),
//        WordCloudWord(text: "设置", frequency: 7),
//        WordCloudWord(text: "权限", frequency: 5),
//        WordCloudWord(text: "文案", frequency: 4),
//        WordCloudWord(text: "反馈", frequency: 6),
//        WordCloudWord(text: "收集", frequency: 3),
//        WordCloudWord(text: "多维", frequency: 8)
//    ]
//    
//    var body: some View {
//        VStack {
//            Text("词云示例")
//                .font(.title)
//                .padding()
//            
//            WordCloudViewRepresentable(words: words) { word in
//                tappedWord = word
//            }
//            .frame(width: 300, height: 300)
////            .clipShape(Circle())
//            .shadow(radius: 4)
//        }
//        .alert(item: $tappedWord) { word in
//            Alert(title: Text("你点击了"), message: Text(word), dismissButton: .default(Text("好的")))
//        }
//    }
//}
//
//extension String: Identifiable {
//    public var id: String { self }
//}




// -------------------------------------------------------------------------------
// WordCloudView 优化版
//import SwiftUI
//import UIKit
//
//struct WordCloudWord {
//    let text: String
//    let frequency: Int
//}
//
//struct WordCloudView: View {
//    @State private var tappedWord: String? = nil
//
//    let words = [
//        WordCloudWord(text: "苹果", frequency: 15),
//        WordCloudWord(text: "香蕉", frequency: 12),
//        WordCloudWord(text: "葡萄", frequency: 9),
//        WordCloudWord(text: "西瓜", frequency: 8),
//        WordCloudWord(text: "草莓", frequency: 7),
//        WordCloudWord(text: "橙子", frequency: 6),
//        WordCloudWord(text: "芒果", frequency: 5),
//        WordCloudWord(text: "樱桃", frequency: 5),
//        WordCloudWord(text: "柠檬", frequency: 4),
//        WordCloudWord(text: "蓝莓", frequency: 3),
//        WordCloudWord(text: "李子", frequency: 3),
//        WordCloudWord(text: "桃子", frequency: 6),
//        WordCloudWord(text: "奇异果", frequency: 4),
//        WordCloudWord(text: "葡萄柚", frequency: 3)
//    ]
//
//    var body: some View {
//        VStack {
//            Text("词云示例")
//                .font(.title)
//                .padding()
//
//            WordCloudViewRepresentable(words: words) { word in
//                tappedWord = word
//            }
//            .frame(width: 300, height: 300)
//            .shadow(radius: 4)
//        }
//        .alert(item: $tappedWord) { word in
//            Alert(title: Text("你点击了"), message: Text(word), dismissButton: .default(Text("好的")))
//        }
//    }
//}
//
//struct WordCloudViewRepresentable: UIViewRepresentable {
//    let words: [WordCloudWord]
//    let onWordTap: (String) -> Void
//
//    func makeUIView(context: Context) -> WordCloudUIView {
//        let view = WordCloudUIView()
//        view.wordTapped = onWordTap
//        return view
//    }
//
//    func updateUIView(_ uiView: WordCloudUIView, context: Context) {
//        uiView.words = words
//        uiView.generateWordCloud()
//    }
//}
//
//class WordCloudUIView: UIView {
//    var words: [WordCloudWord] = []
//    var wordTapped: ((String) -> Void)?
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        // 只生成一次
//        if self.subviews.isEmpty && !bounds.isEmpty {
//            generateWordCloud()
//        }
//    }
//
//    func generateWordCloud() {
//        self.subviews.forEach { $0.removeFromSuperview() }
//        guard !bounds.isEmpty else { return }
//
//        let radius = min(bounds.width, bounds.height) / 2
//        let center = CGPoint(x: bounds.midX, y: bounds.midY)
//
//        let maxFreq = words.map { $0.frequency }.max() ?? 1
//        let minFontSize: CGFloat = 12
//        let maxFontSize: CGFloat = 40
//
//        var placedFrames: [CGRect] = []
//
//        for word in words.shuffled() {
//            let fontSize = minFontSize + CGFloat(word.frequency) / CGFloat(maxFreq) * (maxFontSize - minFontSize)
//            let label = UILabel()
//            label.text = word.text
//            label.font = .systemFont(ofSize: fontSize, weight: .bold)
//            label.textColor = randomColor()
//            label.sizeToFit()
//
//            if label.bounds.width > bounds.width || label.bounds.height > bounds.height {
//                continue
//            }
//
//            var placed = false
//            for _ in 0..<100 {
//                let angle = CGFloat.random(in: 0..<(2 * .pi))
//                let distance = CGFloat.random(in: 0...(radius - max(label.bounds.width, label.bounds.height) / 2))
//                let x = center.x + distance * cos(angle) - label.bounds.width / 2
//                let y = center.y + distance * sin(angle) - label.bounds.height / 2
//                let frame = CGRect(x: x, y: y, width: label.bounds.width, height: label.bounds.height)
//
//                // Check if inside circle
//                let labelCenter = CGPoint(x: frame.midX, y: frame.midY)
//                let dx = labelCenter.x - center.x
//                let dy = labelCenter.y - center.y
//                if sqrt(dx*dx + dy*dy) + max(frame.width, frame.height)/2 > radius {
//                    continue
//                }
//
//                // Check overlap (tight spacing)
//                if !placedFrames.contains(where: { $0.intersects(frame.insetBy(dx: -1, dy: -1)) }) {
//                    label.frame = frame
//
//                    // Optional random rotation (more lively)
//                    if Bool.random() {
//                        label.transform = CGAffineTransform(rotationAngle: .pi / 2)
//                    }
//
//                    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
//                    label.isUserInteractionEnabled = true
//                    label.addGestureRecognizer(tap)
//
//                    self.addSubview(label)
//                    placedFrames.append(frame)
//                    placed = true
//                    break
//                }
//            }
//
//            if !placed {
//                continue
//            }
//        }
//    }
//
//    @objc func handleTap(_ sender: UITapGestureRecognizer) {
//        guard let label = sender.view as? UILabel, let text = label.text else { return }
//        wordTapped?(text)
//    }
//
//    func randomColor() -> UIColor {
//        // 柔和颜色方案 (蓝绿紫范围)
//        let hue = CGFloat.random(in: 0.55...0.75)
//        let saturation = CGFloat.random(in: 0.4...0.7)
//        let brightness = CGFloat.random(in: 0.7...1.0)
//        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
//    }
//}
//
//extension String: Identifiable {
//    public var id: String { self }
//}
//
//#Preview {
//    WordCloudView()
//}




// -------------------------------------------------------------------------------
//import SwiftUI
//
//struct WordCloudWord {
//    let text: String
//    let frequency: Int
//}
//
//struct WordCloudView: View {
//    @State private var tappedWord: String? = nil
//    @State private var wordPositions: [CGRect] = []
//
//    let words = [
//        WordCloudWord(text: "苹果", frequency: 15),
//        WordCloudWord(text: "香蕉", frequency: 12),
//        WordCloudWord(text: "橘子", frequency: 9),
//        WordCloudWord(text: "西瓜", frequency: 7),
//        WordCloudWord(text: "桃子", frequency: 8),
//        WordCloudWord(text: "葡萄", frequency: 5),
//        WordCloudWord(text: "芒果", frequency: 6),
//        WordCloudWord(text: "柠檬", frequency: 4),
//        WordCloudWord(text: "草莓", frequency: 6),
//        WordCloudWord(text: "李子", frequency: 8)
//    ]
//
//    var body: some View {
//        GeometryReader { geo in
//            ZStack {
//                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
//                    WordView(word: word.text,
//                             frequency: word.frequency,
//                             isHighlighted: tappedWord == word.text)
//                        .position(randomPosition(in: geo.size, index: index))
//                        .onTapGesture {
//                            tappedWord = word.text
//                        }
//                }
//            }
//            .alert(item: $tappedWord) { word in
//                Alert(title: Text("你点击了"), message: Text(word), dismissButton: .default(Text("好的")))
//            }
//        }
//    }
//
//    // 伪随机：防止完全重叠（简单版本，生产级可换成更复杂算法）
//    func randomPosition(in size: CGSize, index: Int) -> CGPoint {
//        let cols = Int(sqrt(Double(words.count)).rounded(.up))
//        let rows = (words.count + cols - 1) / cols
//        let gridW = size.width / CGFloat(cols)
//        let gridH = size.height / CGFloat(rows)
//
//        let col = index % cols
//        let row = index / cols
//
//        let baseX = gridW * CGFloat(col) + gridW / 2
//        let baseY = gridH * CGFloat(row) + gridH / 2
//
//        let jitterX = CGFloat.random(in: -gridW * 0.2...gridW * 0.2)
//        let jitterY = CGFloat.random(in: -gridH * 0.2...gridH * 0.2)
//
//        return CGPoint(x: baseX + jitterX, y: baseY + jitterY)
//    }
//}
//
//struct WordView: View {
//    let word: String
//    let frequency: Int
//    let isHighlighted: Bool
//
//    var body: some View {
//        Text(word)
//            .font(.system(size: CGFloat(12 + frequency)))
//            .foregroundColor(isHighlighted ? .white : randomColor())
//            .padding(4)
//            .background(isHighlighted ? Color.blue : Color.clear)
//            .cornerRadius(4)
//            .shadow(radius: 2)
//            .rotationEffect(.degrees(Double.random(in: -15...15)))
//    }
//
//    func randomColor() -> Color {
//        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
//        return colors.randomElement()!.opacity(0.7)
//    }
//}
//
//extension String: Identifiable {
//    public var id: String { self }
//}
//
//#Preview {
//    WordCloudView()
//}






// -------------------------------------------------------------------------------
import SwiftUI

struct WordCloudWord: Identifiable {
    let id = UUID()
    let text: String
    let frequency: Int
}

struct PositionedWord: Identifiable {
    let id = UUID()
    let word: WordCloudWord
    let position: CGPoint
    let estimatedSize: CGSize
}

struct TextSizeReader: UIViewRepresentable {
    let text: String
    let font: UIFont
    let onSizeChange: (CGSize) -> Void

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = font
        label.text = text
        label.isHidden = true
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.font = font
        uiView.sizeToFit()
        DispatchQueue.main.async {
            self.onSizeChange(uiView.bounds.size)
        }
    }
}

struct MeasuredWord: Identifiable {
    let id = UUID()
    let word: WordCloudWord
    let size: CGSize
}


struct WordCloudView: View {
    @State private var tappedWord: String? = nil
    @State private var positionedWords: [PositionedWord] = []
    @State private var measuredSizes: [String: CGSize] = [:]

    let words: [WordCloudWord]
    
    var tapItem: ((String) -> Void)? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 渲染单词
                ForEach(positionedWords) { item in
                    WordView(word: item.word.text,
                             frequency: item.word.frequency,
                             isHighlighted: tappedWord == item.word.text)
                    .position(item.position)
                    .onTapGesture {
                        tappedWord = item.word.text
                        tapItem?(item.word.text)
                    }
                }
                
                // 測量器
                ForEach(words, id: \.text) { word in
                    let fontSize = CGFloat(12 + word.frequency)
                    let font = UIFont.systemFont(ofSize: fontSize)
                    
                    TextSizeReader(text: word.text, font: font) { size in
                        DispatchQueue.main.async {
                            // ✅ 只在首次测量时写入，避免重复 setState
                            if measuredSizes[word.text] == nil {
                                measuredSizes[word.text] = size

                                // ✅ 全部测量完毕才计算
                                if measuredSizes.count == words.count {
                                    let measured = words.map {
                                        MeasuredWord(word: $0, size: measuredSizes[$0.text]!)
                                    }
                                    positionedWords = computePrecisePositions(measuredWords: measured, in: geo.size)
                                }
                            }
                        }
                    }
                    .frame(width: 0, height: 0)
                }
            }
            
            .onAppear {
                measureWords(words) { measured in
                    positionedWords = computePrecisePositions(measuredWords: measured, in: geo.size)
                }
            }
            
//            .alert(item: $tappedWord) { word in
//                Alert(title: Text("你点击了"), message: Text(word), dismissButton: .default(Text("好的")))
//            }
        }
    }

    func measureWords(_ words: [WordCloudWord], completion: @escaping ([MeasuredWord]) -> Void) {
        var measured: [MeasuredWord] = []
        let group = DispatchGroup()

        for word in words {
            group.enter()
            let fontSize = CGFloat(12 + word.frequency)
            let font = UIFont.systemFont(ofSize: fontSize)

            TextSizeReader(text: word.text, font: font) { size in
                measured.append(MeasuredWord(word: word, size: size))
                group.leave()
            }
            .frame(width: 0, height: 0) // invisible
        }

        group.notify(queue: .main) {
            completion(measured)
        }
    }
    
    func computePrecisePositions(measuredWords: [MeasuredWord], in size: CGSize) -> [PositionedWord] {
        var result: [PositionedWord] = []
        var occupiedRects: [CGRect] = []
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        for item in measuredWords.sorted(by: { $0.word.frequency > $1.word.frequency }) {
            let estWidth = item.size.width
            let estHeight = item.size.height

            var angle: CGFloat = 0
            var radius: CGFloat = 0
            let maxRadius = min(size.width, size.height) / 2

            var foundPosition: CGPoint? = nil

            while radius < maxRadius {
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)

                let candidateRect = CGRect(x: x - estWidth / 2, y: y - estHeight / 2, width: estWidth, height: estHeight)

//                if !occupiedRects.contains(where: { $0.intersects(candidateRect.insetBy(dx: -2, dy: -2)) }) {
                if !occupiedRects.contains(where: { $0.intersects(candidateRect.offsetBy(dx: -2, dy: -2)) }) {
                    foundPosition = CGPoint(x: x, y: y)
                    occupiedRects.append(candidateRect)
                    break
                }

                angle += 0.3
                radius += 1
            }

            if let pos = foundPosition {
                result.append(PositionedWord(word: item.word, position: pos, estimatedSize: item.size))
            } else {
                result.append(PositionedWord(word: item.word, position: center, estimatedSize: item.size))
            }
        }

        return result
    }

}

struct WordView: View {
    let word: String
    let frequency: Int
    let isHighlighted: Bool

    var body: some View {
        Text(word)
            .font(.system(size: CGFloat(12 + frequency)))
            .foregroundColor(isHighlighted ? .white : randomColor())
            .padding(4)
            .background(isHighlighted ? randomColor() : Color.clear)
            .cornerRadius(4)
            .shadow(radius: 2)
    }

    func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        return colors.randomElement()!.opacity(0.7)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}


#Preview {
    let words = [
        WordCloudWord(text: "苹果", frequency: 15),
        WordCloudWord(text: "香蕉", frequency: 12),
        WordCloudWord(text: "橘子", frequency: 9),
        WordCloudWord(text: "西瓜", frequency: 7),
        WordCloudWord(text: "桃子", frequency: 8),
        WordCloudWord(text: "葡萄", frequency: 5),
        WordCloudWord(text: "芒果", frequency: 6),
        WordCloudWord(text: "柠檬", frequency: 4),
        WordCloudWord(text: "草莓", frequency: 6),
        WordCloudWord(text: "pitch4", frequency: 5),
        WordCloudWord(text: "pitch3", frequency: 4),
        WordCloudWord(text: "pitch2", frequency: 3),
        WordCloudWord(text: "pitch1", frequency: 2),
        WordCloudWord(text: "pitch", frequency: 1),
        WordCloudWord(text: "李子", frequency: 8)
    ]
    WordCloudView(words: words)
}






