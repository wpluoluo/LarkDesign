/**
 * ToolStore - 工具状态管理
 *
 * 对应原型 src/stores/tool.ts
 */
export type ToolId =
  | 'select' | 'rectangle' | 'ellipse' | 'text'
  | 'eyedropper' | 'hand' | 'zoom'

export interface ToolOption {
  id: string
  label: string
  value: string | number | boolean
}

export class ToolStore {
  private static instance: ToolStore
  private _currentTool: ToolId = 'select'
  private _options: Map<string, ToolOption> = new Map()

  private constructor() {}

  static getInstance(): ToolStore {
    if (!ToolStore.instance) {
      ToolStore.instance = new ToolStore()
    }
    return ToolStore.instance
  }

  get currentTool(): ToolId {
    return this._currentTool
  }

  setTool(tool: ToolId): void {
    this._currentTool = tool
    AppStorage.setOrCreate<string>('currentTool', tool)
  }

  getOption(key: string): ToolOption | undefined {
    return this._options.get(key)
  }

  setOption(key: string, value: string | number | boolean): void {
    this._options.set(key, { id: key, label: key, value })
  }

  /** 各工具对应的快捷键 */
  static getShortcut(tool: ToolId): string {
    const map: Record<ToolId, string> = {
      'select': 'V',
      'rectangle': 'R',
      'ellipse': 'O',
      'text': 'T',
      'eyedropper': 'I',
      'hand': 'H',
      'zoom': 'Z',
    }
    return map[tool]
  }
}
