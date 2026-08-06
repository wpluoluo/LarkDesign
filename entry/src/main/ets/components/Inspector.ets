/**
 * Inspector - 右侧属性面板（父容器）
 *
 * 管理 Tab 切换与 ColorPickerPopover
 * 拆分后：Design/Export/Settings/AI 各为独立 @Component
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { ColorPickerPopover } from './ColorPickerPopover'
import { InspectorDesignTab } from './InspectorDesignTab'
import { InspectorExportTab } from './InspectorExportTab'
import { InspectorSettingsTab } from './InspectorSettingsTab'
import { InspectorAiTab } from './InspectorAiTab'

@Component
export struct Inspector {
  @State activeTab: string = 'design'
  @State hoveredTab: string = ''
  @State hoveredSection: string = ''

  // ColorPickerPopover state
  @State colorPickerVisible: boolean = false
  @State colorPickerTarget: string = 'fill'
  @State colorPickerValue: string = '#3AC487'
  @State colorPickerOpacity: number = 100
  @State colorPickerVersion: number = 0

  private colorPickerX: number = 8
  private colorPickerY: number = 80
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row() {
          this.tabButton('design', '设计', '')
          this.tabButton('export', '导出', '')
          this.tabButton('settings', '设置', Icon.gear)
          this.tabButton('ai', 'AI智能', Icon.wand)
          Blank()
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

        if (this.activeTab === 'design') {
          InspectorDesignTab({
            onOpenColorPicker: (target: string, currentColor: string, currentOpacity: number): void => {
              this.openColorPicker(target, currentColor, currentOpacity)
            },
            colorPickerVersion: this.colorPickerVersion,
          })
        } else if (this.activeTab === 'export') {
          InspectorExportTab({})
        } else if (this.activeTab === 'settings') {
          InspectorSettingsTab({})
        } else {
          InspectorAiTab({})
        }
      }
      .width(LayoutToken.inspector_width)
      .height('100%')
      .backgroundColor(ColorToken.white)
      .border({ width: { left: 1 }, color: { left: ColorToken.border } })

      ColorPickerPopover({
        visible: this.colorPickerVisible,
        anchorX: this.colorPickerX,
        anchorY: this.colorPickerY,
        modelValue: this.colorPickerValue,
        initialOpacity: this.colorPickerOpacity,
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

  @Builder
  tabButton(id: string, label: string, icon: string): void {
    Row() {
      if (icon !== '') {
        Text(icon)
          .fontSize(11)
          .fontColor(this.activeTab === id ? ColorToken.primary_dark_700 : (this.hoveredTab === id ? ColorToken.body : ColorToken.muted))
      }
      Text(label)
        .fontSize(12)
        .fontWeight(this.activeTab === id ? FontWeightConstant.bold : FontWeightConstant.medium)
        .fontColor(this.activeTab === id ? ColorToken.primary_dark_700 : (this.hoveredTab === id ? ColorToken.body : ColorToken.muted))
        .margin({ left: icon !== '' ? 6 : 0 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(6)
    .backgroundColor(this.activeTab === id ? ColorToken.hover_bg : (this.hoveredTab === id ? ColorToken.panel : Color.Transparent))
    .border({ width: this.activeTab === id ? 1 : 0, color: this.activeTab === id ? ColorToken.primary_light_300 : Color.Transparent })
    .margin({ right: 4 })
    .onClick(() => { this.activeTab = id })
    .onHover((isHover: boolean) => {
      if (this.activeTab !== id) {
        this.hoveredTab = isHover ? id : ''
      }
    })
  }

  private openColorPicker(target: string, currentColor: string, currentOpacity: number): void {
    this.colorPickerTarget = target
    this.colorPickerValue = currentColor.toUpperCase()
    this.colorPickerOpacity = currentOpacity
    this.colorPickerX = 8
    this.colorPickerY = 80
    this.colorPickerVisible = true
  }

  private applyColorPickerValue(hex: string): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (this.colorPickerTarget === 'fill') {
      this.colorPickerValue = hex
      if (sel.length > 0) {
        this.fusionStore.updateObjectAppearance(sel[0].id, 'fill', hex)
      }
    } else if (this.colorPickerTarget === 'stroke') {
      this.colorPickerValue = hex
      if (sel.length > 0) {
        this.fusionStore.updateObjectAppearance(sel[0].id, 'stroke', hex)
      }
    } else if (this.colorPickerTarget === 'text') {
      this.colorPickerValue = hex
      if (sel.length > 0 && sel[0].type === 'text') {
        this.fusionStore.updateObjectTextProp(sel[0].id, 'color', hex)
      }
    }
    this.colorPickerVersion++
  }
}