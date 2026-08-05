/**
 * SplashScreen - 启动屏
 *
 * 对应原型 src/components/SplashScreen.vue
 * 精准还原：顶部品牌栏 + Hero + Tabs(新建/最近/模板) + 4种Frame模式 + 最近文件 + 模板 + 创建按钮
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, HeightToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface FrameMode {
  type: string
  name: string
  desc: string
  orient: string
}

interface RecentFile {
  name: string
  time: string
  size: string
  pages: number
  bgColor: string
  blockHeights: number[]
  blockColors: string[]
}

interface Template {
  name: string
  icon: string
  count: number
  color: string
}

interface MarginParam {
  left?: number
  right?: number
  top?: number
  bottom?: number
}

@Component
export struct SplashScreen {
  onEnter: (mode: string) => void = () => {}
  @State activeTab: string = 'new'
  @State selectedFrameType: string = 'single'
  @State hoveredMode: string = ''
  @State hoveredFile: string = ''
  @State hoveredTpl: number = -1
  // 主题切换
  @StorageLink('currentTheme') currentTheme: string = 'light'
  // 自定义尺寸 Modal
  @State showCustomModal: boolean = false
  @State customW: number = 210
  @State customH: number = 297
  @State customUnit: string = 'mm'
  @State customWInput: string = '210'
  @State customHInput: string = '297'
  @State facing: string = 'portrait'  // portrait | landscape
  @State includeBleed: boolean = false
  @State useCMYK: boolean = false
  @State colorProfile: string = 'sRGB'
  @State rasterEffect: string = '300'
  @State hoveredModalBtn: string = ''
  @State hoveredHeaderBtn: string = ''
  @State hoveredTab: string = ''
  @State hoveredCustomTrigger: boolean = false
  @State hoveredCreateBtn: boolean = false
  @State hoveredBrowseAll: boolean = false
  @State hoveredViewSwitch: string = ''
  @State hoveredApplyBtn: boolean = false
  // Toast 通知（通过 AppStorage 触发 ToastContainer）
  @StorageLink('toastMessage') toastMessage: string = ''
  @StorageLink('toastIcon') toastIcon: string = ''
  @StorageLink('toastType') toastType: string = 'info'
  @StorageLink('toastVisible') toastVisible: boolean = false

  private modes: FrameMode[] = [
    { type: 'single',    name: '单页',   desc: '595 × 842 · A4 竖向',  orient: '竖' },
    { type: 'poster',    name: '海报',   desc: '595 × 842 · A4 海报',  orient: '竖' },
    { type: 'book-page', name: '书页',   desc: '297 × 420 · 书籍单页', orient: '竖' },
    { type: 'spread',    name: '对页',   desc: '594 × 420 · 左右对页', orient: '横' },
  ]

  private recentFiles: RecentFile[] = [
    { name: '品牌画册_v3.hds', time: '5 分钟前', size: '12.4 MB', pages: 24, bgColor: '#FAFBFB',
      blockHeights: [20, 36, 16], blockColors: ['#3AC487', '#E5E7EB', '#1F2329'] },
    { name: '夏季海报_2026.hds', time: '1 小时前', size: '8.7 MB', pages: 1, bgColor: '#FFF8E8',
      blockHeights: [40, 24], blockColors: ['#F59E0B', '#1F2329'] },
    { name: '社交媒体合集.hds', time: '昨天 14:32', size: '5.2 MB', pages: 6, bgColor: '#F0F6F3',
      blockHeights: [16, 16, 16, 16], blockColors: ['#3AC487', '#3B82F6', '#F59E0B', '#1F2329'] },
    { name: '产品手册_2026Q3.hds', time: '2 天前', size: '18.1 MB', pages: 32, bgColor: '#FAFBFB',
      blockHeights: [24, 30, 18], blockColors: ['#1F2329', '#E5E7EB', '#3AC487'] },
    { name: 'Logo设计稿.hds', time: '3 天前', size: '2.8 MB', pages: 4, bgColor: '#FFFFFF',
      blockHeights: [60], blockColors: ['#1F2329'] },
    { name: '展会横幅.hds', time: '上周', size: '24.6 MB', pages: 2, bgColor: '#FEF2F2',
      blockHeights: [30, 30], blockColors: ['#EF4444', '#1F2329'] },
  ]

  private templates: Template[] = [
    { name: '海报', icon: Icon.image, count: 24, color: '#3AC487' },
    { name: '画册', icon: Icon.book, count: 18, color: '#3B82F6' },
    { name: '社媒图', icon: Icon.grid, count: 32, color: '#F59E0B' },
    { name: '名片', icon: Icon.rect, count: 12, color: '#8B5CF6' },
    { name: 'Logo', icon: Icon.star, count: 16, color: '#EC4899' },
    { name: '插画', icon: Icon.pen, count: 28, color: '#06B6D4' },
    { name: '排版', icon: Icon.text, count: 14, color: '#10B981' },
    { name: 'UI设计', icon: Icon.layout, count: 22, color: '#6366F1' },
  ]

  private frameModeName(type: string): string {
    const m = this.modes.find((x: FrameMode) => x.type === type)
    return m ? m.name : '单页'
  }

  /** 显示 Toast 通知 */
  private showToast(message: string, icon: string, type: string): void {
    this.toastMessage = message
    this.toastIcon = icon
    this.toastType = type
    this.toastVisible = true
    setTimeout(() => { this.toastVisible = false }, 3000)
  }

  /** 主题切换 */
  private toggleTheme(): void {
    this.currentTheme = this.currentTheme === 'dark' ? 'light' : 'dark'
    AppStorage.setOrCreate<string>('currentTheme', this.currentTheme)
    this.showToast(
      this.currentTheme === 'dark' ? '已切换暗色模式' : '已切换亮色模式',
      this.currentTheme === 'dark' ? Icon.moon : Icon.sun,
      'info'
    )
  }

  /** 设置按钮点击 */
  private onSettingsClick(): void {
    this.showToast('设置', Icon.gear, 'info')
  }

  /** 创建文档 */
  private onCreateDocument(): void {
    const modeName = this.frameModeName(this.selectedFrameType)
    this.showToast(`已创建 ${modeName} 文档`, Icon.file_new, 'success')
    // 触发 onEnter 回调进入工作区
    this.onEnter(this.selectedFrameType)
  }

  /** 最近文件点击 */
  private onRecentFileClick(name: string): void {
    this.showToast(`打开 ${name}`, Icon.file, 'info')
    this.onEnter('recent')
  }

  /** 模板点击 */
  private onTemplateClick(name: string): void {
    this.showToast(`从模板创建：${name}`, Icon.grid, 'success')
    this.onEnter('template')
  }

  /** 浏览全部模板 */
  private onBrowseAllClick(): void {
    this.showToast('浏览全部模板', Icon.grid, 'info')
  }

  /** Modal 应用按钮点击 */
  private onModalApply(): void {
    this.showCustomModal = false
    this.showToast(`自定义尺寸已应用：${this.customW} × ${this.customH} ${this.customUnit}`, Icon.sliders, 'success')
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 主背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorToken.bg)

      // 2. Hero 区装饰渐变背景（极淡）
      Column()
        .width('100%')
        .height(280)
        .linearGradient({
          angle: 180,
          colors: [['#3AC4871A', 0.0], ['#3AC48700', 0.7]],
        })

      // 3. 内容层
      Column() {
        // ─── 顶部品牌栏 ───
        Row() {
          Row() {
            // Logo（原型 fa-bezier-curve）
            Column() {
              Text(Icon.bezier)
                .fontSize(11)
                .fontColor(ColorToken.white)
                .textAlign(TextAlign.Center)
            }
            .width(26)
            .height(26)
            .borderRadius(7)
            .linearGradient({ angle: 135, colors: [['#3AC487', 0.0], ['#2AA36F', 1.0]] })
            .shadow(ShadowToken.primary_sm)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('Harmony Design Studio')
              .fontSize(FontSizeToken.level3)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.title)
              .letterSpacing(-0.12)
              .margin({ left: SpacingToken.s2 })

            // 版本徽章
            Text('v0.1.0')
              .fontSize(9)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.muted)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(3)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border_light })
              .margin({ left: 6 })
          }

          Blank()

          // 设置按钮
          Column() {
            Text(Icon.gear)
              .fontSize(11)
              .fontColor(ColorToken.secondary)
              .textAlign(TextAlign.Center)
          }
          .width(28)
          .height(28)
          .borderRadius(RadiusToken.md)
          .backgroundColor(this.hoveredHeaderBtn === 'settings' ? ColorToken.panel : Color.Transparent)
          .onHover((isHover: boolean) => { this.hoveredHeaderBtn = isHover ? 'settings' : '' })
          .onClick(() => { this.onSettingsClick() })

          // 主题切换
          Column() {
            Text(this.currentTheme === 'dark' ? Icon.sun : Icon.moon)
              .fontSize(11)
              .fontColor(ColorToken.secondary)
              .textAlign(TextAlign.Center)
          }
          .width(28)
          .height(28)
          .borderRadius(RadiusToken.md)
          .backgroundColor(this.hoveredHeaderBtn === 'theme' ? ColorToken.panel : Color.Transparent)
          .margin({ left: 2 })
          .onHover((isHover: boolean) => { this.hoveredHeaderBtn = isHover ? 'theme' : '' })
          .onClick(() => { this.toggleTheme() })
        }
        .width('100%')
        .height(52)
        .padding({ left: 24, right: 24 })
        .alignItems(VerticalAlign.Center)

        // ─── 主区：可滚动 ───
        Scroll() {
          Column() {
            // Hero 区
            Column() {
              // Welcome 标识（单层圆点 + 外发光环：原型 shadow-[0_0_0_3px_rgba(58,196,135,0.16)]）
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.primary)
                  .shadow({ radius: 3, color: '#3AC48729', offsetX: 0, offsetY: 0 })

                Text('WELCOME')
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.semibold)
                  .fontColor(ColorToken.primary_dark_700)
                  .letterSpacing(1.8)
                  .margin({ left: 6 })
              }

              Text('开启你的下一个设计')
                .fontSize(28)
                .fontWeight(FontWeightConstant.bold)
                .fontColor(ColorToken.title)
                .letterSpacing(-0.56)
                .lineHeight(34)
                .margin({ top: 14 })

              Text('选择预设快速开始，或从最近文件继续创作')
                .fontSize(FontSizeToken.level2)
                .fontColor(ColorToken.muted)
                .margin({ top: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ top: 40, bottom: 36 })

            // ─── Tabs ───
            Row() {
              this.tabButton('new', Icon.file_new, '新建')
              this.tabButton('recent', Icon.file_recent, '最近', { left: 2 })
              this.tabButton('templates', Icon.file_template, '模板', { left: 2 })
            }
            .padding(3)
            .borderRadius(RadiusToken.lg)
            .backgroundColor(ColorToken.white)
            .border({ width: 1, color: ColorToken.border_light })
            .shadow(ShadowToken.xs)
            .margin({ bottom: 24 })

            // ─── 新建 Tab 内容 ───
            if (this.activeTab === 'new') {
              this.newTabContent()
            } else if (this.activeTab === 'recent') {
              this.recentTabContent()
            } else {
              this.templateTabContent()
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // ─── 底部状态栏 ───
        Row() {
          Row() {
            Column()
              .width(5)
              .height(5)
              .borderRadius(2.5)
              .backgroundColor(ColorToken.primary)
            Text('就绪')
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
            Text('·')
              .fontSize(9)
              .fontColor(ColorToken.border)
              .margin({ left: 6 })
            Text('BYOK 未配置')
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .margin({ left: 6 })
          }
          Blank()
          Text('HarmonyOS / OpenHarmony 通用')
            .fontSize(9)
            .fontColor(ColorToken.muted)
          Text('·')
            .fontSize(9)
            .fontColor(ColorToken.border)
            .margin({ left: 6 })
          Text('Skia 引擎待初始化')
            .fontSize(9)
            .fontColor(ColorToken.muted)
            .margin({ left: 6 })
        }
        .width('100%')
        .height(26)
        .padding({ left: 24, right: 24 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')

      // ─── 自定义尺寸 Modal ───
      if (this.showCustomModal) {
        this.customSizeModal()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorToken.bg)
  }

  // ─── 自定义尺寸 Modal ───
  @Builder
  customSizeModal(): void {
    Stack({ alignContent: Alignment.Center }) {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#0F172A66')
        .onClick(() => { this.showCustomModal = false })

      // Modal 主体
      Column() {
        // ─── Header ───
        Row() {
          Column() {
            Text('自定义尺寸')
              .fontSize(FontSizeToken.level4)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.title)
            Text('为你的项目设定精确画布')
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .margin({ top: 1 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 关闭按钮
          Column() {
            Text(Icon.xmark)
              .fontSize(10)
              .fontColor(ColorToken.muted)
              .textAlign(TextAlign.Center)
          }
          .width(24)
          .height(24)
          .borderRadius(5)
          .backgroundColor(this.hoveredModalBtn === 'close' ? ColorToken.panel : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredModalBtn = isHover ? 'close' : '' })
          .onClick(() => { this.showCustomModal = false })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .border({ width: 0, color: ColorToken.border_light })

        // ─── Body ───
        Column() {
          // 宽 / 链接 / 高 / 单位
          Row() {
            // 宽度
            Column() {
              Text('宽度')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .letterSpacing(0.5)
              TextInput({ text: this.customWInput, placeholder: '210' })
                .type(InputType.Number)
                .fontSize(12)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
                .height(32)
                .padding({ left: 10, right: 10 })
                .borderRadius(6)
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border })
                .margin({ top: 4 })
                .onChange((val: string) => {
                  this.customWInput = val
                  const n = parseInt(val, 10)
                  if (!isNaN(n) && n > 0) this.customW = n
                })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 链接图标
            Column() {
              Text(Icon.link)
                .fontSize(10)
                .fontColor(ColorToken.muted)
                .textAlign(TextAlign.Center)
            }
            .width(28)
            .height(32)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 高度
            Column() {
              Text('高度')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .letterSpacing(0.5)
              TextInput({ text: this.customHInput, placeholder: '297' })
                .type(InputType.Number)
                .fontSize(12)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
                .height(32)
                .padding({ left: 10, right: 10 })
                .borderRadius(6)
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border })
                .margin({ top: 4 })
                .onChange((val: string) => {
                  this.customHInput = val
                  const n = parseInt(val, 10)
                  if (!isNaN(n) && n > 0) this.customH = n
                })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 单位选择器
            Column() {
              Text('单位')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .letterSpacing(0.5)
              Row() {
                Text(this.customUnit)
                  .fontSize(12)
                  .fontWeight(FontWeightConstant.semibold)
                  .fontColor(ColorToken.body)
                  .layoutWeight(1)
                Text(Icon.chevron_down)
                  .fontSize(6)
                  .fontColor(ColorToken.muted)
                  .margin({ left: 4 })
              }
              .height(32)
              .padding({ left: 8, right: 8 })
              .borderRadius(6)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .alignItems(VerticalAlign.Center)
              .margin({ top: 4 })
              .onClick(() => {
                // 循环切换单位
                const units: string[] = ['mm', 'cm', 'px', 'pt', 'in']
                const idx = units.indexOf(this.customUnit)
                this.customUnit = units[(idx + 1) % units.length]
              })
            }
            .width(80)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          // 朝向 + 出血 + CMYK
          Row() {
            // 竖向
            Row() {
              Column() {
                if (this.facing === 'portrait') {
                  Text(Icon.check)
                    .fontSize(7)
                    .fontColor(ColorToken.white)
                    .textAlign(TextAlign.Center)
                }
              }
              .width(16)
              .height(16)
              .borderRadius(4)
              .backgroundColor(this.facing === 'portrait' ? ColorToken.primary : ColorToken.white)
              .border({ width: 1, color: this.facing === 'portrait' ? ColorToken.primary : ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.facing = 'portrait' })

              Text('竖向')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .margin({ left: 6 })
            }
            .alignItems(VerticalAlign.Center)

            // 横向
            Row() {
              Column() {
                if (this.facing === 'landscape') {
                  Text(Icon.check)
                    .fontSize(7)
                    .fontColor(ColorToken.white)
                    .textAlign(TextAlign.Center)
                }
              }
              .width(16)
              .height(16)
              .borderRadius(4)
              .backgroundColor(this.facing === 'landscape' ? ColorToken.primary : ColorToken.white)
              .border({ width: 1, color: this.facing === 'landscape' ? ColorToken.primary : ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.facing = 'landscape' })

              Text('横向')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .margin({ left: 6 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ left: 10 })

            Blank()

            // 出血 3mm
            Row() {
              Column() {
                if (this.includeBleed) {
                  Text(Icon.check)
                    .fontSize(7)
                    .fontColor(ColorToken.white)
                    .textAlign(TextAlign.Center)
                }
              }
              .width(12)
              .height(12)
              .borderRadius(2)
              .backgroundColor(this.includeBleed ? ColorToken.primary : ColorToken.white)
              .border({ width: 1, color: this.includeBleed ? ColorToken.primary : ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.includeBleed = !this.includeBleed })

              Text('出血 3mm')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)

            // CMYK
            Row() {
              Column() {
                if (this.useCMYK) {
                  Text(Icon.check)
                    .fontSize(7)
                    .fontColor(ColorToken.white)
                    .textAlign(TextAlign.Center)
                }
              }
              .width(12)
              .height(12)
              .borderRadius(2)
              .backgroundColor(this.useCMYK ? ColorToken.primary : ColorToken.white)
              .border({ width: 1, color: this.useCMYK ? ColorToken.primary : ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => { this.useCMYK = !this.useCMYK })

              Text('CMYK')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ left: 8 })
          }
          .width('100%')
          .margin({ top: 14 })

          // 色彩配置 / 栅格效果（两列）
          Row() {
            // 色彩配置
            Column() {
              Text('色彩配置')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .letterSpacing(0.5)
              Row() {
                Text(this.colorProfileLabel(this.colorProfile))
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.body)
                  .layoutWeight(1)
                Text(Icon.chevron_down)
                  .fontSize(6)
                  .fontColor(ColorToken.muted)
                  .margin({ left: 4 })
              }
              .height(28)
              .padding({ left: 8, right: 8 })
              .borderRadius(5)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .alignItems(VerticalAlign.Center)
              .margin({ top: 4 })
              .onClick(() => {
                const opts: string[] = ['sRGB', 'displayP3', 'adobeRGB', 'cmykCoated']
                const idx = opts.indexOf(this.colorProfile)
                this.colorProfile = opts[(idx + 1) % opts.length]
              })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 栅格效果
            Column() {
              Text('栅格效果')
                .fontSize(9)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .letterSpacing(0.5)
              Row() {
                Text(this.rasterEffectLabel(this.rasterEffect))
                  .fontSize(10)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor(ColorToken.body)
                  .layoutWeight(1)
                Text(Icon.chevron_down)
                  .fontSize(6)
                  .fontColor(ColorToken.muted)
                  .margin({ left: 4 })
              }
              .height(28)
              .padding({ left: 8, right: 8 })
              .borderRadius(5)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .alignItems(VerticalAlign.Center)
              .margin({ top: 4 })
              .onClick(() => {
                const opts: string[] = ['300', '150', '72']
                const idx = opts.indexOf(this.rasterEffect)
                this.rasterEffect = opts[(idx + 1) % opts.length]
              })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 10 })
          }
          .width('100%')
          .margin({ top: 14 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 18, bottom: 18 })

        // ─── Footer ───
        Row() {
          Blank()

          // 取消按钮
          Row() {
            Text('取消')
              .fontSize(11)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(this.hoveredModalBtn === 'cancel' ? ColorToken.body : ColorToken.secondary)
          }
          .height(32)
          .padding({ left: 14, right: 14 })
          .borderRadius(6)
          .backgroundColor(this.hoveredModalBtn === 'cancel' ? ColorToken.white : Color.Transparent)
          .alignItems(VerticalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredModalBtn = isHover ? 'cancel' : '' })
          .onClick(() => { this.showCustomModal = false })

          // 应用按钮（原型：hover:bg-[#32B77C]）
          Row() {
            Text('应用')
              .fontSize(11)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.white)
          }
          .height(32)
          .padding({ left: 16, right: 16 })
          .borderRadius(6)
          .backgroundColor(this.hoveredApplyBtn ? '#32B77C' : ColorToken.primary)
          .shadow(ShadowToken.primary_sm)
          .alignItems(VerticalAlign.Center)
          .margin({ left: 8 })
          .onHover((isHover: boolean) => { this.hoveredApplyBtn = isHover })
          .onClick(() => { this.onModalApply() })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .backgroundColor(ColorToken.panel)
        .border({ width: 0, color: ColorToken.border_light })
      }
      .width(420)
      .borderRadius(RadiusToken.xl)
      .backgroundColor(ColorToken.white)
      .shadow(ShadowToken.xl)
      .border({ width: 1, color: ColorToken.border_light })
      .clip(true)
    }
    .width('100%')
    .height('100%')
    .zIndex(ZIndexToken.modal)
  }

  // 色彩配置显示标签
  private colorProfileLabel(value: string): string {
    if (value === 'sRGB') return 'sRGB IEC61966-2.1'
    if (value === 'displayP3') return 'Display P3'
    if (value === 'adobeRGB') return 'Adobe RGB (1998)'
    if (value === 'cmykCoated') return 'CMYK FOGRA39'
    return value
  }

  // 栅格效果显示标签
  private rasterEffectLabel(value: string): string {
    if (value === '300') return '高 (300 PPI)'
    if (value === '150') return '中 (150 PPI)'
    if (value === '72') return '屏幕 (72 PPI)'
    return value
  }

  // ─── Tab 按钮 ───
  @Builder
  tabButton(id: string, icon: string, label: string, margin?: MarginParam): void {
    Row() {
      Text(icon)
        .fontSize(10)
        .fontColor(this.activeTab === id
          ? ColorToken.white
          : (this.hoveredTab === id ? ColorToken.body : ColorToken.secondary))
      Text(label)
        .fontSize(FontSizeToken.level2)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(this.activeTab === id
          ? ColorToken.white
          : (this.hoveredTab === id ? ColorToken.body : ColorToken.secondary))
        .margin({ left: 6 })
    }
    .height(28)
    .padding({ left: 14, right: 14 })
    .borderRadius(RadiusToken.md)
    .backgroundColor(this.activeTab === id
      ? ColorToken.primary
      : (this.hoveredTab === id ? ColorToken.panel : Color.Transparent))
    .shadow(this.activeTab === id ? ShadowToken.primary_sm : ShadowToken.none)
    .alignItems(VerticalAlign.Center)
    .margin(margin ?? {})
    .onClick(() => { this.activeTab = id })
    .onHover((isHover: boolean) => { this.hoveredTab = isHover ? id : '' })
  }

  // ─── 新建 Tab 内容 ───
  @Builder
  newTabContent(): void {
    Column() {
      // 标题 + 提示
      Row() {
        Text('选择画板模式')
          .fontSize(11)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.muted)
          .letterSpacing(1)
        Blank()
        Text('将创建一个初始 Frame')
          .fontSize(9)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ bottom: 12 })

      // 4 模式卡片
      Row() {
        ForEach(this.modes, (mode: FrameMode) => {
          Column() {
            // 缩略图区
            Stack({ alignContent: Alignment.TopEnd }) {
              // 缩略图内容
              if (mode.type === 'single') {
                Column()
                  .width(36)
                  .height(50)
                  .backgroundColor(ColorToken.white)
                  .border({ width: 1, color: ColorToken.border })
                  .shadow(ShadowToken.xs)
              } else if (mode.type === 'poster') {
                Column() {
                  Column().width('80%').height(8).backgroundColor(ColorToken.primary_light_300).borderRadius(1)
                  Column().width('100%').height(4).backgroundColor(ColorToken.border).borderRadius(1).margin({ top: 2 })
                  Column().width('100%').height(20).backgroundColor(ColorToken.panel).borderRadius(1).margin({ top: 2 })
                }
                .width(44)
                .height(56)
                .padding(3)
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border })
                .shadow(ShadowToken.xs)
              } else if (mode.type === 'book-page') {
                Stack({ alignContent: Alignment.Center }) {
                  Column()
                    .width(2)
                    .height(50)
                    .backgroundColor(ColorToken.border_light)
                }
                .width(36)
                .height(50)
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border })
                .shadow(ShadowToken.xs)
              } else {
                // spread：对页
                Row() {
                  Column()
                    .width(24)
                    .height(34)
                    .backgroundColor(ColorToken.white)
                    .border({ width: 1, color: ColorToken.border })
                    .shadow(ShadowToken.xs)
                  Column()
                    .width(24)
                    .height(34)
                    .backgroundColor(ColorToken.white)
                    .border({ width: 1, color: ColorToken.border })
                    .shadow(ShadowToken.xs)
                    .margin({ left: 2 })
                }
              }

              // 方向徽章（原型 absolute top-[4px] right-[5px]）
              Text(mode.orient)
                .fontSize(7)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.muted)
                .backgroundColor('#FFFFFFB3')
                .padding({ left: 3, right: 3, top: 0.5, bottom: 0.5 })
                .borderRadius(2)
                .border({ width: 0.5, color: ColorToken.border_light })
                .margin({ top: 4, right: 5 })
            }
            .width('100%')
            .height(80)
            .backgroundColor(ColorToken.panel)
            .borderRadius(RadiusToken.md)
            .border({ width: 1, color: ColorToken.border_light })
            .margin({ bottom: 10 })

            // 模式名 + 选中图标
            Row() {
              Text(mode.name)
                .fontSize(FontSizeToken.level3)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.title)
              if (this.selectedFrameType === mode.type) {
                Text(Icon.check)
                  .fontSize(9)
                  .fontColor(ColorToken.primary)
                  .margin({ left: 4 })
              }
            }
            .width('100%')

            Text(mode.desc)
              .fontSize(10)
              .fontColor(ColorToken.muted)
              .margin({ top: 1 })
          }
          .layoutWeight(1)
          .padding(14)
          .borderRadius(RadiusToken.xl)
          .backgroundColor(ColorToken.white)
          .border({
            width: this.selectedFrameType === mode.type ? 2 : 1,
            color: this.selectedFrameType === mode.type
              ? ColorToken.primary
              : (this.hoveredMode === mode.type ? ColorToken.primary_light_300 : ColorToken.border_light),
          })
          .shadow(this.selectedFrameType === mode.type
            ? ShadowToken.primary_sm
            : (this.hoveredMode === mode.type ? ShadowToken.md : ShadowToken.none))
          .margin({ left: 6, right: 6 })
          .offset({ y: this.hoveredMode === mode.type ? -2 : 0 })
          .onClick(() => { this.selectedFrameType = mode.type })
          .onHover((isHover: boolean) => { this.hoveredMode = isHover ? mode.type : '' })
        })
      }
      .width('100%')
      .padding({ left: 26, right: 26 })
      .margin({ bottom: 16 })

      // 自定义尺寸触发器（原型：fa-sliders + 文本 + chevron-right）
      Row() {
        Text(Icon.sliders)
          .fontSize(10)
          .fontColor(this.hoveredCustomTrigger ? ColorToken.body : ColorToken.secondary)
        Text(`自定义尺寸 · ${this.customW} × ${this.customH} ${this.customUnit}`)
          .fontSize(11)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(this.hoveredCustomTrigger ? ColorToken.body : ColorToken.secondary)
          .margin({ left: 8 })
        Text(Icon.chevron_right)
          .fontSize(7)
          .fontColor(ColorToken.muted)
          .margin({ left: 2 })
      }
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(RadiusToken.md)
      .backgroundColor(this.hoveredCustomTrigger ? ColorToken.panel : ColorToken.white)
      .border({ width: 1, color: this.hoveredCustomTrigger ? ColorToken.primary_light_300 : ColorToken.border_light })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 4 })
      .onClick(() => { this.showCustomModal = true })
      .onHover((isHover: boolean) => { this.hoveredCustomTrigger = isHover })

      // 创建按钮（带阴影，hover 加深 + 上浮）
      Row() {
        Text(Icon.plus)
          .fontSize(11)
          .fontColor(ColorToken.white)
        Text(`创建 ${this.frameModeName(this.selectedFrameType)} 文档`)
          .fontSize(FontSizeToken.level4)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.white)
          .margin({ left: 8 })
        Text('Enter')
          .fontSize(9)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.white)
          .opacity(0.8)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .borderRadius(3)
          .backgroundColor('#FFFFFF26')
          .margin({ left: 6 })
      }
      .height(44)
      .padding({ left: 28, right: 28 })
      .borderRadius(RadiusToken.xl)
      .backgroundColor(this.hoveredCreateBtn ? '#32B77C' : ColorToken.primary)
      .shadow(this.hoveredCreateBtn
        ? { radius: 24, color: '#3AC48766', offsetX: 0, offsetY: 8 }
        : ShadowToken.primary_md)
      .offset({ y: this.hoveredCreateBtn ? -1 : 0 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 28 })
      .onClick(() => { this.onCreateDocument() })
      .onHover((isHover: boolean) => { this.hoveredCreateBtn = isHover })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // ─── 最近 Tab 内容 ───
  @Builder
  recentTabContent(): void {
    Column() {
      // 标题 + 视图切换
      Row() {
        Column() {
          Text(`${this.recentFiles.length} 个最近文档`)
            .fontSize(FontSizeToken.level3)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
          Text('按修改时间排序')
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 视图切换器
        Row() {
          Column() {
            Text(Icon.list)
              .fontSize(9)
              .fontColor(ColorToken.secondary)
          }
          .width(24)
          .height(24)
          .borderRadius(4)
          .backgroundColor(this.hoveredViewSwitch === 'list' ? ColorToken.panel : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredViewSwitch = isHover ? 'list' : '' })

          Column() {
            Text(Icon.grid_view)
              .fontSize(9)
              .fontColor(ColorToken.primary_dark_700)
          }
          .width(24)
          .height(24)
          .borderRadius(4)
          .backgroundColor(ColorToken.panel)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .padding(3)
        .borderRadius(RadiusToken.md)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border_light })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ bottom: 16 })

      // 文件网格（2列）
      Grid() {
        ForEach(this.recentFiles, (file: RecentFile) => {
          GridItem() {
            Column() {
              // 缩略图（原型：relative h-[120px]，徽章 absolute top-7 right-8）
              Stack({ alignContent: Alignment.Center }) {
                // 居中的缩略图主体（白底）
                Column()
                  .width(70)
                  .height(96)
                  .backgroundColor(ColorToken.white)
                  .border({ width: 1, color: ColorToken.border_light })
                  .shadow(ShadowToken.sm)

                // 内容块叠在缩略图上
                Column() {
                  ForEach(file.blockHeights, (h: number, idx?: number) => {
                    Column()
                      .width('100%')
                      .height(h)
                      .backgroundColor(file.blockColors[idx ?? 0])
                      .borderRadius(1.5)
                      .margin({ bottom: (idx ?? 0) < file.blockHeights.length - 1 ? 3 : 0 })
                  })
                }
                .width(70)
                .height(96)
                .padding(5)

                // 页码徽章（绝对定位到右上角，使用 Stack 占满宽度 + Row 右对齐）
                Row() {
                  Text(`${file.pages} 页`)
                    .fontSize(8)
                    .fontWeight(FontWeightConstant.semibold)
                    .fontColor(ColorToken.muted)
                    .backgroundColor('#FFFFFFD9')
                    .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    .borderRadius(3)
                    .border({ width: 0.5, color: ColorToken.border_light })
                }
                .width('100%')
                .height('100%')
                .padding({ top: 7, right: 8 })
                .justifyContent(FlexAlign.End)
                .alignItems(VerticalAlign.Top)
              }
              .width('100%')
              .height(120)
              .backgroundColor(file.bgColor)

              // 文件信息
              Row() {
                Text(file.name)
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.semibold)
                  .fontColor(ColorToken.title)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                // 原型：opacity-0 group-hover:opacity-100 -translate-x-[4px] group-hover:translate-x-0
                Text(Icon.arrow_right)
                  .fontSize(9)
                  .fontColor(ColorToken.primary)
                  .opacity(this.hoveredFile === file.name ? 1 : 0)
                  .offset({ x: this.hoveredFile === file.name ? 0 : -4 })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10 })

              Row() {
                Text(file.time)
                  .fontSize(9)
                  .fontColor(ColorToken.muted)
                Blank()
                Text(file.size)
                  .fontSize(9)
                  .fontColor(ColorToken.muted)
              }
              .width('100%')
              .padding({ left: 12, right: 12, bottom: 10 })
            }
            .backgroundColor(ColorToken.white)
            .border({
              width: 1,
              color: this.hoveredFile === file.name ? ColorToken.primary_light_300 : ColorToken.border_light,
            })
            .borderRadius(RadiusToken.xl)
            .shadow(this.hoveredFile === file.name ? ShadowToken.lg : ShadowToken.none)
            .offset({ y: this.hoveredFile === file.name ? -2 : 0 })
            .clip(true)
            .onClick(() => { this.onRecentFileClick(file.name) })
            .onHover((isHover: boolean) => { this.hoveredFile = isHover ? file.name : '' })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(14)
      .columnsGap(14)
      .padding({ left: 32, right: 32 })
      .height(380)
    }
    .width('100%')
  }

  // ─── 模板 Tab 内容 ───
  @Builder
  templateTabContent(): void {
    Column() {
      // 标题 + 浏览全部
      Row() {
        Text('按场景选择起步模板')
          .fontSize(FontSizeToken.level3)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.body)
        Blank()
        Row() {
          Text('浏览全部')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.hoveredBrowseAll ? ColorToken.primary_dark_700 : ColorToken.secondary)
          Text(Icon.arrow_right)
            .fontSize(7)
            .fontColor(this.hoveredBrowseAll ? ColorToken.primary_dark_700 : ColorToken.muted)
            .margin({ left: 3 })
        }
        .onHover((isHover: boolean) => { this.hoveredBrowseAll = isHover })
        .onClick(() => { this.onBrowseAllClick() })
      }
      .width('100%')
      .padding({ left: 32, right: 32 })
      .margin({ bottom: 14 })

      // 模板网格
      Grid() {
        ForEach(this.templates, (tpl: Template, idx?: number) => {
          GridItem() {
            Column() {
              // 图标盒（原型：group-hover:scale-[1.06]）
              Column() {
                Text(tpl.icon)
                  .fontSize(14)
                  .fontColor(tpl.color)
              }
              .width(40)
              .height(40)
              .borderRadius(RadiusToken.xl)
              .backgroundColor(tpl.color + '14')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .scale({ x: this.hoveredTpl === (idx ?? 0) ? 1.06 : 1, y: this.hoveredTpl === (idx ?? 0) ? 1.06 : 1 })

              Text(tpl.name)
                .fontSize(FontSizeToken.level3)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.title)
                .margin({ top: 10 })

              Text(`${tpl.count} 套模板`)
                .fontSize(10)
                .fontColor(ColorToken.muted)
                .margin({ top: 1 })
            }
            .layoutWeight(1)
            .padding(16)
            .borderRadius(RadiusToken.xl)
            .backgroundColor(ColorToken.white)
            .border({
              width: 1,
              color: this.hoveredTpl === (idx ?? 0) ? ColorToken.primary_light_300 : ColorToken.border_light,
            })
            .shadow(this.hoveredTpl === (idx ?? 0) ? ShadowToken.md : ShadowToken.none)
            .offset({ y: this.hoveredTpl === (idx ?? 0) ? -2 : 0 })
            .onClick(() => { this.onTemplateClick(tpl.name) })
            .onHover((isHover: boolean) => { this.hoveredTpl = isHover ? (idx ?? 0) : -1 })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .padding({ left: 32, right: 32 })
      .height(280)
    }
    .width('100%')
  }
}
