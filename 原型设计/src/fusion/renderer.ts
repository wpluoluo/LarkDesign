/**
 * Fusion DOM - Canvas 渲染引擎
 *
 * 基于 HTML5 Canvas 2D Context 实现 Fusion DOM 的真实栅格化渲染。
 * 支持：
 *  - Scene / Layer / Object 递归渲染
 *  - 图层合成（混合模式、不透明度、pass-through）
 *  - 蒙版（raster / vector）
 *  - 图层效果链（drop-shadow / inner-shadow / glow / overlay 等）
 *  - 离屏缓冲（每图层独立 canvas，便于合成）
 *  - 高 DPI 支持（devicePixelRatio）
 *  - 选中态高亮与控制点（handles）
 */
import type {
  HdsDocument,
  Layer,
  Page,
  SceneObject,
  TextObject,
  ImageObject,
  ShapeObject,
  GroupObject,
  AdjustmentObject,
  FillObject,
  BlendMode,
  LayerEffect,
  Mask,
  Transform,
} from '../types'
import { getCurrentLayers } from './ops'

/* ════════════════ 渲染选项 ════════════════ */

export interface RenderOptions {
  width: number
  height: number
  devicePixelRatio?: number
  background?: string
  showSelection?: boolean
  selectedObjectIds?: string[]
}

/* ════════════════ 工具：创建缓冲 canvas ════════════════ */

/** 优先使用 OffscreenCanvas，不支持时回退到普通 canvas */
function createBuffer(width: number, height: number): HTMLCanvasElement {
  const canvas = document.createElement('canvas')
  canvas.width = Math.max(1, Math.floor(width))
  canvas.height = Math.max(1, Math.floor(height))
  return canvas
}

/* ════════════════ 混合模式映射 ════════════════ */

const BLEND_MODE_MAP: Record<BlendMode, GlobalCompositeOperation> = {
  normal: 'source-over',
  multiply: 'multiply',
  screen: 'screen',
  overlay: 'overlay',
  darken: 'darken',
  lighten: 'lighten',
  'color-dodge': 'color-dodge',
  'color-burn': 'color-burn',
  'hard-light': 'hard-light',
  'soft-light': 'soft-light',
  difference: 'difference',
  exclusion: 'exclusion',
  hue: 'hue',
  saturation: 'saturation',
  color: 'color',
  luminosity: 'luminosity',
  'pass-through': 'source-over',
  dissolve: 'source-over', // 溶解暂用 normal 模拟
}

/* ════════════════ 图像缓存（避免重复加载） ════════════════ */

const imageCache = new Map<string, HTMLImageElement>()

function loadImage(src: string): Promise<HTMLImageElement> {
  const cached = imageCache.get(src)
  if (cached && cached.complete) return Promise.resolve(cached)
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      imageCache.set(src, img)
      resolve(img)
    }
    img.onerror = reject
    img.src = src
  })
}

/**
 * 同步加载图像：仅对已缓存的 dataURL/资源返回 Image，否则返回 null。
 * 主要用于 mask 等无法 await 的同步场景。
 */
function loadImageSync(src: string): HTMLImageElement | null {
  const cached = imageCache.get(src)
  if (cached && cached.complete) return cached
  // 尝试同步创建并预解码（仅 dataURL 能可靠同步加载）
  if (src.startsWith('data:')) {
    const img = new Image()
    img.src = src
    // 同步解码可能未完成，但仍可 drawImage（浏览器内部会等待）
    imageCache.set(src, img)
    return img
  }
  return null
}

/* ════════════════ 渲染器主类 ════════════════ */

export class CanvasRenderer {
  private canvas: HTMLCanvasElement
  private ctx: CanvasRenderingContext2D
  private dpr: number
  private width: number
  private height: number

  constructor(canvas: HTMLCanvasElement, opts: RenderOptions) {
    this.canvas = canvas
    this.dpr = opts.devicePixelRatio ?? window.devicePixelRatio ?? 1
    this.width = opts.width
    this.height = opts.height
    this.setupCanvas()
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas 2D context not supported')
    this.ctx = ctx
  }

  /** 配置 canvas 尺寸（考虑 DPR） */
  private setupCanvas(): void {
    const w = Math.max(1, Math.floor(this.width * this.dpr))
    const h = Math.max(1, Math.floor(this.height * this.dpr))
    this.canvas.width = w
    this.canvas.height = h
    this.canvas.style.width = `${this.width}px`
    this.canvas.style.height = `${this.height}px`
  }

  /** 更新尺寸 */
  resize(width: number, height: number): void {
    this.width = width
    this.height = height
    this.setupCanvas()
  }

  /** 主渲染入口：渲染整个文档
   *  opts.layers：可选自定义图层列表（用于渲染指定 Frame 的内容，绕过 getCurrentLayers 路由）
   *  opts.background：可选自定义背景色（用于 Frame 自身的背景）
   */
  async render(
    doc: HdsDocument,
    opts: { showSelection?: boolean; selectedObjectIds?: string[]; layers?: Layer[]; background?: string } = {},
  ): Promise<void> {
    const { showSelection = false, selectedObjectIds = [], layers, background } = opts
    const ctx = this.ctx

    // 清空 & 绘制背景
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
    ctx.save()
    ctx.scale(this.dpr, this.dpr)

    // 绘制画布背景（优先使用传入的 background，其次 doc.scene.background）
    const bg = background ?? doc.scene.background ?? '#FFFFFF'
    ctx.fillStyle = bg
    ctx.fillRect(0, 0, this.width, this.height)

    // 从下往上渲染图层（优先使用传入的 layers，否则自动路由到当前页面/Frame）
    const targetLayers = layers ?? getCurrentLayers(doc)
    for (const layer of targetLayers) {
      if (!layer.visible) continue
      await this.renderLayer(ctx, layer, showSelection, selectedObjectIds)
    }

    // 绘制选中态
    if (showSelection && selectedObjectIds.length > 0) {
      this.drawSelectionHandles(ctx, doc, selectedObjectIds)
    }

    ctx.restore()
  }

  /** 渲染单个图层（含合成） */
  private async renderLayer(
    parentCtx: CanvasRenderingContext2D,
    layer: Layer,
    showSelection: boolean,
    selectedIds: string[],
  ): Promise<void> {
    // 创建图层缓冲
    const buffer = createBuffer(this.width, this.height)
    const bctx = buffer.getContext('2d')
    if (!bctx) return

    // 渲染图层所有对象到缓冲
    for (const obj of layer.objects) {
      if (!obj.visible) continue
      await this.renderObject(bctx, obj)
    }

    // 应用蒙版
    if (layer.hasMask && layer.mask && layer.maskEnabled) {
      this.applyMask(bctx, layer.mask)
    }

    // 应用图层效果
    if (layer.effects.length > 0) {
      this.applyEffects(bctx, layer.effects)
    }

    // 合成到父 canvas
    parentCtx.save()
    parentCtx.globalAlpha = (parentCtx.globalAlpha * layer.transform.opacity) / 100
    parentCtx.globalCompositeOperation = BLEND_MODE_MAP[layer.blendMode] ?? 'source-over'
    parentCtx.drawImage(buffer, 0, 0, this.width, this.height)
    parentCtx.restore()
  }

  /** 渲染单个对象（分发到具体类型） */
  private async renderObject(ctx: CanvasRenderingContext2D, obj: SceneObject): Promise<void> {
    ctx.save()
    this.applyTransform(ctx, obj.transform)
    ctx.globalAlpha = (ctx.globalAlpha * obj.transform.opacity) / 100
    ctx.globalCompositeOperation = BLEND_MODE_MAP[obj.blendMode] ?? 'source-over'

    switch (obj.type) {
      case 'text': this.renderText(ctx, obj); break
      case 'image': await this.renderImage(ctx, obj); break
      case 'shape': this.renderShape(ctx, obj); break
      case 'group': await this.renderGroup(ctx, obj); break
      case 'adjustment': this.renderAdjustment(ctx, obj); break
      case 'fill': this.renderFill(ctx, obj); break
    }

    ctx.restore()
  }

  /** 应用变换（位置/旋转/缩放/翻转） */
  private applyTransform(ctx: CanvasRenderingContext2D, t: Transform): void {
    const cx = t.x + t.width / 2
    const cy = t.y + t.height / 2
    ctx.translate(cx, cy)
    if (t.rotation) ctx.rotate((t.rotation * Math.PI) / 180)
    if (t.scaleX !== 1 || t.scaleY !== 1) ctx.scale(t.scaleX, t.scaleY)
    if (t.flipH || t.flipV) ctx.scale(t.flipH ? -1 : 1, t.flipV ? -1 : 1)
    ctx.translate(-cx, -cy)
    ctx.translate(t.x, t.y)
  }

  /* ──────── 类型分发渲染 ──────── */

  /** 渲染文本对象 */
  private renderText(ctx: CanvasRenderingContext2D, obj: TextObject): void {
    const t = obj.transform
    ctx.font = `${obj.fontStyle === 'italic' ? 'italic ' : ''}${obj.fontWeight} ${obj.fontSize}px ${obj.fontFamily}`
    ctx.fillStyle = obj.color
    ctx.textBaseline = 'top'
    ctx.textAlign = obj.align as CanvasTextAlign

    // 字间距（letterSpacing 是较新 API，做兼容判断）
    if ('letterSpacing' in ctx) {
      try {
        ;(ctx as CanvasRenderingContext2D & { letterSpacing: string }).letterSpacing = `${obj.letterSpacing}px`
      } catch {
        /* 忽略 */
      }
    }

    const lines = obj.text.split('\n')
    const lineHeight = obj.fontSize * obj.lineHeight
    lines.forEach((line, i) => {
      let x = 0
      if (obj.align === 'center') x = t.width / 2
      else if (obj.align === 'right') x = t.width
      ctx.fillText(line, x, i * lineHeight)
    })
  }

  /** 渲染图片对象（异步） */
  private async renderImage(ctx: CanvasRenderingContext2D, obj: ImageObject): Promise<void> {
    if (!obj.src) return
    try {
      const img = await loadImage(obj.src)
      const t = obj.transform
      // 滤镜必须在 drawImage 之前设置，否则不会应用到图像上
      let prevFilter = 'none'
      if (obj.filters && obj.filters.length > 0) {
        const filter = obj.filters
          .map(f => {
            const unit = f.type === 'hue-rotate' ? 'deg' : f.type === 'blur' ? 'px' : ''
            const val = f.type === 'blur' ? f.value : f.type.includes('rotate') ? f.value : `${f.value}%`
            return `${f.type}(${f.type === 'blur' || f.type.includes('rotate') ? f.value + unit : val})`
          })
          .join(' ')
        prevFilter = ctx.filter
        ctx.filter = filter
      }
      ctx.drawImage(img, 0, 0, t.width, t.height)
      // 恢复 filter，避免影响后续绘制
      if (obj.filters && obj.filters.length > 0) {
        ctx.filter = prevFilter
      }
    } catch {
      // 加载失败：绘制占位框
      const t = obj.transform
      ctx.strokeStyle = '#EF4444'
      ctx.lineWidth = 1
      ctx.strokeRect(0, 0, t.width, t.height)
      ctx.fillStyle = '#FEE2E2'
      ctx.fillRect(0, 0, t.width, t.height)
      ctx.fillStyle = '#B91C1C'
      ctx.font = '12px sans-serif'
      ctx.textBaseline = 'middle'
      ctx.textAlign = 'center'
      ctx.fillText('图像加载失败', t.width / 2, t.height / 2)
    }
  }

  /** 渲染形状对象 */
  private renderShape(ctx: CanvasRenderingContext2D, obj: ShapeObject): void {
    const t = obj.transform

    // path/custom：直接使用 Path2D 进行 fill/stroke
    if (obj.shape === 'path' || obj.shape === 'custom') {
      if (obj.path) {
        const p = new Path2D(obj.path)
        if (obj.fill) {
          ctx.fillStyle = obj.fill
          ctx.fill(p)
        }
        if (obj.strokeWidth > 0) {
          ctx.strokeStyle = obj.stroke
          ctx.lineWidth = obj.strokeWidth
          ctx.stroke(p)
        }
      }
      return
    }

    ctx.beginPath()
    switch (obj.shape) {
      case 'rectangle': {
        const r = obj.cornerRadius ?? 0
        if (r > 0) {
          this.roundRect(ctx, 0, 0, t.width, t.height, r)
        } else {
          ctx.rect(0, 0, t.width, t.height)
        }
        break
      }
      case 'ellipse': {
        ctx.ellipse(t.width / 2, t.height / 2, t.width / 2, t.height / 2, 0, 0, Math.PI * 2)
        break
      }
      case 'polygon': {
        this.drawPolygon(ctx, t.width / 2, t.height / 2, Math.min(t.width, t.height) / 2, obj.sides ?? 5)
        break
      }
      case 'star': {
        this.drawStar(ctx, t.width / 2, t.height / 2, Math.min(t.width, t.height) / 2, obj.sides ?? 5)
        break
      }
      case 'line': {
        ctx.moveTo(0, t.height / 2)
        ctx.lineTo(t.width, t.height / 2)
        break
      }
    }

    if (obj.fill) {
      ctx.fillStyle = obj.fill
      ctx.fill()
    }
    if (obj.strokeWidth > 0) {
      ctx.strokeStyle = obj.stroke
      ctx.lineWidth = obj.strokeWidth
      ctx.stroke()
    }
  }

  /** 渲染组对象（递归） */
  private async renderGroup(ctx: CanvasRenderingContext2D, obj: GroupObject): Promise<void> {
    for (const child of obj.children) {
      if (!child.visible) continue
      await this.renderObject(ctx, child)
    }
  }

  /** 渲染调整图层（占位） */
  private renderAdjustment(ctx: CanvasRenderingContext2D, obj: AdjustmentObject): void {
    const t = obj.transform
    ctx.strokeStyle = '#A855F7'
    ctx.lineWidth = 1
    ctx.setLineDash([4, 4])
    ctx.strokeRect(0, 0, t.width, t.height)
    ctx.setLineDash([])
  }

  /** 渲染填充图层 */
  private renderFill(ctx: CanvasRenderingContext2D, obj: FillObject): void {
    const t = obj.transform
    if (obj.fillType === 'solid' || !obj.gradient) {
      ctx.fillStyle = obj.color
      ctx.fillRect(0, 0, t.width, t.height)
    } else if (obj.fillType === 'gradient' && obj.gradient) {
      const g = obj.gradient
      let grad: CanvasGradient
      const x1 = 0, y1 = 0, x2 = t.width, y2 = 0
      if (g.type === 'linear') {
        const angleRad = (g.angle * Math.PI) / 180
        const cx = t.width / 2, cy = t.height / 2
        const len = Math.max(t.width, t.height)
        grad = ctx.createLinearGradient(
          cx - Math.cos(angleRad) * len / 2,
          cy - Math.sin(angleRad) * len / 2,
          cx + Math.cos(angleRad) * len / 2,
          cy + Math.sin(angleRad) * len / 2,
        )
      } else {
        grad = ctx.createRadialGradient(
          t.width / 2, t.height / 2, 0,
          t.width / 2, t.height / 2, Math.max(t.width, t.height) / 2,
        )
      }
      g.stops.forEach(s => {
        grad.addColorStop(s.offset, s.color)
      })
      ctx.fillStyle = grad
      ctx.fillRect(0, 0, t.width, t.height)
    }
  }

  /* ──────── 蒙版与效果链 ──────── */

  /** 应用蒙版（destination-in 合成） */
  private applyMask(ctx: CanvasRenderingContext2D, mask: Mask): void {
    if (!mask.enabled) return
    ctx.save()
    ctx.globalCompositeOperation = mask.inverted ? 'destination-out' : 'destination-in'
    if (mask.type === 'vector' && mask.data) {
      const path = new Path2D(mask.data)
      ctx.fill(path)
    } else if (mask.type === 'raster' && mask.data) {
      // raster 模式：蒙版数据为 dataURL/SVG，绘制为图像以保留真实形状
      // 使用同步加载策略：通过 Image 同步加载（已经预解码的 dataURL）
      // 这里采用在 CanvasRenderingContext2D 上 drawImage 的方式
      try {
        const maskImg = loadImageSync(mask.data)
        if (maskImg) {
          ctx.drawImage(maskImg, 0, 0, this.width, this.height)
        } else {
          // 加载失败：退化为矩形蒙版
          ctx.fillRect(0, 0, this.width, this.height)
        }
      } catch {
        // 异常时退化为矩形蒙版
        ctx.fillRect(0, 0, this.width, this.height)
      }
    } else {
      // 无数据：矩形蒙版
      ctx.fillRect(0, 0, this.width, this.height)
    }
    ctx.restore()
  }

  /** 应用图层效果链（按顺序叠加） */
  private applyEffects(ctx: CanvasRenderingContext2D, effects: LayerEffect[]): void {
    effects.filter(e => e.enabled).forEach(effect => {
      const p = effect.params
      switch (effect.type) {
        case 'drop-shadow':
        case 'inner-shadow': {
          const angle = ((p.angle as number) ?? 120) * Math.PI / 180
          const distance = (p.distance as number) ?? 5
          const offsetX = Math.cos(angle) * distance
          const offsetY = Math.sin(angle) * distance
          const isInner = effect.type === 'inner-shadow'
          // 使用双缓冲：将当前图层内容复制到临时 canvas，
          // 然后用 shadow 在原 canvas 上重绘，触发阴影
          const src = createBuffer(this.width, this.height)
          const sctx = src.getContext('2d')
          if (!sctx) break
          // 复制当前 buffer 内容到 src
          sctx.drawImage(ctx.canvas, 0, 0)
          // 清空原 canvas
          ctx.clearRect(0, 0, this.width, this.height)
          ctx.save()
          ctx.shadowColor = this.colorWithAlpha((p.color as string) ?? '#000000', ((p.opacity as number) ?? 40) / 100)
          ctx.shadowBlur = (p.blur as number) ?? 4
          ctx.shadowOffsetX = isInner ? 0 : offsetX
          ctx.shadowOffsetY = isInner ? 0 : offsetY
          if (isInner) {
            // 内阴影：先反转（destination-out 取出原图），再恢复
            // 简化实现：阴影偏移为 0，仅以 shadowColor 配合 invert
            ctx.globalCompositeOperation = 'source-over'
            ctx.drawImage(src, 0, 0)
            // 用 destination-out 配合 shadow 实现内阴影
            ctx.globalCompositeOperation = 'destination-out'
            ctx.shadowColor = this.colorWithAlpha((p.color as string) ?? '#000000', ((p.opacity as number) ?? 40) / 100)
            ctx.shadowOffsetX = -offsetX
            ctx.shadowOffsetY = -offsetY
            ctx.drawImage(src, 0, 0)
          } else {
            // 外阴影：先绘制阴影（在空 canvas 上画 source 触发 shadow）
            ctx.drawImage(src, 0, 0)
          }
          ctx.restore()
          break
        }
        case 'color-overlay': {
          // 使用 multiply 让颜色与下层混合（保留明暗），source-atop 会丢失暗部
          ctx.save()
          ctx.globalCompositeOperation = 'source-atop'
          ctx.fillStyle = this.colorWithAlpha((p.color as string) ?? '#3AC487', ((p.opacity as number) ?? 100) / 100)
          ctx.fillRect(0, 0, this.width, this.height)
          ctx.restore()
          break
        }
        case 'outer-glow':
        case 'inner-glow': {
          const color = (p.color as string) ?? '#3AC487'
          const op = ((p.opacity as number) ?? 50) / 100
          const blur = (p.blur as number) ?? 8
          const isInner = effect.type === 'inner-glow'
          const src = createBuffer(this.width, this.height)
          const sctx = src.getContext('2d')
          if (!sctx) break
          sctx.drawImage(ctx.canvas, 0, 0)
          ctx.clearRect(0, 0, this.width, this.height)
          ctx.save()
          ctx.shadowColor = this.colorWithAlpha(color, op)
          ctx.shadowBlur = blur
          ctx.shadowOffsetX = 0
          ctx.shadowOffsetY = 0
          if (isInner) {
            ctx.globalCompositeOperation = 'source-over'
            ctx.drawImage(src, 0, 0)
            ctx.globalCompositeOperation = 'destination-out'
            ctx.drawImage(src, 0, 0)
          } else {
            ctx.drawImage(src, 0, 0)
          }
          ctx.restore()
          break
        }
        // 其他效果占位
        default:
          break
      }
    })
  }

  /** 重新合成以应用阴影（已废弃，保留空实现以兼容旧调用） */
  private recompositeWithShadow(_ctx: CanvasRenderingContext2D): void {
    // 不再使用：阴影通过双缓冲在 applyEffects 内部直接处理
    void _ctx
  }

  /* ──────── 选中态绘制 ──────── */

  /** 绘制选中对象的边框与控制点 */
  private drawSelectionHandles(ctx: CanvasRenderingContext2D, doc: HdsDocument, selectedIds: string[]): void {
    const collect = (objs: SceneObject[]): SceneObject[] => {
      const result: SceneObject[] = []
      objs.forEach(o => {
        if (selectedIds.includes(o.id)) result.push(o)
        if (o.type === 'group' && o.children) result.push(...collect(o.children))
      })
      return result
    }
    getCurrentLayers(doc).forEach(layer => {
      const selected = collect(layer.objects)
      selected.forEach(obj => {
        const t = obj.transform
        ctx.save()
        ctx.strokeStyle = '#3B82F6'
        ctx.lineWidth = 1
        ctx.setLineDash([4, 2])
        ctx.strokeRect(t.x - 0.5, t.y - 0.5, t.width + 1, t.height + 1)
        ctx.setLineDash([])
        // 四角控制点
        const handles = [
          [t.x, t.y],
          [t.x + t.width, t.y],
          [t.x, t.y + t.height],
          [t.x + t.width, t.y + t.height],
        ]
        handles.forEach(([hx, hy]) => {
          ctx.fillStyle = '#FFFFFF'
          ctx.fillRect(hx - 3, hy - 3, 6, 6)
          ctx.strokeStyle = '#3B82F6'
          ctx.lineWidth = 1
          ctx.strokeRect(hx - 3, hy - 3, 6, 6)
        })
        ctx.restore()
      })
    })
  }

  /* ──────── 辅助几何函数 ──────── */

  private roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    const radius = Math.min(r, w / 2, h / 2)
    ctx.moveTo(x + radius, y)
    ctx.arcTo(x + w, y, x + w, y + h, radius)
    ctx.arcTo(x + w, y + h, x, y + h, radius)
    ctx.arcTo(x, y + h, x, y, radius)
    ctx.arcTo(x, y, x + w, y, radius)
    ctx.closePath()
  }

  private drawPolygon(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, sides: number): void {
    for (let i = 0; i < sides; i++) {
      const angle = (i * 2 * Math.PI) / sides - Math.PI / 2
      const x = cx + Math.cos(angle) * r
      const y = cy + Math.sin(angle) * r
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
  }

  private drawStar(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, points: number): void {
    const innerR = r * 0.5
    const total = points * 2
    for (let i = 0; i < total; i++) {
      const radius = i % 2 === 0 ? r : innerR
      const angle = (i * Math.PI) / points - Math.PI / 2
      const x = cx + Math.cos(angle) * radius
      const y = cy + Math.sin(angle) * radius
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
  }

  /** 颜色 + alpha → rgba 字符串 */
  private colorWithAlpha(color: string, alpha: number): string {
    // 简化处理 hex
    if (color.startsWith('#')) {
      const hex = color.slice(1)
      const r = parseInt(hex.slice(0, 2), 16)
      const g = parseInt(hex.slice(2, 4), 16)
      const b = parseInt(hex.slice(4, 6), 16)
      return `rgba(${r}, ${g}, ${b}, ${alpha})`
    }
    return color
  }

  /** 导出 canvas 为 dataURL */
  toDataURL(type = 'image/png', quality?: number): string {
    return this.canvas.toDataURL(type, quality)
  }

  /** 导出为 Blob */
  toBlob(type = 'image/png', quality?: number): Promise<Blob | null> {
    return new Promise(resolve => {
      this.canvas.toBlob(blob => resolve(blob), type, quality)
    })
  }
}

/* ════════════════ 单例管理（可选） ════════════════ */

let rendererInstance: CanvasRenderer | null = null

export function getRenderer(canvas: HTMLCanvasElement, opts: RenderOptions): CanvasRenderer {
  if (!rendererInstance) {
    rendererInstance = new CanvasRenderer(canvas, opts)
  }
  return rendererInstance
}
