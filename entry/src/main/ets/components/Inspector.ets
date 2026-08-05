/**
 * Inspector - 右侧属性面板
 *
 * 对应原型 src/components/Inspector.vue
 * 精准还原：Tab 头 + 选中元素指示条 + 可折叠分区
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, HeightToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { ColorPickerPopover } from './ColorPickerPopover'

/** fx 图层样式项 */
interface FxItem {
  id: string
  type: string  // shadow | inner_shadow | bg_blur | blur
  enabled: boolean
  label: string
  icon: string
  summary: string
}

/** 混合模式选项 */
interface BlendModeOption {
  value: string
  label: string
}

/** 导出格式选项 */
interface ExportFormatOption {
  id: string
  name: string
}

/** MCP 工具 */
interface McpTool {
  name: string
  icon: string
  calls: number
  enabled: boolean
}

/** 智能体技能 */
interface AgentSkill {
  label: string
  desc: string
  icon: string
  agent: string
  connected: boolean
}

/** AI 对话消息 */
interface AiMessage {
  role: string  // 'assistant' | 'user' | 'tool'
  content: string
  name?: string
}

@Component
export struct Inspector {
  @State activeTab: string = 'design'
  @State expandedSection: string = 'canvas'
  @State linkRatio: boolean = false
  @State flipH: boolean = false
  @State flipV: boolean = false
  @State hoveredPathfinder: string = ''
  @State hoveredSection: string = ''
  @State hoveredTab: string = ''
  // 选中元素状态（原型：未选中显示"未选中元素"）
  @State selectedObjectName: string = 'Frame 1'
  // 画板分区状态
  @State frameName: string = 'Frame 1'
  @State frameType: string = 'single'
  @State frameOrder: number = 1
  @State frameX: number = 0
  @State frameY: number = 0
  @State frameW: number = 595
  @State frameH: number = 842
  @State frameBackground: string = '#FFFFFF'
  @State frameHidden: boolean = false
  @State frameShowPageNumber: boolean = false
  @State hoveredFrameRow: string = ''
  @State hoveredFrameEye: boolean = false
  // 变换分区状态（原型：可输入 input）
  @State transformX: number = 0
  @State transformY: number = 0
  @State transformW: number = 595
  @State transformH: number = 842
  @State transformRot: number = 0
  @State transformScale: number = 100
  // 外观分区状态
  @State fillColor: string = '#34B87A'
  @State strokeColor: string = '#1C2026'
  @State strokeWidth: number = 0
  @State strokePosition: string = 'center'  // center | inside | outside
  @State cornerRadius: number = 0
  @State opacityValue: number = 100
  @State blendMode: string = 'normal'
  @State showBlendModePopup: boolean = false
  @State showFxMenu: boolean = false
  @State hoveredAppearanceRow: string = ''
  @State hoveredBlendMode: boolean = false
  // fx 图层样式列表
  @State fxList: FxItem[] = []
  // 对齐与分布状态
  @State selectedAlign: string = ''
  @State selectedDistribute: string = ''
  @State hoveredAlignBtn: string = ''
  @State hoveredDistributeBtn: string = ''
  // 文字分区状态
  @State textContent: string = ''
  @State textFontSize: number = 14
  @State textLineHeight: number = 1.5
  @State textLetterSpacing: number = 0
  @State textColor: string = '#1C2026'
  @State textFontWeight: string = '400'
  @State hoveredFontWeight: string = ''
  @State textFontFamily: string = 'HarmonyOS Sans SC'
  @State activeTypeStyle: string = ''
  // 颜色选择器弹窗状态
  @State colorPickerVisible: boolean = false
  @State colorPickerX: number = 0
  @State colorPickerY: number = 0
  @State colorPickerTarget: string = 'fill' // fill | stroke | text | frame
  @State colorPickerValue: string = '#3AC487'
  @State colorPickerOpacity: number = 100
  // 导出 Tab 状态
  @State exportFormat: string = 'png'
  @State exportQuality: number = 92
  @State exportScale: number = 100
  @State exportConstrain: boolean = true
  @State exportTransparent: boolean = true
  @State exportColorSpace: string = 'sRGB'
  @State exportEmbedICC: boolean = true
  @State exportPreset: string = 'PNG-24 透明'
  @State secExportBasic: boolean = false
  @State secExportSize: boolean = false
  @State secExportFormatOpt: boolean = false
  @State secExportColor: boolean = false
  @State secExportPresets: boolean = false
  @State pngMode: string = 'PNG-24'
  @State pngInterlace: boolean = false
  @State jpegProgressive: boolean = false
  @State jpegOptimize: boolean = true
  @State svgInline: boolean = true
  @State svgMinify: boolean = true
  @State svgResponsive: boolean = true
  @State pdfStandard: string = 'PDF/X-1a'
  @State pdfCropMarks: boolean = true
  @State pdfBleedMarks: boolean = true
  @State pdfColorBars: boolean = false
  @State hdsMode: string = '标准'
  @State hdsEmbedFonts: boolean = true
  @State hdsEmbedImages: boolean = true
  @State embedFonts: boolean = true
  @State embedImages: boolean = true
  @State hoveredExportFormat: string = ''
  @State hoveredExportPreset: string = ''
  @State hoveredExportColorSpace: string = ''
  @State hoveredExportSection: string = ''
  // 设置 Tab 状态
  @State mcpExpanded: boolean = false
  @State modelExpanded: boolean = false
  @State skillExpanded: boolean = false
  @State sysInfoExpanded: boolean = false
  @State modelProtocol: string = 'OpenAI'
  @State modelProvider: string = 'DeepSeek'
  @State modelUrl: string = 'https://api.deepseek.com/v1'
  @State modelToken: string = 'sk-••••••••••••••••'
  @State modelTokenVisible: boolean = false
  @State modelId: string = 'deepseek-v4-flash'
  @State modelAdvanced: boolean = false
  @State modelMaxTokens: number = 8192
  @State modelTemperature: number = 0.7
  @State modelTimeout: number = 60
  @State modelRetries: number = 3
  @State modelStream: boolean = true
  @State modelThinking: boolean = true
  @State hoveredSettingsRow: string = ''
  // AI Tab 状态（对齐 AIAssistant.vue 原型）
  @State byokConfigured: boolean = false
  @State byokModelId: string = '演示模式'
  @State aiInputText: string = ''
  @State aiMessages: AiMessage[] = [
    { role: 'assistant', content: '你好！我是 AI 设计助手。我可以帮你生成设计元素、调整布局、应用样式。\n\n试试输入"新建一个白底图层"或"查看画布信息"来开始吧。' },
  ]
  @State aiThinking: boolean = false
  @State aiLastError: string = ''
  @State aiToolCallCount: number = 0
  @State aiLayerCount: number = 1
  @State showByokModal: boolean = false
  @State hoveredAiHeaderBtn: string = ''
  @State hoveredAiSend: boolean = false
  @State hoveredAiAttach: boolean = false

  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  aboutToAppear(): void {
    this.syncSelection()
  }

  /** 同步选中对象属性 */
  private syncSelection(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length > 0) {
      const obj = sel[0]
      this.transformX = obj.transform.x
      this.transformY = obj.transform.y
      this.transformW = obj.transform.width
      this.transformH = obj.transform.height
      this.transformRot = obj.transform.rotation
      this.transformScale = obj.transform.scaleX * 100
      this.selectedObjectName = obj.name
    } else {
      const frame = this.fusionStore.getCurrentFrame()
      if (frame) {
        this.frameName = frame.name
        this.frameX = frame.x
        this.frameY = frame.y
        this.frameW = frame.width
        this.frameH = frame.height
        this.frameBackground = frame.background if frame.background else "#FFFFFF"
      }
    }
  }

  /** 更新变换属性到 Store */
  private updateTransform(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length > 0) {
      const obj = sel[0]
      obj.transform.x = this.transformX
      obj.transform.y = this.transformY
      obj.transform.width = this.transformW
      obj.transform.height = this.transformH
      obj.transform.rotation = this.transformRot
      obj.transform.scaleX = this.transformScale / 100
      obj.transform.scaleY = this.transformScale / 100
    }
  }

  /** 更新 Frame 属性到 Store */
  private updateFrameProps(): void {
    const frame = this.fusionStore.getCurrentFrame()
    if (frame) {
      this.fusionStore.updateFrameById(frame.id, this.frameX, this.frameY, this.frameW, this.frameH, this.frameName)
    }
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // Tab 头（原型：h-44px px-12px gap-4px border-b bg-panel + 右侧 ml-auto gear 窗口设置按钮）
        Row() {
          this.tabButton('design', '设计', '')
          this.tabButton('export', '导出', '')
          this.tabButton('settings', '设置', Icon.gear)
          this.tabButton('ai', 'AI智能', Icon.wand)
          Blank()
          // 窗口设置 gear 按钮（原型：ml-auto p-6 rounded-5 hover:bg-hover-bg hover:rotate-45）
          Column() {
            Text(Icon.gear)
              .fontSize(12)
              .fontColor(this.hoveredSection === 'window-settings' ? ColorToken.body : ColorToken.muted)
              .textAlign(TextAlign.Center)
          }
          .width(28)
          .height(28)
          .borderRadius(5)
          .backgroundColor(this.hoveredSection === 'window-settings' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredSection = isHover ? 'window-settings' : '' })
          .onClick(() => { this.activeTab = 'settings' })
        }
        .width('100%')
        .height(44)
        .padding({ left: 12, right: 12 })
        .backgroundColor(ColorToken.panel)
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
        .alignItems(VerticalAlign.Center)

        // ─── DESIGN TAB ───
        if (this.activeTab === 'design') {
          // 选中元素指示条（原型：未选中显示"未选中元素" + 已选中显示对象名+"已选中"+xmark取消）
          Row() {
            Column()
              .width(10)
              .height(10)
              .borderRadius(3)
              .backgroundColor(this.selectedObjectName ? ColorToken.primary : ColorToken.border)
            Text(this.selectedObjectName || '未选中元素')
              .fontSize(13)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(this.selectedObjectName ? ColorToken.body : ColorToken.muted)
              .margin({ left: 8 })
            if (this.selectedObjectName) {
              Blank()
              Text('已选中')
                .fontSize(10)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .margin({ right: 8 })
              Text(Icon.xmark)
                .fontSize(11)
                .fontColor(this.hoveredSection === 'deselect' ? ColorToken.error : ColorToken.muted)
                .onClick(() => { this.selectedObjectName = '' })
            }
          }
          .width('100%')
          .height(40)
          .padding({ left: 14, right: 14 })
          .backgroundColor(this.selectedObjectName ? ColorToken.hover_bg : Color.Transparent)
          .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
          .alignItems(VerticalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredSection = isHover && this.selectedObjectName ? 'deselect' : '' })

          // 可滚动属性区（原型顺序：画板→变换→对齐与分布→外观→文字→路径查找器）
          Scroll() {
            Column() {
              // 画板分区（带动态 frame 图标）
              this.sectionWithIcon('canvas', '画板', this.frameTypeIcon(this.frameType))
              // 变换分区
              this.section('transform', '变换')
              // 对齐与分布分区
              this.section('layout', '对齐与分布')
              // 外观分区
              this.section('appearance', '外观')
              // 文字分区
              this.section('typography', '文字')
              // 路径查找器分区
              this.section('pathfinder', '路径查找器')
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else if (this.activeTab === 'export') {
          this.exportTabContent()
        } else if (this.activeTab === 'settings') {
          this.settingsTabContent()
        } else {
          this.aiTabContent()
        }
      }
      .width(LayoutToken.inspector_width)
      .height('100%')
      .backgroundColor(ColorToken.white)
      .border({ width: { left: 1 }, color: { left: ColorToken.border } })

      // ─── 颜色选择器弹窗（浮层） ───
      ColorPickerPopover({
        visible: this.colorPickerVisible,
        anchorX: this.colorPickerX,
        anchorY: this.colorPickerY,
        modelValue: this.colorPickerValue,
        opacity: this.colorPickerOpacity,
        onPick: (hex: string) => {
          this.colorPickerValue = hex.toUpperCase()
          this.applyColorPickerValue(hex)
        },
        onOpacityChange: (val: number) => {
          this.colorPickerOpacity = val
        },
        onClose: () => { this.colorPickerVisible = false },
      })
    }
    .width(LayoutToken.inspector_width)
    .height('100%')
  }

  /** 打开颜色选择器（使用 Inspector 内固定位置：左侧偏移避免遮挡） */
  private openColorPicker(target: string): void {
    this.colorPickerTarget = target
    if (target === 'fill') {
      this.colorPickerValue = this.fillColor.toUpperCase()
    } else if (target === 'stroke') {
      this.colorPickerValue = this.strokeColor.toUpperCase()
    } else if (target === 'text') {
      this.colorPickerValue = this.textColor.toUpperCase()
    } else if (target === 'frame') {
      this.colorPickerValue = this.frameBackground.toUpperCase()
    }
    // 固定锚点：Inspector 左侧偏移 8px，顶部偏移 80px（避免遮挡 Tab 头）
    this.colorPickerX = 8
    this.colorPickerY = 80
    this.colorPickerVisible = true
  }

  /** 应用颜色选择器返回值 */
  private applyColorPickerValue(hex: string): void {
    if (this.colorPickerTarget === 'fill') {
      this.fillColor = hex
    } else if (this.colorPickerTarget === 'stroke') {
      this.strokeColor = hex
    } else if (this.colorPickerTarget === 'text') {
      this.textColor = hex
    } else if (this.colorPickerTarget === 'frame') {
      this.frameBackground = hex
    }
  }

  @Builder
  tabButton(id: string, label: string, icon: string): void {
    Row() {
      if (icon !== '') {
        Text(icon)
          .fontSize(11)
          .fontColor(this.activeTab === id
            ? ColorToken.primary_dark_700
            : (this.hoveredTab === id ? ColorToken.body : ColorToken.muted))
      }
      Text(label)
        .fontSize(12)
        .fontWeight(this.activeTab === id ? FontWeightConstant.bold : FontWeightConstant.medium)
        .fontColor(this.activeTab === id
          ? ColorToken.primary_dark_700
          : (this.hoveredTab === id ? ColorToken.body : ColorToken.muted))
        .margin({ left: icon !== '' ? 6 : 0 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(6)
    .backgroundColor(this.activeTab === id
      ? ColorToken.hover_bg
      : (this.hoveredTab === id ? ColorToken.panel : Color.Transparent))
    .border({
      width: this.activeTab === id ? 1 : 0,
      color: this.activeTab === id ? ColorToken.primary_light_300 : Color.Transparent
    })
    .margin({ right: 4 })
    .onClick(() => { this.activeTab = id })
    .onHover((isHover: boolean) => {
      if (this.activeTab !== id) {
        this.hoveredTab = isHover ? id : ''
      }
    })
  }

  @Builder
  section(id: string, title: string): void {
    Column() {
      // 分区头（原型：标题在左，chevron 在右）
      Row() {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
        Blank()
        Text(this.expandedSection === id ? Icon.chevron_up : Icon.chevron_down)
          .fontSize(10)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .backgroundColor(this.hoveredSection === id ? ColorToken.panel : Color.Transparent)
      .onClick(() => {
        this.expandedSection = this.expandedSection === id ? '' : id
      })
      .onHover((isHover: boolean) => { this.hoveredSection = isHover ? id : '' })

      // 内容区
      if (this.expandedSection === id) {
        if (id === 'canvas') {
          this.canvasContent()
        } else if (id === 'transform') {
          this.transformContent()
        } else if (id === 'appearance') {
          this.appearanceContent()
        } else if (id === 'layout') {
          this.layoutContent()
        } else if (id === 'pathfinder') {
          this.pathfinderContent()
        } else if (id === 'typography') {
          this.typographyContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  sectionWithIcon(id: string, title: string, icon: string): void {
    Column() {
      // 分区头（带左侧图标）
      Row() {
        Text(icon)
          .fontSize(11)
          .fontColor(ColorToken.primary)
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
          .margin({ left: 8 })
        Blank()
        Text(this.expandedSection === id ? Icon.chevron_up : Icon.chevron_down)
          .fontSize(10)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .backgroundColor(this.hoveredSection === id ? ColorToken.panel : Color.Transparent)
      .onClick(() => {
        this.expandedSection = this.expandedSection === id ? '' : id
      })
      .onHover((isHover: boolean) => { this.hoveredSection = isHover ? id : '' })

      // 内容区
      if (this.expandedSection === id) {
        if (id === 'canvas') {
          this.canvasContent()
        } else if (id === 'transform') {
          this.transformContent()
        } else if (id === 'appearance') {
          this.appearanceContent()
        } else if (id === 'layout') {
          this.layoutContent()
        } else if (id === 'pathfinder') {
          this.pathfinderContent()
        } else if (id === 'typography') {
          this.typographyContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  canvasContent(): void {
    Column() {
      // ─── 画板名称（原型：input v-model，label w-28 uppercase） ───
      Row() {
        Text('名称')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        TextInput({ text: this.frameName })
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .onChange((val: string) => { this.frameName = val })
      }
      .width('100%')
      .height(32)
      .padding({ left: 8, right: 8 })
      .borderRadius(5)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: this.hoveredFrameRow === 'name' ? ColorToken.border : Color.Transparent })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })
      .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'name' : '' })

      // ─── 类型 + 序号（grid-cols-2 gap-8 mb-8） ───
      Row() {
        // 类型
        Row() {
          Text('类型')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .width(28)
          Text(this.frameTypeLabel(this.frameType))
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)

        // 序号
        Row() {
          Text('序号')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .width(28)
          Text(`${this.frameOrder}`)
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 位置 X/Y（原型：input v-model.number） ───
      Row() {
        // X
        Row() {
          Text('X')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.frameX}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.frameX = Number(val) || 0; this.updateFrameProps() })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'x' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'x' : '' })

        // Y
        Row() {
          Text('Y')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.frameY}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.frameY = Number(val) || 0; this.updateFrameProps() })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'y' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'y' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 尺寸 W/H（原型：input v-model.number） ───
      Row() {
        // W
        Row() {
          Text('W')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.frameW}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.frameW = Number(val) || 0; this.updateFrameProps() })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'w' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'w' : '' })

        // H
        Row() {
          Text('H')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.frameH}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.frameH = Number(val) || 0; this.updateFrameProps() })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'h' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'h' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 10 })

      // ─── 背景色（原型：color preview + hex input v-model + 点击打开 ColorPickerPopover） ───
      Row() {
        Text('背景色')
          .fontSize(11)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(4)
            .backgroundColor(this.frameBackground)
            .border({ width: 1, color: ColorToken.border_light })
            .onClick(() => { this.openColorPicker('frame') })
          TextInput({ text: this.frameBackground })
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: Color.Transparent })
            .borderRadius(4)
            .width(88)
            .height(28)
            .padding({ left: 6, right: 6 })
            .textAlign(TextAlign.Start)
            .margin({ left: 6 })
            .onChange((val: string) => { this.frameBackground = val })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(32)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 10 })

      // ─── 书页/对页模式：页码设置（原型：v-if type === 'book-page' || 'spread'） ───
      if (this.frameType === 'book-page' || this.frameType === 'spread') {
        Column() {
          // 显示页码 toggle（原型：w-28 h-16 圆角8 开关）
          Row() {
            Text('显示页码')
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
            Blank()
            Row() {
              Column()
                .width(12)
                .height(12)
                .borderRadius(6)
                .backgroundColor(ColorToken.white)
                .position({ x: this.frameShowPageNumber ? 14 : 2, y: 2 })
            }
            .width(28)
            .height(16)
            .borderRadius(8)
            .backgroundColor(this.frameShowPageNumber ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.frameShowPageNumber = !this.frameShowPageNumber })
          }
          .width('100%')
          .height(28)
          .alignItems(VerticalAlign.Center)

          // 页码 input
          Row() {
            Text('页码')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(28)
            TextInput({ text: `${this.frameOrder}` })
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .type(InputType.Number)
              .onChange((val: string) => { this.frameOrder = Number(val) || 1 })
          }
          .width('100%')
          .height(28)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(ColorToken.panel)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 8 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }

      // ─── 隐藏/显示画板（原型：flex justify-between pt-8 border-t） ───
      Row() {
        Text(this.frameHidden ? '已隐藏' : '显示中')
          .fontSize(11)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Text(this.frameHidden ? Icon.eye_off : Icon.eye)
          .fontSize(11)
          .fontColor(this.hoveredFrameEye
            ? ColorToken.primary
            : (this.frameHidden ? ColorToken.error : ColorToken.muted))
          .onClick(() => { this.frameHidden = !this.frameHidden })
          .onHover((isHover: boolean) => { this.hoveredFrameEye = isHover })
      }
      .width('100%')
      .padding({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  // 画板类型显示标签
  private frameTypeLabel(type: string): string {
    if (type === 'single') return '单页'
    if (type === 'poster') return '海报'
    if (type === 'book-page') return '书页'
    if (type === 'spread') return '对页'
    return '单页'
  }

  /** 根据 Frame 类型返回图标 */
  private frameTypeIcon(type: string): string {
    if (type === 'single') return Icon.file
    if (type === 'poster') return Icon.image
    if (type === 'book-page') return Icon.book
    if (type === 'spread') return Icon.book_open
    return Icon.file
  }

  @Builder
  transformContent(): void {
    Column() {
      // hasSingleSelection：根据是否有选中对象判定 disabled
      // ─── 位置 X/Y（原型：input v-model.number + disabled !hasSingleSelection） ───
      Row() {
        // X
        Row() {
          Text('X')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.transformX}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformX = Number(val) || 0; this.updateTransform() })
          Text('mm')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'tx' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'tx' : '' })

        // Y
        Row() {
          Text('Y')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.transformY}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformY = Number(val) || 0 })
          Text('mm')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'ty' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'ty' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 尺寸 W/H（原型：input v-model.number + disabled） ───
      Row() {
        // W
        Row() {
          Text('W')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.transformW}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformW = Number(val) || 0 })
          Text('mm')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'tw' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'tw' : '' })

        // H
        Row() {
          Text('H')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: `${this.transformH}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformH = Number(val) || 0 })
          Text('mm')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'th' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'th' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 旋转 ∠ + 缩放 ⤧（原型：input v-model.number + disabled） ───
      Row() {
        // ∠ 旋转
        Row() {
          Text('∠')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(20)
          TextInput({ text: `${this.transformRot}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformRot = Number(val) || 0; this.updateTransform() })
          Text('°')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'rot' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'rot' : '' })

        // ⤧ 缩放
        Row() {
          Text('⤧')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(20)
          TextInput({ text: `${this.transformScale}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .enabled(!!this.selectedObjectName)
            .onChange((val: string) => { this.transformScale = Number(val) || 100; this.updateTransform() })
          Text('%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .layoutWeight(1)
        .height(32)
        .padding({ left: 8, right: 8 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'scale' ? ColorToken.border : Color.Transparent })
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .opacity(this.selectedObjectName ? 1 : 0.5)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'scale' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // ─── 链接比例 + 翻转按钮（原型：mt-10 justify-between + disabled） ───
      Row() {
        // 约束比例 checkbox（原型：fa-link 图标在选中时显示）
        Row() {
          Column() {
            if (this.linkRatio) {
              Text(Icon.link)
                .fontSize(8)
                .fontColor(ColorToken.white)
                .textAlign(TextAlign.Center)
            }
          }
          .width(16)
          .height(16)
          .borderRadius(4)
          .backgroundColor(this.linkRatio ? ColorToken.primary : ColorToken.white)
          .border({ width: 1, color: this.linkRatio ? ColorToken.primary : ColorToken.border })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.linkRatio = !this.linkRatio })
          Text('约束比例')
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
        .opacity(this.selectedObjectName ? 1 : 0.5)

        Blank()

        // 水平翻转（原型：hover:bg-panel）
        Column() {
          Text(Icon.flip_h)
            .fontSize(11)
            .fontColor(this.flipH ? ColorToken.primary_dark_700 : ColorToken.secondary)
            .textAlign(TextAlign.Center)
        }
        .width(28)
        .height(28)
        .borderRadius(5)
        .backgroundColor(this.hoveredFrameRow === 'flipH' ? ColorToken.panel : Color.Transparent)
        .border({ width: 1, color: ColorToken.border_light })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 4 })
        .opacity(this.selectedObjectName ? 1 : 0.4)
        .onClick(() => { if (this.selectedObjectName) this.flipH = !this.flipH })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'flipH' : '' })

        // 垂直翻转（原型：hover:bg-panel）
        Column() {
          Text(Icon.flip_v)
            .fontSize(11)
            .fontColor(this.flipV ? ColorToken.primary_dark_700 : ColorToken.secondary)
            .textAlign(TextAlign.Center)
        }
        .width(28)
        .height(28)
        .borderRadius(5)
        .backgroundColor(this.hoveredFrameRow === 'flipV' ? ColorToken.panel : Color.Transparent)
        .border({ width: 1, color: ColorToken.border_light })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 4 })
        .opacity(this.selectedObjectName ? 1 : 0.4)
        .onClick(() => { if (this.selectedObjectName) this.flipV = !this.flipV })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'flipV' : '' })
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  @Builder
  appearanceContent(): void {
    Column() {
      // ─── 填充色（原型：color preview w-24 h-24 + label + color hex 右对齐 + 点击打开 ColorPickerPopover） ───
      Row() {
        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(5)
            .backgroundColor(this.fillColor)
            .border({ width: 1, color: ColorToken.border })
            .shadow(ShadowToken.sm)
            .onClick(() => { this.openColorPicker('fill') })
          Text('填充')
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()
        Text(this.fillColor.toUpperCase())
          .fontSize(11)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 描边色 + 描边宽度（原型：color preview + label + input v-model.number + px + 点击打开 ColorPickerPopover） ───
      Row() {
        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(5)
            .backgroundColor(this.strokeColor)
            .border({ width: 1, color: ColorToken.border })
            .shadow(ShadowToken.sm)
            .onClick(() => { this.openColorPicker('stroke') })
          Text('描边')
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()
        Row() {
          TextInput({ text: `${this.strokeWidth}` })
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .width(52)
            .height(28)
            .padding({ left: 8, right: 8 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.strokeWidth = Number(val) || 0 })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 描边位置 3 按钮组（原型：外部/居中/内部） ───
      Row() {
        this.strokePositionOp('outside', '外部')
        this.strokePositionOp('center', '居中')
        this.strokePositionOp('inside', '内部')
      }
      .width('100%')
      .margin({ bottom: 10 })

      // ─── 圆角半径（原型：label + input v-model.number + px） ───
      Row() {
        Text('圆角半径')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          TextInput({ text: `${this.cornerRadius}` })
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .width(52)
            .height(28)
            .padding({ left: 8, right: 8 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .onChange((val: string) => { this.cornerRadius = Number(val) || 0 })
          Text('px')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 不透明度（原型：label + range slider + input v-model.number + %） ───
      Row() {
        Text('不透明度')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          // slider（可拖拽，带手柄）
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(5)
              .backgroundColor(ColorToken.border)
              .borderRadius(2)
            Row()
              .width(`${this.opacityValue}%`)
              .height(5)
              .backgroundColor(ColorToken.primary)
              .borderRadius(2)
            // 拖动手柄
            Row()
              .width(10)
              .height(10)
              .borderRadius(5)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.primary })
              .margin({ left: `${Math.max(0, this.opacityValue - 5)}%` })
          }
          .width(90)
          .height(12)
          .alignContent(Alignment.Center)
          .gesture(
            PanGesture()
              .onActionStart((e: GestureEvent) => {
                this.updateOpacityFromX(e.fingerList[0].localX)
              })
              .onActionUpdate((e: GestureEvent) => {
                this.updateOpacityFromX(e.fingerList[0].localX)
              })
          )
          .onClick((e: ClickEvent) => {
            this.updateOpacityFromX(e.x)
          })

          TextInput({ text: `${this.opacityValue}` })
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .width(42)
            .height(24)
            .padding({ left: 8, right: 8 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .textAlign(TextAlign.End)
            .type(InputType.Number)
            .margin({ left: 8 })
            .onChange((val: string) => {
              const n = Number(val) || 0
              this.opacityValue = Math.max(0, Math.min(100, n))
            })
          Text('%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 混合模式（原型：label + 点击切换 + chevron-down + popup 列表） ───
      Row() {
        Text('混合模式')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          Text(this.blendModeLabel(this.blendMode))
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
          Text(Icon.chevron_down)
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ left: 4 })
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(this.hoveredBlendMode ? ColorToken.panel : Color.Transparent)
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredBlendMode = isHover })
        .onClick(() => { this.showBlendModePopup = !this.showBlendModePopup })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 混合模式 popup 浮层（原型：fixed z-150 w-170 max-h-280 overflow-y-auto） ───
      if (this.showBlendModePopup) {
        Scroll() {
          Column() {
            ForEach(this.blendModeOptions, (opt: BlendModeOption) => {
              Row() {
                Text(opt.label)
                  .fontSize(12)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.body)
                Blank()
                if (this.blendMode === opt.value) {
                  Text(Icon.check)
                    .fontSize(10)
                    .fontColor(ColorToken.primary)
                }
              }
              .width('100%')
              .height(28)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.hoveredAppearanceRow === `blend_${opt.value}` ? ColorToken.hover_bg : (this.blendMode === opt.value ? ColorToken.hover_bg : Color.Transparent))
              .alignItems(VerticalAlign.Center)
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? `blend_${opt.value}` : '' })
              .onClick(() => {
                this.blendMode = opt.value
                this.showBlendModePopup = false
              })
            })
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        }
        // 原型：fixed z-150 w-[170px] max-h-[280px]
        .width(170)
        .constraintSize({ maxHeight: 280 })
        .scrollBar(BarState.Off)
        .borderRadius(8)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow(ShadowToken.lg)
        .position({ x: '100%', y: 0 })
        .markAnchor({ x: '100%', y: 0 })
        .offset({ x: -14, y: 0 })
        .zIndex(ZIndexToken.dropdown)
      }

      // ─── 图层样式 fx 区（原型：pt-8 border-t） ───
      Column() {
        Row() {
          Text('图层样式')
            .fontSize(11)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          Blank()
          Text(Icon.plus)
            .fontSize(11)
            .fontColor(this.hoveredAppearanceRow === 'fxAdd' ? ColorToken.primary : ColorToken.muted)
            .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? 'fxAdd' : '' })
            .onClick(() => { this.showFxMenu = !this.showFxMenu })
        }
        .width('100%')
        .height(24)
        .alignItems(VerticalAlign.Center)

        // fx 添加菜单（展开时显示）
        if (this.showFxMenu) {
          Column() {
            ForEach(this.fxAvailableTypes, (opt: FxItem) => {
              Row() {
                Text(opt.icon)
                  .fontSize(11)
                  .fontColor(ColorToken.muted)
                  .margin({ right: 8 })
                Text(opt.label)
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.secondary)
              }
              .width('100%')
              .height(28)
              .padding({ left: 8, right: 8 })
              .borderRadius(4)
              .backgroundColor(this.hoveredAppearanceRow === `fx_${opt.type}` ? ColorToken.hover_bg : Color.Transparent)
              .alignItems(VerticalAlign.Center)
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? `fx_${opt.type}` : '' })
              .onClick(() => { this.addFx(opt.type) })
            })
          }
          .width('100%')
          .borderRadius(5)
          .backgroundColor(ColorToken.panel)
          .border({ width: 1, color: ColorToken.border_light })
          .padding(3)
          .margin({ top: 4 })
        }

        // 已有 fx 列表（toggle enable + 删除按钮）
        ForEach(this.fxList, (fx: FxItem) => {
          Row() {
            // 启用/禁用 checkbox
            Text(fx.enabled ? Icon.check_square : Icon.square)
              .fontSize(12)
              .fontColor(fx.enabled ? ColorToken.primary : ColorToken.muted)
              .margin({ right: 8 })
              .onClick(() => { this.toggleFx(fx.id) })
            // fx 图标
            Text(fx.icon)
              .fontSize(12)
              .fontColor(fx.enabled ? ColorToken.primary_dark_700 : ColorToken.muted)
              .margin({ right: 8 })
            // fx 标签
            Text(fx.label)
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(fx.enabled ? ColorToken.secondary : ColorToken.muted)
              .layoutWeight(1)
            // fx 摘要
            Text(fx.summary)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .margin({ right: 8 })
            // 删除按钮
            Text(Icon.trash)
              .fontSize(10)
              .fontColor(this.hoveredAppearanceRow === `fx_del_${fx.id}` ? ColorToken.error : ColorToken.muted)
              .onClick(() => { this.removeFx(fx.id) })
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? `fx_del_${fx.id}` : '' })
          }
          .width('100%')
          .padding(6)
          .borderRadius(5)
          .backgroundColor(this.hoveredAppearanceRow === `fx_item_${fx.id}` ? ColorToken.border_light : Color.Transparent)
          .alignItems(VerticalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? `fx_item_${fx.id}` : '' })
        })

        // 空状态提示（fxList 为空时显示）
        if (this.fxList.length === 0) {
          Row() {
            Text('暂无图层样式')
              .fontSize(11)
              .fontColor(ColorToken.muted)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 8, bottom: 8 })
        }
      }
      .width('100%')
      .padding({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  // 描边位置按钮
  @Builder
  strokePositionOp(value: string, label: string): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(this.strokePosition === value
          ? ColorToken.primary_dark_700
          : (this.hoveredAppearanceRow === value ? ColorToken.body : ColorToken.muted))
    }
    .layoutWeight(1)
    .height(28)
    .borderRadius(4)
    .backgroundColor(this.strokePosition === value
      ? ColorToken.hover_bg
      : (this.hoveredAppearanceRow === value ? ColorToken.panel : Color.Transparent))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ left: 2, right: 2 })
    .onClick(() => { this.strokePosition = value })
    .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? value : '' })
  }

  // fx 菜单项
  @Builder
  fxMenuItem(value: string, label: string, icon: string): void {
    Row() {
      Text(icon)
        .fontSize(11)
        .fontColor(ColorToken.muted)
        .margin({ right: 8 })
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.secondary)
    }
    .width('100%')
    .height(28)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(this.hoveredAppearanceRow === `fx_${value}` ? ColorToken.hover_bg : Color.Transparent)
    .alignItems(VerticalAlign.Center)
    .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? `fx_${value}` : '' })
  }

  // 混合模式标签
  private blendModeLabel(mode: string): string {
    if (mode === 'normal') return '正常'
    if (mode === 'multiply') return '正片叠底'
    if (mode === 'screen') return '滤色'
    if (mode === 'overlay') return '叠加'
    if (mode === 'darken') return '变暗'
    if (mode === 'lighten') return '变亮'
    if (mode === 'color-dodge') return '颜色减淡'
    if (mode === 'color-burn') return '颜色加深'
    if (mode === 'hard-light') return '强光'
    if (mode === 'soft-light') return '柔光'
    if (mode === 'difference') return '差值'
    if (mode === 'exclusion') return '排除'
    if (mode === 'hue') return '色相'
    if (mode === 'saturation') return '饱和度'
    if (mode === 'color') return '颜色'
    if (mode === 'luminosity') return '明度'
    return '正常'
  }

  // 混合模式选项列表（16 种）
  private blendModeOptions: BlendModeOption[] = [
    { value: 'normal', label: '正常' },
    { value: 'multiply', label: '正片叠底' },
    { value: 'screen', label: '滤色' },
    { value: 'overlay', label: '叠加' },
    { value: 'darken', label: '变暗' },
    { value: 'lighten', label: '变亮' },
    { value: 'color-dodge', label: '颜色减淡' },
    { value: 'color-burn', label: '颜色加深' },
    { value: 'hard-light', label: '强光' },
    { value: 'soft-light', label: '柔光' },
    { value: 'difference', label: '差值' },
    { value: 'exclusion', label: '排除' },
    { value: 'hue', label: '色相' },
    { value: 'saturation', label: '饱和度' },
    { value: 'color', label: '颜色' },
    { value: 'luminosity', label: '明度' },
  ]

  // fx 可添加类型（原型：9 种图层样式）
  private fxAvailableTypes: FxItem[] = [
    { id: 'drop_shadow_opt', type: 'drop-shadow', enabled: true, label: '投影', icon: Icon.download, summary: '' },
    { id: 'inner_shadow_opt', type: 'inner-shadow', enabled: true, label: '内阴影', icon: Icon.shadow, summary: '' },
    { id: 'outer_glow_opt', type: 'outer-glow', enabled: true, label: '外发光', icon: Icon.circle, summary: '' },
    { id: 'inner_glow_opt', type: 'inner-glow', enabled: true, label: '内发光', icon: Icon.eye, summary: '' },
    { id: 'bevel_opt', type: 'bevel', enabled: true, label: '斜面与浮雕', icon: Icon.cube, summary: '' },
    { id: 'satin_opt', type: 'satin', enabled: true, label: '光泽', icon: Icon.droplet, summary: '' },
    { id: 'color_overlay_opt', type: 'color-overlay', enabled: true, label: '颜色叠加', icon: Icon.palette, summary: '' },
    { id: 'gradient_overlay_opt', type: 'gradient-overlay', enabled: true, label: '渐变叠加', icon: Icon.palette, summary: '' },
    { id: 'pattern_overlay_opt', type: 'pattern-overlay', enabled: true, label: '图案叠加', icon: Icon.grid, summary: '' },
  ]

  /** 添加 fx 图层样式 */
  private addFx(type: string): void {
    const opt = this.fxAvailableTypes.find(f => f.type === type)
    if (!opt) return
    // 根据类型生成默认摘要
    let summary = '0%'
    if (type === 'drop-shadow' || type === 'inner-shadow') {
      summary = '5px · #000000 40%'
    } else if (type === 'outer-glow' || type === 'inner-glow') {
      summary = '#3AC487 50%'
    } else if (type === 'color-overlay') {
      summary = '#3AC487 100%'
    } else if (type === 'bevel') {
      summary = 'inner · 50%'
    } else if (type === 'satin') {
      summary = '#000000 50%'
    } else if (type === 'gradient-overlay') {
      summary = '线性 100%'
    } else if (type === 'pattern-overlay') {
      summary = '默认 100%'
    }
    const newItem: FxItem = {
      id: `${type}_${Date.now()}`,
      type: type,
      enabled: true,
      label: opt.label,
      icon: opt.icon,
      summary: summary,
    }
    this.fxList = [...this.fxList, newItem]
    this.showFxMenu = false
  }

  /** 切换 fx 启用状态 */
  private toggleFx(id: string): void {
    this.fxList = this.fxList.map((fx: FxItem): FxItem => ({
      id: fx.id, type: fx.type, enabled: fx.id === id ? !fx.enabled : fx.enabled,
      label: fx.label, icon: fx.icon, summary: fx.summary,
    }))
  }

  /** 根据滑块上的 x 坐标更新不透明度（轨道宽度 90vp） */
  private updateOpacityFromX(localX: number): void {
    const trackWidth = 90
    const ratio = Math.max(0, Math.min(1, localX / trackWidth))
    const newOpacity = Math.round(ratio * 100)
    if (newOpacity !== this.opacityValue) {
      this.opacityValue = newOpacity
    }
  }

  /** 删除 fx */
  private removeFx(id: string): void {
    this.fxList = this.fxList.filter(fx => fx.id !== id)
  }

  @Builder
  layoutContent(): void {
    Column() {
      // ─── 对齐按钮组（6 个：左/中/右/顶/中/底，原型：flex-1 h-32 rounded-5 gap-4） ───
      Row() {
        this.alignButton('align_left', Icon.align_left)
        this.alignButton('align_center', Icon.align_center)
        this.alignButton('align_right', Icon.align_right)
        this.alignButton('align_top', Icon.align_top)
        this.alignButton('align_middle', Icon.align_middle)
        this.alignButton('align_bottom', Icon.align_bottom)
      }
      .width('100%')
      .margin({ bottom: 8 })

      // ─── 分布按钮组（原型：4 个：水平均匀/垂直均匀/水平间距/垂直间距） ───
      Row() {
        this.distributeButton('dist_h', Icon.distribute_h)
        this.distributeButton('dist_v', Icon.distribute_v)
        this.distributeButton('dist_h_gap', Icon.flip_h)
        this.distributeButton('dist_v_gap', Icon.flip_v)
      }
      .width('100%')
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  // 对齐按钮（原型：active bg-primary-light-100 text-primary-dark-700 shadow inset border）
  @Builder
  alignButton(id: string, icon: string): void {
    Column() {
      Text(icon)
        .fontSize(12)
        .fontColor(this.selectedAlign === id
          ? ColorToken.primary_dark_700
          : (this.hoveredAlignBtn === id ? ColorToken.body : ColorToken.secondary))
    }
    .layoutWeight(1)
    .height(32)
    .borderRadius(5)
    .backgroundColor(this.selectedAlign === id
      ? ColorToken.primary_light_100
      : (this.hoveredAlignBtn === id ? ColorToken.panel : Color.Transparent))
    .border({
      width: this.selectedAlign === id ? 1 : 0,
      color: this.selectedAlign === id ? ColorToken.primary_light_300 : Color.Transparent
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.selectedAlign = id })
    .onHover((isHover: boolean) => { this.hoveredAlignBtn = isHover ? id : '' })
  }

  // 分布按钮（同对齐按钮结构，hover 状态独立）
  @Builder
  distributeButton(id: string, icon: string): void {
    Column() {
      Text(icon)
        .fontSize(12)
        .fontColor(this.selectedDistribute === id
          ? ColorToken.primary_dark_700
          : (this.hoveredDistributeBtn === id ? ColorToken.body : ColorToken.secondary))
    }
    .layoutWeight(1)
    .height(32)
    .borderRadius(5)
    .backgroundColor(this.selectedDistribute === id
      ? ColorToken.primary_light_100
      : (this.hoveredDistributeBtn === id ? ColorToken.panel : Color.Transparent))
    .border({
      width: this.selectedDistribute === id ? 1 : 0,
      color: this.selectedDistribute === id ? ColorToken.primary_light_300 : Color.Transparent
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.selectedDistribute = id })
    .onHover((isHover: boolean) => { this.hoveredDistributeBtn = isHover ? id : '' })
  }

  @Builder
  typographyContent(): void {
    Column() {
      // ─── 内容（原型：input v-model + placeholder） ───
      Row() {
        Text('内容')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        TextInput({ text: this.textContent, placeholder: '输入文字...' })
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
          .onChange((val: string) => { this.textContent = val })
      }
      .width('100%')
      .height(32)
      .padding({ left: 8, right: 8 })
      .borderRadius(5)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: this.hoveredFrameRow === 'text_content' ? ColorToken.border : Color.Transparent })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })
      .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_content' : '' })

      // ─── 字体（原型：label w-28 uppercase + select 左对齐 + chevron-down） ───
      Row() {
        Text('字体')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        Text(this.textFontFamily)
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(Icon.chevron_down)
          .fontSize(10)
          .fontColor(ColorToken.muted)
          .margin({ left: 4 })
      }
      .width('100%')
      .height(32)
      .padding({ left: 8, right: 8 })
      .borderRadius(5)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: this.hoveredFrameRow === 'text_font' ? ColorToken.border : Color.Transparent })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })
      .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_font' : '' })

      // ─── 字号/行距/字距 3 列（原型：input v-model.number） ───
      Row() {
        // 字号
        Column() {
          Text('字号')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: `${this.textFontSize}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { this.textFontSize = Number(val) || 14 })
        }
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'text_size' ? ColorToken.border : Color.Transparent })
        .alignItems(HorizontalAlign.Start)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_size' : '' })

        // 行距
        Column() {
          Text('行距')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: `${this.textLineHeight}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { this.textLineHeight = Number(val) || 1.5 })
        }
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'text_lh' ? ColorToken.border : Color.Transparent })
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 6 })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_lh' : '' })

        // 字距
        Column() {
          Text('字距')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: `${this.textLetterSpacing}` })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { this.textLetterSpacing = Number(val) || 0 })
        }
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'text_ls' ? ColorToken.border : Color.Transparent })
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 6 })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_ls' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ bottom: 8 })

      // ─── 字重按钮组（原型：6 个：细/常规/中/半粗/粗/特粗，值 300/400/500/600/700/800，gap-6，首个无左间距） ───
      Row() {
        Text('字重')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        this.fontWeightButton('300', '细', true)
        this.fontWeightButton('400', '常规', false)
        this.fontWeightButton('500', '中', false)
        this.fontWeightButton('600', '半粗', false)
        this.fontWeightButton('700', '粗', false)
        this.fontWeightButton('800', '特粗', false)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 样式按钮（B/I/U + 左/中/右/两端对齐，原型：7 个 w-28 h-28 gap-2） ───
      Row() {
        this.typeStyleButton('bold', 'B', true, FontWeightConstant.bold)
        this.typeStyleButton('italic', 'I', true, FontWeightConstant.regular)
        this.typeStyleButton('underline', 'U', true, FontWeightConstant.regular)
        this.typeStyleButton('align_left', Icon.align_left, false, FontWeightConstant.regular)
        this.typeStyleButton('align_center', Icon.align_center, false, FontWeightConstant.regular)
        this.typeStyleButton('align_right', Icon.align_right, false, FontWeightConstant.regular)
        this.typeStyleButton('align_justify', Icon.list, false, FontWeightConstant.regular)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // ─── 文字色（原型：label + color preview + hex input v-model + 点击打开 ColorPickerPopover） ───
      Row() {
        Text('文字色')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
        Blank()
        Row() {
          Column()
            .width(20)
            .height(20)
            .borderRadius(4)
            .backgroundColor(this.textColor)
            .border({ width: 1, color: ColorToken.border_light })
            .onClick(() => { this.openColorPicker('text') })
          TextInput({ text: this.textColor })
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .width(88)
            .height(28)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: Color.Transparent })
            .textAlign(TextAlign.Start)
            .margin({ left: 6 })
            .onChange((val: string) => { this.textColor = val })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  // 字重按钮（原型：active bg-primary text-white, inactive bg-panel text-secondary hover:bg-border-light, gap-6）
  @Builder
  fontWeightButton(weight: string, label: string, isFirst: boolean): void {
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeightConstant.medium)
      .fontColor(this.textFontWeight === weight ? ColorToken.white : ColorToken.secondary)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .height(24)
      .borderRadius(4)
      .backgroundColor(this.textFontWeight === weight
        ? ColorToken.primary
        : (this.hoveredFontWeight === weight ? ColorToken.border_light : ColorToken.panel))
      .margin({ left: isFirst ? 0 : 6 })
      .textAlign(TextAlign.Center)
      .onClick(() => { this.textFontWeight = weight })
      .onHover((isHover: boolean) => { this.hoveredFontWeight = isHover ? weight : '' })
  }

  // 样式按钮（B/I/U + 对齐，原型：active bg-primary text-white，B 加粗/I 斜体）
  @Builder
  typeStyleButton(id: string, label: string, isText: boolean, weight: number): void {
    Column() {
      Text(label)
        .fontSize(12)
        .fontWeight(weight)
        .fontColor(this.activeTypeStyle === id ? ColorToken.white : ColorToken.secondary)
    }
    .width(28)
    .height(28)
    .borderRadius(4)
    .backgroundColor(this.activeTypeStyle === id ? ColorToken.primary : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 2 })
    .onClick(() => { this.activeTypeStyle = id })
  }

  @Builder
  pathfinderContent(): void {
    Column() {
      // 4 个路径查找器操作按钮（原型：flex-1 h-32 rounded-5 hover:bg-border-light border border-border text-11 secondary）
      Row() {
        this.pathfinderOp('union', '合集', true)
        this.pathfinderOp('subtract', '差集', false)
        this.pathfinderOp('intersect', '交集', false)
        this.pathfinderOp('exclude', '排除', false)
      }
      .width('100%')
      .margin({ top: 4, bottom: 8 })
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  @Builder
  pathfinderOp(op: string, label: string, isFirst: boolean): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(this.hoveredPathfinder === op ? ColorToken.body : ColorToken.secondary)
    }
    .layoutWeight(1)
    .height(32)
    .borderRadius(5)
    .backgroundColor(this.hoveredPathfinder === op ? ColorToken.border_light : Color.Transparent)
    .border({ width: 1, color: ColorToken.border })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: isFirst ? 0 : 8 })
    .onHover((isHover: boolean) => { this.hoveredPathfinder = isHover ? op : '' })
  }

  // ─── EXPORT TAB ───
  @Builder
  exportTabContent(): void {
    Scroll() {
      Column() {
        // Header（原型：px-12 py-8 border-b flex justify-between）
        Row() {
          Text('导出设置')
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
          Blank()
          Text('1 个图层')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
        .alignItems(VerticalAlign.Center)

        // 格式选择条（原型：px-12 py-8 border-b）
        Column() {
          Text('格式')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .margin({ bottom: 4 })
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.exportFormats, (fmt: ExportFormatOption) => {
              Text(fmt.name)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.exportFormat === fmt.id ? ColorToken.primary_dark_700 : ColorToken.secondary)
                .height(28)
                .padding({ left: 8, right: 8 })
                .borderRadius(4)
                .backgroundColor(this.exportFormat === fmt.id ? ColorToken.hover_bg : Color.Transparent)
                .border({
                  width: 1,
                  color: this.exportFormat === fmt.id ? ColorToken.primary : ColorToken.border
                })
                .margin({ right: 4, bottom: 4 })
                .onClick(() => { this.exportFormat = fmt.id })
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

        // ─── 1. 基本分区（可折叠） ───
        this.exportSection('basic', '基本', this.secExportBasic, (v: boolean) => { this.secExportBasic = v })

        // ─── 2. 尺寸分区（可折叠） ───
        this.exportSection('size', '尺寸', this.secExportSize, (v: boolean) => { this.secExportSize = v })

        // ─── 3. 格式选项分区（可折叠，标题随选中格式变化） ───
        this.exportSection('formatOpt', this.formatOptionLabel(), this.secExportFormatOpt, (v: boolean) => { this.secExportFormatOpt = v })

        // ─── 4. 色彩与元数据分区（可折叠） ───
        this.exportSection('color', '色彩与元数据', this.secExportColor, (v: boolean) => { this.secExportColor = v })

        // ─── 5. 预设方案分区（可折叠） ───
        this.exportSection('presets', '预设方案', this.secExportPresets, (v: boolean) => { this.secExportPresets = v })

        // ─── Footer：预估大小 + 导出按钮 ───
        Column() {
          // 预估大小行
          Row() {
            Text('预估大小')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
            Blank()
            Text(this.estimatedSize())
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
          }
          .width('100%')
          .height(24)
          .padding({ left: 8, right: 8 })
          .borderRadius(4)
          .backgroundColor(ColorToken.panel)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 6 })

          // 导出按钮组
          Row() {
            // 导出当前
            Row() {
              Text(Icon.download)
                .fontSize(10)
                .fontColor(ColorToken.white)
                .margin({ right: 6 })
              Text('导出当前')
                .fontSize(10)
                .fontWeight(FontWeightConstant.bold)
                .fontColor(ColorToken.white)
            }
            .layoutWeight(1)
            .height(32)
            .borderRadius(6)
            .backgroundColor(ColorToken.primary_dark_700)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 批量导出按钮
            Column() {
              Text(Icon.layers)
                .fontSize(10)
                .fontColor(ColorToken.secondary)
            }
            .width(30)
            .height(32)
            .borderRadius(6)
            .border({ width: 1, color: ColorToken.border })
            .backgroundColor(ColorToken.white)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 8 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 导出可折叠分区头 */
  @Builder
  exportSection(id: string, title: string, expanded: boolean, toggle: (v: boolean) => void): void {
    Column() {
      Row() {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
        Blank()
        Text(expanded ? Icon.chevron_down : Icon.chevron_up)
          .fontSize(8)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.hoveredExportSection === id ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { toggle(!expanded) })
      .onHover((isHover: boolean) => { this.hoveredExportSection = isHover ? id : '' })

      if (!expanded) {
        if (id === 'basic') {
          this.exportBasicContent()
        } else if (id === 'size') {
          this.exportSizeContent()
        } else if (id === 'formatOpt') {
          this.exportFormatOptContent()
        } else if (id === 'color') {
          this.exportColorContent()
        } else if (id === 'presets') {
          this.exportPresetsContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  /** 基本：品质 + 缩放滑块 */
  @Builder
  exportBasicContent(): void {
    Column() {
      // 品质
      Column() {
        Row() {
          Text('品质')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
          Blank()
          Text(`${this.exportQuality}%`)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 2 })

        // slider
        Row() {
          Row()
            .width(`${this.exportQuality}%`)
            .height('100%')
            .backgroundColor(ColorToken.primary)
            .borderRadius(2)
        }
        .width('100%')
        .height(4)
        .backgroundColor(ColorToken.border)
        .borderRadius(2)
        .gesture(
          PanGesture()
            .onActionUpdate((e: GestureEvent) => {
              // 估算：Inspector 宽度约 260，slider 宽 100%
              const w = 236
              const pct = Math.max(1, Math.min(100, Math.round((e.offsetX / w) * 100)))
              this.exportQuality = pct
            })
        )

        Row() {
          Text('低')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('中')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('高')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('最佳')
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 1 })
      }
      .width('100%')
      .margin({ bottom: 6 })

      // 缩放
      Column() {
        Row() {
          Text('缩放')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
          Blank()
          Text(`${this.exportScale}%`)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 2 })

        Row() {
          Row()
            .width(`${this.exportScale / 4}%`)
            .height('100%')
            .backgroundColor(ColorToken.primary)
            .borderRadius(2)
        }
        .width('100%')
        .height(4)
        .backgroundColor(ColorToken.border)
        .borderRadius(2)
        .gesture(
          PanGesture()
            .onActionUpdate((e: GestureEvent) => {
              const w = 236
              const pct = Math.max(10, Math.min(400, Math.round((e.offsetX / w) * 400)))
              this.exportScale = pct
            })
        )

        Row() {
          Text('10%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('100%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
          Blank()
          Text('400%')
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 2, right: 2 })
        .alignItems(VerticalAlign.Center)
        .margin({ top: 1 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  /** 尺寸：宽高 + 约束/透明开关 */
  @Builder
  exportSizeContent(): void {
    Column() {
      // 宽度/高度
      Row() {
        // 宽度
        Row() {
          Text('宽度')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('420 px')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .layoutWeight(1)
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)

        // 高度
        Row() {
          Text('高度')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('600 px')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .layoutWeight(1)
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 4 })

      // 约束比例 + 透明开关
      Row() {
        // 约束比例
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.exportConstrain ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.exportConstrain ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.exportConstrain = !this.exportConstrain })

          Text('约束比例')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        // 透明
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.exportTransparent ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.exportTransparent ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.exportTransparent = !this.exportTransparent })

          Text('透明')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  /** 格式选项（根据 exportFormat 动态显示） */
  @Builder
  exportFormatOptContent(): void {
    Column() {
      // PNG 格式
      if (this.exportFormat === 'png') {
        Row() {
          // PNG-24
          Row() {
            Text('PNG-24')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.pngMode === 'PNG-24' ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({
            width: 1,
            color: this.pngMode === 'PNG-24' ? ColorToken.primary : ColorToken.border
          })
          .backgroundColor(this.pngMode === 'PNG-24' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.pngMode = 'PNG-24' })

          // PNG-8
          Row() {
            Text('PNG-8')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.pngMode === 'PNG-8' ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({
            width: 1,
            color: this.pngMode === 'PNG-8' ? ColorToken.primary : ColorToken.border
          })
          .backgroundColor(this.pngMode === 'PNG-8' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 4 })
          .onClick(() => { this.pngMode = 'PNG-8' })
        }
        .width('100%')
        .margin({ bottom: 4 })

        // 交错开关
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .position({ x: this.pngInterlace ? 9 : 1, y: 2 })
          }
          .width(16)
          .height(10)
          .borderRadius(5)
          .backgroundColor(this.pngInterlace ? ColorToken.primary : ColorToken.border)
          .onClick(() => { this.pngInterlace = !this.pngInterlace })
          Text('交错')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
      }

      // JPEG / WebP
      if (this.exportFormat === 'jpg' || this.exportFormat === 'webp') {
        Row() {
          // 渐进式
          Row() {
            Text('渐进式')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.jpegProgressive ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({
            width: 1,
            color: this.jpegProgressive ? ColorToken.primary : ColorToken.border
          })
          .backgroundColor(this.jpegProgressive ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => { this.jpegProgressive = !this.jpegProgressive })

          // 优化
          Row() {
            Text('优化')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.jpegOptimize ? ColorToken.primary_dark_700 : ColorToken.muted)
          }
          .layoutWeight(1)
          .height(24)
          .borderRadius(3)
          .border({
            width: 1,
            color: this.jpegOptimize ? ColorToken.primary : ColorToken.border
          })
          .backgroundColor(this.jpegOptimize ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 4 })
          .onClick(() => { this.jpegOptimize = !this.jpegOptimize })
        }
        .width('100%')
        .margin({ bottom: 4 })

        Row() {
          Text('子采样')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Blank()
          Text('4:4:4')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
        }
        .width('100%')
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.panel)
        .alignItems(VerticalAlign.Center)
      }

      // SVG
      if (this.exportFormat === 'svg') {
        Column() {
          // 内联样式
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgInline ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgInline ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgInline = !this.svgInline })
            Text('内联样式')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          // 压缩精简
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgMinify ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgMinify ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgMinify = !this.svgMinify })
            Text('压缩精简')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          // 响应式 viewBox
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.svgResponsive ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.svgResponsive ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.svgResponsive = !this.svgResponsive })
            Text('响应式 viewBox')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      // PDF
      if (this.exportFormat === 'pdf') {
        Column() {
          // PDF 标准
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.pdfStandards, (std: string) => {
              Text(std)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.pdfStandard === std ? ColorToken.primary_dark_700 : ColorToken.muted)
                .height(24)
                .padding({ left: 6, right: 6 })
                .borderRadius(3)
                .border({
                  width: 1,
                  color: this.pdfStandard === std ? ColorToken.primary : ColorToken.border
                })
                .backgroundColor(this.pdfStandard === std ? ColorToken.hover_bg : Color.Transparent)
                .margin({ right: 4, bottom: 4 })
                .onClick(() => { this.pdfStandard = std })
            })
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 压缩 + 嵌入字体
          Row() {
            Row() {
              Text('压缩')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('JPEG 最大')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('嵌入字体')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('全部')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 4 })

          // 裁切/出血/色标开关
          Row() {
            // 裁切
            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfCropMarks ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfCropMarks ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfCropMarks = !this.pdfCropMarks })
              Text('裁切')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            // 出血
            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfBleedMarks ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfBleedMarks ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfBleedMarks = !this.pdfBleedMarks })
              Text('出血')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)

            Blank()

            // 色标
            Row() {
              Row() {
                Column()
                  .width(4)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.pdfColorBars ? 7 : 1, y: 2 })
              }
              .width(12)
              .height(8)
              .borderRadius(3)
              .backgroundColor(this.pdfColorBars ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.pdfColorBars = !this.pdfColorBars })
              Text('色标')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      // EPS / CDR
      if (this.exportFormat === 'eps' || this.exportFormat === 'cdr') {
        Column() {
          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.embedFonts ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.embedFonts ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.embedFonts = !this.embedFonts })
            Text('嵌入字体')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 3 })

          Row() {
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: this.embedImages ? 9 : 1, y: 2 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.embedImages ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.embedImages = !this.embedImages })
            Text('嵌入图片')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }

      // HDS
      if (this.exportFormat === 'hds') {
        Column() {
          // 模式选择 3 按钮
          Row() {
            ForEach(['标准', '精简', '兼容'], (m: string) => {
              Text(m)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.hdsMode === m ? ColorToken.primary_dark_700 : ColorToken.muted)
            })
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 版本 + 压缩
          Row() {
            Row() {
              Text('版本')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('v3.0')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)

            Row() {
              Text('压缩')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.muted)
              Blank()
              Text('无损')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
            }
            .layoutWeight(1)
            .height(24)
            .padding({ left: 6, right: 6 })
            .borderRadius(4)
            .backgroundColor(ColorToken.panel)
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 4 })

          // 嵌入字体 + 嵌入图片
          Row() {
            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.hdsEmbedFonts ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.hdsEmbedFonts ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.hdsEmbedFonts = !this.hdsEmbedFonts })
              Text('嵌入字体')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ right: 8 })

            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.hdsEmbedImages ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.hdsEmbedImages ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.hdsEmbedImages = !this.hdsEmbedImages })
              Text('嵌入图片')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  /** 色彩与元数据 */
  @Builder
  exportColorContent(): void {
    Column() {
      // 色彩空间选择
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.exportColorSpaces, (cs: string) => {
          Text(cs)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.exportColorSpace === cs ? ColorToken.primary_dark_700 : ColorToken.muted)
            .height(24)
            .padding({ left: 8, right: 8 })
            .borderRadius(3)
            .border({
              width: 1,
              color: this.exportColorSpace === cs ? ColorToken.primary : ColorToken.border
            })
            .backgroundColor(this.exportColorSpace === cs ? ColorToken.hover_bg : Color.Transparent)
            .margin({ right: 4, bottom: 4 })
            .onClick(() => { this.exportColorSpace = cs })
        })
      }
      .width('100%')
      .margin({ bottom: 4 })

      // 嵌入 ICC 配置文件开关
      Row() {
        Row() {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(ColorToken.white)
            .position({ x: this.exportEmbedICC ? 9 : 1, y: 2 })
        }
        .width(16)
        .height(10)
        .borderRadius(5)
        .backgroundColor(this.exportEmbedICC ? ColorToken.primary : ColorToken.border)
        .onClick(() => { this.exportEmbedICC = !this.exportEmbedICC })
        Text('嵌入 ICC 配置文件')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  /** 预设方案 */
  @Builder
  exportPresetsContent(): void {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.exportPresets, (preset: string) => {
        Row() {
          if (this.exportPreset === preset) {
            Text('✓')
              .fontSize(10)
              .fontColor(ColorToken.primary_dark_700)
              .margin({ right: 3 })
          }
          Text(preset)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.exportPreset === preset ? ColorToken.primary_dark_700 : ColorToken.muted)
        }
        .height(24)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .border({
          width: 1,
          color: this.exportPreset === preset ? ColorToken.primary : ColorToken.border
        })
        .backgroundColor(this.exportPreset === preset ? ColorToken.hover_bg : Color.Transparent)
        .margin({ right: 4, bottom: 4 })
        .onClick(() => { this.exportPreset = preset })
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 10 })
  }

  /** 格式选项标签 */
  private formatOptionLabel(): string {
    if (this.exportFormat === 'png') return 'PNG 选项'
    if (this.exportFormat === 'jpg') return 'JPEG 选项'
    if (this.exportFormat === 'webp') return 'WebP 选项'
    if (this.exportFormat === 'svg') return 'SVG 选项'
    if (this.exportFormat === 'pdf') return 'PDF 选项'
    if (this.exportFormat === 'eps') return 'EPS 选项'
    if (this.exportFormat === 'cdr') return 'CDR 选项'
    if (this.exportFormat === 'hds') return 'HDS 选项'
    return '格式选项'
  }

  /** 预估大小计算 */
  private estimatedSize(): string {
    const base = 420 * 600 * 3
    const qualityFactor = this.exportQuality / 100
    const sizeKb = Math.round(base * qualityFactor * 0.1 * Math.pow(this.exportScale / 100, 2) / 1024)
    if (sizeKb < 1024) return `${Math.max(4, sizeKb)} KB`
    return `${(sizeKb / 1024).toFixed(1)} MB`
  }

  // 导出格式列表
  private exportFormats: ExportFormatOption[] = [
    { id: 'png', name: 'PNG' },
    { id: 'jpg', name: 'JPEG' },
    { id: 'webp', name: 'WebP' },
    { id: 'svg', name: 'SVG' },
    { id: 'pdf', name: 'PDF' },
    { id: 'eps', name: 'EPS' },
    { id: 'cdr', name: 'CDR' },
    { id: 'hds', name: 'HDS' },
  ]

  private exportColorSpaces: string[] = ['sRGB', 'Adobe RGB', 'Display P3', 'CMYK']

  private pdfStandards: string[] = ['PDF/X-1a', 'PDF/X-3', 'PDF/X-4', 'PDF/A-1b', 'PDF/A-2b', 'PDF 2.0']

  private exportPresets: string[] = [
    'PNG-24 透明', 'PNG-8 256色', 'JPEG 最大质量', 'JPEG 网页中等',
    'WebP 无损', 'WebP 有损 80%', 'SVG 压缩', 'PDF 打印高质',
    'PDF 网页最小', 'EPS 印刷', 'CDR 兼容', 'HDS 标准归档',
  ]

  // ─── SETTINGS TAB ───
  @Builder
  settingsTabContent(): void {
    Scroll() {
      Column() {
        // MCP 协议
        this.settingsSection('mcp', 'MCP 协议', Icon.tower_broadcast, this.mcpExpanded, (v: boolean) => { this.mcpExpanded = v })
        // 模型信息配置
        this.settingsSection('model', '模型信息配置', Icon.microchip, this.modelExpanded, (v: boolean) => { this.modelExpanded = v })
        // 智能体技能
        this.settingsSection('skill', '智能体技能', Icon.robot, this.skillExpanded, (v: boolean) => { this.skillExpanded = v })
        // 系统信息
        this.settingsSection('sysInfo', '系统信息', Icon.info_circle, this.sysInfoExpanded, (v: boolean) => { this.sysInfoExpanded = v })

        // Footer
        Row() {
          Text(Icon.refresh)
            .fontSize(10)
            .fontColor(ColorToken.white)
            .margin({ right: 8 })
          Text('检查更新')
            .fontSize(10)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.white)
        }
        .width('100%')
        .height(32)
        .borderRadius(6)
        .backgroundColor(ColorToken.primary_dark_700)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 12, right: 12, top: 10, bottom: 10 })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 设置可折叠分区头 */
  @Builder
  settingsSection(id: string, title: string, icon: string, expanded: boolean, toggle: (v: boolean) => void): void {
    Column() {
      Row() {
        Row() {
          Text(icon)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
          Text(title)
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        if (id === 'skill') {
          Text('4 个')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .margin({ right: 8 })
        }
        Text(expanded ? Icon.chevron_down : Icon.chevron_up)
          .fontSize(8)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.hoveredSettingsRow === id ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { toggle(!expanded) })
      .onHover((isHover: boolean) => { this.hoveredSettingsRow = isHover ? id : '' })

      if (!expanded) {
        if (id === 'mcp') {
          this.mcpContent()
        } else if (id === 'model') {
          this.modelContent()
        } else if (id === 'skill') {
          this.skillContent()
        } else if (id === 'sysInfo') {
          this.sysInfoContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  /** MCP 协议内容 */
  @Builder
  mcpContent(): void {
    Column() {
      // 服务状态
      Row() {
        Row() {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(ColorToken.primary)
          Text('服务运行中')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        Text('PID 2847')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .borderRadius(4)
      .backgroundColor(ColorToken.panel)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // 端点信息
      Column() {
        this.mcpInfoRow('端点地址', 'localhost:11435')
        this.mcpInfoRow('协议版本', '2025-03-26')
        this.mcpInfoRow('RPC 通道', 'Streamable HTTP · SSE')
        this.mcpInfoRow('会话数', '3 个活跃会话')
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 暴露的工具
      Text('暴露的工具 (Tools)')
        .fontSize(10)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })

      Column() {
        ForEach(this.mcpTools, (tool: McpTool) => {
          Row() {
            Row() {
              Text(tool.icon)
                .fontSize(8)
                .fontColor(ColorToken.secondary)
              Text(tool.name)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .margin({ left: 8 })
            }
            .alignItems(VerticalAlign.Center)
            .layoutWeight(1)

            Text(`${tool.calls} 次`)
              .fontSize(10)
              .fontColor(ColorToken.muted)
              .margin({ right: 4 })

            // 开关
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: tool.enabled ? 11 : 1, y: 2 })
            }
            .width(18)
            .height(10)
            .borderRadius(5)
            .backgroundColor(tool.enabled ? ColorToken.primary : ColorToken.border)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 暴露的资源
      Text('暴露的资源 (Resources)')
        .fontSize(10)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })

      Column() {
        ForEach(this.mcpResources, (res: string) => {
          Row() {
            Text(Icon.file)
              .fontSize(8)
              .fontColor(ColorToken.secondary)
            Text(res)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')

      // 重启 / 复制按钮
      Row() {
        Row() {
          Text(Icon.refresh)
            .fontSize(8)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('重启服务')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Row() {
          Text(Icon.copy)
            .fontSize(8)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('复制端点')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .padding({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  /** MCP 信息行 */
  @Builder
  mcpInfoRow(label: string, value: string): void {
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
    .width('100%')
    .height(24)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(ColorToken.panel)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 4 })
  }

  /** 模型配置内容 */
  @Builder
  modelContent(): void {
    Column() {
      // 协议
      Column() {
        Text('协议')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.modelProtocols, (proto: string) => {
            Text(proto)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.modelProtocol === proto ? ColorToken.primary_dark_700 : ColorToken.muted)
              .height(24)
              .padding({ left: 8, right: 8 })
              .borderRadius(3)
              .border({
                width: 1,
                color: this.modelProtocol === proto ? ColorToken.primary : ColorToken.border
              })
              .backgroundColor(this.modelProtocol === proto ? ColorToken.hover_bg : Color.Transparent)
              .margin({ right: 4, bottom: 4 })
              .onClick(() => { this.modelProtocol = proto })
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 6 })

      // 提供商
      Column() {
        Text('提供商')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.modelProviders, (prov: string) => {
            Text(prov)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.modelProvider === prov ? ColorToken.primary_dark_700 : ColorToken.muted)
              .height(24)
              .padding({ left: 8, right: 8 })
              .borderRadius(3)
              .border({
                width: 1,
                color: this.modelProvider === prov ? ColorToken.primary : ColorToken.border
              })
              .backgroundColor(this.modelProvider === prov ? ColorToken.hover_bg : Color.Transparent)
              .margin({ right: 4, bottom: 4 })
              .onClick(() => { this.modelProvider = prov })
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 6 })

      // API 端点 URL
      Column() {
        Text('API 端点 URL')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.link)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelUrl, placeholder: 'https://api.openai.com/v1' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
          Text(Icon.paste)
            .fontSize(8)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      // API 令牌
      Column() {
        Text('API 令牌')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.key)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelToken, placeholder: 'sk-xxxxxxxxxxxxxxxx' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .type(this.modelTokenVisible ? InputType.Normal : InputType.Password)
          Text(this.modelTokenVisible ? Icon.eye : Icon.eye_off)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
            .onClick(() => { this.modelTokenVisible = !this.modelTokenVisible })
          Text(Icon.paste)
            .fontSize(8)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      // 模型 ID
      Column() {
        Text('模型 ID')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.tag)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelId, placeholder: 'deepseek-v4-flash' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      // 高级选项
      Row() {
        Text(this.modelAdvanced ? Icon.chevron_down : Icon.chevron_right)
          .fontSize(10)
          .fontColor(ColorToken.muted)
        Text('高级选项')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 6 })
      .onClick(() => { this.modelAdvanced = !this.modelAdvanced })

      // 高级选项内容
      if (this.modelAdvanced) {
        Column() {
          // 4 个数字输入
          Row() {
            this.modelNumberInput('最大 Token', this.modelMaxTokens, (v: number) => { this.modelMaxTokens = v })
            this.modelNumberInput('温度 (0-2)', this.modelTemperature, (v: number) => { this.modelTemperature = v })
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            this.modelNumberInput('超时 (秒)', this.modelTimeout, (v: number) => { this.modelTimeout = v })
            this.modelNumberInput('重试次数', this.modelRetries, (v: number) => { this.modelRetries = v })
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 流式输出 + 推理模式开关
          Row() {
            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.modelStream ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.modelStream ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.modelStream = !this.modelStream })
              Text('流式输出')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ right: 8 })

            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.modelThinking ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.modelThinking ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.modelThinking = !this.modelThinking })
              Text('推理模式')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 8 })
        .border({ width: { left: 1 }, color: { left: ColorToken.border_light } })
        .margin({ bottom: 6 })
      }

      // 测试连接 + 保存配置
      Row() {
        Row() {
          Text(Icon.plug)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('测试连接')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Row() {
          Text(Icon.save)
            .fontSize(10)
            .fontColor(ColorToken.primary_dark_700)
            .margin({ right: 4 })
          Text('保存配置')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.primary_dark_700)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.primary })
        .backgroundColor(ColorToken.hover_bg)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .padding({ top: 6 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  /** 模型数字输入框 */
  @Builder
  modelNumberInput(label: string, value: number, onChange: (v: number) => void): void {
    Column() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })
      TextInput({ text: `${value}` })
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
        .height(24)
        .padding({ left: 4, right: 4 })
        .borderRadius(3)
        .border({ width: 1, color: ColorToken.border })
        .backgroundColor(ColorToken.white)
        .type(InputType.Number)
        .onChange((val: string) => { onChange(Number(val) || 0) })
    }
    .layoutWeight(1)
    .margin({ right: 4 })
  }

  /** 智能体技能内容 */
  @Builder
  skillContent(): void {
    Column() {
      // 搜索框
      Row() {
        Text(Icon.search)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 6 })
        TextInput({ placeholder: '搜索可用技能...' })
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .borderRadius(4)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: ColorToken.border })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // 技能列表
      ForEach(this.agentSkills, (skill: AgentSkill) => {
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(skill.connected ? ColorToken.primary : ColorToken.muted)
            Text(skill.icon)
              .fontSize(10)
              .fontColor(ColorToken.secondary)
              .margin({ left: 8 })
            Column() {
              Text(skill.label)
                .fontSize(10)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
              Text(skill.desc)
                .fontSize(10)
                .fontColor(ColorToken.muted)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)

          Text(skill.agent)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .borderRadius(4)
        .alignItems(VerticalAlign.Center)
        .opacity(skill.connected ? 1 : 0.6)
      })

      // 注册新智能体
      Row() {
        Text(Icon.plus)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 8 })
        Text('注册新智能体...')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8, bottom: 8 })
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  /** 系统信息内容 */
  @Builder
  sysInfoContent(): void {
    Column() {
      Row() {
        this.sysInfoCell('版本', '3.0.0')
        this.sysInfoCell('构建', '2026.07.19')
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        this.sysInfoCell('模型', 'deepseek-v4')
        this.sysInfoCell('引擎', 'OpenClaw v2.3')
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        this.sysInfoCell('网关', '百炼 + 中转')
        this.sysInfoCell('凭证', '已绑定')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  /** 系统信息单元 */
  @Builder
  sysInfoCell(label: string, value: string): void {
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
    .height(24)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(ColorToken.panel)
    .alignItems(VerticalAlign.Center)
    .margin({ right: 4 })
  }

  // MCP 工具数据
  private mcpTools: McpTool[] = [
    { name: 'canvas.read', icon: '👁', calls: 47, enabled: true },
    { name: 'canvas.write', icon: '✎', calls: 23, enabled: true },
    { name: 'layer.list', icon: '▤', calls: 12, enabled: true },
    { name: 'layer.modify', icon: '✒', calls: 18, enabled: true },
    { name: 'page.manage', icon: '📄', calls: 0, enabled: false },
    { name: 'export.render', icon: '⤓', calls: 6, enabled: true },
    { name: 'doc.info', icon: 'ℹ', calls: 34, enabled: true },
    { name: 'style.apply', icon: '◐', calls: 0, enabled: false },
  ]

  private mcpResources: string[] = [
    'harmony://canvas/current',
    'harmony://layers',
    'harmony://pages',
    'harmony://pages/{id}',
    'harmony://assets',
    'harmony://styles',
  ]

  private modelProtocols: string[] = ['OpenAI', 'Anthropic', 'Google', '本地', '自定义']

  private modelProviders: string[] = ['OpenAI', 'Azure', 'DeepSeek', '通义千问', '百度文心', '智谱GLM', '讯飞星火', 'Moonshot', '本地', '其他']

  private agentSkills: AgentSkill[] = [
    { label: 'AI 图像生成', desc: '文生图/图生图/智能扩图', icon: '✦', agent: '创作引擎', connected: true },
    { label: '智能配色', desc: '色彩提取/配色方案/色盲优化', icon: '◐', agent: '创作引擎', connected: true },
    { label: '版式智能', desc: '自动排版/网格生成/布局建议', icon: '▦', agent: '创作引擎', connected: true },
    { label: '字体助手', desc: '字体匹配/字距优化/字体推荐', icon: 'T', agent: '创作引擎', connected: true },
    { label: '文案生成', desc: '广告文案/标题生成/多语言翻译', icon: '✎', agent: '创作引擎', connected: true },
    { label: '矢量创作', desc: '路径简化/形状生成/图标创作', icon: '✒', agent: '创作引擎', connected: true },
    { label: '样机生成', desc: '3D 样机/场景合成/贴图映射', icon: '◆', agent: '渲染引擎', connected: true },
    { label: '滤镜引擎', desc: '风格迁移/图像增强/特效滤镜', icon: '✦', agent: '渲染引擎', connected: false },
  ]

  // ─── AI TAB ───
  @Builder
  aiTabContent(): void {
    Column() {
      // ─── Header bar: model + BYOK ───
      Row() {
        Row() {
          Text(Icon.microchip)
            .fontSize(9)
            .fontColor(ColorToken.secondary)
            .margin({ right: 6 })
          Text(this.byokConfigured ? this.byokModelId : '演示模式')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 140 })
          if (!this.byokConfigured) {
            Text('未配置')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor('#C97912')
              .backgroundColor('#FFF8E8')
              .border({ width: 1, color: '#F4D48A' })
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(3)
              .margin({ left: 6 })
          }
        }
        .alignItems(VerticalAlign.Center)

        Blank()
        Row() {
          // BYOK 配置按钮
          Column() {
            Text(Icon.gear)
              .fontSize(10)
              .fontColor(this.hoveredAiHeaderBtn === 'byok' ? ColorToken.body : ColorToken.tertiary)
              .textAlign(TextAlign.Center)
          }
          .width(20)
          .height(20)
          .borderRadius(4)
          .backgroundColor(this.hoveredAiHeaderBtn === 'byok' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAiHeaderBtn = isHover ? 'byok' : '' })
          .onClick(() => { this.showByokModal = true })

          // 清空对话按钮
          Column() {
            Text(Icon.refresh)
              .fontSize(9)
              .fontColor(this.hoveredAiHeaderBtn === 'clear' ? ColorToken.body : ColorToken.tertiary)
              .textAlign(TextAlign.Center)
          }
          .width(20)
          .height(20)
          .borderRadius(4)
          .backgroundColor(this.hoveredAiHeaderBtn === 'clear' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 6 })
          .onHover((isHover: boolean) => { this.hoveredAiHeaderBtn = isHover ? 'clear' : '' })
          .onClick(() => { this.clearAiConversation() })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(32)
      .padding({ left: 10, right: 10 })
      .backgroundColor(ColorToken.panel)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .alignItems(VerticalAlign.Center)

      // ─── 对话区（可滚动） ───
      Scroll() {
        Column() {
          ForEach(this.aiMessages, (msg: AiMessage, idx: number) => {
            if (msg.role === 'assistant') {
              // AI 消息
              Row() {
                Column() {
                  Text(Icon.robot)
                    .fontSize(10)
                    .fontColor(ColorToken.white)
                }
                .width(24)
                .height(24)
                .backgroundColor(ColorToken.primary)
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ top: 2 })

                Column() {
                  Text(msg.content)
                    .fontSize(11)
                    .fontWeight(FontWeightConstant.regular)
                    .fontColor(ColorToken.body)
                    .maxLines(20)
                }
                .constraintSize({ maxWidth: '80%' })
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor(ColorToken.panel)
                .border({ width: 1, color: ColorToken.border })
                .borderRadius({ topLeft: 2, topRight: 8, bottomLeft: 8, bottomRight: 8 })
                .margin({ left: 8 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            } else if (msg.role === 'user') {
              // 用户消息
              Row() {
                Column() {
                  Text(msg.content)
                    .fontSize(11)
                    .fontWeight(FontWeightConstant.medium)
                    .fontColor(ColorToken.body)
                    .maxLines(20)
                }
                .constraintSize({ maxWidth: '80%' })
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor(ColorToken.hover_bg)
                .border({ width: 1, color: '#B8EAD4' })
                .borderRadius({ topLeft: 8, topRight: 2, bottomLeft: 8, bottomRight: 8 })

                Column() {
                  Text('U')
                    .fontSize(8)
                    .fontWeight(FontWeightConstant.bold)
                    .fontColor(ColorToken.white)
                }
                .width(24)
                .height(24)
                .backgroundColor(ColorToken.title)
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ top: 2, left: 8 })
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
              .alignItems(VerticalAlign.Top)
            } else if (msg.role === 'tool') {
              // 工具调用消息（折叠展示）
              Row() {
                Column() {
                  Row() {
                    Text(Icon.wand)
                      .fontSize(7)
                      .fontColor(ColorToken.tertiary)
                      .margin({ right: 6 })
                    Text(msg.name ? msg.name : 'tool')
                      .fontSize(8)
                      .fontWeight(FontWeightConstant.medium)
                      .fontColor(ColorToken.muted)
                    Text(Icon.check)
                      .fontSize(7)
                      .fontColor(ColorToken.primary)
                      .margin({ left: 6 })
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border_light })
                .borderRadius(4)
              }
              .width('100%')
              .padding({ left: 32 })
              .alignItems(VerticalAlign.Top)
            }
          }, (msg: AiMessage) => msg.role + msg.content)

          // Thinking 指示器
          if (this.aiThinking) {
            Row() {
              Column() {
                Text(Icon.robot)
                  .fontSize(10)
                  .fontColor(ColorToken.white)
              }
              .width(24)
              .height(24)
              .backgroundColor(ColorToken.primary)
              .borderRadius(6)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 2 })

              Column() {
                Text('思考中...')
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.regular)
                  .fontColor(ColorToken.muted)
              }
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius({ topLeft: 2, topRight: 8, bottomLeft: 8, bottomRight: 8 })
              .margin({ left: 8 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }

          // 演示模式提示
          if (!this.byokConfigured) {
            Row() {
              Text(Icon.info_circle)
                .fontSize(10)
                .fontColor('#C97912')
                .margin({ top: 1 })
              Column() {
                Text('演示模式')
                  .fontSize(9)
                  .fontWeight(FontWeightConstant.bold)
                  .fontColor('#7A5314')
                Text('可识别关键词：新建图层 / 列表 / 白底 / 深色背景 / 画布信息。点击右上角齿轮配置 BYOK 以接入真实大模型。')
                  .fontSize(9)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor('#7A5314')
                  .margin({ top: 4 })
              }
              .margin({ left: 8 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF8E8')
            .border({ width: 1, color: '#F4D48A' })
            .borderRadius(6)
            .alignItems(VerticalAlign.Top)
          }

          // 错误提示
          if (this.aiLastError !== '') {
            Row() {
              Text(Icon.warning)
                .fontSize(10)
                .fontColor('#DC2626')
                .margin({ top: 1 })
              Text(this.aiLastError)
                .fontSize(9)
                .fontWeight(FontWeightConstant.medium)
                .fontColor('#7F1D1D')
                .margin({ left: 8 })
                .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FEF2F2')
            .border({ width: 1, color: '#FCA5A5' })
            .borderRadius(6)
            .alignItems(VerticalAlign.Top)
          }
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ─── Input Footer ───
      Column() {
        // 输入行
        Row() {
          Text(Icon.copy)
            .fontSize(10)
            .fontColor(this.hoveredAiAttach ? ColorToken.body : ColorToken.tertiary)
            .onHover((isHover: boolean) => { this.hoveredAiAttach = isHover })

          Row() {
            TextInput({ text: this.aiInputText, placeholder: '输入设计需求...' })
              .fontSize(10)
              .fontColor(ColorToken.body)
              .placeholderColor('#9AA2AC')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .layoutWeight(1)
              .onChange((val: string) => { this.aiInputText = val })
              .onSubmit(() => { this.onAiSend() })
          }
          .layoutWeight(1)
          .height(28)
          .padding({ left: 8, right: 8 })
          .backgroundColor(ColorToken.panel)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(4)
          .margin({ left: 6 })
          .alignItems(VerticalAlign.Center)

          // 发送按钮
          Column() {
            Text(Icon.arrow_up)
              .fontSize(10)
              .fontColor(ColorToken.white)
              .textAlign(TextAlign.Center)
          }
          .width(28)
          .height(28)
          .borderRadius(6)
          .backgroundColor(
            this.aiInputText.trim() !== '' && !this.aiThinking
              ? (this.hoveredAiSend ? ColorToken.primary_dark_900 : ColorToken.primary_dark_700)
              : ColorToken.border_light
          )
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 6 })
          .onHover((isHover: boolean) => { this.hoveredAiSend = isHover })
          .onClick(() => { this.onAiSend() })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        // 上下文信息
        Row() {
          Text(`${this.aiLayerCount} 个图层`)
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
          Text('·')
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ left: 6, right: 6 })
          Text(`${this.aiToolCallCount} 次工具调用`)
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
          Text('·')
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ left: 6, right: 6 })
          Text('嵌入')
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 4, bottom: 2 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .border({ width: { top: 1 }, color: { top: ColorToken.border } })
      .backgroundColor(ColorToken.white)
    }
    .width('100%')
    .height('100%')
  }

  /** 发送 AI 消息 */
  private onAiSend(): void {
    const text = this.aiInputText.trim()
    if (text === '' || this.aiThinking) return
    this.aiInputText = ''
    this.aiMessages.push({ role: 'user', content: text })
    this.aiThinking = true
    // 演示模式：模拟 AI 回复
    setTimeout(() => {
      this.aiThinking = false
      const reply = this.demoReply(text)
      this.aiMessages.push({ role: 'assistant', content: reply })
      // 模拟工具调用
      if (text.indexOf('图层') >= 0 || text.indexOf('列表') >= 0 || text.indexOf('画布') >= 0) {
        this.aiToolCallCount += 1
        this.aiMessages.push({ role: 'tool', content: '', name: 'apply_design_change' })
      }
    }, 600)
  }

  /** 清空对话 */
  private clearAiConversation(): void {
    this.aiMessages = []
    this.aiLastError = ''
    this.aiToolCallCount = 0
  }

  /** 演示模式关键词回复 */
  private demoReply(input: string): string {
    if (input.indexOf('新建') >= 0 && input.indexOf('图层') >= 0) {
      this.aiLayerCount += 1
      return `已为你新建一个白底图层（当前共 ${this.aiLayerCount} 个图层）。你可以在左侧图层面板中查看并继续编辑。`
    }
    if (input.indexOf('列表') >= 0) {
      return `已生成列表结构：\n• 标题：欢迎使用 LarkDesign\n• 副标题：智能设计协作平台\n• 内容：AI 驱动的设计工作流\n\n可通过左侧面板调整层级和样式。`
    }
    if (input.indexOf('白底') >= 0) {
      return '已将当前图层背景设置为白色（#FFFFFF）。'
    }
    if (input.indexOf('深色') >= 0 && input.indexOf('背景') >= 0) {
      return '已切换画布为深色背景模式，文字色已同步调整为浅色以保证对比度。'
    }
    if (input.indexOf('画布') >= 0 && input.indexOf('信息') >= 0) {
      return `画布信息：\n• 尺寸：595 × 842\n• 单位：mm\n• 页数：1\n• 图层数：${this.aiLayerCount}\n• 缩放：100%`
    }
    return `我已收到你的需求：「${input}」。\n\n当前为演示模式，仅支持关键词识别（新建图层 / 列表 / 白底 / 深色背景 / 画布信息）。点击右上角齿轮配置 BYOK 以接入真实大模型。`
  }
}
