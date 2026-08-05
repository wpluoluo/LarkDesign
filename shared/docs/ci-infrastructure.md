# LarkDesign 测试与 CI 基础设施

> 创建：2026-08-05
> 目标：建立 HarmonyOS 真机 CI、渲染金样、SBOM、许可证和漏洞扫描

## 一、测试分层

| 层 | 运行环境 | 工具 | 触发条件 | 目标 |
|----|---------|------|---------|------|
| **单元测试** | Node.js (vitest) | vitest + @ohos/hypium | 每次 commit | 共享层算法、Fusion DOM、序列化 |
| **集成测试** | HarmonyOS 模拟器/真机 | hypium + hamock | PR 合并前 | Store、交互、Canvas 渲染 |
| **渲染金样测试** | 跨端 (Node.js 生成参考) | vitest + 像素对比 | 每次 commit | 相同 Fusion DOM 输出一致渲染结果 |
| **E2E 测试** | 真机 | hypium UI 测试 | 发布前 | 完整用户流程 |
| **格式往返测试** | Node.js | vitest | 每次 commit | .hds/SVG/JSON 导入导出无损 |

## 二、质量门禁

1. **依赖图门禁**：检测循环依赖、Feature 横向内部引用、domain 引用 adapter/UI/ArkUI/pgx
2. **契约兼容门禁**：OpenAPI/JSON Schema/Event/C ABI 做 breaking-change 检测
3. **替身测试**：Casdoor、钱包、模型、对象存储、NAPI 均可替换为 fake adapter
4. **渲染隔离测试**：Fusion DOM 金样不含 Skia/ArkUI 类型；相同快照跨端输出落在容差阈值内
5. **依赖许可证扫描**：每个库记录版本、许可证、目标 ABI、HarmonyOS 构建状态、测试覆盖

## 三、CI 配置（GitHub Actions — 模板）

```yaml
# .github/workflows/ci.yml
name: LarkDesign CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - uses: pnpm/action-setup@v2
        with: { version: 10 }
      - run: pnpm install
      - run: pnpm test
      - run: pnpm typecheck
      - run: pnpm build

  # HarmonyOS 构建（需自托管 runner 或 DevEco Cloud）
  harmonyos-build:
    runs-on: self-hosted  # 需安装 DevEco Studio + SDK
    steps:
      - uses: actions/checkout@v4
      - run: hvigor build --mode debug
      - run: hvigor test

  # 依赖许可证扫描
  license-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
        with: { version: 10 }
      - run: pnpm install
      - run: pnpm licenses list  # 或集成 fossa / scancode
```

## 四、SBOM（Software Bill of Materials）

每个关键依赖进入主干前需记录：

| 字段 | 示例 |
|------|------|
| 名称 | Skia |
| 版本 | m131 |
| 许可证 | BSD-3-Clause |
| 目标 ABI | arm64-v8a, x86_64 |
| HarmonyOS 构建验证 | 已通过 DevEco Studio moudle build |
| 测试覆盖 | 矩形/椭圆/文本/位图渲染 |
| 替代方案 | QPainter（Cairo/Qt） |
| 供应链风险 | 低 — Google 维护，活跃社区 |

## 五、渲染金样测试

```
shared/tests/golden/
  ├── rect-simple.png        # 参考输出
  ├── rect-simple.json       # Fusion DOM 输入
  ├── text-simple.png
  ├── text-simple.json
  └── ...
```

金样测试步骤：
1. 从 JSON 构建 Fusion DOM
2. 渲染到 Skia 离屏 buffer
3. 与参考 PNG 逐像素对比（容差阈值 ΔE < 2）
4. 跨端（HarmonyOS / Android / Windows）执行相同测试

## 六、架构冻结验收门槛

```text
1. HarmonyOS 真机完成登录 → /me → 新建文档 → 保存 .hds
2. OpenHarmony 目标设备完成同一流程，且不引入 HMS 私有依赖
3. Go API 通过 issuer/audience/JWKS/nonce/过期校验测试
4. 同一 Command 可由 GUI、CLI、MCP 之一执行并产生日志与可回放结果
5. .hds、SVG、PDF 至少完成一组导入/导出往返和渲染金样对比
6. 关键依赖完成许可证、SBOM、漏洞和 ABI 记录
7. Windows 共享核心的 C ABI 与平台端口完成编译样例
```
