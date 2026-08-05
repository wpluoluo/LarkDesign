<template>
  <Teleport to="body">
    <Transition name="menu">
      <div
        v-if="visible"
        ref="menuRef"
        class="fixed z-[200] min-w-[210px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12),0_2px_8px_rgba(0,0,0,0.06)] py-[6px]"
        :style="{ left: x + 'px', top: y + 'px' }"
        @click.stop
      >
        <template v-for="(item, ci) in items" :key="ci">
          <div v-if="item.divider" class="h-[1px] bg-[var(--color-border-light)] mx-[8px] my-[4px]"></div>
          <div
            v-else
            class="flex flex-row justify-between items-center h-[30px] px-[10px] mx-[4px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] whitespace-nowrap relative transition-colors duration-100"
            :class="item.disabled ? 'opacity-40 cursor-default pointer-events-none' : ''"
            @click="onItemClick(item)"
            @mouseenter="item.children ? (activeSub = item.label ?? '') : (activeSub = '')"
          >
            <div class="flex flex-row items-center gap-[9px]">
              <i
                v-if="item.icon"
                :class="['fa-solid', item.icon, 'text-[11px]', 'w-[15px] text-center', item.danger ? 'text-[var(--color-error)]' : 'text-[var(--color-tertiary)]']"
              ></i>
              <span
                v-if="item.label"
                class="text-[12px] leading-[16px] font-[450]"
                :class="item.danger ? 'text-[var(--color-error)] font-[500]' : item.disabled ? 'text-[var(--color-muted)] text-[10px] font-[600] uppercase tracking-wide' : 'text-[var(--color-body)]'"
              >{{ item.label }}</span>
            </div>
            <div class="flex flex-row items-center gap-[8px]">
              <span v-if="item.shortcut" class="text-[10px] leading-[12px] font-[500] text-[#9AA2AC] px-[4px] py-[1px] bg-[var(--color-panel)] rounded-[3px]">{{ item.shortcut }}</span>
              <i v-if="item.children" class="fa-solid fa-chevron-right text-[7px] text-[var(--color-muted)]"></i>
            </div>
            <!-- Submenu -->
            <div
              v-if="item.children && activeSub === item.label"
              class="absolute left-[calc(100%+2px)] top-[-6px] min-w-[180px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[6px] z-50"
              @mouseleave="activeSub = ''"
            >
              <div
                v-for="(sub, si) in item.children"
                :key="si"
                class="flex flex-row justify-between items-center h-[28px] px-[10px] mx-[4px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] whitespace-nowrap transition-colors duration-100"
                @click.stop="onSubItemClick(sub)"
              >
                <div class="flex flex-row items-center gap-[8px]">
                  <i v-if="sub.icon" :class="['fa-solid', sub.icon, 'text-[10px]', 'w-[13px] text-center', 'text-[var(--color-tertiary)]']"></i>
                  <span class="text-[11px] leading-[14px] font-[450] text-[var(--color-body)]">{{ sub.label }}</span>
                </div>
                <span v-if="sub.shortcut" class="text-[9px] leading-[12px] font-[500] text-[#9AA2AC] ml-[8px]">{{ sub.shortcut }}</span>
              </div>
            </div>
          </div>
        </template>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useClickOutside } from '../composables/useClickOutside'
import type { ContextMenuItem } from '../types'

const props = defineProps<{
  visible: boolean
  x: number
  y: number
  items: ContextMenuItem[]
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'action', action: string): void
}>()

const menuRef = ref<HTMLElement | null>(null)
const activeSub = ref('')

useClickOutside(menuRef, () => {
  if (props.visible) emit('close')
})

const onItemClick = (item: ContextMenuItem) => {
  if (item.disabled || item.divider) return
  if (item.children) {
    activeSub.value = activeSub.value === item.label ? '' : (item.label ?? '')
    return
  }
  if (item.action) emit('action', item.action)
  emit('close')
}

const onSubItemClick = (sub: ContextMenuItem) => {
  if (sub.action) emit('action', sub.action)
  emit('close')
}
</script>
