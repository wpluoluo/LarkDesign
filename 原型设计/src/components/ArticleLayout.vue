<template>
  <div class="flex flex-col justify-start items-stretch p-[24px] gap-[24px] bg-[var(--color-panel)]">
    <!-- Header info -->
    <div class="flex flex-row justify-between items-start">
      <span class="text-[9px] leading-[12px] font-[700] text-[var(--color-primary-dark-700)] tracking-[0.1em]">HARMONY / DESIGN / 内页版式 01</span>
    </div>
    <h1 class="text-[28px] leading-[36px] font-[800] text-[var(--color-title)]">品牌视觉语言构建指南</h1>
    <div class="flex flex-row justify-start items-center gap-[8px] text-[12px] leading-[16px] font-[500] text-[var(--color-tertiary)]">
      <span>2026年7月19日</span>
      <span>·</span>
      <span>6 分钟阅读</span>
    </div>
    <!-- Article body -->
    <div class="flex flex-col gap-[6px] py-[8px]">
      <p class="text-[13px] leading-[20px] font-[400] text-[var(--color-body)]">
        建立一致的品牌视觉语言是现代设计系统的核心。本文档概述了 Harmony Design Studio 中品牌标识的核心原则、色彩使用规范、字体层级标准以及版式网格系统。
      </p>
    </div>
    <!-- Section 1: Color -->
    <div class="flex flex-col gap-[12px]">
      <h2 class="text-[20px] leading-[28px] font-[700] text-[var(--color-title)]">1. 色彩体系</h2>
      <p class="text-[13px] leading-[20px] font-[400] text-[var(--color-body)]">
        品牌主色为 <span class="font-[600] text-[var(--color-primary)]">Harmony Green #30D158</span>，传达专业、创新与协调。
      </p>
    </div>
    <!-- Section 2: Typography -->
    <div class="flex flex-col gap-[12px]">
      <h2 class="text-[20px] leading-[28px] font-[700] text-[var(--color-title)]">2. 字体层级</h2>
      <p class="text-[13px] leading-[20px] font-[400] text-[var(--color-body)]">
        字体采用 HarmonyOS Sans SC，H1(28pt)、H2(20pt)、H3(16pt)，正文字体 13pt。
      </p>
      <!-- Type examples -->
      <div class="flex flex-col gap-[8px] p-[16px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px]">
        <div class="text-[28px] leading-[36px] font-[800] text-[var(--color-title)]">H1 标题</div>
        <div class="text-[14px] leading-[18px] font-[500] text-[var(--color-muted)]">28pt ExtraBold</div>
        <div class="w-full h-[1px] bg-[var(--color-border-light)] my-[4px]"></div>
        <div class="text-[20px] leading-[28px] font-[700] text-[var(--color-title)]">H2 标题</div>
        <div class="text-[14px] leading-[18px] font-[500] text-[var(--color-muted)]">20pt Bold</div>
        <div class="w-full h-[1px] bg-[var(--color-border-light)] my-[4px]"></div>
        <div class="text-[13px] leading-[20px] font-[400] text-[var(--color-body)]">正文</div>
        <div class="text-[14px] leading-[18px] font-[500] text-[var(--color-muted)]">13pt Regular</div>
      </div>
    </div>
    <!-- Page properties -->
    <div class="flex flex-col gap-[8px] p-[16px] bg-[var(--color-white)] border border-[var(--color-border)] rounded-[8px]">
      <span class="text-[11px] leading-[14px] font-[700] text-[var(--color-body)]">页面属性</span>
      <div class="grid grid-cols-2 gap-[8px]">
        <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[#8B939D]">尺寸</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">A4 · 210 × 297 mm</span>
        </div>
        <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[#8B939D]">方向</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">纵向</span>
        </div>
        <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[#8B939D]">栏数</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">12 栏</span>
        </div>
        <div class="flex flex-row justify-between items-center h-[28px] px-[8px] bg-[var(--color-panel)] rounded-[4px]">
          <span class="text-[10px] leading-[12px] font-[500] text-[#8B939D]">色彩空间</span>
          <span class="text-[10px] leading-[12px] font-[500] text-[var(--color-body)]">RGB · sRGB</span>
        </div>
      </div>
    </div>
  </div>
</template>