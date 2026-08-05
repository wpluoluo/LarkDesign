/**
 * ToastStore - Toast 提示管理
 *
 * 对应原型 src/stores/toast.ts
 * 固定一行显示：新消息替换旧消息，不追加弹出。
 */
export type ToastType = 'success' | 'info' | 'warning'

export interface ToastItem {
  id: number
  message: string
  icon?: string
  type: ToastType
}

let toastId = 0
let dismissTimer: number = -1

export class ToastStore {
  private static instance: ToastStore
  private _toasts: ToastItem[] = []

  private constructor() {}

  static getInstance(): ToastStore {
    if (!ToastStore.instance) {
      ToastStore.instance = new ToastStore()
    }
    return ToastStore.instance
  }

  get toasts(): ToastItem[] {
    return this._toasts
  }

  /** 显示提示（替换模式：只保留最新一条） */
  show(message: string, icon?: string, type?: ToastType): void {
    const id = ++toastId
    const toastType = type ?? 'info'
    // 替换而非追加
    this._toasts = [{ id, message, icon, type: toastType }]
    // 同步到 AppStorage
    AppStorage.setOrCreate<string>('toastMessage', message)
    AppStorage.setOrCreate<string>('toastType', toastType)
    // 清除之前的定时器
    if (dismissTimer >= 0) {
      clearTimeout(dismissTimer)
    }
    // 3 秒后自动消失
    dismissTimer = setTimeout(() => {
      this.dismiss(id)
    }, 3000)
  }

  success(message: string, icon?: string): void {
    this.show(message, icon, 'success')
  }

  info(message: string, icon?: string): void {
    this.show(message, icon, 'info')
  }

  warning(message: string, icon?: string): void {
    this.show(message, icon, 'warning')
  }

  dismiss(id: number): void {
    const idx = this._toasts.findIndex(t => t.id === id)
    if (idx >= 0) this._toasts.splice(idx, 1)
    if (this._toasts.length === 0) {
      AppStorage.setOrCreate<string>('toastMessage', '')
    }
  }
}
