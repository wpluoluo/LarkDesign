/**
 * useCanvasInteraction - 画布交互引擎
 *
 * 处理画布上的所有鼠标交互：
 *  - 单选 / 多选（Shift 加选）
 *  - 框选（空白处拖拽）
 *  - 拖拽移动选中对象
 *  - 调整尺寸（8 个 handle：nw/n/ne/e/se/s/sw/w）
 *  - 悬停高亮
 *
 * 工作流程：
 *  1. CanvasStage 提供 canvasRef、stageRef 与显示尺寸
 *  2. composable 监听 stage 上的 mousedown/mousemove/mouseup
 *  3. 命中检测通过遍历 Fusion DOM 对象（从顶到底）
 *  4. 修改 transform 时调用 fusion.pushHistory() 记录历史
 */
import { ref, computed, type Ref } from 'vue'
import type { SceneObject, Transform } from '../types'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useShapeDrawing } from './useShapeDrawing'

/** Resize handle 位置 */
export type HandlePosition = 'nw' | 'n' | 'ne' | 'e' | 'se' | 's' | 'sw' | 'w'

/** Handle → 鼠标样式映射 */
const HANDLE_CURSOR: Record<HandlePosition, string> = {
  nw: 'nwse-resize',
  se: 'nwse-resize',
  ne: 'nesw-resize',
  sw: 'nesw-resize',
  n: 'ns-resize',
  s: 'ns-resize',
  e: 'ew-resize',
  w: 'ew-resize',
}

/** Handle 大小（px） */
const HANDLE_SIZE = 8

/** 命中检测容差（px） */
const HIT_TOLERANCE = 2

/** 单次拖拽触发的最小距离（px） */
const DRAG_THRESHOLD = 3

export interface UseCanvasInteractionOptions {
  canvasRef: Ref<HTMLCanvasElement | null>
  stageRef: Ref<HTMLElement | null>
  /** 显示宽度（CSS 像素） */
  displayWidth: Ref<number>
  /** 显示高度（CSS 像素） */
  displayHeight: Ref<number>
  /** 触发重渲染 */
  requestRender: () => void
  /** 滚动容器（用于抓手工具平移） */
  scrollContainer?: Ref<HTMLElement | null>
}

export function useCanvasInteraction(opts: UseCanvasInteractionOptions) {
  const fusion = useFusionDocumentStore()

  // ─── 形状/文字工具绘制引擎 ───
  const shapeDrawing = useShapeDrawing({
    requestRender: opts.requestRender,
    canvasRef: opts.canvasRef,
    displayWidth: opts.displayWidth,
    displayHeight: opts.displayHeight,
    scrollContainer: opts.scrollContainer,
  })

  // ─── 交互状态 ───
  const hoverObjectId = ref<string | null>(null)
  const isDragging = ref(false)
  const isResizing = ref(false)
  const isBoxSelecting = ref(false)
  const activeHandle = ref<HandlePosition | null>(null)
  const cursor = ref<string>('default')

  // ─── 拖拽内部状态（不响应式） ───
  let dragStartX = 0
  let dragStartY = 0
  let dragStartPositions: Array<{ id: string; x: number; y: number; width: number; height: number }> = []
  let boxSelectStartX = 0
  let boxSelectStartY = 0
  const boxSelectRect = ref<{ x: number; y: number; width: number; height: number } | null>(null)

  // ─── 命中检测：从顶到底 ───
  function hitTest(x: number, y: number): SceneObject | null {
    for (let i = fusion.layers.length - 1; i >= 0; i--) {
      const layer = fusion.layers[i]
      if (!layer.visible || layer.locked) continue
      for (let j = layer.objects.length - 1; j >= 0; j--) {
        const obj = layer.objects[j]
        if (!obj.visible || obj.locked) continue
        if (isPointInObject(x, y, obj)) {
          return obj
        }
      }
    }
    return null
  }

  /** 点是否在对象内（考虑旋转：把点反向旋转到对象局部坐标系后做 AABB 测试） */
  function isPointInObject(x: number, y: number, obj: SceneObject): boolean {
    const t = obj.transform
    if (t.rotation) {
      const cx = t.x + t.width / 2
      const cy = t.y + t.height / 2
      const rad = (-t.rotation * Math.PI) / 180
      const cos = Math.cos(rad)
      const sin = Math.sin(rad)
      const dx = x - cx
      const dy = y - cy
      const rx = dx * cos - dy * sin + cx
      const ry = dx * sin + dy * cos + cy
      return rx >= t.x - HIT_TOLERANCE && rx <= t.x + t.width + HIT_TOLERANCE
        && ry >= t.y - HIT_TOLERANCE && ry <= t.y + t.height + HIT_TOLERANCE
    }
    return x >= t.x - HIT_TOLERANCE && x <= t.x + t.width + HIT_TOLERANCE
      && y >= t.y - HIT_TOLERANCE && y <= t.y + t.height + HIT_TOLERANCE
  }

  // ─── Handle 命中检测（考虑旋转：handle 围绕对象中心旋转） ───
  function hitTestHandle(x: number, y: number, obj: SceneObject): HandlePosition | null {
    if (!fusion.selectedObjectIds.includes(obj.id)) return null
    const t = obj.transform
    const cx = t.x + t.width / 2
    const cy = t.y + t.height / 2
    const rad = (t.rotation * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    // 8 个 handle 在局部坐标系中（相对中心）的位置
    const localHandles: Array<{ pos: HandlePosition; lx: number; ly: number }> = [
      { pos: 'nw', lx: -t.width / 2, ly: -t.height / 2 },
      { pos: 'n',  lx: 0,           ly: -t.height / 2 },
      { pos: 'ne', lx:  t.width / 2, ly: -t.height / 2 },
      { pos: 'e',  lx:  t.width / 2, ly: 0 },
      { pos: 'se', lx:  t.width / 2, ly:  t.height / 2 },
      { pos: 's',  lx: 0,           ly:  t.height / 2 },
      { pos: 'sw', lx: -t.width / 2, ly:  t.height / 2 },
      { pos: 'w',  lx: -t.width / 2, ly: 0 },
    ]
    const half = HANDLE_SIZE / 2 + HIT_TOLERANCE
    for (const h of localHandles) {
      // 局部坐标旋转到世界坐标
      const hx = cx + (h.lx * cos - h.ly * sin)
      const hy = cy + (h.lx * sin + h.ly * cos)
      if (x >= hx - half && x <= hx + half && y >= hy - half && y <= hy + half) {
        return h.pos
      }
    }
    return null
  }

  // ─── 屏幕 → 画布坐标 ───
  function screenToCanvas(clientX: number, clientY: number): { x: number; y: number } {
    const rect = opts.canvasRef.value?.getBoundingClientRect()
    if (!rect) return { x: 0, y: 0 }
    const sx = (clientX - rect.left) / rect.width * opts.displayWidth.value
    const sy = (clientY - rect.top) / rect.height * opts.displayHeight.value
    return { x: sx, y: sy }
  }

  // ─── 鼠标按下 ───
  function onMouseDown(e: MouseEvent): void {
    if (e.button !== 0) return // 仅左键
    const { x, y } = screenToCanvas(e.clientX, e.clientY)

    // -1) 形状/文字工具：进入绘制模式（命中检测之前优先处理）
    if (shapeDrawing.maybeStartDraw(x, y, e)) {
      return
    }

    // 0) 优先检测是否点中 resize handle（仅单选时）
    //    handle 是 DOM 元素，但其位置由对象的 transform 决定
    if (fusion.selectedObjects.length === 1) {
      const obj = fusion.selectedObjects[0]
      const handle = hitTestHandle(x, y, obj)
      if (handle) {
        activeHandle.value = handle
        isResizing.value = true
        dragStartX = x
        dragStartY = y
        dragStartPositions = [{ id: obj.id, x: obj.transform.x, y: obj.transform.y, width: obj.transform.width, height: obj.transform.height }]
        fusion.pushHistory('调整尺寸')
        return
      }
    }

    // 1) 命中检测对象
    const hit = hitTest(x, y)
    if (hit) {
      // 选中对象
      if (e.shiftKey) {
        // 加选/减选
        fusion.selectObject(hit.id, true)
      } else if (!fusion.selectedObjectIds.includes(hit.id)) {
        // 单选（点击未选中的对象）
        fusion.selectObject(hit.id, false)
      }
      // 准备拖拽
      dragStartX = x
      dragStartY = y
      dragStartPositions = fusion.selectedObjects.map(o => ({
        id: o.id,
        x: o.transform.x,
        y: o.transform.y,
        width: o.transform.width,
        height: o.transform.height,
      }))
      isDragging.value = false // 等到 mousemove 触发阈值才置 true
      return
    }

    // 2) 点击空白处：开始框选 / 取消选中
    if (!e.shiftKey) {
      fusion.deselectAll()
    }
    isBoxSelecting.value = true
    boxSelectStartX = x
    boxSelectStartY = y
    boxSelectRect.value = { x, y, width: 0, height: 0 }
  }

  // ─── 鼠标移动 ───
  function onMouseMove(e: MouseEvent): void {
    const { x, y } = screenToCanvas(e.clientX, e.clientY)

    // 0) 形状绘制中：更新预览
    if (shapeDrawing.isDrawing.value) {
      shapeDrawing.updateDrawPreview(x, y)
      return
    }

    // 1) 正在 resize
    if (isResizing.value && activeHandle.value && dragStartPositions.length === 1) {
      const dx = x - dragStartX
      const dy = y - dragStartY
      const start = dragStartPositions[0]
      const obj = findObjectById(start.id)
      if (!obj) return
      resizeObject(obj, start, activeHandle.value, dx, dy)
      opts.requestRender()
      return
    }

    // 2) 正在拖拽（达到阈值才真正移动）
    if (dragStartPositions.length > 0 && (isDragging.value || !isBoxSelecting.value)) {
      const dx = x - dragStartX
      const dy = y - dragStartY
      if (!isDragging.value) {
        if (Math.abs(dx) < DRAG_THRESHOLD && Math.abs(dy) < DRAG_THRESHOLD) return
        isDragging.value = true
        fusion.pushHistory('移动对象')
      }
      // 应用增量
      dragStartPositions.forEach(start => {
        const obj = findObjectById(start.id)
        if (obj) {
          obj.transform.x = start.x + dx
          obj.transform.y = start.y + dy
        }
      })
      opts.requestRender()
      return
    }

    // 3) 正在框选
    if (isBoxSelecting.value) {
      boxSelectRect.value = {
        x: Math.min(boxSelectStartX, x),
        y: Math.min(boxSelectStartY, y),
        width: Math.abs(x - boxSelectStartX),
        height: Math.abs(y - boxSelectStartY),
      }
      // 实时选中与框相交的对象
      updateBoxSelection(e.shiftKey)
      return
    }

    // 4) 悬停高亮 + cursor
    const hit = hitTest(x, y)
    hoverObjectId.value = hit?.id ?? null
    // 形状/文字工具激活时：显示 crosshair
    if (shapeDrawing.isShapeTool.value || shapeDrawing.isTextTool.value) {
      cursor.value = 'crosshair'
      return
    }
    // 吸管/抓手/缩放工具
    if (shapeDrawing.isEyedropper.value) {
      cursor.value = 'crosshair'
      return
    }
    if (shapeDrawing.isHandTool.value) {
      cursor.value = shapeDrawing.isDrawing.value ? 'grabbing' : 'grab'
      return
    }
    if (shapeDrawing.isZoomTool.value) {
      cursor.value = 'zoom-in'
      return
    }
    // 检测是否悬停在 handle 上
    if (fusion.selectedObjects.length === 1) {
      const handle = hitTestHandle(x, y, fusion.selectedObjects[0])
      if (handle) {
        cursor.value = HANDLE_CURSOR[handle]
        return
      }
    }
    cursor.value = hit ? 'move' : 'default'
  }

  // ─── 鼠标释放 ───
  function onMouseUp(_e: MouseEvent): void {
    // 形状绘制中：完成对象创建
    if (shapeDrawing.isDrawing.value) {
      shapeDrawing.commitDraw()
      return
    }
    isDragging.value = false
    isResizing.value = false
    isBoxSelecting.value = false
    activeHandle.value = null
    dragStartPositions = []
    boxSelectRect.value = null
  }

  // ─── 双击进入文本编辑模式 ───
  const editingObjectId = ref<string | null>(null)
  function onDoubleClick(e: MouseEvent): void {
    const { x, y } = screenToCanvas(e.clientX, e.clientY)
    const hit = hitTest(x, y)
    if (!hit) return
    if (hit.type !== 'text') {
      // 非文字对象：保持默认行为（不进入编辑）
      return
    }
    // 确保对象已选中
    if (!fusion.selectedObjectIds.includes(hit.id)) {
      fusion.selectObject(hit.id)
    }
    editingObjectId.value = hit.id
  }

  /** 退出编辑模式 */
  function exitEditing(): void {
    editingObjectId.value = null
  }

  // ─── Resize 对象（旋转对象：增量先转到局部坐标系，再以中心点为锚调整） ───
  function resizeObject(
    obj: SceneObject,
    start: { x: number; y: number; width: number; height: number },
    handle: HandlePosition,
    dxWorld: number,
    dyWorld: number,
  ): void {
    const t = obj.transform
    let nx = start.x
    let ny = start.y
    let nw = start.width
    let nh = start.height

    if (t.rotation) {
      // 旋转对象：把世界增量转换到局部坐标系
      const rad = (-t.rotation * Math.PI) / 180
      const cos = Math.cos(rad)
      const sin = Math.sin(rad)
      const dx = dxWorld * cos - dyWorld * sin
      const dy = dxWorld * sin + dyWorld * cos
      // 中心点不变（保持中心位置），通过反向偏移实现
      const cx = start.x + start.width / 2
      const cy = start.y + start.height / 2
      if (handle.includes('w')) {
        nw = start.width - dx
      }
      if (handle.includes('e')) {
        nw = start.width + dx
      }
      if (handle.includes('n')) {
        nh = start.height - dy
      }
      if (handle.includes('s')) {
        nh = start.height + dy
      }
      const MIN = 4
      nw = Math.max(MIN, nw)
      nh = Math.max(MIN, nh)
      // 保持中心不变：重新计算 x/y（局部坐标），中心保持
      nx = cx - nw / 2
      ny = cy - nh / 2
    } else {
      // 未旋转：直接应用世界增量
      if (handle.includes('w')) {
        nx = start.x + dxWorld
        nw = start.width - dxWorld
      }
      if (handle.includes('e')) {
        nw = start.width + dxWorld
      }
      if (handle.includes('n')) {
        ny = start.y + dyWorld
        nh = start.height - dyWorld
      }
      if (handle.includes('s')) {
        nh = start.height + dyWorld
      }
      const MIN = 4
      if (nw < MIN) {
        if (handle.includes('w')) nx = start.x + start.width - MIN
        nw = MIN
      }
      if (nh < MIN) {
        if (handle.includes('n')) ny = start.y + start.height - MIN
        nh = MIN
      }
    }

    t.x = nx
    t.y = ny
    t.width = nw
    t.height = nh
  }

  // ─── 框选：更新选中（跨图层） ───
  function updateBoxSelection(additive: boolean): void {
    if (!boxSelectRect.value) return
    const rect = boxSelectRect.value
    const hits: string[] = []
    let firstHitLayerId: string | null = null
    // 从顶到底遍历所有图层，收集命中对象 ID
    for (let i = fusion.layers.length - 1; i >= 0; i--) {
      const layer = fusion.layers[i]
      if (!layer.visible || layer.locked) continue
      for (let j = layer.objects.length - 1; j >= 0; j--) {
        const obj = layer.objects[j]
        if (!obj.visible || obj.locked) continue
        if (rectIntersect(obj.transform, rect)) {
          hits.push(obj.id)
          // 记录第一个命中对象所在图层（顶到底顺序），作为活动图层
          if (firstHitLayerId === null) firstHitLayerId = layer.id
        }
      }
    }
    if (additive) {
      // 加选模式：合并原有 + 框选
      const set = new Set([...fusion.selectedObjectIds, ...hits])
      fusion.selectedObjectIds = Array.from(set)
      // 仅在当前无活动图层时切换
      if (firstHitLayerId && !fusion.selectedLayerId) {
        fusion.selectedLayerId = firstHitLayerId
      }
    } else {
      fusion.selectedObjectIds = hits
      // 自动将活动图层切换到第一个命中对象所在图层，
      // 否则 selectedObjects 计算属性会因为 layerId 不匹配而看不到选中对象
      if (firstHitLayerId) {
        fusion.selectedLayerId = firstHitLayerId
      }
    }
  }

  // ─── 矩形相交检测（旋转对象用 SAT，未旋转用 AABB） ───
  function rectIntersect(a: Transform, b: { x: number; y: number; width: number; height: number }): boolean {
    if (!a.rotation) {
      // AABB-AABB 快速路径
      return !(a.x + a.width < b.x || b.x + b.width < a.x || a.y + a.height < b.y || b.y + b.height < a.y)
    }
    return obbAabbIntersect(a, b)
  }

  /** OBB（旋转矩形）vs AABB（轴对齐矩形）相交检测 - SAT（分离轴定理） */
  function obbAabbIntersect(obb: Transform, aabb: { x: number; y: number; width: number; height: number }): boolean {
    const cx = obb.x + obb.width / 2
    const cy = obb.y + obb.height / 2
    const rad = (obb.rotation * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    const hw = obb.width / 2
    const hh = obb.height / 2
    // OBB 四个角（世界坐标）
    const obbCorners = [
      { x: cx + (-hw * cos - -hh * sin), y: cy + (-hw * sin + -hh * cos) },
      { x: cx + ( hw * cos - -hh * sin), y: cy + ( hw * sin + -hh * cos) },
      { x: cx + ( hw * cos -  hh * sin), y: cy + ( hw * sin +  hh * cos) },
      { x: cx + (-hw * cos -  hh * sin), y: cy + (-hw * sin +  hh * cos) },
    ]
    // AABB 四个角
    const acx = aabb.x + aabb.width / 2
    const acy = aabb.y + aabb.height / 2
    const ahw = aabb.width / 2
    const ahh = aabb.height / 2
    const aabbCorners = [
      { x: acx - ahw, y: acy - ahh },
      { x: acx + ahw, y: acy - ahh },
      { x: acx + ahw, y: acy + ahh },
      { x: acx - ahw, y: acy + ahh },
    ]
    // SAT 分离轴：OBB 两条边方向 + AABB 两条边方向（AABB 的轴即 X/Y）
    const axes = [
      { x: cos, y: sin },
      { x: -sin, y: cos },
      { x: 1, y: 0 },
      { x: 0, y: 1 },
    ]
    for (const axis of axes) {
      const [minA, maxA] = projectCorners(obbCorners, axis)
      const [minB, maxB] = projectCorners(aabbCorners, axis)
      if (maxA < minB || maxB < minA) return false
    }
    return true
  }

  /** 将一组角点投影到轴上，返回 [min, max] */
  function projectCorners(corners: Array<{ x: number; y: number }>, axis: { x: number; y: number }): [number, number] {
    let min = Infinity
    let max = -Infinity
    for (const c of corners) {
      const p = c.x * axis.x + c.y * axis.y
      if (p < min) min = p
      if (p > max) max = p
    }
    return [min, max]
  }

  // ─── 查找对象 ───
  function findObjectById(id: string): SceneObject | null {
    for (const layer of fusion.layers) {
      const obj = layer.objects.find(o => o.id === id)
      if (obj) return obj
    }
    return null
  }

  // ─── 是否显示框选矩形 ───
  const showBoxSelect = computed(() => isBoxSelecting.value && boxSelectRect.value !== null)

  // ─── 是否显示拖拽预览 ───
  const isHovering = computed(() => hoverObjectId.value !== null && !fusion.selectedObjectIds.includes(hoverObjectId.value))

  return {
    // 状态
    hoverObjectId,
    isDragging,
    isResizing,
    isBoxSelecting,
    boxSelectRect,
    showBoxSelect,
    isHovering,
    cursor,
    // 形状绘制
    shapeDrawing,
    // 文本编辑
    editingObjectId,
    // 方法
    onMouseDown,
    onMouseMove,
    onMouseUp,
    onDoubleClick,
    exitEditing,
    hitTest,
    screenToCanvas,
  }
}
