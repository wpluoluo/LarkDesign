<template>
  <!-- ╔══════════════════════════════════════════════════════════════╗
       ║  Mode A: 无限画布模式（多 Frame）— 当 fusion.isFramesMode 为真时启用  ║
       ╚══════════════════════════════════════════════════════════════╝ -->
  <div
    v-if="fusion.isFramesMode"
    ref="infiniteViewportRef"
    class="relative overflow-hidden select-none w-full h-full"
    :class="canvasAreaClass"
    :style="{ cursor: infiniteCanvas.cursor.value }"
    @contextmenu.prevent="onContextMenu($event)"
    @mousedown="infiniteCanvas.onMouseDown($event)"
    @mousemove="infiniteCanvas.onMouseMove($event)"
    @mouseup="infiniteCanvas.onMouseUp($event)"
    @mouseleave="infiniteCanvas.onMouseUp($event)"
    @dblclick="infiniteCanvas.onDblClick($event)"
    @wheel="onInfiniteWheel($event)"
  >
    <!-- 背景网格层 -->
    <div class="absolute inset-0 pointer-events-none" :class="gridBackgroundClass"></div>

    <!-- 变换容器：承载所有 Frame -->
    <div
      class="absolute top-0 left-0 will-change-transform"
      :style="{ transform: infiniteCanvas.canvasTransform.value, transformOrigin: '0 0' }"
    >
      <FrameView
        v-for="frame in visibleFrames"
        :key="frame.id"
        :frame="frame"
        :zoom="infiniteCanvas.zoom.value"
        :selected="frame.id === fusion.selectedFrameId"
        :editing-mode="frame.id === infiniteCanvas.editingFrameId.value"
        @select="onFrameSelect"
        @enter-edit="onFrameEnterEdit"
        @exit-edit="infiniteCanvas.exitFrameEdit"
        @move="infiniteCanvas.moveFrame"
        @resize="infiniteCanvas.resizeFrame"
      />
    </div>

    <!-- 左下角：缩放控件 -->
    <div class="absolute bottom-[12px] left-[12px] flex flex-row items-center gap-[4px] px-[8px] h-[26px] rounded-[6px] bg-[var(--color-panel)] border border-[var(--color-border-light)] shadow-[0_2px_8px_rgba(15,23,42,0.06)] z-20">
      <button type="button" class="flex flex-row justify-center items-center w-[20px] h-[20px] rounded-[4px] hover:bg-[var(--color-hover-bg)] text-[var(--color-secondary)] transition-colors" title="缩小" @click="zoomOut">
        <i class="fa-solid fa-minus text-[9px]"></i>
      </button>
      <span class="text-[10px] font-[600] text-[var(--color-body)] w-[36px] text-center tabular-nums">{{ Math.round(infiniteCanvas.zoom.value * 100) }}%</span>
      <button type="button" class="flex flex-row justify-center items-center w-[20px] h-[20px] rounded-[4px] hover:bg-[var(--color-hover-bg)] text-[var(--color-secondary)] transition-colors" title="放大" @click="zoomIn">
        <i class="fa-solid fa-plus text-[9px]"></i>
      </button>
      <div class="w-[1px] h-[12px] bg-[var(--color-border-light)] mx-[2px]"></div>
      <button type="button" class="flex flex-row justify-center items-center w-[20px] h-[20px] rounded-[4px] hover:bg-[var(--color-hover-bg)] text-[var(--color-secondary)] transition-colors" title="适配视图" @click="infiniteCanvas.fitToFrames()">
        <i class="fa-solid fa-expand text-[9px]"></i>
      </button>
    </div>

    <!-- 右下角：当前 Frame 信息 -->
    <div
      v-if="fusion.currentFrame"
      class="absolute bottom-[12px] right-[12px] flex flex-row items-center gap-[6px] px-[10px] h-[26px] rounded-[6px] bg-[var(--color-panel)] border border-[var(--color-border-light)] shadow-[0_2px_8px_rgba(15,23,42,0.06)] z-20"
    >
      <i :class="['fa-solid', frameTypeIcon, 'text-[10px] text-[var(--color-primary)]']"></i>
      <span class="text-[10px] font-[600] text-[var(--color-body)]">{{ fusion.currentFrame.name }}</span>
      <span class="text-[9px] text-[var(--color-muted)] tabular-nums">{{ Math.round(fusion.currentFrame.width) }} × {{ Math.round(fusion.currentFrame.height) }}</span>
    </div>

    <!-- 鸟瞰图（无限画布模式） -->
    <Minimap :viewport-width="viewportWidth" :viewport-height="viewportHeight" />

    <!-- 加载态 -->
    <div
      v-if="isRendering"
      class="absolute top-[8px] right-[8px] flex flex-row items-center gap-[6px] px-[8px] h-[20px] rounded-[4px] bg-[var(--color-panel)] border border-[var(--color-border-light)] text-[9px] font-[500] text-[var(--color-muted)] pointer-events-none"
    >
      <i class="fa-solid fa-circle-notch fa-spin text-[9px]"></i>
      <span>渲染中</span>
    </div>
  </div>

  <!-- ╔══════════════════════════════════════════════════════════════╗
       ║  Mode B: 单画布模式（旧版兼容）— 当没有 Frame 时启用                 ║
       ╚══════════════════════════════════════════════════════════════╝ -->
  <div
    v-else
    ref="stageRef"
    class="relative overflow-hidden select-none"
    :style="{ cursor: interaction.cursor.value }"
    @contextmenu.prevent="onContextMenu($event)"
    @mousedown="interaction.onMouseDown($event)"
    @mousemove="interaction.onMouseMove($event)"
    @mouseup="interaction.onMouseUp($event)"
    @mouseleave="interaction.onMouseUp($event)"
    @dblclick="interaction.onDoubleClick($event)"
    @dragover.prevent="onDragOver"
    @drop.prevent="onDrop"
  >
    <!-- 真实 Canvas 渲染层 -->
    <canvas
      ref="canvasRef"
      class="block"
      :style="{
        width: displayWidth + 'px',
        height: displayHeight + 'px',
      }"
    />

    <!-- 悬停高亮 overlay（虚线框） -->
    <div
      v-if="interaction.isHovering.value && interaction.hoverObjectId.value"
      class="absolute pointer-events-none border border-[var(--color-info)] border-dashed"
      :style="hoverStyle"
    ></div>

    <!-- 选中对象的 handles overlay -->
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
          class="absolute pointer-events-auto bg-[var(--color-white)] border border-[var(--color-info)] rounded-[1px] z-10"
          :style="{
            ...h.style,
            cursor: h.cursor,
          }"
        ></div>
      </template>
    </template>

    <!-- 框选矩形 overlay -->
    <div
      v-if="interaction.showBoxSelect.value && interaction.boxSelectRect.value"
      class="absolute pointer-events-none border border-[var(--color-info)] bg-[var(--color-info)]/10"
      :style="boxSelectStyle"
    ></div>

    <!-- 形状绘制预览 overlay -->
    <div
      v-if="interaction.shapeDrawing.drawPreview.value"
      class="absolute pointer-events-none border border-[var(--color-primary)] bg-[var(--color-primary)]/15"
      :style="drawPreviewStyle"
    >
      <span class="absolute -top-[16px] left-0 text-[9px] font-[600] text-[var(--color-primary)] whitespace-nowrap">
        {{ Math.round(interaction.shapeDrawing.drawPreview.value.width) }} × {{ Math.round(interaction.shapeDrawing.drawPreview.value.height) }}
      </span>
    </div>

    <!-- 文本编辑 overlay（双击文字对象进入编辑模式） -->
    <textarea
      v-if="editingObject"
      ref="textEditorRef"
      v-model="editingText"
      class="absolute pointer-events-auto outline-none border-2 border-[var(--color-info)] bg-[var(--color-white)]/95 px-[4px] py-[2px] text-[var(--color-body)] resize-none overflow-hidden whitespace-pre-wrap z-20"
      :style="textEditorStyle"
      @blur="commitTextEdit"
      @keydown.enter.exact.prevent="commitTextEdit"
      @keydown.escape.prevent="cancelTextEdit"
    ></textarea>

    <!-- 标尺与边框层（可选） -->
    <div
      v-if="showFrame"
      class="absolute pointer-events-none inset-0"
    >
      <div class="absolute -top-[18px] left-0 text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">
        第 {{ pageIndex + 1 }} 页 · {{ pageName }}
      </div>
    </div>

    <!-- 加载态 -->
    <div
      v-if="isRendering"
      class="absolute top-[8px] right-[8px] flex flex-row items-center gap-[6px] px-[8px] h-[20px] rounded-[4px] bg-[var(--color-panel)] border border-[var(--color-border-light)] text-[9px] font-[500] text-[var(--color-muted)] pointer-events-none"
    >
      <i class="fa-solid fa-circle-notch fa-spin text-[9px]"></i>
      <span>渲染中</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'
import { useCanvasRenderer } from '../composables/useCanvasRenderer'
import { useCanvasInteraction, type HandlePosition } from '../composables/useCanvasInteraction'
import { useInfiniteCanvas } from '../composables/useInfiniteCanvas'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useToastStore } from '../stores/toast'
import { useDocumentStore } from '../stores/document'
import type { SceneObject, Frame } from '../types'
import FrameView from './FrameView.vue'
import Minimap from './Minimap.vue'

const props = defineProps<{
  zoomPercent?: number
  showFrame?: boolean
  pageIndex?: number
  pageName?: string
  scrollContainer?: HTMLElement | null
}>()

const emit = defineEmits<{
  (e: 'contextmenu', payload: { x: number; y: number; target: 'canvas' | 'object' | 'page' }): void
  (e: 'object-click', objId: string | null): void
}>()

const fusion = useFusionDocumentStore()
const toastStore = useToastStore()
const docStore = useDocumentStore()

// ─── 单画布模式相关 ───
const stageRef = ref<HTMLDivElement | null>(null)
const canvasRef = ref<HTMLCanvasElement | null>(null)
const showSelection = ref(true)

const zoomPercent = computed(() => props.zoomPercent ?? docStore.zoomPercent)
const pageIndex = computed(() => props.pageIndex ?? 0)
const pageName = computed(() => props.pageName ?? '页面')

const displayWidth = computed(() => fusion.scene.canvasWidth)
const displayHeight = computed(() => fusion.scene.canvasHeight)

const { isRendering, initRenderer, requestRender, reinit, toDataURL, toBlob } = useCanvasRenderer({
  canvasRef,
  showSelection,
})

// 滚动容器（响应式）
const scrollContainerRef = computed(() => props.scrollContainer ?? null)

// ─── 交互引擎（单画布模式） ───
const interaction = useCanvasInteraction({
  canvasRef,
  stageRef,
  displayWidth,
  displayHeight,
  requestRender,
  scrollContainer: scrollContainerRef,
})

// ─── 无限画布模式相关 ───
const infiniteViewportRef = ref<HTMLDivElement | null>(null)
const viewportWidth = ref(800)
const viewportHeight = ref(600)

function updateViewportSize(): void {
  const el = infiniteViewportRef.value
  if (!el) return
  viewportWidth.value = el.clientWidth
  viewportHeight.value = el.clientHeight
}

const infiniteCanvas = useInfiniteCanvas({
  viewportRef: infiniteViewportRef,
  viewportWidth,
  viewportHeight,
})

// 仅显示未隐藏的 Frame
const visibleFrames = computed<Frame[]>(() => fusion.frames.filter(f => !f.hidden))

// 背景网格样式
const gridBackgroundClass = computed(() => {
  const bg = fusion.scene.canvas?.background ?? 'grid'
  return bg === 'grid' ? 'bg-infinite-grid' : bg === 'dots' ? 'bg-infinite-dots' : ''
})

// 画布区光标样式
const canvasAreaClass = computed(() => ({
  'bg-[var(--color-canvas-bg)]': true,
}))

// 当前 Frame 类型图标
const frameTypeIcon = computed(() => {
  const type = fusion.currentFrame?.type
  switch (type) {
    case 'single': return 'fa-file'
    case 'poster': return 'fa-image'
    case 'book-page': return 'fa-book'
    case 'spread': return 'fa-book-open'
    default: return 'fa-file'
  }
})

// ─── 无限画布缩放控件 ───
function zoomIn(): void {
  infiniteCanvas.setZoom(infiniteCanvas.zoom.value * 1.2)
}
function zoomOut(): void {
  infiniteCanvas.setZoom(infiniteCanvas.zoom.value / 1.2)
}

// ─── 无限画布滚轮处理（包装 useInfiniteCanvas.onWheel 以处理 passive） ───
function onInfiniteWheel(e: WheelEvent): void {
  infiniteCanvas.onWheel(e)
}

// ─── Frame 事件桥接 ───
function onFrameSelect(frameId: string, additive: boolean): void {
  infiniteCanvas.selectFrame(frameId, additive)
}
function onFrameEnterEdit(frameId: string): void {
  infiniteCanvas.enterFrameEdit(frameId)
}

// ─── 右键菜单 ───
function onContextMenu(e: MouseEvent): void {
  emit('contextmenu', { x: e.clientX, y: e.clientY, target: 'canvas' })
}

// ─── 选中对象的样式（用于绘制 overlay 边框与 handle，考虑旋转） ───
const selectedObjectsWithTransform = computed(() => {
  return fusion.selectedObjects.map((obj: SceneObject) => {
    const t = obj.transform
    const cx = t.x + t.width / 2
    const cy = t.y + t.height / 2
    const rad = (t.rotation * Math.PI) / 180
    const cos = Math.cos(rad)
    const sin = Math.sin(rad)
    // 选中边框：用 transform 旋转，transform-origin 为中心
    const borderStyle: Record<string, string | number> = {
      left: `${t.x}px`,
      top: `${t.y}px`,
      width: `${t.width}px`,
      height: `${t.height}px`,
      transform: `rotate(${t.rotation}deg)`,
      transformOrigin: 'center center',
    }
    // 8 个 handle 在局部坐标系（相对中心）
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
    const handleCursor: Record<HandlePosition, string> = {
      nw: 'nwse-resize',
      se: 'nwse-resize',
      ne: 'nesw-resize',
      sw: 'nesw-resize',
      n: 'ns-resize',
      s: 'ns-resize',
      e: 'ew-resize',
      w: 'ew-resize',
    }
    const HAND = 6
    const HALF = HAND / 2
    const handles = localHandles.map(h => {
      // 旋转到世界坐标
      const wx = cx + (h.lx * cos - h.ly * sin)
      const wy = cy + (h.lx * sin + h.ly * cos)
      return {
        pos: h.pos,
        cursor: handleCursor[h.pos],
        style: {
          left: `${wx - HALF}px`,
          top: `${wy - HALF}px`,
          width: `${HAND}px`,
          height: `${HAND}px`,
        },
      }
    })
    return { id: obj.id, borderStyle, handles }
  })
})

// ─── 悬停对象样式 ───
const hoverStyle = computed(() => {
  const id = interaction.hoverObjectId.value
  if (!id) return {}
  const obj = findObjectById(id)
  if (!obj) return {}
  const t = obj.transform
  return {
    left: `${t.x}px`,
    top: `${t.y}px`,
    width: `${t.width}px`,
    height: `${t.height}px`,
  }
})

// ─── 框选矩形样式 ───
const boxSelectStyle = computed(() => {
  const rect = interaction.boxSelectRect.value
  if (!rect) return {}
  return {
    left: `${rect.x}px`,
    top: `${rect.y}px`,
    width: `${rect.width}px`,
    height: `${rect.height}px`,
  }
})

// ─── 形状绘制预览样式 ───
const drawPreviewStyle = computed(() => {
  const p = interaction.shapeDrawing.drawPreview.value
  if (!p) return {}
  return {
    left: `${p.x}px`,
    top: `${p.y}px`,
    width: `${p.width}px`,
    height: `${p.height}px`,
  }
})

// ─── 文本编辑 overlay ───
const textEditorRef = ref<HTMLTextAreaElement | null>(null)
const editingObject = computed<SceneObject | null>(() => {
  const id = interaction.editingObjectId.value
  if (!id) return null
  for (const layer of fusion.layers) {
    const obj = layer.objects.find(o => o.id === id)
    if (obj) return obj
  }
  return null
})
const editingText = ref('')
/** 监听 editingObjectId 变化，进入编辑模式时同步初始文本 */
watch(() => interaction.editingObjectId.value, (id) => {
  if (id && editingObject.value) {
    editingText.value = (editingObject.value as any).text ?? ''
    nextTick(() => {
      textEditorRef.value?.focus()
      textEditorRef.value?.select()
    })
  }
})
const textEditorStyle = computed(() => {
  const obj = editingObject.value
  if (!obj) return {}
  const t = obj.transform
  const fontSize = (obj as any).fontSize ?? 14
  return {
    left: `${t.x}px`,
    top: `${t.y}px`,
    width: `${t.width}px`,
    height: `${t.height}px`,
    fontSize: `${fontSize}px`,
    fontFamily: (obj as any).fontFamily ?? 'inherit',
    fontWeight: (obj as any).fontWeight ?? 400,
    lineHeight: (obj as any).lineHeight ?? 1.4,
    color: (obj as any).color ?? '#1F2329',
    textAlign: (obj as any).textAlign ?? 'left',
  }
})
/** 提交编辑：将文本写回对象并退出 */
function commitTextEdit(): void {
  const obj = editingObject.value
  if (obj && (obj as any).text !== editingText.value) {
    fusion.pushHistory('编辑文本')
    ;(obj as any).text = editingText.value
    requestRender()
  }
  interaction.exitEditing()
}
function cancelTextEdit(): void {
  interaction.exitEditing()
}

// ─── 拖入外部图片创建 image 对象 ───
const isDragOver = ref(false)
function onDragOver(e: DragEvent): void {
  // 只在包含文件或链接时显示拖入态
  if (e.dataTransfer?.types?.includes('Files') || e.dataTransfer?.types?.includes('text/uri-list')) {
    isDragOver.value = true
  }
}
async function onDrop(e: DragEvent): Promise<void> {
  isDragOver.value = false
  const { x, y } = interaction.screenToCanvas(e.clientX, e.clientY)

  // 1) 优先处理文件拖入
  const files = Array.from(e.dataTransfer?.files ?? []).filter(f => f.type.startsWith('image/'))
  if (files.length > 0) {
    for (const file of files) {
      await createImageFromFile(file, x, y)
    }
    return
  }

  // 2) 处理 URL 拖入（从浏览器拖图片）
  const url = e.dataTransfer?.getData('text/uri-list') || e.dataTransfer?.getData('text/plain')
  if (url && /^https?:\/\//.test(url)) {
    await createImageFromUrl(url, x, y)
    return
  }

  toastStore.show('请拖入图片文件或图片链接', 'fa-image', 'warning')
}

/** 从 File 创建 image 对象（FileReader 读取为 dataURL） */
function createImageFromFile(file: File, x: number, y: number): Promise<void> {
  return new Promise(resolve => {
    const reader = new FileReader()
    reader.onload = () => {
      const src = reader.result as string
      // 预加载获取自然尺寸
      const img = new Image()
      img.onload = () => {
        commitCreateImage({
          src,
          naturalWidth: img.naturalWidth,
          naturalHeight: img.naturalHeight,
          x,
          y,
          name: file.name.replace(/\.[^.]+$/, ''),
        })
        resolve()
      }
      img.onerror = () => {
        commitCreateImage({ src, x, y, name: file.name })
        resolve()
      }
      img.src = src
    }
    reader.onerror = () => {
      toastStore.show(`读取文件失败：${file.name}`, 'fa-triangle-exclamation', 'warning')
      resolve()
    }
    reader.readAsDataURL(file)
  })
}

/** 从 URL 创建 image 对象（受 CORS 限制可能无法取尺寸） */
function createImageFromUrl(url: string, x: number, y: number): Promise<void> {
  return new Promise(resolve => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      commitCreateImage({
        src: url,
        naturalWidth: img.naturalWidth,
        naturalHeight: img.naturalHeight,
        x,
        y,
        name: '网络图片',
      })
      resolve()
    }
    img.onerror = () => {
      // 跨域失败：仍创建对象，但无自然尺寸
      commitCreateImage({ src: url, x, y, name: '网络图片' })
      resolve()
    }
    img.src = url
  })
}

/** 实际写入 fusion store 创建 image 对象 */
function commitCreateImage(params: {
  src: string
  naturalWidth?: number
  naturalHeight?: number
  x: number
  y: number
  name?: string
}): void {
  // 确保有目标图层
  let layerId = fusion.selectedLayerId
  if (!layerId) {
    const layer = fusion.newLayer()
    layerId = layer.id
  }
  // 计算显示尺寸：保持比例，最大 400
  const maxDim = 400
  let dispW = params.naturalWidth || maxDim
  let dispH = params.naturalHeight || maxDim * 0.75
  if (dispW > maxDim || dispH > maxDim) {
    const ratio = dispW / dispH
    if (dispW > dispH) {
      dispW = maxDim
      dispH = Math.round(maxDim / ratio)
    } else {
      dispH = maxDim
      dispW = Math.round(maxDim * ratio)
    }
  }
  const p = {
    name: params.name || '图片',
    x: params.x,
    y: params.y,
    width: dispW,
    height: dispH,
    src: params.src,
    naturalWidth: params.naturalWidth ?? 0,
    naturalHeight: params.naturalHeight ?? 0,
  } as unknown as Parameters<typeof fusion.newObject>[2]
  const obj = fusion.newObject(layerId, 'image', p)
  if (obj) {
    fusion.selectObject(obj.id)
    toastStore.show(`已导入图片 ${obj.name}`, 'fa-image', 'success')
    requestRender()
  }
}

// ─── 查找对象 ───
function findObjectById(id: string): SceneObject | null {
  for (const layer of fusion.layers) {
    const obj = layer.objects.find(o => o.id === id)
    if (obj) return obj
  }
  return null
}

// ─── 缩放变化时重新渲染（单画布模式） ───
watch(zoomPercent, () => {
  if (!fusion.isFramesMode) requestRender()
})

// ─── 文档尺寸变化时重新初始化（单画布模式） ───
watch(
  () => [fusion.scene.canvasWidth, fusion.scene.canvasHeight],
  () => {
    if (!fusion.isFramesMode) nextTick(() => reinit())
  },
)

// ─── 无限画布模式：监听视口尺寸变化 ───
watch(infiniteViewportRef, (el) => {
  if (el) {
    updateViewportSize()
    // 适配视图
    nextTick(() => {
      infiniteCanvas.fitToFrames()
    })
  }
})

// 使用 ResizeObserver 监听视口尺寸变化
let resizeObserver: ResizeObserver | null = null
let lastViewportW = 0
let lastViewportH = 0
onMounted(() => {
  if (infiniteViewportRef.value) {
    resizeObserver = new ResizeObserver(() => {
      const prevW = lastViewportW
      const prevH = lastViewportH
      updateViewportSize()
      // 尺寸从 0 变为非 0 时重新适配视图（修复初始化时容器尺寸为 0 的问题）
      if ((prevW === 0 || prevH === 0) && viewportWidth.value > 0 && viewportHeight.value > 0) {
        nextTick(() => infiniteCanvas.fitToFrames())
      }
      lastViewportW = viewportWidth.value
      lastViewportH = viewportHeight.value
    })
    resizeObserver.observe(infiniteViewportRef.value)
    updateViewportSize()
    lastViewportW = viewportWidth.value
    lastViewportH = viewportHeight.value
  }
  // 单画布模式：初始化渲染器
  if (!fusion.isFramesMode) {
    nextTick(() => initRenderer())
  }
  // 无限画布模式：绑定键盘事件（Space 平移、Esc 退出编辑、Ctrl+0 适配）
  if (fusion.isFramesMode) {
    window.addEventListener('keydown', infiniteCanvas.onKeyDown)
    window.addEventListener('keyup', infiniteCanvas.onKeyUp)
  }
})

onBeforeUnmount(() => {
  if (resizeObserver) {
    resizeObserver.disconnect()
    resizeObserver = null
  }
  // 清理键盘事件
  window.removeEventListener('keydown', infiniteCanvas.onKeyDown)
  window.removeEventListener('keyup', infiniteCanvas.onKeyUp)
})

// 暴露导出 API
defineExpose({
  toDataURL,
  toBlob,
  requestRender,
  reinit,
})
</script>

<style scoped>
/* 无限画布网格背景 */
.bg-infinite-grid {
  background-image:
    linear-gradient(to right, rgba(15, 23, 42, 0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(15, 23, 42, 0.04) 1px, transparent 1px);
  background-size: 20px 20px;
}

.bg-infinite-dots {
  background-image: radial-gradient(circle, rgba(15, 23, 42, 0.08) 1px, transparent 1px);
  background-size: 16px 16px;
}

/* 暗色主题适配 */
:global(.dark) .bg-infinite-grid {
  background-image:
    linear-gradient(to right, rgba(255, 255, 255, 0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(255, 255, 255, 0.04) 1px, transparent 1px);
}

:global(.dark) .bg-infinite-dots {
  background-image: radial-gradient(circle, rgba(255, 255, 255, 0.08) 1px, transparent 1px);
}
</style>
