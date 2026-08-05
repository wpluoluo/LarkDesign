import { onMounted, onUnmounted, type Ref } from 'vue'

/**
 * 点击目标元素外部时触发回调（常用于关闭弹窗/菜单）
 * @param targetRef 目标元素的 ref
 * @param onClickOutside 点击外部时的回调
 * @param eventName 监听的事件名，默认 'click'
 */
export function useClickOutside(
  targetRef: Ref<HTMLElement | null>,
  onClickOutside: () => void,
  eventName: 'click' | 'mousedown' = 'click',
) {
  const handler = (e: MouseEvent) => {
    const el = targetRef.value
    if (!el) return
    if (!el.contains(e.target as Node)) {
      onClickOutside()
    }
  }

  onMounted(() => document.addEventListener(eventName, handler))
  onUnmounted(() => document.removeEventListener(eventName, handler))

  return { handler }
}
