/**
 * InfiniteCanvas - 无限画布视口引擎
 *
 * 对应原型 src/composables/useInfiniteCanvas.ts
 * 职责：
 *  - 画布平移状态管理（Space+拖拽 / 中键 / 手势）
 *  - 画布缩放（滚轮 / 双指捏合 / 按钮）
 *  - 屏幕 ↔ 画布坐标转换
 *  - 适配视口到所有 Frame
 *  - Frame 选择与移动
 *
 * 设计说明：
 *  - 本类持有非响应式交互状态（isPanning / panStart 等）
 *  - 通过 ViewportCallback 回调通知 CanvasStage 更新 @State
 *  - 响应式状态（zoom / panX / panY）仍由 CanvasStage 的 @State 持有
 */
import { Frame, Point, FitToFramesResult } from '../domain/SceneTypes'

/** 视口变化回调（由 CanvasStage 实现，用于同步 @State） */
export interface ViewportCallback {
  onZoomChange(zoom: number): void
  onPanChange(panX: number, panY: number): void
}

/** 缩放范围 */
const MIN_ZOOM = 10
const MAX_ZOOM = 400

/** 画布内容层相对视口左上角的固定偏移（与 CanvasStage 中一致） */
const CANVAS_OFFSET_X = 80
const CANVAS_OFFSET_Y = 50

export class InfiniteCanvas {
  private static instance: InfiniteCanvas

  /** 视口变化回调 */
  private callback: ViewportCallback | null = null

  // ─── 平移内部状态 ───
  isPanning: boolean = false
  private panStartX: number = 0
  private panStartY: number = 0
  private panStartPanX: number = 0
  private panStartPanY: number = 0

  private constructor() {}

  static getInstance(): InfiniteCanvas {
    if (!InfiniteCanvas.instance) {
      InfiniteCanvas.instance = new InfiniteCanvas()
    }
    return InfiniteCanvas.instance
  }

  /** 绑定视口变化回调 */
  bindCallback(cb: ViewportCallback): void {
    this.callback = cb
  }

  /** 解绑回调 */
  unbindCallback(): void {
    this.callback = null
  }

  // ─── 常量暴露 ───
  static readonly MIN_ZOOM = MIN_ZOOM
  static readonly MAX_ZOOM = MAX_ZOOM
  static readonly OFFSET_X = CANVAS_OFFSET_X
  static readonly OFFSET_Y = CANVAS_OFFSET_Y

  // ─── 缩放因子 ───
  /** zoom 百分比 → 缩放比例 */
  static zoomScale(zoom: number): number {
    return zoom / 100
  }

  /** 将缩放值限制在合法范围 */
  static clampZoom(zoom: number): number {
    return Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, Math.round(zoom)))
  }

  // ─── 坐标转换 ───
  /**
   * 屏幕坐标 → 画布坐标
   * @param screenX/Y 手势全局坐标
   * @param panX/panY 当前视口平移
   * @param zoom 当前缩放百分比
   */
  static screenToCanvas(screenX: number, screenY: number, panX: number, panY: number, zoom: number): Point {
    const scale = InfiniteCanvas.zoomScale(zoom)
    return {
      x: (screenX - panX - CANVAS_OFFSET_X) / scale,
      y: (screenY - panY - CANVAS_OFFSET_Y) / scale,
    } as Point
  }

  /**
   * 屏幕坐标 → Frame 内相对坐标
   * @param frame 目标 Frame（提供 x/y 偏移）
   */
  static screenToFrame(screenX: number, screenY: number, panX: number, panY: number, zoom: number, frame: Frame): Point {
    const c = InfiniteCanvas.screenToCanvas(screenX, screenY, panX, panY, zoom)
    return { x: c.x - frame.x, y: c.y - frame.y } as Point
  }

  /** 画布坐标 → 屏幕坐标 */
  static canvasToScreen(canvasX: number, canvasY: number, panX: number, panY: number, zoom: number): Point {
    const scale = InfiniteCanvas.zoomScale(zoom)
    return {
      x: canvasX * scale + panX + CANVAS_OFFSET_X,
      y: canvasY * scale + panY + CANVAS_OFFSET_Y,
    } as Point
  }

  // ─── 平移 ───
  /** 开始平移（记录起点） */
  startPan(startScreenX: number, startScreenY: number, currentPanX: number, currentPanY: number): void {
    this.isPanning = true
    this.panStartX = startScreenX
    this.panStartY = startScreenY
    this.panStartPanX = currentPanX
    this.panStartPanY = currentPanY
  }

  /** 更新平移（计算增量并通知回调） */
  updatePan(currentScreenX: number, currentScreenY: number): void {
    if (!this.isPanning) return
    const dx = currentScreenX - this.panStartX
    const dy = currentScreenY - this.panStartY
    const newPanX = this.panStartPanX + dx
    const newPanY = this.panStartPanY + dy
    if (this.callback) {
      this.callback.onPanChange(newPanX, newPanY)
    }
  }

  /** 结束平移 */
  endPan(): void {
    this.isPanning = false
  }

  // ─── 缩放 ───
  /** 滚轮缩放（delta > 0 放大，delta < 0 缩小） */
  onWheelScroll(currentZoom: number, delta: number): number {
    const factor = delta > 0 ? 1.1 : 1 / 1.1
    return InfiniteCanvas.clampZoom(currentZoom * factor)
  }

  /** 按钮缩放：放大 */
  zoomIn(currentZoom: number): number {
    return InfiniteCanvas.clampZoom(currentZoom * 1.2)
  }

  /** 按钮缩放：缩小 */
  zoomOut(currentZoom: number): number {
    return InfiniteCanvas.clampZoom(currentZoom / 1.2)
  }

  /** 双指捏合缩放 */
  pinchZoom(currentZoom: number, scale: number): number {
    return InfiniteCanvas.clampZoom(currentZoom * scale)
  }

  /** 重置视口到 100% 并居中 */
  resetView(): void {
    if (this.callback) {
      this.callback.onZoomChange(100)
      this.callback.onPanChange(0, 0)
    }
  }

  /** 设置缩放（按钮 / 快捷键） */
  setZoom(zoom: number): void {
    if (this.callback) {
      this.callback.onZoomChange(InfiniteCanvas.clampZoom(zoom))
    }
  }

  // ─── 适配视口 ───
  /**
   * 适配所有 Frame 到视口
   * @param frames 所有 Frame 列表
   * @param viewportWidth/Height 视口可用宽高
   * @returns 计算出的 { zoom, panX, panY }
   */
  static fitToFrames(frames: Frame[], viewportWidth: number, viewportHeight: number): FitToFramesResult {
    if (frames.length === 0) {
      return { zoom: 100, panX: 0, panY: 0 } as FitToFramesResult
    }

    let minX = Infinity
    let minY = Infinity
    let maxX = -Infinity
    let maxY = -Infinity
    for (const f of frames) {
      minX = Math.min(minX, f.x)
      minY = Math.min(minY, f.y)
      maxX = Math.max(maxX, f.x + f.width)
      maxY = Math.max(maxY, f.y + f.height)
    }
    const contentW = maxX - minX
    const contentH = maxY - minY
    if (contentW <= 0 || contentH <= 0) {
      return { zoom: 100, panX: 0, panY: 0 } as FitToFramesResult
    }

    const availW = viewportWidth - CANVAS_OFFSET_X * 2
    const availH = viewportHeight - CANVAS_OFFSET_Y * 2
    const scaleX = availW / contentW
    const scaleY = availH / contentH
    const scale = Math.min(scaleX, scaleY) * 0.9
    const zoom = InfiniteCanvas.clampZoom(scale * 100)

    const contentCenterX = (minX + maxX) / 2
    const contentCenterY = (minY + maxY) / 2
    const viewportCenterX = viewportWidth / 2
    const viewportCenterY = viewportHeight / 2
    const s = InfiniteCanvas.zoomScale(zoom)
    const panX = viewportCenterX - CANVAS_OFFSET_X - contentCenterX * s
    const panY = viewportCenterY - CANVAS_OFFSET_Y - contentCenterY * s

    return { zoom, panX, panY } as FitToFramesResult
  }

  /** 适配视口并通知回调 */
  fitToFramesAndApply(frames: Frame[], viewportWidth: number, viewportHeight: number): void {
    const result = InfiniteCanvas.fitToFrames(frames, viewportWidth, viewportHeight)
    if (this.callback) {
      this.callback.onZoomChange(result.zoom)
      this.callback.onPanChange(result.panX, result.panY)
    }
  }
}
