/**
 * WorkspaceLayout - 工作区主布局
 *
 * 对应原型 src/components/WorkspaceLayout.vue
 * 结构：顶部 MenuBar + ToolOptionsBar / 中部 ToolRail + PagesPanel + Canvas(含标尺) + Inspector + HistoryPanel / 底部 StatusBar + ColorBar + ToastContainer
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, RadiusToken, FontWeightConstant } from '../tokens/DesignTokens'
import { MenuBar } from './MenuBar'
import { ToolOptionsBar } from './ToolOptionsBar'
import { ToolRail } from './ToolRail'
import { PagesPanel } from './PagesPanel'
import { Inspector } from './Inspector'
import { HistoryPanel } from './HistoryPanel'
import { StatusBar } from './StatusBar'
import { CanvasStage } from './CanvasStage'
import { ToastContainer } from './ToastContainer'
import { ColorBar } from './ColorBar'
import { DocumentToolbar } from './DocumentToolbar'
import { ColorSystem } from './ColorSystem'
import { ComponentLibrary } from './ComponentLibrary'
import { AIAssistant } from './AIAssistant'
import { IconCharToken as Icon } from '../tokens/IconToken'

/** 参考线 */
interface GuideLine {
  id: number
  orientation: 'h' | 'v'
  pos: number
}

/** 标尺刻度标签 */
interface RulerMark {
  pos: number
  label: string
}

/** 标尺刻度线 */
interface RulerTick {
  pos: number
  isMajor: boolean
}

@Component
export struct WorkspaceLayout {
  @StorageLink('showPagesPanel') showPagesPanel: boolean = true
  @StorageLink('showInspector') showInspector: boolean = true
  @StorageLink('showHistoryPanel') showHistoryPanel: boolean = false
  @StorageLink('showRuler') showRuler: boolean = true
  @StorageLink('showColorSystem') showColorSystem: boolean = false
  @StorageLink('showComponentLibrary') showComponentLibrary: boolean = false
  @StorageLink('showAIAssistant') showAIAssistant: boolean = false

  // 标尺刻度数据（动态生成）
  private get hMarksGen(): Array<RulerMark> {
    const marks: Array<RulerMark> = []
    for (let i = 0; i <= 800; i += 50) {
      marks.push({ pos: i, label: String(i) } as RulerMark)
    }
    return marks
  }
  private get vMarksGen(): Array<RulerMark> {
    const marks: Array<RulerMark> = []
    for (let i = 0; i <= 600; i += 50) {
      marks.push({ pos: i, label: String(i) } as RulerMark)
    }
    return marks
  }
  private get hTicksGen(): Array<RulerTick> {
    const ticks: Array<RulerTick> = []
    for (let i = 0; i <= 800; i += 5) {
      ticks.push({ pos: i, isMajor: i % 50 === 0 } as RulerTick)
    }
    return ticks
  }
  private get vTicksGen(): Array<RulerTick> {
    const ticks: Array<RulerTick> = []
    for (let i = 0; i <= 600; i += 5) {
      ticks.push({ pos: i, isMajor: i % 50 === 0 } as RulerTick)
    }
    return ticks
  }

  // 参考线状态
  @State guidelines: GuideLine[] = []
  @State draggingGuide: GuideLine | null = null
  @State hoveredGuideId: number = -1
  private guideIdCounter: number = 0

  build(): void {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 顶部：菜单栏 + 工具选项栏
        MenuBar()
        ToolOptionsBar()

        // 面板切换工具栏（原型：StatusBar 中的面板切换入口）
        Row() {
          // 左侧面板切换
          Row() {
            Text(Icon.palette)
              .fontSize(9)
              .fontColor(this.showColorSystem ? ColorToken.primary_dark_700 : ColorToken.tertiary)
            Text('色彩')
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.showColorSystem ? ColorToken.primary_dark_700 : ColorToken.tertiary)
              .margin({ left: 3 })
          }
          .height(22)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(this.showColorSystem ? ColorToken.hover_bg : Color.Transparent)
          .onClick(() => {
            this.showColorSystem = !this.showColorSystem
            AppStorage.setOrCreate<boolean>('showColorSystem', this.showColorSystem)
          })
          .margin({ left: 8 })

          Row() {
            Text(Icon.grid)
              .fontSize(9)
              .fontColor(this.showComponentLibrary ? ColorToken.primary_dark_700 : ColorToken.tertiary)
            Text('组件')
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.showComponentLibrary ? ColorToken.primary_dark_700 : ColorToken.tertiary)
              .margin({ left: 3 })
          }
          .height(22)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(this.showComponentLibrary ? ColorToken.hover_bg : Color.Transparent)
          .onClick(() => {
            this.showComponentLibrary = !this.showComponentLibrary
            AppStorage.setOrCreate<boolean>('showComponentLibrary', this.showComponentLibrary)
          })
          .margin({ left: 4 })

          Row() {
            Text(Icon.wand)
              .fontSize(9)
              .fontColor(this.showAIAssistant ? ColorToken.primary_dark_700 : ColorToken.tertiary)
            Text('AI')
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.showAIAssistant ? ColorToken.primary_dark_700 : ColorToken.tertiary)
              .margin({ left: 3 })
          }
          .height(22)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(this.showAIAssistant ? ColorToken.hover_bg : Color.Transparent)
          .onClick(() => {
            this.showAIAssistant = !this.showAIAssistant
            AppStorage.setOrCreate<boolean>('showAIAssistant', this.showAIAssistant)
          })
          .margin({ left: 4 })

          Blank()
        }
        .width('100%')
        .height(26)
        .backgroundColor(ColorToken.panel)
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
        .alignItems(VerticalAlign.Center)

        // 中部：三栏布局
        Row() {
          // 左侧：工具栏 + 页面面板
          ToolRail()

          if (this.showPagesPanel) {
            PagesPanel()
          }

          // 中央：画布区域（含标尺 + 参考线叠加层 + 额外面板）
          Stack({ alignContent: Alignment.TopStart }) {
            Column() {
              // 顶部水平标尺
              if (this.showRuler) {
                Row() {
                  // 标尺角落
                  Stack({ alignContent: Alignment.Center }) {
                    Column()
                      .width(6)
                      .height(1)
                      .backgroundColor(ColorToken.ruler_corner)
                      .rotate({ x: 0, y: 0, z: 1, angle: 45 })
                  }
                  .width(14)
                  .height(14)
                  .backgroundColor(ColorToken.ruler_bg)
                  .border({ width: { right: 1, bottom: 1 }, color: { right: ColorToken.ruler_border, bottom: ColorToken.ruler_border } })
                  .onClick(() => { this.guidelines = [] })

                  // 水平刻度
                  Row() {
                    ForEach(this.hMarksGen, (m: RulerMark) => {
                      Text(m.label)
                        .fontSize(7)
                        .fontColor(ColorToken.ruler_text)
                        .position({ x: m.pos, y: 1 })
                    })
                    ForEach(this.hTicksGen, (t: RulerTick) => {
                      Column()
                        .width(1)
                        .height(t.pos % 50 === 0 ? 5 : (t.pos % 10 === 0 ? 3 : 2))
                        .backgroundColor(ColorToken.ruler_tick)
                        .position({ x: t.pos, y: 14 - (t.pos % 50 === 0 ? 5 : (t.pos % 10 === 0 ? 3 : 2)) })
                    })
                  }
                  .layoutWeight(1)
                  .height(14)
                  .backgroundColor(ColorToken.ruler_bg)
                  .border({ width: { bottom: 1 }, color: { bottom: ColorToken.ruler_border } })
                  .alignItems(VerticalAlign.Top)
                  .gesture(
                    PanGesture()
                      .onActionStart((e: GestureEvent) => {
                        this.draggingGuide = { id: 0, orientation: 'h', pos: e.offsetY } as GuideLine
                      })
                      .onActionUpdate((e: GestureEvent) => {
                        if (this.draggingGuide) {
                          this.draggingGuide = { id: 0, orientation: 'h', pos: Math.max(0, e.offsetY) } as GuideLine
                        }
                      })
                      .onActionEnd(() => {
                        if (this.draggingGuide && this.draggingGuide.pos > 14) {
                          this.guideIdCounter += 1
                          this.guidelines = [...this.guidelines, {
                            id: this.guideIdCounter,
                            orientation: 'h',
                            pos: this.draggingGuide.pos
                          } as GuideLine]
                        }
                        this.draggingGuide = null
                      })
                  )
                }
                .width('100%')
                .height(14)
              }

              // 左侧垂直标尺 + 画布
              Row() {
                if (this.showRuler) {
                  Column() {
                    ForEach(this.vMarksGen, (m: RulerMark) => {
                      Text(m.label)
                        .fontSize(7)
                        .fontColor(ColorToken.ruler_text)
                        .position({ x: 1, y: m.pos - 4 })
                    })
                  }
                  .width(14)
                  .height('100%')
                  .backgroundColor(ColorToken.ruler_bg)
                  .border({ width: { right: 1 }, color: { right: ColorToken.ruler_border } })
                  .alignItems(HorizontalAlign.Start)
                  .gesture(
                    PanGesture()
                      .onActionStart((e: GestureEvent) => {
                        this.draggingGuide = { id: 0, orientation: 'v', pos: e.offsetX } as GuideLine
                      })
                      .onActionUpdate((e: GestureEvent) => {
                        if (this.draggingGuide) {
                          this.draggingGuide = { id: 0, orientation: 'v', pos: Math.max(0, e.offsetX) } as GuideLine
                        }
                      })
                      .onActionEnd(() => {
                        if (this.draggingGuide && this.draggingGuide.pos > 14) {
                          this.guideIdCounter += 1
                          this.guidelines = [...this.guidelines, {
                            id: this.guideIdCounter,
                            orientation: 'v',
                            pos: this.draggingGuide.pos
                          } as GuideLine]
                        }
                        this.draggingGuide = null
                      })
                  )
                }

                // 画布主体
                CanvasStage()
                  .layoutWeight(1)
                  .height('100%')
              }
              .layoutWeight(1)
            }
            .width('100%')
            .height('100%')

            // 参考线叠加层
            ForEach(this.guidelines, (g: GuideLine) => {
              if (g.orientation === 'h') {
                Stack({ alignContent: Alignment.Center }) {
                  Row()
                    .width('100%')
                    .height(1)
                    .backgroundColor(ColorToken.info)
                  Column()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(ColorToken.info)
                    .opacity(this.hoveredGuideId === g.id ? 1 : 0)
                }
                .width('100%')
                .height(1)
                .position({ x: 14, y: 14 + g.pos })
                .zIndex(10)
                .onHover((isHover: boolean) => { this.hoveredGuideId = isHover ? g.id : -1 })
              } else {
                Stack({ alignContent: Alignment.Center }) {
                  Column()
                    .width(1)
                    .height('100%')
                    .backgroundColor(ColorToken.info)
                  Column()
                    .width(12)
                    .height(12)
                    .borderRadius(6)
                    .backgroundColor(ColorToken.info)
                    .opacity(this.hoveredGuideId === g.id ? 1 : 0)
                }
                .width(1)
                .height('100%')
                .position({ x: 14 + g.pos, y: 14 })
                .zIndex(10)
                .onHover((isHover: boolean) => { this.hoveredGuideId = isHover ? g.id : -1 })
              }
            }, (g: GuideLine) => `${g.id}`)

            // 拖动预览线
            if (this.draggingGuide) {
              if (this.draggingGuide.orientation === 'h') {
                Row()
                  .width('100%')
                  .height(1)
                  .backgroundColor(ColorToken.error)
                  .position({ x: 14, y: 14 + this.draggingGuide.pos })
                  .zIndex(20)
              } else {
                Column()
                  .width(1)
                  .height('100%')
                  .backgroundColor(ColorToken.error)
                  .position({ x: 14 + this.draggingGuide.pos, y: 14 })
                  .zIndex(20)
              }
            }

            // 右侧浮动面板层
            // 颜色系统面板（左上角浮动）
            if (this.showColorSystem) {
              ColorSystem()
                .width(240)
                .position({ x: 20, y: 20 })
                .zIndex(30)
            }

            // 组件库面板（右下角浮动）
            if (this.showComponentLibrary) {
              ComponentLibrary()
                .width(240)
                .position({ x: '100%', y: '100%' })
                .markAnchor({ x: '100%', y: '100%' })
                .offset({ x: -20, y: -20 })
                .zIndex(30)
            }

            // AI 助手面板（右下角浮动，在组件库上方）
            if (this.showAIAssistant) {
              AIAssistant()
                .width(280)
                .height(380)
                .position({ x: '100%', y: '100%' })
                .markAnchor({ x: '100%', y: '100%' })
                .offset({ x: -280, y: -400 })
                .zIndex(30)
            }
          }
          .layoutWeight(1)
          .backgroundColor(ColorToken.canvas_bg)

          // 历史面板
          if (this.showHistoryPanel) {
            HistoryPanel()
          }

          // 右侧：检查器
          if (this.showInspector) {
            Inspector()
          }
        }
        .layoutWeight(1)

        // 底部：色彩条 + 状态栏
        Column() {
          ColorBar()
          StatusBar()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorToken.panel)

      // 浮动 Toast
      ToastContainer()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorToken.panel)
  }
}


