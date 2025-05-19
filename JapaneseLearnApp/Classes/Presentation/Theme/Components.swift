//
//  Components.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import SwiftUI

// MARK: - 基础组件库
/// 根据UI/UX设计规范文档实现的基础组件
struct Components {
    // MARK: - 按钮组件
    struct Buttons {
        // 主要按钮
        struct PrimaryButton: View {
            let title: String
            let action: () -> Void
            let isDisabled: Bool
            
            init(title: String, action: @escaping () -> Void, isDisabled: Bool = false) {
                self.title = title
                self.action = action
                self.isDisabled = isDisabled
            }
            
            var body: some View {
                Button(action: action) {
                    Text(title)
                        .font(DesignSystem.Typography.subtitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(.white)
                        .background(isDisabled ? DesignSystem.Colors.primaryLightHex : DesignSystem.Colors.primaryHex)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                }
                .disabled(isDisabled)
            }
        }
        
        // 次要按钮
        struct SecondaryButton: View {
            let title: String
            let action: () -> Void
            let isDisabled: Bool
            
            init(title: String, action: @escaping () -> Void, isDisabled: Bool = false) {
                self.title = title
                self.action = action
                self.isDisabled = isDisabled
            }
            
            var body: some View {
                Button(action: action) {
                    Text(title)
                        .font(DesignSystem.Typography.subtitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundColor(isDisabled ? DesignSystem.Colors.primaryLightHex : DesignSystem.Colors.primaryHex)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(isDisabled ? DesignSystem.Colors.primaryLightHex : DesignSystem.Colors.primaryHex, lineWidth: 1)
                        )
                }
                .disabled(isDisabled)
            }
        }
        
        // 文本按钮
        struct TextButton: View {
            let title: String
            let action: () -> Void
            let isDisabled: Bool
            
            init(title: String, action: @escaping () -> Void, isDisabled: Bool = false) {
                self.title = title
                self.action = action
                self.isDisabled = isDisabled
            }
            
            var body: some View {
                Button(action: action) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(isDisabled ? DesignSystem.Colors.primaryLightHex : DesignSystem.Colors.primaryHex)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    // MARK: - 输入框组件
    struct InputFields {
        // 搜索框
        struct SearchField: View {
            @Binding var text: String
            let placeholder: String
            let onSubmit: () -> Void
            
            var body: some View {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textHintHex)
                    
                    TextField(placeholder, text: $text, onCommit: onSubmit)
                        .font(DesignSystem.Typography.body)
                    
                    if !text.isEmpty {
                        Button(action: { text = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.textHintHex)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(DesignSystem.Colors.neutralLightHex)
                .cornerRadius(DesignSystem.CornerRadius.small)
            }
        }
        
        // 文本输入框
        struct TextInputField: View {
            @Binding var text: String
            let placeholder: String
            let isSecure: Bool
            
            init(text: Binding<String>, placeholder: String, isSecure: Bool = false) {
                self._text = text
                self.placeholder = placeholder
                self.isSecure = isSecure
            }
            
            var body: some View {
                VStack(spacing: 4) {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .font(DesignSystem.Typography.body)
                    } else {
                        TextField(placeholder, text: $text)
                            .font(DesignSystem.Typography.body)
                    }
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(text.isEmpty ? DesignSystem.Colors.neutralMediumHex : DesignSystem.Colors.primaryHex)
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - 卡片组件
    struct Cards {
        // 标准卡片
        struct StandardCard<Content: View>: View {
            let content: Content
            
            init(@ViewBuilder content: () -> Content) {
                self.content = content()
            }
            
            var body: some View {
                content
                    .standardCardStyle()
            }
        }
        
        // 词条卡片
        struct WordCard: View {
            let word: String
            let reading: String
            let meaning: String
            let onTap: () -> Void
            
            var body: some View {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.compact) {
                        Text(word)
                            .font(DesignSystem.Typography.title)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                        
                        Text(reading)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondaryHex)
                        
                        Text(meaning)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimaryHex)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .wordCardStyle()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 特殊组件
    struct SpecialComponents {
        // 浮动学习中心按钮
        struct FloatingLearningCenterButton: View {
            let action: () -> Void
            
            var body: some View {
                Button(action: action) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [DesignSystem.Colors.primaryHex, DesignSystem.Colors.primaryDarkHex]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadowStyle(DesignSystem.Shadow.large)
                }
            }
        }
        
        // 发音按钮
        struct PronunciationButton: View {
            let action: () -> Void
            
            var body: some View {
                Button(action: action) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(DesignSystem.Colors.primaryHex)
                        .frame(width: 36, height: 36)
                        .background(DesignSystem.Colors.primaryHex.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
    }
}