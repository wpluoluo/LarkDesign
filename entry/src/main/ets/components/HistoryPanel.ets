/**
 * HistoryPanel - 历史记录面板
 *
 * 对应原型 src/components/HistoryPanel.vue
 * 精准还原：标题栏 + 快照条（相机图标 + 步数）+ 撤销/重做进度条 + 历史列表 + 底部统计
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontSizeToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'

interface HistoryItem {
  key: string
  label: string
  icon: string
  index: number
  current: boolean
  future: boolean
  canRedo: boolean
  timestamp: string
}

@Component
export struct HistoryPanel {
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  @State collapsed: boolean = false
  @State hoveredItem: string = ''
  @State hoveredBtn: string = ''
  @State undoCount: number = 0
  @State redoCount: number = 0
  @State showOptions: boolean = false
  @State currentIndex: number = 6
  // 折叠动画宽度
  @State panelWidth: number = 200

  aboutToAppear(): void {
    this.syncHistory()
  }

  private syncHistory(): void {
    this.undoCount = this.fusionStore.getHistoryUndoCount()
    this.redoCount = this.fusionStore.getHistoryRedoCount()
  }

  private historyList: HistoryItem[] = [
    { key: 'h1', label: '新建矩形', icon: Icon.plus, index: 1, current: false, future: false, canRedo: false, timestamp: '14:32' },
    { key: 'h2', label: '调整位置', icon: Icon.cursor, index: 2, current: false, future: false, canRedo: false, timestamp: '14:33' },
    { key: 'h3', label: '修改填充色', icon: Icon.palette, index: 3, current: false, future: false, canRedo: false, timestamp: '14:35' },
    { key: 'h4', label: '添加文字', icon: Icon.text, index: 4, current: false, future: false, canRedo: false, timestamp: '14:36' },
    { key: 'h5', label: '手动快照', icon: Icon.camera, index: 5, current: false, future: false, canRedo: false, timestamp: '14:38' },
    { key: 'h6', label: '编组对象', icon: Icon.group, index: 6, current: true, future: false, canRedo: false, timestamp: '14:42' },
    { key: 'h7', label: '删除图片', icon: Icon.trash, index: 7, current: false, future: true, canRedo: true, timestamp: '14:45' },
    { key: 'h8', label: '修改圆角', icon: Icon.grid, index: 8, current: false, future: true, canRedo: true, timestamp: '14:48' },
  ]

  /** 根据描述动态推断图标（对应原型 describeToIcon） */
  private describeToIcon(desc: string): string {
    if (desc.includes('新增') || desc.includes('创建') || desc.includes('新建')) return Icon.plus
    if (desc.includes('删除') || desc.includes('移除')) return Icon.trash
    if (desc.includes('移动') || desc.includes('调整') || desc.includes('变换')) return Icon.cursor
    if (desc.includes('编组') || desc.includes('组')) return Icon.group
    if (desc.includes('图层')) return Icon.layers
    if (desc.includes('文字') || desc.includes('文本')) return Icon.text
    if (desc.includes('形状') || desc.includes('矩形') || desc.includes('椭圆')) return Icon.rect
    if (desc.includes('图片') || desc.includes('图像')) return Icon.image
    if (desc.includes('蒙版')) return Icon.palette
    if (desc.includes('效果') || desc.includes('投影') || desc.includes('阴影')) return Icon.wand
    if (desc.includes('混合')) return Icon.palette
    if (desc.includes('保存')) return Icon.save
    if (desc.includes('重命名')) return Icon.pen
    if (desc.includes('锁定')) return Icon.lock
    if (desc.includes('隐藏') || desc.includes('显示')) return Icon.eye
    if (desc.includes('复制') || desc.includes('克隆')) return Icon.copy
    if (desc.includes('翻转')) return Icon.flip_h
    if (desc.includes('旋转')) return Icon.rotate
    return Icon.history
  }

  /** 切换折叠状态并播放宽度过渡动画 */
  private toggleCollapse(): void {
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.collapsed = !this.collapsed
      this.panelWidth = this.collapsed ? 36 : 200
    })
  }

  build(): void {
    Column() {
      // Header
      Row() {
        Row() {
          Text(Icon.history)
            .fontSize(11)
            .fontColor(ColorToken.secondary)
          if (!this.collapsed) {
            Text('历史记录')
              .fontSize(FontSizeToken.level3)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.body)
              .margin({ left: 6 })
          }
        }
        .layoutWeight(1)

        // 折叠按钮（原型：chevron 在前，p-[4px] 自适应 ≈ 17×17）
        Column() {
          Text(this.collapsed ? Icon.chevron_right : Icon.chevron_left)
            .fontSize(9)
            .fontColor(this.hoveredBtn === 'collapse' ? ColorToken.body : ColorToken.tertiary)
            .textAlign(TextAlign.Center)
        }
        .padding(4)
        .borderRadius(4)
        .backgroundColor(this.hoveredBtn === 'collapse' ? ColorToken.panel : Color.Transparent)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .animation({ duration: 150, curve: Curve.EaseInOut })
        .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'collapse' : '' })
        .onClick(() => { this.toggleCollapse() })

        if (!this.collapsed) {
          // 选项按钮（原型：ellipsis 在后，gap-[4px]，p-[4px] 自适应）
          Column() {
            Text(Icon.ellipsis)
              .fontSize(9)
              .fontColor(this.hoveredBtn === 'options' ? ColorToken.body : ColorToken.tertiary)
              .textAlign(TextAlign.Center)
          }
          .padding(4)
          .borderRadius(4)
          .margin({ left: 4 })
          .backgroundColor(this.hoveredBtn === 'options' ? ColorToken.panel : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .animation({ duration: 100, curve: Curve.EaseInOut })
          .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'options' : '' })
          .onClick(() => { this.showOptions = !this.showOptions })
        }
      }
      .width('100%')
      .height(40)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })

      if (!this.collapsed) {
        // ─── 快照条（原型：相机图标 + flex-1 占位 + 步数） ───
        Row() {
          // 相机图标（新建快照，原型：text-[8px]，无容器，仅 hover 颜色变化）
          Text(Icon.camera)
            .fontSize(8)
            .fontColor(this.hoveredBtn === 'snapshot' ? ColorToken.primary : ColorToken.tertiary)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'snapshot' : '' })
            .onClick(() => {
              // 新建快照：在当前 index 后插入一条
              const newIndex: number = this.currentIndex + 1
              this.currentIndex = newIndex
              this.historyList = this.historyList.map((h: HistoryItem): HistoryItem => {
                const item: HistoryItem = {
                  key: h.key, label: h.label, icon: h.icon, index: h.index,
                  current: h.index === newIndex, future: h.index > newIndex, canRedo: h.index > newIndex,
                  timestamp: h.timestamp,
                }
                return item
              })
              this.undoCount = newIndex
              this.redoCount = this.historyList.length - newIndex
            })

          // flex-1 占位
          Blank()
            .layoutWeight(1)

          // 步数（原型：仅显示 undoStack.length 步）
          Text(`${this.undoCount} 步`)
            .fontSize(8)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(32)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(ColorToken.panel)
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

        // ─── Undo/Redo 进度条（原型：h-[24px]，gap-[6px]，图标无容器） ───
        Row() {
          // 撤销按钮（原型：text-[8px]，无容器）
          Text(Icon.backward)
            .fontSize(8)
            .fontColor(this.undoCount > 0
              ? (this.hoveredBtn === 'undo' ? ColorToken.primary : ColorToken.tertiary)
              : ColorToken.border)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'undo' : '' })
            .onClick(() => {
              if (this.undoCount > 0) {
                this.undoCount = this.undoCount - 1
                this.redoCount = this.redoCount + 1
                this.currentIndex = this.undoCount
                this.historyList = this.historyList.map((h: HistoryItem): HistoryItem => {
                  const item: HistoryItem = {
                    key: h.key, label: h.label, icon: h.icon, index: h.index,
                    current: h.index === this.undoCount, future: h.index > this.undoCount, canRedo: h.index > this.undoCount,
                    timestamp: h.timestamp,
                  }
                  return item
                })
              }
            })

          // 进度条（原型：h-[3px]，无滑块，gap-[6px]）
          Row() {
            Column()
              .width(`${(this.undoCount / (this.undoCount + this.redoCount)) * 100}%`)
              .height('100%')
              .backgroundColor(ColorToken.primary)
              .borderRadius(2)
          }
          .layoutWeight(1)
          .height(3)
          .backgroundColor(ColorToken.border)
          .borderRadius(2)
          .margin({ left: 6, right: 6 })
          .onClick(() => {
            if (this.undoCount > 0) {
              this.undoCount = this.undoCount - 1
              this.redoCount = this.redoCount + 1
              this.currentIndex = this.undoCount
              this.historyList = this.historyList.map((h: HistoryItem): HistoryItem => {
                const item: HistoryItem = {
                  key: h.key, label: h.label, icon: h.icon, index: h.index,
                  current: h.index === this.undoCount, future: h.index > this.undoCount, canRedo: h.index > this.undoCount,
                  timestamp: h.timestamp,
                }
                return item
              })
            }
          })

          // 重做按钮（原型：text-[8px]，无容器）
          Text(Icon.forward)
            .fontSize(8)
            .fontColor(this.redoCount > 0
              ? (this.hoveredBtn === 'redo' ? ColorToken.primary : ColorToken.tertiary)
              : ColorToken.border)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'redo' : '' })
            .onClick(() => {
              if (this.redoCount > 0) {
                this.redoCount = this.redoCount - 1
                this.undoCount = this.undoCount + 1
                this.currentIndex = this.undoCount
                this.historyList = this.historyList.map((h: HistoryItem): HistoryItem => {
                  const item: HistoryItem = {
                    key: h.key, label: h.label, icon: h.icon, index: h.index,
                    current: h.index === this.undoCount, future: h.index > this.undoCount, canRedo: h.index > this.undoCount,
                    timestamp: h.timestamp,
                  }
                  return item
                })
              }
            })
        }
        .width('100%')
        .height(24)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)

        // ─── 历史列表 ───
        if (this.historyList.length === 0) {
          // 空状态（原型：clock-rotate-left 图标 + 暂无历史记录 + 提示，gap-[8px]）
          Column() {
            Text(Icon.history)
              .fontSize(20)
              .fontColor(ColorToken.muted)
              .opacity(0.5)
            Text('暂无历史记录')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .margin({ top: 8 })
            Text('操作文档后会自动记录')
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 40, bottom: 40 })
        } else {
          Scroll() {
            Column() {
              ForEach(this.historyList, (item: HistoryItem) => {
                Row() {
                  // 左侧内容（序号 + 图标 + 标签，gap-[6px]）
                  Row() {
                    // 序号 / 当前指示（w-[14px]，居中）
                    Column() {
                      if (item.current) {
                        Text(Icon.arrow_left)
                          .fontSize(8)
                          .fontColor(ColorToken.primary_dark_700)
                      } else {
                        Text(`${item.index}`)
                          .fontSize(8)
                          .fontWeight(FontWeightConstant.medium)
                          .fontColor(ColorToken.muted)
                      }
                    }
                    .width(14)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    // 图标（gap-[6px]）
                    Text(item.icon)
                      .fontSize(8)
                      .fontColor(item.current ? ColorToken.primary_dark_700 : ColorToken.muted)
                      .margin({ left: 6 })

                    // 标签（gap-[6px]，flex-1，truncate）
                    Text(item.label)
                      .fontSize(10)
                      .fontWeight(item.current ? FontWeightConstant.semibold : FontWeightConstant.regular)
                      .fontColor(item.current ? ColorToken.body : ColorToken.secondary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 6 })
                      .layoutWeight(1)
                  }
                  .layoutWeight(1)
                  .alignItems(VerticalAlign.Center)

                  // 重做图标（原型：v-if canRedo，opacity-0 hover:opacity-100）
                  if (item.canRedo) {
                    Text(Icon.redo)
                      .fontSize(7)
                      .fontColor(ColorToken.muted)
                      .opacity(this.hoveredItem === item.key ? 1 : 0)
                  }
                }
                .width('100%')
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .border({ width: { left: 3 }, color: { left: item.current ? ColorToken.primary : Color.Transparent } })
                .backgroundColor(item.current
                  ? ColorToken.hover_bg
                  : (this.hoveredItem === item.key ? ColorToken.panel : Color.Transparent))
                .opacity(item.future ? 0.5 : 1)
                .alignItems(VerticalAlign.Center)
                .onHover((isHover: boolean) => { this.hoveredItem = isHover ? item.key : '' })
                .onClick(() => {
                  this.currentIndex = item.index
                  this.historyList = this.historyList.map((h: HistoryItem): HistoryItem => {
                    const item2: HistoryItem = {
                      key: h.key, label: h.label, icon: h.icon, index: h.index,
                      current: h.key === item.key, future: h.index > item.index, canRedo: h.index > item.index,
                      timestamp: h.timestamp,
                    }
                    return item2
                  })
                  // 同步 undoCount/redoCount
                  this.undoCount = item.index
                  this.redoCount = this.historyList.length - item.index
                })
              })
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }

        // ─── 底部统计（原型：仅文字） ───
        Row() {
          Text(`${this.undoCount} 已撤销`)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)

          Blank()

          Text(`${this.redoCount} 可重做`)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(22)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
    }
    .width(this.panelWidth)
    .height('100%')
    .backgroundColor(ColorToken.white)
    .border({ width: { left: 1 }, color: { left: ColorToken.border } })
  }
}
