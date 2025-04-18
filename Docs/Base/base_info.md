## 基本情况：
- 项目目标与范围：
    - 项目目标：开发一款类似`MOJi辞书`的日语学习APP
    - 功能需求：结合部分数据和主观认为功能主要包含查词、单词详情展示、日语文章阅读（可以结合市场分析讨论）
    - 用户群体：日语学习者
- 现有资源与技术：
    - 团队规模：我自己（iOS独立开发）
    - 技术栈和工具：参考 dev_tools.md
    - 技术限制和偏好：我是iOS开发者，有成熟iOS移动端项目开发经验
- 时间与进度
    - 目前属于项目规划阶段，先确定项目的功能清单/用户旅程图/PRD文档等


- 已准备资源
    - 核心词库：realm数据库
    - 发音功能：AVSpeechSynthesizer/Siri
    - 离线功能支持：本地realm查询展示




- 数据同步方案
    ## 推荐方案：CloudKit
优势：

- 苹果官方提供，与iOS生态深度集成
- 免费额度足够小型应用使用（每天5GB传输，每月10GB存储）
- 不需要自建服务器
- 用户使用Apple ID登录，无需额外的账号系统
- 支持私有数据库和公共数据库
实现难度： 中等

成本： 免费（在基本使用范围内）

示例用法：

```swift
// 基本的CloudKit存储示例
let container = CKContainer.default()
let privateDB = container.privateCloudDatabase

// 保存单词收藏记录
let record = CKRecord(recordType: "SavedWord")
record["word"] = "こんにちは" as CKRecordValue
record["meaning"] = "你好" as CKRecordValue
record["timestamp"] = Date() as CKRecordValue

privateDB.save(record) { (record, error) in
    if let error = error {
        print("Error saving to CloudKit: \(error.localizedDescription)")
    } else {
        print("Successfully saved to CloudKit")
    }
}
```
