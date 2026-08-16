# LarkDesign

LarkDesign 的正式交付目标是 HarmonyOS 原生应用。仓库中的 Vue 工程位于 `原型设计/`，从本次整理起只作为只读参考，不参与正式功能验收、发布包或默认质量门禁。

## 项目边界

- `entry/`：HarmonyOS 应用模块，正式产品代码与测试。
- `napi/`：C/C++ 渲染与导出引擎，通过窄 NAPI 接口被 ArkTS 调用。
- `shared/`：跨端契约、纯数据模型、算法和 Node 单元测试。
- `原型设计/`：冻结的 Vue 参考原型，仅用于交互和视觉对照。
- `docs/`：正式架构、工程标准、门禁和开发计划，入口见 [文档索引](docs/README.md)。

## 常用命令

```text
pnpm test                 # shared 单元测试
pnpm typecheck            # Vue 参考工程类型检查
pnpm build:reference      # 仅构建冻结原型，不代表鸿蒙构建
pnpm verify:formal        # 检查正式目录边界、垃圾产物和 git diff
pnpm build:harmony        # 在已配置 DevEco/SDK 的 Windows 环境构建 HAP
```

正式发布必须另外通过 `pnpm verify:release`、ArkTS 编译、NAPI/CMake 构建、设备验收和导出往返测试。任何“演示成功”、空实现或未接通的能力都不能作为发布证据。

详见：

- [正式 HarmonyOS 结构](docs/architecture/official-harmony-structure.md)
- [工程门禁](docs/standards/engineering-gates.md)
- [ArkTS 标准](docs/standards/arkts-style.md)
- [Native Bridge 标准](docs/standards/native-bridge.md)
- [开发计划](docs/superpowers/plans/2026-08-15-harmony-formalization.md)
