/**
 * useShapeDrawing - 形状/文字工具绘制引擎
 *
 * 当 ToolRail 激活形状或文字工具时，拦截画布的鼠标事件以创建新对象：
 *  - 形状工具（矩形/圆角矩形/椭圆/直线/多边形）：拖拽确定包围盒，松开后创建对象
 *  - 文字工具：点击直接创建默认尺寸的文本对象，进入重命名/编辑状态
 *
 * 工作流程：
 *  1. CanvasStage 在 mousedown 时调用 maybeStartDraw，若返回 true 则进入创建模式
 *  2. mousemove 期间调用 updateDrawPreview 更新预览矩形
 *  3. mouseup 时调用 commitDraw 完成对象创建并选中
 */
import { ref, computed, type Ref } from 'vue'
import type { SceneObject, ShapeKind } from '../types'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useToolStore } from '../stores/tool'
import { useToastStore } from '../stores/toast'
import { useColorStore } from '../stores/color'
import { useDocumentStore } from '../stores/document'

/** 当前绘制模式 */
export type DrawMode = 'none' | 'shape' | 'text'

/** 绘制预览矩形 */
export interface DrawPreview {
  x: number
  y: number
  width: number
  height: number
  shape: ShapeKind
}

export interface UseShapeDrawingOptions {
  /** 触发重渲染 */
  requestRender: () => void
  /** Canvas DOM 元素（用于吸管取色） */
  canvasRef: Ref<HTMLCanvasElement | null>
  /** Canvas 显示尺寸（用于计算取色位置） */
  displayWidth: Ref<number>
  displayHeight: Ref<number>
  /** 滚动容器（用于抓手平移） */
  scrollContainer?: Ref<HTMLElement | null>
}

export function useShapeDrawing(opts: UseShapeDrawingOptions) {
  const fusion = useFusionDocumentStore()
  const toolStore = useToolStore()
  const toastStore = useToastStore()
  const colorStore = useColorStore()
  const docStore = useDocumentStore()

  const drawMode = ref<DrawMode>('none')
  const drawPreview = ref<DrawPreview | null>(null)
  let startX = 0
  let startY = 0
  // 抓手平移起始滚动位置
  let panStartScrollLeft = 0
  let panStartScrollTop = 0

  /** 当前激活工具是否为形状工具 */
  const isShapeTool = computed(() => {
    const name = toolStore.activeToolName
    return ['矩形', '圆角矩形', '椭圆', '多边形', '直线', '自定形状'].includes(name)
  })

  /** 当前激活工具是否为文字工具 */
  const isTextTool = computed(() => {
    const name = toolStore.activeToolName
    return ['文字', '垂直文字', '横排文字蒙版', '直排文字蒙版', '路径文字'].includes(name)
  })

  /** 当前激活工具是否为吸管 */
  const isEyedropper = computed(() => toolStore.activeToolName === '吸管')

  /** 当前激活工具是否为抓手 */
  const isHandTool = computed(() => toolStore.activeToolName === '抓手')

  /** 当前激活工具是否为缩放 */
  const isZoomTool = computed(() => toolStore.activeToolName === '放大镜' || toolStore.activeToolName === '缩放')

  /** 是否处于绘制模式 */
  const isDrawing = computed(() => drawMode.value !== 'none')

  /** 工具名 → ShapeKind 映射 */
  function toolNameToShape(toolName: string): ShapeKind {
    switch (toolName) {
      case '矩形': return 'rectangle'
      case '圆角矩形': return 'rectangle' // cornerRadius 在创建时设置
      case '椭圆': return 'ellipse'
      case '多边形': return 'polygon'
      case '直线': return 'line'
      case '自定形状': return 'star'
      default: return 'rectangle'
    }
  }

  /** 根据工具名决定 cornerRadius */
  function toolNameToCornerRadius(toolName: string): number {
    return toolName === '圆角矩形' ? 8 : 0
  }

  /**
   * 尝试开始绘制
   * @returns true 表示已进入绘制模式，调用方应跳过默认的选择/拖拽逻辑
   */
  function maybeStartDraw(canvasX: number, canvasY: number, e?: MouseEvent): boolean {
    // 吸管工具：从 canvas 取色
    if (isEyedropper.value) {
      pickColorAt(canvasX, canvasY)
      return true
    }
    // 缩放工具：点击放大，Alt+点击缩小
    if (isZoomTool.value) {
      if (e?.altKey) docStore.zoomOut()
      else docStore.zoomIn()
      return true
    }
    // 抓手工具：进入平移模式（由 updateDrawPreview/mouseMove 处理）
    if (isHandTool.value) {
      drawMode.value = 'shape' // 复用 shape mode 触发 mousemove/mouseup
      startX = canvasX
      startY = canvasY
      panStartScrollLeft = opts.scrollContainer?.value?.scrollLeft ?? 0
      panStartScrollTop = opts.scrollContainer?.value?.scrollTop ?? 0
      return true
    }
    if (isShapeTool.value) {
      drawMode.value = 'shape'
      startX = canvasX
      startY = canvasY
      drawPreview.value = {
        x: canvasX,
        y: canvasY,
        width: 0,
        height: 0,
        shape: toolNameToShape(toolStore.activeToolName),
      }
      return true
    }
    if (isTextTool.value) {
      // 文字工具：点击即创建，无需拖拽
      commitTextAt(canvasX, canvasY)
      return true
    }
    return false
  }

  /** 更新绘制预览（仅形状工具） */
  function updateDrawPreview(canvasX: number, canvasY: number): void {
    if (drawMode.value !== 'shape') return
    // 抓手工具：平移滚动
    if (isHandTool.value && opts.scrollContainer?.value) {
      const dx = canvasX - startX
      const dy = canvasY - startY
      opts.scrollContainer.value.scrollLeft = panStartScrollLeft - dx
      opts.scrollContainer.value.scrollTop = panStartScrollTop - dy
      return
    }
    if (!drawPreview.value) return
    drawPreview.value = {
      x: Math.min(startX, canvasX),
      y: Math.min(startY, canvasY),
      width: Math.abs(canvasX - startX),
      height: Math.abs(canvasY - startY),
      shape: drawPreview.value.shape,
    }
  }

  /** 完成绘制：创建实际对象 */
  function commitDraw(): void {
    if (drawMode.value === 'shape' && drawPreview.value) {
      const p = drawPreview.value
      // 最小尺寸阈值，避免误触创建过小对象
      if (p.width >= 4 && p.height >= 4) {
        createShapeObjectAt(p.x, p.y, p.width, p.height, p.shape)
      }
    }
    drawMode.value = 'none'
    drawPreview.value = null
  }

  /** 取消绘制（如按 Esc 或鼠标离开画布） */
  function cancelDraw(): void {
    drawMode.value = 'none'
    drawPreview.value = null
  }

  /** 从 canvas 像素中取色 */
  function pickColorAt(canvasX: number, canvasY: number): void {
    const canvas = opts.canvasRef.value
    if (!canvas) {
      toastStore.show('画布未就绪', 'fa-circle-info', 'warning')
      return
    }
    try {
      const ctx = canvas.getContext('2d', { willReadFrequently: true })
      if (!ctx) return
      // 将画布逻辑坐标转换为 canvas 像素坐标（考虑 DPR）
      const dpr = window.devicePixelRatio || 1
      const px = Math.floor(canvasX * dpr)
      const py = Math.floor(canvasY * dpr)
      const pixel = ctx.getImageData(px, py, 1, 1).data
      if (pixel[3] === 0) {
        // 透明像素：返回白色
        colorStore.setColor('#FFFFFF')
      } else {
        const hex = '#' + [pixel[0], pixel[1], pixel[2]]
          .map(c => c.toString(16).padStart(2, '0'))
          .join('')
          .toUpperCase()
        colorStore.setColor(hex)
      }
      toastStore.show(`已取色 ${colorStore.currentHex}`, 'fa-eye-dropper', 'success')
    } catch (err) {
      // 跨域读取会抛错，降级为根据对象填充色取色
      const hit = findObjectAt(canvasX, canvasY)
      if (hit) {
        const color = (hit as any).fill ?? (hit as any).color ?? '#FFFFFF'
        colorStore.setColor(color.toUpperCase())
        toastStore.show(`已取色 ${color}`, 'fa-eye-dropper', 'success')
      } else {
        toastStore.show('取色失败（跨域限制）', 'fa-triangle-exclamation', 'warning')
      }
    }
  }

  /** 查找指定坐标下的对象（用于吸管降级） */
  function findObjectAt(x: number, y: number): SceneObject | null {
    for (let i = fusion.layers.length - 1; i >= 0; i--) {
      const layer = fusion.layers[i]
      if (!layer.visible || layer.locked) continue
      for (let j = layer.objects.length - 1; j >= 0; j--) {
        const obj = layer.objects[j]
        if (!obj.visible || obj.locked) continue
        const t = obj.transform
        if (x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height) {
          return obj
        }
      }
    }
    return null
  }

  /** 在指定位置创建形状对象 */
  function createShapeObjectAt(x: number, y: number, w: number, h: number, shape: ShapeKind): void {
    // 确保有目标图层：优先使用当前选中图层，否则新建一个
    let layerId = fusion.selectedLayerId
    if (!layerId) {
      const layer = fusion.newLayer()
      layerId = layer.id
    }
    const toolName = toolStore.activeToolName
    // 使用 colorStore 当前颜色作为填充色，描边使用默认色
    const currentColor = colorStore.currentHex || '#3AC487'
    // 使用类型断言绕过 CreateNodeParams 严格限制（运行时工厂方法支持这些字段）
    const params = {
      name: toolName,
      x,
      y,
      width: w,
      height: h,
      shape,
      fill: currentColor,
      stroke: '#1F2329',
      strokeWidth: 0,
      cornerRadius: toolNameToCornerRadius(toolName),
    } as unknown as Parameters<typeof fusion.newObject>[2]
    const obj = fusion.newObject(layerId, 'shape', params)
    if (obj) {
      fusion.selectObject(obj.id)
      toastStore.show(`已创建${toolName}`, 'fa-square', 'success')
      opts.requestRender()
    }
  }

  /** 在指定位置创建文本对象 */
  function commitTextAt(x: number, y: number): void {
    let layerId = fusion.selectedLayerId
    if (!layerId) {
      const layer = fusion.newLayer()
      layerId = layer.id
    }
    const params = {
      name: '文字',
      text: '双击编辑文字',
      x,
      y,
      width: 200,
      height: 40,
      fontSize: 28,
      fontWeight: 600,
      color: '#1F2329',
    } as unknown as Parameters<typeof fusion.newObject>[2]
    const obj = fusion.newObject(layerId, 'text', params)
    if (obj) {
      fusion.selectObject(obj.id)
      toastStore.show('已创建文本对象，双击可编辑', 'fa-font', 'success')
      opts.requestRender()
    }
    drawMode.value = 'none'
  }

  return {
    // 状态
    drawMode,
    drawPreview,
    isDrawing,
    isShapeTool,
    isTextTool,
    isEyedropper,
    isHandTool,
    isZoomTool,
    // 方法
    maybeStartDraw,
    updateDrawPreview,
    commitDraw,
    cancelDraw,
    pickColorAt,
  }
}
