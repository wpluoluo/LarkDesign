/**
 * InspectorPagePropsPanel - 页面属性面板
 *
 * 对应原型 src/components/Inspector.vue 的 Design Tab 页面属性部分
 * 包含：尺寸与单位、出血、边距、分栏
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

@Component
export struct InspectorPagePropsPanel {
  @State expanded: boolean = false
  @State hoveredHead: boolean = false
  @State pageSize: string = 'A4'
  @State bleedEnabled: boolean = false
  @State marginPreset: string = '\u5e38\u89c4'
  @State hoveredMarginBtn: string = ''

  private sizeOptions: string[] = ['A4', 'A3', 'A5', '\u4fe1\u7eb8', '\u6cd5\u5f8b']
  private marginOptions: string[] = ['\u7a84', '\u5e38\u89c4', '\u5bbd']
  private pageWidth: string = '210 mm'
  private pageHeight: string = '297 mm'
  private pageOrientation: string = '\u7eb5\u5411'
  private pageUnit: string = 'mm'
  private pageDPI: string = '300 DPI'
  private bleedTop: string = '3 mm'
  private bleedBottom: string = '3 mm'
  private bleedLeft: string = '3 mm'
  private bleedRight: string = '3 mm'
  private marginTop: string = '20 mm'
  private marginBottom: string = '20 mm'
  private marginLeft: string = '15 mm'
  private marginRight: string = '15 mm'
  private columns: string = '12'
  private columnGutter: string = '8 mm'

  build(): void {
    Column() {
      Row() {
        Text('\u9875\u9762\u5c5e\u6027')
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
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
          // ─── 尺寸与单位 ───
          Text('\u5c3a\u5bf8\u4e0e\u5355\u4f4d')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .width('100%')
            .height(28)
          Row() {
            ForEach(this.sizeOptions, (opt: string, idx: number) => {
              Column() {
                Text(opt)
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.body)
              }
              .layoutWeight(1)
              .height(28)
              .borderRadius(4)
              .border({ width: 1, color: this.pageSize === opt ? ColorToken.primary : ColorToken.border })
              .backgroundColor(this.pageSize === opt ? ColorToken.hover_bg : Color.Transparent)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: idx === this.sizeOptions.length - 1 ? 0 : 8 })
              .onClick(() => { this.pageSize = opt })
            })
          }
          .width('100%')
          .margin({ bottom: 6 })
          .alignItems(VerticalAlign.Center)

          Column() {
            this.rowPair('\u5bbd\u5ea6', this.pageWidth, '\u9ad8\u5ea6', this.pageHeight, false)
            this.rowPair('\u65b9\u5411', this.pageOrientation, '\u5355\u4f4d', this.pageUnit, false)
            this.singleRow('DPI', this.pageDPI)
          }
          .width('100%')

          // ─── 出血 ───
          Row() {
            Text('\u51fa\u8840')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
            Blank()
            Row() {
              Text('\u542f\u7528')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
                .margin({ right: 4 })
              Row() {
                Column()
                  .width(10)
                  .height(10)
                  .borderRadius(5)
                  .backgroundColor(ColorToken.white)
              }
              .width(28)
              .height(14)
              .borderRadius(7)
              .padding({ left: 2, right: 2 })
              .justifyContent(this.bleedEnabled ? FlexAlign.End : FlexAlign.Start)
              .backgroundColor(this.bleedEnabled ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.bleedEnabled = !this.bleedEnabled })
            }
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.bleedEnabled = !this.bleedEnabled })
          }
          .width('100%')
          .height(28)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })

          if (this.bleedEnabled) {
            Column() {
              this.rowPair('\u4e0a', this.bleedTop, '\u4e0b', this.bleedBottom, false)
              this.rowPair('\u5de6', this.bleedLeft, '\u53f3', this.bleedRight, false)
            }
            .width('100%')
            .margin({ bottom: 6 })
          }

          // ─── 边距 ───
          Row() {
            Text('\u8fb9\u8ddd')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
            Blank()
            Row() {
              ForEach(this.marginOptions, (m: string) => {
                Text(m)
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(this.marginPreset === m ? ColorToken.primary_dark_700 : ColorToken.muted)
                  .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                  .borderRadius(2)
                  .border({ width: 1, color: this.marginPreset === m ? ColorToken.primary : ColorToken.border })
                  .backgroundColor(this.marginPreset === m ? ColorToken.hover_bg : Color.Transparent)
                  .margin({ right: 4 })
                  .onClick(() => { this.marginPreset = m })
              })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .height(28)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4 })

          Column() {
            this.rowPair('\u4e0a', this.marginTop, '\u4e0b', this.marginBottom, false)
            this.rowPair('\u5de6', this.marginLeft, '\u53f3', this.marginRight, false)
          }
          .width('100%')
          .margin({ bottom: 6 })

          // ─── 分栏 ───
          Text('\u5206\u680f')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .width('100%')
            .height(28)
          Column() {
            this.rowPair('\u680f\u6570', this.columns, '\u95f4\u8ddd', this.columnGutter, false)
          }
          .width('100%')
        }
        .padding({ left: 12, right: 12, bottom: 12 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  statCell(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Blank()
      Text(value)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
    }
    .layoutWeight(1)
    .height(28)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(ColorToken.panel)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  rowPair(l1: string, v1: string, l2: string, v2: string, unused: boolean): void {
    Row() {
      this.statCell(l1, v1)
      this.statCell(l2, v2)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }

  @Builder
  singleRow(label: string, value: string): void {
    Row() {
      this.statCell(label, value)

    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 8 })
  }
}