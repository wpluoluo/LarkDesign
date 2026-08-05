# LarkDesign 鸿蒙端迁移指南

> 文档创建：2026-07-28
> 源项目：f:\LarkDesign\原型设计\（Vue 3 原型）
> 目标端：HarmonyOS ArkUI + ArkUI-X 跨端

## 一、已完成事项

### 1. 设计 Token 冻结 ✅
- 源文件：[shared/tokens/tokens.json](file:///f:/LarkDesign/shared/tokens/tokens.json)
- 包含 5 套主题（明亮/温暖暗色/专业暗黑/石板灰/暖纸阅读）的完整色板
- 间距/圆角/字号/高度等尺寸 Token
- 已同步到鸿蒙资源文件：
  - [entry/src/main/resources/base/element/color.json](file:///f:/LarkDesign/entry/src/main/resources/base/element/color.json)（浅色主题）
  - [entry/src/main/resources/dark/element/color.json](file:///f:/LarkDesign/entry/src/main/resources/dark/element/color.json)（暗色主题）
  - [entry/src/main/resources/base/element/float.json](file:///f:/LarkDesign/entry/src/main/resources/base/element/float.json)（尺寸 Token）

### 2. 组件清单与映射 ✅
- 源文件：[shared/docs/component-inventory.md](file:///f:/LarkDesign/shared/docs/component-inventory.md)
- 按 P0-P4 五级优先级梳理 26 个 Vue 组件
- 8 个 Store、11 个 Composable、6 个 Fusion DOM 模块
- 每个模块都标注了鸿蒙迁移方式

### 3. 交互流程规范 ✅
- 源文件：[shared/docs/interaction-spec.md](file:///f:/LarkDesign/shared/docs/interaction-spec.md)
- 覆盖画布交互、工具栏、Inspector、图层、Frame、键盘快捷键、右键菜单
- 包含 Vue→ArkUI 事件映射表

### 4. 鸿蒙工程脚手架 ✅
已创建以下骨架文件（路径：`entry/src/main/ets/`）：

#### 核心文件
- [tokens/DesignTokens.ets](file:///f:/LarkDesign/entry/src/main/ets/tokens/DesignTokens.ets) - Token 常量类
- [pages/Index.ets](file:///f:/LarkDesign/entry/src/main/ets/pages/Index.ets) - 主页面入口（替换 Hello World）

#### Stores
- [stores/ThemeStore.ets](file:///f:/LarkDesign/entry/src/main/ets/stores/ThemeStore.ets) - 主题管理
- [stores/DocumentStore.ets](file:///f:/LarkDesign/entry/src/main/ets/stores/DocumentStore.ets) - 文档状态

#### Components
- [components/SplashScreen.ets](file:///f:/LarkDesign/entry/src/main/ets/components/SplashScreen.ets) - 启动屏（4 种模式选择）
- [components/WorkspaceLayout.ets](file:///f:/LarkDesign/entry/src/main/ets/components/WorkspaceLayout.ets) - 工作区主布局
- [components/MenuBar.ets](file:///f:/LarkDesign/entry/src/main/ets/components/MenuBar.ets) - 菜单栏
- [components/ToolRail.ets](file:///f:/LarkDesign/entry/src/main/ets/components/ToolRail.ets) - 工具栏
- [components/ToolOptionsBar.ets](file:///f:/LarkDesign/entry/src/main/ets/components/ToolOptionsBar.ets) - 工具选项栏
- [components/StatusBar.ets](file:///f:/LarkDesign/entry/src/main/ets/components/StatusBar.ets) - 状态栏
- [components/PagesPanel.ets](file:///f:/LarkDesign/entry/src/main/ets/components/PagesPanel.ets) - Frame 面板
- [components/Inspector.ets](file:///f:/LarkDesign/entry/src/main/ets/components/Inspector.ets) - 属性面板
- [components/CanvasStage.ets](file:///f:/LarkDesign/entry/src/main/ets/components/CanvasStage.ets) - 画布舞台

### 5. 跨端共享类型 ✅
- [shared/types/scene.ts](file:///f:/LarkDesign/shared/types/scene.ts) - 核心类型定义

## 二、技术选型确认（冻结于 2026-08-05）

### 2.1 渲染架构冻结

| 层 | 技术 | 说明 |
|----|------|------|
| **UI 外壳** | ArkUI（ArkTS） | 窗口、面板、输入、选择框、Inspector、HistoryPanel、Minimap——所有非画布 UI |
| **内容渲染** | Skia（C++，经 NAPI 桥接） | 场景绘制、矢量路径、文本排布、位图合成、滤镜、导出渲染——唯一渲染引擎 |
| **NAPI 桥接** | 窄接口 DTO + 句柄 | 只暴露稳定数据结构与操作句柄，不暴露 Skia 类型给 ArkTS |
| **多端策略** | 保留多端 | 通过 ArkUI-X 支持 Android/iOS，桌面端通过共享 Fusion Core（C ABI）扩展 |
| **资源格式** | 鸿蒙原生资源 | color.json / loat.json / string.json |

### 2.2 依赖方向约束（强制）

`
UI (ArkTS) → Feature (ArkTS) → Domain (纯 TS/ArkTS) → Port (NAPI/系统 API)
                                                          ↓
                                                 C/C++ 引擎层 (Skia/lcms2/FreeType)
`

- ArkTS 层不得直接调用 Skia C API。
- NAPI 只暴露自有稳定结构 + 句柄，不暴露 Skia 类型。
- Fusion DOM 不保存 SkPath、SkBitmap 或任何原生类型。
- 依赖方向固定，禁止反向。
## 三、迁移路线图
## 三、C/C++ 依赖基线（按需引入，非一次性安装）

| 领域 | 首期依赖 | 后续可选 | 许可证 | 备注 |
|------|---------|---------|--------|------|
| 渲染 | **Skia** | — | BSD-3 | 唯一渲染引擎，图片编解码通过 Skia codec 解决 |
| 文本排版 | **FreeType** + **HarfBuzz** + **ICU** | — | FTL / MIT / Unicode | 通过 HarmonyOS NDK 系统库提供，非外包 |
| 色彩管理 | — | **LittleCMS 2** | MIT | 印前工作流需要时引入，首期用 Skia 原生 sRGB |
| PDF 导出 | — | **libHaru** | ZLIB | 首期通过 Skia 生成 PDF 代理，后期替换 |
| PDF 高保真导入 | — | **PDFium** | BSD-3 | 保留评估，体积大，首期不入 |
| EPS 导入 | — | **Ghostscript** | AGPL | 仅作为可选导入组件，不默认绑定 |
| 图像处理 | — | **OpenCV** | Apache-2.0 | 首期图像调整由 Skia + 自研节点图实现 |

**依赖引入原则**：
- 每个库在进入主干前需记录版本、许可证、目标 ABI、HarmonyOS 构建状态、测试覆盖和替代方案。
- 不一次性安装所有 C/C++ 库，按垂直切片逐个验证。
- 图片编解码优先使用 Skia codec，不重复引入 libpng / libjpeg-turbo / libwebp。

### 阶段一：静态 UI 复刻（P0-P1）✅ 骨架已就绪
- 已完成：Index、SplashScreen、WorkspaceLayout、MenuBar、ToolRail、ToolOptionsBar、StatusBar、PagesPanel、Inspector、CanvasStage
- 待完善：组件内部交互逻辑、图标资源、样式细节

### 阶段二：数据与状态层
- [ ] FusionDocumentStore（对应原型 fusionDocument.ts）
- [ ] LayerStore
- [ ] ToolStore
- [ ] ColorStore
- [ ] ToastStore

### 阶段三：Fusion DOM 核心算法（迁移到 shared/）
- [ ] shared/fusion/factory.ts（工厂函数）
- [ ] shared/fusion/ops.ts（文档操作）
- [ ] shared/fusion/serializer.ts（序列化）
- [ ] shared/algorithms/alignment.ts（对齐分布）
- [ ] shared/algorithms/hitTest.ts（命中检测）
- [ ] shared/algorithms/coordinate.ts（坐标转换）

### 阶段四：画布渲染引擎
- [ ] CanvasRenderer（ArkUI Canvas 渲染器）
- [ ] CanvasInteraction（交互引擎，替换 useCanvasInteraction）
- [ ] InfiniteCanvas（无限画布，替换 useInfiniteCanvas）
- [ ] FrameView 组件

### 阶段五：交互逻辑迁移
- [ ] 工具切换与形状绘制
- [ ] 选中/拖拽/resize/框选
- [ ] 双击编辑
- [ ] 复制粘贴剪切
- [ ] 撤销重做
- [ ] 键盘快捷键
- [ ] 右键菜单

### 阶段六：高级功能
- [ ] Inspector 完整双向绑定
- [ ] 颜色系统（ColorPicker 等）
- [ ] 历史记录面板
- [ ] 鸟瞰图
- [ ] 导出（PNG/JPG/SVG）
- [ ] 文档持久化

### 阶段七：ArkUI-X 跨端适配
- [ ] Android 平台适配
- [ ] iOS 平台适配
- [ ] 桌面端（Compose Multiplatform，可选）

## 四、关键映射表

### Vue → ArkUI 语法映射

| Vue | ArkUI |
|-----|-------|
| `<template>` | `build()` |
| `ref()` | `@State` |
| `reactive()` | `@State` / `@ObjectLink` |
| `computed()` | `get` 属性 / build 内计算 |
| `watch()` | `@Watch` |
| `defineProps()` | `@Prop` / `@Link` |
| `defineEmits()` | 回调函数参数 |
| `provide/inject` | `@Provide` / `@Consume` |
| Pinia store | `AppStorage` + `@StorageLink` |
| `v-if` | `if/else` |
| `v-for` | `ForEach` |
| `v-model` | `@Link` + 手动赋值 |
| `@click` | `.onClick()` |
| `@mousedown/move/up` | `.onTouch()` / `PanGesture` |
| `@keydown` | `.onKeyEvent()` |
| `@wheel` | `.onAxis()` |
| `class="..."` | 链式 Modifier |
| `:style="..."` | 链式 Modifier |
| CSS 变量 | `$r('app.color.xxx')` |
| `<canvas>` | `Canvas` 组件 |
| `<svg>` | `Shape` 组件 / Canvas |
| `ResizeObserver` | `.onAreaChange()` |

## 五、开发流程建议

1. **先跑通静态 UI**：用假数据填充组件，验证视觉一致性
2. **再接 Store**：替换假数据为真实响应式数据
3. **最后接交互**：逐步添加事件绑定和手势

## 六、验证方式

- 视觉对比：原型截图 vs 鸿蒙端渲染
- 交互对比：按 [interaction-spec.md](file:///f:/LarkDesign/shared/docs/interaction-spec.md) 逐项验证
- 跨端对比：鸿蒙 / Android / iOS 三端一致性



