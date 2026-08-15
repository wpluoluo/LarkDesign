/**
 * HistoryPanel - 历史记录面板
 *
 * 对应原型 src/components/HistoryPanel.vue
 * 从 FusionDocumentStore 读取真实历史记录数据
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontSizeToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore, HistoryEntry } from '../stores/FusionDocumentStore'
import { ToastStore } from '../stores/ToastStore'

@Component
export struct HistoryPanel {
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private toast: ToastStore = ToastStore.getInstance()
  @State collapsed: boolean = false
  @State hoveredItem: string = ''
  @State hoveredBtn: string = ''
  @State showOptions: boolean = false
  @State panelWidth: number = 200

  @StorageLink('historyVersion') historyVersion: number = 0

  private get historyEntries(): HistoryEntry[] {
    return this.fusionStore.getHistoryEntries()
  }

  private get undoCount(): number {
    return this.fusionStore.getHistoryUndoCount()
  }

  private get redoCount(): number {
    return this.fusionStore.getHistoryRedoCount()
  }

  private get undoProgress(): number {
    return this.fusionStore.getHistoryUndoProgress()
  }

  /** 根据描述动态推断图标 */
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
    if (desc.includes('快照')) return Icon.camera
    return Icon.history
  }

  private toggleCollapse(): void {
    this.collapsed = !this.collapsed
    this.panelWidth = this.collapsed ? 36 : 200
  }

  private onUndo(): void {
    if (this.fusionStore.canUndo()) {
      this.fusionStore.undo()
      this.toast.show('已撤销', Icon.undo, 'info')
    }
  }

  private onRedo(): void {
    if (this.fusionStore.canRedo()) {
      this.fusionStore.redo()
      this.toast.show('已重做', Icon.redo, 'info')
    }
  }

  private onItemClick(item: HistoryEntry): void {
    if (item.current) return
    this.fusionStore.jumpToHistory(item.index)
    this.toast.show(`跳转到: ${item.label}`, Icon.history, 'info')
  }

  private onSnapshot(): void {
    this.fusionStore.pushHistory('手动快照')
    this.toast.show('已创建快照', Icon.camera, 'success')
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
        // 快照条
        Row() {
          Text(Icon.camera)
            .fontSize(8)
            .fontColor(this.hoveredBtn === 'snapshot' ? ColorToken.primary : ColorToken.tertiary)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'snapshot' : '' })
            .onClick(() => { this.onSnapshot() })

          Blank()
            .layoutWeight(1)

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

        // Undo/Redo 进度条
        Row() {
          Text(Icon.backward)
            .fontSize(8)
            .fontColor(this.undoCount > 0
              ? (this.hoveredBtn === 'undo' ? ColorToken.primary : ColorToken.tertiary)
              : ColorToken.border)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'undo' : '' })
            .onClick(() => { this.onUndo() })

          Row() {
            Column()
              .width(`${this.undoProgress}%`)
              .height('100%')
              .backgroundColor(ColorToken.primary)
              .borderRadius(2)
          }
          .layoutWeight(1)
          .height(3)
          .backgroundColor(ColorToken.border)
          .borderRadius(2)
          .margin({ left: 6, right: 6 })
          .onClick(() => { this.onUndo() })

          Text(Icon.forward)
            .fontSize(8)
            .fontColor(this.redoCount > 0
              ? (this.hoveredBtn === 'redo' ? ColorToken.primary : ColorToken.tertiary)
              : ColorToken.border)
            .textAlign(TextAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'redo' : '' })
            .onClick(() => { this.onRedo() })
        }
        .width('100%')
        .height(24)
        .padding({ left: 10, right: 10 })
        .alignItems(VerticalAlign.Center)

        // 历史列表
        if (this.historyEntries.length === 0) {
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
              ForEach(this.historyEntries, (item: HistoryEntry) => {
                Row() {
                  Row() {
                    Column() {
                      if (item.current) {
                        Text(Icon.arrow_left)
                          .fontSize(8)
                          .fontColor(ColorToken.primary_dark_700)
                      } else {
                        Text(`${item.index + 1}`)
                          .fontSize(8)
                          .fontWeight(FontWeightConstant.medium)
                          .fontColor(ColorToken.muted)
                      }
                    }
                    .width(14)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)

                    Text(this.describeToIcon(item.label))
                      .fontSize(8)
                      .fontColor(item.current ? ColorToken.primary_dark_700 : ColorToken.muted)
                      .margin({ left: 6 })

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
                .onClick(() => { this.onItemClick(item) })
              })
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }

        // 底部统计
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
