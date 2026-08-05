/**
 * ContextMenu - 通用右键菜单
 *
 * 对应原型 src/components/ContextMenu.vue + data/contextMenuItems.ts
 * 支持：5套菜单（text/image/shape/page/canvas）+ 图标 + 快捷键 + 分隔符 + 危险操作红色
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontSizeToken, SpacingToken, RadiusToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

/** 菜单项数据 */
export interface CtxMenuItem {
  label: string
  icon: string
  shortcut: string
  action: string
  divider: boolean
  disabled: boolean
  danger: boolean
  children?: CtxMenuItem[]
}

/** 根据类型获取菜单项 */
export function getCtxMenuItems(type: string): CtxMenuItem[] {
  if (type === 'text') return textCtxItems
  if (type === 'image') return imageCtxItems
  if (type === 'shape') return shapeCtxItems
  if (type === 'page') return pageCtxItems
  if (type === 'pageList') return pageListItemCtxItems
  return canvasCtxItems
}

/** 创建一个空菜单项（用于分隔符或占位） */
function emptyItem(): CtxMenuItem {
  return { label: '', icon: '', shortcut: '', action: '', divider: true, disabled: false, danger: false }
}

/** 创建一个菜单项 */
function item(label: string, icon: string, action: string, shortcut: string = '', divider: boolean = false, disabled: boolean = false, danger: boolean = false, children?: CtxMenuItem[]): CtxMenuItem {
  return { label, icon, action, shortcut, divider, disabled, danger, children }
}

/** 创建分隔符 */
function divider(): CtxMenuItem {
  return { label: '', icon: '', shortcut: '', action: '', divider: true, disabled: false, danger: false }
}

// ─── 复用片段 ───
const layerOrderItems: CtxMenuItem[] = [
  { label: '移到顶层', icon: Icon.arrow_up, shortcut: 'Ctrl+⇧+]', action: 'bringToFront', divider: false, disabled: false, danger: false },
  { label: '上移一层', icon: Icon.arrow_up, shortcut: 'Ctrl+]', action: 'bringForward', divider: false, disabled: false, danger: false },
  { label: '下移一层', icon: Icon.arrow_down, shortcut: 'Ctrl+[', action: 'sendBackward', divider: false, disabled: false, danger: false },
  { label: '移到底层', icon: Icon.arrow_down, shortcut: 'Ctrl+⇧+[', action: 'sendToBack', divider: true, disabled: false, danger: false },
]

const commonItems: CtxMenuItem[] = [
  { label: '剪切', icon: Icon.cut, shortcut: 'Ctrl+X', action: 'cut', divider: false, disabled: false, danger: false },
  { label: '复制', icon: Icon.copy, shortcut: 'Ctrl+C', action: 'copy', divider: false, disabled: false, danger: false },
  { label: '粘贴', icon: Icon.paste, shortcut: 'Ctrl+V', action: 'paste', divider: true, disabled: false, danger: false },
  ...layerOrderItems,
  { label: '编组', icon: Icon.group, shortcut: 'Ctrl+G', action: 'group', divider: false, disabled: false, danger: false },
  { label: '解组', icon: Icon.ungroup, shortcut: 'Ctrl+⇧+G', action: 'ungroup', divider: false, disabled: false, danger: false },
  { label: '锁定', icon: Icon.lock, shortcut: 'Ctrl+L', action: 'lock', divider: false, disabled: false, danger: false },
  { label: '隐藏', icon: Icon.eye_off, shortcut: 'Ctrl+3', action: 'hide', divider: true, disabled: false, danger: false },
  { label: '复制图层', icon: Icon.copy, shortcut: 'Ctrl+J', action: 'duplicateLayer', divider: false, disabled: false, danger: false },
  { label: '合并图层', icon: Icon.layers, shortcut: 'Ctrl+E', action: 'mergeDown', divider: true, disabled: false, danger: false },
  { label: '删除', icon: Icon.trash, shortcut: 'Delete', action: 'delete', divider: false, disabled: false, danger: true },
]

// ─── 文字元素右键 ───
const textCtxItems: CtxMenuItem[] = [
  { label: '编辑文字', icon: Icon.text, shortcut: '', action: 'editText', divider: false, disabled: false, danger: false },
  { label: '复制文本', icon: Icon.copy, shortcut: 'Ctrl+C', action: 'copyText', divider: true, disabled: false, danger: false },
  ...commonItems,
  { label: '字体设置', icon: Icon.text, shortcut: 'Ctrl+T', action: 'fontSettings', divider: false, disabled: false, danger: false },
  { label: '段落设置', icon: Icon.list, shortcut: 'Ctrl+Alt+T', action: 'paragraphSettings', divider: true, disabled: false, danger: false },
  { label: '加粗', icon: Icon.text, shortcut: 'Ctrl+B', action: 'bold', divider: false, disabled: false, danger: false },
  { label: '斜体', icon: Icon.text, shortcut: 'Ctrl+I', action: 'italic', divider: false, disabled: false, danger: false },
  { label: '下划线', icon: Icon.text, shortcut: 'Ctrl+U', action: 'underline', divider: true, disabled: false, danger: false },
  { label: '增大字号', icon: Icon.plus, shortcut: 'Ctrl+⇧+>', action: 'increaseFont', divider: false, disabled: false, danger: false },
  { label: '减小字号', icon: Icon.minus, shortcut: 'Ctrl+⇧+<', action: 'decreaseFont', divider: false, disabled: false, danger: false },
  { label: '创建轮廓', icon: Icon.pen, shortcut: 'Ctrl+⇧+O', action: 'createOutline', divider: false, disabled: false, danger: false },
]

// ─── 图片元素右键 ───
const imageCtxItems: CtxMenuItem[] = [
  { label: '替换图片', icon: Icon.image, shortcut: '', action: 'replaceImage', divider: false, disabled: false, danger: false },
  { label: '调整图像', icon: Icon.palette, shortcut: '', action: 'adjustImage', divider: false, disabled: false, danger: false },
  { label: '裁剪', icon: Icon.grid, shortcut: 'C', action: 'cropImage', divider: false, disabled: false, danger: false },
  { label: '变换', icon: Icon.scale, shortcut: 'Ctrl+T', action: 'freeTransform', divider: true, disabled: false, danger: false },
  ...commonItems,
  { label: '添加蒙版', icon: Icon.layers, shortcut: '', action: 'addMask', divider: false, disabled: false, danger: false },
  { label: '调整...', icon: Icon.palette, shortcut: '', action: 'adjustments', divider: false, disabled: false, danger: false, children: [
    { label: '色阶', icon: Icon.grid, shortcut: '', action: 'levels', divider: false, disabled: false, danger: false },
    { label: '曲线', icon: Icon.grid, shortcut: '', action: 'curves', divider: false, disabled: false, danger: false },
    { label: '色相/饱和度', icon: Icon.palette, shortcut: '', action: 'hueSaturation', divider: false, disabled: false, danger: false },
    { label: '亮度/对比度', icon: Icon.grid, shortcut: '', action: 'brightnessContrast', divider: false, disabled: false, danger: false },
    { label: '色彩平衡', icon: Icon.scale, shortcut: '', action: 'colorBalance', divider: false, disabled: false, danger: false },
    { label: '黑白', icon: Icon.grid, shortcut: '', action: 'blackWhite', divider: false, disabled: false, danger: false },
  ]},
  { label: '滤镜', icon: Icon.wand, shortcut: '', action: 'filters', divider: false, disabled: false, danger: false, children: [
    { label: '高斯模糊', icon: Icon.droplet, shortcut: '', action: 'gaussianBlur', divider: false, disabled: false, danger: false },
    { label: '锐化', icon: Icon.grid, shortcut: '', action: 'sharpen', divider: false, disabled: false, danger: false },
    { label: '杂色', icon: Icon.grid, shortcut: '', action: 'noise', divider: false, disabled: false, danger: false },
    { label: '扭曲', icon: Icon.wand, shortcut: '', action: 'distort', divider: false, disabled: false, danger: false },
  ]},
  { label: '转换为智能对象', icon: Icon.grid, shortcut: '', action: 'smartObject', divider: false, disabled: false, danger: false },
  { label: '栅格化', icon: Icon.grid, shortcut: '', action: 'rasterize', divider: false, disabled: false, danger: false },
  { label: '导出为...', icon: Icon.export, shortcut: '', action: 'exportImage', divider: false, disabled: false, danger: false },
]

// 参考线子菜单（页面/画布共用）
const guideSettingsChildren: CtxMenuItem[] = [
  { label: '锁定参考线', icon: Icon.lock, shortcut: 'Ctrl+Alt+;', action: 'lockGuides', divider: false, disabled: false, danger: false },
  { label: '清除参考线', icon: Icon.trash, shortcut: '', action: 'clearGuides', divider: false, disabled: false, danger: false },
  { label: '新建参考线', icon: Icon.plus, shortcut: '', action: 'newGuide', divider: false, disabled: false, danger: false },
]

// ─── 形状元素右键 ───
const shapeCtxItems: CtxMenuItem[] = [
  { label: '编辑路径', icon: Icon.pen, shortcut: '', action: 'editPath', divider: false, disabled: false, danger: false },
  { label: '填充颜色', icon: Icon.palette, shortcut: '', action: 'fillColor', divider: false, disabled: false, danger: false },
  { label: '描边设置', icon: Icon.pen, shortcut: '', action: 'strokeSettings', divider: false, disabled: false, danger: false },
  { label: '变换', icon: Icon.scale, shortcut: 'Ctrl+T', action: 'freeTransform', divider: true, disabled: false, danger: false },
  ...commonItems,
  { label: '路径查找器', icon: Icon.group, shortcut: '', action: 'pathfinder', divider: false, disabled: false, danger: false, children: [
    { label: '合集', icon: Icon.group, shortcut: '', action: 'unite', divider: false, disabled: false, danger: false },
    { label: '差集', icon: Icon.ungroup, shortcut: '', action: 'minusFront', divider: false, disabled: false, danger: false },
    { label: '交集', icon: Icon.rect, shortcut: '', action: 'intersect', divider: false, disabled: false, danger: false },
    { label: '排除', icon: Icon.rect, shortcut: '', action: 'exclude', divider: false, disabled: false, danger: false },
  ]},
  { label: '转换为曲线', icon: Icon.bezier, shortcut: '', action: 'convertToCurve', divider: false, disabled: false, danger: false },
  { label: '圆角设置', icon: Icon.grid, shortcut: '', action: 'cornerRadius', divider: false, disabled: false, danger: false },
  { label: '效果设置', icon: Icon.wand, shortcut: '', action: 'shapeEffects', divider: false, disabled: false, danger: false, children: [
    { label: '投影', icon: Icon.shadow, shortcut: '', action: 'dropShadow', divider: false, disabled: false, danger: false },
    { label: '内阴影', icon: Icon.shadow, shortcut: '', action: 'innerShadow', divider: false, disabled: false, danger: false },
    { label: '外发光', icon: Icon.grid, shortcut: '', action: 'outerGlow', divider: false, disabled: false, danger: false },
    { label: '内发光', icon: Icon.grid, shortcut: '', action: 'innerGlow', divider: false, disabled: false, danger: false },
    { label: '模糊', icon: Icon.droplet, shortcut: '', action: 'blur', divider: false, disabled: false, danger: false },
  ]},
  { label: '渐变填充', icon: Icon.palette, shortcut: '', action: 'gradientFill', divider: false, disabled: false, danger: false },
  { label: '复制样式', icon: Icon.copy, shortcut: '', action: 'copyStyle', divider: false, disabled: false, danger: false },
  { label: '粘贴样式', icon: Icon.paste, shortcut: '', action: 'pasteStyle', divider: false, disabled: false, danger: false },
]

// ─── 页面右键 ───
const pageCtxItems: CtxMenuItem[] = [
  { label: '粘贴', icon: Icon.paste, shortcut: 'Ctrl+V', action: 'paste', divider: false, disabled: false, danger: false },
  { label: '全选', icon: Icon.group, shortcut: 'Ctrl+A', action: 'selectAll', divider: false, disabled: false, danger: false },
  { label: '取消选择', icon: Icon.xmark, shortcut: 'Ctrl+D', action: 'deselect', divider: true, disabled: false, danger: false },
  { label: '页面设置', icon: Icon.gear, shortcut: '', action: 'pageSetup', divider: false, disabled: false, danger: false },
  { label: '边距与分栏', icon: Icon.grid, shortcut: '', action: 'marginsColumns', divider: false, disabled: false, danger: false },
  { label: '出血设置', icon: Icon.scale, shortcut: '', action: 'bleedSettings', divider: false, disabled: false, danger: false },
  { label: '网格设置', icon: Icon.grid, shortcut: '', action: 'gridSettings', divider: false, disabled: false, danger: false },
  { label: '参考线', icon: Icon.plus, shortcut: '', action: 'guideSettings', divider: false, disabled: false, danger: false, children: guideSettingsChildren },
  { label: '色彩空间', icon: Icon.palette, shortcut: '', action: 'colorSpace', divider: true, disabled: false, danger: false },
  { label: '文档设置', icon: Icon.gear, shortcut: 'Ctrl+Alt+P', action: 'docSettings', divider: false, disabled: false, danger: false },
]

// ─── 画布右键 ───
const canvasCtxItems: CtxMenuItem[] = [
  { label: '粘贴', icon: Icon.paste, shortcut: 'Ctrl+V', action: 'paste', divider: false, disabled: false, danger: false },
  { label: '全选', icon: Icon.group, shortcut: 'Ctrl+A', action: 'selectAll', divider: true, disabled: false, danger: false },
  { label: '标尺', icon: Icon.eye, shortcut: 'Ctrl+R', action: 'toggleRuler', divider: false, disabled: false, danger: false },
  { label: '网格', icon: Icon.grid, shortcut: 'Ctrl+"', action: 'toggleGrid', divider: false, disabled: false, danger: false },
  { label: '参考线', icon: Icon.plus, shortcut: '', action: 'guideSettings', divider: false, disabled: false, danger: false, children: guideSettingsChildren },
  { label: '吸附', icon: Icon.grid, shortcut: 'Ctrl+⇧+;', action: 'toggleSnap', divider: true, disabled: false, danger: false },
  { label: '放大', icon: Icon.zoom_in, shortcut: 'Ctrl++', action: 'zoomIn', divider: false, disabled: false, danger: false },
  { label: '缩小', icon: Icon.zoom_out, shortcut: 'Ctrl+-', action: 'zoomOut', divider: false, disabled: false, danger: false },
  { label: '适配画布', icon: Icon.zoom_fit, shortcut: 'Ctrl+0', action: 'fitCanvas', divider: false, disabled: false, danger: false },
  { label: '实际像素', icon: Icon.eye, shortcut: 'Ctrl+1', action: 'actualPixels', divider: true, disabled: false, danger: false },
  { label: '显示设置', icon: Icon.gear, shortcut: '', action: 'displaySettings', divider: false, disabled: false, danger: false, children: [
    { label: '画布颜色...', icon: Icon.palette, shortcut: '', action: 'canvasColor', divider: false, disabled: false, danger: false },
    { label: '显示页面阴影', icon: Icon.rect, shortcut: '', action: 'togglePageShadow', divider: false, disabled: false, danger: false },
    { label: '显示页面边界', icon: Icon.grid, shortcut: '', action: 'togglePageBorder', divider: false, disabled: false, danger: false },
  ]},
  { label: '视图旋转', icon: Icon.rotate, shortcut: 'R', action: 'rotateView', divider: false, disabled: false, danger: false },
]

// ─── 页面列表项右键 ───
const pageListItemCtxItems: CtxMenuItem[] = [
  { label: '新建页面', icon: Icon.rect, shortcut: 'Ctrl+⇧+P', action: 'new', divider: false, disabled: false, danger: false },
  { label: '复制页面', icon: Icon.copy, shortcut: 'Ctrl+J', action: 'duplicate', divider: false, disabled: false, danger: false },
  { label: '重命名', icon: Icon.pen, shortcut: '', action: 'rename', divider: true, disabled: false, danger: false },
  { label: '上移', icon: Icon.arrow_up, shortcut: 'Ctrl+↑', action: 'moveUp', divider: false, disabled: false, danger: false },
  { label: '下移', icon: Icon.arrow_down, shortcut: 'Ctrl+↓', action: 'moveDown', divider: true, disabled: false, danger: false },
  { label: '应用母版', icon: Icon.layers, shortcut: '', action: 'applyMaster', divider: false, disabled: false, danger: false },
  { label: '页面设置', icon: Icon.gear, shortcut: '', action: 'settings', divider: false, disabled: false, danger: false },
  { label: '导出页面', icon: Icon.export, shortcut: '', action: 'exportPage', divider: false, disabled: false, danger: false, children: [
    { label: '导出为 PNG', icon: Icon.image, shortcut: '', action: 'exportPng', divider: false, disabled: false, danger: false },
    { label: '导出为 PDF', icon: Icon.rect, shortcut: '', action: 'exportPdf', divider: false, disabled: false, danger: false },
    { label: '导出为 JPG', icon: Icon.image, shortcut: '', action: 'exportJpg', divider: false, disabled: false, danger: false },
  ]},
  { label: '删除页面', icon: Icon.trash, shortcut: '', action: 'delete', divider: true, disabled: false, danger: true },
]

@Component
export struct ContextMenu {
  @Prop visible: boolean = false
  @Prop menuX: number = 0
  @Prop menuY: number = 0
  @Prop menuType: string = 'canvas'
  onAction: (action: string) => void = () => {}
  onClose: () => void = () => {}
  @State hoveredItem: string = ''
  @State activeSub: string = ''

  build(): void {
    if (this.visible) {
      Stack({ alignContent: Alignment.TopStart }) {
        // 透明遮罩（点击关闭）
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.onClose(); this.activeSub = '' })

        // 菜单主体（min-w-[210px]，原型圆角 rounded-[10px]）
        Column() {
          Scroll() {
            Column() {
              ForEach(this.getItems(), (item: CtxMenuItem) => {
                if (item.divider && item.label === '') {
                  // 分隔符（mx-[8px] my-[4px]）
                  Row()
                    .height(1)
                    .backgroundColor(ColorToken.border_light)
                    .margin({ left: 8, right: 8, top: 4, bottom: 4 })
                } else {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    this.menuItemRow(item)
                    // 子菜单（绝对定位，位于父菜单右侧）
                    if (item.children && item.children.length > 0 && this.activeSub === item.label) {
                      this.subMenu(item.children!)
                    }
                  }
                  if (item.divider) {
                    Row()
                      .height(1)
                      .backgroundColor(ColorToken.border_light)
                      .margin({ left: 8, right: 8, top: 4, bottom: 4 })
                  }
                }
              })
            }
            .width('100%')
          }
          .scrollBar(BarState.Off)
          .constraintSize({ maxHeight: 400 })
        }
        .width(220)
        .constraintSize({ minWidth: 210 })
        .padding({ top: 6, bottom: 6 })
        .borderRadius(RadiusToken.xl)
        .backgroundColor(ColorToken.white)
        // 原型：双层阴影 0_8px_32px_rgba(0,0,0,0.12),0_2px_8px_rgba(0,0,0,0.06)
        // ArkUI 不支持双层阴影叠加，这里使用稍深的单层阴影近似还原视觉层次感
        .shadow({ radius: 32, color: '#00000026', offsetX: 0, offsetY: 8 })
        .border({ width: 1, color: ColorToken.border })
        .position({ x: this.menuX, y: this.menuY })
        .zIndex(ZIndexToken.dropdown)
      }
      .width('100%')
      .height('100%')
      .zIndex(ZIndexToken.dropdown)
    }
  }

  @Builder
  menuItemRow(item: CtxMenuItem): void {
    Row() {
      // 图标（w-[15px]）
      Text(item.icon)
        .fontSize(11)
        .fontColor(item.disabled ? ColorToken.muted : (item.danger ? ColorToken.error : ColorToken.tertiary))
        .width(15)
        .textAlign(TextAlign.Center)

      // 标签（gap-[9px]，原型：hover 时仅背景变化，文字色不变）
      // 原型：font-[450]（介于regular和medium之间），ETS使用regular更接近
      Text(item.label)
        .fontSize(item.disabled ? 10 : FontSizeToken.level3)
        .fontWeight(item.disabled ? FontWeightConstant.semibold : FontWeightConstant.regular)
        .fontColor(item.disabled
          ? ColorToken.muted
          : (item.danger ? ColorToken.error : ColorToken.body))
        .letterSpacing(item.disabled ? 1 : 0)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: 9 })
        .layoutWeight(1)

      // 快捷键（带背景 var(--color-panel) + 圆角3px + padding）
      // 原型：始终使用 #9AA2AC 颜色，disabled 时父级 opacity 控制
      if (item.shortcut !== '') {
        Text(item.shortcut)
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor('#9AA2AC')
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 8 })
          .borderRadius(3)
          .backgroundColor(ColorToken.panel)
      }

      // 子菜单指示箭头（chevron_right）
      if (item.children && item.children.length > 0) {
        Text(Icon.chevron_right)
          .fontSize(7)
          .fontColor(ColorToken.muted)
          .margin({ left: 8 })
      }
    }
    .width('100%')
    .height(30)
    .padding({ left: 10, right: 10 })
    .margin({ left: 4, right: 4 })
    .borderRadius(RadiusToken.md)
    .backgroundColor(this.hoveredItem === item.action || this.activeSub === item.label ? ColorToken.hover_bg : Color.Transparent)
    .alignItems(VerticalAlign.Center)
    .opacity(item.disabled ? 0.4 : 1)
    .onHover((isHover: boolean) => {
      this.hoveredItem = isHover ? item.action : ''
      // 有子菜单的项 hover 时自动展开
      if (isHover && item.children && item.children.length > 0) {
        this.activeSub = item.label
      } else if (!isHover && item.children && item.children.length > 0 && this.activeSub === item.label) {
        // 不立即关闭，让用户可以移动到子菜单
      }
    })
    .onClick(() => {
      if (item.disabled) return
      if (item.children && item.children.length > 0) {
        this.activeSub = this.activeSub === item.label ? '' : item.label
      } else {
        this.onAction(item.action)
        this.onClose()
        this.activeSub = ''
      }
    })
  }

  // 子菜单（位于父菜单右侧，top: -6px）
  @Builder
  subMenu(children: CtxMenuItem[]): void {
    Column() {
      Scroll() {
        Column() {
          ForEach(children, (sub: CtxMenuItem) => {
            Row() {
              // 子菜单图标（w-[13px]）
              Text(sub.icon)
                .fontSize(10)
                .fontColor(ColorToken.tertiary)
                .width(13)
                .textAlign(TextAlign.Center)

              // 子菜单标签（原型：whitespace-nowrap，font-[450]）
              Text(sub.label)
                .fontSize(11)
                .fontWeight(FontWeightConstant.regular)
                .fontColor(ColorToken.body)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ left: 8 })
                .layoutWeight(1)

              // 子菜单快捷键
              if (sub.shortcut !== '') {
                Text(sub.shortcut)
                  .fontSize(9)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor('#9AA2AC')
                  .margin({ left: 8 })
              }
            }
            .width('100%')
            .height(28)
            .padding({ left: 10, right: 10 })
            .margin({ left: 4, right: 4 })
            .borderRadius(RadiusToken.md)
            .backgroundColor(this.hoveredItem === sub.action ? ColorToken.hover_bg : Color.Transparent)
            .alignItems(VerticalAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredItem = isHover ? sub.action : '' })
            .onClick(() => {
              this.onAction(sub.action)
              this.onClose()
              this.activeSub = ''
            })
          })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .constraintSize({ maxHeight: 320 })
    }
    .width(180)
    .padding({ top: 6, bottom: 6 })
    .borderRadius(RadiusToken.xl)
    .backgroundColor(ColorToken.white)
    // 原型：0_8px_32px_rgba(0,0,0,0.12)（radius 32）
    .shadow({ radius: 32, color: '#0000001F', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: ColorToken.border })
    // 原型：相对父菜单 right + 2px
    .position({ x: 224, y: -6 })
    .zIndex(ZIndexToken.dropdown + 1)
  }

  private getItems(): CtxMenuItem[] {
    return getCtxMenuItems(this.menuType)
  }
}
