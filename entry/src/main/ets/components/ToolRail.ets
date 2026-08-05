/**
 * ToolRail - 左侧工具栏
 *
 * 对应原型 src/components/ToolRail.vue
 * 精准还原：48px 宽 + 36x36 工具按钮 + 选中态内描边 + hover + 多工具指示器 + Tooltip + Flyout 弹出菜单
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, SpacingToken, RadiusToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

/** 工具项 */
interface ToolItem {
  id: string
  name: string
  icon: string
  shortcut: string
}

/** 工具组 */
interface ToolGroupItem {
  id: string
  label: string
  icon: string
  shortcut: string
  hasMultiple: boolean
  tools: ToolItem[]
}

@Component
export struct ToolRail {
  @StorageLink('currentTool') currentTool: string = 'select'
  @State hoveredTool: string = ''
  @State tooltipTool: string = ''
  // Flyout 弹出菜单（长按/右键展开）
  @State flyoutGroupId: string = ''
  @State flyoutY: number = 0
  @State hoveredFlyoutTool: string = ''
  // 长按计时器（350ms 触发）
  private longPressTimerId: number = -1

  private tools: ToolGroupItem[] = [
    {
      id: 'select', label: '选择', icon: Icon.cursor, shortcut: 'V', hasMultiple: true,
      tools: [
        { id: 'select', name: '选择', icon: Icon.cursor, shortcut: 'V' },
        { id: 'direct_select', name: '直接选择', icon: Icon.cursor, shortcut: 'A' },
        { id: 'lasso', name: '套索', icon: Icon.cursor, shortcut: 'L' },
      ],
    },
    {
      id: 'rectangle', label: '矩形', icon: Icon.rect, shortcut: 'R', hasMultiple: true,
      tools: [
        { id: 'rectangle', name: '矩形', icon: Icon.rect, shortcut: 'R' },
        { id: 'rounded_rect', name: '圆角矩形', icon: Icon.rect, shortcut: 'R' },
        { id: 'line', name: '直线', icon: Icon.rect, shortcut: '\\' },
      ],
    },
    {
      id: 'ellipse', label: '椭圆', icon: Icon.circle, shortcut: 'O', hasMultiple: false,
      tools: [{ id: 'ellipse', name: '椭圆', icon: Icon.circle, shortcut: 'O' }],
    },
    {
      id: 'text', label: '文字', icon: Icon.text, shortcut: 'T', hasMultiple: false,
      tools: [{ id: 'text', name: '文字', icon: Icon.text, shortcut: 'T' }],
    },
    {
      id: 'pen', label: '钢笔', icon: Icon.pen, shortcut: 'P', hasMultiple: true,
      tools: [
        { id: 'pen', name: '钢笔', icon: Icon.pen, shortcut: 'P' },
        { id: 'bezier', name: '贝塞尔', icon: Icon.bezier, shortcut: 'P' },
        { id: 'pencil', name: '铅笔', icon: Icon.pen, shortcut: 'N' },
      ],
    },
    {
      id: 'eyedropper', label: '吸管', icon: Icon.eyedropper, shortcut: 'I', hasMultiple: false,
      tools: [{ id: 'eyedropper', name: '吸管', icon: Icon.eyedropper, shortcut: 'I' }],
    },
    {
      id: 'hand', label: '抓手', icon: Icon.hand, shortcut: 'H', hasMultiple: false,
      tools: [{ id: 'hand', name: '抓手', icon: Icon.hand, shortcut: 'H' }],
    },
    {
      id: 'zoom', label: '缩放', icon: Icon.zoom_in, shortcut: 'Z', hasMultiple: false,
      tools: [{ id: 'zoom', name: '缩放', icon: Icon.zoom_in, shortcut: 'Z' }],
    },
  ]

  /** 获取当前 Flyout 组的工具列表 */
  private getFlyoutTools(): ToolItem[] {
    const g = this.tools.find(t => t.id === this.flyoutGroupId)
    return g ? g.tools : []
  }

  /** 获取当前 Flyout 组标签 */
  private getFlyoutGroupLabel(): string {
    const g = this.tools.find(t => t.id === this.flyoutGroupId)
    return g ? g.label : ''
  }

  /** 获取当前 Flyout 组图标 */
  private getFlyoutGroupIcon(): string {
    const g = this.tools.find(t => t.id === this.flyoutGroupId)
    return g ? g.icon : ''
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        ForEach(this.tools, (tool: ToolGroupItem) => {
          this.toolButton(tool)
        })
      }
      .width(LayoutToken.tool_rail_width)
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: SpacingToken.s2, bottom: SpacingToken.s2 })
      .backgroundColor(ColorToken.panel)
      .border({ width: { right: 1 }, color: { right: ColorToken.border } })
      .zIndex(40)

      // Flyout 弹出菜单（长按/右键展开，原型：min-w-[180px] rounded-[10px]）
      if (this.flyoutGroupId !== '') {
        Column() {
          // Flyout 头部（组图标 + 组标签）
          Row() {
            Text(this.getFlyoutGroupIcon())
              .fontSize(10)
              .fontColor(ColorToken.primary_dark_700)
            Text(this.getFlyoutGroupLabel())
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.tertiary)
              .margin({ left: 6 })
          }
          .width('100%')
          .height(26)
          .padding({ left: 12, right: 12 })
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 2 })

          // 工具项列表
          ForEach(this.getFlyoutTools(), (tItem: ToolItem) => {
            Row() {
              // 图标 + 名称
              Row() {
                Text(tItem.icon)
                  .fontSize(11)
                  .fontColor(tItem.id === this.currentTool ? ColorToken.primary_dark_700 : ColorToken.secondary)
                  .width(16)
                  .textAlign(TextAlign.Center)
                Text(tItem.name)
                  .fontSize(12)
                  .fontWeight(tItem.id === this.currentTool ? FontWeightConstant.semibold : FontWeightConstant.regular)
                  .fontColor(tItem.id === this.currentTool ? ColorToken.primary_dark_700 : ColorToken.body)
                  .margin({ left: 10 })
              }
              .layoutWeight(1)

              // 快捷键
              if (tItem.shortcut !== '') {
                Text(tItem.shortcut)
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.tertiary)
                  .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                  .borderRadius(3)
                  .backgroundColor(ColorToken.panel)
                  .margin({ left: 12 })
              }
            }
            .width('100%')
            .height(32)
            .padding({ left: 12, right: 12 })
            .margin({ left: 4, right: 4 })
            .borderRadius(RadiusToken.md)
            .backgroundColor(tItem.id === this.currentTool
              ? ColorToken.hover_bg
              : (this.hoveredFlyoutTool === tItem.id ? ColorToken.panel : Color.Transparent))
            .alignItems(VerticalAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredFlyoutTool = isHover ? tItem.id : '' })
            .onClick(() => {
              AppStorage.setOrCreate<string>('currentTool', tItem.id)
              this.flyoutGroupId = ''
            })
          })
        }
        .width(180)
        .borderRadius(RadiusToken.xl)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow(ShadowToken.xl)
        .padding({ top: 6, bottom: 6 })
        .position({ x: 54, y: this.flyoutY })
        .zIndex(ZIndexToken.dropdown)
      }
    }
    .width('100%')
    .height('100%')
  }

  // CSS triangle 多工具指示器（原型：bottom-[2px] right-[2px] border-l/r/t-[3px] rotate-[-45deg]）
  @Builder
  multiToolIndicator(): void {
    // 用三个 Column 拼接的三角形，简化为旋转的小方框对角线
    Column()
      .width(0)
      .height(0)
      .border({
        width: { left: 3, right: 3, top: 3 },
        color: { left: Color.Transparent, right: Color.Transparent, top: ColorToken.tertiary }
      })
      .rotate({ x: 0, y: 0, z: 1, angle: -45 })
      // 原型：bottom-[2px] right-[2px]，按钮36x36，三角形3x3，所以位置 31,31
      .position({ x: 31, y: 31 })
  }

  @Builder
  toolButton(tool: ToolGroupItem): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Text(tool.icon)
          .fontSize(14)
          .fontColor(this.currentTool === tool.id ? ColorToken.primary_dark_700 : (this.hoveredTool === tool.id ? ColorToken.secondary : ColorToken.secondary))
      }
      .width(36)
      .height(36)
      .borderRadius(RadiusToken.lg)
      .backgroundColor(this.currentTool === tool.id ? ColorToken.hover_bg : (this.hoveredTool === tool.id ? ColorToken.border_light : Color.Transparent))
      .border({
        width: this.currentTool === tool.id ? 1.5 : (this.hoveredTool === tool.id ? 1 : 0),
        color: this.currentTool === tool.id ? ColorToken.primary_light_300 : (this.hoveredTool === tool.id ? ColorToken.border : Color.Transparent),
      })
      // 原型：transition-all duration-100（背景/边框过渡动画）
      .animation({ duration: 100, curve: Curve.EaseInOut })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        // 清除长按计时器（如果还在等待）
        if (this.longPressTimerId !== -1) {
          clearTimeout(this.longPressTimerId)
          this.longPressTimerId = -1
        }
        // 如果 flyout 已展开且为当前组，关闭它
        if (this.flyoutGroupId === tool.id) {
          this.flyoutGroupId = ''
          return
        }
        // 正常点击：激活工具
        AppStorage.setOrCreate<string>('currentTool', tool.id)
        this.flyoutGroupId = ''
      })
      .onHover((isHover: boolean) => {
        this.hoveredTool = isHover ? tool.id : ''
        this.tooltipTool = isHover ? tool.id : ''
      })
      // 长按 350ms 触发展开（仅多工具组）
      .gesture(
        LongPressGesture({ repeat: false, duration: 350 })
          .onAction((event: GestureEvent) => {
            if (tool.hasMultiple) {
              this.showFlyout(tool.id, event.fingerList[0].localY)
            }
          })
      )
      // 右键立即展开（仅多工具组）
      .bindContextMenu({
        builder: () => {
          this.showFlyout(tool.id, 0)
        },
      }, ResponseType.LongPress)

      // 多工具指示器（原型：CSS triangle rotate-[-45deg]，位于 bottom-2 right-2）
      if (tool.hasMultiple) {
        this.multiToolIndicator()
      }

      // Tooltip（原型：opacity-0 group-hover:opacity-100 transition-opacity duration-150 delay-300）
      if (this.tooltipTool === tool.id && this.flyoutGroupId === '') {
        // 主体 + 左指箭头（水平排列，垂直居中对齐按钮中线）
        Row() {
          // 左指箭头（原型：border-t/b-[4px] border-r-[5px] border-r-title）
          Column()
            .width(0)
            .height(0)
            .border({
              width: { top: 4, bottom: 4, right: 5 },
              color: { top: Color.Transparent, bottom: Color.Transparent, right: ColorToken.title }
            })

          // 主体内容
          Row() {
            Text(tool.label)
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.white)
            if (tool.hasMultiple) {
              Text('长按展开')
                .fontSize(9)
                .fontColor(ColorToken.tertiary)
                .margin({ left: 6 })
            }
          }
          .height(26)
          .padding({ left: 8, right: 8 })
          .backgroundColor(ColorToken.title)
          .borderRadius(6)
          // 原型 shadow-lg：双层 0_10px_15px_-3px_rgba(0,0,0,0.1),0_4px_6px_-4px_rgba(0,0,0,0.1)
          .shadow({ radius: 15, color: '#00000026', offsetX: 0, offsetY: 10 })
          .alignItems(VerticalAlign.Center)
        }
        .alignItems(VerticalAlign.Center)
        .position({ x: 44, y: 5 })
        .zIndex(100)
        .opacity(1)
        .animation({ duration: 150, curve: Curve.EaseOut, delay: 300 })
      }
    }
    .width(36)
    .height(36)
    .margin({ top: 1, bottom: 1 })
  }

  /** 显示 Flyout 弹出菜单 */
  private showFlyout(groupId: string, clickY: number): void {
    this.flyoutGroupId = groupId
    // 估算 flyout 位置：基于按钮索引
    const idx = this.tools.findIndex(t => t.id === groupId)
    const baseY = 8 + Math.max(0, idx) * 38 - 8
    this.flyoutY = Math.max(8, baseY)
    this.tooltipTool = ''
  }
}
