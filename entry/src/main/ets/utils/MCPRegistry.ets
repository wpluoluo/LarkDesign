/**
 * MCPRegistry - MCP 工具注册中心
 *
 * 对应原型 src/ai/mcp.ts
 * 轻量级 MCP 风格工具注册中心，让 AI Agent 通过工具调用操作 Fusion DOM。
 */
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { SceneObject, Transform, BlendMode, NodeType, HdsDocument, Layer } from '../types/SceneTypes'
import { findObjectInDoc, addLayer } from '../types/FusionOps'

export interface ToolResult {
  ok: boolean
  data?: string
  message?: string
}

export class ToolError extends Error {
  code: string
  constructor(message: string, code: string = 'TOOL_ERROR') {
    super(message)
    this.code = code
  }
}

export interface ToolDef {
  name: string
  description: string
  inputSchema: string
}

export type ToolHandler = (args: Record<string, string>, store: FusionDocumentStore) => ToolResult

export interface ToolCallLog {
  id: string
  name: string
  args: string
  result: string
  timestamp: number
  durationMs: number
}

const toolNames: string[] = []
const toolDescs: string[] = []
const toolSchemas: string[] = []
const toolHandlers: ToolHandler[] = []

function genId(): string {
  const now = Date.now().toString(36)
  const rand = Math.floor(Math.random() * 100000).toString(36)
  return `tc_${now}_${rand}`
}

function register(name: string, description: string, inputSchema: string, handler: ToolHandler): void {
  toolNames.push(name)
  toolDescs.push(description)
  toolSchemas.push(inputSchema)
  toolHandlers.push(handler)
}

register('canvas.read', '读取整个画布文档的完整 JSON。无参数。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const doc = store.getDocument()
    const r: ToolResult = { ok: true, data: JSON.stringify(doc), message: '已读取文档' }
    return r
  })

register('canvas.info', '获取画布摘要信息：尺寸、图层数、对象数等。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const frame = store.getCurrentFrame()
    const layers = store.getCurrentLayers()
    const frameData = frame ? ('{"id":"' + frame.id + '","name":"' + frame.name + '","width":' + frame.width + ',"height":' + frame.height + '}') : 'null'
    const info = '{"frame":' + frameData + ',"layerCount":' + layers.length + '}'
    const r: ToolResult = { ok: true, data: info, message: '已读取画布信息' }
    return r
  })

register('canvas.resize', '调整画布尺寸。', '{"type":"object","properties":{"width":{"type":"number"},"height":{"type":"number"}},"required":["width","height"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const w = Number(args['width'] ?? 0)
    const h = Number(args['height'] ?? 0)
    if (!isFinite(w) || !isFinite(h) || w <= 0 || h <= 0) {
      const r: ToolResult = { ok: false, message: 'width/height 必须为正数' }
      return r
    }
    const scene = store.getScene()
    scene.canvasWidth = w
    scene.canvasHeight = h
    const r: ToolResult = { ok: true, message: `画布已调整为 ${w}×${h}` }
    return r
  })

register('canvas.background', '设置画布背景色。', '{"type":"object","properties":{"color":{"type":"string"}},"required":["color"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const color = args['color'] ?? ''
    const scene = store.getScene()
    scene.background = color
    const r: ToolResult = { ok: true, message: `画布背景已设为 ${color}` }
    return r
  })

register('layer.list', '列出所有图层及其对象摘要。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const allLayers = store.getCurrentLayers()
    const items: string[] = []
    for (let i = 0; i < allLayers.length; i++) {
      const l = allLayers[i]
      items.push('{"id":"' + l.id + '","name":"' + l.name + '","visible":' + l.visible + '}')
    }
    const r: ToolResult = { ok: true, data: '[' + items.join(',') + ']', message: '已列出图层' }
    return r
  })

register('layer.create', '新建图层。', '{"type":"object","properties":{"name":{"type":"string"}}}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const name = args['name'] ?? 'AI 新图层'
    const doc = store.getDocument()

    const layer = addLayer(doc)
    layer.name = name
    const r: ToolResult = { ok: true, data: '{"id":"' + layer.id + '","name":"' + layer.name + '"}', message: '已新建图层 ' + layer.name }
    return r
  })

register('layer.delete', '删除图层。', '{"type":"object","properties":{"layerId":{"type":"string"}},"required":["layerId"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const layerId = args['layerId'] ?? ''
    const layers = store.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      if (layers[i].id === layerId) {
        layers.splice(i, 1)
        const r: ToolResult = { ok: true, message: '已删除图层 ' + layerId }
        return r
      }
    }
    const r: ToolResult = { ok: false, message: '图层 ' + layerId + ' 不存在' }
    return r
  })

register('layer.modify', '修改图层属性。支持 name/visible/locked/blendMode。', '{"type":"object","properties":{"layerId":{"type":"string"},"name":{"type":"string"},"visible":{"type":"boolean"},"locked":{"type":"boolean"}},"required":["layerId"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const layerId = args['layerId'] ?? ''
    const layers = store.getCurrentLayers()
    let found = false
    for (let i = 0; i < layers.length; i++) {
      if (layers[i].id === layerId) {
        const l = layers[i]
        const nameVal = args['name']
        const visibleVal = args['visible']
        const lockedVal = args['locked']
        if (nameVal !== undefined) l.name = nameVal
        if (visibleVal !== undefined) l.visible = visibleVal === 'true'
        if (lockedVal !== undefined) l.locked = lockedVal === 'true'
        found = true
        break
      }
    }
    if (!found) {
      const r: ToolResult = { ok: false, message: '图层 ' + layerId + ' 不存在' }
      return r
    }
    const r: ToolResult = { ok: true, message: '已修改图层 ' + layerId }
    return r
  })

/* ═════════ Object ═════════ */

register('object.create', '在指定图层中新建对象。type 为 text/shape/image。', '{"type":"object","properties":{"layerId":{"type":"string"},"type":{"type":"string"},"name":{"type":"string"},"x":{"type":"number"},"y":{"type":"number"},"width":{"type":"number"},"height":{"type":"number"}},"required":["layerId","type"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const layerId = args['layerId'] ?? ''
    const objType = args['type'] ?? 'shape'
    const obj: SceneObject = {
      id: 'ai_' + Date.now().toString(36),
      type: objType as NodeType,
      name: args['name'] ?? 'AI 对象',
      visible: true,
      locked: false,
      blendMode: 'normal' as BlendMode,
      transform: {
        x: Number(args['x'] ?? 100),
        y: Number(args['y'] ?? 100),
        width: Number(args['width'] ?? 100),
        height: Number(args['height'] ?? 100),
        rotation: 0, scaleX: 1, scaleY: 1,
        flipH: false, flipV: false, opacity: 100,
      } as Transform,
      fill: '#3AC487',
      stroke: '#1F2329',
      strokeWidth: 0,
      cornerRadius: 0,
      sides: 5,
    }
    store.newObject(obj, layerId)
    const r: ToolResult = { ok: true, data: obj.id, message: `已创建 ${objType} 对象` }
    return r
  })

register('object.delete', '删除图层中的对象。', '{"type":"object","properties":{"objectId":{"type":"string"}},"required":["objectId"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const objectId = args['objectId'] ?? ''
    store.removeObjectById(objectId)
    const r: ToolResult = { ok: true, message: `已删除对象 ${objectId}` }
    return r
  })

register('object.modify', '修改对象属性。支持 x/y/width/height/rotation/opacity/fill/stroke/strokeWidth/name/visible/locked。', '{"type":"object","properties":{"objectId":{"type":"string"},"props":{"type":"object"}},"required":["objectId","props"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const objectId = args['objectId'] ?? ''
    const found = findObjectInDoc(store.getDocument(), objectId)
    if (!found) {
      const r: ToolResult = { ok: false, message: `对象 ${objectId} 不存在` }
      return r
    }
    const propsStr = args['props'] ?? '{}'
    let props: Record<string, string> = {}
    try {
      props = JSON.parse(propsStr) as Record<string, string>
    } catch (_e) {
      const r: ToolResult = { ok: false, message: 'props 格式错误' }
      return r
    }
    store.pushHistory('AI 修改对象')
    const obj = found.obj
    const xVal = props['x']
    const yVal = props['y']
    const wVal = props['width']
    const hVal = props['height']
    if (xVal !== undefined) store.updateObjectTransform(objectId, Number(xVal))
    if (yVal !== undefined && xVal === undefined) store.updateObjectTransform(objectId, undefined, Number(yVal))
    if (xVal !== undefined && yVal !== undefined) store.updateObjectTransform(objectId, Number(xVal), Number(yVal))
    if (wVal !== undefined) obj.transform.width = Number(wVal)
    if (hVal !== undefined) obj.transform.height = Number(hVal)
    const fillVal = props['fill']
    const strokeVal = props['stroke']
    const swVal = props['strokeWidth']
    const nameVal = props['name']
    const visibleVal = props['visible']
    const lockedVal = props['locked']
    if (fillVal !== undefined) obj.fill = fillVal
    if (strokeVal !== undefined) obj.stroke = strokeVal
    if (swVal !== undefined) obj.strokeWidth = Number(swVal)
    if (nameVal !== undefined) obj.name = nameVal
    if (visibleVal !== undefined) obj.visible = visibleVal === 'true'
    if (lockedVal !== undefined) obj.locked = lockedVal === 'true'
    const r: ToolResult = { ok: true, message: `已修改对象 ${obj.name}` }
    return r
  })

register('object.list', '列出指定图层中所有对象。', '{"type":"object","properties":{"layerId":{"type":"string"}},"required":["layerId"]}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const layerId = args['layerId'] ?? ''
    const layers = store.getCurrentLayers()
    let objects: string = '[]'
    for (let i = 0; i < layers.length; i++) {
      if (layers[i].id === layerId) {
        const items: string[] = []
        for (let j = 0; j < layers[i].objects.length; j++) {
          const o = layers[i].objects[j]
          items.push('{"id":"' + o.id + '","name":"' + o.name + '","type":"' + o.type + '"}')
        }
        objects = '[' + items.join(',') + ']'
        break
      }
    }
    const r: ToolResult = { ok: true, data: objects, message: '已列出对象' }
    return r
  })

/* ═════════ History ═════════ */

register('history.undo', '撤销上一步操作。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    if (!store.canUndo()) {
      const r: ToolResult = { ok: false, message: '无可撤销操作' }
      return r
    }
    store.undo()
    const r: ToolResult = { ok: true, message: '已撤销' }
    return r
  })

register('history.redo', '重做最近撤销的操作。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    if (!store.canRedo()) {
      const r: ToolResult = { ok: false, message: '无可重做操作' }
      return r
    }
    store.redo()
    const r: ToolResult = { ok: true, message: '已重做' }
    return r
  })

/* ═════════ Selection ═════════ */

register('selection.set', '设置当前选中对象。', '{"type":"object","properties":{"objectId":{"type":"string"}}}',
  (args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const objectId = args['objectId'] ?? ''
    store.selectObject(objectId)
    const r: ToolResult = { ok: true, message: objectId ? `已选中对象 ${objectId}` : '已取消选中' }
    return r
  })

register('selection.list', '获取当前选中的对象 ID 列表。', '{}',
  (_args: Record<string, string>, store: FusionDocumentStore): ToolResult => {
    const sel = store.getSelectedObjects()
    const ids: string[] = []
    for (let i = 0; i < sel.length; i++) {
      ids.push(sel[i].id)
    }
    const r: ToolResult = { ok: true, data: JSON.stringify(ids), message: '已获取选中列表' }
    return r
  })

/* ═════════ Export ═════════ */

register('export.render', '渲染画布并导出为指定格式。format 可为 png/jpeg/json。', '{"type":"object","properties":{"format":{"type":"string","enum":["png","jpeg","json"]}},"required":["format"]}',
  (args: Record<string, string>, _store: FusionDocumentStore): ToolResult => {
    const format = args['format'] ?? 'png'
    const r: ToolResult = { ok: true, message: `已导出 ${format.toUpperCase()}（演示）`, data: '{"format":"' + format + '"}' }
    return r
  })

export function getToolCount(): number {
  return toolNames.length
}

export function getToolAt(index: number): ToolDef {
  const t: ToolDef = {
    name: toolNames[index],
    description: toolDescs[index],
    inputSchema: toolSchemas[index],
  }
  return t
}

export function callTool(name: string, args: Record<string, string>, store: FusionDocumentStore): ToolResult {
  for (let i = 0; i < toolNames.length; i++) {
    if (toolNames[i] === name) {
      try {
        return toolHandlers[i](args, store)
      } catch (err) {
        const msg = (err as Error).message
        const r: ToolResult = { ok: false, message: `工具 ${name} 执行失败：${msg}` }
        return r
      }
    }
  }
  const r: ToolResult = { ok: false, message: `工具 ${name} 未注册` }
  return r
}

export function createToolCallLog(name: string, args: Record<string, string>, result: ToolResult, durationMs: number): ToolCallLog {
  const log: ToolCallLog = {
    id: genId(),
    name,
    args: JSON.stringify(args),
    result: JSON.stringify(result),
    timestamp: Date.now(),
    durationMs,
  }
  return log
}

/** 列出所有工具的元信息（不含 handler） */
export function listTools(): ToolDef[] {
  const result: ToolDef[] = []
  for (let i = 0; i < toolNames.length; i++) {
    result.push({
      name: toolNames[i],
      description: toolDescs[i],
      inputSchema: toolSchemas[i],
    })
  }
  return result
}

/** 按名称查找工具 */
export function findTool(name: string): ToolDef | null {
  for (let i = 0; i < toolNames.length; i++) {
    if (toolNames[i] === name) {
      return {
        name: toolNames[i],
        description: toolDescs[i],
        inputSchema: toolSchemas[i],
      }
    }
  }
  return null
}

/** 获取工具调用次数 */
export function getToolCallCount(): number {
  return toolCallCounters.length
}

const toolCallCounters: number[] = []