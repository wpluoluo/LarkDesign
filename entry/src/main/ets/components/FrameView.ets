/**
 * FrameView - 帧视图（画板显示）
 *
 * 对应原型 src/components/FrameView.vue + useFrameHandles.ts
 * 功能：
 *  - 标题栏（类型图标 + 名称 + 页码）
 *  - 选中高亮环（ring）
 *  - 尺寸标签（hover 时显示）
 *  - 对页关联指示器（spread）
 *  - 页码显示（书籍模式）
 *  - Frame 拖拽移动
 *  - Frame 8 点缩放
 *  - 双击进入编辑模式
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, RadiusToken, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { Frame, SceneObject, Layer } from '../types/SceneTypes'

@Component
export struct FrameView {
  @Prop frame: Frame = {
    id: '', type: 'single', name: '', x: 0, y: 0, width: 0, height: 0,
    background: '#FFFFFF', children: [], hidden: false, createdAt: '',
    showPageNumber: false, pageNumberFormat: 'P{n}'
  }
  @Prop zoom: number = 100
  @Prop isSelected: boolean = false
  @Prop editingMode: boolean = false
  onSelect: (additive: boolean) => void = () => {}
  onMove: (x: number, y: number) => void = () => {}
  onResize: (w: number, h: number) => void = () => {}
  onEnterEdit: () => void = () => {}

  @State isHovered: boolean = false
  @State isDragging: boolean = false
  @State isResizing: boolean = false
  @State resizePos: string = ''
  private dragStartX: number = 0
  private dragStartY: number = 0
  private dragStartFrameX: number = 0
  private dragStartFrameY: number = 0
  private resizeStartX: number = 0
  private resizeStartY: number = 0
  private resizeStartW: number = 0
  private resizeStartH: number = 0
  private zoomScale: number = 1

  aboutToAppear(): void {
    this.zoomScale = this.zoom / 100
  }

  private get typeIcon(): string {
    const typeMap: Record<string, string> = {
      'single': Icon.rect,
      'poster': Icon.image,
      'book-page': Icon.book,
      'spread': Icon.book_open,
    }
    return typeMap[this.frame.type] ?? Icon.rect
  }

  build(): void {
    Stack() {
      // 标题栏
      Row() {
        Text(this.typeIcon)
          .fontSize(10)
          .fontColor(this.isSelected ? ColorToken.white : ColorToken.secondary)
        Text(this.frame.name)
          .fontSize(11)
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(this.isSelected ? ColorToken.white : ColorToken.body)
          .maxLines(1)
          .layoutWeight(1)
        if (this.frame.type === 'book-page' && this.frame.order) {
          Text(`${this.frame.order}`)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.isSelected ? ColorToken.white : ColorToken.muted)
            .opacity(0.7)
            .margin({ left: 4 })
        }
        if (this.frame.showPageNumber && this.frame.order) {
          Text(`P${this.frame.order}`)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(this.isSelected ? ColorToken.white : ColorToken.muted)
            .opacity(0.6)
            .margin({ left: 4 })
        }
      }
      .height(24)
      .padding({ left: 8, right: 8 })
      .borderRadius(4)
      .backgroundColor(this.isSelected ? ColorToken.primary : ColorToken.panel)
      .border({
        width: this.isSelected ? 0 : 1,
        color: this.isSelected ? Color.Transparent : ColorToken.border
      })
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: -28 })
      .onClick(() => { this.onSelect(false) })

      // Frame 画布区域
      Stack({ alignContent: Alignment.TopStart }) {
        Column()
          .width(this.frame.width)
          .height(this.frame.height)
          .backgroundColor(this.frame.background ?? '#FFFFFF')
          .border({
            width: 1,
            color: this.isSelected ? ColorToken.primary : (this.isHovered ? ColorToken.primary : ColorToken.border)
          })
          .borderRadius(1)
          .shadow({ radius: 2, color: '#00000012', offsetX: 0, offsetY: 1 })

        // 选中高亮环
        if (this.isSelected) {
          Column()
            .width(this.frame.width + 4)
            .height(this.frame.height + 4)
            .border({ width: 2, color: ColorToken.primary })
            .borderRadius(2)
            .position({ x: -2, y: -2 })
        }

        // 对页关联指示器
        if (this.frame.spreadWith) {
          Column() {
            Text(Icon.book_open)
              .fontSize(8)
              .fontColor(ColorToken.warning)
          }
          .width(8)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .position({
            x: this.frame.spreadSide === 'left' ? this.frame.width - 8 : -8,
            y: '50%'
          })
        }

        // 页码（书籍模式）
        if (this.frame.showPageNumber && this.frame.order) {
          Text(this.frame.pageNumberFormat.replace('{n}', String(this.frame.order)))
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .position({ x: '50%', y: this.frame.height + 2 })
            .markAnchor({ x: '50%', y: 0 })
        }
      }
      .width(`${this.frame.width}px`)
      .height(`${this.frame.height}px`)
      .onHover((isHover: boolean) => { this.isHovered = isHover })

      // 尺寸标签（hover）
      if (this.isHovered) {
        Text(`${Math.round(this.frame.width)} × ${Math.round(this.frame.height)}`)
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .position({ x: 0, y: this.frame.height + 4 })
          .opacity(0.8)
      }

      // 8 个 resize handle
      if (this.isSelected && !this.editingMode) {
        this.resizeHandle(0, 0, 'nw')
        this.resizeHandle(this.frame.width / 2 - 4, 0, 'n')
        this.resizeHandle(this.frame.width - 8, 0, 'ne')
        this.resizeHandle(0, this.frame.height / 2 - 4, 'w')
        this.resizeHandle(this.frame.width - 8, this.frame.height / 2 - 4, 'e')
        this.resizeHandle(0, this.frame.height - 8, 'sw')
        this.resizeHandle(this.frame.width / 2 - 4, this.frame.height - 8, 's')
        this.resizeHandle(this.frame.width - 8, this.frame.height - 8, 'se')
      }
    }
    .width(`${this.frame.width}px`)
    .height(`${this.frame.height}px`)
    .position({ x: this.frame.x, y: this.frame.y })
    .hitTestBehavior(HitTestMode.Default)
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2 })
          .onAction(() => { this.onEnterEdit() }),
        PanGesture({ direction: PanDirection.All, distance: 5 })
          .onActionStart((event: GestureEvent) => {
            if (this.editingMode) return
            this.isDragging = true
            this.dragStartX = event.fingerList[0].globalX
            this.dragStartY = event.fingerList[0].globalY
            this.dragStartFrameX = this.frame.x
            this.dragStartFrameY = this.frame.y
          })
          .onActionUpdate((event: GestureEvent) => {
            if (!this.isDragging) return
            const dx = (event.fingerList[0].globalX - this.dragStartX) / this.zoomScale
            const dy = (event.fingerList[0].globalY - this.dragStartY) / this.zoomScale
            this.onMove(this.dragStartFrameX + dx, this.dragStartFrameY + dy)
          })
          .onActionEnd(() => { this.isDragging = false })
      )
    )
    .onClick(() => {
      if (!this.editingMode) this.onSelect(false)
    })
  }

  @Builder
  resizeHandle(hx: number, hy: number, pos: string): void {
    Column()
      .width(8)
      .height(8)
      .backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.primary })
      .borderRadius(1)
      .position({ x: hx, y: hy })
      .zIndex(10)
      .hitTestBehavior(HitTestMode.Default)
      .gesture(
        PanGesture({ direction: PanDirection.All })
          .onActionStart((event: GestureEvent) => {
            this.isResizing = true
            this.resizePos = pos
            this.resizeStartX = event.fingerList[0].globalX
            this.resizeStartY = event.fingerList[0].globalY
            this.resizeStartW = this.frame.width
            this.resizeStartH = this.frame.height
          })
          .onActionUpdate((event: GestureEvent) => {
            if (!this.isResizing) return
            const dx = (event.fingerList[0].globalX - this.resizeStartX) / this.zoomScale
            const dy = (event.fingerList[0].globalY - this.resizeStartY) / this.zoomScale
            let newW = this.resizeStartW
            let newH = this.resizeStartH
            if (pos === 'e' || pos === 'ne' || pos === 'se') newW = this.resizeStartW + dx
            if (pos === 'w' || pos === 'nw' || pos === 'sw') newW = Math.max(50, this.resizeStartW - dx)
            if (pos === 's' || pos === 'se' || pos === 'sw') newH = this.resizeStartH + dy
            if (pos === 'n' || pos === 'ne' || pos === 'nw') newH = Math.max(50, this.resizeStartH - dy)
            newW = Math.max(50, newW)
            newH = Math.max(50, newH)
            this.onResize(newW, newH)
          })
          .onActionEnd(() => {
            this.isResizing = false
            this.resizePos = ''
          })
      )
  }
}
