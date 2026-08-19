export type ThemeId = 'light' | 'dark' | 'pro-black' | 'slate' | 'sepia'

export interface ThemeMeta {
  id: ThemeId
  name: string
  description: string
  swatch: string[]
}

export interface ThemeDefinition {
  meta: ThemeMeta
  tokens: Map<string, string>
}

export const THEME_LIST: ThemeMeta[] = [
  { id: 'light', name: '明亮', description: '默认浅色主题，温暖中性', swatch: ['#FFFFFF', '#F3F5F7', '#34B87A', '#1C2026'] },
  { id: 'dark', name: '温暖暗色', description: '降低眼疲劳的深色主题', swatch: ['#1A1E22', '#131618', '#5CD4A2', '#E9EBED'] },
  { id: 'pro-black', name: '专业暗黑', description: '类 Figma 深色，中性冷调', swatch: ['#1E1E1E', '#0F0F0F', '#3DDC8C', '#E5E5E5'] },
  { id: 'slate', name: '石板灰', description: '冷色中性，类似 Linear', swatch: ['#F8FAFC', '#E2E8F0', '#34B87A', '#0F172A'] },
  { id: 'sepia', name: '暖纸阅读', description: '纸张色调，长时间阅读舒适', swatch: ['#F5EDDC', '#E8DCC4', '#7CB342', '#3D2F1F'] },
]

class ThemeTokenBuilder {
  static buildTokens(themeId: ThemeId): Map<string, string> {
    const m = new Map<string, string>()
    if (themeId === 'light') {
      m.set('--color-primary', '#34B87A')
      m.set('--color-primary-dark-900', '#0E5A3D')
      m.set('--color-primary-dark-700', '#1A7D5A')
      m.set('--color-primary-light-300', '#A3DFC4')
      m.set('--color-primary-light-100', '#E4F7EE')
      m.set('--color-info', '#4A8FE7')
      m.set('--color-success', '#34B87A')
      m.set('--color-warning', '#E8A33D')
      m.set('--color-error', '#E55555')
      m.set('--color-title', '#1C2026')
      m.set('--color-body', '#333940')
      m.set('--color-secondary', '#525B65')
      m.set('--color-tertiary', '#636D78')
      m.set('--color-muted', '#78828D')
      m.set('--color-border', '#D9DDE2')
      m.set('--color-border-light', '#E8EAED')
      m.set('--color-panel', '#F8F9FA')
      m.set('--color-bg', '#F3F5F7')
      m.set('--color-white', '#FFFFFF')
      m.set('--color-surface', '#FFFFFF')
      m.set('--color-canvas-bg', '#E9EBEE')
      m.set('--color-hover-bg', '#EFF8F4')
      m.set('--color-focus-ring', '#34B87A')
      m.set('--color-page', '#FFFFFF')
      m.set('--color-ruler-bg', '#F8F9FA')
      m.set('--color-ruler-border', '#D5D9DE')
      m.set('--color-ruler-tick', '#CDD2D8')
      m.set('--color-ruler-text', '#8D959E')
      m.set('--color-ruler-corner', '#B4BAC2')
    } else if (themeId === 'dark') {
      m.set('--color-primary', '#34B87A')
      m.set('--color-primary-dark-900', '#82DFB4')
      m.set('--color-primary-dark-700', '#5CD4A2')
      m.set('--color-primary-light-300', '#1A5A40')
      m.set('--color-primary-light-100', '#0E3A28')
      m.set('--color-info', '#5BA0F5')
      m.set('--color-success', '#34B87A')
      m.set('--color-warning', '#F0B453')
      m.set('--color-error', '#FF6B6B')
      m.set('--color-title', '#E9EBED')
      m.set('--color-body', '#C5C9CE')
      m.set('--color-secondary', '#9BA3AC')
      m.set('--color-tertiary', '#7E8790')
      m.set('--color-muted', '#68717A')
      m.set('--color-border', '#383D44')
      m.set('--color-border-light', '#2D3238')
      m.set('--color-panel', '#1D2126')
      m.set('--color-bg', '#131618')
      m.set('--color-white', '#1A1E22')
      m.set('--color-surface', '#1D2126')
      m.set('--color-canvas-bg', '#0F1214')
      m.set('--color-hover-bg', '#14352A')
      m.set('--color-focus-ring', '#5CD4A2')
      m.set('--color-page', '#FFFFFF')
      m.set('--color-ruler-bg', '#1D2126')
      m.set('--color-ruler-border', '#383D44')
      m.set('--color-ruler-tick', '#484F57')
      m.set('--color-ruler-text', '#68717A')
      m.set('--color-ruler-corner', '#566069')
    } else if (themeId === 'pro-black') {
      m.set('--color-primary', '#3DDC8C')
      m.set('--color-primary-dark-900', '#7BEFB0')
      m.set('--color-primary-dark-700', '#5FE39F')
      m.set('--color-primary-light-300', '#1A4A30')
      m.set('--color-primary-light-100', '#0E2A1C')
      m.set('--color-info', '#4DA8FF')
      m.set('--color-success', '#3DDC8C')
      m.set('--color-warning', '#F0B453')
      m.set('--color-error', '#FF6B6B')
      m.set('--color-title', '#E5E5E5')
      m.set('--color-body', '#B5B5B5')
      m.set('--color-secondary', '#8A8A8A')
      m.set('--color-tertiary', '#6E6E6E')
      m.set('--color-muted', '#5A5A5A')
      m.set('--color-border', '#3A3A3A')
      m.set('--color-border-light', '#2A2A2A')
      m.set('--color-panel', '#1A1A1A')
      m.set('--color-bg', '#0F0F0F')
      m.set('--color-white', '#1E1E1E')
      m.set('--color-surface', '#1A1A1A')
      m.set('--color-canvas-bg', '#0A0A0A')
      m.set('--color-hover-bg', '#1A4A30')
      m.set('--color-focus-ring', '#3DDC8C')
      m.set('--color-page', '#1E1E1E')
      m.set('--color-ruler-bg', '#1A1A1A')
      m.set('--color-ruler-border', '#3A3A3A')
      m.set('--color-ruler-tick', '#4A4A4A')
      m.set('--color-ruler-text', '#6E6E6E')
      m.set('--color-ruler-corner', '#5A5A5A')
    } else if (themeId === 'slate') {
      m.set('--color-primary', '#34B87A')
      m.set('--color-primary-dark-900', '#A3DFC4')
      m.set('--color-primary-dark-700', '#5CD4A2')
      m.set('--color-primary-light-300', '#1A7D5A')
      m.set('--color-primary-light-100', '#E4F7EE')
      m.set('--color-info', '#3B82F6')
      m.set('--color-success', '#34B87A')
      m.set('--color-warning', '#F59E0B')
      m.set('--color-error', '#EF4444')
      m.set('--color-title', '#0F172A')
      m.set('--color-body', '#334155')
      m.set('--color-secondary', '#475569')
      m.set('--color-tertiary', '#64748B')
      m.set('--color-muted', '#94A3B8')
      m.set('--color-border', '#E2E8F0')
      m.set('--color-border-light', '#F1F5F9')
      m.set('--color-panel', '#F8FAFC')
      m.set('--color-bg', '#EDF2F7')
      m.set('--color-white', '#FFFFFF')
      m.set('--color-surface', '#FFFFFF')
      m.set('--color-canvas-bg', '#E2E8F0')
      m.set('--color-hover-bg', '#E4F7EE')
      m.set('--color-focus-ring', '#34B87A')
      m.set('--color-page', '#FFFFFF')
      m.set('--color-ruler-bg', '#F8FAFC')
      m.set('--color-ruler-border', '#E2E8F0')
      m.set('--color-ruler-tick', '#CBD5E1')
      m.set('--color-ruler-text', '#64748B')
      m.set('--color-ruler-corner', '#94A3B8')
    } else if (themeId === 'sepia') {
      m.set('--color-primary', '#7CB342')
      m.set('--color-primary-dark-900', '#AED581')
      m.set('--color-primary-dark-700', '#9CCC65')
      m.set('--color-primary-light-300', '#558B2F')
      m.set('--color-primary-light-100', '#DCEDC8')
      m.set('--color-info', '#6B8FA8')
      m.set('--color-success', '#7CB342')
      m.set('--color-warning', '#C28A55')
      m.set('--color-error', '#B85450')
      m.set('--color-title', '#3D2F1F')
      m.set('--color-body', '#5A4632')
      m.set('--color-secondary', '#7A604A')
      m.set('--color-tertiary', '#9C8568')
      m.set('--color-muted', '#B0967A')
      m.set('--color-border', '#D4C5A0')
      m.set('--color-border-light', '#E8DCC4')
      m.set('--color-panel', '#F5EDDC')
      m.set('--color-bg', '#EDE2C8')
      m.set('--color-white', '#FAF4E5')
      m.set('--color-surface', '#F5EDDC')
      m.set('--color-canvas-bg', '#E8DCC4')
      m.set('--color-hover-bg', '#F0E6CC')
      m.set('--color-focus-ring', '#7CB342')
      m.set('--color-page', '#FAF4E5')
      m.set('--color-ruler-bg', '#F5EDDC')
      m.set('--color-ruler-border', '#D4C5A0')
      m.set('--color-ruler-tick', '#C8B68A')
      m.set('--color-ruler-text', '#9C8568')
      m.set('--color-ruler-corner', '#B0967A')
    }
    return m
  }
}

export function getThemeTokens(themeId: ThemeId): Map<string, string> {
  return ThemeTokenBuilder.buildTokens(themeId)
}

const STORAGE_KEY = 'hds-theme'

export class ThemeStore {
  private static instance: ThemeStore
  private _currentThemeId: ThemeId = 'light'
  private _followSystem: boolean = false
  private _prefersDark: boolean = false

  private constructor() {}

  static getInstance(): ThemeStore {
    if (!ThemeStore.instance) {
      ThemeStore.instance = new ThemeStore()
    }
    return ThemeStore.instance
  }

  init(): void {
    this.restoreTheme()
  }

  get currentThemeId(): ThemeId {
    return this._currentThemeId
  }

  get currentTheme(): ThemeMeta {
    for (let i = 0; i < THEME_LIST.length; i++) {
      if (THEME_LIST[i].id === this._currentThemeId) return THEME_LIST[i]
    }
    return THEME_LIST[0]
  }

  get isDark(): boolean {
    return this._currentThemeId === 'dark' || this._currentThemeId === 'pro-black'
  }

  get followSystem(): boolean {
    return this._followSystem
  }

  get prefersDark(): boolean {
    return this._prefersDark
  }

  applyTheme(themeId: ThemeId): void {
    AppStorage.setOrCreate<string>('currentTheme', themeId)
    AppStorage.setOrCreate<boolean>('isDark', themeId === 'dark' || themeId === 'pro-black')
  }

  setTheme(themeId: ThemeId): void {
    this._currentThemeId = themeId
    this._followSystem = false
    this.applyTheme(themeId)
    this.persistTheme()
  }

  setFollowSystem(follow: boolean): void {
    this._followSystem = follow
    if (follow) {
      const sysDark = this._prefersDark
      const targetTheme: ThemeId = sysDark ? 'dark' : 'light'
      this._currentThemeId = targetTheme
      this.applyTheme(targetTheme)
    } else {
      this.applyTheme(this._currentThemeId)
    }
    this.persistTheme()
  }

  persistTheme(): void {
    try {
      console.info('ThemeStore', 'persist: ' + this._currentThemeId + ', follow: ' + this._followSystem)
    } catch (err) {
      console.warn('ThemeStore', 'persist failed: ' + err)
    }
  }

  restoreTheme(): void {
    try {
      this.applyTheme('light')
    } catch {
      this.applyTheme('light')
    }
  }

  bindSystemListener(): void {
    console.info('ThemeStore', 'bindSystemListener - system theme change detection')
  }
}