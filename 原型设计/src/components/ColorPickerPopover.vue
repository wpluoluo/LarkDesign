<template>
  <Teleport to="body">
    <div
      v-if="visible"
      class="fixed z-[200] w-[220px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg p-[10px]"
      :style="{ left: x + 'px', top: y + 'px' }"
      @click.stop
      @mousedown.stop
    >
      <!-- 顶部小三角（指向锚点） -->
      <div
        v-if="showArrow"
        class="absolute w-[10px] h-[10px] bg-[var(--color-white)] border-l border-t border-[var(--color-border)] rotate-45 pointer-events-none"
        :style="arrowStyle"
      ></div>

      <!-- 颜色选择器主体 -->
      <ColorPickerPanel
        :model-value="modelValue"
        @update:model-value="onPick"
      />

      <!-- 底部操作行 -->
      <div class="flex flex-row items-center justify-between gap-[6px] mt-[8px] pt-[6px] border-t border-[var(--color-border-light)]">
        <!-- 透明度滑块（占位，未来扩展） -->
        <div class="flex flex-row items-center gap-[4px] flex-1">
          <span class="text-[9px] font-[500] text-[var(--color-muted)]">α</span>
          <input
            type="range"
            class="flex-1 h-[4px] accent-[var(--color-primary)] cursor-pointer"
            min="0"
            max="100"
            :value="opacity"
            @input="onOpacityInput"
          />
          <span class="text-[9px] font-[500] text-[var(--color-body)] w-[26px] text-right">{{ opacity }}%</span>
        </div>
        <!-- 取消按钮 -->
        <button
          class="h-[22px] px-[8px] rounded-[3px] text-[9px] font-[600] bg-[var(--color-panel)] hover:bg-[var(--color-border-light)] text-[var(--color-secondary)]"
          @click="onCancel"
        >取消</button>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import ColorPickerPanel from './ColorPickerPanel.vue'

const props = withDefaults(defineProps<{
  visible: boolean
  /** 锚点位置（屏幕坐标，左上角） */
  anchorX: number
  anchorY: number
  /** 当前颜色（HEX） */
  modelValue: string
  /** 透明度 0-100 */
  opacity?: number
  /** 弹窗相对于锚点的方向 */
  placement?: 'bottom-left' | 'bottom-right' | 'top-left' | 'top-right'
}>(), {
  opacity: 100,
  placement: 'bottom-left',
})

const emit = defineEmits<{
  (e: 'update:modelValue', hex: string): void
  (e: 'update:opacity', val: number): void
  (e: 'close'): void
}>()

const POPUP_W = 220
const POPUP_H = 280
const MARGIN = 8

const x = ref(props.anchorX)
const y = ref(props.anchorY)
const showArrow = ref(true)

// 重新计算位置避免超出视口
function clampPosition(ax: number, ay: number): void {
  const vw = window.innerWidth
  const vh = window.innerHeight
  let nx = ax
  let ny = ay
  // 横向
  if (props.placement.startsWith('bottom') || props.placement.startsWith('top')) {
    if (nx + POPUP_W + MARGIN > vw) nx = vw - POPUP_W - MARGIN
    if (nx < MARGIN) nx = MARGIN
  }
  // 纵向
  if (props.placement.startsWith('bottom')) {
    if (ny + POPUP_H + MARGIN > vh) ny = ay - POPUP_H - MARGIN // 翻转到上方
  } else if (props.placement.startsWith('top')) {
    ny = ay - POPUP_H
    if (ny < MARGIN) ny = ay + MARGIN // 翻转到下方
  }
  x.value = nx
  y.value = ny
}

watch(() => [props.anchorX, props.anchorY, props.visible], ([ax, ay, vis]) => {
  if (vis) clampPosition(ax as number, ay as number)
}, { immediate: true })

const arrowStyle = computed(() => {
  // 箭头位置：默认在弹窗顶部左侧
  const left = Math.max(12, Math.min(props.anchorX - x.value, POPUP_W - 24))
  return {
    left: `${left}px`,
    top: '-5px',
  }
})

function onPick(hex: string): void {
  emit('update:modelValue', hex)
}

function onOpacityInput(e: Event): void {
  const v = Number((e.target as HTMLInputElement).value)
  emit('update:opacity', v)
}

function onCancel(): void {
  emit('close')
}
</script>
