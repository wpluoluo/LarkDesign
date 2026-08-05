/**
 * useCanvasRenderer - Canvas 渲染引擎的 Vue Composable
 *
 * 职责：
 *  - 管理 CanvasRenderer 实例生命周期
 *  - 监听 Fusion DOM 变化自动重渲染
 *  - 监听选中态、缩放等变化触发重绘
 *  - 暴露渲染控制 API（resize / export）
 *
 * 支持两种渲染模式：
 *  1. 默认模式：渲染当前文档（自动路由到当前页面/Frame）
 *  2. 自定义模式：通过 width/height/background/layersSource 渲染指定内容
 *     用于 FrameView 渲染单个 Frame 的内容
 */
import { ref, watch, onUnmounted, type Ref } from 'vue'
import { CanvasRenderer } from '../fusion/renderer'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import type { Layer } from '../types'

export interface UseCanvasRendererOptions {
  /** 渲染目标 canvas 元素引用 */
  canvasRef: Ref<HTMLCanvasElement | null>
  /** 是否绘制选中态 */
  showSelection?: Ref<boolean>
  /** 设备像素比（默认使用 window.devicePixelRatio） */
  devicePixelRatio?: number
  /** 自定义画布宽度（用于 Frame 渲染） */
  width?: Ref<number>
  /** 自定义画布高度（用于 Frame 渲染） */
  height?: Ref<number>
  /** 自定义背景色（用于 Frame 渲染） */
  background?: Ref<string>
  /** 自定义图层源（用于渲染指定 Frame 的内容） */
  layersSource?: Ref<{ layers: Layer[]; selectedIds?: string[] } | null>
}

export function useCanvasRenderer(opts: UseCanvasRendererOptions) {
  const fusion = useFusionDocumentStore()
  const renderer = ref<CanvasRenderer | null>(null)
  const isRendering = ref(false)
  let renderRaf: number | null = null

  /** 获取当前渲染宽度 */
  function getRenderWidth(): number {
    return opts.width?.value ?? fusion.scene.canvasWidth
  }

  /** 获取当前渲染高度 */
  function getRenderHeight(): number {
    return opts.height?.value ?? fusion.scene.canvasHeight
  }

  /** 获取当前背景色 */
  function getBackground(): string {
    return opts.background?.value ?? fusion.scene.background ?? '#FFFFFF'
  }

  /** 初始化渲染器（绑定 canvas 元素后调用） */
  function initRenderer(): boolean {
    if (!opts.canvasRef.value) return false
    const dpr = opts.devicePixelRatio ?? window.devicePixelRatio ?? 1
    renderer.value = new CanvasRenderer(opts.canvasRef.value, {
      width: getRenderWidth(),
      height: getRenderHeight(),
      devicePixelRatio: dpr,
      background: getBackground(),
    })
    requestRender()
    return true
  }

  /** 请求重渲染（节流到下一帧） */
  function requestRender(): void {
    if (renderRaf !== null) return
    renderRaf = requestAnimationFrame(async () => {
      renderRaf = null
      if (!renderer.value) return
      isRendering.value = true
      try {
        const layersSource = opts.layersSource?.value
        if (layersSource) {
          // 自定义图层源模式（Frame 渲染）
          await renderer.value.render(fusion.doc, {
            showSelection: opts.showSelection?.value ?? false,
            selectedObjectIds: layersSource.selectedIds ?? [],
            layers: layersSource.layers,
            background: getBackground(),
          })
        } else {
          // 默认模式：渲染整个文档（自动路由到当前页面/Frame）
          await renderer.value.render(fusion.doc, {
            showSelection: opts.showSelection?.value ?? false,
            selectedObjectIds: fusion.selectedObjectIds,
          })
        }
      } finally {
        isRendering.value = false
      }
    })
  }

  /** 重新初始化（尺寸变化时） */
  function reinit(): void {
    renderer.value = null
    initRenderer()
  }

  /** 导出为 dataURL */
  function toDataURL(type = 'image/png', quality?: number): string | null {
    return renderer.value?.toDataURL(type, quality) ?? null
  }

  /** 导出为 Blob */
  async function toBlob(type = 'image/png', quality?: number): Promise<Blob | null> {
    return (await renderer.value?.toBlob(type, quality)) ?? null
  }

  // ─── 自动响应 Fusion DOM 变化 ───
  // 默认模式下监听文档全局变化；自定义模式下监听 layersSource 引用变化
  if (opts.layersSource) {
    // 自定义模式：监听 layersSource 与 showSelection
    watch(
      opts.layersSource,
      () => requestRender(),
      { deep: true },
    )
    if (opts.showSelection) {
      watch(opts.showSelection, () => requestRender())
    }
    // 同时监听 width/height/background 变化触发 reinit
    watch(
      [opts.width, opts.height, opts.background].filter(Boolean) as Ref<unknown>[],
      () => {
        nextTickReinit()
      },
    )
  } else {
    // 默认模式：监听文档选中状态、页面变化
    watch(
      () => [fusion.doc, fusion.currentPageId, fusion.selectedLayerId, fusion.selectedObjectIds.join(',')] as const,
      () => requestRender(),
    )
    if (opts.showSelection) {
      watch(opts.showSelection, () => requestRender())
    }
    // 文档尺寸变化时重新初始化
    watch(
      () => [fusion.scene.canvasWidth, fusion.scene.canvasHeight],
      () => {
        nextTickReinit()
      },
    )
  }

  function nextTickReinit(): void {
    renderer.value = null
    requestAnimationFrame(() => {
      initRenderer()
    })
  }

  // ─── 清理 ───
  onUnmounted(() => {
    if (renderRaf !== null) {
      cancelAnimationFrame(renderRaf)
      renderRaf = null
    }
    renderer.value = null
  })

  return {
    renderer,
    isRendering,
    initRenderer,
    reinit,
    requestRender,
    toDataURL,
    toBlob,
  }
}
