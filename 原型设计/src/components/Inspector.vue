<template>
  <div
    class="flex flex-col justify-start items-stretch bg-[var(--color-white)] border-l border-[var(--color-border)] shrink-0 overflow-y-auto w-[300px] transition-all duration-200"
  >
    <!-- Tabs -->
    <div class="flex flex-row justify-start items-center h-[44px] px-[12px] gap-[4px] border-b border-[var(--color-border)] shrink-0 bg-[var(--color-panel)]">
      <span
        v-for="tab in inspectorTabs"
        :key="tab.id"
        :class="tabClass(tab.id)"
        @click="activeTab = tab.id"
      >
        <i v-if="tab.icon" :class="['fa-solid', tab.icon, 'text-[11px]']"></i>
        {{ tab.label }}
      </span>
      <!-- Window settings gear -->
      <i class="fa-solid fa-gear text-[12px] text-[var(--color-muted)] cursor-pointer ml-auto hover:text-[var(--color-body)] hover:rotate-45 transition-all duration-200 p-[6px] rounded-[5px] hover:bg-[var(--color-hover-bg)]" @click="showWindowSettings = true" title="窗口设置"></i>
    </div>

    <!-- ==================== DESIGN TAB ==================== -->
    <template v-if="activeTab === 'design'">
      <!-- Selected element indicator -->
      <div class="flex flex-row items-center gap-[8px] px-[14px] h-[40px] border-b border-[var(--color-border-light)] shrink-0" :class="selectedObjectName ? 'bg-[var(--color-hover-bg)]' : ''">
        <div class="w-[10px] h-[10px] rounded-[3px]" :class="selectedObjectName ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-border)]'"></div>
        <span class="text-[13px] leading-[16px] font-[600]" :class="selectedObjectName ? 'text-[var(--color-body)]' : 'text-[var(--color-muted)]'">{{ selectedObjectName || '未选中元素' }}</span>
        <div v-if="selectedObjectName" class="flex flex-row items-center gap-[8px] ml-auto">
          <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase tracking-wide">已选中</span>
          <i class="fa-solid fa-xmark text-[11px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-error)]" @click="deselectAll" title="取消选中"></i>
        </div>
      </div>
      <!-- 画板 (Frame) 属性 -->
      <div v-if="hasFrame" class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.frame = !sections.frame">
          <div class="flex flex-row items-center gap-[8px]">
            <i :class="['fa-solid', frameTypeIcon, 'text-[11px] text-[var(--color-primary)]']"></i>
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">画板</span>
          </div>
          <i class="fa-solid text-[10px] text-[var(--color-muted)] transition-transform duration-150" :class="sections.frame ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.frame" class="px-[14px] pb-[14px]">
          <!-- 画板名称 -->
          <div class="mb-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">名称</span>
              <input type="text" v-model="frameName" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none" />
            </label>
          </div>
          <!-- 画板类型 + 序号 -->
          <div class="grid grid-cols-2 gap-[8px] mb-[8px]">
            <div class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">类型</span>
              <span class="flex-1 text-[12px] font-[500] text-[var(--color-body)] text-right">{{ frameTypeLabel }}</span>
            </div>
            <div class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">序号</span>
              <span class="flex-1 text-[12px] font-[500] text-[var(--color-body)] text-right">{{ frameOrderLabel }}</span>
            </div>
          </div>
          <!-- 位置 X/Y -->
          <div class="grid grid-cols-2 gap-[8px] mb-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">X</span>
              <input type="number" v-model.number="frameX" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right" />
              <span class="text-[10px] text-[var(--color-muted)]">px</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">Y</span>
              <input type="number" v-model.number="frameY" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right" />
              <span class="text-[10px] text-[var(--color-muted)]">px</span>
            </label>
          </div>
          <!-- 尺寸 W/H -->
          <div class="grid grid-cols-2 gap-[8px] mb-[10px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">W</span>
              <input type="number" v-model.number="frameW" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right" />
              <span class="text-[10px] text-[var(--color-muted)]">px</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">H</span>
              <input type="number" v-model.number="frameH" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right" />
              <span class="text-[10px] text-[var(--color-muted)]">px</span>
            </label>
          </div>
          <!-- 背景色 -->
          <div class="flex flex-row items-center justify-between h-[32px] mb-[10px]">
            <span class="text-[11px] font-[600] text-[var(--color-secondary)]">背景色</span>
            <div class="flex flex-row items-center gap-[6px]">
              <div class="w-[20px] h-[20px] rounded-[4px] border border-[var(--color-border-light)]" :style="{ backgroundColor: frameBackground }"></div>
              <input type="text" v-model="frameBackground" @focus="onFrameFocus" @change="onFrameChange" class="w-[88px] text-[11px] font-[500] text-[var(--color-body)] bg-[var(--color-panel)] border border-transparent rounded-[4px] px-[6px] py-[4px] outline-none focus:border-[var(--color-primary)] uppercase" />
            </div>
          </div>
          <!-- 书籍模式：页码设置 -->
          <div v-if="currentFrame?.type === 'book-page' || currentFrame?.type === 'spread'" class="flex flex-col gap-[8px] pt-[8px] border-t border-[var(--color-border-light)]">
            <div class="flex flex-row items-center justify-between h-[28px]">
              <span class="text-[11px] font-[500] text-[var(--color-secondary)]">显示页码</span>
              <div class="w-[28px] h-[16px] rounded-[8px] transition-colors cursor-pointer relative" :class="frameShowPageNumber ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-border)]'" @click="toggleFramePageNumber">
                <div class="w-[12px] h-[12px] rounded-[6px] bg-white absolute top-[2px] transition-all" :class="frameShowPageNumber ? 'left-[14px]' : 'left-[2px]'"></div>
              </div>
            </div>
            <label class="flex flex-row items-center gap-[8px] h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">页码</span>
              <input type="number" v-model.number="frameOrder" min="1" @focus="onFrameFocus" @change="onFrameChange" class="flex-1 min-w-0 bg-transparent text-[11px] font-[500] text-[var(--color-body)] border-none outline-none text-right" />
            </label>
          </div>
          <!-- 隐藏/显示画板 -->
          <div class="flex flex-row items-center justify-between pt-[8px] border-t border-[var(--color-border-light)]">
            <span class="text-[11px] font-[500] text-[var(--color-secondary)]">{{ currentFrame?.hidden ? '已隐藏' : '显示中' }}</span>
            <i :class="['fa-solid', currentFrame?.hidden ? 'fa-eye-slash text-[var(--color-error)]' : 'fa-eye text-[var(--color-muted)]', 'text-[11px] cursor-pointer hover:text-[var(--color-primary)] transition-colors']" @click="toggleFrameHidden" :title="currentFrame?.hidden ? '显示画板' : '隐藏画板'"></i>
          </div>
        </div>
      </div>
      <!-- 变换 -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.transform = !sections.transform">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">变换</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)] transition-transform duration-150" :class="sections.transform ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.transform" class="px-[14px] pb-[14px]">
          <div class="grid grid-cols-2 gap-[8px] mb-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">X</span>
              <input type="number" v-model.number="transformX" :disabled="!hasSingleSelection" @focus="onTransformFocus('移动 X')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">mm</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">Y</span>
              <input type="number" v-model.number="transformY" :disabled="!hasSingleSelection" @focus="onTransformFocus('移动 Y')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">mm</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">W</span>
              <input type="number" v-model.number="transformW" :disabled="!hasSingleSelection" @focus="onTransformFocus('修改宽度')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">mm</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[10px]">H</span>
              <input type="number" v-model.number="transformH" :disabled="!hasSingleSelection" @focus="onTransformFocus('修改高度')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">mm</span>
            </label>
          </div>
          <div class="grid grid-cols-2 gap-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[20px]">∠</span>
              <input type="number" v-model.number="transformRot" :disabled="!hasSingleSelection" @focus="onTransformFocus('旋转')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">°</span>
            </label>
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors" :class="!hasSingleSelection ? 'opacity-50' : ''">
              <span class="text-[11px] font-[700] text-[var(--color-muted)] w-[20px]">⤧</span>
              <input type="number" v-model.number="transformScale" :disabled="!hasSingleSelection" @focus="onTransformFocus('缩放')" @change="onTransformChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none text-right disabled:cursor-not-allowed" />
              <span class="text-[10px] text-[var(--color-muted)]">%</span>
            </label>
          </div>
          <!-- 链接比例 + 翻转 -->
          <div class="flex flex-row items-center justify-between mt-[10px]">
            <label class="flex flex-row items-center gap-[8px]" :class="hasSingleSelection ? 'cursor-pointer' : 'opacity-50 cursor-not-allowed'">
              <div class="w-[16px] h-[16px] rounded-[4px] border flex items-center justify-center" :class="linkRatio ? 'bg-[var(--color-primary)] border-[var(--color-primary)]' : 'border-[var(--color-border)] bg-[var(--color-white)]'" @click="hasSingleSelection && (linkRatio = !linkRatio)">
                <i v-if="linkRatio" class="fa-solid fa-link text-[8px] text-[var(--color-white)]"></i>
              </div>
              <span class="text-[11px] font-[500] text-[var(--color-secondary)]">约束比例</span>
            </label>
            <div class="flex flex-row items-center gap-[4px]">
              <div class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[5px] cursor-pointer hover:bg-[var(--color-panel)] border border-[var(--color-border-light)] transition-opacity" :class="!hasSingleSelection ? 'opacity-40 cursor-not-allowed' : ''" :title="hasSingleSelection ? '水平翻转' : ''" @click="toggleFlipH">
                <i class="fa-solid fa-arrows-left-right text-[11px]" :class="flipH ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]'"></i>
              </div>
              <div class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[5px] cursor-pointer hover:bg-[var(--color-panel)] border border-[var(--color-border-light)] transition-opacity" :class="!hasSingleSelection ? 'opacity-40 cursor-not-allowed' : ''" :title="hasSingleSelection ? '垂直翻转' : ''" @click="toggleFlipV">
                <i class="fa-solid fa-arrows-up-down text-[11px]" :class="flipV ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]'"></i>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 对齐与分布 -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.align = !sections.align">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">对齐与分布</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)] transition-transform duration-150" :class="sections.align ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.align" class="px-[14px] pb-[14px]">
          <div class="flex flex-row items-center gap-[4px] justify-between mb-[8px]">
            <div v-for="(btn, bi) in alignButtons" :key="bi" class="flex flex-row justify-center items-center flex-1 h-[32px] rounded-[5px] cursor-pointer transition-all duration-100" :title="btn.label" :class="btn.active ? 'bg-[var(--color-primary-light-100)] text-[var(--color-primary-dark-700)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300)]' : 'text-[var(--color-secondary)] hover:bg-[var(--color-panel)]'" @click="onAlignClick(bi)">
              <i :class="['fa-solid', btn.icon, 'text-[12px]']"></i>
            </div>
          </div>
          <div class="flex flex-row items-center gap-[4px] justify-between">
            <div v-for="(btn, di) in distributeButtons" :key="di" class="flex flex-row justify-center items-center flex-1 h-[32px] rounded-[5px] cursor-pointer transition-all duration-100" :title="btn.label" :class="btn.active ? 'bg-[var(--color-primary-light-100)] text-[var(--color-primary-dark-700)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300)]' : 'text-[var(--color-secondary)] hover:bg-[var(--color-panel)]'" @click="onDistributeClick(di)">
              <i :class="['fa-solid', btn.icon, 'text-[12px]']"></i>
            </div>
          </div>
        </div>
      </div>

      <!-- 外观 -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.appearance = !sections.appearance">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">外观</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.appearance ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.appearance" class="px-[14px] pb-[14px]">
          <!-- 填充色（仅 shape/fill 有 fill 字段） -->
          <div v-if="hasFill" class="flex flex-row justify-between items-center mb-[8px]">
            <div class="flex flex-row items-center gap-[8px] cursor-pointer" @click="openColorPicker($event, 'fill')">
              <div class="w-[24px] h-[24px] rounded-[5px] border border-[var(--color-border)] shadow-sm" :style="{ backgroundColor: fillColor }"></div>
              <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">填充</span>
            </div>
            <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)] cursor-pointer font-mono" @click="openColorPicker($event, 'fill')">{{ fillColor.toUpperCase() }}</span>
          </div>
          <!-- 文本色（仅 text 有 color 字段） -->
          <div v-else-if="hasTextColor" class="flex flex-row justify-between items-center mb-[8px]">
            <div class="flex flex-row items-center gap-[8px] cursor-pointer" @click="openColorPicker($event, 'color')">
              <div class="w-[24px] h-[24px] rounded-[5px] border border-[var(--color-border)] shadow-sm" :style="{ backgroundColor: textColor }"></div>
              <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">文字色</span>
            </div>
            <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)] cursor-pointer font-mono" @click="openColorPicker($event, 'color')">{{ textColor.toUpperCase() }}</span>
          </div>
          <!-- 描边（仅 shape 有 stroke 字段） -->
          <div v-if="hasStroke" class="flex flex-col gap-[8px] mb-[10px]">
            <div class="flex flex-row justify-between items-center">
              <div class="flex flex-row items-center gap-[8px] cursor-pointer" @click="openColorPicker($event, 'stroke')">
                <div class="w-[24px] h-[24px] rounded-[5px] border border-[var(--color-border)] shadow-sm" :style="{ backgroundColor: strokeColor }"></div>
                <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">描边</span>
              </div>
              <div class="flex flex-row items-center gap-[8px]">
                <input type="number" min="0" max="100" :value="strokeWidth" @focus="onAppearanceFocus('修改描边宽度')" @change="onStrokeWidthChange" class="w-[52px] h-[28px] text-[11px] font-[500] text-right bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)]" />
                <span class="text-[10px] text-[var(--color-muted)]">px</span>
              </div>
            </div>
            <!-- 描边位置 -->
            <div class="flex flex-row gap-[4px]">
              <div v-for="opt in strokePositionOptions" :key="opt.value"
                class="flex-1 flex flex-row justify-center items-center h-[28px] rounded-[4px] cursor-pointer text-[11px] font-[500] transition-colors"
                :class="strokePosition === opt.value ? 'bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
                @click="setStrokePosition(opt.value)"
              >{{ opt.label }}</div>
            </div>
          </div>
          <!-- 圆角半径（仅矩形形状） -->
          <div v-if="hasCornerRadius" class="flex flex-row justify-between items-center mb-[8px]">
            <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">圆角半径</span>
            <div class="flex flex-row items-center gap-[8px]">
              <input type="number" min="0" max="500" :value="cornerRadius" @focus="onAppearanceFocus('修改圆角半径')" @change="onCornerRadiusChange" class="w-[52px] h-[28px] text-[11px] font-[500] text-right bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)]" />
              <span class="text-[10px] text-[var(--color-muted)]">px</span>
            </div>
          </div>
          <!-- 不透明度（绑定到 transform.opacity） -->
          <div class="flex flex-row justify-between items-center mb-[8px]">
            <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">不透明度</span>
            <div class="flex flex-row items-center gap-[8px]">
              <input type="range" class="w-[90px] h-[5px] accent-[var(--color-primary)] cursor-pointer" min="0" max="100" :value="opacityValue" @input="onOpacityInput" @mousedown="onAppearanceFocus('修改不透明度')" @change="onAppearanceChange" />
              <input type="number" min="0" max="100" :value="opacityValue" @focus="onAppearanceFocus('修改不透明度')" @change="onOpacityNumberChange" class="w-[42px] h-[24px] text-[11px] font-[500] text-right bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)]" />
              <span class="text-[10px] text-[var(--color-muted)]">%</span>
            </div>
          </div>
          <!-- 混合模式（对象级 + 图层级 fallback） -->
          <div class="flex flex-row justify-between items-center mb-[8px]">
            <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-secondary)]">混合模式</span>
            <div class="flex flex-row items-center gap-[8px] cursor-pointer hover:bg-[var(--color-panel)] px-[8px] py-[4px] rounded-[5px]" @click="toggleBlendModePopup">
              <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">{{ currentBlendLabel }}</span>
              <i class="fa-solid fa-chevron-down text-[10px] text-[var(--color-muted)]"></i>
            </div>
            <!-- Inline blend mode popup -->
            <Teleport to="body">
              <div v-if="showBlendModePopup" class="fixed z-[150] w-[170px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg py-[4px] max-h-[280px] overflow-y-auto" :style="blendPopupStyle" @click.stop>
                <div v-for="opt in BLEND_MODE_OPTIONS" :key="opt.value" class="flex flex-row justify-between items-center h-[28px] px-[12px] cursor-pointer hover:bg-[var(--color-hover-bg)]" :class="currentBlendValue === opt.value ? 'bg-[var(--color-hover-bg)]' : ''" @click="setBlendMode(opt.value)">
                  <span class="text-[12px] leading-[15px] font-[500] text-[var(--color-body)]">{{ opt.label }}</span>
                  <span v-if="currentBlendValue === opt.value" class="text-[10px] text-[var(--color-primary)]">✓</span>
                </div>
              </div>
            </Teleport>
          </div>
          <!-- 图层效果链 fx -->
          <div class="flex flex-col gap-[8px] pt-[8px] border-t border-[var(--color-border-light)]">
            <div class="flex flex-row justify-between items-center h-[24px]">
              <span class="text-[11px] font-[600] text-[var(--color-muted)] uppercase tracking-wider">图层样式</span>
              <i class="fa-solid fa-plus text-[11px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-primary)]" title="添加图层样式" @click="showFxMenu = !showFxMenu"></i>
            </div>
            <!-- fx 添加菜单 -->
            <div v-if="showFxMenu" class="flex flex-col gap-[4px] bg-[var(--color-panel)] rounded-[5px] p-[3px] border border-[var(--color-border-light)]">
              <div v-for="opt in fxAvailableTypes" :key="opt.value"
                class="flex flex-row items-center h-[28px] px-[8px] cursor-pointer hover:bg-[var(--color-hover-bg)] rounded-[4px]"
                @click="addFx(opt.value)"
              >
                <i :class="[opt.icon, 'text-[11px] text-[var(--color-muted)] mr-[8px]']"></i>
                <span class="text-[11px] font-[500] text-[var(--color-secondary)]">{{ opt.label }}</span>
              </div>
            </div>
            <!-- 已有 fx 列表 -->
            <div v-for="fx in currentEffects" :key="fx.id" class="flex flex-row justify-between items-center cursor-pointer hover:bg-[var(--color-border-light)] rounded-[5px] p-[6px]" @click="openFxEditor(fx.id)">
              <div class="flex flex-row items-center gap-[8px]">
                <i class="fa-regular text-[12px] cursor-pointer" :class="fx.enabled ? 'fa-square-check text-[var(--color-primary)]' : 'fa-square text-[var(--color-muted)]'" @click.stop="toggleFx(fx.id)"></i>
                <i :class="[fxIcon(fx.type), 'text-[12px]', fx.enabled ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]']"></i>
                <span class="text-[11px] leading-[14px] font-[500]" :class="fx.enabled ? 'text-[var(--color-secondary)]' : 'text-[var(--color-muted)]'">{{ fxLabel(fx.type) }}</span>
              </div>
              <div class="flex flex-row items-center gap-[8px]">
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">{{ fxSummary(fx) }}</span>
                <i class="fa-solid fa-trash text-[10px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-error)]" @click.stop="removeFx(fx.id)"></i>
              </div>
            </div>
            <div v-if="currentEffects.length === 0" class="text-[11px] text-[var(--color-muted)] text-center py-[8px]">暂无图层样式</div>
          </div>
        </div>
      </div>

      <!-- 颜色选择器弹窗 -->
      <ColorPickerPopover
        :visible="colorPicker.visible"
        :anchor-x="colorPicker.x"
        :anchor-y="colorPicker.y"
        :model-value="colorPicker.value"
        :opacity="100"
        @update:model-value="onColorPick"
        @close="closeColorPicker"
      />

      <!-- 文字 -->
      <div v-if="isTextObject" class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.typography = !sections.typography">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">文字</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.typography ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.typography" class="px-[14px] pb-[14px]">
          <!-- 文字内容 -->
          <div class="mb-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">内容</span>
              <input type="text" v-model="textContent" @change="onTextContentChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none" placeholder="输入文字..." />
            </label>
          </div>
          <!-- 字体选择 -->
          <div class="mb-[8px]">
            <label class="flex flex-row items-center gap-[8px] h-[32px] px-[8px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">字体</span>
              <select v-model="textFontFamily" @change="onTextFontChange" class="flex-1 min-w-0 bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none cursor-pointer">
                <option value="HarmonyOS Sans SC">HarmonyOS Sans SC</option>
                <option value="Inter">Inter</option>
                <option value="Noto Sans SC">Noto Sans SC</option>
                <option value="Microsoft YaHei">微软雅黑</option>
                <option value="SimSun">宋体</option>
                <option value="SimHei">黑体</option>
                <option value="KaiTi">楷体</option>
                <option value="FangSong">仿宋</option>
                <option value="JetBrains Mono">JetBrains Mono</option>
                <option value="Consolas">Consolas</option>
              </select>
            </label>
          </div>
          <!-- 字号/行距/字距 -->
          <div class="grid grid-cols-3 gap-[6px] mb-[8px]">
            <label class="flex flex-col gap-[2px] px-[6px] py-[4px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[9px] font-[600] text-[var(--color-muted)] uppercase">字号</span>
              <input type="number" v-model.number="textFontSize" @change="onTextFontChange" min="6" max="400" class="w-full bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none" />
            </label>
            <label class="flex flex-col gap-[2px] px-[6px] py-[4px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[9px] font-[600] text-[var(--color-muted)] uppercase">行距</span>
              <input type="number" v-model.number="textLineHeight" @change="onTextFontChange" min="0.5" max="5" step="0.1" class="w-full bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none" />
            </label>
            <label class="flex flex-col gap-[2px] px-[6px] py-[4px] bg-[var(--color-panel)] rounded-[5px] border border-transparent hover:border-[var(--color-border)] transition-colors">
              <span class="text-[9px] font-[600] text-[var(--color-muted)] uppercase">字距</span>
              <input type="number" v-model.number="textLetterSpacing" @change="onTextFontChange" step="0.5" class="w-full bg-transparent text-[12px] font-[500] text-[var(--color-body)] border-none outline-none" />
            </label>
          </div>
          <!-- 字重选择 -->
          <div class="mb-[8px]">
            <div class="flex flex-row items-center gap-[6px] flex-wrap">
              <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase w-[28px]">字重</span>
              <div
                v-for="w in fontWeightOptions"
                :key="w.value"
                :class="['flex flex-row justify-center items-center px-[8px] h-[24px] rounded-[4px] cursor-pointer text-[10px] font-[500] transition-colors', textFontWeight === w.value ? 'bg-[var(--color-primary)] text-white' : 'bg-[var(--color-panel)] text-[var(--color-secondary)] hover:bg-[var(--color-border-light)]']"
                @click="setTextFontWeight(w.value)"
              >{{ w.label }}</div>
            </div>
          </div>
          <!-- 样式按钮（B/I/U + 对齐） -->
          <div class="flex flex-row items-center gap-[2px] mb-[8px] flex-wrap">
            <div
              v-for="(btn, bi) in typeStyleBtns"
              :key="bi"
              :class="['flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[4px] cursor-pointer transition-colors', btn.active ? 'bg-[var(--color-primary)] text-white' : 'hover:bg-[var(--color-border-light)] text-[var(--color-secondary)]']"
              :title="btn.title"
              @click="onTypeStyleClick(btn)"
            >
              <span v-if="btn.type === 'text'" :class="['text-[12px]', btn.cssClass]">{{ btn.label }}</span>
              <i v-else :class="['fa-solid', btn.icon, 'text-[12px]']"></i>
            </div>
          </div>
          <!-- 文字颜色 -->
          <div class="flex flex-row items-center justify-between h-[32px] mb-[8px]">
            <span class="text-[10px] font-[600] text-[var(--color-muted)] uppercase">文字色</span>
            <div class="flex flex-row items-center gap-[6px]">
              <div class="w-[20px] h-[20px] rounded-[4px] border border-[var(--color-border-light)]" :style="{ backgroundColor: textColor }"></div>
              <input type="text" v-model="textColorValue" @change="onTextColorChange" class="w-[88px] text-[11px] font-[500] text-[var(--color-body)] bg-[var(--color-panel)] border border-transparent rounded-[4px] px-[6px] py-[4px] outline-none focus:border-[var(--color-primary)] uppercase" />
            </div>
          </div>
        </div>
      </div>

      <!-- 路径查找器 -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.pathfinder = !sections.pathfinder">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">路径查找器</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.pathfinder ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.pathfinder" class="px-[14px] pb-[14px]">
          <div class="flex flex-row items-center gap-[8px]">
            <div v-for="(op, i) in pathfinderOps" :key="i" class="flex flex-row justify-center items-center flex-1 h-[32px] rounded-[5px] cursor-pointer hover:bg-[var(--color-border-light)] border border-[var(--color-border)] text-[11px] font-[500] text-[var(--color-secondary)]" :title="op.label">{{ op.label }}</div>
          </div>
        </div>
      </div>

      <!-- 页面属性（标准化尺寸/出血/边距） -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.pageProps = !sections.pageProps">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">页面属性</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.pageProps ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.pageProps" class="px-[12px] pb-[12px]">
          <!-- 尺寸与单位 -->
          <div class="flex flex-row justify-between items-center h-[28px] mb-[6px]">
            <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)]">尺寸与单位</span>
          </div>
          <div class="flex flex-row gap-[8px] mb-[6px]">
            <div class="flex flex-row justify-center items-center flex-1 h-[28px] px-[8px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-panel)]" :class="pageSize === 'A4' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click="pageSize='A4'">A4</div>
            <div class="flex flex-row justify-center items-center flex-1 h-[28px] px-[8px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-panel)]" :class="pageSize === 'A3' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click="pageSize='A3'">A3</div>
            <div class="flex flex-row justify-center items-center flex-1 h-[28px] px-[8px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-panel)]" :class="pageSize === 'A5' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click="pageSize='A5'">A5</div>
            <div class="flex flex-row justify-center items-center flex-1 h-[28px] px-[8px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-panel)]" :class="pageSize === 'Letter' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click="pageSize='Letter'">信纸</div>
            <div class="flex flex-row justify-center items-center flex-1 h-[28px] px-[8px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-panel)]" :class="pageSize === 'Legal' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click="pageSize='Legal'">法律</div>
          </div>
          <div class="grid grid-cols-2 gap-[8px] mb-[6px]">
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">宽度</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ pageWidth }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">高度</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ pageHeight }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px] cursor-pointer"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">方向</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ pageOrientation }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px] cursor-pointer"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">单位</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ pageUnit }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px] cursor-pointer"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">DPI</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ pageDPI }}</span></div>
          </div>
          <!-- 出血设置 -->
          <div class="flex flex-row justify-between items-center h-[28px] mb-[6px] mt-[8px]">
            <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)]">出血</span>
            <label class="flex flex-row items-center gap-[4px] cursor-pointer"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">启用</span><div class="w-[28px] h-[14px] rounded-[7px] cursor-pointer flex items-center px-[2px] transition-colors" :class="bleedEnabled ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="bleedEnabled = !bleedEnabled"><div class="w-[10px] h-[10px] bg-[var(--color-white)] rounded-[5px] shadow-sm"></div></div></label>
          </div>
          <div v-show="bleedEnabled" class="grid grid-cols-2 gap-[8px] mb-[6px]">
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">上</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ bleedTop }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">下</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ bleedBottom }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">左</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ bleedLeft }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">右</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ bleedRight }}</span></div>
          </div>
          <!-- 边距 -->
          <div class="flex flex-row justify-between items-center h-[28px] mb-[6px] mt-[4px]">
            <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)]">边距</span>
            <div class="flex flex-row gap-[4px]">
              <span class="text-[10px] leading-[13px] px-[4px] py-[2px] rounded-[2px] cursor-pointer border border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]" :class="marginPreset === '窄' ? 'bg-[var(--color-hover-bg)] border-[var(--color-primary)]' : ''" @click="marginPreset='窄'">窄</span>
              <span class="text-[10px] leading-[13px] px-[4px] py-[2px] rounded-[2px] cursor-pointer border border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]" :class="marginPreset === '常规' ? 'bg-[var(--color-hover-bg)] border-[var(--color-primary)]' : ''" @click="marginPreset='常规'">常规</span>
              <span class="text-[10px] leading-[13px] px-[4px] py-[2px] rounded-[2px] cursor-pointer border border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]" :class="marginPreset === '宽' ? 'bg-[var(--color-hover-bg)] border-[var(--color-primary)]' : ''" @click="marginPreset='宽'">宽</span>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-[8px] mb-[6px]">
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">上</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ marginTop }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">下</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ marginBottom }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">左</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ marginLeft }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">右</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ marginRight }}</span></div>
          </div>
          <!-- 分栏 -->
          <div class="flex flex-row justify-between items-center h-[28px] mb-[6px] mt-[4px]">
            <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)]">分栏</span>
          </div>
          <div class="grid grid-cols-2 gap-[8px]">
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">栏数</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ columns }}</span></div>
            <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">间距</span><span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">{{ columnGutter }}</span></div>
          </div>
        </div>
      </div>

      <!-- 色彩管理 (统一使用 ColorPickerPanel) -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.colorManage = !sections.colorManage">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">色彩管理</span>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.colorManage ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.colorManage" class="px-[12px] pb-[12px]">
          <ColorPickerPanel
            v-model="currentColorHex"
            :swatches="colorSwatches"
            @select="onColorPickerSelect"
          />
        </div>
      </div>

      <!-- 画布属性 -->
      <div class="border-b border-[var(--color-border-light)]">
        <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sections.canvas = !sections.canvas">
          <div class="flex flex-row items-center gap-[8px]">
            <i class="fa-solid fa-display text-[10px] text-[var(--color-secondary)]"></i>
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">画布属性</span>
          </div>
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="sections.canvas ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
        <div v-show="!sections.canvas" class="px-[12px] pb-[12px]">
          <!-- 画布背景色 -->
          <div class="flex flex-row items-center gap-[8px] mb-[6px]">
            <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)] w-[52px]">背景色</span>
            <div class="w-[24px] h-[24px] rounded-[3px] border border-[var(--color-border)] cursor-pointer" :style="{ backgroundColor: canvasBgColor }" @click="canvasColorOpen = !canvasColorOpen"></div>
            <div class="flex flex-row justify-between items-center flex-1 h-[24px] px-[4px] bg-[var(--color-panel)] rounded-[4px]">
              <input class="w-full bg-transparent text-[10px] leading-[13px] font-[500] font-mono text-[var(--color-body)] border-none outline-none" v-model="canvasBgColor" maxlength="7" />
            </div>
          </div>
          <!-- 画布尺寸 -->
          <div class="grid grid-cols-2 gap-[4px] mb-[6px]">
            <div class="flex flex-col gap-[4px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">工作区宽度</span>
              <div class="flex flex-row items-center h-[24px] px-[4px] bg-[var(--color-panel)] rounded-[4px]">
                <input type="number" class="flex-1 bg-transparent text-[10px] leading-[13px] font-[500] text-[var(--color-body)] border-none outline-none" v-model.number="canvasWidth" min="100" />
                <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">px</span>
              </div>
            </div>
            <div class="flex flex-col gap-[4px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">工作区高度</span>
              <div class="flex flex-row items-center h-[24px] px-[4px] bg-[var(--color-panel)] rounded-[4px]">
                <input type="number" class="flex-1 bg-transparent text-[10px] leading-[13px] font-[500] text-[var(--color-body)] border-none outline-none" v-model.number="canvasHeight" min="100" />
                <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">px</span>
              </div>
            </div>
          </div>
          <!-- 网格 -->
          <div class="flex flex-col gap-[4px] mb-[6px]">
            <div class="flex flex-row justify-between items-center">
              <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">网格</span>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer">
                <div class="w-[22px] h-[12px] rounded-[6px] cursor-pointer flex items-center px-[2px] transition-colors" :class="canvasShowGrid ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="canvasShowGrid = !canvasShowGrid"><div class="w-[8px] h-[8px] bg-[var(--color-white)] rounded-[4px] shadow-sm"></div></div>
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">{{ canvasShowGrid ? '显示' : '隐藏' }}</span>
              </label>
            </div>
            <div v-show="canvasShowGrid" class="grid grid-cols-3 gap-[4px]">
              <div class="flex flex-col gap-[1px]">
                <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">网格大小</span>
                <input type="number" class="h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none bg-[var(--color-white)] text-[var(--color-body)]" v-model.number="canvasGridSize" min="1" />
              </div>
              <div class="flex flex-col gap-[1px]">
                <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">网格颜色</span>
                <div class="flex flex-row items-center gap-[4px]">
                  <input class="flex-1 h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] font-mono border border-[var(--color-border)] rounded-[3px] outline-none bg-[var(--color-white)] text-[var(--color-body)]" v-model="canvasGridColor" maxlength="7" />
                  <div class="w-[14px] h-[14px] rounded-[2px] border border-[var(--color-border)] shrink-0" :style="{ backgroundColor: canvasGridColor }"></div>
                </div>
              </div>
              <div class="flex flex-col gap-[1px]">
                <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">分段</span>
                <select class="h-[24px] text-[10px] leading-[13px] border border-[var(--color-border)] rounded-[3px] outline-none bg-[var(--color-white)] text-[var(--color-body)]" v-model.number="canvasGridDivisions">
                  <option :value="1">1</option><option :value="2">2</option><option :value="4">4</option><option :value="8">8</option>
                </select>
              </div>
            </div>
          </div>
          <!-- 吸附 -->
          <div class="flex flex-row justify-between items-center mb-[6px]">
            <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">吸附</span>
            <label class="flex flex-row items-center gap-[4px] cursor-pointer">
              <div class="w-[22px] h-[12px] rounded-[6px] cursor-pointer flex items-center px-[2px] transition-colors" :class="canvasSnap ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="canvasSnap = !canvasSnap"><div class="w-[8px] h-[8px] bg-[var(--color-white)] rounded-[4px] shadow-sm"></div></div>
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">{{ canvasSnap ? '开启' : '关闭' }}</span>
            </label>
          </div>
          <!-- 网格吸附 + 参考线吸附 -->
          <div v-show="canvasSnap" class="flex flex-row gap-[4px] mb-[6px]">
            <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none">
              <div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="canvasSnapGrid ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="canvasSnapGrid = !canvasSnapGrid"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div>
              <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-secondary)]">网格</span>
            </label>
            <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none">
              <div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="canvasSnapGuide ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="canvasSnapGuide = !canvasSnapGuide"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div>
              <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-secondary)]">参考线</span>
            </label>
          </div>
          <!-- 标尺 -->
          <div class="flex flex-row justify-between items-center mb-[6px] pt-[4px] border-t border-[var(--color-border-light)]">
            <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">标尺</span>
            <label class="flex flex-row items-center gap-[4px] cursor-pointer">
              <div class="w-[22px] h-[12px] rounded-[6px] cursor-pointer flex items-center px-[2px] transition-colors" :class="canvasShowRuler ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="canvasShowRuler = !canvasShowRuler"><div class="w-[8px] h-[8px] bg-[var(--color-white)] rounded-[4px] shadow-sm"></div></div>
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">显示标尺</span>
            </label>
          </div>
        </div>
      </div>

      <!-- 图层 -->
      <div class="border-b border-[var(--color-border-light)]">
        <!-- Header: layer count + sort -->
        <div class="flex flex-row justify-between items-center h-[40px] px-[12px]">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">图层</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ flatLayers.length }} 层</span>
        </div>
        <!-- Blend mode + opacity bar -->
        <div class="flex flex-row items-center gap-[8px] h-[40px] px-[12px] border-y border-[var(--color-border-light)] bg-[var(--color-panel)]">
          <div class="flex flex-row justify-between items-center flex-1 h-[28px] px-[8px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] cursor-pointer hover:border-[var(--color-primary)] text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">
            <span>{{ currentLayerBlendLabel }}</span>
            <i class="fa-solid fa-chevron-down text-[10px] text-[var(--color-muted)]"></i>
          </div>
          <div class="flex flex-row justify-between items-center w-[62px] h-[28px] px-[8px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] cursor-pointer hover:border-[var(--color-primary)] text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">
            <span>100%</span>
            <i class="fa-solid fa-chevron-down text-[10px] text-[var(--color-muted)]"></i>
          </div>
          <div class="flex flex-row items-center gap-[4px]">
            <i class="fa-solid fa-lock text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-title)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="锁定透明像素"></i>
            <i class="fa-solid fa-border-all text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-title)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="锁定图像像素"></i>
            <i class="fa-solid fa-location-dot text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-title)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="锁定位置"></i>
          </div>
        </div>
        <!-- Search bar -->
        <div class="flex flex-row items-center h-[28px] px-[8px] border-b border-[var(--color-border-light)]">
          <i class="fa-solid fa-magnifying-glass text-[8px] text-[var(--color-muted)] mr-[6px]"></i>
          <input type="text" placeholder="筛选图层..." class="flex-1 text-[10px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)] placeholder:text-[var(--color-muted)]" />
          <i class="fa-solid fa-arrow-up-a-z text-[10px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-title)] p-[2px]" title="排序"></i>
          <i class="fa-solid fa-sliders text-[10px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-title)] p-[2px]" title="图层筛选"></i>
        </div>
        <!-- Layer list -->
        <div class="flex flex-col justify-start items-stretch max-h-[220px] overflow-y-auto select-none" ref="layerListEl">
          <template v-for="(layer, i) in flatLayers" :key="layer._key">
            <div
              class="flex flex-row justify-between items-center h-[32px] cursor-pointer border-b border-[var(--color-border-light)] group"
              :class="[layer.active ? 'bg-[var(--color-hover-bg)]' : 'hover:bg-[var(--color-panel)]', dragOverIndex === i ? 'border-t-2 border-t-[var(--color-primary)]' : '']"
              :style="{ paddingLeft: (8 + (layer.depth || 0) * 14) + 'px' }"
              @click="selectLayerByKey(layer._key)"
              @contextmenu.prevent="onLayerContextMenu(i, $event)"
              @mousedown="onLayerDragStart($event, i)"
              @mouseenter="onLayerDragOver(i)"
              draggable="false"
            >
              <div class="flex flex-row items-center gap-[4px] flex-1 min-w-0">
                <!-- Group expand/collapse -->
                <i
                  v-if="layer.type === 'group'"
                  class="fa-solid text-[10px] text-[var(--color-muted)] cursor-pointer shrink-0 transition-transform"
                  :class="layer.expanded ? 'fa-chevron-down' : 'fa-chevron-right'"
                  @click.stop="toggleGroup(layer)"
                ></i>
                <!-- Layer thumbnail -->
                <div class="flex flex-row justify-center items-center w-[20px] h-[20px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[2px] shrink-0 overflow-hidden" :style="layer.thumbColor ? { backgroundColor: layer.thumbColor } : {}">
                  <i v-if="layer.type === 'text'" class="fa-solid fa-font text-[8px]" :class="layer.active ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-muted)]'"></i>
                  <i v-else-if="layer.type === 'image'" class="fa-solid fa-image text-[8px] text-[var(--color-muted)]"></i>
                  <i v-else-if="layer.type === 'adjustment'" class="fa-solid fa-circle-half-stroke text-[8px] text-[var(--color-muted)]"></i>
                  <i v-else-if="layer.type === 'group'" class="fa-solid fa-folder text-[8px] text-[var(--color-warning)]"></i>
                  <i v-else-if="layer.type === 'fill'" class="fa-solid fa-fill-drip text-[8px] text-[var(--color-muted)]"></i>
                  <i v-else class="fa-solid fa-square text-[8px]" :class="layer.iconColor === 'green' ? 'text-[var(--color-primary)]' : 'text-[var(--color-border)]'"></i>
                </div>
                <!-- Mask thumbnail (overlay on layer thumb when present) -->
                <div v-if="layer.hasMask" class="flex flex-row justify-center items-center w-[16px] h-[16px] -ml-[4px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[2px] shrink-0 z-[1] cursor-pointer" :title="layer.maskEnabled ? '禁用蒙版' : '启用蒙版'" @click.stop="toggleMask(layer)">
                  <div class="w-full h-full rounded-[1px]" :class="layer.maskEnabled ? 'bg-gradient-to-br from-[var(--color-white)] via-[var(--color-white)] to-[var(--color-title)]' : 'bg-[var(--color-border-light)] opacity-50'"></div>
                </div>
                <!-- Layer name -->
                <span class="text-[10px] leading-[14px] truncate flex-1" :class="layer.active ? 'font-[600] text-[var(--color-primary-dark-700)]' : 'font-[500] text-[var(--color-secondary)]'">{{ layer.name }}</span>
              </div>
              <div class="flex flex-row items-center gap-[4px] px-[4px] shrink-0">
                <!-- Add mask button (on hover) -->
                <i v-if="!layer.hasMask && layer.type !== 'group'" class="fa-regular fa-circle-dot text-[8px] text-[var(--color-muted)] opacity-0 group-hover:opacity-100 cursor-pointer hover:text-[var(--color-primary)]" title="添加图层蒙版" @click.stop="addMask(layer)"></i>
                <!-- Mask toggle -->
                <i v-if="layer.hasMask" class="fa-solid text-[8px] cursor-pointer" :class="layer.maskEnabled ? 'fa-circle text-[var(--color-primary)]' : 'fa-circle text-[var(--color-muted)]'" :title="layer.maskEnabled ? '禁用蒙版' : '启用蒙版'" @click.stop="toggleMask(layer)"></i>
                <i v-if="layer.linked" class="fa-solid fa-link text-[8px] text-[var(--color-tertiary)] cursor-pointer"></i>
                <i v-if="layer.locked" class="fa-solid fa-lock text-[10px] text-[var(--color-muted)] cursor-pointer" @click.stop="toggleLockByKey(layer._key)"></i>
                <i class="text-[10px] cursor-pointer" :class="layer.visible ? 'fa-regular fa-eye text-[var(--color-tertiary)]' : 'fa-regular fa-eye-slash text-[var(--color-muted)]'" @click.stop="toggleVisibilityByKey(layer._key)"></i>
              </div>
            </div>
          </template>
        </div>
        <!-- Layers bottom toolbar (PS style) -->
        <div class="flex flex-row justify-between items-center h-[40px] px-[8px] border-t border-[var(--color-border-light)] bg-[var(--color-panel)] shrink-0">
          <div class="flex flex-row items-center gap-[4px]">
            <i class="fa-solid fa-link text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="链接图层"></i>
            <i class="fa-solid fa-layer-group text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="添加图层样式 fx"></i>
            <i class="fa-solid fa-mask text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="添加图层蒙版"></i>
            <div class="w-[1px] h-[16px] bg-[var(--color-border)] mx-[4px]"></div>
            <i class="fa-solid fa-adjust text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="创建新的填充或调整图层"><span class="fa-solid fa-caret-down text-[8px] ml-[2px]"></span></i>
            <i class="fa-solid fa-folder text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="新建组"></i>
            <i class="fa-solid fa-plus text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-primary)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="新建图层"></i>
          </div>
          <div class="flex flex-row items-center gap-[4px]">
            <i class="fa-solid fa-trash text-[11px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-error)] p-[6px] rounded-[4px] hover:bg-[var(--color-border-light)]" title="删除图层"></i>
          </div>
        </div>
      </div>
    </template>

    <!-- ==================== EXPORT TAB ==================== -->
    <template v-if="activeTab === 'export'">
      <div class="flex flex-col justify-start overflow-y-auto flex-1">
        <!-- Header -->
        <div class="flex flex-row justify-between items-center px-[12px] py-[8px] border-b border-[var(--color-border-light)]">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">导出设置</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">1 个图层</span>
        </div>

        <!-- Format bar (always visible) -->
        <div class="px-[12px] py-[8px] border-b border-[var(--color-border-light)]">
          <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)] block mb-[4px]">格式</span>
          <div class="flex flex-row flex-wrap gap-[4px]">
            <div v-for="fmt in exportFormats" :key="fmt.id"
              class="flex flex-row justify-center items-center h-[28px] px-[8px] rounded-[4px] cursor-pointer border text-[10px] font-[500] transition-colors"
              :class="exportFormat === fmt.id ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-secondary)] hover:bg-[var(--color-panel)]'"
              @click="exportFormat = fmt.id">{{ fmt.name }}</div>
          </div>
        </div>

        <!-- Collapsible sections -->
        <!-- 1. 基本 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="secExport.basic = !secExport.basic">
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">基本</span>
            <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform" :class="secExport.basic ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!secExport.basic" class="px-[12px] pb-[10px]">
            <!-- Quality -->
            <div class="mb-[6px]">
              <div class="flex flex-row justify-between items-center mb-[2px]">
                <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">品质</span>
                <span class="text-[10px] leading-[12px] font-[500] font-mono text-[var(--color-body)]">{{ exportQuality }}%</span>
              </div>
              <input type="range" class="w-full h-[4px] accent-[var(--color-primary)] cursor-pointer" min="1" max="100" v-model.number="exportQuality" />
              <div class="flex flex-row justify-between text-[10px] leading-[13px] font-[500] text-[var(--color-muted)] mt-[1px] px-[2px]">
                <span>低</span><span>中</span><span>高</span><span>最佳</span>
              </div>
            </div>
            <!-- Scale -->
            <div>
              <div class="flex flex-row justify-between items-center mb-[2px]">
                <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">缩放</span>
                <span class="text-[10px] leading-[12px] font-[500] font-mono text-[var(--color-body)]">{{ exportScale }}%</span>
              </div>
              <input type="range" class="w-full h-[4px] accent-[var(--color-primary)] cursor-pointer" min="10" max="400" v-model.number="exportScale" />
              <div class="flex flex-row justify-between text-[10px] leading-[13px] font-[500] text-[var(--color-muted)] mt-[1px] px-[2px]">
                <span>10%</span><span>100%</span><span>400%</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. 尺寸 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="secExport.size = !secExport.size">
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">尺寸</span>
            <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform" :class="secExport.size ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!secExport.size" class="px-[12px] pb-[10px]">
            <div class="grid grid-cols-2 gap-[4px] mb-[4px]">
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">宽度</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">420 px</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">高度</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">600 px</span></div>
            </div>
            <div class="flex flex-row items-center gap-[8px]">
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="exportConstrain ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="exportConstrain = !exportConstrain"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">约束比例</span></label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="exportTransparent ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="exportTransparent = !exportTransparent"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">透明</span></label>
            </div>
          </div>
        </div>

        <!-- 3. 格式选项 (per-format, collapsible) -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="secExport.formatOpt = !secExport.formatOpt">
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">{{ formatOptionLabel }}</span>
            <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform" :class="secExport.formatOpt ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!secExport.formatOpt" class="px-[12px] pb-[10px]">
            <!-- PNG -->
            <template v-if="exportFormat === 'png'">
              <div class="flex flex-row gap-[4px] mb-[4px]">
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] cursor-pointer border text-[10px] font-[500]" :class="pngMode === 'PNG-24' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'" @click="pngMode='PNG-24'">PNG-24</div>
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] cursor-pointer border text-[10px] font-[500]" :class="pngMode === 'PNG-8' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'" @click="pngMode='PNG-8'">PNG-8</div>
              </div>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="pngInterlace ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="pngInterlace = !pngInterlace"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">交错</span></label>
            </template>
            <!-- JPEG / WebP -->
            <template v-if="exportFormat === 'jpg' || exportFormat === 'webp'">
              <div class="flex flex-row gap-[4px] mb-[4px]">
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] cursor-pointer border text-[10px] font-[500]" :class="jpegProgressive ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'" @click="jpegProgressive = !jpegProgressive">渐进式</div>
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] cursor-pointer border text-[10px] font-[500]" :class="jpegOptimize ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'" @click="jpegOptimize = !jpegOptimize">优化</div>
              </div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">子采样</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">4:4:4</span></div>
            </template>
            <!-- SVG -->
            <template v-if="exportFormat === 'svg'">
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none mb-[3px]"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="svgInline ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="svgInline = !svgInline"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">内联样式</span></label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none mb-[3px]"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="svgMinify ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="svgMinify = !svgMinify"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">压缩精简</span></label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="svgResponsive ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="svgResponsive = !svgResponsive"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">响应式 viewBox</span></label>
            </template>
            <!-- PDF -->
            <template v-if="exportFormat === 'pdf'">
              <div class="flex flex-row flex-wrap gap-[4px] mb-[4px]">
                <div v-for="std in pdfStandards" :key="std" class="flex flex-row justify-center items-center h-[24px] px-[6px] rounded-[3px] cursor-pointer border text-[10px] font-[500] transition-colors" :class="pdfStandard === std ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'" @click="pdfStandard = std">{{ std }}</div>
              </div>
              <div class="grid grid-cols-2 gap-[4px] mb-[4px]">
                <div class="flex flex-row justify-between items-center h-[24px] px-[6px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">压缩</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">JPEG 最大</span></div>
                <div class="flex flex-row justify-between items-center h-[24px] px-[6px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">嵌入字体</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">全部</span></div>
              </div>
              <div class="flex flex-row flex-wrap gap-[4px]">
                <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[12px] h-[8px] rounded-[3px] cursor-pointer flex items-center px-[1px] transition-colors" :class="pdfCropMarks ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="pdfCropMarks = !pdfCropMarks"><div class="w-[4px] h-[4px] bg-[var(--color-white)] rounded-[2px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">裁切</span></label>
                <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[12px] h-[8px] rounded-[3px] cursor-pointer flex items-center px-[1px] transition-colors" :class="pdfBleedMarks ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="pdfBleedMarks = !pdfBleedMarks"><div class="w-[4px] h-[4px] bg-[var(--color-white)] rounded-[2px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">出血</span></label>
                <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[12px] h-[8px] rounded-[3px] cursor-pointer flex items-center px-[1px] transition-colors" :class="pdfColorBars ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="pdfColorBars = !pdfColorBars"><div class="w-[4px] h-[4px] bg-[var(--color-white)] rounded-[2px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">色标</span></label>
              </div>
            </template>
            <!-- EPS / CDR -->
            <template v-if="exportFormat === 'eps' || exportFormat === 'cdr'">
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none mb-[3px]"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="embedFonts ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="embedFonts = !embedFonts"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">嵌入字体</span></label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="embedImages ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="embedImages = !embedImages"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">嵌入图片</span></label>
            </template>
            <!-- HDS -->
            <template v-if="exportFormat === 'hds'">
              <div class="flex flex-row gap-[4px] mb-[4px]">
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] border text-[10px] font-[500] cursor-pointer" :class="hdsMode === '标准' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)]'" @click="hdsMode='标准'">标准</div>
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] border text-[10px] font-[500] cursor-pointer" :class="hdsMode === '精简' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)]'" @click="hdsMode='精简'">精简</div>
                <div class="flex flex-row justify-center items-center flex-1 h-[24px] rounded-[3px] border text-[10px] font-[500] cursor-pointer" :class="hdsMode === '兼容' ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)]'" @click="hdsMode='兼容'">兼容</div>
              </div>
              <div class="grid grid-cols-2 gap-[4px] mb-[4px]">
                <div class="flex flex-row justify-between items-center h-[24px] px-[6px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">版本</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">v3.0</span></div>
                <div class="flex flex-row justify-between items-center h-[24px] px-[6px] bg-[var(--color-panel)] rounded-[4px]"><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">压缩</span><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">无损</span></div>
              </div>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none mb-[2px]"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="hdsEmbedFonts ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="hdsEmbedFonts = !hdsEmbedFonts"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">嵌入字体</span></label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="hdsEmbedImages ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="hdsEmbedImages = !hdsEmbedImages"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">嵌入图片</span></label>
            </template>
          </div>
        </div>

        <!-- 4. 色彩 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="secExport.color = !secExport.color">
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">色彩与元数据</span>
            <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform" :class="secExport.color ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!secExport.color" class="px-[12px] pb-[10px]">
            <div class="flex flex-row flex-wrap gap-[4px] mb-[4px]">
              <div v-for="cs in exportColorSpaces" :key="cs"
                class="flex flex-row justify-center items-center h-[24px] px-[8px] rounded-[3px] cursor-pointer border text-[10px] font-[500] transition-colors"
                :class="exportColorSpace === cs ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
                @click="exportColorSpace = cs">{{ cs }}</div>
            </div>
            <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none"><div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="exportEmbedICC ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="exportEmbedICC = !exportEmbedICC"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div><span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">嵌入 ICC 配置文件</span></label>
          </div>
        </div>

        <!-- 5. 预设 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="secExport.presets = !secExport.presets">
            <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">预设方案</span>
            <i class="fa-solid text-[8px] text-[var(--color-muted)] transition-transform" :class="secExport.presets ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!secExport.presets" class="px-[12px] pb-[10px]">
            <div class="flex flex-row flex-wrap gap-[4px]">
              <div v-for="preset in exportPresets" :key="preset"
                class="flex flex-row justify-center items-center h-[24px] px-[8px] rounded-[4px] cursor-pointer border text-[10px] font-[500] transition-colors"
                :class="exportPreset === preset ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
                @click="exportPreset = preset">
                <i v-if="exportPreset === preset" class="fa-solid fa-check text-[10px] mr-[3px]"></i>{{ preset }}</div>
            </div>
          </div>
        </div>

        <!-- Footer: estimate + export buttons -->
        <div class="px-[12px] py-[10px] mt-auto border-t border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px] mb-[6px]">
            <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">预估大小</span>
            <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">{{ estimatedSize }}</span>
          </div>
          <div class="flex flex-row gap-[8px]">
            <div class="flex flex-row justify-center items-center flex-1 h-[32px] bg-[var(--color-primary-dark-700)] rounded-[6px] cursor-pointer hover:bg-[var(--color-primary-dark-900)] transition-colors">
              <i class="fa-solid fa-download text-[10px] text-[var(--color-white)] mr-[6px]"></i>
              <span class="text-[10px] leading-[12px] font-[700] text-[var(--color-white)]">导出当前</span>
            </div>
            <div class="flex flex-row justify-center items-center w-[30px] h-[32px] rounded-[6px] cursor-pointer border border-[var(--color-border)] hover:bg-[var(--color-panel)] transition-colors" title="批量导出">
              <i class="fa-solid fa-layer-group text-[10px] text-[var(--color-secondary)]"></i>
            </div>
          </div>
        </div>
      </div>
    </template>
    <!-- ==================== SETTINGS TAB ==================== -->
    <template v-if="activeTab === 'settings'">
      <div class="flex flex-col justify-start overflow-y-auto flex-1">
        <!-- Section: MCP 协议配置 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="mcpExpanded = !mcpExpanded">
            <div class="flex flex-row items-center gap-[8px]">
              <i class="fa-solid fa-tower-broadcast text-[10px] text-[var(--color-secondary)]"></i>
              <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">MCP 协议</span>
            </div>
            <i class="fa-solid text-[8px] text-[var(--color-muted)]" :class="mcpExpanded ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!mcpExpanded" class="px-[12px] pb-[12px]">
            <!-- Server Status -->
            <div class="flex flex-row items-center justify-between h-[28px] mb-[8px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
              <div class="flex flex-row items-center gap-[8px]">
                <div class="w-[6px] h-[6px] rounded-full bg-[var(--color-primary)]"></div>
                <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">服务运行中</span>
              </div>
              <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">PID 2847</span>
            </div>
            <!-- Endpoint Info -->
            <div class="flex flex-col gap-[4px] mb-[8px]">
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">端点地址</span>
                <span class="text-[10px] leading-[13px] font-[500] font-mono text-[var(--color-body)]">localhost:11435</span>
              </div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">协议版本</span>
                <span class="text-[10px] leading-[13px] font-[500] font-mono text-[var(--color-body)]">2025-03-26</span>
              </div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">RPC 通道</span>
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">Streamable HTTP · SSE</span>
              </div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">会话数</span>
                <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-body)]">3 个活跃会话</span>
              </div>
            </div>
            <!-- Allowed Tools -->
            <div class="mb-[6px]">
              <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)] block mb-[4px]">暴露的工具 (Tools)</span>
              <div class="flex flex-col gap-[4px]">
                <div v-for="(tool, ti) in mcpTools" :key="ti" class="flex flex-row items-center justify-between px-[8px] py-[4px] rounded-[3px] hover:bg-[var(--color-panel)] cursor-pointer">
                  <div class="flex flex-row items-center gap-[8px] min-w-0 flex-1">
                    <i :class="['fa-solid', tool.icon, 'text-[8px]', 'text-[var(--color-secondary)]']"></i>
                    <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)] truncate">{{ tool.name }}</span>
                  </div>
                  <div class="flex flex-row items-center gap-[4px]">
                    <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">{{ tool.calls }}</span>
                    <label class="cursor-pointer"><div class="w-[18px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="tool.enabled ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click.stop="tool.enabled = !tool.enabled"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div></label>
                  </div>
                </div>
              </div>
            </div>
            <!-- Exposed Resources -->
            <div>
              <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-muted)] block mb-[4px]">暴露的资源 (Resources)</span>
              <div class="flex flex-col gap-[4px]">
                <div v-for="(res, ri) in mcpResources" :key="ri" class="flex flex-row items-center justify-between px-[8px] py-[4px] rounded-[3px] hover:bg-[var(--color-panel)] cursor-pointer">
                  <div class="flex flex-row items-center gap-[8px] min-w-0 flex-1">
                    <i class="fa-regular fa-file-lines text-[8px] text-[var(--color-secondary)]"></i>
                    <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)] truncate">{{ res }}</span>
                  </div>
                </div>
              </div>
            </div>
            <!-- Restart / Refresh buttons -->
            <div class="mt-[8px] pt-[8px] border-t border-[var(--color-border-light)] flex flex-row gap-[8px]">
              <div class="flex flex-row justify-center items-center flex-1 h-[28px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-secondary)] hover:bg-[var(--color-panel)] gap-[4px]">
                <i class="fa-solid fa-rotate text-[8px]"></i>
                <span>重启服务</span>
              </div>
              <div class="flex flex-row justify-center items-center flex-1 h-[28px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-secondary)] hover:bg-[var(--color-panel)] gap-[4px]">
                <i class="fa-solid fa-copy text-[8px]"></i>
                <span>复制端点</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Section: 模型信息配置 🆕 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="modelExpanded = !modelExpanded">
            <div class="flex flex-row items-center gap-[8px]">
              <i class="fa-solid fa-microchip text-[10px] text-[var(--color-secondary)]"></i>
              <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">模型信息配置</span>
            </div>
            <i class="fa-solid text-[8px] text-[var(--color-muted)]" :class="modelExpanded ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!modelExpanded" class="px-[12px] pb-[12px]">
            <!-- 协议选择 -->
            <div class="flex flex-col gap-[4px] mb-[6px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">协议</span>
              <div class="flex flex-row flex-wrap gap-[4px]">
                <div v-for="proto in modelProtocols" :key="proto"
                  class="flex flex-row justify-center items-center h-[24px] px-[8px] rounded-[3px] cursor-pointer border text-[10px] font-[500] transition-colors"
                  :class="modelProtocol === proto ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
                  @click="modelProtocol = proto">{{ proto }}</div>
              </div>
            </div>
            <!-- 提供商 -->
            <div class="flex flex-col gap-[4px] mb-[6px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">提供商</span>
              <div class="flex flex-row flex-wrap gap-[4px]">
                <div v-for="prov in modelProviders" :key="prov"
                  class="flex flex-row justify-center items-center h-[24px] px-[8px] rounded-[3px] cursor-pointer border text-[10px] font-[500] transition-colors"
                  :class="modelProvider === prov ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[var(--color-primary-dark-700)]' : 'border-[var(--color-border)] text-[var(--color-muted)] hover:bg-[var(--color-panel)]'"
                  @click="modelProvider = prov">{{ prov }}</div>
              </div>
            </div>
            <!-- URL -->
            <div class="flex flex-col gap-[4px] mb-[6px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">API 端点 URL</span>
              <div class="flex flex-row items-center h-[28px] px-[8px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] focus-within:border-[var(--color-primary)]">
                <i class="fa-solid fa-link text-[8px] text-[var(--color-muted)] mr-[4px]"></i>
                <input type="text" v-model="modelUrl" class="flex-1 text-[10px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)]" placeholder="https://api.openai.com/v1" />
                <i class="fa-solid fa-paste text-[8px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-title)]" title="粘贴"></i>
              </div>
            </div>
            <!-- 令牌 -->
            <div class="flex flex-col gap-[4px] mb-[6px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">API 令牌</span>
              <div class="flex flex-row items-center h-[28px] px-[8px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] focus-within:border-[var(--color-primary)]">
                <i class="fa-solid fa-key text-[8px] text-[var(--color-muted)] mr-[4px]"></i>
                <input :type="modelTokenVisible ? 'text' : 'password'" v-model="modelToken" class="flex-1 text-[10px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)] font-mono" placeholder="sk-xxxxxxxxxxxxxxxx" />
                <i class="fa-solid text-[8px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-title)] mr-[4px]" :class="modelTokenVisible ? 'fa-eye' : 'fa-eye-slash'" @click="modelTokenVisible = !modelTokenVisible" :title="modelTokenVisible ? '隐藏' : '显示'"></i>
                <i class="fa-solid fa-paste text-[8px] text-[var(--color-muted)] cursor-pointer hover:text-[var(--color-title)]" title="粘贴"></i>
              </div>
            </div>
            <!-- 模型ID -->
            <div class="flex flex-col gap-[4px] mb-[6px]">
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">模型 ID</span>
              <div class="flex flex-row items-center h-[28px] px-[8px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] focus-within:border-[var(--color-primary)]">
                <i class="fa-solid fa-tag text-[8px] text-[var(--color-muted)] mr-[4px]"></i>
                <input type="text" v-model="modelId" class="flex-1 text-[10px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)] font-mono" placeholder="deepseek-v4-flash" />
              </div>
            </div>
            <!-- 高级选项 -->
            <div class="flex flex-row items-center gap-[8px] mb-[6px] cursor-pointer" @click="modelAdvanced = !modelAdvanced">
              <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="modelAdvanced ? 'fa-chevron-down' : 'fa-chevron-right'"></i>
              <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">高级选项</span>
            </div>
            <div v-show="modelAdvanced" class="flex flex-col gap-[8px] mb-[6px] pl-[8px] border-l border-[var(--color-border-light)]">
              <div class="grid grid-cols-2 gap-[4px]">
                <div class="flex flex-col gap-[4px]">
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">最大 Token</span>
                  <input type="number" v-model.number="modelMaxTokens" class="h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" max="65536" />
                </div>
                <div class="flex flex-col gap-[4px]">
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">温度 (0-2)</span>
                  <input type="number" v-model.number="modelTemperature" class="h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="0" max="2" step="0.1" />
                </div>
                <div class="flex flex-col gap-[4px]">
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">超时 (秒)</span>
                  <input type="number" v-model.number="modelTimeout" class="h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" max="300" />
                </div>
                <div class="flex flex-col gap-[4px]">
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">重试次数</span>
                  <input type="number" v-model.number="modelRetries" class="h-[24px] px-[4px] text-[10px] leading-[13px] font-[500] border border-[var(--color-border)] rounded-[3px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="0" max="10" />
                </div>
              </div>
              <div class="flex flex-row items-center gap-[4px]">
                <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none">
                  <div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="modelStream ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="modelStream = !modelStream"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div>
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">流式输出</span>
                </label>
                <label class="flex flex-row items-center gap-[4px] cursor-pointer select-none">
                  <div class="w-[16px] h-[10px] rounded-[5px] cursor-pointer flex items-center px-[1px] transition-colors" :class="modelThinking ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="modelThinking = !modelThinking"><div class="w-[6px] h-[6px] bg-[var(--color-white)] rounded-[3px]"></div></div>
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-secondary)]">推理模式</span>
                </label>
              </div>
            </div>
            <!-- 连接测试 & 保存 -->
            <div class="flex flex-row gap-[4px] mt-[8px] pt-[6px] border-t border-[var(--color-border-light)]">
              <div class="flex flex-row justify-center items-center flex-1 h-[28px] rounded-[4px] cursor-pointer border border-[var(--color-border)] text-[10px] font-[500] text-[var(--color-secondary)] hover:bg-[var(--color-panel)] gap-[4px]">
                <i class="fa-solid fa-plug text-[10px]"></i>
                <span>测试连接</span>
              </div>
              <div class="flex flex-row justify-center items-center flex-1 h-[28px] rounded-[4px] cursor-pointer border border-[var(--color-primary)] bg-[var(--color-hover-bg)] text-[10px] font-[600] text-[var(--color-primary-dark-700)] hover:bg-[var(--color-primary-light-100)] gap-[4px]">
                <i class="fa-solid fa-floppy-disk text-[10px]"></i>
                <span>保存配置</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Section: 智能体技能 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="skillExpanded = !skillExpanded">
            <div class="flex flex-row items-center gap-[8px]">
              <i class="fa-solid fa-robot text-[10px] text-[var(--color-secondary)]"></i>
              <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">智能体技能</span>
            </div>
            <div class="flex flex-row items-center gap-[8px]">
              <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ agentSkills.length }} 个</span>
              <i class="fa-solid text-[8px] text-[var(--color-muted)]" :class="skillExpanded ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
            </div>
          </div>
          <div v-show="!skillExpanded" class="px-[12px] pb-[12px]">
            <div class="flex flex-row items-center h-[28px] px-[8px] mb-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px]">
              <i class="fa-solid fa-magnifying-glass text-[8px] text-[var(--color-muted)] mr-[6px]"></i>
              <input type="text" placeholder="搜索可用技能..." class="flex-1 text-[10px] leading-[12px] border-none outline-none bg-transparent text-[var(--color-body)] placeholder:text-[var(--color-muted)]" />
            </div>
            <div class="flex flex-col gap-[4px]">
              <div v-for="(skill, si) in agentSkills" :key="skill.name"
                class="flex flex-row justify-between items-center px-[8px] py-[8px] rounded-[4px] hover:bg-[var(--color-panel)] cursor-pointer transition-colors"
                :class="skill.connected ? '' : 'opacity-60'"
              >
                <div class="flex flex-row items-center gap-[8px] min-w-0 flex-1">
                  <div class="w-[6px] h-[6px] rounded-full shrink-0" :class="skill.connected ? 'bg-[var(--color-primary)]' : 'bg-[var(--color-muted)]'"></div>
                  <i :class="['fa-solid', skill.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i>
                  <div class="flex flex-col items-start gap-[1px] min-w-0">
                    <span class="text-[10px] leading-[13px] font-[600] text-[var(--color-body)] truncate w-full">{{ skill.label }}</span>
                    <span class="text-[10px] leading-[13px] font-[400] text-[var(--color-muted)]">{{ skill.desc }}</span>
                  </div>
                </div>
                <div class="flex flex-row items-center gap-[4px] shrink-0">
                  <span class="text-[10px] leading-[13px] font-[500] text-[var(--color-muted)]">{{ skill.agent }}</span>
                </div>
              </div>
            </div>
            <div class="mt-[8px] pt-[8px] border-t border-[var(--color-border-light)]">
              <div class="flex flex-row items-center gap-[8px] px-[4px] py-[8px] rounded-[4px] cursor-pointer hover:bg-[var(--color-panel)]">
                <i class="fa-solid fa-plus text-[8px] text-[var(--color-muted)]"></i>
                <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">注册新智能体...</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Section: 系统信息 -->
        <div class="border-b border-[var(--color-border-light)]">
          <div class="flex flex-row justify-between items-center px-[14px] py-[10px] cursor-pointer select-none hover:bg-[var(--color-panel)] transition-colors duration-100" @click="sysInfoExpanded = !sysInfoExpanded">
            <div class="flex flex-row items-center gap-[8px]">
              <i class="fa-solid fa-circle-info text-[10px] text-[var(--color-secondary)]"></i>
              <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">系统信息</span>
            </div>
            <i class="fa-solid text-[8px] text-[var(--color-muted)]" :class="sysInfoExpanded ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
          </div>
          <div v-show="!sysInfoExpanded" class="px-[12px] pb-[12px]">
            <div class="grid grid-cols-2 gap-[4px] text-[10px] leading-[12px]">
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">版本</span><span class="font-[500] text-[var(--color-body)]">3.0.0</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">构建</span><span class="font-[500] text-[var(--color-body)]">2026.07.19</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">模型</span><span class="font-[500] text-[var(--color-body)]">deepseek-v4</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">引擎</span><span class="font-[500] text-[var(--color-body)]">OpenClaw v2.3</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">网关</span><span class="font-[500] text-[var(--color-body)]">百炼 + 中转</span></div>
              <div class="flex flex-row justify-between items-center h-[24px] px-[8px] bg-[var(--color-panel)] rounded-[4px]"><span class="font-[500] text-[var(--color-muted)]">凭证</span><span class="font-[500] text-[var(--color-body)]">已绑定</span></div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="px-[12px] py-[10px] mt-auto border-t border-[var(--color-border-light)]">
          <div class="flex flex-row justify-center items-center h-[32px] bg-[var(--color-primary-dark-700)] rounded-[6px] cursor-pointer hover:bg-[var(--color-primary-dark-900)] transition-colors gap-[8px]">
            <i class="fa-solid fa-rotate text-[10px] text-[var(--color-white)]"></i>
            <span class="text-[10px] leading-[12px] font-[700] text-[var(--color-white)]">检查更新</span>
          </div>
        </div>
      </div>
    </template>
    <!-- ==================== AI TAB ==================== -->
    <AIAssistant v-if="activeTab === 'ai'" embedded />
  </div>

  <!-- Layer Context Menu -->
  <Teleport to="body">
    <div v-if="contextMenu.visible" class="fixed z-[100] min-w-[180px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg py-[4px]" :style="{ left: contextMenu.x + 'px', top: contextMenu.y + 'px' }" @click.stop="closeContextMenu">
      <div v-for="(item, ci) in contextMenuItems" :key="ci" class="flex flex-row justify-between items-center h-[32px] px-[12px] cursor-pointer hover:bg-[var(--color-hover-bg)] whitespace-nowrap relative" @click="handleContextAction(item.action)">
        <div class="flex flex-row items-center gap-[8px] flex-1">
          <i v-if="item.icon" :class="['fa-solid', item.icon, 'text-[11px]', 'w-[14px] text-center', 'text-[var(--color-secondary)]']"></i>
          <span class="text-[12px] leading-[16px] font-[500] text-[var(--color-body)]">{{ item.label }}</span>
        </div>
        <div class="flex flex-row items-center gap-[8px]">
          <span v-if="item.shortcut" class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">{{ item.shortcut }}</span>
          <i v-if="item.hasSubmenu" class="fa-solid fa-chevron-right text-[8px] text-[var(--color-muted)]"></i>
        </div>
      </div>
    </div>
  </Teleport>

  <!-- Blend Mode Submenu (from context menu) -->
  <Teleport to="body">
    <div v-if="blendModeSubmenu.visible" class="fixed z-[110] w-[170px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg py-[4px] max-h-[300px] overflow-y-auto" :style="{ left: blendModeSubmenu.x + 'px', top: blendModeSubmenu.y + 'px' }" @click.stop>
      <div class="flex flex-row justify-between items-center h-[28px] px-[12px] bg-[var(--color-panel)] text-[10px] font-[600] text-[var(--color-muted)]">
        <span>混合模式</span>
        <span class="text-[10px] text-[var(--color-muted)]">{{ currentContextLayerBlend }}</span>
      </div>
      <div v-for="opt in BLEND_MODE_OPTIONS" :key="opt.value" class="flex flex-row justify-between items-center h-[28px] px-[12px] cursor-pointer hover:bg-[var(--color-hover-bg)]" :class="currentContextBlendValue === opt.value ? 'bg-[var(--color-hover-bg)]' : ''" @click="setContextBlendMode(opt.value)">
        <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-body)]">{{ opt.label }}</span>
        <span v-if="currentContextBlendValue === opt.value" class="text-[10px] text-[var(--color-primary)]">✓</span>
      </div>
    </div>
  </Teleport>

  <!-- Window Settings Dialog -->
  <Teleport to="body">
    <div v-if="showWindowSettings" class="fixed inset-0 z-[200] flex items-center justify-center bg-black/30" @click.self="showWindowSettings = false">
      <div class="w-[420px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[12px] shadow-2xl overflow-hidden">
        <div class="flex flex-row justify-between items-center h-[44px] px-[16px] border-b border-[var(--color-border)]">
          <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-body)]">窗口设置</span>
          <i class="fa-solid fa-xmark text-[12px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)]" @click="showWindowSettings = false"></i>
        </div>
        <div class="p-[16px] max-h-[400px] overflow-y-auto">
          <div class="mb-[16px]">
            <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-body)] mb-[8px] block">预设布局</span>
            <div class="flex flex-row gap-[8px]">
              <div v-for="preset in layoutPresets" :key="preset.id" class="flex flex-col items-center gap-[4px] cursor-pointer" :class="activePreset === preset.id ? 'opacity-100' : 'opacity-60 hover:opacity-80'" @click="activePreset = preset.id">
                <div class="w-[72px] h-[48px] border border-[var(--color-border)] rounded-[6px] overflow-hidden flex flex-row" :class="activePreset === preset.id ? 'border-[var(--color-primary)] ring-1 ring-[var(--color-primary)]' : ''">
                  <div class="bg-[var(--color-panel)]" :style="{ width: preset.preview[0] + '%' }"></div>
                  <div class="bg-[var(--color-white)]" :style="{ width: preset.preview[1] + '%' }"></div>
                  <div class="bg-[var(--color-panel)]" :style="{ width: preset.preview[2] + '%' }"></div>
                </div>
                <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-secondary)]">{{ preset.name }}</span>
              </div>
            </div>
          </div>
          <div class="mb-[16px]">
            <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-body)] mb-[8px] block">工具栏显示</span>
            <div v-for="(item, i) in toolbarItems" :key="i" class="flex flex-row justify-between items-center h-[32px] px-[8px] hover:bg-[var(--color-panel)] rounded-[4px]">
              <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-secondary)]">{{ item.label }}</span>
              <div class="w-[36px] h-[20px] rounded-[10px] cursor-pointer flex items-center px-[2px] transition-colors" :class="item.visible ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="item.visible = !item.visible">
                <div class="w-[16px] h-[16px] bg-[var(--color-white)] rounded-[8px] shadow-sm"></div>
              </div>
            </div>
          </div>
          <div>
            <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-body)] mb-[8px] block">面板显示</span>
            <div v-for="(item, i) in panelItems" :key="i" class="flex flex-row justify-between items-center h-[32px] px-[8px] hover:bg-[var(--color-panel)] rounded-[4px]">
              <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-secondary)]">{{ item.label }}</span>
              <div class="w-[36px] h-[20px] rounded-[10px] cursor-pointer flex items-center px-[2px] transition-colors" :class="item.visible ? 'bg-[var(--color-primary)] justify-end' : 'bg-[var(--color-border)] justify-start'" @click="item.visible = !item.visible">
                <div class="w-[16px] h-[16px] bg-[var(--color-white)] rounded-[8px] shadow-sm"></div>
              </div>
            </div>
          </div>
        </div>
        <div class="flex flex-row justify-end items-center h-[48px] px-[16px] gap-[8px] border-t border-[var(--color-border)]">
          <div class="flex flex-row justify-center items-center h-[32px] px-[12px] border border-[var(--color-border)] rounded-[6px] cursor-pointer hover:bg-[var(--color-panel)]" @click="showWindowSettings = false"><span class="text-[11px] leading-[14px] font-[600] text-[var(--color-secondary)]">取消</span></div>
          <div class="flex flex-row justify-center items-center h-[32px] px-[12px] bg-[var(--color-primary-dark-700)] rounded-[6px] cursor-pointer hover:bg-[var(--color-primary-dark-900)]" @click="showWindowSettings = false"><span class="text-[11px] leading-[14px] font-[700] text-[var(--color-white)]">应用</span></div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, onUnmounted } from 'vue'
import type { LayerItem, SceneObject, ShapeObject, TextObject, ImageObject, FillObject, LayerEffect, BlendMode, FrameType } from '../types'
import AIAssistant from './AIAssistant.vue'
import ColorPickerPanel from './ColorPickerPanel.vue'
import ColorPickerPopover from './ColorPickerPopover.vue'
import { layerBlendModes, BLEND_MODE_OPTIONS, getBlendModeLabel } from '../composables/layerBlendStore'
import { useLayerStore } from '../stores/layer'
import { useToastStore } from '../stores/toast'
import { useFusionDocumentStore } from '../stores/fusionDocument'

const layerStore = useLayerStore()
const toastStore = useToastStore()
const fusion = useFusionDocumentStore()

// ─── Transform (Inspector 变换输入) ───
// 与 Fusion DOM 双向绑定：单选对象时直接读写 selectedObjects[0].transform
// 当无选中或选中多个对象时，输入框禁用并回退到占位值
const hasSingleSelection = computed<boolean>(() => fusion.selectedObjects.length === 1)
const currentObject = computed<SceneObject | null>(() =>
  hasSingleSelection.value ? fusion.selectedObjects[0] : null,
)
const currentTransform = computed(() => currentObject.value?.transform ?? null)
// 选中元素名称：优先使用 layerStore，回退到 fusion 选中对象的 name
const selectedObjectName = computed(() => {
  if (layerStore.selectedElement) return layerStore.selectedElement
  if (hasSingleSelection.value && currentObject.value) {
    return currentObject.value.name
  }
  if (fusion.selectedObjects.length > 1) {
    return `${fusion.selectedObjects.length} 个对象`
  }
  return ''
})

const transformX = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.x) : 0),
  set: (v) => {
    if (!currentTransform.value) return
    currentTransform.value.x = Number.isFinite(v) ? v : 0
  },
})
const transformY = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.y) : 0),
  set: (v) => {
    if (!currentTransform.value) return
    currentTransform.value.y = Number.isFinite(v) ? v : 0
  },
})
const transformW = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.width) : 0),
  set: (v) => {
    if (!currentTransform.value) return
    const newW = Math.max(1, Number.isFinite(v) ? v : 1)
    if (linkRatio.value && currentTransform.value.width > 0) {
      const ratio = currentTransform.value.height / currentTransform.value.width
      currentTransform.value.height = Math.round(newW * ratio)
    }
    currentTransform.value.width = newW
  },
})
const transformH = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.height) : 0),
  set: (v) => {
    if (!currentTransform.value) return
    const newH = Math.max(1, Number.isFinite(v) ? v : 1)
    if (linkRatio.value && currentTransform.value.height > 0) {
      const ratio = currentTransform.value.width / currentTransform.value.height
      currentTransform.value.width = Math.round(newH * ratio)
    }
    currentTransform.value.height = newH
  },
})
const transformRot = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.rotation) : 0),
  set: (v) => {
    if (!currentTransform.value) return
    currentTransform.value.rotation = Number.isFinite(v) ? v : 0
  },
})
// 缩放取 scaleX（默认 1 = 100%）；写入时同时设置 scaleX/scaleY 保持等比
const transformScale = computed<number>({
  get: () => (currentTransform.value ? Math.round(currentTransform.value.scaleX * 100) : 100),
  set: (v) => {
    if (!currentTransform.value) return
    const s = Number.isFinite(v) ? Math.max(1, v) / 100 : 1
    currentTransform.value.scaleX = s
    currentTransform.value.scaleY = s
  },
})
const linkRatio = ref(true)
const flipH = computed<boolean>({
  get: () => (currentTransform.value ? currentTransform.value.flipH : false),
  set: (v) => {
    if (!currentTransform.value) return
    currentTransform.value.flipH = !!v
  },
})
const flipV = computed<boolean>({
  get: () => (currentTransform.value ? currentTransform.value.flipV : false),
  set: (v) => {
    if (!currentTransform.value) return
    currentTransform.value.flipV = !!v
  },
})

/** 变换编辑状态：focus 时 pushHistory 保存修改前快照，change 时结束编辑 */
let transformEditing = false

/** 输入框 focus：保存修改前快照到 undoStack（仅本次编辑的第一次 focus 推一次） */
function onTransformFocus(description: string): void {
  if (!hasSingleSelection.value || transformEditing) return
  transformEditing = true
  fusion.pushHistory(description)
}

/** 输入框 change（失焦/回车）：结束本次编辑，允许下次 focus 再次推历史 */
function onTransformChange(): void {
  transformEditing = false
}

// ─── Frame (画板) 属性 ───
// 当选中 Frame 时显示画板属性：名称、类型、位置、尺寸、背景色、页码（书籍模式）
const hasFrame = computed<boolean>(() => fusion.isFramesMode && !!fusion.currentFrame)
const currentFrame = computed(() => fusion.currentFrame)

/** 根据 Frame 类型返回图标（与 FrameView/PagesPanel 保持一致） */
const frameTypeIcon = computed<string>(() => {
  switch (currentFrame.value?.type) {
    case 'single': return 'fa-file'
    case 'poster': return 'fa-image'
    case 'book-page': return 'fa-book'
    case 'spread': return 'fa-book-open'
    default: return 'fa-file'
  }
})

/** 根据 Frame 类型返回中文标签 */
const frameTypeLabel = computed<string>(() => {
  switch (currentFrame.value?.type) {
    case 'single': return '单页'
    case 'poster': return '海报'
    case 'book-page': return '书页'
    case 'spread': return '对页'
    default: return '未知'
  }
})

/** Frame 序号显示（书籍模式） */
const frameOrderLabel = computed<string>(() => {
  const f = currentFrame.value
  if (!f) return '—'
  if (f.type === 'book-page' || f.type === 'spread') {
    return f.order ? `P${f.order}` : '未设'
  }
  return '—'
})

const frameName = computed<string>({
  get: () => currentFrame.value?.name ?? '',
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.name = v
  },
})
const frameX = computed<number>({
  get: () => currentFrame.value ? Math.round(currentFrame.value.x) : 0,
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.x = Number.isFinite(v) ? v : 0
  },
})
const frameY = computed<number>({
  get: () => currentFrame.value ? Math.round(currentFrame.value.y) : 0,
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.y = Number.isFinite(v) ? v : 0
  },
})
const frameW = computed<number>({
  get: () => currentFrame.value ? Math.round(currentFrame.value.width) : 0,
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.width = Math.max(1, Number.isFinite(v) ? v : 1)
  },
})
const frameH = computed<number>({
  get: () => currentFrame.value ? Math.round(currentFrame.value.height) : 0,
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.height = Math.max(1, Number.isFinite(v) ? v : 1)
  },
})
const frameBackground = computed<string>({
  get: () => currentFrame.value?.background ?? '#FFFFFF',
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.background = v
  },
})
const frameShowPageNumber = computed<boolean>(() => currentFrame.value?.showPageNumber ?? false)
const frameOrder = computed<number>({
  get: () => currentFrame.value?.order ?? 1,
  set: (v) => {
    const f = currentFrame.value
    if (!f) return
    f.order = Math.max(1, Number.isFinite(v) ? Math.floor(v) : 1)
  },
})

/** Frame 编辑状态：focus 时 pushHistory，change 时结束编辑 */
let frameEditing = false
function onFrameFocus(): void {
  if (!hasFrame.value || frameEditing) return
  frameEditing = true
  fusion.pushHistory('修改画板')
}
function onFrameChange(): void {
  frameEditing = false
}
function toggleFramePageNumber(): void {
  const f = currentFrame.value
  if (!f) return
  fusion.pushHistory(f.showPageNumber ? '隐藏页码' : '显示页码')
  f.showPageNumber = !f.showPageNumber
}
function toggleFrameHidden(): void {
  const f = currentFrame.value
  if (!f) return
  fusion.toggleFrameHidden(f.id)
}

/** 翻转按钮：先 pushHistory 保存修改前状态，再切换翻转值 */
function toggleFlipH(): void {
  if (!hasSingleSelection.value) return
  fusion.pushHistory(flipH.value ? '取消水平翻转' : '水平翻转')
  flipH.value = !flipH.value
  toastStore.show(flipH.value ? '已水平翻转' : '已取消水平翻转', 'fa-arrows-left-right', 'info')
}
/** 翻转按钮：先 pushHistory 保存修改前状态，再切换翻转值 */
function toggleFlipV(): void {
  if (!hasSingleSelection.value) return
  fusion.pushHistory(flipV.value ? '取消垂直翻转' : '垂直翻转')
  flipV.value = !flipV.value
  toastStore.show(flipV.value ? '已垂直翻转' : '已取消垂直翻转', 'fa-arrows-up-down', 'info')
}

// ─── Align / Distribute 点击处理（真实几何运算） ───
function onAlignClick(index: number) {
  alignButtons.forEach((b, i) => { b.active = i === index })
  const btn = alignButtons[index]
  const objs = fusion.selectedObjects
  if (objs.length < 2) {
    toastStore.show('至少选择 2 个对象', 'fa-triangle-exclamation', 'warning')
    return
  }
  fusion.pushHistory(`对齐：${btn.label}`)
  // 计算所有对象的包围盒
  const boxes = objs.map(o => ({
    id: o.id,
    x: o.transform.x,
    y: o.transform.y,
    w: o.transform.width,
    h: o.transform.height,
  }))
  const minX = Math.min(...boxes.map(b => b.x))
  const maxX = Math.max(...boxes.map(b => b.x + b.w))
  const minY = Math.min(...boxes.map(b => b.y))
  const maxY = Math.max(...boxes.map(b => b.y + b.h))
  const centerX = (minX + maxX) / 2
  const centerY = (minY + maxY) / 2

  for (const b of boxes) {
    let newX = b.x
    let newY = b.y
    switch (index) {
      case 0: newX = minX; break                                    // 左对齐
      case 1: newX = centerX - b.w / 2; break                       // 水平居中
      case 2: newX = maxX - b.w; break                              // 右对齐
      case 3: newY = minY; break                                    // 顶对齐
      case 4: newY = centerY - b.h / 2; break                       // 垂直居中
      case 5: newY = maxY - b.h; break                              // 底对齐
    }
    fusion.updateObject(b.id, { transform: { x: newX, y: newY } }, `对齐 ${btn.label}`, true)
  }
  toastStore.show(btn.label, 'fa-align-left', 'success')
}
function onDistributeClick(index: number) {
  distributeButtons.forEach((b, i) => { b.active = i === index })
  const btn = distributeButtons[index]
  const objs = fusion.selectedObjects
  if (objs.length < 3) {
    toastStore.show('至少选择 3 个对象', 'fa-triangle-exclamation', 'warning')
    return
  }
  fusion.pushHistory(`分布：${btn.label}`)
  const boxes = objs.map(o => ({
    id: o.id,
    x: o.transform.x,
    y: o.transform.y,
    w: o.transform.width,
    h: o.transform.height,
  }))
  // 水平均匀分布 (0) / 垂直均匀分布 (1)
  if (index === 0) {
    boxes.sort((a, b) => a.x - b.x)
    const first = boxes[0]
    const last = boxes[boxes.length - 1]
    const totalSpan = (last.x + last.w) - first.x
    const totalGap = totalSpan - boxes.reduce((s, b) => s + b.w, 0)
    const gap = boxes.length > 2 ? totalGap / (boxes.length - 1) : 0
    let cursorX = first.x
    for (const b of boxes) {
      if (b.id !== first.id && b.id !== last.id) {
        cursorX += gap
        fusion.updateObject(b.id, { transform: { x: cursorX } }, `分布 ${btn.label}`, true)
      }
      cursorX += b.w
    }
  } else if (index === 1) {
    boxes.sort((a, b) => a.y - b.y)
    const first = boxes[0]
    const last = boxes[boxes.length - 1]
    const totalSpan = (last.y + last.h) - first.y
    const totalGap = totalSpan - boxes.reduce((s, b) => s + b.h, 0)
    const gap = boxes.length > 2 ? totalGap / (boxes.length - 1) : 0
    let cursorY = first.y
    for (const b of boxes) {
      if (b.id !== first.id && b.id !== last.id) {
        cursorY += gap
        fusion.updateObject(b.id, { transform: { y: cursorY } }, `分布 ${btn.label}`, true)
      }
      cursorY += b.h
    }
  }
  toastStore.show(btn.label, 'fa-arrows-left-right', 'success')
}

// ─── Section collapse state ───
const sections = reactive({
  transform: false,
  align: false,
  appearance: false,
  typography: false,
  pathfinder: false,
  pageProps: false,
  colorManage: false,
  canvas: false,
  frame: false,
})

// ─── Canvas properties ───
const canvasBgColor = ref('#ECEDEF')
const canvasWidth = ref(1440)
const canvasHeight = ref(960)
const canvasShowGrid = ref(false)
const canvasGridSize = ref(10)
const canvasGridColor = ref('#D8DCE1')
const canvasGridDivisions = ref(4)
const canvasSnap = ref(true)
const canvasSnapGrid = ref(true)
const canvasSnapGuide = ref(true)
const canvasShowRuler = ref(true)
const canvasColorOpen = ref(false)

// ─── Export collapsible sections ───
const secExport = reactive({
  basic: false,
  size: false,
  formatOpt: false,
  color: false,
  presets: false,
})

// ─── Inspector tabs ───
const inspectorTabs: { id: 'design' | 'export' | 'settings' | 'ai'; label: string; icon: string }[] = [
  { id: 'design', label: '设计', icon: '' },
  { id: 'export', label: '导出', icon: '' },
  { id: 'settings', label: '设置', icon: 'fa-gear' },
  { id: 'ai', label: 'AI智能', icon: 'fa-wand-magic-sparkles' },
]

const activeTab = ref<'design' | 'export' | 'settings' | 'ai'>('design')

const tabClass = (tab: string) => [
  'text-[12px] leading-[15px] cursor-pointer transition-all duration-100 flex items-center gap-[8px] shrink-0 whitespace-nowrap px-[12px] py-[6px] rounded-[6px] relative',
  activeTab.value === tab ? 'font-[700] text-[var(--color-primary-dark-700)] bg-[var(--color-hover-bg)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300)]' : 'font-[500] text-[var(--color-muted)] hover:text-[var(--color-body)] hover:bg-[var(--color-panel)]',
]

// ─── Settings Tab State ───
const mcpExpanded = ref(false)
const skillExpanded = ref(false)
const sysInfoExpanded = ref(false)
const modelExpanded = ref(false)

// 模型信息配置
const modelProtocols = ['OpenAI', 'Anthropic', 'Google', '本地', '自定义']
const modelProtocol = ref('OpenAI')
const modelProviders = ['OpenAI', 'Azure', 'DeepSeek', '通义千问', '百度文心', '智谱GLM', '讯飞星火', 'Moonshot', '本地', '其他']
const modelProvider = ref('DeepSeek')
const modelUrl = ref('https://api.deepseek.com/v1')
const modelToken = ref('sk-••••••••••••••••')
const modelTokenVisible = ref(false)
const modelId = ref('deepseek-v4-flash')
const modelAdvanced = ref(false)
const modelMaxTokens = ref(8192)
const modelTemperature = ref(0.7)
const modelTimeout = ref(60)
const modelRetries = ref(3)
const modelStream = ref(true)
const modelThinking = ref(true)

// MCP 协议配置（智能体连接我们的协议）
const mcpTools = ref([
  { name: 'canvas.read', icon: 'fa-eye', enabled: true, calls: '47 次' },
  { name: 'canvas.write', icon: 'fa-pen', enabled: true, calls: '23 次' },
  { name: 'layer.list', icon: 'fa-layer-group', enabled: true, calls: '12 次' },
  { name: 'layer.modify', icon: 'fa-pen-nib', enabled: true, calls: '18 次' },
  { name: 'page.manage', icon: 'fa-file', enabled: false, calls: '0 次' },
  { name: 'export.render', icon: 'fa-download', enabled: true, calls: '6 次' },
  { name: 'doc.info', icon: 'fa-circle-info', enabled: true, calls: '34 次' },
  { name: 'style.apply', icon: 'fa-palette', enabled: false, calls: '0 次' },
])

const mcpResources = ref([
  'harmony://canvas/current',
  'harmony://layers',
  'harmony://pages',
  'harmony://pages/{id}',
  'harmony://assets',
  'harmony://styles',
])

// 智能体技能（其他智能体注册到系统的能力）
interface AgentSkill {
  name: string; label: string; icon: string; desc: string; agent: string; connected: boolean
}

const agentSkills = ref<AgentSkill[]>([
  { name: 'ai-image-gen', label: 'AI 图像生成', icon: 'fa-wand-magic-sparkles', desc: '文生图/图生图/智能扩图', agent: '创作引擎', connected: true },
  { name: 'ai-color', label: '智能配色', icon: 'fa-palette', desc: '色彩提取/配色方案/色盲优化', agent: '创作引擎', connected: true },
  { name: 'ai-layout', label: '版式智能', icon: 'fa-object-group', desc: '自动排版/网格生成/布局建议', agent: '创作引擎', connected: true },
  { name: 'ai-font', label: '字体助手', icon: 'fa-font', desc: '字体匹配/字距优化/字体推荐', agent: '创作引擎', connected: true },
  { name: 'ai-copy', label: '文案生成', icon: 'fa-pen', desc: '广告文案/标题生成/多语言翻译', agent: '创作引擎', connected: true },
  { name: 'ai-vector', label: '矢量创作', icon: 'fa-pen-nib', desc: '路径简化/形状生成/图标创作', agent: '创作引擎', connected: true },
  { name: 'ai-mockup', label: '样机生成', icon: 'fa-cube', desc: '3D 样机/场景合成/贴图映射', agent: '渲染引擎', connected: true },
  { name: 'ai-filter', label: '滤镜引擎', icon: 'fa-wand-magic-sparkles', desc: '风格迁移/图像增强/特效滤镜', agent: '渲染引擎', connected: false },
])

// ─── Layer data ───
interface EnhancedLayer extends LayerItem {
  linked?: boolean
  thumbColor?: string
  hasMask?: boolean
  maskEnabled?: boolean
  depth?: number
  expanded?: boolean
  children?: EnhancedLayer[]
  blendMode?: string
}

const layers = ref<EnhancedLayer[]>([
  { name: '组 1', type: 'group', visible: true, active: false, linked: false, locked: false, depth: 0, expanded: true, children: [
    { name: '构想，让设计发生', type: 'text', visible: true, active: true, linked: false, locked: false, depth: 1, hasMask: false, blendMode: 'normal' },
    { name: '正文段落', type: 'text', visible: true, active: false, linked: false, locked: false, depth: 1, hasMask: false, blendMode: 'normal' },
  ]},
  { name: 'Image 01', type: 'image', visible: true, active: false, linked: false, locked: false, depth: 0, hasMask: true, maskEnabled: true, thumbColor: '#E5E7EB', blendMode: 'multiply' },
  { name: 'Green Shape', type: 'shape', visible: true, active: false, linked: false, locked: false, depth: 0, iconColor: 'green', thumbColor: '#3AC487', hasMask: false, blendMode: 'overlay' },
  { name: '色相/饱和度', type: 'adjustment', visible: true, active: false, linked: false, locked: false, depth: 0, hasMask: true, maskEnabled: false, blendMode: 'color' },
  { name: 'Background', type: 'shape', visible: true, locked: true, active: false, depth: 0, iconColor: 'gray', thumbColor: '#BFC6CB', hasMask: false, blendMode: 'normal' },
  { name: '纯色填充', type: 'fill', visible: true, active: false, linked: false, locked: false, depth: 0, thumbColor: '#30D158', hasMask: false, blendMode: 'screen' },
  { name: '智能对象', type: 'image', visible: false, active: false, linked: true, locked: false, depth: 0, hasMask: true, maskEnabled: true, thumbColor: '#D1D5DB', blendMode: 'normal' },
])

// ─── Layer effects (已迁移到 currentEffects) ───
const _layerEffectsDeprecated = [
  { name: '投影', icon: 'fa-solid fa-cloud-arrow-down', value: '2px · #000 40%', active: true },
  { name: '内阴影', icon: 'fa-solid fa-circle-half-stroke', value: '', active: false },
  { name: '外发光', icon: 'fa-solid fa-circle-radiation', value: '', active: false },
  { name: '内发光', icon: 'fa-solid fa-bullseye', value: '', active: false },
  { name: '斜面与浮雕', icon: 'fa-solid fa-cube', value: '', active: false },
  { name: '光泽', icon: 'fa-solid fa-water', value: '', active: false },
  { name: '颜色叠加', icon: 'fa-solid fa-droplet', value: '', active: false },
  { name: '渐变叠加', icon: 'fa-solid fa-paint-roller', value: '', active: false },
  { name: '图案叠加', icon: 'fa-solid fa-border-all', value: '', active: false },
]

// ─── Type style buttons（响应式，根据当前对象状态高亮） ───
const typeStyleBtns = computed(() => {
  const obj = currentObject.value
  const isText = obj?.type === 'text'
  const tobj = isText ? (obj as unknown as TextObject) : null
  return [
    { type: 'text' as const, label: 'B', cssClass: 'font-[700]', icon: '', title: '加粗 Ctrl+B', active: tobj ? tobj.fontWeight >= 700 : false },
    { type: 'text' as const, label: 'I', cssClass: 'italic font-[700]', icon: '', title: '斜体 Ctrl+I', active: tobj ? tobj.fontStyle === 'italic' : false },
    { type: 'text' as const, label: 'U', cssClass: 'underline font-[700]', icon: '', title: '下划线 Ctrl+U', active: tobj ? tobj.textDecoration === 'underline' : false },
    { type: 'icon' as const, label: '', cssClass: '', icon: 'fa-align-left', title: '左对齐', active: tobj ? tobj.align === 'left' : false },
    { type: 'icon' as const, label: '', cssClass: '', icon: 'fa-align-center', title: '居中', active: tobj ? tobj.align === 'center' : false },
    { type: 'icon' as const, label: '', cssClass: '', icon: 'fa-align-right', title: '右对齐', active: tobj ? tobj.align === 'right' : false },
    { type: 'icon' as const, label: '', cssClass: '', icon: 'fa-align-justify', title: '两端对齐', active: tobj ? tobj.align === 'justify' : false },
  ]
})

// ─── 字重选项 ───
const fontWeightOptions = [
  { value: 300, label: '细' },
  { value: 400, label: '常规' },
  { value: 500, label: '中' },
  { value: 600, label: '半粗' },
  { value: 700, label: '粗' },
  { value: 800, label: '特粗' },
]

// ─── Alignment buttons ───
const alignButtons = [
  { icon: 'fa-align-left', label: '左对齐', active: false },
  { icon: 'fa-align-center', label: '水平居中', active: false },
  { icon: 'fa-align-right', label: '右对齐', active: false },
  { icon: 'fa-arrow-up', label: '顶对齐', active: false },
  { icon: 'fa-arrows-up-down', label: '垂直居中', active: false },
  { icon: 'fa-arrow-down', label: '底对齐', active: true },
]

const distributeButtons = [
  { icon: 'fa-arrows-left-right', label: '水平均匀分布', active: false },
  { icon: 'fa-arrows-up-down', label: '垂直均匀分布', active: false },
  { icon: 'fa-arrows-left-right-to-line', label: '水平间距', active: false },
  { icon: 'fa-arrows-up-down-to-line', label: '垂直间距', active: false },
]

const pathfinderOps = [{ label: '合集' }, { label: '差集' }, { label: '交集' }, { label: '排除' }]

// ─── Page Properties (标准化) ───
const pageSize = ref('A4')
const pageWidth = ref('210 mm')
const pageHeight = ref('297 mm')
const pageOrientation = ref('纵向')
const pageUnit = ref('mm')
const pageDPI = ref('300 DPI')

// Bleed
const bleedEnabled = ref(false)
const bleedTop = ref('3 mm')
const bleedBottom = ref('3 mm')
const bleedLeft = ref('3 mm')
const bleedRight = ref('3 mm')

// Margins
const marginPreset = ref('常规')
const marginTop = ref('20 mm')
const marginBottom = ref('20 mm')
const marginLeft = ref('15 mm')
const marginRight = ref('15 mm')

// Columns
const columns = ref('12')
const columnGutter = ref('8 mm')

// ─── Color Management ───
const currentColorHex = ref('#3AC487')
const colorSwatches = ['#3AC487', '#16865F', '#0D5A3D', '#3B82F6', '#22C55E', '#F59E0B', '#EF4444', '#263238', '#FFFFFF', '#000000']

const onColorPickerSelect = (hex: string) => {
  currentColorHex.value = hex
}

// ─── Export Tab ───
const exportFormat = ref('png')
const formatLabels: Record<string, string> = {
  png: 'PNG 选项', jpg: 'JPEG 选项', webp: 'WebP 选项',
  svg: 'SVG 选项', pdf: 'PDF 选项', eps: 'EPS 选项',
  cdr: 'CDR 选项', hds: 'HDS 选项',
}
const formatOptionLabel = computed(() => formatLabels[exportFormat.value] || '格式选项')
const exportFormats = [
  { id: 'png', name: 'PNG' },
  { id: 'jpg', name: 'JPEG' },
  { id: 'webp', name: 'WebP' },
  { id: 'svg', name: 'SVG' },
  { id: 'pdf', name: 'PDF' },
  { id: 'eps', name: 'EPS' },
  { id: 'cdr', name: 'CDR' },
  { id: 'hds', name: 'HDS' },
]
const exportQuality = ref(92)
const exportScale = ref(100)
const exportConstrain = ref(true)
const exportTransparent = ref(true)
const exportColorSpace = ref('sRGB')
const exportColorSpaces = ['sRGB', 'Adobe RGB', 'Display P3', 'CMYK']
const exportEmbedICC = ref(true)
const exportPreset = ref('PNG-24 透明')
const exportPresets = [
  'PNG-24 透明', 'PNG-8 256色', 'JPEG 最大质量', 'JPEG 网页中等',
  'WebP 无损', 'WebP 有损 80%', 'SVG 压缩', 'PDF 打印高质',
  'PDF 网页最小', 'EPS 印刷', 'CDR 兼容', 'HDS 标准归档'
]
const estimatedSize = computed(() => {
  const base = 420 * 600 * 3 // raw pixel data estimate
  const qualityFactor = exportQuality.value / 100
  const sizeKb = Math.round(base * qualityFactor * 0.1 * (exportScale.value / 100) ** 2 / 1024)
  if (sizeKb < 1024) return `${Math.max(4, sizeKb)} KB`
  return `${(sizeKb / 1024).toFixed(1)} MB`
})

// PNG-specific
const pngMode = ref('PNG-24')
const pngInterlace = ref(false)

// JPEG-specific
const jpegProgressive = ref(false)
const jpegOptimize = ref(true)

// SVG-specific
const svgInline = ref(true)
const svgMinify = ref(true)
const svgResponsive = ref(true)

// EPS/CDR
const embedFonts = ref(true)
const embedImages = ref(true)

// HDS
const hdsMode = ref('标准')

// PDF
const pdfStandard = ref('PDF/X-1a')
const pdfStandards = ['PDF/X-1a', 'PDF/X-3', 'PDF/X-4', 'PDF/A-1b', 'PDF/A-2b', 'PDF 2.0']
const pdfCropMarks = ref(true)
const pdfBleedMarks = ref(true)
const pdfColorBars = ref(false)
const hdsEmbedFonts = ref(true)
const hdsEmbedImages = ref(true)

// ─── Layer operations ───
const selectLayer = (index: number) => { layers.value.forEach((l, i) => l.active = i === index) }
const toggleVisibility = (index: number) => { layers.value[index].visible = !layers.value[index].visible }
const toggleLock = (index: number) => { layers.value[index].locked = !layers.value[index].locked }

// Flatten layers (groups expanded) for rendering
const flatLayers = computed(() => {
  const result: (EnhancedLayer & { _key: string })[] = []
  let keyCounter = 0
  const walk = (items: EnhancedLayer[]) => {
    items.forEach(item => {
      const key = `layer_${keyCounter++}`
      if (item.type === 'group' && item.expanded && item.children) {
        result.push({ ...item, _key: key })
        walk(item.children)
      } else {
        result.push({ ...item, _key: key })
      }
    })
  }
  walk(layers.value)
  return result
})

const selectLayerByKey = (key: string) => {
  const idx = flatLayers.value.findIndex(l => l._key === key)
  if (idx >= 0) {
    layers.value.forEach(l => { l.active = false; l.children?.forEach(c => c.active = false) })
    // Find actual layer
    for (const l of layers.value) {
      if ((l as any)._key === key) { l.active = true; break }
      if (l.children) {
        for (const c of l.children) {
          if ((c as any)._key === key) { c.active = true; break }
        }
      }
    }
  }
}
const toggleVisibilityByKey = (key: string) => {
  for (const l of layers.value) {
    if ((l as any)._key === key) { l.visible = !l.visible; return }
    if (l.children) { for (const c of l.children) { if ((c as any)._key === key) { c.visible = !c.visible; return } } }
  }
}
const toggleLockByKey = (key: string) => {
  for (const l of layers.value) {
    if ((l as any)._key === key) { l.locked = !l.locked; return }
    if (l.children) { for (const c of l.children) { if ((c as any)._key === key) { c.locked = !c.locked; return } } }
  }
}

// Group toggle
const toggleGroup = (layer: EnhancedLayer) => {
  if (layer.type === 'group') {
    layer.expanded = !layer.expanded
  }
}

// Mask operations
const addMask = (layer: EnhancedLayer) => {
  layer.hasMask = true
  layer.maskEnabled = true
}
const toggleMask = (layer: EnhancedLayer) => {
  layer.maskEnabled = !layer.maskEnabled
}

// Drag reorder
const dragIndex = ref(-1)
const dragOverIndex = ref(-1)
const layerListEl = ref<HTMLElement | null>(null)

const onLayerDragStart = (e: MouseEvent, index: number) => {
  dragIndex.value = index
  dragOverIndex.value = -1
}

const onLayerDragOver = (index: number) => {
  if (dragIndex.value >= 0 && dragIndex.value !== index) {
    dragOverIndex.value = index
  }
}

onMounted(() => {
  document.addEventListener('mouseup', onGlobalMouseUp)
  document.addEventListener('click', onGlobalClick)
})

onUnmounted(() => {
  document.removeEventListener('mouseup', onGlobalMouseUp)
  document.removeEventListener('click', onGlobalClick)
})

const onGlobalClick = () => {
  // Close blend mode popup on click outside
  showBlendModePopup.value = false
}

const onGlobalMouseUp = () => {
  if (dragIndex.value >= 0 && dragOverIndex.value >= 0 && dragIndex.value !== dragOverIndex.value) {
    const flat = flatLayers.value
    if (dragIndex.value < flat.length && dragOverIndex.value < flat.length) {
      // Swap in the actual layers array (simplified reorder)
      const item = flat[dragIndex.value]
      const target = flat[dragOverIndex.value]
      // Find in original hierarchy - simplified: just reorder top-level
      const fromIdx = layers.value.findIndex((l: any) => (l as any)._key === item._key)
      const toIdx = layers.value.findIndex((l: any) => (l as any)._key === target._key)
      if (fromIdx >= 0 && toIdx >= 0) {
        const [moved] = layers.value.splice(fromIdx, 1)
        layers.value.splice(toIdx, 0, moved)
      }
    }
  }
  dragIndex.value = -1
  dragOverIndex.value = -1
}

// ─── Context menu ───
const contextMenu = reactive({ visible: false, x: 0, y: 0, layerIndex: -1 })
const contextMenuItems = [
  { label: '复制图层', icon: 'fa-copy', shortcut: 'Ctrl+J', action: 'duplicate' },
  { label: '新建图层', icon: 'fa-plus', shortcut: 'Ctrl+Shift+N', action: 'new' },
  { label: '新建组', icon: 'fa-layer-group', shortcut: 'Ctrl+G', action: 'group' },
  { label: '混合模式', icon: 'fa-blender', shortcut: '', action: 'blendMode', hasSubmenu: true },
  { label: '合并图层', icon: 'fa-object-group', shortcut: 'Ctrl+E', action: 'merge' },
  { label: '合并可见', icon: 'fa-eye', shortcut: 'Ctrl+Shift+E', action: 'mergeVisible' },
  { label: '向下合并', icon: 'fa-arrow-down', shortcut: 'Ctrl+Alt+E', action: 'mergeDown' },
  { label: '栅格化', icon: 'fa-border-all', action: 'rasterize' },
  { label: '转换为智能对象', icon: 'fa-wand-magic-sparkles', action: 'smartObject' },
  { label: '复制 CSS', icon: 'fa-code', action: 'copyCSS' },
  { label: '删除图层', icon: 'fa-trash', shortcut: 'Delete', action: 'delete' },
]
const onLayerContextMenu = (index: number, event: MouseEvent) => { contextMenu.visible = true; contextMenu.x = event.clientX; contextMenu.y = event.clientY; contextMenu.layerIndex = index }
const closeContextMenu = () => { contextMenu.visible = false; blendModeSubmenu.visible = false }
const handleContextAction = (action: string) => {
  if (action === 'blendMode') {
    // Open blend mode submenu to the right of the context menu
    blendModeSubmenu.x = contextMenu.x + 180
    blendModeSubmenu.y = contextMenu.y
    blendModeSubmenu.visible = true
    return
  }
  closeContextMenu()
}

// ─── Blend Mode (Context Menu Submenu) ───
const blendModeSubmenu = reactive({ visible: false, x: 0, y: 0 })
const currentContextBlendValue = computed(() => {
  if (contextMenu.layerIndex < 0) return 'normal'
  const flat = flatLayers.value
  const layer = flat[contextMenu.layerIndex]
  if (!layer) return 'normal'
  return layer.blendMode || 'normal'
})
const currentContextLayerBlend = computed(() => getBlendModeLabel(currentContextBlendValue.value))
const setContextBlendMode = (value: string) => {
  if (contextMenu.layerIndex < 0) return
  const flat = flatLayers.value
  const layer = flat[contextMenu.layerIndex]
  if (!layer) return
  layer.blendMode = value
  layerBlendModes[layer.name] = value
  blendModeSubmenu.visible = false
  contextMenu.visible = false
}

// ─── Blend Mode (Inline Popup in Appearance section) ───
// 优先绑定到选中对象（对象级），fallback 到当前图层
const showBlendModePopup = ref(false)
const layerBlendModeValue = computed(() => {
  // Find the active layer
  for (const l of layers.value) {
    if (l.active) return l.blendMode || 'normal'
    if (l.children) { for (const c of l.children) { if (c.active) return c.blendMode || 'normal' } }
  }
  return 'normal'
})
const currentBlendValue = computed<string>(() => {
  // 优先使用对象级混合模式
  if (hasSingleSelection.value && currentObject.value) {
    return currentObject.value.blendMode || 'normal'
  }
  return layerBlendModeValue.value
})
const currentBlendLabel = computed(() => getBlendModeLabel(currentBlendValue.value))
// 图层面板仍使用图层级 blend mode（不带对象 fallback）
const currentLayerBlendLabel = computed(() => getBlendModeLabel(layerBlendModeValue.value))
const blendPopupStyle = computed(() => {
  return { right: '12px', top: 'auto', bottom: 'auto' }
})
const setBlendMode = (value: string) => {
  // 若有单选对象，更新到对象级
  if (hasSingleSelection.value && currentObject.value) {
    fusion.pushHistory(`设置混合模式 ${getBlendModeLabel(value)}`)
    currentObject.value.blendMode = value as BlendMode
  } else {
    // fallback 更新图层
    for (const l of layers.value) {
      if (l.active) { l.blendMode = value; layerBlendModes[l.name] = value; break }
      if (l.children) { for (const c of l.children) { if (c.active) { c.blendMode = value; layerBlendModes[c.name] = value; break } } }
    }
  }
  showBlendModePopup.value = false
}
function toggleBlendModePopup(): void {
  showBlendModePopup.value = !showBlendModePopup.value
}

// ─── 外观属性：填充 / 描边 / 不透明度 / 文本色 ───
// 兼容性判断：当前选中对象支持哪些外观字段
const hasFill = computed<boolean>(() => {
  if (!hasSingleSelection.value || !currentObject.value) return false
  const t = currentObject.value.type
  return t === 'shape' || t === 'fill'
})
const hasTextColor = computed<boolean>(() => {
  if (!hasSingleSelection.value || !currentObject.value) return false
  return currentObject.value.type === 'text'
})
const hasStroke = computed<boolean>(() => {
  if (!hasSingleSelection.value || !currentObject.value) return false
  return currentObject.value.type === 'shape'
})
// 是否为文字对象
const isTextObject = computed<boolean>(() => {
  if (!hasSingleSelection.value || !currentObject.value) return false
  return currentObject.value.type === 'text'
})
// 是否支持圆角半径（仅矩形）
const hasCornerRadius = computed<boolean>(() => {
  if (!hasSingleSelection.value || !currentObject.value) return false
  if (currentObject.value.type !== 'shape') return false
  const s = currentObject.value as ShapeObject
  return s.shape === 'rectangle'
})

// ─── 文字属性双向绑定 ───
const textContent = ref<string>('')
const textFontFamily = ref<string>('HarmonyOS Sans SC')
const textFontSize = ref<number>(14)
const textFontWeight = ref<number>(400)
const textLineHeight = ref<number>(1.5)
const textLetterSpacing = ref<number>(0)
const textColorValue = ref<string>('#1F2329')

// 监听选中对象变化，同步文字属性到本地 ref
watch(() => currentObject.value?.id, () => {
  const obj = currentObject.value
  if (obj && obj.type === 'text') {
    const t = obj as unknown as TextObject
    textContent.value = t.text ?? ''
    textFontFamily.value = t.fontFamily ?? 'HarmonyOS Sans SC'
    textFontSize.value = t.fontSize ?? 14
    textFontWeight.value = t.fontWeight ?? 400
    textLineHeight.value = t.lineHeight ?? 1.5
    textLetterSpacing.value = t.letterSpacing ?? 0
    textColorValue.value = t.color ?? '#1F2329'
  }
}, { immediate: true })

// 同步当前对象的所有文字属性（用于 watch 触发时统一更新）
watch(() => currentObject.value, () => {
  const obj = currentObject.value
  if (obj && obj.type === 'text') {
    const t = obj as unknown as TextObject
    textContent.value = t.text ?? ''
    textFontFamily.value = t.fontFamily ?? 'HarmonyOS Sans SC'
    textFontSize.value = t.fontSize ?? 14
    textFontWeight.value = t.fontWeight ?? 400
    textLineHeight.value = t.lineHeight ?? 1.5
    textLetterSpacing.value = t.letterSpacing ?? 0
    textColorValue.value = t.color ?? '#1F2329'
  }
}, { deep: false })

function onTextContentChange(): void {
  if (!currentObject.value || currentObject.value.type !== 'text') return
  fusion.pushHistory('修改文字内容')
  ;(currentObject.value as unknown as TextObject).text = textContent.value
}
function onTextFontChange(): void {
  if (!currentObject.value || currentObject.value.type !== 'text') return
  fusion.pushHistory('修改文字属性')
  const t = currentObject.value as unknown as TextObject
  t.fontFamily = textFontFamily.value
  t.fontSize = textFontSize.value
  t.lineHeight = textLineHeight.value
  t.letterSpacing = textLetterSpacing.value
}
function setTextFontWeight(w: number): void {
  if (!currentObject.value || currentObject.value.type !== 'text') return
  fusion.pushHistory('修改字重')
  ;(currentObject.value as unknown as TextObject).fontWeight = w
  textFontWeight.value = w
}
function onTypeStyleClick(btn: { type: string; label: string; title: string }): void {
  if (!currentObject.value || currentObject.value.type !== 'text') return
  const t = currentObject.value as unknown as TextObject
  fusion.pushHistory(`修改文字样式 ${btn.title}`)
  if (btn.label === 'B') {
    t.fontWeight = t.fontWeight >= 700 ? 400 : 700
    textFontWeight.value = t.fontWeight
  } else if (btn.label === 'I') {
    t.fontStyle = t.fontStyle === 'italic' ? 'normal' : 'italic'
  } else if (btn.label === 'U') {
    t.textDecoration = t.textDecoration === 'underline' ? 'none' : 'underline'
  } else {
    // 对齐按钮
    const map: Record<string, TextObject['align']> = {
      '左对齐': 'left',
      '居中': 'center',
      '右对齐': 'right',
      '两端对齐': 'justify',
    }
    const align = map[btn.title]
    if (align) t.align = align
  }
}
function onTextColorChange(): void {
  if (!currentObject.value || currentObject.value.type !== 'text') return
  fusion.pushHistory('修改文字颜色')
  ;(currentObject.value as unknown as TextObject).color = textColorValue.value
}

// ─── 圆角半径 ───
const cornerRadius = computed<number>(() => {
  if (!currentObject.value || currentObject.value.type !== 'shape') return 0
  return (currentObject.value as ShapeObject).cornerRadius ?? 0
})
function onCornerRadiusChange(e: Event): void {
  if (!currentObject.value || currentObject.value.type !== 'shape') return
  const v = Math.max(0, Math.min(500, Number((e.target as HTMLInputElement).value) || 0))
  fusion.pushHistory('修改圆角半径')
  ;(currentObject.value as ShapeObject).cornerRadius = v
}

// 填充色（shape.fill / fill.color）
const fillColor = computed<string>(() => {
  if (!currentObject.value) return '#3AC487'
  const obj = currentObject.value as unknown as { fill?: string; color?: string }
  return obj.fill ?? obj.color ?? '#3AC487'
})
// 文本色（text.color）
const textColor = computed<string>(() => {
  if (!currentObject.value) return '#1F2329'
  const obj = currentObject.value as unknown as { color?: string }
  return obj.color ?? '#1F2329'
})
// 描边色与宽度（shape.stroke / shape.strokeWidth）
const strokeColor = computed<string>(() => {
  if (!currentObject.value || currentObject.value.type !== 'shape') return '#1F2329'
  return (currentObject.value as ShapeObject).stroke ?? '#1F2329'
})
const strokeWidth = computed<number>(() => {
  if (!currentObject.value || currentObject.value.type !== 'shape') return 0
  return (currentObject.value as ShapeObject).strokeWidth ?? 0
})
// 描边位置：外部/居中/内部（仅作为元数据存到 metadata.strokePosition）
type StrokePosition = 'outside' | 'center' | 'inside'
const strokePositionOptions: { value: StrokePosition; label: string }[] = [
  { value: 'outside', label: '外部' },
  { value: 'center', label: '居中' },
  { value: 'inside', label: '内部' },
]
const strokePosition = computed<StrokePosition>(() => {
  if (!currentObject.value) return 'center'
  const m = (currentObject.value.metadata ?? {}) as Record<string, unknown>
  return (m.strokePosition as StrokePosition) ?? 'center'
})
function setStrokePosition(p: StrokePosition): void {
  if (!hasSingleSelection.value || !currentObject.value) return
  fusion.pushHistory(`修改描边位置 ${p}`)
  if (!currentObject.value.metadata) {
    ;(currentObject.value as SceneObject).metadata = {}
  }
  ;(currentObject.value.metadata as Record<string, unknown>).strokePosition = p
  toastStore.show(`描边位置：${strokePositionOptions.find(o => o.value === p)?.label}`, 'fa-border-all', 'info')
}

// 不透明度（transform.opacity 0-100）
const opacityValue = computed<number>(() => {
  if (!currentTransform.value) return 100
  return Math.round(currentTransform.value.opacity ?? 100)
})
let opacityEditing = false
function onAppearanceFocus(description: string): void {
  if (!hasSingleSelection.value || opacityEditing) return
  opacityEditing = true
  fusion.pushHistory(description)
}
function onAppearanceChange(): void {
  opacityEditing = false
}
function onOpacityInput(e: Event): void {
  if (!currentTransform.value) return
  const v = Number((e.target as HTMLInputElement).value)
  currentTransform.value.opacity = Math.max(0, Math.min(100, v))
}
function onOpacityNumberChange(e: Event): void {
  if (!currentTransform.value) return
  const v = Number((e.target as HTMLInputElement).value)
  const clamped = Math.max(0, Math.min(100, Number.isFinite(v) ? v : 100))
  currentTransform.value.opacity = clamped
  opacityEditing = false
}
function onStrokeWidthChange(e: Event): void {
  if (!currentObject.value || currentObject.value.type !== 'shape') return
  const v = Number((e.target as HTMLInputElement).value)
  const clamped = Math.max(0, Math.min(100, Number.isFinite(v) ? v : 0))
  ;(currentObject.value as ShapeObject).strokeWidth = clamped
  opacityEditing = false
}

// ─── 颜色选择器弹窗 ───
const colorPicker = reactive({
  visible: false,
  x: 0,
  y: 0,
  target: 'fill' as 'fill' | 'stroke' | 'color',
  value: '#3AC487',
})
function openColorPicker(e: MouseEvent, target: 'fill' | 'stroke' | 'color'): void {
  if (!hasSingleSelection.value) {
    toastStore.show('请先选择对象', 'fa-circle-info', 'info')
    return
  }
  // 取当前颜色作为初始值
  let cur = '#3AC487'
  if (target === 'fill') {
    cur = fillColor.value
  } else if (target === 'stroke') {
    cur = strokeColor.value
  } else if (target === 'color') {
    cur = textColor.value
  }
  colorPicker.target = target
  colorPicker.value = cur.toUpperCase()
  colorPicker.x = e.clientX
  colorPicker.y = e.clientY + 8
  colorPicker.visible = true
  fusion.pushHistory(`修改${target === 'fill' ? '填充' : target === 'stroke' ? '描边' : '文字'}色`)
}
function onColorPick(hex: string): void {
  if (!hasSingleSelection.value || !currentObject.value) {
    colorPicker.value = hex.toUpperCase()
    return
  }
  colorPicker.value = hex.toUpperCase()
  // 同步到对象字段
  const obj = currentObject.value as unknown as Record<string, unknown>
  if (colorPicker.target === 'fill') {
    if (currentObject.value.type === 'shape') {
      ;(currentObject.value as ShapeObject).fill = hex
    } else if (currentObject.value.type === 'fill') {
      ;(currentObject.value as FillObject).color = hex
    }
  } else if (colorPicker.target === 'stroke') {
    if (currentObject.value.type === 'shape') {
      ;(currentObject.value as ShapeObject).stroke = hex
    }
  } else if (colorPicker.target === 'color') {
    if (currentObject.value.type === 'text') {
      ;(currentObject.value as TextObject).color = hex
    }
  }
  // 避免 unused warning
  void obj
}
function closeColorPicker(): void {
  colorPicker.visible = false
}

/** 取消选中（同时清除 fusion 对象选中与 layerStore） */
function deselectAll(): void {
  fusion.deselectAll()
  layerStore.deselect()
}

// ─── 图层效果链 fx ───
const showFxMenu = ref(false)
const fxAvailableTypes: { value: LayerEffect['type']; label: string; icon: string }[] = [
  { value: 'drop-shadow', label: '投影', icon: 'fa-solid fa-cloud-arrow-down' },
  { value: 'inner-shadow', label: '内阴影', icon: 'fa-solid fa-circle-half-stroke' },
  { value: 'outer-glow', label: '外发光', icon: 'fa-solid fa-circle-radiation' },
  { value: 'inner-glow', label: '内发光', icon: 'fa-solid fa-bullseye' },
  { value: 'bevel', label: '斜面与浮雕', icon: 'fa-solid fa-cube' },
  { value: 'satin', label: '光泽', icon: 'fa-solid fa-water' },
  { value: 'color-overlay', label: '颜色叠加', icon: 'fa-solid fa-droplet' },
  { value: 'gradient-overlay', label: '渐变叠加', icon: 'fa-solid fa-paint-roller' },
  { value: 'pattern-overlay', label: '图案叠加', icon: 'fa-solid fa-border-all' },
]
function fxLabel(type: LayerEffect['type']): string {
  return fxAvailableTypes.find(f => f.value === type)?.label ?? type
}
function fxIcon(type: LayerEffect['type']): string {
  return fxAvailableTypes.find(f => f.value === type)?.icon ?? 'fa-solid fa-wand-magic-sparkles'
}
function fxSummary(fx: LayerEffect): string {
  const p = fx.params
  switch (fx.type) {
    case 'drop-shadow':
    case 'inner-shadow': {
      const dist = (p.distance as number) ?? 5
      const color = (p.color as string) ?? '#000000'
      const op = (p.opacity as number) ?? 40
      return `${dist}px · ${color} ${op}%`
    }
    case 'outer-glow':
    case 'inner-glow': {
      const color = (p.color as string) ?? '#3AC487'
      const op = (p.opacity as number) ?? 50
      return `${color} ${op}%`
    }
    case 'color-overlay': {
      const color = (p.color as string) ?? '#3AC487'
      const op = (p.opacity as number) ?? 100
      return `${color} ${op}%`
    }
    case 'bevel':
      return `${(p.style as string) ?? 'inner'} · ${(p.depth as number) ?? 50}%`
    case 'satin':
      return `${(p.size as number) ?? 14}px`
    case 'gradient-overlay':
      return `${(p.angle as number) ?? 90}°`
    case 'pattern-overlay':
      return `${(p.scale as number) ?? 100}%`
    default:
      return '—'
  }
}
// 当前图层的效果列表
const currentEffects = computed<LayerEffect[]>(() => {
  const layer = fusion.selectedLayer
  if (!layer) return []
  return layer.effects ?? []
})
function addFx(type: LayerEffect['type']): void {
  const layerId = fusion.selectedLayerId
  if (!layerId) {
    toastStore.show('请先选择图层', 'fa-circle-info', 'warning')
    return
  }
  fusion.addEffect(layerId, type)
  toastStore.show(`已添加图层样式：${fxLabel(type)}`, 'fa-plus', 'success')
  showFxMenu.value = false
}
function removeFx(fxId: string): void {
  const layerId = fusion.selectedLayerId
  if (!layerId) return
  fusion.removeEffect(layerId, fxId)
  toastStore.show('已删除图层样式', 'fa-trash', 'warning')
}
function toggleFx(fxId: string): void {
  const layer = fusion.selectedLayer
  if (!layer) return
  const fx = layer.effects.find(f => f.id === fxId)
  if (!fx) return
  fusion.pushHistory(`${fx.enabled ? '禁用' : '启用'}图层样式 ${fxLabel(fx.type)}`)
  fx.enabled = !fx.enabled
}
function openFxEditor(fxId: string): void {
  // 简化版：仅 toast 提示，未来扩展为完整参数编辑面板
  const layer = fusion.selectedLayer
  if (!layer) return
  const fx = layer.effects.find(f => f.id === fxId)
  if (!fx) return
  toastStore.show(`编辑 ${fxLabel(fx.type)}（参数面板开发中）`, 'fa-sliders', 'info')
}

// ─── Window Settings ───
const showWindowSettings = ref(false)
const layoutPresets = [
  { id: 'default', name: '默认布局', preview: [20, 60, 20] },
  { id: 'typo', name: '排版设计', preview: [15, 55, 30] },
  { id: 'painting', name: '绘画', preview: [10, 70, 20] },
  { id: 'photo', name: '摄影', preview: [15, 65, 20] },
  { id: 'minimal', name: '极简', preview: [5, 85, 10] },
]
const activePreset = ref('default')
const toolbarItems = reactive([
  { label: '对齐工具', visible: true },
  { label: '分布工具', visible: true },
  { label: '排列工具', visible: true },
  { label: '编组/解组', visible: true },
  { label: '变换读数', visible: true },
  { label: '撤销/重做', visible: true },
  { label: '保存/导出', visible: true },
  { label: '预览模式', visible: true },
])
const panelItems = reactive([
  { label: '工具轨', visible: true },
  { label: '页面面板', visible: true },
  { label: '检查器', visible: true },
  { label: 'AI 助手', visible: true },
  { label: '图层面板', visible: true },
  { label: '色板面板', visible: false },
  { label: '历史记录', visible: false },
  { label: '信息面板', visible: false },
])
</script>
