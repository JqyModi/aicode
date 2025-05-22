//
//  JapaneseLearnAppApp.swift
//  JapaneseLearnApp
//
//  Created by Modi on 2025/4/6.
//

import SwiftUI
import Combine

// MARK: - 开启侧滑手势
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

@main
struct JapaneseLearnAppApp: App {
    // 创建视图模型实例
    let dictionaryService = DictionaryService(dictionaryRepository: DictionaryDataRepository())
    let userService = UserService(userRepository: UserAuthDataRepository())
    let hotWordService = HotWordService(hotWordRepository: HotWordDataRepository())

    // 新增：用StateObject持有UserViewModel，便于全局绑定
    @StateObject private var userViewModel = UserViewModel(userService: UserService(userRepository: UserAuthDataRepository()))

    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView(
                    searchViewModel: SearchViewModel(dictionaryService: dictionaryService),
                    userViewModel: userViewModel,
                    hotWordViewModel: HotWordViewModel(hotWordService: hotWordService)
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            // 关键：根据userViewModel.darkMode切换主题
            .preferredColorScheme(userViewModel.darkMode ? .dark : .light)
        }
    }
}
