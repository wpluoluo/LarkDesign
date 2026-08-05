/**
 * PagesPanel - 左侧页面/图层/资源面板
 *
 * 对应原型 src/components/PagesPanel.vue
 * 精准还原：Tab 头（44px + 下划线 60%） + 工具栏 + Frame 列表（54x72 缩略图）
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, HeightToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface FrameItemData {
  id: string
  name: string
  type: string
  width: number
  height: number
  layerCount: number
  hidden: boolean
  order?: number
}

interface LayerItemData {
  id: string
  name: string
  icon: string
  objCount: number
  selected: boolean
  locked: boolean
  visible: boolean
}

interface ResourceCategory {
  id: string
  label: string
  icon: string
  sourceLabel: string
  badgeColor: string
  badgeBg: string
  syncInfo: string
  count: number
  expanded: boolean
}

interface ResourceItem {
  id: string
  name: string
  type: string  // image | color | icon | file
  thumbColor: string  // 占位颜色（替代图片）
  icon: string  // icon/file 类型用
  color: string  // color 类型用
}

@Component
export struct PagesPanel {
  @State frames: FrameItemData[] = []
  @State selectedFrameId: string = ''
  @State activeTab: string = 'pages'
  @State layers: LayerItemData[] = []
  @State selectedLayerId: string = ''
  @State expandedCategory: string = 'cloud'
  @State hoveredTool: string = ''
  @State hoveredAsset: string = ''
  // Frames 模式开关（false 显示空状态）
  @State isFramesMode: boolean = true
  // Frame 重命名
  @State renamingFrameId: string = ''
  @State renamingFrameName: string = ''
  // Layer 重命名
  @State renamingLayerId: string = ''
  @State renamingLayerName: string = ''
  // Frame/Layer hover 状态
  @State hoveredFrame: string = ''
  @State hoveredLayer: string = ''

  private cloudItems: ResourceItem[] = [
    { id: 'c1', name: '品牌背景.jpg', type: 'image', thumbColor: '#1E3A8A', icon: '', color: '' },
    { id: 'c2', name: '纹理.png', type: 'image', thumbColor: '#0E7490', icon: '', color: '' },
    { id: 'c3', name: '项目图标集', type: 'icon', thumbColor: '', icon: Icon.grid, color: '' },
    { id: 'c4', name: '配色方案.hpal', type: 'color', thumbColor: '', icon: '', color: '#3AC487' },
    { id: 'c5', name: '海报模板.hds', type: 'icon', thumbColor: '', icon: Icon.file, color: '' },
    { id: 'c6', name: '插图.ai', type: 'image', thumbColor: '#7C3AED', icon: '', color: '' },
  ]
  private localItems: ResourceItem[] = [
    { id: 'l1', name: '产品照片.png', type: 'image', thumbColor: '#7C3AED', icon: '', color: '' },
    { id: 'l2', name: 'Logo 源文件.svg', type: 'icon', thumbColor: '', icon: Icon.code, color: '' },
    { id: 'l3', name: '企业色板.ase', type: 'color', thumbColor: '', icon: '', color: '#1E40AF' },
    { id: 'l4', name: '人物抠图.png', type: 'image', thumbColor: '#059669', icon: '', color: '' },
    { id: 'l5', name: '字体包.zip', type: 'icon', thumbColor: '', icon: Icon.folder, color: '' },
    { id: 'l6', name: '背景素材.jpg', type: 'image', thumbColor: '#0E7490', icon: '', color: '' },
  ]
  private agentItems: ResourceItem[] = [
    { id: 'a1', name: 'AI 封面图.png', type: 'image', thumbColor: '#8B5CF6', icon: '', color: '' },
    { id: 'a2', name: 'AI 调色方案', type: 'color', thumbColor: '', icon: '', color: '#F472B6' },
    { id: 'a3', name: 'AI 生成文案.txt', type: 'icon', thumbColor: '', icon: Icon.file, color: '' },
    { id: 'a4', name: 'AI 图标集', type: 'icon', thumbColor: '', icon: Icon.wand, color: '' },
  ]
  private builtinItems: ResourceItem[] = [
    { id: 'b1', name: '系统图标', type: 'icon', thumbColor: '', icon: Icon.star, color: '' },
    { id: 'b2', name: '基本色板', type: 'color', thumbColor: '', icon: '', color: '#EF4444' },
    { id: 'b3', name: '基础形状', type: 'icon', thumbColor: '', icon: Icon.rect, color: '' },
    { id: 'b4', name: '渐变预设', type: 'color', thumbColor: '', icon: '', color: '#8B5CF6' },
    { id: 'b5', name: '图案填充', type: 'icon', thumbColor: '', icon: Icon.grid_view, color: '' },
    { id: 'b6', name: '笔刷预设', type: 'icon', thumbColor: '', icon: Icon.pen, color: '' },
  ]

  private getCategoryItems(id: string): ResourceItem[] {
    if (id === 'cloud') return this.cloudItems
    if (id === 'local') return this.localItems
    if (id === 'agent') return this.agentItems
    return this.builtinItems
  }

  aboutToAppear(): void {
    this.frames = [
      { id: 'f1', name: '页面 1', type: 'single', width: 595, height: 842, layerCount: 3, hidden: false, order: 1 },
      { id: 'f2', name: '页面 2', type: 'single', width: 595, height: 842, layerCount: 2, hidden: false, order: 2 },
      { id: 'f3', name: '海报', type: 'poster', width: 420, height: 594, layerCount: 5, hidden: false },
      { id: 'f4', name: '隐藏页', type: 'single', width: 595, height: 842, layerCount: 1, hidden: true },
    ]
    this.selectedFrameId = 'f1'

    this.layers = [
      { id: 'l1', name: '背景层', icon: Icon.grid, objCount: 3, selected: false, locked: true, visible: true },
      { id: 'l2', name: '图形', icon: Icon.rect, objCount: 5, selected: true, locked: false, visible: true },
      { id: 'l3', name: '文字', icon: Icon.text, objCount: 2, selected: false, locked: false, visible: true },
      { id: 'l4', name: '图片', icon: Icon.image, objCount: 1, selected: false, locked: false, visible: false },
    ]
    this.selectedLayerId = 'l2'
  }

  build(): void {
    Column() {
      // Tab 头（Pages / Layers / Assets）
      Row() {
        this.tabButton('pages', '页面')
        this.tabButton('layers', '图层')
        this.tabButton('assets', '资源')
      }
      .width('100%')
      .height(HeightToken.xl)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
      .backgroundColor(ColorToken.white)

      if (this.activeTab === 'pages') {
        this.pagesTab()
      } else if (this.activeTab === 'layers') {
        this.layersTab()
      } else {
        this.assetsTab()
      }
    }
    .width(LayoutToken.pages_panel_width)
    .height('100%')
    .backgroundColor(ColorToken.white)
    .border({ width: { right: 1 }, color: { right: ColorToken.border } })
  }

  @Builder
  tabButton(id: string, label: string): void {
    Column() {
      Text(label)
        .fontSize(FontSizeToken.level3)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(this.activeTab === id ? ColorToken.primary_dark_700 : ColorToken.muted)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      // 下划线指示器（60% 宽度）
      Column()
        .width('60%')
        .height(2)
        .backgroundColor(this.activeTab === id ? ColorToken.primary : Color.Transparent)
        .borderRadius({ topLeft: 2, topRight: 2 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.End)
    .onClick(() => { this.activeTab = id })
  }

  @Builder
  pagesTab(): void {
    Column() {
      // 工具栏
      Row() {
        // 新建按钮
        this.toolbarIcon(Icon.plus, 'add', 10, false)
        // 复制按钮（无选中时 disabled）
        this.toolbarIcon(Icon.copy, 'dup', 10, !this.selectedFrameId)
        // 分隔符
        Column()
          .width(1)
          .height(14)
          .backgroundColor(ColorToken.border)
          .margin({ left: 6, right: 6 })
        // 上移（第一个或无选中时 disabled）
        this.toolbarIcon(Icon.arrow_up, 'up', 9, !this.selectedFrameId || this.frames.findIndex(f => f.id === this.selectedFrameId) <= 0)
        // 下移（最后一个或无选中时 disabled）
        this.toolbarIcon(Icon.arrow_down, 'down', 9, !this.selectedFrameId || this.frames.findIndex(f => f.id === this.selectedFrameId) >= this.frames.length - 1)
        Blank()
        Text(`${this.frames.length} 板`)
          .fontSize(9)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .height(36)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

      // 非 Frames 模式：空状态提示
      if (!this.isFramesMode) {
        this.framesEmptyState()
      } else {
        // Frame 列表
        Scroll() {
          Column() {
            ForEach(this.frames, (frame: FrameItemData, idx?: number) => {
              this.frameItem(frame, (idx ?? 0) + 1)
            })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 非 Frames 模式空状态（原型：file-circle-plus + 提示 + 启用按钮）
  @Builder
  framesEmptyState(): void {
    Column() {
      Text(Icon.file)
        .fontSize(28)
        .fontColor(ColorToken.muted)
        .opacity(0.5)
      Text('当前文档未启用画板模式\n启用以使用无限画布')
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .textAlign(TextAlign.Center)
        .margin({ top: 10 })
      Row() {
        Text(Icon.plus)
          .fontSize(9)
          .fontColor(ColorToken.white)
          .margin({ right: 4 })
        Text('启用画板模式')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.white)
      }
      .height(26)
      .padding({ left: 12, right: 12 })
      .backgroundColor(ColorToken.primary)
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10 })
      .onClick(() => { this.isFramesMode = true })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 12, right: 12, top: 24, bottom: 24 })
  }

  @Builder
  toolbarIcon(icon: string, id: string, fontSize: number, disabled: boolean = false): void {
    Column() {
      Text(icon)
        .fontSize(fontSize)
        .fontColor(disabled ? ColorToken.muted : (this.hoveredTool === id ? ColorToken.primary : ColorToken.secondary))
        .textAlign(TextAlign.Center)
    }
    .width(22)
    .height(22)
    .borderRadius(RadiusToken.sm)
    .backgroundColor(!disabled && this.hoveredTool === id ? ColorToken.border_light : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: 2, right: 2 })
    .opacity(disabled ? 0.4 : 1)
    .onHover((isHover: boolean) => { this.hoveredTool = isHover && !disabled ? id : '' })
    .onClick(() => {
      if (disabled) return
      if (id === 'add') this.addFrame()
      else if (id === 'dup') this.duplicateFrame()
      else if (id === 'layer-add') this.addLayer()
      else if (id === 'layer-dup') this.duplicateLayer()
      else if (id === 'layer-del') this.deleteLayer()
      else if (id === 'up') this.moveFrame(-1)
      else if (id === 'down') this.moveFrame(1)
      else if (id === 'layer-up') this.moveLayer(-1)
      else if (id === 'layer-down') this.moveLayer(1)
    })
  }

  @Builder
  frameItem(frame: FrameItemData, index: number): void {
    Row() {
      // 序号
      Text(`${index}`)
        .fontSize(10)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(this.selectedFrameId === frame.id ? ColorToken.primary_dark_700 : ColorToken.muted)
        .width(16)
        .textAlign(TextAlign.Center)

      // 缩略图（54x72 精细还原原型）
      Column() {
        // 顶部行：图标 + 页码
        Row() {
          Text(this.frameTypeIcon(frame.type))
            .fontSize(7)
            .fontColor(this.selectedFrameId === frame.id ? ColorToken.primary : ColorToken.muted)
          Blank()
          if (frame.type === 'book-page' && frame.order) {
            Text(`P${frame.order}`)
              .fontSize(6)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
          }
        }
        .width('100%')

        Blank()

        // 中间内容：3条线（28x2 + 40x28 + 16x4）
        Column() {
          Row()
            .width(28)
            .height(2)
            .backgroundColor(ColorToken.border_light)
            .borderRadius(1)
            .margin({ bottom: 2 })
          Row()
            .width(40)
            .height(28)
            .backgroundColor(ColorToken.panel)
            .borderRadius(1)
            .margin({ bottom: 2 })
          Row()
            .width(16)
            .height(4)
            .backgroundColor(ColorToken.primary_light_300)
            .borderRadius(1)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 4 })

        Blank()

        // 隐藏标记
        if (frame.hidden) {
          Row() {
            Text('隐')
              .fontSize(6)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
          }
          .backgroundColor('#FFFFFFCC')
          .padding({ left: 2, right: 2 })
          .borderRadius(1)
          .position({ x: 42, y: 2 })
        }
      }
      .width(54)
      .height(72)
      .backgroundColor(ColorToken.white)
      .border({
        width: 2,
        color: this.selectedFrameId === frame.id ? ColorToken.primary : ColorToken.border,
      })
      .borderRadius(3)
      .padding(5)
      .margin({ left: 8 })

      // 名称与信息
      Column() {
        // 重命名 input / 显示文本
        if (this.renamingFrameId === frame.id) {
          TextInput({ text: this.renamingFrameName })
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .backgroundColor(ColorToken.white)
            .border({ width: 1, color: ColorToken.primary })
            .borderRadius(3)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .width('100%')
            .height(18)
            .onChange((val: string) => { this.renamingFrameName = val })
            .onSubmit(() => { this.commitRenameFrame() })
            .onBlur(() => { this.commitRenameFrame() })
        } else {
          Text(frame.name)
            .fontSize(FontSizeToken.level2)
            .fontWeight(this.selectedFrameId === frame.id ? FontWeightConstant.semibold : FontWeightConstant.medium)
            .fontColor(this.selectedFrameId === frame.id ? ColorToken.body : ColorToken.tertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
        Text(`${frame.layerCount} 图层`)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ top: 2 })
        Text(`${frame.width}×${frame.height}`)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ top: 1 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 })

      // 隐藏图标
      if (frame.hidden) {
        Text(Icon.eye_off)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 4 })
      }
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .backgroundColor(this.selectedFrameId === frame.id ? ColorToken.hover_bg : (this.hoveredFrame === frame.id ? ColorToken.panel : Color.Transparent))
    .border({
      width: { left: 3 },
      color: { left: this.selectedFrameId === frame.id ? ColorToken.primary : Color.Transparent }
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectedFrameId = frame.id
    })
    .onHover((isHover: boolean) => { this.hoveredFrame = isHover ? frame.id : '' })
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          this.startRenameFrame(frame.id, frame.name)
        })
    )
  }

  @Builder
  layersTab(): void {
    Column() {
      // 工具栏（标题显示当前 Frame 名称：图层 · 页面 X）
      Row() {
        Text(`图层${this.selectedFrameId ? ` · ${this.frames.find(f => f.id === this.selectedFrameId)?.name ?? ''}` : ''}`)
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
        Blank()
        this.toolbarIcon(Icon.plus, 'layer-add', 10, false)
        this.toolbarIcon(Icon.copy, 'layer-dup', 9, !this.selectedLayerId)
        this.toolbarIcon(Icon.trash, 'layer-del', 9, !this.selectedLayerId)
        Column()
          .width(1)
          .height(12)
          .backgroundColor(ColorToken.border)
          .margin({ left: 4, right: 4 })
        this.toolbarIcon(Icon.arrow_up, 'layer-up', 9, !this.selectedLayerId || this.layers.findIndex(l => l.id === this.selectedLayerId) <= 0)
        this.toolbarIcon(Icon.arrow_down, 'layer-down', 9, !this.selectedLayerId || this.layers.findIndex(l => l.id === this.selectedLayerId) >= this.layers.length - 1)
      }
      .width('100%')
      .height(36)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

      // 图层列表 / 空状态
      if (this.layers.length === 0) {
        this.layersEmptyState()
      } else {
        Scroll() {
          Column() {
            ForEach(this.layers, (layer: LayerItemData) => {
              this.layerItem(layer)
            })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }

      // 底部状态
      Row() {
        Text(`${this.layers.length} 个图层`)
          .fontSize(9)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
        Blank()
        if (this.selectedLayerId) {
          Text('已选: 1')
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
      }
      .width('100%')
      .height(24)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 图层空状态（原型：layer-group 图标 + 暂无图层 + 新建按钮）
  @Builder
  layersEmptyState(): void {
    Column() {
      Text(Icon.layers)
        .fontSize(20)
        .fontColor(ColorToken.muted)
        .opacity(0.5)
      Text('暂无图层')
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .margin({ top: 8 })
      Row() {
        Text('新建图层')
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.white)
      }
      .height(24)
      .padding({ left: 10, right: 10 })
      .backgroundColor(ColorToken.primary)
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .onClick(() => { this.addLayer() })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 40, bottom: 40 })
  }

  @Builder
  layerItem(layer: LayerItemData): void {
    Row() {
      // 缩略图（20x20 圆角3 + 边框，原型：gap-[6px] 由后续 margin 实现）
      Column() {
        Text(layer.icon)
          .fontSize(9)
          .fontColor(layer.selected ? ColorToken.primary_dark_700 : ColorToken.muted)
      }
      .width(20)
      .height(20)
      .borderRadius(3)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: ColorToken.border_light })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .opacity(layer.visible ? 1 : 0.3)

      // 名称（gap-[6px]）— 重命名 input / 显示文本
      if (this.renamingLayerId === layer.id) {
        TextInput({ text: this.renamingLayerName })
          .fontSize(FontSizeToken.level2)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.primary })
          .borderRadius(3)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .height(18)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onChange((val: string) => { this.renamingLayerName = val })
          .onSubmit(() => { this.commitRenameLayer() })
          .onBlur(() => { this.commitRenameLayer() })
      } else {
        Text(layer.name)
          .fontSize(FontSizeToken.level2)
          .fontWeight(layer.selected ? FontWeightConstant.semibold : FontWeightConstant.regular)
          .fontColor(layer.selected ? ColorToken.body : ColorToken.secondary)
          .margin({ left: 6 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 对象数
      Text(`${layer.objCount}`)
        .fontSize(8)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .margin({ right: 6 })

      // 锁定图标（group-hover 显示：未锁定时仅在 hover 时显示）
      Text(Icon.lock)
        .fontSize(8)
        .fontColor(layer.locked ? ColorToken.primary_dark_700 : ColorToken.muted)
        .margin({ right: 4 })
        .opacity(layer.locked || this.hoveredLayer === layer.id ? 1 : 0)
        .borderRadius(2)
        .padding(2)
        .onClick(() => { this.toggleLayerLock(layer.id) })

      // 可见性图标
      Text(layer.visible ? Icon.eye : Icon.eye_off)
        .fontSize(9)
        .fontColor(layer.visible ? ColorToken.muted : ColorToken.error)
        .margin({ right: 10 })
        .borderRadius(2)
        .padding(2)
        .onClick(() => { this.toggleLayerVisible(layer.id) })
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 7, bottom: 7 })
    .backgroundColor(layer.selected ? ColorToken.hover_bg : (this.hoveredLayer === layer.id ? ColorToken.panel : Color.Transparent))
    .border({
      width: { left: 3 },
      color: { left: layer.selected ? ColorToken.primary : Color.Transparent }
    })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectedLayerId = layer.id
      this.layers = this.layers.map((l: LayerItemData): LayerItemData => {
        const item: LayerItemData = {
          id: l.id,
          name: l.name,
          icon: l.icon,
          objCount: l.objCount,
          selected: l.id === layer.id,
          locked: l.locked,
          visible: l.visible,
        }
        return item
      })
    })
    .onHover((isHover: boolean) => { this.hoveredLayer = isHover ? layer.id : '' })
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          this.startRenameLayer(layer.id, layer.name)
        })
    )
  }

  @Builder
  assetsTab(): void {
    Column() {
      // 标题栏（原型：text-[11px] font-[600]）
      Row() {
        Text('资源管理器')
          .fontSize(11)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
        Blank()
        this.toolbarIcon(Icon.import, 'asset-import', 9, false)
        this.toolbarIcon(Icon.refresh, 'asset-refresh', 9, false)
      }
      .width('100%')
      .height(36)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })

      // 搜索框（原型：input type="text" placeholder="搜索所有资源..."）
      Row() {
        Text(Icon.search)
          .fontSize(8)
          .fontColor(ColorToken.muted)
        TextInput({ placeholder: '搜索所有资源...' })
          .fontSize(9)
          .fontColor(ColorToken.body)
          .placeholderColor('#9AA2AC')
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .margin({ left: 6 })
      }
      .width('90%')
      .height(28)
      .borderRadius(RadiusToken.sm)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: ColorToken.border })
      .padding({ left: 8, right: 8 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })

      // 资源分类卡片（原型：flex flex-col gap-[6px] px-[8px] py-[6px]）
      Scroll() {
        Column() {
          this.resourceCategory('cloud', '云端资源', Icon.cloud, '来源 · 用户云端', '#3B82F6', '#DBEAFE', '已同步 2026-07-19', 18, true)
          this.resourceCategory('local', '本地导入', Icon.folder_open, '来源 · 本机文件', '#F59E0B', '#FEF3C7', '最后导入: 2026-07-18', 12, true)
          this.resourceCategory('agent', '智能体生成', Icon.wand, '来源 · AI 创作引擎', '#8B5CF6', '#EDE9FE', '缓存 12 个', 8, false)
          this.resourceCategory('builtin', '内置素材', Icon.cube, '来源 · 系统预设', '#6B7280', '#F3F4F6', '只读', 24, false)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  resourceCategory(id: string, label: string, icon: string, source: string, badgeColor: string, badgeBg: string, syncInfo: string, count: number, expanded: boolean): void {
    Column() {
      // 分类头（原型：h-32 px-8 hover:bg-panel）
      Row() {
        Text(icon)
          .fontSize(9)
          .fontColor(ColorToken.secondary)
        Text(label)
          .fontSize(10)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
          .margin({ left: 6 })
        Text(`${count}`)
          .fontSize(8)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ left: 6 })
        Blank()
        Text(this.expandedCategory === id ? Icon.chevron_down : Icon.chevron_right)
          .fontSize(7)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .height(32)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.hoveredTool === `cat_${id}` ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.expandedCategory = this.expandedCategory === id ? '' : id })
      .onHover((isHover: boolean) => { this.hoveredTool = isHover ? `cat_${id}` : '' })

      // 内容区
      if (this.expandedCategory === id) {
        Column() {
          // 来源徽章
          Row() {
            Text(source)
              .fontSize(7)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(badgeColor)
              .backgroundColor(badgeBg)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(3)
            Text(syncInfo)
              .fontSize(7)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .width('100%')
          .margin({ bottom: 6 })

          // 资源网格（3列 × N 行）
          Grid() {
            ForEach(this.getCategoryItems(id), (item: ResourceItem) => {
              GridItem() {
                this.resourceTile(item)
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsGap(4)
          .columnsGap(4)
          .width('100%')
        }
        .padding(8)
        .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      }
    }
    .width('100%')
    .border({ width: 1, color: ColorToken.border })
    .borderRadius(RadiusToken.md)
    .margin({ top: 6 })
    .clip(true)
  }

  @Builder
  resourceTile(item: ResourceItem): void {
    Column() {
      // 缩略图（原型：aspect-square，固定 60x60）
      Stack({ alignContent: Alignment.Center }) {
        // 背景层（按类型填充）
        if (item.type === 'image') {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(item.thumbColor)
          Text(Icon.image)
            .fontSize(10)
            .fontColor(ColorToken.white)
        } else if (item.type === 'color') {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(item.color)
        } else if (item.type === 'icon') {
          Text(item.icon)
            .fontSize(14)
            .fontColor(ColorToken.secondary)
        } else {
          Text(item.icon)
            .fontSize(14)
            .fontColor(ColorToken.muted)
        }

        // Hover 黑色遮罩（始终渲染，用 opacity 控制）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#0000001A')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .opacity(this.hoveredAsset === item.id ? 1 : 0)

        // Hover "+" 图标（始终渲染，用 opacity 控制）
        Text(Icon.plus)
          .fontSize(10)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.white)
          .opacity(this.hoveredAsset === item.id ? 1 : 0)
      }
      .width('100%')
      .height(60)
      .backgroundColor(item.type === 'image' || item.type === 'color' ? Color.Transparent : ColorToken.panel)
      .border({ width: 1, color: ColorToken.border })
      .borderRadius(3)
      .clip(true)
      .onHover((isHover: boolean) => { this.hoveredAsset = isHover ? item.id : '' })

      Text(item.name)
        .fontSize(7)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 3 })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .padding(4)
    .borderRadius(4)
    .backgroundColor(this.hoveredAsset === item.id ? ColorToken.panel : Color.Transparent)
  }

  private addFrame(): void {
    const newId = `f${this.frames.length + 1}_${Date.now()}`
    const newFrame: FrameItemData = {
      id: newId, name: `页面 ${this.frames.length + 1}`, type: 'single',
      width: 595, height: 842, layerCount: 0, hidden: false,
    }
    this.frames = [...this.frames, newFrame]
    this.selectedFrameId = newId
  }

  private duplicateFrame(): void {
    const src = this.frames.find(f => f.id === this.selectedFrameId)
    if (!src) return
    const newId = `${src.id}_copy`
    const copy: FrameItemData = {
      id: newId, name: `${src.name} 副本`, type: src.type,
      width: src.width, height: src.height, layerCount: src.layerCount, hidden: false,
    }
    const idx = this.frames.findIndex(f => f.id === src.id)
    const newList = [...this.frames]
    newList.splice(idx + 1, 0, copy)
    this.frames = newList
    this.selectedFrameId = newId
  }

  /** 移动 Frame 顺序（-1 上移，+1 下移） */
  private moveFrame(direction: number): void {
    if (!this.selectedFrameId) return
    const cur = this.frames.findIndex(f => f.id === this.selectedFrameId)
    if (cur < 0) return
    const target = cur + direction
    if (target < 0 || target >= this.frames.length) return
    const tmp = this.frames[cur]
    this.frames[cur] = this.frames[target]
    this.frames[target] = tmp
    this.frames = [...this.frames]
  }

  // ─── Frame 重命名 ───
  private startRenameFrame(id: string, name: string): void {
    this.renamingFrameId = id
    this.renamingFrameName = name
  }

  private commitRenameFrame(): void {
    if (!this.renamingFrameId) return
    const newName = this.renamingFrameName.trim()
    if (newName) {
      const idx = this.frames.findIndex(f => f.id === this.renamingFrameId)
      if (idx >= 0) {
        this.frames[idx] = {
          id: this.frames[idx].id, name: newName, type: this.frames[idx].type,
          width: this.frames[idx].width, height: this.frames[idx].height,
          layerCount: this.frames[idx].layerCount, hidden: this.frames[idx].hidden,
          order: this.frames[idx].order,
        }
        this.frames = [...this.frames]
      }
    }
    this.renamingFrameId = ''
    this.renamingFrameName = ''
  }

  private cancelRenameFrame(): void {
    this.renamingFrameId = ''
    this.renamingFrameName = ''
  }

  // ─── Layer 操作 ───
  private addLayer(): void {
    const newId = `l${this.layers.length + 1}_${Date.now()}`
    const newLayer: LayerItemData = {
      id: newId, name: `图层 ${this.layers.length + 1}`, icon: Icon.grid,
      objCount: 0, selected: true, locked: false, visible: true,
    }
    this.layers = [newLayer, ...this.layers.map((l: LayerItemData): LayerItemData => ({
      id: l.id, name: l.name, icon: l.icon, objCount: l.objCount,
      selected: false, locked: l.locked, visible: l.visible,
    }))]
    this.selectedLayerId = newId
  }

  private duplicateLayer(): void {
    if (!this.selectedLayerId) return
    const src = this.layers.find(l => l.id === this.selectedLayerId)
    if (!src) return
    const newId = `${src.id}_copy`
    const copy: LayerItemData = {
      id: newId, name: `${src.name} 副本`, icon: src.icon,
      objCount: src.objCount, selected: true, locked: false, visible: src.visible,
    }
    const idx = this.layers.findIndex(l => l.id === src.id)
    const newList = this.layers.map((l: LayerItemData): LayerItemData => ({
      id: l.id, name: l.name, icon: l.icon, objCount: l.objCount,
      selected: false, locked: l.locked, visible: l.visible,
    }))
    newList.splice(idx + 1, 0, copy)
    this.layers = newList
    this.selectedLayerId = newId
  }

  private deleteLayer(): void {
    if (!this.selectedLayerId) return
    this.layers = this.layers.filter(l => l.id !== this.selectedLayerId)
    this.selectedLayerId = ''
  }

  /** 移动 Layer 顺序（-1 上移，+1 下移） */
  private moveLayer(direction: number): void {
    if (!this.selectedLayerId) return
    const cur = this.layers.findIndex(l => l.id === this.selectedLayerId)
    if (cur < 0) return
    const target = cur + direction
    if (target < 0 || target >= this.layers.length) return
    const tmp = this.layers[cur]
    this.layers[cur] = this.layers[target]
    this.layers[target] = tmp
    this.layers = [...this.layers]
  }

  private toggleLayerLock(id: string): void {
    this.layers = this.layers.map((l: LayerItemData): LayerItemData => ({
      id: l.id, name: l.name, icon: l.icon, objCount: l.objCount,
      selected: l.selected, locked: l.id === id ? !l.locked : l.locked, visible: l.visible,
    }))
  }

  private toggleLayerVisible(id: string): void {
    this.layers = this.layers.map((l: LayerItemData): LayerItemData => ({
      id: l.id, name: l.name, icon: l.icon, objCount: l.objCount,
      selected: l.selected, locked: l.locked, visible: l.id === id ? !l.visible : l.visible,
    }))
  }

  // ─── Layer 重命名 ───
  private startRenameLayer(id: string, name: string): void {
    this.renamingLayerId = id
    this.renamingLayerName = name
  }

  private commitRenameLayer(): void {
    if (!this.renamingLayerId) return
    const newName = this.renamingLayerName.trim()
    if (newName) {
      this.layers = this.layers.map((l: LayerItemData): LayerItemData => ({
        id: l.id, name: l.id === this.renamingLayerId ? newName : l.name,
        icon: l.icon, objCount: l.objCount, selected: l.selected,
        locked: l.locked, visible: l.visible,
      }))
    }
    this.renamingLayerId = ''
    this.renamingLayerName = ''
  }

  private cancelRenameLayer(): void {
    this.renamingLayerId = ''
    this.renamingLayerName = ''
  }

  private frameTypeIcon(type: string): string {
    const icons: Record<string, string> = {
      'single': Icon.rect,
      'poster': Icon.rect,
      'book-page': Icon.grid,
      'multi': Icon.grid,
    }
    return icons[type] ?? Icon.rect
  }
}
