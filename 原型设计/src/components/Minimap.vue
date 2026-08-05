<template>
  <div
    v-if="fusion.isFramesMode && fusion.frames.length > 0"
    class="absolute bottom-[48px] right-[12px] z-20 flex flex-col rounded-[8px] bg-[var(--color-panel)] border border-[var(--color-border-light)] shadow-[0_4px_16px_rgba(15,23,42,0.10)] overflow-hidden transition-all duration-200"
    :style="{ width: expanded ? minimapWidth + 'px' : 'auto' }"
  >
    <!-- 标题栏 -->
    <div
      class="flex flex-row justify-between items-center h-[26px] px-[8px] cursor-pointer select-none hover:bg-[var(--color-hover-bg)] transition-colors shrink-0"
      @click="expanded = !expanded"
      :title="expanded ? '收起鸟瞰图' : '展开鸟瞰图'"
    >
      <div class="flex flex-row items-center gap-[6px]">
        <i class="fa-solid fa-map text-[9px] text-[var(--color-primary)]"></i>
        <span class="text-[10px] font-[600] text-[var(--color-body)]">鸟瞰图</span>
      </div>
      <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform duration-150" :class="expanded ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
    </div>
    <!-- 鸟瞰图主体 -->
    <div
      v-if="expanded"
      ref="minimapRef"
      class="relative cursor-pointer bg-[var(--color-white)]"
      :style="{ width: minimapWidth + 'px', height: minimapHeight + 'px' }"
      @mousedown.stop="onMinimapClick"
    >
      <svg :width="minimapWidth" :height="minimapHeight" class="block">
        <!-- Frame 矩形 -->
        <rect
          v-for="f in frameRects"
          :key="f.id"
          :x="f.x"
          :y="f.y"
          :width="f.w"
          :height="f.h"
          :rx="1"
          :fill="f.selected ? 'var(--color-primary-light-100)' : 'var(--color-white)'"
          :stroke="f.selected ? 'var(--color-primary)' : 'var(--color-border)'"
          :stroke-width="f.selected ? 1.5 : 0.8"
        />
        <!-- 视口矩形 -->
        <rect
          v-if="viewportRect"
          :x="viewportRect.x"
          :y="viewportRect.y"
          :width="viewportRect.w"
          :height="viewportRect.h"
          fill="rgba(58,196,135,0.10)"
          stroke="var(--color-primary)"
          :stroke-width="1.2"
          stroke-dasharray="3 2"
          pointer-events="none"
        />
      </svg>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { getFramesBoundingBox } from '../fusion'

const props = defineProps<{
  /** 视口宽度（DOM 像素） */
  viewportWidth: number
  /** 视口高度（DOM 像素） */
  viewportHeight: number
}>()

const fusion = useFusionDocumentStore()
const minimapRef = ref<HTMLDivElement | null>(null)
const expanded = ref(true)

// ─── 鸟瞰图尺寸 ───
const minimapWidth = 180
const minimapHeight = 120

// ─── 计算 Frame 包围盒 ───
const bbox = computed(() => {
  const frames = fusion.frames
  if (frames.length === 0) return null
  return getFramesBoundingBox(fusion.doc)
})

// ─── 缩放比例：画布坐标 → 鸟瞰图坐标 ───
const PADDING = 12
const scale = computed(() => {
  const b = bbox.value
  if (!b) return 1
  const cw = b.maxX - b.minX
  const ch = b.maxY - b.minY
  if (cw <= 0 || ch <= 0) return 1
  const sx = (minimapWidth - PADDING * 2) / cw
  const sy = (minimapHeight - PADDING * 2) / ch
  return Math.min(sx, sy)
})

// ─── 画布坐标 → 鸟瞰图坐标 ───
function toMinimap(x: number, y: number): { x: number; y: number } {
  const b = bbox.value
  if (!b) return { x: 0, y: 0 }
  const s = scale.value
  const cw = b.maxX - b.minX
  const ch = b.maxY - b.minY
  // 居中
  const offsetX = (minimapWidth - cw * s) / 2
  const offsetY = (minimapHeight - ch * s) / 2
  return {
    x: offsetX + (x - b.minX) * s,
    y: offsetY + (y - b.minY) * s,
  }
}

// ─── Frame 矩形列表 ───
const frameRects = computed(() => {
  return fusion.frames.map(f => {
    const p = toMinimap(f.x, f.y)
    return {
      id: f.id,
      x: p.x,
      y: p.y,
      w: Math.max(2, f.width * scale.value),
      h: Math.max(2, f.height * scale.value),
      selected: f.id === fusion.selectedFrameId,
    }
  })
})

// ─── 视口矩形 ───
const viewportRect = computed(() => {
  const canvas = fusion.scene.canvas
  if (!canvas) return null
  const z = canvas.zoom || 1
  const vx = canvas.viewportX || 0
  const vy = canvas.viewportY || 0
  // 视口在画布坐标系中的范围
  const halfW = props.viewportWidth / (2 * z)
  const halfH = props.viewportHeight / (2 * z)
  const minX = vx - halfW
  const minY = vy - halfH
  const w = halfW * 2
  const h = halfH * 2
  const p = toMinimap(minX, minY)
  return {
    x: p.x,
    y: p.y,
    w: Math.max(4, w * scale.value),
    h: Math.max(4, h * scale.value),
  }
})

// ─── 点击鸟瞰图：平移视口到点击位置 ───
function onMinimapClick(e: MouseEvent): void {
  const el = minimapRef.value
  if (!el || !bbox.value) return
  const rect = el.getBoundingClientRect()
  // 鼠标在鸟瞰图中的坐标
  const mx = e.clientX - rect.left
  const my = e.clientY - rect.top
  // 反向转换为画布坐标
  const b = bbox.value
  const s = scale.value
  const cw = b.maxX - b.minX
  const ch = b.maxY - b.minY
  const offsetX = (minimapWidth - cw * s) / 2
  const offsetY = (minimapHeight - ch * s) / 2
  const canvasX = (mx - offsetX) / s + b.minX
  const canvasY = (my - offsetY) / s + b.minY
  // 更新视口中心
  fusion.updateCanvasViewport({
    viewportX: canvasX,
    viewportY: canvasY,
  })
}
</script>
