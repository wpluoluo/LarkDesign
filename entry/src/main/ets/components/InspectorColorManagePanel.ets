/**
 * InspectorColorManagePanel - 色彩管理面板
 *
 * 对应原型 src/components/Inspector.vue 的 Design Tab 色彩管理部分
 * 复用 ColorPickerPanel 作为完整取色器
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { ColorPickerPanel } from '../features/color/components/ColorPickerPanel'

@Component
export struct InspectorColorManagePanel {
  @State expanded: boolean = false
  @State hoveredHead: boolean = false
  @State currentColorHex: string = '#3AC487'

  private colorSwatches: string[] = [
    '#3AC487', '#16865F', '#0D5A3D', '#3B82F6', '#22C55E',
    '#F59E0B', '#EF4444', '#263238', '#FFFFFF', '#000000',
  ]

  build(): void {
    Column() {
      Row() {
        Row() {
          Text(Icon.palette)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
          Text('\u8272\u5f69\u7ba1\u7406')
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
        Blank()
        Text(this.expanded ? Icon.chevron_up : Icon.chevron_down)
          .fontSize(10)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .backgroundColor(this.hoveredHead ? ColorToken.panel : Color.Transparent)
      .onClick(() => { this.expanded = !this.expanded })
      .onHover((isHover: boolean) => { this.hoveredHead = isHover })

      if (this.expanded) {
        ColorPickerPanel({
          modelValue: this.currentColorHex,
          onPick: (hex: string): void => {
            this.currentColorHex = hex
          },
        })
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 12 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }
}
