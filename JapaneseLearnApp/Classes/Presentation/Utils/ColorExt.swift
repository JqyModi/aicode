//
//  ColorExt.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/17.
//

import SwiftUI

extension Color {
    static func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        return colors.randomElement()!.opacity(0.7)
    }
    
    func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        return colors.randomElement()!.opacity(0.7)
    }
}

extension View {
    func themeColor() -> Color {
//        Color("Primary")
        Color.randomColor()
    }
}

extension StrokeStyle {
    static let roundStyle: StrokeStyle = StrokeStyle(
        lineWidth: AppTheme.Borders.medium,
        lineCap: .round, // ✅ 两端圆角
        lineJoin: .round
    )
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollOffsetReader: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geo.frame(in: .named("scroll")).minY
                )
        }
        .frame(height: 1)
    }
}
