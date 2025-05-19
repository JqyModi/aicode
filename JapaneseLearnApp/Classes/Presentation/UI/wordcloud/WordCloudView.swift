//
//  WordCloudView.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/12.
//

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

enum WordCloudShape {
    case circle
    case rect
    case ellipse
    case heart
    case custom(mask: UIImage)
}


struct WordCloudView: View {
    @State private var tappedWord: String? = nil
    @State private var positionedWords: [PositionedWord] = []
    @State private var measuredSizes: [String: CGSize] = [:]

    let words: [WordCloudWord]
    let shape: WordCloudShape
    let showShapeOverlay: Bool = false // 新增变量，控制可视化

    var tapItem: ((String) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. 可视化 shape 区域
                if showShapeOverlay {
                    shapeOverlayView(size: geo.size)
                        .opacity(0.2)
                        .allowsHitTesting(false)
                }
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
        let sortedWords = measuredWords.sorted { $0.word.frequency > $1.word.frequency }
    
        switch shape {
        case .ellipse:
            // 椭圆螺旋发散
            let a = size.width / 2
            let b = size.height / 2
            let spiralStep: CGFloat = 0.25
            let radiusStep: CGFloat = 2.0
            for item in sortedWords {
                let estWidth = item.size.width
                let estHeight = item.size.height
                var angle: CGFloat = 0
                var radius: CGFloat = 0
                let maxRadius = min(a, b)
                var foundPosition: CGPoint? = nil
                while radius < maxRadius {
                    // 椭圆极坐标变换
                    let x = center.x + radius * cos(angle) * (a / maxRadius)
                    let y = center.y + radius * sin(angle) * (b / maxRadius)
                    let candidateRect = CGRect(x: x - estWidth / 2, y: y - estHeight / 2, width: estWidth, height: estHeight)
                    let candidateCenter = CGPoint(x: x, y: y)
                    if isPointInShape(candidateCenter, in: size) &&
                        !occupiedRects.contains(where: { $0.intersects(candidateRect.insetBy(dx: -1, dy: -1)) }) {
                        foundPosition = candidateCenter
                        occupiedRects.append(candidateRect)
                        break
                    }
                    angle += spiralStep
                    radius += radiusStep * spiralStep / (2 * .pi)
                }
                if let pos = foundPosition {
                    result.append(PositionedWord(word: item.word, position: pos, estimatedSize: item.size))
                } else {
                    result.append(PositionedWord(word: item.word, position: center, estimatedSize: item.size))
                }
            }
        case .rect:
            // 水平优先，充分利用矩形空间
            let a = size.width / 2
            let b = size.height / 2
            let spiralStep: CGFloat = 0.25
            let radiusStep: CGFloat = 2.0
            for item in sortedWords {
                let estWidth = item.size.width
                let estHeight = item.size.height
                var angle: CGFloat = 0
                var radius: CGFloat = 0
                let maxRadius = 1.0 // 归一化到1，后面乘a/b
                var foundPosition: CGPoint? = nil
                while radius < maxRadius {
                    // x方向最大到a，y方向最大到b，实现真正的矩形填充
                    let x = center.x + (radius * a) * cos(angle)
                    let y = center.y + (radius * b) * sin(angle)
                    let candidateRect = CGRect(x: x - estWidth / 2, y: y - estHeight / 2, width: estWidth, height: estHeight)
                    let rectBounds = CGRect(origin: .zero, size: size)
                    if rectBounds.contains(candidateRect) &&
                        !occupiedRects.contains(where: { $0.intersects(candidateRect.insetBy(dx: -1, dy: -1)) }) {
                        foundPosition = CGPoint(x: x, y: y)
                        occupiedRects.append(candidateRect)
                        break
                    }
                    angle += spiralStep
                    radius += radiusStep * spiralStep / (2 * .pi * max(a, b))
                }
                if let pos = foundPosition {
                    result.append(PositionedWord(word: item.word, position: pos, estimatedSize: item.size))
                } else {
                    result.append(PositionedWord(word: item.word, position: center, estimatedSize: item.size))
                }
            }
        case .rect:
            // 矩形水平方向螺旋发散
            let maxRadius = min(size.width, size.height) / 2
            let spiralStep: CGFloat = 0.25
            let radiusStep: CGFloat = 2.0
            for item in sortedWords {
                let estWidth = item.size.width
                let estHeight = item.size.height
                var angle: CGFloat = 0
                var radius: CGFloat = 0
                var foundPosition: CGPoint? = nil
                while radius < maxRadius {
                    // angle=0时向右，π时向左，π/2和3π/2时上下
                    // 这里让x方向的变化更大，y方向变化更小，实现水平方向优先
                    let x = center.x + radius * cos(angle)
                    let y = center.y + (radius * 0.4) * sin(angle)
                    let candidateRect = CGRect(x: x - estWidth / 2, y: y - estHeight / 2, width: estWidth, height: estHeight)
                    let candidateCenter = CGPoint(x: x, y: y)
                    if isPointInShape(candidateCenter, in: size) &&
                        !occupiedRects.contains(where: { $0.intersects(candidateRect.insetBy(dx: -1, dy: -1)) }) {
                        foundPosition = candidateCenter
                        occupiedRects.append(candidateRect)
                        break
                    }
                    angle += spiralStep
                    radius += radiusStep * spiralStep / (2 * .pi)
                }
                if let pos = foundPosition {
                    result.append(PositionedWord(word: item.word, position: pos, estimatedSize: item.size))
                } else {
                    result.append(PositionedWord(word: item.word, position: center, estimatedSize: item.size))
                }
            }
        default:
            // 其他形状仍用螺旋方式
            for item in sortedWords {
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
                    let candidateCenter = CGPoint(x: x, y: y)
                    if isPointInShape(candidateCenter, in: size) &&
                        !occupiedRects.contains(where: { $0.intersects(candidateRect.insetBy(dx: -1, dy: -1)) }) {
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
        }
        return result
    }

    func isPointInShape(_ point: CGPoint, in size: CGSize) -> Bool {
        switch shape {
        case .circle:
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let radius = min(size.width, size.height)/2
            let dx = point.x - center.x
            let dy = point.y - center.y
            return dx*dx + dy*dy <= radius*radius
        case .rect:
            return CGRect(origin: .zero, size: size).contains(point)
        case .ellipse:
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let rx = size.width/2
            let ry = size.height/2
            let dx = point.x - center.x
            let dy = point.y - center.y
            return (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry) <= 1
        case .heart:
            // 心形公式判定
            let center = CGPoint(x: size.width/2, y: size.height/2)
            let scale = min(size.width, size.height)/2
            let x = (point.x - center.x)/scale
            let y = (point.y - center.y)/scale
            let value = pow(x*x + y*y - 1, 3) - x*x*y*y*y
            return value <= 0
        case .custom(let mask):
            // 根据mask图片像素判定
            // 伪代码：取point对应像素，判断是否为有效区域
//            return mask.isPointOpaque(point: point, in: size)
            return false
        }
    }

    /// 根据当前 shape 枚举返回对应的 SwiftUI Shape 视图
    @ViewBuilder
    func shapeOverlayView(size: CGSize) -> some View {
        switch shape {
        case .circle:
            Circle()
                .fill(Color.blue)
                .frame(width: size.width, height: size.height)
        case .rect:
            Rectangle()
                .fill(Color.green)
                .frame(width: size.width, height: size.height)
        case .ellipse:
            Ellipse()
                .fill(Color.purple)
                .frame(width: size.width, height: size.height)
        case .heart:
            HeartShape()
                .fill(Color.red)
                .frame(width: size.width, height: size.height)
        case .custom(_):
            // 可选：自定义图片蒙版可视化
            Rectangle()
                .stroke(Color.orange, lineWidth: 2)
                .frame(width: size.width, height: size.height)
        }
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
    WordCloudView(words: words, shape: .circle)
        .frame(width: 280, height:360)
}

// 新增心形 Shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y + height * 0.25))
        path.addCurve(to: CGPoint(x: 0, y: height * 0.25),
                      control1: CGPoint(x: center.x, y: height * 0.7),
                      control2: CGPoint(x: 0, y: height * 0.6))
        path.addArc(center: CGPoint(x: width * 0.25, y: height * 0.25),
                    radius: width * 0.25,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addArc(center: CGPoint(x: width * 0.75, y: height * 0.25),
                    radius: width * 0.25,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false)
        path.addCurve(to: CGPoint(x: center.x, y: center.y + height * 0.25),
                      control1: CGPoint(x: width, y: height * 0.6),
                      control2: CGPoint(x: center.x, y: height * 0.7))
        return path
    }
}






