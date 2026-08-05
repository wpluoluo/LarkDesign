<template>
  <div ref="toolRailRef" class="flex flex-col justify-start items-center w-[48px] bg-[var(--color-panel)] border-r border-[var(--color-border)] py-[8px] gap-[2px] shrink-0 relative z-40">
    <div v-for="group in toolStore.toolGroups" :key="group.id" class="relative group/item">
      <!-- Tool button -->
      <div
        class="flex flex-row justify-center items-center w-[36px] h-[36px] rounded-[8px] cursor-pointer relative select-none transition-all duration-100"
        :class="group.active
          ? 'bg-[var(--color-hover-bg)] shadow-[inset_0_0_0_1.5px_var(--color-primary-light-300)]'
          : 'hover:bg-[var(--color-border-light)] hover:shadow-[inset_0_0_0_1px_var(--color-border)]'"
        @mousedown.prevent="onMouseDown(group, $event)"
        @mouseup="onMouseUp(group)"
        @contextmenu.prevent="showFlyout(group, $event)"
      >
        <i :class="['fa-solid', group.icon, 'text-[14px] transition-colors', group.active ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]']"></i>
        <!-- Multi-tool indicator -->
        <span v-if="group.tools.length > 1" class="absolute bottom-[2px] right-[2px] w-0 h-0 border-l-[3px] border-r-[3px] border-t-[3px] border-l-transparent border-r-transparent border-t-[var(--color-tertiary)] rotate-[-45deg]"></span>
      </div>
      <!-- Tooltip -->
      <div class="absolute left-[calc(100%+8px)] top-1/2 -translate-y-1/2 z-[100] pointer-events-none opacity-0 group-hover/item:opacity-100 transition-opacity duration-150 delay-300">
        <div class="flex flex-row items-center gap-[6px] h-[26px] px-[8px] bg-[var(--color-title)] rounded-[6px] shadow-lg whitespace-nowrap">
          <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-white)]">{{ group.activeTool || group.label }}</span>
          <span v-if="group.tools.length > 1" class="text-[9px] leading-[12px] font-[400] text-[var(--color-tertiary)]">长按展开</span>
        </div>
        <div class="absolute right-full top-1/2 -translate-y-1/2 w-0 h-0 border-t-[4px] border-b-[4px] border-r-[5px] border-t-transparent border-b-transparent border-r-[var(--color-title)]"></div>
      </div>
    </div>
  </div>

  <!-- Flyout menu -->
  <Teleport to="body">
    <Transition name="flyout">
      <div
        v-if="flyoutGroup"
        ref="flyoutRef"
        class="fixed z-[9999] min-w-[180px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[6px] overflow-hidden"
        :style="{ left: flyoutPos.x + 'px', top: flyoutPos.y + 'px' }"
        @mouseleave="onFlyoutMouseLeave"
        @mouseenter="mouseInFlyout = true"
      >
        <!-- Flyout header -->
        <div class="flex flex-row items-center gap-[6px] px-[12px] py-[4px] mb-[2px]">
          <i :class="['fa-solid', flyoutGroupIcon, 'text-[10px]', 'text-[var(--color-primary-dark-700)]']"></i>
          <span class="text-[10px] leading-[13px] font-[600] text-[var(--color-tertiary)]">{{ flyoutGroupLabel }}</span>
        </div>
        <div
          v-for="(tool, ti) in currentFlyoutTools"
          :key="ti"
          class="flex flex-row justify-between items-center h-[32px] px-[12px] mx-[4px] rounded-[6px] cursor-pointer transition-colors"
          :class="tool.name === currentActiveTool ? 'bg-[var(--color-hover-bg)]' : 'hover:bg-[var(--color-panel)]'"
          @click="selectTool(tool)"
        >
          <div class="flex flex-row items-center gap-[10px]">
            <i :class="['fa-solid', tool.icon, 'text-[11px]', 'w-[16px] text-center', tool.name === currentActiveTool ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]']"></i>
            <span class="text-[12px] leading-[16px]" :class="tool.name === currentActiveTool ? 'text-[var(--color-primary-dark-700)] font-[600]' : 'text-[var(--color-body)] font-[400]'">{{ tool.name }}</span>
          </div>
          <span v-if="tool.shortcut" class="text-[10px] leading-[12px] font-[500] text-[var(--color-tertiary)] ml-[12px] px-[4px] py-[1px] bg-[var(--color-panel)] rounded-[3px]">{{ tool.shortcut }}</span>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useToolStore, type ToolGroupData, type ToolItemData } from '../stores/tool'

const toolStore = useToolStore()
const toolRailRef = ref<HTMLElement | null>(null)
const flyoutRef = ref<HTMLElement | null>(null)

// ─── Flyout state ───
const flyoutGroup = ref<string | null>(null)
const flyoutPos = ref({ x: 0, y: 0 })
let mouseInFlyout = false

const currentFlyoutTools = computed(() => {
  const g = toolStore.toolGroups.find(g => g.id === flyoutGroup.value)
  return g ? g.tools : []
})
const currentActiveTool = computed(() => {
  const g = toolStore.toolGroups.find(g => g.id === flyoutGroup.value)
  return g ? g.activeTool : ''
})
const flyoutGroupIcon = computed(() => {
  const g = toolStore.toolGroups.find(g => g.id === flyoutGroup.value)
  return g ? g.icon : ''
})
const flyoutGroupLabel = computed(() => {
  const g = toolStore.toolGroups.find(g => g.id === flyoutGroup.value)
  return g ? g.label : ''
})

// ─── Long-press / Flyout logic ───
let longPressTimer: ReturnType<typeof setTimeout> | null = null
let isLongPress = false
let suppressClick = false

const showFlyout = (group: ToolGroupData, e?: MouseEvent) => {
  let rect: DOMRect
  if (e) {
    rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
  } else {
    // fallback: find the element
    const el = toolRailRef.value?.querySelector(`[data-group="${group.id}"]`)
    rect = el ? el.getBoundingClientRect() : new DOMRect(48, 0, 36, 36)
  }
  flyoutPos.value = { x: rect.right + 6, y: Math.max(8, rect.top - 8) }
  flyoutGroup.value = group.id
  mouseInFlyout = false
}

const onMouseDown = (group: ToolGroupData, e: MouseEvent) => {
  // Right-click: show flyout immediately
  if (e.button === 2) {
    showFlyout(group, e)
    return
  }
  // Left-click on multi-tool group: start long-press timer
  if (group.tools.length > 1) {
    isLongPress = false
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect()
    longPressTimer = setTimeout(() => {
      showFlyout(group)
      flyoutPos.value = { x: rect.right + 6, y: Math.max(8, rect.top - 8) }
      isLongPress = true
      suppressClick = true
      longPressTimer = null
    }, 350)
  }
}

const onMouseUp = (group: ToolGroupData) => {
  // Cancel long-press timer if still pending
  if (longPressTimer) {
    clearTimeout(longPressTimer)
    longPressTimer = null
  }
  // If long-press already fired, don't activate
  if (isLongPress) {
    isLongPress = false
    return
  }
  // If flyout is open for this group, close it
  if (flyoutGroup.value === group.id) {
    flyoutGroup.value = null
    return
  }
  // Normal click: activate tool
  toolStore.activateGroup(group.id)
  flyoutGroup.value = null
}

const onFlyoutMouseLeave = () => {
  mouseInFlyout = false
  setTimeout(() => { if (!mouseInFlyout) flyoutGroup.value = null }, 200)
}

// Global click to close flyout
const onGlobalMouseDown = (e: MouseEvent) => {
  if (!flyoutGroup.value) return
  if (flyoutRef.value?.contains(e.target as Node)) return
  if (toolRailRef.value?.contains(e.target as Node)) return
  flyoutGroup.value = null
}

const selectTool = (tool: ToolItemData) => {
  if (flyoutGroup.value) toolStore.selectTool(flyoutGroup.value, tool.name)
  flyoutGroup.value = null
}

onMounted(() => document.addEventListener('mousedown', onGlobalMouseDown))
onUnmounted(() => {
  document.removeEventListener('mousedown', onGlobalMouseDown)
  if (longPressTimer) clearTimeout(longPressTimer)
})
</script>

<style scoped>
.flyout-enter-active { transition: all 0.15s ease-out; }
.flyout-leave-active { transition: all 0.1s ease-in; }
.flyout-enter-from { opacity: 0; transform: translateX(-4px) scale(0.96); }
.flyout-leave-to { opacity: 0; transform: translateX(-2px) scale(0.98); }
</style>
