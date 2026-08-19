/**
 * FusionOps - ArkTS 版文档操作
 *
 * 对应原型 src/fusion/ops.ts
 * 提供 Scene/Layer/Object/Frame 的增删改查。
 */
import { HdsDocument, Layer, Frame, FrameType, Scene, SceneObject, Page, Transform, Mask, LayerEffect, InfiniteCanvasConfig } from './SceneTypes'
import { createLayer, createFrame, createPage, genId, CreateFrameParams } from './FusionFactory'

/** 深克隆 */
export function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value))
}

/** 获取当前页面 */
export function getCurrentPage(doc: HdsDocument): Page | undefined {
  if (!doc.scene.pages || doc.scene.pages.length === 0) return undefined
  if (!doc.scene.currentPageId) return doc.scene.pages[0]
  return doc.scene.pages.find(p => p.id === doc.scene.currentPageId)
}

/** 获取当前图层列表 */
export function getCurrentLayers(doc: HdsDocument): Layer[] {
  const curFrame = getCurrentFrame(doc)
  if (curFrame) return curFrame.children
  const curPage = getCurrentPage(doc)
  if (curPage) return curPage.children
  return doc.scene.children
}

/** 获取当前 Frame */
export function getCurrentFrame(doc: HdsDocument): Frame | null {
  if (!doc.scene.frames || doc.scene.frames.length === 0) return null
  const cur = doc.scene.frames.find(f => f.id === doc.scene.selectedFrameId)
  if (cur) return cur
  const firstVisible = doc.scene.frames.find(f => !f.hidden)
  return firstVisible ?? doc.scene.frames[0] ?? null
}

/** 按 ID 查找 Frame */
export function findFrameById(doc: HdsDocument, frameId: string): Frame | undefined {
  return doc.scene.frames?.find(f => f.id === frameId)
}

/** 添加 Frame */
export function addFrame(doc: HdsDocument, type?: string, name?: string, x?: number, y?: number): Frame {
  if (!doc.scene.frames) {
    doc.scene.frames = []
    const canvasConfig: InfiniteCanvasConfig = {
      viewportX: 0, viewportY: 0, zoom: 1,
      background: 'grid', showRulers: false,
    }
    doc.scene.canvas = canvasConfig
  }
  const frameType: FrameType = (type ?? 'single') as FrameType
  const frame = createFrame({ type: frameType, name: name, x: x, y: y } as CreateFrameParams)
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
  for (const l of clonedLayers) {
    l.id = genId('layer')
    for (const o of l.objects) {
      o.id = genId(o.type)
    }
  }
  const newFrame: Frame = deepClone(src)
  newFrame.id = genId('frame')
  newFrame.name = `${src.name} 副本`
  newFrame.x = src.x + 60
  newFrame.y = src.y + 60
  newFrame.children = clonedLayers
  newFrame.createdAt = new Date().toISOString()
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

/** 更新 Frame 属性 */
export function updateFrame(
  doc: HdsDocument, frameId: string,
  x?: number, y?: number, width?: number, height?: number,
  name?: string, hidden?: boolean,
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
export interface FrameBBox {
  minX: number
  minY: number
  maxX: number
  maxY: number
}

export function getFramesBoundingBox(doc: HdsDocument): FrameBBox | null {
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

/** 适配视口 */
export function fitViewportToFrames(
  doc: HdsDocument, viewportWidth: number, viewportHeight: number, padding?: number,
): void {
  const bbox = getFramesBoundingBox(doc)
  if (!bbox || !doc.scene.canvas) return
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

/** 添加 Layer */
export function addLayer(doc: HdsDocument, name?: string): Layer {
  const arr = getCurrentLayers(doc)
  const layerName = name ?? `图层 ${arr.length + 1}`
  const newLayer = createLayer({ name: layerName })
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

/** 查找结果 */
export interface FindResult {
  layer: Layer
  obj: SceneObject
}

/** 按 ID 查找对象 */
export function findObjectInDoc(doc: HdsDocument, objId: string): FindResult | undefined {
  for (const layer of getCurrentLayers(doc)) {
    const found = findObjectRecursive(layer.objects, objId)
    if (found) {
      const result: FindResult = { layer, obj: found }
      return result
    }
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

/** 列出所有对象 */
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

/* ════════════════ Layer 扩展操作 ════════════════ */

export function moveLayer(doc: HdsDocument, fromIndex: number, toIndex: number): void {
  const arr = getCurrentLayers(doc)
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  if (fromIndex === toIndex) return
  const moved = arr.splice(fromIndex, 1)[0]
  arr.splice(toIndex, 0, moved)
}

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

export function findObjectInLayer(layer: Layer, objId: string): SceneObject | undefined {
  return layer.objects.find(o => o.id === objId)
}

export function removeObjectFromLayer(doc: HdsDocument, layerId: string, objId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.objects.findIndex(o => o.id === objId)
  if (idx < 0) return false
  layer.objects.splice(idx, 1)
  return true
}

export function moveObjectInLayer(doc: HdsDocument, layerId: string, fromIndex: number, toIndex: number): void {
  const layer = findLayerById(doc, layerId)
  if (!layer) return
  const arr = layer.objects
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  if (fromIndex === toIndex) return
  const moved = arr.splice(fromIndex, 1)[0]
  arr.splice(toIndex, 0, moved)
}

/* ════════════════ 编组/解组 ════════════════ */

export function groupObjects(doc: HdsDocument, layerId: string, objIds: string[]): SceneObject | undefined {
  const layer = findLayerById(doc, layerId)
  if (!layer || objIds.length < 2) return undefined
  const objs: SceneObject[] = []
  const indices: number[] = []
  for (let i = 0; i < objIds.length; i++) {
    const idx = layer.objects.findIndex(o => o.id === objIds[i])
    if (idx >= 0) {
      objs.push(layer.objects[idx])
      indices.push(idx)
    }
  }
  if (objs.length < 2) return undefined
  indices.sort((a, b) => b - a)
  for (let i = 0; i < indices.length; i++) {
    layer.objects.splice(indices[i], 1)
  }
  const insertAt = Math.min(...indices)
  const minX = Math.min(...objs.map(o => o.transform.x))
  const minY = Math.min(...objs.map(o => o.transform.y))
  const maxX = Math.max(...objs.map(o => o.transform.x + o.transform.width))
  const maxY = Math.max(...objs.map(o => o.transform.y + o.transform.height))
  const group: SceneObject = {
    id: genId('group'),
    type: 'group',
    name: `组 ${layer.objects.length + 1}`,
    transform: {
      x: minX, y: minY,
      width: maxX - minX, height: maxY - minY,
      rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100,
    } as Transform,
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: objs,
  }
  layer.objects.splice(insertAt, 0, group)
  return group
}

export function ungroupObjects(doc: HdsDocument, layerId: string, groupId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.objects.findIndex(o => o.id === groupId && o.type === 'group')
  if (idx < 0) return false
  const group = layer.objects[idx]
  const children = group.children ?? []
  layer.objects.splice(idx, 1, ...children)
  return true
}

function regenerateObjectIds(obj: SceneObject): SceneObject {
  const cloned = deepClone(obj)
  cloned.id = genId(obj.type)
  if (cloned.type === 'group' && cloned.children) {
    cloned.children = cloned.children.map(regenerateObjectIds)
  }
  return cloned
}

/* ════════════════ 蒙版与效果 ════════════════ */

export function addMaskToLayer(doc: HdsDocument, layerId: string, mask: Mask): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.hasMask = true
  layer.maskEnabled = true
  layer.mask = mask
  return true
}

export function toggleLayerMask(doc: HdsDocument, layerId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer || !layer.hasMask) return false
  layer.maskEnabled = !layer.maskEnabled
  return true
}

export function addLayerEffect(doc: HdsDocument, layerId: string, effect: LayerEffect): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.effects.push(effect)
  return true
}

export function removeLayerEffect(doc: HdsDocument, layerId: string, effectId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.effects.findIndex(e => e.id === effectId)
  if (idx < 0) return false
  layer.effects.splice(idx, 1)
  return true
}

/* ════════════════ 信息查询 ════════════════ */

export function listAllLayers(doc: HdsDocument): Layer[] {
  return getCurrentLayers(doc)
}

export function listAllPages(doc: HdsDocument): Page[] {
  return doc.scene.pages ?? []
}

export interface SceneInfo {
  layerCount: number
  objectCount: number
  canvasSize: string
  pageCount: number
  currentPage: number
}

export function getSceneInfo(doc: HdsDocument): SceneInfo {
  const pages = doc.scene.pages ?? []
  const curIdx = pages.findIndex(p => p.id === doc.scene.currentPageId)
  const info: SceneInfo = {
    layerCount: getCurrentLayers(doc).length,
    objectCount: listAllObjects(doc).length,
    canvasSize: `${doc.scene.canvasWidth} × ${doc.scene.canvasHeight} ${doc.scene.unit}`,
    pageCount: pages.length || 1,
    currentPage: curIdx >= 0 ? curIdx + 1 : 1,
  }
  return info
}

/* ════════════════ Page 操作 ════════════════ */

export function addPage(doc: HdsDocument, name?: string): Page {
  if (!doc.scene.pages) doc.scene.pages = []
  const page: Page = {
    id: genId('page'),
    name: name ?? `页面 ${doc.scene.pages.length + 1}`,
    width: doc.scene.canvasWidth,
    height: doc.scene.canvasHeight,
    background: '#FFFFFF',
    children: [],
    hidden: false,
    createdAt: new Date().toISOString(),
  }
  doc.scene.pages.push(page)
  if (!doc.scene.currentPageId) doc.scene.currentPageId = page.id
  return page
}

export function duplicatePage(doc: HdsDocument, pageId: string): Page | null {
  if (!doc.scene.pages) return null
  const src = doc.scene.pages.find(p => p.id === pageId)
  if (!src) return null
  const clonedLayers = deepClone(src.children)
  for (let i = 0; i < clonedLayers.length; i++) {
    const l = clonedLayers[i]
    l.id = genId('layer')
    l.objects = l.objects.map(o => regenerateObjectIds(o))
  }
  const newPage: Page = {
    id: genId('page'),
    name: `${src.name} 副本`,
    width: src.width,
    height: src.height,
    background: src.background,
    children: clonedLayers,
    hidden: false,
    createdAt: new Date().toISOString(),
  }
  const idx = doc.scene.pages.findIndex(p => p.id === pageId)
  doc.scene.pages.splice(idx + 1, 0, newPage)
  return newPage
}

export function deletePage(doc: HdsDocument, pageId: string): boolean {
  if (!doc.scene.pages || doc.scene.pages.length <= 1) return false
  const idx = doc.scene.pages.findIndex(p => p.id === pageId)
  if (idx < 0) return false
  doc.scene.pages.splice(idx, 1)
  if (doc.scene.currentPageId === pageId) {
    doc.scene.currentPageId = doc.scene.pages[0]?.id ?? ''
  }
  return true
}

export function switchPage(doc: HdsDocument, pageId: string): boolean {
  if (!doc.scene.pages) return false
  const exists = doc.scene.pages.find(p => p.id === pageId)
  if (!exists) return false
  doc.scene.currentPageId = pageId
  return true
}

export function renamePage(doc: HdsDocument, pageId: string, name: string): boolean {
  if (!doc.scene.pages) return false
  const page = doc.scene.pages.find(p => p.id === pageId)
  if (!page) return false
  page.name = name
  return true
}

export function movePage(doc: HdsDocument, pageId: string, newIndex: number): boolean {
  if (!doc.scene.pages) return false
  const curIdx = doc.scene.pages.findIndex(p => p.id === pageId)
  if (curIdx < 0) return false
  const clamped = Math.max(0, Math.min(doc.scene.pages.length - 1, newIndex))
  if (clamped === curIdx) return false
  const page = doc.scene.pages.splice(curIdx, 1)[0]
  doc.scene.pages.splice(clamped, 0, page)
  return true
}

export function addLayerToPage(doc: HdsDocument, pageId: string, layer?: Layer): Layer | null {
  if (!doc.scene.pages) return null
  const page = doc.scene.pages.find(p => p.id === pageId)
  if (!page) return null
  const l = layer ?? createLayer({ name: `Layer ${page.children.length + 1}` })
  l.parentId = page.id
  page.children.push(l)
  return l
}
