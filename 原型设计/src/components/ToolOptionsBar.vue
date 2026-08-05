<template>
  <div class="flex flex-col bg-[var(--color-white)] border-b border-[var(--color-border)] shrink-0">
    <!-- Row 1: Group headers (always visible) -->
    <div class="flex flex-row justify-between items-center h-[40px] px-[10px]">
      <div class="flex flex-row justify-start items-center gap-[4px]">
        <div class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[7px] cursor-pointer hover:bg-[var(--color-border-light)] transition-colors duration-100" title="主页" @click="$emit('home')">
          <i class="fa-solid fa-house text-[13px] text-[var(--color-secondary)]"></i>
        </div>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)] mx-[6px]"></div>
        <div v-for="(grp, gi) in toolGroups" :key="grp.id"
          class="flex flex-row items-center gap-[5px] px-[9px] py-[5px] rounded-[6px] cursor-pointer select-none hover:bg-[var(--color-border-light)] transition-all duration-100"
          :class="grp.expanded ? 'bg-[var(--color-hover-bg)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300)]' : ''"
          @click="grp.expanded = !grp.expanded"
        >
          <i class="fa-solid text-[9px] transition-transform duration-150" :class="[grp.expanded ? 'fa-chevron-down text-[var(--color-primary-dark-700)]' : 'fa-chevron-right text-[var(--color-muted)]']"></i>
          <i :class="['fa-solid', grp.icon, 'text-[11px]', grp.expanded ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]']"></i>
          <span class="text-[12px] leading-[15px] font-[600]" :class="grp.expanded ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]'">{{ grp.label }}</span>
        </div>
      </div>
      <div class="flex flex-row items-center gap-[10px]">
        <div class="flex flex-row items-center gap-[7px] px-[8px] py-[4px] bg-[var(--color-panel)] rounded-[5px] border border-[var(--color-border-light)]">
          <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-muted)]">W</span><span class="text-[11px] leading-[14px] font-[600] text-[var(--color-body)] font-mono">148</span>
          <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-muted)]">H</span><span class="text-[11px] leading-[14px] font-[600] text-[var(--color-body)] font-mono">92</span>
          <span class="text-[11px] leading-[14px] font-[500] text-[var(--color-muted)]">∠</span><span class="text-[11px] leading-[14px] font-[600] text-[var(--color-body)] font-mono">0°</span>
        </div>
        <div class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[5px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors duration-100" :title="collapsed ? '展开全部' : '收起全部'" @click="collapsed = !collapsed">
          <i class="fa-solid text-[10px] text-[var(--color-muted)]" :class="collapsed ? 'fa-chevron-down' : 'fa-chevron-up'"></i>
        </div>
      </div>
    </div>

    <!-- Row 2: 布局工具 (编组/排列/对齐/分布) - 紧凑单行 -->
    <div v-show="layoutExpanded" class="flex flex-row items-center gap-[8px] px-[12px] py-[7px] border-t border-[var(--color-border-light)] bg-[var(--color-panel)] overflow-x-auto">
      <template v-for="(group, gi) in layoutGroups" :key="group.id">
        <div v-if="toolGroups[gi].expanded" class="flex flex-row items-center gap-[3px]" :title="group.label">
          <span class="text-[10px] leading-[13px] font-[700] text-[var(--color-muted)] uppercase tracking-wider px-[5px] select-none">{{ group.label }}</span>
          <div
            v-for="(item, i) in group.items"
            :key="group.id + i"
            class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[5px] cursor-pointer transition-all duration-100"
            :class="item.active
              ? 'bg-[var(--color-primary-light-100)] text-[var(--color-primary-dark-700)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300)]'
              : 'text-[var(--color-secondary)] hover:bg-[var(--color-white)] hover:shadow-[inset_0_0_0_1px_var(--color-border)]'"
            :title="item.shortcut ? item.label + ' (' + item.shortcut + ')' : item.label"
            @click="onToolClick(group.id, item)"
          >
            <i :class="['fa-solid', item.icon, 'text-[12px]']"></i>
          </div>
        </div>
        <div v-if="toolGroups[gi].expanded && gi < layoutGroups.length - 1 && toolGroups[gi+1].expanded" class="w-[1px] h-[18px] bg-[var(--color-border)] mx-[3px] shrink-0"></div>
      </template>
      <!-- 右侧：对齐目标 + 关键对象 -->
      <div class="flex flex-row items-center gap-[7px] ml-auto shrink-0 pl-[10px] border-l border-[var(--color-border-light)]">
        <span class="text-[11px] font-[500] text-[var(--color-muted)]">对齐到</span>
        <select v-model="alignTarget" class="h-[26px] px-[6px] text-[11px] font-[500] border border-[var(--color-border)] rounded-[4px] outline-none bg-[var(--color-white)] text-[var(--color-body)] cursor-pointer hover:border-[var(--color-primary)]">
          <option value="selection">所选对象</option>
          <option value="artboard">画板</option>
          <option value="key">关键对象</option>
        </select>
      </div>
    </div>

    <!-- Row 3: 矢量工具 - 主行（路径/编辑/形状） -->
    <div v-show="toolGroups[4].expanded" class="flex flex-col border-t border-[var(--color-border-light)] bg-[var(--color-panel)]">
      <div class="flex flex-row flex-wrap items-center gap-x-[10px] gap-y-[6px] px-[12px] py-[8px]">
        <span class="text-[12px] leading-[15px] font-[700] text-[var(--color-primary-dark-700)] mr-[2px] shrink-0 flex items-center gap-[5px]">
          <i class="fa-solid fa-pen-nib text-[12px]"></i>矢量
        </span>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <!-- 路径 -->
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">路径</span>
          <div v-for="(item, i) in vectorPathModes" :key="'vpm'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100" :class="item.active ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : 'border-[var(--color-border)]'" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', item.active ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]']"></i></div>
        </div>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <!-- 编辑 -->
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">编辑</span>
          <div v-for="(item, i) in vectorEditTools.slice(0,4)" :key="'ve'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
        </div>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <!-- 形状 -->
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">形状</span>
          <div v-for="(item, i) in shapePresets.slice(0,8)" :key="'sp'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
        </div>
        <div class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)] relative ml-auto" :class="vectorMoreOpen ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : ''" @click.stop="onVectorMoreClick" title="更多矢量工具"><i class="fa-solid fa-ellipsis text-[12px] text-[var(--color-secondary)]"></i></div>
      <Teleport to="body">
        <div v-if="vectorMoreOpen" class="fixed z-[300] min-w-[240px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px] shadow-lg py-[4px]" :style="{ left: vectorMorePos.x + 'px', top: vectorMorePos.y + 'px' }" @click.stop @mouseleave="vectorMoreOpen = false">
          <div class="px-[8px] py-[4px] bg-[var(--color-panel)] text-[10px] font-[600] text-[var(--color-primary-dark-700)]">矢量 · 扩展工具</div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap mt-[2px]">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">查找器</span>
            <div v-for="(item, i) in vectorPathfinder" :key="'vpf'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">编辑+</span>
            <div v-for="(item, i) in vectorEditTools.slice(4)" :key="'ve2'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] ml-[4px]">变换+</span>
            <div v-for="(item, i) in vectorTransform.slice(4)" :key="'vt2'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">变形</span>
            <div v-for="(item, i) in vectorWarp" :key="'vw'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] ml-[4px]">轮廓</span>
            <div v-for="(item, i) in vectorOutline" :key="'vo'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">生成</span>
            <div v-for="(item, i) in vectorShapeBuilder" :key="'vsb'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] ml-[4px]">混合</span>
            <div v-for="(item, i) in vectorBlend.slice(0,2)" :key="'vb'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">描边+</span>
            <div v-for="(item, i) in strokeStyles.slice(3)" :key="'ss2'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] ml-[4px]">角+</span>
            <div v-for="(item, i) in vectorCorners.slice(4)" :key="'vc2'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[2px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)] w-[36px]">形状+</span>
            <div v-for="(item, i) in shapePresets.slice(8)" :key="'sp2'+i" class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[3px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-panel)] border border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[10px]', 'text-[var(--color-secondary)]']"></i></div>
          </div>
          <div class="h-[1px] bg-[var(--color-border)] mx-[8px] my-[3px]"></div>
          <div class="flex flex-row items-center gap-[4px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)]">多边形</span>
            <div class="flex flex-row items-center gap-[2px]">
              <div class="flex flex-row justify-center items-center w-[18px] h-[18px] rounded-[2px] cursor-pointer bg-[var(--color-panel)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="polygonSides = Math.max(3, polygonSides - 1)"><i class="fa-solid fa-minus text-[6px] text-[var(--color-secondary)]"></i></div>
              <div class="flex flex-row justify-center items-center w-[32px] h-[18px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[2px] text-[10px] leading-[10px] font-[600] text-[var(--color-body)] font-mono cursor-pointer" @click="showPolygonInput = true" title="点击输入边数">{{ polygonSides }}</div>
              <div class="flex flex-row justify-center items-center w-[18px] h-[18px] rounded-[2px] cursor-pointer bg-[var(--color-panel)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="polygonSides = Math.min(60, polygonSides + 1)"><i class="fa-solid fa-plus text-[6px] text-[var(--color-secondary)]"></i></div>
              <span class="text-[9px] leading-[9px] font-[400] text-[var(--color-muted)]">边</span>
            </div>
            <div class="flex flex-row justify-center items-center w-[22px] h-[22px] rounded-[2px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-primary)] border border-[var(--color-primary)]" title="应用多边形"><i class="fa-solid fa-check text-[10px] text-[var(--color-white)]"></i></div>
          </div>
          <div class="flex flex-row items-center gap-[4px] px-[8px] py-[3px] flex-wrap">
            <span class="text-[10px] leading-[10px] font-[600] text-[var(--color-muted)]">星形</span>
            <div class="flex flex-row items-center gap-[2px]">
              <span class="text-[9px] leading-[9px] font-[400] text-[var(--color-muted)]">角</span>
              <div class="flex flex-row justify-center items-center w-[18px] h-[18px] rounded-[2px] cursor-pointer bg-[var(--color-panel)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="starPoints = Math.max(3, starPoints - 1)"><i class="fa-solid fa-minus text-[6px] text-[var(--color-secondary)]"></i></div>
              <div class="flex flex-row justify-center items-center w-[32px] h-[18px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[2px] text-[10px] leading-[10px] font-[600] text-[var(--color-body)] font-mono">{{ starPoints }}</div>
              <div class="flex flex-row justify-center items-center w-[18px] h-[18px] rounded-[2px] cursor-pointer bg-[var(--color-panel)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="starPoints = Math.min(60, starPoints + 1)"><i class="fa-solid fa-plus text-[6px] text-[var(--color-secondary)]"></i></div>
              <span class="text-[9px] leading-[9px] font-[400] text-[var(--color-muted)]">尖</span>
            </div>
            <div class="flex flex-row items-center gap-[2px]">
              <span class="text-[9px] leading-[9px] font-[400] text-[var(--color-muted)]">半径</span>
              <input type="range" class="w-[60px] h-[3px] accent-[var(--color-primary)]" min="10" max="100" v-model.number="starRadius" />
              <span class="text-[9px] leading-[9px] font-[500] text-[var(--color-body)] w-[24px] text-right">{{ starRadius }}%</span>
            </div>
            <div class="flex flex-row justify-center items-center w-[22px] h-[22px] rounded-[2px] cursor-pointer hover:bg-[var(--color-border-light)] bg-[var(--color-primary)] border border-[var(--color-primary)]" title="应用星形"><i class="fa-solid fa-check text-[10px] text-[var(--color-white)]"></i></div>
          </div>
        </div>
      </Teleport>
      </div>
      <!-- 形状属性 (仅选中/创建形状时显示) -->
      <div v-if="showShapeProps" class="w-full border-t border-[var(--color-border-light)] mt-[4px] pt-[6px] flex flex-row flex-wrap items-center gap-x-[8px] gap-y-[4px] px-[12px] py-[8px]">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-primary-dark-700)] flex items-center gap-[4px]"><i class="fa-solid fa-shapes text-[11px]"></i>形状</span>
        <div class="w-[1px] h-[14px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">宽</span>
          <input type="number" value="420" class="w-[40px] h-[22px] px-[4px] text-[11px] leading-[14px] font-[500] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" />
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">高</span>
          <input type="number" value="600" class="w-[40px] h-[22px] px-[4px] text-[11px] leading-[14px] font-[500] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="1" />
        </div>
        <div class="w-[1px] h-[14px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">圆角</span>
          <input type="number" value="0" class="w-[32px] h-[22px] px-[4px] text-[11px] leading-[14px] font-[500] border border-[var(--color-border)] rounded-[4px] outline-none focus:border-[var(--color-primary)] bg-[var(--color-white)] text-[var(--color-body)]" min="0" />
          <span class="text-[10px] leading-[12px] font-[400] text-[var(--color-muted)]">px</span>
        </div>
        <div class="w-[1px] h-[14px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">边</span>
          <div class="flex flex-row justify-center items-center w-[18px] h-[22px] rounded-[4px] cursor-pointer bg-[var(--color-white)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="shapePolygonSides = Math.max(3, shapePolygonSides - 1)"><i class="fa-solid fa-minus text-[8px] text-[var(--color-secondary)]"></i></div>
          <div class="flex flex-row justify-center items-center w-[28px] h-[22px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] text-[11px] leading-[14px] font-[600] text-[var(--color-body)] font-mono">{{ shapePolygonSides }}</div>
          <div class="flex flex-row justify-center items-center w-[18px] h-[22px] rounded-[4px] cursor-pointer bg-[var(--color-white)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="shapePolygonSides = Math.min(60, shapePolygonSides + 1)"><i class="fa-solid fa-plus text-[8px] text-[var(--color-secondary)]"></i></div>
        </div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-muted)]">星</span>
          <div class="flex flex-row justify-center items-center w-[18px] h-[22px] rounded-[4px] cursor-pointer bg-[var(--color-white)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="shapeStarPoints = Math.max(3, shapeStarPoints - 1)"><i class="fa-solid fa-minus text-[8px] text-[var(--color-secondary)]"></i></div>
          <div class="flex flex-row justify-center items-center w-[28px] h-[22px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] text-[11px] leading-[14px] font-[600] text-[var(--color-body)] font-mono">{{ shapeStarPoints }}</div>
          <div class="flex flex-row justify-center items-center w-[18px] h-[22px] rounded-[4px] cursor-pointer bg-[var(--color-white)] border border-[var(--color-border)] hover:bg-[var(--color-border-light)]" @click="shapeStarPoints = Math.min(60, shapeStarPoints + 1)"><i class="fa-solid fa-plus text-[8px] text-[var(--color-secondary)]"></i></div>
        </div>
        <div class="w-[1px] h-[14px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <div class="w-[18px] h-[18px] rounded-[4px] cursor-pointer border border-[var(--color-border)]" style="background-color:var(--color-primary)" title="填充色"></div>
          <div class="w-[18px] h-[18px] rounded-[4px] cursor-pointer border border-[var(--color-border)]" style="background-color:var(--color-title)" title="描边色"></div>
          <div class="flex flex-row justify-between items-center w-[36px] h-[22px] px-[6px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[4px] cursor-pointer text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">1 <i class="fa-solid fa-chevron-down text-[8px] text-[var(--color-muted)]"></i></div>
        </div>
        <div class="flex flex-row justify-center items-center h-[24px] px-[10px] rounded-[4px] cursor-pointer bg-[var(--color-primary-dark-700)] text-[11px] font-[600] text-[var(--color-white)] hover:bg-[var(--color-primary-dark-900)] gap-[4px]">
          <i class="fa-solid fa-check text-[9px]"></i>
          <span>创建</span>
        </div>
      </div>
    </div>
    <div v-show="toolGroups[5].expanded" class="flex flex-row flex-wrap items-center gap-x-[10px] gap-y-[6px] px-[12px] py-[8px] border-t border-[var(--color-border-light)] bg-[var(--color-panel)]">
      <span class="text-[12px] leading-[15px] font-[700] text-[var(--color-secondary)] mr-[2px] shrink-0 flex items-center gap-[5px]"><i class="fa-solid fa-image text-[12px]"></i>图片</span>
      <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
      <div class="flex flex-row items-center gap-[4px] flex-wrap">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">描摹</span>
        <div v-for="(item, i) in vectorImageTrace" :key="'vit'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100" :class="item.highlighted ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : 'border-[var(--color-border)]'" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', item.highlighted ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]']"></i></div>
      </div>
      <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
      <div class="flex flex-row items-center gap-[4px]">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">滤镜</span>
        <div v-for="(item, i) in imageFilters.slice(0,6)" :key="'flt'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
      </div>
      <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
      <div class="flex flex-row items-center gap-[4px]">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">调整</span>
        <div v-for="(item, i) in imageAdjustments.slice(0,6)" :key="'adj'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
      </div>
      <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
      <div class="flex flex-row items-center gap-[4px]">
        <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">效果</span>
        <div v-for="(item, i) in imageEffects.slice(0,4)" :key="'eff'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
      </div>
      <div class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)] ml-auto" title="更多图片工具"><i class="fa-solid fa-ellipsis text-[12px] text-[var(--color-secondary)]"></i></div>
    </div>

    <!-- Row 5: 色彩工具 - 双行 -->
    <div v-show="toolGroups[6].expanded" class="flex flex-col border-t border-[var(--color-border-light)] bg-[var(--color-panel)]">
      <!-- Row 5a: 工具 -->
      <div class="flex flex-row flex-wrap items-center gap-x-[10px] gap-y-[6px] px-[12px] py-[8px]">
        <span class="text-[12px] leading-[15px] font-[700] text-[var(--color-secondary)] mr-[2px] shrink-0 flex items-center gap-[5px]"><i class="fa-solid fa-palette text-[12px]"></i>色彩</span>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">取色</span>
          <div v-for="(item, i) in colorPickTools" :key="'cp'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
        </div>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">调整</span>
          <div v-for="(item, i) in colorAdjustTools.slice(0,7)" :key="'ca'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100 border-[var(--color-border)]" :title="item.label"><i :class="['fa-solid', item.icon, 'text-[12px]', 'text-[var(--color-secondary)]']"></i></div>
        </div>
        <div class="w-[1px] h-[18px] bg-[var(--color-border)]"></div>
        <div class="flex flex-row items-center gap-[4px]">
          <span class="text-[11px] leading-[14px] font-[600] text-[var(--color-tertiary)] mr-[4px]">模式</span>
          <div v-for="(item, i) in colorModeTools" :key="'cm'+i" class="flex flex-row justify-center items-center w-[30px] h-[30px] rounded-[6px] cursor-pointer hover:bg-[var(--color-hover-bg)] bg-[var(--color-white)] border transition-all duration-100" :class="item.active ? 'border-[var(--color-primary)] bg-[var(--color-hover-bg)]' : 'border-[var(--color-border)]'" :title="item.label"><span class="text-[12px] leading-[15px] font-[700]" :class="item.active ? 'text-[var(--color-primary-dark-700)]' : 'text-[var(--color-secondary)]'">{{ item.label }}</span></div>
        </div>
      </div>
    </div>

    <!-- Collapse separator -->
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, onUnmounted } from 'vue'
import { useToastStore } from '../stores/toast'

defineEmits<{
  (e: 'home'): void
}>()

const props = withDefaults(defineProps<{
  showShapeProps?: boolean
}>(), {
  showShapeProps: false,
})

const toastStore = useToastStore()

const toolGroups = ref([
  { id: 'group', label: '编组', icon: 'fa-object-group', expanded: false },
  { id: 'arrange', label: '排列', icon: 'fa-arrow-up', expanded: false },
  { id: 'align', label: '对齐', icon: 'fa-align-left', expanded: false },
  { id: 'dist', label: '分布', icon: 'fa-arrows-left-right', expanded: false },
  { id: 'vector', label: '矢量', icon: 'fa-pen-nib', expanded: false },
  { id: 'image', label: '图片', icon: 'fa-image', expanded: false },
  { id: 'color', label: '色彩', icon: 'fa-palette', expanded: false },
])

const collapsed = ref(false)

const anyExpanded = computed(() => toolGroups.value.some(g => g.expanded))
const layoutExpanded = computed(() => toolGroups.value.slice(0, 4).some(g => g.expanded))

// 对齐目标
const alignTarget = ref<'selection' | 'artboard' | 'key'>('selection')

// 布局工具组（编组/排列/对齐/分布，统一通过 layoutGroups 渲染）
const layoutGroups = computed(() => [
  { id: 'group', label: '编组', items: groupTools },
  { id: 'arrange', label: '排列', items: arrangeTools },
  { id: 'align', label: '对齐', items: alignTools },
  { id: 'dist', label: '分布', items: distTools },
])

// 工具点击反馈（保持原型行为，但带语义化反馈）
const onToolClick = (groupId: string, item: { icon?: string; label: string; active?: boolean }) => {
  // 对齐/分布类工具支持 active 互斥切换
  if (groupId === 'align' || groupId === 'dist') {
    const group = groupId === 'align' ? alignTools : distTools
    group.forEach(t => { t.active = false })
    item.active = true
  }
  toastStore.show(item.label, item.icon, 'success')
}

// Vector tools "more" popup state
const vectorMoreOpen = ref(false)
const vectorMorePos = ref({ x: 0, y: 0 })
const polygonSides = ref(6)
const showPolygonInput = ref(false)
const starPoints = ref(5)
const starRadius = ref(50)

// 形状属性（独立于矢量弹出菜单）
const shapePolygonSides = ref(6)
const shapeStarPoints = ref(5)
const shapeStarRadius = ref(50)

const onVectorMoreClick = (e: MouseEvent) => {
  vectorMoreOpen.value = !vectorMoreOpen.value
  if (vectorMoreOpen.value) {
    const el = e.currentTarget as HTMLElement
    const rect = el.getBoundingClientRect()
    vectorMorePos.value = { x: rect.left, y: rect.bottom + 4 }
  }
}

const onGlobalClick = () => { vectorMoreOpen.value = false }

// ─── Keyboard shortcut handler ───
// Alignment: L=左 R=右 T=顶 B=底 C=水平居中 M=垂直居中
// Distribution: Shift+L/R/T/B/C/M/E
// Arrange: Ctrl+]/[  Ctrl+Shift+]/[
// Group: Ctrl+G  Ungroup: Ctrl+Shift+G
const alignKeys: Record<string, number> = { l: 0, c: 1, r: 2, t: 3, m: 4, b: 5 }
const distKeys: Record<string, number> = { l: 0, c: 1, r: 2, e: 3, t: 4, m: 5, b: 6 }

const onGlobalKeyDown = (e: KeyboardEvent) => {
  const tag = (e.target as HTMLElement)?.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return

  const key = e.key.toLowerCase()

  // Single-letter alignment (no modifiers)
  if (!e.ctrlKey && !e.altKey && !e.metaKey && !e.shiftKey) {
    if (key in alignKeys) {
      e.preventDefault()
      return
    }
  }

  // Shift+letter distribution
  if (e.shiftKey && !e.ctrlKey && !e.altKey && !e.metaKey) {
    if (key in distKeys) {
      e.preventDefault()
      return
    }
  }
}

onMounted(() => {
  document.addEventListener('click', onGlobalClick)
  document.addEventListener('keydown', onGlobalKeyDown)
})

onUnmounted(() => {
  document.removeEventListener('click', onGlobalClick)
  document.removeEventListener('keydown', onGlobalKeyDown)
})

// ─── Tool data ───
const groupTools = reactive([
  { icon: 'fa-object-group', label: '编组', shortcut: 'Ctrl+G', active: false },
  { icon: 'fa-object-ungroup', label: '解组', shortcut: 'Ctrl+Shift+G', active: false },
  { icon: 'fa-lock', label: '锁定所选', shortcut: 'Ctrl+L', active: false },
  { icon: 'fa-lock-open', label: '解锁全部', shortcut: 'Ctrl+Shift+L', active: false },
  { icon: 'fa-eye-slash', label: '隐藏所选', shortcut: 'Ctrl+3', active: false },
])

const arrangeTools = reactive([
  { icon: 'fa-chevron-up', label: '上移一层', shortcut: 'Ctrl+]', active: false },
  { icon: 'fa-chevron-down', label: '下移一层', shortcut: 'Ctrl+[', active: false },
  { icon: 'fa-arrow-up', label: '移到顶层', shortcut: 'Ctrl+Shift+]', active: false },
  { icon: 'fa-arrow-down', label: '移到底层', shortcut: 'Ctrl+Shift+[', active: false },
])

const alignTools = reactive([
  { icon: 'fa-align-left', label: '左对齐', shortcut: 'L', active: true },
  { icon: 'fa-align-center', label: '水平居中', shortcut: 'C', active: false },
  { icon: 'fa-align-right', label: '右对齐', shortcut: 'R', active: false },
  { icon: 'fa-arrow-up', label: '顶对齐', shortcut: 'T', active: false },
  { icon: 'fa-arrows-up-down', label: '垂直居中', shortcut: 'M', active: false },
  { icon: 'fa-arrow-down', label: '底对齐', shortcut: 'B', active: false },
])

const distTools = reactive([
  { icon: 'fa-arrows-left-right', label: '水平左分布', shortcut: 'Shift+L', active: false },
  { icon: 'fa-arrows-left-right', label: '水平居中分布', shortcut: 'Shift+C', active: true },
  { icon: 'fa-arrows-left-right', label: '水平右分布', shortcut: 'Shift+R', active: false },
  { icon: 'fa-arrow-left-long', label: '水平间距分布', shortcut: 'Shift+E', active: false },
  { icon: 'fa-arrow-up-long', label: '垂直顶分布', shortcut: 'Shift+T', active: false },
  { icon: 'fa-arrow-up-long', label: '垂直居中分布', shortcut: 'Shift+M', active: false },
  { icon: 'fa-arrow-up-long', label: '垂直底分布', shortcut: 'Shift+B', active: false },
])

// ─── Vector Tools ───
const vectorPathModes = [
  { icon: 'fa-object-group', label: '合集', active: true },
  { icon: 'fa-object-ungroup', label: '差集', active: false },
  { icon: 'fa-vector-square', label: '交集', active: false },
  { icon: 'fa-square', label: '排除', active: false },
]

const vectorEditTools = [
  { icon: 'fa-bezier-curve', label: '平滑路径' },
  { icon: 'fa-compress', label: '简化路径' },
  { icon: 'fa-arrow-right-arrow-left', label: '偏移路径' },
  { icon: 'fa-link', label: '连接路径' },
  { icon: 'fa-scissors', label: '修剪路径' },
  { icon: 'fa-arrows-up-down-left-right', label: '分割路径' },
  { icon: 'fa-code-merge', label: '合并路径' },
  { icon: 'fa-crop', label: '裁剪路径' },
]

const vectorPathfinder = [
  { icon: 'fa-divide', label: '分割' },
  { icon: 'fa-scissors', label: '修边' },
  { icon: 'fa-code-merge', label: '合并' },
  { icon: 'fa-crop', label: '裁剪' },
  { icon: 'fa-indent', label: '轮廓' },
  { icon: 'fa-circle-minus', label: '减去后方' },
  { icon: 'fa-circle-plus', label: '加上前方' },
]

const vectorTransform = [
  { icon: 'fa-rotate', label: '旋转' },
  { icon: 'fa-expand', label: '缩放' },
  { icon: 'fa-arrow-right-arrow-left', label: '镜像' },
  { icon: 'fa-sliders', label: '倾斜' },
  { icon: 'fa-up-right-and-down-left-from-center', label: '自由变换' },
  { icon: 'fa-cube', label: '透视变换' },
]

const vectorWarp = [
  { icon: 'fa-hand', label: '变形工具' },
  { icon: 'fa-rotate', label: '扭转' },
  { icon: 'fa-compress', label: '收缩' },
  { icon: 'fa-expand', label: '膨胀' },
  { icon: 'fa-wind', label: '扇贝' },
  { icon: 'fa-gem', label: '晶化' },
  { icon: 'fa-wind', label: '褶皱' },
]

const vectorOutline = [
  { icon: 'fa-arrow-right-arrow-left', label: '宽度工具' },
  { icon: 'fa-vector-square', label: '轮廓化描边' },
  { icon: 'fa-arrows-up-down', label: '位移路径' },
  { icon: 'fa-pen', label: '书法画笔' },
]

const vectorShapeBuilder = [
  { icon: 'fa-paintbrush', label: '形状生成器' },
  { icon: 'fa-fill-drip', label: '实时上色' },
  { icon: 'fa-fill-drip', label: '实时上色选择' },
  { icon: 'fa-mouse-pointer', label: '形状构建' },
]

const vectorBlend = [
  { icon: 'fa-object-ungroup', label: '混合形状' },
  { icon: 'fa-palette', label: '混合颜色' },
  { icon: 'fa-arrow-right-to-bracket', label: '混合步骤' },
  { icon: 'fa-expand', label: '释放混合' },
]

const vectorImageTrace = [
  { icon: 'fa-wand-magic-sparkles', label: '图像描摹', highlighted: true },
  { icon: 'fa-bolt', label: '快速描摹' },
  { icon: 'fa-pen-nib', label: '轮廓描摹' },
  { icon: 'fa-circle', label: '黑白徽标' },
  { icon: 'fa-pencil', label: '素描图稿' },
  { icon: 'fa-gear', label: '技术图纸' },
  { icon: 'fa-image', label: '高保真照片' },
  { icon: 'fa-bezier-curve', label: '线条稿' },
  { icon: 'fa-palette', label: '彩色图稿' },
  { icon: 'fa-sliders', label: '描摹预设...' },
]

const vectorCorners = [
  { icon: 'fa-circle', label: '圆角连接' },
  { icon: 'fa-square', label: '斜角连接' },
  { icon: 'fa-grip-lines', label: '平角连接' },
  { icon: 'fa-grip-lines-vertical', label: '倒角' },
  { icon: 'fa-chevron-down', label: '反向圆角' },
  { icon: 'fa-cut', label: '切角' },
]

const strokeStyles = [
  { icon: 'fa-minus', label: '实线' },
  { icon: 'fa-grip-lines', label: '虚线' },
  { icon: 'fa-grip-lines-vertical', label: '点线' },
  { icon: 'fa-ellipsis', label: '圆点线' },
  { icon: 'fa-grip-lines', label: '双线', iconExtra: 'fa-rotate-90' },
  { icon: 'fa-grip', label: '装饰线' },
]

const shapePresets = [
  { icon: 'fa-square', label: '矩形' },
  { icon: 'fa-square', label: '圆角矩形' },
  { icon: 'fa-circle', label: '椭圆' },
  { icon: 'fa-hexagon', label: '六边形' },
  { icon: 'fa-play', label: '三角形' },
  { icon: 'fa-stop', label: '八边形' },
  { icon: 'fa-gem', label: '菱形' },
  { icon: 'fa-star', label: '星形' },
  { icon: 'fa-circle-notch', label: '螺旋线' },
  { icon: 'fa-arrow-right', label: '箭头' },
  { icon: 'fa-bolt', label: '闪电' },
  { icon: 'fa-heart', label: '心形' },
  { icon: 'fa-comment', label: '对话气泡' },
  { icon: 'fa-ribbon', label: '丝带' },
  { icon: 'fa-crown', label: '皇冠' },
  { icon: 'fa-cloud', label: '云朵' },
  { icon: 'fa-droplet', label: '水滴' },
  { icon: 'fa-fire', label: '火焰' },
  { icon: 'fa-sun', label: '太阳' },
  { icon: 'fa-moon', label: '月亮' },
  { icon: 'fa-snowflake', label: '雪花' },
  { icon: 'fa-leaf', label: '叶子' },
  { icon: 'fa-hand', label: '手掌' },
  { icon: 'fa-flag', label: '旗帜' },
  { icon: 'fa-location-dot', label: '图钉' },
  { icon: 'fa-tag', label: '价格标签' },
  { icon: 'fa-gift', label: '礼物' },
  { icon: 'fa-trophy', label: '奖杯' },
  { icon: 'fa-medal', label: '勋章' },
]

// ─── Image Tools ───
const imageFilters = [
  { icon: 'fa-droplet', label: '高斯模糊' },
  { icon: 'fa-wind', label: '动感模糊' },
  { icon: 'fa-circle', label: '径向模糊' },
  { icon: 'fa-bolt', label: 'USM 锐化' },
  { icon: 'fa-brain', label: '智能锐化' },
  { icon: 'fa-border-all', label: '像素化' },
  { icon: 'fa-wave-square', label: '波浪' },
  { icon: 'fa-water', label: '波纹' },
]

const imageAdjustments = [
  { icon: 'fa-sliders', label: '色阶' },
  { icon: 'fa-chart-line', label: '曲线' },
  { icon: 'fa-palette', label: '色相/饱和度' },
  { icon: 'fa-sun', label: '亮度/对比度' },
  { icon: 'fa-balance-scale', label: '色彩平衡' },
  { icon: 'fa-circle-half-stroke', label: '黑白' },
  { icon: 'fa-rotate', label: '反相' },
  { icon: 'fa-border-all', label: '阈值' },
]

const imageEffects = [
  { icon: 'fa-wand-magic-sparkles', label: '风格迁移' },
  { icon: 'fa-cube', label: '3D 效果' },
  { icon: 'fa-gem', label: '宝石效果' },
  { icon: 'fa-fire', label: '火焰效果' },
]

// ─── Color Tools ───
const colorPickTools = [
  { icon: 'fa-eye-dropper', label: '吸管' },
  { icon: 'fa-palette', label: '颜色拾取器' },
  { icon: 'fa-swatchbook', label: '色板浏览器' },
  { icon: 'fa-circle', label: '屏幕取色' },
]

const colorAdjustTools = [
  { icon: 'fa-adjust', label: '可选颜色' },
  { icon: 'fa-tint', label: '通道混合器' },
  { icon: 'fa-fill-drip', label: '渐变映射' },
  { icon: 'fa-sliders', label: '替换颜色' },
  { icon: 'fa-palette', label: '颜色查找' },
  { icon: 'fa-circle-half-stroke', label: '色调分离' },
  { icon: 'fa-equals', label: '色调均化' },
]

const colorModeTools = [
  { label: 'RGB', active: true },
  { label: 'CMYK', active: false },
  { label: 'HSL', active: false },
  { label: 'LAB', active: false },
]

</script>