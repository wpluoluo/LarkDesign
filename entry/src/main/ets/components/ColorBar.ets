/**
 * ColorBar - 色彩条
 *
 * 对应原型 src/components/ColorBar.vue
 * 显示最近使用/常用色彩 + 当前选中色 + 弹出颜色选择器
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant, FontSizeToken, ShadowToken, SpacingToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { ColorStore } from '../stores/ColorStore'
import { ColorPickerPanel } from './ColorPickerPanel'

@Component
export struct ColorBar {
  @StorageLink('currentColor') currentColor: string = '#3AC487'
  @State showPicker: boolean = false
  @State pickerX: number = 0
  @State pickerY: number = 0

  private colorStore: ColorStore = ColorStore.getInstance()

  private recentColors: string[] = []
  private commonColors: string[] = [
    '#3AC487', '#16865F', '#3B82F6', '#EF4444', '#F59E0B', '#8B5CF6',
    '#EC4899', '#14B8A6', '#6B7280', '#FF6B6B', '#4ECDC4', '#45B7D1',
    '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9',
  ]

  aboutToAppear(): void {
    this.recentColors = this.colorStore.history
  }

  build(): void {
    Stack() {
      Row() {
        // 最近使用
        Text('最近')
          .fontSize(8)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .width(36)

        ForEach(this.recentColors.length > 0 ? this.recentColors : ['#3AC487', '#FFFFFF', '#000000'], (color: string) => {
          Column()
            .width(18)
            .height(18)
            .borderRadius(3)
            .backgroundColor(color)
            .border({ width: 1, color: ColorToken.border })
            .margin({ right: 3 })
            .onClick(() => {
              this.colorStore.setColor(color)
            })
        })

        // 分隔线
        Column()
          .width(1)
          .height(16)
          .backgroundColor(ColorToken.border)
          .margin({ left: 2, right: 4 })

        // 常用色彩
        Text('常用')
          .fontSize(8)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .width(36)

        ForEach(this.commonColors, (color: string) => {
          Column()
            .width(18)
            .height(18)
            .borderRadius(3)
            .backgroundColor(color)
            .border({ width: 1, color: ColorToken.border })
            .margin({ right: 3 })
            .onClick(() => {
              this.colorStore.setColor(color)
            })
        })

        // 添加按钮
        Column() {
          Text(Icon.plus)
            .fontSize(6)
            .fontColor(ColorToken.muted)
            .textAlign(TextAlign.Center)
        }
        .width(18)
        .height(18)
        .borderRadius(3)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Blank()

        // 当前选中色
        Row() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(3)
            .backgroundColor(this.currentColor)
            .border({ width: 1, color: ColorToken.border })

          Text(this.currentColor)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .margin({ left: 4 })
        }
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .borderRadius(3)
        .onClick(() => {
          this.showPicker = !this.showPicker
        })
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .backgroundColor(ColorToken.white)
      .alignItems(VerticalAlign.Center)

      // 颜色选择器弹出层
      if (this.showPicker) {
        Column() {
          ColorPickerPanel({
            modelValue: this.currentColor,
            onPick: (hex: string) => {
              this.colorStore.setColor(hex)
              this.currentColor = hex
            }
          })
        }
        .width(280)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(8)
        .shadow(ShadowToken.lg)
        .position({ x: this.pickerX, y: this.pickerY })
        .zIndex(400)
      }
    }
  }
}
