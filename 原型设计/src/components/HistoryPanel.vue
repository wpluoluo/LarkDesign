<template>
  <div class="flex flex-col justify-start items-stretch bg-[var(--color-white)] shrink-0 overflow-y-auto border-l border-[var(--color-border)] transition-all duration-200 ease-in-out" :class="collapsed ? 'w-[36px]' : 'w-[200px]'">
    <!-- Header -->
    <div class="flex flex-row justify-between items-center h-[40px] px-[10px] border-b border-[var(--color-border)] shrink-0">
      <div class="flex flex-row items-center gap-[6px]">
        <i class="fa-solid fa-clock-rotate-left text-[11px] text-[var(--color-secondary)]"></i>
        <span v-if="!collapsed" class="text-[12px] leading-[16px] font-[700] text-[var(--color-body)]">历史记录</span>
      </div>
      <div class="flex flex-row items-center gap-[4px]">
        <i class="fa-solid fa-chevron-left text-[9px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)] p-[4px] rounded-[4px] hover:bg-[var(--color-panel)] transition-all duration-150" :class="collapsed ? 'fa-rotate-180' : ''" @click="collapsed = !collapsed" :title="collapsed ? '展开' : '折叠'"></i>
        <i v-if="!collapsed" class="fa-solid fa-ellipsis text-[9px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)] p-[4px] rounded-[4px] hover:bg-[var(--color-panel)] transition-colors duration-100" title="历史记录选项"></i>
      </div>
    </div>
    <!-- Content -->
    <template v-if="!collapsed">
      <!-- Snapshot bar -->
      <div class="flex flex-row items-center h-[32px] px-[10px] gap-[4px] border-b border-[var(--color-border-light)] bg-[var(--color-panel)]">
        <i class="fa-solid fa-camera text-[8px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)]" title="新建快照" @click="onSnapshot"></i>
        <div class="flex-1"></div>
        <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">{{ fusion.undoStack.length }} 步</span>
      </div>
      <!-- Undo/Redo buttons -->
      <div class="flex flex-row items-center h-[24px] px-[10px] gap-[6px]">
        <i class="fa-solid fa-backward-step text-[8px] cursor-pointer transition-colors" :class="fusion.canUndo ? 'text-[var(--color-tertiary)] hover:text-[var(--color-primary)]' : 'text-[var(--color-border)]'" title="撤销" @click="onUndo"></i>
        <div class="flex-1 h-[3px] bg-[var(--color-border)] rounded-[2px] overflow-hidden cursor-pointer" title="拖动回退" @click="onSliderClick">
          <div class="h-full bg-[var(--color-primary)] rounded-[2px] transition-all duration-150" :style="{ width: undoProgress + '%' }"></div>
        </div>
        <i class="fa-solid fa-forward-step text-[8px] cursor-pointer transition-colors" :class="fusion.canRedo ? 'text-[var(--color-tertiary)] hover:text-[var(--color-primary)]' : 'text-[var(--color-border)]'" title="重做" @click="onRedo"></i>
      </div>
      <!-- History list -->
      <div class="flex flex-col justify-start items-stretch flex-1 overflow-y-auto">
        <!-- 空状态 -->
        <div v-if="historyList.length === 0" class="flex flex-col items-center justify-center py-[40px] gap-[8px]">
          <i class="fa-solid fa-clock-rotate-left text-[20px] text-[var(--color-muted)] opacity-50"></i>
          <span class="text-[10px] font-[500] text-[var(--color-muted)]">暂无历史记录</span>
          <span class="text-[9px] text-[var(--color-muted)]">操作文档后会自动记录</span>
        </div>
        <!-- 历史项（从新到旧） -->
        <div
          v-for="(item, i) in historyList"
          :key="item.key"
          class="flex flex-row justify-between items-center px-[10px] py-[5px] cursor-pointer border-l-[3px] transition-all duration-100"
          :class="item.current
            ? 'bg-[var(--color-hover-bg)] border-l-[var(--color-primary)]'
            : item.future
              ? 'border-l-transparent hover:bg-[var(--color-panel)] opacity-50'
              : 'border-l-transparent hover:bg-[var(--color-panel)]'"
          @click="onItemClick(item)"
          :title="item.timestamp ? new Date(item.timestamp).toLocaleString() : ''"
        >
          <div class="flex flex-row items-center gap-[6px] min-w-0 flex-1">
            <div class="flex flex-row justify-center items-center w-[14px]">
              <i v-if="item.current" class="fa-solid fa-arrow-left text-[8px] text-[var(--color-primary-dark-700)]"></i>
              <span v-else class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">{{ item.index }}</span>
            </div>
            <i :class="['fa-solid', item.icon, 'text-[8px]', item.current ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]']"></i>
            <span class="text-[10px] leading-[14px] truncate" :class="item.current ? 'font-[600] text-[var(--color-body)]' : 'font-[400] text-[var(--color-secondary)]'">{{ item.label }}</span>
          </div>
          <i v-if="item.canRedo" class="fa-solid fa-rotate-right text-[7px] text-[var(--color-muted)] opacity-0 hover:opacity-100"></i>
        </div>
      </div>
      <!-- 底部信息 -->
      <div class="flex flex-row justify-between items-center h-[22px] px-[10px] border-t border-[var(--color-border-light)] text-[9px] font-[500] text-[var(--color-muted)] shrink-0">
        <span>{{ fusion.undoStack.length }} 已撤销</span>
        <span>{{ fusion.redoStack.length }} 可重做</span>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useToastStore } from '../stores/toast'
import { useFusionDocumentStore } from '../stores/fusionDocument'

const toastStore = useToastStore()
const fusion = useFusionDocumentStore()
const collapsed = ref(false)

/** 根据描述推断图标 */
function describeToIcon(desc: string): string {
  if (desc.includes('新增') || desc.includes('创建') || desc.includes('新建')) return 'fa-plus'
  if (desc.includes('删除') || desc.includes('移除')) return 'fa-trash'
  if (desc.includes('移动') || desc.includes('调整') || desc.includes('变换')) return 'fa-arrows-up-down-left-right'
  if (desc.includes('编组') || desc.includes('组')) return 'fa-object-group'
  if (desc.includes('图层')) return 'fa-layer-group'
  if (desc.includes('文字') || desc.includes('文本')) return 'fa-font'
  if (desc.includes('形状') || desc.includes('矩形') || desc.includes('椭圆')) return 'fa-square'
  if (desc.includes('图片') || desc.includes('图像')) return 'fa-image'
  if (desc.includes('蒙版')) return 'fa-circle-half-stroke'
  if (desc.includes('效果') || desc.includes('投影') || desc.includes('阴影')) return 'fa-wand-magic-sparkles'
  if (desc.includes('混合')) return 'fa-blender'
  if (desc.includes('保存')) return 'fa-floppy-disk'
  if (desc.includes('重命名')) return 'fa-pen'
  if (desc.includes('锁定')) return 'fa-lock'
  if (desc.includes('隐藏') || desc.includes('显示')) return 'fa-eye'
  if (desc.includes('复制') || desc.includes('克隆')) return 'fa-copy'
  if (desc.includes('翻转')) return 'fa-arrows-left-right'
  if (desc.includes('旋转')) return 'fa-rotate'
  return 'fa-clock-rotate-left'
}

interface HistoryItem {
  key: string
  label: string
  icon: string
  index: number
  timestamp: number
  current: boolean
  future: boolean
  canRedo: boolean
}

/** 合并 undoStack + redoStack 形成完整历史时间线 */
const historyList = computed<HistoryItem[]>(() => {
  const items: HistoryItem[] = []
  const undoLen = fusion.undoStack.length
  // undoStack：过去（从新到旧）
  for (let i = undoLen - 1; i >= 0; i--) {
    const entry = fusion.undoStack[i]
    items.push({
      key: `u-${i}-${entry.timestamp}`,
      label: entry.description,
      icon: describeToIcon(entry.description),
      index: i + 1,
      timestamp: entry.timestamp,
      current: i === undoLen - 1,
      future: false,
      canRedo: false,
    })
  }
  // redoStack：未来（从旧到新）
  for (let i = 0; i < fusion.redoStack.length; i++) {
    const entry = fusion.redoStack[i]
    items.push({
      key: `r-${i}-${entry.timestamp}`,
      label: entry.description,
      icon: describeToIcon(entry.description),
      index: undoLen + i + 2,
      timestamp: entry.timestamp,
      current: false,
      future: true,
      canRedo: true,
    })
  }
  return items
})

/** 撤销进度条（0-100） */
const undoProgress = computed(() => {
  const total = fusion.undoStack.length + fusion.redoStack.length
  if (total === 0) return 0
  return (fusion.undoStack.length / total) * 100
})

/** 点击撤销 */
function onUndo(): void {
  if (!fusion.canUndo) return
  const desc = fusion.undoStack[fusion.undoStack.length - 1].description
  fusion.undo()
  toastStore.show(`已撤销: ${desc}`, 'fa-rotate-left', 'info')
}

/** 点击重做 */
function onRedo(): void {
  if (!fusion.canRedo) return
  const desc = fusion.redoStack[fusion.redoStack.length - 1].description
  fusion.redo()
  toastStore.show(`已重做: ${desc}`, 'fa-rotate-right', 'info')
}

/** 点击历史项：根据在 undo/redo 栈中的位置回退/前进 */
function onItemClick(item: HistoryItem): void {
  if (item.current) return
  if (item.future) {
    // 前进到该项：连续 redo
    const redoCount = fusion.redoStack.length - (item.index - fusion.undoStack.length - 1)
    for (let i = 0; i < redoCount; i++) {
      fusion.redo()
    }
    toastStore.show(`前进到: ${item.label}`, 'fa-forward-step', 'info')
  } else {
    // 回退到该项：连续 undo
    const undoCount = fusion.undoStack.length - item.index
    for (let i = 0; i < undoCount; i++) {
      fusion.undo()
    }
    toastStore.show(`回退到: ${item.label}`, 'fa-backward-step', 'info')
  }
}

/** 点击进度条：撤销一步 */
function onSliderClick(): void {
  onUndo()
}

/** 新建快照（将当前状态作为新的历史点推入栈） */
function onSnapshot(): void {
  fusion.pushHistory('手动快照')
  toastStore.show('已创建快照', 'fa-camera', 'success')
}
</script>
