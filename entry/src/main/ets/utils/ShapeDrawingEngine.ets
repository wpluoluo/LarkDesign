import { SceneObject, Frame, ShapeKind } from '../domain/SceneTypes'
import { createShapeObject, createTextObject } from '../domain/FusionFactory'
import { CanvasInteraction } from '../components/CanvasInteraction'
import { FusionDocumentStore } from '../domain/FusionDocumentStore'

export type DrawMode = 'none' | 'shape' | 'text'

export interface DrawPreview {
  x: number
  y: number
  width: number
  height: number
  shape: string
}

export class ShapeDrawingEngine {
  private static instance: ShapeDrawingEngine
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private _drawMode: DrawMode = 'none'
  private _drawPreview: DrawPreview | null = null
  private startX: number = 0
  private startY: number = 0

  private constructor() {}

  static getInstance(): ShapeDrawingEngine {
    if (!ShapeDrawingEngine.instance) {
      ShapeDrawingEngine.instance = new ShapeDrawingEngine()
    }
    return ShapeDrawingEngine.instance
  }

  get drawMode(): DrawMode {
    return this._drawMode
  }

  get drawPreview(): DrawPreview | null {
    return this._drawPreview
  }

  get isDrawing(): boolean {
    return this._drawMode !== 'none'
  }

  private showToast(message: string, icon: string, type: string): void {
    AppStorage.setOrCreate<string>('toastMessage', message)
    AppStorage.setOrCreate<string>('toastIcon', icon)
    AppStorage.setOrCreate<string>('toastType', type)
    AppStorage.setOrCreate<boolean>('toastVisible', true)
    setTimeout(() => {
      AppStorage.setOrCreate<boolean>('toastVisible', false)
    }, 3000)
  }

  maybeStartDraw(canvasX: number, canvasY: number, tool: string): boolean {
    if (CanvasInteraction.isEyedropper(tool)) {
      this.pickColorAt(canvasX, canvasY)
      return true
    }
    if (CanvasInteraction.isZoomTool(tool)) {
      const zoom = AppStorage.get<number>('viewportZoom') ?? 1
      AppStorage.setOrCreate<number>('viewportZoom', Math.min(zoom * 1.25, 32))
      this.showToast(Math.round(AppStorage.get<number>('viewportZoom')! * 100) + '%', 'zoom_in', 'info')
      return true
    }
    if (CanvasInteraction.isHandTool(tool)) {
      this._drawMode = 'shape'
      this.startX = canvasX
      this.startY = canvasY
      return true
    }
    if (CanvasInteraction.isShapeTool(tool)) {
      this._drawMode = 'shape'
      this.startX = canvasX
      this.startY = canvasY
      this._drawPreview = {
        x: canvasX,
        y: canvasY,
        width: 0,
        height: 0,
        shape: CanvasInteraction.toolNameToShape(tool),
      }
      return true
    }
    if (tool === 'text' || tool === '文字') {
      this.commitTextAt(canvasX, canvasY)
      return true
    }
    return false
  }

  updateDrawPreview(canvasX: number, canvasY: number): void {
    if (this._drawMode !== 'shape') return
    if (this._drawPreview === null) return
    this._drawPreview = {
      x: Math.min(this.startX, canvasX),
      y: Math.min(this.startY, canvasY),
      width: Math.abs(canvasX - this.startX),
      height: Math.abs(canvasY - this.startY),
      shape: this._drawPreview.shape,
    }
  }

  commitDraw(tool: string, frame: Frame | null): void {
    if (this._drawMode === 'shape' && this._drawPreview !== null) {
      const p = this._drawPreview
      if (p.width >= 4 && p.height >= 4) {
        this.createShapeObjectAt(p.x, p.y, p.width, p.height, p.shape, tool, frame)
      }
    }
    this._drawMode = 'none'
    this._drawPreview = null
  }

  cancelDraw(): void {
    this._drawMode = 'none'
    this._drawPreview = null
  }

  private pickColorAt(canvasX: number, canvasY: number): void {
    const frame = this.fusionStore.getCurrentFrame()
    const layers = this.fusionStore.getCurrentLayers()
    let allObjects: SceneObject[] = []
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        allObjects.push(layers[i].objects[j])
      }
    }
    const color = CanvasInteraction.pickColorFromObjects(allObjects, frame, canvasX, canvasY)
    AppStorage.setOrCreate<string>('currentColor', color)
    this.showToast('已取色 ' + color, 'eyedropper', 'success')
  }

  private createShapeObjectAt(
    x: number, y: number, w: number, h: number,
    shape: string, tool: string, frame: Frame | null,
  ): void {
    const currentColor = AppStorage.get<string>('currentColor') ?? '#3AC487'
    const cornerRadius = CanvasInteraction.toolNameToCornerRadius(tool)
    const obj = createShapeObject({
      shape: shape as ShapeKind,
      x: x, y: y,
      width: w, height: h,
      fill: currentColor,
      stroke: '#1F2329',
      strokeWidth: 0,
      cornerRadius: cornerRadius,
    })
    this.fusionStore.newObject(obj)
    this.showToast('已创建形状', 'shape', 'success')
  }

  private commitTextAt(canvasX: number, canvasY: number): void {
    const obj = createTextObject({
      text: '双击编辑文字',
      x: canvasX,
      y: canvasY,
      width: 200,
      height: 40,
    })
    this.fusionStore.newObject(obj)
    this.showToast('已创建文本对象，双击可编辑', 'text', 'success')
    this._drawMode = 'none'
  }
}
