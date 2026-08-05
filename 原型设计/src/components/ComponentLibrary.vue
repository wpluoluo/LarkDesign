<template>
  <div class="flex flex-col justify-start items-stretch w-[280px] bg-[var(--color-white)] border-r border-[var(--color-border)] shrink-0 overflow-y-auto">
    <!-- Header -->
    <div class="flex flex-col justify-start items-stretch p-[12px] gap-[12px] border-b border-[var(--color-border)]">
      <div class="flex flex-row justify-between items-center">
        <span class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">组件库</span>
      </div>
      <!-- Search -->
      <div class="flex flex-row justify-start items-center h-[32px] px-[10px] gap-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[6px]">
        <i class="fa-solid fa-magnifying-glass text-[11px] text-[var(--color-muted)]"></i>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="搜索组件..."
          class="flex-1 text-[12px] leading-[16px] font-[400] text-[var(--color-body)] bg-transparent border-none outline-none placeholder:text-[var(--color-muted)]"
        />
      </div>
      <!-- Tabs -->
      <div class="flex flex-row justify-start items-center gap-[12px]">
        <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-primary-dark-700)] cursor-pointer">图标</span>
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-muted)] cursor-pointer">模板</span>
      </div>
    </div>
    <!-- Categories -->
    <div
      v-for="cat in filteredCategories"
      :key="cat.name"
      class="flex flex-col justify-start items-stretch border-b border-[var(--color-border-light)]"
    >
      <div class="flex flex-row justify-between items-center px-[12px] py-[8px] cursor-pointer hover:bg-[var(--color-panel)]">
        <div class="flex flex-row justify-start items-center gap-[8px]">
          <i class="fa-solid fa-chevron-down text-[8px] text-[var(--color-muted)]"></i>
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-body)]">{{ cat.name }}</span>
        </div>
        <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ cat.count }} 组件</span>
      </div>
      <div class="flex flex-col justify-start items-stretch px-[12px] pb-[8px] gap-[6px]">
        <div
          v-for="(item, ii) in cat.items"
          :key="ii"
          class="flex flex-col justify-start items-stretch gap-[4px] py-[4px]"
        >
          <!-- Form Input (special rendering for famous components) -->
          <template v-if="cat.name === '表单输入' && item.name === '输入框'">
            <div class="flex flex-row justify-start items-center h-[32px] px-[10px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[6px]">
              <span class="text-[11px] leading-[14px] font-[400] text-[var(--color-muted)]">请输入文本...</span>
            </div>
          </template>
          <template v-else-if="cat.name === '表单输入' && item.name === '选项'">
            <div class="flex flex-row justify-start items-center gap-[12px]">
              <div class="flex flex-row justify-start items-center gap-[6px]">
                <div class="w-[14px] h-[14px] border border-[var(--color-border)] rounded-[3px] cursor-pointer hover:border-[var(--color-primary)]"></div>
                <span class="text-[11px] leading-[14px] font-[400] text-[var(--color-body)]">选项 A</span>
              </div>
              <div class="flex flex-row justify-start items-center gap-[6px]">
                <div class="w-[14px] h-[14px] border border-[var(--color-primary)] rounded-[3px] bg-[var(--color-hover-bg)] cursor-pointer"></div>
                <span class="text-[11px] leading-[14px] font-[400] text-[var(--color-body)]">选项 B</span>
              </div>
            </div>
          </template>
          <template v-else-if="cat.name === '导航'">
            <div class="flex flex-row justify-start items-center gap-[12px]">
              <span
                v-for="(nav, ni) in ['首页', '项目', '设置', '所有项目']"
                :key="ni"
                :class="[
                  'text-[11px] leading-[14px] cursor-pointer',
                  ni === 0 ? 'font-[600] text-[var(--color-primary-dark-700)]' : 'font-[400] text-[var(--color-secondary)] hover:text-[var(--color-body)]'
                ]"
              >{{ nav }}</span>
            </div>
          </template>
          <template v-else-if="cat.name === '反馈提示'">
            <div class="flex flex-col justify-start items-stretch gap-[4px]">
              <div class="flex flex-row justify-start items-center gap-[6px] px-[8px] py-[6px] bg-[#EDF9F4] border border-[#B8EAD4] rounded-[4px]">
                <i class="fa-solid fa-circle-check text-[10px] text-[var(--color-success)]"></i>
                <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-primary-dark-700)]">操作成功 · 文档已保存</span>
              </div>
              <div class="flex flex-row justify-start items-center gap-[6px] px-[8px] py-[6px] bg-[#FFF8E8] border border-[#F4D48A] rounded-[4px]">
                <i class="fa-solid fa-circle-exclamation text-[10px] text-[var(--color-warning)]"></i>
                <span class="text-[10px] leading-[12px] font-[500] text-[#7A5314]">注意 · 尚有未保存的更改</span>
              </div>
              <div class="flex flex-row justify-start items-center gap-[6px] px-[8px] py-[6px] bg-[#FFF0F0] border border-[#F5B7B7] rounded-[4px]">
                <i class="fa-solid fa-circle-xmark text-[10px] text-[var(--color-error)]"></i>
                <span class="text-[10px] leading-[12px] font-[500] text-[#991B1B]">错误 · 无法读取文件格式</span>
              </div>
            </div>
          </template>
          <template v-else-if="cat.name === '数据展示'">
            <table class="w-full text-[10px] leading-[14px]">
              <thead>
                <tr class="text-[var(--color-muted)] font-[500]">
                  <td class="py-[4px] pr-[8px]">名称</td>
                  <td class="py-[4px] pr-[8px]">类型</td>
                  <td class="py-[4px] pr-[8px]">大小</td>
                  <td class="py-[4px]">修改时间</td>
                </tr>
              </thead>
              <tbody>
                <tr class="text-[var(--color-secondary)] border-t border-[var(--color-border-light)]">
                  <td class="py-[4px] pr-[8px] font-[500]">封面.psd</td>
                  <td class="py-[4px] pr-[8px]">图像</td>
                  <td class="py-[4px] pr-[8px]">2.4 MB</td>
                  <td class="py-[4px]">今天 10:23</td>
                </tr>
                <tr class="text-[var(--color-secondary)] border-t border-[var(--color-border-light)]">
                  <td class="py-[4px] pr-[8px] font-[500]">品牌画册.hds</td>
                  <td class="py-[4px] pr-[8px]">文档</td>
                  <td class="py-[4px] pr-[8px]">840 KB</td>
                  <td class="py-[4px]">昨天 16:45</td>
                </tr>
              </tbody>
            </table>
          </template>
          <div v-else class="text-[11px] leading-[14px] font-[400] text-[var(--color-secondary)]">{{ item.name }}</div>
        </div>
      </div>
    </div>
    <!-- Footer -->
    <div class="flex flex-row justify-start items-center px-[12px] py-[8px] border-t border-[var(--color-border)]">
      <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">36 个组件 · 4 个分类</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import type { ComponentCategory } from '../types'

const searchQuery = ref('')

const categories: ComponentCategory[] = [
  {
    name: '表单输入',
    count: 12,
    items: [
      { name: '输入框', description: '文本输入字段' },
      { name: '选项', description: '复选框和单选' },
    ],
  },
  {
    name: '导航',
    count: 8,
    items: [
      { name: '导航栏', description: '页面导航链接' },
    ],
  },
  {
    name: '反馈提示',
    count: 6,
    items: [
      { name: '成功提示', description: '操作成功消息' },
      { name: '警告提示', description: '注意消息' },
      { name: '错误提示', description: '错误消息' },
    ],
  },
  {
    name: '数据展示',
    count: 10,
    items: [
      { name: '文件列表', description: '资源文件表格' },
    ],
  },
]

const filteredCategories = computed(() => {
  if (!searchQuery.value) return categories
  const q = searchQuery.value.toLowerCase()
  return categories.filter(c =>
    c.name.toLowerCase().includes(q) ||
    c.items.some(i => i.name.toLowerCase().includes(q))
  ).map(c => ({
    ...c,
    items: c.items.filter(i => i.name.toLowerCase().includes(q)),
  }))
})
</script>