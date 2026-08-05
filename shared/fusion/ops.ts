/**
 * Fusion DOM - 文档操作（跨端共享）
 *
 * 对应原型 src/fusion/ops.ts（精简核心部分）
 * 包含 Scene/Layer/Object/Frame 的增删改查。
 */
import {
  HdsDocument, Layer, Frame, Scene, SceneObject, Page,
} from '../types/scene'
import { createLayer, createFrame, genId } from './factory'

/** 深克隆（跨端兼容：优先 structuredClone，回退 JSON） */
export function deepClone<T>(value: T): T {
  if (typeof structuredClone === 'function') {
    try { return structuredClone(value) } catch {}
  }
  return JSON.parse(JSON.stringify(value))
}

/* ════════════════ 当前页面/Frame 工具 ════════════════ */

/** 获取当前页面 */
export function getCurrentPage(doc: HdsDocument): Page | undefined {
  if (!doc.scene.pages || doc.scene.pages.length === 0) return undefined
  if (!doc.scene.currentPageId) return doc.scene.pages[0]
  return doc.scene.pages.find(p => p.id === doc.scene.currentPageId)
}

/** 获取当前图层列表（优先 frames > pages > children） */
export function getCurrentLayers(doc: HdsDocument): Layer[] {
  // Frame 模式
  const curFrame = getCurrentFrame(doc)
  if (curFrame) return curFrame.children
  // 多页面模式
  const curPage = getCurrentPage(doc)
  if (curPage) return curPage.children
  // 单页面模式
  return doc.scene.children
}

/** 获取当前激活的 Frame */
export function getCurrentFrame(doc: HdsDocument): Frame | null {
  if (!doc.scene.frames || doc.scene.frames.length === 0) return null
  const cur = doc.scene.frames.find(f => f.id === doc.scene.selectedFrameId)
  return cur ?? doc.scene.frames.find(f => !f.hidden) ?? doc.scene.frames[0] ?? null
}

/** 获取所有 Frame */
export function listAllFrames(doc: HdsDocument): Frame[] {
  return doc.scene.frames ?? []
}

/* ════════════════ Layer 操作 ════════════════ */

/** 添加 Layer */
export function addLayer(doc: HdsDocument, layer?: Layer): Layer {
  const arr = getCurrentLayers(doc)
  const newLayer = layer ?? createLayer({ name: `图层 ${arr.length + 1}` })
  const curPage = getCurrentPage(doc)
  newLayer.parentId = curPage?.id ?? doc.scene.id
  arr.push(newLayer)
  return newLayer
}

/** 按 ID 查找 Layer */
export function findLayerById(doc: HdsDocument, layerId: string): Layer | undefined {
  return getCurrentLayers(doc).find(l => l.id === layerId)
}

/** 按 ID 删除 Layer */
export function removeLayer(doc: HdsDocument, layerId: string): boolean {
  const arr = getCurrentLayers(doc)
  const idx = arr.findIndex(l => l.id === layerId)
  if (idx < 0) return false
  arr.splice(idx, 1)
  return true
}

/** 移动 Layer 顺序 */
export function moveLayer(doc: HdsDocument, fromIndex: number, toIndex: number): void {
  const arr = getCurrentLayers(doc)
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  if (fromIndex === toIndex) return
  const moved = arr.splice(fromIndex, 1)[0]
  arr.splice(toIndex, 0, moved)
}

/** 复制 Layer */
export function duplicateLayer(doc: HdsDocument, layerId: string): Layer | undefined {
  const src = findLayerById(doc, layerId)
  if (!src) return undefined
  const cloned = deepClone(src)
  cloned.id = genId('layer')
  cloned.name = `${src.name} 副本`
  cloned.objects = cloned.objects.map(o => regenerateObjectIds(o))
  getCurrentLayers(doc).push(cloned)
  return cloned
}

/** 递归重新生成对象 ID */
function regenerateObjectIds(obj: SceneObject): SceneObject {
  const cloned = deepClone(obj)
  cloned.id = genId(obj.type)
  if (cloned.type === 'group' && cloned.children) {
    cloned.children = cloned.children.map(regenerateObjectIds)
  }
  return cloned
}

/* ════════════════ Object 操作 ════════════════ */

/** 递归查找对象 */
function findObjectRecursive(objects: SceneObject[], objId: string): SceneObject | undefined {
  for (const o of objects) {
    if (o.id === objId) return o
    if (o.type === 'group' && o.children) {
      const found = findObjectRecursive(o.children, objId)
      if (found) return found
    }
  }
  return undefined
}

/** 按 ID 查找对象 */
export function findObjectInDoc(doc: HdsDocument, objId: string): { layer: Layer; obj: SceneObject } | undefined {
  for (const layer of getCurrentLayers(doc)) {
    const found = findObjectRecursive(layer.objects, objId)
    if (found) return { layer, obj: found }
  }
  return undefined
}

/** 添加对象到 Layer */
export function addObjectToLayer(doc: HdsDocument, layerId: string, obj: SceneObject): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.objects.push(obj)
  return true
}

/** 按 ID 删除对象 */
export function removeObject(doc: HdsDocument, objId: string): boolean {
  const layers = getCurrentLayers(doc)
  for (const layer of layers) {
    const idx = layer.objects.findIndex(o => o.id === objId)
    if (idx >= 0) {
      layer.objects.splice(idx, 1)
      return true
    }
    // 递归 Group
    for (const obj of layer.objects) {
      if (obj.type === 'group' && obj.children) {
        if (removeFromGroup(obj.children, objId)) return true
      }
    }
  }
  return false
}

function removeFromGroup(children: SceneObject[], objId: string): boolean {
  const idx = children.findIndex(o => o.id === objId)
  if (idx >= 0) {
    children.splice(idx, 1)
    return true
  }
  for (const obj of children) {
    if (obj.type === 'group' && obj.children) {
      if (removeFromGroup(obj.children, objId)) return true
    }
  }
  return false
}

/** 更新对象 transform */
export function updateObjectTransform(
  doc: HdsDocument, objId: string,
  x?: number, y?: number, width?: number, height?: number, rotation?: number,
): boolean {
  const found = findObjectInDoc(doc, objId)
  if (!found) return false
  const t = found.obj.transform
  if (x !== undefined) t.x = x
  if (y !== undefined) t.y = y
  if (width !== undefined) t.width = width
  if (height !== undefined) t.height = height
  if (rotation !== undefined) t.rotation = rotation
  return true
}

/** 列出当前页面所有对象 */
export function listAllObjects(doc: HdsDocument): SceneObject[] {
  const layers = getCurrentLayers(doc)
  const result: SceneObject[] = []
  for (const layer of layers) {
    collectObjects(layer.objects, result)
  }
  return result
}

function collectObjects(objects: SceneObject[], result: SceneObject[]): void {
  for (const o of objects) {
    result.push(o)
    if (o.type === 'group' && o.children) {
      collectObjects(o.children, result)
    }
  }
}

/* ════════════════ Frame 操作 ════════════════ */

/** 按 ID 查找 Frame */
export function findFrameById(doc: HdsDocument, frameId: string): Frame | undefined {
  return doc.scene.frames?.find(f => f.id === frameId)
}

/** 添加 Frame */
export function addFrame(doc: HdsDocument, type?: string, name?: string, x?: number, y?: number): Frame {
  if (!doc.scene.frames) {
    doc.scene.frames = []
    doc.scene.canvas = {
      viewportX: 0, viewportY: 0, zoom: 1,
      background: 'grid', showRulers: false,
    }
  }
  const frame = createFrame(type as Frame['type'], name, x, y)
  if (doc.scene.frames.length > 0 && x === undefined) {
    const last = doc.scene.frames[doc.scene.frames.length - 1]
    frame.x = last.x + last.width + 80
    frame.y = last.y
  }
  doc.scene.frames.push(frame)
  if (!doc.scene.selectedFrameId) doc.scene.selectedFrameId = frame.id
  return frame
}

/** 复制 Frame */
export function duplicateFrame(doc: HdsDocument, frameId: string): Frame | null {
  if (!doc.scene.frames) return null
  const src = doc.scene.frames.find(f => f.id === frameId)
  if (!src) return null
  const clonedLayers = deepClone(src.children)
  clonedLayers.forEach(l => {
    l.id = genId('layer')
    l.objects.forEach(o => { o.id = genId(o.type) })
  })
  const newFrame: Frame = {
    ...deepClone(src),
    id: genId('frame'),
    name: `${src.name} 副本`,
    x: src.x + 60, y: src.y + 60,
    children: clonedLayers,
    createdAt: new Date().toISOString(),
  }
  const idx = doc.scene.frames.findIndex(f => f.id === frameId)
  doc.scene.frames.splice(idx + 1, 0, newFrame)
  return newFrame
}

/** 删除 Frame */
export function removeFrame(doc: HdsDocument, frameId: string): boolean {
  if (!doc.scene.frames) return false
  const idx = doc.scene.frames.findIndex(f => f.id === frameId)
  if (idx < 0) return false
  doc.scene.frames.splice(idx, 1)
  if (doc.scene.selectedFrameId === frameId) {
    doc.scene.selectedFrameId = doc.scene.frames[0]?.id ?? ''
  }
  return true
}

/** 移动 Frame 顺序 */
export function moveFrame(doc: HdsDocument, fromIndex: number, toIndex: number): void {
  if (!doc.scene.frames) return
  const arr = doc.scene.frames
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  const moved = arr.splice(fromIndex, 1)[0]
  arr.splice(toIndex, 0, moved)
}

/** 更新 Frame 属性 */
export function updateFrame(
  doc: HdsDocument, frameId: string,
  x?: number, y?: number, width?: number, height?: number, name?: string, hidden?: boolean,
): boolean {
  const frame = findFrameById(doc, frameId)
  if (!frame) return false
  if (x !== undefined) frame.x = x
  if (y !== undefined) frame.y = y
  if (width !== undefined) frame.width = width
  if (height !== undefined) frame.height = height
  if (name !== undefined) frame.name = name
  if (hidden !== undefined) frame.hidden = hidden
  return true
}

/** 获取 Frame 包围盒 */
export function getFramesBoundingBox(doc: HdsDocument): { minX: number; minY: number; maxX: number; maxY: number } | null {
  if (!doc.scene.frames || doc.scene.frames.length === 0) return null
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (const f of doc.scene.frames) {
    minX = Math.min(minX, f.x)
    minY = Math.min(minY, f.y)
    maxX = Math.max(maxX, f.x + f.width)
    maxY = Math.max(maxY, f.y + f.height)
  }
  return { minX, minY, maxX, maxY }
}

/** 适配视口到所有 Frame */
export function fitViewportToFrames(
  doc: HdsDocument, viewportWidth: number, viewportHeight: number, padding?: number,
): void {
  const bbox = getFramesBoundingBox(doc)
  if (!bbox) return
  if (!doc.scene.canvas) return
  const pad = padding ?? 80
  if (viewportWidth <= 0 || viewportHeight <= 0) return
  const contentW = bbox.maxX - bbox.minX
  const contentH = bbox.maxY - bbox.minY
  if (contentW <= 0 || contentH <= 0) return
  const scaleX = (viewportWidth - pad * 2) / contentW
  const scaleY = (viewportHeight - pad * 2) / contentH
  const zoom = Math.max(0.05, Math.min(scaleX, scaleY, 1))
  doc.scene.canvas.viewportX = (bbox.minX + bbox.maxX) / 2
  doc.scene.canvas.viewportY = (bbox.minY + bbox.maxY) / 2
  doc.scene.canvas.zoom = zoom
}
