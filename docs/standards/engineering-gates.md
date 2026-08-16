# 工程门禁与发布标准

## 1. 分层门禁

| 门禁 | 命令/证据 | 适用范围 | 失败处理 |
| --- | --- | --- | --- |
| 共享测试 | `pnpm test` | 每次提交 | 修复后才能合并 |
| Harmony 本地单元测试 | `pnpm test:harmony` | 修改正式 ArkTS 纯逻辑时 | ArkTS 编译或 Hypium 测试结果失败即阻断 |
| 参考工程类型检查 | `pnpm typecheck` | 仅参考原型回归 | 不得宣称鸿蒙通过 |
| 正式结构检查 | `pnpm verify:formal` | 每次提交 | 清理垃圾或修正文档边界 |
| ArkTS 编译 | `pnpm build:harmony` / DevEco 等价命令 | 正式 PR、发布 | 记录完整编译错误 |
| Native 构建 | NAPI CMake + 目标 ABI | 正式 PR、发布 | 缺依赖或 ABI 不匹配即阻断 |
| 静态检查 | `code-linter.json5` 对全部正式 ETS | 正式 PR、发布 | 禁止占位 lint 脚本 |
| 差异检查 | `git diff --check` | 每次提交 | 修复空白和冲突标记 |
| 设备验收 | 新建→编辑→保存→导出→重启恢复 | 发布 | 没有真实文件/日志不得放行 |

## 2. 发布阻断项

以下任一项存在，状态只能是“未完成/阻塞”，不能标记 release-ready：

- ArkTS 或 NAPI 构建失败。
- 功能函数以 `TODO`、空实现、`demo` 回复、固定成功值或伪造文件结果结束。
- 画布仍由 ArkUI 占位组件绘制，或 NAPI 没有被正式页面调用。
- 文档保存只存在于 `AppStorage`，重启后无法恢复。
- 导出按钮报告成功但没有可读的 PNG/PDF/EPS/CDR 文件或字节数据。
- BYOK 等配置的 UI 字段与存储模型不一致，或 `save()` 不持久化。
- 发布门禁只运行 Vue 原型构建而没有 ArkTS/NAPI 证据。

## 3. 变更要求

- 每个功能变更必须同时提供单元/集成测试和失败证据；禁止先改实现再补“通过”截图。
- 共享契约先变更，平台适配器后实现；不允许在 ArkTS、Vue 和 C++ 中各自推导不同字段。
- 不引入 fallback、兼容双写或静默降级来隐藏真实错误。错误必须携带稳定 code 并在边界处转换。
- 新依赖须登记版本、许可证、目标 ABI、构建证据、测试覆盖和替代方案。
- 合并前不得提交构建缓存、IDE 数据库、截图、Playwright 导出、错误日志、备份文件或本机 SDK 路径。

## 4. 当前基线

截至 2026-08-16，DevEco Studio `D:\DevEco Studio`、Hvigor/OHOS 插件 `6.22.4`、SDK `6.0.2` 已统一；`pnpm build:harmony` 已完成 Native arm64-v8a/x86_64、ArkTS 编译和未签名 HAP 打包，`pnpm test:harmony` 已接入并编译/生成 ArkTS 本地测试结果。PNG/JPEG/WebP/PDF 的代码链路已在写回后校验长度、SHA-256 和格式结构；签名、真实设备文件读回、外部 PDF 解析与重启恢复仍是发布前阻断项，计划见 [开发计划](../superpowers/plans/2026-08-16-vertical-slice-migration.md)。
