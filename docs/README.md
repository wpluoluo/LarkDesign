# 文档索引

本目录是 LarkDesign 正式文档的唯一权威来源。历史文档只作参考，不构成状态或发布证据。

## 架构（architecture/）

- [正式 HarmonyOS 项目结构](architecture/official-harmony-structure.md) — 交付边界、目录依赖方向和迁移期规则。
- [核心框架与插件化运行时审查](architecture/core-plugin-runtime.md) — 核心/插件边界的结论与依据。

## 工程标准（standards/）

- [工程门禁与发布标准](standards/engineering-gates.md) — 分层门禁、命令和失败处理。
- [ArkTS 编码标准](standards/arkts-style.md) — 目录、类型和错误处理约束。
- [Native Bridge 标准](standards/native-bridge.md) — NAPI 接口边界、句柄与参数校验规则。

## 开发计划（superpowers/plans/）

- [垂直切片迁移与发布验收计划](superpowers/plans/2026-08-16-vertical-slice-migration.md) — 当前主计划：平铺目录迁移切片与发布阻断项闭环。
- [HarmonyOS 正式化实施计划](superpowers/plans/2026-08-15-harmony-formalization.md) — 前一阶段计划，Task 1-4 已完成。

## 迁移参考（reference/）

迁移旧平铺代码时按需对照，不作为完成证据：

- [组件清单与鸿蒙映射](reference/component-inventory.md)
- [交互流程规范](reference/interaction-spec.md)
- [测试与 CI 基础设施](reference/ci-infrastructure.md)

## 历史记录（history/）

只描述过去状态，当前结构以本目录为准：

- [Code Wiki（2026-07-27 代码索引）](history/CODE_WIKI.md)
- [鸿蒙端迁移指南（早期过程）](history/migration-guide.md)
