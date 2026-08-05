# LarkDesign 组件清单与鸿蒙映射

> 冻结时间：2026-07-28
> 原型源：f:\LarkDesign\原型设计\src\components\
> 目标端：HarmonyOS ArkUI + ArkUI-X（Android/iOS 跨端）

## 一、组件分级清单（按迁移顺序）

### Level 1 - 基础原子组件（优先迁移）

| Vue 组件 | 职责 | ArkUI 对应 | 优先级 |
|---------|------|-----------|--------|
| `HdsButton.vue` | 通用按钮 | `@Component HdsButton` | P0 |
| `ToastContainer.vue` | 顶部提示（单条） | `@Component ToastContainer` + `OverlayManager` | P0 |
| `ContextMenu.vue` | 右键菜单 | `@Component ContextMenu` + `Menu` | P0 |
| `StatusBar.vue` | 底部状态栏 | `@Component StatusBar` | P0 |

### Level 2 - 工具与控件组件

| Vue 组件 | 职责 | ArkUI 对应 | 优先级 |
|---------|------|-----------|--------|
| `ToolRail.vue` | 左侧工具栏（选择/形状/文字/吸管/抓手/缩放） | `@Component ToolRail` | P1 |
| `ToolOptionsBar.vue` | 顶部工具属性栏（上下文相关） | `@Component ToolOptionsBar` | P1 |
| `MenuBar.vue` | 顶部菜单栏 | `@Component MenuBar` | P1 |
| `ThemePicker.vue` | 主题选择器 | `@Component ThemePicker` | P1 |
| `ColorBar.vue` | 颜色色板条 | `@Component ColorBar` | P1 |
| `ColorChannelInput.vue` | 颜色通道输入框 | `@Component ColorChannelInput` | P1 |
| `ColorPickerPopover.vue` | 颜色选择弹出层 | `@Component ColorPickerPopover` | P1 |
| `ColorPickerPanel.vue` | 颜色选择面板 | `@Component ColorPickerPanel` | P1 |

### Level 3 - 面板组件

| Vue 组件 | 职责 | ArkUI 对应 | 优先级 |
|---------|------|-----------|--------|
| `PagesPanel.vue` | 左侧 Frame 大纲面板 | `@Component PagesPanel` | P2 |
| `Inspector.vue` | 右侧属性面板（含Typography/Appearance等） | `@Component Inspector` | P2 |
| `HistoryPanel.vue` | 历史记录面板 | `@Component HistoryPanel` | P2 |
| `Minimap.vue` | 鸟瞰图 | `@Component Minimap` | P2 |
| `SplashScreen.vue` | 启动屏（模式选择） | `@Component SplashScreen` | P2 |
| `AIAssistant.vue` | AI 助手面板 | `@Component AIAssistant` | P3 |
| `ByokConfigModal.vue` | BYOK 配置弹窗 | `@Component ByokConfigModal` | P3 |
| `ComponentLibrary.vue` | 组件库面板 | `@Component ComponentLibrary` | P3 |
| `ColorSystem.vue` | 颜色系统面板 | `@Component ColorSystem` | P3 |

### Level 4 - 容器与画布组件（最后迁移）

| Vue 组件 | 职责 | ArkUI 对应 | 优先级 |
|---------|------|-----------|--------|
| `WorkspaceLayout.vue` | 工作区主布局 | `@Component WorkspaceLayout` | P3 |
| `CanvasStage.vue` | 画布舞台（无限画布+单画布模式） | `@Component CanvasStage` + `Canvas`/`XComponent` | P3 |
| `FrameView.vue` | 单个 Frame 容器（编辑模式） | `@Component FrameView` | P3 |
| `DocumentToolbar.vue` | 文档工具栏 | `@Component DocumentToolbar` | P3 |
| `ArticleLayout.vue` | 文章布局组件 | `@Component ArticleLayout` | P4 |
| `useFrameHandles.ts` | Frame handles 复用逻辑 | `useFrameHandles.ets` 工具文件 | P3 |

## 二、Store 清单

| Vue Store | 职责 | ArkUI 对应 |
|-----------|------|------------|
| `stores/theme.ts` | 主题管理（5套主题切换） | `AppStorage` + `ThemeStore` |
| `stores/document.ts` | 文档状态（缩放、面板显隐） | `AppStorage` + `DocumentStore` |
| `stores/fusionDocument.ts` | Fusion DOM 文档（页面/图层/对象） | `AppStorage` + `FusionDocumentStore` |
| `stores/tool.ts` | 当前工具与工具选项 | `AppStorage` + `ToolStore` |
| `stores/color.ts` | 当前颜色、颜色历史 | `AppStorage` + `ColorStore` |
| `stores/layer.ts` | 图层状态 | `AppStorage` + `LayerStore` |
| `stores/toast.ts` | Toast 提示（单条） | `AppStorage` + `ToastStore` |
| `stores/byok.ts` | BYK 配置 | `AppStorage` + `ByokStore` |

## 三、Composable 清单（纯算法，可跨端共享）

| Vue Composable | 职责 | 迁移方式 |
|----------------|------|----------|
| `composables/useCanvasInteraction.ts` | 画布交互（选中/拖拽/resize/框选） | ArkTS 类 + shared 算法 |
| `composables/useInfiniteCanvas.ts` | 无限画布（平移/缩放/视口） | ArkTS 类 + shared 算法 |
| `composables/useCanvasRenderer.ts` | Canvas 渲染器 | ArkTS Canvas API |
| `composables/useShapeDrawing.ts` | 形状绘制 | ArkTS + shared |
| `composables/useKeyboardShortcuts.ts` | 键盘快捷键 | ArkTS `onKeyEvent` |
| `composables/useContextMenuActions.ts` | 右键菜单动作 | ArkTS 类 |
| `composables/useMenuActions.ts` | 菜单动作 | ArkTS 类 |
| `composables/useClickOutside.ts` | 点击外部关闭 | ArkTS `onAreaChange` + 触摸监听 |
| `composables/useAiAgent.ts` | AI Agent | ArkTS HTTP |
| `composables/colorUtils.ts` | 颜色工具（HSL/RGB转换） | shared 跨端 |
| `composables/layerBlendStore.ts` | 混合模式 | shared 跨端 |

## 四、Fusion DOM 清单（核心数据层）

| 文件 | 职责 | 迁移方式 |
|------|------|----------|
| `fusion/index.ts` | 类型导出 | → `shared/types/` |
| `fusion/factory.ts` | 工厂函数（创建对象/文档） | → `shared/fusion/` |
| `fusion/ops.ts` | 文档操作（addFrame/moveObject等） | → `shared/fusion/` |
| `fusion/serializer.ts` | 序列化/反序列化 | → `shared/fusion/` |
| `fusion/renderer.ts` | 渲染器 | → ArkTS Canvas 渲染 |
| `fusion/exporter.ts` | 导出（PNG/JPG/SVG） | → ArkTS 导出 |

## 五、数据与配置

| 文件 | 职责 | 迁移方式 |
|------|------|----------|
| `data/menuItems.ts` | 菜单项配置 | → `entry/ets/data/` |
| `data/contextMenuItems.ts` | 右键菜单项配置 | → `entry/ets/data/` |
| `ai/mcp.ts` | AI MCP 协议 | → `entry/ets/ai/` |
| `types/index.ts` | 类型定义 | → `shared/types/` |

## 六、迁移优先级总结

```
P0 (基础)  → HdsButton, ToastContainer, ContextMenu, StatusBar
P1 (工具)  → ToolRail, ToolOptionsBar, MenuBar, ThemePicker, Color*（4个）
P2 (面板)  → PagesPanel, Inspector, HistoryPanel, Minimap, SplashScreen
P3 (画布)  → WorkspaceLayout, CanvasStage, FrameView, DocumentToolbar, useFrameHandles
P4 (辅助)  → ArticleLayout, AIAssistant, ByokConfigModal, ComponentLibrary, ColorSystem
```

## 七、跨端共享层（shared/）

以下内容为纯算法/类型，可在鸿蒙、Android、iOS、桌面端共享：

```
shared/
├── tokens/
│   └── tokens.json          ✅ 已创建
├── types/
│   ├── scene.ts             # SceneObject/Frame/Layer 类型
│   ├── document.ts          # HdsDocument 类型
│   └── transform.ts         # Transform 类型
├── algorithms/
│   ├── alignment.ts         # 对齐分布算法
│   ├── hitTest.ts           # 命中检测
│   ├── geometry.ts          # 几何运算（包围盒、相交等）
│   ├── coordinate.ts        # 坐标转换
│   └── pathfinder.ts        # 布尔运算（合集/差集/交集）
├── fusion/
│   ├── factory.ts           # 工厂函数
│   ├── ops.ts               # 文档操作
│   └── serializer.ts        # 序列化
└── color/
    ├── colorUtils.ts        # 颜色工具
    └── blendModes.ts        # 混合模式
```
