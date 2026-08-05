<template>
  <div
    class="flex flex-row items-center gap-[4px] cursor-pointer hover:bg-[var(--color-border-light)] px-[6px] py-[2px] rounded-[3px] relative shrink-0"
    @click.stop="togglePopup"
    title="切换主题"
  >
    <i class="fa-solid fa-palette text-[10px] text-[var(--color-tertiary)]"></i>
    <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-tertiary)]">{{ theme.currentTheme.name }}</span>
    <i class="fa-solid fa-chevron-down text-[6px] text-[var(--color-muted)]"></i>
  </div>

  <Teleport to="body">
    <div
      v-if="popupOpen"
      class="fixed z-[500] w-[280px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[10px] shadow-[0_8px_32px_rgba(0,0,0,0.18)] py-[4px] overflow-hidden"
      :style="{ left: popupPos.x + 'px', top: popupPos.y + 'px' }"
      @click.stop
    >
      <!-- 标题 -->
      <div class="px-[12px] py-[6px] bg-[var(--color-panel)] border-b border-[var(--color-border-light)] flex flex-row items-center gap-[6px]">
        <i class="fa-solid fa-palette text-[11px] text-[var(--color-primary)]"></i>
        <span class="text-[11px] font-[700] text-[var(--color-body)]">主题</span>
        <span class="text-[10px] text-[var(--color-muted)] ml-auto">视觉效果</span>
      </div>

      <!-- 跟随系统开关 -->
      <div class="flex flex-row items-center justify-between px-[12px] py-[8px] cursor-pointer hover:bg-[var(--color-hover-bg)] border-b border-[var(--color-border-light)]" @click="theme.setFollowSystem(!theme.followSystem)">
        <div class="flex flex-row items-center gap-[8px]">
          <i class="fa-solid fa-desktop text-[11px] text-[var(--color-secondary)]"></i>
          <span class="text-[11px] font-[500] text-[var(--color-body)]">跟随系统</span>
        </div>
        <div class="w-[28px] h-[16px] rounded-[8px] border transition-colors flex items-center" :class="theme.followSystem ? 'bg-[var(--color-primary)] border-[var(--color-primary)]' : 'bg-[var(--color-panel)] border-[var(--color-border)]'">
          <div class="w-[12px] h-[12px] rounded-full bg-white transition-transform duration-150" :class="theme.followSystem ? 'translate-x-[14px]' : 'translate-x-[1px]'"></div>
        </div>
      </div>

      <!-- 主题列表 -->
      <div class="py-[4px]">
        <div
          v-for="t in theme.themeList"
          :key="t.id"
          class="flex flex-row items-center gap-[10px] px-[12px] py-[8px] cursor-pointer hover:bg-[var(--color-hover-bg)] transition-colors"
          :class="theme.currentThemeId === t.id ? 'bg-[var(--color-hover-bg)]' : ''"
          @click="selectTheme(t.id)"
        >
          <!-- 色板预览 -->
          <div class="flex flex-row items-center gap-[2px] shrink-0">
            <div
              v-for="(color, ci) in t.swatch"
              :key="ci"
              class="w-[14px] h-[14px] rounded-[3px] border border-[var(--color-border)]"
              :style="{ backgroundColor: color }"
            ></div>
          </div>
          <!-- 名称 + 描述 -->
          <div class="flex flex-col items-start flex-1 min-w-0">
            <span class="text-[11px] font-[600] text-[var(--color-body)]">{{ t.name }}</span>
            <span class="text-[9px] text-[var(--color-muted)] truncate w-full">{{ t.description }}</span>
          </div>
          <!-- 当前选中标记 -->
          <i v-if="theme.currentThemeId === t.id" class="fa-solid fa-check text-[10px] text-[var(--color-primary)] shrink-0"></i>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useThemeStore, type ThemeId } from '../stores/theme'

const theme = useThemeStore()

const popupOpen = ref(false)
const popupPos = ref({ x: 0, y: 0 })

function togglePopup(e: MouseEvent) {
  popupOpen.value = !popupOpen.value
  if (popupOpen.value) {
    const el = e.currentTarget as HTMLElement
    const rect = el.getBoundingClientRect()
    // 弹窗向左对齐（因为 ThemePicker 在 StatusBar 右侧）
    popupPos.value = {
      x: rect.right - 280,
      y: rect.bottom + 4,
    }
  }
}

function selectTheme(id: ThemeId) {
  theme.setTheme(id)
  popupOpen.value = false
}

const onGlobalClick = () => { popupOpen.value = false }

onMounted(() => {
  document.addEventListener('click', onGlobalClick)
})
onUnmounted(() => {
  document.removeEventListener('click', onGlobalClick)
})
</script>
