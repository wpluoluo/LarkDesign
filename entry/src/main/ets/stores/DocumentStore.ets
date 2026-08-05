/**
 * DocumentStore - 文档状态管理
 *
 * 对应原型 src/stores/document.ts + fusionDocument.ts
 * 管理缩放、面板显隐、当前工具等 UI 状态。
 */
export class DocumentStore {
  private static instance: DocumentStore

  // 视图状态
  zoomPercent: number = 100
  showRuler: boolean = true
  showPagesPanel: boolean = true
  showInspector: boolean = true
  showHistoryPanel: boolean = false

  // 当前工具
  currentTool: string = 'select'

  private constructor() {}

  static getInstance(): DocumentStore {
    if (!DocumentStore.instance) {
      DocumentStore.instance = new DocumentStore()
    }
    return DocumentStore.instance
  }

  init(): void {
    // 初始化 UI 状态到 AppStorage
    AppStorage.setOrCreate<number>('zoomPercent', this.zoomPercent)
    AppStorage.setOrCreate<boolean>('showRuler', this.showRuler)
    AppStorage.setOrCreate<boolean>('showPagesPanel', this.showPagesPanel)
    AppStorage.setOrCreate<boolean>('showInspector', this.showInspector)
    AppStorage.setOrCreate<boolean>('showHistoryPanel', this.showHistoryPanel)
    AppStorage.setOrCreate<string>('currentTool', this.currentTool)
  }

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

  setTool(tool: string): void {
    this.currentTool = tool
    AppStorage.setOrCreate<string>('currentTool', this.currentTool)
  }
}
