/**
 * FusionDocumentStore - Fusion 文档状态管理（鸿蒙端）
 *
 * 对应原型 src/stores/fusionDocument.ts
 * 使用 AppStorage 实现全局响应式，配合 @StorageLink 在组件中订阅。
 */
import { HdsDocument, Scene, Layer, Frame, SceneObject, Transform } from '../types/SceneTypes'
import { createScene } from '../types/FusionFactory'
import {
  getCurrentFrame, getCurrentLayers, getCurrentPage,
  addFrame, removeFrame, duplicateFrame, findFrameById, updateFrame,
  addLayer, findLayerById, removeLayer,
  findObjectInDoc, addObjectToLayer, updateObjectTransform,
  listAllObjects, getFramesBoundingBox, fitViewportToFrames,
} from '../types/FusionOps'
import { FusionDocumentStoreInfo } from './FusionDocumentStoreInfo'
import { serialize, deserialize, deepClone, estimateSize } from '../types/FusionSerializer'

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

  selectObject(objId: string | null, additive?: boolean): void {
    if (objId === null) {
      this.selectedObjectIds = []
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
  }

  moveObject(objId: string, x: number, y: number, skipHistory?: boolean): void {
    updateObjectTransform(this.doc, objId, x, y)
    if (!skipHistory) this.pushHistory()
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

  /* ════════════════ 历史记录 ════════════════ */

  private pushHistory(label?: string): void {
    this.scheduleAutoSave()
    this.historyLabels.push(label ?? 'action')
    const snapshot = JSON.stringify(this.doc)
    this.historyStack = this.historyStack.slice(0, this.historyIndex + 1)
    this.historyStack.push(snapshot)
    if (this.historyStack.length > 50) {
      this.historyStack.shift()
    } else {
      this.historyIndex++
    }
    this.doc.metadata.modifiedAt = new Date().toISOString()
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
  }

  redo(): void {
    if (!this.canRedo()) return
    this.historyIndex++
    const snapshot = this.historyStack[this.historyIndex]
    this.doc = JSON.parse(snapshot) as object as HdsDocument
    this.selectedObjectIds = []
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

