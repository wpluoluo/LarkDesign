/**
 * LayerStore - 图层状态管理
 *
 * 管理当前图层与元素选择状态。
 */
import { SceneObject, Layer } from './SceneTypes'
import { FusionDocumentStore } from './FusionDocumentStore'
import { listAllObjects, findObjectInDoc, FindResult } from './FusionOps'

export class LayerStore {
  private static instance: LayerStore
  private _selectedLayerId: string = ''
  private _selectedElement: SceneObject | null = null

  private constructor() {}

  static getInstance(): LayerStore {
    if (!LayerStore.instance) {
      LayerStore.instance = new LayerStore()
    }
    return LayerStore.instance
  }

  getSelectedLayerId(): string {
    return this._selectedLayerId
  }

  getSelectedElement(): SceneObject | null {
    return this._selectedElement
  }

  select(name: string): void {
    const fusion = FusionDocumentStore.getInstance()
    const allObjects = listAllObjects(fusion.getDocument())
    const obj = allObjects.find(o => o.name === name)
    if (obj) {
      this._selectedElement = obj
      AppStorage.setOrCreate<string>('selectedElementName', name)
    }
  }

  selectById(objId: string): void {
    const fusion = FusionDocumentStore.getInstance()
    const found = findObjectInDoc(fusion.getDocument(), objId)
    if (found) {
      this._selectedElement = found.obj
      this._selectedLayerId = found.layer.id
      AppStorage.setOrCreate<string>('selectedLayerId', this._selectedLayerId)
    }
  }

  deselect(): void {
    this._selectedElement = null
    this._selectedLayerId = ''
    AppStorage.setOrCreate<string>('selectedLayerId', '')
  }
}
