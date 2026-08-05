# LarkDesign · Code Wiki

> **项目名称**：Harmony Design Studio（HDS）
> **Bundle ID**：`com.example.larkdesign`
> **版本**：v1.0.0（构建 1000000）
> **文档生成日期**：2026-07-27
> **目标平台**：HarmonyOS / OpenHarmony（手机）、Android（ArkUI-X）、iOS（ArkUI-X）、Web（Vue 原型）

---

## 目录

1. [项目概览](#1-项目概览)
2. [整体架构](#2-整体架构)
3. [目录结构](#3-目录结构)
4. [HarmonyOS 原生模块](#4-harmonyos-原生模块)
5. [ArkUI-X 跨平台层](#5-arkuix-跨平台层)
6. [Vue 原型设计项目](#6-vue-原型设计项目)
7. [核心模块职责](#7-核心模块职责)
8. [关键类与函数说明](#8-关键类与函数说明)
9. [类型系统](#9-类型系统)
10. [设计令牌（Design Tokens）](#10-设计令牌design-tokens)
11. [依赖关系](#11-依赖关系)
12. [项目运行方式](#12-项目运行方式)
13. [构建与发布](#13-构建与发布)
14. [约定与规范](#14-约定与规范)

---

## 1. 项目概览

### 1.1 一句话定义

LarkDesign 是一个 **"鸿蒙原生版 Affinity 三合一 + Adobe Firefly 式 AI 中台"** —— 一个通用平面设计/排版工作台，融合矢量（Illustrator）、位图（Photoshop）、多页排版（InDesign）三类能力，并由云端 AI 中台统一操控。

### 1.2 项目组成

LarkDesign 仓库是一个**多形态混合工程**，包含三大部分：

| 部分 | 路径 | 角色 | 技术栈 |
|---|---|---|---|
| HarmonyOS 应用主体 | `entry/`、`AppScope/`、`build-profile.json5` | 鸿蒙原生应用（ArkTS + ArkUI Stage 模型） | ArkTS、ArkUI、Hvigor |
| ArkUI-X 跨平台层 | `.arkui-x/` | 一套 ArkTS 代码桥接到 Android/iOS | ArkUI-X、Gradle、Xcode |
| Vue 原型设计 | `原型设计/` | 高保真 Web 原型，验证 UI/交互与设计令牌 | Vue 3、Vite 6、TypeScript、Tailwind v4 |

### 1.3 产品愿景（来自技术可行性研究报告）

- 一套 ArkTS/ArkUI 代码运行于 HarmonyOS 手机/PC + OpenHarmony 设备/PC，无 HMS 私有依赖。
- AI 推理与生成全部云端化，端侧仅做渲染、排版、导出。
- 自研融合文档模型 Fusion DOM（矢+位+多页统一容器）作为技术护城河。
- 文件格式双轨：开放格式（SVG/ODG/PDF 2.0/OpenRaster）优先 + 原生 `.hds` 格式承载完整上下文。

---

## 2. 整体架构

### 2.1 三形态分层

```
┌────────────────────────────────────────────────────────────────────┐
│                     LarkDesign 多形态工程                            │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────────┐   ┌──────────────────┐   ┌────────────────┐  │
│  │  Vue 原型设计    │   │  HarmonyOS 原生   │   │  ArkUI-X 跨平台 │  │
│  │  (原型设计/)      │   │  (entry/ +        │   │  (.arkui-x/)    │  │
│  │                  │   │   AppScope/)      │   │                 │  │
│  │  • UI 高保真     │   │  • ArkTS Entry    │   │  • Android      │  │
│  │  • 交互验证      │   │  • UIAbility      │   │  • iOS           │  │
│  │  • Design Tokens │   │  • Stage 模型     │   │  • 共享 ArkTS    │  │
│  │  • 组件库原型    │   │  • 主入口         │   │                 │  │
│  └────────┬─────────┘   └────────┬──────────┘   └────────┬────────┘  │
│           │                       │                       │           │
│           └───────────────────────┴───────────────────────┘           │
│                              ↓                                       │
│              共享设计语言 (Design Tokens + 组件规范)                  │
└────────────────────────────────────────────────────────────────────┘
```

### 2.2 Vue 原型应用架构（当前实际可运行部分）

原型项目采用 **极简的两层切换 + 工作区布局 + 全局 Toast** 架构：

```
App.vue
  ├── SplashScreen.vue     (启动屏 / 项目入口)
  ├── WorkspaceLayout.vue  (主工作区，组装以下子面板)
  │     ├── MenuBar.vue              (顶部菜单栏：9 大菜单 + 4 级子菜单，数据来自 data/menuItems.ts)
  │     ├── ToolOptionsBar.vue       (工具选项栏：编组/排列/对齐/分布/矢量/图片/色彩 7 组)
  │     ├── ToolRail.vue             (左侧工具轨：14 个工具组 + 长按弹出 flyout，状态来自 stores/tool.ts)
  │     ├── PagesPanel.vue           (左侧页面/资源面板：双 Tab，状态来自 stores/document.ts)
  │     ├── 画布区 (WorkspaceLayout 内联实现)
  │     │     ├── 标尺 (H/V 双向 + 参考线拖拽)
  │     │     ├── A4 页面 (含示例元素，选中/混合模式来自 stores/layer.ts)
  │     │     ├── ContextMenu.vue   (通用右键菜单，菜单项来自 data/contextMenuItems.ts)
  │     │     └── 缩放控制           (来自 stores/document.ts)
  │     ├── HistoryPanel.vue        (右侧历史记录面板)
  │     ├── Inspector.vue           (右侧检查器：4 个 Tab)
  │     │     ├── 设计 Tab  (变换/对齐/外观/文字/路径查找器/页面属性/色彩管理/画布属性/图层)
  │     │     ├── 导出 Tab  (8 种格式 + 5 个折叠节)
  │     │     ├── 设置 Tab  (MCP 协议/模型信息/智能体技能/系统信息)
  │     │     └── AI 智能Tab (内嵌 AIAssistant.vue)
  │     └── StatusBar.vue           (底部状态栏：色彩空间/尺寸/页码/缩放)
  └── ToastContainer.vue   (全局 Toast，Teleport 到 body，数据来自 stores/toast.ts)
```

### 2.4 渲染架构冻结（2026-08-05）

| 层 | 技术 | 说明 |
|----|------|------|
| **UI 外壳** | ArkUI（ArkTS） | 窗口、面板、输入、选择框、Inspector、HistoryPanel、Minimap——所有非画布 UI |
| **内容渲染** | Skia（C++，经 NAPI 桥接） | 场景绘制、矢量路径、文本排布、位图合成、滤镜、导出渲染——唯一渲染引擎 |
| **NAPI 桥接** | 窄接口 DTO + 句柄 | 只暴露稳定数据结构与操作句柄，不暴露 Skia 类型给 ArkTS |

依赖方向固定为：UI → Feature → Domain → Port → C/C++ 引擎层，禁止反向。

### 2.3 数据流

- **状态管理**：Vue 3 `<script setup>` + Composition API；引入 **Pinia ^4.0.2** 作为应用级状态管理（见 `src/stores/`）。
- **跨组件共享（Pinia Stores）**：
  - `useDocumentStore` — 文档元信息、多页结构、缩放、标尺、面板可见性
  - `useToolStore` — 工具组与激活工具（14 个工具组）
  - `useLayerStore` — 当前选中图层 + 每图层混合模式映射
  - `useColorStore` — 当前色 / 最近色 / 常用色板
  - `useToastStore` — 全局 Toast 队列（自动 2.2s 后消失）
- **遗留共享状态**：`composables/layerBlendStore.ts` 仍以 `reactive` 暴露 16 种混合模式常量与全局映射，被 `useLayerStore` 复用。
- **事件通信**：父子组件用 `defineEmits` / `defineProps`；全局点击/键盘通过 `document.addEventListener` 在 `onMounted/onUnmounted` 注册与释放。
- **菜单/上下文菜单数据**：菜单项数据抽离至 `src/data/menuItems.ts`（顶级 9 大菜单 + 子菜单）与 `src/data/contextMenuItems.ts`（按 text/image/shape/page/canvas 5 套右键菜单）。

---

## 3. 目录结构

```
LarkDesign/
├── .arkui-x/                       # ArkUI-X 跨平台支持
│   ├── android/                    #   Android 工程（Gradle）
│   │   ├── app/                    #     主模块
│   │   │   ├── src/main/
│   │   │   │   ├── java/com/example/larkdesign/
│   │   │   │   │   ├── EntryEntryAbilityActivity.java
│   │   │   │   │   └── MyApplication.java
│   │   │   │   ├── res/            #     资源
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── build.gradle
│   │   └── ... (gradle wrapper 等)
│   ├── ios/                        #   iOS 工程（Xcode）
│   │   └── app/
│   │       ├── AppDelegate.h/m
│   │       ├── EntryEntryAbilityViewController.h/m
│   │       ├── Info.plist
│   │       └── app.xcodeproj/
│   └── arkui-x-config.json5        #   ArkUI-X 配置
│
├── AppScope/                       # 应用级配置（HarmonyOS）
│   ├── app.json5                   #   bundleName/versionCode/icon
│   └── resources/                  #   应用级资源（图标/字符串）
│
├── entry/                          # HarmonyOS 主模块
├── napi/                            # NAPI C++ 引擎层
│   ├── CMakeLists.txt               #   CMake 构建（Skia + lcms2）
│   ├── include/
│   │   └── lark_engine.h            #   稳定 C ABI 头文件
│   ├── src/
│   │   ├── bridge/
│   │   │   ├── napi_register.cpp    #   NAPI 注册入口
│   │   │   └── scene_graph.cpp      #   场景图桥接
│   │   ├── render/
│   │   │   └── canvas_renderer.cpp  #   Skia 画布渲染器
│   │   ├── font/                    #   字体管理（占位）
│   │   └── export/                  #   导出引擎（占位）
│   └── third_party/                 #   第三方库头文件/预编译
│       ├── skia/                    #   Skia 构建输出
│       └── lcms2/                   #   lcms2 构建输出│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/
│   │   │   │   ├── entryability/
│   │   │   │   │   └── EntryAbility.ets    # UIAbility 入口
│   │   │   │   └── pages/
│   │   │   │       └── Index.ets            # 主页面（Hello World 占位）
│   │   │   ├── resources/
│   │   │   │   └── base/
│   │   │   │       ├── element/             # color/float/string
│   │   │   │       ├── media/               # 图标/启动图
│   │   │   │       └── profile/main_pages.json  # 页面路由
│   │   │   └── module.json5                  # 模块清单
│   │   ├── mock/mock-config.json5
│   │   ├── ohosTest/                         # UI 测试
│   │   └── test/                             # 单元测试
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── obfuscation-rules.txt
│   └── oh-package.json5
│
├── 原型设计/                       # Vue 原型设计项目（核心实现）
│   ├── src/
│   │   ├── components/             # 20 个 Vue 组件
│   │   ├── composables/            # 3 个组合函数
│   │   ├── data/                   # 菜单与上下文菜单数据
│   │   │   ├── menuItems.ts        #   顶级菜单数据（9 大菜单）
│   │   │   └── contextMenuItems.ts #   5 套右键菜单（text/image/shape/page/canvas）
│   │   ├── stores/                 # Pinia 状态管理（5 个 store）
│   │   │   ├── document.ts         #   文档/页面/缩放/面板可见性
│   │   │   ├── tool.ts             #   工具组与激活工具
│   │   │   ├── layer.ts            #   选中图层与混合模式
│   │   │   ├── color.ts            #   当前色与色板
│   │   │   └── toast.ts            #   全局 Toast 队列
│   │   ├── types/index.ts          # TS 类型定义
│   │   ├── App.vue                 # 应用根（Splash + Workspace + Toast）
│   │   ├── main.ts                 # 入口（含 Pinia 装配）
│   │   └── style.css               # 全局样式 + Design Tokens
│   ├── dist/                       # 构建产物
│   ├── index.html
│   ├── package.json                # 含 Pinia 依赖
│   ├── vite.config.ts
│   ├── tsconfig*.json
│   ├── AGENTS.md                  # AI Agent 协作指南
│   ├── read_project.ps1            # 项目读取脚本
│   ├── 全系统完整架构图.svg
│   └── 技术可行性研究报告.md
│
├── .hvigor/                       # Hvigor 构建缓存
├── .idea/                         # DevEco IDE 配置
├── hvigor/hvigor-config.json5
├── build-profile.json5            # 工程级构建配置
├── code-linter.json5              # 代码检查规则（含安全规则）
├── hvigorfile.ts                  # 工程级 Hvigor 脚本
├── oh-package.json5               # 工程级依赖
└── oh-package-lock.json5
```

---

## 4. HarmonyOS 原生模块

### 4.1 应用清单（`AppScope/app.json5`）

```json5
{
  "app": {
    "bundleName": "com.example.larkdesign",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:layered_image",
    "label": "$string:app_name"
  }
}
```

### 4.2 模块清单（`entry/src/main/module.json5`）

- **API 类型**：Stage 模式（`apiType: "stageMode"`）
- **入口 Ability**：`EntryAbility`
- **设备类型**：`phone`
- **主元素**：`EntryAbility`，含 `entity.system.home` + `ohos.want.action.home` skill，作为启动入口
- **页面路由**：`$profile:main_pages`，目前仅注册 `pages/Index`

### 4.3 构建配置（`build-profile.json5`）

- **目标 SDK**：HarmonyOS 6.0.2(22)
- **兼容 SDK**：HarmonyOS 6.0.2(22)
- **构建模式**：`debug` / `release`
- **严格模式**：开启大小写检查（`caseSensitiveCheck`）

### 4.4 入口 Ability（`EntryAbility.ets`）

继承 `UIAbility`，实现标准生命周期回调：

| 回调 | 作用 |
|---|---|
| `onCreate(want, launchParam)` | Ability 创建，记录 hilog |
| `onWindowStageCreate(windowStage)` | 加载主页 `pages/Index` |
| `onForeground()` / `onBackground()` | 前后台切换 |
| `onWindowStageDestroy()` | 释放 UI 资源 |
| `onDestroy()` | Ability 销毁 |

> 当前 `Index.ets` 仅显示 "Hello World" 文本，是 HarmonyOS 应用的脚手架占位，**真正可用的 UI 在 Vue 原型项目中**。

### 4.5 代码检查规则（`code-linter.json5`）

- **目标**：所有 `*.ets` 文件
- **忽略**：测试、mock、构建产物
- **规则集**：`@performance/recommended` + `@typescript-eslint/recommended`
- **安全规则**（强制 `error`）：禁用不安全的 AES/Hash/MAC/DH/DSA/ECDSA/RSA/3DES 等

---

## 5. ArkUI-X 跨平台层

### 5.1 配置（`.arkui-x/arkui-x-config.json5`）

```json5
{
  "crossplatform": true,
  "modules": ["entry"]
}
```

将 `entry` 模块标记为跨平台，编译产物可分发到 Android/iOS。

### 5.2 Android 工程（`.arkui-x/android/`）

- **包名**：`com.example.larkdesign`
- **入口**：`EntryEntryAbilityActivity.java` 继承自 ArkUI-X 提供的 Ability Activity
- **Application**：`MyApplication.java`
- **构建系统**：Gradle（含 wrapper）

### 5.3 iOS 工程（`.arkui-x/ios/app/`）

- **入口**：`EntryEntryAbilityViewController.{h,m}` + `AppDelegate.{h,m}` + `main.m`
- **配置**：`Info.plist`、`LaunchScreen.storyboard`
- **资源**：`Assets.xcassets`（AppIcon/AccentColor）

---

## 6. Vue 原型设计项目

### 6.1 技术栈

| 类别 | 选型 | 版本 |
|---|---|---|
| 框架 | Vue 3 | ^3.5.13 |
| 状态管理 | Pinia | ^4.0.2 |
| 语言 | TypeScript | ~5.7.3 |
| 构建 | Vite | ^6.2.0 |
| 样式 | Tailwind CSS v4 + `@tailwindcss/vite` | ^4.0.6 |
| 图标 | Font Awesome Free | ^6.7.2（CDN 加载） |
| 字体 | Inter / Noto Sans SC / Microsoft YaHei | Google Fonts CDN |
| TS 检查 | vue-tsc | ^2.2.0 |

### 6.2 Vite 配置（`原型设计/vite.config.ts`）

```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
})
```

仅启用 Vue 单文件组件 + Tailwind v4 Vite 插件，无额外别名或代理。

### 6.3 TypeScript 配置

- 目标：ES2020 / ESNext 模块
- 严格模式开启（`strict: true`）
- 路径别名：`@/*` → `./src/*`
- 仅类型检查（`noEmit: true`），构建由 Vite 接管

### 6.4 入口（`src/main.ts`）

```ts
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.mount('#app')
```

`createPinia()` 在挂载前注入，所有 store 通过 `defineStore` 自动注册到全局 Pinia 实例。

### 6.5 根组件（`src/App.vue`）

通过 `showSplash` 布尔状态在 `SplashScreen`（启动屏）与 `WorkspaceLayout`（主工作区）间切换；`ToastContainer` 始终挂载，通过 `Teleport to="body"` 渲染全局 Toast：

```vue
<SplashScreen v-if="showSplash" @enter-workspace="showSplash = false" />
<WorkspaceLayout v-else @home="showSplash = true" />
<ToastContainer />
```

---

## 7. 核心模块职责

### 7.1 顶层切换组件

| 组件 | 职责 |
|---|---|
| **SplashScreen.vue** | 启动屏：Logo、标语、新建/打开文件按钮、主题切换、最近文件、模板入口。emit `enter-workspace`。 |
| **WorkspaceLayout.vue** | 主工作区容器，组装所有子面板，实现画布、标尺、参考线、上下文菜单、键盘快捷键、缩放。 |
| **ToastContainer.vue** | 全局 Toast 容器：通过 `<Teleport to="body">` 渲染在画布之上，订阅 `useToastStore.toasts`，自动 2.2s 后消失；不同类型（success/info/warning）显示不同图标与颜色。 |

### 7.2 顶部与底部栏

| 组件 | 职责 |
|---|---|
| **MenuBar.vue** | 顶部菜单栏：文件/编辑/对象/文字/选择/页面/效果/视图/窗口/帮助 9 大菜单，支持 4 级子菜单。集成暗色模式切换、用户头像、窗口控制按钮。 |
| **StatusBar.vue** | 底部状态栏：色彩空间、文档尺寸、页码（均可点击弹窗修改）、同步状态、缩放控制（带进度条）。包含 ColorBar。 |
| **ColorBar.vue** | 状态栏内嵌的色彩条：最近使用色 + 常用色 + 当前色 + 颜色选择器弹窗（复用 ColorPickerPanel）。 |

### 7.3 左侧面板

| 组件 | 职责 |
|---|---|
| **ToolRail.vue** | 工具轨：14 个工具组（选择/套索/裁剪/画笔/橡皮擦/填充/矢量/文字/形状/修饰/效果/色调/取色/导航），支持长按 400ms 弹出 flyout 选择子工具，右键立即弹出。 |
| **PagesPanel.vue** | 双 Tab 面板：**页面 Tab**（母版 + 页面列表，支持增删/复制/移动/拖拽排序/重命名/右键菜单/导出）和**资源 Tab**（按来源分类：云端/本地/智能体生成/内置素材）。 |

### 7.4 右侧面板

| 组件 | 职责 |
|---|---|
| **Inspector.vue** | 右侧检查器，4 个 Tab 切换：设计 / 导出 / 设置 / AI智能。包含图层管理、混合模式、外观、文字、路径查找器、页面属性、色彩管理、画布属性等。 |
| **HistoryPanel.vue** | 历史记录面板：可折叠，快照栏 + 历史滑块 + 步骤列表（12 步示例）。 |

### 7.5 工具选项栏

| 组件 | 职责 |
|---|---|
| **ToolOptionsBar.vue** | 顶部工具选项栏，7 个可展开的分组：编组 / 排列 / 对齐 / 分布 / 矢量（绿色底，含形状属性 + 扩展工具弹窗）/ 图片（蓝色底）/ 色彩（紫色底）。 |

### 7.6 工具与子组件

| 组件 | 职责 |
|---|---|
| **AIAssistant.vue** | AI 智能助手面板（嵌入 Inspector 的 AI Tab 或独立窗口）：对话气泡、AI 建议方案、执行计划（带进度）、作用域、权限提示、快捷操作、输入框。 |
| **ColorPickerPanel.vue** | 颜色选择器面板：色相条 + SV 方块、HEX 输入、RGB/HSL/CMYK 三种模式切换、色板、ICC 配置文件、渲染意图。 |
| **ColorChannelInput.vue** | 颜色通道输入原子组件：标签 + 数字 input + 后缀，emit `update:modelValue`。 |
| **ColorSystem.vue** | 色彩体系展示组件：品牌色、品牌色阶、功能色、中性色。 |
| **ComponentLibrary.vue** | 组件库面板：搜索 + 分类列表，含表单输入/导航/反馈提示等示例组件渲染。 |
| **ArticleLayout.vue** | 文章版式示例：标题/正文/章节/字体层级/页面属性展示。 |
| **ContextMenu.vue** | 通用右键菜单组件：props（visible/x/y/items），items 来自 `data/contextMenuItems.ts`，emit `close` 与 `action`。 |
| **DocumentToolbar.vue** | 文档工具栏（轻量辅助组件）。 |
| **HdsButton.vue** | 设计系统按钮组件：5 种 variant（primary/secondary/text/danger/success）× 3 种 size（sm/md/lg）× 5 种 state（default/hover/focus/disabled/loading）。 |

### 7.7 Composables（组合函数）

| 文件 | 职责 |
|---|---|
| **composables/colorUtils.ts** | 色彩转换工具集：HEX ↔ RGB ↔ HSL ↔ CMYK 互转，含 `parseHsl` 解析器。 |
| **composables/layerBlendStore.ts** | 全局图层混合模式状态：`reactive` 对象 `layerBlendModes`（图层名 → 混合模式字符串），16 种混合模式常量 `BLEND_MODE_OPTIONS`，标签查询函数 `getBlendModeLabel`。被 `stores/layer.ts` 复用。 |
| **composables/useClickOutside.ts** | 点击元素外部触发回调的组合函数：`useClickOutside(targetRef, onClickOutside, eventName?)`，在 `onMounted`/`onUnmounted` 内自动注册/释放 document 事件监听。 |

### 7.8 Pinia Stores（应用级状态管理）

所有 store 集中在 `src/stores/`，使用 Composition API 风格（setup store）：

| Store | ID | 关键状态 | 关键方法 |
|---|---|---|---|
| **useDocumentStore** | `document` | `docName`、`unsaved`、`colorSpace`、`documentSize`、`pages: PageData[]`、`zoomPercent`、`showRuler`、`showPagesPanel`、`showInspector`、`showHistoryPanel` | `switchPage/addPage/duplicatePage/deletePage/movePage/renamePage`、`zoomIn/zoomOut/zoomToFit/zoomToActual`、`toggleRuler` |
| **useToolStore** | `tool` | `toolGroups: ToolGroupData[]`（14 个工具组） | `activateGroup(groupId)`、`selectTool(groupId, toolName)` |
| **useLayerStore** | `layer` | `selectedElement`、`blendModes: Record<layerName, blendMode>` | `select(name)`、`deselect()`、`setBlendMode(layerName, mode)` |
| **useColorStore** | `color` | `currentHex`、`recentColors[]`、`commonColors[]`、`allSwatches`（computed） | `setCurrentColor(hex)`、`addRecent(hex)` |
| **useToastStore** | `toast` | `toasts: ToastItem[]` | `show(message, icon?, type?)`（自动 2.2s 后 `dismiss`）、`dismiss(id)` |

### 7.9 Data 数据层

| 文件 | 职责 |
|---|---|
| **data/menuItems.ts** | MenuBar 9 大菜单的完整数据：文件/编辑/对象/文字/选择/页面/效果/视图/窗口/帮助，每菜单含 3-6 组子项，部分支持 4 级嵌套（共 300+ 菜单项）。 |
| **data/contextMenuItems.ts** | 5 套上下文菜单（`text/image/shape/page/canvas`），通过 `getCtxItemsByType(type)` 返回对应菜单项；内置可复用片段 `layerOrder`（图层顺序）与 `commonActions`（剪切/复制/粘贴/编组/锁定/合并/删除等）。 |

---

## 8. 关键类与函数说明

### 8.1 HarmonyOS 侧

#### `EntryAbility`（`entry/src/main/ets/entryability/EntryAbility.ets`）

```ts
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void
  onDestroy(): void
  onWindowStageCreate(windowStage: window.WindowStage): void
  onWindowStageDestroy(): void
  onForeground(): void
  onBackground(): void
}
```

继承 `@kit.AbilityKit.UIAbility`，使用 `@kit.ArkUI.window` 与 `@kit.PerformanceAnalysisKit.hilog`。`onWindowStageCreate` 中调用 `windowStage.loadContent('pages/Index', ...)` 加载主页。

#### `Index`（`entry/src/main/ets/pages/Index.ets`）

```ts
@Entry @Component
struct Index {
  @State message: string = 'Hello World'
  build() { /* Row > Column > Text */ }
}
```

当前为占位页面，点击文本切换为 "Welcome"。

### 8.2 Vue 侧关键函数

#### `composables/colorUtils.ts`

| 函数 | 签名 | 说明 |
|---|---|---|
| `hexToRgb` | `(hex: string) => {r,g,b} \| null` | HEX 转 RGB，正则匹配 `#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})` |
| `rgbToHex` | `(r,g,b: number) => string` | RGB 转 HEX，自动 clamp 0-255 |
| `rgbToHsl` | `(r,g,b: number) => {h,s,l}` | RGB 转 HSL，h/s/l 均取整 |
| `hslToRgb` | `(h,s,l: number) => {r,g,b}` | HSL 转 RGB |
| `rgbToCmyk` | `(r,g,b: number) => {c,m,y,k}` | RGB 转 CMYK（百分比） |
| `cmykToRgb` | `(c,m,y,k: number) => {r,g,b}` | CMYK 转 RGB |
| `hexToCmyk` | `(hex) => {c,m,y,k}` | 组合：hexToRgb → rgbToCmyk |
| `cmykToHex` | `(c,m,y,k) => string` | 组合：cmykToRgb → rgbToHex |
| `parseHsl` | `(str: string) => {h,s,l} \| null` | 解析 `"152,54,50"` 格式 HSL 字符串 |

#### `composables/layerBlendStore.ts`

```ts
export const layerBlendModes = reactive<LayerBlendState>({...})  // 8 个图层的混合模式
export const BLEND_MODE_OPTIONS = [...]  // 16 种混合模式常量（正常/正片叠底/滤色/...）
export function getBlendModeLabel(value: string): string  // 值 → 中文标签
```

#### Pinia Stores 关键签名

```ts
// stores/document.ts
interface PageData { id: string; name: string; isActive: boolean; color?: string }
useDocumentStore = defineStore('document', () => {
  // state: docName, unsaved, colorSpace, documentSize, pages, zoomPercent, showRuler, showPagesPanel, showInspector, showHistoryPanel
  // actions: switchPage/addPage/duplicatePage/deletePage/movePage/renamePage
  //          zoomIn/zoomOut/zoomToFit/zoomToActual, toggleRuler
})

// stores/tool.ts
interface ToolItemData { name: string; icon: string; shortcut?: string }
interface ToolGroupData { id: string; icon: string; label: string; active: boolean; activeTool: string; tools: ToolItemData[] }
useToolStore = defineStore('tool', () => {
  // state: toolGroups (14 个工具组)
  // actions: activateGroup(groupId), selectTool(groupId, toolName)
})

// stores/layer.ts
interface LayerEffect { name: string; icon: string; active: boolean }
useLayerStore = defineStore('layer', () => {
  // state: selectedElement, blendModes: Record<string, string>
  // actions: select(name), deselect(), setBlendMode(layerName, mode)
  // re-exports: BLEND_MODE_OPTIONS from composables/layerBlendStore
})

// stores/color.ts
useColorStore = defineStore('color', () => {
  // state: currentHex, recentColors[], commonColors[]
  // getters: allSwatches (computed)
  // actions: setCurrentColor(hex), addRecent(hex)
})

// stores/toast.ts
interface ToastItem { id: number; message: string; icon?: string; type: 'success' | 'info' | 'warning' }
useToastStore = defineStore('toast', () => {
  // state: toasts: ToastItem[]
  // actions: show(message, icon?, type?), dismiss(id)
})
```

#### `data/contextMenuItems.ts` 关键导出

```ts
export const textCtxItems: ContextMenuItem[]     // 文字元素右键（编辑/字体/段落/样式/加粗/斜体/...）
export const imageCtxItems: ContextMenuItem[]    // 图片元素右键（替换/裁剪/调整/滤镜/蒙版/...）
export const shapeCtxItems: ContextMenuItem[]    // 形状元素右键
export const pageCtxItems: ContextMenuItem[]     // 页面右键
export const canvasCtxItems: ContextMenuItem[]   // 画布右键
export function getCtxItemsByType(type: string): ContextMenuItem[]  // 按类型选择上述数组
```

#### `WorkspaceLayout.vue` 中的关键逻辑

| 函数/数据 | 说明 |
|---|---|
| `rulerScale = 50` | 标尺主刻度间距（px） |
| `hMarks/hTicks/vMarks/vTicks` | 计算属性，生成标尺主刻度文字与次刻度位置 |
| `guidelines: GuideLine[]` | 参考线列表，`{id, orientation: 'h'\|'v', pos}` |
| `onHRulerMouseDown` / `onVRulerMouseDown` | 从标尺拖出参考线 |
| `onRulerCornerMouseDown` | 点击标尺左上角清空所有参考线 |
| `docStore.zoomIn/zoomOut/zoomToFit/zoomToActual` | 画布缩放（10-400%，步长 10），来自 `useDocumentStore` |
| `onElementDragStart/Move/End` | 选中元素后支持鼠标拖动，`dragOffset` 跟踪位移；切换选中时重置 |
| `onWheelZoom(e)` | `Ctrl+Wheel` 缩放画布 |
| `onKeyDown(e)` | 全局键盘：`Ctrl+R` 标尺、`Ctrl++/-` 缩放、`Ctrl+0` 适配、`Ctrl+1` 实际像素、`Ctrl+S` 保存、`Ctrl+C/V` 复制粘贴、`Ctrl+Z/Shift+Z` 撤销重做、`Space` 平移光标、`Delete/Esc` 取消选中 |
| `ctxVisible/ctxX/ctxY/ctxType/ctxItems` | 上下文菜单状态，`ctxItems` 为 computed，通过 `getCtxItemsByType(ctxType)` 从 data 层取菜单项 |
| `onElementContextMenu/onCanvasContextMenu/onPageContextMenu` | 分别对应元素/画布/页面右键，设置 ctxType 后弹出 `ContextMenu` 组件 |
| `onCtxAction(action)` | 派发菜单动作到对应 store 方法或 `toastStore.show()` 反馈 |
| `ResizeObserver` | 监听画布滚动容器尺寸变化，动态更新标尺长度（`rulerWidth/rulerHeight`） |
| `isPanning` | `Space` 键按下时进入抓手平移模式 |

#### `MenuBar.vue` 中的菜单数据

菜单项数据**抽离至 `src/data/menuItems.ts`**，导出 `menuItems: MenuItem[]`，包含 9 个顶级菜单，每个菜单有 3-6 组子项，部分子项支持 4 级嵌套。完整菜单项约 300+ 条，覆盖 Adobe 全家桶功能映射。`MenuBar.vue` 仅负责渲染与交互。

#### `Inspector.vue` 中的关键逻辑

| 数据 | 说明 |
|---|---|
| `layers: EnhancedLayer[]` | 8 个图层（含 1 个组、2 个文本、1 个图像、1 个形状、1 个调整层、1 个背景、1 个填充、1 个智能对象） |
| `flatLayers` | computed：将层级图层扁平化为带 `_key` 的列表用于渲染 |
| `selectLayerByKey` / `toggleVisibilityByKey` / `toggleLockByKey` | 通过 `_key` 操作图层（避免索引错乱） |
| `setBlendMode(value)` | 设置当前激活图层的混合模式，同时同步到全局 `layerBlendModes` |
| `mcpTools` / `mcpResources` | MCP 协议暴露的工具与资源（设置 Tab） |
| `agentSkills` | 8 个智能体技能（AI 图像生成/智能配色/版式智能/字体助手/文案生成/矢量创作/样机生成/滤镜引擎） |
| `modelProtocols` / `modelProviders` | 模型信息配置：5 种协议 × 10 家提供商 |
| `exportFormats` | 8 种导出格式：PNG/JPEG/WebP/SVG/PDF/EPS/CDR/HDS |
| `estimatedSize` | computed：根据尺寸/质量/缩放估算导出文件大小 |

#### `ToolRail.vue` 中的工具组

`toolGroups: ToolGroup[]` 共 14 组，每组含 `tools: ToolItem[]`。关键交互：

- **长按 400ms** 弹出 flyout（左键多工具组）
- **右键** 立即弹出 flyout
- **单击** 单工具组直接激活
- flyout 通过 `<Teleport to="body">` 避免被父容器 `overflow` 裁剪

#### `HdsButton.vue` 设计系统按钮

```ts
type ButtonVariant = 'primary' | 'secondary' | 'text' | 'danger' | 'success'
type ButtonSize = 'sm' | 'md' | 'lg'
type ButtonState = 'default' | 'hover' | 'focus' | 'disabled' | 'loading'
```

通过 `computed` 计算 `sizeClasses` / `variantClasses` / `stateClasses`，loading 状态显示旋转图标且禁用点击。

---

## 9. 类型系统

类型集中定义在 `原型设计/src/types/index.ts`：

| 类型 | 用途 |
|---|---|
| `ButtonVariant` | 按钮变体：`primary/secondary/text/danger/success` |
| `ButtonSize` | 按钮尺寸：`sm/md/lg` |
| `ButtonState` | 按钮状态：`default/hover/focus/disabled/loading` |
| `MenuItem` | 菜单项：`{label, shortcut?, icon?, children?, divider?, disabled?}` |
| `ComponentCategory` | 组件库分类：`{name, count, icon?, items}` |
| `ComponentItem` | 组件库项：`{name, description?, icon?}` |
| `ColorGroup` | 色彩分组：`{name, colors}` |
| `ColorToken` | 色彩令牌：`{name, value, hex, cssVar?}` |
| `PageTab` | 页面标签：`{id, name, thumb?, isActive?}` |
| `ToolItem` | 工具项：`{name, icon, active?}` |
| `LayerItem` | 图层项：`{name, type: 'text'\|'image'\|'shape'\|'group', visible, locked?, active?, icon?, iconColor?}` |
| `PositionSize` | 位置尺寸：`{x, y, width, height, unit}` |

> 部分组件内部还定义了扩展类型（如 `Inspector.vue` 的 `EnhancedLayer extends LayerItem`、`ToolRail.vue` 的 `ToolGroup`、`PagesPanel.vue` 的 `ResourceCategory`/`ResourceItem`/`LocalPage`），均就近定义在使用处。

---

## 10. 设计令牌（Design Tokens）

全部定义在 `原型设计/src/style.css`，通过 CSS 变量驱动，支持亮/暗双主题。

### 10.1 色彩令牌

| 类别 | 变量 | 示例值 |
|---|---|---|
| 品牌主色 | `--color-primary` | `#3AC487`（Harmony Green） |
| 品牌深色 | `--color-primary-dark-900/700` | `#0D5A3D` / `#16865F` |
| 品牌浅色 | `--color-primary-light-300/100` | `#9EDDC0` / `#DDF5EA` |
| 功能色 | `--color-info/success/warning/error` | `#3B82F6` / `#22C55E` / `#F59E0B` / `#EF4444` |
| 文本色 | `--color-title/body/secondary/tertiary/muted` | `#20242A` → `#7B8490` 五级灰 |
| 边框 | `--color-border/border-light` | `#D8DCE1` / `#E3E6E9` |
| 面板/背景 | `--color-panel/bg/white/surface` | `#F7F8F9` / `#F4F6FA` / `#FFFFFF` |
| 画布 | `--color-canvas-bg/page/hover-bg/focus-ring` | `#ECEDEF` / `#FFFFFF` / `#EDF9F4` / `#3AC487` |
| 标尺 | `--color-ruler-bg/border/tick/text/corner` | 5 个标尺专用色 |

### 10.2 间距与圆角

| 类别 | 变量 |
|---|---|
| 间距 | `--spacing-1/2/3/4/5/6/8/10` = `4/8/12/16/20/24/32/40px` |
| 圆角 | `--radius-sm/md/lg/xl/2xl/full` = `4/6/8/12/16/9999px` |

### 10.3 暗色模式

通过 `.dark` 类名作用域覆盖上述变量（页面 `--color-page` 始终保持白色）。`MenuBar.vue` 中的 `toggleDark()` 通过 `document.documentElement.classList.toggle('dark')` 切换。

### 10.4 字体

```css
.font-primary { font-family: "Inter", "HarmonyOS Sans SC", "Microsoft YaHei", sans-serif; }
.font-mono    { font-family: "JetBrains Mono", "Consolas", monospace; }
```

字体通过 `index.html` 中的 Google Fonts CDN 与 Font Awesome CDN 加载。

### 10.5 样式约定

- 全局 `* { scrollbar-width: thin; scrollbar-color: var(--color-border) transparent; }`
- Tailwind v4 通过 `@import "tailwindcss";` 引入
- 业务样式大量使用 Tailwind 任意值语法：`bg-[var(--color-panel)]`、`text-[10px]`、`rounded-[4px]`、`px-[12px]` 等，**精确到像素**

---

## 11. 依赖关系

### 11.1 HarmonyOS 依赖（`oh-package.json5`）

**devDependencies**：

- `@ohos/hypium` `1.0.25` — HarmonyOS 单元测试框架
- `@ohos/hamock` `1.0.0` — HarmonyOS Mock 框架

**Hvigor 插件**（`hvigorfile.ts`）：

- `@ohos/hvigor-ohos-plugin` — 通过 `export { appTasks }` 注册

### 11.2 Vue 原型依赖（`原型设计/package.json`）

**dependencies**：

- `vue` `^3.5.13`
- `@fortawesome/fontawesome-free` `^6.7.2`
- `pinia` `^4.0.2` — 应用级状态管理（document/tool/layer/color/toast 5 个 store）

**devDependencies**：

- `@vitejs/plugin-vue` `^5.2.3`
- `autoprefixer` `^10.4.20`
- `tailwindcss` `^4.0.6` + `@tailwindcss/vite` `^4.0.6`
- `typescript` `~5.7.3`
- `vite` `^6.2.0`
- `vue-tsc` `^2.2.0`

### 11.3 组件间依赖图（Vue 原型）

```
App.vue
  ├── SplashScreen.vue
  ├── WorkspaceLayout.vue
  │     ├── MenuBar.vue            ← data/menuItems
  │     ├── ToolOptionsBar.vue     ← emits 'home'
  │     ├── ToolRail.vue           ← stores/tool
  │     ├── PagesPanel.vue         ← stores/document
  │     ├── (画布区：内联在 WorkspaceLayout)
  │     │     ├── 标尺 / 参考线 / 缩放
  │     │     ├── ContextMenu.vue ← data/contextMenuItems (getCtxItemsByType)
  │     │     └── 画布元素 ↔ stores/layer (selectedElement + blendModes)
  │     ├── HistoryPanel.vue      ← stores/toast (回退反馈)
  │     ├── Inspector.vue         ← stores/layer, stores/color
  │     │     ├── AIAssistant.vue
  │     │     └── ColorPickerPanel.vue
  │     │           └── ColorChannelInput.vue ← composables/colorUtils
  │     └── StatusBar.vue         ← stores/document
  │           └── ColorBar.vue    ← stores/color
  │                 └── ColorPickerPanel.vue
  └── ToastContainer.vue         ← stores/toast (全局 Teleport)
```

**Stores 注入路径**：

- `main.ts` 调用 `app.use(createPinia())` 装配
- 所有组件可通过 `useXxxStore()` 在 `<script setup>` 内访问，无需 props 透传
- `useDocumentStore` 是中枢：`pages` / `zoom` / `showRuler` / 面板可见性均由此驱动

**未在 App.vue 中挂载但已存在的组件**（设计系统库，可被引用）：

- `ColorSystem.vue`、`ComponentLibrary.vue`、`ArticleLayout.vue`、`HdsButton.vue`

### 11.4 已知构建问题（截至 2026-07-27）

`npm run build` 当前会因 TypeScript 严格模式失败，错误集中在 `src/data/menuItems.ts`：

- **菜单分隔符缺 `label`**：`{ divider: true }` 在 `MenuItem` 类型中要求 `label` 必填，约 28 处报错（TS2741）
- **tsconfig 未知选项**：`tsconfig.app.json` 中包含无效编译选项 `useDefineForEmit`（应为 `useDefineForClassFields`），TS5023 报错

修复建议（未自动应用）：

1. 将 `MenuItem.label` 改为可选（`label?: string`），或在所有 `{ divider: true }` 处补 `label: ''`
2. 删除 `tsconfig.app.json` 中的 `useDefineForEmit` 选项或改为正确的 `useDefineForClassFields: true`

---

## 12. 项目运行方式

### 12.1 Vue 原型（推荐快速预览）

```bash
cd f:\LarkDesign\原型设计

# 安装依赖（首次）
npm install

# 启动开发服务器（默认 http://localhost:5173）
npm run dev

# 类型检查 + 生产构建
npm run build

# 预览构建产物
npm run preview
```

构建脚本：

```json
{
  "dev": "vite",
  "build": "vue-tsc -b && vite build",
  "preview": "vite preview"
}
```

### 12.2 HarmonyOS 应用

**前置**：安装 [DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio/)（鸿蒙官方 IDE）。

**步骤**：

1. 用 DevEco Studio 打开 `f:\LarkDesign` 工程根目录
2. 等待 Hvigor 同步完成（`.hvigor/` 会生成缓存）
3. 配置签名（`build-profile.json5` 中 `signingConfigs`，目前为空）
4. 选择设备/模拟器（phone）
5. 点击运行 ▶ 或 `F5`，Hvigor 会编译 `entry` 模块并部署到设备

**关键文件**：

- `entry/src/main/ets/entryability/EntryAbility.ets` — 入口 Ability
- `entry/src/main/ets/pages/Index.ets` — 主页面
- `entry/src/main/resources/base/profile/main_pages.json` — 页面路由（当前仅 `pages/Index`）

### 12.3 ArkUI-X 跨平台构建

**Android**：

```bash
cd f:\LarkDesign\.arkui-x\android
./gradlew assembleDebug    # 生成 APK
./gradlew assembleRelease  # 生成 Release APK
```

需要先在 DevEco Studio 中执行 ArkUI-X 的跨平台编译，生成 ArkTS 产物后再由 Gradle 打包。

**iOS**：

用 Xcode 打开 `.arkui-x/ios/app.xcodeproj`，选择目标设备/模拟器后 Build & Run。同样需要先在 DevEco 中生成 ArkTS 产物。

### 12.4 测试

**HarmonyOS 单元测试**：

- 位于 `entry/src/test/` 与 `entry/src/ohosTest/`
- 框架：`@ohos/hypium`
- 在 DevEco Studio 中右键测试文件运行

**Vue 原型**：当前 `package.json` 未配置 test 脚本。

---

## 13. 构建与发布

### 13.1 HarmonyOS 构建

| 配置项 | 值 |
|---|---|
| 工程级构建 | `build-profile.json5` |
| 模块级构建 | `entry/build-profile.json5` |
| 构建模式 | `debug` / `release` |
| 目标 SDK | HarmonyOS 6.0.2(22) |
| 混淆规则 | `entry/obfuscation-rules.txt`（默认关闭） |
| 严格模式 | 大小写检查开启 |

### 13.2 Vue 原型构建

- 构建产物：`原型设计/dist/`（已包含 `index.html` + `assets/index-*.js` + `assets/index-*.css`）
- 类型检查：`vue-tsc -b` 在 `build` 脚本中先执行
- 部署：纯静态资源，可托管在任意静态服务器（Nginx/Vercel/Netlify/GitHub Pages）

### 13.3 代码检查

- **HarmonyOS**：`code-linter.json5` 配置，运行 `code-linter` 命令
- **Vue 原型**：依赖 `vue-tsc` 进行类型检查；Tailwind 由 PostCSS 处理；无 ESLint/Prettier 配置（建议后续补充）

---

## 14. 约定与规范

### 14.1 命名约定

- **HarmonyOS**：Ability 以 `XxxAbility` 命名，页面以 `Index.ets` 为入口，资源用 `$type:name` 引用
- **Vue 组件**：PascalCase 文件名（`WorkspaceLayout.vue`），`<script setup lang="ts">` 单文件组件
- **TS 类型**：PascalCase 接口名，集中定义在 `types/index.ts` 或就近组件内
- **Composables**：camelCase 文件名（`colorUtils.ts`、`layerBlendStore.ts`），导出函数与常量

### 14.2 样式约定

- **首选 Tailwind 任意值**：`bg-[var(--color-panel)]`、`text-[12px]`、`rounded-[8px]`
- **设计令牌优先**：所有颜色必须用 CSS 变量（`var(--color-xxx)`），不允许硬编码十六进制（除令牌定义本身）
- **像素精确**：UI 高度/宽度/字号均精确到 px，使用任意值而非预设档位
- **暗色模式**：仅修改 `:root` 变量，组件代码无需感知主题

### 14.3 交互约定

- 弹窗/菜单通过 `<Teleport to="body">` 渲染到 body，避免父容器 `overflow` 裁剪
- 全局事件监听在 `onMounted` 注册，**必须**在 `onUnmounted` 释放
- 弹窗关闭：点击外部（`document.addEventListener('click', ...)`）+ Esc（部分组件）
- 拖拽：原生 HTML5 drag API（`draggable`/`@dragstart`/`@drop`），见 `PagesPanel.vue`

### 14.4 安全约定（来自 `code-linter.json5`）

- 禁用不安全的 AES/Hash/MAC/DH/DSA/ECDSA/RSA/3DES 实现（`error` 级别）
- 部分操作（如 MAC）降级为 `warn`
- 使用 `@performance/recommended` 性能规则集

### 14.5 Git 忽略（来自根 `.gitignore` 与 `entry/.gitignore`）

- 构建产物：`build/`、`dist/`、`.preview/`、`oh_modules/`、`node_modules/`
- IDE 配置：`.idea/`（部分）
- Hvigor 缓存：`.hvigor/`（部分）

---

## 附录 A：菜单与快捷键速查

### A.1 MenuBar 9 大菜单

| 菜单 | 子组数 | 主要内容 |
|---|---|---|
| 文件 | 6 | 新建/打开/最近/置入/保存/导出/打印/退出 |
| 编辑 | 6 | 撤销/剪切复制粘贴/填充/变换/定义预设/偏好设置 |
| 对象 | 6 | 变换/排列编组/锁定隐藏/扩展蒙版/图层操作/对齐分布 |
| 文字 | 6 | 字符段落面板/样式/字体样式/对齐/字号轮廓/高级 |
| 选择 | 4 | 基础/相同/选区操作/扩展选取 |
| 页面 | 4 | 页面操作/母版/显示模式/布局 |
| 效果 | 5 | 画廊/图层样式/滤镜分类/变形/清除 |
| 视图 | 5 | 缩放/显示对齐/校样色域/工作区 |
| 窗口 | 5 | 工作区/核心面板/辅助面板/排列/重置 |
| 帮助 | 3 | 帮助文档/关于/更新反馈 |

### A.2 全局快捷键（`WorkspaceLayout` 中注册）

| 快捷键 | 作用 |
|---|---|
| `Ctrl+R` | 切换标尺 |
| `Ctrl++` / `Ctrl+=` | 放大 |
| `Ctrl+-` | 缩小 |
| `Ctrl+0` | 适配画布 |
| `Ctrl+1` | 实际像素 |
| `Ctrl+S` | 保存（toast 反馈） |
| `Ctrl+C` / `Ctrl+V` | 复制 / 粘贴（toast 反馈） |
| `Ctrl+Z` / `Ctrl+Shift+Z` | 撤销 / 重做（toast 反馈） |
| `Delete` / `Esc` | 取消选中图层 |
| `Space`（按住） | 进入抓手平移模式 |
| `Ctrl+Wheel` | 滚轮缩放画布 |

### A.3 工具快捷键（`ToolRail`）

`V` 选择 / `A` 直接选择 / `W` 魔棒 / `L` 套索 / `C` 裁剪 / `B` 画笔 / `N` 铅笔 / `E` 橡皮擦 / `G` 填充 / `P` 钢笔 / `T` 文字 / `U` 形状 / `S` 仿制图章 / `J` 修复 / `Y` 历史画笔 / `O` 减淡加深 / `I` 吸管 / `K` 标尺 / `H` 抓手 / `R` 旋转视图 / `Z` 缩放

---

## 附录 B：参考文档

- **技术可行性研究报告**：[技术可行性研究报告.md](file:///f:/LarkDesign/原型设计/技术可行性研究报告.md) — 详细的引擎选型、Fusion DOM 设计、AI 中台协议、文件格式规范
- **全系统架构图**：[全系统完整架构图.svg](file:///f:/LarkDesign/原型设计/全系统完整架构图.svg)
- **HarmonyOS 开发文档**：https://developer.harmonyos.com/
- **ArkUI-X 文档**：https://gitee.com/openharmony/arkui_for_android
- **Vue 3 文档**：https://vuejs.org/
- **Tailwind CSS v4**：https://tailwindcss.com/
- **Vite 6**：https://vite.dev/

---

> **文档维护说明**：本 Wiki 反映仓库截至 2026-07-27 的状态（覆盖来自 `F:\LarkDesign1\原型设计` 的最新版本）。Vue 原型已引入 **Pinia** 作为应用级状态管理，菜单与上下文菜单数据抽离至 `src/data/`，全局 Toast 通过 `ToastContainer` + `useToastStore` 统一管理。HarmonyOS 侧仍为脚手架占位，所有可交互 UI 实现集中在 `原型设计/` 目录。已知构建问题（`menuItems.ts` 分隔符 + `tsconfig.app.json` 无效选项）详见 §11.4。


