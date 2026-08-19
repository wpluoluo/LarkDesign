/**
 * CanvasExportPanel - Canvas 导出预览面板
 *
 * 浮动面板，使用 CanvasExportView 渲染当前 Frame，
 * 提供导出预览、尺寸信息、DPI 设置和导出按钮。
 */
import { ColorToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { CanvasExportView, CanvasExportSettings } from './CanvasExportView'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { Exporter, ExportFormat } from '../utils/Exporter'
import { Frame } from '../domain/SceneTypes'

@Component
export struct CanvasExportPanel {
  @StorageLink('showCanvasExport') showCanvasExport: boolean = false
  @State frameInfo: string = ''
  @State dpi: number = 72
  @State exportFormat: string = 'png'
  @State exporting: boolean = false
  @State exportMessage: string = ''

  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private exporter: Exporter = Exporter.getInstance()
  private currentFrame: Frame | null = null

  aboutToAppear(): void {
    this.refreshFrame()
  }

  refreshFrame(): void {
    this.currentFrame = this.fusionStore.getCurrentFrame()
    if (this.currentFrame) {
      this.frameInfo = `${this.currentFrame.name} · ${this.currentFrame.width}×${this.currentFrame.height}`
    } else {
      this.frameInfo = '无画板'
    }
  }

  private async doExport(): Promise<void> {
    this.exporting = true
    this.exportMessage = ''
    const fmt = this.exportFormat as ExportFormat
    const result = await this.exporter.export({ format: fmt, dpi: this.dpi, quality: 0.92 })
    this.exportMessage = result.message
    setTimeout(() => {
      this.exporting = false
    }, 1500)
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('导出预览')
          .fontSize(12)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.title)
          .layoutWeight(1)

        Text(Icon.close)
          .fontSize(10)
          .fontColor(ColorToken.tertiary)
          .onClick(() => {
            this.showCanvasExport = false
            AppStorage.setOrCreate<boolean>('showCanvasExport', false)
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 画布信息
      Text(this.frameInfo)
        .fontSize(10)
        .fontColor(ColorToken.muted)
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 6 })

      // Canvas 预览
      if (this.currentFrame) {
        CanvasExportView()
          .width('100%')
          .height(200)
          .constraintSize({ maxWidth: '100%' })
          .padding(8)
      } else {
        Column() {
          Text('暂无画板内容')
            .fontSize(11)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      // 导出设置
      Row() {
        Text('DPI:')
          .fontSize(10)
          .fontColor(ColorToken.body)
        TextInput({ text: this.dpi.toString(), placeholder: '72' })
          .fontSize(10)
          .width(60)
          .height(24)
          .onChange((val: string) => {
            const n = parseInt(val)
            if (n > 0) this.dpi = n
          })

        Text('格式:')
          .fontSize(10)
          .fontColor(ColorToken.body)
          .margin({ left: 8 })

        Column() {
          Text(this.exportFormat.toUpperCase())
            .fontSize(10)
            .fontColor(ColorToken.body)
        }
        .width(50)
        .height(24)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(4)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.exportFormat = this.exportFormat === 'png' ? 'jpeg' : 'png'
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .alignItems(VerticalAlign.Center)

      // 导出按钮 + 状态
      Column() {
        Row() {
          Text(this.exporting ? '导出中...' : '导出')
            .fontSize(11)
            .fontColor(ColorToken.white)
        }
        .width('100%')
        .height(32)
        .backgroundColor(ColorToken.primary)
        .borderRadius(6)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.doExport() })

        if (this.exportMessage.length > 0) {
          Text(this.exportMessage)
            .fontSize(9)
            .fontColor(ColorToken.primary)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 10 })
    }
    .width(280)
    .backgroundColor(ColorToken.white)
    .borderRadius(8)
    .border({ width: 1, color: ColorToken.border_light })
    .shadow({ radius: 8, color: '#0000001A', offsetY: 4 })
  }
}
