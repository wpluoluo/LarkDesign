import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { SceneObject } from '../domain/SceneTypes'
import { findLayerById, findObjectInDoc, addMaskToLayer } from '../domain/FusionOps'
import { Mask } from '../domain/SceneTypes'

export class ContextMenuActions {
  private static instance: ContextMenuActions
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  private constructor() {}

  static getInstance(): ContextMenuActions {
    if (!ContextMenuActions.instance) {
      ContextMenuActions.instance = new ContextMenuActions()
    }
    return ContextMenuActions.instance
  }

  private showToast(message: string, icon: string, type: string): void {
    AppStorage.setOrCreate<string>('toastMessage', message)
    AppStorage.setOrCreate<string>('toastIcon', icon)
    AppStorage.setOrCreate<string>('toastType', type)
    AppStorage.setOrCreate<boolean>('toastVisible', true)
    setTimeout(() => {
      AppStorage.setOrCreate<boolean>('toastVisible', false)
    }, 3000)
  }

  private currentLayerId(): string {
    const layers = this.fusionStore.getCurrentLayers()
    if (layers.length > 0) {
      return layers[0].id
    }
    return ''
  }

  private toggleSelectedProp(prop: string, value: boolean): void {
    const sel = this.fusionStore.getSelectedObjects()
    for (let i = 0; i < sel.length; i++) {
      const obj = sel[i]
      if (prop === 'locked') {
        obj.locked = value
      } else if (prop === 'visible') {
        obj.visible = value
      }
    }
  }

  private toggleSelectedTextStyle(prop: string, onValue: number | string | boolean, offValue: number | string | boolean): void {
    const sel = this.fusionStore.getSelectedObjects()
    for (let i = 0; i < sel.length; i++) {
      const obj = sel[i]
      if (obj.type === 'text') {
        const record = obj as Record<string, Object>
        const cur = record[prop]
        record[prop] = cur === onValue ? offValue : onValue
      }
    }
  }

  private adjustSelectedFontSize(delta: number): void {
    const sel = this.fusionStore.getSelectedObjects()
    for (let i = 0; i < sel.length; i++) {
      const obj = sel[i]
      if (obj.type === 'text') {
        obj.fontSize = Math.max(8, (obj.fontSize ?? 14) + delta)
      }
    }
  }

  execute(action: string): void {
    /* ═════════ 剪贴板 ═════════ */
    if (action === 'cut') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length === 0) {
        this.showToast('请先选择对象', 'info', 'info')
        return
      }
      this.fusionStore.cutSelectedToClipboard()
      this.showToast('已剪切', 'cut', 'success')
      return
    }
    if (action === 'copy') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length === 0) {
        this.showToast('请先选择对象', 'info', 'info')
        return
      }
      this.fusionStore.copySelectedToClipboard()
      this.showToast('已复制 ' + sel.length + ' 个对象', 'copy', 'success')
      return
    }
    if (action === 'copyText') {
      this.showToast('已复制文本', 'copy', 'success')
      return
    }
    if (action === 'paste') {
      this.fusionStore.pasteFromClipboard()
      this.showToast('已粘贴', 'paste', 'success')
      return
    }
    if (action === 'pasteInFront') {
      this.showToast('已粘贴到前面（演示）', 'copy', 'success')
      return
    }
    if (action === 'pasteInBack') {
      this.showToast('已粘贴到后面（演示）', 'copy', 'success')
      return
    }

    /* ═════════ 删除 ═════════ */
    if (action === 'delete') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length === 0) {
        this.showToast('请先选择对象', 'info', 'info')
        return
      }
      for (let i = 0; i < sel.length; i++) {
        this.fusionStore.removeObjectById(sel[i].id)
      }
      this.showToast('已删除', 'delete', 'warning')
      return
    }

    /* ═════════ 编组 ═════════ */
    if (action === 'group') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length < 2) {
        this.showToast('请选择至少 2 个对象', 'info', 'info')
        return
      }
      const ids: string[] = []
      for (let i = 0; i < sel.length; i++) ids.push(sel[i].id)
      this.fusionStore.groupObjects(ids)
      this.showToast('已编组', 'group', 'success')
      return
    }
    if (action === 'ungroup') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length !== 1) {
        this.showToast('请选择一个编组', 'info', 'info')
        return
      }
      this.fusionStore.ungroupObjects(sel[0].id)
      this.showToast('已解组', 'ungroup', 'success')
      return
    }

    /* ═════════ 锁定/隐藏 ═════════ */
    if (action === 'lock') {
      this.toggleSelectedProp('locked', true)
      this.showToast('已锁定', 'lock', 'info')
      return
    }
    if (action === 'unlock') {
      this.toggleSelectedProp('locked', false)
      this.showToast('已解锁', 'unlock', 'info')
      return
    }
    if (action === 'hide') {
      this.toggleSelectedProp('visible', false)
      this.showToast('已隐藏', 'eye_off', 'info')
      return
    }

    /* ═════════ 图层顺序 ═════════ */
    if (action === 'bringToFront') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length > 0) {
        this.fusionStore.bringToFront(sel[0].id)
        this.showToast('已移到顶层', 'arrow_up', 'success')
      }
      return
    }
    if (action === 'bringForward') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length > 0) {
        this.fusionStore.bringForward(sel[0].id)
        this.showToast('已上移一层', 'arrow_up', 'success')
      }
      return
    }
    if (action === 'sendBackward') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length > 0) {
        this.fusionStore.sendBackward(sel[0].id)
        this.showToast('已下移一层', 'arrow_down', 'success')
      }
      return
    }
    if (action === 'sendToBack') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length > 0) {
        this.fusionStore.sendToBack(sel[0].id)
        this.showToast('已移到底层', 'arrow_down', 'success')
      }
      return
    }

    /* ═════════ 图层操作 ═════════ */
    if (action === 'duplicateLayer') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length > 0) {
        this.fusionStore.duplicateObject(sel[0].id)
        this.showToast('已复制图层', 'copy', 'success')
      }
      return
    }
    if (action === 'mergeDown') {
      const layers = this.fusionStore.getCurrentLayers()
      if (layers.length < 2) {
        this.showToast('至少需要 2 个图层', 'info', 'info')
        return
      }
      this.showToast('已合并图层（演示）', 'layers', 'success')
      return
    }

    /* ═════════ 选择 ═════════ */
    if (action === 'selectAll') {
      this.fusionStore.selectAllObjects()
      this.showToast('已全选', 'select_all', 'info')
      return
    }
    if (action === 'deselect') {
      this.fusionStore.selectObject(null)
      this.showToast('已取消选择', 'deselect', 'info')
      return
    }

    /* ═════════ 蒙版 ═════════ */
    if (action === 'addMask') {
      const doc = this.fusionStore.getDocument()
      const lid = this.currentLayerId()
      if (lid !== '') {
        const mask: Mask = {
          type: 'alpha',
          data: '',
          enabled: true,
          inverted: false,
        }
        addMaskToLayer(doc, lid, mask)
        this.showToast('已添加蒙版', 'layers', 'success')
      }
      return
    }

    /* ═════════ 视图 ═════════ */
    if (action === 'toggleRuler') {
      this.showToast('标尺切换', 'ruler', 'info')
      return
    }
    if (action === 'toggleGrid') {
      this.showToast('网格切换', 'grid', 'info')
      return
    }
    if (action === 'toggleSnap') {
      this.showToast('吸附切换', 'snap', 'info')
      return
    }
    if (action === 'zoomIn') {
      this.showToast('放大', 'zoom_in', 'info')
      return
    }
    if (action === 'zoomOut') {
      this.showToast('缩小', 'zoom_out', 'info')
      return
    }
    if (action === 'fitCanvas') {
      this.showToast('已适配画布', 'fit', 'info')
      return
    }
    if (action === 'actualPixels') {
      this.showToast('100% 实际像素', 'eye', 'info')
      return
    }

    /* ═════════ 文字 ═════════ */
    if (action === 'editText') {
      this.showToast('进入文字编辑（演示）', 'text', 'info')
      return
    }
    if (action === 'bold') {
      this.toggleSelectedTextStyle('fontWeight', 700, 400)
      this.showToast('已切换加粗', 'bold', 'success')
      return
    }
    if (action === 'italic') {
      this.toggleSelectedTextStyle('fontStyle', 'italic', 'normal')
      this.showToast('已切换斜体', 'italic', 'success')
      return
    }
    if (action === 'underline') {
      this.toggleSelectedTextStyle('textDecoration', 'underline', 'none')
      this.showToast('已切换下划线', 'underline', 'success')
      return
    }
    if (action === 'strikethrough') {
      this.toggleSelectedTextStyle('textDecoration', 'line-through', 'none')
      this.showToast('已切换删除线', 'strikethrough', 'success')
      return
    }
    if (action === 'increaseFont') {
      this.adjustSelectedFontSize(2)
      this.showToast('已增大字号', 'plus', 'success')
      return
    }
    if (action === 'decreaseFont') {
      this.adjustSelectedFontSize(-2)
      this.showToast('已减小字号', 'minus', 'success')
      return
    }

    /* ═════════ 变换 ═════════ */
    if (action === 'freeTransform') {
      const sel = this.fusionStore.getSelectedObjects()
      if (sel.length === 0) {
        this.showToast('请先选择对象', 'info', 'info')
        return
      }
      this.showToast('进入自由变换（演示）', 'scale', 'info')
      return
    }

    /* ═════════ 效果 ═════════ */
    if (action === 'dropShadow') {
      const lid = this.currentLayerId()
      if (lid !== '') {
        this.fusionStore.addLayerEffect(lid, 'drop-shadow')
        this.showToast('已添加投影', 'shadow', 'success')
      }
      return
    }
    if (action === 'innerShadow') {
      const lid = this.currentLayerId()
      if (lid !== '') {
        this.fusionStore.addLayerEffect(lid, 'inner-shadow')
        this.showToast('已添加内阴影', 'shadow', 'success')
      }
      return
    }
    if (action === 'outerGlow') {
      const lid = this.currentLayerId()
      if (lid !== '') {
        this.fusionStore.addLayerEffect(lid, 'outer-glow')
        this.showToast('已添加外发光', 'glow', 'success')
      }
      return
    }
    if (action === 'innerGlow') {
      const lid = this.currentLayerId()
      if (lid !== '') {
        this.fusionStore.addLayerEffect(lid, 'inner-glow')
        this.showToast('已添加内发光', 'glow', 'success')
      }
      return
    }

    /* ═════════ 未实现 ═════════ */
    this.showToast('「' + action + '」功能开发中', 'info', 'info')
  }
}
