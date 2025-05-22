//
//  AppTheme.swift
//  JapaneseLearnApp
//
//  Created by System on 2025/4/6.
//

import SwiftUI

typealias Shadow = DesignSystem.ShadowStyle

/// 应用主题样式管理
/// 集中管理应用中使用的颜色、字体、间距等UI样式元素
struct AppTheme {
    // MARK: - 颜色
    struct Colors {
        // 主题色
//        static let primary = Color("Primary")
        static var primary: Color {
            UserViewModel.globalThemeColor
        }
        static var primaryLight: Color {
            UserViewModel.globalThemeColor.opacity(0.7)
        }
        static var primaryLighter: Color {
            UserViewModel.globalThemeColor.opacity(0.5)
        }
        static var primaryLightest: Color {
            UserViewModel.globalThemeColor.opacity(0.3)
        }
        static var primaryDark: Color {
            UserViewModel.globalThemeColor.opacity(1.2)
        }
        
        // 背景色
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        
        // 文本颜色
        static let text = Color.primary
        static let secondaryText = Color.gray
        static let placeholderText = Color.gray
        
        // 其他颜色
        static let shadow = Color.black.opacity(0.05)
        static let divider = Color.gray.opacity(0.3)
        static let overlay = Color.white.opacity(0.1)
    }
    
    // MARK: - 字体
    struct Fonts {
        // 标题
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        
        // 正文
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // 自定义大小
        static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return Font.system(size: size, weight: weight)
        }
    }
    
    // MARK: - 字重
    struct FontWeights {
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }
    
    // MARK: - 间距
    struct Spacing {
        // 基础间距
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 15
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 25
        static let huge: CGFloat = 32
        
        // 内边距
        static let cardPadding: CGFloat = 15
        static let screenPadding: CGFloat = 20
        static let buttonPadding: EdgeInsets = EdgeInsets(top: 8, leading: 15, bottom: 8, trailing: 15)
        
        // 特定元素间距
        static let cardSpacing: CGFloat = 25
        static let itemSpacing: CGFloat = 15
        static let sectionSpacing: CGFloat = 30
    }
    
    // MARK: - 圆角
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 10
        static let large: CGFloat = 15
        static let extraLarge: CGFloat = 20
        static let circle: CGFloat = 999
    }
    
    // MARK: - 阴影
    struct Shadows {
        static let small: Shadow = Shadow(color: Colors.shadow, radius: 5, x: 0, y: 2)
        static let medium: Shadow = Shadow(color: Colors.shadow, radius: 10, x: 0, y: 5)
        static let large: Shadow = Shadow(color: Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 动画
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let gradientAnimation = Animation.linear(duration: 3).repeatForever(autoreverses: true)
    }
    
    // MARK: - 渐变
    struct Gradients {
        static func primaryGradient(animate: Bool) -> LinearGradient {
            LinearGradient(
                colors: [Colors.primary, Colors.primaryLight],
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )
        }
    }
    
    // MARK: - 边框
    struct Borders {
        static let thin = 1.0
        static let medium = 2.0
        static let thick = 4.0
    }
    
    // MARK: - 尺寸
    struct Sizes {
        // 图标尺寸
        static let smallIcon: CGFloat = 18
        static let mediumIcon: CGFloat = 22
        static let largeIcon: CGFloat = 28
        
        // 控件尺寸
        static let buttonHeight: CGFloat = 44
        static let iconButtonSize: CGFloat = 36
        static let circleProgressSize: CGFloat = 70
        
        // 卡片尺寸
        static let recommendationCardHeight: CGFloat = 180
        static let progressCardHeight: CGFloat = 200
        static let searchCardHeight: CGFloat = 130
    }
}

// MARK: - 视图扩展
extension View {
    // 应用卡片样式
    func cardStyle(cornerRadius: CGFloat = AppTheme.CornerRadius.extraLarge, shadowStyle: Shadow = AppTheme.Shadows.medium) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Colors.secondaryBackground)
            )
            .shadow(color: shadowStyle.color, radius: shadowStyle.radius, x: shadowStyle.x, y: shadowStyle.y)
    }
    
    // 应用主题渐变卡片样式
    func gradientCardStyle(animate: Bool, cornerRadius: CGFloat = AppTheme.CornerRadius.extraLarge, shadowStyle: Shadow = AppTheme.Shadows.large) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Gradients.primaryGradient(animate: animate))
            )
            .shadow(color: shadowStyle.color, radius: shadowStyle.radius, x: shadowStyle.x, y: shadowStyle.y)
    }
    
    // 应用胶囊按钮样式
    func capsuleButtonStyle(foregroundColor: Color = AppTheme.Colors.primary, strokeColor: Color = AppTheme.Colors.primaryLightest) -> some View {
        self
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(
                Capsule()
                    .stroke(strokeColor, lineWidth: AppTheme.Borders.thin)
            )
    }
    
    // 应用圆形图标按钮样式
    func circleIconButtonStyle() -> some View {
        self
            .frame(width: AppTheme.Sizes.iconButtonSize, height: AppTheme.Sizes.iconButtonSize)
            .background(
                Circle()
                    .fill(AppTheme.Colors.secondaryBackground)
            )
    }
}
