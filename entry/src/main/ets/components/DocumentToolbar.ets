/**
 * DocumentToolbar - 文档工具栏
 *
 * 对应原型 src/components/DocumentToolbar.vue
 * 显示文档名称、格式、缩放等文档级操作
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant, FontSizeToken, SpacingToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'

@Component
export struct DocumentToolbar {
  @StorageLink('zoomPercent') zoomPercent: number = 100
  @State docName: string = '未命名文档'
  @State showZoomMenu: boolean = false

  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  build(): void {
    Row() {
      // 文档名称
      Text(this.docName)
        .fontSize(12)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.body)
        .maxLines(1)
        .layoutWeight(1)
        .margin({ left: 12 })

      // 缩放控件
      Row() {
        // 缩小
        Column() {
          Text(Icon.minus)
            .fontSize(8)
            .fontColor(ColorToken.tertiary)
        }
        .width(22)
        .height(22)
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.zoomPercent = Math.max(10, this.zoomPercent - 10)
          AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
        })

        // 缩放百分比
        Text(`${this.zoomPercent}%`)
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
          .width(50)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showZoomMenu = !this.showZoomMenu
          })

        // 放大
        Column() {
          Text(Icon.plus)
            .fontSize(8)
            .fontColor(ColorToken.tertiary)
        }
        .width(22)
        .height(22)
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.zoomPercent = Math.min(400, this.zoomPercent + 10)
          AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
        })
      }
      .margin({ right: 12 })
    }
    .width('100%')
    .height(32)
    .backgroundColor(ColorToken.panel)
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
    .alignItems(VerticalAlign.Center)
  }
}
