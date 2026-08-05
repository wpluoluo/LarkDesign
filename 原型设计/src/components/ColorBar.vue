<template>
  <div class="flex flex-row justify-start items-center h-[28px] bg-[var(--color-white)] px-[8px] gap-[6px] shrink-0 select-none">
    <!-- 最近使用 -->
    <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)] w-[36px] shrink-0">最近</span>
    <div
      v-for="(c, i) in recentColors"
      :key="'rc'+i"
      ref="swatchRefs"
      class="w-[18px] h-[18px] rounded-[3px] cursor-pointer hover:ring-2 hover:ring-[var(--color-primary)] border border-[var(--color-border)] transition-all"
      :style="{ backgroundColor: c }"
      :title="c"
      :data-hex="c"
      @click.stop="onColorSwatchClick(c, $event)"
    ></div>
    <div class="w-[1px] h-[16px] bg-[var(--color-border)] mx-[2px]"></div>
    <!-- 常用色彩 -->
    <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)] w-[36px] shrink-0">常用</span>
    <div
      v-for="(c, i) in commonColors"
      :key="'cc'+i"
      class="w-[18px] h-[18px] rounded-[3px] cursor-pointer hover:ring-2 hover:ring-[var(--color-primary)] border border-[var(--color-border)] transition-all"
      :style="{ backgroundColor: c }"
      :title="c"
      @click.stop="onColorSwatchClick(c, $event)"
    ></div>
    <div class="flex flex-row justify-center items-center w-[18px] h-[18px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" title="添加到常用">
      <i class="fa-solid fa-plus text-[6px] text-[var(--color-muted)]"></i>
    </div>
    <div class="flex-1"></div>
    <!-- 当前选中色 -->
    <div class="flex flex-row items-center gap-[4px] px-[4px] py-[2px] rounded-[3px]">
      <div class="w-[20px] h-[20px] rounded-[3px] border border-[var(--color-border)]" :style="{ backgroundColor: currentHex }"></div>
      <span class="text-[9px] leading-[12px] font-[500] font-mono text-[var(--color-body)]">{{ currentHex }}</span>
    </div>

    <!-- Color Picker Popup (Teleport) — 统一使用 ColorPickerPanel -->
    <Teleport to="body">
      <div
        v-if="colorPicker.visible"
        ref="popupRef"
        class="fixed z-[400] w-[280px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg py-[10px] px-[12px]"
        :style="{ left: colorPicker.x + 'px', top: colorPicker.y + 'px' }"
        @click.stop
      >
        <ColorPickerPanel
          v-model="currentHex"
          :swatches="allSwatches"
          @select="onPickerSelect"
        />
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import ColorPickerPanel from './ColorPickerPanel.vue'
import { useColorStore } from '../stores/color'

const colorStore = useColorStore()
const popupRef = ref<HTMLElement | null>(null)

// 当前色（双向绑定到 store）
const currentHex = computed({
  get: () => colorStore.currentHex,
  set: (v: string) => colorStore.setColor(v),
})

// 最近使用 / 常用色彩（从 store 读取）
const recentColors = computed(() => colorStore.recentColors)
const commonColors = ref<string[]>([
  '#3AC487', '#16865F', '#3B82F6', '#EF4444', '#F59E0B', '#8B5CF6',
  '#EC4899', '#14B8A6', '#6B7280', '#FF6B6B', '#4ECDC4', '#45B7D1',
  '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9'
])

const allSwatches = computed(() => [...new Set([...recentColors.value, ...commonColors.value])])

// 色彩弹窗状态
const colorPicker = reactive({
  visible: false,
  x: 0, y: 0,
  lastClickedHex: '',
})

// 当前点击的色块索引 (用于判断是否再次点击同一色块)
let lastSwatchEl: HTMLElement | null = null

const onColorSwatchClick = (hex: string, e: MouseEvent) => {
  const el = e.currentTarget as HTMLElement

  // 如果已经打开且点击的是同一色块 → 收起
  if (colorPicker.visible && colorPicker.lastClickedHex === hex && lastSwatchEl === el) {
    colorPicker.visible = false
    lastSwatchEl = null
    return
  }

  // 否则打开（或切换到新色块的颜色）
  colorStore.setColor(hex)
  const rect = el.getBoundingClientRect()
  const MARGIN = 16
  const POPUP_W = 280
  const POPUP_H = 430

  let x = rect.left
  if (x + POPUP_W > window.innerWidth - MARGIN) {
    x = rect.right - POPUP_W
  }
  if (x < MARGIN) x = MARGIN
  if (x + POPUP_W > window.innerWidth - MARGIN) {
    x = window.innerWidth - POPUP_W - MARGIN
  }
  colorPicker.x = Math.round(x)

  const spaceBelow = window.innerHeight - rect.bottom - MARGIN
  const spaceAbove = rect.top - MARGIN
  if (spaceBelow >= POPUP_H) {
    colorPicker.y = rect.bottom + 4
  } else if (spaceAbove >= POPUP_H) {
    colorPicker.y = rect.top - POPUP_H + 4
  } else {
    colorPicker.y = Math.max(MARGIN, Math.min(rect.bottom + 4, window.innerHeight - POPUP_H - MARGIN))
  }
  colorPicker.y = Math.round(colorPicker.y)

  colorPicker.visible = true
  colorPicker.lastClickedHex = hex
  lastSwatchEl = el
}

const onPickerSelect = (hex: string) => {
  colorStore.setColor(hex)
}

// ─── 全局点击关闭弹窗 ───
const onGlobalMouseDown = (e: MouseEvent) => {
  if (!colorPicker.visible) return
  if (popupRef.value && popupRef.value.contains(e.target as Node)) return
  const swatch = (e.target as HTMLElement).closest('[data-hex]') || (e.target as HTMLElement).closest('[style*="background-color"]')
  if (swatch) return
  colorPicker.visible = false
  lastSwatchEl = null
}

onMounted(() => {
  document.addEventListener('mousedown', onGlobalMouseDown)
})

onUnmounted(() => {
  document.removeEventListener('mousedown', onGlobalMouseDown)
})
</script>
