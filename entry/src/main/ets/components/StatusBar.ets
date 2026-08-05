/**
 * StatusBar - 底部状态栏
 *
 * 对应原型 src/components/StatusBar.vue
 * 精准还原：主题切换 + 色彩空间/文档尺寸/页码3个chevron可点击项 + ColorBar + 同步状态 + 缩放控件
 * 弹窗交互：色彩空间/文档尺寸/图层列表 + 自定义尺寸输入 + 约束比例
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, HeightToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface ColorSwatch {
  name: string
  hex: string
}

interface LayerRow {
  id: string
  name: string
  visible: boolean
  locked: boolean
  objectCount: number
}

interface DocSizeOption {
  label: string
  size: string
}

@Component
export struct StatusBar {
  @State zoom: number = 82
  @State activePopup: string = ''
  @State hoveredBtn: string = ''
  @State hoveredSwatch: string = ''
  @State hoveredPopupItem: string = ''
  @StorageLink('currentTheme') currentTheme: string = 'light'

  // 文档信息
  @State colorSpace: string = 'sRGB IEC61966-2.1'
  @State documentSize: string = '210 × 297 mm'
  @State pageInfo: string = '未选中 · 1 图层'

  // 同步状态
  @StorageLink('hds_save_status') syncText: string = '已同步'
  @StorageLink('hds_last_saved') lastSaved: string = ''

  // 自定义尺寸
  @State customWidth: string = '210'
  @State customHeight: string = '297'
  @State customUnit: string = 'mm'
  @State constrainProportions: boolean = false
  @State hoveredAction: string = ''

  // 色板（原型：最近6色 + 常用6色 + 添加按钮 + 当前色）
  private recentColors: ColorSwatch[] = [
    { name: 'rc1', hex: '#3AC487' },
    { name: 'rc2', hex: '#16865F' },
    { name: 'rc3', hex: '#3B82F6' },
    { name: 'rc4', hex: '#EF4444' },
    { name: 'rc5', hex: '#F59E0B' },
    { name: 'rc6', hex: '#8B5CF6' },
  ]

  private commonColors: ColorSwatch[] = [
    { name: 'cc1', hex: '#EC4899' },
    { name: 'cc2', hex: '#14B8A6' },
    { name: 'cc3', hex: '#6B7280' },
    { name: 'cc4', hex: '#FF6B6B' },
    { name: 'cc5', hex: '#4ECDC4' },
    { name: 'cc6', hex: '#45B7D1' },
  ]

  // 当前选中色
  @State currentHex: string = '#3AC487'

  // 色彩空间选项
  private colorSpaceOptions: string[] = [
    'sRGB IEC61966-2.1',
    'Adobe RGB (1998)',
    'Display P3',
    'CMYK Coated FOGRA39',
    'CMYK Uncoated FOGRA29',
    'ProPhoto RGB',
    'Apple RGB',
  ]

  // 文档尺寸选项（带副标题）
  private docSizeOptions: DocSizeOption[] = [
    { label: 'A4', size: '210 × 297 mm' },
    { label: 'A3', size: '297 × 420 mm' },
    { label: 'A5', size: '148 × 210 mm' },
    { label: '信纸', size: '215.9 × 279.4 mm' },
    { label: '法律', size: '215.9 × 355.6 mm' },
    { label: '名片', size: '90 × 54 mm' },
    { label: '海报', size: '420 × 594 mm' },
    { label: '横幅', size: '594 × 210 mm' },
  ]

  // 图层列表数据
  @State layers: LayerRow[] = [
    { id: 'l1', name: '背景层', visible: true, locked: true, objectCount: 3 },
    { id: 'l2', name: '图形层', visible: true, locked: false, objectCount: 5 },
    { id: 'l3', name: '文字层', visible: true, locked: false, objectCount: 2 },
    { id: 'l4', name: '图片层', visible: false, locked: false, objectCount: 1 },
  ]
  @State selectedLayerId: string = 'l2'

  private unitOptions: string[] = ['mm', 'cm', 'px', 'pt', 'in']

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        // ─── 左侧 ───
        Row() {
          // 主题切换（palette 图标 + 主题名 + chevron，模仿 ThemePicker）
          Row() {
            Text(Icon.palette)
              .fontSize(10)
              .fontColor(ColorToken.tertiary)
            Text(this.currentTheme === 'dark' ? '暗色' : '亮色')
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.tertiary)
              .margin({ left: 4 })
            Text(Icon.chevron_down)
              .fontSize(6)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(3)
          .backgroundColor(this.hoveredBtn === 'theme' ? ColorToken.border_light : Color.Transparent)
          .alignItems(VerticalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'theme' : '' })
          .onClick(() => {
            this.currentTheme = this.currentTheme === 'dark' ? 'light' : 'dark'
            AppStorage.setOrCreate<string>('currentTheme', this.currentTheme)
          })

          // 色彩空间（可点击 + chevron）
          Row() {
            Text(this.colorSpace)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.tertiary)
            Text(Icon.chevron_down)
              .fontSize(6)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(3)
          .backgroundColor(this.activePopup === 'colorSpace'
            ? ColorToken.hover_bg
            : (this.hoveredBtn === 'colorSpace' ? ColorToken.border_light : Color.Transparent))
          .alignItems(VerticalAlign.Center)
          .margin({ left: 16 })
          .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'colorSpace' : '' })
          .onClick(() => { this.activePopup = this.activePopup === 'colorSpace' ? '' : 'colorSpace' })

          // 文档尺寸（可点击 + chevron）
          Row() {
            Text(this.documentSize)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.tertiary)
            Text(Icon.chevron_down)
              .fontSize(6)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(3)
          .backgroundColor(this.activePopup === 'docSize'
            ? ColorToken.hover_bg
            : (this.hoveredBtn === 'docSize' ? ColorToken.border_light : Color.Transparent))
          .alignItems(VerticalAlign.Center)
          .margin({ left: 16 })
          .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'docSize' : '' })
          .onClick(() => { this.activePopup = this.activePopup === 'docSize' ? '' : 'docSize' })

          // 页码（可点击 + chevron）
          Row() {
            Text(this.pageInfo)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.tertiary)
            Text(Icon.chevron_down)
              .fontSize(6)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(3)
          .backgroundColor(this.activePopup === 'pageInfo'
            ? ColorToken.hover_bg
            : (this.hoveredBtn === 'pageInfo' ? ColorToken.border_light : Color.Transparent))
          .alignItems(VerticalAlign.Center)
          .margin({ left: 16 })
          .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'pageInfo' : '' })
          .onClick(() => { this.activePopup = this.activePopup === 'pageInfo' ? '' : 'pageInfo' })
        }

        Blank()

        // ─── 右侧 ───
        Row() {
          // ColorBar 色板（原型：最近6色 + 分隔符 + 常用6色 + 添加按钮 + 当前色显示）
          Row() {
            // "最近" 标签
            Text('最近')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .width(36)
              .margin({ right: 6 })

            // 最近使用 6 色
            ForEach(this.recentColors, (s: ColorSwatch) => {
              Column()
                .width(18)
                .height(18)
                .borderRadius(3)
                .backgroundColor(s.hex)
                .border({
                  width: 1,
                  color: ColorToken.border,
                })
                .margin({ right: 6 })
                .onHover((isHover: boolean) => {
                  this.hoveredSwatch = isHover ? s.name : ''
                  if (isHover) this.currentHex = s.hex
                })
            })

            // 分隔符（原型：mx-[2px]）
            Column()
              .width(1)
              .height(16)
              .backgroundColor(ColorToken.border)
              .margin({ left: 2, right: 2 })

            // "常用" 标签
            Text('常用')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .width(36)
              .margin({ right: 6 })

            // 常用 6 色
            ForEach(this.commonColors, (s: ColorSwatch) => {
              Column()
                .width(18)
                .height(18)
                .borderRadius(3)
                .backgroundColor(s.hex)
                .border({
                  width: 1,
                  color: ColorToken.border,
                })
                .margin({ right: 6 })
                .onHover((isHover: boolean) => {
                  this.hoveredSwatch = isHover ? s.name : ''
                  if (isHover) this.currentHex = s.hex
                })
            })

            // 添加到常用按钮（原型：18×18 圆角3，bg-panel + border + plus 图标）
            Column() {
              Text(Icon.plus)
                .fontSize(6)
                .fontColor(ColorToken.muted)
            }
            .width(18)
            .height(18)
            .borderRadius(3)
            .backgroundColor(this.hoveredSwatch === 'add' ? ColorToken.border_light : ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredSwatch = isHover ? 'add' : '' })

            // 占位
            Blank()

            // 当前选中色（原型：20×20 色块 + hex 文字）
            Row() {
              Column()
                .width(20)
                .height(20)
                .borderRadius(3)
                .backgroundColor(this.currentHex)
                .border({ width: 1, color: ColorToken.border })

              Text(this.currentHex.toUpperCase())
                .fontSize(9)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .margin({ left: 4 })
            }
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
            .borderRadius(3)
          }
          .height(28)
          .backgroundColor(ColorToken.white)
          .padding({ left: 8, right: 8 })
          .margin({ right: 16 })

          // 同步状态（原型：fa-circle-check 实心圆圈带勾，颜色 primary-dark-700）
          Row() {
            Stack() {
              Column()
                .width(10)
                .height(10)
                .borderRadius(5)
                .backgroundColor(ColorToken.primary_dark_700)
              Text(Icon.check)
                .fontSize(7)
                .fontColor(ColorToken.white)
            }
            .width(10)
            .height(10)
            Text(this.syncText)
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.primary_dark_700)
              .margin({ left: 6 })
          }
          .margin({ right: 16 })

          // 缩放控件
          Row() {
            // 减号
            Column() {
              Text(Icon.minus)
                .fontSize(9)
                .fontColor(this.hoveredBtn === 'zoomOut' ? ColorToken.body : ColorToken.tertiary)
            }
            .padding(3)
            .borderRadius(3)
            .backgroundColor(this.hoveredBtn === 'zoomOut' ? ColorToken.border_light : Color.Transparent)
            .onClick(() => { if (this.zoom > 10) this.zoom = Math.max(10, this.zoom - 5) })
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'zoomOut' : '' })

            // 进度条（原型：width: zoomPercent + '%'，hover 变深色）
            Row() {
              Row()
                .width(`${this.zoom}%`)
                .height('100%')
                .backgroundColor(this.hoveredBtn === 'zoomBar' ? ColorToken.primary_dark_700 : ColorToken.primary)
                .borderRadius(2)
            }
            .width(64)
            .height(4)
            .backgroundColor(ColorToken.border)
            .borderRadius(2)
            .margin({ left: 6, right: 6 })
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'zoomBar' : '' })
            .onClick(() => { this.zoom = 100 })

            // 加号
            Column() {
              Text(Icon.plus)
                .fontSize(9)
                .fontColor(this.hoveredBtn === 'zoomIn' ? ColorToken.body : ColorToken.tertiary)
            }
            .padding(3)
            .borderRadius(3)
            .backgroundColor(this.hoveredBtn === 'zoomIn' ? ColorToken.border_light : Color.Transparent)
            .onClick(() => { if (this.zoom < 400) this.zoom = Math.min(400, this.zoom + 5) })
            .onHover((isHover: boolean) => { this.hoveredBtn = isHover ? 'zoomIn' : '' })

            // 数值
            Text(`${this.zoom}%`)
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.body)
              .width(34)
              .textAlign(TextAlign.End)
              .margin({ left: 8 })
          }
        }
      }
      .width('100%')
      .height(LayoutToken.status_bar_height)
      .padding({ left: 12, right: 12 })
      .backgroundColor(ColorToken.panel)
      .border({ width: { top: 1 }, color: { top: ColorToken.border } })
      .alignItems(VerticalAlign.Center)

      // ─── 弹窗：色彩空间 ───
      if (this.activePopup === 'colorSpace') {
        this.colorSpacePopup()
      }

      // ─── 弹窗：文档尺寸（含自定义尺寸输入） ───
      if (this.activePopup === 'docSize' || this.activePopup === 'customSize') {
        this.docSizePopup()
      }

      // ─── 弹窗：图层列表 ───
      if (this.activePopup === 'pageInfo') {
        this.layerListPopup()
      }
    }
    .width('100%')
    .height(LayoutToken.status_bar_height)
  }

  // ─── 色彩空间弹窗 ───
  @Builder
  colorSpacePopup(): void {
    Column() {
      Text('色彩空间')
        .fontSize(9)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .width('100%')
        .padding({ left: 10, top: 4, bottom: 4 })
        .backgroundColor(ColorToken.panel)

      ForEach(this.colorSpaceOptions, (cs: string) => {
        Row() {
          Text(cs)
            .fontSize(11)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.colorSpace === cs ? ColorToken.primary_dark_700 : ColorToken.body)
            .layoutWeight(1)
          if (this.colorSpace === cs) {
            Text(Icon.check)
              .fontSize(9)
              .fontColor(ColorToken.primary)
          }
        }
        .width('100%')
        .height(28)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.colorSpace === cs
          ? ColorToken.hover_bg
          : (this.hoveredPopupItem === cs ? ColorToken.panel : Color.Transparent))
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredPopupItem = isHover ? cs : '' })
        .onClick(() => { this.colorSpace = cs; this.activePopup = '' })
      })
    }
    .width(200)
    .borderRadius(RadiusToken.xl)
    .backgroundColor(ColorToken.white)
    .border({ width: 1, color: ColorToken.border })
    .shadow(ShadowToken.xl)
    .position({ x: 80, y: -220 })
    .zIndex(ZIndexToken.dropdown)
  }

  // ─── 文档尺寸弹窗（含自定义尺寸输入区） ───
  @Builder
  docSizePopup(): void {
    Column() {
      Text('文档尺寸')
        .fontSize(9)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .width('100%')
        .padding({ left: 10, top: 4, bottom: 4 })
        .backgroundColor(ColorToken.panel)

      // 预设尺寸
      ForEach(this.docSizeOptions, (opt: DocSizeOption) => {
        Row() {
          Column() {
            Text(opt.label)
              .fontSize(11)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.documentSize === opt.size ? ColorToken.primary_dark_700 : ColorToken.body)
            Text(opt.size)
              .fontSize(8)
              .fontColor(ColorToken.muted)
              .margin({ top: 1 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (this.documentSize === opt.size) {
            Text(Icon.check)
              .fontSize(9)
              .fontColor(ColorToken.primary)
          }
        }
        .width('100%')
        .height(32)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.documentSize === opt.size
          ? ColorToken.hover_bg
          : (this.hoveredPopupItem === opt.label ? ColorToken.panel : Color.Transparent))
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredPopupItem = isHover ? opt.label : '' })
        .onClick(() => {
          this.documentSize = opt.size
          this.activePopup = ''
        })
      })

      // 分隔线
      Row()
        .width('80%')
        .height(1)
        .backgroundColor(ColorToken.border)
        .margin({ top: 4, bottom: 4 })

      // 自定义尺寸入口
      Row() {
        Text(Icon.plus)
          .fontSize(8)
          .fontColor(this.activePopup === 'customSize' ? ColorToken.primary : ColorToken.muted)
        Text('自定义尺寸')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(this.activePopup === 'customSize' ? ColorToken.primary : ColorToken.muted)
          .margin({ left: 4 })
      }
      .width('100%')
      .height(28)
      .padding({ left: 10, right: 10 })
      .backgroundColor(this.hoveredPopupItem === 'custom' ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onHover((isHover: boolean) => { this.hoveredPopupItem = isHover ? 'custom' : '' })
      .onClick(() => { this.activePopup = 'customSize' })

      // ─── 自定义尺寸输入区（仅 customSize 时显示） ───
      if (this.activePopup === 'customSize') {
        Column() {
          // 宽度行
          Row() {
            Text('宽')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor('#8B939D')
              .width(20)
            TextInput({ text: this.customWidth, placeholder: '210' })
              .type(InputType.Number)
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .height(22)
              .padding({ left: 4, right: 4 })
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .layoutWeight(1)
              .onChange((val: string) => {
                this.customWidth = val
                // 约束比例
                if (this.constrainProportions) {
                  const n = parseInt(val, 10)
                  const h = parseInt(this.customHeight, 10)
                  if (!isNaN(n) && !isNaN(h) && n > 0) {
                    this.customHeight = `${Math.round(n * h / (parseInt(this.customWidth, 10) || 1))}`
                  }
                }
              })

            // 单位选择器
            Row() {
              Text(this.customUnit)
                .fontSize(8)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .layoutWeight(1)
              Text(Icon.chevron_down)
                .fontSize(5)
                .fontColor(ColorToken.muted)
                .margin({ left: 2 })
            }
            .width(32)
            .height(22)
            .padding({ left: 2, right: 2 })
            .borderRadius(3)
            .backgroundColor(ColorToken.white)
            .border({ width: 1, color: ColorToken.border })
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
            .onClick(() => {
              const idx = this.unitOptions.indexOf(this.customUnit)
              this.customUnit = this.unitOptions[(idx + 1) % this.unitOptions.length]
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 4 })

          // 高度行 + 应用按钮
          Row() {
            Text('高')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor('#8B939D')
              .width(20)
            TextInput({ text: this.customHeight, placeholder: '297' })
              .type(InputType.Number)
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .height(22)
              .padding({ left: 4, right: 4 })
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .layoutWeight(1)
              .onChange((val: string) => { this.customHeight = val })

            // 应用按钮
            Row() {
              Text('应用')
                .fontSize(8)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.white)
            }
            .width(22)
            .height(22)
            .borderRadius(3)
            .backgroundColor(ColorToken.primary)
            .justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
            .margin({ left: 4 })
            .onClick(() => {
              this.documentSize = `${this.customWidth} × ${this.customHeight} ${this.customUnit}`
              this.activePopup = ''
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // 约束比例开关
          Row() {
            // Toggle
            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .margin({ left: this.constrainProportions ? 9 : 1 })
            }
            .width(16)
            .height(10)
            .borderRadius(5)
            .backgroundColor(this.constrainProportions ? ColorToken.primary : ColorToken.border)
            .onClick(() => { this.constrainProportions = !this.constrainProportions })

            Text('约束比例')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.secondary)
              .margin({ left: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 4 })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .border({ width: 0, color: ColorToken.border })
      }
    }
    .width(220)
    .borderRadius(RadiusToken.xl)
    .backgroundColor(ColorToken.white)
    .border({ width: 1, color: ColorToken.border })
    .shadow(ShadowToken.xl)
    .position({ x: 200, y: -260 })
    .zIndex(ZIndexToken.dropdown)
  }

  // ─── 图层列表弹窗 ───
  @Builder
  layerListPopup(): void {
    Column() {
      Text('图层列表')
        .fontSize(9)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .width('100%')
        .padding({ left: 10, top: 4, bottom: 4 })
        .backgroundColor(ColorToken.panel)

      ForEach(this.layers, (layer: LayerRow, idx?: number) => {
        Row() {
          // 序号
          Text(`${(idx ?? 0) + 1}`)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .width(16)

          // 可见性图标（可点击切换）
          Text(layer.visible ? Icon.eye : Icon.eye_off)
            .fontSize(8)
            .fontColor(layer.visible ? ColorToken.muted : ColorToken.error)
            .onClick(() => {
              this.layers = this.layers.map((l: LayerRow): LayerRow => {
                const item: LayerRow = {
                  id: l.id, name: l.name, visible: l.id === layer.id ? !l.visible : l.visible,
                  locked: l.locked, objectCount: l.objectCount,
                }
                return item
              })
            })

          // 图层名
          Text(layer.name)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .margin({ left: 6 })
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 对象数（原型：text-[8px] text-muted，无 lock 图标）
          Text(`${layer.objectCount}`)
            .fontSize(8)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(26)
        .padding({ left: 10, right: 10 })
        .backgroundColor(this.selectedLayerId === layer.id
          ? ColorToken.hover_bg
          : (this.hoveredPopupItem === layer.id ? ColorToken.panel : Color.Transparent))
        .alignItems(VerticalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredPopupItem = isHover ? layer.id : '' })
        .onClick(() => {
          this.selectedLayerId = layer.id
          this.pageInfo = `${layer.name} · ${layer.objectCount} 对象`
          this.activePopup = ''
        })
      })

      // 暂无图层占位
      if (this.layers.length === 0) {
        Text('暂无图层')
          .fontSize(9)
          .fontColor(ColorToken.muted)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 8, bottom: 8 })
      }
    }
    .width(200)
    .borderRadius(RadiusToken.xl)
    .backgroundColor(ColorToken.white)
    .border({ width: 1, color: ColorToken.border })
    .shadow(ShadowToken.xl)
    .position({ x: 320, y: -200 })
    .zIndex(ZIndexToken.dropdown)
  }
}

// 透明色辅助（避免直接用 Color.Transparent 字符串混乱）
function ColorTransparent(): ResourceColor {
  return Color.Transparent
}
