export class ColorStore {
  private static instance: ColorStore
  private _currentHex: string = '#3AC487'
  private _recentColors: string[] = [
    '#3AC487', '#1F2329', '#FFFFFF', '#F3F4F6', '#E5E7EB', '#9CA3AF',
  ]
  private _favoriteColors: string[] = [
    '#3AC487', '#1F2329', '#FFFFFF', '#EF4444', '#F59E0B', '#3B82F6',
  ]

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

  get recentColors(): string[] {
    return this._recentColors
  }

  get favoriteColors(): string[] {
    return this._favoriteColors
  }

  get history(): string[] {
    return this._recentColors
  }

  setColor(hex: string): void {
    const normalized = hex.toUpperCase()
    if (normalized === this._currentHex) return
    this._recentColors = this._recentColors.filter(c => c.toUpperCase() !== normalized)
    this._recentColors.unshift(normalized)
    if (this._recentColors.length > 12) {
      this._recentColors = this._recentColors.slice(0, 12)
    }
    this._currentHex = normalized
    AppStorage.setOrCreate<string>('currentColor', normalized)
  }

  addFavorite(hex: string): void {
    const normalized = hex.toUpperCase()
    let found = false
    for (let i = 0; i < this._favoriteColors.length; i++) {
      if (this._favoriteColors[i].toUpperCase() === normalized) {
        found = true
        break
      }
    }
    if (!found) {
      this._favoriteColors.push(normalized)
    }
  }

  removeFavorite(hex: string): void {
    const normalized = hex.toUpperCase()
    const result: string[] = []
    for (let i = 0; i < this._favoriteColors.length; i++) {
      if (this._favoriteColors[i].toUpperCase() !== normalized) {
        result.push(this._favoriteColors[i])
      }
    }
    this._favoriteColors = result
  }
}