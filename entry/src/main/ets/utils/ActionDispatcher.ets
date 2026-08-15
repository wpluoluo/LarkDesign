import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { Exporter, ExportFormat } from './Exporter'
import { SceneObject } from '../types/SceneTypes'
import { addLayer } from '../types/FusionOps'

export class ActionDispatcher {
  private static instance: ActionDispatcher
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private exporter: Exporter = Exporter.getInstance()

  private constructor() {}

  static getInstance(): ActionDispatcher {
    if (!ActionDispatcher.instance) {
      ActionDispatcher.instance = new ActionDispatcher()
    }
    return ActionDispatcher.instance
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

  private getSelectedCount(): number {
    return this.fusionStore.getSelectedObjects().length
  }

  private getSelectedObject(): SceneObject | null {
    const sel = this.fusionStore.getSelectedObjects()
    return sel.length > 0 ? sel[0] : null
  }

  private clipboard: SceneObject[] = []
  private pasteOffset: number = 0
  private lastDeselectedIds: string[] = []

  /* ═════════ 文件 ═════════ */

  newDocument(type: string): void {
    if (type === 'poster' || type === '单页海报') {
      this.fusionStore.newDocument('poster')
      this.showToast('已创建海报文档', 'image', 'success')
    } else if (type === 'album' || type === '画册') {
      this.fusionStore.newDocument('single')
      this.showToast('已创建画册文档', 'book', 'success')
    } else if (type === 'social' || type === '社交媒体') {
      this.fusionStore.newDocument('single')
      this.showToast('已创建社交媒体文档', 'share', 'success')
    } else {
      this.fusionStore.newDocument('single')
      this.showToast('已创建默认文档', 'file_new', 'success')
    }
  }

  save(): void {
    this.fusionStore.saveToStorage()
    this.showToast('文档已保存', 'save', 'success')
  }

  saveAs(): void {
    this.fusionStore.saveToStorage()
    this.showToast('已另存为副本', 'copy', 'success')
  }

  saveCopy(): void {
    this.fusionStore.saveToStorage()
    this.showToast('已保存副本', 'clone', 'success')
  }

  close(): void {
    this.fusionStore.newDocument('single')
    this.showToast('已关闭并新建文档', 'close', 'info')
  }

  exit(): void {
    this.showToast('请手动关闭应用以退出', 'exit', 'info')
  }

  documentSettings(): void {
    const scene = this.fusionStore.getScene()
    this.showToast('文档 ' + scene.canvasWidth + '×' + scene.canvasHeight + ' ' + scene.unit, 'settings', 'info')
  }

  fileInfo(): void {
    const scene = this.fusionStore.getScene()
    const layers = this.fusionStore.getCurrentLayers()
    let objCount = 0
    for (let i = 0; i < layers.length; i++) {
      objCount += layers[i].objects.length
    }
    this.showToast(layers.length + ' 层 / ' + objCount + ' 对象 · ' + scene.canvasWidth + '×' + scene.canvasHeight + ' ' + scene.unit, 'info', 'info')
  }

  exportTo(format: string): void {
    const fmt = format as ExportFormat
    void this.exporter.export({ format: fmt }).then((result) => {
      this.showToast(result.message, 'export', result.ok ? 'success' : 'warning')
    }).catch((error: Error) => {
      this.showToast('导出失败: ' + error.message, 'export', 'warning')
    })
  }

  /* ═════════ 编辑 ═════════ */

  undo(): void {
    if (this.fusionStore.canUndo()) {
      this.fusionStore.undo()
      this.showToast('已撤销', 'undo', 'info')
    } else {
      this.showToast('无可撤销操作', 'info', 'info')
    }
  }

  redo(): void {
    if (this.fusionStore.canRedo()) {
      this.fusionStore.redo()
      this.showToast('已重做', 'redo', 'info')
    } else {
      this.showToast('无可重做操作', 'info', 'info')
    }
  }

  cut(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) {
      this.showToast('请先选择对象', 'info', 'info')
      return
    }
    this.clipboard = JSON.parse(JSON.stringify(sel)) as SceneObject[]
    this.pasteOffset = 0
    for (const obj of sel) {
      this.fusionStore.removeObjectById(obj.id)
    }
    this.showToast('已剪切 ' + this.clipboard.length + ' 个对象', 'cut', 'success')
  }

  copy(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) {
      this.showToast('请先选择对象', 'info', 'info')
      return
    }
    this.clipboard = JSON.parse(JSON.stringify(sel)) as SceneObject[]
    this.pasteOffset = 0
    this.showToast('已复制 ' + sel.length + ' 个对象', 'copy', 'success')
  }

  paste(): void {
    if (this.clipboard.length === 0) {
      this.showToast('剪贴板为空', 'info', 'info')
      return
    }
    this.pasteOffset += 20
    const layers = this.fusionStore.getCurrentLayers()
    if (layers.length === 0) return
    const targetLayer = layers[0]
    const newIds: string[] = []
    for (const src of this.clipboard) {
      const clone = JSON.parse(JSON.stringify(src)) as SceneObject
      clone.id = 'obj_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 7)
      clone.transform.x += this.pasteOffset
      clone.transform.y += this.pasteOffset
      targetLayer.objects.push(clone)
      newIds.push(clone.id)
    }
    this.showToast('已粘贴 ' + this.clipboard.length + ' 个对象', 'paste', 'success')
  }

  pasteInPlace(): void {
    if (this.clipboard.length === 0) {
      this.showToast('剪贴板为空', 'info', 'info')
      return
    }
    const layers = this.fusionStore.getCurrentLayers()
    if (layers.length === 0) return
    const targetLayer = layers[0]
    for (const src of this.clipboard) {
      const clone = JSON.parse(JSON.stringify(src)) as SceneObject
      clone.id = 'obj_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 7)
      targetLayer.objects.push(clone)
    }
    this.showToast('已原位粘贴 ' + this.clipboard.length + ' 个对象', 'paste', 'success')
  }

  deleteSelected(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) {
      this.showToast('请先选择对象', 'info', 'info')
      return
    }
    for (const obj of sel) {
      this.fusionStore.removeObjectById(obj.id)
    }
    this.showToast('已删除', 'delete', 'warning')
  }

  /* ═════════ 选择 ═════════ */

  selectAll(): void {
    this.fusionStore.selectAllObjects()
    this.showToast('已全选', 'select_all', 'info')
  }

  deselect(): void {
    this.lastDeselectedIds = this.fusionStore.getSelectedObjects().map((o: SceneObject) => o.id)
    this.fusionStore.selectObject(null)
    this.showToast('已取消选择', 'deselect', 'info')
  }

  reselect(): void {
    if (this.lastDeselectedIds.length === 0) {
      this.showToast('没有可恢复的选择', 'info', 'info')
      return
    }
    this.fusionStore.selectObject(null)
    for (let i = 0; i < this.lastDeselectedIds.length; i++) {
      this.fusionStore.selectObject(this.lastDeselectedIds[i])
    }
    this.showToast('已重新选择 ' + this.lastDeselectedIds.length + ' 个对象', 'reselect', 'info')
  }

  invertSelection(): void {
    const layers = this.fusionStore.getCurrentLayers()
    if (layers.length === 0) return
    const allIds: string[] = []
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        allIds.push(layers[i].objects[j].id)
      }
    }
    const selIds = this.fusionStore.getSelectedObjects().map((o: SceneObject) => o.id)
    this.fusionStore.selectObject(null)
    for (let i = 0; i < allIds.length; i++) {
      if (selIds.indexOf(allIds[i]) < 0) {
        this.fusionStore.selectObject(allIds[i])
      }
    }
    this.showToast('已反选', 'invert', 'info')
  }

  /* ═════════ 对象 - 编组 ═════════ */

  group(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length < 2) {
      this.showToast('请选择至少两个对象', 'info', 'info')
      return
    }
    this.fusionStore.groupObjects(sel.map((o: SceneObject) => o.id))
    this.showToast('已编组', 'group', 'success')
  }

  ungroup(): void {
    const obj = this.getSelectedObject()
    if (!obj || obj.type !== 'group') {
      this.showToast('请选择一个编组', 'info', 'info')
      return
    }
    this.fusionStore.ungroupObjects(obj.id)
    this.showToast('已解组', 'ungroup', 'success')
  }

  /* ═════════ 对象 - 排列 ═════════ */

  bringToFront(): void {
    const obj = this.getSelectedObject()
    if (!obj) return
    this.fusionStore.bringToFront(obj.id)
    this.showToast('已移到顶层', 'arrow_up', 'info')
  }

  bringForward(): void {
    const obj = this.getSelectedObject()
    if (!obj) return
    this.fusionStore.bringForward(obj.id)
    this.showToast('已上移一层', 'arrow_up', 'info')
  }

  sendBackward(): void {
    const obj = this.getSelectedObject()
    if (!obj) return
    this.fusionStore.sendBackward(obj.id)
    this.showToast('已下移一层', 'arrow_down', 'info')
  }

  sendToBack(): void {
    const obj = this.getSelectedObject()
    if (!obj) return
    this.fusionStore.sendToBack(obj.id)
    this.showToast('已移到底层', 'arrow_down', 'info')
  }

  /* ═════════ 对象 - 图层操作 ═════════ */

  newLayer(): void {
    const doc = this.fusionStore.getDocument()
    addLayer(doc)
    this.showToast('已新建图层', 'plus', 'success')
  }

  duplicateLayer(): void {
    const obj = this.getSelectedObject()
    if (!obj) return
    this.fusionStore.duplicateObject(obj.id)
    this.showToast('已复制图层', 'copy', 'success')
  }

  mergeLayers(): void {
    const layers = this.fusionStore.getCurrentLayers()
    if (layers.length < 2) {
      this.showToast('至少需要 2 个图层', 'info', 'info')
      return
    }
    const target = layers[0]
    for (let i = layers.length - 1; i > 0; i--) {
      const upper = layers[i]
      for (let j = 0; j < upper.objects.length; j++) {
        target.objects.push(upper.objects[j])
      }
      upper.objects = []
    }
    this.showToast('已合并图层', 'merge', 'success')
  }

  /* ═════════ 对象 - 锁定/隐藏 ═════════ */

  lock(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) {
      this.showToast('请先选择对象', 'info', 'info')
      return
    }
    const layers = this.fusionStore.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        const o = layers[i].objects[j]
        for (let k = 0; k < sel.length; k++) {
          if (o.id === sel[k].id) {
            o.locked = !o.locked
          }
        }
      }
    }
    this.showToast('已切换锁定', 'lock', 'info')
  }

  unlockAll(): void {
    const layers = this.fusionStore.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        layers[i].objects[j].locked = false
      }
    }
    this.showToast('已全部解锁', 'unlock', 'info')
  }

  hide(): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length === 0) {
      this.showToast('请先选择对象', 'info', 'info')
      return
    }
    const layers = this.fusionStore.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        const o = layers[i].objects[j]
        for (let k = 0; k < sel.length; k++) {
          if (o.id === sel[k].id) {
            o.visible = !o.visible
          }
        }
      }
    }
    this.showToast('已切换显示', 'eye_off', 'info')
  }

  showAll(): void {
    const layers = this.fusionStore.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      for (let j = 0; j < layers[i].objects.length; j++) {
        layers[i].objects[j].visible = true
      }
    }
    this.showToast('已全部显示', 'eye', 'info')
  }

  /* ═════════ 对象 - 对齐 ═════════ */

  private alignObjects(mode: string): void {
    const sel = this.fusionStore.getSelectedObjects()
    if (sel.length < 2) {
      this.showToast('请选择至少 2 个对象', 'info', 'info')
      return
    }
    if (mode === 'left') {
      let minX = sel[0].transform.x
      for (let i = 1; i < sel.length; i++) {
        if (sel[i].transform.x < minX) minX = sel[i].transform.x
      }
      for (let i = 0; i < sel.length; i++) sel[i].transform.x = minX
    } else if (mode === 'right') {
      let maxX = sel[0].transform.x + sel[0].transform.width
      for (let i = 1; i < sel.length; i++) {
        const r = sel[i].transform.x + sel[i].transform.width
        if (r > maxX) maxX = r
      }
      for (let i = 0; i < sel.length; i++) sel[i].transform.x = maxX - sel[i].transform.width
    } else if (mode === 'centerH') {
      let sum = 0
      for (let i = 0; i < sel.length; i++) sum += sel[i].transform.x + sel[i].transform.width / 2
      const avg = sum / sel.length
      for (let i = 0; i < sel.length; i++) sel[i].transform.x = avg - sel[i].transform.width / 2
    } else if (mode === 'top') {
      let minY = sel[0].transform.y
      for (let i = 1; i < sel.length; i++) {
        if (sel[i].transform.y < minY) minY = sel[i].transform.y
      }
      for (let i = 0; i < sel.length; i++) sel[i].transform.y = minY
    } else if (mode === 'bottom') {
      let maxY = sel[0].transform.y + sel[0].transform.height
      for (let i = 1; i < sel.length; i++) {
        const b = sel[i].transform.y + sel[i].transform.height
        if (b > maxY) maxY = b
      }
      for (let i = 0; i < sel.length; i++) sel[i].transform.y = maxY - sel[i].transform.height
    } else if (mode === 'centerV') {
      let sum = 0
      for (let i = 0; i < sel.length; i++) sum += sel[i].transform.y + sel[i].transform.height / 2
      const avg = sum / sel.length
      for (let i = 0; i < sel.length; i++) sel[i].transform.y = avg - sel[i].transform.height / 2
    }
  }

  alignLeft(): void { this.alignObjects('left'); this.showToast('已左对齐', 'align', 'success') }
  alignCenterH(): void { this.alignObjects('centerH'); this.showToast('已水平居中', 'align', 'success') }
  alignRight(): void { this.alignObjects('right'); this.showToast('已右对齐', 'align', 'success') }
  alignTop(): void { this.alignObjects('top'); this.showToast('已顶对齐', 'align', 'success') }
  alignCenterV(): void { this.alignObjects('centerV'); this.showToast('已垂直居中', 'align', 'success') }
  alignBottom(): void { this.alignObjects('bottom'); this.showToast('已底对齐', 'align', 'success') }

  /* ═════════ 视图 ═════════ */

  zoomIn(): void {
    const zoom = AppStorage.get<number>('viewportZoom') ?? 1
    AppStorage.setOrCreate<number>('viewportZoom', Math.min(zoom * 1.25, 32))
    this.showToast(Math.round(AppStorage.get<number>('viewportZoom')! * 100) + '%', 'zoom_in', 'info')
  }

  zoomOut(): void {
    const zoom = AppStorage.get<number>('viewportZoom') ?? 1
    AppStorage.setOrCreate<number>('viewportZoom', Math.max(zoom / 1.25, 0.05))
    this.showToast(Math.round(AppStorage.get<number>('viewportZoom')! * 100) + '%', 'zoom_out', 'info')
  }

  zoomToFit(): void {
    AppStorage.setOrCreate<number>('viewportZoom', 1)
    this.showToast('已适配画布', 'fit', 'info')
  }

  zoomToActual(): void {
    AppStorage.setOrCreate<number>('viewportZoom', 1)
    this.showToast('100% 实际像素', 'actual', 'info')
  }

  toggleRuler(): void {
    const show = AppStorage.get<boolean>('showRuler') ?? false
    AppStorage.setOrCreate<boolean>('showRuler', !show)
    this.showToast(!show ? '已显示标尺' : '已隐藏标尺', 'ruler', 'info')
  }

  toggleGrid(): void {
    const show = AppStorage.get<boolean>('showGrid') ?? false
    AppStorage.setOrCreate<boolean>('showGrid', !show)
    this.showToast(!show ? '已显示网格' : '已隐藏网格', 'grid', 'info')
  }

  toggleSnap(): void {
    const show = AppStorage.get<boolean>('showSnap') ?? false
    AppStorage.setOrCreate<boolean>('showSnap', !show)
    this.showToast(!show ? '已开启吸附' : '已关闭吸附', 'snap', 'info')
  }

  toggleSmartGuides(): void {
    const show = AppStorage.get<boolean>('showSmartGuides') ?? false
    AppStorage.setOrCreate<boolean>('showSmartGuides', !show)
    this.showToast(!show ? '已显示智能参考线' : '已隐藏智能参考线', 'guides', 'info')
  }

  toggleTheme(): void {
    const current = AppStorage.get<string>('currentTheme') ?? 'light'
    const next = current === 'dark' ? 'light' : 'dark'
    AppStorage.setOrCreate<string>('currentTheme', next)
    this.showToast(next === 'dark' ? '已切换暗色模式' : '已切换亮色模式', 'theme', 'info')
  }

  togglePanels(): void {
    const show = AppStorage.get<boolean>('showPagesPanel') ?? true
    AppStorage.setOrCreate<boolean>('showPagesPanel', !show)
    AppStorage.setOrCreate<boolean>('showInspector', !show)
    this.showToast(!show ? '面板已显示' : '面板已隐藏', 'panels', 'info')
  }

  toggleHistory(): void {
    const show = AppStorage.get<boolean>('showHistoryPanel') ?? false
    AppStorage.setOrCreate<boolean>('showHistoryPanel', !show)
    this.showToast(!show ? '历史记录已显示' : '历史记录已隐藏', 'history', 'info')
  }

  toggleToolRail(): void {
    const show = AppStorage.get<boolean>('showToolRail') ?? true
    AppStorage.setOrCreate<boolean>('showToolRail', !show)
    this.showToast(!show ? '已显示工具轨' : '已隐藏工具轨', 'tool_rail', 'info')
  }

  toggleInspector(): void {
    const show = AppStorage.get<boolean>('showInspector') ?? true
    AppStorage.setOrCreate<boolean>('showInspector', !show)
    this.showToast(!show ? '已显示检查器' : '已隐藏检查器', 'inspector', 'info')
  }

  togglePagesPanel(): void {
    const show = AppStorage.get<boolean>('showPagesPanel') ?? true
    AppStorage.setOrCreate<boolean>('showPagesPanel', !show)
    this.showToast(!show ? '已显示页面面板' : '已隐藏页面面板', 'pages', 'info')
  }

  /* ═════════ 中文标签动作分发 ═════════ */

  handleActionByLabel(label: string): void {
    if (label === '默认文档' || label === 'newDefault') { this.newDocument('default'); return }
    if (label === '单页海报' || label === 'newPoster') { this.newDocument('poster'); return }
    if (label === '画册' || label === 'newAlbum') { this.newDocument('album'); return }
    if (label === '社交媒体' || label === 'newSocial') { this.newDocument('social'); return }
    if (label === '保存' || label === 'save') { this.save(); return }
    if (label === '另存为' || label === 'saveAs') { this.saveAs(); return }
    if (label === '保存副本' || label === 'saveCopy') { this.saveCopy(); return }
    if (label === '关闭' || label === 'close') { this.close(); return }
    if (label === '退出' || label === 'exit') { this.exit(); return }
    if (label === '文档设置' || label === 'documentSettings') { this.documentSettings(); return }
    if (label === '文件信息' || label === 'fileInfo') { this.fileInfo(); return }
    if (label === '导出为 PNG' || label === 'exportPng') { this.exportTo('png'); return }
    if (label === '导出为 JPEG' || label === '导出为 JPG' || label === 'exportJpg') { this.exportTo('jpeg'); return }
    if (label === '导出为 PDF' || label === 'exportPdf') { this.exportTo('pdf'); return }
    if (label === '导出为 SVG' || label === 'exportSvg') { this.exportTo('svg'); return }
    if (label === '导出为 WebP' || label === 'exportWebp') { this.exportTo('webp'); return }
    if (label === '撤销' || label === 'undo') { this.undo(); return }
    if (label === '重做' || label === 'redo') { this.redo(); return }
    if (label === '剪切' || label === 'cut') { this.cut(); return }
    if (label === '复制' || label === 'copy') { this.copy(); return }
    if (label === '粘贴' || label === 'paste') { this.paste(); return }
    if (label === '原位粘贴' || label === 'pasteInPlace') { this.pasteInPlace(); return }
    if (label === '清除' || label === 'delete' || label === 'deleteSelected') { this.deleteSelected(); return }
    if (label === '全部' || label === '全选' || label === 'selectAll') { this.selectAll(); return }
    if (label === '取消选择' || label === 'deselect') { this.deselect(); return }
    if (label === '重新选择' || label === 'reselect') { this.reselect(); return }
    if (label === '反选' || label === 'invertSelection') { this.invertSelection(); return }
    if (label === '编组' || label === 'group') { this.group(); return }
    if (label === '解组' || label === 'ungroup') { this.ungroup(); return }
    if (label === '上移一层' || label === 'bringForward') { this.bringForward(); return }
    if (label === '下移一层' || label === 'sendBackward') { this.sendBackward(); return }
    if (label === '移到顶层' || label === 'bringToFront') { this.bringToFront(); return }
    if (label === '移到底层' || label === 'sendToBack') { this.sendToBack(); return }
    if (label === '新建图层' || label === 'newLayer') { this.newLayer(); return }
    if (label === '复制图层' || label === 'duplicateLayer') { this.duplicateLayer(); return }
    if (label === '合并图层' || label === 'mergeLayers') { this.mergeLayers(); return }
    if (label === '锁定所选对象' || label === 'lock') { this.lock(); return }
    if (label === '解锁全部' || label === 'unlockAll') { this.unlockAll(); return }
    if (label === '隐藏所选' || label === 'hide') { this.hide(); return }
    if (label === '显示全部' || label === 'showAll') { this.showAll(); return }
    if (label === '左对齐' || label === 'alignLeft') { this.alignLeft(); return }
    if (label === '水平居中' || label === 'alignCenterH') { this.alignCenterH(); return }
    if (label === '右对齐' || label === 'alignRight') { this.alignRight(); return }
    if (label === '顶对齐' || label === 'alignTop') { this.alignTop(); return }
    if (label === '垂直居中' || label === 'alignCenterV') { this.alignCenterV(); return }
    if (label === '底对齐' || label === 'alignBottom') { this.alignBottom(); return }
    if (label === '放大' || label === 'zoomIn') { this.zoomIn(); return }
    if (label === '缩小' || label === 'zoomOut') { this.zoomOut(); return }
    if (label === '适配画布' || label === 'zoomToFit') { this.zoomToFit(); return }
    if (label === '实际像素' || label === 'zoomToActual') { this.zoomToActual(); return }
    if (label === '标尺' || label === 'toggleRuler') { this.toggleRuler(); return }
    if (label === '网格' || label === 'toggleGrid') { this.toggleGrid(); return }
    if (label === '智能参考线' || label === 'toggleSmartGuides') { this.toggleSmartGuides(); return }
    if (label === '隐藏面板' || label === 'togglePanels') { this.togglePanels(); return }
    if (label === '全屏' || label === 'toggleFullscreen') { this.showToast('全屏模式', 'fullscreen', 'info'); return }
    if (label === '工具轨' || label === 'toggleToolRail') { this.toggleToolRail(); return }
    if (label === '检查器' || label === 'toggleInspector') { this.toggleInspector(); return }
    if (label === '页面面板' || label === 'togglePagesPanel') { this.togglePagesPanel(); return }
    if (label === '历史记录' || label === 'toggleHistory') { this.toggleHistory(); return }
    this.showToast(label, 'info', 'info')
  }

  /* ═════════ 通用动作分发（英文/标识符） ═════════ */

  handleAction(action: string): void {
    this.handleActionByLabel(action)
  }
}
