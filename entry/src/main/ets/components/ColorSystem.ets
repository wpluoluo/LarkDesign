/**
 * ColorSystem - 色彩系统面板
 *
 * 对应原型 src/components/ColorSystem.vue
 * 显示文档色彩系统：色板、渐变色、色彩样式
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, SpacingToken, RadiusToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

@Component
export struct ColorSystem {
  @State activeTab: string = 'swatches'

  private colorSwatches: string[] = [
    '#3AC487', '#16865F', '#0D5A3D', '#3B82F6', '#22C55E',
    '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899', '#14B8A6',
    '#6B7280', '#1F2329', '#FFFFFF', '#F3F5F7', '#E5E7EB',
  ]

  build(): void {
    Column() {
      // 标题
      Row() {
        Text(Icon.palette)
          .fontSize(12)
          .fontColor(ColorToken.primary)
        Text('色彩系统')
          .fontSize(12)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.title)
          .margin({ left: 6 })
        Blank()
        Text(Icon.plus)
          .fontSize(10)
          .fontColor(ColorToken.tertiary)
          .padding(4)
          .onClick(() => {})
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 标签页
      Row() {
        this.tabButton('swatches', '色板')
        this.tabButton('gradients', '渐变色')
        this.tabButton('styles', '色彩样式')
      }
      .width('100%')
      .padding({ left: 8, right: 8 })
      .margin({ bottom: 6 })

      // 内容
      if (this.activeTab === 'swatches') {
        // 色板网格
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.colorSwatches, (swatch: string) => {
            Column()
              .width(24)
              .height(24)
              .borderRadius(4)
              .backgroundColor(swatch)
              .border({ width: 1, color: ColorToken.border_light })
              .margin({ right: 4, bottom: 4 })
              .onClick(() => {})
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
      } else if (this.activeTab === 'gradients') {
        Column() {
          Text('暂无渐变色')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      } else {
        Column() {
          Text('暂无色彩样式')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .backgroundColor(ColorToken.white)
    .borderRadius(8)
    .border({ width: 1, color: ColorToken.border_light })
  }

  @Builder
  tabButton(id: string, label: string): void {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeightConstant.semibold)
      .fontColor(this.activeTab === id ? ColorToken.primary_dark_700 : ColorToken.muted)
      .layoutWeight(1)
      .height(26)
      .textAlign(TextAlign.Center)
      .borderRadius(5)
      .backgroundColor(this.activeTab === id ? ColorToken.hover_bg : Color.Transparent)
      .onClick(() => { this.activeTab = id })
  }
}
