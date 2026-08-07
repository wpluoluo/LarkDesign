/**
 * WindowSettingsDialog - 窗口设置对话框
 *
 * 对应原型 src/components/Inspector.vue 的 Window Settings Dialog
 * 包含：预设布局、工具栏显示、面板显示
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface LayoutPreset {
  id: string
  name: string
  left: number
  middle: number
  right: number
}

interface ToggleItem {
  label: string
  visible: boolean
}

@Component
export struct WindowSettingsDialog {
  @Prop visible: boolean = false
  onClose: () => void = () => {}

  @State activePreset: string = 'default'
  @State hoveredPreset: string = ''
  @State hoveredItem: string = ''

  private layoutPresets: LayoutPreset[] = [
    { id: 'default', name: '\u9ed8\u8ba4\u5e03\u5c40', left: 20, middle: 60, right: 20 },
    { id: 'typo', name: '\u6392\u7248\u8bbe\u8ba1', left: 15, middle: 55, right: 30 },
    { id: 'painting', name: '\u7ed8\u753b', left: 10, middle: 70, right: 20 },
    { id: 'photo', name: '\u6444\u5f71', left: 15, middle: 65, right: 20 },
    { id: 'minimal', name: '\u6781\u7b80', left: 5, middle: 85, right: 10 },
  ]
  private toolbarItems: ToggleItem[] = [
    { label: '\u5bf9\u9f50\u5de5\u5177', visible: true },
    { label: '\u5206\u5e03\u5de5\u5177', visible: true },
    { label: '\u6392\u5217\u5de5\u5177', visible: true },
    { label: '\u7f16\u7ec4/\u89e3\u7ec4', visible: true },
    { label: '\u53d8\u6362\u8bfb\u6570', visible: true },
    { label: '\u64a4\u9500/\u91cd\u505a', visible: true },
    { label: '\u4fdd\u5b58/\u5bfc\u51fa', visible: true },
    { label: '\u9884\u89c8\u6a21\u5f0f', visible: true },
  ]
  private panelItems: ToggleItem[] = [
    { label: '\u5de5\u5177\u8f68', visible: true },
    { label: '\u9875\u9762\u9762\u677f', visible: true },
    { label: '\u68c0\u67e5\u5668', visible: true },
    { label: 'AI \u52a9\u624b', visible: true },
    { label: '\u56fe\u5c42\u9762\u677f', visible: true },
    { label: '\u8272\u677f\u9762\u677f', visible: false },
    { label: '\u5386\u53f2\u8bb0\u5f55', visible: false },
    { label: '\u4fe1\u606f\u9762\u677f', visible: false },
  ]

  build(): void {
    if (this.visible) {
      Stack() {
        // 遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#0000004D')
          .onClick(() => { this.onClose() })

        // 对话框
        Column() {
          // Header
          Row() {
            Text('\u7a97\u53e3\u8bbe\u7f6e')
              .fontSize(13)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.body)
            Blank()
            Text(Icon.xmark)
              .fontSize(12)
              .fontColor(ColorToken.tertiary)
              .onClick(() => { this.onClose() })
          }
          .width('100%')
          .height(44)
          .padding({ left: 16, right: 16 })
          .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
          .alignItems(VerticalAlign.Center)

          // Body
          Scroll() {
            Column() {
              // ─── 预设布局 ───
              Column() {
                Text('\u9884\u8bbe\u5e03\u5c40')
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.bold)
                  .fontColor(ColorToken.body)
                Row() {
                  ForEach(this.layoutPresets, (preset: LayoutPreset) => {
                    Column() {
                      Row() {
                        Column()
                          .layoutWeight(preset.left)
                          .height(48)
                          .backgroundColor(ColorToken.panel)
                        Column()
                          .layoutWeight(preset.middle)
                          .height(48)
                          .backgroundColor(ColorToken.white)
                        Column()
                          .layoutWeight(preset.right)
                          .height(48)
                          .backgroundColor(ColorToken.panel)
                      }
                      .width(72)
                      .height(48)
                      .border({ width: 1, color: this.activePreset === preset.id ? ColorToken.primary : ColorToken.border })
                      .borderRadius(6)
                      .backgroundColor(ColorToken.white)
                      .clip(true)

                      Text(preset.name)
                        .fontSize(10)
                        .fontWeight(FontWeightConstant.medium)
                        .fontColor(ColorToken.secondary)
                        .margin({ top: 4 })
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Center)
                    .opacity(this.activePreset === preset.id ? 1 : 0.6)
                    .onClick(() => { this.activePreset = preset.id })
                  })
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
                .margin({ top: 8 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })

              // ─── 工具栏显示 ───
              Column() {
                Text('\u5de5\u5177\u680f\u663e\u793a')
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.bold)
                  .fontColor(ColorToken.body)
                Column() {
                  ForEach(this.toolbarItems, (item: ToggleItem, ti: number) => {
                    this.toggleRow('\u5de5\u5177' + ti, item)
                  })
                }
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })

              // ─── 面板显示 ───
              Column() {
                Text('\u9762\u677f\u663e\u793a')
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.bold)
                  .fontColor(ColorToken.body)
                Column() {
                  ForEach(this.panelItems, (item: ToggleItem, pi: number) => {
                    this.toggleRow('\u9762\u677f' + pi, item)
                  })
                }
                .width('100%')
                .margin({ top: 4 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(16)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // Footer
          Row() {
            Blank()
            Column() {
              Text('\u53d6\u6d88')
                .fontSize(11)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.secondary)
            }
            .height(32)
            .padding({ left: 12, right: 12 })
            .border({ width: 1, color: ColorToken.border })
            .borderRadius(6)
            .justifyContent(FlexAlign.Center)
            .onClick(() => { this.onClose() })

            Column() {
              Text('\u5e94\u7528')
                .fontSize(11)
                .fontWeight(FontWeightConstant.bold)
                .fontColor(ColorToken.white)
            }
            .height(32)
            .padding({ left: 12, right: 12 })
            .borderRadius(6)
            .backgroundColor(ColorToken.primary_dark_700)
            .justifyContent(FlexAlign.Center)
            .margin({ left: 8 })
            .onClick(() => { this.onClose() })
          }
          .width('100%')
          .height(48)
          .padding({ left: 16, right: 16 })
          .border({ width: { top: 1 }, color: { top: ColorToken.border } })
          .alignItems(VerticalAlign.Center)
        }
        .width(420)
        .constraintSize({ maxHeight: 520 })
        .borderRadius(12)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow({ radius: 24, color: '#00000059', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
      .zIndex(200)
    }
  }

  @Builder
  toggleRow(key: string, item: ToggleItem): void {
    Row() {
      Text(item.label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.secondary)
      Blank()
      Row() {
        Column()
          .width(16)
          .height(16)
          .borderRadius(8)
          .backgroundColor(ColorToken.white)
      }
      .width(36)
      .height(20)
      .borderRadius(10)
      .padding({ left: 2, right: 2 })
      .justifyContent(item.visible ? FlexAlign.End : FlexAlign.Start)
      .backgroundColor(item.visible ? ColorToken.primary : ColorToken.border)
      .onClick(() => { this.toggleItemValue(key, item) })
    }
    .width('100%')
    .height(32)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(this.hoveredItem === key ? ColorToken.panel : Color.Transparent)
    .alignItems(VerticalAlign.Center)
    .onHover((isHover: boolean) => { this.hoveredItem = isHover ? key : '' })
  }

  private toggleItemValue(key: string, item: ToggleItem): void {
    if (key.indexOf('\u5de5\u5177') === 0) {
      const idx = Number(key.substring(2))
      if (idx >= 0 && idx < this.toolbarItems.length) {
        this.toolbarItems[idx].visible = !this.toolbarItems[idx].visible
      }
    } else {
      const idx = Number(key.substring(2))
      if (idx >= 0 && idx < this.panelItems.length) {
        this.panelItems[idx].visible = !this.panelItems[idx].visible
      }
    }
  }
}