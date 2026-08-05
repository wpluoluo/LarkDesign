<template>
  <div
    class="absolute select-none"
    :style="frameStyle"
    @mousedown.stop="onFrameMouseDown"
    @dblclick.stop="onFrameDoubleClick"
  >
    <!-- Frame 标题栏 -->
    <div
      class="absolute -top-[28px] left-0 flex flex-row items-center gap-[6px] h-[24px] px-[8px] rounded-[4px] cursor-pointer transition-colors"
      :class="selected ? 'bg-[var(--color-primary)] text-[var(--color-white)]' : 'bg-[var(--color-panel)] border border-[var(--color-border)] text-[var(--color-secondary)] hover:bg-[var(--color-hover-bg)]'"
      @click.stop="onTitleClick"
    >
      <i :class="['fa-solid', typeIcon, 'text-[10px]']"></i>
      <span class="text-[11px] font-[600] leading-[14px]">{{ frame.name }}</span>
      <span v-if="frame.type === 'book-page' && frame.order" class="text-[10px] font-[500] opacity-70">{{ frame.order }}</span>
      <span v-if="frame.showPageNumber && frame.order" class="text-[9px] font-[500] opacity-60">P{{ frame.order }}</span>
    </div>

    <!-- Frame 画布区域 -->
    <div
      ref="frameCanvasAreaRef"
      class="relative overflow-hidden bg-white shadow-[0_2px_12px_rgba(0,0,0,0.08)]"
      :class="selected ? 'ring-2 ring-[var(--color-primary)]' : 'ring-1 ring-[var(--color-border)] hover:ring-[var(--color-primary-light-300)]'"
      :style="{ width: frame.width + 'px', height: frame.height + 'px', background: frame.background ?? '#FFFFFF', cursor: editingCursor }"
      @mousedown="onCanvasAreaMouseDown"
    >
      <!-- Frame 内的 Canvas 渲染层 -->
      <canvas
        ref="canvasRef"
        class="block"
        :style="{ width: frame.width + 'px', height: frame.height + 'px' }"
      />

      <!-- Frame 内选中对象的边框 + handle（仅进入编辑模式时显示） -->
      <template v-if="editingMode">
        <template v-for="obj in selectedObjectsWithTransform" :key="obj.id">
          <!-- 选中边框 -->
          <div
            class="absolute pointer-events-none border border-[var(--color-primary)]"
            :style="obj.borderStyle"
          ></div>
          <!-- 8 个 resize handle（仅单选时显示） -->
          <template v-if="selectedObjectsWithTransform.length === 1">
            <div
              v-for="h in obj.handles"
              :key="h.pos"
              class="absolute w-[8px] h-[8px] bg-white border border-[var(--color-primary)] rounded-[1px] pointer-events-auto z-10"
              :style="{ ...h.style, cursor: h.cursor }"
              @mousedown.stop="onObjectResizeStart($event, h.pos)"
            ></div>
          </template>
        </template>
      </template>
    </div>

    <!-- Frame 尺寸标签（hover 时显示） -->
    <div
      class="absolute -bottom-[20px] left-0 text-[10px] font-[500] text-[var(--color-muted)] opacity-0 hover:opacity-100 transition-opacity pointer-events-none"
    >
      {{ Math.round(frame.width) }} × {{ Math.round(frame.height) }}
    </div>

    <!-- 对页关联指示器 -->
    <div
      v-if="frame.spreadWith"
      class="absolute top-1/2 -translate-y-1/2 w-[8px] h-[40px] flex flex-col items-center justify-center"
      :class="frame.spreadSide === 'left' ? '-right-[8px]' : '-left-[8px]'"
    >
      <i class="fa-solid fa-book-open text-[8px] text-[var(--color-warning)]"></i>
    </div>

    <!-- 页码（书籍模式，底部居中） -->
    <div
      v-if="frame.showPageNumber && frame.order"
      class="absolute -bottom-[18px] left-1/2 -translate-x-1/2 text-[10px] font-[500] text-[var(--color-muted)]"
    >
      {{ frame.pageNumberFormat?.replace('{n}', String(frame.order)) ?? frame.order }}
    </div>

    <!-- Frame 调整尺寸 handle（8 个，仅选中时显示） -->
    <template v-if="selected && !editingMode">
      <div
        v-for="h in resizeHandles"
        :key="h.pos"
        class="absolute w-[8px] h-[8px] bg-white border border-[var(--color-primary)] rounded-[1px] pointer-events-auto z-10"
        :style="{ ...h.style, cursor: h.cursor }"
        @mousedown.stop="onResizeStart($event, h.pos)"
      ></div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick, type PropType } from 'vue'
import type { Frame, SceneObject, Layer } from '../types'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useCanvasRenderer } from '../composables/useCanvasRenderer'
import type { HandlePosition } from './useFrameHandles'

const props = defineProps({
  frame: { type: Object as PropType<Frame>, required: true },
  zoom: { type: Number, default: 1 },
  selected: { type: Boolean, default: false },
  editingMode: { type: Boolean, default: false },
})

const emit = defineEmits<{
  (e: 'select', frameId: string, additive: boolean): void
  (e: 'enter-edit', frameId: string): void
  (e: 'exit-edit'): void
  (e: 'move', frameId: string, x: number, y: number): void
  (e: 'resize', frameId: string, width: number, height: number): void
}>()

const fusion = useFusionDocumentStore()

const canvasRef = ref<HTMLCanvasElement | null>(null)
const frameCanvasAreaRef = ref<HTMLDivElement | null>(null)
const showSelection = ref(true)

// ─── Frame 自身的宽度/高度/背景（响应式） ───
const frameWidth = computed(() => props.frame.width)
const frameHeight = computed(() => props.frame.height)
const frameBackground = computed(() => props.frame.background ?? '#FFFFFF')

// ─── Frame 图层源：传递给 useCanvasRenderer，绕过 getCurrentLayers 路由 ───
// 在编辑模式下显示选中态，其他模式仅渲染内容
const layersSource = computed<{ layers: Layer[]; selectedIds?: string[] } | null>(() => {
  return {
    layers: props.frame.children,
    selectedIds: props.editingMode ? fusion.selectedObjectIds : [],
  }
})

// ─── 渲染器：始终初始化（每个 Frame 都渲染自己的内容） ───
const { isRendering, initRenderer, requestRender, reinit } = useCanvasRenderer({
  canvasRef,
  showSelection,
  width: frameWidth,
  height: frameHeight,
  background: frameBackground,
  layersSource,
})

// Frame 尺寸变化时重新初始化（已由 useCanvasRenderer 内部监听，这里作兜底）
watch(
  () => [props.frame.width, props.frame.height, props.frame.background],
  () => {
    if (props.editingMode) nextTick(() => reinit())
  },
)

// Frame 内图层变化时重渲染（已由 useCanvasRenderer 的 deep watch 处理，这里保留兜底）
watch(
  () => props.frame.children,
  () => {
    requestRender()
  },
  { deep: true },
)

// 挂载时初始化
onMounted(() => {
  nextTick(() => initRenderer())
})

// ─── Frame 类型图标 ───
const typeIcon = computed(() => {
  switch (props.frame.type) {
    case 'single': return 'fa-file'
    case 'poster': return 'fa-image'
    case 'book-page': return 'fa-book'
    case 'spread': return 'fa-book-open'
    default: return 'fa-file'
  }
})

// ─── Frame 容器样式 ───
const frameStyle = computed(() => ({
  left: props.frame.x + 'px',
  top: props.frame.y + 'px',
  width: props.frame.width + 'px',
  height: props.frame.height + 'px',
  cursor: props.editingMode ? 'default' : 'move',
}))

// ─── 编辑模式光标 ───
const editingCursor = computed(() => {
  if (!props.editingMode) return 'default'
  if (isObjDragging.value) return 'move'
  return 'default'
})

// ═══════════════════════════════════════════════════════════════
// Frame 内对象交互（编辑模式）
// ═══════════════════════════════════════════════════════════════

// ─── 屏幕 → Frame 内部坐标转换 ───
function screenToFrame(clientX: number, clientY: number): { x: number; y: number } {
  const rect = frameCanvasAreaRef.value?.getBoundingClientRect()
  if (!rect) return { x: 0, y: 0 }
  // canvas 元素的显示尺寸已经包含了 zoom 缩放，所以用比例映射即可
  const x = (clientX - rect.left) / rect.width * props.frame.width
  const y = (clientY - rect.top) / rect.height * props.frame.height
  return { x, y }
}

// ─── 命中检测：从顶到底遍历当前 Frame 的图层 ───
function hitTestFrame(x: number, y: number): SceneObject | null {
  for (let i = props.frame.children.length - 1; i >= 0; i--) {
    const layer = props.frame.children[i]
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

// ─── 点是否在对象内（AABB，忽略旋转，简化版） ───
function isPointInObject(x: number, y: number, obj: SceneObject): boolean {
  const t = obj.transform
  // 简化：不考虑旋转，仅用 AABB
  return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

// ─── 选中对象的边框 + handle（编辑模式时） ───
const selectedObjectsWithTransform = computed(() => {
  if (!props.editingMode) return []
  return fusion.selectedObjects.map((obj: SceneObject) => {
    const t = obj.transform
    const cx = t.x + t.width / 2
    const cy = t.y + t.height / 2
    const rad = (t.rotation * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    const handleCursor: Record<HandlePosition, string> = {
      nw: 'nwse-resize', se: 'nwse-resize',
      ne: 'nesw-resize', sw: 'nesw-resize',
      n: 'ns-resize', s: 'ns-resize',
      e: 'ew-resize', w: 'ew-resize',
    }
    const localHandles: Array<{ pos: HandlePosition; lx: number; ly: number }> = [
      { pos: 'nw', lx: -t.width / 2, ly: -t.height / 2 },
      { pos: 'n',  lx: 0,            ly: -t.height / 2 },
      { pos: 'ne', lx:  t.width / 2, ly: -t.height / 2 },
      { pos: 'e',  lx:  t.width / 2, ly: 0 },
      { pos: 'se', lx:  t.width / 2, ly:  t.height / 2 },
      { pos: 's',  lx: 0,            ly:  t.height / 2 },
      { pos: 'sw', lx: -t.width / 2, ly:  t.height / 2 },
      { pos: 'w',  lx: -t.width / 2, ly: 0 },
    ]
    const HAND = 8
    const HALF = HAND / 2
    const handles = localHandles.map(h => {
      const wx = cx + (h.lx * cos - h.ly * sin)
      const wy = cy + (h.lx * sin + h.ly * cos)
      return {
        pos: h.pos,
        cursor: handleCursor[h.pos],
        style: {
          left: `${wx - HALF}px`,
          top: `${wy - HALF}px`,
        },
      }
    })
    return {
      id: obj.id,
      borderStyle: {
        left: `${t.x}px`,
        top: `${t.y}px`,
        width: `${t.width}px`,
        height: `${t.height}px`,
        transform: `rotate(${t.rotation}deg)`,
        transformOrigin: 'center center',
      },
      handles,
    }
  })
})

// ─── 对象拖拽状态 ───
const isObjDragging = ref(false)
let objDragStartX = 0
let objDragStartY = 0
let objDragStartPositions: Array<{ id: string; x: number; y: number }> = []
let objHistoryRecorded = false

// ─── Frame 画布区域 mousedown：对象选择与拖拽 ───
function onCanvasAreaMouseDown(e: MouseEvent): void {
  if (!props.editingMode) return
  if (e.button !== 0) return

  const { x, y } = screenToFrame(e.clientX, e.clientY)
  const hit = hitTestFrame(x, y)

  if (hit) {
    // 命中对象：选中
    if (e.shiftKey) {
      fusion.selectObject(hit.id, true)
    } else if (!fusion.selectedObjectIds.includes(hit.id)) {
      fusion.selectObject(hit.id, false)
    }
    // 准备拖拽
    objDragStartX = x
    objDragStartY = y
    objDragStartPositions = fusion.selectedObjects.map(o => ({
      id: o.id,
      x: o.transform.x,
      y: o.transform.y,
    }))
    isObjDragging.value = false
    objHistoryRecorded = false
    window.addEventListener('mousemove', onObjDragMove)
    window.addEventListener('mouseup', onObjDragEnd)
    e.stopPropagation()
  } else {
    // 点击 Frame 内空白处：仅取消对象选择，不退出编辑模式（阻止冒泡到 CanvasStage）
    if (!e.shiftKey) {
      fusion.deselectAll()
    }
    e.stopPropagation()
  }
}

function onObjDragMove(e: MouseEvent): void {
  const { x, y } = screenToFrame(e.clientX, e.clientY)
  const dx = x - objDragStartX
  const dy = y - objDragStartY
  // 超过阈值才真正开始拖拽
  if (!isObjDragging.value && (Math.abs(dx) > 1 || Math.abs(dy) > 1)) {
    isObjDragging.value = true
  }
  if (!isObjDragging.value) return
  // 第一次移动时记录历史
  if (!objHistoryRecorded) {
    fusion.pushHistory('移动对象')
    objHistoryRecorded = true
  }
  // 更新所有选中对象的位置（跳过历史记录，避免多次入栈）
  for (const start of objDragStartPositions) {
    fusion.updateObject(start.id, {
      transform: { x: start.x + dx, y: start.y + dy },
    }, '移动对象', true)
  }
}

function onObjDragEnd(): void {
  isObjDragging.value = false
  objHistoryRecorded = false
  window.removeEventListener('mousemove', onObjDragMove)
  window.removeEventListener('mouseup', onObjDragEnd)
}

// ─── 对象 resize handle ───
let objResizeStartX = 0
let objResizeStartY = 0
let objResizeStartTransform: { x: number; y: number; width: number; height: number } | null = null
let objResizePos: HandlePosition | null = null
let objResizeHistoryRecorded = false

function onObjectResizeStart(e: MouseEvent, pos: HandlePosition): void {
  e.stopPropagation()
  if (fusion.selectedObjects.length !== 1) return
  const obj = fusion.selectedObjects[0]
  objResizeStartX = e.clientX
  objResizeStartY = e.clientY
  objResizeStartTransform = { ...obj.transform }
  objResizePos = pos
  objResizeHistoryRecorded = false
  window.addEventListener('mousemove', onObjectResizeMove)
  window.addEventListener('mouseup', onObjectResizeEnd)
}

function onObjectResizeMove(e: MouseEvent): void {
  if (!objResizeStartTransform || !objResizePos) return
  const obj = fusion.selectedObjects[0]
  if (!obj) return
  // 使用屏幕坐标差值，再除以 zoom（Frame 的缩放）转 Frame 内部坐标
  const dx = (e.clientX - objResizeStartX) / props.zoom
  const dy = (e.clientY - objResizeStartY) / props.zoom
  if (!objResizeHistoryRecorded && (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5)) {
    fusion.pushHistory('调整对象尺寸')
    objResizeHistoryRecorded = true
  }
  const start = objResizeStartTransform
  let newX = start.x
  let newY = start.y
  let newW = start.width
  let newH = start.height
  if (objResizePos.includes('e')) newW = start.width + dx
  if (objResizePos.includes('w')) { newW = start.width - dx; newX = start.x + dx }
  if (objResizePos.includes('s')) newH = start.height + dy
  if (objResizePos.includes('n')) { newH = start.height - dy; newY = start.y + dy }
  // 最小尺寸限制
  newW = Math.max(4, newW)
  newH = Math.max(4, newH)
  // 跳过历史记录，避免多次入栈（已在上面记录一次）
  fusion.updateObject(obj.id, {
    transform: { x: newX, y: newY, width: newW, height: newH },
  }, '调整对象尺寸', true)
}

function onObjectResizeEnd(): void {
  objResizeStartTransform = null
  objResizePos = null
  objResizeHistoryRecorded = false
  window.removeEventListener('mousemove', onObjectResizeMove)
  window.removeEventListener('mouseup', onObjectResizeEnd)
}

// ─── 8 个 resize handle（Frame 自身） ───
const resizeHandles = computed(() => {
  const f = props.frame
  const positions: Array<{ pos: HandlePosition; lx: number; ly: number; cursor: string }> = [
    { pos: 'nw', lx: 0, ly: 0, cursor: 'nwse-resize' },
    { pos: 'n', lx: f.width / 2, ly: 0, cursor: 'ns-resize' },
    { pos: 'ne', lx: f.width, ly: 0, cursor: 'nesw-resize' },
    { pos: 'e', lx: f.width, ly: f.height / 2, cursor: 'ew-resize' },
    { pos: 'se', lx: f.width, ly: f.height, cursor: 'nwse-resize' },
    { pos: 's', lx: f.width / 2, ly: f.height, cursor: 'ns-resize' },
    { pos: 'sw', lx: 0, ly: f.height, cursor: 'nesw-resize' },
    { pos: 'w', lx: 0, ly: f.height / 2, cursor: 'ew-resize' },
  ]
  const HANDLE = 8
  const HALF = HANDLE / 2
  return positions.map(p => ({
    pos: p.pos,
    cursor: p.cursor,
    style: {
      left: `${p.lx - HALF}px`,
      top: `${p.ly - HALF}px`,
    },
  }))
})

// ─── Frame 拖拽状态（非响应式） ───
let dragStartX = 0
let dragStartY = 0
let dragStartFrameX = 0
let dragStartFrameY = 0
let isDragging = false
let historyRecorded = false

// ─── Frame 选中（点击 Frame 本体） ───
function onFrameMouseDown(e: MouseEvent): void {
  if (props.editingMode) return // 编辑模式下不触发 Frame 选择
  emit('select', props.frame.id, e.shiftKey)
  // 启动拖拽
  dragStartX = e.clientX
  dragStartY = e.clientY
  dragStartFrameX = props.frame.x
  dragStartFrameY = props.frame.y
  isDragging = true
  historyRecorded = false
  window.addEventListener('mousemove', onDragMove)
  window.addEventListener('mouseup', onDragEnd)
}

function onDragMove(e: MouseEvent): void {
  if (!isDragging) return
  const dx = (e.clientX - dragStartX) / props.zoom
  const dy = (e.clientY - dragStartY) / props.zoom
  // 真正开始拖拽时才记录历史（避免点击不拖拽时产生冗余记录）
  if (!historyRecorded && (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5)) {
    fusion.pushHistory('移动画板')
    historyRecorded = true
  }
  emit('move', props.frame.id, dragStartFrameX + dx, dragStartFrameY + dy)
}

function onDragEnd(): void {
  isDragging = false
  window.removeEventListener('mousemove', onDragMove)
  window.removeEventListener('mouseup', onDragEnd)
}

// ─── 双击进入编辑模式 ───
function onFrameDoubleClick(e: MouseEvent): void {
  if (!props.editingMode) {
    emit('enter-edit', props.frame.id)
  }
}

// ─── 标题栏点击（仅选中，不拖拽） ───
function onTitleClick(e: MouseEvent): void {
  emit('select', props.frame.id, e.shiftKey)
}

// ─── Frame 调整尺寸 ───
let resizeStartX = 0
let resizeStartY = 0
let resizeStartW = 0
let resizeStartH = 0
let resizing = false
let resizePos: HandlePosition | null = null
let resizeHistoryRecorded = false

function onResizeStart(e: MouseEvent, pos: HandlePosition): void {
  e.stopPropagation()
  resizeStartX = e.clientX
  resizeStartY = e.clientY
  resizeStartW = props.frame.width
  resizeStartH = props.frame.height
  resizing = true
  resizePos = pos
  resizeHistoryRecorded = false
  window.addEventListener('mousemove', onResizeMove)
  window.addEventListener('mouseup', onResizeEnd)
}

function onResizeMove(e: MouseEvent): void {
  if (!resizing || !resizePos) return
  const dx = (e.clientX - resizeStartX) / props.zoom
  const dy = (e.clientY - resizeStartY) / props.zoom
  // 真正开始调整时才记录历史
  if (!resizeHistoryRecorded && (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5)) {
    fusion.pushHistory('调整画板尺寸')
    resizeHistoryRecorded = true
  }
  let newW = resizeStartW
  let newH = resizeStartH
  // 根据 handle 位置调整宽高
  if (resizePos.includes('e')) newW = resizeStartW + dx
  if (resizePos.includes('w')) newW = resizeStartW - dx
  if (resizePos.includes('s')) newH = resizeStartH + dy
  if (resizePos.includes('n')) newH = resizeStartH - dy
  // 最小尺寸限制
  newW = Math.max(50, newW)
  newH = Math.max(50, newH)
  emit('resize', props.frame.id, newW, newH)
}

function onResizeEnd(): void {
  resizing = false
  resizePos = null
  window.removeEventListener('mousemove', onResizeMove)
  window.removeEventListener('mouseup', onResizeEnd)
}

onBeforeUnmount(() => {
  onDragEnd()
  onResizeEnd()
  onObjDragEnd()
  onObjectResizeEnd()
})
</script>
