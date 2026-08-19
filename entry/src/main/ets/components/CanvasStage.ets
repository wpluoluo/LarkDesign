/**
 * CanvasStage - 无限画布（接入真实数据流）
 *
 * 对应原型 src/components/CanvasStage.vue + FrameView.vue + useInfiniteCanvas.ts
 * 功能：从 FusionDocumentStore 读取真实 Frame/Layer/Object 数据，
 *       工具按钮联动创建对象，拖拽创建形状，选中/拖拽/缩放对象
 */
import { ColorToken } from '../tokens/DesignTokens'
import { LayoutToken, FontSizeToken, SpacingToken, RadiusToken, FontWeightConstant, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { Minimap } from './Minimap'
import { FrameView } from './FrameView'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { SceneObject, Frame, Layer, Transform, Rect } from '../domain/SceneTypes'
import { genId, createShapeObject, createTextObject } from '../domain/FusionFactory'
import { InfiniteCanvas, ViewportCallback } from './InfiniteCanvas'
import { CanvasRenderer, ObjectWithLayer } from './CanvasRenderer'
import { CanvasInteraction, InteractionCallback, HandlePosition, ResizeResult } from './CanvasInteraction'
import { ContextMenu } from './ContextMenu'
import { ActionDispatcher } from '../utils/ActionDispatcher'
import { ColorStore } from '../stores/ColorStore'

class ViewportCB implements ViewportCallback {
  private s: CanvasStage
  constructor(s: CanvasStage) { this.s = s }
  onZoomChange(zoom: number): void { this.s.zoom = zoom }
  onPanChange(panX: number, panY: number): void { this.s.panX = panX; this.s.panY = panY }
}

class InteractionCB implements InteractionCallback {
  private s: CanvasStage
  constructor(s: CanvasStage) { this.s = s }
  onSelectedChange(objId: string): void { this.s.selectedObjId = objId }
  onHoveredChange(objId: string): void { this.s.hoveredObjId = objId }
  onDrawingChange(isDrawing: boolean, sx: number, sy: number, cx: number, cy: number): void {
    this.s.isDrawing = isDrawing; this.s.drawStartX = sx; this.s.drawStartY = sy; this.s.drawCurrentX = cx; this.s.drawCurrentY = cy
  }
  onBoxSelectChange(isBox: boolean, sx: number, sy: number, cx: number, cy: number): void {
    this.s.isBoxSelecting = isBox; this.s.boxStartX = sx; this.s.boxStartY = sy; this.s.boxCurrentX = cx; this.s.boxCurrentY = cy
  }
  onTextEditStart(objId: string): void {
    const objects = this.s.getObjects()
    const found = objects.find((o: ObjectWithLayer) => o.obj.id === objId)
    if (found) {
      this.s.editingObjId = found.obj.id
      this.s.editingText = found.obj.text ?? ''
      this.s.editingObjX = found.obj.transform.x
      this.s.editingObjY = found.obj.transform.y
      this.s.editingObjW = found.obj.transform.width
      this.s.editingObjH = found.obj.transform.height
      this.s.editingObjFontSize = found.obj.fontSize ?? 14
      this.s.editingObjColor = found.obj.color ?? '#1F2329'
      this.s.editingObjFontWeight = found.obj.fontWeight ?? 400
    }
  }
  onTextEditCancel(): void { this.s.editingObjId = ''; this.s.editingText = '' }
  onToast(msg: string, icon: string, type: string): void { this.s.showToast(msg, icon, type) }
  onSyncFrames(): void { this.s.syncFrames() }
}

/** 生成 0..n-1 的整数数组 */
function range(n: number): number[] {
  const result: number[] = []
  for (let i = 0; i < n; i++) {
    result.push(i)
  }
  return result
}

@Component
export struct CanvasStage {
  // ─── 视口状态 ───
  @State zoom: number = 100
  @State panX: number = 0
  @State panY: number = 0
  @State hoveredZoomBtn: string = ''
  @State isPanning: boolean = false

  // ─── 当前工具 ───
  @StorageLink('currentTool') currentTool: string = 'select'

  // ─── 选中状态 ───
  @State selectedObjId: string = ''
  @State hoveredObjId: string = ''

  // ─── 右键菜单 ───
  @State contextMenuX: number = 0
  @State contextMenuY: number = 0
  @State showContextMenu: boolean = false
  @State ctxMenuType: string = 'canvas'


  // ─── 形状绘制状态（拖拽创建） ───
  @State isDrawing: boolean = false
  @State drawStartX: number = 0
  @State drawStartY: number = 0
  @State drawCurrentX: number = 0
  @State drawCurrentY: number = 0

  // ─── 框选状态 ───
  @State isBoxSelecting: boolean = false
  @State boxStartX: number = 0
  @State boxStartY: number = 0
  @State boxCurrentX: number = 0
  @State boxCurrentY: number = 0

  // ─── 渲染状态 ───
  @State isRendering: boolean = false
  @State renderSpinAngle: number = 0

  // ─── 文档状态 ───
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private viewportEngine: InfiniteCanvas = InfiniteCanvas.getInstance()
  private rendererEngine: CanvasRenderer = CanvasRenderer.getInstance()
  private interactionEngine: CanvasInteraction = CanvasInteraction.getInstance()
  @State frames: Frame[] = []
  @State currentFrameId: string = ''
  private frameSnapshot: Frame | null = null

  // ─── 文本编辑状态 ───
  @State editingObjId: string = ''
  @State editingText: string = ''
  @State editingObjX: number = 0
  @State editingObjY: number = 0
  @State editingObjW: number = 200
  @State editingObjH: number = 36
  @State editingObjFontSize: number = 14
  @State editingObjColor: string = '#1F2329'
  @State editingObjFontWeight: number = 400

  // ─── 工具光标提示 ───
  @State showToolCursor: boolean = false


  // ─── Toast 通知 ───
  @StorageLink('toastMessage') toastMessage: string = ''
  @StorageLink('toastIcon') toastIcon: string = ''
  @StorageLink('toastType') toastType: string = 'info'
  @StorageLink('toastVisible') toastVisible: boolean = false

  aboutToAppear(): void {
    this.syncFrames()
    this.currentFrameId = this.fusionStore.getSelectedFrameId()
    console.info('CanvasStage', `appear frames=${this.frames.length} selected=${this.currentFrameId}`)
    // 绑定引擎回调
    this.viewportEngine.bindCallback(new ViewportCB(this))
    this.interactionEngine.bindCallback(new InteractionCB(this))
  }

  aboutToDisappear(): void {
    this.viewportEngine.unbindCallback()
    this.interactionEngine.unbindCallback()
  }

  /** 从 FusionDocumentStore 同步 Frame 数据 */
  syncFrames(): void {
    // 状态系统在异步文档恢复期间可能短暂返回 undefined；ForEach 只能接收稳定数组。
    this.frames = this.fusionStore.getFrames() ?? []
    this.currentFrameId = this.fusionStore.getSelectedFrameId()
    this.frameSnapshot = this.frames.find((f: Frame) => f.id === this.currentFrameId) ?? null
    console.info('CanvasStage', `sync frames=${this.frames.length} selected=${this.currentFrameId}`)
  }

  /** 获取当前 Frame */
  private get currentFrame(): Frame | null {
    return (this.frames ?? []).find((f: Frame) => f.id === this.currentFrameId) ?? null
  }

  /** 获取当前 Frame 的所有图层对象（扁平化） */
  getObjects(): Array<ObjectWithLayer> {
    return CanvasRenderer.getObjectsFromFrame(this.currentFrame)
  }

  /** 缩放比例因子 */
  private get zoomScale(): number {
    return InfiniteCanvas.zoomScale(this.zoom)
  }

  /** 显示 Toast */
  showToast(message: string, icon: string, type: string): void {
    this.toastMessage = message
    this.toastIcon = icon
    this.toastType = type
    this.toastVisible = true
    setTimeout(() => { this.toastVisible = false }, 3000)
  }

  /** 滚轮缩放 */
  private onWheelScroll(delta: number): void {
    this.zoom = this.viewportEngine.onWheelScroll(this.zoom, delta)
  }

  /** 点击空白取消选中 */
  private onCanvasClick(): void {
    if (this.selectedObjId !== '') {
      this.selectedObjId = ''
    }
    if (this.showContextMenu) {
      this.showContextMenu = false
    }
  }

  /** 吸管取色 */
  private pickColorAtCanvas(screenX: number, screenY: number): void {
    const frame = this.currentFrame
    if (!frame) {
      this.showToast('没有画板', Icon.info, 'info')
      return
    }
    const c = InfiniteCanvas.screenToFrame(screenX, screenY, this.panX, this.panY, this.zoom, frame)
    const allObjects: SceneObject[] = []
    for (const layer of frame.children) {
      for (const obj of layer.objects) {
        allObjects.push(obj)
      }
    }
    const color = CanvasInteraction.pickColorFromObjects(allObjects, frame, c.x, c.y)
    const colorStore = ColorStore.getInstance()
    colorStore.setColor(color)
    this.showToast(`已取色 ${color}`, Icon.eyedropper, 'success')
  }

  /** 右键菜单 */
  private onContextMenu(x: number, y: number): void {
    this.contextMenuX = x
    this.contextMenuY = y
    // 根据选中对象类型决定右键菜单类型
    if (this.selectedObject) {
      const t = this.selectedObject.obj.type
      if (t === 'text') this.ctxMenuType = 'text'
      else if (t === 'image') this.ctxMenuType = 'image'
      else if (t === 'shape') this.ctxMenuType = 'shape'
      else this.ctxMenuType = 'page'
    } else {
      this.ctxMenuType = 'canvas'
    }
    this.showContextMenu = true
  }

  /** 处理右键菜单动作 */
  private onCtxAction(action: string): void {
    const dispatcher = ActionDispatcher.getInstance()
    const dispatcherActions: string[] = [
      'copy', 'delete', 'cut', 'duplicateLayer', 'selectAll', 'deselect',
      'lock', 'unlock', 'hide', 'show', 'group', 'ungroup',
      'bringToFront', 'bringForward', 'sendBackward', 'sendToBack',
      'toggleRuler', 'toggleGrid', 'toggleSnap',
    ]
    if (dispatcherActions.indexOf(action) >= 0) {
      dispatcher.handleAction(action)
      this.syncFrames()
      return
    }
    switch (action) {
      case 'zoomIn':
        this.zoom = this.viewportEngine.zoomIn(this.zoom)
        break
      case 'zoomOut':
        this.zoom = this.viewportEngine.zoomOut(this.zoom)
        break
      case 'fitCanvas':
        this.viewportEngine.fitToFramesAndApply(this.frames, this.getViewportWidth(), this.getViewportHeight())
        break
      case 'actualPixels':
        this.viewportEngine.setZoom(100)
        break
      case 'editText':
        if (this.selectedObject) {
          this.startTextEdit(this.selectedObject.obj)
        }
        break
      default:
        this.showToast(`${action}`, Icon.info, 'info')
        break
    }
  }

  /** 根据当前工具在画布上创建对象 */
  private createObjectAtCanvas(x: number, y: number): void {
    const tool = this.currentTool
    const frame = this.currentFrame
    if (!frame) return

    // 转换屏幕坐标到 Frame 内相对坐标
    const rel = InfiniteCanvas.screenToFrame(x, y, this.panX, this.panY, this.zoom, frame)
    const frameRelX = rel.x
    const frameRelY = rel.y

    let obj: SceneObject | null = null
    let objName = ''

    if (tool === 'rectangle') {
      obj = createShapeObject({ shape: 'rectangle', x: frameRelX, y: frameRelY, width: 120, height: 80, fill: '#3AC487' })
      objName = '矩形'
    } else if (tool === 'ellipse') {
      obj = createShapeObject({ shape: 'ellipse', x: frameRelX, y: frameRelY, width: 120, height: 120, fill: '#3B82F6' })
      objName = '椭圆'
    } else if (tool === 'text') {
      obj = createTextObject({ text: '双击编辑文字', x: frameRelX, y: frameRelY, width: 200, height: 36 })
      objName = '文字'
    }

    if (obj) {
      obj.name = objName
      this.fusionStore.newObject(obj)
      this.syncFrames()
      this.selectedObjId = obj.id
      this.showToast(`已创建 ${objName}`, Icon.plus, 'success')
    }
  }

  /** 提交拖拽创建的形状 */
  private commitDrawShape(endX: number, endY: number): void {
    const frame = this.currentFrame
    if (!frame) return

    const shape = this.interactionEngine.commitDrawing(
      this.drawStartX, this.drawStartY, endX, endY,
      this.panX, this.panY, this.zoom, frame,
    )
    if (!shape) {
      this.isDrawing = false
      return
    }

    let obj: SceneObject | null = null
    let objName = ''

    if (this.currentTool === 'rectangle') {
      obj = createShapeObject({ shape: 'rectangle', x: shape.x, y: shape.y, width: shape.width, height: shape.height, fill: '#3AC487' })
      objName = '矩形'
    } else if (this.currentTool === 'ellipse') {
      obj = createShapeObject({ shape: 'ellipse', x: shape.x, y: shape.y, width: shape.width, height: shape.height, fill: '#3B82F6' })
      objName = '椭圆'
    }

    if (obj) {
      obj.name = objName
      this.fusionStore.newObject(obj)
      this.syncFrames()
      this.selectedObjId = obj.id
      this.showToast(`已创建 ${objName}`, Icon.plus, 'success')
    }

    this.isDrawing = false
  }

  /** 开始编辑文本对象 */
  private startTextEdit(obj: SceneObject): void {
    this.interactionEngine.startTextEdit(obj)
  }

  /** 提交文本编辑 */
  private commitTextEdit(): void {
    if (this.editingObjId !== '') {
      const objects = this.getObjects()
      const found = objects.find((o: ObjectWithLayer) => o.obj.id === this.editingObjId)
      if (found) {
        found.obj.text = this.editingText
      }
      this.editingObjId = ''
      this.syncFrames()
    }
  }

  /** 取消文本编辑 */
  private cancelTextEdit(): void {
    this.interactionEngine.cancelTextEdit()
  }

  /** 获取当前工具对应的光标图标 */
  private get toolCursorIcon(): string {
    const key = CanvasInteraction.getToolCursorIcon(this.currentTool)
    if (key === '') return ''
    const map: Record<string, string> = {
      'rect': Icon.rect,
      'circle': Icon.circle,
      'text': Icon.text,
      'eyedropper': Icon.eyedropper,
      'hand': Icon.hand,
      'zoom_in': Icon.zoom_in,
    }
    return map[key] ?? ''
  }

  /** 获取视口宽度 */
  private getViewportWidth(): number {
    return 1920
  }

  /** 获取视口高度 */
  private getViewportHeight(): number {
    return 1080
  }

  /** 获取当前工具对应的光标名称 */
  private get toolCursorName(): string {
    return CanvasInteraction.getToolCursorName(this.currentTool)
  }

  /** 当前悬停对象 */
  private get hoveredObject(): ObjectWithLayer | undefined {
    if (this.hoveredObjId === '') return undefined
    return this.getObjects().find((o: ObjectWithLayer) => o.obj.id === this.hoveredObjId)
  }

  /** 当前选中对象 */
  private get selectedObject(): ObjectWithLayer | undefined {
    if (this.selectedObjId === '') return undefined
    return this.getObjects().find((o: ObjectWithLayer) => o.obj.id === this.selectedObjId)
  }

  /** 框选矩形屏幕坐标 */
  private get boxRect(): Rect {
    const bx = Math.min(this.boxStartX, this.boxCurrentX) - InfiniteCanvas.OFFSET_X - this.panX
    const by = Math.min(this.boxStartY, this.boxCurrentY) - InfiniteCanvas.OFFSET_Y - this.panY
    const bw = Math.abs(this.boxCurrentX - this.boxStartX)
    const bh = Math.abs(this.boxCurrentY - this.boxStartY)
    return { x: bx, y: by, width: bw, height: bh } as Rect
  }

  /** 绘制预览矩形屏幕坐标 */
  private get drawRect(): Rect {
    const x = Math.min(this.drawStartX, this.drawCurrentX) - InfiniteCanvas.OFFSET_X - this.panX
    const y = Math.min(this.drawStartY, this.drawCurrentY) - InfiniteCanvas.OFFSET_Y - this.panY
    const w = Math.abs(this.drawCurrentX - this.drawStartX)
    const h = Math.abs(this.drawCurrentY - this.drawStartY)
    return { x: x, y: y, width: w, height: h } as Rect
  }

  /** 完成框选并选中框内对象 */
  private commitBoxSelect(): void {
    const selectedIds = this.interactionEngine.commitBoxSelect(
      this.boxStartX, this.boxStartY, this.boxCurrentX, this.boxCurrentY,
      this.panX, this.panY, this.zoom, this.currentFrame,
    )
    if (selectedIds.length > 0) {
      this.selectedObjId = selectedIds[0]
      this.fusionStore.selectObject(selectedIds[0])
    }
  }

  /** 删除选中对象 */
  private deleteSelected(): void {
    if (this.selectedObjId !== '') {
      this.fusionStore.removeObjectById(this.selectedObjId)
      this.syncFrames()
      this.selectedObjId = ''
      this.showToast('已删除', Icon.trash, 'warning')
    }
  }

  build(): void {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 画布背景色
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorToken.canvas_bg)

      // 2. 网格背景
      this.gridBackground()

      // 工具光标提示（左上角）
      if (this.currentTool !== 'select' && this.currentTool !== 'hand') {
        Row() {
          Text(this.toolCursorIcon)
            .fontSize(10)
            .fontColor(ColorToken.white)
          Text(this.toolCursorName)
            .fontSize(9)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.white)
            .margin({ left: 4 })
        }
        .height(22)
        .padding({ left: 8, right: 8 })
        .borderRadius(6)
        .backgroundColor('#1F2329CC')
        .alignItems(VerticalAlign.Center)
        .position({ x: 12, y: 12 })
        .zIndex(50)
      }

      // 3. 可平移/缩放的内容层
      Stack({ alignContent: Alignment.TopStart }) {
        // 直接构建当前 Frame，避免设备端 ForEach 在文档异步恢复期间吞掉整个画布子树。
        if (this.frameSnapshot !== null) {
          FrameView({
            frame: this.frameSnapshot,
            zoom: this.zoom,
            isSelected: true,
            interactionTool: this.currentTool,
            onSelect: () => {
              this.fusionStore.switchFrame(this.currentFrameId)
              this.selectedObjId = ''
            }
          })

          // 渲染当前选中 Frame 内的对象
          ForEach(this.frameSnapshot.children ?? [], (layer: Layer) => {
            ForEach(layer.objects ?? [], (obj: SceneObject) => {
              this.renderSceneObject(obj, layer.id)
            })
          })
        }

        // 无 Frame 时显示提示
        if (this.frames.length === 0) {
          Column() {
            Text(Icon.rect)
              .fontSize(32)
              .fontColor(ColorToken.border)
            Text('点击上方"新建"创建画板')
              .fontSize(12)
              .fontColor(ColorToken.muted)
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }

        // 悬停高亮虚线框
        if (this.hoveredObject) {
          Column()
            .width(this.hoveredObject.obj.transform.width)
            .height(this.hoveredObject.obj.transform.height)
            .border({ width: 1, color: ColorToken.info, style: BorderStyle.Dashed })
            .position({ x: this.hoveredObject.obj.transform.x, y: this.hoveredObject.obj.transform.y })
        }

        // 选中框 + 8 控制点
        if (this.selectedObject) {
          this.selectionOverlay(this.selectedObject.obj.transform)
        }

        // 文本编辑 overlay
        if (this.editingObjId !== '') {
          TextArea({
            text: this.editingText,
            placeholder: '输入文字...',
            controller: new TextAreaController()
          })
          .width(this.editingObjW)
          .height(this.editingObjH)
          .position({
            x: this.editingObjX,
            y: this.editingObjY
          })
          .zIndex(100)
          .fontSize(this.editingObjFontSize)
          .fontColor(this.editingObjColor)
          .fontWeight(this.editingObjFontWeight)
          .defaultFocus(true)
          .onChange((value: string) => {
            this.editingText = value
          })
          .onBlur(() => {
            this.commitTextEdit()
          })
        }

        // 框选预览矩形
        if (this.isBoxSelecting) {
          Column()
            .width(this.boxRect.width > 0 ? this.boxRect.width : 1)
            .height(this.boxRect.height > 0 ? this.boxRect.height : 1)
            .border({ width: 1, color: ColorToken.info })
            .backgroundColor('#3B82F614')
            .position({ x: this.boxRect.x, y: this.boxRect.y })
            .scale({ x: 1 / this.zoomScale, y: 1 / this.zoomScale })
        }

        // 拖拽创建预览矩形 + 尺寸标注
        if (this.isDrawing) {
          Stack({ alignContent: Alignment.TopStart }) {
            Column()
              .width(this.drawRect.width > 0 ? this.drawRect.width : 1)
              .height(this.drawRect.height > 0 ? this.drawRect.height : 1)
              .border({ width: 1, color: ColorToken.primary, style: BorderStyle.Dashed })
              .backgroundColor('#3AC48714')
            // 尺寸标注
            if (this.drawRect.width > 20 && this.drawRect.height > 20) {
              Row() {
                Text(`${Math.round(this.drawRect.width)} × ${Math.round(this.drawRect.height)}`)
                  .fontSize(10)
                  .fontWeight(700)
                  .fontColor(ColorToken.white)
              }
              .height(20)
              .padding({ left: 6, right: 6 })
              .borderRadius(3)
              .backgroundColor('#1F2329CC')
              .alignItems(VerticalAlign.Center)
              .position({ x: this.drawRect.width / 2 - 30, y: 4 })
            }
          }
          .width(this.drawRect.width > 0 ? this.drawRect.width : 1)
          .height(this.drawRect.height > 0 ? this.drawRect.height : 1)
          .position({ x: this.drawRect.x, y: this.drawRect.y })
          .scale({ x: 1 / this.zoomScale, y: 1 / this.zoomScale })
        }
      }
      .position({ x: this.panX + InfiniteCanvas.OFFSET_X, y: this.panY + InfiniteCanvas.OFFSET_Y })
      .scale({ x: this.zoomScale, y: this.zoomScale, centerX: 0, centerY: 0 })

      // 右键菜单（使用通用 ContextMenu 组件）
      ContextMenu({
        visible: this.showContextMenu,
        menuX: this.contextMenuX,
        menuY: this.contextMenuY,
        menuType: this.ctxMenuType,
        onAction: (action: string) => { this.onCtxAction(action) },
        onClose: () => { this.showContextMenu = false; this.ctxMenuType = 'canvas' },
      })

      // 4. 缩放控件
      this.zoomControls()

      // 5. 鸟瞰图
      Minimap()

      // 6. Frame 信息栏（右下角）
      if (this.currentFrame) {
        Row() {
          Text(this.getFrameTypeIcon(this.currentFrame.type))
            .fontSize(10)
            .fontColor(ColorToken.primary)
          Text(this.currentFrame.name)
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 6 })
          Text(`${Math.round(this.currentFrame.width)} × ${Math.round(this.currentFrame.height)}`)
            .fontSize(9)
            .fontColor(ColorToken.muted)
            .margin({ left: 6 })
        }
        .height(26)
        .padding({ left: 10, right: 10 })
        .borderRadius(6)
        .backgroundColor(ColorToken.panel)
        .border({ width: 1, color: ColorToken.border_light })
        .shadow({ radius: 8, color: '#0F17220F', offsetX: 0, offsetY: 2 })
        .alignItems(VerticalAlign.Center)
        .position({ x: '100%', y: '100%' })
        .markAnchor({ x: '100%', y: '100%' })
        .offset({ x: -12, y: -12 })
        .zIndex(20)
      }

      // 7. 抓手模式提示
      if (this.isPanning) {
        Row() {
          Text(Icon.hand).fontSize(10).fontColor(ColorToken.white)
          Text('平移中').fontSize(9).fontWeight(FontWeightConstant.medium).fontColor(ColorToken.white).margin({ left: 4 })
        }
        .height(22).padding({ left: 10, right: 10 }).borderRadius(RadiusToken.sm)
        .backgroundColor('#1F2329CC').alignItems(VerticalAlign.Center)
        .position({ x: '45%', y: 12 })
      }

    }
    .width('100%').height('100%').backgroundColor(ColorToken.canvas_bg).clip(true)
    .onClick(() => { this.onCanvasClick() })

    .gesture(
      GestureGroup(GestureMode.Exclusive,
        PanGesture({ direction: PanDirection.All, distance: 5 })
          .onActionStart((event: GestureEvent) => {
            const gx = event.fingerList[0].globalX
            const gy = event.fingerList[0].globalY
            // 吸管工具：取色
            if (this.currentTool === 'eyedropper') {
              this.pickColorAtCanvas(gx, gy)
              return
            }
            // 选择工具空白处：开始框选
            if (this.currentTool === 'select') {
              this.interactionEngine.startBoxSelect(gx, gy)
              return
            }
            // 形状工具：开始拖拽创建
            if (CanvasInteraction.isShapeTool(this.currentTool)) {
              this.interactionEngine.startDrawing(gx, gy)
              return
            }
            // 抓手或选择工具：开始平移
            this.viewportEngine.startPan(gx, gy, this.panX, this.panY)
            this.isPanning = this.viewportEngine.isPanning
          })
          .onActionUpdate((event: GestureEvent) => {
            const gx = event.fingerList[0].globalX
            const gy = event.fingerList[0].globalY
            if (this.isBoxSelecting) {
              this.interactionEngine.updateBoxSelect(gx, gy, this.boxStartX, this.boxStartY)
              return
            }
            if (this.isDrawing) {
              this.interactionEngine.updateDrawing(gx, gy, this.drawStartX, this.drawStartY)
              return
            }
            if (this.viewportEngine.isPanning) {
              this.viewportEngine.updatePan(gx, gy)
            }
          })
          .onActionEnd((event: GestureEvent) => {
            if (this.isBoxSelecting) {
              this.commitBoxSelect()
              return
            }
            if (this.isDrawing) {
              this.commitDrawShape(event.fingerList[0].globalX, event.fingerList[0].globalY)
              return
            }
            this.viewportEngine.endPan()
            this.isPanning = false
          }),
        PinchGesture({ fingers: 2 })
          .onActionUpdate((event: GestureEvent) => {
            this.zoom = this.viewportEngine.pinchZoom(this.zoom, event.scale)
          })
      )
    )
    .gesture(
      TapGesture({ count: 2 })
        .onAction((event: GestureEvent) => {
          // 双击空白处创建新 Frame
          if (this.currentTool === 'select' || this.currentTool === 'hand') {
            const c = InfiniteCanvas.screenToCanvas(event.fingerList[0].globalX, event.fingerList[0].globalY, this.panX, this.panY, this.zoom)
            const frame = this.fusionStore.newFrame('single', '页面', c.x - 150, c.y - 200)
            if (frame) {
              this.currentFrameId = frame.id
              this.fusionStore.switchFrame(frame.id)
              this.syncFrames()
              this.showToast('已创建新画板', Icon.plus, 'success')
            }
          }
        })
    )
  }

  // ─── 网格背景 ───
  @Builder
  gridBackground(): void {
    Stack() {
      Column() {
        ForEach(range(40), (i: number) => {
          Row().width('100%').height(1).backgroundColor('#0F172A0A').margin({ top: i === 0 ? 0 : 19 })
        })
      }.width('100%').height('100%')
      Row() {
        ForEach(range(60), (i: number) => {
          Column().width(1).height('100%').backgroundColor('#0F172A0A').margin({ left: i === 0 ? 0 : 19 })
        })
      }.width('100%').height('100%')
    }.width('100%').height('100%')
  }

  // ─── 渲染单个 SceneObject ───
  @Builder
  renderSceneObject(obj: SceneObject, layerId: string): void {
    Column() {
      if (obj.type === 'text') {
        Text(obj.text ?? obj.name)
          .fontSize(obj.fontSize ?? 14)
          .fontWeight(obj.fontWeight ?? FontWeightConstant.regular)
          .fontColor(obj.color ?? '#1F2329')
          .maxLines(1)
      } else if (obj.type === 'image') {
        Column() {
          Text(Icon.image).fontSize(20).fontColor(ColorToken.muted)
          Text(obj.name).fontSize(10).fontColor(ColorToken.muted).margin({ top: 4 })
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
        .backgroundColor(obj.fill ?? '#F3F5F7')
      } else if (obj.type === 'shape' && obj.shape === 'ellipse') {
        Column().width('100%').height('100%')
          .borderRadius('50%')
          .backgroundColor(obj.fill ?? '#3B82F6')
          .border({ width: obj.strokeWidth ?? 0, color: obj.stroke ?? Color.Transparent })
      } else if (obj.type === 'shape' && obj.shape === 'line') {
        Column().width('100%').height(2).backgroundColor(obj.fill ?? '#D8DCE1').borderRadius(1)
      } else {
        // 默认形状（矩形等）
        Column().width('100%').height('100%')
          .backgroundColor(obj.fill ?? '#3AC487')
          .borderRadius(obj.cornerRadius ?? 0)
          .border({ width: obj.strokeWidth ?? 0, color: obj.stroke ?? Color.Transparent })
      }
    }
    .width(obj.transform.width)
    .height(obj.transform.height)
    .position({ x: obj.transform.x, y: obj.transform.y })
    .rotate({ x: 0, y: 0, z: 1, angle: obj.transform.rotation })
    .onHover((isHover: boolean) => { this.hoveredObjId = isHover ? obj.id : '' })
    .onClick(() => {
      this.selectedObjId = obj.id
      this.fusionStore.selectObject(obj.id)
    })
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 2 })
          .onAction(() => {
            if (obj.type === 'text') {
              this.startTextEdit(obj)
            }
          }),
        PanGesture({ direction: PanDirection.All, distance: 3 })
          .onActionStart((event: GestureEvent) => {
          this.interactionEngine.startDrag(obj.id, event.fingerList[0].globalX, event.fingerList[0].globalY, obj.transform.x, obj.transform.y)
          this.selectedObjId = obj.id
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.interactionEngine.dragObjId === obj.id) {
            const pos = this.interactionEngine.computeDragPosition(event.fingerList[0].globalX, event.fingerList[0].globalY, this.zoom)
            if (pos) {
              this.fusionStore.moveObject(obj.id, pos.x, pos.y, true)
              this.syncFrames()
            }
          }
        })
        .onActionEnd(() => {
          if (this.interactionEngine.dragObjId === obj.id) {
            this.fusionStore.moveObject(obj.id, this.fusionStore.getSelectedObjects()[0]?.transform.x ?? 0, this.fusionStore.getSelectedObjects()[0]?.transform.y ?? 0)
          }
          this.interactionEngine.endDrag()
        })
      )
    )
  }

  // ─── 选中框 + 8 控制点 + 旋转 handle ───
  @Builder
  selectionOverlay(t: Transform): void {
    Stack({ alignContent: Alignment.TopStart }) {
      Column().width(t.width).height(t.height).border({ width: 1, color: ColorToken.primary })
      this.handle(-3, -3, 'nw', t)
      this.handle(t.width / 2 - 3, -3, 'n', t)
      this.handle(t.width - 3, -3, 'ne', t)
      this.handle(-3, t.height / 2 - 3, 'w', t)
      this.handle(t.width - 3, t.height / 2 - 3, 'e', t)
      this.handle(-3, t.height - 3, 'sw', t)
      this.handle(t.width / 2 - 3, t.height - 3, 's', t)
      this.handle(t.width - 3, t.height - 3, 'se', t)
      // 旋转 handle（圆形，位于顶部中心上方）
      this.rotateHandle(t)
      Row() {
        Text(`${t.width} × ${t.height}`)
          .fontSize(9).fontWeight(FontWeightConstant.medium).fontColor(ColorToken.white)
      }
      .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(3)
      .backgroundColor(ColorToken.primary)
      .position({ x: t.width / 2 - 30, y: t.height + 8 })
    }
    .width(t.width).height(t.height)
    .position({ x: t.x, y: t.y })
    .rotate({ x: 0, y: 0, z: 1, angle: t.rotation })
  }

  @Builder
  handle(hx: number, hy: number, pos: string, t: Transform): void {
    Column().width(6).height(6).backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.info }).borderRadius(1)
      .position({ x: hx, y: hy }).zIndex(10)
      .gesture(
        PanGesture()
          .onActionStart((e: GestureEvent) => {
            this.interactionEngine.startResize(this.selectedObjId, e.fingerList[0].globalX, e.fingerList[0].globalY, t.width, t.height, t.x, t.y, t.rotation)
          })
          .onActionUpdate((e: GestureEvent) => {
            if (this.interactionEngine.dragObjId === this.selectedObjId) {
              const result: ResizeResult = this.interactionEngine.computeResize(e.fingerList[0].globalX, e.fingerList[0].globalY, this.zoom, pos as HandlePosition)
              const objects = this.getObjects()
              const sel = objects.find((o: ObjectWithLayer) => o.obj.id === this.selectedObjId)
              if (sel) {
                sel.obj.transform.x = result.x
                sel.obj.transform.y = result.y
                sel.obj.transform.width = result.width
                sel.obj.transform.height = result.height
                this.syncFrames()
              }
            }
          })
          .onActionEnd(() => { this.interactionEngine.endResize() })
      )
  }

  @Builder
  rotateHandle(t: Transform): void {
    Column()
      .width(8).height(8)
      .backgroundColor(ColorToken.primary)
      .border({ width: 2, color: ColorToken.white })
      .borderRadius(4)
      .position({ x: t.width / 2 - 4, y: -16 })
      .zIndex(10)
      .gesture(
        PanGesture()
          .onActionStart((e: GestureEvent) => {
            this.interactionEngine.startRotate(this.selectedObjId, e.fingerList[0].globalX, e.fingerList[0].globalY, t.rotation)
          })
          .onActionUpdate((e: GestureEvent) => {
            if (this.interactionEngine.dragObjId === this.selectedObjId) {
              const objects = this.getObjects()
              const sel = objects.find((o: ObjectWithLayer) => o.obj.id === this.selectedObjId)
              if (sel) {
                const cx = sel.obj.transform.x + sel.obj.transform.width / 2
                const cy = sel.obj.transform.y + sel.obj.transform.height / 2
                sel.obj.transform.rotation = this.interactionEngine.computeRotation(
                  e.fingerList[0].globalX, e.fingerList[0].globalY, this.zoom, cx, cy,
                )
                this.syncFrames()
              }
            }
          })
          .onActionEnd(() => { this.interactionEngine.endRotate() })
      )
  }

  // ─── 缩放控件 ───
  @Builder
  zoomControls(): void {
    Row() {
      Column() {
        Text(Icon.minus).fontSize(9).fontColor(ColorToken.secondary).textAlign(TextAlign.Center)
      }
      .width(20).height(20).borderRadius(4)
      .backgroundColor(this.hoveredZoomBtn === 'out' ? ColorToken.hover_bg : Color.Transparent)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => { this.zoomOut() })
      .onHover((isHover: boolean) => { this.hoveredZoomBtn = isHover ? 'out' : '' })

      Text(`${this.zoom}%`)
        .fontSize(10).fontWeight(FontWeightConstant.semibold).fontColor(ColorToken.body)
        .width(36).textAlign(TextAlign.Center).margin({ left: 4 })
        .onClick(() => { this.zoom = 100; this.panX = 0; this.panY = 0 })

      Column() {
        Text(Icon.plus).fontSize(9).fontColor(ColorToken.secondary).textAlign(TextAlign.Center)
      }
      .width(20).height(20).borderRadius(4)
      .backgroundColor(this.hoveredZoomBtn === 'in' ? ColorToken.hover_bg : Color.Transparent)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center).margin({ left: 4 })
      .onClick(() => { this.zoomIn() })
      .onHover((isHover: boolean) => { this.hoveredZoomBtn = isHover ? 'in' : '' })

      Column().width(1).height(12).backgroundColor(ColorToken.border_light).margin({ left: 2, right: 2 })

      Column() {
        Text(Icon.zoom_fit).fontSize(9).fontColor(ColorToken.secondary).textAlign(TextAlign.Center)
      }
      .width(20).height(20).borderRadius(4)
      .backgroundColor(this.hoveredZoomBtn === 'fit' ? ColorToken.hover_bg : Color.Transparent)
      .justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      .onClick(() => { this.zoom = 100; this.panX = 0; this.panY = 0 })
      .onHover((isHover: boolean) => { this.hoveredZoomBtn = isHover ? 'fit' : '' })
    }
    .height(26).padding({ left: 8, right: 8 }).borderRadius(RadiusToken.md)
    .backgroundColor(ColorToken.panel).border({ width: 1, color: ColorToken.border_light })
    .shadow({ radius: 8, color: '#0F17220F', offsetX: 0, offsetY: 2 }).alignItems(VerticalAlign.Center)
    .position({ x: 12, y: '100%' }).markAnchor({ x: 0, y: '100%' }).offset({ x: 0, y: -12 })
  }

  /** 获取帧类型图标 */
  private getFrameTypeIcon(type: string): string {
    return CanvasRenderer.getFrameTypeIcon(type, (key: string): string => {
      const map: Record<string, string> = {
        'rect': Icon.rect,
        'image': Icon.image,
        'book': Icon.book,
        'book_open': Icon.book_open,
      }
      return map[key] ?? Icon.rect
    })
  }

  private zoomIn(): void { this.zoom = this.viewportEngine.zoomIn(this.zoom) }
  private zoomOut(): void { this.zoom = this.viewportEngine.zoomOut(this.zoom) }
}
