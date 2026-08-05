/**
 * ArticleLayout - 文章/书籍布局模式
 *
 * 对应原型 src/components/ArticleLayout.vue
 * 提供文章编辑界面：目录栏 + 内容区 + 样式面板
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, SpacingToken, RadiusToken, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

@Component
export struct ArticleLayout {
  @State activeSection: number = 0
  @State showToc: boolean = true

  private sections: string[] = [
    '封面',
    '目录',
    '第一章 设计基础',
    '1.1 色彩理论',
    '1.2 排版原则',
    '1.3 布局网格',
    '第二章 品牌设计',
    '2.1 Logo 设计',
  ]

  build(): void {
    Row() {
      // 目录栏
      if (this.showToc) {
        Column() {
          // 标题
          Row() {
            Text(Icon.book)
              .fontSize(12)
              .fontColor(ColorToken.primary)
            Text('目录')
              .fontSize(12)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.title)
              .margin({ left: 6 })
            Blank()
            Text(Icon.chevron_down)
              .fontSize(8)
              .fontColor(ColorToken.tertiary)
              .onClick(() => { this.showToc = false })
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 10, bottom: 8 })
          .alignItems(VerticalAlign.Center)

          // 章节列表
          Scroll() {
            Column() {
              ForEach(this.sections, (section: string, index: number) => {
                Row() {
                  Text(section)
                    .fontSize(11)
                    .fontWeight(index === this.activeSection ? FontWeightConstant.semibold : FontWeightConstant.regular)
                    .fontColor(index === this.activeSection ? ColorToken.primary_dark_700 : ColorToken.body)
                    .maxLines(1)
                    .textOverflow(TextOverflow.Ellipsis)
                }
                .width('100%')
                .height(28)
                .padding({ left: 12, right: 12 })
                .backgroundColor(index === this.activeSection ? ColorToken.hover_bg : Color.Transparent)
                .borderRadius(4)
                .onClick(() => { this.activeSection = index })
              })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .width(200)
        .backgroundColor(ColorToken.white)
        .border({ width: { right: 1 }, color: { right: ColorToken.border_light } })
      }

      // 内容区
      Column() {
        // 顶部工具栏
        Row() {
          if (!this.showToc) {
            Text(Icon.chevron_right)
              .fontSize(10)
              .fontColor(ColorToken.tertiary)
              .margin({ left: 8, right: 8 })
              .onClick(() => { this.showToc = true })
          }

          Text('第 ${this.activeSection + 1} 节')
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.title)

          Blank()

          // 样式按钮
          Row() {
            Text(Icon.text)
              .fontSize(10)
              .fontColor(ColorToken.secondary)
            Text('正文')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
            Text(Icon.chevron_down)
              .fontSize(6)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .height(24)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(ColorToken.panel)
          .border({ width: 1, color: ColorToken.border })
          .margin({ right: 8 })
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .height(36)
        .backgroundColor(ColorToken.panel)
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
        .alignItems(VerticalAlign.Center)

        // 编辑区
        Scroll() {
          Column() {
            // 文章标题
            Text('设计基础导论')
              .fontSize(24)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.title)
              .lineHeight(32)
              .margin({ bottom: 16 })

            // 文章内容
            Text('设计是视觉传达的艺术与科学。在数字时代，优秀的设计不仅仅是美观的呈现，更是有效沟通的桥梁。本章将介绍设计的基础理论，为后续的实践打下坚实的理论基础。')
              .fontSize(14)
              .fontWeight(FontWeightConstant.regular)
              .fontColor(ColorToken.body)
              .lineHeight(24)
              .margin({ bottom: 12 })

            Text('色彩是设计中最重要的元素之一。不同的色彩能够唤起不同的情感反应，影响观者的感知和决策。理解色彩理论对于创建有效的设计至关重要。')
              .fontSize(14)
              .fontWeight(FontWeightConstant.regular)
              .fontColor(ColorToken.body)
              .lineHeight(24)
              .margin({ bottom: 12 })

            Text('排版是设计的另一个核心要素。合适的字体选择、行距、字距和段落间距能够显著提升可读性和视觉层次感。在排版中，一致性和对比度是需要平衡的两个关键原则。')
              .fontSize(14)
              .fontWeight(FontWeightConstant.regular)
              .fontColor(ColorToken.body)
              .lineHeight(24)
              .margin({ bottom: 12 })
          }
          .width('100%')
          .padding({ left: 32, right: 32, top: 24, bottom: 24 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(ColorToken.white)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorToken.bg)
  }
}
