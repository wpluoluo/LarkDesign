/**
 * 全局主题系统 store
 *
 * 提供多套预设主题，通过动态注入 CSS 变量实现整体视觉切换。
 * 主题：light（默认明亮）/ dark（温暖暗色）/ pro-black（专业暗黑）
 *       slate（石板灰冷色）/ sepia（暖纸阅读）
 */
import { defineStore } from 'pinia'
import { ref, computed, watch, onMounted } from 'vue'

export type ThemeId = 'light' | 'dark' | 'pro-black' | 'slate' | 'sepia'

export interface ThemeMeta {
  id: ThemeId
  name: string
  description: string
  swatch: string[] // 色板预览，用于 UI 展示
}

export interface ThemeDefinition {
  meta: ThemeMeta
  tokens: Record<string, string>
}

/** 主题元数据列表（UI 用） */
export const THEME_LIST: ThemeMeta[] = [
  {
    id: 'light',
    name: '明亮',
    description: '默认浅色主题，温暖中性',
    swatch: ['#FFFFFF', '#F3F5F7', '#34B87A', '#1C2026'],
  },
  {
    id: 'dark',
    name: '温暖暗色',
    description: '降低眼疲劳的深色主题',
    swatch: ['#1A1E22', '#131618', '#5CD4A2', '#E9EBED'],
  },
  {
    id: 'pro-black',
    name: '专业暗黑',
    description: '类 Figma 深色，中性冷调',
    swatch: ['#1E1E1E', '#0F0F0F', '#3DDC8C', '#E5E5E5'],
  },
  {
    id: 'slate',
    name: '石板灰',
    description: '冷色中性，类似 Linear',
    swatch: ['#F8FAFC', '#E2E8F0', '#34B87A', '#0F172A'],
  },
  {
    id: 'sepia',
    name: '暖纸阅读',
    description: '纸张色调，长时间阅读舒适',
    swatch: ['#F5EDDC', '#E8DCC4', '#7CB342', '#3D2F1F'],
  },
]

/** 各主题完整 CSS 变量定义 */
const THEME_TOKENS: Record<ThemeId, Record<string, string>> = {
  light: {
    '--color-primary': '#34B87A',
    '--color-primary-dark-900': '#0E5A3D',
    '--color-primary-dark-700': '#1A7D5A',
    '--color-primary-light-300': '#A3DFC4',
    '--color-primary-light-100': '#E4F7EE',
    '--color-info': '#4A8FE7',
    '--color-success': '#34B87A',
    '--color-warning': '#E8A33D',
    '--color-error': '#E55555',
    '--color-title': '#1C2026',
    '--color-body': '#333940',
    '--color-secondary': '#525B65',
    '--color-tertiary': '#636D78',
    '--color-muted': '#78828D',
    '--color-border': '#D9DDE2',
    '--color-border-light': '#E8EAED',
    '--color-panel': '#F8F9FA',
    '--color-bg': '#F3F5F7',
    '--color-white': '#FFFFFF',
    '--color-surface': '#FFFFFF',
    '--color-canvas-bg': '#E9EBEE',
    '--color-hover-bg': '#EFF8F4',
    '--color-focus-ring': '#34B87A',
    '--color-page': '#FFFFFF',
    '--color-ruler-bg': '#F8F9FA',
    '--color-ruler-border': '#D5D9DE',
    '--color-ruler-tick': '#CDD2D8',
    '--color-ruler-text': '#8D959E',
    '--color-ruler-corner': '#B4BAC2',
  },
  dark: {
    '--color-primary': '#34B87A',
    '--color-primary-dark-900': '#82DFB4',
    '--color-primary-dark-700': '#5CD4A2',
    '--color-primary-light-300': '#1A5A40',
    '--color-primary-light-100': '#0E3A28',
    '--color-info': '#5BA0F5',
    '--color-success': '#34B87A',
    '--color-warning': '#F0B453',
    '--color-error': '#FF6B6B',
    '--color-title': '#E9EBED',
    '--color-body': '#C5C9CE',
    '--color-secondary': '#9BA3AC',
    '--color-tertiary': '#7E8790',
    '--color-muted': '#68717A',
    '--color-border': '#383D44',
    '--color-border-light': '#2D3238',
    '--color-panel': '#1D2126',
    '--color-bg': '#131618',
    '--color-white': '#1A1E22',
    '--color-surface': '#1D2126',
    '--color-canvas-bg': '#0F1214',
    '--color-hover-bg': '#14352A',
    '--color-focus-ring': '#5CD4A2',
    '--color-page': '#FFFFFF',
    '--color-ruler-bg': '#1D2126',
    '--color-ruler-border': '#383D44',
    '--color-ruler-tick': '#484F57',
    '--color-ruler-text': '#68717A',
    '--color-ruler-corner': '#566069',
  },
  'pro-black': {
    '--color-primary': '#3DDC8C',
    '--color-primary-dark-900': '#7BEFB0',
    '--color-primary-dark-700': '#5FE39F',
    '--color-primary-light-300': '#1A4A30',
    '--color-primary-light-100': '#0E2A1C',
    '--color-info': '#4DA8FF',
    '--color-success': '#3DDC8C',
    '--color-warning': '#F0B453',
    '--color-error': '#FF6B6B',
    '--color-title': '#E5E5E5',
    '--color-body': '#B5B5B5',
    '--color-secondary': '#8A8A8A',
    '--color-tertiary': '#6E6E6E',
    '--color-muted': '#5A5A5A',
    '--color-border': '#3A3A3A',
    '--color-border-light': '#2A2A2A',
    '--color-panel': '#1A1A1A',
    '--color-bg': '#0F0F0F',
    '--color-white': '#1E1E1E',
    '--color-surface': '#1A1A1A',
    '--color-canvas-bg': '#0A0A0A',
    '--color-hover-bg': '#1A4A30',
    '--color-focus-ring': '#3DDC8C',
    '--color-page': '#1E1E1E',
    '--color-ruler-bg': '#1A1A1A',
    '--color-ruler-border': '#3A3A3A',
    '--color-ruler-tick': '#4A4A4A',
    '--color-ruler-text': '#6E6E6E',
    '--color-ruler-corner': '#5A5A5A',
  },
  slate: {
    '--color-primary': '#34B87A',
    '--color-primary-dark-900': '#A3DFC4',
    '--color-primary-dark-700': '#5CD4A2',
    '--color-primary-light-300': '#1A7D5A',
    '--color-primary-light-100': '#E4F7EE',
    '--color-info': '#3B82F6',
    '--color-success': '#34B87A',
    '--color-warning': '#F59E0B',
    '--color-error': '#EF4444',
    '--color-title': '#0F172A',
    '--color-body': '#334155',
    '--color-secondary': '#475569',
    '--color-tertiary': '#64748B',
    '--color-muted': '#94A3B8',
    '--color-border': '#E2E8F0',
    '--color-border-light': '#F1F5F9',
    '--color-panel': '#F8FAFC',
    '--color-bg': '#EDF2F7',
    '--color-white': '#FFFFFF',
    '--color-surface': '#FFFFFF',
    '--color-canvas-bg': '#E2E8F0',
    '--color-hover-bg': '#E4F7EE',
    '--color-focus-ring': '#34B87A',
    '--color-page': '#FFFFFF',
    '--color-ruler-bg': '#F8FAFC',
    '--color-ruler-border': '#E2E8F0',
    '--color-ruler-tick': '#CBD5E1',
    '--color-ruler-text': '#64748B',
    '--color-ruler-corner': '#94A3B8',
  },
  sepia: {
    '--color-primary': '#7CB342',
    '--color-primary-dark-900': '#AED581',
    '--color-primary-dark-700': '#9CCC65',
    '--color-primary-light-300': '#558B2F',
    '--color-primary-light-100': '#DCEDC8',
    '--color-info': '#6B8FA8',
    '--color-success': '#7CB342',
    '--color-warning': '#C28A55',
    '--color-error': '#B85450',
    '--color-title': '#3D2F1F',
    '--color-body': '#5A4632',
    '--color-secondary': '#7A604A',
    '--color-tertiary': '#9C8568',
    '--color-muted': '#B0967A',
    '--color-border': '#D4C5A0',
    '--color-border-light': '#E8DCC4',
    '--color-panel': '#F5EDDC',
    '--color-bg': '#EDE2C8',
    '--color-white': '#FAF4E5',
    '--color-surface': '#F5EDDC',
    '--color-canvas-bg': '#E8DCC4',
    '--color-hover-bg': '#F0E6CC',
    '--color-focus-ring': '#7CB342',
    '--color-page': '#FAF4E5',
    '--color-ruler-bg': '#F5EDDC',
    '--color-ruler-border': '#D4C5A0',
    '--color-ruler-tick': '#C8B68A',
    '--color-ruler-text': '#9C8568',
    '--color-ruler-corner': '#B0967A',
  },
}

const STORAGE_KEY = 'hds-theme'

export const useThemeStore = defineStore('theme', () => {
  // 当前主题 ID
  const currentThemeId = ref<ThemeId>('light')

  // 系统暗色偏好（首次加载时检测）
  const prefersDark = ref(false)

  // 是否跟随系统
  const followSystem = ref(false)

  // 当前主题元数据
  const currentTheme = computed(() =>
    THEME_LIST.find(t => t.id === currentThemeId.value) ?? THEME_LIST[0],
  )

  // 是否暗色类主题
  const isDark = computed(() =>
    ['dark', 'pro-black'].includes(currentThemeId.value),
  )

  /** 应用主题到 :root */
  function applyTheme(themeId: ThemeId) {
    const tokens = THEME_TOKENS[themeId]
    if (!tokens) return

    const root = document.documentElement

    // 清除其他主题的 class 标记
    root.classList.remove('dark', 'pro-black', 'slate', 'sepia', 'light')
    root.classList.add(themeId)

    // 注入 CSS 变量
    Object.entries(tokens).forEach(([key, value]) => {
      root.style.setProperty(key, value)
    })
  }

  /** 切换主题 */
  function setTheme(themeId: ThemeId) {
    currentThemeId.value = themeId
    followSystem.value = false
    applyTheme(themeId)
    persistTheme()
  }

  /** 切换跟随系统 */
  function setFollowSystem(follow: boolean) {
    followSystem.value = follow
    if (follow) {
      const sysDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      prefersDark.value = sysDark
      const targetTheme: ThemeId = sysDark ? 'dark' : 'light'
      currentThemeId.value = targetTheme
      applyTheme(targetTheme)
    } else {
      applyTheme(currentThemeId.value)
    }
    persistTheme()
  }

  /** 持久化主题选择 */
  function persistTheme() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        themeId: currentThemeId.value,
        followSystem: followSystem.value,
      }))
    } catch (err) {
      console.warn('[theme] persist failed:', err)
    }
  }

  /** 从 localStorage 恢复 */
  function restoreTheme() {
    try {
      const saved = localStorage.getItem(STORAGE_KEY)
      if (saved) {
        const parsed = JSON.parse(saved) as { themeId: ThemeId; followSystem: boolean }
        if (parsed.followSystem) {
          setFollowSystem(true)
        } else if (parsed.themeId) {
          setTheme(parsed.themeId)
        } else {
          applyTheme('light')
        }
      } else {
        // 首次访问，检测系统偏好
        const sysDark = window.matchMedia('(prefers-color-scheme: dark)').matches
        if (sysDark) {
          setTheme('dark')
        } else {
          applyTheme('light')
        }
      }
    } catch {
      applyTheme('light')
    }
  }

  /** 监听系统主题变化 */
  function bindSystemListener() {
    const mql = window.matchMedia('(prefers-color-scheme: dark)')
    const handler = (e: MediaQueryListEvent) => {
      prefersDark.value = e.matches
      if (followSystem.value) {
        const targetTheme: ThemeId = e.matches ? 'dark' : 'light'
        currentThemeId.value = targetTheme
        applyTheme(targetTheme)
      }
    }
    mql.addEventListener('change', handler)
  }

  return {
    currentThemeId,
    currentTheme,
    isDark,
    followSystem,
    prefersDark,
    themeList: THEME_LIST,
    setTheme,
    setFollowSystem,
    applyTheme,
    restoreTheme,
    bindSystemListener,
  }
})
