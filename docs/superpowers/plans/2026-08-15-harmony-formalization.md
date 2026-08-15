# HarmonyOS Formalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 LarkDesign 从“Vue 原型 + 未完成鸿蒙骨架”整理为以 HarmonyOS 正式项目为中心、可验证、可持续迁移的工程基线。

**Architecture:** `entry` 提供 ArkUI 外壳和 feature，`domain`/`shared` 提供纯数据与契约，`platform` 负责系统能力，`native` 通过窄 NAPI 接口连接 C++/Skia。Vue 原型冻结为只读参考；所有正式验收以 ArkTS、NAPI、设备和真实文件证据为准。

**Tech Stack:** HarmonyOS ArkTS/ArkUI、Hvigor、CMake/C++、Skia（目标依赖就绪后）、Node.js、pnpm、Vitest、GitHub Actions。

---

### Task 1: 冻结参考原型与仓库边界

**Files:**
- Create: `README.md`
- Create: `原型设计/README.md`
- Modify: `shared/docs/migration-guide.md`
- Modify: `.gitignore`

- [x] 将原型用途、正式目录和禁止发布项写入根 README。
- [x] 在原型目录声明 reference-only，并停止把原型构建当作正式交付证据。
- [x] 将旧迁移指南改为历史记录入口，状态以 `docs/` 为准。
- [x] 忽略 `.arts/`、本机配置、Playwright/IDE 数据和根级证据产物。

### Task 2: 建立正式目录与编码/桥接标准

**Files:**
- Create: `docs/architecture/official-harmony-structure.md`
- Create: `docs/standards/engineering-gates.md`
- Create: `docs/standards/arkts-style.md`
- Create: `docs/standards/native-bridge.md`
- Create: `entry/src/main/ets/app/README.md`
- Create: `entry/src/main/ets/features/README.md`
- Create: `entry/src/main/ets/domain/README.md`
- Create: `entry/src/main/ets/platform/README.md`
- Create: `entry/src/main/ets/native/README.md`

- [x] 固定依赖方向和迁移期旧目录边界。
- [x] 禁止新代码继续进入平铺 `components/stores/types/utils`。
- [x] 记录当前阻断项，不用历史迁移文档中的完成标记替代验证。

### Task 3: 实现自动化正式门禁

**Files:**
- Create: `scripts/verify-formal-project.mjs`
- Create: `scripts/build-harmony.ps1`
- Modify: `package.json`
- Modify: `.github/workflows/ci.yml`

- [x] 检查必需模块、正式文档、备份文件和根级生成物。
- [x] 运行 `git diff --check`，并提供 `--release` 模式扫描占位实现。
- [x] 将参考测试与正式门禁分开命名。
- [x] 增加可选的 Windows/self-hosted HarmonyOS 构建 job；没有自托管 runner 时不伪造通过。

### Task 4: 清理垃圾并修复已确认的 Native 边界错误

**Files:**
- Delete: `_fix_history.py`, `_fix_status.py`, `_update_inspector.py`, `_update_store.py`
- Delete: 根目录历史截图/YAML 和 `build_errors.txt`
- Delete: `entry/src/main/ets/components/FrameView.ets.bak`
- Modify: `napi/src/bridge/napi_register.cpp`
- Modify: `napi/src/bridge/scene_graph.cpp`

- [x] 删除没有引用的临时脚本、截图、Playwright/AppAnalyzer 导出和错误日志；保留 `local.properties`、`.npmrc` 的本机用途并忽略它们。
- [x] 修正 `drawRect` 参数数组越界，缺参时返回错误。
- [x] 让场景图解析失败/未实现明确返回失败，不再固定成功。
- [x] 运行共享测试、正式门禁、`git diff --check`；在依赖为空时如实记录 NAPI/Harmony 构建阻断。

### Task 5: 垂直切片迁移与发布验收

**Files:**
- Modify: `entry/src/main/ets/types/*`, `stores/*`, `utils/*`, `components/*`（按切片迁移）
- Create: `entry/src/main/ets/features/*`, `domain/*`, `platform/*`, `native/*` 实现文件
- Create: 对应 `entry/src/test`、`entry/src/ohosTest` 和 `shared/tests` 测试

- [x] 先迁移 Ability 和主页面入口到 `app/`，为后续文档模型/序列化垂直迁移建立边界。
- [x] 文档模型/序列化、文件持久化和 NAPI 画布已接入正式适配器；后续继续按垂直切片迁移旧平铺目录。
- [ ] 每个切片通过 ArkTS 编译、NAPI ABI 构建、设备流程和真实文件读回后，删除旧平铺文件。
- [ ] 发布前通过新建→编辑→保存→重启恢复→PNG/PDF 导出往返，并附日志/文件哈希证据。
- [x] 完成核心框架与插件化边界审查，第一阶段采用静态内置插件，不执行未知动态代码。

### 验证命令

```text
pnpm test
pnpm typecheck
pnpm verify:formal
pnpm verify:release
pnpm build:harmony
git diff --check
```

当前预期：前四项中的参考测试、类型检查和基础门禁应可运行；`verify:release`、ArkTS 和 NAPI 依赖准备完成前必须保持阻断状态。
