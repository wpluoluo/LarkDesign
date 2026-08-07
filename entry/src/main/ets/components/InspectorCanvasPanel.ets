/**
 * InspectorCanvasPanel - 画布属性面板
 *
 * 对应原型 src/components/Inspector.vue 的 Design Tab 画布属性部分
 * 包含：背景色、工作区尺寸、网格、吸附、标尺
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

@Component
export struct InspectorCanvasPanel {
  @State expanded: boolean = false
  @State hoveredHead: boolean = false
  @State canvasBgColor: string = '#ECEDEF'
  @State canvasWidth: number = 1440
  @State canvasHeight: number = 960
  @State canvasShowGrid: boolean = false
  @State canvasGridSize: number = 10
  @State canvasGridColor: string = '#D8DCE1'
  @State canvasGridDivisions: number = 4
  @State canvasSnap: boolean = true
  @State canvasSnapGrid: boolean = true
  @State canvasSnapGuide: boolean = true
  @State canvasShowRuler: boolean = true
  @State hoveredRow: string = ''

  private divisionOptions: number[] = [1, 2, 4, 8]

  build(): void {
    Column() {
      Row() {
        Row() {
          Text(Icon.layers)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
          Text('\u753b\u5e03\u5c5e\u6027')
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
        Column() {
          // ─── 背景色 ───
          Row() {
            Text('\u80cc\u666f\u8272')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .width(52)
            Column()
              .width(24)
              .height(24)
              .borderRadius(3)
              .backgroundColor(this.canvasBgColor)
              .border({ width: 1, color: ColorToken.border })
            Row() {
              TextInput({ text: this.canvasBgColor })
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .backgroundColor(Color.Transparent)
                .border({ width: 0 })
                .layoutWeight(1)
                .onChange((val: string) => { this.canvasBgColor = val })
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 4, right: 4 })
            .backgroundColor(ColorToken.panel)
            .borderRadius(4)
            .margin({ left: 8 })
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 8 })

          // ─── 工作区尺寸 ───
          Row() {
            this.sizeInput('\u5de5\u4f5c\u533a\u5bbd\u5ea6', this.canvasWidth, 'w')
            this.sizeInput('\u5de5\u4f5c\u533a\u9ad8\u5ea6', this.canvasHeight, 'h')
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 6 })

          // ─── 网格 ───
          Row() {
            Text('\u7f51\u683c')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
            Blank()
            Row() {
              Row() {
                Column()
                  .width(8)
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(ColorToken.white)
              }
              .width(22)
              .height(12)
              .borderRadius(6)
              .padding({ left: 2, right: 2 })
              .justifyContent(this.canvasShowGrid ? FlexAlign.End : FlexAlign.Start)
              .backgroundColor(this.canvasShowGrid ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.canvasShowGrid = !this.canvasShowGrid })
              Text(this.canvasShowGrid ? '\u663e\u793a' : '\u9690\u85cf')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.canvasShowGrid = !this.canvasShowGrid })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 6 })

          if (this.canvasShowGrid) {
            Row() {
              this.gridSizeInput()
              this.gridColorInput()
              this.gridDivisionBtn()
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .margin({ bottom: 6 })
          }

          // ─── 吸附 ───
          Row() {
            Text('\u5438\u9644')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
            Blank()
            Row() {
              Row() {
                Column()
                  .width(8)
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(ColorToken.white)
              }
              .width(22)
              .height(12)
              .borderRadius(6)
              .padding({ left: 2, right: 2 })
              .justifyContent(this.canvasSnap ? FlexAlign.End : FlexAlign.Start)
              .backgroundColor(this.canvasSnap ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.canvasSnap = !this.canvasSnap })
              Text(this.canvasSnap ? '\u5f00\u542f' : '\u5173\u95ed')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.canvasSnap = !this.canvasSnap })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 6 })

          if (this.canvasSnap) {
            Row() {
              this.miniToggle('\u7f51\u683c', this.canvasSnapGrid, 'snapGrid')
              this.miniToggle('\u53c2\u8003\u7ebf', this.canvasSnapGuide, 'snapGuide')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 6 })
          }

          // ─── 标尺 ───
          Row() {
            Text('\u6807\u5c3a')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
            Blank()
            Row() {
              Row() {
                Column()
                  .width(8)
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(ColorToken.white)
              }
              .width(22)
              .height(12)
              .borderRadius(6)
              .padding({ left: 2, right: 2 })
              .justifyContent(this.canvasShowRuler ? FlexAlign.End : FlexAlign.Start)
              .backgroundColor(this.canvasShowRuler ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.canvasShowRuler = !this.canvasShowRuler })
              Text('\u663e\u793a\u6807\u5c3a')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.canvasShowRuler = !this.canvasShowRuler })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 4 })
          .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 12 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  sizeInput(label: string, value: number, key: string): void {
    Column() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Row() {
        TextInput({ text: '' + value })
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .type(InputType.Number)
          .onChange((val: string) => {
            const v = Number(val) || 100
            if (key === 'w') {
              this.canvasWidth = v
            } else {
              this.canvasHeight = v
            }
          })
        Text('px')
          .fontSize(10)
          .fontColor(ColorToken.muted)
          .margin({ left: 4 })
      }
      .layoutWeight(1)
      .height(24)
      .padding({ left: 4, right: 4 })
      .backgroundColor(ColorToken.panel)
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)

    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .margin({ right: 4 })
  }

  @Builder
  gridSizeInput(): void {
    Column() {
      Text('\u7f51\u683c\u5927\u5c0f')
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      TextInput({ text: '' + this.canvasGridSize })
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
        .height(24)
        .padding({ left: 4, right: 4 })
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(3)
        .type(InputType.Number)
        .onChange((val: string) => { this.canvasGridSize = Number(val) || 1 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .margin({ right: 4 })
  }

  @Builder
  gridColorInput(): void {
    Column() {
      Text('\u7f51\u683c\u989c\u8272')
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Row() {
        TextInput({ text: this.canvasGridColor })
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .layoutWeight(1)
          .height(24)
          .padding({ left: 4, right: 4 })
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(3)
        Column()
          .width(14)
          .height(14)
          .borderRadius(2)
          .backgroundColor(this.canvasGridColor)
          .border({ width: 1, color: ColorToken.border })
          .margin({ left: 4 })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .margin({ right: 4 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  gridDivisionBtn(): void {
    Column() {
      Text('\u5206\u6bb5')
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Row() {
        Text('' + this.canvasGridDivisions)
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
        Text(Icon.chevron_down)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ left: 4 })
      }
      .layoutWeight(1)
      .height(24)
      .padding({ left: 4, right: 4 })
      .backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.border })
      .borderRadius(3)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.canvasGridDivisions = this.nextDivision() })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  miniToggle(label: string, enabled: boolean, key: string): void {
    Row() {
      Row() {
        Column()
          .width(6)
          .height(6)
          .borderRadius(3)
          .backgroundColor(ColorToken.white)
      }
      .width(16)
      .height(10)
      .borderRadius(5)
      .padding({ left: 1, right: 1 })
      .justifyContent(enabled ? FlexAlign.End : FlexAlign.Start)
      .backgroundColor(enabled ? ColorToken.primary : ColorToken.border)
      .onClick(() => {
        if (key === 'snapGrid') {
          this.canvasSnapGrid = !this.canvasSnapGrid
        } else {
          this.canvasSnapGuide = !this.canvasSnapGuide
        }
      })
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.secondary)
        .margin({ left: 4 })
    }
    .alignItems(VerticalAlign.Center)
    .margin({ right: 12 })
  }

  private nextDivision(): number {
    const idx = this.divisionOptions.indexOf(this.canvasGridDivisions)
    return this.divisionOptions[(idx + 1) % this.divisionOptions.length]
  }
}