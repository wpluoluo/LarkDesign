import { reactive } from 'vue'

export interface LayerBlendState {
  [layerName: string]: string
}

export const layerBlendModes = reactive<LayerBlendState>({
  '构想，让设计发生': 'normal',
  '正文段落': 'normal',
  'Image 01': 'multiply',
  'Green Shape': 'overlay',
  '色相/饱和度': 'color',
  'Background': 'normal',
  '纯色填充': 'screen',
  '智能对象': 'normal',
  '组 1': 'normal',
})

export const BLEND_MODE_OPTIONS = [
  { value: 'normal', label: '正常' },
  { value: 'multiply', label: '正片叠底' },
  { value: 'screen', label: '滤色' },
  { value: 'overlay', label: '叠加' },
  { value: 'darken', label: '变暗' },
  { value: 'lighten', label: '变亮' },
  { value: 'color-dodge', label: '颜色减淡' },
  { value: 'color-burn', label: '颜色加深' },
  { value: 'hard-light', label: '强光' },
  { value: 'soft-light', label: '柔光' },
  { value: 'difference', label: '差值' },
  { value: 'exclusion', label: '排除' },
  { value: 'hue', label: '色相' },
  { value: 'saturation', label: '饱和度' },
  { value: 'color', label: '颜色' },
  { value: 'luminosity', label: '明度' },
]

export function getBlendModeLabel(value: string): string {
  const found = BLEND_MODE_OPTIONS.find(o => o.value === value)
  return found ? found.label : '正常'
}