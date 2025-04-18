# 数据模型列表

本文档记录了项目中所有的数据模型，按照数据层(Data)、业务层(Domain)和表现层(Presentation)进行分类。每个模型都有明确的用途说明，以避免重复定义和混用不同层级的模型。

## 命名规范

为了清晰区分不同层级的模型，我们采用以下命名规范：

- **数据层模型**：使用`DB`前缀，如`DBWord`
- **业务层模型**：使用`Domain`后缀，如`DictEntryDomain`
- **表现层模型**：使用`UI`后缀，如`WordDetailsUI`

当需要在不同层级之间转换模型时，应提供相应的转换方法，如：
```swift
func toDomain() -> DictEntryDomain
func toUI() -> WordDetailsUI
```

## 数据层模型 (Data Layer)

### 词典模块

#### DBWord
- **用途**：数据库中的词条原始数据
- **文件位置**：`Data/Models/word-core-model.swift`
- **主要属性**：objectId, spell, pron, details, subdetails, examples等

#### DBWordDetail
- **用途**：词条详情数据
- **文件位置**：`Data/Models/word-core-model.swift`
- **主要属性**：objectId, wordId, partOfSpeech

#### DBSubdetail
- **用途**：词条释义数据
- **文件位置**：`Data/Models/word-core-model.swift`
- **主要属性**：objectId, title, wordId, lang, relaId

#### DBExample
- **用途**：词条例句数据
- **文件位置**：`Data/Models/word-core-model.swift`
- **主要属性**：objectId, wordId, title, lang

#### DBDictionaryVersion
- **用途**：词典版本信息
- **文件位置**：待创建
- **主要属性**：id, version, updateDate, wordCount

#### DBSearchHistoryItem
- **用途**：搜索历史记录
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, searchDate

### 收藏模块

#### DBFolder
- **用途**：收藏夹数据
- **文件位置**：待创建
- **主要属性**：id, name, createdAt, items, syncStatus, lastModified, isDefault

#### DBFavoriteItem
- **用途**：收藏项数据
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, meaning, note, addedAt, syncStatus, lastModified

#### DBFavoriteCategory
- **用途**：收藏分类数据
- **文件位置**：待创建
- **主要属性**：id, name, iconName, count, createdAt, updatedAt, syncStatus

### 用户模块

#### DBUser
- **用途**：用户数据
- **文件位置**：待创建
- **主要属性**：id, nickname, email, settings, lastSyncTime, createdAt, syncStatus

#### DBUserSettings
- **用途**：用户设置数据
- **文件位置**：待创建
- **主要属性**：darkMode, fontSize, autoSync, notificationsEnabled, syncFrequency

#### DBAuthToken
- **用途**：认证令牌数据
- **文件位置**：待创建
- **主要属性**：id, identityToken, authorizationCode, expiresAt, refreshToken

### 同步模块

#### DBSyncStatus
- **用途**：同步状态数据
- **文件位置**：待创建
- **主要属性**：id, lastSyncTime, cloudKitAvailable, autoSyncEnabled, serverChangeTokenData

#### DBSyncOperation
- **用途**：同步操作数据
- **文件位置**：待创建
- **主要属性**：id, type, status, startTime, endTime, progress, itemsProcessed, totalItems, errorMessage

#### DBSyncRecord
- **用途**：同步记录数据
- **文件位置**：待创建
- **主要属性**：id, recordType, lastSynced, cloudKitRecordID, cloudKitRecordChangeTag, deleted

#### DBSyncConflict
- **用途**：同步冲突数据
- **文件位置**：待创建
- **主要属性**：id, recordId, recordType, localData, remoteData, localModified, remoteModified, resolved, resolutionType

## 业务层模型 (Domain Layer)

### 词典模块

#### DictEntryDomain
- **用途**：词条业务模型
- **文件位置**：待创建
- **主要属性**：id, word, reading, partOfSpeech, definitions, examples, jlptLevel, commonWord
- **转换方法**：
  - `init(from dbWord: DBWord)`
  - `func toUI() -> WordDetailsUI`

#### DefinitionDomain
- **用途**：释义业务模型
- **文件位置**：待创建
- **主要属性**：meaning, notes

#### ExampleDomain
- **用途**：例句业务模型
- **文件位置**：待创建
- **主要属性**：sentence, translation

#### SearchResultDomain
- **用途**：搜索结果业务模型
- **文件位置**：待创建
- **主要属性**：query, totalCount, items

#### WordListItemDomain
- **用途**：词条列表项业务模型
- **文件位置**：待创建
- **主要属性**：id, word, reading, partOfSpeech, briefMeaning

#### SearchHistoryItemDomain
- **用途**：搜索历史业务模型
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, searchDate
- **转换方法**：
  - `init(from dbItem: DBSearchHistoryItem)`
  - `func toData() -> DBSearchHistoryItem`
  - `func toUI() -> SearchHistoryItemUI`

### 收藏模块

#### FolderDomain
- **用途**：收藏夹业务模型
- **文件位置**：待创建
- **主要属性**：id, name, createdAt, items, syncStatus, lastModified, isDefault
- **转换方法**：
  - `init(from dbFolder: DBFolder)`
  - `func toData() -> DBFolder`
  - `func toUI() -> FolderUI`

#### FavoriteItemDomain
- **用途**：收藏项业务模型
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, meaning, note, addedAt, syncStatus, lastModified
- **转换方法**：
  - `init(from dbItem: DBFavoriteItem)`
  - `func toData() -> DBFavoriteItem`
  - `func toUI() -> FavoriteItemUI`

#### FolderSummaryDomain
- **用途**：收藏夹摘要业务模型
- **文件位置**：待创建
- **主要属性**：id, name, createdAt, itemCount, syncStatus

### 用户模块

#### UserProfileDomain
- **用途**：用户资料业务模型
- **文件位置**：待创建
- **主要属性**：userId, nickname, settings, lastSyncTime, favoriteCount, folderCount
- **转换方法**：
  - `init(from dbUser: DBUser)`
  - `func toData() -> DBUser`
  - `func toUI() -> UserProfileUI`

#### UserPreferencesDomain
- **用途**：用户偏好业务模型
- **文件位置**：待创建
- **主要属性**：darkMode, fontSize, autoSync

## 表现层模型 (Presentation Layer)

### 词典模块

#### WordDetailsUI
- **用途**：词条详情UI模型
- **文件位置**：待创建
- **主要属性**：id, word, reading, partOfSpeech, definitions, examples, tags, isFavorited, relatedWords
- **转换方法**：
  - `init(from domain: DictEntryDomain, isFavorited: Bool, relatedWords: [WordListItemUI])`

#### WordListItemUI
- **用途**：词条列表项UI模型
- **文件位置**：待创建
- **主要属性**：id, word, reading, partOfSpeech, briefMeaning
- **转换方法**：
  - `init(from domain: WordListItemDomain)`

#### SearchResultUI
- **用途**：搜索结果UI模型
- **文件位置**：待创建
- **主要属性**：query, totalCount, items
- **转换方法**：
  - `init(from domain: SearchResultDomain)`

#### SearchHistoryItemUI
- **用途**：搜索历史UI模型
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, searchDate
- **转换方法**：
  - `init(from domain: SearchHistoryItemDomain)`

### 收藏模块

#### FolderUI
- **用途**：收藏夹UI模型
- **文件位置**：待创建
- **主要属性**：id, name, createdAt, items, syncStatus, lastModified, isDefault
- **转换方法**：
  - `init(from domain: FolderDomain)`

#### FavoriteItemUI
- **用途**：收藏项UI模型
- **文件位置**：待创建
- **主要属性**：id, wordId, word, reading, meaning, note, addedAt, syncStatus
- **转换方法**：
  - `init(from domain: FavoriteItemDomain)`

#### FolderSummaryUI
- **用途**：收藏夹摘要UI模型
- **文件位置**：待创建
- **主要属性**：id, name, createdAt, itemCount, syncStatus
- **转换方法**：
  - `init(from domain: FolderSummaryDomain)`

### 用户模块

#### UserProfileUI
- **用途**：用户资料UI模型
- **文件位置**：待创建
- **主要属性**：userId, nickname, settings, lastSyncTime, favoriteCount, folderCount
- **转换方法**：
  - `init(from domain: UserProfileDomain)`

#### UserPreferencesUI
- **用途**：用户偏好UI模型
- **文件位置**：待创建
- **主要属性**：darkMode, fontSize, autoSync
- **转换方法**：
  - `init(from domain: UserPreferencesDomain)`