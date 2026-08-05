/**
 * ColorChannelInput - 颜色通道输入框
 *
 * 对应原型 src/components/ColorChannelInput.vue
 * 单通道数值输入（R/G/B/H/S/L/C/M/Y/K），带标签、后缀、min/max 约束
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'

@Component
export struct ColorChannelInput {
  @Prop label: string = 'R'
  @Prop labelColor: string = '#EF4444'
  @Prop value: number = 0
  @Prop suffix: string = ''
  @Prop min: number = 0
  @Prop max: number = 255
  onChange: (value: number) => void = () => {}

  @State localValue: string = '0'
  @State isFocused: boolean = false

  aboutToAppear(): void {
    this.localValue = `${this.value}`
  }

  onValueUpdate(newVal: number): void {
    this.localValue = `${newVal}`
  }

  build(): void {
    Row() {
      // 标签
      Text(this.label)
        .fontSize(9)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(this.labelColor)
        .width(10)
        .textAlign(TextAlign.Start)

      // 数值输入
      TextInput({ text: this.localValue, placeholder: '0' })
        .fontSize(9)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
        .backgroundColor(Color.Transparent)
        .border({ width: 0 })
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .height(20)
        .onChange((val: string) => {
          this.localValue = val
          const n = parseInt(val, 10)
          if (!isNaN(n)) {
            const clamped = Math.max(this.min, Math.min(this.max, n))
            this.onChange(clamped)
          }
        })
        .onFocus(() => { this.isFocused = true })
        .onBlur(() => { this.isFocused = false })

      // 后缀
      if (this.suffix.length > 0) {
        Text(this.suffix)
          .fontSize(9)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.tertiary)
          .margin({ left: 2 })
      }
    }
    .width('100%')
    .height(20)
    .padding({ left: 4, right: 4 })
    .backgroundColor(ColorToken.panel)
    .border({
      width: 1,
      color: this.isFocused ? ColorToken.primary : ColorToken.border
    })
    .borderRadius(3)
    .alignItems(VerticalAlign.Center)
  }
}
