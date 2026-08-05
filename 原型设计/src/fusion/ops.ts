/**
 * Fusion DOM - Scene / Layer / Object 操作
 *
 * 提供对 Fusion DOM 的增删改查、移动、复制、编组等核心操作。
 * 所有操作都是纯函数（不可变更新），便于接入撤销/重做栈。
 */
import type {
  HdsDocument,
  Layer,
  Page,
  Frame,
  FrameType,
  Scene,
  SceneObject,
  LayerEffect,
  Mask,
} from '../types'
import { deepClone } from './serializer'
import { createLayer, createPage, createFrame, genId } from './factory'

/* ════════════════ Scene 操作 ════════════════ */

/** 在 Scene 顶部添加 Layer（默认插入到当前页面最上方） */
export function addLayer(doc: HdsDocument, layer?: Layer): Layer {
  const arr = getCurrentLayers(doc)
  const newLayer = layer ?? createLayer({ name: `图层 ${arr.length + 1}` })
  // 多页面模式下 parentId 设为 pageId，单页面模式设为 sceneId
  const curPage = getCurrentPage(doc)
  newLayer.parentId = curPage?.id ?? doc.scene.id
  arr.push(newLayer)
  return newLayer
}

/** 按 ID 查找 Layer（在当前页面中查找） */
export function findLayerById(doc: HdsDocument, layerId: string): Layer | undefined {
  return getCurrentLayers(doc).find(l => l.id === layerId)
}

/** 按 ID 删除 Layer（在当前页面中删除） */
export function removeLayer(doc: HdsDocument, layerId: string): boolean {
  const arr = getCurrentLayers(doc)
  const idx = arr.findIndex(l => l.id === layerId)
  if (idx < 0) return false
  arr.splice(idx, 1)
  return true
}

/** 移动 Layer 顺序（drag reorder，作用于当前页面） */
export function moveLayer(doc: HdsDocument, fromIndex: number, toIndex: number): void {
  const arr = getCurrentLayers(doc)
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  if (fromIndex === toIndex) return
  const [moved] = arr.splice(fromIndex, 1)
  arr.splice(toIndex, 0, moved)
}

/** 复制 Layer（添加到当前页面末尾） */
export function duplicateLayer(doc: HdsDocument, layerId: string): Layer | undefined {
  const src = findLayerById(doc, layerId)
  if (!src) return undefined
  const cloned = deepClone(src)
  cloned.id = genId('layer')
  cloned.name = `${src.name} 副本`
  // 重新生成所有子对象 ID
  cloned.objects = cloned.objects.map(o => regenerateObjectIds(o))
  getCurrentLayers(doc).push(cloned)
  return cloned
}

/** 递归生成新 ID（用于复制时避免 ID 冲突） */
function regenerateObjectIds(obj: SceneObject): SceneObject {
  const cloned = deepClone(obj)
  cloned.id = genId(obj.type)
  if (cloned.type === 'group' && cloned.children) {
    cloned.children = cloned.children.map(regenerateObjectIds)
  }
  return cloned
}

/* ════════════════ Layer 内对象操作 ════════════════ */

/** 在指定 Layer 中添加对象 */
export function addObjectToLayer(doc: HdsDocument, layerId: string, obj: SceneObject): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.objects.push(obj)
  return true
}

/** 按 ID 在 Layer 中查找对象 */
export function findObjectInLayer(layer: Layer, objId: string): SceneObject | undefined {
  return layer.objects.find(o => o.id === objId)
}

/** 按 ID 在整个文档中查找对象（含 Group 递归，作用于当前页面） */
export function findObjectInDoc(doc: HdsDocument, objId: string): { layer: Layer; obj: SceneObject } | undefined {
  for (const layer of getCurrentLayers(doc)) {
    const found = findObjectRecursive(layer.objects, objId)
    if (found) return { layer, obj: found }
  }
  return undefined
}

/** 递归查找对象 */
function findObjectRecursive(objects: SceneObject[], objId: string): SceneObject | undefined {
  for (const o of objects) {
    if (o.id === objId) return o
    if (o.type === 'group' && o.children) {
      const nested = findObjectRecursive(o.children, objId)
      if (nested) return nested
    }
  }
  return undefined
}

/** 删除 Layer 中的对象 */
export function removeObjectFromLayer(doc: HdsDocument, layerId: string, objId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.objects.findIndex(o => o.id === objId)
  if (idx < 0) return false
  layer.objects.splice(idx, 1)
  return true
}

/** 移动 Layer 内对象顺序 */
export function moveObjectInLayer(doc: HdsDocument, layerId: string, fromIndex: number, toIndex: number): void {
  const layer = findLayerById(doc, layerId)
  if (!layer) return
  const arr = layer.objects
  if (fromIndex < 0 || fromIndex >= arr.length) return
  if (toIndex < 0 || toIndex >= arr.length) return
  if (fromIndex === toIndex) return
  const [moved] = arr.splice(fromIndex, 1)
  arr.splice(toIndex, 0, moved)
}

/* ════════════════ 编组/解组 ════════════════ */

/**
 * 将多个对象编组为 Group（在原 Layer 内替换为 Group）
 * @returns 新建的 Group 对象
 */
export function groupObjects(doc: HdsDocument, layerId: string, objIds: string[]): SceneObject | undefined {
  const layer = findLayerById(doc, layerId)
  if (!layer || objIds.length === 0) return undefined
  const objs: SceneObject[] = []
  const indices: number[] = []
  objIds.forEach(id => {
    const idx = layer.objects.findIndex(o => o.id === id)
    if (idx >= 0) {
      objs.push(layer.objects[idx])
      indices.push(idx)
    }
  })
  if (objs.length === 0) return undefined
  // 按索引倒序删除
  indices.sort((a, b) => b - a)
  indices.forEach(i => layer.objects.splice(i, 1))
  // 在最小原索引处插入 Group
  const insertAt = Math.min(...indices)
  const group: SceneObject = {
    id: genId('group'),
    type: 'group',
    name: `组 ${layer.objects.length + 1}`,
    transform: {
      x: Math.min(...objs.map(o => o.transform.x)),
      y: Math.min(...objs.map(o => o.transform.y)),
      width: Math.max(...objs.map(o => o.transform.x + o.transform.width)) - Math.min(...objs.map(o => o.transform.x)),
      height: Math.max(...objs.map(o => o.transform.y + o.transform.height)) - Math.min(...objs.map(o => o.transform.y)),
      rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100,
    },
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: objs,
  }
  layer.objects.splice(insertAt, 0, group)
  return group
}

/** 解组（将 Group 内对象展开到原 Layer） */
export function ungroupObjects(doc: HdsDocument, layerId: string, groupId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.objects.findIndex(o => o.id === groupId && o.type === 'group')
  if (idx < 0) return false
  const group = layer.objects[idx] as SceneObject & { type: 'group'; children: SceneObject[] }
  const children = group.children ?? []
  layer.objects.splice(idx, 1, ...children)
  return true
}

/* ════════════════ 蒙版与效果 ════════════════ */

/** 给 Layer 添加蒙版 */
export function addMaskToLayer(doc: HdsDocument, layerId: string, mask: Mask): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.hasMask = true
  layer.maskEnabled = true
  layer.mask = mask
  return true
}

/** 启用/禁用 Layer 蒙版 */
export function toggleLayerMask(doc: HdsDocument, layerId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer || !layer.hasMask) return false
  layer.maskEnabled = !layer.maskEnabled
  return true
}

/** 给 Layer 添加效果 */
export function addLayerEffect(doc: HdsDocument, layerId: string, effect: LayerEffect): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  layer.effects.push(effect)
  return true
}

/** 删除 Layer 效果 */
export function removeLayerEffect(doc: HdsDocument, layerId: string, effectId: string): boolean {
  const layer = findLayerById(doc, layerId)
  if (!layer) return false
  const idx = layer.effects.findIndex(e => e.id === effectId)
  if (idx < 0) return false
  layer.effects.splice(idx, 1)
  return true
}

/* ════════════════ 选择与遍历 ════════════════ */

/**
 * 获取当前激活的图层列表。
 * 优先级：frames > pages > children
 * - frames 模式：取 selectedFrameId 对应的 Frame.children
 * - pages 模式：取 currentPageId 对应的 Page.children
 * - 单页面模式：回退到 scene.children
 */
export function getCurrentLayers(doc: HdsDocument): Layer[] {
  // 1. frames 模式（新架构优先）
  if (doc.scene.frames && doc.scene.frames.length > 0) {
    const cur = doc.scene.frames.find(f => f.id === doc.scene.selectedFrameId)
    if (cur) return cur.children
    // 兜底：返回第一个可见 Frame
    const firstVisible = doc.scene.frames.find(f => !f.hidden)
    return firstVisible?.children ?? []
  }
  // 2. pages 模式（兼容旧多页文档）
  if (doc.scene.pages && doc.scene.pages.length > 0) {
    const cur = doc.scene.pages.find(p => p.id === doc.scene.currentPageId)
    if (cur) return cur.children
    return doc.scene.pages[0].children
  }
  // 3. 单页面模式
  return doc.scene.children
}

/** 获取所有 Layer（已扁平化，自动路由到当前页面） */
export function listAllLayers(doc: HdsDocument): Layer[] {
  return getCurrentLayers(doc)
}

/** 获取所有 Page（多页面模式下返回 pages，否则返回空数组） */
export function listAllPages(doc: HdsDocument): Page[] {
  return doc.scene.pages ?? []
}

/** 获取当前激活的 Page（多页面模式下使用） */
export function getCurrentPage(doc: HdsDocument): Page | null {
  if (!doc.scene.pages || doc.scene.pages.length === 0) return null
  const cur = doc.scene.pages.find(p => p.id === doc.scene.currentPageId)
  return cur ?? doc.scene.pages[0] ?? null
}

/** 获取文档内所有对象（含 Group 内，自动路由到当前页面） */
export function listAllObjects(doc: HdsDocument): SceneObject[] {
  const result: SceneObject[] = []
  const walk = (objs: SceneObject[]) => {
    objs.forEach(o => {
      result.push(o)
      if (o.type === 'group' && o.children) walk(o.children)
    })
  }
  getCurrentLayers(doc).forEach(l => walk(l.objects))
  return result
}

/** 获取 Scene 信息（用于 UI 显示） */
export function getSceneInfo(doc: HdsDocument): {
  layerCount: number
  objectCount: number
  canvasSize: string
  pageCount: number
  currentPage: number
} {
  const pages = doc.scene.pages ?? []
  const curIdx = pages.findIndex(p => p.id === doc.scene.currentPageId)
  return {
    layerCount: getCurrentLayers(doc).length,
    objectCount: listAllObjects(doc).length,
    canvasSize: `${doc.scene.canvasWidth} × ${doc.scene.canvasHeight} ${doc.scene.unit}`,
    pageCount: pages.length || 1,
    currentPage: curIdx >= 0 ? curIdx + 1 : 1,
  }
}

/* ════════════════ Page 操作（多页面模式） ════════════════ */

/** 添加新页面（插入到末尾） */
export function addPage(doc: HdsDocument, params?: Parameters<typeof createPage>[0]): Page {
  if (!doc.scene.pages) doc.scene.pages = []
  const page = createPage(params ?? { name: `页面 ${doc.scene.pages.length + 1}` })
  doc.scene.pages.push(page)
  if (!doc.scene.currentPageId) doc.scene.currentPageId = page.id
  return page
}

/** 复制页面（深拷贝图层并重新生成 ID） */
export function duplicatePage(doc: HdsDocument, pageId: string): Page | null {
  if (!doc.scene.pages) return null
  const src = doc.scene.pages.find(p => p.id === pageId)
  if (!src) return null
  const clonedLayers = deepClone(src.children)
  // 重新生成 layer ID 与对象 ID 防止冲突
  clonedLayers.forEach(l => {
    l.id = genId('layer')
    l.objects.forEach(o => regenerateObjectIdsInPlace(o))
  })
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

/** 删除页面（至少保留一页） */
export function deletePage(doc: HdsDocument, pageId: string): boolean {
  if (!doc.scene.pages || doc.scene.pages.length <= 1) return false
  const idx = doc.scene.pages.findIndex(p => p.id === pageId)
  if (idx < 0) return false
  doc.scene.pages.splice(idx, 1)
  // 若删除的是当前页，切到第一页
  if (doc.scene.currentPageId === pageId) {
    doc.scene.currentPageId = doc.scene.pages[0]?.id
  }
  return true
}

/** 切换当前页面 */
export function switchPage(doc: HdsDocument, pageId: string): boolean {
  if (!doc.scene.pages) return false
  const exists = doc.scene.pages.find(p => p.id === pageId)
  if (!exists) return false
  doc.scene.currentPageId = pageId
  return true
}

/** 重命名页面 */
export function renamePage(doc: HdsDocument, pageId: string, name: string): boolean {
  if (!doc.scene.pages) return false
  const page = doc.scene.pages.find(p => p.id === pageId)
  if (!page) return false
  page.name = name
  return true
}

/** 重排页面（移动 pageId 到 newIndex） */
export function movePage(doc: HdsDocument, pageId: string, newIndex: number): boolean {
  if (!doc.scene.pages) return false
  const curIdx = doc.scene.pages.findIndex(p => p.id === pageId)
  if (curIdx < 0) return false
  const clamped = Math.max(0, Math.min(doc.scene.pages.length - 1, newIndex))
  if (clamped === curIdx) return false
  const [page] = doc.scene.pages.splice(curIdx, 1)
  doc.scene.pages.splice(clamped, 0, page)
  return true
}

/** 在指定页面下添加 Layer */
export function addLayerToPage(doc: HdsDocument, pageId: string, layer?: Layer): Layer | null {
  if (!doc.scene.pages) return null
  const page = doc.scene.pages.find(p => p.id === pageId)
  if (!page) return null
  const l = layer ?? createLayer({ name: `Layer ${page.children.length + 1}` })
  l.parentId = page.id
  page.children.push(l)
  return l
}

/** 将对象从当前页面复制到目标页面 */
export function copyObjectToPage(
  doc: HdsDocument,
  objId: string,
  targetPageId: string,
): SceneObject | null {
  const found = findObjectInDoc(doc, objId)
  if (!found) return null
  const targetPage = doc.scene.pages?.find(p => p.id === targetPageId)
  if (!targetPage) return null
  // 目标页若没有图层，先建一个
  let targetLayer = targetPage.children[0]
  if (!targetLayer) {
    const created = addLayerToPage(doc, targetPageId)
    if (!created) return null
    targetLayer = created
  }
  const cloned = deepClone(found.obj)
  regenerateObjectIdsInPlace(cloned)
  targetLayer.objects.push(cloned)
  return cloned
}

/** 递归重新生成对象 ID（原地修改，用于复制/克隆时避免冲突） */
function regenerateObjectIdsInPlace(obj: SceneObject): void {
  obj.id = genId(obj.type)
  if (obj.type === 'group' && obj.children) {
    obj.children.forEach(regenerateObjectIdsInPlace)
  }
}

/* ════════════════ Frame 操作（无限画布 + 融合多重模式） ════════════════ */

/** 获取当前激活的 Frame（frames 模式下使用） */
export function getCurrentFrame(doc: HdsDocument): Frame | null {
  if (!doc.scene.frames || doc.scene.frames.length === 0) return null
  const cur = doc.scene.frames.find(f => f.id === doc.scene.selectedFrameId)
  return cur ?? doc.scene.frames.find(f => !f.hidden) ?? doc.scene.frames[0] ?? null
}

/** 获取所有 Frame */
export function listAllFrames(doc: HdsDocument): Frame[] {
  return doc.scene.frames ?? []
}

/** 按 ID 查找 Frame */
export function findFrameById(doc: HdsDocument, frameId: string): Frame | undefined {
  return doc.scene.frames?.find(f => f.id === frameId)
}

/** 添加新 Frame（插入到末尾） */
export function addFrame(doc: HdsDocument, params?: Parameters<typeof createFrame>[0]): Frame {
  if (!doc.scene.frames) {
    doc.scene.frames = []
    doc.scene.canvas = {
      viewportX: 0,
      viewportY: 0,
      zoom: 1,
      background: 'grid',
      showRulers: false,
    }
  }
  const frame = createFrame(params ?? {})
  // 智能定位：仅在未显式指定坐标时，避免与已有 Frame 重叠，放在右侧
  if (doc.scene.frames.length > 0 && (params?.x === undefined || params?.y === undefined)) {
    const last = doc.scene.frames[doc.scene.frames.length - 1]
    if (params?.x === undefined) frame.x = last.x + last.width + 80
    if (params?.y === undefined) frame.y = last.y
  }
  doc.scene.frames.push(frame)
  if (!doc.scene.selectedFrameId) doc.scene.selectedFrameId = frame.id
  return frame
}

/** 复制 Frame（深拷贝图层并重新生成 ID） */
export function duplicateFrame(doc: HdsDocument, frameId: string): Frame | null {
  if (!doc.scene.frames) return null
  const src = doc.scene.frames.find(f => f.id === frameId)
  if (!src) return null
  const clonedLayers = deepClone(src.children)
  clonedLayers.forEach(l => {
    l.id = genId('layer')
    l.objects.forEach(o => regenerateObjectIdsInPlace(o))
  })
  const newFrame: Frame = {
    ...deepClone(src),
    id: genId('frame'),
    name: `${src.name} 副本`,
    x: src.x + 60,
    y: src.y + 60,
    children: clonedLayers,
    createdAt: new Date().toISOString(),
    // 清除对页关联（副本独立）
    spreadWith: undefined,
    spreadSide: undefined,
  }
  const idx = doc.scene.frames.findIndex(f => f.id === frameId)
  doc.scene.frames.splice(idx + 1, 0, newFrame)
  return newFrame
}

/** 删除 Frame（至少保留一个，frames 模式下） */
export function deleteFrame(doc: HdsDocument, frameId: string): boolean {
  if (!doc.scene.frames || doc.scene.frames.length <= 1) return false
  const idx = doc.scene.frames.findIndex(f => f.id === frameId)
  if (idx < 0) return false
  // 解除对页关联
  const target = doc.scene.frames[idx]
  if (target.spreadWith) {
    const partner = doc.scene.frames.find(f => f.id === target.spreadWith)
    if (partner) {
      partner.spreadWith = undefined
      partner.spreadSide = undefined
    }
  }
  doc.scene.frames.splice(idx, 1)
  // 若删除的是当前 Frame，切到第一个
  if (doc.scene.selectedFrameId === frameId) {
    doc.scene.selectedFrameId = doc.scene.frames[0]?.id
  }
  return true
}

/** 切换当前激活 Frame */
export function switchFrame(doc: HdsDocument, frameId: string): boolean {
  if (!doc.scene.frames) return false
  const exists = doc.scene.frames.find(f => f.id === frameId)
  if (!exists) return false
  doc.scene.selectedFrameId = frameId
  return true
}

/** 重命名 Frame */
export function renameFrame(doc: HdsDocument, frameId: string, name: string): boolean {
  const frame = findFrameById(doc, frameId)
  if (!frame) return false
  frame.name = name
  return true
}

/** 移动 Frame 位置（在无限画布上的 x/y） */
export function moveFrame(doc: HdsDocument, frameId: string, x: number, y: number): boolean {
  const frame = findFrameById(doc, frameId)
  if (!frame) return false
  frame.x = x
  frame.y = y
  return true
}

/** 调整 Frame 尺寸 */
export function resizeFrame(doc: HdsDocument, frameId: string, width: number, height: number): boolean {
  const frame = findFrameById(doc, frameId)
  if (!frame) return false
  frame.width = width
  frame.height = height
  return true
}

/** 重排 Frame 顺序（移动 frameId 到 newIndex，影响书籍页码） */
export function moveFrameOrder(doc: HdsDocument, frameId: string, newIndex: number): boolean {
  if (!doc.scene.frames) return false
  const curIdx = doc.scene.frames.findIndex(f => f.id === frameId)
  if (curIdx < 0) return false
  const clamped = Math.max(0, Math.min(doc.scene.frames.length - 1, newIndex))
  if (clamped === curIdx) return false
  const [frame] = doc.scene.frames.splice(curIdx, 1)
  doc.scene.frames.splice(clamped, 0, frame)
  // 重排书籍模式：更新 order 与页码
  if (frame.type === 'book-page') {
    doc.scene.frames.forEach((f, i) => {
      if (f.type === 'book-page') {
        f.order = i + 1
        f.name = `第 ${i + 1} 页`
      }
    })
  }
  return true
}

/** 在指定 Frame 下添加 Layer */
export function addLayerToFrame(doc: HdsDocument, frameId: string, layer?: Layer): Layer | null {
  const frame = findFrameById(doc, frameId)
  if (!frame) return null
  const l = layer ?? createLayer({ name: `Layer ${frame.children.length + 1}` })
  l.parentId = frame.id
  frame.children.push(l)
  return l
}

/** 初始化无限画布配置（若不存在） */
export function ensureInfiniteCanvas(doc: HdsDocument): void {
  if (!doc.scene.canvas) {
    doc.scene.canvas = {
      viewportX: 0,
      viewportY: 0,
      zoom: 1,
      background: 'grid',
      showRulers: false,
    }
  }
}

/** 更新无限画布视口 */
export function updateViewport(doc: HdsDocument, viewport: Partial<NonNullable<Scene['canvas']>>): void {
  ensureInfiniteCanvas(doc)
  if (doc.scene.canvas) {
    Object.assign(doc.scene.canvas, viewport)
  }
}

/** 鸟瞰视图：计算包含所有 Frame 的包围盒 */
export function getFramesBoundingBox(doc: HdsDocument): { minX: number; minY: number; maxX: number; maxY: number } | null {
  const frames = doc.scene.frames ?? []
  if (frames.length === 0) return null
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (const f of frames) {
    if (f.hidden) continue
    minX = Math.min(minX, f.x)
    minY = Math.min(minY, f.y)
    maxX = Math.max(maxX, f.x + f.width)
    maxY = Math.max(maxY, f.y + f.height)
  }
  return { minX, minY, maxX, maxY }
}

/** 适配视口到所有 Frame（fit all） */
export function fitViewportToFrames(doc: HdsDocument, viewportWidth: number, viewportHeight: number, padding: number = 80): void {
  const bbox = getFramesBoundingBox(doc)
  if (!bbox) return
  ensureInfiniteCanvas(doc)
  if (!doc.scene.canvas) return
  // 防护：视口尺寸为 0 时不计算 zoom（否则会得到负数）
  if (viewportWidth <= 0 || viewportHeight <= 0) return
  const contentW = bbox.maxX - bbox.minX
  const contentH = bbox.maxY - bbox.minY
  if (contentW <= 0 || contentH <= 0) return
  const scaleX = (viewportWidth - padding * 2) / contentW
  const scaleY = (viewportHeight - padding * 2) / contentH
  const zoom = Math.max(0.05, Math.min(scaleX, scaleY, 1)) // 不放大超过 100%，最小 5%
  const centerX = (bbox.minX + bbox.maxX) / 2
  const centerY = (bbox.minY + bbox.maxY) / 2
  doc.scene.canvas.viewportX = centerX
  doc.scene.canvas.viewportY = centerY
  doc.scene.canvas.zoom = zoom
}
