import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useFusionDocumentStore } from './fusionDocument'

export interface PageData {
  id: string
  name: string
  isActive: boolean
  color?: string
}

export const useDocumentStore = defineStore('document', () => {
  // ─── Fusion DOM 桥接（单一数据源） ───
  const fusion = useFusionDocumentStore()

  // ─── Document meta（从 Fusion DOM 派生） ───
  const docName = computed(() => fusion.scene.name)
  const unsaved = computed(() => fusion.isDirty)
  const colorSpace = computed(() => {
    const cs = fusion.scene.colorSpace
    const map: Record<string, string> = {
      sRGB: 'sRGB IEC61966-2.1',
      AdobeRGB: 'Adobe RGB (1998)',
      DisplayP3: 'Display P3',
      CMYK: 'U.S. Web Coated (SWOP) v2',
    }
    return map[cs] ?? cs
  })
  const documentSize = computed(() => {
    const s = fusion.scene
    return `${s.canvasWidth} × ${s.canvasHeight} ${s.unit}`
  })

  // ─── Pages ───
  const pages = ref<PageData[]>([
    { id: '1', name: '封面', isActive: true, color: 'bg-[var(--color-primary)]' },
    { id: '2', name: '目录', isActive: false, color: 'bg-[#3B82F6]' },
    { id: '3', name: '内页', isActive: false, color: 'bg-[#F59E0B]' },
    { id: '4', name: '封底', isActive: false, color: 'bg-[#8B5CF6]' },
    { id: '5', name: '附录', isActive: false, color: 'bg-[#EC4899]' },
    { id: '6', name: '备注', isActive: false, color: 'bg-[#14B8A6]' },
  ])
  let pageCounter = 6

  const activePageIndex = computed(() => pages.value.findIndex(p => p.isActive))
  const pageInfo = computed(() => `${activePageIndex.value + 1} / ${pages.value.length} 页`)

  function switchPage(index: number) {
    pages.value.forEach((p, i) => (p.isActive = i === index))
  }

  function addPage() {
    pageCounter++
    pages.value.push({
      id: String(pageCounter),
      name: `页面 ${pageCounter}`,
      isActive: false,
      color: 'bg-[var(--color-primary)]',
    })
  }

  function duplicatePage(index: number) {
    const orig = pages.value[index]
    if (!orig) return
    pageCounter++
    pages.value.splice(index + 1, 0, {
      id: String(pageCounter),
      name: `${orig.name} 副本`,
      isActive: false,
      color: orig.color,
    })
  }

  function deletePage(index: number) {
    if (pages.value.length <= 1) return
    pages.value.splice(index, 1)
    if (pages.value[index]) {
      pages.value[index].isActive = true
    } else if (pages.value[index - 1]) {
      pages.value[index - 1].isActive = true
    }
  }

  function movePage(index: number, direction: number) {
    const target = index + direction
    if (target < 0 || target >= pages.value.length) return
    const arr = pages.value
    ;[arr[index], arr[target]] = [arr[target], arr[index]]
  }

  function renamePage(index: number, name: string) {
    if (pages.value[index]) pages.value[index].name = name
  }

  // ─── Zoom ───
  const zoomPercent = ref(100)
  const zoomStep = 10

  function zoomIn() {
    zoomPercent.value = Math.min(400, zoomPercent.value + zoomStep)
  }
  function zoomOut() {
    zoomPercent.value = Math.max(10, zoomPercent.value - zoomStep)
  }
  function zoomToFit() {
    zoomPercent.value = 100
  }
  function zoomToActual() {
    zoomPercent.value = 100
  }

  // ─── Ruler / Guidelines ───
  const showRuler = ref(true)
  function toggleRuler() {
    showRuler.value = !showRuler.value
  }

  // ─── Panels visibility ───
  const showPagesPanel = ref(true)
  const showInspector = ref(true)
  const showHistoryPanel = ref(true)

  // ─── Fusion DOM 桥接方法 ───
  const fusionInfo = computed(() => fusion.sceneInfo)
  const canUndo = computed(() => fusion.canUndo)
  const canRedo = computed(() => fusion.canRedo)

  function newDocument(params: Parameters<typeof fusion.newDocument>[0] = {}): void {
    fusion.newDocument(params)
  }

  function saveDocument(): string {
    return fusion.saveDocument()
  }

  function loadDocument(json: string): void {
    fusion.loadDocument(json)
  }

  function undo(): void {
    fusion.undo()
  }

  function redo(): void {
    fusion.redo()
  }

  return {
    docName, unsaved, colorSpace, documentSize,
    pages, activePageIndex, pageInfo,
    switchPage, addPage, duplicatePage, deletePage, movePage, renamePage,
    zoomPercent, zoomIn, zoomOut, zoomToFit, zoomToActual,
    showRuler, toggleRuler,
    showPagesPanel, showInspector, showHistoryPanel,
    // Fusion DOM 桥接
    fusion, fusionInfo, canUndo, canRedo,
    newDocument, saveDocument, loadDocument, undo, redo,
  }
})
