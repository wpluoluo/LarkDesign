# Vertical Slice Migration & Release Acceptance Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成旧平铺目录（`types/stores/utils/components/data/tokens`）到正式边界的垂直切片迁移，并补齐发布阻断项：重启恢复、导出真实文件读回、签名与发布往返证据。接续 [2026-08-15 正式化计划](2026-08-15-harmony-formalization.md) Task 5 的剩余事项。

**Architecture:** 依赖方向固定为 `app → features → domain → platform → native → shared`。领域模型与序列化进 `domain/`；工具/面板/AI 等特性进 `features/`；系统能力进 `platform/`；C++ 桥接进 `native/`。每个切片必须在 ArkTS 编译、Native ABI 构建、设备流程和真实文件读回全部通过后才允许删除旧平铺文件；发布证据必须是日志、文件哈希或设备截图，不得以原型构建结果替代。

**Tech Stack:** HarmonyOS ArkTS/ArkUI、Hvigor 6.22.4、SDK 6.0.2、CMake/C++（NAPI）、Node.js、pnpm、Vitest、GitHub Actions。

---

### Task 1: 重启恢复闭环（发布阻断项）

**Files:**
- Modify: `entry/src/main/ets/platform/FilePersistence.ets`
- Modify: `entry/src/main/ets/domain/FusionDocumentStore.ets`
- Create: `entry/src/test` 对应持久化用例（LocalUnit）
- Modify: `docs/standards/engineering-gates.md`（完成后更新基线）

- [x] 文档保存写入真实沙箱文件（非仅 `AppStorage`），路径与错误码记录在案。（2026-08-16：`PersistenceTypes` 固定错误码契约，读写日志含 path/bytes/checksum；UTF-8 字节级校验写入完整性）
- [ ] 设备上完成：新建→编辑→保存→杀进程→重启→内容恢复，附日志与文件哈希。（阻断：本机 `hdc list targets` 为空，无设备/模拟器；代码侧已修复恢复竞态——`init` 不再在异步读取完成前 `pushHistory` 触发自动保存，`read-io`/反序列化失败时禁用自动保存防止覆盖磁盘内容）
- [x] 失败路径（磁盘满/权限拒绝）返回明确错误并提示，不静默丢失。（2026-08-16：`not-found` 与 `read-io` 分类；`hds_save_status`/`hds_save_error` 上浮 UI；`clearStorage` 真正删除沙箱文件）

### Task 2: 导出真实文件读回（发布阻断项）

**Files:**
- Modify: `entry/src/main/ets/utils/Exporter.ets`
- Modify: `napi/src/render/canvas_renderer.cpp`（如导出需要补充像素回读）
- Modify: `entry/src/main/ets/native/NativeEngine.ets`
- Create: 导出往返测试（`entry/src/ohosTest` 设备用例）

- [x] 代码链路：PNG/JPEG/WebP 写出后重新读回，校验字节数、源/磁盘 SHA-256 与格式魔数；本地 ArkTS 用例覆盖格式魔数。
- [x] 代码链路：PDF 使用 UTF-8 字节偏移生成 xref，写出后校验 SHA-256、`startxref`、页对象和页数；本地 ArkTS 用例覆盖 xref 偏移损坏。
- [x] 代码链路：HDS/JSON/SVG 写出后重新读回，校验文本一致性、JSON/SVG 结构与精确 UTF-8 字节 SHA-256；本地 ArkTS 用例覆盖非法 JSON、缺失 XML 声明和 SVG 闭合标签。（2026-08-19）
- [x] 导出失败必须返回错误，禁止“报告成功但无文件”。（2026-08-16：写回、哈希、魔数或 PDF 结构任一失败均返回 `ok: false`。）
- [ ] 设备验收：拉取 PNG/PDF，核对主机 SHA-256，并使用外部 PDF 解析器读取页数。（阻断：本机 `hdc list targets` 为 `[Empty]`。）

### Task 3: 签名与 HAP 发布件（发布阻断项）

**Files:**
- Modify: `build-profile.json5`（签名配置占位，密钥不入库）
- Modify: `scripts/build-harmony.ps1`

- [ ] 配置调试/发布签名，产出已签名 HAP，记录构建日志。
- [ ] 签名材料与密码只存在于本机 `local.properties` 类文件中并保持 gitignore。

### Task 4: 领域切片迁移（types → domain）

**Files:**
- Moved: `entry/src/main/ets/domain/SceneTypes.ets`、`FusionSerializer.ets`、`FusionOps.ets`、`FusionFactory.ets`
- Moved: `entry/src/main/ets/native/liblark_engine.d.ts`
- Modified: `docs/standards/native-bridge.md`（d.ts 新路径）
- Deleted: `entry/src/main/ets/types/`

- [x] 序列化/算法用例补入 `entry/src/test`，先测试后迁移。（2026-08-19：先由 `domain/` 入口导入确认模块缺失编译失败，再覆盖文档往返、图层/对象操作与画板边界算法。）
- [x] 迁移后 ArkTS 编译、`pnpm test`、`pnpm verify:formal` 全绿，再删除旧 `types/` 目录。（2026-08-19）

### Task 5: 状态切片迁移（stores → domain / features）

**Files:**
- Move: `FusionDocumentStore`、`LayerStore`、`LayerBlendStore`（文档状态）→ `domain/`
- Move: `ToolStore`、`ColorStore`、`ThemeStore`、`ToastStore`、`BYOKStore`（UI/特性状态）→ `features/*`
- Delete: 旧平铺状态目录（全部迁空后）

- [x] 单例与初始化顺序保持行为不变，`app/pages/Index.ets` 仍是唯一组装点。（2026-08-19：初始化顺序保持 `Theme → Document → FusionDocument → BYOK → Tool → Color → Toast → Layer` 不变。）
- [x] 已删除旧平铺状态目录，不保留兼容 re-export 或旧路径；`FusionDocumentStore`、`FusionDocumentStoreInfo`、`DocumentStore`、`LayerStore`、`LayerBlendStore` 迁入 `domain/`，`ToolStore`、`ColorStore`、`ThemeStore`、`ToastStore`、`BYOKStore` 分别迁入对应特性 `state/` 目录。（2026-08-19）
- [x] 迁移测试证据：先在 `LocalUnit.test.ets` 由未来 `domain/` 与 `features/*/state/` 路径导入并运行 `pnpm test:harmony`，确认因十个目标模块不存在而在 `UnitTestArkTS` 失败；移动后同一命令 `BUILD SUCCESSFUL`，覆盖工具/颜色主题状态、领域文档与图层入口、Toast/BYOK 无初始化入口。最终自动化验证通过：`pnpm test`（18/18）、`pnpm test:harmony`、`pnpm verify:formal`、`pnpm verify:release`、`git diff --check`；随后 Hvigor clean 后的 `pnpm build:harmony` 重新编译 ArkTS 并成功打包 HAP。（2026-08-19）
- [ ] 真机/模拟器冒烟：本机无可用设备或模拟器，未执行设备流程，不能作为迁移完成证据。（阻断：`hdc list targets` 无目标。）

### Task 6: 工具与组件归组（utils / components / data / tokens → features）

**Files:**
- Create: `features/workspace`、`features/canvas`、`features/inspector`、`features/color`、`features/export`、`features/ai`、`features/common`
- Move: `utils/` 中的用例（Exporter、ShapeDrawingEngine、AiAgent、MCPRegistry 等）按归属拆入 features 或 domain
- Move: `components/` 42 个组件按特性归组；`data/`、`tokens/` 随组件归属
- Delete: 旧平铺目录（全部迁空后）

- [ ] 每个特性目录一次迁移+一次设备冒烟，禁止一次性大搬迁。
- [x] 颜色切片：`ColorBar`、颜色选择器和颜色系统组件以及颜色换算工具迁入 `features/color/`；由工作区和检查器通过特性入口引用，新增正式门禁禁止向旧平铺目录新增文件。（2026-08-19）
- [x] AI 切片：BYOK 配置弹窗、AI 助手/检查器面板、`AiAgent` 与 `MCPRegistry` 迁入 `features/ai/`；配置弹窗接入检查器，移除会伪报导出成功的 `export.render` 工具。（2026-08-19）
- [ ] 迁移完成后 `entry/src/main/ets/` 顶层只剩 `app/domain/features/platform/native` 四类正式目录与 README。
- [x] `verify:formal` 增加规则：新提交不得再向平铺目录添加文件。（2026-08-19）

### Task 7: 发布往返验收

- [ ] 设备全流程：新建→编辑→保存→重启恢复→PNG/PDF 导出，每步附日志/哈希证据。
- [ ] `pnpm verify:release` 通过（无 TODO/占位/固定成功实现，`.so` 存在）。
- [ ] 更新 `engineering-gates.md` 基线与两个计划文档的勾选状态。

### 验证命令

```text
pnpm test
pnpm test:harmony
pnpm verify:formal
pnpm verify:release
pnpm build:harmony
git diff --check
```

当前预期：`build:harmony` 在本机 DevEco 环境可完成 Native 双 ABI + ArkTS 编译 + HAP 打包；`verify:release` 在 Task 1-3 完成前保持阻断状态。
