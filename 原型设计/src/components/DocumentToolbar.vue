<template>
  <div class="flex flex-row justify-between items-center h-[48px] bg-[var(--color-white)] border-b border-[var(--color-border)] px-[12px] shrink-0">
    <div class="flex flex-row justify-start items-center gap-[12px]">
      <!-- Document tab -->
      <div class="flex flex-row justify-start items-center h-[32px] px-[12px] gap-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[6px]">
        <i class="fa-regular fa-file-lines text-[12px] text-[var(--color-secondary)]"></i>
        <span class="text-[12px] leading-[16px] font-[600] text-[var(--color-title)]">{{ docName }}</span>
        <span v-if="unsaved" class="text-[14px] leading-[16px] font-[500] text-[var(--color-warning)]">•</span>
      </div>
      <div class="w-[1px] h-[24px] bg-[var(--color-border)]"></div>
      <!-- Tool buttons -->
      <div
        v-for="(tool, ti) in docTools"
        :key="ti"
        class="flex flex-row justify-center items-center w-[32px] h-[32px] rounded-[6px] cursor-pointer hover:bg-[var(--color-border-light)]"
        :class="{ 'opacity-40': tool.disabled }"
      >
        <i :class="['fa-solid', tool.icon, 'text-[13px]', tool.disabled ? 'text-[#9AA2AC]' : 'text-[var(--color-body)]']"></i>
      </div>
    </div>
    <div class="flex flex-row justify-end items-center gap-[12px]">
      <!-- Dark mode toggle -->
      <div class="flex flex-row justify-center items-center w-[32px] h-[32px] rounded-[6px] cursor-pointer hover:bg-[var(--color-border-light)]" @click="toggleDark" :title="isDark ? '切换亮色模式' : '切换暗色模式'">
        <i class="fa-solid text-[15px] text-[var(--color-body)]" :class="isDark ? 'fa-sun' : 'fa-moon'"></i>
      </div>
      <!-- Avatar -->
      <div class="flex flex-row justify-center items-center w-[30px] h-[30px] bg-[#263238] rounded-[15px] cursor-pointer">
        <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-white)]">{{ avatar }}</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'

withDefaults(defineProps<{
  docName?: string
  unsaved?: boolean
  orgName?: string
  settlement?: string
  creditsLabel?: string
  avatar?: string
}>(), {
  docName: '品牌画册.hds',
  unsaved: true,
  orgName: '决策设计工作室',
  settlement: '结算域 S1',
  creditsLabel: 'HDS_CREDIT 1,280',
  avatar: 'JC',
})

const docTools = [
  { icon: 'fa-rotate-left', disabled: false },
  { icon: 'fa-rotate-right', disabled: true },
  { icon: 'fa-floppy-disk', disabled: false },
]

// ─── Dark mode ───
const isDark = ref(false)

onMounted(() => {
  isDark.value = document.documentElement.classList.contains('dark')
})

const toggleDark = () => {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
}
</script>