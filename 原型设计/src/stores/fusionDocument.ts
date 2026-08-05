/**
 * Fusion Document Store
 *
 * 基于 Pinia 的 Fusion DOM 状态管理。
 * 维护当前文档、选中图层、撤销/重做栈。
 * 提供所有 CRUD 操作，并自动管理修改标记与持久化。
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { HdsDocument, Layer, Page, Frame, FrameType, SceneObject, Scene, BlendMode, Mask, LayerEffect } from '../types'
import {
  createScene,
  createLayer,
  createPage,
  createFrame,
  createTextObject,
  createShapeObject,
  createImageObject,
  createObjectByType,
  createMask,
  createLayerEffect,
  serialize,
  deserialize,
  deepClone,
  estimateSize,
  HDS_FORMAT_VERSION,
  addLayer,
  removeLayer,
  moveLayer,
  duplicateLayer,
  findLayerById,
  findObjectInDoc,
  addObjectToLayer,
  removeObjectFromLayer,
  moveObjectInLayer,
  groupObjects,
  ungroupObjects,
  addMaskToLayer,
  toggleLayerMask,
  addLayerEffect,
  removeLayerEffect,
  listAllLayers,
  listAllObjects,
  getSceneInfo,
  listAllPages,
  getCurrentPage,
  getCurrentLayers,
  addPage as opsAddPage,
  duplicatePage as opsDuplicatePage,
  deletePage as opsDeletePage,
  switchPage as opsSwitchPage,
  renamePage as opsRenamePage,
  movePage as opsMovePage,
  copyObjectToPage as opsCopyObjectToPage,
  listAllFrames,
  getCurrentFrame,
  findFrameById,
  addFrame as opsAddFrame,
  duplicateFrame as opsDuplicateFrame,
  deleteFrame as opsDeleteFrame,
  switchFrame as opsSwitchFrame,
  renameFrame as opsRenameFrame,
  moveFrame as opsMoveFrame,
  resizeFrame as opsResizeFrame,
  moveFrameOrder as opsMoveFrameOrder,
  addLayerToFrame as opsAddLayerToFrame,
  ensureInfiniteCanvas as opsEnsureInfiniteCanvas,
  updateViewport as opsUpdateViewport,
  fitViewportToFrames as opsFitViewportToFrames,
  getFramesBoundingBox as opsGetFramesBoundingBox,
  FRAME_DEFAULTS,
} from '../fusion'

/** 历史记录条目 */
interface HistoryEntry {
  description: string
  snapshot: HdsDocument
  timestamp: number
}

const MAX_HISTORY = 50

export const useFusionDocumentStore = defineStore('fusion-document', () => {
  // ─── 当前文档 ───
  const doc = ref<HdsDocument>(createDefaultDocument())

  // ─── 选中状态 ───
  const selectedLayerId = ref<string | null>(null)
  const selectedObjectIds = ref<string[]>([])

  // ─── 历史栈 ───
  const undoStack = ref<HistoryEntry[]>([])
  const redoStack = ref<HistoryEntry[]>([])

  // ─── 元数据 ───
  const isDirty = ref(false)
  const lastSavedAt = ref<string | null>(null)

  // ─── 计算属性 ───
  const scene = computed<Scene>(() => doc.value.scene)
  /** 当前激活的图层列表（自动路由到当前页面，单页面模式回退到 scene.children） */
  const layers = computed<Layer[]>(() => getCurrentLayers(doc.value))
  /** 所有页面（多页面模式，单页面模式返回空数组） */
  const pages = computed<Page[]>(() => listAllPages(doc.value))
  /** 当前页面（多页面模式） */
  const currentPage = computed<Page | null>(() => getCurrentPage(doc.value))
  /** 是否为多页面文档 */
  const isMultiPage = computed<boolean>(() => pages.value.length > 0)
  const currentPageId = computed<string | null>(() => doc.value.scene.currentPageId ?? null)
  /** Frame 相关（无限画布模式） */
  const frames = computed<Frame[]>(() => listAllFrames(doc.value))
  const currentFrame = computed<Frame | null>(() => getCurrentFrame(doc.value))
  const isFramesMode = computed<boolean>(() => frames.value.length > 0)
  const selectedFrameId = computed<string | null>(() => doc.value.scene.selectedFrameId ?? null)
  const selectedLayer = computed<Layer | null>(() =>
    selectedLayerId.value ? findLayerById(doc.value, selectedLayerId.value) ?? null : null,
  )
  const selectedObjects = computed<SceneObject[]>(() => {
    if (!selectedLayerId.value) return []
    const layer = findLayerById(doc.value, selectedLayerId.value)
    if (!layer) return []
    return layer.objects.filter(o => selectedObjectIds.value.includes(o.id))
  })
  const sceneInfo = computed(() => getSceneInfo(doc.value))
  const docSize = computed(() => estimateSize(doc.value))
  const canUndo = computed(() => undoStack.value.length > 0)
  const canRedo = computed(() => redoStack.value.length > 0)

  /* ════════════════ 历史记录 ════════════════ */

  function pushHistory(description: string): void {
    undoStack.value.push({
      description,
      snapshot: deepClone(doc.value),
      timestamp: Date.now(),
    })
    if (undoStack.value.length > MAX_HISTORY) undoStack.value.shift()
    redoStack.value = []
    isDirty.value = true
  }

  function undo(): void {
    const entry = undoStack.value.pop()
    if (!entry) return
    redoStack.value.push({ description: entry.description, snapshot: deepClone(doc.value), timestamp: Date.now() })
    doc.value = entry.snapshot
    isDirty.value = true
  }

  function redo(): void {
    const entry = redoStack.value.pop()
    if (!entry) return
    undoStack.value.push({ description: entry.description, snapshot: deepClone(doc.value), timestamp: Date.now() })
    doc.value = entry.snapshot
    isDirty.value = true
  }

  function clearHistory(): void {
    undoStack.value = []
    redoStack.value = []
  }

  /* ════════════════ 选择 ════════════════ */

  function selectLayer(layerId: string | null): void {
    selectedLayerId.value = layerId
    selectedObjectIds.value = []
  }

  function selectObject(objId: string, additive = false): void {
    // 自动找到对象所在的图层并设置 selectedLayerId
    const found = findObjectInDoc(doc.value, objId)
    if (found && selectedLayerId.value !== found.layer.id) {
      selectedLayerId.value = found.layer.id
    }
    if (!additive) {
      selectedObjectIds.value = [objId]
    } else {
      if (selectedObjectIds.value.includes(objId)) {
        selectedObjectIds.value = selectedObjectIds.value.filter(id => id !== objId)
      } else {
        selectedObjectIds.value.push(objId)
      }
    }
  }

  function deselectAll(): void {
    selectedLayerId.value = null
    selectedObjectIds.value = []
  }

  /* ════════════════ Layer 操作 ════════════════ */

  function newLayer(name?: string): Layer {
    pushHistory(`新增图层`)
    const layer = createLayer({ name: name ?? `图层 ${layers.value.length + 1}` })
    return addLayer(doc.value, layer)
  }

  function deleteLayer(layerId: string): void {
    pushHistory(`删除图层`)
    removeLayer(doc.value, layerId)
    if (selectedLayerId.value === layerId) selectedLayerId.value = null
  }

  function reorderLayer(fromIndex: number, toIndex: number): void {
    pushHistory(`重排图层`)
    moveLayer(doc.value, fromIndex, toIndex)
  }

  function cloneLayer(layerId: string): void {
    pushHistory(`复制图层`)
    duplicateLayer(doc.value, layerId)
  }

  function renameLayer(layerId: string, name: string): void {
    pushHistory(`重命名图层`)
    const layer = findLayerById(doc.value, layerId)
    if (layer) layer.name = name
  }

  function toggleLayerVisible(layerId: string): void {
    const layer = findLayerById(doc.value, layerId)
    if (!layer) return
    pushHistory(`${layer.visible ? '隐藏' : '显示'}图层`)
    layer.visible = !layer.visible
  }

  function toggleLayerLocked(layerId: string): void {
    const layer = findLayerById(doc.value, layerId)
    if (!layer) return
    pushHistory(`${layer.locked ? '解锁' : '锁定'}图层`)
    layer.locked = !layer.locked
  }

  function setLayerBlendMode(layerId: string, blendMode: BlendMode): void {
    const layer = findLayerById(doc.value, layerId)
    if (!layer) return
    pushHistory(`设置混合模式 ${blendMode}`)
    layer.blendMode = blendMode
  }

  /* ════════════════ Object 操作 ════════════════ */

  function newObject(layerId: string, type: SceneObject['type'], params?: Parameters<typeof createObjectByType>[1]): SceneObject | undefined {
    pushHistory(`新增 ${type}`)
    const obj = createObjectByType(type, params)
    if (addObjectToLayer(doc.value, layerId, obj)) return obj
    return undefined
  }

  function deleteObject(layerId: string, objId: string): void {
    pushHistory(`删除对象`)
    removeObjectFromLayer(doc.value, layerId, objId)
    selectedObjectIds.value = selectedObjectIds.value.filter(id => id !== objId)
  }

  function reorderObject(layerId: string, fromIndex: number, toIndex: number): void {
    pushHistory(`重排对象`)
    moveObjectInLayer(doc.value, layerId, fromIndex, toIndex)
  }

  function groupSelected(layerId: string): SceneObject | undefined {
    if (selectedObjectIds.value.length < 2) return undefined
    pushHistory(`编组对象`)
    const group = groupObjects(doc.value, layerId, selectedObjectIds.value)
    if (group) selectedObjectIds.value = [group.id]
    return group
  }

  function ungroupSelected(layerId: string, groupId: string): void {
    pushHistory(`解组对象`)
    ungroupObjects(doc.value, layerId, groupId)
    selectedObjectIds.value = []
  }

  /* ════════════════ 对象属性更新（外观/变换） ════════════════ */

  /**
   * 通用对象属性更新：以 patch 形式合并到目标对象。
   * 自动 pushHistory 并触发响应式更新。
   * @param objId 目标对象 ID
   * @param patch 要合并的字段（浅合并，支持嵌套 transform）
   * @param description 历史记录描述
   * @param skipHistory 跳过历史记录（用于连续拖拽等场景，调用方需自行记录一次）
   */
  function updateObject(
    objId: string,
    patch: Record<string, unknown>,
    description = '修改属性',
    skipHistory = false,
  ): void {
    const found = findObjectInDoc(doc.value, objId)
    if (!found) return
    if (!skipHistory) pushHistory(description)
    const obj = found.obj as unknown as Record<string, unknown>
    for (const key of Object.keys(patch)) {
      const value = patch[key]
      if (key === 'transform' && typeof value === 'object' && value !== null) {
        // 浅合并 transform 子字段
        const tOld = ((obj.transform as unknown) ?? {}) as Record<string, unknown>
        const tNew = value as Record<string, unknown>
        obj.transform = { ...tOld, ...tNew }
      } else {
        obj[key] = value
      }
    }
  }

  /** 批量更新多个对象的同一外观字段 */
  function updateObjectsAppearance(
    objIds: string[],
    patch: Record<string, unknown>,
    description = '修改外观',
  ): void {
    if (objIds.length === 0) return
    pushHistory(description)
    for (const id of objIds) {
      const found = findObjectInDoc(doc.value, id)
      if (!found) continue
      const obj = found.obj as unknown as Record<string, unknown>
      for (const key of Object.keys(patch)) {
        const value = patch[key]
        if (key === 'transform' && typeof value === 'object' && value !== null) {
          const tOld = ((obj.transform as unknown) ?? {}) as Record<string, unknown>
          const tNew = value as Record<string, unknown>
          obj.transform = { ...tOld, ...tNew }
        } else {
          obj[key] = value
        }
      }
    }
  }

  /* ════════════════ 蒙版 & 效果 ════════════════ */

  function addMask(layerId: string, mask?: Mask): void {
    pushHistory(`添加蒙版`)
    addMaskToLayer(doc.value, layerId, mask ?? createMask('raster'))
  }

  function toggleMask(layerId: string): void {
    pushHistory(`切换蒙版`)
    toggleLayerMask(doc.value, layerId)
  }

  function addEffect(layerId: string, effectType: LayerEffect['type']): void {
    pushHistory(`添加效果 ${effectType}`)
    const fx = createLayerEffect(effectType)
    addLayerEffect(doc.value, layerId, fx)
  }

  function removeEffect(layerId: string, effectId: string): void {
    pushHistory(`删除效果`)
    removeLayerEffect(doc.value, layerId, effectId)
  }

  /* ════════════════ Page 操作（多页面模式） ════════════════ */

  /** 新增页面 */
  function newPage(params?: Parameters<typeof createPage>[0]): Page {
    pushHistory(`新增页面`)
    return opsAddPage(doc.value, params)
  }

  /** 复制当前页面或指定页面 */
  function duplicatePageById(pageId: string): Page | null {
    pushHistory(`复制页面`)
    const result = opsDuplicatePage(doc.value, pageId)
    return result
  }

  /** 删除页面（至少保留一页） */
  function deletePageById(pageId: string): boolean {
    // 先校验是否可删除
    if (!doc.value.scene.pages || doc.value.scene.pages.length <= 1) return false
    if (!doc.value.scene.pages.find(p => p.id === pageId)) return false
    pushHistory(`删除页面`)
    opsDeletePage(doc.value, pageId)
    // 切到剩余页面（如果删除的是当前页，ops 已自动切换）
    selectedLayerId.value = null
    selectedObjectIds.value = []
    return true
  }

  /** 切换当前页面 */
  function switchToPage(pageId: string): boolean {
    if (!doc.value.scene.pages?.find(p => p.id === pageId)) return false
    if (doc.value.scene.currentPageId === pageId) return false
    pushHistory(`切换页面`)
    opsSwitchPage(doc.value, pageId)
    // 切换页面时清空选中状态
    selectedLayerId.value = null
    selectedObjectIds.value = []
    return true
  }

  /** 重命名页面 */
  function renamePageById(pageId: string, name: string): boolean {
    const page = listAllPages(doc.value).find(p => p.id === pageId)
    if (!page) return false
    if (page.name === name) return false
    pushHistory(`重命名页面`)
    opsRenamePage(doc.value, pageId, name)
    return true
  }

  /** 重排页面 */
  function reorderPage(pageId: string, newIndex: number): boolean {
    if (!doc.value.scene.pages) return false
    const curIdx = doc.value.scene.pages.findIndex(p => p.id === pageId)
    if (curIdx < 0) return false
    pushHistory(`重排页面`)
    opsMovePage(doc.value, pageId, newIndex)
    return true
  }

  /** 切换页面隐藏状态 */
  function togglePageHidden(pageId: string): void {
    const page = listAllPages(doc.value).find(p => p.id === pageId)
    if (!page) return
    pushHistory(`${page.hidden ? '显示' : '隐藏'}页面`)
    page.hidden = !page.hidden
  }

  /** 复制对象到指定页面 */
  function copyObjectToPageById(objId: string, targetPageId: string): SceneObject | null {
    pushHistory(`跨页复制对象`)
    return opsCopyObjectToPage(doc.value, objId, targetPageId)
  }

  /** 多页面模式切换（启用/禁用 pages 字段） */
  function enableMultiPageMode(): void {
    if (isMultiPage.value) return
    pushHistory(`启用多页面模式`)
    // 将现有 scene.children 转换为第一个页面
    const firstPage = createPage({
      name: `页面 1`,
      children: doc.value.scene.children.map(l => deepClone(l)),
    })
    doc.value.scene.pages = [firstPage]
    doc.value.scene.currentPageId = firstPage.id
    doc.value.scene.children = []
  }

  /* ════════════════ Frame 操作（无限画布 + 融合多重模式） ════════════════ */

  /** 新增 Frame */
  function newFrame(params?: Parameters<typeof createFrame>[0]): Frame {
    pushHistory(`新增画板`)
    return opsAddFrame(doc.value, params)
  }

  /** 复制 Frame */
  function duplicateFrameById(frameId: string): Frame | null {
    pushHistory(`复制画板`)
    return opsDuplicateFrame(doc.value, frameId)
  }

  /** 删除 Frame */
  function deleteFrameById(frameId: string): boolean {
    if (!doc.value.scene.frames || doc.value.scene.frames.length <= 1) return false
    if (!doc.value.scene.frames.find(f => f.id === frameId)) return false
    pushHistory(`删除画板`)
    opsDeleteFrame(doc.value, frameId)
    selectedLayerId.value = null
    selectedObjectIds.value = []
    return true
  }

  /** 切换当前 Frame */
  function switchToFrame(frameId: string): boolean {
    if (!doc.value.scene.frames?.find(f => f.id === frameId)) return false
    if (doc.value.scene.selectedFrameId === frameId) return false
    pushHistory(`切换画板`)
    opsSwitchFrame(doc.value, frameId)
    selectedLayerId.value = null
    selectedObjectIds.value = []
    return true
  }

  /** 重命名 Frame */
  function renameFrameById(frameId: string, name: string): boolean {
    const frame = findFrameById(doc.value, frameId)
    if (!frame || frame.name === name) return false
    pushHistory(`重命名画板`)
    opsRenameFrame(doc.value, frameId, name)
    return true
  }

  /** 移动 Frame 位置 */
  function moveFrameTo(frameId: string, x: number, y: number): void {
    opsMoveFrame(doc.value, frameId, x, y)
  }

  /** 调整 Frame 尺寸 */
  function resizeFrameTo(frameId: string, width: number, height: number): void {
    opsResizeFrame(doc.value, frameId, width, height)
  }

  /** 重排 Frame 顺序 */
  function reorderFrame(frameId: string, newIndex: number): boolean {
    if (!doc.value.scene.frames) return false
    pushHistory(`重排画板`)
    return opsMoveFrameOrder(doc.value, frameId, newIndex)
  }

  /** 切换 Frame 隐藏状态 */
  function toggleFrameHidden(frameId: string): void {
    const frame = findFrameById(doc.value, frameId)
    if (!frame) return
    pushHistory(`${frame.hidden ? '显示' : '隐藏'}画板`)
    frame.hidden = !frame.hidden
  }

  /** 更新无限画布视口 */
  function updateCanvasViewport(viewport: Parameters<typeof opsUpdateViewport>[1]): void {
    opsUpdateViewport(doc.value, viewport)
  }

  /** 鸟瞰视图：适配视口到所有 Frame */
  function fitToFrames(viewportWidth: number, viewportHeight: number): void {
    pushHistory(`适配视图`)
    opsFitViewportToFrames(doc.value, viewportWidth, viewportHeight)
  }

  /** 启用 Frame 模式（从 pages/children 迁移到 frames） */
  function enableFramesMode(initialFrames?: Frame[]): void {
    if (isFramesMode.value && !initialFrames) return
    pushHistory(`启用无限画布模式`)
    if (initialFrames) {
      // 使用传入的预设 Frame 列表
      doc.value.scene.frames = initialFrames
      doc.value.scene.selectedFrameId = initialFrames[0]?.id
      opsEnsureInfiniteCanvas(doc.value)
      // 将旧数据迁移：把 scene.children 的图层放到第一个 Frame
      if (doc.value.scene.children.length > 0 && initialFrames[0]) {
        initialFrames[0].children = doc.value.scene.children.map(l => deepClone(l))
      }
      doc.value.scene.children = []
      doc.value.scene.pages = undefined
      doc.value.scene.currentPageId = undefined
    } else if (!isFramesMode.value) {
      // 从 pages 或 children 迁移到 frames
      const newFrames: Frame[] = []
      if (isMultiPage.value) {
        // 从 pages 转换
        let cursorX = 0
        pages.value.forEach((page, i) => {
          const f = createFrame({
            type: 'single',
            name: page.name,
            x: cursorX,
            y: 0,
            width: page.width ?? doc.value.scene.canvasWidth,
            height: page.height ?? doc.value.scene.canvasHeight,
            children: page.children.map(l => deepClone(l)),
          })
          newFrames.push(f)
          cursorX += (page.width ?? doc.value.scene.canvasWidth) + 80
        })
      } else {
        // 从 children 转换
        newFrames.push(createFrame({
          type: 'single',
          name: '页面 1',
          x: 0,
          y: 0,
          width: doc.value.scene.canvasWidth,
          height: doc.value.scene.canvasHeight,
          children: doc.value.scene.children.map(l => deepClone(l)),
        }))
      }
      doc.value.scene.frames = newFrames
      doc.value.scene.selectedFrameId = newFrames[0]?.id
      opsEnsureInfiniteCanvas(doc.value)
      doc.value.scene.children = []
      doc.value.scene.pages = undefined
      doc.value.scene.currentPageId = undefined
    }
  }

  /* ════════════════ 文档级操作 ════════════════ */

  function newDocument(params: Parameters<typeof createScene>[0] = {}): void {
    doc.value = {
      version: HDS_FORMAT_VERSION,
      scene: createScene(params),
      metadata: {
        createdAt: new Date().toISOString(),
        modifiedAt: new Date().toISOString(),
      },
    }
    clearHistory()
    isDirty.value = false
    deselectAll()
  }

  /** 根据指定 Frame 类型创建新文档（启用无限画布模式）
   *  - single: 单页画板（A4 竖向，595×842）
   *  - poster: 海报画板（A3 竖向，297×420 → 实际用更大尺寸 595×842）
   *  - book-page: 书籍单页（A4 折页，297×420）
   *  - spread: 对页展开（594×420）
   */
  function newDocumentWithFrameType(frameType: FrameType = 'single'): void {
    // 创建空 scene
    newDocument({ canvasWidth: 595, canvasHeight: 842, name: '未命名.hds' })
    // 清空默认 children（newDocument 创建的 scene.children 默认为空，无需清空）
    // 创建指定类型的初始 Frame
    const frame = createFrame({
      type: frameType,
      name: FRAME_DEFAULTS[frameType].name,
      x: 0,
      y: 0,
      width: FRAME_DEFAULTS[frameType].width,
      height: FRAME_DEFAULTS[frameType].height,
    })
    doc.value.scene.frames = [frame]
    doc.value.scene.selectedFrameId = frame.id
    doc.value.scene.canvas = {
      viewportX: 0,
      viewportY: 0,
      zoom: 1,
      background: 'grid',
      showRulers: false,
    }
    clearHistory()
    isDirty.value = false
    deselectAll()
  }

  function loadDocument(json: string): void {
    try {
      const parsed = deserialize(json)
      if (!parsed || !parsed.scene) throw new Error('Invalid document structure')
      doc.value = parsed
      clearHistory()
      isDirty.value = false
      deselectAll()
      lastSavedAt.value = new Date().toISOString()
    } catch (err) {
      console.error('[FusionDoc] loadDocument failed:', err)
      throw new Error(`文档加载失败: ${err instanceof Error ? err.message : String(err)}`)
    }
  }

  function saveDocument(): string {
    doc.value.metadata.modifiedAt = new Date().toISOString()
    isDirty.value = false
    lastSavedAt.value = new Date().toISOString()
    return serialize(doc.value, true)
  }

  function exportToJson(): string {
    return serialize(doc.value, true)
  }

  /** 内部：创建默认文档（含示例图层与对象，用于演示渲染）
   *  默认启用无限画布模式（frames），将所有示例图层放入第一个 Frame 中。
   */
  function createDefaultDocument(): HdsDocument {
    const scene = createScene({ canvasWidth: 595, canvasHeight: 842, name: '未命名.hds' })

    // 示例：背景图层（含形状）
    const bgLayer = createLayer({ name: '背景' })
    bgLayer.parentId = scene.id
    const bgShape = createShapeObject({
      name: '画布背景',
      x: 0,
      y: 0,
      width: 595,
      height: 842,
      fill: '#FFFFFF',
      stroke: '#E5E7EB',
      strokeWidth: 0,
    })
    bgLayer.objects.push(bgShape)

    // 示例：标题图层（含文本与装饰）
    const titleLayer = createLayer({ name: '标题' })
    titleLayer.parentId = scene.id
    const title1 = createTextObject({
      name: '主标题',
      text: '构想，',
      x: 40,
      y: 80,
      width: 400,
      height: 60,
      fontSize: 48,
      fontWeight: 800,
      color: '#1F2329',
      fontFamily: 'HarmonyOS Sans SC',
    })
    const title2 = createTextObject({
      name: '副标题',
      text: '让设计发生',
      x: 40,
      y: 140,
      width: 400,
      height: 60,
      fontSize: 48,
      fontWeight: 800,
      color: '#1F2329',
      fontFamily: 'HarmonyOS Sans SC',
    })
    const decoLine = createShapeObject({
      name: '装饰线',
      shape: 'rectangle',
      x: 40,
      y: 210,
      width: 64,
      height: 4,
      fill: '#3AC487',
      strokeWidth: 0,
    })
    titleLayer.objects.push(title1, title2, decoLine)

    // 示例：内容图层（图片占位 + 文本）
    const contentLayer = createLayer({ name: '内容' })
    contentLayer.parentId = scene.id
    const placeholderImg = createShapeObject({
      name: '图片占位',
      shape: 'rectangle',
      x: 40,
      y: 240,
      width: 360,
      height: 220,
      fill: '#F3F4F6',
      stroke: '#D1D5DB',
      strokeWidth: 1,
      cornerRadius: 4,
    })
    const bodyText = createTextObject({
      name: '正文段落',
      text: '连接矢量、图像与版式，\n在统一画布中建立清晰、\n可复用的视觉语言。',
      x: 40,
      y: 490,
      width: 360,
      height: 80,
      fontSize: 14,
      fontWeight: 400,
      color: '#4B5563',
      fontFamily: 'HarmonyOS Sans SC',
      lineHeight: 1.6,
    })
    contentLayer.objects.push(placeholderImg, bodyText)

    // 示例：底部信息图层
    const footerLayer = createLayer({ name: '页脚' })
    footerLayer.parentId = scene.id
    const footerText = createTextObject({
      name: '页脚',
      text: 'HARMONY / DESIGN / 2026',
      x: 40,
      y: 780,
      width: 300,
      height: 16,
      fontSize: 10,
      fontWeight: 700,
      color: '#3AC487',
      fontFamily: 'HarmonyOS Sans SC',
    })
    footerLayer.objects.push(footerText)

    // ─── 启用无限画布模式：将所有图层放入第一个 Frame ───
    const demoLayers = [bgLayer, titleLayer, contentLayer, footerLayer]
    const firstFrame = createFrame({
      type: 'single',
      name: '封面',
      x: 0,
      y: 0,
      width: 595,
      height: 842,
      children: demoLayers,
    })
    scene.frames = [firstFrame]
    scene.selectedFrameId = firstFrame.id
    scene.canvas = {
      viewportX: 0,
      viewportY: 0,
      zoom: 1,
      background: 'grid',
      showRulers: false,
    }
    // scene.children 留空（frames 模式下不使用）

    return {
      version: HDS_FORMAT_VERSION,
      scene,
      metadata: {
        createdAt: new Date().toISOString(),
        modifiedAt: new Date().toISOString(),
      },
    }
  }

  return {
    // state
    doc, selectedLayerId, selectedObjectIds, isDirty, lastSavedAt,
    undoStack, redoStack,
    // computed
    scene, layers, pages, currentPage, isMultiPage, currentPageId,
    frames, currentFrame, isFramesMode, selectedFrameId,
    selectedLayer, selectedObjects, sceneInfo, docSize, canUndo, canRedo,
    // history
    pushHistory, undo, redo, clearHistory,
    // selection
    selectLayer, selectObject, deselectAll,
    // layer ops
    newLayer, deleteLayer, reorderLayer, cloneLayer, renameLayer,
    toggleLayerVisible, toggleLayerLocked, setLayerBlendMode,
    // object ops
    newObject, deleteObject, reorderObject, groupSelected, ungroupSelected,
    updateObject, updateObjectsAppearance,
    // mask & effect
    addMask, toggleMask, addEffect, removeEffect,
    // page ops
    newPage, duplicatePageById, deletePageById, switchToPage,
    renamePageById, reorderPage, togglePageHidden,
    copyObjectToPageById, enableMultiPageMode,
    // frame ops
    newFrame, duplicateFrameById, deleteFrameById, switchToFrame,
    renameFrameById, moveFrameTo, resizeFrameTo, reorderFrame,
    toggleFrameHidden, updateCanvasViewport, fitToFrames, enableFramesMode,
    // document ops
    newDocument, newDocumentWithFrameType, loadDocument, saveDocument, exportToJson,
    // helpers
    listAllLayers: () => listAllLayers(doc.value),
    listAllObjects: () => listAllObjects(doc.value),
    listAllPages: () => listAllPages(doc.value),
    listAllFrames: () => listAllFrames(doc.value),
    getCurrentPage: () => getCurrentPage(doc.value),
    getCurrentFrame: () => getCurrentFrame(doc.value),
    getCurrentLayers: () => getCurrentLayers(doc.value),
  }
})
