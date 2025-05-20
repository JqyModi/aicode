# 日语学习应用项目规则

## 1. 项目架构规范

### 1.1 整体架构

- 严格遵循MVVM + Clean Architecture架构
- 项目分为表现层(Presentation)、业务层(Domain)和数据层(Data)三层结构
- 各层职责明确分离，遵循单一职责原则
- 采用了"无后端"架构，主要依靠Realm本地数据库、CloudKit云同步和AppleAuth用户认证

### 1.2 目录结构

```
JapaneseLearnApp/
├── Classes/
│   ├── Data/            # 数据层
│   │   ├── Models/      # 数据模型
│   │   ├── Repositories/ # 数据仓库
│   │   └── DataSources/ # 数据源
│   ├── Domain/          # 业务层
│   │   ├── Entities/    # 业务实体
│   │   ├── UseCases/    # 用例
│   │   └── Services/    # 服务
│   └── Presentation/    # 表现层
│       ├── Views/       # UI视图
│       ├── ViewModels/  # 视图模型
│       └── Components/  # 可复用组件
└── Resources/           # 资源文件
```

## 2. 编码规范

### 2.1 文件组织

- 每个Swift文件只包含一个主要类型定义
- 扩展(Extension)可以放在单独的文件中，文件名格式为`类型名+功能.swift`
- 相关的类型应放在同一目录下

### 2.2 类型设计

- 优先使用结构体(struct)而非类(class)，除非需要引用语义或继承
- 使用协议(protocol)定义接口，提高代码可测试性
- 使用枚举(enum)表示有限集合的状态或类型
- 使用值类型(Value Types)作为数据模型

### 2.3 访问控制

- 默认使用`private`或`fileprivate`限制访问范围
- 只有需要在模块外访问的API才使用`public`
- 内部模块间共享的API使用`internal`(默认)

## 3. 数据层规范

### 3.1 数据模型

- 所有Realm模型必须继承`Object`类
- 模型属性使用`@Persisted`标记
- 主键使用`@Persisted(primaryKey: true)`标记

### 3.2 仓库模式

- 每个数据实体对应一个Repository接口
- Repository负责协调本地存储和远程数据源
- 所有Repository方法返回`AnyPublisher`或`Result`类型

### 3.3 数据同步

- 采用离线优先策略，本地操作优先
- 使用同步状态标记(已同步、待同步、同步失败)
- 实现冲突解决策略，默认以最新修改为准

## 4. 业务层规范

### 4.1 用例设计

- 每个业务功能对应一个UseCase
- UseCase只依赖Repository接口，不依赖具体实现
- 复杂业务逻辑在UseCase中实现，保持ViewModel简洁

### 4.2 服务设计

- 通用功能封装为Service
- Service之间保持低耦合
- 使用依赖注入方式获取Service

## 5. 表现层规范

### 5.1 SwiftUI视图

- 视图拆分为小的、可复用的组件
- 使用`@ObservedObject`或`@StateObject`绑定ViewModel
- 复杂视图使用`GeometryReader`适配不同屏幕尺寸

### 5.2 ViewModel设计

- ViewModel使用`ObservableObject`协议
- 状态使用`@Published`属性包装器
- ViewModel通过UseCase获取数据和执行业务逻辑

### 5.3 状态管理

- 使用单向数据流模式
- 状态变更通过Action触发
- UI只读取状态，不直接修改状态

## 6. 响应式编程规范

### 6.1 Combine使用

- 使用Combine处理异步操作和数据流
- 合理使用操作符组合和转换数据流
- 注意内存管理，使用`weak self`和`cancel()`防止内存泄漏

### 6.2 订阅管理

- 使用`AnyCancellable`数组存储订阅
- 在`deinit`中取消所有订阅
- 长生命周期的订阅考虑使用`sink(receiveValue:)`返回值

## 7. 本地存储规范

### 7.1 Realm使用

- 使用`RealmManager`单例管理Realm实例
- 在后台线程执行Realm写操作
- 使用`Results<T>`和`List<T>`代替数组

### 7.2 数据迁移

- 实现版本化的数据迁移策略
- 每次模型变更增加版本号
- 提供向前兼容的迁移方法

## 8. 云同步规范

### 8.1 CloudKit使用

- 使用`CKContainer.default()`获取默认容器
- 区分公共数据库和私有数据库用途
- 实现适当的错误处理和重试机制

### 8.2 同步策略

- 应用启动时检查并执行同步
- 网络状态变化时触发同步
- 提供手动同步选项
- 同步过程显示适当的UI指示器

## 9. 性能优化规范

### 9.1 启动优化

- 减少启动时加载的资源
- 使用懒加载延迟初始化
- 启动时只加载必要的数据

### 9.2 列表性能

- 使用`LazyVStack`和`LazyHStack`
- 实现高效的ID标识机制
- 避免在滚动时进行复杂计算

## 10. 测试规范

### 10.1 单元测试

- 使用XCTest框架
- 为Repository和UseCase编写测试
- 使用Mock对象隔离依赖

### 10.2 UI测试

- 为关键用户流程编写UI测试
- 使用可访问性标识符定位UI元素
- 测试不同设备和方向

## 11. 版本控制规范

### 11.1 分支策略

- 主分支：`main`
- 开发分支：`develop`
- 功能分支：`feature/功能名称`
- 修复分支：`bugfix/问题描述`
- 发布分支：`release/版本号`

### 11.2 提交规范

- 提交信息格式：`[类型] 简短描述`
- 类型包括：feat(新功能)、fix(修复)、docs(文档)、style(格式)、refactor(重构)、test(测试)、chore(构建/工具)
- 提交前进行代码审查

## 12. 文档规范

### 12.1 代码文档

- 使用Markdown格式编写文档
- 关键类和方法添加文档注释
- 复杂算法添加实现说明

### 12.2 项目文档

- 维护README.md说明项目结构和运行方式
- 记录重要设计决策和理由
- 更新API变更和版本历史