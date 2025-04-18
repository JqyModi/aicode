## 文档驱动开发提问
鉴于AI通用能力的大幅提升，我认为文档驱动开发显得尤为重要，因为AI无法主动反馈信息，而它可以通过查询特定阶段特定文档内容作为指导来出色完成任务，如果我想开发一款iOS APP，你认为哪些文档是必要的呢？

## DS - 回答

## uiux设计文档提问
结合 detailed_design.md detailed_design.md 189-195 DDD_V3.md 19-23 设计一份UI/UX设计规范文档，主色调可以参考#903AF4和#00D2DD，界面区别传统tabbar导航设计，可以发挥你的聪明才智设计一个全新的首页，设计风格参考苹果设计理念，简洁美观，交互方便，UI元素布局上聚焦核心功能，简洁但富有创意，最好能给用户眼前一亮的感觉

## 高保真原型设计提问
结合UIUX规范 #file：UIUX.md 现在需要输出高保真的原型图，请通过以下方式帮我完成所有界面的原型设计，并确保这些原型界面可以直接用于开发：

- 高保真 UI 设计：作为 UI 设计师，设计贴近真实 iOS/Android 设计规范的界面，使用现代化的 UI 元素，使其具有良好的视觉体验。

- HTML 原型实现：使用 HTML + Tailwind CSS（或 Bootstrap）生成所有原型界面，并使用 FontAwesome（或其他开源 UI 组件）让界面更加精美、接近真实的 App 设计。拆分代码文件，保持结构清晰：

- 将所有页面直接平铺展示在 index 页面中，而不是跳转链接。- 真实感增强：- 界面尺寸应模拟 iPhone 15 Pro，并让界面圆角化，使其更像真实的手机界面。- 使用真实的 UI 图片，而非占位符图片（可从 Unsplash、Pexels、Apple 官方 UI 资源中选择）。- 添加顶部状态栏（模拟 iOS 状态栏），并包含 App 导航栏（类似 iOS 底部 Tab Bar）。

请按照以上要求生成完整的 HTML 代码，并确保其可用于实际开发。

## 改进后的 - 高保真原型设计提问
```markdown
我需要根据UIUX规范设计一款[应用类型]应用的高保真原型图。以下是我的UIUX规范要点：

[在此粘贴UIUX.md的关键内容]

请帮我完成以下页面的高保真原型设计：
1. [页面1名称]：[简要功能描述]
2. [页面2名称]：[简要功能描述]
3. [页面3名称]：[简要功能描述]
...

技术要求：
- 使用HTML + Tailwind CSS实现所有原型界面
- 使用FontAwesome图标库增强UI表现
- 代码结构清晰，CSS和HTML分离
- 所有页面平铺展示在index.html中，不需要页面跳转

设计规范：
- 设备尺寸：iPhone 15 Pro (宽度390px，高度844px)
- 设计风格：[您偏好的设计风格，如iOS 16扁平化设计]
- 色彩方案：[主色调、辅助色等]
- 包含iOS状态栏和底部导航栏
- 使用真实UI图片，不使用占位符

交互要求：
- [是否需要简单交互，如点击效果]
- [是否需要表单验证]
- [其他交互需求]

请提供完整的HTML、CSS代码，并确保代码可以直接用于开发。
```
## 改进后的 - 高保真原型设计提问(SwiftUI版)
```markdown
我需要根据UIUX规范设计一款[应用类型]应用的高保真原型图。以下是我的UIUX规范要点：

[在此粘贴UIUX.md的关键内容]

请帮我完成以下页面的高保真SwiftUI原型设计：
1. [页面1名称]：[简要功能描述]
2. [页面2名称]：[简要功能描述]
3. [页面3名称]：[简要功能描述]
...

技术要求：
- 使用SwiftUI实现所有原型界面
- 使用SF Symbols图标库增强UI表现
- 代码结构清晰，遵循MVVM架构
- 所有页面通过PreviewProvider展示，方便在Xcode中直接预览
- 使用SwiftUI的组件化开发方式，确保代码可复用性

设计规范：
- 设备尺寸：iPhone 15 Pro
- 设计风格：[您偏好的设计风格，如iOS 16扁平化设计]
- 色彩方案：[主色调、辅助色等]
- 遵循iOS Human Interface Guidelines
- 使用真实UI图片资源，不使用占位符

交互要求：
- [是否需要简单交互，如点击效果]
- [是否需要表单验证]
- [其他交互需求]

请提供完整的SwiftUI代码，包括必要的View、Model和ViewModel，并确保代码可以直接在Xcode中预览和用于实际开发。
```
## iOS交互要求建议
```markdown
## 基础交互建议
1. 点击反馈效果
   
   - 按钮点击时的缩放或颜色变化动画
   - 列表项选中时的高亮效果
   - 长按操作的视觉反馈
2. 手势交互
   
   - 滑动导航（在页面间切换）
   - 下拉刷新内容
   - 拖拽排序列表项
   - 双指缩放图片或地图
3. 表单交互
   
   - 输入验证（邮箱格式、密码强度等）
   - 实时输入反馈（字数限制、格式错误提示）
   - 自动完成/建议功能
   - 键盘适配（自动调整视图避免键盘遮挡）
## 高级交互建议
1. 过渡动画
   
   - 页面间的平滑过渡效果
   - 内容加载时的骨架屏或渐显效果
   - 列表项添加/删除的动画
2. 状态变化反馈
   
   - 加载状态指示器
   - 成功/失败操作的视觉反馈
   - 空状态处理（无数据时的友好提示）
3. 上下文感知交互
   
   - 基于用户行为的智能建议
   - 情境菜单（长按弹出操作选项）
   - 动态内容更新
## 实现示例
您可以在交互要求部分这样描述：

交互要求：
- 实现按钮的点击反馈动画（.scaleEffect和.opacity结合）
- 添加列表项的滑动删除功能
- 实现表单输入验证（邮箱格式、必填项检查）
- 添加页面间的平滑过渡动画
- 实现下拉刷新功能
- 加载状态和空状态的处理
- 键盘出现时自动调整视图位置
```

## 原型技术栈提问
```markdown
# 关于原型设计技术栈的分析与建议
您提到的HTML + Tailwind CSS/Bootstrap + FontAwesome确实是一个非常通用且实用的技术组合，但根据不同的项目需求和团队情况，可能还有其他值得考虑的选择。

## 当前技术栈的优势
1. 通用性强 ：HTML是网页的基础，几乎所有设备都能支持
2. 开发效率高 ：Tailwind CSS和Bootstrap都提供了丰富的预设样式和组件
3. 响应式设计 ：这些框架内置了响应式设计功能，适合多设备适配
4. FontAwesome图标库 ：提供了丰富的图标资源，增强UI表现力
## 其他可考虑的技术方案
### 1. Figma + HTML导出插件
- 优势 ：设计与代码无缝衔接，设计师可直接在Figma中完成设计
- 适用场景 ：有专业设计师参与的项目，需要高度还原设计稿
### 2. React/Vue + 组件库
- 技术组合 ：React/Vue + Ant Design/Element UI/Chakra UI
- 优势 ：组件化开发，可复用性高，交互性更强
- 适用场景 ：最终产品会使用这些框架开发，希望原型和最终产品技术栈一致
### 3. Flutter Web
- 优势 ：如果最终产品是Flutter开发的iOS应用，使用Flutter Web可以保持设计一致性
- 适用场景 ：团队已经使用Flutter开发移动应用
### 4. Tailwind CSS + Alpine.js + Heroicons
- 优势 ：比您提到的方案更轻量，Alpine.js提供了简单的交互能力
- 适用场景 ：需要简单交互但不想引入大型框架的项目
### 5. 专业原型工具
- 工具 ：Axure RP、Adobe XD、InVision
- 优势 ：专为原型设计打造，有丰富的交互功能
- 适用场景 ：需要复杂交互验证的项目，团队中有这些工具使用经验
## 针对iOS应用原型的最佳推荐
考虑到您是开发iOS应用，我的建议是：

1. 如果重视设计还原度 ：使用Figma设计+导出HTML/CSS，或直接使用SwiftUI预览
2. 如果重视开发效率和代码复用 ：使用React/Vue + TailwindCSS + 移动端UI组件库(如Ionic)
3. 如果需要快速验证 ：继续使用您提到的HTML + Tailwind CSS + FontAwesome，但可以考虑添加一些轻量级的JS库如Alpine.js来增强交互性
4. 如果团队已有Swift/SwiftUI经验 ：考虑直接使用SwiftUI创建原型，这样可以直接复用到最终产品中
总的来说，您当前选择的技术栈已经很好，关键是要根据项目的具体需求和团队的技术背景来选择最合适的方案。
```


## 编码阶段提问

Q:
我正在进行文档驱动开发阶段性验证，ddd_v3.md列举了开发过程必要文档，product_define.md是产品定义文档，tec_architecture.md是技术架构文档，feature_list.md是核心功能文档，detailed_design.md详细功能规格说明文档，uiux_v2.md是UI/UX设计规范文档，api_v1.md是API接口文档，在此基础上我将开始编码阶段，如何结构化表达让AI准确理解且遵循现有文档来开发代码？

A:
# 结构化表达指南：让AI准确理解并遵循现有文档开发代码
在进入编码阶段时，为了确保AI能够准确理解并遵循您已有的文档进行开发，我建议采用以下结构化表达方式：

## 1. 明确开发上下文
```plaintext
我正在基于以下文档进行日语学习APP的开发：
- <mcfile name="DDD_V3.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/DDD_V3.md"></mcfile>：开发过程必要文档清单
- <mcfile name="product_define.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/product_define.md"></mcfile>：产品定义文档
- <mcfile name="tec_architecture.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/tec_architecture.md"></mcfile>：技术架构文档
- <mcfile name="feature_list.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/feature_list.md"></mcfile>：核心功能文档
- <mcfile name="detailed_design.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/detailed_design.md"></mcfile>：详细功能规格说明
- <mcfile name="uiux_v2.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/uiux_v2.md"></mcfile>：UI/UX设计规范
- <mcfile name="api_v1.md" path="/Users/modi/Documents/Modi/ai_code/aicode-ios/Docs/MVP/api_v1.md"></mcfile>：API接口文档

现在我需要开始编码实现阶段。
 ``
```

## 2. 明确当前任务
```plaintext
当前任务：[具体描述当前需要实现的功能模块或组件]
参考文档：[指明与当前任务最相关的1-2个文档]
 ```

例如：

```plaintext
当前任务：实现基础词典查询功能的数据层
参考文档：tec_architecture.md的RealmManager接口设计和api_v1.md的DictionaryRepositoryProtocol
 ``
```

## 3. 提供具体实现要求
```plaintext
请根据以下要求实现代码：

1. 遵循技术架构文档中的MVVM+Clean Architecture架构
2. 实现[具体功能]的[具体层级]代码
3. 代码需符合[相关文档]中定义的接口规范
4. 使用Swift语言，支持iOS 14.0及以上版本
5. [其他特定要求]
 ```

## 4. 请求特定文件的创建或修改
```plaintext
请创建以下文件：

1. [文件路径和名称]：实现[具体功能]
   - 需要实现的关键功能：[列出要点]
   - 需要遵循的接口：[接口名称]
   - 依赖的其他组件：[组件名称]

2. [文件路径和名称]：实现[具体功能]
   ...
 ```

## 5. 阶段性验证请求
```plaintext
完成上述文件后，请说明：
1. 代码如何满足文档中的要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能
 ```

## 具体示例
以下是一个完整的请求示例：

```plaintext
我正在基于已有文档进行日语学习APP的开发，现在需要开始实现数据层的基础代码。

当前任务：创建RealmManager和基础数据模型
参考文档：tec_architecture.md的数据层设计和api_v1.md的数据层接口

请根据以下要求实现代码：

1. 遵循技术架构文档中的数据层设计
2. 实现Realm数据模型和RealmManager基础类
3. 代码需符合api_v1.md中定义的DictionaryRepositoryProtocol接口
4. 使用Swift语言，支持iOS 14.0及以上版本
5. 实现离线优先策略

请创建以下文件：

1. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Models/DictModels.swift：
   - 实现词典相关的Realm数据模型
   - 包括DictEntry、Definition、Example等模型
   - 参考api_v1.md中的数据模型设计

2. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/RealmManager.swift：
   - 实现RealmManager基础类
   - 提供Realm实例管理
   - 实现数据库初始化和配置

3. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/DictionaryRepository.swift：
   - 实现DictionaryRepositoryProtocol接口
   - 提供词典查询相关功能
   - 实现离线词库管理

完成上述文件后，请说明：
1. 代码如何满足tec_architecture.md中的数据层设计要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能
 ``
```

## 建议
1. 分阶段请求 ：按照架构分层逐步实现，例如先实现数据层，再实现业务层，最后实现表现层
2. 关注依赖关系 ：明确指出当前实现依赖哪些已有组件或将被哪些组件依赖
3. 引用文档中的具体部分 ：在请求中引用文档的具体章节或页码，帮助AI定位相关信息
4. 提供清晰的文件结构 ：明确指出文件应该放在项目的哪个位置，遵循什么命名规范
5. 设置验收标准 ：明确说明如何判断实现是否符合要求，例如需要通过哪些测试或满足哪些条件
通过这种结构化的表达方式，AI能够更准确地理解您的需求，并基于现有文档生成符合要求的代码。


## 编码阶段提问示例1
```markdown
我正在基于以下文档进行日语学习APP的开发，现在我需要开始编码实现阶段：
- ：产品定义文档
- ：详细功能规格说明
- ：技术架构文档
- ：UI/UX设计规范
- ：本地API接口文档(无后端架构)

当前任务：创建RealmManager和基础数据模型
参考文档：的数据层设计和的数据层接口

请根据以下要求实现代码：

1. 遵循技术架构文档中的数据层设计
2. 实现Realm数据模型和RealmManager基础类
3. 代码需符合中定义的DictionaryRepositoryProtocol接口
4. 使用Swift语言，支持iOS 14.0及以上版本
5. 实现离线优先策略

请创建以下文件：

1. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Models/DictModels.swift：
   - 实现词典相关的Realm数据模型
   - 包括DictEntry、Definition、Example等模型
   - 参考中的数据模型设计

2. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/RealmManager.swift：
   - 实现RealmManager基础类
   - 提供Realm实例管理
   - 实现数据库初始化和配置

3. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/DictionaryRepository.swift：
   - 实现DictionaryRepositoryProtocol接口
   - 提供词典查询相关功能
   - 实现离线词库管理

完成上述文件后，请说明：
1. 代码如何满足中的数据层设计要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能
```

Q:
下一步要实现的功能是：

收藏功能实现 ：
- 创建收藏夹和收藏项的数据模型
- 实现FavoriteRepositoryProtocol接口
- 提供收藏管理相关功能

参考以上示例改写为`收藏功能实现`的具体要求

A:
# 收藏功能实现需求

我将为您提供实现收藏功能的结构化表达，以便AI能准确理解并遵循现有文档进行开发。

```
我正在基于已有文档进行日语学习APP的开发，现在需要实现收藏功能相关代码。

当前任务：实现收藏功能的数据层
参考文档：tec_architecture.md的数据模型设计和api_v1.md的FavoriteRepositoryProtocol接口

请根据以下要求实现代码：

1. 遵循技术架构文档中的数据层设计
2. 实现收藏夹和收藏项的Realm数据模型
3. 实现FavoriteRepositoryProtocol接口
4. 使用Swift语言，支持iOS 14.0及以上版本
5. 实现离线优先策略，支持后续云同步

请创建以下文件：

1. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Models/FavoriteModels.swift：
   - 实现收藏相关的Realm数据模型
   - 包括Folder、FavoriteItem等模型
   - 参考api_v1.md和tec_architecture.md中的数据模型设计

2. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/FavoriteRepository.swift：
   - 实现FavoriteRepositoryProtocol接口
   - 提供收藏夹管理功能（创建、更新、删除）
   - 提供收藏项管理功能（添加、更新、删除）
   - 实现收藏状态查询功能
   - 使用RealmManager进行数据操作

完成上述文件后，请说明：
1. 代码如何满足tec_architecture.md中的数据层设计要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能
```

这个结构化表达包含了：
1. 明确的开发上下文和当前任务
2. 参考的关键文档
3. 具体的实现要求
4. 需要创建的文件及其功能
5. 验收标准

通过这种方式，AI将能够更准确地理解您的需求，并基于现有文档生成符合要求的收藏功能相关代码。


Q:
下一步要实现的功能是：

用户认证模块 ：
   - 实现Sign in with Apple功能
   - 创建用户数据模型
   - 实现用户设置存储功能

参考以上示例改写为`用户认证模块`的具体要求

A:
# 用户认证模块实现需求
我将为您提供实现用户认证模块的结构化表达，以便AI能准确理解并遵循现有文档进行开发。

```plaintext
我正在基于已有文档进行日语学习APP的开发，现在需要实现用户认证模块相关代码。

当前任务：实现用户认证模块的数据层
参考文档：tec_architecture.md的用户认证设计和api_v1.md的UserAuthRepositoryProtocol接口

请根据以下要求实现代码：

1. 遵循技术架构文档中的数据层设计
2. 实现用户和用户设置的Realm数据模型
3. 实现UserAuthRepositoryProtocol接口
4. 集成Sign in with Apple功能
5. 使用Swift语言，支持iOS 14.0及以上版本
6. 实现用户数据的本地存储，为后续云同步做准备

请创建以下文件：

1. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Models/UserModels.swift：
   - 实现用户相关的Realm数据模型
   - 包括User、UserSettings等模型
   - 参考api_v1.md和tec_architecture.md中的数据模型设计

2. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/UserAuthRepository.swift：
   - 实现UserAuthRepositoryProtocol接口
   - 提供Sign in with Apple功能
   - 提供用户信息管理功能
   - 提供用户设置存储功能
   - 使用RealmManager进行数据操作

3. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Services/AppleAuthService.swift：
   - 实现与Apple认证服务的交互
   - 处理认证回调和令牌验证
   - 提供用户标识符和基本信息获取

完成上述文件后，请说明：
1. 代码如何满足tec_architecture.md中的数据层设计要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能
 ``
```

这个结构化表达包含了：

1. 明确的开发上下文和当前任务
2. 参考的关键文档
3. 具体的实现要求
4. 需要创建的文件及其功能
5. 验收标准
通过这种方式，AI将能够更准确地理解您的需求，并基于现有文档生成符合要求的用户认证模块相关代码。








# 改版后的代码实现提问

我正在基于以下文档进行日语学习APP的开发：
- ：开发过程必要文档清单
- ：产品定义文档
- ：技术架构文档
- ：核心功能文档
- ：详细功能规格说明
- ：UI/UX设计规范
- ：API接口文档

现在我需要开始编码实现阶段，技术实现路径参考从数据层到业务层再到表现层，模块依赖参考从SwiftUI组件到UI模块；从业务模型对象到业务逻辑模块；从Realm到数据访问模块等

当前任务：实现词典查询模块的数据层
参考文档：的模块设计，的词典数据模型设计，的RealmManager接口设计DictionaryRepositoryProtocol

请根据以下要求实现代码：
1. 遵循技术架构文档中的MVVM+Clean Architecture架构
2. 实现词典查询模块的数据层代码
3. 代码需符合中定义的接口规范
4. 使用Swift语言，支持iOS 14.0及以上版本
5. 所有用到的模型统一存放在下的Models.swift文件中
6. 每次定义新的数据模型或者枚举类型之前都必须先检查Models.swift中是否有名称和功能相同的数据模型定义，如果有则直接使用，如果存在名称相同但功能不同的则换个名称定义，避免重复定义数据模型

请完成以下任务：
   - 实现词典相关的Realm数据模型
   - 包括DictEntry、Definition、Example等模型
   - 严格按照和定义好的数据模型设计

   - 创建Classes/Data/Repositories/RealmManager.swift：
   - 实现RealmManager基础类
   - 提供Realm实例管理
   - 实现数据库初始化和配置

   - 创建Classes/Data/Repositories/DictionaryRepository.swift：
   - 严格按照实现DictionaryRepositoryProtocol接口
   - 提供词典查询相关功能
   - 实现离线词库管理

完成上述文件后，请说明：
1. 代码如何满足中的数据层设计要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能


# 云同步数据层实现需求
我正在基于已有文档进行日语学习APP的开发，现在需要实现CloudKit云同步相关代码。

当前任务：实现CloudKit云同步的数据层
参考文档：tec_architecture.md的云同步设计和api_v1.md的SyncRepositoryProtocol接口

请根据以下要求实现代码：

1. 遵循技术架构文档中的数据层设计
2. 实现CloudKit同步管理器
3. 实现SyncRepositoryProtocol接口
4. 提供数据同步和冲突解决策略
5. 实现增量同步功能
6. 使用Swift语言，支持iOS 14.0及以上版本
7. 确保离线优先策略，保证在无网络环境下应用仍能正常使用

请创建以下文件：

1. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Models/SyncModels.swift：
   - 实现同步相关的数据模型
   - 包括SyncStatus、SyncOperation、SyncProgress等模型
   - 参考api_v1.md中的同步相关数据模型设计

2. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Services/CloudKitService.swift：
   - 实现与CloudKit的底层交互
   - 提供记录的增删改查功能
   - 处理CloudKit错误和权限问题
   - 实现数据转换（Realm对象与CloudKit记录之间的转换）

3. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Repositories/SyncRepository.swift：
   - 实现SyncRepositoryProtocol接口
   - 提供同步状态查询功能
   - 实现增量同步策略
   - 提供冲突检测和解决机制
   - 使用CloudKitService进行云端数据操作

4. /Users/modi/Documents/Modi/ai_code/aicode-ios/JapaneseApp/Data/Utils/SyncConflictResolver.swift：
   - 实现同步冲突解决策略
   - 提供基于时间戳的冲突检测
   - 实现自动合并和手动选择机制
   - 处理各种冲突场景

完成上述文件后，请说明：
1. 代码如何满足tec_architecture.md中的数据同步策略要求
2. 实现了哪些核心功能
3. 下一步应该实现什么功能