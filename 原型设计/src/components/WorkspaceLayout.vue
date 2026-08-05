<template>
  <div class="flex flex-col justify-start items-stretch w-full h-full bg-[var(--color-panel)] overflow-hidden">
    <MenuBar />
    <ToolOptionsBar @home="$emit('home')" />

    <div class="flex flex-row justify-start items-stretch flex-1 min-h-0">
      <ToolRail />
      <PagesPanel v-if="docStore.showPagesPanel" />

      <!-- Canvas Area with Interactive Rulers -->
      <div class="flex flex-col justify-start items-stretch flex-1 min-w-0 bg-[var(--color-canvas-bg)] relative overflow-hidden" ref="canvasContainer">
        <!-- Top ruler row -->
        <div v-show="docStore.showRuler" class="flex flex-row items-stretch shrink-0">
          <div class="flex flex-row justify-center items-center w-[14px] h-[14px] bg-[var(--color-ruler-bg)] border-b border-r border-[var(--color-ruler-border)] cursor-crosshair shrink-0" @mousedown="onRulerCornerMouseDown">
            <div class="w-[6px] h-[6px] relative overflow-hidden">
              <div class="absolute top-0 left-0 w-full h-[1px] bg-[var(--color-ruler-corner)]" style="transform:rotate(45deg);transform-origin:0 0"></div>
            </div>
          </div>
          <div class="flex-1 h-[14px] bg-[var(--color-ruler-bg)] border-b border-[var(--color-ruler-border)] relative overflow-hidden select-none shrink-0" @mousedown="onHRulerMouseDown">
            <svg class="absolute inset-0 w-full h-full" preserveAspectRatio="none">
              <line v-for="(t, i) in hTicks" :key="'ht'+i" :x1="t.pos" :y1="t.major ? 9 : 11" :x2="t.pos" :y2="14" stroke="var(--color-ruler-tick)" stroke-width="1" />
            </svg>
            <span v-for="(m, i) in hMarks" :key="'hm'+i" class="absolute top-[1px] text-[7px] leading-[8px] font-[400] text-[var(--color-ruler-text)] select-none" :style="{ left: m.pos + 'px' }">{{ m.label }}</span>
          </div>
        </div>
        <!-- Left ruler + canvas row -->
        <div class="flex flex-row items-stretch flex-1 min-h-0">
          <div v-show="docStore.showRuler" class="w-[14px] bg-[var(--color-ruler-bg)] border-r border-[var(--color-ruler-border)] shrink-0 relative overflow-hidden select-none" @mousedown="onVRulerMouseDown">
            <svg class="absolute inset-0 w-full h-full" preserveAspectRatio="none">
              <line v-for="(t, i) in vTicks" :key="'vt'+i" :x1="t.major ? 9 : 11" :y1="t.pos" :x2="14" :y2="t.pos" stroke="var(--color-ruler-tick)" stroke-width="1" />
            </svg>
            <span v-for="(m, i) in vMarks" :key="'vm'+i" class="absolute left-[1px] text-[7px] leading-[8px] font-[400] text-[var(--color-ruler-text)] select-none" :style="{ top: (m.pos - 4) + 'px' }">{{ m.label }}</span>
          </div>
          <div class="flex-1 relative" :class="fusion.isFramesMode ? 'overflow-hidden' : 'overflow-auto'" ref="canvasScroll" @contextmenu.prevent="onCanvasContextMenu($event)" @wheel="onCanvasWheel">
            <!-- 画布区域 (灰色工作区) -->
            <!-- 无限画布模式：CanvasStage 自身承载视口；单画布模式：外层 scale + 滚动 -->
            <div
              :class="fusion.isFramesMode
                ? 'absolute inset-0'
                : 'flex flex-row justify-center items-start p-[40px] transform-gpu transition-transform duration-150 ease-out'"
              :style="fusion.isFramesMode ? {} : { transform: `scale(${docStore.zoomPercent / 100})`, transformOrigin: 'center top' }"
            >
              <!-- Fusion DOM Canvas 渲染舞台 -->
              <CanvasStage
                :page-index="fusionPageIndex"
                :page-name="fusion.currentPage?.name ?? '页面'"
                :scroll-container="canvasScroll"
                show-frame
                @contextmenu="onCanvasStageContextMenu($event)"
                @object-click="onCanvasStageObjectClick"
              />
            </div>
            <!-- Guidelines overlay -->
            <div v-if="!fusion.isFramesMode" v-for="(g, i) in guidelines" :key="i" class="absolute pointer-events-auto cursor-grab group z-10" :class="g.orientation === 'h' ? 'left-0 right-0' : 'top-0 bottom-0'" :style="g.orientation === 'h' ? { top: g.pos + 'px', height: 0 } : { left: g.pos + 'px', width: 0 }">
              <div :class="[g.orientation === 'h' ? 'w-full h-[1px]' : 'w-[1px] h-full', 'bg-[var(--color-info)]']"></div>
              <div :class="[g.orientation === 'h' ? 'mx-auto -mt-[6px]' : 'my-auto -ml-[6px]', 'w-[12px] h-[12px] rounded-full bg-[var(--color-info)] opacity-0 group-hover:opacity-100 cursor-grab absolute', g.orientation === 'h' ? 'left-1/2' : 'top-1/2']"></div>
            </div>
            <!-- Drag preview line -->
            <div v-if="!fusion.isFramesMode && draggingGuide" class="absolute z-20 pointer-events-none" :class="draggingGuide.orientation === 'h' ? 'left-0 right-0 h-[1px]' : 'top-0 bottom-0 w-[1px]'" :style="draggingGuide.orientation === 'h' ? { top: draggingGuide.pos + 'px' } : { left: draggingGuide.pos + 'px' }">
              <div :class="[draggingGuide.orientation === 'h' ? 'w-full h-[1px]' : 'w-[1px] h-full', 'bg-[var(--color-error)]']"></div>
            </div>
          </div>
        </div>
      </div>

      <HistoryPanel v-if="docStore.showHistoryPanel" />
      <Inspector v-if="docStore.showInspector" />
    </div>

    <StatusBar
      :zoom-percent="docStore.zoomPercent"
      @zoom-in="docStore.zoomIn()"
      @zoom-out="docStore.zoomOut()"
    />
  </div>

  <!-- Canvas Context Menu (通用组件) -->
  <ContextMenu
    :visible="ctxVisible"
    :x="ctxX"
    :y="ctxY"
    :items="ctxItems"
    @close="ctxVisible = false"
    @action="onCtxAction"
  />
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import MenuBar from './MenuBar.vue'
import ToolOptionsBar from './ToolOptionsBar.vue'
import ToolRail from './ToolRail.vue'
import PagesPanel from './PagesPanel.vue'
import Inspector from './Inspector.vue'
import HistoryPanel from './HistoryPanel.vue'
import StatusBar from './StatusBar.vue'
import ContextMenu from './ContextMenu.vue'
import CanvasStage from './CanvasStage.vue'
import { useDocumentStore } from '../stores/document'
import { useLayerStore } from '../stores/layer'
import { useToastStore } from '../stores/toast'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { getCtxItemsByType } from '../data/contextMenuItems'
import { useContextMenuActions } from '../composables/useContextMenuActions'
import { useKeyboardShortcuts } from '../composables/useKeyboardShortcuts'

const emit = defineEmits<{ (e: 'home'): void }>()

const docStore = useDocumentStore()
const layerStore = useLayerStore()
const toastStore = useToastStore()
const fusion = useFusionDocumentStore()
const { execute: executeCtxAction } = useContextMenuActions()
const kb = useKeyboardShortcuts()

// 当前页面索引（多页面模式）
const fusionPageIndex = computed(() => {
  if (!fusion.currentPageId) return 0
  const idx = fusion.pages.findIndex(p => p.id === fusion.currentPageId)
  return idx >= 0 ? idx : 0
})

// ─── Element Drag ───
const dragOffset = ref({ x: 0, y: 0 })
let dragStartPos = { x: 0, y: 0 }
let isDraggingElement = false

const onElementDragStart = (e: MouseEvent) => {
  if (!layerStore.selectedElement) return
  isDraggingElement = true
  dragStartPos = { x: e.clientX - dragOffset.value.x, y: e.clientY - dragOffset.value.y }
  document.addEventListener('mousemove', onElementDragMove)
  document.addEventListener('mouseup', onElementDragEnd)
}
const onElementDragMove = (e: MouseEvent) => {
  if (!isDraggingElement) return
  dragOffset.value = { x: e.clientX - dragStartPos.x, y: e.clientY - dragStartPos.y }
}
const onElementDragEnd = () => {
  isDraggingElement = false
  document.removeEventListener('mousemove', onElementDragMove)
  document.removeEventListener('mouseup', onElementDragEnd)
}

// Reset drag offset when switching selected element
watch(() => layerStore.selectedElement, () => {
  dragOffset.value = { x: 0, y: 0 }
})

// ─── Ctrl+Wheel Zoom & Scroll ─── 由 useKeyboardShortcuts.onWheel 统一处理

// ─── Ruler Data ───
const rulerScale = 50
const rulerWidth = ref(800)
const rulerHeight = ref(600)

const hMarks = computed(() =>
  Array.from({ length: Math.floor(rulerWidth.value / rulerScale) + 1 }, (_, i) => ({ pos: i * rulerScale, label: String(i * rulerScale) }))
)
const hTicks = computed(() =>
  Array.from({ length: Math.floor(rulerWidth.value / 5) + 1 }, (_, i) => ({ pos: i * 5, major: i % 10 === 0 }))
)
const vMarks = computed(() =>
  Array.from({ length: Math.floor(rulerHeight.value / rulerScale) + 1 }, (_, i) => ({ pos: i * rulerScale, label: String(i * rulerScale) }))
)
const vTicks = computed(() =>
  Array.from({ length: Math.floor(rulerHeight.value / 5) + 1 }, (_, i) => ({ pos: i * 5, major: i % 10 === 0 }))
)

// ─── Guidelines ───
interface GuideLine { id: number; orientation: 'h' | 'v'; pos: number }
const guidelines = ref<GuideLine[]>([])
let guideIdCounter = 0
const draggingGuide = ref<{ orientation: 'h' | 'v'; pos: number } | null>(null)
const canvasContainer = ref<HTMLElement | null>(null)
const canvasScroll = ref<HTMLElement | null>(null)

const onHRulerMouseDown = (e: MouseEvent) => {
  const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
  draggingGuide.value = { orientation: 'h', pos: e.clientX - rect.left }
  document.addEventListener('mousemove', onGuideDrag)
  document.addEventListener('mouseup', onGuideDragEnd)
}
const onVRulerMouseDown = (e: MouseEvent) => {
  const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
  draggingGuide.value = { orientation: 'v', pos: e.clientY - rect.top }
  document.addEventListener('mousemove', onGuideDrag)
  document.addEventListener('mouseup', onGuideDragEnd)
}
const onRulerCornerMouseDown = () => { guidelines.value = [] }

const onGuideDrag = (e: MouseEvent) => {
  if (!draggingGuide.value || !canvasContainer.value) return
  const rect = canvasContainer.value.getBoundingClientRect()
  if (draggingGuide.value.orientation === 'h') {
    draggingGuide.value.pos = e.clientY - rect.top - 14
  } else {
    draggingGuide.value.pos = e.clientX - rect.left - 14
  }
}
const onGuideDragEnd = () => {
  if (draggingGuide.value) {
    guidelines.value.push({ id: ++guideIdCounter, orientation: draggingGuide.value.orientation, pos: draggingGuide.value.pos })
    draggingGuide.value = null
  }
  document.removeEventListener('mousemove', onGuideDrag)
  document.removeEventListener('mouseup', onGuideDragEnd)
}

// ─── Context Menu (统一使用 ContextMenu 组件) ───
const ctxVisible = ref(false)
const ctxX = ref(0)
const ctxY = ref(0)
const ctxType = ref('canvas')
const ctxItems = computed(() => getCtxItemsByType(ctxType.value))

const onElementContextMenu = (type: string, e: MouseEvent) => {
  ctxType.value = type
  ctxX.value = e.clientX
  ctxY.value = e.clientY
  ctxVisible.value = true
}
const onCanvasContextMenu = (e: MouseEvent) => {
  ctxType.value = 'canvas'
  ctxX.value = e.clientX
  ctxY.value = e.clientY
  ctxVisible.value = true
}

// 滚轮事件桥接：无限画布模式由 CanvasStage 自身处理（不阻止默认），
// 单画布模式由键盘快捷键处理
const onCanvasWheel = (e: WheelEvent) => {
  if (fusion.isFramesMode) {
    // 无限画布模式：事件由 CanvasStage 内部处理，此处不阻止冒泡
    return
  }
  kb.onWheel(e)
}
const onPageContextMenu = (e: MouseEvent) => {
  ctxType.value = 'page'
  ctxX.value = e.clientX
  ctxY.value = e.clientY
  ctxVisible.value = true
}

// ─── CanvasStage 事件桥接 ───
const onCanvasStageContextMenu = (payload: { x: number; y: number; target: 'canvas' | 'object' | 'page' }) => {
  ctxType.value = payload.target === 'object' ? 'text' : payload.target
  ctxX.value = payload.x
  ctxY.value = payload.y
  ctxVisible.value = true
}
const onCanvasStageObjectClick = (objId: string | null) => {
  if (objId) {
    const obj = fusion.listAllObjects().find(o => o.id === objId)
    if (obj) {
      layerStore.select(obj.name)
      toastStore.show(`已选中 · ${obj.name}`, 'fa-hand-pointer', 'info')
    }
  } else {
    layerStore.deselect()
  }
}
const onCtxAction = (action: string) => {
  executeCtxAction(action)
}

// ─── ResizeObserver for rulers ───
let rulerResizeObserver: ResizeObserver | null = null

onMounted(() => {
  if (canvasScroll.value) {
    const updateRulerSize = () => {
      if (canvasScroll.value) {
        rulerWidth.value = canvasScroll.value.scrollWidth
        rulerHeight.value = canvasScroll.value.scrollHeight
      }
    }
    updateRulerSize()
    rulerResizeObserver = new ResizeObserver(updateRulerSize)
    rulerResizeObserver.observe(canvasScroll.value)
  }
  // ─── Fusion DOM 初始化提示 ───
  const info = fusion.sceneInfo
  toastStore.show(
    `Fusion DOM 就绪 · ${info.layerCount} 层 / ${info.objectCount} 对象 · ${info.canvasSize}`,
    'fa-cube',
    'success',
  )
})

onUnmounted(() => {
  if (rulerResizeObserver) { rulerResizeObserver.disconnect(); rulerResizeObserver = null }
})
</script>
