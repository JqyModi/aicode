//
//  ContentView.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HomeView(dictionaryViewModel: DependencyContainer.shared.dictionaryViewModel, searchViewModel: DependencyContainer.shared.searchViewModel)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
