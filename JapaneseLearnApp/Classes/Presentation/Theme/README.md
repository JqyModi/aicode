# 日语学习应用样式指南

## 简介

为了提高代码的可维护性和UI的一致性，我们创建了统一的样式管理系统`AppTheme`。该系统类似于CSS，集中管理应用中使用的颜色、字体、间距等UI样式元素。

## 使用方法

### 1. 导入AppTheme

在需要使用样式的Swift文件中导入：

```swift
import Foundation // 确保基础类型可用
```

### 2. 使用样式元素

#### 颜色

```swift
// 旧方式
Color("Primary")
Color("Primary").opacity(0.7)
Color(UIColor.secondarySystemBackground)
Color.gray

// 新方式
AppTheme.Colors.primary
AppTheme.Colors.primaryLight
AppTheme.Colors.secondaryBackground
AppTheme.Colors.secondaryText
```

#### 字体

```swift
// 旧方式
.font(.title2)
.font(.system(size: 16))
.font(.caption)

// 新方式
.font(AppTheme.Fonts.title2)
.font(AppTheme.Fonts.system(size: 16))
.font(AppTheme.Fonts.caption)
```

#### 字重

```swift
// 旧方式
.fontWeight(.medium)
.fontWeight(.bold)

// 新方式
.fontWeight(AppTheme.FontWeights.medium)
.fontWeight(AppTheme.FontWeights.bold)
```

#### 间距

```swift
// 旧方式
.padding()
.padding(.horizontal, 15)
.padding(.vertical, 8)

// 新方式
.padding(AppTheme.Spacing.cardPadding)
.padding(.horizontal, AppTheme.Spacing.medium)
.padding(.vertical, AppTheme.Spacing.small)
```

#### 圆角

```swift
// 旧方式
RoundedRectangle(cornerRadius: 20)
RoundedRectangle(cornerRadius: 15)

// 新方式
RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
```

#### 阴影

```swift
// 旧方式
.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
.shadow(color: Color("Primary").opacity(0.3), radius: 10, x: 0, y: 5)

// 新方式
.shadow(color: AppTheme.Shadows.medium.color, radius: AppTheme.Shadows.medium.radius, x: AppTheme.Shadows.medium.x, y: AppTheme.Shadows.medium.y)
.shadow(color: AppTheme.Shadows.large.color, radius: AppTheme.Shadows.large.radius, x: AppTheme.Shadows.large.x, y: AppTheme.Shadows.large.y)
```

### 3. 使用扩展方法

AppTheme提供了一些便捷的View扩展方法，可以更简洁地应用常用样式：

```swift
// 卡片样式
.cardStyle()

// 渐变卡片样式
.gradientCardStyle(animate: animateGradient)

// 胶囊按钮样式
.capsuleButtonStyle()

// 圆形图标按钮样式
.circleIconButtonStyle()
```

## 样式系统结构

- **Colors**: 颜色定义
- **Fonts**: 字体定义
- **FontWeights**: 字重定义
- **Spacing**: 间距定义
- **CornerRadius**: 圆角定义
- **Shadows**: 阴影定义
- **Animations**: 动画定义
- **Gradients**: 渐变定义
- **Borders**: 边框定义
- **Sizes**: 尺寸定义

## 迁移指南

1. 识别现有UI代码中的样式元素（颜色、字体、间距等）
2. 查找AppTheme中对应的样式定义
3. 替换为AppTheme中的样式
4. 如果需要的样式在AppTheme中不存在，可以在AppTheme中添加新的样式定义

## 最佳实践

- 始终使用AppTheme中定义的样式，避免硬编码样式值
- 如果需要新的样式，先检查是否可以通过组合现有样式实现
- 如果确实需要新的样式，将其添加到AppTheme中，而不是在视图代码中定义
- 使用View扩展方法应用常用样式组合，提高代码可读性