/**
 * ThemePicker - 主题选择器
 *
 * 对应原型 src/components/ThemePicker.vue
 * 弹出面板显示 5 套主题 + 跟随系统切换
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant, FontSizeToken, ShadowToken, SpacingToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { ThemeStore, ThemeId, THEME_LIST, ThemeMeta } from '../stores/ThemeStore'

export interface ThemeSwatch {
  colors: string[]
}

@Component
export struct ThemePicker {
  @State popupOpen: boolean = false
  @State popupX: number = 0
  @State popupY: number = 0
  @StorageLink('currentTheme') currentThemeId: string = 'light'

  private themeStore: ThemeStore = ThemeStore.getInstance()

  build(): void {
    Column() {
      Row() {
        // 图标
        Text(Icon.palette)
          .fontSize(10)
          .fontColor(ColorToken.tertiary)

        // 当前主题名称
        Text(this.currentThemeName())
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.tertiary)
          .margin({ left: 4 })

        // 下拉箭头
        Text(Icon.chevron_down)
          .fontSize(6)
          .fontColor(ColorToken.muted)
          .margin({ left: 4 })
      }
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(3)
      .backgroundColor(ColorToken.transparent)
      .onHover((isHover: boolean) => {
        if (isHover) {
          // 悬停效果由父容器控制
        }
      })
      .onClick(() => {
        this.popupOpen = !this.popupOpen
      })
    }
    .onClick(() => { this.popupOpen = !this.popupOpen })

    // 弹出面板
    if (this.popupOpen) {
      Column() {
        // 标题区
        Row() {
          Text(Icon.palette)
            .fontSize(11)
            .fontColor(ColorToken.primary)

          Text('主题')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
            .margin({ left: 6 })

          Blank()

          Text('视觉效果')
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor(ColorToken.panel)
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
        .alignItems(VerticalAlign.Center)

        // 跟随系统开关
        Row() {
          Row() {
            Text(Icon.refresh)
              .fontSize(11)
              .fontColor(ColorToken.secondary)

            Text('跟随系统')
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)

          Blank()

          // 开关
          Row() {
            Column()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor(Color.White)
              .position({ x: false ? 14 : 1, y: 2 })
          }
          .width(28)
          .height(16)
          .borderRadius(8)
          .backgroundColor(ColorToken.border)
          .border({ width: 1, color: ColorToken.border })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.themeStore.setFollowSystem(!false)
        })

        // 主题列表
        Column() {
          ForEach(THEME_LIST, (theme: ThemeMeta) => {
            Row() {
              // 色板预览
              Row() {
                ForEach(theme.swatch, (color: string) => {
                  Column()
                    .width(14)
                    .height(14)
                    .borderRadius(3)
                    .backgroundColor(color)
                    .border({ width: 1, color: ColorToken.border })
                    .margin({ right: 2 })
                })
              }

              // 名称 + 描述
              Column() {
                Text(theme.name)
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.semibold)
                  .fontColor(ColorToken.body)
                Text(theme.description)
                  .fontSize(9)
                  .fontColor(ColorToken.muted)
                  .margin({ top: 1 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 10 })

              // 选中标记
              if (this.currentThemeId === theme.id) {
                Text(Icon.check)
                  .fontSize(10)
                  .fontColor(ColorToken.primary)
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(0)
            .backgroundColor(this.currentThemeId === theme.id ? ColorToken.hover_bg : Color.Transparent)
            .onHover((isHover: boolean) => {
              if (isHover && this.currentThemeId !== theme.id) {
                // hover effect handled by backgroundColor
              }
            })
            .onClick(() => {
              this.themeStore.setTheme(theme.id as ThemeId)
              this.popupOpen = false
            })
          })
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }
      .width(280)
      .borderRadius(10)
      .backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.border })
      .shadow(ShadowToken.xl)
      .position({ x: this.popupX, y: this.popupY })
      .zIndex(500)
      .onClick(() => {}) // 阻止事件冒泡
    }
  }

  private currentThemeName(): string {
    const t = THEME_LIST.find((item: ThemeMeta) => item.id === this.currentThemeId)
    return t ? t.name : '明亮'
  }
}


