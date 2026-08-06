/**
 * FusionDocumentStore - Fusion 文档状态管理（鸿蒙端）
 *
 * 对应原型 src/stores/fusionDocument.ts
 * 使用 AppStorage 实现全局响应式，配合 @StorageLink 在组件中订阅。
 */
import { HdsDocument, Scene, Layer, Frame, SceneObject, Transform, LayerEffect, BlendMode } from '../types/SceneTypes'
import { createScene, createLayer, genId } from '../types/FusionFactory'
import {
  getCurrentFrame, getCurrentLayers, getCurrentPage,
  addFrame, removeFrame, duplicateFrame, findFrameById, updateFrame,
  addLayer, findLayerById, removeLayer,
  findObjectInDoc, addObjectToLayer, updateObjectTransform,
  listAllObjects, getFramesBoundingBox, fitViewportToFrames,
} from '../types/FusionOps'
import { FusionDocumentStoreInfo } from './FusionDocumentStoreInfo'
import { serialize, deserialize, deepClone, estimateSize } from '../types/FusionSerializer'

/** 历史记录条目 */
export interface HistoryEntry {
  key: string
  label: string
  icon: string
  index: number
  current: boolean
  future: boolean
  canRedo: boolean
}

export class FusionDocumentStore {
  private static instance: FusionDocumentStore
  private doc: HdsDocument
  private selectedObjectIds: string[] = []
  private historyStack: string[] = []
  private historyIndex: number = -1
  private historyLabels: string[] = []
  private clipboard: SceneObject[] = []

  private constructor() {
    this.doc = this.createDefaultDocument()
  }

  static getInstance(): FusionDocumentStore {
    if (!FusionDocumentStore.instance) {
      FusionDocumentStore.instance = new FusionDocumentStore()
    }
    return FusionDocumentStore.instance
  }

  /** 创建默认文档 */
  private createDefaultDocument(): HdsDocument {
    const scene = createScene()
    const doc: HdsDocument = {
      version: '3.0',
      scene,
      metadata: {
        createdAt: new Date().toISOString(),
        modifiedAt: new Date().toISOString(),
      },
    }
    return doc
  }

  /** 初始化 */
  init(): void {
    AppStorage.setOrCreate<number>('historyVersion', 0)
    AppStorage.setOrCreate<number>('selectionVersion', 0)
    this.loadFromStorage()
    this.pushHistory()
  }

  /** 自动保存（防抖 500ms） */
  private autoSaveTimer: number = -1
  private scheduleAutoSave(): void {
    if (this.autoSaveTimer >= 0) {
      clearTimeout(this.autoSaveTimer)
    }
    this.autoSaveTimer = setTimeout(() => {
      this.saveToStorage()
    }, 500)
  }

  /** 保存文档到 AppStorage */
  saveToStorage(): void {
    try {
      const json = serialize(this.doc, true)
      AppStorage.setOrCreate<string>('hds_document', json)
      const now = new Date().toISOString()
      AppStorage.setOrCreate<string>('hds_last_saved', now)
      AppStorage.setOrCreate<string>('hds_save_status', '已自动保存')
    } catch (e) {
      AppStorage.setOrCreate<string>('hds_save_status', '保存失败')
      console.error('FusionDocumentStore', 'saveToStorage failed: ' + e)
    }
  }

  /** 从 AppStorage 加载文档 */
  loadFromStorage(): void {
    try {
      const json = AppStorage.get<string>('hds_document')
      if (json !== undefined && json.length > 0) {
        this.doc = deserialize(json)
        console.info('FusionDocumentStore', 'Loaded document from storage, size: ' + estimateSize(this.doc) + 'KB')
      }
    } catch (e) {
      console.error('FusionDocumentStore', 'loadFromStorage failed: ' + e)
    }
  }

  /** 清除存储的文档 */
  clearStorage(): void {
    AppStorage.delete('hds_document')
    AppStorage.delete('hds_last_saved')
  }

  /** 获取文档 */
  getDocument(): HdsDocument {
    return this.doc
  }

  getScene(): Scene {
    return this.doc.scene
  }

  getFrames(): Frame[] {
    return this.doc.scene.frames ?? []
  }

  getIsFramesMode(): boolean {
    return !!(this.doc.scene.frames && this.doc.scene.frames.length > 0)
  }

  getSelectedFrameId(): string {
    return this.doc.scene.selectedFrameId ?? ''
  }

  getCurrentFrame(): Frame | null {
    return getCurrentFrame(this.doc)
  }

  getCurrentLayers(): Layer[] {
    return getCurrentLayers(this.doc)
  }

  getSelectedObjects(): SceneObject[] {
    const all = listAllObjects(this.doc)
    return all.filter(o => this.selectedObjectIds.includes(o.id))
  }

  /* ════════════════ Frame action ════════════════ */

  newFrame(type?: string, name?: string, x?: number, y?: number): Frame {
    const frame = addFrame(this.doc, type, name, x, y)
    this.pushHistory()
    return frame
  }

  switchFrame(frameId: string): void {
    this.doc.scene.selectedFrameId = frameId
    this.selectedObjectIds = []
    AppStorage.setOrCreate<number>('selectionVersion', Date.now())
  }

  duplicateCurrentFrame(): Frame | null {
    if (!this.getSelectedFrameId()) return null
    const f = duplicateFrame(this.doc, this.getSelectedFrameId())
    if (f) this.pushHistory()
    return f
  }

  removeCurrentFrame(): boolean {
    if (!this.getSelectedFrameId()) return false
    const ok = removeFrame(this.doc, this.getSelectedFrameId())
    if (ok) this.pushHistory()
    return ok
  }

  updateFrameById(frameId: string, x?: number, y?: number, width?: number, height?: number, name?: string, hidden?: boolean): void {
    updateFrame(this.doc, frameId, x, y, width, height, name, hidden)
    this.pushHistory()
  }

  fitToFrames(viewportWidth: number, viewportHeight: number): void {
    fitViewportToFrames(this.doc, viewportWidth, viewportHeight)
  }

  /* ════════════════ Object action ════════════════ */

  newObject(obj: SceneObject, layerId?: string): void {
    const targetLayerId = layerId ?? this.getCurrentLayers()[0]?.id
    if (!targetLayerId) {
      const newLayer = addLayer(this.doc)
      addObjectToLayer(this.doc, newLayer.id, obj)
    } else {
      addObjectToLayer(this.doc, targetLayerId, obj)
    }
    this.selectedObjectIds = [obj.id]
    this.pushHistory()
  }

  selectAllObjects(): void {
    const all = listAllObjects(this.doc)
    this.selectedObjectIds = all.map(o => o.id)
  }

  selectObject(objId: string | null, additive?: boolean): void {
    if (objId === null) {
      this.selectedObjectIds = []
      AppStorage.setOrCreate<number>('selectionVersion', Date.now())
      return
    }
    if (additive) {
      const idx = this.selectedObjectIds.indexOf(objId)
      if (idx >= 0) {
        this.selectedObjectIds.splice(idx, 1)
      } else {
        this.selectedObjectIds.push(objId)
      }
    } else {
      this.selectedObjectIds = [objId]
    }
    AppStorage.setOrCreate<number>('selectionVersion', Date.now())
  }

  moveObject(objId: string, x: number, y: number, skipHistory?: boolean): void {
    updateObjectTransform(this.doc, objId, x, y)
    if (!skipHistory) this.pushHistory()
  }

  updateObjectTransform(objId: string, x?: number, y?: number, width?: number, height?: number, rotation?: number, scaleX?: number, scaleY?: number): void {
    updateObjectTransform(this.doc, objId, x, y, width, height, rotation)
    const found = findObjectInDoc(this.doc, objId)
    if (found) {
      if (scaleX !== undefined) found.obj.transform.scaleX = scaleX
      if (scaleY !== undefined) found.obj.transform.scaleY = scaleY
    }
    this.pushHistory('变换对象')
  }

  updateObjectAppearance(objId: string, key: string, value: number | string | boolean): void {
    const found = findObjectInDoc(this.doc, objId)
    if (!found) return
    if (key === 'fill') found.obj.fill = value as string
    else if (key === 'stroke') found.obj.stroke = value as string
    else if (key === 'strokeWidth') found.obj.strokeWidth = value as number
    else if (key === 'cornerRadius') found.obj.cornerRadius = value as number
    else if (key === 'opacity') found.obj.transform.opacity = value as number
    else if (key === 'flipH') found.obj.transform.flipH = value as boolean
    else if (key === 'flipV') found.obj.transform.flipV = value as boolean
    else if (key === 'blendMode') found.obj.blendMode = value as BlendMode
    else if (key === 'strokePosition') found.obj.strokePosition = value as string
    this.pushHistory('修改外观')
  }

  removeObjectById(objId: string): void {
    this.removeObjectInternal(objId)
    this.selectedObjectIds = this.selectedObjectIds.filter(id => id !== objId)
    this.pushHistory()
  }

  private removeObjectInternal(objId: string): void {
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const idx = layer.objects.findIndex(o => o.id === objId)
      if (idx >= 0) {
        layer.objects.splice(idx, 1)
        return
      }
    }
  }

  duplicateObject(objId: string): void {
    const found = findObjectInDoc(this.doc, objId)
    if (!found) return
    // 简化：克隆对象
    const srcObj = found.obj
    const cloned: SceneObject = JSON.parse(JSON.stringify(srcObj)) as object as SceneObject
    cloned.id = `${srcObj.type}_${Date.now().toString(36)}`
    const newTransform: Transform = {
      x: srcObj.transform.x + 20,
      y: srcObj.transform.y + 20,
      width: srcObj.transform.width,
      height: srcObj.transform.height,
      rotation: srcObj.transform.rotation,
      scaleX: srcObj.transform.scaleX,
      scaleY: srcObj.transform.scaleY,
      flipH: srcObj.transform.flipH,
      flipV: srcObj.transform.flipV,
      opacity: srcObj.transform.opacity,
    }
    cloned.transform = newTransform
    found.layer.objects.push(cloned)
    this.selectedObjectIds = [cloned.id]
    this.pushHistory()
  }

  /* ════════════════ 锁定/隐藏/编组/图层顺序 ════════════════ */

  toggleObjectLock(objId: string): void {
    const found = findObjectInDoc(this.doc, objId)
    if (found) {
      found.obj.locked = !found.obj.locked
      this.pushHistory()
    }
  }

  toggleObjectVisible(objId: string): void {
    const found = findObjectInDoc(this.doc, objId)
    if (found) {
      found.obj.visible = !found.obj.visible
      this.pushHistory()
    }
  }

  groupObjects(objIds: string[]): void {
    if (objIds.length < 2) return
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const groupObjects: SceneObject[] = []
      const remaining: SceneObject[] = []
      for (const obj of layer.objects) {
        if (objIds.includes(obj.id)) {
          groupObjects.push(obj)
        } else {
          remaining.push(obj)
        }
      }
      if (groupObjects.length >= 2) {
        const groupObj: SceneObject = {
          id: genId('group'),
          type: 'group',
          name: '编组',
          transform: {
            x: 0, y: 0, width: 0, height: 0, rotation: 0,
            scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100,
          },
          blendMode: 'normal',
          visible: true,
          locked: false,
          children: groupObjects,
        }
        remaining.push(groupObj)
        layer.objects = remaining
        this.selectedObjectIds = [groupObj.id]
        this.pushHistory('编组对象')
        return
      }
    }
  }

  ungroupObjects(groupId: string): void {
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const idx = layer.objects.findIndex(o => o.id === groupId)
      if (idx >= 0 && layer.objects[idx].type === 'group' && layer.objects[idx].children) {
        const group = layer.objects[idx]
        const children = group.children ?? []
        layer.objects.splice(idx, 1, ...children)
        this.selectedObjectIds = children.map(c => c.id)
        this.pushHistory('解组对象')
        return
      }
    }
  }

  private moveObjectInLayer(objId: string, targetIndex: number): void {
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const idx = layer.objects.findIndex(o => o.id === objId)
      if (idx >= 0) {
        const obj = layer.objects.splice(idx, 1)[0]
        const clamped = Math.max(0, Math.min(targetIndex, layer.objects.length))
        layer.objects.splice(clamped, 0, obj)
        this.pushHistory('调整图层顺序')
        return
      }
    }
  }

  bringToFront(objId: string): void {
    this.moveObjectInLayer(objId, Infinity)
  }

  bringForward(objId: string): void {
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const idx = layer.objects.findIndex(o => o.id === objId)
      if (idx >= 0) {
        this.moveObjectInLayer(objId, idx + 1)
        return
      }
    }
  }

  sendBackward(objId: string): void {
    const layers = getCurrentLayers(this.doc)
    for (const layer of layers) {
      const idx = layer.objects.findIndex(o => o.id === objId)
      if (idx >= 0) {
        this.moveObjectInLayer(objId, idx - 1)
        return
      }
    }
  }

  sendToBack(objId: string): void {
    this.moveObjectInLayer(objId, 0)
  }

  /* ════════════════ 历史记录 ════════════════ */

  private notifyHistoryChange(): void {
    AppStorage.setOrCreate<number>('historyVersion', Date.now())
  }

  pushHistory(label?: string): void {
    this.scheduleAutoSave()
    this.historyStack = this.historyStack.slice(0, this.historyIndex + 1)
    this.historyLabels = this.historyLabels.slice(0, this.historyIndex + 1)
    this.historyLabels.push(label ?? 'action')
    const snapshot = JSON.stringify(this.doc)
    this.historyStack.push(snapshot)
    if (this.historyStack.length > 50) {
      this.historyStack.shift()
      this.historyLabels.shift()
    } else {
      this.historyIndex++
    }
    this.doc.metadata.modifiedAt = new Date().toISOString()
    this.notifyHistoryChange()
  }

  getHistoryUndoCount(): number {
    return this.historyIndex
  }

  getHistoryRedoCount(): number {
    return Math.max(0, this.historyStack.length - 1 - this.historyIndex)
  }

  canUndo(): boolean {
    return this.historyIndex > 0
  }

  canRedo(): boolean {
    return this.historyIndex < this.historyStack.length - 1
  }

  undo(): void {
    if (!this.canUndo()) return
    this.historyIndex--
    const snapshot = this.historyStack[this.historyIndex]
    this.doc = JSON.parse(snapshot) as object as HdsDocument
    this.selectedObjectIds = []
    this.notifyHistoryChange()
  }

  redo(): void {
    if (!this.canRedo()) return
    this.historyIndex++
    const snapshot = this.historyStack[this.historyIndex]
    this.doc = JSON.parse(snapshot) as object as HdsDocument
    this.selectedObjectIds = []
    this.notifyHistoryChange()
  }

  /** 构建历史条目列表（undo 从新到旧 + redo 从旧到新） */
  getHistoryEntries(): HistoryEntry[] {
    const entries: HistoryEntry[] = []
    const undoLen = this.historyIndex + 1
    for (let i = undoLen - 1; i >= 0; i--) {
      entries.push({
        key: `u-${i}`,
        label: this.historyLabels[i] ?? 'action',
        icon: this.describeToIcon(this.historyLabels[i] ?? ''),
        index: i,
        current: i === this.historyIndex,
        future: false,
        canRedo: false,
      })
    }
    for (let i = this.historyIndex + 1; i < this.historyStack.length; i++) {
      entries.push({
        key: `r-${i}`,
        label: this.historyLabels[i] ?? 'action',
        icon: this.describeToIcon(this.historyLabels[i] ?? ''),
        index: i,
        current: false,
        future: true,
        canRedo: true,
      })
    }
    return entries
  }

  /** 撤销进度百分比（0-100） */
  getHistoryUndoProgress(): number {
    const total = this.historyStack.length
    if (total <= 1) return 100
    return (this.historyIndex + 1) / total * 100
  }

  /** 跳转到指定历史索引 */
  jumpToHistory(index: number): void {
    if (index < 0 || index >= this.historyStack.length) return
    if (index === this.historyIndex) return
    if (index > this.historyIndex) {
      while (this.historyIndex < index && this.canRedo()) {
        this.redo()
      }
    } else {
      while (this.historyIndex > index && this.canUndo()) {
        this.undo()
      }
    }
    this.notifyHistoryChange()
  }

  /** 根据描述推断图标 */
  private describeToIcon(desc: string): string {
    if (desc.includes('新增') || desc.includes('创建') || desc.includes('新建')) return 'p'
    if (desc.includes('删除') || desc.includes('移除')) return 't'
    if (desc.includes('移动') || desc.includes('调整') || desc.includes('变换')) return 'c'
    if (desc.includes('编组') || desc.includes('组')) return 'g'
    if (desc.includes('图层')) return 'l'
    if (desc.includes('文字') || desc.includes('文本')) return 'T'
    if (desc.includes('形状') || desc.includes('矩形') || desc.includes('椭圆')) return 'r'
    if (desc.includes('图片') || desc.includes('图像')) return 'i'
    if (desc.includes('蒙版')) return 'p'
    if (desc.includes('效果') || desc.includes('投影') || desc.includes('阴影')) return 'w'
    if (desc.includes('混合')) return 'p'
    if (desc.includes('保存')) return 's'
    if (desc.includes('重命名')) return 'n'
    if (desc.includes('锁定')) return 'L'
    if (desc.includes('隐藏') || desc.includes('显示')) return 'e'
    if (desc.includes('复制') || desc.includes('克隆')) return 'c'
    if (desc.includes('翻转')) return 'f'
    if (desc.includes('旋转')) return 'r'
    if (desc.includes('快照')) return 'S'
    return 'h'
  }

  /* ════════════════ 剪贴板 ════════════════ */

  copySelectedToClipboard(): void {
    const sel = this.getSelectedObjects()
    if (sel.length > 0) {
      this.clipboard = sel.map(o => JSON.parse(JSON.stringify(o)) as SceneObject)
    }
  }

  pasteFromClipboard(): void {
    if (this.clipboard.length === 0) return
    const targetLayerId = this.getCurrentLayers()[0]?.id
    if (!targetLayerId) return
    for (const src of this.clipboard) {
      const cloned = JSON.parse(JSON.stringify(src)) as SceneObject
      cloned.id = src.type + '_' + Date.now().toString(36)
      cloned.transform.x += 20
      cloned.transform.y += 20
      this.addObjectToLayer(targetLayerId, cloned)
      this.selectedObjectIds = [cloned.id]
    }
    this.pushHistory('粘贴对象')
  }

  cutSelectedToClipboard(): void {
    this.copySelectedToClipboard()
    const ids = [...this.selectedObjectIds]
    for (const id of ids) {
      this.removeObjectById(id)
    }
    this.pushHistory('剪切对象')
  }

  private addObjectToLayer(layerId: string, obj: SceneObject): void {
    const layers = this.getCurrentLayers()
    const layer = layers.find(l => l.id === layerId)
    if (layer) {
      layer.objects.push(obj)
    }
  }

  /* ════════════════ 效果/蒙版/文本样式 ════════════════ */

  addLayerEffect(layerId: string, effectType: string): void {
    const layer = findLayerById(this.doc, layerId)
    if (!layer) return
    const newEffect: LayerEffect = {
      id: `${effectType}_${Date.now().toString(36)}`,
      type: effectType,
      enabled: true,
      params: {
        color: '#000000',
        opacity: 40,
        blur: 4,
        distance: 5,
        angle: 120,
      },
    }
    layer.effects.push(newEffect)
    this.pushHistory('添加效果')
  }

  toggleLayerEffect(layerId: string, effectId: string): void {
    const layer = findLayerById(this.doc, layerId)
    if (!layer) return
    const effect = layer.effects.find(e => e.id === effectId)
    if (effect) {
      effect.enabled = !effect.enabled
      this.pushHistory('切换效果')
    }
  }

  removeLayerEffect(layerId: string, effectId: string): void {
    const layer = findLayerById(this.doc, layerId)
    if (!layer) return
    layer.effects = layer.effects.filter(e => e.id !== effectId)
    this.pushHistory('删除效果')
  }

  updateObjectTextProp(objId: string, key: string, value: number | string | boolean): void {
    const found = findObjectInDoc(this.doc, objId)
    if (!found || found.obj.type !== 'text') return
    if (key === 'fontSize') found.obj.fontSize = value as number
    else if (key === 'fontWeight') found.obj.fontWeight = value as number
    else if (key === 'fontFamily') found.obj.fontFamily = value as string
    else if (key === 'color') found.obj.color = value as string
    else if (key === 'text') found.obj.text = value as string
    else if (key === 'align') found.obj.align = value as string
    else if (key === 'lineHeight') found.obj.lineHeight = value as number
    else if (key === 'letterSpacing') found.obj.letterSpacing = value as number
    this.pushHistory('编辑文本样式')
  }

  /* ════════════════ 文档action ════════════════ */

  newDocument(frameType?: string): void {
    const scene = createScene()
    const doc: HdsDocument = {
      version: '3.0',
      scene,
      metadata: {
        createdAt: new Date().toISOString(),
        modifiedAt: new Date().toISOString(),
      },
    }
    this.doc = doc
    if (frameType) {
      addFrame(this.doc, frameType)
    }
    this.selectedObjectIds = []
    this.historyStack = []
    this.historyIndex = -1
    this.pushHistory()
  }

  /** 获取场景信息 */
  getSceneInfo(): FusionDocumentStoreInfo {
    const layers = this.getCurrentLayers()
    const objects = listAllObjects(this.doc)
    const info: FusionDocumentStoreInfo = {
      layerCount: layers.length,
      objectCount: objects.length,
      canvasSize: `${this.doc.scene.canvasWidth} × ${this.doc.scene.canvasHeight}`,
    }
    return info
  }
}

