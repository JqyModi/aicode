//
//  JapaneseLearnAppApp.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI

@main
struct JapaneseLearnAppApp: App {
    // 创建视图模型实例
    let dictionaryService = DictionaryService1()
    let userService = UserService1()
    
    var body: some Scene {
        WindowGroup {
            // 使用新的HomeView作为主视图
            HomeView(
                searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
                userViewModel: UserViewModel(userService: userService)
            )
        }
    }
}
