import { execFileSync } from 'node:child_process'
import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const root = process.cwd()
const releaseMode = process.argv.includes('--release')
const required = [
  'entry/src/main/module.json5',
  'entry/build-profile.json5',
  'entry/src/main/ets/app/EntryAbility.ets',
  'entry/src/main/ets/app/pages/Index.ets',
  'napi/CMakeLists.txt',
  'shared/types/scene.ts',
  'docs/architecture/official-harmony-structure.md',
  'docs/standards/engineering-gates.md',
]

const errors = []
for (const file of required) {
  if (!existsSync(join(root, file))) errors.push(`缺少正式项目文件: ${file}`)
}

const forbiddenNames = new Set([
  'build_errors.txt',
  'FrameView.ets.bak',
])
const rootGenerated = /^(after-|workspace-.*\.yaml$|homepage\.yaml$|.*\.png$)/i
for (const entry of readdirSync(root, { withFileTypes: true })) {
  if (entry.isFile() && (forbiddenNames.has(entry.name) || rootGenerated.test(entry.name))) {
    errors.push(`根目录存在生成物或错误日志: ${entry.name}`)
  }
}

function walk(dir) {
  if (!existsSync(dir)) return []
  const files = []
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name)
    if (entry.isDirectory()) files.push(...walk(full))
    else files.push(full)
  }
  return files
}

for (const file of walk(join(root, 'entry/src/main/ets'))) {
  if (file.endsWith('.bak')) errors.push(`正式 ArkTS 目录存在备份文件: ${relative(root, file)}`)
}

try {
  execFileSync('git', ['diff', '--check'], { cwd: root, stdio: 'pipe' })
} catch (error) {
  errors.push(`git diff --check 失败: ${error.stdout?.toString() ?? error.message}`)
}

if (releaseMode) {
  const releaseRoots = [join(root, 'entry/src/main/ets'), join(root, 'napi/src')]
  const releasePatterns = [
    { label: 'TODO 占位', pattern: /TODO/i },
    { label: 'demo 回复', pattern: /demoReply|prototype demo/i },
    { label: '固定成功的场景图实现', pattern: /lark_scene_graph_render[\s\S]*return true;/i },
  ]
  for (const file of releaseRoots.flatMap(walk)) {
    const text = readFileSync(file, 'utf8')
    for (const item of releasePatterns) {
      if (item.pattern.test(text)) errors.push(`${item.label}: ${relative(root, file)}`)
    }
  }
}

if (errors.length > 0) {
  console.error(`正式项目检查失败（${errors.length} 项）`)
  for (const error of errors) console.error(`- ${error}`)
  process.exit(1)
}

console.log(`正式项目检查通过${releaseMode ? '（release 模式）' : ''}`)
