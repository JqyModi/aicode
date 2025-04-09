# Must Rules
- 所有数据模型统一存放在DataModels.swift中
- 所有视图模型统一存放在ViewModels.swift中
- 所有新定义类型之前都要检查DataModels.swift和ViewModels.swift中是否已存在相同类型，避免重复定义
- 每次生成代码都要确保代码完整性，不能存在编译错误
- 代码用到的技术栈优先使用#file:dev_tools.md中推荐的技术栈