/**
 * InspectorLayersPanel - 图层面板
 *
 * 对应原型 src/components/Inspector.vue 的 Design Tab 图层部分
 * 包含：图层列表、混合模式/不透明度条、搜索、PS 风格底部工具栏
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

/** 扁平化图层行 */
interface LayerRow {
  key: string
  name: string
  type: string
  visible: boolean
  locked: boolean
  active: boolean
  depth: number
  thumbColor: string
  hasMask: boolean
  maskEnabled: boolean
  linked: boolean
  blendMode: string
  expanded: boolean
  isGroup: boolean
  iconColor: string
  srcIndex: number
}

interface BlendModeOption {
  value: string
  label: string
}

@Component
export struct InspectorLayersPanel {
  @State flatLayers: LayerRow[] = []
  @State searchText: string = ''
  @State showBlendPopup: boolean = false
  @State hoveredBlend: boolean = false
  @State hoveredRow: string = ''
  @State hoveredTool: string = ''

  private groupIndex: number = -1
  private blendOptions: BlendModeOption[] = [
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

  aboutToAppear(): void {
    this.rebuildLayers()
  }

  /** 静态图层树（对应原型 layers ref） */
  private staticTree(): LayerRow[] {
    const rows: LayerRow[] = []
    const push = (name: string, type: string, visible: boolean, active: boolean, locked: boolean, depth: number,
      thumbColor: string, hasMask: boolean, maskEnabled: boolean, linked: boolean, blendMode: string,
      expanded: boolean, iconColor: string, idx: number): void => {
      rows.push({
        key: 'layer_' + rows.length,
        name: name,
        type: type,
        visible: visible,
        locked: locked,
        active: active,
        depth: depth,
        thumbColor: thumbColor,
        hasMask: hasMask,
        maskEnabled: maskEnabled,
        linked: linked,
        blendMode: blendMode,
        expanded: expanded,
        isGroup: type === 'group',
        iconColor: iconColor,
        srcIndex: idx,
      })
    }
    push('\u7ec4 1', 'group', true, false, false, 0, '', false, false, false, 'pass-through', true, '', 0)
    push('Image 01', 'image', true, false, false, 0, '#E5E7EB', true, true, false, 'multiply', false, '', 1)
    push('Green Shape', 'shape', true, false, false, 0, '#3AC487', false, false, false, 'overlay', false, 'green', 2)
    push('\u8272\u76f8/\u9971\u548c\u5ea6', 'adjustment', true, false, false, 0, '', true, false, false, 'color', false, '', 3)
    push('Background', 'shape', true, false, true, 0, '#BFC6CB', false, false, false, 'normal', false, 'gray', 4)
    push('\u7eaf\u8272\u586b\u5145', 'fill', true, false, false, 0, '#30D158', false, false, false, 'screen', false, '', 5)
    push('\u667a\u80fd\u5bf9\u8c61', 'image', false, false, false, 0, '#D1D5DB', true, true, true, 'normal', false, '', 6)
    return rows
  }

  /** 展开组：把组内子层平铺在组行之后 */
  private flatten(rows: LayerRow[]): LayerRow[] {
    const result: LayerRow[] = []
    for (const r of rows) {
      result.push(r)
      if (r.isGroup && r.expanded && r.depth === 0 && r.srcIndex === 0) {
        // 仅对第一个组展开子层
      }
    }
    return result
  }

  /** 重建图层列表（组 1 展开时插入子层） */
  private rebuildLayers(): void {
    const base = this.staticTree()
    const result: LayerRow[] = []
    for (let i = 0; i < base.length; i++) {
      const r = base[i]
      result.push(r)
      if (r.isGroup && r.expanded) {
        result.push(this.makeRow('layer_100', '\u6784\u60f3\uff0c\u8ba9\u8bbe\u8ba1\u53d1\u751f', 'text', true, true, false, 1, '', false, false, false, 'normal', false, '', 1))
        result.push(this.makeRow('layer_101', '\u6b63\u6587\u6bb5\u843d', 'text', true, false, false, 1, '', false, false, false, 'normal', false, '', 2))
      }
    }
    this.flatLayers = result
  }

  private toggleGroupVisible(): void {
    for (let i = 0; i < this.flatLayers.length; i++) {
      const r = this.flatLayers[i]
      if (r.isGroup && r.srcIndex === 0) {
        const expanded = !r.expanded
        this.flatLayers[i] = this.copyRow(r)
        this.flatLayers[i].expanded = expanded
        // 插入/移除子层
        if (expanded) {
          const children: LayerRow[] = [
            this.makeRow('layer_100', '\u6784\u60f3\uff0c\u8ba9\u8bbe\u8ba1\u53d1\u751f', 'text', true, true, false, 1, '', false, false, false, 'normal', false, '', 1),
            this.makeRow('layer_101', '\u6b63\u6587\u6bb5\u843d', 'text', true, false, false, 1, '', false, false, false, 'normal', false, '', 2),
          ]
          const after: LayerRow[] = []
          for (let j = 0; j < this.flatLayers.length; j++) {
            after.push(this.flatLayers[j])
            if (j === i) {
              for (const c of children) {
                after.push(c)
              }
            }
          }
          this.flatLayers = after
        } else {
          const filtered: LayerRow[] = []
          for (const r2 of this.flatLayers) {
            if (r2.key === 'layer_100' || r2.key === 'layer_101') {
              continue
            }
            filtered.push(r2)
          }
          this.flatLayers = filtered
        }
        return
      }
    }
  }

  private makeRow(key: string, name: string, type: string, visible: boolean, active: boolean, locked: boolean,
    depth: number, thumbColor: string, hasMask: boolean, maskEnabled: boolean, linked: boolean,
    blendMode: string, expanded: boolean, iconColor: string, idx: number): LayerRow {
    return {
      key: key,
      name: name,
      type: type,
      visible: visible,
      locked: locked,
      active: active,
      depth: depth,
      thumbColor: thumbColor,
      hasMask: hasMask,
      maskEnabled: maskEnabled,
      linked: linked,
      blendMode: blendMode,
      expanded: expanded,
      isGroup: type === 'group',
      iconColor: iconColor,
      srcIndex: idx,
    }
  }

  private copyRow(r: LayerRow): LayerRow {
    return this.makeRow(r.key, r.name, r.type, r.visible, r.active, r.locked, r.depth, r.thumbColor,
      r.hasMask, r.maskEnabled, r.linked, r.blendMode, r.expanded, r.iconColor, r.srcIndex)
  }

  private selectLayer(key: string): void {
    for (let i = 0; i < this.flatLayers.length; i++) {
      this.flatLayers[i] = this.copyRow(this.flatLayers[i])
      this.flatLayers[i].active = this.flatLayers[i].key === key
    }
  }

  private toggleVisible(key: string): void {
    for (let i = 0; i < this.flatLayers.length; i++) {
      if (this.flatLayers[i].key === key) {
        this.flatLayers[i] = this.copyRow(this.flatLayers[i])
        this.flatLayers[i].visible = !this.flatLayers[i].visible
        return
      }
    }
  }

  private toggleLock(key: string): void {
    for (let i = 0; i < this.flatLayers.length; i++) {
      if (this.flatLayers[i].key === key) {
        this.flatLayers[i] = this.copyRow(this.flatLayers[i])
        this.flatLayers[i].locked = !this.flatLayers[i].locked
        return
      }
    }
  }

  private filteredRows(): LayerRow[] {
    const q = this.searchText.trim()
    if (q === '') {
      return this.flatLayers
    }
    const result: LayerRow[] = []
    for (const r of this.flatLayers) {
      if (r.name.toLowerCase().indexOf(q.toLowerCase()) >= 0) {
        result.push(r)
      }
    }
    return result
  }

  private layerIcon(type: string): string {
    if (type === 'text') return Icon.text
    if (type === 'image') return Icon.image
    if (type === 'adjustment') return Icon.circle
    if (type === 'fill') return Icon.droplet
    if (type === 'shape') return Icon.square
    return Icon.layers
  }

  private blendLabel(mode: string): string {
    for (const opt of this.blendOptions) {
      if (opt.value === mode) {
        return opt.label
      }
    }
    return '\u6b63\u5e38'
  }

  build(): void {
    Column() {
      // ─── Header: layer count ───
      Row() {
        Text('\u56fe\u5c42')
          .fontSize(13)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.body)
        Blank()
        Text('' + this.flatLayers.length + ' \u5c42')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)

      // ─── Blend mode + opacity bar ───
      Row() {
        Row() {
          Text(this.blendLabel(this.activeBlendMode()))
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .layoutWeight(1)
          Text(Icon.chevron_down)
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .layoutWeight(1)
        .height(28)
        .padding({ left: 8, right: 8 })
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: this.hoveredBlend ? ColorToken.primary : ColorToken.border })
        .borderRadius(4)
        .alignItems(VerticalAlign.Center)
        .onClick(() => { this.showBlendPopup = !this.showBlendPopup })
        .onHover((isHover: boolean) => { this.hoveredBlend = isHover })

        Row() {
          Text('100%')
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
          Text(Icon.chevron_down)
            .fontSize(10)
            .fontColor(ColorToken.muted)
        }
        .width(62)
        .height(28)
        .padding({ left: 8, right: 8 })
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(4)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
        .onClick(() => {})

        Row() {
          Text(Icon.lock)
            .fontSize(11)
            .fontColor(ColorToken.tertiary)
            .padding(6)
          Text(Icon.unlock)
            .fontSize(11)
            .fontColor(ColorToken.tertiary)
            .padding(6)
          Text(Icon.layers)
            .fontSize(11)
            .fontColor(ColorToken.tertiary)
            .padding(6)
        }
        .alignItems(VerticalAlign.Center)
        .margin({ left: 4 })
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .border({ width: { top: 1, bottom: 1 }, color: { top: ColorToken.border_light, bottom: ColorToken.border_light } })
      .backgroundColor(ColorToken.panel)
      .alignItems(VerticalAlign.Center)

      if (this.showBlendPopup) {
        Scroll() {
          Column() {
            ForEach(this.blendOptions, (opt: BlendModeOption) => {
              Row() {
                Text(opt.label)
                  .fontSize(12)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.body)
                Blank()
                if (this.activeBlendMode() === opt.value) {
                  Text(Icon.check)
                    .fontSize(10)
                    .fontColor(ColorToken.primary)
                }
              }
              .width('100%')
              .height(28)
              .padding({ left: 12, right: 12 })
              .backgroundColor(this.hoveredRow === 'blend_' + opt.value ? ColorToken.hover_bg : Color.Transparent)
              .alignItems(VerticalAlign.Center)
              .onHover((isHover: boolean) => { this.hoveredRow = isHover ? 'blend_' + opt.value : '' })
              .onClick(() => { this.applyBlendMode(opt.value) })
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
        .shadow({ radius: 12, color: '#0000002E', offsetX: 0, offsetY: 4 })
        .zIndex(100)
      }

      // ─── Search bar ───
      Row() {
        Text(Icon.search)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 6 })
        TextInput({ text: this.searchText, placeholder: '\u7b5b\u9009\u56fe\u5c42...' })
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((val: string) => { this.searchText = val })
        Text(Icon.sliders)
          .fontSize(10)
          .fontColor(ColorToken.muted)
          .padding(2)
        Text(Icon.filter)
          .fontSize(10)
          .fontColor(ColorToken.muted)
          .padding(2)
          .margin({ left: 2 })
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .alignItems(VerticalAlign.Center)


      // ─── Layer list ───
      Scroll() {
        Column() {
          ForEach(this.filteredRows(), (layer: LayerRow, li: number) => {
            this.layerRow(layer, li)
          })
        }
        .width('100%')
      }
      .constraintSize({ maxHeight: 220 })
      .scrollBar(BarState.Off)

      // ─── Bottom toolbar ───
      Row() {
        Row() {
          Text(Icon.link)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'link' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'link' : '' })
          Text(Icon.layers)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'fx' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'fx' : '' })
          Text(Icon.circle)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'mask' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'mask' : '' })
          Column()
            .width(1)
            .height(16)
            .backgroundColor(ColorToken.border)
            .margin({ left: 4, right: 4 })
          Text(Icon.droplet)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'adjust' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'adjust' : '' })
          Text(Icon.folder)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'newGroup' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'newGroup' : '' })
          Text(Icon.plus)
            .fontSize(11)
            .fontColor(this.hoveredTool === 'newLayer' ? ColorToken.primary : ColorToken.tertiary)
            .padding(6)
            .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'newLayer' : '' })
        }
        .alignItems(VerticalAlign.Center)
        Blank()
        Text(Icon.trash)
          .fontSize(11)
          .fontColor(this.hoveredTool === 'delete' ? ColorToken.error : ColorToken.tertiary)
          .padding(6)
          .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'delete' : '' })
      }
      .width('100%')
      .height(40)
      .padding({ left: 8, right: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      .backgroundColor(ColorToken.panel)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  private activeBlendMode(): string {
    for (const r of this.flatLayers) {
      if (r.active) {
        return r.blendMode
      }
    }
    return 'normal'
  }

  private applyBlendMode(mode: string): void {
    for (let i = 0; i < this.flatLayers.length; i++) {
      if (this.flatLayers[i].active) {
        this.flatLayers[i] = this.copyRow(this.flatLayers[i])
        this.flatLayers[i].blendMode = mode
        break
      }
    }
    this.showBlendPopup = false
  }

  @Builder
  layerRow(layer: LayerRow, li: number): void {
    Row() {
      Row() {
        // Group chevron
        if (layer.isGroup) {
          Text(layer.expanded ? Icon.chevron_down : Icon.chevron_right)
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .onClick(() => { this.toggleGroupVisible() })
        }
        // Thumbnail
        Row() {
          if (layer.type === 'text') {
            Text(Icon.text)
              .fontSize(8)
              .fontColor(layer.active ? ColorToken.primary_dark_700 : ColorToken.muted)
          } else if (layer.type === 'group') {
            Text(Icon.folder)
              .fontSize(8)
              .fontColor(ColorToken.warning)
          } else if (layer.type === 'image') {
            Text(Icon.image)
              .fontSize(8)
              .fontColor(ColorToken.muted)
          } else if (layer.type === 'adjustment') {
            Text(Icon.circle)
              .fontSize(8)
              .fontColor(ColorToken.muted)
          } else if (layer.type === 'fill') {
            Text(Icon.droplet)
              .fontSize(8)
              .fontColor(ColorToken.muted)
          } else {
            Text(Icon.square)
              .fontSize(8)
              .fontColor(layer.iconColor === 'green' ? ColorToken.primary : ColorToken.border)
          }
        }
        .width(20)
        .height(20)
        .backgroundColor(layer.thumbColor === '' ? ColorToken.white : layer.thumbColor)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(2)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ left: layer.isGroup ? 2 : 0 })
        .constraintSize({ minWidth: 20, minHeight: 20 })

        // Mask thumbnail
        if (layer.hasMask) {
          Column() {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor(layer.maskEnabled ? '#E5E7EB' : ColorToken.border_light)
              .opacity(layer.maskEnabled ? 1 : 0.5)
          }
          .width(16)
          .height(16)
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(2)
          .margin({ left: -4 })
        }

        // Name
        Text(layer.name)
          .fontSize(10)
          .fontWeight(layer.active ? FontWeightConstant.semibold : FontWeightConstant.medium)
          .fontColor(layer.active ? ColorToken.primary_dark_700 : ColorToken.secondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 6 })
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minWidth: 0 })

      Row() {
        if (layer.linked) {
          Text(Icon.link)
            .fontSize(8)
            .fontColor(ColorToken.tertiary)
            .margin({ left: 4 })
        }
        if (layer.locked) {
          Text(Icon.lock)
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .onClick(() => { this.toggleLock(layer.key) })
            .margin({ left: 4 })
        }
        Text(layer.visible ? Icon.eye : Icon.eye_off)
          .fontSize(10)
          .fontColor(layer.visible ? ColorToken.tertiary : ColorToken.muted)
          .onClick(() => { this.toggleVisible(layer.key) })
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
      .padding({ left: 4, right: 4 })

    }
    .width('100%')
    .height(32)
    .padding({ left: 8 + layer.depth * 14, right: 8 })
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
    .backgroundColor(layer.active ? ColorToken.hover_bg : (this.hoveredRow === layer.key ? ColorToken.panel : Color.Transparent))
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.selectLayer(layer.key) })
    .onHover((isHover: boolean) => { this.hoveredRow = isHover ? layer.key : '' })
  }
}