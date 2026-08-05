/**
 * useInfiniteCanvas - 无限画布交互引擎
 *
 * 职责：
 *  - 画布平移（Space + 拖拽 / 中键拖拽 / 触摸板）
 *  - 画布缩放（Ctrl + 滚轮 / 双指捏合）
 *  - Frame 选择（点击 Frame）
 *  - Frame 拖拽移动（选中后拖拽）
 *  - 空白处点击取消选择
 *  - 双击空白处创建新 Frame
 *  - Esc 退出 Frame 编辑模式
 *
 * 与 useCanvasInteraction 的关系：
 *  - useCanvasInteraction 负责单个 Frame 内部的对象级交互
 *  - useInfiniteCanvas 负责 Frame 之间的画布级交互
 */
import { ref, computed, type Ref } from 'vue'
import { useFusionDocumentStore } from '../stores/fusionDocument'

export interface UseInfiniteCanvasOptions {
  /** 视口容器元素（用于计算相对坐标） */
  viewportRef: Ref<HTMLElement | null>
  /** 视口宽度 */
  viewportWidth: Ref<number>
  /** 视口高度 */
  viewportHeight: Ref<number>
}

/** 缩放范围 */
const MIN_ZOOM = 0.05
const MAX_ZOOM = 8

export function useInfiniteCanvas(opts: UseInfiniteCanvasOptions) {
  const fusion = useFusionDocumentStore()

  // ─── 视口状态（从 scene.canvas 读取） ───
  const viewportX = computed(() => fusion.scene.canvas?.viewportX ?? 0)
  const viewportY = computed(() => fusion.scene.canvas?.viewportY ?? 0)
  const zoom = computed(() => fusion.scene.canvas?.zoom ?? 1)

  // ─── 交互状态 ───
  const isPanning = ref(false)
  const isSpaceDown = ref(false)
  const cursor = ref<string>('default')
  const editingFrameId = ref<string | null>(null)

  // ─── 拖拽平移内部状态 ───
  let panStartClientX = 0
  let panStartClientY = 0
  let panStartViewportX = 0
  let panStartViewportY = 0

  // ─── 视口变换样式（应用到无限画布容器） ───
  const canvasTransform = computed(() => {
    return `translate(${opts.viewportWidth.value / 2}px, ${opts.viewportHeight.value / 2}px) scale(${zoom.value}) translate(${-viewportX.value}px, ${-viewportY.value}px)`
  })

  // ─── 屏幕 → 画布坐标转换 ───
  function screenToCanvas(clientX: number, clientY: number): { x: number; y: number } {
    const rect = opts.viewportRef.value?.getBoundingClientRect()
    if (!rect) return { x: 0, y: 0 }
    // 视口中心到鼠标的偏移
    const dx = clientX - rect.left - opts.viewportWidth.value / 2
    const dy = clientY - rect.top - opts.viewportHeight.value / 2
    // 反向变换：除以缩放，加回视口中心
    const x = dx / zoom.value + viewportX.value
    const y = dy / zoom.value + viewportY.value
    return { x, y }
  }

  // ─── 平移 ───
  function startPan(clientX: number, clientY: number): void {
    isPanning.value = true
    panStartClientX = clientX
    panStartClientY = clientY
    panStartViewportX = viewportX.value
    panStartViewportY = viewportY.value
    cursor.value = 'grabbing'
  }

  function updatePan(clientX: number, clientY: number): void {
    if (!isPanning.value) return
    const dx = (clientX - panStartClientX) / zoom.value
    const dy = (clientY - panStartClientY) / zoom.value
    fusion.updateCanvasViewport({
      viewportX: panStartViewportX - dx,
      viewportY: panStartViewportY - dy,
    })
  }

  function endPan(): void {
    isPanning.value = false
    cursor.value = isSpaceDown.value ? 'grab' : 'default'
  }

  // ─── 缩放（以鼠标位置为中心） ───
  function zoomAt(clientX: number, clientY: number, delta: number): void {
    const oldZoom = zoom.value
    // delta > 0 放大，delta < 0 缩小
    const factor = delta > 0 ? 1.1 : 1 / 1.1
    let newZoom = oldZoom * factor
    newZoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, newZoom))
    if (newZoom === oldZoom) return

    // 保持鼠标位置在画布上不变：
    // newViewport = mouseCanvas - (mouseScreen - viewportCenter) / newZoom
    const rect = opts.viewportRef.value?.getBoundingClientRect()
    if (!rect) {
      fusion.updateCanvasViewport({ zoom: newZoom })
      return
    }
    const mouseCanvas = screenToCanvas(clientX, clientY)
    const mouseCanvasX = mouseCanvas.x
    const mouseCanvasY = mouseCanvas.y
    const dx = clientX - rect.left - opts.viewportWidth.value / 2
    const dy = clientY - rect.top - opts.viewportHeight.value / 2
    const newViewportX = mouseCanvasX - dx / newZoom
    const newViewportY = mouseCanvasY - dy / newZoom
    fusion.updateCanvasViewport({
      zoom: newZoom,
      viewportX: newViewportX,
      viewportY: newViewportY,
    })
  }

  // ─── 设置缩放（以视口为中心） ───
  function setZoom(newZoom: number): void {
    const clamped = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, newZoom))
    fusion.updateCanvasViewport({ zoom: clamped })
  }

  // ─── 适配视口到所有 Frame ───
  function fitToFrames(): void {
    fusion.fitToFrames(opts.viewportWidth.value, opts.viewportHeight.value)
  }

  // ─── Frame 选择 ───
  function selectFrame(frameId: string, additive: boolean): void {
    if (additive) {
      // Shift 加选（暂用单选）
      fusion.switchToFrame(frameId)
    } else {
      fusion.switchToFrame(frameId)
    }
  }

  // ─── 进入 Frame 编辑模式 ───
  function enterFrameEdit(frameId: string): void {
    fusion.switchToFrame(frameId)
    editingFrameId.value = frameId
  }

  function exitFrameEdit(): void {
    editingFrameId.value = null
  }

  // ─── 移动 Frame ───
  function moveFrame(frameId: string, x: number, y: number): void {
    fusion.moveFrameTo(frameId, x, y)
  }

  // ─── 调整 Frame 尺寸 ───
  function resizeFrame(frameId: string, width: number, height: number): void {
    fusion.resizeFrameTo(frameId, width, height)
  }

  // ─── 空白处点击：取消选择 ───
  function onBackgroundClick(): void {
    if (editingFrameId.value) {
      exitFrameEdit()
    } else {
      fusion.deselectAll()
    }
  }

  // ─── 键盘事件处理 ───
  function onKeyDown(e: KeyboardEvent): void {
    if (e.code === 'Space' && !isSpaceDown.value) {
      isSpaceDown.value = true
      cursor.value = 'grab'
    }
    if (e.key === 'Escape' && editingFrameId.value) {
      exitFrameEdit()
    }
    // Ctrl/Cmd + 0: 适配视口
    if ((e.ctrlKey || e.metaKey) && e.key === '0') {
      e.preventDefault()
      fitToFrames()
    }
  }

  function onKeyUp(e: KeyboardEvent): void {
    if (e.code === 'Space') {
      isSpaceDown.value = false
      cursor.value = isPanning.value ? 'grabbing' : 'default'
    }
  }

  // ─── 鼠标事件处理（由 CanvasStage 委托） ───
  function onMouseDown(e: MouseEvent): void {
    // 中键或 Space+左键：平移
    if (e.button === 1 || (e.button === 0 && isSpaceDown.value)) {
      e.preventDefault()
      startPan(e.clientX, e.clientY)
      return
    }
    // 左键空白处：取消选择
    if (e.button === 0) {
      onBackgroundClick()
    }
  }

  function onMouseMove(e: MouseEvent): void {
    if (isPanning.value) {
      updatePan(e.clientX, e.clientY)
    }
  }

  function onMouseUp(e: MouseEvent): void {
    if (isPanning.value) {
      endPan()
    }
  }

  function onWheel(e: WheelEvent): void {
    // Ctrl + 滚轮：缩放
    if (e.ctrlKey || e.metaKey) {
      e.preventDefault()
      zoomAt(e.clientX, e.clientY, -e.deltaY)
    } else {
      // 普通滚轮：平移
      e.preventDefault()
      fusion.updateCanvasViewport({
        viewportX: viewportX.value + e.deltaX / zoom.value,
        viewportY: viewportY.value + e.deltaY / zoom.value,
      })
    }
  }

  function onDblClick(e: MouseEvent): void {
    // 双击空白处：创建新 Frame（简化版：创建 single Frame）
    const { x, y } = screenToCanvas(e.clientX, e.clientY)
    const frame = fusion.newFrame({
      type: 'single',
      name: `页面 ${fusion.frames.length + 1}`,
      x: x - 297, // 居中
      y: y - 420,
    })
    // 自动切换到新创建的 Frame
    if (frame) fusion.switchToFrame(frame.id)
  }

  return {
    // 视口状态
    viewportX,
    viewportY,
    zoom,
    canvasTransform,
    cursor,
    isPanning,
    isSpaceDown,
    editingFrameId,
    // 坐标转换
    screenToCanvas,
    // 缩放
    zoomAt,
    setZoom,
    fitToFrames,
    // Frame 操作
    selectFrame,
    enterFrameEdit,
    exitFrameEdit,
    moveFrame,
    resizeFrame,
    // 事件处理
    onMouseDown,
    onMouseMove,
    onMouseUp,
    onWheel,
    onDblClick,
    onKeyDown,
    onKeyUp,
  }
}
