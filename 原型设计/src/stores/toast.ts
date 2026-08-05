import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface ToastItem {
  id: number
  message: string
  icon?: string
  type: 'success' | 'info' | 'warning'
}

let toastId = 0
let dismissTimer: ReturnType<typeof setTimeout> | null = null

export const useToastStore = defineStore('toast', () => {
  const toasts = ref<ToastItem[]>([])

  /** 固定一行：新消息替换旧消息，不追加弹出 */
  function show(message: string, icon?: string, type: ToastItem['type'] = 'info') {
    const id = ++toastId
    // 替换而非追加：只保留最新一条
    toasts.value = [{ id, message, icon, type }]
    // 清除之前的定时器，重新计时
    if (dismissTimer) clearTimeout(dismissTimer)
    dismissTimer = setTimeout(() => dismiss(id), 3000)
  }

  function dismiss(id: number) {
    const idx = toasts.value.findIndex(t => t.id === id)
    if (idx >= 0) toasts.value.splice(idx, 1)
  }

  return { toasts, show, dismiss }
})
