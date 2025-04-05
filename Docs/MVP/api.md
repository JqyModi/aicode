# 日语学习APP API接口文档
基于MVP阶段的基础功能需求，我为日语学习APP设计了以下API接口文档。由于采用了离线优先策略，本文档主要关注本地数据访问接口和云同步接口。

## 1. 接口概述
### 1.1 接口分类
本API接口文档分为以下几个主要部分：

1. 词典查询接口
2. 收藏管理接口
3. 用户认证接口
4. 云同步接口
### 1.2 通用规范
- 数据格式 ：所有接口采用JSON格式进行数据交换
- 错误处理 ：统一的错误响应结构
- 认证方式 ：基于Apple ID的认证机制
- 版本控制 ：接口版本在路径中体现（v1）
## 2. 词典查询接口
### 2.1 查询单词 请求
```plaintext
GET /api/v1/dictionary/search
 ```

参数 ：
 参数名 类型 必填 描述 
 query|String|是|查询关键词 
 type|String|否|查询类型：word(单词)、reading(读音)、meaning(释义)，默认为auto 
 limit|Integer|否|返回结果数量限制，默认20，最大50 
 offset|Integer|否|分页偏移量，默认0 
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 10,
    "items": [
      {
        "id": "jp_12345",
        "word": "食べる",
        "reading": "たべる",
        "partOfSpeech": "动词",
        "definitions": [
          {
            "meaning": "吃，食用",
            "notes": "自动词"
          }
        ],
        "examples": [
          {
            "sentence": "朝ごはんを食べる",
            "translation": "吃早饭"
          }
        ]
      }
    ]
  }
}
 ```

### 2.2 获取单词详情 请求
```plaintext
GET /api/v1/dictionary/word/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|单词ID
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "jp_12345",
    "word": "食べる",
    "reading": "たべる",
    "partOfSpeech": "动词",
    "definitions": [
      {
        "meaning": "吃，食用",
        "notes": "自动词"
      }
    ],
    "examples": [
      {
        "sentence": "朝ごはんを食べる",
        "translation": "吃早饭"
      },
      {
        "sentence": "お寿司を食べる",
        "translation": "吃寿司"
      }
    ],
    "relatedWords": [
      {
        "id": "jp_12346",
        "word": "食べ物",
        "reading": "たべもの",
        "meaning": "食物"
      }
    ]
  }
}
 ```

### 2.3 获取单词发音 请求
```plaintext
GET /api/v1/dictionary/pronunciation/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|单词ID 
 speed|Float|否|语速，范围0.5-1.5，默认1.0 
 
响应
```plaintext
二进制音频数据 (audio/mpeg)
 ```

响应头 ：

```plaintext
Content-Type: audio/mpeg
Content-Disposition: attachment; filename="pronunciation.mp3"
 ```

### 2.4 获取搜索历史 请求
```plaintext
GET /api/v1/dictionary/history
 ```

参数 ：
 参数名 类型 必填 描述 
 limit|Integer|否|返回结果数量限制，默认20 
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [
      {
        "id": "jp_12345",
        "word": "食べる",
        "reading": "たべる",
        "timestamp": "2023-05-15T10:30:45Z"
      }
    ]
  }
}
 ```

## 3. 收藏管理接口
### 3.1 获取收藏夹列表 请求
```plaintext
GET /api/v1/favorites/folders
 ```

参数 ：无

 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "folders": [
      {
        "id": "folder_001",
        "name": "我的收藏",
        "createdAt": "2023-05-10T08:15:30Z",
        "itemCount": 25,
        "syncStatus": 1
      },
      {
        "id": "folder_002",
        "name": "N3词汇",
        "createdAt": "2023-05-12T14:20:10Z",
        "itemCount": 42,
        "syncStatus": 1
      }
    ]
  }
}
 ```

### 3.2 创建收藏夹 请求
```plaintext
POST /api/v1/favorites/folders
 ```

请求体 ：
```json
{
  "name": "旅行词汇"
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "folder_003",
    "name": "旅行词汇",
    "createdAt": "2023-05-16T09:45:22Z",
    "itemCount": 0,
    "syncStatus": 0
  }
}
 ```

### 3.3 修改收藏夹 请求
```plaintext
PUT /api/v1/favorites/folders/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|收藏夹ID

请求体 ：
```json
{
  "name": "旅行必备词汇"
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "folder_003",
    "name": "旅行必备词汇",
    "updatedAt": "2023-05-16T10:20:15Z",
    "syncStatus": 0
  }
}
 ```

### 3.4 删除收藏夹 请求
```plaintext
DELETE /api/v1/favorites/folders/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|收藏夹ID
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "deleted": true
  }
}
 ```

### 3.5 获取收藏夹内容 请求
```plaintext
GET /api/v1/favorites/folders/{id}/items
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|收藏夹ID
 limit|Integer|否|返回结果数量限制，默认20  
 offset|Integer|否|分页偏移量，默认0
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 42,
    "items": [
      {
        "id": "fav_12345",
        "wordId": "jp_12345",
        "word": "食べる",
        "reading": "たべる",
        "meaning": "吃，食用",
        "note": "常用动词，记住变形",
        "addedAt": "2023-05-14T15:30:20Z",
        "syncStatus": 1
      }
    ]
  }
}
 ```

### 3.6 添加收藏 请求
```plaintext
POST /api/v1/favorites/items
 ```

请求体 ：

```json
{
  "wordId": "jp_12345",
  "folderId": "folder_001",
  "note": "常用动词，记住变形"
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "fav_12345",
    "wordId": "jp_12345",
    "word": "食べる",
    "reading": "たべる",
    "meaning": "吃，食用",
    "note": "常用动词，记住变形",
    "addedAt": "2023-05-16T11:25:30Z",
    "syncStatus": 0
  }
}
 ```

### 3.7 更新收藏笔记 请求
```plaintext
PUT /api/v1/favorites/items/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|收藏项ID
 
请求体 ：

```json
{
  "note": "常用动词，记住て形变形：食べて"
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "fav_12345",
    "note": "常用动词，记住て形变形：食べて",
    "updatedAt": "2023-05-16T11:40:15Z",
    "syncStatus": 0
  }
}
 ```

### 3.8 删除收藏 请求
```plaintext
DELETE /api/v1/favorites/items/{id}
 ```

参数 ：
 参数名 类型 必填 描述 
 id|String|是|收藏项ID
 
响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "deleted": true
  }
}
 ```

## 4. 用户认证接口
### 4.1 Apple ID登录 请求
```plaintext
POST /api/v1/auth/apple
 ```

请求体 ：

```json
{
  "identityToken": "eyJraWQiOiI4NkQ4OEtmIiwiYWxnIjoiUlMyNTYifQ...",
  "authorizationCode": "c8b5e...",
  "fullName": {
    "givenName": "John",
    "familyName": "Appleseed"
  },
  "email": "john.appleseed@privaterelay.appleid.com",
  "userIdentifier": "001231.2a3b4c5d6e7f8g9h0j..."
}
 ```

 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "userId": "user_12345",
    "nickname": "John",
    "isNewUser": false,
    "lastSyncTime": "2023-05-15T18:30:45Z"
  }
}
 ```

### 4.2 获取用户信息 请求
```plaintext
GET /api/v1/user/profile
 ```

参数 ：无
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "userId": "user_12345",
    "nickname": "John",
    "settings": {
      "darkMode": false,
      "fontSize": 2,
      "autoSync": true
    },
    "lastSyncTime": "2023-05-15T18:30:45Z",
    "favoriteCount": 67,
    "folderCount": 3
  }
}
 ```

### 4.3 更新用户设置 请求
```plaintext
PUT /api/v1/user/settings
 ```

请求体 ：

```json
{
  "darkMode": true,
  "fontSize": 3,
  "autoSync": true
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "settings": {
      "darkMode": true,
      "fontSize": 3,
      "autoSync": true
    },
    "updatedAt": "2023-05-16T14:20:30Z",
    "syncStatus": 0
  }
}
 ```

### 4.4 登出 请求
```plaintext
POST /api/v1/auth/logout
 ```

请求体 ：无
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "loggedOut": true
  }
}
 ```

## 5. 云同步接口
### 5.1 获取同步状态 请求
```plaintext
GET /api/v1/sync/status
 ```

参数 ：无
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "lastSyncTime": "2023-05-15T18:30:45Z",
    "pendingChanges": 5,
    "syncStatus": "ready",
    "availableOffline": true
  }
}
 ```

### 5.2 触发同步 请求
```plaintext
POST /api/v1/sync
 ```

请求体 ：

```json
{
  "syncType": "full"  // 可选值: "full", "favorites", "settings"
}
 ```
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "syncId": "sync_12345",
    "startedAt": "2023-05-16T15:10:25Z",
    "status": "in_progress",
    "estimatedTimeRemaining": 5
  }
}
 ```

### 5.3 获取同步进度 请求
```plaintext
GET /api/v1/sync/{syncId}
 ```

参数 ：
 参数名 类型 必填 描述 
 syncId|String|是|同步任务ID
 
 响应
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "syncId": "sync_12345",
    "progress": 75,
    "status": "in_progress",
    "itemsSynced": 15,
    "totalItems": 20,
    "estimatedTimeRemaining": 2
  }
}
 ```

## 6. 错误处理
### 6.1 错误响应格式
所有API错误响应遵循以下统一格式：

```json
{
  "code": 400,
  "message": "Bad Request",
  "error": {
    "type": "ValidationError",
    "details": "Invalid parameter: query cannot be empty"
  }
}
 ```

### 6.2 错误码列表 
错误码 描述 可能原因 
400|Bad Request|请求参数错误或格式不正确 
401|Unauthorized|未登录或认证失败 
403|Forbidden|权限不足
404|Not Found|请求的资源不存在
409|Conflict|资源冲突，如创建同名收藏夹 
429|Too Many Requests|请求频率超限 
500|Internal Server Error|服务器内部错误 
503|Service Unavailable|服务暂时不可用，如同步服务维护

### 6.3 特定错误类型 
错误类型 描述 示例 
ValidationError|输入验证错误|参数格式错误、必填项缺失 
AuthenticationError|认证相关错误|登录失败、Token过期 
SyncError|同步相关错误|同步冲突、网络中断 
ResourceError|资源操作错误|删除默认收藏夹、超出限制 
StorageError|存储相关错误|存储空间不足、数据库错误

## 7. 认证机制
### 7.1 认证流程
1. 用户通过Apple ID登录
2. 服务器验证Apple提供的身份令牌
3. 生成应用内会话标识
4. 后续请求通过Authorization头部传递会话标识
### 7.2 请求认证
所有需要认证的API请求都应在HTTP头部包含以下信息：

```plaintext
Authorization: Bearer {session_token}
 ```

### 7.3 认证状态码
- 401：未认证或认证失败
- 403：已认证但权限不足

## 8. 数据模型关系
### 8.1 核心数据实体
```plaintext
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    User     │───┐   │   Folder    │       │  DictEntry  │
├─────────────┤   │   ├─────────────┤       ├─────────────┤
│ id          │   │   │ id          │       │ id          │
│ nickname    │   └──▶│ userId      │       │ word        │
│ settings    │       │ name        │       │ reading     │
│ lastSyncTime│       │ createdAt   │       │ partOfSpeech│
└─────────────┘       │ syncStatus  │       │ definitions │
                      └──────┬──────┘       │ examples    │
                             │              └──────┬──────┘
                             │                     │
                      ┌──────▼──────┐       ┌──────▼──────┐
                      │ FavoriteItem│◀──────│  Definition │
                      ├─────────────┤       ├─────────────┤
                      │ id          │       │ meaning     │
                      │ folderId    │       │ notes       │
                      │ wordId      │       └─────────────┘
                      │ word        │       ┌─────────────┐
                      │ reading     │       │   Example   │
                      │ meaning     │◀──────┤             │
                      │ note        │       │ sentence    │
                      │ addedAt     │       │ translation │
                      │ syncStatus  │       └─────────────┘
                      └─────────────┘
 ```

### 8.2 数据同步模型
```plaintext
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  LocalData  │       │  SyncQueue  │       │  CloudData  │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ 本地数据库    │──────▶│ 待同步队列   │──────▶│ iCloud数据  │
│ Realm存储    │◀──────│ 操作类型     │◀──────│ CloudKit   │
└─────────────┘       │ 时间戳       │       └─────────────┘
                      │ 冲突策略     │
                      └─────────────┘
 ```

## 9. 实现注意事项
### 9.1 离线优先策略
- 所有API首先操作本地数据库
- 本地操作成功后，将变更加入同步队列
- 同步队列在网络可用时异步处理
- 用户界面始终反映本地数据状态
### 9.2 性能考量
- 查询接口应支持分页加载
- 大型响应（如词典查询结果）应实现增量加载
- 发音数据应实现缓存机制
- 同步操作应在后台线程执行，不阻塞UI
### 9.3 安全考量
- 敏感数据（用户信息、笔记内容）在传输和存储时加密
- 本地数据库使用Realm加密功能
- 云同步利用CloudKit的内置安全机制
- 定期清理过期的认证会话
## 10. MVP阶段API优先级
### 10.1 核心API（优先级：高）
- 词典查询接口（2.1, 2.2）
- 单词发音接口（2.3）
- 基础收藏功能（3.1, 3.6, 3.8）
- Apple ID登录（4.1）
### 10.2 重要API（优先级：中）
- 收藏夹管理（3.2, 3.3, 3.4, 3.5）
- 收藏笔记更新（3.7）
- 用户设置（4.3）
- 基础同步功能（5.1, 5.2）
### 10.3 增强API（优先级：低）
- 搜索历史（2.4）
- 同步进度监控（5.3）
- 高级用户信息（4.2）
通过以上API接口设计，我们为日语学习APP提供了完整的数据访问层，支持MVP阶段的核心功能实现，并为后续功能扩展预留了接口空间。