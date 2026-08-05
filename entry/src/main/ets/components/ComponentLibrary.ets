/**
 * ComponentLibrary - 组件库面板
 *
 * 对应原型 src/components/ComponentLibrary.vue
 * 显示可复用的 UI 组件库
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, SpacingToken, RadiusToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface ComponentCategory {
  name: string
  icon: string
  count: number
}

@Component
export struct ComponentLibrary {
  @State activeCategory: string = 'all'
  @State searchText: string = ''

  private categories: ComponentCategory[] = [
    { name: '全部', icon: Icon.grid, count: 0 },
    { name: '按钮', icon: Icon.square, count: 6 },
    { name: '卡片', icon: Icon.rect, count: 4 },
    { name: '表单', icon: Icon.pen, count: 8 },
    { name: '导航', icon: Icon.list, count: 5 },
    { name: '弹窗', icon: Icon.square, count: 3 },
    { name: '图标', icon: Icon.star, count: 24 },
  ]

  build(): void {
    Column() {
      // 标题 + 搜索
      Row() {
        Text(Icon.grid)
          .fontSize(12)
          .fontColor(ColorToken.primary)
        Text('组件库')
          .fontSize(12)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.title)
          .margin({ left: 6 })
        Blank()
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 搜索框
      Row() {
        Text(Icon.search)
          .fontSize(9)
          .fontColor(ColorToken.muted)
        TextInput({ text: this.searchText, placeholder: '搜索组件...' })
          .fontSize(10)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .margin({ left: 4 })
          .onChange((val: string) => { this.searchText = val })
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: ColorToken.border })
      .borderRadius(6)
      .margin({ left: 12, right: 12, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 分类列表
      Column() {
        ForEach(this.categories, (cat: ComponentCategory) => {
          Row() {
            Text(cat.icon)
              .fontSize(10)
              .fontColor(ColorToken.tertiary)
            Text(cat.name)
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .margin({ left: 8 })
              .layoutWeight(1)
            if (cat.count > 0) {
              Text(`${cat.count}`)
                .fontSize(9)
                .fontColor(ColorToken.muted)
            }
          }
          .width('100%')
          .height(28)
          .padding({ left: 12, right: 12 })
          .borderRadius(5)
          .backgroundColor(this.activeCategory === cat.name ? ColorToken.hover_bg : Color.Transparent)
          .onClick(() => { this.activeCategory = cat.name })
        })
      }
      .width('100%')
      .padding({ top: 4, bottom: 4 })
    }
    .width('100%')
    .backgroundColor(ColorToken.white)
    .borderRadius(8)
    .border({ width: 1, color: ColorToken.border_light })
  }
}

