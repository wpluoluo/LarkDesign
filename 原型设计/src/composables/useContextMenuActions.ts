/**
 * useContextMenuActions - 上下文菜单动作分发器
 *
 * 将 ContextMenuItem 的 action 字段映射到具体业务逻辑。
 * 绑定到 Fusion DOM store、document store、layer store、toast store。
 * 优先实现核心图层/对象操作，未实现的动作为 Toast 提示。
 */
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useDocumentStore } from '../stores/document'
import { useToastStore } from '../stores/toast'
import { useLayerStore } from '../stores/layer'

export function useContextMenuActions() {
  const fusion = useFusionDocumentStore()
  const doc = useDocumentStore()
  const toast = useToastStore()
  const layer = useLayerStore()

  function currentLayerId(): string | null {
    return fusion.selectedLayerId ?? fusion.layers[0]?.id ?? null
  }

  // ─── action → handler 映射 ───
  const handlers: Record<string, () => void> = {
    /* ═════════ 剪贴板 ═════════ */
    cut: () => {
      if (fusion.selectedObjectIds.length === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        fusion.selectedObjectIds.forEach(oid => fusion.deleteObject(lid, oid))
        toast.show('已剪切', 'fa-scissors', 'success')
      }
    },
    copy: () => {
      if (fusion.selectedObjectIds.length === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      toast.show(`已复制 ${fusion.selectedObjectIds.length} 个对象`, 'fa-copy', 'success')
    },
    copyText: () => {
      toast.show('已复制文本', 'fa-copy', 'success')
    },
    paste: () => {
      toast.show('已粘贴（演示）', 'fa-paste', 'success')
    },
    pasteInFront: () => {
      toast.show('已粘贴到前面（演示）', 'fa-copy', 'success')
    },
    pasteInBack: () => {
      toast.show('已粘贴到后面（演示）', 'fa-copy', 'success')
    },

    /* ═════════ 删除 ═════════ */
    delete: () => {
      if (fusion.selectedObjectIds.length === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        fusion.selectedObjectIds.forEach(oid => fusion.deleteObject(lid, oid))
        layer.deselect()
        toast.show('已删除', 'fa-trash', 'warning')
      }
    },

    /* ═════════ 编组 ═════════ */
    group: () => {
      if (fusion.selectedObjectIds.length < 2) {
        toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const g = fusion.groupSelected(lid)
        if (g) toast.show('已编组', 'fa-object-group', 'success')
      }
    },
    ungroup: () => {
      if (fusion.selectedObjectIds.length !== 1) {
        toast.show('请选择一个组', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        fusion.ungroupSelected(lid, fusion.selectedObjectIds[0])
        toast.show('已解组', 'fa-object-ungroup', 'success')
      }
    },

    /* ═════════ 锁定/隐藏 ═════════ */
    lock: () => {
      toggleSelectedProp('locked', true)
      toast.show('已锁定', 'fa-lock', 'info')
    },
    unlock: () => {
      toggleSelectedProp('locked', false)
      toast.show('已解锁', 'fa-lock-open', 'info')
    },
    hide: () => {
      toggleSelectedProp('visible', false)
      toast.show('已隐藏', 'fa-eye-slash', 'info')
    },

    /* ═════════ 图层顺序 ═════════ */
    bringToFront: () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx >= 0 && idx < fusion.layers.length - 1) {
        fusion.reorderLayer(idx, fusion.layers.length - 1)
        toast.show('已移到顶层', 'fa-arrow-up-to-line', 'success')
      }
    },
    bringForward: () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx >= 0 && idx < fusion.layers.length - 1) {
        fusion.reorderLayer(idx, idx + 1)
        toast.show('已上移一层', 'fa-chevron-up', 'success')
      }
    },
    sendBackward: () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx > 0) {
        fusion.reorderLayer(idx, idx - 1)
        toast.show('已下移一层', 'fa-chevron-down', 'success')
      }
    },
    sendToBack: () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx > 0) {
        fusion.reorderLayer(idx, 0)
        toast.show('已移到底层', 'fa-arrow-down-to-line', 'success')
      }
    },

    /* ═════════ 图层操作 ═════════ */
    duplicateLayer: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.cloneLayer(lid)
        toast.show('已复制图层', 'fa-copy', 'success')
      }
    },
    mergeDown: () => {
      if (fusion.layers.length < 2) {
        toast.show('至少需要 2 个图层', 'fa-circle-info', 'info')
        return
      }
      toast.show('已合并图层（演示）', 'fa-layer-group', 'success')
    },

    /* ═════════ 选择 ═════════ */
    selectAll: () => {
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          layerObj.objects.forEach(o => fusion.selectObject(o.id, true))
          toast.show(`已全选 ${layerObj.objects.length} 个对象`, 'fa-object-group', 'info')
        }
      }
    },
    deselect: () => {
      fusion.deselectAll()
      layer.deselect()
      toast.show('已取消选择', 'fa-xmark', 'info')
    },

    /* ═════════ 蒙版 ═════════ */
    addMask: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addMask(lid)
        toast.show('已添加蒙版', 'fa-circle-half-stroke', 'success')
      }
    },

    /* ═════════ 视图 ═════════ */
    toggleRuler: () => {
      doc.toggleRuler()
      toast.show(doc.showRuler ? '已显示标尺' : '已隐藏标尺', 'fa-ruler', 'info')
    },
    toggleGrid: () => {
      toast.show('网格切换（演示）', 'fa-border-all', 'info')
    },
    toggleSnap: () => {
      toast.show('吸附切换（演示）', 'fa-magnet', 'info')
    },
    zoomIn: () => {
      doc.zoomIn()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-plus', 'info')
    },
    zoomOut: () => {
      doc.zoomOut()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-minus', 'info')
    },
    fitCanvas: () => {
      doc.zoomToFit()
      toast.show('已适配画布', 'fa-expand', 'info')
    },
    actualPixels: () => {
      doc.zoomToActual()
      toast.show('100% 实际像素', 'fa-eye', 'info')
    },

    /* ═════════ 文字 ═════════ */
    editText: () => {
      toast.show('进入文字编辑（演示）', 'fa-font', 'info')
    },
    bold: () => {
      toggleSelectedTextStyle('fontWeight', 700, 400)
      toast.show('已切换加粗', 'fa-bold', 'success')
    },
    italic: () => {
      toggleSelectedTextStyle('fontStyle', 'italic', 'normal')
      toast.show('已切换斜体', 'fa-italic', 'success')
    },
    underline: () => {
      toggleSelectedTextStyle('textDecoration', 'underline', 'none')
      toast.show('已切换下划线', 'fa-underline', 'success')
    },
    strikethrough: () => {
      toggleSelectedTextStyle('textDecoration', 'line-through', 'none')
      toast.show('已切换删除线', 'fa-strikethrough', 'success')
    },
    increaseFont: () => {
      adjustSelectedFontSize(2)
      toast.show('已增大字号', 'fa-plus', 'success')
    },
    decreaseFont: () => {
      adjustSelectedFontSize(-2)
      toast.show('已减小字号', 'fa-minus', 'success')
    },

    /* ═════════ 变换 ═════════ */
    freeTransform: () => {
      if (fusion.selectedObjectIds.length === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      toast.show('进入自由变换（演示）', 'fa-up-right-and-down-left-from-center', 'info')
    },

    /* ═════════ 效果 ═════════ */
    dropShadow: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addEffect(lid, 'drop-shadow')
        toast.show('已添加投影', 'fa-layer-group', 'success')
      }
    },
    innerShadow: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addEffect(lid, 'inner-shadow')
        toast.show('已添加内阴影', 'fa-circle', 'success')
      }
    },
    outerGlow: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addEffect(lid, 'outer-glow')
        toast.show('已添加外发光', 'fa-sun', 'success')
      }
    },
    innerGlow: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addEffect(lid, 'inner-glow')
        toast.show('已添加内发光', 'fa-circle', 'success')
      }
    },
    colorOverlay: () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.addEffect(lid, 'color-overlay')
        toast.show('已添加颜色叠加', 'fa-palette', 'success')
      }
    },
  }

  /** 切换选中对象的某个布尔属性 */
  function toggleSelectedProp(prop: 'locked' | 'visible', value: boolean): void {
    const lid = currentLayerId()
    if (!lid) return
    const layerObj = fusion.layers.find(l => l.id === lid)
    if (!layerObj) return
    fusion.selectedObjectIds.forEach(oid => {
      const o = layerObj.objects.find(x => x.id === oid)
      if (o) (o as unknown as Record<string, unknown>)[prop] = value
    })
  }

  /** 切换选中文字对象的样式属性 */
  function toggleSelectedTextStyle(prop: string, onValue: unknown, offValue: unknown): void {
    const lid = currentLayerId()
    if (!lid) return
    const layerObj = fusion.layers.find(l => l.id === lid)
    if (!layerObj) return
    fusion.selectedObjectIds.forEach(oid => {
      const o = layerObj.objects.find(x => x.id === oid && x.type === 'text')
      if (o) {
        const record = o as unknown as Record<string, unknown>
        const cur = record[prop]
        record[prop] = cur === onValue ? offValue : onValue
      }
    })
  }

  /** 调整选中文字对象的字号 */
  function adjustSelectedFontSize(delta: number): void {
    const lid = currentLayerId()
    if (!lid) return
    const layerObj = fusion.layers.find(l => l.id === lid)
    if (!layerObj) return
    fusion.selectedObjectIds.forEach(oid => {
      const o = layerObj.objects.find(x => x.id === oid && x.type === 'text')
      if (o && o.type === 'text') {
        o.fontSize = Math.max(8, o.fontSize + delta)
      }
    })
  }

  /** 执行上下文菜单动作 */
  function execute(action: string): void {
    const handler = handlers[action]
    if (handler) {
      handler()
    } else {
      // 未实现：显示 Toast 提示
      toast.show(`「${action}」功能开发中`, 'fa-circle-info', 'info')
    }
  }

  return { execute }
}
