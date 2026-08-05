/**
 * ColorPickerPanel - 颜色选择器面板
 *
 * 对应原型 src/components/ColorPickerPanel.vue
 * 包含：色相条 + SV 方块 + HEX + RGB 输入 + 色板
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { hexToRgb, rgbToHex, rgbToHsl, hslToRgb, isValidHex, CmykColor } from '../utils/colorUtils'
import { ColorChannelInput } from './ColorChannelInput'

@Component
export struct ColorPickerPanel {
  @Prop modelValue: string = '#3AC487'
  onPick: (hex: string) => void = () => {}

  // 本地状态
  @State localHex: string = '#3AC487'
  @State valR: number = 58
  @State valG: number = 196
  @State valB: number = 135
  @State valH: number = 152
  @State valS: number = 54
  @State valL: number = 50
  @State localMode: string = 'RGB'
  @State cmykC: number = 0
  @State cmykM: number = 56
  @State cmykY: number = 42
  @State cmykK: number = 17
  @State selectedSwatch: string = ''
  @State hoveredSwatch: string = ''
  @State hoveredAction: string = ''
  @State localProfile: string = 'sRGB IEC61966-2.1'
  @State localRenderIntent: string = '相对比色'
  @State showProfileSelect: boolean = false
  @State showIntentSelect: boolean = false

  // 拖拽状态
  @State hueDragging: boolean = false
  @State svDragging: boolean = false
  @State hueY: number = 0
  @State svX: number = 0
  @State svY: number = 0

  private colorModes: string[] = ['RGB', 'HSL', 'CMYK']
  private swatches: string[] = [
    '#3AC487', '#16865F', '#0D5A3D', '#3B82F6', '#22C55E',
    '#F59E0B', '#EF4444', '#263238', '#FFFFFF', '#000000',
  ]
  private profileOptions: string[] = [
    'sRGB IEC61966-2.1', 'Adobe RGB (1998)', 'Display P3',
    'CMYK Coated FOGRA39', 'CMYK Uncoated FOGRA29', 'ProPhoto RGB', 'Apple RGB',
  ]
  private intentOptions: string[] = ['相对比色', '绝对比色', '感知', '饱和度']

  aboutToAppear(): void {
    this.syncFromHex(this.modelValue)
    this.updateHandlePositions()
  }

  /** 从 HEX 同步所有通道 */
  private syncFromHex(hex: string): void {
    if (!isValidHex(hex)) return
    this.localHex = hex.toUpperCase()
    const rgb = hexToRgb(hex)
    if (!rgb) return
    this.valR = rgb.r
    this.valG = rgb.g
    this.valB = rgb.b
    const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b)
    this.valH = hsl.h
    this.valS = hsl.s
    this.valL = hsl.l
    const cmyk = this.rgbToCmykLocal(rgb.r, rgb.g, rgb.b)
    this.cmykC = cmyk.c
    this.cmykM = cmyk.m
    this.cmykY = cmyk.y
    this.cmykK = cmyk.k
  }

  /** 从 RGB 同步 */
  private syncFromRgb(r: number, g: number, b: number): void {
    this.valR = Math.max(0, Math.min(255, Math.round(r)))
    this.valG = Math.max(0, Math.min(255, Math.round(g)))
    this.valB = Math.max(0, Math.min(255, Math.round(b)))
    this.localHex = rgbToHex(this.valR, this.valG, this.valB).toUpperCase()
    const hsl = rgbToHsl(this.valR, this.valG, this.valB)
    this.valH = hsl.h
    this.valS = hsl.s
    this.valL = hsl.l
    const cmyk = this.rgbToCmykLocal(this.valR, this.valG, this.valB)
    this.cmykC = cmyk.c
    this.cmykM = cmyk.m
    this.cmykY = cmyk.y
    this.cmykK = cmyk.k
  }

  /** 从 HSL 同步 */
  private syncFromHsl(h: number, s: number, l: number): void {
    this.valH = Math.max(0, Math.min(360, Math.round(h)))
    this.valS = Math.max(0, Math.min(100, Math.round(s)))
    this.valL = Math.max(0, Math.min(100, Math.round(l)))
    const rgb = hslToRgb(this.valH, this.valS, this.valL)
    this.valR = rgb.r
    this.valG = rgb.g
    this.valB = rgb.b
    this.localHex = rgbToHex(rgb.r, rgb.g, rgb.b).toUpperCase()
    const cmyk = this.rgbToCmykLocal(rgb.r, rgb.g, rgb.b)
    this.cmykC = cmyk.c
    this.cmykM = cmyk.m
    this.cmykY = cmyk.y
    this.cmykK = cmyk.k
  }

  /** RGB 转 CMYK（本地辅助） */
  private rgbToCmykLocal(r: number, g: number, b: number): CmykColor {
    const rr = r / 255
    const gg = g / 255
    const bb = b / 255
    const k = 1 - Math.max(rr, gg, bb)
    if (k === 1) return { c: 0, m: 0, y: 0, k: 100 }
    return {
      c: Math.round(((1 - rr - k) / (1 - k)) * 100),
      m: Math.round(((1 - gg - k) / (1 - k)) * 100),
      y: Math.round(((1 - bb - k) / (1 - k)) * 100),
      k: Math.round(k * 100),
    }
  }

  /** 更新色相条和 SV 方块的手柄位置 */
  private updateHandlePositions(): void {
    // 色相条：h 0-360 映射到 0-120px
    this.hueY = (this.valH / 360) * 120
    // SV 方块：s 0-100 映射到 0-100%, l 0-100 映射到 100%-0%
    this.svX = this.valS
    this.svY = 100 - this.valL
  }

  /** 发送更新事件 */
  private emitUpdate(): void {
    this.onPick(this.localHex)
  }

  build(): void {
    Column() {
      // ─── 色相条 + SV 方块 ───
      Row() {
        // 色相条（垂直，16×128）
        Stack({ alignContent: Alignment.TopStart }) {
          // 色相条背景（线性渐变，从上到下：红→黄→绿→青→蓝→紫→红）
          Column()
            .width('100%')
            .height('100%')
            .borderRadius(4)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [
                ['#FF0000', 0], ['#FFFF00', 0.17], ['#00FF00', 0.33],
                ['#00FFFF', 0.5], ['#0000FF', 0.67], ['#FF00FF', 0.83], ['#FF0000', 1],
              ],
            })
          // 色相指示器（白色边框小条）
          Row()
            .width(20)
            .height(8)
            .borderRadius(2)
            .backgroundColor(this.localHex)
            .border({ width: 2, color: ColorToken.white })
            .position({ x: -2, y: this.hueY })
        }
        .width(16)
        .height(128)
        .borderRadius(4)
        .gesture(
          PanGesture()
            .onActionStart((e: GestureEvent) => {
              this.hueDragging = true
              this.updateHueFromOffset(e.offsetY)
            })
            .onActionUpdate((e: GestureEvent) => {
              this.updateHueFromOffset(e.offsetY)
            })
            .onActionEnd(() => {
              this.hueDragging = false
            })
        )

        // SV 方块（128×128）
        Stack({ alignContent: Alignment.TopStart }) {
          // 底层：当前色相的纯色
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(`hsl(${this.valH}, 100%, 50%)`)
          // 白色到透明（从左到右）
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#FFFFFF', 0], ['#00FFFFFF', 1]],
            })
          // 黑色到透明（从下到上）
          Column()
            .width('100%')
            .height('100%')
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#00000000', 0], ['#000000', 1]],
            })
          // SV 指示器（圆形）
          Column()
            .width(12)
            .height(12)
            .borderRadius(6)
            .backgroundColor(this.localHex)
            .border({ width: 2, color: ColorToken.white })
            .position({ x: `${this.svX}%`, y: `${this.svY}%` })
        }
        .layoutWeight(1)
        .height(128)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .margin({ left: 8 })
        .gesture(
          PanGesture()
            .onActionStart((e: GestureEvent) => {
              this.svDragging = true
              this.updateSVFromOffset(e.offsetX, e.offsetY)
            })
            .onActionUpdate((e: GestureEvent) => {
              this.updateSVFromOffset(e.offsetX, e.offsetY)
            })
            .onActionEnd(() => {
              this.svDragging = false
            })
        )
      }
      .width('100%')

      // ─── HEX + 预览 ───
      Row() {
        // 颜色预览块
        Column()
          .width(22)
          .height(22)
          .borderRadius(4)
          .backgroundColor(this.localHex)
          .border({ width: 1, color: ColorToken.border })

        // HEX 输入框
        Row() {
          Text('HEX')
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor('#8B939D')
          TextInput({ text: this.localHex })
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .width(60)
            .textAlign(TextAlign.End)
            .margin({ left: 6 })
            .onChange((val: string) => {
              const upper = val.toUpperCase()
              this.localHex = upper
              if (isValidHex(upper)) {
                this.syncFromHex(upper)
                this.updateHandlePositions()
                this.emitUpdate()
              }
            })
        }
        .layoutWeight(1)
        .height(24)
        .padding({ left: 6, right: 6 })
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border })
        .borderRadius(4)
        .margin({ left: 6 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 6 })

      // ─── 模式切换 ───
      Row() {
        ForEach(this.colorModes, (mode: string) => {
          Text(mode)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.localMode === mode ? ColorToken.white : ColorToken.muted)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(22)
            .borderRadius(4)
            .backgroundColor(this.localMode === mode ? ColorToken.primary : Color.Transparent)
            .border({ width: 1, color: this.localMode === mode ? ColorToken.primary : ColorToken.border })
            .textAlign(TextAlign.Center)
            .margin({ right: mode === 'RGB' || mode === 'HSL' ? 4 : 0 })
            .onClick(() => { this.localMode = mode })
        })
      }
      .width('100%')
      .margin({ top: 6 })

      // ─── RGB 模式输入 ───
      if (this.localMode === 'RGB') {
        Row() {
          ColorChannelInput({ label: 'R', labelColor: '#EF4444', value: this.valR, max: 255, onChange: (v) => { this.syncFromRgb(v, this.valG, this.valB); this.updateHandlePositions(); this.emitUpdate() } })
          ColorChannelInput({ label: 'G', labelColor: '#22C55E', value: this.valG, max: 255, onChange: (v) => { this.syncFromRgb(this.valR, v, this.valB); this.updateHandlePositions(); this.emitUpdate() } })
          ColorChannelInput({ label: 'B', labelColor: '#3B82F6', value: this.valB, max: 255, onChange: (v) => { this.syncFromRgb(this.valR, this.valG, v); this.updateHandlePositions(); this.emitUpdate() } })
        }
        .width('100%')
        .margin({ top: 6 })
      }

      // ─── HSL 模式输入 ───
      if (this.localMode === 'HSL') {
        Row() {
          ColorChannelInput({ label: 'H', labelColor: '#8B939D', value: this.valH, suffix: '°', max: 360, onChange: (v) => { this.syncFromHsl(v, this.valS, this.valL); this.updateHandlePositions(); this.emitUpdate() } })
          ColorChannelInput({ label: 'S', labelColor: '#8B939D', value: this.valS, suffix: '%', max: 100, onChange: (v) => { this.syncFromHsl(this.valH, v, this.valL); this.updateHandlePositions(); this.emitUpdate() } })
          ColorChannelInput({ label: 'L', labelColor: '#8B939D', value: this.valL, suffix: '%', max: 100, onChange: (v) => { this.syncFromHsl(this.valH, this.valS, v); this.updateHandlePositions(); this.emitUpdate() } })
        }
        .width('100%')
        .margin({ top: 6 })
      }

      // ─── CMYK 模式输入（2×2） ───
      if (this.localMode === 'CMYK') {
        Column() {
          Row() {
            ColorChannelInput({ label: 'C', labelColor: '#00BCD4', value: this.cmykC, suffix: '%', max: 100, onChange: (v) => { this.cmykC = v } })
            ColorChannelInput({ label: 'M', labelColor: '#E91E63', value: this.cmykM, suffix: '%', max: 100, onChange: (v) => { this.cmykM = v } })
          }
          .width('100%')
          Row() {
            ColorChannelInput({ label: 'Y', labelColor: '#FFEB3B', value: this.cmykY, suffix: '%', max: 100, onChange: (v) => { this.cmykY = v } })
            ColorChannelInput({ label: 'K', labelColor: '#263238', value: this.cmykK, suffix: '%', max: 100, onChange: (v) => { this.cmykK = v } })
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .width('100%')
        .margin({ top: 6 })
      }

      // ─── 色板（原型：label + eyedropper + plus 按钮） ───
      Row() {
        Text('色板')
          .fontSize(9)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.muted)
        Blank()
        // 取色器按钮
        Text(Icon.eyedropper)
          .fontSize(9)
          .fontColor(this.hoveredAction === 'eyedropper' ? ColorToken.primary : ColorToken.tertiary)
          .padding(2)
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'eyedropper' : '' })
        // 添加色板按钮
        Text(Icon.plus)
          .fontSize(9)
          .fontColor(this.hoveredAction === 'addSwatch' ? ColorToken.primary : ColorToken.tertiary)
          .padding(2)
          .margin({ left: 4 })
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'addSwatch' : '' })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 6 })

      // 色板列表（自动换行，原型：选中态 ring-2 ring-primary ring-offset-1）
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.swatches, (swatch: string) => {
          Stack() {
            Column()
              .width(20)
              .height(20)
              .borderRadius(3)
              .backgroundColor(swatch)
            // 选中态 ring 圆环（原型：ring-2 ring-primary ring-offset-1）
            if (this.localHex.toUpperCase() === swatch.toUpperCase()) {
              Column()
                .width(22)
                .height(22)
                .borderRadius(4)
                .border({ width: 2, color: ColorToken.primary })
                .position({ x: -1, y: -1 })
            }
          }
          .width(20)
          .height(20)
          .margin({ right: 4, bottom: 4 })
          .scale(this.hoveredSwatch === swatch ? { x: 1.25, y: 1.25 } : { x: 1, y: 1 })
          .onHover((isHover: boolean) => { this.hoveredSwatch = isHover ? swatch : '' })
          .onClick(() => {
            this.syncFromHex(swatch)
            this.updateHandlePositions()
            this.emitUpdate()
          })
        })
      }
      .width('100%')
      .margin({ top: 4 })

      // ─── Color Profile 区域（原型：pt-[2px] border-t） ───
      Column() {
        // 配置文件下拉
        Row() {
          Text('配置文件')
            .fontSize(8)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .width(40)
          Row() {
            Text(this.localProfile)
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .layoutWeight(1)
            Text(Icon.chevron_down)
              .fontSize(7)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .layoutWeight(1)
          .height(20)
          .padding({ left: 4, right: 4 })
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.showProfileSelect = !this.showProfileSelect })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 配置文件下拉浮层
        if (this.showProfileSelect) {
          Column() {
            ForEach(this.profileOptions, (opt: string) => {
              Text(opt)
                .fontSize(8)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.localProfile === opt ? ColorToken.primary_dark_700 : ColorToken.body)
                .width('100%')
                .height(20)
                .padding({ left: 6, right: 6 })
                .backgroundColor(this.localProfile === opt ? ColorToken.hover_bg : Color.Transparent)
                .onClick(() => {
                  this.localProfile = opt
                  this.showProfileSelect = false
                })
            })
          }
          .width('100%')
          .padding({ top: 2, bottom: 2 })
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(3)
          .margin({ top: 2 })
        }

        // 渲染意图下拉
        Row() {
          Text('渲染意图')
            .fontSize(8)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .width(40)
          Row() {
            Text(this.localRenderIntent)
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .layoutWeight(1)
            Text(Icon.chevron_down)
              .fontSize(7)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .layoutWeight(1)
          .height(20)
          .padding({ left: 4, right: 4 })
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
          .onClick(() => { this.showIntentSelect = !this.showIntentSelect })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })

        // 渲染意图下拉浮层
        if (this.showIntentSelect) {
          Column() {
            ForEach(this.intentOptions, (opt: string) => {
              Text(opt)
                .fontSize(8)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(this.localRenderIntent === opt ? ColorToken.primary_dark_700 : ColorToken.body)
                .width('100%')
                .height(20)
                .padding({ left: 6, right: 6 })
                .backgroundColor(this.localRenderIntent === opt ? ColorToken.hover_bg : Color.Transparent)
                .onClick(() => {
                  this.localRenderIntent = opt
                  this.showIntentSelect = false
                })
            })
          }
          .width('100%')
          .padding({ top: 2, bottom: 2 })
          .backgroundColor(ColorToken.white)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(3)
          .margin({ top: 2 })
        }
      }
      .width('100%')
      .padding({ top: 2 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
      .margin({ top: 6 })
    }
    .width('100%')
  }

  /** 根据色相条 Y 偏移更新色相 */
  private updateHueFromOffset(offsetY: number): void {
    const y = Math.max(0, Math.min(120, offsetY))
    const h = Math.round((y / 120) * 360)
    this.syncFromHsl(h, this.valS, this.valL)
    this.updateHandlePositions()
    this.emitUpdate()
  }

  /** 根据 SV 方块偏移更新饱和度和亮度 */
  private updateSVFromOffset(offsetX: number, offsetY: number): void {
    // SV 方块宽度约 188px（220 - 16 - 8 - padding）
    const w = 188
    const h = 128
    const x = Math.max(0, Math.min(1, offsetX / w))
    const y = Math.max(0, Math.min(1, offsetY / h))
    const s = Math.round(x * 100)
    const l = Math.round((1 - y) * 100)
    this.syncFromHsl(this.valH, s, l)
    this.updateHandlePositions()
    this.emitUpdate()
  }
}
