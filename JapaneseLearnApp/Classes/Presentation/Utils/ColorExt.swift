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

