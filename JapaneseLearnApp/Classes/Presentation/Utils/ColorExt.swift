//
//  ColorExt.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/17.
//

import SwiftUI

extension Color {
    /// 主题色枚举，包含唯一标识和颜色
    enum Theme: Int, CaseIterable, Identifiable {
        case `default` = -1 // 默认（随机）
        case red = 0
        case blue
        case green
        case orange
        case purple
        case pink
        
        var id: Int { rawValue }
        
        /// 主题色对应的显示颜色
        var color: Color {
            switch self {
            case .default: return Color.randomColor()
            case .red: return .red
            case .blue: return .blue
            case .green: return .green
            case .orange: return .orange
            case .purple: return .purple
            case .pink: return .pink
            }
        }
        
        /// 主题色名称（可用于UI展示）
        var displayName: String {
            switch self {
            case .default: return "默认"
            case .red: return "红色"
            case .blue: return "蓝色"
            case .green: return "绿色"
            case .orange: return "橙色"
            case .purple: return "紫色"
            case .pink: return "粉色"
            }
        }
        
        /// 通过唯一标识获取主题色
        static func from(id: Int) -> Theme {
            Theme(rawValue: id) ?? .default
        }
    }
    
    /// 所有可选主题色（含默认）
    static var themeColors: [Theme] {
        Theme.allCases
    }
    
    /// 主题色与唯一标识互转
    static func themeColor(for id: Int) -> Color {
        Theme.from(id: id).color
    }
    static func themeId(for color: Color) -> Int? {
        // 仅支持已知色，默认返回nil
        for theme in Theme.allCases where theme.color == color {
            return theme.id
        }
        return nil
    }
    
    /// 随机主题色（不含默认）
    static func randomThemeColor() -> Color {
        let themes = Theme.allCases.filter { $0 != .default }
        return themes.randomElement()?.color.opacity(0.7) ?? .blue.opacity(0.7)
    }
    
    static func randomColor() -> Color {
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
