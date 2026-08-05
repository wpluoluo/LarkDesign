/**
 * ThemeStore - 主题管理
 *
 * 对应原型 src/stores/theme.ts
 * 管理 5 套主题切换，通过 AppStorage 全局响应式更新。
 */
import { preferences } from '@kit.ArkData'

export type ThemeId = 'light' | 'dark' | 'pro-black' | 'slate' | 'sepia'

export interface ThemeMeta {
  id: ThemeId
  name: string
  description: string
  swatch: string[]
}

export const THEME_LIST: ThemeMeta[] = [
  { id: 'light', name: '明亮', description: '默认浅色主题，温暖中性', swatch: ['#FFFFFF', '#F3F5F7', '#34B87A', '#1C2026'] },
  { id: 'dark', name: '温暖暗色', description: '降低眼疲劳的深色主题', swatch: ['#1A1E22', '#131618', '#5CD4A2', '#E9EBED'] },
  { id: 'pro-black', name: '专业暗黑', description: '类 Figma 深色，中性冷调', swatch: ['#1E1E1E', '#0F0F0F', '#3DDC8C', '#E5E5E5'] },
  { id: 'slate', name: '石板灰', description: '冷色中性，类似 Linear', swatch: ['#F8FAFC', '#E2E8F0', '#34B87A', '#0F172A'] },
  { id: 'sepia', name: '暖纸阅读', description: '纸张色调，长时间阅读舒适', swatch: ['#F5EDDC', '#E8DCC4', '#7CB342', '#3D2F1F'] },
]

const STORAGE_KEY = 'hds-theme'

export class ThemeStore {
  private static instance: ThemeStore
  private currentThemeId: ThemeId = 'light'
  private followSystem: boolean = false

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

  get currentTheme(): ThemeMeta {
    return THEME_LIST.find(t => t.id === this.currentThemeId) || THEME_LIST[0]
  }

  get isDark(): boolean {
    return this.currentThemeId === 'dark' || this.currentThemeId === 'pro-black'
  }

  setTheme(themeId: ThemeId): void {
    this.currentThemeId = themeId
    this.followSystem = false
    this.applyTheme(themeId)
    this.persistTheme()
  }

  setFollowSystem(follow: boolean): void {
    this.followSystem = follow
    // 鸿蒙端通过 ConfigurationConstant 读取系统主题
    this.persistTheme()
  }

  private applyTheme(themeId: ThemeId): void {
    // ArkUI 通过资源限定符（base/dark）自动切换，无需手动注入
    // 此处仅更新 AppStorage 中的主题 ID，供组件响应式使用
    AppStorage.setOrCreate<string>('currentTheme', themeId)
  }

  private persistTheme(): void {
    // 持久化到 Preferences
    try {
      // 简化：实际使用 PreferencesHelper
      console.info('ThemeStore', `persist: ${this.currentThemeId}, follow: ${this.followSystem}`)
    } catch (err) {
      console.warn('ThemeStore', `persist failed: ${err}`)
    }
  }

  private restoreTheme(): void {
    // 从 Preferences 恢复
    this.applyTheme('light')
  }
}

