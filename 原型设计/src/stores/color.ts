/**
 * useColorStore - 全局色彩状态
 *
 * 维护当前选中色、最近使用色、常用色板。
 * 吸管工具通过此 store 写入取色结果。
 * ColorBar 通过此 store 读取并显示。
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useColorStore = defineStore('color', () => {
  // 当前选中色（hex）
  const currentHex = ref<string>('#3AC487')

  // 最近使用色（最多 12 个）
  const recentColors = ref<string[]>([
    '#3AC487', '#1F2329', '#FFFFFF', '#F3F4F6', '#E5E7EB', '#9CA3AF',
  ])

  // 常用色板
  const favoriteColors = ref<string[]>([
    '#3AC487', '#1F2329', '#FFFFFF', '#EF4444', '#F59E0B', '#3B82F6',
  ])

  /** 设置当前色，并加入最近使用列表 */
  function setColor(hex: string): void {
    const normalized = hex.toUpperCase()
    currentHex.value = normalized
    // 移除重复
    recentColors.value = recentColors.value.filter(c => c.toUpperCase() !== normalized)
    // 加入最前
    recentColors.value.unshift(normalized)
    // 限制 12 个
    if (recentColors.value.length > 12) recentColors.value = recentColors.value.slice(0, 12)
  }

  /** 加入常用色板 */
  function addFavorite(hex: string): void {
    const normalized = hex.toUpperCase()
    if (!favoriteColors.value.includes(normalized)) {
      favoriteColors.value.push(normalized)
    }
  }

  /** 移除常用色 */
  function removeFavorite(hex: string): void {
    const normalized = hex.toUpperCase()
    favoriteColors.value = favoriteColors.value.filter(c => c.toUpperCase() !== normalized)
  }

  return {
    // state
    currentHex,
    recentColors,
    favoriteColors,
    // actions
    setColor,
    addFavorite,
    removeFavorite,
  }
})
