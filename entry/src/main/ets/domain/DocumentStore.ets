import { FusionDocumentStore } from './FusionDocumentStore'

export interface PageData {
  id: string
  name: string
  isActive: boolean
  color: string
}

export class DocumentStore {
  private static instance: DocumentStore
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  // 视图状态
  zoomPercent: number = 100
  showRuler: boolean = true
  showPagesPanel: boolean = true
  showInspector: boolean = true
  showHistoryPanel: boolean = false

  // 当前工具
  currentTool: string = 'select'

  // 页面管理
  pages: PageData[] = [
    { id: '1', name: '封面', isActive: true, color: '#3AC487' },
    { id: '2', name: '目录', isActive: false, color: '#3B82F6' },
    { id: '3', name: '内页', isActive: false, color: '#F59E0B' },
    { id: '4', name: '封底', isActive: false, color: '#8B5CF6' },
    { id: '5', name: '附录', isActive: false, color: '#EC4899' },
    { id: '6', name: '备注', isActive: false, color: '#14B8A6' },
  ]
  private pageCounter: number = 6

  private constructor() {}

  static getInstance(): DocumentStore {
    if (!DocumentStore.instance) {
      DocumentStore.instance = new DocumentStore()
    }
    return DocumentStore.instance
  }

  // ─── 文档元数据（从 FusionDocumentStore 派生） ───

  get docName(): string {
    const scene = this.fusionStore.getScene()
    return scene.name
  }

  get documentSize(): string {
    const scene = this.fusionStore.getScene()
    return scene.canvasWidth + ' × ' + scene.canvasHeight + ' ' + scene.unit
  }

  get fusionInfo(): string {
    const info = this.fusionStore.getSceneInfo()
    return info.layerCount + ' 层 / ' + info.objectCount + ' 对象 · ' + info.canvasSize
  }

  get canUndo(): boolean {
    return this.fusionStore.canUndo()
  }

  get canRedo(): boolean {
    return this.fusionStore.canRedo()
  }

  // ─── 页面管理 ───

  get activePageIndex(): number {
    for (let i = 0; i < this.pages.length; i++) {
      if (this.pages[i].isActive) return i
    }
    return 0
  }

  get pageInfo(): string {
    return (this.activePageIndex + 1) + ' / ' + this.pages.length + ' 页'
  }

  switchPage(index: number): void {
    for (let i = 0; i < this.pages.length; i++) {
      this.pages[i].isActive = i === index
    }
  }

  addPage(): void {
    this.pageCounter++
    this.pages.push({
      id: String(this.pageCounter),
      name: '页面 ' + this.pageCounter,
      isActive: false,
      color: '#3AC487',
    })
  }

  duplicatePage(index: number): void {
    if (index < 0 || index >= this.pages.length) return
    const orig = this.pages[index]
    this.pageCounter++
    const newPage: PageData = {
      id: String(this.pageCounter),
      name: orig.name + ' 副本',
      isActive: false,
      color: orig.color,
    }
    this.pages.splice(index + 1, 0, newPage)
  }

  deletePage(index: number): void {
    if (this.pages.length <= 1) return
    this.pages.splice(index, 1)
    if (index < this.pages.length) {
      this.pages[index].isActive = true
    } else if (index - 1 >= 0) {
      this.pages[index - 1].isActive = true
    }
  }

  movePage(index: number, direction: number): void {
    const target = index + direction
    if (target < 0 || target >= this.pages.length) return
    const temp = this.pages[index]
    this.pages[index] = this.pages[target]
    this.pages[target] = temp
  }

  renamePage(index: number, name: string): void {
    if (index >= 0 && index < this.pages.length) {
      this.pages[index].name = name
    }
  }

  // ─── 缩放 ───

  zoomIn(): void {
    this.zoomPercent = Math.min(400, Math.round(this.zoomPercent * 1.2))
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
  }

  zoomOut(): void {
    this.zoomPercent = Math.max(10, Math.round(this.zoomPercent / 1.2))
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
  }

  setZoom(percent: number): void {
    this.zoomPercent = Math.max(10, Math.min(400, percent))
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
  }

  zoomToFit(): void {
    this.zoomPercent = 100
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
  }

  zoomToActual(): void {
    this.zoomPercent = 100
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
  }

  // ─── 面板显隐 ───

  toggleRuler(): void {
    this.showRuler = !this.showRuler
    AppStorage.setOrCreate<boolean>('showRuler', this.showRuler)
  }

  togglePagesPanel(): void {
    this.showPagesPanel = !this.showPagesPanel
    AppStorage.setOrCreate<boolean>('showPagesPanel', this.showPagesPanel)
  }

  toggleInspector(): void {
    this.showInspector = !this.showInspector
    AppStorage.setOrCreate<boolean>('showInspector', this.showInspector)
  }

  toggleHistoryPanel(): void {
    this.showHistoryPanel = !this.showHistoryPanel
    AppStorage.setOrCreate<boolean>('showHistoryPanel', this.showHistoryPanel)
  }

  setTool(tool: string): void {
    this.currentTool = tool
    AppStorage.setOrCreate<string>('currentTool', this.currentTool)
  }

  // ─── 初始化 ───

  init(): void {
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
    AppStorage.setOrCreate<boolean>('showRuler', this.showRuler)
    AppStorage.setOrCreate<boolean>('showPagesPanel', this.showPagesPanel)
    AppStorage.setOrCreate<boolean>('showInspector', this.showInspector)
    AppStorage.setOrCreate<boolean>('showHistoryPanel', this.showHistoryPanel)
    AppStorage.setOrCreate<string>('currentTool', this.currentTool)
  }
}