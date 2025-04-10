# Base Rules
- DDD_V3.md：开发过程必要文档清单
- product_define.md：产品定义文档
- tec_architecture.md：技术架构文档
- feature_list.md：核心功能文档
- detailed_design.md：详细功能规格说明
- uiux_v2.md：UI/UX设计规范
- api_v1.md：API接口文档

# Must Rules
- 所有数据模型统一存放在 DataModels.swift 中
- 所有视图模型统一存放在 ViewModels.swift 中
- 所有新定义类型之前都要检查 DataModels.swift 和 ViewModels.swift 中是否已存在相同类型，避免重复定义
- 每次生成代码都要确保代码完整性，不能存在编译错误
- 代码用到的技术栈优先使用 dev_tools.md 中推荐的技术栈
- 遵循技术架构文档中的MVVM+Clean Architecture架构
- 使用Swift语言，支持iOS 14.0及以上版本

tec_architecture.md 中对项目的技术架构设计给出了详细方案，技术实现路径从数据层到业务层再到表现层；模块依赖：从SwiftUI组件到UI模块、从业务模型对象到业务逻辑模块、从Realm到数据访问模块等；
Classes 文件夹中目前已经实现了词典模块、收藏模块、用户服务模块等数据层和业务层代码，表现层已经实现了各个模块的ViewModel，现在开始实现表现层SwiftUI视图代码。