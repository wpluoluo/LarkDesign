/**
 * useKeyboardShortcuts - 全局键盘快捷键系统
 *
 * 集中管理所有快捷键，并复用 useMenuActions 与 useContextMenuActions
 * 中已实现的命令。未实现的命令会显示 Toast 提示。
 */
import { ref, onMounted, onUnmounted } from 'vue'
import { useDocumentStore } from '../stores/document'
import { useLayerStore } from '../stores/layer'
import { useToastStore } from '../stores/toast'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useMenuActions } from './useMenuActions'
import { deepClone } from '../fusion'

export interface UseKeyboardShortcutsOptions {
  /** 滚轮缩放处理器（在 Composition 中已有，可注入） */
  onWheelZoom?: (e: WheelEvent) => void
}

export function useKeyboardShortcuts(opts: UseKeyboardShortcutsOptions = {}) {
  const doc = useDocumentStore()
  const layer = useLayerStore()
  const toast = useToastStore()
  const fusion = useFusionDocumentStore()
  const { execute: runAction } = useMenuActions()

  const isPanning = ref(false)

  /** 是否在输入元素中 */
  function isEditableTarget(t: EventTarget | null): boolean {
    const tag = (t as HTMLElement)?.tagName
    return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || (t as HTMLElement)?.isContentEditable
  }

  /** 处理 Ctrl/Cmd 组合键 */
  function handleCtrlCombo(e: KeyboardEvent): boolean {
    const key = e.key.toLowerCase()
    const ctrl = e.ctrlKey || e.metaKey

    if (!ctrl) return false

    // Ctrl+S 保存
    if (key === 's') {
      e.preventDefault()
      runAction('保存')
      return true
    }
    // Ctrl+Z 撤销 / Ctrl+Shift+Z 或 Ctrl+Y 重做
    if (key === 'z' && !e.shiftKey) {
      e.preventDefault()
      runAction('撤销')
      return true
    }
    if ((key === 'z' && e.shiftKey) || key === 'y') {
      e.preventDefault()
      runAction('重做')
      return true
    }
    // Ctrl+C 复制
    if (key === 'c') {
      e.preventDefault()
      runAction('复制')
      return true
    }
    // Ctrl+X 剪切
    if (key === 'x') {
      e.preventDefault()
      runAction('剪切')
      return true
    }
    // Ctrl+V 粘贴
    if (key === 'v') {
      e.preventDefault()
      runAction('粘贴')
      return true
    }
    // Ctrl+G 编组 / Ctrl+Shift+G 解组
    if (key === 'g' && !e.shiftKey) {
      e.preventDefault()
      runAction('编组')
      return true
    }
    if (key === 'g' && e.shiftKey) {
      e.preventDefault()
      runAction('解组')
      return true
    }
    // Ctrl+E 合并图层
    if (key === 'e') {
      e.preventDefault()
      runAction('合并图层')
      return true
    }
    // Ctrl+Shift+N 新建图层
    if (key === 'n' && e.shiftKey) {
      e.preventDefault()
      runAction('新建图层')
      return true
    }
    // Ctrl+A 全选
    if (key === 'a') {
      e.preventDefault()
      runAction('全选')
      return true
    }
    // Ctrl+D 复制选中对象（原位复制 + 偏移）
    if (key === 'd' && !e.shiftKey) {
      e.preventDefault()
      duplicateSelected()
      return true
    }
    // Ctrl+R 标尺
    if (key === 'r') {
      e.preventDefault()
      doc.toggleRuler()
      toast.show(doc.showRuler ? '已显示标尺' : '已隐藏标尺', 'fa-ruler', 'info')
      return true
    }
    // Ctrl+= / Ctrl++ 放大
    if (key === '=' || key === '+') {
      e.preventDefault()
      doc.zoomIn()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-plus', 'info')
      return true
    }
    // Ctrl+- 缩小
    if (key === '-') {
      e.preventDefault()
      doc.zoomOut()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-minus', 'info')
      return true
    }
    // Ctrl+0 适配画布
    if (key === '0') {
      e.preventDefault()
      doc.zoomToFit()
      toast.show('已适配画布', 'fa-expand', 'info')
      return true
    }
    // Ctrl+1 实际像素
    if (key === '1') {
      e.preventDefault()
      doc.zoomToActual()
      toast.show('100% 实际像素', 'fa-eye', 'info')
      return true
    }
    return false
  }

  /** 处理非组合键（Delete/Escape/Space 等） */
  function handleSingleKey(e: KeyboardEvent): boolean {
    // Delete 删除选中对象
    if (e.key === 'Delete' || e.key === 'Backspace') {
      if (fusion.selectedObjectIds.length > 0) {
        e.preventDefault()
        const lid = fusion.selectedLayerId ?? fusion.layers[0]?.id
        if (lid) {
          fusion.selectedObjectIds.forEach(oid => fusion.deleteObject(lid, oid))
          layer.deselect()
          toast.show('已删除', 'fa-trash', 'warning')
        }
        return true
      }
    }
    // Escape 取消选择
    if (e.key === 'Escape') {
      e.preventDefault()
      fusion.deselectAll()
      layer.deselect()
      toast.show('已取消选中', 'fa-xmark', 'info')
      return true
    }
    // Space 触发平移
    if (e.key === ' ' && !isPanning.value) {
      if (!isEditableTarget(e.target)) {
        e.preventDefault()
        isPanning.value = true
        return true
      }
    }
    // 方向键微调（Shift 加速 10px，否则 1px）
    if (e.key === 'ArrowUp' || e.key === 'ArrowDown' || e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      const step = e.shiftKey ? 10 : 1
      let dx = 0, dy = 0
      if (e.key === 'ArrowUp') dy = -step
      else if (e.key === 'ArrowDown') dy = step
      else if (e.key === 'ArrowLeft') dx = -step
      else if (e.key === 'ArrowRight') dx = step
      e.preventDefault()
      nudgeSelected(dx, dy)
      return true
    }
    return false
  }

  /** 复制选中对象（Ctrl+D） */
  function duplicateSelected(): void {
    const sel = fusion.selectedObjects
    if (sel.length === 0) {
      toast.show('请先选择对象', 'fa-circle-info', 'info')
      return
    }
    const lid = fusion.selectedLayerId
    if (!lid) return
    fusion.pushHistory('复制对象')
    const newIds: string[] = []
    sel.forEach(src => {
      const clone = deepClone(src)
      clone.id = `${src.type}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`
      clone.transform.x += 10
      clone.transform.y += 10
      // 找到目标图层并 push
      const layer = fusion.layers.find(l => l.id === lid)
      if (layer) {
        layer.objects.push(clone)
        newIds.push(clone.id)
      }
    })
    fusion.selectLayer(lid)
    fusion.selectedObjectIds = newIds
    toast.show(`已复制 ${newIds.length} 个对象`, 'fa-copy', 'success')
  }

  /** 方向键微调位置（Shift 加速 10px） */
  function nudgeSelected(dx: number, dy: number): void {
    const sel = fusion.selectedObjects
    if (sel.length === 0) return
    fusion.pushHistory('微调位置')
    sel.forEach(o => {
      o.transform.x += dx
      o.transform.y += dy
    })
  }

  /** 主键盘事件处理器 */
  const onKeyDown = (e: KeyboardEvent) => {
    if (isEditableTarget(e.target)) return
    if (handleCtrlCombo(e)) return
    handleSingleKey(e)
  }

  const onKeyUp = (e: KeyboardEvent) => {
    if (e.key === ' ') isPanning.value = false
  }

  /** Ctrl+滚轮缩放 / Alt+滚轮缩放（可选） */
  const onWheel = (e: WheelEvent) => {
    if (e.ctrlKey || e.metaKey) {
      e.preventDefault()
      if (e.deltaY < 0) doc.zoomIn()
      else doc.zoomOut()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass', 'info')
      return
    }
    if (e.altKey) {
      e.preventDefault()
      if (e.deltaY < 0) doc.zoomIn()
      else doc.zoomOut()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass', 'info')
      return
    }
    // 转发给外部处理器（普通滚动）
    if (opts.onWheelZoom) opts.onWheelZoom(e)
  }

  onMounted(() => {
    document.addEventListener('keydown', onKeyDown)
    document.addEventListener('keyup', onKeyUp)
  })

  onUnmounted(() => {
    document.removeEventListener('keydown', onKeyDown)
    document.removeEventListener('keyup', onKeyUp)
  })

  return {
    isPanning,
    onKeyDown,
    onKeyUp,
    onWheel,
  }
}
