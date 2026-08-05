import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export interface ToolItemData {
  name: string
  icon: string
  shortcut?: string
}

export interface ToolGroupData {
  id: string
  icon: string
  label: string
  active: boolean
  activeTool: string
  tools: ToolItemData[]
}

export const useToolStore = defineStore('tool', () => {
  const toolGroups = ref<ToolGroupData[]>([
    { id: 'select', icon: 'fa-arrow-pointer', label: '选择', active: true, activeTool: '选择/移动', tools: [
      { name: '选择/移动', icon: 'fa-arrow-pointer', shortcut: 'V' },
      { name: '直接选择', icon: 'fa-arrow-trend-up', shortcut: 'A' },
      { name: '魔棒', icon: 'fa-wand-magic-sparkles', shortcut: 'W' },
    ]},
    { id: 'lasso', icon: 'fa-draw-polygon', label: '套索', active: false, activeTool: '套索', tools: [
      { name: '套索', icon: 'fa-draw-polygon', shortcut: 'L' },
      { name: '多边形套索', icon: 'fa-vector-square', shortcut: 'L' },
      { name: '磁性套索', icon: 'fa-magnet', shortcut: 'L' },
    ]},
    { id: 'crop', icon: 'fa-crop', label: '裁剪', active: false, activeTool: '裁剪', tools: [
      { name: '裁剪', icon: 'fa-crop', shortcut: 'C' },
      { name: '透视裁剪', icon: 'fa-crop-simple', shortcut: 'C' },
      { name: '切片', icon: 'fa-scissors', shortcut: 'C' },
      { name: '切片选择', icon: 'fa-hand-pointer', shortcut: 'C' },
    ]},
    { id: 'brush', icon: 'fa-paintbrush', label: '画笔', active: false, activeTool: '画笔', tools: [
      { name: '画笔', icon: 'fa-paintbrush', shortcut: 'B' },
      { name: '铅笔', icon: 'fa-pencil', shortcut: 'N' },
      { name: '颜色替换', icon: 'fa-spray-can-sparkles', shortcut: 'B' },
      { name: '混合器画笔', icon: 'fa-brush', shortcut: 'B' },
      { name: '历史记录画笔', icon: 'fa-clock-rotate-left', shortcut: 'Y' },
      { name: '历史记录艺术画笔', icon: 'fa-paintbrush', shortcut: 'Y' },
    ]},
    { id: 'eraser', icon: 'fa-eraser', label: '橡皮擦', active: false, activeTool: '橡皮擦', tools: [
      { name: '橡皮擦', icon: 'fa-eraser', shortcut: 'E' },
      { name: '背景橡皮擦', icon: 'fa-eraser', shortcut: 'E' },
      { name: '魔术橡皮擦', icon: 'fa-wand-magic', shortcut: 'E' },
    ]},
    { id: 'fill', icon: 'fa-fill-drip', label: '填充', active: false, activeTool: '渐变', tools: [
      { name: '渐变', icon: 'fa-fill-drip', shortcut: 'G' },
      { name: '油漆桶', icon: 'fa-bucket', shortcut: 'G' },
    ]},
    { id: 'vector', icon: 'fa-pen-nib', label: '矢量', active: false, activeTool: '钢笔', tools: [
      { name: '钢笔', icon: 'fa-pen-nib', shortcut: 'P' },
      { name: '自由钢笔', icon: 'fa-pen', shortcut: 'P' },
      { name: '添加锚点', icon: 'fa-plus', shortcut: 'P' },
      { name: '删除锚点', icon: 'fa-minus', shortcut: 'P' },
      { name: '转换点', icon: 'fa-arrow-right-arrow-left', shortcut: 'P' },
    ]},
    { id: 'text', icon: 'fa-font', label: '文字', active: false, activeTool: '文字', tools: [
      { name: '文字', icon: 'fa-font', shortcut: 'T' },
      { name: '垂直文字', icon: 'fa-i-cursor', shortcut: 'T' },
      { name: '直排文字蒙版', icon: 'fa-mask', shortcut: 'T' },
      { name: '横排文字蒙版', icon: 'fa-font', shortcut: 'T' },
      { name: '路径文字', icon: 'fa-text-width', shortcut: 'T' },
    ]},
    { id: 'shape', icon: 'fa-shapes', label: '形状', active: false, activeTool: '矩形', tools: [
      { name: '矩形', icon: 'fa-square', shortcut: 'U' },
      { name: '圆角矩形', icon: 'fa-square-full', shortcut: 'U' },
      { name: '椭圆', icon: 'fa-circle', shortcut: 'U' },
      { name: '多边形', icon: 'fa-draw-polygon', shortcut: 'U' },
      { name: '直线', icon: 'fa-slash', shortcut: 'U' },
      { name: '自定形状', icon: 'fa-star', shortcut: 'U' },
    ]},
    { id: 'retouch', icon: 'fa-stamp', label: '修饰', active: false, activeTool: '仿制图章', tools: [
      { name: '仿制图章', icon: 'fa-stamp', shortcut: 'S' },
      { name: '图案图章', icon: 'fa-paint-roller', shortcut: 'S' },
      { name: '污点修复画笔', icon: 'fa-bandage', shortcut: 'J' },
      { name: '修复画笔', icon: 'fa-brush', shortcut: 'J' },
      { name: '修补', icon: 'fa-arrows-to-circle', shortcut: 'J' },
      { name: '内容感知移动', icon: 'fa-arrows-up-down-left-right', shortcut: 'J' },
    ]},
    { id: 'fx', icon: 'fa-droplet', label: '效果', active: false, activeTool: '模糊', tools: [
      { name: '模糊', icon: 'fa-droplet' },
      { name: '锐化', icon: 'fa-bolt' },
      { name: '涂抹', icon: 'fa-hand-back-fist' },
    ]},
    { id: 'tone', icon: 'fa-sun', label: '色调', active: false, activeTool: '减淡', tools: [
      { name: '减淡', icon: 'fa-sun', shortcut: 'O' },
      { name: '加深', icon: 'fa-moon', shortcut: 'O' },
      { name: '海绵', icon: 'fa-spray-can', shortcut: 'O' },
    ]},
    { id: 'tool', icon: 'fa-eye-dropper', label: '取色', active: false, activeTool: '吸管', tools: [
      { name: '吸管', icon: 'fa-eye-dropper', shortcut: 'I' },
      { name: '颜色取样器', icon: 'fa-eye-dropper', shortcut: 'I' },
      { name: '标尺', icon: 'fa-ruler', shortcut: 'K' },
      { name: '注释', icon: 'fa-note-sticky', shortcut: 'N' },
    ]},
    { id: 'navigate', icon: 'fa-hand', label: '导航', active: false, activeTool: '抓手', tools: [
      { name: '抓手', icon: 'fa-hand', shortcut: 'H' },
      { name: '旋转视图', icon: 'fa-rotate', shortcut: 'R' },
      { name: '缩放', icon: 'fa-magnifying-glass-plus', shortcut: 'Z' },
    ]},
  ])

  const activeGroup = computed(() => toolGroups.value.find(g => g.active))
  const activeToolName = computed(() => activeGroup.value?.activeTool ?? '')

  function activateGroup(groupId: string) {
    toolGroups.value.forEach(g => (g.active = g.id === groupId))
  }

  function selectTool(groupId: string, toolName: string) {
    const g = toolGroups.value.find(g => g.id === groupId)
    if (g) {
      g.activeTool = toolName
      activateGroup(groupId)
    }
  }

  return { toolGroups, activeGroup, activeToolName, activateGroup, selectTool }
})
