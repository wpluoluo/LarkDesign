/**
 * ColorPickerPopover - 颜色选择器弹窗
 *
 * 对应原型 src/components/ColorPickerPopover.vue
 * 包含：ColorPickerPanel + 透明度滑块 + 取消按钮
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { ColorPickerPanel } from './ColorPickerPanel'

@Component
export struct ColorPickerPopover {
  @Prop visible: boolean = false
  @Prop anchorX: number = 0
  @Prop anchorY: number = 0
  @Prop modelValue: string = '#3AC487'
  @Prop initialOpacity: number = 100
  onPick: (hex: string) => void = () => {}
  onOpacityChange: (val: number) => void = () => {}
  onClose: () => void = () => {}

  @State localOpacity: number = 100
  @State localHex: string = '#3AC487'
  @State hoveredCancel: boolean = false

  aboutToAppear(): void {
    this.localOpacity = this.initialOpacity
    this.localHex = this.modelValue.toUpperCase()
  }

  /** 根据滑块上的 x 坐标更新透明度（轨道宽度约 150vp） */
  private updateOpacityFromX(localX: number): void {
    // 弹窗宽 220，左右 padding 10，α 文字约 8，数值约 30，轨道约 150vp
    const trackWidth = 150
    const ratio = Math.max(0, Math.min(1, localX / trackWidth))
    const newOpacity = Math.round(ratio * 100)
    if (newOpacity !== this.localOpacity) {
      this.localOpacity = newOpacity
      this.onOpacityChange(newOpacity)
    }
  }

  build(): void {
    if (this.visible) {
      Stack({ alignContent: Alignment.TopStart }) {
        // 透明遮罩（点击关闭）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onClose() })

        // 弹窗主体
        Column() {
          // ─── 顶部小三角箭头（指向锚点） ───
          // 原型：absolute w-[10px] h-[10px] bg-white border-l border-t border-border rotate-45
          Column()
            .width(10)
            .height(10)
            .backgroundColor(ColorToken.white)
            .border({ width: { left: 1, top: 1 }, color: { left: ColorToken.border, top: ColorToken.border } })
            .rotate({ x: 0, y: 0, z: 1, angle: 45 })
            .position({ x: 12, y: -5 })

          ColorPickerPanel({
            modelValue: this.localHex,
            onPick: (hex: string) => {
              this.localHex = hex.toUpperCase()
              this.onPick(hex)
            },
          })

          // ─── 底部操作行 ───
          Column() {
            // 透明度滑块（可拖动）
            Row() {
              Text('α')
                .fontSize(9)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              // 透明度滑块轨道
              Stack({ alignContent: Alignment.Start }) {
                // 轨道背景
                Row()
                  .width('100%')
                  .height(4)
                  .backgroundColor(ColorToken.border)
                  .borderRadius(2)
                // 已选填充
                Row()
                  .width(`${this.localOpacity}%`)
                  .height(4)
                  .backgroundColor(ColorToken.primary)
                  .borderRadius(2)
                // 拖动手柄
                Row()
                  .width(10)
                  .height(10)
                  .borderRadius(5)
                  .backgroundColor(ColorToken.white)
                  .border({ width: 1, color: ColorToken.primary })
                  .margin({ left: `${Math.max(0, this.localOpacity - 5)}%` })
              }
              .layoutWeight(1)
              .height(12)
              .margin({ left: 4, right: 4 })
              .alignContent(Alignment.Center)
              .gesture(
                PanGesture()
                  .onActionStart((e: GestureEvent) => {
                    this.updateOpacityFromX(e.fingerList[0].localX)
                  })
                  .onActionUpdate((e: GestureEvent) => {
                    this.updateOpacityFromX(e.fingerList[0].localX)
                  })
              )
              .onClick((e: ClickEvent) => {
                this.updateOpacityFromX(e.x)
              })

              Text(`${this.localOpacity}%`)
                .fontSize(9)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .width(26)
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 8 })

            // 取消按钮（原型：hover:bg-border-light）
            Row() {
              Text('取消')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.secondary)
            }
            .height(22)
            .padding({ left: 8, right: 8 })
            .borderRadius(3)
            .backgroundColor(this.hoveredCancel ? ColorToken.border_light : ColorToken.panel)
            .margin({ top: 6 })
            .onHover((isHover: boolean) => { this.hoveredCancel = isHover })
            .onClick(() => { this.onClose() })
          }
          .width('100%')
          .padding({ top: 6 })
          .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
        }
        .width(220)
        .padding(10)
        .borderRadius(8)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow(ShadowToken.lg)
        .position({ x: this.anchorX, y: this.anchorY })
        .zIndex(ZIndexToken.dropdown)
      }
      .width('100%')
      .height('100%')
      .zIndex(ZIndexToken.dropdown)
    }
  }
}
