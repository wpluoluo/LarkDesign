/**
 * InspectorAppearancePanel - 外观属性面板
 *
 * 由 InspectorDesignTab.ets 拆分而来，专注外观（填充/描边/圆角/不透明度/混合模式/图层样式）
 */
import { ColorToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { findObjectInDoc } from '../types/FusionOps'
import { LayerEffect } from '../types/SceneTypes'

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
export struct InspectorAppearancePanel {
  @Link fillColor: string
  @Link strokeColor: string
  @Link strokeWidth: number
  @Link strokePosition: string
  @Link cornerRadius: number
  @Link opacityValue: number
  @Link currentBlendMode: string
  @Link showBlendModePopup: boolean
  @Link showFxMenu: boolean
  @Link fxList: FxItem[]
  @Link hoveredAppearanceRow: string
  @Link hoveredBlendMode: boolean
  @Prop onOpenColorPicker: (target: string, currentColor: string, currentOpacity: number) => void = () => {}

  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  build(): void {
    Column() {
      Row() {
        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(5)
            .backgroundColor(this.fillColor)
            .border({ width: 1, color: ColorToken.border })
            .shadow(ShadowToken.sm)
            .onClick(() => { this.onOpenColorPicker('fill', this.fillColor, this.opacityValue) })
          Text('\u586b\u5145')
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

      Row() {
        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(5)
            .backgroundColor(this.strokeColor)
            .border({ width: 1, color: ColorToken.border })
            .shadow(ShadowToken.sm)
            .onClick(() => { this.onOpenColorPicker('stroke', this.strokeColor, this.opacityValue) })
          Text('\u63cf\u8fb9')
            .fontSize(12)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()
        Row() {
          TextInput({ text: '' + this.strokeWidth })
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
            .onChange((val: string) => { const v = Number(val) || 0; this.strokeWidth = v; this.updateAppearance('strokeWidth', v) })
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

      Row() {
        this.strokePositionOp('outside', '\u5916\u90e8')
        this.strokePositionOp('center', '\u5c45\u4e2d')
        this.strokePositionOp('inside', '\u5185\u90e8')
      }
      .width('100%')
      .margin({ bottom: 10 })

      Row() {
        Text('\u5706\u89d2\u534a\u5f84')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          TextInput({ text: '' + this.cornerRadius })
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
            .onChange((val: string) => { const v = Number(val) || 0; this.cornerRadius = v; this.updateAppearance('cornerRadius', v) })
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

      Row() {
        Text('\u4e0d\u900f\u660e\u5ea6')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width('100%')
              .height(5)
              .backgroundColor(ColorToken.border)
              .borderRadius(2)
            Row()
              .width('' + this.opacityValue + '%')
              .height(5)
              .backgroundColor(ColorToken.primary)
              .borderRadius(2)
            Row()
              .width(10)
              .height(10)
              .borderRadius(5)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.primary })
              .margin({ left: '' + Math.max(0, this.opacityValue - 5) + '%' })
          }
          .width(90)
          .height(12)
          .alignContent(Alignment.Center)
          .gesture(
            PanGesture()
              .onActionStart((e: GestureEvent) => { this.updateOpacityFromX(e.fingerList[0].localX) })
              .onActionUpdate((e: GestureEvent) => { this.updateOpacityFromX(e.fingerList[0].localX) })
          )
          .onClick((e: ClickEvent) => { this.updateOpacityFromX(e.x) })

          TextInput({ text: '' + this.opacityValue })
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
              this.updateAppearance('opacity', this.opacityValue / 100)
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

      Row() {
        Text('\u6df7\u5408\u6a21\u5f0f')
          .fontSize(12)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.secondary)
        Blank()
        Row() {
          Text(this.blendModeLabel(this.currentBlendMode))
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
                if (this.currentBlendMode === opt.value) {
                  Text(Icon.check)
                    .fontSize(10)
                    .fontColor(ColorToken.primary)
                }
              }
              .width('100%')
              .height(28)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.hoveredAppearanceRow === 'blend_' + opt.value ? ColorToken.hover_bg : (this.currentBlendMode === opt.value ? ColorToken.hover_bg : Color.Transparent))
              .alignItems(VerticalAlign.Center)
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? 'blend_' + opt.value : '' })
              .onClick(() => {
                this.currentBlendMode = opt.value
                this.showBlendModePopup = false
                this.updateAppearance('blendMode', opt.value)
              })
            })
          }
          .width('100%')
          .padding({ top: 4, bottom: 4 })
        }
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

      Column() {
        Row() {
          Text('\u56fe\u5c42\u6837\u5f0f')
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
              .backgroundColor(this.hoveredAppearanceRow === 'fx_' + opt.type ? ColorToken.hover_bg : Color.Transparent)
              .alignItems(VerticalAlign.Center)
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? 'fx_' + opt.type : '' })
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

        ForEach(this.fxList, (fx: FxItem) => {
          Row() {
            Text(fx.enabled ? Icon.check_square : Icon.square)
              .fontSize(12)
              .fontColor(fx.enabled ? ColorToken.primary : ColorToken.muted)
              .margin({ right: 8 })
              .onClick(() => { this.toggleFx(fx.id) })
            Text(fx.icon)
              .fontSize(12)
              .fontColor(fx.enabled ? ColorToken.primary_dark_700 : ColorToken.muted)
              .margin({ right: 8 })
            Text(fx.label)
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(fx.enabled ? ColorToken.secondary : ColorToken.muted)
              .layoutWeight(1)
            Text(fx.summary)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .margin({ right: 8 })
            Text(Icon.trash)
              .fontSize(10)
              .fontColor(this.hoveredAppearanceRow === 'fx_del_' + fx.id ? ColorToken.error : ColorToken.muted)
              .onClick(() => { this.removeFx(fx.id) })
              .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? 'fx_del_' + fx.id : '' })
          }
          .width('100%')
          .padding(6)
          .borderRadius(5)
          .backgroundColor(this.hoveredAppearanceRow === 'fx_item_' + fx.id ? ColorToken.border_light : Color.Transparent)
          .alignItems(VerticalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? 'fx_item_' + fx.id : '' })
        })

        if (this.fxList.length === 0) {
          Row() {
            Text('\u6682\u65e0\u56fe\u5c42\u6837\u5f0f')
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

  @Builder
  strokePositionOp(value: string, label: string): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(this.strokePosition === value ? ColorToken.primary_dark_700 : (this.hoveredAppearanceRow === value ? ColorToken.body : ColorToken.muted))
    }
    .layoutWeight(1)
    .height(28)
    .borderRadius(4)
    .backgroundColor(this.strokePosition === value ? ColorToken.hover_bg : (this.hoveredAppearanceRow === value ? ColorToken.panel : Color.Transparent))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .margin({ left: 2, right: 2 })
    .onClick(() => { this.strokePosition = value; this.updateAppearance('strokePosition', value) })
    .onHover((isHover: boolean) => { this.hoveredAppearanceRow = isHover ? value : '' })
  }

  private blendModeLabel(mode: string): string {
    if (mode === 'normal') return '\u6b63\u5e38'
    if (mode === 'multiply') return '\u6b63\u7247\u53e0\u5e95'
    if (mode === 'screen') return '\u6ee4\u8272'
    if (mode === 'overlay') return '\u53e0\u52a0'
    if (mode === 'darken') return '\u53d8\u6697'
    if (mode === 'lighten') return '\u53d8\u4eae'
    if (mode === 'color-dodge') return '\u989c\u8272\u51cf\u6de1'
    if (mode === 'color-burn') return '\u989c\u8272\u52a0\u6df1'
    if (mode === 'hard-light') return '\u5f3a\u5149'
    if (mode === 'soft-light') return '\u67d4\u5149'
    if (mode === 'difference') return '\u5dee\u503c'
    if (mode === 'exclusion') return '\u6392\u9664'
    if (mode === 'hue') return '\u8272\u76f8'
    if (mode === 'saturation') return '\u9971\u548c\u5ea6'
    if (mode === 'color') return '\u989c\u8272'
    if (mode === 'luminosity') return '\u660e\u5ea6'
    return '\u6b63\u5e38'
  }

  private blendModeOptions: BlendModeOption[] = [
    { value: 'normal', label: '\u6b63\u5e38' },
    { value: 'multiply', label: '\u6b63\u7247\u53e0\u5e95' },
    { value: 'screen', label: '\u6ee4\u8272' },
    { value: 'overlay', label: '\u53e0\u52a0' },
    { value: 'darken', label: '\u53d8\u6697' },
    { value: 'lighten', label: '\u53d8\u4eae' },
    { value: 'color-dodge', label: '\u989c\u8272\u51cf\u6de1' },
    { value: 'color-burn', label: '\u989c\u8272\u52a0\u6df1' },
    { value: 'hard-light', label: '\u5f3a\u5149' },
    { value: 'soft-light', label: '\u67d4\u5149' },
    { value: 'difference', label: '\u5dee\u503c' },
    { value: 'exclusion', label: '\u6392\u9664' },
    { value: 'hue', label: '\u8272\u76f8' },
    { value: 'saturation', label: '\u9971\u548c\u5ea6' },
    { value: 'color', label: '\u989c\u8272' },
    { value: 'luminosity', label: '\u660e\u5ea6' },
  ]

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

  private addFx(type: string): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) return
    const found = findObjectInDoc(this.fusionStore.getDocument(), sel[0].id)
    if (!found) return
    this.fusionStore.addLayerEffect(found.layer.id, type)
    this.showFxMenu = false
  }

  private toggleFx(id: string): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) return
    const found = findObjectInDoc(this.fusionStore.getDocument(), sel[0].id)
    if (!found) return
    this.fusionStore.toggleLayerEffect(found.layer.id, id)
  }

  private updateOpacityFromX(localX: number): void {
    const trackWidth = 90
    const ratio = Math.max(0, Math.min(1, localX / trackWidth))
    const newOpacity = Math.round(ratio * 100)
    if (newOpacity !== this.opacityValue) {
      this.opacityValue = newOpacity
      this.updateAppearance('opacity', newOpacity / 100)
    }
  }

  private removeFx(id: string): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) return
    const found = findObjectInDoc(this.fusionStore.getDocument(), sel[0].id)
    if (!found) return
    this.fusionStore.removeLayerEffect(found.layer.id, id)
  }

  private updateAppearance(key: string, value: number | string | boolean): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) return
    this.fusionStore.updateObjectAppearance(sel[0].id, key, value)
  }
}