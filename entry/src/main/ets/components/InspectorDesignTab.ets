/**
 * InspectorDesignTab - 设计属性面板
 *
 * 对应原型 src/components/Inspector.vue 的 Design Tab 部分
 * 由 Inspector.ets 拆分而来，专注 Design Tab 功能
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, HeightToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { findObjectInDoc } from '../domain/FusionOps'
import { LayerEffect } from '../domain/SceneTypes'
import { InspectorAppearancePanel } from './InspectorAppearancePanel'
import { InspectorPagePropsPanel } from './InspectorPagePropsPanel'
import { InspectorColorManagePanel } from './InspectorColorManagePanel'
import { InspectorCanvasPanel } from './InspectorCanvasPanel'
import { InspectorLayersPanel } from './InspectorLayersPanel'

interface FxItem {
  id: string
  type: string
  enabled: boolean
  label: string
  icon: string
  summary: string
}

interface BlendModeOption {
  value: string
  label: string
}

@Component
export struct InspectorDesignTab {
  // 回调不是可观察状态，不能声明为 @Prop；HarmonyOS 状态系统会拒绝函数值。
  onOpenColorPicker: (target: string, currentColor: string, currentOpacity: number) => void = () => {}
  @Prop colorPickerVersion: number = 0

  @State expandedSection: string = 'canvas'
  @State linkRatio: boolean = false
  @State flipH: boolean = false
  @State flipV: boolean = false
  @State hoveredPathfinder: string = ''
  @State hoveredSection: string = ''
  @State selectedObjectName: string = 'Frame 1'
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
  @State transformX: number = 0
  @State transformY: number = 0
  @State transformW: number = 595
  @State transformH: number = 842
  @State transformRot: number = 0
  @State transformScale: number = 100
  @State fillColor: string = '#34B87A'
  @State strokeColor: string = '#1C2026'
  @State strokeWidth: number = 0
  @State strokePosition: string = 'center'
  @State cornerRadius: number = 0
  @State opacityValue: number = 100
  @State currentBlendMode: string = 'normal'
  @State showBlendModePopup: boolean = false
  @State showFxMenu: boolean = false
  @State hoveredAppearanceRow: string = ''
  @State hoveredBlendMode: boolean = false
  @State fxList: FxItem[] = []
  @State selectedAlign: string = ''
  @State selectedDistribute: string = ''
  @State hoveredAlignBtn: string = ''
  @State hoveredDistributeBtn: string = ''
  @State textContent: string = ''
  @State textFontSize: number = 14
  @State textLineHeight: number = 1.5
  @State textLetterSpacing: number = 0
  @State textColor: string = '#1C2026'
  @State textFontWeight: string = '400'
  @State hoveredFontWeight: string = ''
  @State textFontFamily: string = 'HarmonyOS Sans SC'
  @State activeTypeStyle: string = ''
  @State hasFill: boolean = false
  @State hasTextColor: boolean = false
  @State hasStroke: boolean = false
  @State hasCornerRadius: boolean = false
  @State showFontMenu: boolean = false

  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private fontOptions: string[] = ['HarmonyOS Sans SC', 'HarmonyOS Sans', 'PingFang SC', 'Microsoft YaHei', 'SimSun', 'SimHei', 'KaiTi', 'FangSong', 'Arial', 'Helvetica', 'Georgia', 'Times New Roman']

  aboutToAppear(): void {
    this.syncSelection()
  }

  private onInspectorSync(): void {
    this.syncSelection()
  }

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
      const found = findObjectInDoc(this.fusionStore.getDocument(), obj.id)
      if (found) {
        this.fxList = found.layer.effects.map((e: LayerEffect): FxItem => {
          const opt = this.fxAvailableTypes.find((f: FxItem): boolean => f.type === e.type)
          return {
            id: e.id,
            type: e.type,
            enabled: e.enabled,
            label: opt ? opt.label : e.type,
            icon: opt ? opt.icon : '',
            summary: this.defaultFxSummary(e.type),
          } as FxItem
        })
      }
      this.fillColor = obj.fill ?? '#34B87A'
      this.strokeColor = obj.stroke ?? '#1C2026'
      this.strokeWidth = obj.strokeWidth ?? 0
      this.cornerRadius = obj.cornerRadius ?? 0
      this.opacityValue = Math.round((obj.transform.opacity ?? 1) * 100)
      this.flipH = obj.transform.flipH ?? false
      this.flipV = obj.transform.flipV ?? false
      this.currentBlendMode = obj.blendMode ?? 'normal'
      this.strokePosition = obj.strokePosition ?? 'center'
      this.hasFill = obj.type === 'shape' || obj.type === 'fill'
      this.hasTextColor = obj.type === 'text'
      this.hasStroke = obj.type === 'shape'
      this.hasCornerRadius = obj.type === 'shape' && obj.shape === 'rectangle'
      if (obj.type === 'text') {
        this.textContent = obj.text ?? ''
        this.textFontSize = obj.fontSize ?? 14
        this.textLineHeight = obj.lineHeight ?? 1.5
        this.textLetterSpacing = obj.letterSpacing ?? 0
        this.textColor = obj.color ?? '#1C2026'
        this.textFontWeight = String(obj.fontWeight ?? 400)
        this.textFontFamily = obj.fontFamily ?? 'HarmonyOS Sans SC'
      }
    } else {
      const frame = this.fusionStore.getCurrentFrame()
      if (frame) {
        this.frameName = frame.name
        this.frameX = frame.x
        this.frameY = frame.y
        this.frameW = frame.width
        this.frameH = frame.height
        this.frameBackground = frame.background ?? '#FFFFFF'
      }
      this.fxList = []
    }
  }

  private updateTransform(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length > 0) {
      this.fusionStore.updateObjectTransform(sel[0].id, this.transformX, this.transformY, this.transformW, this.transformH, this.transformRot, this.transformScale / 100, this.transformScale / 100)
    }
  }

  private updateFrameProps(): void {
    const frame = this.fusionStore.getCurrentFrame()
    if (frame) {
      this.fusionStore.updateFrameById(frame.id, this.frameX, this.frameY, this.frameW, this.frameH, this.frameName)
    }
  }

  build(): void {
    Column() {
      Row() {
        Column()
          .width(10)
          .height(10)
          .borderRadius(3)
          .backgroundColor(this.selectedObjectName ? ColorToken.primary : ColorToken.border)
        Text(this.selectedObjectName || '\u672a\u9009\u4e2d\u5143\u7d20')
          .fontSize(13)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(this.selectedObjectName ? ColorToken.body : ColorToken.muted)
          .margin({ left: 8 })
        if (this.selectedObjectName) {
          Blank()
          Text('\u5df2\u9009\u4e2d')
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

      Scroll() {
        Column() {
          this.sectionWithIcon('canvas', '\u753b\u677f', this.frameTypeIcon(this.frameType))
          this.section('transform', '\u53d8\u6362')
          this.section('layout', '\u5bf9\u9f50\u4e0e\u5206\u5e03')
          this.section('appearance', '\u5916\u89c2')
          this.section('typography', '\u6587\u5b57')
          this.section('pathfinder', '\u8def\u5f84\u67e5\u627e\u5668')
          InspectorPagePropsPanel({})
          InspectorColorManagePanel({})
          InspectorCanvasPanel({})
          InspectorLayersPanel({})
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  section(id: string, title: string): void {
    
    Column() {
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
      .onClick(() => { this.expandedSection = this.expandedSection === id ? '' : id })
      .onHover((isHover: boolean) => { this.hoveredSection = isHover ? id : '' })

      if (this.expandedSection === id) {
        if (id === 'canvas') {
          this.canvasContent()
        } else if (id === 'transform') {
          this.transformContent()
        } else if (id === 'appearance') {
          InspectorAppearancePanel({
            fillColor: $fillColor,
            strokeColor: $strokeColor,
            strokeWidth: $strokeWidth,
            strokePosition: $strokePosition,
            cornerRadius: $cornerRadius,
            opacityValue: $opacityValue,
            currentBlendMode: $currentBlendMode,
            showBlendModePopup: $showBlendModePopup,
            showFxMenu: $showFxMenu,
            fxList: $fxList,
            hoveredAppearanceRow: $hoveredAppearanceRow,
            hoveredBlendMode: $hoveredBlendMode,
            hasFill: this.hasFill,
            hasTextColor: this.hasTextColor,
            hasStroke: this.hasStroke,
            hasCornerRadius: this.hasCornerRadius,
            textColorValue: $textColor,
            onOpenColorPicker: this.onOpenColorPicker,
          })
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
      .onClick(() => { this.expandedSection = this.expandedSection === id ? '' : id })
      .onHover((isHover: boolean) => { this.hoveredSection = isHover ? id : '' })

      if (this.expandedSection === id) {
        if (id === 'canvas') {
          this.canvasContent()
        } else if (id === 'transform') {
          this.transformContent()
        } else if (id === 'appearance') {
          InspectorAppearancePanel({
            fillColor: $fillColor,
            strokeColor: $strokeColor,
            strokeWidth: $strokeWidth,
            strokePosition: $strokePosition,
            cornerRadius: $cornerRadius,
            opacityValue: $opacityValue,
            currentBlendMode: $currentBlendMode,
            showBlendModePopup: $showBlendModePopup,
            showFxMenu: $showFxMenu,
            fxList: $fxList,
            hoveredAppearanceRow: $hoveredAppearanceRow,
            hoveredBlendMode: $hoveredBlendMode,
            hasFill: this.hasFill,
            hasTextColor: this.hasTextColor,
            hasStroke: this.hasStroke,
            hasCornerRadius: this.hasCornerRadius,
            textColorValue: $textColor,
            onOpenColorPicker: this.onOpenColorPicker,
          })
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
      Row() {
        Text('\u540d\u79f0')
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

      Row() {
        Row() {
          Text('\u7c7b\u578b')
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

        Row() {
          Text('\u5e8f\u53f7')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
            .width(28)
          Text('' + this.frameOrder)
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

      Row() {
        Row() {
          Text('X')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.frameX })
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

        Row() {
          Text('Y')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.frameY })
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

      Row() {
        Row() {
          Text('W')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.frameW })
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

        Row() {
          Text('H')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.frameH })
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

      Row() {
        Text('\u80cc\u666f\u8272')
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
            .onClick(() => { this.onOpenColorPicker('frame', this.frameBackground, 100) })
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

      if (this.frameType === 'book-page' || this.frameType === 'spread') {
        Column() {
          Row() {
            Text('\u663e\u793a\u9875\u7801')
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

          Row() {
            Text('\u9875\u7801')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(28)
            TextInput({ text: '' + this.frameOrder })
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

      Row() {
        Text(this.frameHidden ? '\u5df2\u9690\u85cf' : '\u663e\u793a\u4e2d')
          .fontSize(11)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Text(this.frameHidden ? Icon.eye_off : Icon.eye)
          .fontSize(11)
          .fontColor(this.hoveredFrameEye ? ColorToken.primary : (this.frameHidden ? ColorToken.error : ColorToken.muted))
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

  private frameTypeLabel(type: string): string {
    if (type === 'single') return '\u5355\u9875'
    if (type === 'poster') return '\u6d77\u62a5'
    if (type === 'book-page') return '\u4e66\u9875'
    if (type === 'spread') return '\u5bf9\u9875'
    return '\u5355\u9875'
  }

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
      Row() {
        Row() {
          Text('X')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.transformX })
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

        Row() {
          Text('Y')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.transformY })
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

      Row() {
        Row() {
          Text('W')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.transformW })
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

        Row() {
          Text('H')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(10)
          TextInput({ text: '' + this.transformH })
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

      Row() {
        Row() {
          Text('\u2220')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(20)
          TextInput({ text: '' + this.transformRot })
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
          Text('\u00b0')
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

        Row() {
          Text('\u2932')
            .fontSize(11)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.muted)
            .width(20)
          TextInput({ text: '' + this.transformScale })
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

      Row() {
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
          Text('\u7ea6\u675f\u6bd4\u4f8b')
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
        .opacity(this.selectedObjectName ? 1 : 0.5)

        Blank()

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
        .onClick(() => { if (this.selectedObjectName) { this.flipH = !this.flipH; this.updateAppearance('flipH', this.flipH) } })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'flipH' : '' })

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
        .onClick(() => { if (this.selectedObjectName) { this.flipV = !this.flipV; this.updateAppearance('flipV', this.flipV) } })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'flipV' : '' })
      }
      .width('100%')
      .margin({ top: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }


  private fxAvailableTypes: FxItem[] = [
    { id: 'drop_shadow_opt', type: 'drop-shadow', enabled: true, label: '\u6295\u5f71', icon: Icon.download, summary: '' },
    { id: 'inner_shadow_opt', type: 'inner-shadow', enabled: true, label: '\u5185\u9634\u5f71', icon: Icon.shadow, summary: '' },
    { id: 'outer_glow_opt', type: 'outer-glow', enabled: true, label: '\u5916\u53d1\u5149', icon: Icon.circle, summary: '' },
    { id: 'inner_glow_opt', type: 'inner-glow', enabled: true, label: '\u5185\u53d1\u5149', icon: Icon.eye, summary: '' },
    { id: 'bevel_opt', type: 'bevel', enabled: true, label: '\u659c\u9762\u4e0e\u6d6e\u96d5', icon: Icon.cube, summary: '' },
    { id: 'satin_opt', type: 'satin', enabled: true, label: '\u5149\u6cfd', icon: Icon.droplet, summary: '' },
    { id: 'color_overlay_opt', type: 'color-overlay', enabled: true, label: '\u989c\u8272\u53e0\u52a0', icon: Icon.palette, summary: '' },
    { id: 'gradient_overlay_opt', type: 'gradient-overlay', enabled: true, label: '\u6e10\u53d8\u53e0\u52a0', icon: Icon.palette, summary: '' },
    { id: 'pattern_overlay_opt', type: 'pattern-overlay', enabled: true, label: '\u56fe\u6848\u53e0\u52a0', icon: Icon.grid, summary: '' },
  ]

  private defaultFxSummary(type: string): string {
    if (type === 'drop-shadow' || type === 'inner-shadow') return '5px \u00b7 #000000 40%'
    if (type === 'outer-glow' || type === 'inner-glow') return '#3AC487 50%'
    if (type === 'color-overlay') return '#3AC487 100%'
    if (type === 'bevel') return 'inner \u00b7 50%'
    if (type === 'satin') return '#000000 50%'
    if (type === 'gradient-overlay') return '\u7ebf\u6027 100%'
    if (type === 'pattern-overlay') return '\u9ed8\u8ba4 100%'
    return '0%'
  }


  private updateTextProp(key: string, value: number | string | boolean): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0 || sel[0].type !== 'text') return
    this.fusionStore.updateObjectTextProp(sel[0].id, key, value)
  }

  private updateAppearance(key: string, value: number | string | boolean): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) return
    this.fusionStore.updateObjectAppearance(sel[0].id, key, value)
  }

  @Builder
  layoutContent(): void {
    
    Column() {
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

  @Builder
  alignButton(id: string, icon: string): void {
    
    Column() {
      Text(icon)
        .fontSize(12)
        .fontColor(this.selectedAlign === id ? ColorToken.primary_dark_700 : (this.hoveredAlignBtn === id ? ColorToken.body : ColorToken.secondary))
    }
    .layoutWeight(1)
    .height(32)
    .borderRadius(5)
    .backgroundColor(this.selectedAlign === id ? ColorToken.primary_light_100 : (this.hoveredAlignBtn === id ? ColorToken.panel : Color.Transparent))
    .border({ width: this.selectedAlign === id ? 1 : 0, color: this.selectedAlign === id ? ColorToken.primary : Color.Transparent })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 4 })
    .onClick(() => { this.selectedAlign = id })
    .onHover((isHover: boolean) => { this.hoveredAlignBtn = isHover ? id : '' })
  }

  @Builder
  distributeButton(id: string, icon: string): void {
    
    Column() {
      Text(icon)
        .fontSize(12)
        .fontColor(this.selectedDistribute === id ? ColorToken.primary_dark_700 : (this.hoveredDistributeBtn === id ? ColorToken.body : ColorToken.secondary))
    }
    .layoutWeight(1)
    .height(32)
    .borderRadius(5)
    .backgroundColor(this.selectedDistribute === id ? ColorToken.primary_light_100 : (this.hoveredDistributeBtn === id ? ColorToken.panel : Color.Transparent))
    .border({ width: this.selectedDistribute === id ? 1 : 0, color: this.selectedDistribute === id ? ColorToken.primary : Color.Transparent })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 4 })
    .onClick(() => { this.selectedDistribute = id })
    .onHover((isHover: boolean) => { this.hoveredDistributeBtn = isHover ? id : '' })
  }

  @Builder
  typographyContent(): void {
    
    Column() {
      // ─── 内容输入框 ───
      Column() {
        Text('\u5185\u5bb9')
          .fontSize(9)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
        TextInput({ text: this.textContent, placeholder: '\u8f93\u5165\u6587\u5b57\u5185\u5bb9...' })
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .height(24)
          .onChange((val: string) => { this.textContent = val; this.updateTextProp('text', val) })
      }
      .width('100%')
      .padding({ left: 6, right: 6, top: 4, bottom: 4 })
      .borderRadius(5)
      .backgroundColor(ColorToken.panel)
      .margin({ bottom: 8 })
      .alignItems(HorizontalAlign.Start)

      // ─── 字体行（点击显示下拉） ───
      Row() {
        Text('\u5b57\u4f53')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        Text(this.textFontFamily)
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .height(32)
      .padding({ left: 8, right: 8 })
      .borderRadius(5)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: this.hoveredFrameRow === 'font_family' ? ColorToken.border : Color.Transparent })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })
      .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'font_family' : '' })
      .onClick(() => { this.showFontMenu = !this.showFontMenu })

      if (this.showFontMenu) {
        Column() {
          ForEach(this.fontOptions, (font: string) => {
            Text(font)
              .fontSize(12)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.textFontFamily === font ? ColorToken.primary_dark_700 : ColorToken.body)
              .width('100%')
              .height(28)
              .padding({ left: 12 })
              .backgroundColor(this.hoveredFrameRow === 'font_' + font ? ColorToken.hover_bg : Color.Transparent)
              .onClick(() => { this.textFontFamily = font; this.updateTextProp('fontFamily', font); this.showFontMenu = false })
              .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'font_' + font : '' })
          })
        }
        .width('100%')
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(6)
        .shadow({ radius: 8, color: '#0000001F', offsetX: 0, offsetY: 4 })
        .padding({ top: 4, bottom: 4 })
        .margin({ bottom: 8 })
      }

      Row() {
        Column() {
          Text('\u5b57\u53f7')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: '' + this.textFontSize })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { const v = Number(val) || 14; this.textFontSize = v; this.updateTextProp('fontSize', v) })
        }
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'text_size' ? ColorToken.border : Color.Transparent })
        .alignItems(HorizontalAlign.Start)
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_size' : '' })

        Column() {
          Text('\u884c\u8ddd')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: '' + this.textLineHeight })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { const v = Number(val) || 1.5; this.textLineHeight = v; this.updateTextProp('lineHeight', v) })
        }
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
        .borderRadius(5)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: this.hoveredFrameRow === 'text_lh' ? ColorToken.border : Color.Transparent })
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 6 })
        .onHover((isHover: boolean) => { this.hoveredFrameRow = isHover ? 'text_lh' : '' })

        Column() {
          Text('\u5b57\u8ddd')
            .fontSize(9)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.muted)
          TextInput({ text: '' + this.textLetterSpacing })
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .type(InputType.Number)
            .onChange((val: string) => { const v = Number(val) || 0; this.textLetterSpacing = v; this.updateTextProp('letterSpacing', v) })
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

      Row() {
        Text('\u5b57\u91cd')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
          .width(28)
        this.fontWeightButton('300', '\u7ec6', true)
        this.fontWeightButton('400', '\u5e38\u89c4', false)
        this.fontWeightButton('500', '\u4e2d', false)
        this.fontWeightButton('600', '\u534a\u7c97', false)
        this.fontWeightButton('700', '\u7c97', false)
        this.fontWeightButton('800', '\u7279\u7c97', false)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

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

      Row() {
        Text('\u6587\u5b57\u8272')
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
            .onClick(() => { this.onOpenColorPicker('text', this.textColor, this.opacityValue) })
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
            .onChange((val: string) => { this.textColor = val; this.updateTextProp('color', val) })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .padding({ left: 14, right: 14, bottom: 14 })
  }

  @Builder
  fontWeightButton(weight: string, label: string, isFirst: boolean): void {
    
    Text(label)
      .fontSize(10)
      .fontWeight(FontWeightConstant.medium)
      .fontColor(this.textFontWeight === weight ? ColorToken.white : ColorToken.secondary)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .height(24)
      .borderRadius(4)
      .backgroundColor(this.textFontWeight === weight ? ColorToken.primary : (this.hoveredFontWeight === weight ? ColorToken.border_light : ColorToken.panel))
      .margin({ left: isFirst ? 0 : 6 })
      .textAlign(TextAlign.Center)
      .onClick(() => { this.textFontWeight = weight; this.updateTextProp('fontWeight', Number(weight)) })
      .onHover((isHover: boolean) => { this.hoveredFontWeight = isHover ? weight : '' })
  }

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
      Row() {
        this.pathfinderOp('union', '\u5408\u96c6', true)
        this.pathfinderOp('subtract', '\u5dee\u96c6', false)
        this.pathfinderOp('intersect', '\u4ea4\u96c6', false)
        this.pathfinderOp('exclude', '\u6392\u9664', false)
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
    .alignItems(VerticalAlign.Center)
    .margin({ left: isFirst ? 0 : 8 })
    .onHover((isHover: boolean) => { this.hoveredPathfinder = isHover ? op : '' })
  }
}


