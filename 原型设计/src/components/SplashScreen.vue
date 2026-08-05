<template>
  <div class="min-h-screen w-full flex flex-col bg-[var(--color-bg)] relative overflow-hidden">
    <!-- 顶部装饰渐变（极淡） -->
    <div class="absolute top-0 left-0 right-0 h-[280px] pointer-events-none opacity-[0.55]" style="background: radial-gradient(ellipse 60% 100% at 50% 0%, rgba(58,196,135,0.10) 0%, rgba(58,196,135,0) 70%);"></div>

    <!-- 顶部：极简品牌栏 -->
    <header class="relative flex flex-row justify-between items-center h-[52px] px-[24px] shrink-0 z-[1]">
      <div class="flex flex-row items-center gap-[10px]">
        <div class="flex flex-row justify-center items-center w-[26px] h-[26px] rounded-[7px] bg-gradient-to-br from-[var(--color-primary)] to-[#2AA36F] shadow-[0_3px_10px_rgba(58,196,135,0.32)]">
          <i class="fa-solid fa-bezier-curve text-[11px] text-white"></i>
        </div>
        <span class="text-[12px] font-[700] text-[var(--color-title)] tracking-[-0.01em]">Harmony Design Studio</span>
        <span class="text-[9px] font-[500] text-[var(--color-muted)] ml-[6px] px-[6px] py-[1px] rounded-[3px] border border-[var(--color-border-light)] bg-[var(--color-white)]">v0.1.0</span>
      </div>
      <div class="flex flex-row items-center gap-[2px]">
        <div class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[6px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors duration-100" title="设置">
          <i class="fa-solid fa-gear text-[11px] text-[var(--color-secondary)]"></i>
        </div>
        <div class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[6px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors duration-100" :title="isDark ? '切换亮色' : '切换暗色'" @click="toggleTheme">
          <i class="fa-solid text-[11px] text-[var(--color-secondary)]" :class="isDark ? 'fa-sun' : 'fa-moon'"></i>
        </div>
      </div>
    </header>

    <!-- 主区：居中容器 -->
    <main class="relative flex-1 min-h-0 flex flex-col items-center overflow-y-auto z-[1]">
      <div class="w-full max-w-[1080px] px-[32px] pt-[40px] pb-[40px] flex flex-col items-center">

        <!-- Hero：问候 + 副标题 -->
        <div class="flex flex-col items-center text-center mb-[36px] select-none">
          <div class="flex flex-row items-center gap-[8px] mb-[14px]">
            <span class="w-[6px] h-[6px] rounded-full bg-[var(--color-primary)] shadow-[0_0_0_3px_rgba(58,196,135,0.16)]"></span>
            <span class="text-[10px] font-[600] uppercase tracking-[0.18em] text-[var(--color-primary-dark-700)]">Welcome</span>
          </div>
          <h1 class="text-[28px] font-[700] leading-[34px] text-[var(--color-title)] tracking-[-0.02em]">开启你的下一个设计</h1>
          <p class="text-[12px] font-[400] text-[var(--color-muted)] mt-[8px]">选择预设快速开始，或从最近文件继续创作</p>
        </div>

        <!-- Tabs：新建 | 最近 | 模板 -->
        <div class="flex flex-row items-center gap-[2px] p-[3px] bg-[var(--color-white)] border border-[var(--color-border-light)] rounded-[8px] shadow-[0_1px_2px_rgba(15,23,42,0.04)] mb-[24px]">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            type="button"
            class="flex flex-row items-center gap-[6px] px-[14px] h-[28px] rounded-[6px] text-[11px] font-[600] transition-all duration-150 cursor-pointer"
            :class="activeTab === tab.id
              ? 'bg-[var(--color-primary)] text-white shadow-[0_2px_6px_rgba(58,196,135,0.28)]'
              : 'text-[var(--color-secondary)] hover:text-[var(--color-body)] hover:bg-[var(--color-panel)]'"
            @click="activeTab = tab.id"
          >
            <i :class="['fa-solid', tab.icon, 'text-[10px]']"></i>
            <span>{{ tab.label }}</span>
          </button>
        </div>

        <!-- ============ 新建 Tab ============ -->
        <div v-if="activeTab === 'new'" class="w-full flex flex-col items-center">
          <!-- 4 种 Frame 模式预设（单页/海报/书页/对页） -->
          <div class="w-full mb-[24px]">
            <div class="flex flex-row items-center justify-between mb-[12px]">
              <span class="text-[11px] font-[700] uppercase tracking-[0.1em] text-[var(--color-muted)]">选择画板模式</span>
              <span class="text-[9px] text-[var(--color-muted)]">将创建一个初始 Frame</span>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-[12px] w-full">
              <button
                v-for="mode in frameModes"
                :key="mode.type"
                type="button"
                class="group flex flex-col bg-[var(--color-white)] border rounded-[10px] p-[14px] text-left transition-all duration-150 hover:-translate-y-[2px] hover:shadow-[0_8px_20px_rgba(15,23,42,0.06)]"
                :class="selectedFrameType === mode.type
                  ? 'border-[var(--color-primary)] shadow-[inset_0_0_0_1px_var(--color-primary-light-300),0_4px_12px_rgba(58,196,135,0.10)]'
                  : 'border-[var(--color-border-light)] hover:border-[var(--color-primary-light-300)]'"
                @click="selectedFrameType = mode.type"
              >
                <div class="flex flex-row items-center justify-center h-[80px] mb-[10px] bg-[var(--color-panel)] rounded-[6px] border border-[var(--color-border-light)] relative overflow-hidden">
                  <!-- 不同模式的缩略图 -->
                  <div v-if="mode.type === 'single'" class="bg-[var(--color-white)] border border-[var(--color-border)] shadow-[0_1px_3px_rgba(15,23,42,0.04)]" :style="{ width: '36px', height: '50px' }"></div>
                  <div v-else-if="mode.type === 'poster'" class="bg-[var(--color-white)] border border-[var(--color-border)] shadow-[0_1px_3px_rgba(15,23,42,0.04)]" :style="{ width: '44px', height: '56px' }">
                    <div class="w-full h-full p-[3px] flex flex-col gap-[2px]">
                      <div class="h-[8px] bg-[var(--color-primary-light-300)] rounded-[1px]"></div>
                      <div class="h-[4px] bg-[var(--color-border)] rounded-[1px]"></div>
                      <div class="flex-1 bg-[var(--color-panel)] rounded-[1px]"></div>
                    </div>
                  </div>
                  <div v-else-if="mode.type === 'book-page'" class="bg-[var(--color-white)] border border-[var(--color-border)] shadow-[0_1px_3px_rgba(15,23,42,0.04)]" :style="{ width: '36px', height: '50px' }">
                    <div class="w-[2px] h-full bg-[var(--color-border-light)] absolute left-1/2 -translate-x-1/2"></div>
                  </div>
                  <div v-else-if="mode.type === 'spread'" class="flex flex-row gap-[2px]">
                    <div class="bg-[var(--color-white)] border border-[var(--color-border)] shadow-[0_1px_3px_rgba(15,23,42,0.04)]" :style="{ width: '24px', height: '34px' }"></div>
                    <div class="bg-[var(--color-white)] border border-[var(--color-border)] shadow-[0_1px_3px_rgba(15,23,42,0.04)]" :style="{ width: '24px', height: '34px' }"></div>
                  </div>
                  <span class="absolute top-[4px] right-[5px] text-[7px] font-[600] text-[var(--color-muted)] bg-[var(--color-white)]/70 px-[3px] py-[0.5px] rounded-[2px]">{{ mode.orient }}</span>
                </div>
                <div class="flex flex-row items-center justify-between">
                  <span class="text-[12px] font-[600] text-[var(--color-title)]">{{ mode.name }}</span>
                  <i v-if="selectedFrameType === mode.type" class="fa-solid fa-check text-[9px] text-[var(--color-primary)]"></i>
                </div>
                <span class="text-[10px] text-[var(--color-muted)] mt-[1px]">{{ mode.desc }}</span>
              </button>
            </div>
          </div>

          <!-- 自定义尺寸触发器（弹出层，不在主流程暴露表单） -->
          <button
            type="button"
            class="mt-[4px] flex flex-row items-center gap-[8px] px-[14px] h-[32px] rounded-[7px] bg-[var(--color-white)] border border-[var(--color-border-light)] text-[11px] font-[600] text-[var(--color-secondary)] hover:text-[var(--color-body)] hover:border-[var(--color-primary-light-300)] hover:bg-[var(--color-panel)] transition-all duration-150"
            @click="showCustomModal = true"
          >
            <i class="fa-solid fa-sliders text-[10px]"></i>
            <span>自定义尺寸 · {{ customW }} × {{ customH }} {{ customUnit }}</span>
            <i class="fa-solid fa-chevron-right text-[7px] text-[var(--color-muted)] ml-[2px]"></i>
          </button>

          <!-- 创建按钮 -->
          <button
            type="button"
            class="mt-[28px] flex flex-row items-center justify-center gap-[8px] h-[44px] px-[28px] rounded-[10px] bg-[var(--color-primary)] text-[13px] font-[700] text-white shadow-[0_6px_18px_rgba(58,196,135,0.32)] hover:bg-[#32B77C] hover:shadow-[0_8px_24px_rgba(58,196,135,0.40)] transition-all duration-150 hover:-translate-y-[1px]"
            @click="onCreateDocument"
          >
            <i class="fa-solid fa-plus text-[11px]"></i>
            <span>创建 {{ currentFrameModeName }} 文档</span>
            <span class="ml-[6px] text-[9px] font-[500] opacity-80 px-[6px] py-[1px] rounded-[3px] bg-white/15">Enter</span>
          </button>
        </div>

        <!-- ============ 最近 Tab ============ -->
        <div v-else-if="activeTab === 'recent'" class="w-full">
          <div class="flex flex-row items-center justify-between mb-[16px]">
            <div class="flex flex-col gap-[1px]">
              <span class="text-[12px] font-[600] text-[var(--color-body)]">{{ recentFiles.length }} 个最近文档</span>
              <span class="text-[10px] text-[var(--color-muted)]">按修改时间排序</span>
            </div>
            <div class="flex flex-row items-center gap-[2px] p-[3px] bg-[var(--color-white)] border border-[var(--color-border-light)] rounded-[6px]">
              <div class="flex flex-row justify-center items-center w-[24px] h-[24px] rounded-[4px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors" title="列表视图">
                <i class="fa-solid fa-list text-[9px] text-[var(--color-secondary)]"></i>
              </div>
              <div class="flex flex-row justify-center items-center w-[24px] h-[24px] rounded-[4px] bg-[var(--color-panel)] cursor-pointer" title="网格视图">
                <i class="fa-solid fa-table-cells-large text-[9px] text-[var(--color-primary-dark-700)]"></i>
              </div>
            </div>
          </div>
          <div class="grid grid-cols-2 md:grid-cols-3 gap-[14px]">
            <button
              v-for="file in recentFiles"
              :key="file.name"
              type="button"
              class="group flex flex-col bg-[var(--color-white)] border border-[var(--color-border-light)] rounded-[10px] overflow-hidden text-left transition-all duration-150 hover:-translate-y-[2px] hover:shadow-[0_10px_24px_rgba(15,23,42,0.08)] hover:border-[var(--color-primary-light-300)]"
              @click="$emit('enter-workspace')"
            >
              <div class="relative h-[120px] flex flex-row items-center justify-center overflow-hidden" :style="{ backgroundColor: file.bgColor }">
                <div
                  class="bg-white border border-[var(--color-border-light)] shadow-[0_2px_10px_rgba(15,23,42,0.06)]"
                  :style="{ width: file.thumbW + 'px', height: file.thumbH + 'px' }"
                >
                  <div class="w-full h-full p-[5px] flex flex-col gap-[3px]">
                    <div v-for="i in file.previewBlocks" :key="i" class="rounded-[1.5px]" :style="{ height: file.blockHeights[i-1] + 'px', backgroundColor: file.blockColors[i-1] }"></div>
                  </div>
                </div>
                <span class="absolute top-[7px] right-[8px] text-[8px] font-[600] text-[var(--color-muted)] bg-[var(--color-white)]/85 px-[5px] py-[1px] rounded-[3px] border border-[var(--color-border-light)] backdrop-blur-sm">{{ file.pages }} 页</span>
              </div>
              <div class="flex flex-col gap-[2px] px-[12px] py-[10px]">
                <div class="flex flex-row items-center justify-between gap-[6px]">
                  <span class="text-[11px] font-[600] text-[var(--color-title)] truncate">{{ file.name }}</span>
                  <i class="fa-solid fa-arrow-right text-[9px] text-[var(--color-muted)] opacity-0 group-hover:opacity-100 group-hover:text-[var(--color-primary)] transition-all duration-150 -translate-x-[4px] group-hover:translate-x-0"></i>
                </div>
                <div class="flex flex-row items-center justify-between">
                  <span class="text-[9px] text-[var(--color-muted)]">{{ file.time }}</span>
                  <span class="text-[9px] text-[var(--color-muted)]">{{ file.size }}</span>
                </div>
              </div>
            </button>
          </div>
        </div>

        <!-- ============ 模板 Tab ============ -->
        <div v-else class="w-full">
          <div class="flex flex-row items-center justify-between mb-[14px]">
            <span class="text-[12px] font-[600] text-[var(--color-body)]">按场景选择起步模板</span>
            <button type="button" class="text-[10px] font-[500] text-[var(--color-secondary)] hover:text-[var(--color-primary-dark-700)] flex flex-row items-center gap-[3px]">
              <span>浏览全部</span>
              <i class="fa-solid fa-arrow-right text-[7px]"></i>
            </button>
          </div>
          <div class="grid grid-cols-2 md:grid-cols-4 gap-[12px]">
            <button
              v-for="tpl in templates"
              :key="tpl.name"
              type="button"
              class="group flex flex-col gap-[10px] p-[16px] bg-[var(--color-white)] border border-[var(--color-border-light)] rounded-[10px] text-left transition-all duration-150 hover:-translate-y-[2px] hover:border-[var(--color-primary-light-300)] hover:shadow-[0_8px_20px_rgba(15,23,42,0.06)]"
              @click="$emit('enter-workspace')"
            >
              <div class="flex flex-row justify-center items-center w-[40px] h-[40px] rounded-[10px] shrink-0 transition-transform duration-150 group-hover:scale-[1.06]" :style="{ backgroundColor: tpl.color + '14' }">
                <i :class="['fa-solid', tpl.icon, 'text-[14px]']" :style="{ color: tpl.color }"></i>
              </div>
              <div class="flex flex-col gap-[1px]">
                <span class="text-[12px] font-[600] text-[var(--color-title)]">{{ tpl.name }}</span>
                <span class="text-[10px] text-[var(--color-muted)]">{{ tpl.count }} 套模板</span>
              </div>
            </button>
          </div>
        </div>
      </div>
    </main>

    <!-- 底部状态栏 - 极简 -->
    <footer class="relative flex flex-row justify-between items-center h-[26px] px-[24px] text-[9px] text-[var(--color-muted)] shrink-0 z-[1]">
      <div class="flex flex-row items-center gap-[8px]">
        <span class="flex flex-row items-center gap-[4px]">
          <span class="w-[5px] h-[5px] rounded-full bg-[var(--color-primary)] shadow-[0_0_0_2px_rgba(58,196,135,0.18)]"></span>
          <span>就绪</span>
        </span>
        <span class="text-[var(--color-border)]">·</span>
        <span>BYOK 未配置</span>
      </div>
      <div class="flex flex-row items-center gap-[8px]">
        <span>HarmonyOS / OpenHarmony 通用</span>
        <span class="text-[var(--color-border)]">·</span>
        <span>Skia 引擎待初始化</span>
      </div>
    </footer>

    <!-- 自定义尺寸弹窗 -->
    <Teleport to="body">
      <div v-if="showCustomModal" class="fixed inset-0 z-[200] flex flex-row items-center justify-center" @click.self="showCustomModal = false">
        <div class="absolute inset-0 bg-[#0F172A]/40 backdrop-blur-[2px]"></div>
        <div class="relative flex flex-col w-[420px] bg-[var(--color-white)] rounded-[12px] shadow-[0_20px_60px_rgba(15,23,42,0.20)] border border-[var(--color-border-light)] overflow-hidden">
          <div class="flex flex-row justify-between items-center px-[20px] py-[14px] border-b border-[var(--color-border-light)]">
            <div class="flex flex-col gap-[1px]">
              <span class="text-[13px] font-[700] text-[var(--color-title)]">自定义尺寸</span>
              <span class="text-[9px] text-[var(--color-muted)]">为你的项目设定精确画布</span>
            </div>
            <div class="flex flex-row justify-center items-center w-[24px] h-[24px] rounded-[5px] cursor-pointer hover:bg-[var(--color-panel)] transition-colors" @click="showCustomModal = false">
              <i class="fa-solid fa-xmark text-[10px] text-[var(--color-muted)]"></i>
            </div>
          </div>
          <div class="flex flex-col gap-[14px] px-[20px] py-[18px]">
            <div class="flex flex-row items-end gap-[10px]">
              <label class="flex flex-col gap-[4px] flex-1">
                <span class="text-[9px] font-[600] uppercase tracking-[0.06em] text-[var(--color-muted)]">宽度</span>
                <input type="number" v-model.number="customW" min="1" class="h-[32px] px-[10px] text-[12px] font-[600] border border-[var(--color-border)] rounded-[6px] outline-none focus:border-[var(--color-primary)] focus:shadow-[0_0_0_3px_rgba(58,196,135,0.12)] bg-[var(--color-white)] text-[var(--color-body)] transition-shadow" />
              </label>
              <div class="flex flex-row justify-center items-center w-[28px] h-[32px] mb-[0]">
                <i class="fa-solid fa-link text-[10px] text-[var(--color-muted)]"></i>
              </div>
              <label class="flex flex-col gap-[4px] flex-1">
                <span class="text-[9px] font-[600] uppercase tracking-[0.06em] text-[var(--color-muted)]">高度</span>
                <input type="number" v-model.number="customH" min="1" class="h-[32px] px-[10px] text-[12px] font-[600] border border-[var(--color-border)] rounded-[6px] outline-none focus:border-[var(--color-primary)] focus:shadow-[0_0_0_3px_rgba(58,196,135,0.12)] bg-[var(--color-white)] text-[var(--color-body)] transition-shadow" />
              </label>
              <label class="flex flex-col gap-[4px] w-[80px]">
                <span class="text-[9px] font-[600] uppercase tracking-[0.06em] text-[var(--color-muted)]">单位</span>
                <select v-model="customUnit" class="h-[32px] px-[8px] text-[12px] font-[600] border border-[var(--color-border)] rounded-[6px] outline-none bg-[var(--color-white)] text-[var(--color-body)] focus:border-[var(--color-primary)] cursor-pointer">
                  <option value="mm">毫米</option>
                  <option value="cm">厘米</option>
                  <option value="px">像素</option>
                  <option value="pt">点</option>
                  <option value="in">英寸</option>
                </select>
              </label>
            </div>
            <div class="flex flex-row items-center gap-[10px]">
              <label class="flex flex-row items-center gap-[6px] cursor-pointer">
                <div class="w-[16px] h-[16px] rounded-[4px] border flex items-center justify-center transition-all" :class="facing === 'portrait' ? 'bg-[var(--color-primary)] border-[var(--color-primary)]' : 'border-[var(--color-border)] bg-[var(--color-white)]'" @click="facing = 'portrait'">
                  <i v-if="facing === 'portrait'" class="fa-solid fa-check text-[7px] text-white"></i>
                </div>
                <span class="text-[10px] font-[500] text-[var(--color-body)]">竖向</span>
              </label>
              <label class="flex flex-row items-center gap-[6px] cursor-pointer">
                <div class="w-[16px] h-[16px] rounded-[4px] border flex items-center justify-center transition-all" :class="facing === 'landscape' ? 'bg-[var(--color-primary)] border-[var(--color-primary)]' : 'border-[var(--color-border)] bg-[var(--color-white)]'" @click="facing = 'landscape'">
                  <i v-if="facing === 'landscape'" class="fa-solid fa-check text-[7px] text-white"></i>
                </div>
                <span class="text-[10px] font-[500] text-[var(--color-body)]">横向</span>
              </label>
              <div class="flex-1"></div>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer">
                <input type="checkbox" v-model="includeBleed" class="accent-[var(--color-primary)] cursor-pointer w-[12px] h-[12px]" />
                <span class="text-[10px] font-[500] text-[var(--color-secondary)]">出血 3mm</span>
              </label>
              <label class="flex flex-row items-center gap-[4px] cursor-pointer">
                <input type="checkbox" v-model="cmYK" class="accent-[var(--color-primary)] cursor-pointer w-[12px] h-[12px]" />
                <span class="text-[10px] font-[500] text-[var(--color-secondary)]">CMYK</span>
              </label>
            </div>
            <div class="grid grid-cols-2 gap-[10px]">
              <label class="flex flex-col gap-[4px]">
                <span class="text-[9px] font-[600] uppercase tracking-[0.06em] text-[var(--color-muted)]">色彩配置</span>
                <select v-model="colorProfile" class="h-[28px] px-[8px] text-[10px] font-[500] border border-[var(--color-border)] rounded-[5px] outline-none bg-[var(--color-white)] text-[var(--color-body)] focus:border-[var(--color-primary)] cursor-pointer">
                  <option value="sRGB">sRGB IEC61966-2.1</option>
                  <option value="displayP3">Display P3</option>
                  <option value="adobeRGB">Adobe RGB (1998)</option>
                  <option value="cmykCoated">CMYK FOGRA39</option>
                </select>
              </label>
              <label class="flex flex-col gap-[4px]">
                <span class="text-[9px] font-[600] uppercase tracking-[0.06em] text-[var(--color-muted)]">栅格效果</span>
                <select v-model="rasterEffect" class="h-[28px] px-[8px] text-[10px] font-[500] border border-[var(--color-border)] rounded-[5px] outline-none bg-[var(--color-white)] text-[var(--color-body)] focus:border-[var(--color-primary)] cursor-pointer">
                  <option value="300">高 (300 PPI)</option>
                  <option value="150">中 (150 PPI)</option>
                  <option value="72">屏幕 (72 PPI)</option>
                </select>
              </label>
            </div>
          </div>
          <div class="flex flex-row items-center justify-end gap-[8px] px-[20px] py-[14px] border-t border-[var(--color-border-light)] bg-[var(--color-panel)]">
            <button type="button" class="px-[14px] h-[32px] rounded-[6px] text-[11px] font-[600] text-[var(--color-secondary)] hover:text-[var(--color-body)] hover:bg-[var(--color-white)] transition-colors" @click="showCustomModal = false">取消</button>
            <button type="button" class="px-[16px] h-[32px] rounded-[6px] text-[11px] font-[700] text-white bg-[var(--color-primary)] shadow-[0_3px_10px_rgba(58,196,135,0.30)] hover:bg-[#32B77C] transition-colors" @click="showCustomModal = false">应用</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { useToastStore } from '../stores/toast'
import type { FrameType } from '../types'

const emit = defineEmits<{
  (e: 'enter-workspace'): void
}>()

const fusion = useFusionDocumentStore()
const toastStore = useToastStore()

const isDark = ref(false)
const toggleTheme = () => {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
}

// Tabs
const tabs = [
  { id: 'new', label: '新建', icon: 'fa-file-circle-plus' },
  { id: 'recent', label: '最近', icon: 'fa-clock-rotate-left' },
  { id: 'templates', label: '模板', icon: 'fa-shapes' },
] as const
const activeTab = ref<'new' | 'recent' | 'templates'>('new')

// ─── Frame 模式预设（4 种） ───
interface FrameModePreset {
  type: FrameType
  name: string
  desc: string
  orient: string
}
const frameModes: FrameModePreset[] = [
  { type: 'single',    name: '单页',   desc: '595 × 842 · A4 竖向',  orient: '竖' },
  { type: 'poster',    name: '海报',   desc: '595 × 842 · A4 海报',  orient: '竖' },
  { type: 'book-page', name: '书页',   desc: '297 × 420 · 书籍单页', orient: '竖' },
  { type: 'spread',    name: '对页',   desc: '594 × 420 · 左右对页', orient: '横' },
]
const selectedFrameType = ref<FrameType>('single')
const currentFrameModeName = computed(() => frameModes.find(m => m.type === selectedFrameType.value)?.name ?? '单页')

// ─── 创建文档 ───
function onCreateDocument(): void {
  fusion.newDocumentWithFrameType(selectedFrameType.value)
  toastStore.show(`已创建 ${currentFrameModeName.value} 文档`, 'fa-file-circle-plus', 'success')
  emit('enter-workspace')
}

// 自定义尺寸弹窗
const showCustomModal = ref(false)
const customW = ref(210)
const customH = ref(297)
const customUnit = ref('mm')
const facing = ref<'portrait' | 'landscape'>('portrait')
const includeBleed = ref(true)
const cmYK = ref(false)

// 色彩与栅格
const colorProfile = ref('sRGB')
const rasterEffect = ref('300')

// 最近文件
const recentFiles = [
  {
    name: '品牌画册_v3.hds',
    time: '5 分钟前',
    size: '12.4 MB',
    pages: 24,
    thumbW: 70, thumbH: 96,
    bgColor: '#FAFBFB',
    previewBlocks: 3,
    blockHeights: [20, 36, 16],
    blockColors: ['#3AC487', '#E5E7EB', '#1F2329'],
  },
  {
    name: '夏季海报_2026.hds',
    time: '1 小时前',
    size: '8.7 MB',
    pages: 1,
    thumbW: 70, thumbH: 96,
    bgColor: '#FFF8E8',
    previewBlocks: 2,
    blockHeights: [40, 24],
    blockColors: ['#F59E0B', '#1F2329'],
  },
  {
    name: '社交媒体合集.hds',
    time: '昨天 14:32',
    size: '5.2 MB',
    pages: 6,
    thumbW: 70, thumbH: 96,
    bgColor: '#F0F6F3',
    previewBlocks: 4,
    blockHeights: [16, 16, 16, 16],
    blockColors: ['#3AC487', '#3B82F6', '#F59E0B', '#1F2329'],
  },
  {
    name: '产品手册_2026Q3.hds',
    time: '2 天前',
    size: '18.1 MB',
    pages: 32,
    thumbW: 70, thumbH: 96,
    bgColor: '#FAFBFB',
    previewBlocks: 3,
    blockHeights: [24, 30, 18],
    blockColors: ['#1F2329', '#E5E7EB', '#3AC487'],
  },
  {
    name: 'Logo设计稿.hds',
    time: '3 天前',
    size: '2.8 MB',
    pages: 4,
    thumbW: 70, thumbH: 96,
    bgColor: '#FFFFFF',
    previewBlocks: 1,
    blockHeights: [60],
    blockColors: ['#1F2329'],
  },
  {
    name: '展会横幅.hds',
    time: '上周',
    size: '24.6 MB',
    pages: 2,
    thumbW: 70, thumbH: 96,
    bgColor: '#FEF2F2',
    previewBlocks: 2,
    blockHeights: [30, 30],
    blockColors: ['#EF4444', '#1F2329'],
  },
]

// 模板
const templates = [
  { name: '海报', icon: 'fa-image', count: 24, color: '#3AC487' },
  { name: '画册', icon: 'fa-book', count: 18, color: '#3B82F6' },
  { name: '社媒图', icon: 'fa-share-nodes', count: 32, color: '#F59E0B' },
  { name: '名片', icon: 'fa-id-card', count: 12, color: '#8B5CF6' },
  { name: 'Logo', icon: 'fa-bezier-curve', count: 16, color: '#EC4899' },
  { name: '插画', icon: 'fa-paintbrush', count: 28, color: '#06B6D4' },
  { name: '排版', icon: 'fa-align-left', count: 14, color: '#10B981' },
  { name: 'UI设计', icon: 'fa-mobile-screen', count: 22, color: '#6366F1' },
]
</script>
