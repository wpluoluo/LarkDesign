<template>
  <div class="flex flex-row justify-between items-center h-[28px] bg-[var(--color-panel)] border-t border-[var(--color-border)] px-[12px] shrink-0">
    <div class="flex flex-row justify-start items-center gap-[16px]">
      <!-- 主题切换 -->
      <ThemePicker />
      <!-- 色彩空间 - 可点击修改 -->
      <div class="flex flex-row items-center gap-[4px] cursor-pointer hover:bg-[var(--color-border-light)] px-[4px] py-[2px] rounded-[3px] relative" @click.stop="togglePopup('colorSpace', $event)" title="点击修改色彩空间">
        <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-tertiary)]">{{ localColorSpace }}</span>
        <i class="fa-solid fa-chevron-down text-[6px] text-[var(--color-muted)]"></i>
      </div>
      <!-- 文档尺寸 - 可点击修改 -->
      <div class="flex flex-row items-center gap-[4px] cursor-pointer hover:bg-[var(--color-border-light)] px-[4px] py-[2px] rounded-[3px] relative" @click.stop="togglePopup('documentSize', $event)" title="点击修改文档尺寸">
        <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-tertiary)]">{{ localDocumentSize }}</span>
        <i class="fa-solid fa-chevron-down text-[6px] text-[var(--color-muted)]"></i>
      </div>
      <!-- 页码 - 可点击跳转 -->
      <div class="flex flex-row items-center gap-[4px] cursor-pointer hover:bg-[var(--color-border-light)] px-[4px] py-[2px] rounded-[3px] relative" @click.stop="togglePopup('pageInfo', $event)" title="点击跳转页面">
        <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-tertiary)]">{{ localPageInfo }}</span>
        <i class="fa-solid fa-chevron-down text-[6px] text-[var(--color-muted)]"></i>
      </div>
    </div>
    <div class="flex flex-row justify-end items-center gap-[16px]">
      <ColorBar class="shrink-0 border-0" />
      <div class="flex flex-row justify-start items-center gap-[6px]">
        <i class="fa-solid fa-circle-check text-[10px]" :class="syncColor"></i>
        <span class="text-[10px] leading-[12px] font-[600]" :class="syncColor">{{ syncText }}</span>
      </div>
      <div class="flex flex-row justify-start items-center gap-[8px]">
        <i class="fa-solid fa-minus text-[9px] cursor-pointer text-[var(--color-tertiary)] hover:text-[var(--color-body)] transition-colors duration-100 p-[3px] rounded-[3px] hover:bg-[var(--color-border-light)]" @click="$emit('zoomOut')"></i>
        <div class="w-[64px] h-[4px] bg-[var(--color-border)] rounded-[2px] overflow-hidden cursor-pointer group relative" @click="$emit('zoomToPercent')">
          <div class="h-full rounded-[2px] bg-[var(--color-primary)] transition-all duration-150 group-hover:bg-[var(--color-primary-dark-700)]" :style="{ width: zoomPercent + '%' }"></div>
        </div>
        <i class="fa-solid fa-plus text-[9px] cursor-pointer text-[var(--color-tertiary)] hover:text-[var(--color-body)] transition-colors duration-100 p-[3px] rounded-[3px] hover:bg-[var(--color-border-light)]" @click="$emit('zoomIn')"></i>
        <span class="w-[34px] text-[10px] leading-[12px] font-[600] text-[var(--color-body)] text-right font-mono">{{ zoomPercent }}%</span>
      </div>
    </div>

    <!-- 色彩空间弹窗 -->
    <Teleport to="body">
      <div v-if="activePopup === 'colorSpace'" class="fixed z-[500] min-w-[180px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[4px] overflow-hidden" :style="{ left: popupPos.x + 'px', top: popupPos.y + 'px' }" @click.stop>
        <div class="px-[10px] py-[4px] bg-[var(--color-panel)] text-[9px] font-[600] text-[var(--color-muted)]">色彩空间</div>
        <div v-for="cs in colorSpaceOptions" :key="cs"
          class="flex flex-row justify-between items-center h-[28px] px-[10px] cursor-pointer hover:bg-[var(--color-hover-bg)]"
          :class="localColorSpace === cs ? 'bg-[var(--color-hover-bg)]' : ''"
          @click="localColorSpace = cs; activePopup = ''"
        >
          <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">{{ cs }}</span>
          <i v-if="localColorSpace === cs" class="fa-solid fa-check text-[9px] text-[var(--color-primary)]"></i>
        </div>
      </div>
    </Teleport>

    <!-- 文档尺寸弹窗 -->
    <Teleport to="body">
      <div v-if="activePopup === 'documentSize' || activePopup === 'customSize'" class="fixed z-[500] min-w-[200px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[4px] overflow-hidden" :style="{ left: popupPos.x + 'px', top: popupPos.y + 'px' }" @click.stop>
        <div class="px-[10px] py-[4px] bg-[var(--color-panel)] text-[9px] font-[600] text-[var(--color-muted)]">文档尺寸</div>
        <div v-for="sz in docSizeOptions" :key="sz.label"
          class="flex flex-row justify-between items-center h-[28px] px-[10px] cursor-pointer hover:bg-[var(--color-hover-bg)]"
          :class="localDocumentSize === sz.label ? 'bg-[var(--color-hover-bg)]' : ''"
          @click="applyPresetSize(sz)"
        >
          <div class="flex flex-col items-start">
            <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">{{ sz.label }}</span>
            <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ sz.size }}</span>
          </div>
          <i v-if="localDocumentSize === sz.label" class="fa-solid fa-check text-[9px] text-[var(--color-primary)]"></i>
        </div>
        <div class="h-[1px] bg-[var(--color-border)] mx-[10px] my-[4px]"></div>
        <div class="flex flex-row items-center gap-[4px] px-[10px] py-[4px] cursor-pointer hover:bg-[var(--color-hover-bg)]" @click="activePopup = 'customSize'">
          <i class="fa-solid fa-plus text-[8px] text-[var(--color-muted)]"></i>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">自定义尺寸</span>
        </div>
        <!-- 自定义尺寸 -->
        <div v-if="activePopup === 'customSize'" class="px-[10px] py-[6px] border-t border-[var(--color-border)]">
          <div class="flex flex-row items-center gap-[4px] mb-[4px]">
            <span class="text-[8px] leading-[10px] font-[500] text-[#8B939D] w-[20px]">宽</span>
            <input type="number" v-model.number="customWidth" class="flex-1 h-[22px] px-[4px] text-[9px] leading-[12px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" />
            <select class="h-[22px] px-[2px] text-[8px] leading-[10px] border border-[var(--color-border)] rounded-[3px] outline-none bg-[var(--color-white)] text-[var(--color-body)]" v-model="customUnit">
              <option>mm</option><option>cm</option><option>px</option><option>pt</option><option>in</option>
            </select>
          </div>
          <div class="flex flex-row items-center gap-[4px] mb-[4px]">
            <span class="text-[8px] leading-[10px] font-[500] text-[#8B939D] w-[20px]">高</span>
            <input type="number" v-model.number="customHeight" class="flex-1 h-[22px] px-[4px] text-[9px] leading-[12px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" />
            <div class="flex flex-row justify-center items-center w-[22px] h-[22px] rounded-[3px] cursor-pointer bg-[var(--color-primary)] text-[8px] font-[600] text-[var(--color-white)] hover:bg-[var(--color-primary-dark-900)]" @click="applyCustomSize">应用</div>
          </div>
          <label class="flex flex-row items-center gap-[4px] cursor-pointer mt-[4px]">
            <div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="constrainProportions ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="constrainProportions = !constrainProportions"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div>
            <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-secondary)]">约束比例</span>
          </label>
        </div>
      </div>
    </Teleport>

    <!-- 页码弹窗：图层快速跳转 -->
    <Teleport to="body">
      <div v-if="activePopup === 'pageInfo'" class="fixed z-[500] min-w-[180px] max-h-[280px] overflow-y-auto bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[4px] overflow-hidden" :style="{ left: popupPos.x + 'px', top: popupPos.y + 'px' }" @click.stop>
        <div class="px-[10px] py-[4px] bg-[var(--color-panel)] text-[9px] font-[600] text-[var(--color-muted)]">图层列表</div>
        <div
          v-for="(layer, idx) in fusion.layers"
          :key="layer.id"
          class="flex flex-row justify-between items-center h-[26px] px-[10px] cursor-pointer hover:bg-[var(--color-hover-bg)]"
          :class="fusion.selectedLayerId === layer.id ? 'bg-[var(--color-hover-bg)]' : ''"
          @click="fusion.selectLayer(layer.id); activePopup = ''"
        >
          <div class="flex flex-row items-center gap-[6px] min-w-0">
            <span class="text-[9px] font-[500] text-[var(--color-muted)] w-[16px]">{{ idx + 1 }}</span>
            <i :class="['fa-solid', layer.visible ? 'fa-eye' : 'fa-eye-slash', 'text-[8px]', layer.visible ? 'text-[var(--color-muted)]' : 'text-[var(--color-error)]']"></i>
            <span class="text-[10px] font-[500] text-[var(--color-body)] truncate">{{ layer.name }}</span>
          </div>
          <span class="text-[8px] text-[var(--color-muted)] shrink-0">{{ layer.objects.length }}</span>
        </div>
        <div v-if="fusion.layers.length === 0" class="px-[10px] py-[8px] text-[9px] text-[var(--color-muted)] text-center">暂无图层</div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted } from 'vue'
import ColorBar from './ColorBar.vue'
import ThemePicker from './ThemePicker.vue'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useToastStore } from '../stores/toast'

const fusion = useFusionDocumentStore()
const toastStore = useToastStore()

defineEmits<{
  (e: 'zoomIn'): void
  (e: 'zoomOut'): void
  (e: 'zoomToPercent'): void
}>()

const props = withDefaults(defineProps<{
  zoomPercent?: number
}>(), {
  zoomPercent: 82,
})

// ─── 文档信息（派生自 fusion） ───
const localColorSpace = ref('sRGB IEC61966-2.1')
const localDocumentSize = computed(() => {
  const w = fusion.scene.canvasWidth
  const h = fusion.scene.canvasHeight
  const u = fusion.scene.unit
  return `${w} × ${h} ${u}`
})
const localPageInfo = computed(() => {
  // Fusion DOM 当前为单 scene，显示对象数与图层信息
  const total = fusion.layers.length
  return `${fusion.selectedLayerId ? fusion.selectedLayer?.name ?? '未命名' : '未选中'} · ${total} 图层`
})

// ─── 同步状态：根据 fusion.isDirty 实时反映 ───
const syncText = computed(() => {
  if (fusion.isDirty) return '未保存'
  if (fusion.lastSavedAt) return '已保存'
  return '已同步'
})
const syncColor = computed(() => {
  if (fusion.isDirty) return 'text-[var(--color-warning)]'
  return 'text-[var(--color-primary-dark-700)]'
})
const syncStatus = computed<'synced' | 'unsaved'>(() => fusion.isDirty ? 'unsaved' : 'synced')

// 弹窗状态
const activePopup = ref<string>('')
const popupPos = reactive({ x: 0, y: 0 })

// 文档尺寸选项
const docSizeOptions = [
  { label: 'A4 · 210 × 297 mm', size: '210 × 297 mm', w: 595, h: 842 },
  { label: 'A3 · 297 × 420 mm', size: '297 × 420 mm', w: 842, h: 1191 },
  { label: 'A5 · 148 × 210 mm', size: '148 × 210 mm', w: 420, h: 595 },
  { label: '信纸 · 215.9 × 279.4 mm', size: '215.9 × 279.4 mm', w: 612, h: 792 },
  { label: '法律 · 215.9 × 355.6 mm', size: '215.9 × 355.6 mm', w: 612, h: 1008 },
  { label: '名片 · 90 × 54 mm', size: '90 × 54 mm', w: 255, h: 153 },
  { label: '海报 · 420 × 594 mm', size: '420 × 594 mm', w: 1191, h: 1684 },
  { label: '横幅 · 594 × 210 mm', size: '594 × 210 mm', w: 1684, h: 595 },
]

// 色彩空间选项
const colorSpaceOptions = [
  'sRGB IEC61966-2.1',
  'Adobe RGB (1998)',
  'Display P3',
  'CMYK Coated FOGRA39',
  'CMYK Uncoated FOGRA29',
  'ProPhoto RGB',
  'Apple RGB',
]

// 自定义尺寸
const customWidth = ref(210)
const customHeight = ref(297)
const customUnit = ref('mm')
const constrainProportions = ref(true)

const togglePopup = (type: string, e?: MouseEvent) => {
  if (activePopup.value === type) {
    activePopup.value = ''
    return
  }
  activePopup.value = type
  // 计算弹窗位置：从点击元素下方弹出
  if (e && e.currentTarget) {
    const el = e.currentTarget as HTMLElement
    const rect = el.getBoundingClientRect()
    popupPos.x = rect.left
    popupPos.y = rect.bottom + 4
  }
}

/** 应用预设尺寸到 fusion 文档 */
function applyPresetSize(opt: { label: string; w: number; h: number }): void {
  fusion.pushHistory('修改文档尺寸')
  fusion.scene.canvasWidth = opt.w
  fusion.scene.canvasHeight = opt.h
  localColorSpace.value = localColorSpace.value // 触发响应
  activePopup.value = ''
  toastStore.show(`已应用尺寸：${opt.label}`, 'fa-vector-square', 'success')
}

/** 应用自定义尺寸 */
function applyCustomSize(): void {
  fusion.pushHistory('自定义文档尺寸')
  // 简化：直接写入像素值（不考虑单位转换）
  fusion.scene.canvasWidth = customWidth.value
  fusion.scene.canvasHeight = customHeight.value
  activePopup.value = ''
  toastStore.show(`已应用自定义尺寸 ${customWidth.value}×${customHeight.value}`, 'fa-vector-square', 'success')
}

// 全局点击关闭
const onGlobalClick = () => { activePopup.value = '' }

onMounted(() => { document.addEventListener('click', onGlobalClick) })
onUnmounted(() => { document.removeEventListener('click', onGlobalClick) })
</script>