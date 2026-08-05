/**
 * useMenuActions - 菜单动作分发器
 *
 * 将菜单项的 label 映射到具体的业务动作。
 * 优先实现文件/编辑/对象/视图菜单的核心功能，
 * 绑定到 Fusion DOM store、document store、layer store、toast store。
 * 未实现的菜单项降级为 Toast 提示。
 */
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useDocumentStore } from '../stores/document'
import { useToastStore } from '../stores/toast'
import { useLayerStore } from '../stores/layer'
import { downloadHdsFile, exportDocument, deepClone } from '../fusion'
import type { SceneObject } from '../types'

/** 内部剪贴板：保存复制的对象快照 */
let clipboard: SceneObject[] = []
/** 原位粘贴偏移量 */
let pasteOffset = 0

export function useMenuActions() {
  const fusion = useFusionDocumentStore()
  const doc = useDocumentStore()
  const toast = useToastStore()
  const layer = useLayerStore()

  /** 文档操作：需要选中图层时获取当前选中图层 ID */
  function currentLayerId(): string | null {
    return fusion.selectedLayerId ?? fusion.layers[0]?.id ?? null
  }

  /** 选中对象数量 */
  function selectedCount(): number {
    return fusion.selectedObjectIds.length
  }

  /** 生成唯一 ID */
  function genId(prefix: string): string {
    return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`
  }

  /** 粘贴剪贴板对象到指定图层，位置偏移 dx/dy */
  function pasteObjects(layerId: string, dx: number, dy: number): void {
    if (clipboard.length === 0) return
    fusion.pushHistory('粘贴对象')
    const newIds: string[] = []
    clipboard.forEach(src => {
      const clone = deepClone(src)
      clone.id = genId('obj')
      clone.transform.x += dx
      clone.transform.y += dy
      // 通过 newObject 添加（避免直接 mutate doc 结构）
      const layerObj = fusion.layers.find(l => l.id === layerId)
      if (layerObj) {
        layerObj.objects.push(clone)
        newIds.push(clone.id)
      }
    })
    // 选中刚粘贴的对象
    fusion.selectLayer(layerId)
    fusion.selectedObjectIds = newIds
  }

  /** 记录上次取消选择的对象 ID（用于"重新选择"） */
  let lastDeselectedIds: string[] = []
  /** 包装 fusion.deselectAll，记录被取消选中的 ID */
  function recordDeselect(): void {
    lastDeselectedIds = [...fusion.selectedObjectIds]
    fusion.deselectAll()
  }

  // ─── 动作表（label → handler） ───
  const actions: Record<string, () => void> = {
    /* ═════════ 文件 ═════════ */
    '默认文档': () => {
      fusion.newDocument({ canvasWidth: 595, canvasHeight: 842, name: '未命名.hds' })
      toast.show('已创建默认文档', 'fa-file', 'success')
    },
    '单页海报': () => {
      fusion.newDocument({ canvasWidth: 420, canvasHeight: 595, name: '海报.hds' })
      toast.show('已创建海报文档', 'fa-image', 'success')
    },
    '画册': () => {
      fusion.newDocument({ canvasWidth: 595, canvasHeight: 842, name: '画册.hds' })
      toast.show('已创建画册文档', 'fa-book', 'success')
    },
    '社交媒体': () => {
      fusion.newDocument({ canvasWidth: 1080, canvasHeight: 1080, name: '社交媒体.hds', unit: 'px' })
      toast.show('已创建社交媒体文档', 'fa-share-nodes', 'success')
    },
    '保存': () => {
      const json = fusion.saveDocument()
      try {
        downloadHdsFile(fusion.doc, fusion.scene.name)
        toast.show(`已保存 · ${fusion.scene.name}`, 'fa-floppy-disk', 'success')
      } catch {
        toast.show('保存失败', 'fa-triangle-exclamation', 'warning')
      }
      void json
    },
    '另存为': () => {
      try {
        downloadHdsFile(fusion.doc, `${fusion.scene.name.replace('.hds', '')}_副本.hds`)
        toast.show('已另存为副本', 'fa-copy', 'success')
      } catch {
        toast.show('另存失败', 'fa-triangle-exclamation', 'warning')
      }
    },
    '保存副本': () => {
      try {
        downloadHdsFile(fusion.doc, `${fusion.scene.name.replace('.hds', '')}_备份.hds`)
        toast.show('已保存副本', 'fa-clone', 'success')
      } catch {
        toast.show('保存副本失败', 'fa-triangle-exclamation', 'warning')
      }
    },
    '关闭': () => {
      if (fusion.isDirty) {
        toast.show('文档有未保存更改，请先保存', 'fa-triangle-exclamation', 'warning')
        return
      }
      fusion.newDocument({ canvasWidth: 595, canvasHeight: 842, name: '未命名.hds' })
      toast.show('已关闭并新建文档', 'fa-xmark', 'info')
    },
    '退出': () => {
      toast.show('请手动关闭浏览器标签页以退出', 'fa-right-from-bracket', 'info')
    },
    '文档设置': () => {
      toast.show(`文档 · ${fusion.scene.canvasWidth}×${fusion.scene.canvasHeight} ${fusion.scene.unit}`, 'fa-gear', 'info')
    },
    '文件信息': () => {
      const info = fusion.sceneInfo
      toast.show(`${info.layerCount} 层 / ${info.objectCount} 对象 · ${info.canvasSize}`, 'fa-circle-info', 'info')
    },

    /* ═════════ 编辑 - 撤销/重做 ═════════ */
    '撤销': () => {
      if (fusion.canUndo) {
        fusion.undo()
        toast.show('已撤销', 'fa-rotate-left', 'info')
      } else {
        toast.show('无可撤销操作', 'fa-circle-info', 'info')
      }
    },
    '重做': () => {
      if (fusion.canRedo) {
        fusion.redo()
        toast.show('已重做', 'fa-rotate-right', 'info')
      } else {
        toast.show('无可重做操作', 'fa-circle-info', 'info')
      }
    },

    /* ═════════ 编辑 - 剪贴板 ═════════ */
    '剪切': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        // 保存到内部剪贴板
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          clipboard = fusion.selectedObjectIds
            .map(oid => layerObj.objects.find(o => o.id === oid))
            .filter((o): o is SceneObject => !!o)
            .map(o => deepClone(o))
        }
        fusion.selectedObjectIds.forEach(oid => fusion.deleteObject(lid, oid))
        pasteOffset = 0
        toast.show(`已剪切 ${clipboard.length} 个对象`, 'fa-scissors', 'success')
      }
    },
    '复制': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          clipboard = fusion.selectedObjectIds
            .map(oid => layerObj.objects.find(o => o.id === oid))
            .filter((o): o is SceneObject => !!o)
            .map(o => deepClone(o))
          // 尝试写入浏览器剪贴板（文本形式：JSON）
          try {
            navigator.clipboard?.writeText(JSON.stringify({
              source: 'HDS',
              objects: clipboard,
            })).catch(() => {})
          } catch { /* 忽略权限错误 */ }
          pasteOffset = 0
          toast.show(`已复制 ${clipboard.length} 个对象`, 'fa-copy', 'success')
        }
      }
    },
    '粘贴': () => {
      if (clipboard.length === 0) {
        toast.show('剪贴板为空', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (!lid) {
        const newLayer = fusion.newLayer()
        pasteObjects(newLayer.id, 20 + pasteOffset, 20 + pasteOffset)
      } else {
        pasteObjects(lid, 20 + pasteOffset, 20 + pasteOffset)
      }
      pasteOffset += 10
      toast.show(`已粘贴 ${clipboard.length} 个对象`, 'fa-paste', 'success')
    },
    '原位粘贴': () => {
      if (clipboard.length === 0) {
        toast.show('剪贴板为空', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId() ?? fusion.newLayer().id
      pasteObjects(lid, 0, 0)
      toast.show(`已原位粘贴 ${clipboard.length} 个对象`, 'fa-paste', 'success')
    },
    '清除': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        fusion.selectedObjectIds.forEach(oid => fusion.deleteObject(lid, oid))
        toast.show('已清除', 'fa-trash', 'warning')
      }
    },
    '自由变换': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      // 切换到选择工具并选中对象（用户可拖拽 handle 进行变换）
      toast.show('已激活自由变换，拖拽 handle 即可缩放/旋转', 'fa-up-right-and-down-left-from-center', 'info')
    },

    /* ═════════ 选择 ═════════ */
    '全部': () => {
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          layerObj.objects.forEach(o => fusion.selectObject(o.id, true))
          toast.show(`已全选 ${layerObj.objects.length} 个对象`, 'fa-object-group', 'info')
        }
      }
    },
    '全选': () => actions['全部'](),
    '取消选择': () => {
      recordDeselect()
      layer.deselect()
      toast.show('已取消选择', 'fa-xmark', 'info')
    },
    '重新选择': () => {
      if (lastDeselectedIds.length === 0) {
        toast.show('没有可恢复的选择', 'fa-circle-info', 'info')
        return
      }
      fusion.selectedObjectIds = [...lastDeselectedIds]
      toast.show(`已重新选择 ${lastDeselectedIds.length} 个对象`, 'fa-rotate', 'info')
    },
    '反选': () => {
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          const inverted = layerObj.objects.filter(o => !fusion.selectedObjectIds.includes(o.id)).map(o => o.id)
          fusion.selectedObjectIds = inverted
          toast.show(`已反选 ${inverted.length} 个对象`, 'fa-arrows-left-right', 'info')
        }
      }
    },

    /* ═════════ 对象 - 编组 ═════════ */
    '编组': () => {
      if (selectedCount() < 2) {
        toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const group = fusion.groupSelected(lid)
        if (group) toast.show('已编组', 'fa-object-group', 'success')
      }
    },
    '解组': () => {
      if (selectedCount() !== 1) {
        toast.show('请选择一个组', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const gid = fusion.selectedObjectIds[0]
        fusion.ungroupSelected(lid, gid)
        toast.show('已解组', 'fa-object-ungroup', 'success')
      }
    },

    /* ═════════ 对象 - 排列 ═════════ */
    '上移一层': () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx >= 0 && idx < fusion.layers.length - 1) {
        fusion.reorderLayer(idx, idx + 1)
        toast.show('已上移一层', 'fa-arrow-up', 'success')
      }
    },
    '下移一层': () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx > 0) {
        fusion.reorderLayer(idx, idx - 1)
        toast.show('已下移一层', 'fa-arrow-down', 'success')
      }
    },
    '移到顶层': () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx >= 0 && idx < fusion.layers.length - 1) {
        fusion.reorderLayer(idx, fusion.layers.length - 1)
        toast.show('已移到顶层', 'fa-arrow-up-to-line', 'success')
      }
    },
    '移到底层': () => {
      const lid = currentLayerId()
      if (!lid) return
      const idx = fusion.layers.findIndex(l => l.id === lid)
      if (idx > 0) {
        fusion.reorderLayer(idx, 0)
        toast.show('已移到底层', 'fa-arrow-down-to-line', 'success')
      }
    },

    /* ═════════ 对象 - 图层操作 ═════════ */
    '新建图层': () => {
      fusion.newLayer()
      toast.show('已新建图层', 'fa-plus', 'success')
    },
    '复制图层': () => {
      const lid = currentLayerId()
      if (lid) {
        fusion.cloneLayer(lid)
        toast.show('已复制图层', 'fa-copy', 'success')
      }
    },
    '合并图层': () => {
      if (fusion.layers.length < 2) {
        toast.show('至少需要 2 个图层', 'fa-circle-info', 'info')
        return
      }
      // 合并所有可见图层到最底层（向下合并）
      fusion.pushHistory('合并图层')
      const layers = fusion.layers
      // 从顶到底合并到底层
      const target = layers[0]
      for (let i = layers.length - 1; i > 0; i--) {
        const upper = layers[i]
        // 把上层对象全部移到底层
        upper.objects.forEach(o => target.objects.push(o))
        upper.objects = []
      }
      // 移除空图层（除底层外）
      const emptyLayers = layers.filter((l, i) => i > 0 && l.objects.length === 0)
      emptyLayers.forEach(l => {
        const idx = layers.findIndex(x => x.id === l.id)
        if (idx > 0) {
          // 直接删除：调用 store 内部方法会重复 pushHistory，所以直接修改 doc
          fusion.doc.scene.children.splice(idx, 1)
        }
      })
      fusion.selectLayer(target.id)
      toast.show(`已合并 ${layers.length} 个图层`, 'fa-layer-group', 'success')
    },

    /* ═════════ 对象 - 锁定/隐藏 ═════════ */
    '锁定所选对象': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          fusion.pushHistory('锁定对象')
          fusion.selectedObjectIds.forEach(oid => {
            const o = layerObj.objects.find(x => x.id === oid)
            if (o) o.locked = !o.locked
          })
          toast.show('已切换锁定', 'fa-lock', 'info')
        }
      }
    },
    '解锁全部': () => {
      fusion.pushHistory('解锁全部')
      fusion.layers.forEach(l => l.objects.forEach(o => (o.locked = false)))
      toast.show('已全部解锁', 'fa-lock-open', 'info')
    },
    '隐藏所选': () => {
      if (selectedCount() === 0) {
        toast.show('请先选择对象', 'fa-circle-info', 'info')
        return
      }
      const lid = currentLayerId()
      if (lid) {
        const layerObj = fusion.layers.find(l => l.id === lid)
        if (layerObj) {
          fusion.pushHistory('隐藏对象')
          fusion.selectedObjectIds.forEach(oid => {
            const o = layerObj.objects.find(x => x.id === oid)
            if (o) o.visible = !o.visible
          })
          toast.show('已切换显示', 'fa-eye-slash', 'info')
        }
      }
    },
    '显示全部': () => {
      fusion.pushHistory('显示全部')
      fusion.layers.forEach(l => l.objects.forEach(o => (o.visible = true)))
      toast.show('已全部显示', 'fa-eye', 'info')
    },

    /* ═════════ 对象 - 对齐 ═════════ */
    '左对齐': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('left')
      toast.show('已左对齐', 'fa-align-left', 'success')
    },
    '水平居中': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('centerH')
      toast.show('已水平居中', 'fa-align-center', 'success')
    },
    '右对齐': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('right')
      toast.show('已右对齐', 'fa-align-right', 'success')
    },
    '顶对齐': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('top')
      toast.show('已顶对齐', 'fa-align-justify', 'success')
    },
    '垂直居中': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('centerV')
      toast.show('已垂直居中', 'fa-align-center', 'success')
    },
    '底对齐': () => {
      if (selectedCount() < 2) { toast.show('请选择至少 2 个对象', 'fa-circle-info', 'info'); return }
      alignObjects('bottom')
      toast.show('已底对齐', 'fa-align-justify', 'success')
    },

    /* ═════════ 视图 - 缩放 ═════════ */
    '放大': () => {
      doc.zoomIn()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-plus', 'info')
    },
    '缩小': () => {
      doc.zoomOut()
      toast.show(`${doc.zoomPercent}%`, 'fa-magnifying-glass-minus', 'info')
    },
    '适配画布': () => {
      doc.zoomToFit()
      toast.show('已适配画布', 'fa-expand', 'info')
    },
    '实际像素': () => {
      doc.zoomToActual()
      toast.show('100% 实际像素', 'fa-eye', 'info')
    },
    '打印尺寸': () => {
      doc.zoomToFit()
      toast.show('打印尺寸', 'fa-print', 'info')
    },

    /* ═════════ 视图 - 显示 ═════════ */
    '标尺': () => {
      doc.toggleRuler()
      toast.show(doc.showRuler ? '已显示标尺' : '已隐藏标尺', 'fa-ruler', 'info')
    },
    '网格': () => {
      ;(doc as any).showGrid = !((doc as any).showGrid)
      toast.show((doc as any).showGrid ? '已显示网格' : '已隐藏网格', 'fa-border-all', 'info')
    },
    '参考线': () => {
      doc.toggleRuler()
      toast.show(doc.showRuler ? '已显示参考线' : '已隐藏参考线', 'fa-ruler', 'info')
    },
    '智能参考线': () => {
      ;(doc as any).showSmartGuides = !((doc as any).showSmartGuides)
      toast.show((doc as any).showSmartGuides ? '已显示智能参考线' : '已隐藏智能参考线', 'fa-magnet', 'info')
    },
    '隐藏面板': () => {
      doc.showPagesPanel = !doc.showPagesPanel
      doc.showInspector = !doc.showInspector
      doc.showHistoryPanel = !doc.showHistoryPanel
      toast.show('已切换面板显示', 'fa-eye-slash', 'info')
    },

    /* ═════════ 窗口 - 面板 ═════════ */
    '工具轨': () => {
      ;(doc as any).showToolRail = !((doc as any).showToolRail ?? true)
      toast.show((doc as any).showToolRail ? '已显示工具轨' : '已隐藏工具轨', 'fa-wrench', 'info')
    },
    '检查器': () => {
      doc.showInspector = !doc.showInspector
      toast.show(doc.showInspector ? '已显示检查器' : '已隐藏检查器', 'fa-sliders', 'info')
    },
    '页面面板': () => {
      doc.showPagesPanel = !doc.showPagesPanel
      toast.show(doc.showPagesPanel ? '已显示页面面板' : '已隐藏页面面板', 'fa-file', 'info')
    },
    '历史记录': () => {
      doc.showHistoryPanel = !doc.showHistoryPanel
      toast.show(doc.showHistoryPanel ? '已显示历史记录' : '已隐藏历史记录', 'fa-clock-rotate-left', 'info')
    },

    /* ═════════ 导出（接入 fusion exporter） ═════════ */
    '导出为 PNG': async () => {
      toast.show('正在导出 PNG...', 'fa-file-image', 'info')
      const result = await exportDocument(fusion.doc, { format: 'png' })
      toast.show(result.message, result.ok ? 'fa-file-image' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
    },
    '导出为 PDF': async () => {
      toast.show('正在导出 PDF...', 'fa-file-pdf', 'info')
      const result = await exportDocument(fusion.doc, { format: 'pdf' })
      toast.show(result.message, result.ok ? 'fa-file-pdf' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
    },
    '导出为 SVG': async () => {
      toast.show('正在导出 SVG...', 'fa-file-code', 'info')
      const result = await exportDocument(fusion.doc, { format: 'svg' })
      toast.show(result.message, result.ok ? 'fa-file-code' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
    },
    '导出为 WebP': async () => {
      toast.show('正在导出 WebP...', 'fa-file-image', 'info')
      const result = await exportDocument(fusion.doc, { format: 'webp' })
      toast.show(result.message, result.ok ? 'fa-file-image' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
    },
    '导出为 JPG': async () => {
      toast.show('正在导出 JPG...', 'fa-file-image', 'info')
      const result = await exportDocument(fusion.doc, { format: 'jpeg' })
      toast.show(result.message, result.ok ? 'fa-file-image' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
    },
  }

  /** 对齐选中对象 */
  function alignObjects(mode: 'left' | 'centerH' | 'right' | 'top' | 'centerV' | 'bottom'): void {
    const lid = currentLayerId()
    if (!lid) return
    const layerObj = fusion.layers.find(l => l.id === lid)
    if (!layerObj) return
    const objs = layerObj.objects.filter(o => fusion.selectedObjectIds.includes(o.id))
    if (objs.length < 2) return
    fusion.pushHistory(`对齐 ${mode}`)
    switch (mode) {
      case 'left': {
        const minX = Math.min(...objs.map(o => o.transform.x))
        objs.forEach(o => (o.transform.x = minX))
        break
      }
      case 'right': {
        const maxX = Math.max(...objs.map(o => o.transform.x + o.transform.width))
        objs.forEach(o => (o.transform.x = maxX - o.transform.width))
        break
      }
      case 'centerH': {
        const cs = objs.map(o => o.transform.x + o.transform.width / 2)
        const avg = cs.reduce((a, b) => a + b, 0) / cs.length
        objs.forEach(o => (o.transform.x = avg - o.transform.width / 2))
        break
      }
      case 'top': {
        const minY = Math.min(...objs.map(o => o.transform.y))
        objs.forEach(o => (o.transform.y = minY))
        break
      }
      case 'bottom': {
        const maxY = Math.max(...objs.map(o => o.transform.y + o.transform.height))
        objs.forEach(o => (o.transform.y = maxY - o.transform.height))
        break
      }
      case 'centerV': {
        const cs = objs.map(o => o.transform.y + o.transform.height / 2)
        const avg = cs.reduce((a, b) => a + b, 0) / cs.length
        objs.forEach(o => (o.transform.y = avg - o.transform.height / 2))
        break
      }
    }
  }

  /** 执行菜单动作 */
  function execute(label: string): void {
    const action = actions[label]
    if (action) {
      action()
    } else {
      // 未实现的动作：显示 Toast 提示
      toast.show(label, 'fa-circle-info', 'info')
    }
  }

  return { execute }
}
