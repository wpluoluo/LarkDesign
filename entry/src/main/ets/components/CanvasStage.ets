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
import { SceneObject, Frame, Layer, Transform } from '../types/SceneTypes'
import { genId, createShapeObject, createTextObject } from '../types/FusionFactory'

/** 画布对象与图层ID的映射 */
interface ObjectWithLayer {
  obj: SceneObject
  layerId: string
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

  // ─── 拖拽状态 ───
  private dragObjId: string = ''
  private dragStartX: number = 0
  private dragStartY: number = 0
  private dragObjStartX: number = 0
  private dragObjStartY: number = 0
  private panStartX: number = 0
  private panStartY: number = 0
  private panStartPanX: number = 0
  private panStartPanY: number = 0

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
  @State frames: Frame[] = []
  @State currentFrameId: string = ''

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
  }

  /** 从 FusionDocumentStore 同步 Frame 数据 */
  private syncFrames(): void {
    this.frames = this.fusionStore.getFrames()
    this.currentFrameId = this.fusionStore.getSelectedFrameId()
  }

  /** 获取当前 Frame */
  private get currentFrame(): Frame | null {
    return this.frames.find((f: Frame) => f.id === this.currentFrameId) ?? null
  }

  /** 获取当前 Frame 的所有图层对象（扁平化） */
  private getObjects(): Array<ObjectWithLayer> {
    const frame = this.currentFrame
    if (!frame) return []
    const result: Array<ObjectWithLayer> = []
    for (const layer of frame.children) {
      for (const obj of layer.objects) {
        result.push({ obj: obj, layerId: layer.id } as ObjectWithLayer)
      }
    }
    return result
  }

  /** 缩放比例因子 */
  private get zoomScale(): number {
    return this.zoom / 100
  }

  /** 显示 Toast */
  private showToast(message: string, icon: string, type: string): void {
    this.toastMessage = message
    this.toastIcon = icon
    this.toastType = type
    this.toastVisible = true
    setTimeout(() => { this.toastVisible = false }, 3000)
  }

  /** 滚轮缩放 */
  private onWheelScroll(delta: number): void {
    const factor = delta > 0 ? 1.1 : 1 / 1.1
    this.zoom = Math.max(10, Math.min(400, Math.round(this.zoom * factor)))
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

  /** 右键菜单 */
  private onContextMenu(x: number, y: number): void {
    this.contextMenuX = x
    this.contextMenuY = y
    this.showContextMenu = true
  }

  /** 根据当前工具在画布上创建对象 */
  private createObjectAtCanvas(x: number, y: number): void {
    const tool = this.currentTool
    const frame = this.currentFrame
    if (!frame) return

    // 转换屏幕坐标到画布坐标
    const canvasX = (x - this.panX - 80) / this.zoomScale
    const canvasY = (y - this.panY - 50) / this.zoomScale
    // 考虑 Frame 偏移
    const frameRelX = canvasX - frame.x
    const frameRelY = canvasY - frame.y

    let obj: SceneObject | null = null
    let objName = ''

    if (tool === 'rectangle') {
      obj = createShapeObject('rectangle', frameRelX, frameRelY, 120, 80, '#3AC487')
      objName = '矩形'
    } else if (tool === 'ellipse') {
      obj = createShapeObject('ellipse', frameRelX, frameRelY, 120, 120, '#3B82F6')
      objName = '椭圆'
    } else if (tool === 'text') {
      obj = createTextObject('双击编辑文字', frameRelX, frameRelY, 200, 36)
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

    const canvasStartX = (this.drawStartX - this.panX - 80) / this.zoomScale - frame.x
    const canvasStartY = (this.drawStartY - this.panY - 50) / this.zoomScale - frame.y
    const canvasEndX = (endX - this.panX - 80) / this.zoomScale - frame.x
    const canvasEndY = (endY - this.panY - 50) / this.zoomScale - frame.y

    const x = Math.min(canvasStartX, canvasEndX)
    const y = Math.min(canvasStartY, canvasEndY)
    const w = Math.max(10, Math.abs(canvasEndX - canvasStartX))
    const h = Math.max(10, Math.abs(canvasEndY - canvasStartY))

    let obj: SceneObject | null = null
    let objName = ''

    if (this.currentTool === 'rectangle') {
      obj = createShapeObject('rectangle', x, y, w, h, '#3AC487')
      objName = '矩形'
    } else if (this.currentTool === 'ellipse') {
      obj = createShapeObject('ellipse', x, y, w, h, '#3B82F6')
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
    this.editingObjId = obj.id
    this.editingText = obj.text ?? ''
    this.editingObjX = obj.transform.x
    this.editingObjY = obj.transform.y
    this.editingObjW = obj.transform.width
    this.editingObjH = obj.transform.height
    this.editingObjFontSize = obj.fontSize ?? 14
    this.editingObjColor = obj.color ?? '#1F2329'
    this.editingObjFontWeight = obj.fontWeight ?? 400
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
    this.editingObjId = ''
    this.editingText = ''
  }

  /** 获取当前工具对应的光标图标 */
  private get toolCursorIcon(): string {
    const map: Record<string, string> = {
      'select': '',
      'rectangle': Icon.rect,
      'ellipse': Icon.circle,
      'text': Icon.text,
      'eyedropper': Icon.eyedropper,
      'hand': Icon.hand,
      'zoom': Icon.zoom_in,
    }
    return map[this.currentTool] ?? ''
  }

  /** 获取当前工具对应的光标名称 */
  private get toolCursorName(): string {
    const map: Record<string, string> = {
      'select': '选择',
      'rectangle': '矩形',
      'ellipse': '椭圆',
      'text': '文字',
      'eyedropper': '吸管',
      'hand': '抓手',
      'zoom': '缩放',
    }
    return map[this.currentTool] ?? ''
  }

  /** 完成框选并选中框内对象 */
  private commitBoxSelect(): void {
    this.isBoxSelecting = false
    // 转换框选区域到画布坐标
    const scale = this.zoomScale
    const bx = (Math.min(this.boxStartX, this.boxCurrentX) - this.panX - 80) / scale
    const by = (Math.min(this.boxStartY, this.boxCurrentY) - this.panY - 50) / scale
    const bw = Math.abs(this.boxCurrentX - this.boxStartX) / scale
    const bh = Math.abs(this.boxCurrentY - this.boxStartY) / scale

    if (bw < 5 || bh < 5) return // 太小的框忽略

    const frame = this.currentFrame
    if (!frame) return

    // 找到框内对象
    const selectedIds: string[] = []
    for (const layer of frame.children) {
      for (const obj of layer.objects) {
        const ox = obj.transform.x
        const oy = obj.transform.y
        const ow = obj.transform.width
        const oh = obj.transform.height
        // 检测矩形相交
        if (ox < bx + bw && ox + ow > bx && oy < by + bh && oy + oh > by) {
          selectedIds.push(obj.id)
        }
      }
    }

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
        // 渲染所有 Frame
        ForEach(this.frames, (frame: Frame) => {
          FrameView({
            frame: frame,
            zoom: this.zoom,
            isSelected: frame.id === this.currentFrameId,
            onSelect: () => {
              this.currentFrameId = frame.id
              this.fusionStore.switchFrame(frame.id)
              this.selectedObjId = ''
            }
          })

          // 渲染当前选中 Frame 内的对象
          if (frame.id === this.currentFrameId) {
            ForEach(frame.children, (layer: Layer) => {
              ForEach(layer.objects, (obj: SceneObject) => {
                this.renderSceneObject(obj, layer.id)
              })
            })
          }
        }, (frame: Frame) => frame.id)

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
        if (this.hoveredObjId !== '' && this.hoveredObjId !== this.selectedObjId) {
          // 简化：通过对象查找并渲染虚线框
          const objects = this.getObjects()
          const hovered = objects.find((o: ObjectWithLayer) => o.obj.id === this.hoveredObjId)
          if (hovered) {
            Column()
              .width(hovered.obj.transform.width)
              .height(hovered.obj.transform.height)
              .border({ width: 1, color: ColorToken.info, style: BorderStyle.Dashed })
              .position({ x: hovered.obj.transform.x, y: hovered.obj.transform.y })
          }
        }

        // 选中框 + 8 控制点
        if (this.selectedObjId !== '') {
          const objects = this.getObjects()
          const selected = objects.find((o: ObjectWithLayer) => o.obj.id === this.selectedObjId)
          if (selected) {
            this.selectionOverlay(selected.obj.transform)
          }
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
          const bx = Math.min(this.boxStartX, this.boxCurrentX) - 80 - this.panX
          const by = Math.min(this.boxStartY, this.boxCurrentY) - 50 - this.panY
          const bw = Math.abs(this.boxCurrentX - this.boxStartX)
          const bh = Math.abs(this.boxCurrentY - this.boxStartY)
          Column()
            .width(bw > 0 ? bw : 1)
            .height(bh > 0 ? bh : 1)
            .border({ width: 1, color: ColorToken.info })
            .backgroundColor('#3B82F614')
            .position({ x: bx, y: by })
            .scale({ x: 1 / this.zoomScale, y: 1 / this.zoomScale })
        }

        // 拖拽创建预览矩形
        if (this.isDrawing) {
          const x = Math.min(this.drawStartX, this.drawCurrentX) - 80 - this.panX
          const y = Math.min(this.drawStartY, this.drawCurrentY) - 50 - this.panY
          const w = Math.abs(this.drawCurrentX - this.drawStartX)
          const h = Math.abs(this.drawCurrentY - this.drawStartY)
          Column()
            .width(w > 0 ? w : 1)
            .height(h > 0 ? h : 1)
            .border({ width: 1, color: ColorToken.primary, style: BorderStyle.Dashed })
            .backgroundColor('#3AC48714')
            .position({ x: x, y: y })
            .scale({ x: 1 / this.zoomScale, y: 1 / this.zoomScale })
        }
      }
      .position({ x: this.panX + 80, y: this.panY + 50 })
      .scale({ x: this.zoomScale, y: this.zoomScale, centerX: 0, centerY: 0 })

      // 右键菜单
      if (this.showContextMenu) {
        Column() {
          Row() {
            Text(Icon.copy).fontSize(10).fontColor(ColorToken.secondary)
            Text('复制').fontSize(FontSizeToken.level3).fontColor(ColorToken.body).margin({ left: 8 })
          }
          .width('100%').height(28).padding({ left: 10, right: 10 }).alignItems(VerticalAlign.Center)
          .onClick(() => {
            if (this.selectedObjId !== '') {
              this.fusionStore.duplicateObject(this.selectedObjId)
              this.syncFrames()
              this.showToast('已复制', Icon.copy, 'success')
            }
            this.showContextMenu = false
          })

          Row() {
            Text(Icon.trash).fontSize(10).fontColor(ColorToken.secondary)
            Text('删除').fontSize(FontSizeToken.level3).fontColor(ColorToken.body).margin({ left: 8 })
          }
          .width('100%').height(28).padding({ left: 10, right: 10 }).alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.deleteSelected()
            this.showContextMenu = false
          })
        }
        .width(160).padding({ top: 4, bottom: 4 })
        .borderRadius(8).backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .shadow({ radius: 16, color: '#0000002E', offsetX: 0, offsetY: 4 })
        .position({ x: this.contextMenuX, y: this.contextMenuY }).zIndex(200)
      }

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
            // 选择工具空白处：开始框选
            if (this.currentTool === 'select') {
              this.isBoxSelecting = true
              this.boxStartX = event.fingerList[0].globalX
              this.boxStartY = event.fingerList[0].globalY
              this.boxCurrentX = event.fingerList[0].globalX
              this.boxCurrentY = event.fingerList[0].globalY
              return
            }
            // 形状工具：开始拖拽创建
            if (this.currentTool === 'rectangle' || this.currentTool === 'ellipse') {
              this.isDrawing = true
              this.drawStartX = event.fingerList[0].globalX
              this.drawStartY = event.fingerList[0].globalY
              this.drawCurrentX = event.fingerList[0].globalX
              this.drawCurrentY = event.fingerList[0].globalY
              return
            }
            // 抓手或选择工具：开始平移
            this.isPanning = true
            this.panStartX = event.fingerList[0].globalX
            this.panStartY = event.fingerList[0].globalY
            this.panStartPanX = this.panX
            this.panStartPanY = this.panY
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.isBoxSelecting) {
              this.boxCurrentX = event.fingerList[0].globalX
              this.boxCurrentY = event.fingerList[0].globalY
              return
            }
            if (this.isDrawing) {
              this.drawCurrentX = event.fingerList[0].globalX
              this.drawCurrentY = event.fingerList[0].globalY
              return
            }
            if (this.isPanning) {
              const dx = event.fingerList[0].globalX - this.panStartX
              const dy = event.fingerList[0].globalY - this.panStartY
              this.panX = this.panStartPanX + dx
              this.panY = this.panStartPanY + dy
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
            // 选择工具：点击空白处创建对象
            if (this.currentTool !== 'select' && this.currentTool !== 'hand' && this.currentTool !== 'zoom') {
              // 判断是否短点击（拖拽距离 < 10px）
              const dx = Math.abs(event.fingerList[0].globalX - this.panStartX)
              const dy = Math.abs(event.fingerList[0].globalY - this.panStartY)
              if (dx < 10 && dy < 10) {
                // 不创建，只取消平移状态
              }
            }
            this.isPanning = false
          }),
        PinchGesture({ fingers: 2 })
          .onActionUpdate((event: GestureEvent) => {
            const newZoom = Math.round(this.zoom * event.scale)
            this.zoom = Math.max(10, Math.min(400, newZoom))
          })
      )
    )
    .gesture(
      TapGesture({ count: 2 })
        .onAction((event: GestureEvent) => {
          // 双击空白处创建新 Frame
          if (this.currentTool === 'select' || this.currentTool === 'hand') {
            const x = (event.fingerList[0].globalX - this.panX - 80) / this.zoomScale
            const y = (event.fingerList[0].globalY - this.panY - 50) / this.zoomScale
            const frame = this.fusionStore.newFrame('single', '页面', x - 150, y - 200)
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
          this.dragObjId = obj.id
          this.dragStartX = event.fingerList[0].globalX
          this.dragStartY = event.fingerList[0].globalY
          this.dragObjStartX = obj.transform.x
          this.dragObjStartY = obj.transform.y
          this.selectedObjId = obj.id
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.dragObjId === obj.id) {
            const dx = (event.fingerList[0].globalX - this.dragStartX) / this.zoomScale
            const dy = (event.fingerList[0].globalY - this.dragStartY) / this.zoomScale
            const newX = Math.round(this.dragObjStartX + dx)
            const newY = Math.round(this.dragObjStartY + dy)
            this.fusionStore.moveObject(obj.id, newX, newY, true)
            // 强制刷新
            this.syncFrames()
          }
        })
        .onActionEnd(() => {
          if (this.dragObjId === obj.id) {
            // 最终位置写入历史
            this.fusionStore.moveObject(obj.id, this.fusionStore.getSelectedObjects()[0]?.transform.x ?? 0, this.fusionStore.getSelectedObjects()[0]?.transform.y ?? 0)
          }
          this.dragObjId = ''
        })
      )
    )
  }

  // ─── 选中框 + 8 控制点 ───
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
  }

  @Builder
  handle(hx: number, hy: number, pos: string, t: Transform): void {
    Column().width(6).height(6).backgroundColor(ColorToken.white)
      .border({ width: 1, color: ColorToken.info }).borderRadius(1)
      .position({ x: hx, y: hy }).zIndex(10)
      .gesture(
        PanGesture()
          .onActionStart((e: GestureEvent) => {
            this.dragObjId = this.selectedObjId
            this.dragStartX = e.fingerList[0].globalX
            this.dragStartY = e.fingerList[0].globalY
            this.dragObjStartX = t.width
            this.dragObjStartY = t.height
          })
          .onActionUpdate((e: GestureEvent) => {
            if (this.dragObjId === this.selectedObjId) {
              const dx = (e.fingerList[0].globalX - this.dragStartX) / this.zoomScale
              const dy = (e.fingerList[0].globalY - this.dragStartY) / this.zoomScale
              let nw = t.width, nh = t.height
              if (pos === 'se' || pos === 'ne' || pos === 'e') nw = Math.max(10, Math.round(this.dragObjStartX + dx))
              if (pos === 'se' || pos === 'sw' || pos === 's') nh = Math.max(10, Math.round(this.dragObjStartY + dy))
              if (pos === 'nw' || pos === 'w') nw = Math.max(10, Math.round(this.dragObjStartX - dx))
              if (pos === 'nw' || pos === 'n') nh = Math.max(10, Math.round(this.dragObjStartY - dy))
              // 更新对象尺寸
              const objects = this.getObjects()
              const sel = objects.find((o: ObjectWithLayer) => o.obj.id === this.selectedObjId)
              if (sel) {
                sel.obj.transform.width = nw
                sel.obj.transform.height = nh
                this.syncFrames()
              }
            }
          })
          .onActionEnd(() => { this.dragObjId = '' })
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
    const map: Record<string, string> = {
      'single': Icon.rect,
      'poster': Icon.image,
      'book-page': Icon.book,
      'spread': Icon.book_open,
    }
    return map[type] ?? Icon.rect
  }

  private zoomIn(): void { this.zoom = Math.min(400, Math.round(this.zoom * 1.2)) }
  private zoomOut(): void { this.zoom = Math.max(10, Math.round(this.zoom / 1.2)) }
}
