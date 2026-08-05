/**
 * ColorStore - 颜色状态管理
 *
 * 对应原型 src/stores/color.ts
 */
export class ColorStore {
  private static instance: ColorStore
  private _currentHex: string = '#3AC487'
  private _history: string[] = []

  private constructor() {}

  static getInstance(): ColorStore {
    if (!ColorStore.instance) {
      ColorStore.instance = new ColorStore()
    }
    return ColorStore.instance
  }

  get currentHex(): string {
    return this._currentHex
  }

  get history(): string[] {
    return this._history
  }

  setColor(hex: string): void {
    if (hex === this._currentHex) return
    // 加入历史（去重）
    const idx = this._history.indexOf(hex)
    if (idx >= 0) this._history.splice(idx, 1)
    this._history.unshift(hex)
    if (this._history.length > 16) this._history.length = 16
    this._currentHex = hex
    AppStorage.setOrCreate<string>('currentColor', hex)
  }
}
