# 产品定义文档
## 1. 产品愿景与目标
### 产品愿景
打造一款专注于核心功能的日语学习词典应用，以简洁高效的用户体验为中心，帮助日语学习者快速查询、记忆和掌握日语词汇。

### 目标
- 为日语学习者提供一个稳定、高效的词典查询工具
- 解决用户在日语学习过程中的词汇查询和记忆难题
- 专注于核心功能，避免过度复杂的功能设计
- 建立可靠的数据存储和同步机制，确保用户数据安全
## 2. 用户画像
### 主要用户群体：日语学习者
1. 大学生日语学习者
   
   - 特征：18-25岁，正在大学学习日语或将日语作为第二外语
   - 需求：快速查询生词，记忆单词，准备考试
   - 使用场景：课堂学习，自习，做作业时查询不熟悉的单词
2. 自学日语爱好者
   
   - 特征：25-40岁，工作之余自学日语，可能有考取日语等级证书的目标
   - 需求：系统性学习词汇，建立个人词库，定期复习
   - 使用场景：碎片时间学习，阅读日语材料时查询生词
3. 日语专业人士
   
   - 特征：25-45岁，工作中需要使用日语，如翻译、外贸、导游等
   - 需求：查询专业词汇，确认词义和用法
   - 使用场景：工作中遇到不熟悉的词汇，需要快速准确查询
## MVP阶段实现优先级
### 第一阶段（核心功能）
1. 基础词典查询系统
2. 简单收藏功能
3. 基本用户账户（Sign in with Apple）
4. 本地数据存储
### 第二阶段（数据安全与同步）
1. CloudKit数据同步
2. 备份与恢复功能
3. 收藏夹管理
4. 笔记功能
### 第三阶段（学习功能）
1. 基础单词测试
2. 简单学习计划
3. 例句与用法参考完善
4. 学习统计


# 详细功能规格说明文档
## 1. 用户故事
### 1.1 基础词典查询
1. 作为大学生日语学习者 ，我希望能够通过日语、中文或罗马音输入查询单词，以便在课堂上快速查找不熟悉的词汇。
2. 作为自学日语爱好者 ，我希望查询结果显示完整的词条信息（假名、汉字、词性、释义），以便全面理解单词的用法。
3. 作为日语专业人士 ，我希望能够听到准确的单词发音，以便确认正确的发音方式。
4. 作为移动设备用户 ，我希望在没有网络连接的情况下也能查询基础词库，以便在任何环境下都能使用词典功能。
### 1.2 个人词库管理
1. 作为大学生日语学习者 ，我希望能够一键收藏查询过的单词，以便后续复习。
2. 作为自学日语爱好者 ，我希望能够创建和管理多个单词收藏夹，以便按主题或难度分类整理词汇。
3. 作为日语专业人士 ，我希望能够对收藏的单词添加个人笔记，以便记录特定语境下的用法或记忆技巧。
4. 作为多设备用户 ，我希望我的收藏数据能够安全地同步到所有设备，以便在不同设备上继续学习。
### 1.3 用户账户与数据同步
1. 作为隐私关注用户 ，我希望能够使用Apple ID一键登录，以便不需要创建额外的账户和密码。
2. 作为谨慎用户 ，我希望应用能够定期自动备份我的学习数据，以便防止数据丢失。
3. 作为新用户 ，我希望能够在不登录的情况下使用基本功能，以便先体验应用再决定是否注册。
## 2. 功能详述
### 2.1 词典查询功能 
2.1.1 多语言输入查询
- 功能描述 ：支持用户通过日语（平假名、片假名、汉字）、中文或罗马音输入查询单词。
- 交互逻辑 ：
  - 用户在搜索框输入查询内容
  - 系统自动识别输入类型（日语/中文/罗马音）
  - 实时显示搜索建议（最多显示5个）
  - 用户可点击建议或按搜索按钮执行查询
- 边界条件 ：
  - 最短查询长度：1个字符
  - 最长查询长度：50个字符
  - 无结果时显示"未找到匹配结果"提示
  - 网络中断时自动切换到离线词库 
2.1.2 词条详情展示
- 功能描述 ：显示查询单词的完整信息，包括假名、汉字、词性、释义等。
- 交互逻辑 ：
  - 点击搜索结果进入详情页
  - 顶部显示单词原形和读音
  - 中部显示词性和释义列表
  - 底部显示例句和相关词汇
  - 右上角提供收藏按钮
- 边界条件 ：
  - 长释义自动折叠，点击展开
  - 最多显示5个例句，更多例句通过"查看更多"按钮加载
  - 支持横竖屏自适应布局 
2.1.3 发音功能
- 功能描述 ：提供单词和例句的标准发音播放功能。
- 交互逻辑 ：
  - 点击单词旁的发音图标播放发音
  - 例句旁同样提供发音图标
  - 提供语速调节选项（0.75x, 1.0x, 1.25x）
- 边界条件 ：
  - 发音请求优先使用缓存
  - 离线状态下使用AVSpeechSynthesizer合成发音
  - 发音播放最大时长限制为10秒
  - 同时只允许一个音频播放，新请求会中断当前播放 
2.1.4 离线词库
- 功能描述 ：预装基础词库，支持离线查询常用单词。
- 交互逻辑 ：
  - 应用首次启动时自动解压词库到本地数据库
  - 联网状态下自动检查词库更新
  - 用户可在设置中查看词库版本和容量
- 边界条件 ：
  - 基础词库包含10,000个常用词汇
  - 词库大小不超过50MB
  - 词库更新增量不超过10MB
  - 更新下载仅在WiFi环境下自动进行
### 2.2 个人词库管理功能 
2.2.1 单词收藏
- 功能描述 ：允许用户一键收藏查询过的单词。
- 交互逻辑 ：
  - 词条详情页右上角提供收藏/取消收藏按钮
  - 收藏时弹出收藏夹选择对话框（如有多个收藏夹）
  - 收藏成功显示简短确认提示
  - 已收藏单词在搜索结果中显示收藏标记
- 边界条件 ：
  - 单个收藏夹最多支持10,000个单词
  - 最多创建50个收藏夹
  - 离线状态下收藏操作保存在本地，联网后自动同步 
2.2.2 收藏夹管理
- 功能描述 ：支持创建、编辑、删除和合并收藏夹。
- 交互逻辑 ：
  - 收藏页面提供收藏夹列表
  - 长按收藏夹显示操作菜单（重命名、删除、合并）
  - 点击收藏夹进入单词列表
  - 提供新建收藏夹按钮
- 边界条件 ：
  - 默认创建"我的收藏"文件夹，不可删除
  - 删除收藏夹需二次确认
  - 合并操作需选择目标收藏夹
  - 收藏夹名称长度限制为20个字符 
2.2.3 笔记功能
- 功能描述 ：允许用户为收藏的单词添加个人笔记。
- 交互逻辑 ：
  - 收藏单词详情页提供笔记编辑区域
  - 支持基本文本格式化（加粗、列表）
  - 自动保存编辑内容
  - 提供清空笔记选项
- 边界条件 ：
  - 单个笔记最大长度为1,000个字符
  - 编辑区域支持自动扩展
  - 支持表情符号输入
  - 笔记内容实时同步到云端 
2.2.4 数据同步与备份
- 功能描述 ：通过CloudKit实现用户数据的云同步和备份。
- 交互逻辑 ：
  - 用户登录Apple ID后自动启用同步
  - 设置页面提供同步状态和上次同步时间显示
  - 提供手动同步按钮
  - 支持导出/导入备份文件
- 边界条件 ：
  - 自动同步间隔不少于15分钟
  - 单次同步数据量不超过5MB
  - 冲突解决策略：以最新修改为准，保留冲突版本
  - 备份文件采用加密存储
### 2.3 用户账户功能 
2.3.1 Sign in with Apple
- 功能描述 ：支持用户通过Apple ID一键登录。
- 交互逻辑 ：
  - 首次启动应用提供登录选项
  - 设置页面提供登录/登出功能
  - 登录成功后显示用户名和头像
- 边界条件 ：
  - 登录失败提供明确错误提示
  - 支持隐藏邮箱选项
  - 登出需二次确认
  - 账户切换时提供数据处理选项 
2.3.2 游客模式
- 功能描述 ：允许用户在不登录的情况下使用基本功能。
- 交互逻辑 ：
  - 首次启动提供"跳过登录"选项
  - 设置页面显示登录提醒
  - 尝试使用需要登录的功能时提示登录
- 边界条件 ：
  - 游客模式下收藏数量限制为100个
  - 不支持云同步功能
  - 本地数据在登录后可选择合并到账户
## 3. 非功能性需求
### 3.1 性能指标 
3.1.1 响应时间
- 应用冷启动时间不超过3秒（iPhone X及以上机型）
- 搜索响应时间不超过500毫秒
- 词条详情页加载时间不超过1秒
- 发音播放延迟不超过300毫秒 
3.1.2 资源占用
- 应用安装包大小不超过100MB
- 运行内存占用不超过200MB
- CPU使用率平均不超过10%
- 电池消耗：正常使用1小时电量消耗不超过5% 
3.1.3 并发能力
- 支持同时处理最多5个后台任务
- 数据同步不影响前台操作流畅度
- 词库更新不阻塞用户操作
### 3.2 安全要求 
3.2.1 数据安全
- 用户收藏数据使用CloudKit安全存储
- 本地Realm数据库启用加密
- 导出备份文件采用AES-256加密
- 应用内不存储Apple ID密码 
3.2.2 隐私保护
- 明确的隐私政策说明
- 最小化数据收集范围
- 提供数据删除选项
- 不收集与功能无关的用户信息
### 3.3 可访问性标准 
3.3.1 视觉辅助
- 支持iOS动态字体大小调整
- 支持VoiceOver屏幕阅读
- 提供高对比度模式
- 颜色设计考虑色盲用户 
3.3.2 操作辅助
- 关键操作区域触控面积不小于44×44点
- 支持键盘操作（外接键盘）
- 避免需要精细运动控制的操作
- 提供操作撤销机制 
3.3.3 听觉辅助
- 发音功能提供字幕选项
- 操作反馈不仅依赖声音
- 重要提示同时提供视觉反馈
### 3.4 兼容性要求 
3.4.1 设备兼容性
- 支持iPhone 8及以上机型
- 支持iPad Air 2及以上机型
- 优化适配iPhone Pro Max系列大屏
- 支持iPad分屏多任务模式 
3.4.2 系统兼容性
- 支持iOS 14.0及以上版本
- 适配iOS 16深色模式
- 支持最新iOS版本发布后4周内完成适配
- 针对不同iOS版本的API差异提供兼容处理
## 4. 优先级与实施阶段
### 4.1 MVP阶段必要功能（优先级：高）
- 基础词典查询（多语言输入、词条展示）
- 单词发音（基础发音功能）
- 离线词库（基础10,000词）
- 简单收藏功能（单一收藏夹）
- Sign in with Apple基础集成
- 本地数据存储
### 4.2 第二阶段功能（优先级：中）
- 收藏夹管理（创建、编辑、删除）
- CloudKit数据同步
- 笔记功能
- 备份与恢复功能
- 游客模式完善
- 性能优化
### 4.3 第三阶段功能（优先级：低）
- 高级发音选项
- 扩展词库下载
- 收藏夹合并与高级管理
- 数据导出/导入
- 可访问性优化
- 兼容性扩展


# 技术架构文档
## 1. 系统架构图
### 1.1 整体架构
```plaintext
┌─────────────────────────────────────────────────────────────┐
│                        表现层 (Presentation)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  搜索模块    │  │  词条详情   │  │  个人收藏           │  │
│  │  SearchView  │  │ DetailView  │  │  FavoriteView      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                        业务层 (Domain)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 词典服务     │  │ 收藏服务    │  │  用户服务           │  │
│  │ DictService  │  │ FavService  │  │  UserService       │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                        数据层 (Data)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 本地存储     │  │ 云同步      │  │  用户认证           │  │
│  │ RealmManager │  │ CloudKit    │  │  AppleAuth         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
 ``
```

### 1.2 模块依赖关系
```plaintext
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│   UI 模块      │──────▶  业务逻辑模块  │──────▶  数据访问模块  │
└───────────────┘      └───────────────┘      └───────────────┘
        │                      │                      │
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│  SwiftUI 组件  │      │  业务模型对象  │      │   Realm/云存储 │
└───────────────┘      └───────────────┘      └───────────────┘
 ``
```

## 2. 技术栈选择
### 2.1 前端框架
SwiftUI + UIKit 混合架构

- SwiftUI ：作为主要UI框架
  
  - 优势：声明式UI编程，开发效率高，适配性好
  - 应用：搜索界面、词条详情、收藏列表等主要界面
- UIKit ：作为补充
  
  - 优势：成熟稳定，功能丰富
  - 应用：复杂交互组件、自定义控件、性能关键区域
选择理由 ：

- SwiftUI提供快速开发能力，适合MVP快速迭代
- 关键性能区域可降级到UIKit实现
- 混合架构平衡了开发效率与性能需求
### 2.2 本地存储
Realm 数据库

- 优势：
  
  - 跨平台支持
  - 对象映射简单直观
  - 查询性能优异
  - 支持加密
  - 轻量级，无需额外配置
- 应用：
  
  - 词典数据本地存储
  - 用户收藏数据
  - 学习记录与统计
### 2.3 云同步
CloudKit

- 优势：
  
  - 苹果原生支持
  - 与iCloud账户集成
  - 免费额度足够MVP阶段使用
  - 无需自建后端
- 应用：
  
  - 用户收藏数据同步
  - 学习进度同步
  - 用户设置同步
### 2.4 用户认证
Sign in with Apple

- 优势：
  - 一键登录，用户体验佳
  - 符合App Store审核要求
  - 保护用户隐私
  - 实现简单
## 3. 设计模式
### 3.1 主体架构：MVVM + Clean Architecture
MVVM (Model-View-ViewModel)

- Model : 核心数据模型，如词条、收藏项
- View : SwiftUI视图
- ViewModel : 视图状态管理，业务逻辑处理
Clean Architecture 分层

- Entities : 核心业务模型
- Use Cases : 业务逻辑封装
- Interface Adapters : 数据转换与适配
- Frameworks : 外部依赖（Realm、CloudKit等）
选择理由 ：

- MVVM与SwiftUI天然契合
- Clean Architecture提供清晰的责任分离
- 便于单元测试
- 模块化程度高，适合团队协作
### 3.2 辅助模式
- Repository模式 : 数据访问抽象
- Factory模式 : 对象创建
- Observer模式 : 数据变更通知
- Strategy模式 : 搜索策略、同步策略
## 4. 数据流设计
### 4.1 单向数据流
```plaintext
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   用户操作   │───▶│  状态更新   │───▶│   UI渲染    │
└─────────────┘    └─────────────┘    └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  数据持久化  │
                   └─────────────┘
 ``
```

- 用户操作触发Action
- ViewModel处理Action并更新State
- View根据State渲染UI
- 数据变更同步到持久层
### 4.2 离线优先策略
```plaintext
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  本地操作    │───▶│  本地存储   │───▶│   UI更新    │
└─────────────┘    └─────────────┘    └─────────────┘
                          │
                          ▼
                   ┌─────────────┐
                   │  云端同步   │
                   └─────────────┘
 ``
```

- 所有操作优先写入本地数据库
- UI从本地数据库读取并显示
- 后台异步进行云同步
- 同步冲突采用最新优先策略
### 4.3 状态管理
- 本地状态 : SwiftUI @State, @StateObject
- 共享状态 : 环境对象 @EnvironmentObject
- 持久状态 : Realm对象观察
## 5. 核心模块详细设计
### 5.1 词典查询模块
```plaintext
┌─────────────────────────────────────────────────────────────┐
│                      SearchViewModel                         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 查询状态     │  │ 搜索历史    │  │  搜索建议           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      DictionaryService                       │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 精确查询     │  │ 模糊查询    │  │  拼音查询           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      RealmManager                            │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 词条模型     │  │ 索引优化    │  │  缓存策略           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
 ``
```

### 5.2 收藏管理模块
```plaintext
┌─────────────────────────────────────────────────────────────┐
│                      FavoriteViewModel                       │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 收藏列表     │  │ 收藏操作    │  │  分类管理           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      FavoriteService                         │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 本地存储     │  │ 云同步      │  │  冲突解决           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
 ``
```

### 5.3 用户认证模块
```plaintext
┌─────────────────────────────────────────────────────────────┐
│                      UserViewModel                           │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ 登录状态     │  │ 用户信息    │  │  设置管理           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                      AuthService                             │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Apple登录    │  │ 游客模式    │  │  权限管理           │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
 ``
```

## 6. 数据模型设计
### 6.1 词典数据模型
```swift
// 词条模型
class DictEntry: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var word: String              // 单词
    @Persisted var reading: String           // 读音
    @Persisted var partOfSpeech: String      // 词性
    @Persisted var definitions: List<Definition> // 释义列表
    @Persisted var examples: List<Example>   // 例句列表
}

// 释义模型
class Definition: EmbeddedObject {
    @Persisted var meaning: String           // 中文释义
    @Persisted var notes: String?            // 注释
}

// 例句模型
class Example: EmbeddedObject {
    @Persisted var sentence: String          // 日语例句
    @Persisted var translation: String       // 中文翻译
}
 ``
```

### 6.2 用户数据模型
```swift
// 用户模型
class User: Object {
    @Persisted(primaryKey: true) var id: String  // Apple ID标识符
    @Persisted var nickname: String?             // 昵称
    @Persisted var settings: UserSettings?       // 用户设置
    @Persisted var lastSyncTime: Date?           // 最后同步时间
}

// 用户设置
class UserSettings: EmbeddedObject {
    @Persisted var darkMode: Bool = false        // 深色模式
    @Persisted var fontSize: Int = 2             // 字体大小
    @Persisted var autoSync: Bool = true         // 自动同步
}
 ``
```

### 6.3 收藏数据模型
```swift
// 收藏夹模型
class Folder: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var name: String                  // 收藏夹名称
    @Persisted var createdAt: Date = Date()      // 创建时间
    @Persisted var items: List<FavoriteItem>     // 收藏项目
    @Persisted var syncStatus: Int = 0           // 同步状态
}

// 收藏项目
class FavoriteItem: Object {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var wordId: String                // 词条ID
    @Persisted var word: String                  // 单词
    @Persisted var reading: String               // 读音
    @Persisted var meaning: String               // 简要释义
    @Persisted var note: String?                 // 个人笔记
    @Persisted var addedAt: Date = Date()        // 添加时间
    @Persisted var syncStatus: Int = 0           // 同步状态
}
 ``
```

## 7. 技术实现关键点
### 7.1 性能优化
- 词典查询索引优化
  
  - 为常用查询字段建立索引
  - 实现高效的模糊搜索算法
- 资源加载策略
  
  - 懒加载非关键资源
  - 预加载可能需要的数据
- UI渲染优化
  
  - 避免大列表一次性加载
  - 使用分页加载技术
### 7.2 离线功能实现
- 核心词库预装
  
  - 应用包含基础词库
  - 首次启动解压到Realm数据库
- 增量更新机制
  
  - 词库版本控制
  - 按需下载词库更新
### 7.3 数据同步策略
- 增量同步
  
  - 仅同步变更数据
  - 使用时间戳标记变更
- 冲突解决
  
  - 基于时间戳的冲突检测
  - 用户可选择保留哪个版本
### 7.4 错误处理
- 网络错误
  
  - 优雅降级到离线模式
  - 后台重试机制
- 数据错误
  
  - 数据完整性验证
  - 自动修复策略
## 8. 第三方依赖
- RealmSwift : 本地数据库
- CloudKit : 云同步
- AuthenticationServices : Sign in with Apple
- AVFoundation : 语音合成与播放
## 9. 安全考虑
- 数据安全
  
  - Realm数据库加密
  - 敏感信息安全存储
- 用户隐私
  
  - 最小化数据收集
  - 明确的隐私政策
## 10. 扩展性设计
- 模块化架构
  
  - 松耦合设计
  - 接口抽象
- 功能扩展点
  
  - 预留API扩展接口
  - 插件化设计思想

  
# UI/UX设计规范文档
## 1. 设计理念
我们的日语学习APP遵循"简约而不简单"的设计哲学，融合苹果设计语言与日本传统美学元素，创造出一个既现代又富有文化底蕴的学习环境。设计强调：

- 专注学习 ：减少视觉干扰，突出核心功能
- 直觉交互 ：用户无需思考即可完成操作
- 文化融合 ：将日本传统美学元素融入现代界面设计
- 愉悦体验 ：通过微妙的动效和视觉反馈增强用户满足感
## 2. 色彩系统
### 2.1 主色调
- 主色 Primary ：#00D2DD（清新湖水蓝）
  - 浅色变体：#7EEAEF（70%）
  - 深色变体：#008A91（130%）
### 2.2 辅助色
- 强调色 Accent ：#FF6B6B（暖珊瑚红）
- 中性色 Neutral ：
  - 浅灰：#F5F7FA
  - 中灰：#E1E5EA
  - 深灰：#8A9199
- 文本色 ：
  - 主要文本：#2C3E50
  - 次要文本：#5D6D7E
  - 提示文本：#8A9199
### 2.3 功能色
- 成功 ：#4CD964
- 警告 ：#FFCC00
- 错误 ：#FF3B30
- 信息 ：#007AFF
### 2.4 深色模式调整
- 背景 ：#121212
- 表面 ：#1E1E1E
- 主色调整 ：#00E6F2（增加亮度10%）
- 文本 ：#FFFFFF / #BBBBBB / #777777
## 3. 排版系统
### 3.1 字体
- 主要字体 ：SF Pro Text（英文/数字）+ PingFang SC（中文）+ Hiragino Sans（日文）
- 特殊强调 ：SF Pro Display（标题）
### 3.2 字号与行高
- 大标题 ：24pt / 32pt行高
- 标题 ：20pt / 28pt行高
- 副标题 ：17pt / 24pt行高
- 正文 ：15pt / 22pt行高
- 次要文本 ：13pt / 18pt行高
- 注释 ：11pt / 16pt行高
### 3.3 字重
- 粗体 ：用于标题、强调内容（600）
- 常规 ：用于正文内容（400）
- 轻量 ：用于次要信息（300）
## 4. 间距与布局
### 4.1 基础间距单位
基础单位：8pt

- 紧凑间距 ：8pt（1×）
- 标准间距 ：16pt（2×）
- 宽松间距 ：24pt（3×）
- 分隔间距 ：32pt（4×）
### 4.2 布局网格
- 外边距 ：16pt（屏幕边缘）
- 列间距 ：16pt
- 安全区域 ：遵循iOS安全区域指南
### 4.3 组件间距
- 相关元素间 ：8pt
- 独立区块间 ：24pt
- 主要分区间 ：32pt
## 5. 组件库
### 5.1 基础组件 5.1.1 按钮
- 主要按钮 ：
  
  - 高度：48pt
  - 圆角：12pt
  - 背景：主色
  - 文字：白色，17pt，600字重
  - 状态：普通/按下/禁用
- 次要按钮 ：
  
  - 高度：48pt
  - 圆角：12pt
  - 背景：透明
  - 边框：1pt主色
  - 文字：主色，17pt，600字重
- 文本按钮 ：
  
  - 无背景和边框
  - 文字：主色，15pt，400字重
  - 状态：普通/按下/禁用 5.1.2 输入框
- 搜索框 ：
  
  - 高度：44pt
  - 圆角：10pt
  - 背景：#F5F7FA（浅灰）
  - 内边距：水平12pt，垂直0
  - 图标：左侧搜索图标，右侧清除按钮
  - 文字：15pt，400字重
- 文本输入框 ：
  
  - 高度：44pt
  - 底部边框：1pt，#E1E5EA
  - 激活状态：底部边框变为主色
  - 内边距：水平0，垂直12pt
  - 文字：15pt，400字重 5.1.3 卡片
- 标准卡片 ：
  
  - 圆角：16pt
  - 背景：白色
  - 阴影：y:2pt, blur:8pt, #0000001A
  - 内边距：16pt
  - 边距：水平16pt，垂直12pt
- 词条卡片 ：
  
  - 圆角：12pt
  - 背景：白色
  - 阴影：y:1pt, blur:4pt, #0000000F
  - 内边距：16pt
  - 边距：水平16pt，垂直8pt
### 5.2 特殊组件 5.2.1 浮动学习中心
- 形状 ：圆形，直径64pt
- 背景 ：主色渐变（#00D2DD到#00A8B3）
- 阴影 ：y:4pt, blur:16pt, #00D2DD40
- 图标 ：白色，32pt
- 位置 ：屏幕右下角，距离边缘24pt 5.2.2 词汇卡片
- 外观 ：圆角16pt，白色背景
- 布局 ：
  - 顶部：日语单词（20pt，600字重）
  - 中部：假名（15pt，400字重）
  - 底部：中文释义（15pt，400字重）
- 交互 ：支持左右滑动、点击展开详情
- 状态指示 ：收藏状态、学习进度 5.2.3 发音按钮
- 形状 ：圆形，直径36pt
- 背景 ：主色10%透明度
- 图标 ：主色，18pt
- 位置 ：单词旁边
- 动效 ：点击时波纹效果
## 6. 创新导航设计
### 6.1 学习中心导航
取代传统的Tabbar，我们设计了一个创新的"学习中心"导航系统：

- 核心元素 ：屏幕右下角的浮动圆形按钮（学习中心）
- 交互方式 ：
  - 点击：展开半圆形菜单，显示主要功能区域
  - 长按：显示快捷操作（快速搜索、收藏管理）
  - 滑动：可拖动到屏幕边缘，自动吸附
### 6.2 功能区域划分
- 词典区域 ：主屏幕，支持搜索和浏览
- 收藏区域 ：通过学习中心一键进入
- 学习区域 ：个性化学习计划和进度
- 设置区域 ：通过顶部个人头像进入
### 6.3 手势导航
- 返回 ：从左侧边缘向右滑动
- 收起菜单 ：点击空白区域
- 快速搜索 ：从屏幕顶部下拉
- 刷新内容 ：下拉刷新
## 7. 首页设计
### 7.1 概述
首页采用流体卡片设计，摒弃传统列表式布局，创造出一个动态、有机的学习环境。

### 7.2 布局结构
- 顶部区域 ：
  
  - 左侧：用户头像（未登录则显示默认图标）
  - 中间：动态问候语（"早上好"/"下午好"等）
  - 右侧：设置入口
- 搜索区域 ：
  
  - 大型搜索框，占据屏幕80%宽度
  - 支持语音输入和手写识别
  - 智能输入建议
- 学习流区域 ：
  
  - 动态流体卡片布局
  - 卡片类型：
    - 每日学习建议
    - 最近查询词汇
    - 学习进度卡片
    - 收藏夹快速访问
- 浮动学习中心 ：
  
  - 右下角主色调圆形按钮
  - 点击展开功能菜单
### 7.3 视觉特点
- 流体动效 ：卡片随滚动产生微妙的视差效果
- 渐变色彩 ：主色调的精妙渐变应用
- 空间层次 ：通过阴影和高光创造深度感
- 微妙动画 ：界面元素的细微动效增强交互感
### 7.4 创新元素
- 智能词云 ：根据用户学习历史动态生成的词云
- 学习路径 ：可视化的学习进度曲线
- 情境推荐 ：基于时间、位置的学习内容推荐
- 互动提示 ：轻量级的学习提示和鼓励
## 8. 屏幕流程图
### 8.1 核心用户旅程 8.1.1 词典查询流程
1. 首页 → 搜索框输入
2. 搜索结果列表
3. 词条详情页
4. 可选操作：收藏/发音/查看例句 8.1.2 收藏管理流程
1. 学习中心 → 收藏选项
2. 收藏夹列表
3. 收藏夹内容
4. 单词详情/编辑笔记 8.1.3 用户登录流程
1. 首页 → 头像
2. 登录选项页
3. Sign in with Apple
4. 个人设置页
## 9. 交互规范
### 9.1 触摸反馈
- 按钮 ：轻微缩放(0.97)和透明度变化(0.9)
- 卡片 ：轻微下沉效果(y:1pt)
- 列表项 ：背景色变化
### 9.2 动效指南
- 转场动画 ：自然、流畅，持续时间300ms
- 加载动画 ：使用主色调的脉动效果
- 微交互 ：按钮、开关等元素的状态变化动画
### 9.3 可访问性考量
- 触控区域 ：最小44×44pt
- 色彩对比 ：符合WCAG AA级标准
- 动效减弱 ：提供减少动画选项
- VoiceOver ：所有元素添加适当标签
## 10. MVP阶段实现优先级
### 10.1 必要UI组件（优先级：高）
- 创新的学习中心导航
- 搜索框及结果展示
- 词条详情页布局
- 基础卡片组件
- 收藏按钮和标记
### 10.2 次要UI组件（优先级：中）
- 用户头像和设置入口
- 学习流动态卡片
- 发音按钮动效
- Sign in with Apple按钮
### 10.3 增强UI组件（优先级：低）
- 流体动效和视差效果
- 智能词云
- 学习路径可视化
- 深色模式适配
## 11. 设计资源
- 设计系统组件库（Figma）
- 图标库（SF Symbols + 自定义图标）
- 动效规范（Lottie动画）
- 原型交互示例


# 基于本地数据层的API接口文档设计
根据技术架构文档中的数据层设计，我们采用了"无后端"架构，主要依靠Realm本地数据库、CloudKit云同步和AppleAuth用户认证。针对这种情况，我们需要设计一套内部API接口文档，主要描述应用内各层之间的交互方式。

## 1. 接口设计思路
在无后端架构下，API接口主要是指：

1. 业务层(Domain)与数据层(Data)之间的接口
2. 表现层(Presentation)与业务层(Domain)之间的接口
3. 数据层内部组件之间的接口
这些接口将以Swift协议(Protocol)和函数(Function)的形式定义，而非传统的HTTP REST API。

## 2. 数据层接口设计
### 2.1 RealmManager接口
```swift
protocol DictionaryRepositoryProtocol {
    // 查询单词
    func searchWords(query: String, type: SearchType, limit: Int, offset: Int) -> AnyPublisher<[DictEntry], Error>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<DictEntry?, Error>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], Error>
    
    // 添加搜索历史
    func addSearchHistory(word: DictEntry) -> AnyPublisher<Void, Error>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Void, Error>
    
    // 初始化/更新词库
    func initializeDictionary() -> AnyPublisher<Void, Error>
    
    // 检查词库版本
    func checkDictionaryVersion() -> AnyPublisher<DictionaryVersion, Error>
}

enum SearchType {
    case auto      // 自动识别
    case word      // 按单词
    case reading   // 按读音
    case meaning   // 按释义
}
```

### 2.2 收藏管理接口
```swift
protocol FavoriteRepositoryProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[Folder], Error>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<Folder, Error>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<Folder, Error>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, Error>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<[FavoriteItem], Error>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItem, Error>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItem, Error>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, Error>
    
    // 检查单词是否已收藏
    func isWordFavorited(wordId: String) -> AnyPublisher<Bool, Error>
}
```

### 2.3 用户认证接口
```swift
protocol UserAuthRepositoryProtocol {
    // Apple ID登录
    func signInWithApple(identityToken: Data, authorizationCode: String, fullName: PersonNameComponents?, email: String?, userIdentifier: String) -> AnyPublisher<User, Error>
    
    // 获取当前用户
    func getCurrentUser() -> AnyPublisher<User?, Error>
    
    // 更新用户设置
    func updateUserSettings(settings: UserSettings) -> AnyPublisher<UserSettings, Error>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, Error>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

```

### 2.4 云同步接口
```swift
protocol SyncRepositoryProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatus, Error>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperation, Error>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgress, Error>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, Error>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, Error>
}

enum SyncType {
    case full       // 全量同步
    case favorites  // 仅同步收藏
    case settings   // 仅同步设置
}

enum ConflictResolution {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}

```

## 3. 业务层接口设计
### 3.1 词典服务接口
```swift
protocol DictionaryServiceProtocol {
    // 搜索单词
    func searchWords(query: String, type: SearchType?, limit: Int, offset: Int) -> AnyPublisher<SearchResult, DictionaryError>
    
    // 获取单词详情
    func getWordDetails(id: String) -> AnyPublisher<WordDetails, DictionaryError>
    
    // 获取单词发音
    func getWordPronunciation(id: String, speed: Float) -> AnyPublisher<URL, DictionaryError>
    
    // 获取搜索历史
    func getSearchHistory(limit: Int) -> AnyPublisher<[SearchHistoryItem], DictionaryError>
    
    // 清除搜索历史
    func clearSearchHistory() -> AnyPublisher<Bool, DictionaryError>
}

struct SearchResult {
    let total: Int
    let items: [WordSummary]
}

struct WordSummary {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let briefMeaning: String
}

struct WordDetails {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [Definition]
    let examples: [Example]
    let relatedWords: [WordSummary]
    let isFavorited: Bool
}

enum DictionaryError: Error {
    case notFound
    case searchFailed
    case databaseError
    case pronunciationFailed
    case networkError
}

```

### 3.2 收藏服务接口
```swift
protocol FavoriteServiceProtocol {
    // 获取所有收藏夹
    func getAllFolders() -> AnyPublisher<[FolderSummary], FavoriteError>
    
    // 创建收藏夹
    func createFolder(name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 更新收藏夹
    func updateFolder(id: String, name: String) -> AnyPublisher<FolderSummary, FavoriteError>
    
    // 删除收藏夹
    func deleteFolder(id: String) -> AnyPublisher<Bool, FavoriteError>
    
    // 获取收藏夹内容
    func getFolderItems(folderId: String, limit: Int, offset: Int) -> AnyPublisher<FolderContent, FavoriteError>
    
    // 添加收藏
    func addFavorite(wordId: String, folderId: String, note: String?) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 更新收藏笔记
    func updateFavoriteNote(id: String, note: String) -> AnyPublisher<FavoriteItemDetail, FavoriteError>
    
    // 删除收藏
    func deleteFavorite(id: String) -> AnyPublisher<Bool, FavoriteError>
}

struct FolderSummary {
    let id: String
    let name: String
    let createdAt: Date
    let itemCount: Int
    let syncStatus: SyncStatus
}

struct FolderContent {
    let total: Int
    let items: [FavoriteItemDetail]
}

struct FavoriteItemDetail {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: SyncStatus
}

enum FavoriteError: Error {
    case folderNotFound
    case itemNotFound
    case duplicateName
    case databaseError
    case syncError
}

enum SyncStatus {
    case synced        // 已同步
    case pendingUpload // 待上传
    case pendingDownload // 待下载
    case conflict      // 冲突
    case error         // 错误
}

```

### 3.3 用户服务接口
```swift
protocol UserServiceProtocol {
    // Apple ID登录
    func signInWithApple() -> AnyPublisher<UserProfile, UserError>
    
    // 获取用户信息
    func getUserProfile() -> AnyPublisher<UserProfile, UserError>
    
    // 更新用户设置
    func updateUserSettings(settings: UserPreferences) -> AnyPublisher<UserPreferences, UserError>
    
    // 登出
    func signOut() -> AnyPublisher<Bool, UserError>
    
    // 检查登录状态
    func isUserLoggedIn() -> Bool
}

struct UserProfile {
    let userId: String
    let nickname: String?
    let settings: UserPreferences
    let lastSyncTime: Date?
    let favoriteCount: Int
    let folderCount: Int
}

struct UserPreferences {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

enum UserError: Error {
    case authenticationFailed
    case userNotFound
    case settingsUpdateFailed
    case signOutFailed
}

```

### 3.4 同步服务接口
```swift
protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfo, SyncError>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperationInfo, SyncError>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfo, SyncError>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, SyncError>
}

struct SyncStatusInfo {
    let lastSyncTime: Date?
    let pendingChanges: Int
    let syncStatus: String
    let availableOffline: Bool
}

struct SyncOperationInfo {
    let syncId: String
    let startedAt: Date
    let status: String
    let estimatedTimeRemaining: Int?
}

struct SyncProgressInfo {
    let syncId: String
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
}

enum SyncError: Error {
    case networkUnavailable
    case cloudKitError
    case authenticationRequired
    case conflictDetected
    case syncInProgress
}

```

## 4. 表现层接口设计
### 4.1 SearchViewModel接口
```swift
protocol SearchViewModelProtocol: ObservableObject {
    // 输入属性
    var searchQuery: String { get set }
    var searchType: SearchType { get set }
    
    // 输出属性
    var searchResults: [WordSummary] { get }
    var searchHistory: [SearchHistoryItem] { get }
    var suggestions: [String] { get }
    var isSearching: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func search()
    func clearSearch()
    func selectWord(id: String)
    func clearHistory()
    func loadMoreResults()
}


### 4.2 DetailViewModel接口
```swift
protocol DetailViewModelProtocol: ObservableObject {
    // 输出属性
    var wordDetails: WordDetails? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isFavorited: Bool { get }
    
    // 方法
    func loadWordDetails(id: String)
    func playPronunciation(speed: Float)
    func toggleFavorite()
    func addNote(note: String)
}


### 4.3 FavoriteViewModel接口
```swift
protocol FavoriteViewModelProtocol: ObservableObject {
    // 输出属性
    var folders: [FolderSummary] { get }
    var selectedFolder: FolderSummary? { get }
    var folderItems: [FavoriteItemDetail] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    // 方法
    func loadFolders()
    func createFolder(name: String)
    func renameFolder(id: String, newName: String)
    func deleteFolder(id: String)
    func selectFolder(id: String)
    func loadFolderItems(folderId: String)
    func updateNote(itemId: String, note: String)
    func removeFromFavorites(itemId: String)
    func loadMoreItems()
}


### 4.4 UserViewModel接口
```swift
protocol UserViewModelProtocol: ObservableObject {
    // 输出属性
    var userProfile: UserProfile? { get }
    var isLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var userSettings: UserPreferences { get }
    
    // 方法
    func signInWithApple()
    func signOut()
    func loadUserProfile()
    func updateSettings(darkMode: Bool, fontSize: Int, autoSync: Bool)
}


## 5. 数据模型
### 5.1 领域模型
这些模型是业务层使用的，与数据层的Realm模型相分离：

```swift
// 词典领域模型
struct DictEntryDomain {
    let id: String
    let word: String
    let reading: String
    let partOfSpeech: String
    let definitions: [DefinitionDomain]
    let examples: [ExampleDomain]
}

struct DefinitionDomain {
    let meaning: String
    let notes: String?
}

struct ExampleDomain {
    let sentence: String
    let translation: String
}

// 用户领域模型
struct UserDomain {
    let id: String
    let nickname: String?
    let settings: UserSettingsDomain
    let lastSyncTime: Date?
}

struct UserSettingsDomain {
    let darkMode: Bool
    let fontSize: Int
    let autoSync: Bool
}

// 收藏领域模型
struct FolderDomain {
    let id: String
    let name: String
    let createdAt: Date
    let items: [FavoriteItemDomain]
    let syncStatus: Int
}

struct FavoriteItemDomain {
    let id: String
    let wordId: String
    let word: String
    let reading: String
    let meaning: String
    let note: String?
    let addedAt: Date
    let syncStatus: Int
}


## 6. 错误处理
### 6.1 错误类型定义
```swift
// 通用错误基类
enum AppError: Error {
    case unknown
    case networkError
    case databaseError(String)
    case validationError(String)
    case authenticationError
    case syncError(String)
}

// 特定功能错误
extension AppError {
    static func dictionary(_ error: DictionaryError) -> AppError {
        switch error {
        case .notFound:
            return .validationError("单词未找到")
        case .searchFailed:
            return .databaseError("搜索失败")
        case .databaseError:
            return .databaseError("数据库错误")
        case .pronunciationFailed:
            return .unknown
        case .networkError:
            return .networkError
        }
    }
    
    static func favorite(_ error: FavoriteError) -> AppError {
        switch error {
        case .folderNotFound:
            return .validationError("收藏夹未找到")
        case .itemNotFound:
            return .validationError("收藏项未找到")
        case .duplicateName:
            return .validationError("收藏夹名称重复")
        case .databaseError:
            return .databaseError("数据库错误")
        case .syncError:
            return .syncError("同步错误")
        }
    }
}


### 6.2 错误处理策略
```swift
protocol ErrorHandling {
    func handle(_ error: Error) -> String
    func logError(_ error: Error, file: String, line: Int, function: String)
}

class AppErrorHandler: ErrorHandling {
    func handle(_ error: Error) -> String {
        // 将各种错误转换为用户友好的消息
        if let appError = error as? AppError {
            switch appError {
            case .unknown:
                return "发生未知错误"
            case .networkError:
                return "网络连接错误，请检查网络设置"
            case .databaseError(let message):
                return "数据访问错误: \(message)"
            case .validationError(let message):
                return message
            case .authenticationError:
                return "认证失败，请重新登录"
            case .syncError(let message):
                return "同步错误: \(message)"
            }
        }
        return "操作失败，请稍后重试"
    }
    
    func logError(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        // 记录错误日志
        print("Error: \(error.localizedDescription), File: \(file), Line: \(line), Function: \(function)")
        // 在实际应用中，可以将错误发送到日志服务
    }
}

```

## 7. 数据转换
### 7.1 数据层到业务层的转换
```swift
// Realm模型到领域模型的转换
extension DictEntry {
    func toDomain() -> DictEntryDomain {
        return DictEntryDomain(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            definitions: definitions.map { $0.toDomain() },
            examples: examples.map { $0.toDomain() }
        )
    }
}

extension Definition {
    func toDomain() -> DefinitionDomain {
        return DefinitionDomain(
            meaning: meaning,
            notes: notes
        )
    }
}

extension Example {
    func toDomain() -> ExampleDomain {
        return ExampleDomain(
            sentence: sentence,
            translation: translation
        )
    }
}


### 7.2 业务层到表现层的转换
```swift
// 领域模型到视图模型的转换
extension DictEntryDomain {
    func toWordDetails(isFavorited: Bool) -> WordDetails {
        return WordDetails(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            definitions: definitions.map { 
                Definition(meaning: $0.meaning, notes: $0.notes) 
            },
            examples: examples.map { 
                Example(sentence: $0.sentence, translation: $0.translation) 
            },
            relatedWords: [], // 需要另外填充
            isFavorited: isFavorited
        )
    }
    
    func toWordSummary() -> WordSummary {
        return WordSummary(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            briefMeaning: definitions.first?.meaning ?? ""
        )
    }
}


## 8. 实现注意事项
### 8.1 离线优先策略
- 所有数据操作首先在本地Realm数据库执行
- 操作成功后，标记为待同步状态
- 当网络可用且用户已登录iCloud时，后台执行CloudKit同步
- 同步冲突时，根据策略自动解决或提示用户选择
### 8.2 性能考量
- 使用Realm的异步查询API
- 实现分页加载机制，避免一次加载大量数据
- 对频繁访问的数据实现内存缓存
- 使用Combine框架的防抖动操作优化搜索性能
### 8.3 安全考量
- 使用Realm加密功能保护本地数据
- 敏感用户数据存储在钥匙串(Keychain)中
- 利用CloudKit的内置安全机制保护云端数据
- 实现适当的错误处理，避免敏感信息泄露
## 9. 接口使用示例
### 9.1 词典查询示例
```swift
class SearchViewModel: SearchViewModelProtocol {
    private let dictionaryService: DictionaryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // 实现协议属性
    @Published var searchQuery: String = ""
    @Published var searchType: SearchType = .auto
    @Published private(set) var searchResults: [WordSummary] = []
    @Published private(set) var searchHistory: [SearchHistoryItem] = []
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    init(dictionaryService: DictionaryServiceProtocol) {
        self.dictionaryService = dictionaryService
        loadSearchHistory()
    }
    
    func search() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        dictionaryService.searchWords(query: searchQuery, type: searchType, limit: 20, offset: 0)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSearching = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = AppErrorHandler().handle(error)
                    }
                },
                receiveValue: { [weak self] result in
                    self?.searchResults = result.items
                }
            )
            .store(in: &cancellables)
    }
    
    // 其他方法实现...
}

```

### 9.2 收藏操作示例
```swift
class DetailViewModel: DetailViewModelProtocol {
    private let dictionaryService: DictionaryServiceProtocol
    private let favoriteService: FavoriteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // 实现协议属性
    @Published private(set) var wordDetails: WordDetails? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var isFavorited: Bool = false
    
    init(dictionaryService: DictionaryServiceProtocol, favoriteService: FavoriteServiceProtocol) {
        self.dictionaryService = dictionaryService
        self.favoriteService = favoriteService
    }
    
    func loadWordDetails(id: String) {
        isLoading = true
        errorMessage = nil
        
        dictionaryService.getWordDetails(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = AppErrorHandler().handle(error)
                    }
                },
                receiveValue: { [weak self] details in
                    self?.wordDetails = details
                    self?.isFavorited = details.isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleFavorite() {
        guard let wordDetails = wordDetails else { return }
        
        if isFavorited {
            // 查找并删除收藏
            // 实际实现需要先查询收藏项ID
            // 这里简化处理
        } else {
            // 添加到默认收藏夹
            favoriteService.addFavorite(wordId: wordDetails.id, folderId: "default", note: nil)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            self?.errorMessage = AppErrorHandler().handle(error)
                        }
                    },
                    receiveValue: { [weak self] _ in
                        self?.isFavorited = true
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    // 其他方法实现...
}

```

## 10. 总结
本API接口文档设计基于无后端架构，主要通过Swift协议定义了应用内各层之间的交互接口。这种设计有以下优势：

1. 符合离线优先策略 ：所有操作首先在本地执行，确保离线可用
2. 利用原生能力 ：充分利用Realm、CloudKit和AppleAuth的原生能力
3. 清晰的责任分离 ：各层之间通过接口通信，降低耦合度
4. 易于测试 ：接口抽象便于编写单元测试和模拟测试
5. 扩展性好 ：如果未来需要添加后端服务，只需实现相同的接口即可
通过这套接口设计，我们可以实现MVP阶段所需的全部功能，同时为后续功能扩展提供良好的架构基础。