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
            HomeView(viewModel: DictionaryViewModel())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
