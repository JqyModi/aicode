//
//  LaunchView.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/5/21.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            Color.white
            VStack {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                Text("欢迎使用")
                    .font(.headline)
                    .padding(.top, 20)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LaunchView()
}
