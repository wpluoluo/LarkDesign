# 正式 HarmonyOS 项目结构

状态：结构基线已建立，ArkTS 业务代码仍处于从历史平铺目录迁移到目标边界的阶段。当前编译失败和未接通能力必须按门禁记录，不能用原型构建结果掩盖。

## 1. 交付边界

正式交付只包含 `entry/`、`napi/`、`shared/` 和必要的资源、配置。`原型设计/` 是冻结参考；根目录截图、Playwright 导出、临时脚本和错误日志不是源代码。

## 2. 目标目录

```text
entry/src/main/ets/
├── app/                 # Ability、应用启动、路由和生命周期
├── features/            # 按用户能力组织的 UI 与用例
│   ├── workspace/       # 工作区、菜单、工具栏、画布宿主
│   ├── inspector/       # Design/Export/Settings/AI 面板
│   ├── document/        # 文档、页面、图层和历史操作
│   └── ai/              # AI 配置、会话和工具调用
├── domain/              # 纯 ArkTS 数据模型、操作、序列化和算法
│   ├── model/
│   ├── operations/
│   └── ports/
├── platform/            # 文件、持久化、网络、窗口和系统能力适配器
├── native/              # NAPI DTO、句柄生命周期和错误映射
└── resources/           # 仅由 entry/src/main/resources 管理
```

跨端纯契约继续放在 `shared/`；C/C++ 实现只放在 `napi/src/{bridge,render,export,font}`。不允许 ArkTS 直接依赖 Skia 类型、UI 组件依赖 C++ 头文件，或 domain 反向依赖 UI/平台实现。

## 3. 迁移规则

历史目录 `components/`、`stores/`、`types/`、`utils/` 仅作为迁移期兼容位置；Ability 和页面入口已先迁入 `app/`。新文件不得继续放入这些平铺目录；每次迁移以一个垂直切片为单位，先迁移测试和依赖，再删除旧文件。禁止复制一份“新旧并行”的实现来掩盖未完成迁移。

建议顺序：

1. `types/` → `domain/model`，保留 `shared` 契约作为唯一跨端源。
2. `stores/` → 对应 feature 的状态与 `domain` 用例，持久化通过 `platform` port。
3. `utils/` → 明确归属 `domain`、`platform` 或 `native`，禁止继续使用含义不明的工具箱。
4. `components/` → `features/*`，由页面入口只组合 feature，不承载业务逻辑。

## 4. 源代码真相

- 文档格式和场景数据：`shared/types/scene.ts` 与其 ArkTS 映射。
- 画布渲染：NAPI/Skia；ArkUI 只负责宿主和交互。
- 持久化文档：正式实现必须使用 `platform` 持久化适配器，`AppStorage` 只能保存瞬时 UI 状态。
- 功能状态：以设备测试、日志和真实文件数据为准；截图和“返回成功”不构成证据。
