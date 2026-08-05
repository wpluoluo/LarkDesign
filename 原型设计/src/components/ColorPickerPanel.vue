<template>
  <div class="flex flex-col gap-[6px]">
    <!-- ===== Hue Strip + SV Square ===== -->
    <div class="flex flex-row gap-[8px]">
      <!-- Hue strip (vertical) -->
      <div class="w-[16px] h-[128px] rounded-[4px] relative cursor-pointer shrink-0" :style="{ background: hueStripBg }" @mousedown="onHueStripMouseDown">
        <div class="absolute w-[20px] h-[8px] -left-[2px] rounded-[2px] border-2 border-white shadow-md pointer-events-none" :style="{ top: (huePct * 120) + 'px', backgroundColor: localHex }"></div>
      </div>
      <!-- SV Square -->
      <div class="flex-1 h-[128px] rounded-[4px] relative cursor-crosshair overflow-hidden border border-[var(--color-border)]" ref="svSquareRef" @mousedown="onSVSquareMouseDown">
        <div class="absolute inset-0" :style="{ background: svSquareBg }"></div>
        <div class="absolute inset-0" :style="{ background: 'linear-gradient(to top, #000, transparent)' }"></div>
        <div class="absolute inset-0" :style="{ background: 'linear-gradient(to right, #fff, transparent)' }"></div>
        <div class="absolute w-[12px] h-[12px] rounded-full border-2 border-white shadow-md -translate-x-1/2 -translate-y-1/2 pointer-events-none" :style="{ left: satPct + '%', top: (100 - lightPct) + '%', backgroundColor: localHex }"></div>
      </div>
    </div>

    <!-- ===== HEX + Preview ===== -->
    <div class="flex flex-row items-center gap-[6px]">
      <div class="w-[22px] h-[22px] rounded-[4px] border border-[var(--color-border)] shrink-0" :style="{ backgroundColor: localHex }"></div>
      <div class="flex flex-row justify-between items-center flex-1 h-[24px] px-[6px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px]">
        <span class="text-[9px] leading-[12px] font-[500] text-[#8B939D]">HEX</span>
        <input class="w-[60px] bg-transparent text-[9px] leading-[12px] font-[500] font-mono text-[var(--color-body)] border-none outline-none text-right" :value="localHex" @input="onHexInput" maxlength="7" />
      </div>
    </div>

    <!-- ===== Mode Tabs ===== -->
    <div class="flex flex-row gap-[4px]">
      <div v-for="mode in colorModes" :key="mode"
        class="flex-1 flex flex-row justify-center items-center h-[22px] rounded-[4px] cursor-pointer border text-[9px] font-[500] transition-colors"
        :class="localMode === mode ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-white)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
        @click="localMode = mode"
      >{{ mode }}</div>
    </div>

    <!-- ===== RGB Mode Inputs ===== -->
    <div v-if="localMode === 'RGB'" class="grid grid-cols-3 gap-[4px]">
      <ColorChannelInput label="R" :label-color="'#EF4444'" :model-value="valR" @update:model-value="onChannelInput('r', $event)" />
      <ColorChannelInput label="G" :label-color="'#22C55E'" :model-value="valG" @update:model-value="onChannelInput('g', $event)" />
      <ColorChannelInput label="B" :label-color="'#3B82F6'" :model-value="valB" @update:model-value="onChannelInput('b', $event)" />
    </div>

    <!-- ===== HSL Mode Inputs ===== -->
    <div v-if="localMode === 'HSL'" class="grid grid-cols-3 gap-[4px]">
      <ColorChannelInput label="H" :label-color="'#8B939D'" :model-value="valH" :suffix="'°'" :min="0" :max="360" @update:model-value="onHSLInput('h', $event)" />
      <ColorChannelInput label="S" :label-color="'#8B939D'" :model-value="valS" suffix="%" @update:model-value="onHSLInput('s', $event)" />
      <ColorChannelInput label="L" :label-color="'#8B939D'" :model-value="valL" suffix="%" @update:model-value="onHSLInput('l', $event)" />
    </div>

    <!-- ===== CMYK Mode Inputs ===== -->
    <div v-if="localMode === 'CMYK'" class="grid grid-cols-2 gap-[4px]">
      <ColorChannelInput label="C" :label-color="'#00BCD4'" :model-value="cmykC" suffix="%" @update:model-value="onCMYKInput('c', $event)" />
      <ColorChannelInput label="M" :label-color="'#E91E63'" :model-value="cmykM" suffix="%" @update:model-value="onCMYKInput('m', $event)" />
      <ColorChannelInput label="Y" :label-color="'#FFEB3B'" :model-value="cmykY" suffix="%" @update:model-value="onCMYKInput('y', $event)" />
      <ColorChannelInput label="K" :label-color="'#263238'" :model-value="cmykK" suffix="%" @update:model-value="onCMYKInput('k', $event)" />
    </div>

    <!-- ===== Color Swatches ===== -->
    <div class="flex flex-row items-center justify-between">
      <span class="text-[9px] leading-[12px] font-[600] text-[var(--color-muted)]">色板</span>
      <div class="flex flex-row gap-[4px]">
        <i class="fa-solid fa-eye-dropper text-[9px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[2px]" title="取色"></i>
        <i class="fa-solid fa-plus text-[9px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[2px]" title="添加色板"></i>
      </div>
    </div>
    <div class="flex flex-row flex-wrap gap-[4px]">
      <div
        v-for="(swatch, si) in swatches"
        :key="si"
        class="w-[20px] h-[20px] rounded-[3px] border border-[var(--color-border)] cursor-pointer hover:scale-125 transition-transform"
        :class="localHex.toUpperCase() === swatch.toUpperCase() ? 'ring-2 ring-[var(--color-primary)] ring-offset-1' : ''"
        :style="{ backgroundColor: swatch }"
        :title="swatch"
        @click="onSwatchClick(swatch)"
      ></div>
    </div>

    <!-- ===== Color Profile ===== -->
    <div class="flex flex-row items-center gap-[6px] pt-[2px] border-t border-[var(--color-border-light)]">
      <div class="flex flex-row items-center gap-[4px] flex-1">
        <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">配置文件</span>
        <select class="flex-1 h-[20px] text-[8px] font-[500] border border-[var(--color-border)] rounded-[3px] px-[4px] bg-[var(--color-white)] text-[var(--color-body)] outline-none" v-model="localProfile">
          <option>sRGB IEC61966-2.1</option>
          <option>Adobe RGB (1998)</option>
          <option>Display P3</option>
          <option>CMYK Coated FOGRA39</option>
          <option>CMYK Uncoated FOGRA29</option>
          <option>ProPhoto RGB</option>
          <option>Apple RGB</option>
        </select>
      </div>
      <div class="flex flex-row items-center gap-[4px]">
        <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">渲染</span>
        <select class="h-[20px] text-[8px] font-[500] border border-[var(--color-border)] rounded-[3px] px-[4px] bg-[var(--color-white)] text-[var(--color-body)] outline-none" v-model="localRenderIntent">
          <option>相对比色</option>
          <option>绝对比色</option>
          <option>可感知</option>
          <option>饱和度</option>
        </select>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import ColorChannelInput from './ColorChannelInput.vue'
import {
  hexToRgb, rgbToHex, rgbToHsl, hslToRgb,
  rgbToCmyk, cmykToRgb
} from '../composables/colorUtils'

const props = withDefaults(defineProps<{
  modelValue?: string
  profile?: string
  renderIntent?: string
  swatches?: string[]
}>(), {
  modelValue: '#3AC487',
  profile: 'sRGB IEC61966-2.1',
  renderIntent: '相对比色',
  swatches: () => ['#3AC487', '#16865F', '#0D5A3D', '#3B82F6', '#22C55E', '#F59E0B', '#EF4444', '#263238', '#FFFFFF', '#000000'],
})

const emit = defineEmits<{
  (e: 'update:modelValue', val: string): void
  (e: 'update:profile', val: string): void
  (e: 'update:renderIntent', val: string): void
  (e: 'select', hex: string): void
}>()

// ─── Local state ───
const localHex = ref(props.modelValue)
const localMode = ref('RGB')
const localProfile = ref(props.profile)
const localRenderIntent = ref(props.renderIntent)

const colorModes = ['RGB', 'HSL', 'CMYK']

// RGB
const valR = ref(58)
const valG = ref(196)
const valB = ref(135)

// HSL
const valH = ref(152)
const valS = ref(54)
const valL = ref(50)

// CMYK
const cmykC = ref(0)
const cmykM = ref(56)
const cmykY = ref(42)
const cmykK = ref(17)

// ─── Computed ───
const huePct = computed(() => valH.value / 360)
const satPct = computed(() => valS.value / 100 * 100)
const lightPct = computed(() => valL.value / 100 * 100)
const hueStripBg = 'linear-gradient(to bottom, #FF0000 0%, #FFFF00 17%, #00FF00 33%, #00FFFF 50%, #0000FF 67%, #FF00FF 83%, #FF0000 100%)'
const svSquareBg = computed(() => `hsl(${valH.value}, 100%, 50%)`)

// ─── Sync functions ───
const syncFromHex = (hex: string) => {
  localHex.value = hex
  const rgb = hexToRgb(hex)
  if (!rgb) return
  valR.value = rgb.r; valG.value = rgb.g; valB.value = rgb.b
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b)
  valH.value = hsl.h; valS.value = hsl.s; valL.value = hsl.l
  const cmyk = rgbToCmyk(rgb.r, rgb.g, rgb.b)
  cmykC.value = cmyk.c; cmykM.value = cmyk.m; cmykY.value = cmyk.y; cmykK.value = cmyk.k
}

const syncFromRgb = (r: number, g: number, b: number) => {
  valR.value = Math.max(0, Math.min(255, Math.round(r)))
  valG.value = Math.max(0, Math.min(255, Math.round(g)))
  valB.value = Math.max(0, Math.min(255, Math.round(b)))
  localHex.value = rgbToHex(valR.value, valG.value, valB.value)
  const hsl = rgbToHsl(valR.value, valG.value, valB.value)
  valH.value = hsl.h; valS.value = hsl.s; valL.value = hsl.l
  const cmyk = rgbToCmyk(valR.value, valG.value, valB.value)
  cmykC.value = cmyk.c; cmykM.value = cmyk.m; cmykY.value = cmyk.y; cmykK.value = cmyk.k
}

const syncFromHsl = (h: number, s: number, l: number) => {
  valH.value = Math.max(0, Math.min(360, Math.round(h)))
  valS.value = Math.max(0, Math.min(100, Math.round(s)))
  valL.value = Math.max(0, Math.min(100, Math.round(l)))
  const rgb = hslToRgb(valH.value, valS.value, valL.value)
  valR.value = rgb.r; valG.value = rgb.g; valB.value = rgb.b
  localHex.value = rgbToHex(rgb.r, rgb.g, rgb.b)
  const cmyk = rgbToCmyk(rgb.r, rgb.g, rgb.b)
  cmykC.value = cmyk.c; cmykM.value = cmyk.m; cmykY.value = cmyk.y; cmykK.value = cmyk.k
}

const syncFromCmyk = (c: number, m: number, y: number, k: number) => {
  cmykC.value = Math.max(0, Math.min(100, Math.round(c)))
  cmykM.value = Math.max(0, Math.min(100, Math.round(m)))
  cmykY.value = Math.max(0, Math.min(100, Math.round(y)))
  cmykK.value = Math.max(0, Math.min(100, Math.round(k)))
  const rgb = cmykToRgb(cmykC.value, cmykM.value, cmykY.value, cmykK.value)
  valR.value = rgb.r; valG.value = rgb.g; valB.value = rgb.b
  localHex.value = rgbToHex(rgb.r, rgb.g, rgb.b)
  const hsl = rgbToHsl(rgb.r, rgb.g, rgb.b)
  valH.value = hsl.h; valS.value = hsl.s; valL.value = hsl.l
}

const emitUpdate = (hex?: string) => {
  emit('update:modelValue', hex || localHex.value)
}

// ─── Handlers ───
const onHexInput = (e: Event) => {
  const val = (e.target as HTMLInputElement).value
  if (/^#[0-9a-fA-F]{6}$/.test(val)) {
    syncFromHex(val)
    emitUpdate(val)
  }
  localHex.value = val
}

const onChannelInput = (channel: string, val: number) => {
  const clamped = Math.max(0, Math.min(255, val))
  let r = valR.value, g = valG.value, b = valB.value
  if (channel === 'r') r = clamped
  else if (channel === 'g') g = clamped
  else if (channel === 'b') b = clamped
  syncFromRgb(r, g, b)
  emitUpdate()
}

const onHSLInput = (channel: string, val: number) => {
  const clamped = Math.max(0, channel === 'h' ? Math.min(360, val) : Math.min(100, val))
  let h = valH.value, s = valS.value, l = valL.value
  if (channel === 'h') h = clamped
  else if (channel === 's') s = clamped
  else if (channel === 'l') l = clamped
  syncFromHsl(h, s, l)
  emitUpdate()
}

const onCMYKInput = (channel: string, val: number) => {
  const clamped = Math.max(0, Math.min(100, val))
  let c = cmykC.value, m = cmykM.value, y = cmykY.value, k = cmykK.value
  if (channel === 'c') c = clamped
  else if (channel === 'm') m = clamped
  else if (channel === 'y') y = clamped
  else if (channel === 'k') k = clamped
  syncFromCmyk(c, m, y, k)
  emitUpdate()
}

const onSwatchClick = (swatch: string) => {
  syncFromHex(swatch)
  emit('select', swatch)
  emitUpdate(swatch)
}

// ─── Hue Strip ───
const onHueStripMouseDown = (e: MouseEvent) => {
  updateHueFromEvent(e)
  document.addEventListener('mousemove', onHueDrag)
  document.addEventListener('mouseup', onHueDragEnd)
}

const onHueDrag = (e: MouseEvent) => updateHueFromEvent(e)

const onHueDragEnd = () => {
  document.removeEventListener('mousemove', onHueDrag)
  document.removeEventListener('mouseup', onHueDragEnd)
}

const updateHueFromEvent = (e: MouseEvent) => {
  const el = e.currentTarget as HTMLElement
  if (!el) return
  const rect = el.getBoundingClientRect()
  const y = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height))
  syncFromHsl(Math.round(y * 360), valS.value, valL.value)
  emitUpdate()
}

// ─── SV Square ───
const svSquareRef = ref<HTMLElement | null>(null)

const onSVSquareMouseDown = (e: MouseEvent) => {
  updateSVFromEvent(e)
  document.addEventListener('mousemove', onSVDrag)
  document.addEventListener('mouseup', onSVDragEnd)
}

const onSVDrag = (e: MouseEvent) => updateSVFromEvent(e)

const onSVDragEnd = () => {
  document.removeEventListener('mousemove', onSVDrag)
  document.removeEventListener('mouseup', onSVDragEnd)
}

const updateSVFromEvent = (e: MouseEvent) => {
  const el = svSquareRef.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  const x = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width))
  const y = Math.max(0, Math.min(1, (e.clientY - rect.top) / rect.height))
  syncFromHsl(valH.value, Math.round(x * 100), Math.round((1 - y) * 100))
  emitUpdate()
}

// ─── Watch external prop changes ───
watch(() => props.modelValue, (nv) => {
  if (nv && nv !== localHex.value) {
    syncFromHex(nv)
  }
})

watch(localProfile, (v) => emit('update:profile', v))
watch(localRenderIntent, (v) => emit('update:renderIntent', v))

// Init
syncFromHex(props.modelValue)
</script>
