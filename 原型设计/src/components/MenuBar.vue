<template>
  <div class="flex flex-row justify-between items-center h-[32px] bg-[var(--color-panel)] border-b border-[var(--color-border)] px-[12px] shrink-0" ref="menuBarRef">
    <div class="flex flex-row justify-start items-center gap-[20px]">
      <div class="flex flex-row justify-start items-center gap-[8px]">
        <div class="flex flex-row justify-center items-center w-[20px] h-[20px] bg-[var(--color-primary)] rounded-[4px]">
          <i class="fa-solid fa-bezier-curve text-[11px] text-[var(--color-white)]"></i>
        </div>
        <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-title)]">Harmony Design</span>
      </div>
      <div class="flex flex-row justify-start items-center gap-[18px]">
        <span
          v-for="item in menuItems"
          :key="item.label"
          class="text-[12px] leading-[16px] font-[400] text-[var(--color-body)] cursor-pointer relative px-[4px] py-[6px] hover:bg-[var(--color-border-light)] rounded-[5px] select-none transition-colors duration-100"
          @click.stop="toggleMenu(item.label)"
          @mouseenter="hoverMenu(item.label)"
        >
          {{ item.label }}
          <div
            v-if="openMenu === item.label && item.children"
            class="absolute top-[100%] left-0 z-50 min-w-[240px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12),0_2px_8px_rgba(0,0,0,0.06)] py-[6px]"
            @mouseleave="closeThirdMenu"
          >
            <template v-for="(child, ci) in item.children" :key="ci">
              <div v-if="child.divider" class="h-[1px] bg-[var(--color-border)] my-[3px]"></div>
              <div
                v-else
                class="flex flex-row justify-between items-center h-[27px] px-[10px] mx-[4px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] relative group transition-colors duration-100"
                :class="child.disabled ? 'opacity-40 cursor-default' : ''"
                @click="child.children ? undefined : onMenuItemClick(child.label)"
                @mouseenter="openSecondMenu = child.children ? (child.label ?? null) : null"
              >
                <div class="flex flex-row items-center gap-[10px]">
                  <i
                    v-if="child.icon"
                    :class="['fa-solid', child.icon, 'text-[11px]', child.disabled ? 'text-[var(--color-muted)]' : 'text-[var(--color-tertiary)]', 'w-[14px] text-center']"
                  ></i>
                  <span
                    class="text-[12px] leading-[16px] whitespace-nowrap"
                    :class="child.disabled ? 'text-[var(--color-muted)]' : 'text-[var(--color-body)]'"
                  >{{ child.label }}</span>
                </div>
                <div class="flex flex-row items-center gap-[12px]">
                  <span v-if="child.shortcut" class="text-[10px] leading-[12px] font-[500] text-[#9AA2AC]">{{ child.shortcut }}</span>
                  <i v-if="child.children" class="fa-solid fa-chevron-right text-[8px] text-[var(--color-muted)]"></i>
                </div>
                <!-- 3rd-level submenu -->
                <div
                  v-if="child.children && openSecondMenu === child.label"
                  class="absolute left-[calc(100%+2px)] top-[-6px] min-w-[220px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[6px] z-50"
                  @mouseleave="openSecondMenu = null"
                >
                  <template v-for="(sub, si) in child.children" :key="si">
                    <div v-if="sub.divider" class="h-[1px] bg-[var(--color-border)] my-[3px]"></div>
                    <div
                      v-else
                      class="flex flex-row justify-between items-center h-[27px] px-[10px] mx-[4px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] relative transition-colors duration-100"
                      :class="sub.disabled ? 'opacity-40 cursor-default' : ''"
                      @click="sub.children ? undefined : onMenuItemClick(sub.label)"
                      @mouseenter="openThirdMenu = sub.children ? (sub.label ?? null) : null"
                    >
                      <div class="flex flex-row items-center gap-[8px]">
                        <i
                          v-if="sub.icon"
                          :class="['fa-solid', sub.icon, 'text-[11px]', 'text-[var(--color-tertiary)]', 'w-[14px] text-center']"
                        ></i>
                        <span class="text-[12px] leading-[16px] whitespace-nowrap text-[var(--color-body)]">{{ sub.label }}</span>
                      </div>
                      <div class="flex flex-row items-center gap-[12px]">
                        <span v-if="sub.shortcut" class="text-[10px] leading-[12px] font-[500] text-[#9AA2AC]">{{ sub.shortcut }}</span>
                        <i v-if="sub.children" class="fa-solid fa-chevron-right text-[8px] text-[var(--color-muted)]"></i>
                      </div>
                      <!-- 4th-level submenu -->
                      <div
                        v-if="sub.children && openThirdMenu === sub.label"
                        class="absolute left-[calc(100%+2px)] top-[-6px] min-w-[200px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.12)] py-[6px] z-50"
                      >
                        <div
                          v-for="(sub4, s4i) in sub.children"
                          :key="s4i"
                          class="flex flex-row justify-between items-center h-[27px] px-[10px] mx-[4px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] transition-colors duration-100"
                          @click="onMenuItemClick(sub4.label)"
                        >
                          <div class="flex flex-row items-center gap-[8px]">
                            <i
                              v-if="sub4.icon"
                              :class="['fa-solid', sub4.icon, 'text-[11px]', 'text-[var(--color-tertiary)]', 'w-[14px] text-center']"
                            ></i>
                            <span class="text-[12px] leading-[16px] whitespace-nowrap text-[var(--color-body)]">{{ sub4.label }}</span>
                          </div>
                          <span v-if="sub4.shortcut" class="text-[10px] leading-[12px] font-[500] text-[#9AA2AC]">{{ sub4.shortcut }}</span>
                        </div>
                      </div>
                    </div>
                  </template>
                </div>
              </div>
            </template>
          </div>
        </span>
      </div>
    </div>
    <div class="flex flex-row justify-end items-center gap-[10px]">
      <div class="flex flex-row justify-center items-center w-[24px] h-[24px] rounded-[4px] cursor-pointer hover:bg-[var(--color-border-light)]" @click="toggleDark" :title="isDark ? '切换亮色模式' : '切换暗色模式'">
        <i class="fa-solid text-[12px] text-[var(--color-body)]" :class="isDark ? 'fa-sun' : 'fa-moon'"></i>
      </div>
      <div class="flex flex-row justify-center items-center w-[24px] h-[24px] bg-[#263238] rounded-[12px] cursor-pointer">
        <span class="text-[10px] leading-[14px] font-[700] text-[var(--color-white)]">JC</span>
      </div>
      <div class="w-[1px] h-[16px] bg-[var(--color-border)] mx-[4px]"></div>
      <i class="fa-solid fa-minus text-[10px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)]" title="最小化"></i>
      <i class="fa-regular fa-square text-[10px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)]" title="最大化"></i>
      <i class="fa-solid fa-xmark text-[12px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-error)]" title="关闭"></i>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useClickOutside } from '../composables/useClickOutside'
import { menuItems } from '../data/menuItems'
import { useToastStore } from '../stores/toast'
import { useMenuActions } from '../composables/useMenuActions'

const toastStore = useToastStore()
const { execute: executeAction } = useMenuActions()

// ─── Dark mode ───
const isDark = ref(false)
onMounted(() => { isDark.value = document.documentElement.classList.contains('dark') })
const toggleDark = () => {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  toastStore.show(isDark.value ? '已切换暗色模式' : '已切换亮色模式', isDark.value ? 'fa-moon' : 'fa-sun', 'info')
}

// ─── Menu state ───
const openMenu = ref<string | null>(null)
const openSecondMenu = ref<string | null>(null)
const openThirdMenu = ref<string | null>(null)
const menuBarRef = ref<HTMLElement | null>(null)

const closeAllMenus = () => {
  openMenu.value = null
  openSecondMenu.value = null
  openThirdMenu.value = null
}

const toggleMenu = (label?: string) => {
  if (!label) return
  openMenu.value = openMenu.value === label ? null : label
  openSecondMenu.value = null
  openThirdMenu.value = null
}

const hoverMenu = (label?: string) => {
  if (!label) return
  if (openMenu.value) {
    openMenu.value = label
    openSecondMenu.value = null
    openThirdMenu.value = null
  }
}

const closeThirdMenu = () => {
  openSecondMenu.value = null
  openThirdMenu.value = null
}

// Menu item click: 调用动作分发器
const onMenuItemClick = (label?: string) => {
  if (label) executeAction(label)
  openMenu.value = null
  openSecondMenu.value = null
  openThirdMenu.value = null
}

// Click outside to close
useClickOutside(menuBarRef, closeAllMenus)
</script>
