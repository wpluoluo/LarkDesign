<template>
  <div class="flex flex-col justify-start items-stretch p-[24px] gap-[24px] bg-[var(--color-panel)]">
    <!-- Brand colors -->
    <div class="flex flex-col gap-[12px]">
      <span class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">品牌色</span>
      <div class="grid grid-cols-5 gap-[8px]">
        <div
          v-for="color in brandColors"
          :key="color.name"
          class="flex flex-col items-start gap-[4px]"
        >
          <div
            class="w-full h-[40px] rounded-[6px] border border-[var(--color-border)]"
            :style="{ backgroundColor: color.hex }"
          ></div>
          <span class="text-[9px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ color.name }}</span>
          <span class="text-[9px] leading-[12px] font-[600] text-[var(--color-body)]">{{ color.hex }}</span>
        </div>
      </div>
    </div>
    <!-- Brand scale -->
    <div class="flex flex-col gap-[12px]">
      <span class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">品牌色阶</span>
      <div class="flex flex-row gap-[4px]">
        <div
          v-for="(c, i) in brandScale"
          :key="i"
          class="flex-1 h-[32px] rounded-[4px] flex items-end justify-center pb-[2px]"
          :style="{ backgroundColor: c.hex }"
        >
          <span class="text-[8px] leading-[10px] font-[500]" :class="c.darkText ? 'text-[#222]' : 'text-[#fff]'">{{ c.label }}</span>
        </div>
      </div>
    </div>
    <!-- Functional colors -->
    <div class="flex flex-col gap-[12px]">
      <span class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">功能色</span>
      <div class="grid grid-cols-4 gap-[8px]">
        <div
          v-for="color in functionalColors"
          :key="color.name"
          class="flex flex-col items-start gap-[4px]"
        >
          <div
            class="w-full h-[40px] rounded-[6px]"
            :style="{ backgroundColor: color.hex }"
          ></div>
          <span class="text-[9px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ color.name }}</span>
          <span class="text-[9px] leading-[12px] font-[600] text-[var(--color-body)]">{{ color.hex }}</span>
        </div>
      </div>
    </div>
    <!-- Neutral colors -->
    <div class="flex flex-col gap-[12px]">
      <span class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">中性色</span>
      <div class="grid grid-cols-5 gap-[8px]">
        <div
          v-for="color in neutralColors"
          :key="color.name"
          class="flex flex-col items-start gap-[4px]"
        >
          <div
            class="w-full h-[40px] rounded-[6px] border border-[var(--color-border)]"
            :style="{ backgroundColor: color.hex }"
          ></div>
          <span class="text-[9px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ color.name }}</span>
          <span class="text-[9px] leading-[12px] font-[600] text-[var(--color-body)]">{{ color.hex }}</span>
        </div>
      </div>
    </div>
    <!-- Footer -->
    <div class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">
      色彩系统 · 设计令牌 · 16 色 · 3 分组
    </div>
  </div>
</template>

<script setup lang="ts">
import type { ColorToken } from '../types'

const brandColors: ColorToken[] = [
  { name: 'Dark 900', value: '品牌深色', hex: '#0D5A3D' },
  { name: 'Dark 700', value: '品牌深色', hex: '#16865F' },
  { name: 'Primary', value: '品牌主色', hex: '#30D158' },
  { name: 'Light 300', value: '品牌浅色', hex: '#9EDDC0' },
  { name: 'Light 100', value: '品牌浅色', hex: '#DDF5EA' },
]

const brandScale = [
  { label: '900', hex: '#0D5A3D', darkText: false },
  { label: '800', hex: '#0F7349', darkText: false },
  { label: '700', hex: '#16865F', darkText: false },
  { label: '600', hex: '#1FA876', darkText: false },
  { label: '500', hex: '#2AC487', darkText: false },
  { label: '400', hex: '#30D158', darkText: false },
  { label: '300', hex: '#9EDDC0', darkText: true },
  { label: '200', hex: '#BEEBD5', darkText: true },
  { label: '100', hex: '#DDF5EA', darkText: true },
  { label: '50', hex: '#EEFBF4', darkText: true },
]

const functionalColors: ColorToken[] = [
  { name: '信息', value: 'Info', hex: '#3B82F6' },
  { name: '成功', value: 'Success', hex: '#22C55E' },
  { name: '警告', value: 'Warning', hex: '#F59E0B' },
  { name: '错误', value: 'Error', hex: '#EF4444' },
]

const neutralColors: ColorToken[] = [
  { name: '标题', value: 'Title', hex: '#F5F5F7' },
  { name: '正文', value: 'Body', hex: '#98989D' },
  { name: '次要', value: 'Secondary', hex: '#6E6E72' },
  { name: '边框', value: 'Border', hex: '#48484A' },
  { name: '面板', value: 'Panel', hex: '#2C2C2E' },
]

// The neutral colors from the PDF are for dark theme. Let me also include light theme neutrals.
// Actually, looking at the PDF more carefully, the neutral colors shown (F5F5F7, 98989D, etc.) are for dark theme.
// For the components I've built with light theme, let me also show the light theme neutrals.

// But wait - the user's design in the PDF shows specific colors. Let me just render what's in the design.
</script>