/**
 * ToolOptionsBar - 顶部工具选项栏
 *
 * 对应原型 src/components/ToolOptionsBar.vue
 * 精准还原：主页 + 7个工具组 + W/H/∠ + 折叠按钮
 * 第二行：布局工具组（编组/排列/对齐/分布）
 * 第三行：矢量工具组（路径操作 + 锚点 + 描边 + 填充）
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, FontWeightConstant, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface ToolGroupItem {
  id: string
  label: string
  icon: string
  expanded: boolean
}

interface LayoutToolItem {
  icon: string
  label: string
  active: boolean
}

@Component
export struct ToolOptionsBar {
  @StorageLink('currentTool') currentTool: string = 'select'
  @State toolGroups: ToolGroupItem[] = [
    { id: 'group', label: '编组', icon: Icon.group, expanded: false },
    { id: 'arrange', label: '排列', icon: Icon.bring_forward, expanded: false },
    { id: 'align', label: '对齐', icon: Icon.align_center, expanded: false },
    { id: 'dist', label: '分布', icon: Icon.distribute_h, expanded: false },
    { id: 'vector', label: '矢量', icon: Icon.pen_nib, expanded: false },
    { id: 'image', label: '图片', icon: Icon.image, expanded: false },
    { id: 'color', label: '色彩', icon: Icon.palette, expanded: false },
  ]
  @State collapsed: boolean = false
  @State alignTarget: string = 'selection'
  @State hoveredTool: string = ''
  @State vectorMoreOpen: boolean = false
  // 可变工具数组（支持 active 切换）
  @State alignTools: LayoutToolItem[] = [
    { icon: Icon.align_left, label: '左对齐', active: true },
    { icon: Icon.align_center, label: '水平居中', active: false },
    { icon: Icon.align_right, label: '右对齐', active: false },
    { icon: Icon.align_top, label: '顶对齐', active: false },
    { icon: Icon.align_middle, label: '垂直居中', active: false },
    { icon: Icon.align_bottom, label: '底对齐', active: false },
  ]
  @State distTools: LayoutToolItem[] = [
    { icon: Icon.align_left, label: '水平左', active: false },
    { icon: Icon.distribute_h, label: '水平居中', active: true },
    { icon: Icon.align_right, label: '水平右', active: false },
    { icon: Icon.distribute_h, label: '水平间距', active: false },
    { icon: Icon.align_top, label: '垂直顶', active: false },
    { icon: Icon.distribute_v, label: '垂直居中', active: false },
    { icon: Icon.align_bottom, label: '垂直底', active: false },
  ]
  @State colorModeTools: LayoutToolItem[] = [
    { icon: 'RGB', label: 'RGB', active: true },
    { icon: 'CMYK', label: 'CMYK', active: false },
    { icon: 'HSL', label: 'HSL', active: false },
    { icon: 'LAB', label: 'LAB', active: false },
  ]
  // Toast 通知（通过 AppStorage 触发 ToastContainer）
  @StorageLink('toastMessage') toastMessage: string = ''
  @StorageLink('toastIcon') toastIcon: string = ''
  @StorageLink('toastType') toastType: string = 'info'
  @StorageLink('toastVisible') toastVisible: boolean = false

  private groupTools: LayoutToolItem[] = [
    { icon: Icon.group, label: '编组', active: false },
    { icon: Icon.ungroup, label: '解组', active: false },
    { icon: Icon.lock, label: '锁定', active: false },
    { icon: Icon.unlock, label: '解锁', active: false },
    { icon: Icon.eye_off, label: '隐藏', active: false },
  ]

  private arrangeTools: LayoutToolItem[] = [
    { icon: Icon.bring_forward, label: '上移一层', active: false },
    { icon: Icon.send_backward, label: '下移一层', active: false },
    { icon: Icon.bring_front, label: '移到顶层', active: false },
    { icon: Icon.send_back, label: '移到底层', active: false },
  ]

  // 矢量：路径操作（4个布尔运算）
  private vectorBooleanTools: LayoutToolItem[] = [
    { icon: Icon.union, label: '合集', active: true },
    { icon: Icon.subtract, label: '差集', active: false },
    { icon: Icon.intersect, label: '交集', active: false },
    { icon: Icon.exclude, label: '排除', active: false },
  ]

  // 矢量：锚点操作
  private vectorAnchorTools: LayoutToolItem[] = [
    { icon: Icon.pen, label: '添加锚点', active: false },
    { icon: Icon.trash, label: '删除锚点', active: false },
    { icon: Icon.convert_anchor, label: '转换锚点', active: false },
    { icon: Icon.flip_h, label: '平滑/角点', active: false },
  ]

  // 矢量：编辑工具（原型 vectorEditTools.slice(0,4)）
  private vectorEditTools: LayoutToolItem[] = [
    { icon: Icon.bezier, label: '平滑路径', active: false },
    { icon: Icon.compress, label: '简化路径', active: false },
    { icon: Icon.flip_h, label: '偏移路径', active: false },
    { icon: Icon.link, label: '连接路径', active: false },
  ]

  // 矢量：形状预设（原型 shapePresets.slice(0,8)）
  private shapePresets: LayoutToolItem[] = [
    { icon: Icon.rect, label: '矩形', active: false },
    { icon: Icon.rect, label: '圆角矩形', active: false },
    { icon: Icon.circle, label: '椭圆', active: false },
    { icon: Icon.hexagon, label: '六边形', active: false },
    { icon: Icon.play, label: '三角形', active: false },
    { icon: Icon.stop, label: '八边形', active: false },
    { icon: Icon.diamond, label: '菱形', active: false },
    { icon: Icon.star, label: '星形', active: false },
  ]

  // 矢量：查找器（原型 vectorPathfinder，扩展工具弹出菜单）
  private vectorPathfinder: LayoutToolItem[] = [
    { icon: Icon.scissors, label: '分割', active: false },
    { icon: Icon.scissors, label: '修边', active: false },
    { icon: Icon.group, label: '合并', active: false },
    { icon: Icon.crop, label: '裁剪', active: false },
    { icon: Icon.rect, label: '轮廓', active: false },
    { icon: Icon.subtract, label: '减去后方', active: false },
    { icon: Icon.union, label: '加上前方', active: false },
  ]

  // 矢量：变形工具（原型 vectorWarp）
  private vectorWarp: LayoutToolItem[] = [
    { icon: Icon.hand, label: '变形工具', active: false },
    { icon: Icon.refresh, label: '扭转', active: false },
    { icon: Icon.compress, label: '收缩', active: false },
    { icon: Icon.expand, label: '膨胀', active: false },
    { icon: Icon.wand, label: '扇贝', active: false },
    { icon: Icon.diamond, label: '晶化', active: false },
    { icon: Icon.wand, label: '褶皱', active: false },
  ]

  // 矢量：轮廓（原型 vectorOutline）
  private vectorOutline: LayoutToolItem[] = [
    { icon: Icon.flip_h, label: '宽度工具', active: false },
    { icon: Icon.rect, label: '轮廓化描边', active: false },
    { icon: Icon.align_middle, label: '位移路径', active: false },
    { icon: Icon.pen, label: '书法画笔', active: false },
  ]

  // 矢量：生成工具（原型 vectorShapeBuilder）
  private vectorShapeBuilder: LayoutToolItem[] = [
    { icon: Icon.wand, label: '形状生成器', active: false },
    { icon: Icon.group, label: '路径查找器', active: false },
    { icon: Icon.subtract, label: '分割', active: false },
    { icon: Icon.union, label: '合并', active: false },
  ]

  // 矢量：混合工具（原型 vectorBlend）
  private vectorBlend: LayoutToolItem[] = [
    { icon: Icon.bezier, label: '混合工具', active: false },
    { icon: Icon.flip_h, label: '替换混合轴', active: false },
    { icon: Icon.refresh, label: '反向混合轴', active: false },
    { icon: Icon.ungroup, label: '释放', active: false },
  ]

  // 矢量：扩展形状预设（原型 shapePresets.slice(8)）
  private shapePresetsExtra: LayoutToolItem[] = [
    { icon: Icon.star, label: '五角星', active: false },
    { icon: Icon.hexagon, label: '多边形', active: false },
    { icon: Icon.diamond, label: '菱形', active: false },
    { icon: Icon.rect, label: '圆角矩形', active: false },
  ]

  // 多边形边数
  @State polygonSides: number = 5
  @State starPoints: number = 5
  @State starRadius: number = 50

  // 图片：描摹工具（原型 vectorImageTrace）
  private imageTraceTools: LayoutToolItem[] = [
    { icon: Icon.wand, label: '图像描摹', active: true },
    { icon: Icon.bolt, label: '快速描摹', active: false },
    { icon: Icon.pen_nib, label: '轮廓描摹', active: false },
    { icon: Icon.circle, label: '黑白徽标', active: false },
    { icon: Icon.pen, label: '素描图稿', active: false },
    { icon: Icon.gear, label: '技术图纸', active: false },
    { icon: Icon.image, label: '高保真照片', active: false },
    { icon: Icon.bezier, label: '线条稿', active: false },
    { icon: Icon.palette, label: '彩色图稿', active: false },
    { icon: Icon.sliders, label: '描摹预设', active: false },
  ]

  // 图片：滤镜（原型 imageFilters.slice(0,6)）
  private imageFilterTools: LayoutToolItem[] = [
    { icon: Icon.circle, label: '高斯模糊', active: false },
    { icon: Icon.bolt, label: '动感模糊', active: false },
    { icon: Icon.circle, label: '径向模糊', active: false },
    { icon: Icon.bolt, label: 'USM 锐化', active: false },
    { icon: Icon.wand, label: '智能锐化', active: false },
    { icon: Icon.square, label: '像素化', active: false },
  ]

  // 图片：调整（原型 imageAdjustments.slice(0,6)）
  private imageAdjustTools: LayoutToolItem[] = [
    { icon: Icon.sliders, label: '色阶', active: false },
    { icon: Icon.bezier, label: '曲线', active: false },
    { icon: Icon.palette, label: '色相/饱和度', active: false },
    { icon: Icon.sun, label: '亮度/对比度', active: false },
    { icon: Icon.palette, label: '色彩平衡', active: false },
    { icon: Icon.circle, label: '黑白', active: false },
  ]

  // 图片：效果（原型 imageEffects.slice(0,4)）
  private imageEffectTools: LayoutToolItem[] = [
    { icon: Icon.wand, label: '风格迁移', active: false },
    { icon: Icon.square, label: '3D 效果', active: false },
    { icon: Icon.diamond, label: '宝石效果', active: false },
    { icon: Icon.bolt, label: '火焰效果', active: false },
  ]

  // 色彩：取色工具（原型 colorPickTools）
  private colorPickTools: LayoutToolItem[] = [
    { icon: Icon.eyedropper, label: '吸管', active: false },
    { icon: Icon.palette, label: '颜色拾取器', active: false },
    { icon: Icon.book, label: '色板浏览器', active: false },
    { icon: Icon.circle, label: '屏幕取色', active: false },
  ]

  // 色彩：调整工具（原型 colorAdjustTools.slice(0,7)）
  private colorAdjustTools: LayoutToolItem[] = [
    { icon: Icon.sliders, label: '可选颜色', active: false },
    { icon: Icon.palette, label: '通道混合器', active: false },
    { icon: Icon.palette, label: '渐变映射', active: false },
    { icon: Icon.sliders, label: '替换颜色', active: false },
    { icon: Icon.palette, label: '颜色查找', active: false },
    { icon: Icon.circle, label: '色调分离', active: false },
    { icon: Icon.ellipsis, label: '色调均化', active: false },
  ]

  // 色彩：模式（已移到 @State colorModeTools）

  /** 显示 Toast 通知 */
  private showToast(message: string, icon: string, type: string): void {
    this.toastMessage = message
    this.toastIcon = icon
    this.toastType = type
    this.toastVisible = true
    setTimeout(() => { this.toastVisible = false }, 3000)
  }

  /** 工具点击反馈（原型：onToolClick → toastStore.show） */
  private onToolClick(groupId: string, item: LayoutToolItem): void {
    // 对齐/分布类工具支持 active 互斥切换
    if (groupId === 'align') {
      this.alignTools = this.alignTools.map((t: LayoutToolItem): LayoutToolItem => {
        return { icon: t.icon, label: t.label, active: t.label === item.label }
      })
    } else if (groupId === 'dist') {
      this.distTools = this.distTools.map((t: LayoutToolItem): LayoutToolItem => {
        return { icon: t.icon, label: t.label, active: t.label === item.label }
      })
    } else if (groupId === 'colorMode') {
      // 颜色模式互斥切换
      this.colorModeTools = this.colorModeTools.map((t: LayoutToolItem): LayoutToolItem => {
        return { icon: t.icon, label: t.label, active: t.label === item.label }
      })
    }
    // Toast 通知
    this.showToast(item.label, item.icon, 'success')
  }

  /** 主页按钮点击（原型：$emit('home')） */
  private onHomeClick(): void {
    this.showToast('返回主页', Icon.house, 'info')
  }

  build(): void {
    Column() {
      // 主行
      Row() {
        this.homeButton()

        Column()
          .width(1)
          .height(18)
          .backgroundColor(ColorToken.border)
          .margin({ left: 6, right: 6 })

        ForEach(this.toolGroups, (grp: ToolGroupItem) => {
          this.groupLabel(grp)
        })

        Blank()

        // W/H/∠ 显示（原型 gap-[7px]）
        Row() {
          Text('W')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
          Text('148')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 7 })
          Text('H')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .margin({ left: 7 })
          Text('92')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 7 })
          Text('∠')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .margin({ left: 7 })
          Text('0°')
            .fontSize(FontSizeToken.level2)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 7 })
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor(ColorToken.panel)
        .borderRadius(5)
        .border({ width: 1, color: ColorToken.border_light })
        .margin({ right: 10 })

        // 折叠按钮
        Column() {
          Text(this.collapsed ? Icon.chevron_down : Icon.chevron_up)
            .fontSize(10)
            .fontColor(ColorToken.muted)
            .textAlign(TextAlign.Center)
        }
        .width(26)
        .height(26)
        .borderRadius(5)
        .backgroundColor(this.hoveredTool === 'collapse' ? ColorToken.panel : Color.Transparent)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'collapse' : '' })
        .onClick(() => {
          this.collapsed = !this.collapsed
          if (this.collapsed) {
            this.toolGroups = this.toolGroups.map((g: ToolGroupItem): ToolGroupItem => {
              const item: ToolGroupItem = { id: g.id, label: g.label, icon: g.icon, expanded: false }
              return item
            })
          }
        })
      }
      .width('100%')
      .height(LayoutToken.tool_options_bar_height)
      .padding({ left: 10, right: 10 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(ColorToken.white)

      // 第二行：布局工具组
      if (this.isLayoutExpanded() && !this.collapsed) {
        this.layoutRow()
      }

      // 第三行：矢量工具组
      if (this.toolGroups[4].expanded && !this.collapsed) {
        this.vectorRow()
      }

      // 第四行：图片工具组
      if (this.toolGroups[5].expanded && !this.collapsed) {
        this.imageRow()
      }

      // 第五行：色彩工具组
      if (this.toolGroups[6].expanded && !this.collapsed) {
        this.colorRow()
      }
    }
    .backgroundColor(ColorToken.white)
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
  }

  private isLayoutExpanded(): boolean {
    return this.toolGroups[0].expanded || this.toolGroups[1].expanded ||
           this.toolGroups[2].expanded || this.toolGroups[3].expanded
  }

  @Builder
  homeButton(): void {
    Column() {
      Text(Icon.house)
        .fontSize(13)
        .fontColor(ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(30)
    .height(30)
    .borderRadius(7)
    .backgroundColor(this.hoveredTool === 'home' ? ColorToken.border_light : Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onHover((isHover: boolean) => { this.hoveredTool = isHover ? 'home' : '' })
    .onClick(() => { this.onHomeClick() })
  }

  @Builder
  groupLabel(grp: ToolGroupItem): void {
    Row() {
      Text(grp.expanded ? Icon.chevron_down : Icon.chevron_right)
        .fontSize(9)
        .fontColor(grp.expanded ? ColorToken.primary_dark_700 : ColorToken.muted)
      Text(grp.icon)
        .fontSize(11)
        .fontColor(grp.expanded ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .margin({ left: 5 })
      Text(grp.label)
        .fontSize(FontSizeToken.level3)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(grp.expanded ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .margin({ left: 5 })
    }
    .padding({ left: 9, right: 9, top: 5, bottom: 5 })
    .borderRadius(RadiusToken.md)
    .backgroundColor(grp.expanded ? ColorToken.hover_bg : (this.hoveredTool === grp.id ? ColorToken.border_light : Color.Transparent))
    .border({ width: grp.expanded ? 1 : 0, color: grp.expanded ? ColorToken.primary_light_300 : Color.Transparent })
    .margin({ right: 4 })
    .onHover((isHover: boolean) => { this.hoveredTool = isHover ? grp.id : '' })
    .onClick(() => {
      this.toolGroups = this.toolGroups.map((g: ToolGroupItem): ToolGroupItem => {
        const item: ToolGroupItem = { id: g.id, label: g.label, icon: g.icon, expanded: g.id === grp.id ? !g.expanded : g.expanded }
        return item
      })
    })
  }

  @Builder
  layoutRow(): void {
    Row() {
      if (this.toolGroups[0].expanded) {
        this.layoutGroup('编组', 'group', this.groupTools)
        if (this.toolGroups[1].expanded) this.layoutSeparator()
      }
      if (this.toolGroups[1].expanded) {
        this.layoutGroup('排列', 'arrange', this.arrangeTools)
        if (this.toolGroups[2].expanded) this.layoutSeparator()
      }
      if (this.toolGroups[2].expanded) {
        this.layoutGroup('对齐', 'align', this.alignTools)
        if (this.toolGroups[3].expanded) this.layoutSeparator()
      }
      if (this.toolGroups[3].expanded) {
        this.layoutGroup('分布', 'dist', this.distTools)
      }

      Blank()

      Text('对齐到')
        .fontSize(FontSizeToken.level2)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .margin({ right: 7 })

      Row() {
        Text(this.alignTarget === 'selection' ? '所选对象' : (this.alignTarget === 'artboard' ? '画板' : '关键对象'))
          .fontSize(FontSizeToken.level2)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
        Text(Icon.chevron_down)
          .fontSize(6)
          .fontColor(ColorToken.muted)
          .margin({ left: 4 })
      }
      .height(26)
      .padding({ left: 6, right: 6 })
      .backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.border })
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        const next = this.alignTarget === 'selection' ? 'artboard' : (this.alignTarget === 'artboard' ? 'key' : 'selection')
        this.alignTarget = next
      })
    }
    .width('100%')
    .padding({ left: SpacingToken.s3, right: SpacingToken.s3, top: 7, bottom: 7 })
    .backgroundColor(ColorToken.panel)
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  layoutSeparator(): void {
    Column()
      .width(1)
      .height(18)
      .backgroundColor(ColorToken.border)
      .margin({ left: 3, right: 3 })
  }

  @Builder
  layoutGroup(label: string, groupId: string, tools: LayoutToolItem[]): void {
    Row() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.bold)
        .fontColor(ColorToken.muted)
        .letterSpacing(0.8)
        .padding({ left: 5, right: 5 })

      ForEach(tools, (item: LayoutToolItem) => {
        this.layoutToolButtonWithGroup(item, groupId)
      })
    }
  }

  @Builder
  layoutToolButtonWithGroup(item: LayoutToolItem, groupId: string): void {
    Column() {
      Text(item.icon)
        .fontSize(12)
        .fontColor(item.active ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(28)
    .height(28)
    .borderRadius(5)
    .backgroundColor(item.active
      ? ColorToken.primary_light_100
      : (this.hoveredTool === item.label ? ColorToken.white : Color.Transparent))
    .border({
      width: item.active ? 1 : (this.hoveredTool === item.label ? 1 : 0),
      color: item.active ? ColorToken.primary_light_300 : (this.hoveredTool === item.label ? ColorToken.border : Color.Transparent)
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: 3 })
    .onHover((isHover: boolean) => { this.hoveredTool = isHover ? item.label : '' })
    .onClick(() => { this.onToolClick(groupId, item) })
  }

  @Builder
  layoutToolButton(item: LayoutToolItem): void {
    Column() {
      Text(item.icon)
        .fontSize(12)
        .fontColor(item.active ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(28)
    .height(28)
    .borderRadius(5)
    .backgroundColor(item.active
      ? ColorToken.primary_light_100
      : (this.hoveredTool === item.label ? ColorToken.white : Color.Transparent))
    .border({
      width: item.active ? 1 : (this.hoveredTool === item.label ? 1 : 0),
      color: item.active ? ColorToken.primary_light_300 : (this.hoveredTool === item.label ? ColorToken.border : Color.Transparent)
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ left: 3 })
    .onHover((isHover: boolean) => { this.hoveredTool = isHover ? item.label : '' })
    .onClick(() => { this.showToast(item.label, item.icon, 'success') })
  }

  // ─── 第三行：矢量工具组 ───
  @Builder
  vectorRow(): void {
    Row() {
      // 矢量标题（原型：fa-pen-nib + "矢量"，mr-[2px]）
      Row() {
        Text(Icon.pen_nib)
          .fontSize(12)
          .fontColor(ColorToken.primary_dark_700)
        Text('矢量')
          .fontSize(FontSizeToken.level3)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.primary_dark_700)
          .margin({ left: 5 })
      }
      .margin({ right: 2 })

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)

      // 路径组
      this.vectorToolGroup('路径', this.vectorBooleanTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 编辑组
      this.vectorToolGroup('编辑', this.vectorEditTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 形状组
      this.vectorToolGroup('形状', this.shapePresets)

      Blank()

      // 更多按钮（原型 ml-auto）
      this.vectorMoreButton()
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(ColorToken.panel)
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  vectorToolGroup(label: string, tools: LayoutToolItem[]): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.tertiary)
        .margin({ right: 4 })

      ForEach(tools, (item: LayoutToolItem) => {
        this.vectorToolButton(item)
      })
    }
    .margin({ left: 10 })
  }

  @Builder
  vectorToolButton(item: LayoutToolItem): void {
    Column() {
      Text(item.icon)
        .fontSize(12)
        .fontColor(item.active ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(30)
    .height(30)
    .borderRadius(6)
    .backgroundColor(item.active
      ? ColorToken.hover_bg
      : (this.hoveredTool === item.label ? ColorToken.hover_bg : ColorToken.white))
    .border({
      width: 1,
      color: item.active ? ColorToken.primary : ColorToken.border
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 4 })
    .onHover((isHover: boolean) => { this.hoveredTool = isHover ? item.label : '' })
    .onClick(() => { this.showToast(item.label, item.icon, 'success') })
  }

  @Builder
  vectorMoreButton(): void {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Text(Icon.ellipsis)
          .fontSize(12)
          .fontColor(ColorToken.secondary)
          .textAlign(TextAlign.Center)
      }
      .width(30)
      .height(30)
      .borderRadius(6)
      .backgroundColor(this.vectorMoreOpen ? ColorToken.hover_bg : ColorToken.white)
      .border({
        width: 1,
        color: this.vectorMoreOpen ? ColorToken.primary : ColorToken.border
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.vectorMoreOpen = !this.vectorMoreOpen
        if (this.vectorMoreOpen) {
          this.showToast('矢量扩展工具', Icon.pen_nib, 'info')
        }
      })

      // 矢量更多弹出菜单（原型：Teleport to body，min-w-[240px]）
      if (this.vectorMoreOpen) {
        Column() {
          // 头部
          Row() {
            Text('矢量 · 扩展工具')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.primary_dark_700)
          }
          .width('100%')
          .height(26)
          .padding({ left: 8, right: 8 })
          .backgroundColor(ColorToken.panel)
          .alignItems(VerticalAlign.Center)

          // 查找器组
          Row() {
            Text('查找器')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
            ForEach(this.vectorPathfinder, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Row().height(1).backgroundColor(ColorToken.border).margin({ left: 8, right: 8, top: 3, bottom: 3 })

          // 变形 + 轮廓组
          Row() {
            Text('变形')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
            ForEach(this.vectorWarp, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
            Text('轮廓')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
              .margin({ left: 4 })
            ForEach(this.vectorOutline, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Row().height(1).backgroundColor(ColorToken.border).margin({ left: 8, right: 8, top: 3, bottom: 3 })

          // 生成 + 混合组
          Row() {
            Text('生成')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
            ForEach(this.vectorShapeBuilder, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
            Text('混合')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
              .margin({ left: 4 })
            ForEach(this.vectorBlend, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Row().height(1).backgroundColor(ColorToken.border).margin({ left: 8, right: 8, top: 3, bottom: 3 })

          // 形状+组（扩展形状预设）
          Row() {
            Text('形状+')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
            ForEach(this.shapePresetsExtra, (item: LayoutToolItem) => {
              Column() {
                Text(item.icon)
                  .fontSize(10)
                  .fontColor(ColorToken.secondary)
              }
              .width(26)
              .height(26)
              .borderRadius(3)
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ right: 2 })
              .onClick(() => { this.showToast(item.label, item.icon, 'success') })
            })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .alignItems(VerticalAlign.Center)

          // 分隔线
          Row().height(1).backgroundColor(ColorToken.border).margin({ left: 8, right: 8, top: 3, bottom: 3 })

          // 多边形 + 星形参数组（原型：多边形边数 + 星形角数/半径）
          Row() {
            Text('多边形')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .width(36)
            // 减号按钮
            Column() {
              Text(Icon.minus)
                .fontSize(6)
                .fontColor(ColorToken.secondary)
            }
            .width(18)
            .height(18)
            .borderRadius(2)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => { this.polygonSides = Math.max(3, this.polygonSides - 1) })

            // 边数显示
            Text(`${this.polygonSides}`)
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.body)
              .width(32)
              .height(18)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius(2)
              .textAlign(TextAlign.Center)
              .margin({ left: 2 })

            // 加号按钮
            Column() {
              Text(Icon.plus)
                .fontSize(6)
                .fontColor(ColorToken.secondary)
            }
            .width(18)
            .height(18)
            .borderRadius(2)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 2 })
            .onClick(() => { this.polygonSides = Math.min(60, this.polygonSides + 1) })

            Text('边')
              .fontSize(9)
              .fontColor(ColorToken.muted)
              .margin({ left: 4 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .alignItems(VerticalAlign.Center)
        }
        .width(240)
        .borderRadius(8)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow({ radius: 16, color: '#0000002E', offsetX: 0, offsetY: 4 })
        .padding({ top: 4, bottom: 4 })
        .position({ x: -210, y: 36 })
        .zIndex(200)
      }
    }
    .width(30)
    .height(30)
  }

  @Builder
  imageMoreButton(): void {
    Column() {
      Text(Icon.ellipsis)
        .fontSize(12)
        .fontColor(ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(30)
    .height(30)
    .borderRadius(6)
    .backgroundColor(ColorToken.white)
    .border({ width: 1, color: ColorToken.border })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.showToast('更多图片工具', Icon.ellipsis, 'info') })
  }

  // ─── 第四行：图片工具组 ───
  @Builder
  imageRow(): void {
    Row() {
      // 图片标题（原型：fa-image + "图片"，mr-[2px]）
      Row() {
        Text(Icon.image)
          .fontSize(12)
          .fontColor(ColorToken.secondary)
        Text('图片')
          .fontSize(FontSizeToken.level3)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.secondary)
          .margin({ left: 5 })
      }
      .margin({ right: 2 })

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)

      // 描摹组
      this.imageToolGroup('描摹', this.imageTraceTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 滤镜组
      this.imageToolGroup('滤镜', this.imageFilterTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 调整组
      this.imageToolGroup('调整', this.imageAdjustTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 效果组
      this.imageToolGroup('效果', this.imageEffectTools)

      Blank()

      // 更多按钮
      this.imageMoreButton()
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(ColorToken.panel)
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  imageToolGroup(label: string, tools: LayoutToolItem[]): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.tertiary)
        .margin({ right: 4 })

      ForEach(tools, (item: LayoutToolItem) => {
        this.vectorToolButton(item)
      })
    }
    .margin({ left: 10 })
  }

  // ─── 第五行：色彩工具组 ───
  @Builder
  colorRow(): void {
    Row() {
      // 色彩标题（原型：fa-palette + "色彩"，mr-[2px]）
      Row() {
        Text(Icon.palette)
          .fontSize(12)
          .fontColor(ColorToken.secondary)
        Text('色彩')
          .fontSize(FontSizeToken.level3)
          .fontWeight(FontWeightConstant.bold)
          .fontColor(ColorToken.secondary)
          .margin({ left: 5 })
      }
      .margin({ right: 2 })

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)

      // 取色组
      this.colorToolGroup('取色', this.colorPickTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 调整组
      this.colorToolGroup('调整', this.colorAdjustTools)

      Column()
        .width(1)
        .height(18)
        .backgroundColor(ColorToken.border)
        .margin({ left: 10 })

      // 模式组（文字按钮）
      Row() {
        Text('模式')
          .fontSize(11)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(ColorToken.tertiary)
          .margin({ right: 4 })

        ForEach(this.colorModeTools, (item: LayoutToolItem) => {
          this.colorModeButton(item)
        })
      }
      .margin({ left: 10 })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(ColorToken.panel)
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  colorToolGroup(label: string, tools: LayoutToolItem[]): void {
    Row() {
      Text(label)
        .fontSize(11)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.tertiary)
        .margin({ right: 4 })

      ForEach(tools, (item: LayoutToolItem) => {
        this.vectorToolButton(item)
      })
    }
    .margin({ left: 10 })
  }

  @Builder
  colorModeButton(item: LayoutToolItem): void {
    Column() {
      Text(item.label)
        .fontSize(12)
        .fontWeight(FontWeightConstant.bold)
        .fontColor(item.active ? ColorToken.primary_dark_700 : ColorToken.secondary)
        .textAlign(TextAlign.Center)
    }
    .width(30)
    .height(30)
    .borderRadius(6)
    .backgroundColor(item.active ? ColorToken.hover_bg : ColorToken.white)
    .border({
      width: 1,
      color: item.active ? ColorToken.primary : ColorToken.border
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ right: 4 })
    .onClick(() => { this.onToolClick('colorMode', item) })
  }
}
