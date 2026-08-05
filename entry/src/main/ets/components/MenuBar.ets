/**
 * MenuBar - 菜单栏（支持多级子菜单）
 *
 * 对应原型 src/components/MenuBar.vue
 * 功能：10 组菜单项，支持多级子菜单弹出、悬停切换、分隔线、快捷键显示
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { MENU_ITEMS, MenuBarItem, SubMenuItem } from '../data/MenuItems'

@Component
export struct MenuBar {
  @State activeMenu: string = ''
  @State hoveredMenu: string = ''
  @State hoveredItem: string = ''
  @State hoveredAction: string = ''
  @State openSubMenu: string = ''
  @State openSubSubMenu: string = ''
  @StorageLink('currentTheme') currentTheme: string = 'light'
  @StorageLink('showPagesPanel') showPagesPanel: boolean = true
  @StorageLink('showInspector') showInspector: boolean = true
  @StorageLink('showHistoryPanel') showHistoryPanel: boolean = false
  @StorageLink('toastMessage') toastMessage: string = ''
  @StorageLink('toastIcon') toastIcon: string = ''
  @StorageLink('toastType') toastType: string = 'info'
  @StorageLink('toastVisible') toastVisible: boolean = false
  @State isMaximized: boolean = false

  private menus: MenuBarItem[] = MENU_ITEMS

  /** 显示 Toast 通知 */
  private showToast(message: string, icon: string, type: string): void {
    this.toastMessage = message
    this.toastIcon = icon
    this.toastType = type
    this.toastVisible = true
    setTimeout(() => { this.toastVisible = false }, 3000)
  }

  /** 切换主题 */
  private toggleTheme(): void {
    this.currentTheme = this.currentTheme === 'dark' ? 'light' : 'dark'
    AppStorage.setOrCreate<string>('currentTheme', this.currentTheme)
    this.showToast(
      this.currentTheme === 'dark' ? '已切换暗色模式' : '已切换亮色模式',
      this.currentTheme === 'dark' ? Icon.moon : Icon.sun,
      'info'
    )
  }

  /** 菜单项点击 */
  private onMenuItemClick(label: string): void {
    if (label === '新建') this.showToast('新建文档', Icon.file_new, 'info')
    else if (label === '保存') this.showToast('文档已保存', Icon.save, 'success')
    else if (label === '导出') this.showToast('导出中...', Icon.export, 'info')
    else if (label === '撤销') this.showToast('已撤销', Icon.undo, 'info')
    else if (label === '重做') this.showToast('已重做', Icon.redo, 'info')
    else if (label === '编组') this.showToast('已编组', Icon.group, 'success')
    else if (label === '解组') this.showToast('已解组', Icon.ungroup, 'success')
    else if (label === '隐藏面板') {
      this.showPagesPanel = !this.showPagesPanel
      this.showInspector = !this.showInspector
      this.showToast(this.showPagesPanel ? '面板已显示' : '面板已隐藏', Icon.eye, 'info')
    }
    else if (label === '历史记录') {
      this.showHistoryPanel = !this.showHistoryPanel
      this.showToast(this.showHistoryPanel ? '历史记录已显示' : '历史记录已隐藏', Icon.history, 'info')
    }
    else this.showToast(label, Icon.info, 'info')
    this.activeMenu = ''
    this.openSubMenu = ''
    this.openSubSubMenu = ''
  }

  /** 获取菜单项是否有子菜单 */
  private hasChildren(item: SubMenuItem): boolean {
    return !!(item.children && item.children.length > 0)
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      // ─── 主菜单栏 ───
      Row() {
        // Logo 区
        Row() {
          Column() {
            Text(Icon.bezier)
              .fontSize(11)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.white)
              .textAlign(TextAlign.Center)
          }
          .width(20)
          .height(20)
          .borderRadius(RadiusToken.sm)
          .backgroundColor(ColorToken.primary)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Text('Harmony Design')
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.title)
            .margin({ left: SpacingToken.s2 })
        }
        .margin({ left: SpacingToken.s3, right: 20 })

        // 菜单项
        Row() {
          ForEach(this.menus, (menu: MenuBarItem) => {
            Text(menu.label)
              .fontSize(FontSizeToken.level3)
              .fontWeight(this.activeMenu === menu.label ? FontWeightConstant.medium : FontWeightConstant.regular)
              .fontColor(this.activeMenu === menu.label
                ? ColorToken.primary_dark_700
                : (this.hoveredMenu === menu.label ? ColorToken.title : ColorToken.body))
              .padding({ left: 4, right: 4, top: 6, bottom: 6 })
              .borderRadius(5)
              .backgroundColor(this.activeMenu === menu.label
                ? ColorToken.hover_bg
                : (this.hoveredMenu === menu.label ? ColorToken.border_light : Color.Transparent))
              .margin({ right: 18 })
              .onClick(() => {
                this.activeMenu = this.activeMenu === menu.label ? '' : menu.label
                this.openSubMenu = ''
                this.openSubSubMenu = ''
              })
              .onHover((isHover: boolean) => {
                this.hoveredMenu = isHover ? menu.label : ''
                if (isHover && this.activeMenu !== '') {
                  this.activeMenu = menu.label
                  this.openSubMenu = ''
                  this.openSubSubMenu = ''
                }
              })
          })
        }

        Blank()

        // 右侧操作区
        Row() {
          // 主题切换
          Column() {
            Text(this.currentTheme === 'dark' ? Icon.sun : Icon.moon)
              .fontSize(12)
              .fontColor(ColorToken.body)
              .textAlign(TextAlign.Center)
          }
          .width(24)
          .height(24)
          .borderRadius(RadiusToken.sm)
          .backgroundColor(this.hoveredAction === 'theme' ? ColorToken.border_light : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: SpacingToken.s2 })
          .onClick(() => { this.toggleTheme() })
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'theme' : '' })

          // 头像
          Text('JC')
            .fontSize(10)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.white)
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor('#263238')
            .textAlign(TextAlign.Center)
            .margin({ right: 4 })

          // 分隔符
          Column()
            .width(1)
            .height(16)
            .backgroundColor(ColorToken.border)
            .margin({ left: 4, right: 4 })

          // 最小化
          Column() {
            Text(Icon.minus)
              .fontSize(10)
              .fontColor(this.hoveredAction === 'min' ? ColorToken.body : ColorToken.tertiary)
          }
          .width(24)
          .height(24)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'min' : '' })

          // 最大化
          Column() {
            Text(Icon.square)
              .fontSize(10)
              .fontColor(this.hoveredAction === 'max' ? ColorToken.body : ColorToken.tertiary)
          }
          .width(24)
          .height(24)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'max' : '' })

          // 关闭
          Column() {
            Text(Icon.xmark)
              .fontSize(12)
              .fontColor(this.hoveredAction === 'close' ? ColorToken.error : ColorToken.tertiary)
          }
          .width(24)
          .height(24)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAction = isHover ? 'close' : '' })
        }
        .margin({ right: SpacingToken.s2 })
      }
      .width('100%')
      .height(LayoutToken.menubar_height)
      .padding({ left: SpacingToken.s3, right: SpacingToken.s2 })
      .backgroundColor(ColorToken.panel)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border } })
      .alignItems(VerticalAlign.Center)

      // ─── 一级下拉菜单 ───
      if (this.activeMenu !== '') {
        this.renderSubMenu(this.getMenuItems(this.activeMenu), 0, 34, 240)
      }
    }
    .width('100%')
    .height(LayoutToken.menubar_height)
    .backgroundColor(ColorToken.panel)
    .onClick(() => { this.activeMenu = ''; this.openSubMenu = ''; this.openSubSubMenu = '' })
  }

  /** 获取菜单项 */
  private getMenuItems(label: string): SubMenuItem[] {
    for (const menu of this.menus) {
      if (menu.label === label) return menu.children
    }
    return []
  }

  /** 菜单 X 偏移 */
  private menuOffsetX(label: string): number {
    const baseX = 150
    const step = 50
    const idx = this.menus.findIndex((m: MenuBarItem) => m.label === label)
    return baseX + Math.max(0, idx) * step
  }

  /** 渲染子菜单（递归） */
  @Builder
  renderSubMenu(items: SubMenuItem[], level: number, posY: number, width: number): void {
    Column() {
      ForEach(items, (item: SubMenuItem) => {
        if (item.divider) {
          // 分隔线
          Row()
            .height(1)
            .backgroundColor(ColorToken.border)
            .margin({ top: 3, bottom: 3 })
        } else {
          Row() {
            // 图标占位
            Text(item.icon ?? ' ')
              .fontSize(11)
              .fontColor(item.disabled ? ColorToken.muted : ColorToken.tertiary)
              .width(14)
              .textAlign(TextAlign.Center)

            // 标签
            Text(item.label)
              .fontSize(FontSizeToken.level3)
              .fontWeight(FontWeightConstant.regular)
              .fontColor(item.disabled ? ColorToken.muted : ColorToken.body)
              .margin({ left: 10 })
              .layoutWeight(1)

            // 快捷键
            if (item.shortcut && item.shortcut.length > 0) {
              Text(item.shortcut)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor('#9AA2AC')
                .margin({ left: 12 })
            }

            // 子菜单箭头
            if (this.hasChildren(item)) {
              Text('>')
                .fontSize(8)
                .fontColor(ColorToken.muted)
                .margin({ left: 8 })
            }
          }
          .width('100%')
          .height(27)
          .padding({ left: 10, right: 10 })
          .margin({ left: 4, right: 4 })
          .borderRadius(RadiusToken.md)
          .backgroundColor(this.hoveredItem === item.label ? ColorToken.hover_bg : Color.Transparent)
          .alignItems(VerticalAlign.Center)
          .opacity(item.disabled ? 0.4 : 1)
          .onHover((isHover: boolean) => {
            this.hoveredItem = isHover ? item.label : ''
            // 悬停时自动打开子菜单
            if (isHover && this.hasChildren(item)) {
              this.openSubMenu = item.label
              this.openSubSubMenu = ''
            }
          })
          .onClick(() => {
            if (!item.disabled && !this.hasChildren(item)) {
              this.onMenuItemClick(item.label)
            }
          })

          // 二级子菜单
          if (this.hasChildren(item) && this.openSubMenu === item.label) {
            Stack() {
              this.renderSubMenu(item.children!, 1, 0, 220)
            }
            .position({ x: 238, y: -4 })
            .zIndex(ZIndexToken.dropdown)
          }
        }
      })
    }
    .width(width)
    .padding({ top: 6, bottom: 6 })
    .borderRadius(RadiusToken.xl)
    .backgroundColor(ColorToken.white)
    .shadow(ShadowToken.xl)
    .border({ width: 1, color: ColorToken.border })
    .position({ x: this.menuOffsetX(this.activeMenu), y: posY })
    .zIndex(ZIndexToken.dropdown)
  }
}
