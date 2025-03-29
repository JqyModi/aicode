## 编程语言
- Swift：苹果主推的现代编程语言，语法简洁高效，支持面向协议编程

## UI框架
- SwiftUI：苹果推出的声明式UI框架，支持跨Apple平台（iOS、macOS、watchOS）
- UIKit：传统的iOS UI框架，支持Storyboard和代码布局
- Core Animation：用于高性能动画和图形渲染
- Core Graphics / Quartz 2D：2D绘图框架
- SceneKit / SpriteKit：3D和2D游戏开发框架

## 网络通信
- URLSession：苹果原生的HTTP/HTTPS网络请求库
- Alamofire：基于Swift的流行HTTP网络库，简化API调用
- WebSocket（如Starscream）：用于实时通信
- 数据解析
    - Codable (原生JSON解析)
    - SwiftyJSON (旧项目可能仍在使用)

## 数据库与存储
- SwiftData (iOS 17+，基于Core Data的声明式封装)
- Realm (第三方高性能数据库)
- UserDefaults/Keychain (轻量级存储)
- File System / Sandbox：本地文件读写管理

## 多线程与并发
- Combine：苹果的响应式编程框架（类似RxSwift）
- GCD（Grand Central Dispatch）：苹果的低级多线程管理库

## 架构模式
- SwiftUI + Combine：声明式UI + 响应式数据流
- MVVM（+ Combine/RxSwift）：现代架构，数据绑定更清晰

## 依赖管理
- Swift Package Manager (SPM) (官方首选) 集成在Xcode中，支持本地和远程依赖
- CocoaPods (传统工具，适合混合项目)

## 调试与工具
- Xcode：官方IDE，支持代码编辑、调试、性能分析
- LLDB / Instruments：调试和性能优化工具
- Fastlane：自动化构建、测试和发布
- CocoaPods / Swift Package Manager (SPM)：依赖管理工具
- Firebase Crashlytics：崩溃分析工具

## 跨平台与混合开发
- Flutter（Dart）：Google的跨平台UI框架，可编译为iOS应用

## 安全与加密
- Keychain Services：安全存储敏感数据
- CommonCrypto：基础加密库（AES、RSA等）
- HTTPS + SSL Pinning：防止中间人攻击

## AI与机器学习
- Core ML：苹果的机器学习框架，支持本地模型推理
- Create ML：训练轻量级机器学习模型
- TensorFlow Lite / PyTorch Mobile：第三方ML框架的iOS支持

## CI/CD & 发布
- Fastlane (自动化构建、打包、发布)
- GitHub Actions (第三方CI工具)
- Xcode Cloud (Apple官方CI服务)
