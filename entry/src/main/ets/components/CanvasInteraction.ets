/**
 * CanvasInteraction - 画布交互引擎
 *
 * 对应原型 src/composables/useCanvasInteraction.ts
 * 职责：
 *  - 对象选中 / 悬停状态管理
 *  - 拖拽移动对象（单选 / 多选）
 *  - 8 方向 Resize（nw/n/ne/e/se/s/sw/w）支持旋转对象
 *  - 旋转 handle（拖拽旋转对象）
 *  - 框选（空白处拖拽选中多个对象）
 *  - 形状绘制（矩形 / 椭圆拖拽创建）
 *  - 文本编辑状态管理
 *  - 命中检测（考虑旋转）
 */
import { Frame, SceneObject, Transform, Point, Size, Rect } from '../domain/SceneTypes'
import { ObjectWithLayer, CanvasRenderer } from './CanvasRenderer'
import { InfiniteCanvas } from './InfiniteCanvas'

/** Resize handle 位置 */
export type HandlePosition = 'nw' | 'n' | 'ne' | 'e' | 'se' | 's' | 'sw' | 'w'

/** 交互状态变化回调（由 CanvasStage 实现） */
export interface InteractionCallback {
  onSelectedChange(objId: string): void
  onHoveredChange(objId: string): void
  onDrawingChange(isDrawing: boolean, startX: number, startY: number, currentX: number, currentY: number): void
  onBoxSelectChange(isBoxSelecting: boolean, startX: number, startY: number, currentX: number, currentY: number): void
  onTextEditStart(objId: string): void
  onTextEditCancel(): void
  onToast(message: string, icon: string, type: string): void
  onSyncFrames(): void
}

/** Resize 结果（新位置 + 新尺寸） */
export interface ResizeResult {
  x: number
  y: number
  width: number
  height: number
}

/** 命中检测容差（px） */
const HIT_TOLERANCE = 2
const DRAG_THRESHOLD = 3
const MIN_SIZE = 10

export class CanvasInteraction {
  private static instance: CanvasInteraction
  private callback: InteractionCallback | null = null

  // ─── 拖拽内部状态 ───
  dragObjId: string = ''
  private dragStartX: number = 0
  private dragStartY: number = 0
  private dragObjStartX: number = 0
  private dragObjStartY: number = 0

  // ─── Resize 内部状态 ───
  private resizeStartW: number = 0
  private resizeStartH: number = 0
  private resizeStartX: number = 0
  private resizeStartY: number = 0
  private resizeObjRotation: number = 0

  // ─── 旋转内部状态 ───
  private rotateStartAngle: number = 0
  private rotateObjInitialRotation: number = 0

  private constructor() {}

  static getInstance(): CanvasInteraction {
    if (!CanvasInteraction.instance) {
      CanvasInteraction.instance = new CanvasInteraction()
    }
    return CanvasInteraction.instance
  }

  bindCallback(cb: InteractionCallback): void {
    this.callback = cb
  }

  unbindCallback(): void {
    this.callback = null
  }

  // ─── 旋转辅助 ───
  /** 将点绕中心旋转（反向旋转，用于将世界坐标转到局部坐标） */
  static reverseRotatePoint(px: number, py: number, cx: number, cy: number, angleDeg: number): Point {
    const rad = (-angleDeg * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    const dx = px - cx
    const dy = py - cy
    return { x: dx * cos - dy * sin + cx, y: dx * sin + dy * cos + cy } as Point
  }

  /** 将点绕中心旋转（正向旋转，用于将局部坐标转到世界坐标） */
  static rotatePoint(px: number, py: number, cx: number, cy: number, angleDeg: number): Point {
    const rad = (angleDeg * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    const dx = px - cx
    const dy = py - cy
    return { x: dx * cos - dy * sin + cx, y: dx * sin + dy * cos + cy } as Point
  }

  // ─── 命中检测 ───
  static isPointInObject(canvasX: number, canvasY: number, obj: SceneObject): boolean {
    const t = obj.transform
    if (t.rotation) {
      const cx = t.x + t.width / 2
      const cy = t.y + t.height / 2
      const local = CanvasInteraction.reverseRotatePoint(canvasX, canvasY, cx, cy, t.rotation)
      return local.x >= t.x - HIT_TOLERANCE && local.x <= t.x + t.width + HIT_TOLERANCE
        && local.y >= t.y - HIT_TOLERANCE && local.y <= t.y + t.height + HIT_TOLERANCE
    }
    return canvasX >= t.x - HIT_TOLERANCE
      && canvasX <= t.x + t.width + HIT_TOLERANCE
      && canvasY >= t.y - HIT_TOLERANCE
      && canvasY <= t.y + t.height + HIT_TOLERANCE
  }

  static hitTest(canvasX: number, canvasY: number, frame: Frame | null): SceneObject | null {
    if (!frame) return null
    for (let i = frame.children.length - 1; i >= 0; i--) {
      const layer = frame.children[i]
      if (!layer.visible || layer.locked) continue
      for (let j = layer.objects.length - 1; j >= 0; j--) {
        const obj = layer.objects[j]
        if (!obj.visible || obj.locked) continue
        if (CanvasInteraction.isPointInObject(canvasX, canvasY, obj)) {
          return obj
        }
      }
    }
    return null
  }

  // ─── 框选相交检测（支持旋转 OBB） ───
  static rectIntersect(obj: SceneObject, rect: Rect): boolean {
    const t = obj.transform
    if (!t.rotation) {
      return !(t.x + t.width < rect.x || rect.x + rect.width < t.x
        || t.y + t.height < rect.y || rect.y + rect.height < t.y)
    }
    return CanvasInteraction.obbAabbIntersect(t, rect)
  }

  /** OBB（旋转矩形）vs AABB 相交检测 - SAT */
  static obbAabbIntersect(obb: Transform, aabb: Rect): boolean {
    const cx = obb.x + obb.width / 2
    const cy = obb.y + obb.height / 2
    const rad = (obb.rotation * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    const hw = obb.width / 2
    const hh = obb.height / 2
    const corners: Point[] = [
      { x: cx + (-hw * cos - -hh * sin), y: cy + (-hw * sin + -hh * cos) } as Point,
      { x: cx + ( hw * cos - -hh * sin), y: cy + ( hw * sin + -hh * cos) } as Point,
      { x: cx + ( hw * cos -  hh * sin), y: cy + ( hw * sin +  hh * cos) } as Point,
      { x: cx + (-hw * cos -  hh * sin), y: cy + (-hw * sin +  hh * cos) } as Point,
    ]
    const obbMinX = Math.min(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
    const obbMaxX = Math.max(corners[0].x, corners[1].x, corners[2].x, corners[3].x)
    const obbMinY = Math.min(corners[0].y, corners[1].y, corners[2].y, corners[3].y)
    const obbMaxY = Math.max(corners[0].y, corners[1].y, corners[2].y, corners[3].y)
    if (obbMaxX < aabb.x || aabb.x + aabb.width < obbMinX
      || obbMaxY < aabb.y || aabb.y + aabb.height < obbMinY) {
      return false
    }
    const aabbCorners: Point[] = [
      { x: aabb.x, y: aabb.y } as Point,
      { x: aabb.x + aabb.width, y: aabb.y } as Point,
      { x: aabb.x + aabb.width, y: aabb.y + aabb.height } as Point,
      { x: aabb.x, y: aabb.y + aabb.height } as Point,
    ]
    const acx = aabb.x + aabb.width / 2
    const acy = aabb.y + aabb.height / 2
    const negRad = -rad
    const ncos = Math.cos(negRad)
    const nsin = Math.sin(negRad)
    const aabbLocalMinX = Math.min(...aabbCorners.map(c => {
      const dx = c.x - acx
      const dy = c.y - acy
      return dx * ncos - dy * nsin + cx
    }))
    const aabbLocalMaxX = Math.max(...aabbCorners.map(c => {
      const dx = c.x - acx
      const dy = c.y - acy
      return dx * ncos - dy * nsin + cx
    }))
    const aabbLocalMinY = Math.min(...aabbCorners.map(c => {
      const dx = c.x - acx
      const dy = c.y - acy
      return dx * nsin + dy * ncos + cy
    }))
    const aabbLocalMaxY = Math.max(...aabbCorners.map(c => {
      const dx = c.x - acx
      const dy = c.y - acy
      return dx * nsin + dy * ncos + cy
    }))
    if (aabbLocalMaxX < obb.x || obb.x + obb.width < aabbLocalMinX
      || aabbLocalMaxY < obb.y || obb.y + obb.height < aabbLocalMinY) {
      return false
    }
    return true
  }

  static getObjectsInBox(frame: Frame | null, rect: Rect): string[] {
    if (!frame) return []
    const result: string[] = []
    for (const layer of frame.children) {
      if (!layer.visible || layer.locked) continue
      for (const obj of layer.objects) {
        if (!obj.visible || obj.locked) continue
        if (CanvasInteraction.rectIntersect(obj, rect)) {
          result.push(obj.id)
        }
      }
    }
    return result
  }

  // ─── 选中 ───
  selectObject(objId: string): void {
    if (this.callback) {
      this.callback.onSelectedChange(objId)
    }
  }

  deselectAll(): void {
    if (this.callback) {
      this.callback.onSelectedChange('')
    }
  }

  setHovered(objId: string): void {
    if (this.callback) {
      this.callback.onHoveredChange(objId)
    }
  }

  // ─── 拖拽移动 ───
  startDrag(objId: string, screenX: number, screenY: number, objStartX: number, objStartY: number): void {
    this.dragObjId = objId
    this.dragStartX = screenX
    this.dragStartY = screenY
    this.dragObjStartX = objStartX
    this.dragObjStartY = objStartY
  }

  computeDragPosition(currentScreenX: number, currentScreenY: number, zoom: number): Point | null {
    if (this.dragObjId === '') return null
    const scale = InfiniteCanvas.zoomScale(zoom)
    const dx = (currentScreenX - this.dragStartX) / scale
    const dy = (currentScreenY - this.dragStartY) / scale
    return {
      x: Math.round(this.dragObjStartX + dx),
      y: Math.round(this.dragObjStartY + dy),
    } as Point
  }

  endDrag(): void {
    this.dragObjId = ''
  }

  get isDragging(): boolean {
    return this.dragObjId !== ''
  }

  // ─── Resize（支持旋转对象） ───
  startResize(objId: string, screenX: number, screenY: number, startW: number, startH: number, startX: number, startY: number, rotation: number): void {
    this.dragObjId = objId
    this.dragStartX = screenX
    this.dragStartY = screenY
    this.resizeStartW = startW
    this.resizeStartH = startH
    this.resizeStartX = startX
    this.resizeStartY = startY
    this.resizeObjRotation = rotation
  }

  computeResize(currentScreenX: number, currentScreenY: number, zoom: number, handle: HandlePosition): ResizeResult {
    const scale = InfiniteCanvas.zoomScale(zoom)
    let dx = (currentScreenX - this.dragStartX) / scale
    let dy = (currentScreenY - this.dragStartY) / scale

    if (this.resizeObjRotation) {
      const rad = (-this.resizeObjRotation * Math.PI) / 180
      const cos = Math.cos(rad)
      const sin = Math.sin(rad)
      const ld = { x: dx * cos - dy * sin, y: dx * sin + dy * cos } as Point
      dx = ld.x
      dy = ld.y
    }

    let nx = this.resizeStartX
    let ny = this.resizeStartY
    let nw = this.resizeStartW
    let nh = this.resizeStartH

    if (handle === 'se' || handle === 'ne' || handle === 'e') {
      nw = Math.max(MIN_SIZE, Math.round(this.resizeStartW + dx))
    }
    if (handle === 'se' || handle === 'sw' || handle === 's') {
      nh = Math.max(MIN_SIZE, Math.round(this.resizeStartH + dy))
    }
    if (handle === 'nw' || handle === 'w') {
      nw = Math.max(MIN_SIZE, Math.round(this.resizeStartW - dx))
    }
    if (handle === 'nw' || handle === 'n') {
      nh = Math.max(MIN_SIZE, Math.round(this.resizeStartH - dy))
    }

    if (this.resizeObjRotation) {
      const cx = this.resizeStartX + this.resizeStartW / 2
      const cy = this.resizeStartY + this.resizeStartH / 2
      nx = cx - nw / 2
      ny = cy - nh / 2
    } else {
      if (handle.includes('w')) nx = this.resizeStartX + dx
      if (handle.includes('n')) ny = this.resizeStartY + dy
      if (nw < MIN_SIZE && handle.includes('w')) nx = this.resizeStartX + this.resizeStartW - MIN_SIZE
      if (nh < MIN_SIZE && handle.includes('n')) ny = this.resizeStartY + this.resizeStartH - MIN_SIZE
    }

    return { x: Math.round(nx), y: Math.round(ny), width: Math.round(nw), height: Math.round(nh) } as ResizeResult
  }

  endResize(): void {
    this.dragObjId = ''
    this.resizeObjRotation = 0
  }

  // ─── 旋转 Handle ───
  startRotate(objId: string, screenX: number, screenY: number, objRotation: number): void {
    this.dragObjId = objId
    this.dragStartX = screenX
    this.dragStartY = screenY
    this.rotateObjInitialRotation = objRotation
    this.rotateStartAngle = 0
  }

  computeRotation(currentScreenX: number, currentScreenY: number, zoom: number, cx: number, cy: number): number {
    if (this.dragObjId === '') return this.rotateObjInitialRotation
    const scale = InfiniteCanvas.zoomScale(zoom)
    const startAngle = Math.atan2(
      (this.dragStartY - cy * scale - InfiniteCanvas.OFFSET_Y - 0) / scale,
      (this.dragStartX - cx * scale - InfiniteCanvas.OFFSET_X - 0) / scale,
    )
    const currentAngle = Math.atan2(
      (currentScreenY - cy * scale - InfiniteCanvas.OFFSET_Y - 0) / scale,
      (currentScreenX - cx * scale - InfiniteCanvas.OFFSET_X - 0) / scale,
    )
    const deltaDeg = (currentAngle - startAngle) * 180 / Math.PI
    return this.rotateObjInitialRotation + Math.round(deltaDeg)
  }

  endRotate(): void {
    this.dragObjId = ''
    this.rotateObjInitialRotation = 0
  }

  // ─── 框选 ───
  startBoxSelect(screenX: number, screenY: number): void {
    if (this.callback) {
      this.callback.onBoxSelectChange(true, screenX, screenY, screenX, screenY)
    }
  }

  updateBoxSelect(currentScreenX: number, currentScreenY: number, startX: number, startY: number): void {
    if (this.callback) {
      this.callback.onBoxSelectChange(true, startX, startY, currentScreenX, currentScreenY)
    }
  }

  commitBoxSelect(
    startX: number, startY: number, currentX: number, currentY: number,
    panX: number, panY: number, zoom: number,
    frame: Frame | null,
  ): string[] {
    if (this.callback) {
      this.callback.onBoxSelectChange(false, 0, 0, 0, 0)
    }
    const scale = InfiniteCanvas.zoomScale(zoom)
    const bx = (Math.min(startX, currentX) - panX - InfiniteCanvas.OFFSET_X) / scale
    const by = (Math.min(startY, currentY) - panY - InfiniteCanvas.OFFSET_Y) / scale
    const bw = Math.abs(currentX - startX) / scale
    const bh = Math.abs(currentY - startY) / scale
    if (bw < 5 || bh < 5) return []
    return CanvasInteraction.getObjectsInBox(frame, { x: bx, y: by, width: bw, height: bh } as Rect)
  }

  // ─── 形状绘制 ───
  startDrawing(screenX: number, screenY: number): void {
    if (this.callback) {
      this.callback.onDrawingChange(true, screenX, screenY, screenX, screenY)
    }
  }

  updateDrawing(currentScreenX: number, currentScreenY: number, startX: number, startY: number): void {
    if (this.callback) {
      this.callback.onDrawingChange(true, startX, startY, currentScreenX, currentScreenY)
    }
  }

  commitDrawing(
    startX: number, startY: number, endX: number, endY: number,
    panX: number, panY: number, zoom: number, frame: Frame | null,
  ): Rect | null {
    if (this.callback) {
      this.callback.onDrawingChange(false, 0, 0, 0, 0)
    }
    if (!frame) return null
    const scale = InfiniteCanvas.zoomScale(zoom)
    const canvasStartX = (startX - panX - InfiniteCanvas.OFFSET_X) / scale - frame.x
    const canvasStartY = (startY - panY - InfiniteCanvas.OFFSET_Y) / scale - frame.y
    const canvasEndX = (endX - panX - InfiniteCanvas.OFFSET_X) / scale - frame.x
    const canvasEndY = (endY - panY - InfiniteCanvas.OFFSET_Y) / scale - frame.y
    const w = Math.max(MIN_SIZE, Math.abs(canvasEndX - canvasStartX))
    const h = Math.max(MIN_SIZE, Math.abs(canvasEndY - canvasStartY))
    if (w < MIN_SIZE || h < MIN_SIZE) return null
    return {
      x: Math.min(canvasStartX, canvasEndX),
      y: Math.min(canvasStartY, canvasEndY),
      width: w,
      height: h,
    } as Rect
  }

  // ─── 文本编辑 ───
  startTextEdit(obj: SceneObject): void {
    if (this.callback) {
      this.callback.onTextEditStart(obj.id)
    }
  }

  cancelTextEdit(): void {
    if (this.callback) {
      this.callback.onTextEditCancel()
    }
  }

  // ─── 工具光标 ───
  static getToolCursorIcon(tool: string): string {
    const map: Record<string, string> = {
      'select': '', 'rectangle': 'rect', 'ellipse': 'circle',
      'text': 'text', 'eyedropper': 'eyedropper', 'hand': 'hand', 'zoom': 'zoom_in',
    }
    return map[tool] ?? ''
  }

  static getToolCursorName(tool: string): string {
    const map: Record<string, string> = {
      'select': '选择', 'rectangle': '矩形', 'ellipse': '椭圆',
      'text': '文字', 'eyedropper': '吸管', 'hand': '抓手', 'zoom': '缩放',
    }
    return map[tool] ?? ''
  }

  static isShapeTool(tool: string): boolean {
    return tool === 'rectangle' || tool === 'ellipse'
  }

  static isCursorTool(tool: string): boolean {
    return tool !== 'select' && tool !== 'hand'
  }

  static isEyedropper(tool: string): boolean {
    return tool === 'eyedropper'
  }

  static isHandTool(tool: string): boolean {
    return tool === 'hand'
  }

  static isZoomTool(tool: string): boolean {
    return tool === 'zoom'
  }

  static toolNameToShape(tool: string): string {
    if (tool === 'rectangle') return 'rectangle'
    if (tool === 'ellipse') return 'ellipse'
    return 'rectangle'
  }

  static toolNameToCornerRadius(tool: string): number {
    return 0
  }

  static findObjectAt(objects: SceneObject[], x: number, y: number): SceneObject | null {
    for (let i = objects.length - 1; i >= 0; i--) {
      const obj = objects[i]
      if (!obj.visible || obj.locked) continue
      const t = obj.transform
      if (x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height) {
        return obj
      }
    }
    return null
  }

  static pickColorFromObjects(objects: SceneObject[], frame: Frame | null, x: number, y: number): string {
    const hit = CanvasInteraction.findObjectAt(objects, x, y)
    if (hit) {
      const color = hit.fill ?? hit.color ?? '#3AC487'
      return color
    }
    if (frame) {
      return frame.background ?? '#FFFFFF'
    }
    return '#FFFFFF'
  }
}
