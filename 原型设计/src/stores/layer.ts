import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { BLEND_MODE_OPTIONS, getBlendModeLabel } from '../composables/layerBlendStore'

export interface LayerEffect {
  name: string
  icon: string
  active: boolean
}

export const useLayerStore = defineStore('layer', () => {
  const selectedElement = ref('')

  // 每个图层的混合模式
  const blendModes = ref<Record<string, string>>({
    '构想，让设计发生': 'normal',
    '正文段落': 'normal',
    'Image 01': 'multiply',
    'Green Shape': 'overlay',
    '装饰线': 'normal',
  })

  const currentBlendMode = computed(() => blendModes.value[selectedElement.value] ?? 'normal')
  const currentBlendLabel = computed(() => getBlendModeLabel(currentBlendMode.value))

  function setBlendMode(layerName: string, mode: string) {
    blendModes.value[layerName] = mode
  }

  function select(name: string) {
    selectedElement.value = name
  }

  function deselect() {
    selectedElement.value = ''
  }

  return {
    selectedElement, blendModes,
    currentBlendMode, currentBlendLabel,
    setBlendMode, select, deselect,
    BLEND_MODE_OPTIONS,
  }
})
