//
//  DesignSystem.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI

// MARK: - 设计系统
/// 根据UI/UX设计规范文档实现的设计系统
struct DesignSystem {
    // MARK: - 颜色系统
    struct Colors {
        // 主色调
        static let primary = Color("Primary", bundle: nil) // #00D2DD 清新湖水蓝
        static let primaryLight = Color("PrimaryLight", bundle: nil) // #7EEAEF 70%
        static let primaryDark = Color("PrimaryDark", bundle: nil) // #008A91 130%
        
        // 辅助色
        static let accent = Color("Accent", bundle: nil) // #FF6B6B 暖珊瑚红
        
        // 中性色
        static let neutralLight = Color("NeutralLight", bundle: nil) // #F5F7FA
        static let neutralMedium = Color("NeutralMedium", bundle: nil) // #E1E5EA
        static let neutralDark = Color("NeutralDark", bundle: nil) // #8A9199
        
        // 文本色
        static let textPrimary = Color("TextPrimary", bundle: nil) // #2C3E50
        static let textSecondary = Color("TextSecondary", bundle: nil) // #5D6D7E
        static let textHint = Color("TextHint", bundle: nil) // #8A9199
        
        // 功能色
        static let success = Color("Success", bundle: nil) // #4CD964
        static let warning = Color("Warning", bundle: nil) // #FFCC00
        static let error = Color("Error", bundle: nil) // #FF3B30
        static let info = Color("Info", bundle: nil) // #007AFF
        
        // 深色模式背景
        static let backgroundDark = Color("BackgroundDark", bundle: nil) // #121212
        static let surfaceDark = Color("SurfaceDark", bundle: nil) // #1E1E1E
        
        // 扩展颜色 - 用于直接使用十六进制值的情况
        static let primaryHex = Color(hex: "00D2DD")
        static let primaryLightHex = Color(hex: "7EEAEF")
        static let primaryDarkHex = Color(hex: "008A91")
        static let accentHex = Color(hex: "FF6B6B")
        static let neutralLightHex = Color(hex: "F5F7FA")
        static let neutralMediumHex = Color(hex: "E1E5EA")
        static let neutralDarkHex = Color(hex: "8A9199")
        static let textPrimaryHex = Color(hex: "2C3E50")
        static let textSecondaryHex = Color(hex: "5D6D7E")
        static let textHintHex = Color(hex: "8A9199")
        static let successHex = Color(hex: "4CD964")
        static let warningHex = Color(hex: "FFCC00")
        static let errorHex = Color(hex: "FF3B30")
        static let infoHex = Color(hex: "007AFF")
        static let backgroundDarkHex = Color(hex: "121212")
        static let surfaceDarkHex = Color(hex: "1E1E1E")
    }
    
    // MARK: - 排版系统
    struct Typography {
        // 字体
        static func sfProText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.system(size: size, weight: weight, design: .default)
        }
        
        static func sfProDisplay(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.system(size: size, weight: weight, design: .default)
        }
        
        // 预定义字体样式
        static let largeTitle = sfProDisplay(24, weight: .semibold) // 大标题
        static let title = sfProDisplay(20, weight: .semibold) // 标题
        static let subtitle = sfProText(17, weight: .semibold) // 副标题
        static let body = sfProText(15, weight: .regular) // 正文
        static let callout = sfProText(13, weight: .regular) // 次要文本
        static let footnote = sfProText(11, weight: .regular) // 注释
        
        // 字重
        static let bold = Font.Weight.semibold // 600
        static let regular = Font.Weight.regular // 400
        static let light = Font.Weight.light // 300
    }
    
    // MARK: - 间距与布局
    struct Spacing {
        // 基础间距单位: 8pt
        static let unit: CGFloat = 8
        
        // 预定义间距
        static let compact: CGFloat = unit // 8pt (1×)
        static let standard: CGFloat = unit * 2 // 16pt (2×)
        static let relaxed: CGFloat = unit * 3 // 24pt (3×)
        static let separate: CGFloat = unit * 4 // 32pt (4×)
        
        // 布局边距
        static let screenEdge: CGFloat = standard // 16pt
    }
    
    // MARK: - 圆角
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: - 阴影
    struct Shadow {
        static let small = ShadowStyle(color: Color.black.opacity(0.1), radius: 4, y: 1)
        static let medium = ShadowStyle(color: Color.black.opacity(0.15), radius: 8, y: 2)
        static let large = ShadowStyle(color: Color.black.opacity(0.25), radius: 16, y: 4)
    }
    
    // 阴影样式结构
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }
    }
}

// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 视图扩展
extension View {
    // 应用阴影样式
    func shadowStyle(_ style: DesignSystem.ShadowStyle) -> some View {
        return self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
    
    // 应用标准卡片样式
    func standardCardStyle() -> some View {
        return self
            .padding(DesignSystem.Spacing.standard)
            .background(Color.white)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadowStyle(DesignSystem.Shadow.medium)
    }
    
    // 应用词条卡片样式
    func wordCardStyle() -> some View {
        return self
            .padding(DesignSystem.Spacing.standard)
            .background(Color.white)
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .shadowStyle(DesignSystem.Shadow.small)
    }
}