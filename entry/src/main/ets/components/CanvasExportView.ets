/**
 * CanvasExportView - Canvas 渲染/导出组件
 *
 * 使用 ArkUI <Canvas> 组件 + Canvas2DRenderer 渲染当前 Frame，
 * 支持通过 getPixelMap 导出为图片。
 * 自动从 FusionDocumentStore 读取当前 Frame 并缩放适配。
 */
import { Canvas2DRenderer } from '../utils/Canvas2DRenderer'
import { Frame, SceneObject } from '../domain/SceneTypes'
import { FusionDocumentStore } from '../domain/FusionDocumentStore'

@Component
export struct CanvasExportView {
  private showSelection: boolean = false
  private selectedObjectIds: string[] = []
  private pixelMapCallback: (pixelMap: PixelMap) => void = (_pm: PixelMap): void => {}
  private dpi: number = 72
  private canvasWidth: number = 200
  private canvasHeight: number = 200
  @State hasFrame: boolean = false

  private canvasCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D()
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  aboutToAppear(): void {
    this.updateFromStore()
  }

  updateFromStore(): void {
    const frame = this.fusionStore.getCurrentFrame()
    this.hasFrame = frame !== null
  }

  setPixelMapCallback(callback: (pm: PixelMap) => void): void {
    this.pixelMapCallback = callback
  }

  setDpi(dpi: number): void {
    this.dpi = dpi
  }

  private renderToCanvas(): void {
    const ctx = this.canvasCtx
    const frame = this.fusionStore.getCurrentFrame()
    if (!frame) return
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight)
    ctx.save()
    const scaleX = this.canvasWidth / frame.width
    const scaleY = this.canvasHeight / frame.height
    const scale = Math.min(scaleX, scaleY)
    const offsetX = (this.canvasWidth - frame.width * scale) / 2
    const offsetY = (this.canvasHeight - frame.height * scale) / 2
    ctx.translate(offsetX, offsetY)
    ctx.scale(scale, scale)
    Canvas2DRenderer.renderFrame(ctx, frame, frame.width, frame.height)
    if (this.showSelection && this.selectedObjectIds.length > 0) {
      const allObjects: SceneObject[] = []
      for (const layer of frame.children) {
        for (const obj of layer.objects) {
          if (this.selectedObjectIds.includes(obj.id)) {
            allObjects.push(obj)
          }
        }
      }
      Canvas2DRenderer.drawSelectionHandles(ctx, allObjects)
    }
    ctx.restore()
  }

  private onCanvasAreaClick(): void {
    const pm = this.canvasCtx.getPixelMap(0, 0, this.canvasWidth, this.canvasHeight)
    if (pm && this.pixelMapCallback) {
      this.pixelMapCallback(pm)
    }
  }

  build() {
    Column() {
      if (this.hasFrame) {
        Canvas(this.canvasCtx)
          .width(this.canvasWidth)
          .height(this.canvasHeight)
          .backgroundColor('#FFFFFF')
          .onReady(() => {
            this.renderToCanvas()
          })
          .onClick(() => {
            this.onCanvasAreaClick()
          })
      } else {
        Column() {
          Text('请先创建画板')
            .fontSize(11)
            .fontColor('#8A919F')
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

export interface CanvasExportSettings {
  exportWidth: number
  exportHeight: number
  dpi: number
}
