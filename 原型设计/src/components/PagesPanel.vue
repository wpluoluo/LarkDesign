<template>
  <div class="flex flex-col justify-start items-stretch w-[200px] bg-[var(--color-white)] border-r border-[var(--color-border)] shrink-0">
    <!-- Tabs -->
    <div class="flex flex-row justify-start items-stretch border-b border-[var(--color-border)] shrink-0">
      <div class="flex flex-row justify-center items-center flex-1 h-[44px] cursor-pointer relative transition-colors duration-100" @click="activePageTab = 'pages'">
        <span class="text-[12px] leading-[16px] font-[600]" :class="activePageTab === 'pages' ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]'">页面</span>
        <div v-if="activePageTab === 'pages'" class="absolute bottom-0 left-[20%] right-[20%] h-[2px] bg-[var(--color-primary)] rounded-t-[2px]"></div>
      </div>
      <div class="flex flex-row justify-center items-center flex-1 h-[44px] cursor-pointer relative transition-colors duration-100" @click="activePageTab = 'layers'">
        <span class="text-[12px] leading-[16px] font-[600]" :class="activePageTab === 'layers' ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]'">图层</span>
        <div v-if="activePageTab === 'layers'" class="absolute bottom-0 left-[20%] right-[20%] h-[2px] bg-[var(--color-primary)] rounded-t-[2px]"></div>
      </div>
      <div class="flex flex-row justify-center items-center flex-1 h-[44px] cursor-pointer relative transition-colors duration-100" @click="activePageTab = 'assets'">
        <span class="text-[12px] leading-[16px] font-[600]" :class="activePageTab === 'assets' ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]'">资源</span>
        <div v-if="activePageTab === 'assets'" class="absolute bottom-0 left-[20%] right-[20%] h-[2px] bg-[var(--color-primary)] rounded-t-[2px]"></div>
      </div>
    </div>

    <!-- ===== PAGES TAB (Frame 大纲) ===== -->
    <template v-if="activePageTab === 'pages'">
      <!-- 工具栏 -->
      <div class="flex flex-row justify-between items-center h-[36px] px-[10px] shrink-0 border-b border-[var(--color-border-light)]">
        <div class="flex flex-row items-center gap-[6px]">
          <i class="fa-solid fa-plus text-[10px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" @click="onAddFrame" title="新建画板"></i>
          <i class="fa-solid fa-copy text-[10px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!fusion.selectedFrameId ? 'opacity-40 cursor-not-allowed' : ''" @click="onDuplicateFrame" title="复制画板"></i>
          <div class="w-[1px] h-[14px] bg-[var(--color-border)]"></div>
          <i class="fa-solid fa-arrow-up text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!canMoveFrameUp ? 'opacity-40 cursor-not-allowed' : ''" @click="onMoveFrame(-1)" title="上移画板"></i>
          <i class="fa-solid fa-arrow-down text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!canMoveFrameDown ? 'opacity-40 cursor-not-allowed' : ''" @click="onMoveFrame(1)" title="下移画板"></i>
        </div>
        <span class="text-[9px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ fusion.frames.length }} 板</span>
      </div>

      <!-- 非 Frames 模式提示 -->
      <div v-if="!fusion.isFramesMode" class="flex flex-col items-center justify-center px-[12px] py-[24px] gap-[10px]">
        <i class="fa-solid fa-file-circle-plus text-[28px] text-[var(--color-muted)] opacity-50"></i>
        <span class="text-[10px] font-[500] text-[var(--color-muted)] text-center leading-[14px]">当前文档未启用画板模式<br/>启用以使用无限画布</span>
        <button
          class="flex flex-row justify-center items-center h-[26px] px-[12px] bg-[var(--color-primary)] rounded-[4px] cursor-pointer hover:bg-[var(--color-primary-dark-700)] transition-colors"
          @click="onEnableFrames"
        >
          <i class="fa-solid fa-plus text-[9px] text-white mr-[4px]"></i>
          <span class="text-[10px] font-[600] text-white">启用画板模式</span>
        </button>
      </div>

      <!-- Frames 模式：画板列表 -->
      <div v-else class="flex-1 overflow-y-auto">
        <div
          v-for="(frame, fi) in fusion.frames"
          :key="frame.id"
          :class="[
            'flex flex-row justify-start items-center px-[8px] py-[8px] gap-[8px] cursor-pointer transition-colors border-l-[3px]',
            frame.id === fusion.selectedFrameId ? 'bg-[var(--color-hover-bg)] border-l-[var(--color-primary)]' : 'border-l-transparent hover:bg-[var(--color-panel)]'
          ]"
          @click="onSwitchFrame(frame.id)"
          @contextmenu.prevent="onFrameItemCtx(fi, $event)"
          draggable="true"
          @dragstart="onFrameDragStart(fi, $event)"
          @dragover.prevent
          @drop.prevent="onFrameDrop(fi)"
        >
          <span :class="['w-[16px] text-[10px] leading-[14px] font-[600] text-center shrink-0', frame.id === fusion.selectedFrameId ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]']">{{ fi + 1 }}</span>
          <!-- 缩略图 -->
          <div :class="['relative flex flex-col justify-between items-stretch w-[54px] h-[72px] bg-[var(--color-white)] border-2 rounded-[3px] p-[5px] shrink-0 overflow-hidden', frame.id === fusion.selectedFrameId ? 'border-[var(--color-primary)]' : 'border-[var(--color-border)]']">
            <div class="flex flex-row justify-between items-center">
              <i :class="['fa-solid', getFrameIcon(frame.type), 'text-[7px]', frame.id === fusion.selectedFrameId ? 'text-[var(--color-primary)]' : 'text-[var(--color-muted)]']"></i>
              <span v-if="frame.type === 'book-page' && frame.order" class="text-[6px] font-[600] text-[var(--color-muted)]">P{{ frame.order }}</span>
            </div>
            <div class="flex flex-col gap-[2px]">
              <div class="w-[28px] h-[2px] bg-[var(--color-border-light)] rounded-[1px]"></div>
              <div class="w-[40px] h-[28px] bg-[var(--color-panel)] rounded-[1px]"></div>
              <div class="w-[16px] h-[4px] bg-[var(--color-primary-light-300)] rounded-[1px]"></div>
            </div>
            <span v-if="frame.hidden" class="absolute top-[2px] right-[2px] text-[6px] font-[600] text-[var(--color-muted)] bg-[var(--color-white)]/80 px-[2px] rounded-[1px]">隐</span>
          </div>
          <div class="flex flex-col items-start gap-[2px] min-w-0 flex-1">
            <input
              v-if="renamingFrameId === frame.id"
              v-model="renamingFrameName"
              class="w-full text-[11px] leading-[14px] font-[600] text-[var(--color-body)] bg-[var(--color-white)] border border-[var(--color-primary)] rounded-[3px] px-[4px] py-[1px] outline-none"
              @blur="commitRenameFrame"
              @keydown.enter="commitRenameFrame"
              @keydown.escape="cancelRenameFrame"
              ref="frameRenameInputRef"
            />
            <span v-else class="text-[11px] leading-[14px] truncate w-full font-[500] text-[var(--color-tertiary)]" :class="frame.id === fusion.selectedFrameId ? 'font-[600] text-[var(--color-body)]' : ''" :title="frame.name" @dblclick="startRenameFrame(frame.id, frame.name)">{{ frame.name }}</span>
            <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ frame.children.length }} 图层</span>
            <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)] tabular-nums">{{ Math.round(frame.width) }}×{{ Math.round(frame.height) }}</span>
          </div>
          <i v-if="frame.hidden" class="fa-solid fa-eye-slash text-[8px] text-[var(--color-muted)] mr-[4px]" title="画板已隐藏"></i>
        </div>
      </div>
    </template>

    <!-- ===== LAYERS TAB ===== -->
    <template v-if="activePageTab === 'layers'">
      <!-- 图层操作工具栏 -->
      <div class="flex flex-row justify-between items-center h-[36px] px-[10px] shrink-0 border-b border-[var(--color-border-light)]">
        <span class="text-[10px] leading-[13px] font-[600] text-[var(--color-body)]">图层{{ fusion.isFramesMode ? ` · ${fusion.currentFrame?.name ?? ''}` : (fusion.isMultiPage ? ` · ${fusion.currentPage?.name ?? ''}` : '') }}</span>
        <div class="flex flex-row items-center gap-[2px]">
          <i class="fa-solid fa-plus text-[10px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" @click="onAddLayer" title="新建图层"></i>
          <i class="fa-solid fa-copy text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!fusion.selectedLayerId ? 'opacity-40 cursor-not-allowed' : ''" @click="onDuplicateLayer" title="复制图层"></i>
          <i class="fa-solid fa-trash text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-error)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!fusion.selectedLayerId ? 'opacity-40 cursor-not-allowed' : ''" @click="onDeleteLayer" title="删除图层"></i>
          <div class="w-[1px] h-[12px] bg-[var(--color-border)] mx-[2px]"></div>
          <i class="fa-solid fa-arrow-up text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!canMoveLayerUp ? 'opacity-40 cursor-not-allowed' : ''" @click="onMoveLayer(-1)" title="上移图层"></i>
          <i class="fa-solid fa-arrow-down text-[9px] text-[var(--color-secondary)] cursor-pointer hover:text-[var(--color-primary)] p-[4px] rounded-[4px] hover:bg-[var(--color-border-light)]" :class="!canMoveLayerDown ? 'opacity-40 cursor-not-allowed' : ''" @click="onMoveLayer(1)" title="下移图层"></i>
        </div>
      </div>
      <div class="flex-1 overflow-y-auto" @contextmenu.prevent="onLayerCtx($event)">
        <div
          v-for="(layer, li) in fusion.layers"
          :key="layer.id"
          class="flex flex-row items-center gap-[6px] px-[10px] py-[7px] cursor-pointer transition-colors duration-100 border-l-[3px] group"
          :class="fusion.selectedLayerId === layer.id ? 'bg-[var(--color-hover-bg)] border-l-[var(--color-primary)]' : 'border-l-transparent hover:bg-[var(--color-panel)]'"
          @click="onSelectLayer(layer.id)"
          @dblclick="onStartRenameLayer(layer.id, layer.name)"
          draggable="true"
          @dragstart="onLayerDragStart(li, $event)"
          @dragover.prevent
          @drop.prevent="onLayerDrop(li)"
          @contextmenu.prevent.stop="onLayerItemCtx(li, $event)"
        >
          <!-- 缩略图 -->
          <div class="w-[20px] h-[20px] rounded-[3px] border border-[var(--color-border-light)] flex items-center justify-center shrink-0" :class="layer.visible ? '' : 'opacity-30'">
            <i :class="['fa-solid', getLayerIcon(layer), 'text-[9px]', fusion.selectedLayerId === layer.id ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]']"></i>
          </div>
          <!-- 名称 -->
          <input
            v-if="renamingLayerId === layer.id"
            v-model="renamingLayerName"
            class="flex-1 min-w-0 text-[11px] leading-[14px] font-[600] text-[var(--color-body)] bg-[var(--color-white)] border border-[var(--color-primary)] rounded-[3px] px-[4px] py-[1px] outline-none"
            @blur="commitRenameLayer"
            @keydown.enter="commitRenameLayer"
            @keydown.escape="cancelRenameLayer"
            ref="renameInputRef"
          />
          <span v-else class="text-[11px] leading-[14px] flex-1 truncate" :class="fusion.selectedLayerId === layer.id ? 'font-[600] text-[var(--color-body)]' : 'font-[400] text-[var(--color-secondary)]'" :title="layer.name">{{ layer.name }}</span>
          <!-- 对象数 -->
          <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)] shrink-0">{{ layer.objects.length }}</span>
          <!-- 锁定 -->
          <i
            :class="['fa-solid', 'fa-lock', 'text-[8px]', 'cursor-pointer', 'transition-colors', 'p-[2px]', 'rounded-[2px]', 'hover:bg-[var(--color-border-light)]', layer.locked ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)] opacity-0 group-hover:opacity-100']"
            @click.stop="onToggleLock(layer.id)"
            :title="layer.locked ? '解锁图层' : '锁定图层'"
          ></i>
          <!-- 可见性 -->
          <i
            :class="['fa-solid', layer.visible ? 'fa-eye' : 'fa-eye-slash', 'text-[9px]', 'cursor-pointer', 'transition-colors', 'p-[2px]', 'rounded-[2px]', 'hover:bg-[var(--color-border-light)]', layer.visible ? 'text-[var(--color-muted)]' : 'text-[var(--color-error)]']"
            @click.stop="onToggleVisible(layer.id)"
            :title="layer.visible ? '隐藏图层' : '显示图层'"
          ></i>
        </div>
        <!-- 空状态 -->
        <div v-if="fusion.layers.length === 0" class="flex flex-col items-center justify-center py-[40px] gap-[8px]">
          <i class="fa-solid fa-layer-group text-[20px] text-[var(--color-muted)] opacity-50"></i>
          <span class="text-[10px] font-[500] text-[var(--color-muted)]">暂无图层</span>
          <div class="flex flex-row justify-center items-center h-[24px] px-[10px] bg-[var(--color-primary)] rounded-[4px] cursor-pointer hover:bg-[var(--color-primary-dark-700)]" @click="onAddLayer">
            <span class="text-[10px] font-[600] text-white">新建图层</span>
          </div>
        </div>
      </div>
      <!-- 图层底部状态 -->
      <div class="flex flex-row justify-between items-center h-[24px] px-[10px] border-t border-[var(--color-border-light)] text-[9px] font-[500] text-[var(--color-muted)] shrink-0">
        <span>{{ fusion.layers.length }} 个图层</span>
        <span v-if="fusion.selectedLayerId">已选: 1</span>
      </div>
    </template>

    <!-- ===== ASSETS TAB ===== -->
    <template v-if="activePageTab === 'assets'">
      <div class="flex flex-row justify-between items-center h-[36px] px-[10px] shrink-0 border-b border-[var(--color-border-light)]">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-body)]">资源管理器</span>
        <div class="flex flex-row items-center gap-[4px]">
          <div class="flex flex-row justify-center items-center w-[22px] h-[22px] rounded-[4px] cursor-pointer hover:bg-[var(--color-border-light)]" title="导入资源"><i class="fa-solid fa-upload text-[9px] text-[var(--color-secondary)]"></i></div>
          <div class="flex flex-row justify-center items-center w-[22px] h-[22px] rounded-[4px] cursor-pointer hover:bg-[var(--color-border-light)]" title="刷新"><i class="fa-solid fa-rotate text-[9px] text-[var(--color-secondary)]"></i></div>
        </div>
      </div>
      <div class="flex flex-row justify-start items-center h-[28px] mx-[8px] mt-[8px] px-[8px] gap-[6px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px]">
        <i class="fa-solid fa-magnifying-glass text-[8px] text-[var(--color-muted)]"></i>
        <input type="text" placeholder="搜索所有资源..." class="flex-1 text-[9px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)] placeholder:text-[#9AA2AC]" />
      </div>
      <div class="flex-1 overflow-y-auto px-[8px] py-[6px] flex flex-col gap-[6px]">
        <div v-for="cat in resourceCategories" :key="cat.id" class="flex flex-col border border-[var(--color-border)] rounded-[6px] overflow-hidden">
          <div class="flex flex-row justify-between items-center h-[32px] px-[8px] cursor-pointer select-none hover:bg-[var(--color-panel)]" @click="cat.expanded = !cat.expanded">
            <div class="flex flex-row items-center gap-[6px]">
              <i :class="['fa-solid', cat.icon, 'text-[9px]', 'text-[var(--color-secondary)]']"></i>
              <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">{{ cat.label }}</span>
              <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">{{ cat.count }}</span>
            </div>
            <i class="fa-solid text-[7px] text-[var(--color-muted)] transition-transform" :class="cat.expanded ? 'fa-chevron-down' : 'fa-chevron-right'"></i>
          </div>
          <div v-show="cat.expanded" class="border-t border-[var(--color-border-light)] p-[8px]">
            <div class="flex flex-row items-center gap-[4px] mb-[6px]">
              <span class="text-[7px] leading-[9px] font-[500] rounded-[3px] px-[4px] py-[1px]" :class="cat.badgeClass">{{ cat.sourceLabel }}</span>
              <span v-if="cat.syncInfo" class="text-[7px] leading-[9px] font-[400] text-[var(--color-muted)]">{{ cat.syncInfo }}</span>
            </div>
            <div class="grid grid-cols-3 gap-[4px]">
              <div v-for="item in cat.items" :key="item.id" class="flex flex-col items-center gap-[3px] p-[4px] rounded-[4px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors group">
                <div class="w-full aspect-square rounded-[3px] border border-[var(--color-border)] flex items-center justify-center overflow-hidden relative" :class="item.type === 'image' ? '' : 'bg-[var(--color-panel)]'">
                  <template v-if="item.type === 'image'"><div class="w-full h-full bg-cover bg-center" :style="{ backgroundImage: `url(${item.thumb})` }"></div></template>
                  <template v-else-if="item.type === 'icon'"><i :class="['fa-solid', item.icon || 'fa-file', 'text-[14px]', 'text-[var(--color-secondary)]']"></i></template>
                  <template v-else-if="item.type === 'color'"><div class="w-full h-full" :style="{ backgroundColor: item.color }"></div></template>
                  <template v-else><i class="fa-regular fa-file text-[14px] text-[var(--color-muted)]"></i></template>
                  <div class="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center"><i class="fa-solid fa-plus text-[10px] text-white opacity-0 group-hover:opacity-100 transition-opacity"></i></div>
                </div>
                <span class="text-[7px] leading-[9px] font-[500] text-[var(--color-muted)] truncate w-full text-center">{{ item.name }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>

  <!-- Frame Item Context Menu -->
  <ContextMenu
    :visible="frameCtxVisible"
    :x="frameCtxX"
    :y="frameCtxY"
    :items="frameCtxItems"
    @close="frameCtxVisible = false"
    @action="onFrameCtxAction"
  />

  <!-- Layer Item Context Menu -->
  <ContextMenu
    :visible="layerCtxVisible"
    :x="layerCtxX"
    :y="layerCtxY"
    :items="layerCtxItems"
    @close="layerCtxVisible = false"
    @action="onLayerCtxAction"
  />
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue'
import ContextMenu from './ContextMenu.vue'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useToastStore } from '../stores/toast'
import type { Layer, SceneObject, ContextMenuItem, FrameType } from '../types'

const fusion = useFusionDocumentStore()
const toastStore = useToastStore()
const activePageTab = ref<'pages' | 'layers' | 'assets'>('pages')

/* ════════════════ Frame 操作（无限画布画板） ════════════════ */

const renamingFrameId = ref<string | null>(null)
const renamingFrameName = ref('')
const frameRenameInputRef = ref<HTMLInputElement | null>(null)

/** 当前选中 Frame 索引 */
const currentFrameIndex = computed<number>(() =>
  fusion.selectedFrameId
    ? fusion.frames.findIndex(f => f.id === fusion.selectedFrameId)
    : -1,
)
const canMoveFrameUp = computed(() => currentFrameIndex.value > 0)
const canMoveFrameDown = computed(() =>
  currentFrameIndex.value >= 0 && currentFrameIndex.value < fusion.frames.length - 1,
)

/** 根据 Frame 类型返回图标（与 FrameView 保持一致） */
function getFrameIcon(type: FrameType): string {
  switch (type) {
    case 'single': return 'fa-file'
    case 'poster': return 'fa-image'
    case 'book-page': return 'fa-book'
    case 'spread': return 'fa-book-open'
    default: return 'fa-file'
  }
}

function onEnableFrames(): void {
  fusion.enableFramesMode()
  toastStore.show('已启用画板模式', 'fa-check', 'success')
}

function onAddFrame(): void {
  if (!fusion.isFramesMode) {
    onEnableFrames()
    return
  }
  // 在当前 Frame 右侧创建新画板（默认 single 类型）
  const cur = fusion.currentFrame
  const x = cur ? cur.x + cur.width + 80 : 0
  const y = cur ? cur.y : 0
  const frame = fusion.newFrame({ type: 'single', x, y })
  fusion.switchToFrame(frame.id)
  toastStore.show(`已新建画板「${frame.name}」`, 'fa-plus', 'success')
}

function onDuplicateFrame(): void {
  if (!fusion.selectedFrameId) return
  const frame = fusion.duplicateFrameById(fusion.selectedFrameId)
  if (frame) {
    fusion.switchToFrame(frame.id)
    toastStore.show(`已复制画板「${frame.name}」`, 'fa-copy', 'success')
  }
}

function onMoveFrame(direction: -1 | 1): void {
  if (!fusion.selectedFrameId) return
  const cur = currentFrameIndex.value
  if (cur < 0) return
  const target = cur + direction
  if (target < 0 || target >= fusion.frames.length) return
  fusion.reorderFrame(fusion.selectedFrameId, target)
}

function onSwitchFrame(frameId: string): void {
  fusion.switchToFrame(frameId)
}

function startRenameFrame(frameId: string, currentName: string): void {
  renamingFrameId.value = frameId
  renamingFrameName.value = currentName
  nextTick(() => {
    frameRenameInputRef.value?.focus()
    frameRenameInputRef.value?.select()
  })
}

function commitRenameFrame(): void {
  if (!renamingFrameId.value) return
  const newName = renamingFrameName.value.trim()
  const frameId = renamingFrameId.value
  if (newName) {
    fusion.renameFrameById(frameId, newName)
    toastStore.show(`已重命名为「${newName}」`, 'fa-pen', 'success')
  }
  renamingFrameId.value = null
  renamingFrameName.value = ''
}

function cancelRenameFrame(): void {
  renamingFrameId.value = null
  renamingFrameName.value = ''
}

// ─── 画板拖拽重排 ───
let frameDragIndex = -1
function onFrameDragStart(index: number, e: DragEvent): void {
  frameDragIndex = index
  if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move'
}
function onFrameDrop(targetIndex: number): void {
  if (frameDragIndex < 0 || frameDragIndex === targetIndex) return
  const srcFrame = fusion.frames[frameDragIndex]
  if (srcFrame) fusion.reorderFrame(srcFrame.id, targetIndex)
  frameDragIndex = -1
}

// ─── 画板右键菜单 ───
const frameCtxVisible = ref(false)
const frameCtxX = ref(0)
const frameCtxY = ref(0)
const frameCtxIndex = ref(-1)

const frameCtxItems = computed<ContextMenuItem[]>(() => {
  const idx = frameCtxIndex.value
  const hasSel = idx >= 0 && idx < fusion.frames.length
  const target = hasSel ? fusion.frames[idx] : null
  const isCurrent = target?.id === fusion.selectedFrameId
  return [
    { label: '新建画板', icon: 'fa-plus', action: 'new' },
    { label: '复制画板', icon: 'fa-copy', action: 'duplicate', disabled: !hasSel },
    { label: '重命名', icon: 'fa-pen', action: 'rename', disabled: !hasSel },
    { divider: true },
    { label: '设为当前画板', icon: 'fa-circle-dot', action: 'activate', disabled: !hasSel || isCurrent },
    { label: target?.hidden ? '显示画板' : '隐藏画板', icon: target?.hidden ? 'fa-eye' : 'fa-eye-slash', action: 'toggleHidden', disabled: !hasSel },
    { divider: true },
    { label: '上移画板', icon: 'fa-arrow-up', action: 'moveUp', disabled: !hasSel || idx <= 0 },
    { label: '下移画板', icon: 'fa-arrow-down', action: 'moveDown', disabled: !hasSel || idx >= fusion.frames.length - 1 },
    { divider: true },
    { label: '删除画板', icon: 'fa-trash', action: 'delete', disabled: !hasSel || fusion.frames.length <= 1, danger: true },
  ]
})

function onFrameItemCtx(index: number, e: MouseEvent): void {
  frameCtxIndex.value = index
  frameCtxX.value = e.clientX
  frameCtxY.value = e.clientY
  frameCtxVisible.value = true
}

function onFrameCtxAction(action: string): void {
  const idx = frameCtxIndex.value
  const frame = idx >= 0 ? fusion.frames[idx] : null
  switch (action) {
    case 'new': onAddFrame(); break
    case 'duplicate': if (frame) { fusion.switchToFrame(frame.id); onDuplicateFrame(); } break
    case 'rename': if (frame) startRenameFrame(frame.id, frame.name); break
    case 'activate': if (frame) fusion.switchToFrame(frame.id); break
    case 'toggleHidden': if (frame) fusion.toggleFrameHidden(frame.id); break
    case 'moveUp': if (frame && idx > 0) fusion.reorderFrame(frame.id, idx - 1); break
    case 'moveDown': if (frame && idx >= 0 && idx < fusion.frames.length - 1) fusion.reorderFrame(frame.id, idx + 1); break
    case 'delete':
      if (frame) {
        const name = frame.name
        fusion.deleteFrameById(frame.id)
        toastStore.show(`已删除画板「${name}」`, 'fa-trash', 'info')
      }
      break
  }
  frameCtxVisible.value = false
}

/* ════════════════ Layer 操作 ════════════════ */

const renamingLayerId = ref<string | null>(null)
const renamingLayerName = ref('')
const renameInputRef = ref<HTMLInputElement | null>(null)

/** 当前选中图层的索引 */
const selectedLayerIndex = computed<number>(() =>
  fusion.selectedLayerId
    ? fusion.layers.findIndex(l => l.id === fusion.selectedLayerId)
    : -1,
)
const canMoveLayerUp = computed(() => selectedLayerIndex.value > 0)
const canMoveLayerDown = computed(() =>
  selectedLayerIndex.value >= 0 && selectedLayerIndex.value < fusion.layers.length - 1,
)

/** 根据图层内容推断图标 */
function getLayerIcon(layer: Layer): string {
  if (layer.objects.length === 0) return 'fa-layer-group'
  const first = layer.objects[0] as SceneObject
  switch (first.type) {
    case 'text': return 'fa-font'
    case 'image': return 'fa-image'
    case 'shape': return 'fa-square'
    case 'group': return 'fa-object-group'
    case 'adjustment': return 'fa-sliders'
    case 'fill': return 'fa-fill-drip'
    default: return 'fa-layer-group'
  }
}

function onSelectLayer(layerId: string): void {
  fusion.selectLayer(layerId)
}

function onAddLayer(): void {
  const layer = fusion.newLayer()
  fusion.selectLayer(layer.id)
  toastStore.show(`已新建图层「${layer.name}」`, 'fa-plus', 'success')
}

function onDuplicateLayer(): void {
  if (!fusion.selectedLayerId) return
  fusion.cloneLayer(fusion.selectedLayerId)
  toastStore.show('已复制图层', 'fa-copy', 'success')
}

function onDeleteLayer(): void {
  if (!fusion.selectedLayerId) return
  const layer = fusion.selectedLayer
  fusion.deleteLayer(fusion.selectedLayerId)
  toastStore.show(`已删除图层「${layer?.name ?? ''}」`, 'fa-trash', 'info')
}

function onMoveLayer(direction: -1 | 1): void {
  const from = selectedLayerIndex.value
  if (from < 0) return
  const to = from + direction
  if (to < 0 || to >= fusion.layers.length) return
  fusion.reorderLayer(from, to)
}

function onToggleVisible(layerId: string): void {
  fusion.toggleLayerVisible(layerId)
}

function onToggleLock(layerId: string): void {
  fusion.toggleLayerLocked(layerId)
}

function onStartRenameLayer(layerId: string, currentName: string): void {
  renamingLayerId.value = layerId
  renamingLayerName.value = currentName
  nextTick(() => {
    renameInputRef.value?.focus()
    renameInputRef.value?.select()
  })
}

function commitRenameLayer(): void {
  if (!renamingLayerId.value) return
  const newName = renamingLayerName.value.trim()
  const layerId = renamingLayerId.value
  if (newName) {
    fusion.renameLayer(layerId, newName)
    toastStore.show(`已重命名为「${newName}」`, 'fa-pen', 'success')
  }
  renamingLayerId.value = null
  renamingLayerName.value = ''
}

function cancelRenameLayer(): void {
  renamingLayerId.value = null
  renamingLayerName.value = ''
}

// ─── 图层拖拽重排 ───
let layerDragIndex = -1
function onLayerDragStart(index: number, e: DragEvent): void {
  layerDragIndex = index
  if (e.dataTransfer) e.dataTransfer.effectAllowed = 'move'
}
function onLayerDrop(targetIndex: number): void {
  if (layerDragIndex < 0 || layerDragIndex === targetIndex) return
  fusion.reorderLayer(layerDragIndex, targetIndex)
  layerDragIndex = -1
}

// ─── 图层右键菜单 ───
const layerCtxVisible = ref(false)
const layerCtxX = ref(0)
const layerCtxY = ref(0)
const layerCtxIndex = ref(-1)
const layerCtxItems = computed<ContextMenuItem[]>(() => {
  const idx = layerCtxIndex.value
  const hasSel = idx >= 0 && idx < fusion.layers.length
  const target = hasSel ? fusion.layers[idx] : null
  return [
    { label: '新建图层', icon: 'fa-plus', action: 'add' },
    { label: '复制图层', icon: 'fa-copy', action: 'duplicate', disabled: !hasSel },
    { label: '重命名', icon: 'fa-pen', action: 'rename', disabled: !hasSel },
    { divider: true },
    { label: target?.visible ? '隐藏图层' : '显示图层', icon: target?.visible ? 'fa-eye-slash' : 'fa-eye', action: 'visible', disabled: !hasSel },
    { label: target?.locked ? '解锁图层' : '锁定图层', icon: target?.locked ? 'fa-lock-open' : 'fa-lock', action: 'lock', disabled: !hasSel },
    { divider: true },
    { label: '上移图层', icon: 'fa-arrow-up', action: 'moveUp', disabled: !hasSel || idx <= 0 },
    { label: '下移图层', icon: 'fa-arrow-down', action: 'moveDown', disabled: !hasSel || idx >= fusion.layers.length - 1 },
    { divider: true },
    { label: '删除图层', icon: 'fa-trash', action: 'delete', disabled: !hasSel, danger: true },
  ]
})

function onLayerItemCtx(index: number, e: MouseEvent): void {
  layerCtxIndex.value = index
  fusion.selectLayer(fusion.layers[index].id)
  layerCtxX.value = e.clientX
  layerCtxY.value = e.clientY
  layerCtxVisible.value = true
}

function onLayerCtx(e: MouseEvent): void {
  layerCtxIndex.value = -1
  layerCtxX.value = e.clientX
  layerCtxY.value = e.clientY
  layerCtxVisible.value = true
}

function onLayerCtxAction(action: string): void {
  const idx = layerCtxIndex.value
  const layer = idx >= 0 ? fusion.layers[idx] : null
  switch (action) {
    case 'add': onAddLayer(); break
    case 'duplicate': if (layer) { fusion.selectLayer(layer.id); onDuplicateLayer(); } break
    case 'rename': if (layer) onStartRenameLayer(layer.id, layer.name); break
    case 'visible': if (layer) onToggleVisible(layer.id); break
    case 'lock': if (layer) onToggleLock(layer.id); break
    case 'moveUp': if (idx > 0) fusion.reorderLayer(idx, idx - 1); break
    case 'moveDown': if (idx >= 0 && idx < fusion.layers.length - 1) fusion.reorderLayer(idx, idx + 1); break
    case 'delete': if (layer) { fusion.selectLayer(layer.id); onDeleteLayer(); } break
  }
  layerCtxVisible.value = false
}

// ─── Resource data ───
interface ResourceItem { id: string; name: string; type: 'image' | 'icon' | 'color' | 'other'; icon?: string; color?: string; thumb?: string }
interface ResourceCategory { id: string; label: string; icon: string; sourceLabel: string; badgeClass: string; syncInfo?: string; count: number; expanded: boolean; items: ResourceItem[] }

const resourceCategories = ref<ResourceCategory[]>([
  { id: 'cloud', label: '云端资源', icon: 'fa-cloud', sourceLabel: '来源 · 用户云端', badgeClass: 'text-[#3B82F6] bg-[#DBEAFE]', syncInfo: '已同步 2026-07-19', count: 18, expanded: true, items: [
    { id: 'c1', name: '品牌背景.jpg', type: 'image', thumb: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=100&q=60' },
    { id: 'c2', name: '纹理.png', type: 'image', thumb: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&q=60' },
    { id: 'c3', name: '项目图标集', type: 'icon', icon: 'fa-icons' },
    { id: 'c4', name: '配色方案.hpal', type: 'color', color: '#3AC487' },
    { id: 'c5', name: '海报模板.hds', type: 'icon', icon: 'fa-file' },
    { id: 'c6', name: '插图.ai', type: 'image', thumb: 'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=100&q=60' },
  ]},
  { id: 'local', label: '本地导入', icon: 'fa-folder-open', sourceLabel: '来源 · 本机文件', badgeClass: 'text-[#F59E0B] bg-[#FEF3C7]', syncInfo: '最后导入: 2026-07-18', count: 12, expanded: true, items: [
    { id: 'l1', name: '产品照片.png', type: 'image', thumb: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&q=60' },
    { id: 'l2', name: 'Logo 源文件.svg', type: 'icon', icon: 'fa-code' },
    { id: 'l3', name: '企业色板.ase', type: 'color', color: '#1E40AF' },
    { id: 'l4', name: '人物抠图.png', type: 'image', thumb: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=60' },
    { id: 'l5', name: '字体包.zip', type: 'icon', icon: 'fa-file-archive' },
    { id: 'l6', name: '背景素材.jpg', type: 'image', thumb: 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=100&q=60' },
  ]},
  { id: 'agent', label: '智能体生成', icon: 'fa-wand-magic-sparkles', sourceLabel: '来源 · AI 创作引擎', badgeClass: 'text-[#8B5CF6] bg-[#EDE9FE]', syncInfo: '缓存 12 个', count: 8, expanded: false, items: [
    { id: 'a1', name: 'AI 封面图.png', type: 'image', thumb: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?w=100&q=60' },
    { id: 'a2', name: 'AI 调色方案', type: 'color', color: '#F472B6' },
    { id: 'a3', name: 'AI 生成文案.txt', type: 'icon', icon: 'fa-file-lines' },
    { id: 'a4', name: 'AI 图标集', type: 'icon', icon: 'fa-wand-magic-sparkles' },
  ]},
  { id: 'builtin', label: '内置素材', icon: 'fa-cube', sourceLabel: '来源 · 系统预设', badgeClass: 'text-[#6B7280] bg-[#F3F4F6]', syncInfo: '只读', count: 24, expanded: false, items: [
    { id: 'b1', name: '系统图标', type: 'icon', icon: 'fa-star' },
    { id: 'b2', name: '基本色板', type: 'color', color: '#EF4444' },
    { id: 'b3', name: '基础形状', type: 'icon', icon: 'fa-shapes' },
    { id: 'b4', name: '渐变预设', type: 'color', color: '#8B5CF6' },
    { id: 'b5', name: '图案填充', type: 'icon', icon: 'fa-border-all' },
    { id: 'b6', name: '笔刷预设', type: 'icon', icon: 'fa-paintbrush' },
  ]},
])
</script>
