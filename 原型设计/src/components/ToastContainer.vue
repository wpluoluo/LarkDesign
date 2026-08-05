<template>
  <Teleport to="body">
    <div
      class="fixed bottom-[48px] left-1/2 -translate-x-1/2 z-[9999] pointer-events-none"
      :class="currentToast ? 'opacity-100' : 'opacity-0'"
      style="transition: opacity 0.15s ease"
    >
      <div
        v-if="currentToast"
        :key="currentToast.id"
        class="flex flex-row items-center gap-[8px] h-[32px] px-[14px] bg-[var(--color-title)] rounded-[6px] shadow-[0_4px_16px_rgba(0,0,0,0.18)] pointer-events-auto whitespace-nowrap"
      >
        <i :class="['fa-solid', toastIcon(currentToast), 'text-[11px]', toastColor(currentToast)]"></i>
        <span class="text-[12px] leading-[16px] font-[500] text-white">{{ currentToast.message }}</span>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useToastStore, type ToastItem } from '../stores/toast'

const toastStore = useToastStore()

// 固定一行：始终只显示最新一条
const currentToast = computed<ToastItem | null>(() => {
  return toastStore.toasts.length > 0 ? toastStore.toasts[toastStore.toasts.length - 1] : null
})

const toastIcon = (t: ToastItem) => t.icon || (t.type === 'success' ? 'fa-circle-check' : t.type === 'warning' ? 'fa-triangle-exclamation' : 'fa-circle-info')
const toastColor = (t: ToastItem) => t.type === 'success' ? 'text-[#4ADE80]' : t.type === 'warning' ? 'text-[#FBBF24]' : 'text-[#60A5FA]'
</script>
