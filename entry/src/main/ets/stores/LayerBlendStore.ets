/**
 * LayerBlendStore - 混合模式状态管理
 *
 * 对应原型 src/composables/layerBlendStore.ts
 * 提供混合模式选项列表、标签查询和图层级混合模式快捷切换。
 */
import { FusionDocumentStore } from './FusionDocumentStore'

export interface BlendModeOption {
  value: string
  label: string
}

export const BLEND_MODE_OPTIONS: BlendModeOption[] = [
  { value: 'normal', label: '正常' } as BlendModeOption,
  { value: 'multiply', label: '正片叠底' } as BlendModeOption,
  { value: 'screen', label: '滤色' } as BlendModeOption,
  { value: 'overlay', label: '叠加' } as BlendModeOption,
  { value: 'darken', label: '变暗' } as BlendModeOption,
  { value: 'lighten', label: '变亮' } as BlendModeOption,
  { value: 'color-dodge', label: '颜色减淡' } as BlendModeOption,
  { value: 'color-burn', label: '颜色加深' } as BlendModeOption,
  { value: 'hard-light', label: '强光' } as BlendModeOption,
  { value: 'soft-light', label: '柔光' } as BlendModeOption,
  { value: 'difference', label: '差值' } as BlendModeOption,
  { value: 'exclusion', label: '排除' } as BlendModeOption,
  { value: 'hue', label: '色相' } as BlendModeOption,
  { value: 'saturation', label: '饱和度' } as BlendModeOption,
  { value: 'color', label: '颜色' } as BlendModeOption,
  { value: 'luminosity', label: '明度' } as BlendModeOption,
]

export function getBlendModeLabel(value: string): string {
  for (let i = 0; i < BLEND_MODE_OPTIONS.length; i++) {
    if (BLEND_MODE_OPTIONS[i].value === value) {
      return BLEND_MODE_OPTIONS[i].label
    }
  }
  return '正常'
}

export class LayerBlendStore {
  private static instance: LayerBlendStore
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  private constructor() {}

  static getInstance(): LayerBlendStore {
    if (!LayerBlendStore.instance) {
      LayerBlendStore.instance = new LayerBlendStore()
    }
    return LayerBlendStore.instance
  }

  setLayerBlendMode(layerId: string, blendMode: string): void {
    const layers = this.fusionStore.getCurrentLayers()
    for (let i = 0; i < layers.length; i++) {
      if (layers[i].id === layerId) {
        layers[i].blendMode = blendMode
        this.fusionStore.pushHistory('修改混合模式')
        return
      }
    }
  }
}