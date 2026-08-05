/**
 * MCP-style Tools Registry
 *
 * 一个轻量级的 Model Context Protocol 风格的工具注册中心，
 * 让 AI Agent 能够通过工具调用读取/修改 Fusion DOM 文档。
 *
 * - 每个工具有 name / description / inputSchema / handler
 * - handler 接收参数与上下文（fusion store），返回 JSON 结果
 * - 支持 listTools() / callTool(name, args)
 *
 * 与标准 MCP 的差异：本实现运行在浏览器内，作为原型设计阶段的
 * AI 中间件调度层；后续可对接真实的 MCP server（stdio/SSE）。
 */
import type { HdsDocument, Layer, SceneObject } from '../types'
import type { useFusionDocumentStore } from '../stores/fusionDocument'

/** 工具调用上下文：注入 fusion store */
export interface ToolContext {
  fusion: ReturnType<typeof useFusionDocumentStore>
}

/** 工具的 JSON Schema 输入定义（简化版） */
export interface ToolInputSchema {
  type: 'object'
  properties: Record<string, unknown>
  required?: string[]
}

/** 工具定义 */
export interface Tool {
  name: string
  description: string
  inputSchema: ToolInputSchema
  handler: (args: Record<string, unknown>, ctx: ToolContext) => Promise<ToolResult> | ToolResult
}

/** 工具调用结果 */
export interface ToolResult {
  ok: boolean
  data?: unknown
  message?: string
}

/** 工具调用错误 */
export class ToolError extends Error {
  constructor(message: string, public readonly code: string = 'TOOL_ERROR') {
    super(message)
    this.name = 'ToolError'
  }
}

// ─────────────────────────────────────────────────
// 工具实现
// ─────────────────────────────────────────────────

const tools: Tool[] = [
  /* ═════════ Canvas ═════════ */
  {
    name: 'canvas.read',
    description: '读取整个画布文档（Fusion DOM）的完整 JSON。无参数。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      const doc: HdsDocument = ctx.fusion.doc
      return { ok: true, data: doc, message: `已读取 · ${ctx.fusion.scene.name}` }
    },
  },
  {
    name: 'canvas.info',
    description: '获取画布摘要信息：尺寸、图层数、对象数等。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      const info = ctx.fusion.sceneInfo
      return { ok: true, data: info }
    },
  },
  {
    name: 'canvas.resize',
    description: '调整画布尺寸。',
    inputSchema: {
      type: 'object',
      properties: {
        width: { type: 'number', description: '新画布宽度' },
        height: { type: 'number', description: '新画布高度' },
      },
      required: ['width', 'height'],
    },
    handler: (args, ctx) => {
      const w = Number(args.width)
      const h = Number(args.height)
      if (!Number.isFinite(w) || !Number.isFinite(h) || w <= 0 || h <= 0) {
        throw new ToolError('width/height 必须为正数', 'INVALID_ARGS')
      }
      ctx.fusion.scene.canvasWidth = w
      ctx.fusion.scene.canvasHeight = h
      return { ok: true, message: `画布已调整为 ${w}×${h}` }
    },
  },
  {
    name: 'canvas.background',
    description: '设置画布背景色。',
    inputSchema: {
      type: 'object',
      properties: {
        color: { type: 'string', description: '十六进制颜色，如 #FFFFFF' },
      },
      required: ['color'],
    },
    handler: (args, ctx) => {
      const color = String(args.color ?? '')
      if (!/^#([0-9a-fA-F]{3,8})$/.test(color)) {
        throw new ToolError('color 必须为有效的十六进制颜色', 'INVALID_ARGS')
      }
      ctx.fusion.scene.background = color
      return { ok: true, message: `画布背景已设为 ${color}` }
    },
  },

  /* ═════════ Layer ═════════ */
  {
    name: 'layer.list',
    description: '列出所有图层及其对象摘要。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      const list = ctx.fusion.layers.map((l: Layer) => ({
        id: l.id,
        name: l.name,
        visible: l.visible,
        locked: l.locked,
        blendMode: l.blendMode,
        opacity: l.transform.opacity,
        objectCount: l.objects.length,
        objects: l.objects.map(o => ({ id: o.id, name: o.name, type: o.type })),
      }))
      return { ok: true, data: list }
    },
  },
  {
    name: 'layer.create',
    description: '新建图层。',
    inputSchema: {
      type: 'object',
      properties: {
        name: { type: 'string', description: '图层名称（可选）' },
      },
    },
    handler: (args, ctx) => {
      const name = args.name ? String(args.name) : undefined
      const layer = ctx.fusion.newLayer(name)
      return { ok: true, data: { id: layer.id, name: layer.name }, message: `已新建图层 ${layer.name}` }
    },
  },
  {
    name: 'layer.delete',
    description: '删除图层。',
    inputSchema: {
      type: 'object',
      properties: { layerId: { type: 'string' } },
      required: ['layerId'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      ctx.fusion.deleteLayer(layerId)
      return { ok: true, message: `已删除图层 ${layerId}` }
    },
  },
  {
    name: 'layer.modify',
    description: '修改图层属性：name/visible/locked/blendMode/opacity。',
    inputSchema: {
      type: 'object',
      properties: {
        layerId: { type: 'string' },
        name: { type: 'string' },
        visible: { type: 'boolean' },
        locked: { type: 'boolean' },
        opacity: { type: 'number' },
      },
      required: ['layerId'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      const layer = ctx.fusion.layers.find((l: Layer) => l.id === layerId)
      if (!layer) throw new ToolError(`图层 ${layerId} 不存在`, 'NOT_FOUND')
      if (typeof args.name === 'string') ctx.fusion.renameLayer(layerId, String(args.name))
      if (typeof args.visible === 'boolean') layer.visible = args.visible
      if (typeof args.locked === 'boolean') layer.locked = args.locked
      if (typeof args.opacity === 'number') layer.transform.opacity = Math.max(0, Math.min(100, args.opacity))
      return { ok: true, message: `已修改图层 ${layer.name}` }
    },
  },

  /* ═════════ Object ═════════ */
  {
    name: 'object.create',
    description: '在指定图层中新建对象。type 可为 text/shape/image。',
    inputSchema: {
      type: 'object',
      properties: {
        layerId: { type: 'string' },
        type: { type: 'string', enum: ['text', 'shape', 'image'] },
        params: { type: 'object', description: '对象参数（位置/尺寸/文本/颜色等）' },
      },
      required: ['layerId', 'type'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      const type = String(args.type ?? '') as SceneObject['type']
      const params = (args.params ?? {}) as Record<string, unknown>
      const obj = ctx.fusion.newObject(layerId, type, params as never)
      if (!obj) throw new ToolError(`创建对象失败 · 图层 ${layerId}`, 'CREATE_FAILED')
      return { ok: true, data: { id: obj.id, name: obj.name, type: obj.type }, message: `已新建 ${type} 对象` }
    },
  },
  {
    name: 'object.delete',
    description: '删除图层中的对象。',
    inputSchema: {
      type: 'object',
      properties: { layerId: { type: 'string' }, objectId: { type: 'string' } },
      required: ['layerId', 'objectId'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      const objectId = String(args.objectId ?? '')
      ctx.fusion.deleteObject(layerId, objectId)
      return { ok: true, message: `已删除对象 ${objectId}` }
    },
  },
  {
    name: 'object.list',
    description: '列出指定图层中所有对象。',
    inputSchema: {
      type: 'object',
      properties: { layerId: { type: 'string' } },
      required: ['layerId'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      const layer = ctx.fusion.layers.find((l: Layer) => l.id === layerId)
      if (!layer) throw new ToolError(`图层 ${layerId} 不存在`, 'NOT_FOUND')
      return { ok: true, data: layer.objects }
    },
  },
  {
    name: 'object.modify',
    description: '修改对象属性。支持 text/shape/image 的通用属性（x/y/width/height/name/visible/locked）与各自特有属性。',
    inputSchema: {
      type: 'object',
      properties: {
        layerId: { type: 'string' },
        objectId: { type: 'string' },
        props: { type: 'object', description: '要修改的属性键值对' },
      },
      required: ['layerId', 'objectId', 'props'],
    },
    handler: (args, ctx) => {
      const layerId = String(args.layerId ?? '')
      const objectId = String(args.objectId ?? '')
      const props = (args.props ?? {}) as Record<string, unknown>
      const layer = ctx.fusion.layers.find((l: Layer) => l.id === layerId)
      if (!layer) throw new ToolError(`图层 ${layerId} 不存在`, 'NOT_FOUND')
      const obj = layer.objects.find(o => o.id === objectId)
      if (!obj) throw new ToolError(`对象 ${objectId} 不存在`, 'NOT_FOUND')
      ctx.fusion.pushHistory('AI 修改对象')
      const record = obj as unknown as Record<string, unknown>
      const transformKeys = new Set(['x', 'y', 'width', 'height', 'rotation', 'opacity'])
      for (const [k, v] of Object.entries(props)) {
        if (transformKeys.has(k)) {
          ;(obj.transform as unknown as Record<string, unknown>)[k] = v
        } else if (k in record) {
          record[k] = v
        }
      }
      return { ok: true, message: `已修改对象 ${obj.name}` }
    },
  },

  /* ═════════ Selection ═════════ */
  {
    name: 'selection.set',
    description: '设置当前选中图层。',
    inputSchema: {
      type: 'object',
      properties: { layerId: { type: 'string' } },
    },
    handler: (args, ctx) => {
      const layerId = args.layerId ? String(args.layerId) : null
      ctx.fusion.selectLayer(layerId)
      return { ok: true, message: layerId ? `已选中图层 ${layerId}` : '已取消选中' }
    },
  },
  {
    name: 'selection.list',
    description: '获取当前选中的图层 ID 与对象 ID 列表。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      return {
        ok: true,
        data: {
          layerId: ctx.fusion.selectedLayerId,
          objectIds: ctx.fusion.selectedObjectIds,
        },
      }
    },
  },

  /* ═════════ History ═════════ */
  {
    name: 'history.undo',
    description: '撤销上一步操作。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      if (!ctx.fusion.canUndo) return { ok: false, message: '无可撤销操作' }
      ctx.fusion.undo()
      return { ok: true, message: '已撤销' }
    },
  },
  {
    name: 'history.redo',
    description: '重做最近撤销的操作。',
    inputSchema: { type: 'object', properties: {} },
    handler: (_args, ctx) => {
      if (!ctx.fusion.canRedo) return { ok: false, message: '无可重做操作' }
      ctx.fusion.redo()
      return { ok: true, message: '已重做' }
    },
  },

  /* ═════════ Export ═════════ */
  {
    name: 'export.render',
    description: '渲染画布并导出为指定格式。format 可为 png/jpeg/webp/svg/json。',
    inputSchema: {
      type: 'object',
      properties: {
        format: { type: 'string', enum: ['png', 'jpeg', 'webp', 'svg', 'json'] },
        scale: { type: 'number', description: '缩放倍率（默认 1）' },
      },
      required: ['format'],
    },
    handler: async (args, ctx) => {
      const format = String(args.format ?? 'png') as 'png' | 'jpeg' | 'webp' | 'svg' | 'json'
      const scale = typeof args.scale === 'number' ? args.scale : 1
      // 简化版：直接导出文档 JSON
      if (format === 'json') {
        const json = ctx.fusion.exportToJson()
        return { ok: true, data: json, message: '已导出 HDS JSON' }
      }
      // TODO: 接入 Canvas 渲染引擎的 toDataURL
      const info = ctx.fusion.sceneInfo
      return {
        ok: true,
        message: `已导出 ${format.toUpperCase()} · ${info.canvasSize} × ${scale}（演示）`,
        data: { format, scale, size: info.canvasSize },
      }
    },
  },
]

// ─────────────────────────────────────────────────
// Registry API
// ─────────────────────────────────────────────────

/** 列出所有工具的元信息（不含 handler） */
export function listTools(): Array<Omit<Tool, 'handler'>> {
  return tools.map(({ handler: _handler, ...meta }) => meta)
}

/** 查找工具 */
export function findTool(name: string): Tool | undefined {
  return tools.find(t => t.name === name)
}

/** 调用工具 */
export async function callTool(
  name: string,
  args: Record<string, unknown>,
  ctx: ToolContext,
): Promise<ToolResult> {
  const tool = findTool(name)
  if (!tool) throw new ToolError(`工具 ${name} 未注册`, 'TOOL_NOT_FOUND')
  try {
    return await tool.handler(args, ctx)
  } catch (err) {
    if (err instanceof ToolError) return { ok: false, message: err.message }
    return { ok: false, message: `工具 ${name} 执行失败：${(err as Error).message}` }
  }
}

/** 工具调用日志条目 */
export interface ToolCallLog {
  id: string
  name: string
  args: Record<string, unknown>
  result: ToolResult
  timestamp: number
  durationMs: number
}

/** 创建工具调用日志（用于 UI 展示） */
export function createToolCallLog(
  name: string,
  args: Record<string, unknown>,
  result: ToolResult,
  durationMs: number,
): ToolCallLog {
  return {
    id: `tc_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
    name,
    args,
    result,
    timestamp: Date.now(),
    durationMs,
  }
}
