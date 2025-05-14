//
//  JapaneseLearnAppApp.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

@main
struct JapaneseLearnAppApp: App {
    // 创建视图模型实例
    let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
    let userService = UserService(userRepository: UserAuthDataRepository())
    let hotWordService = HotWordService(hotWordRepository: HotWordDataRepository())
    
    var body: some Scene {
        WindowGroup {
            // 使用新的HomeView作为主视图
            NavigationView {
                HomeView(
                    searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
                    userViewModel: UserViewModel(userService: userService),
                    hotWordViewModel: HotWordViewModel(hotWordService: hotWordService)
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
