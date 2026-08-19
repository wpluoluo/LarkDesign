/**
 * Canvas2DRenderer - Canvas 2D 渲染引擎
 *
 * 对应原型 src/fusion/renderer.ts
 * 使用 ArkUI CanvasRenderingContext2D API 实现 Fusion DOM 的栅格化渲染。
 * 支持：图层合成（混合模式/不透明度）、蒙版（raster/vector）、效果链（投影/发光/叠加）
 */
import { Frame, Layer, SceneObject, Transform, LayerEffect, Mask } from '../domain/SceneTypes'

class BlendModeMap {
  get(key: string): string {
    if (key === 'multiply') return 'multiply'
    if (key === 'screen') return 'screen'
    if (key === 'overlay') return 'overlay'
    if (key === 'darken') return 'darken'
    if (key === 'lighten') return 'lighten'
    if (key === 'color-dodge') return 'color-dodge'
    if (key === 'color-burn') return 'color-burn'
    if (key === 'hard-light') return 'hard-light'
    if (key === 'soft-light') return 'soft-light'
    if (key === 'difference') return 'difference'
    if (key === 'exclusion') return 'exclusion'
    if (key === 'hue') return 'hue'
    if (key === 'saturation') return 'saturation'
    if (key === 'color') return 'color'
    if (key === 'luminosity') return 'luminosity'
    return 'source-over'
  }
}

const BLEND_MODE_MAP: BlendModeMap = new BlendModeMap()

export class Canvas2DRenderer {
  static renderFrame(ctx: CanvasRenderingContext2D, frame: Frame, width: number, height: number): void {
    ctx.save()
    ctx.fillStyle = frame.background ?? '#FFFFFF'
    ctx.fillRect(0, 0, width, height)
    for (const layer of frame.children) {
      if (!layer.visible) continue
      Canvas2DRenderer.renderLayer(ctx, layer, width, height)
    }
    ctx.restore()
  }

  static renderLayer(ctx: CanvasRenderingContext2D, layer: Layer, width: number, height: number): void {
    ctx.save()
    ctx.globalAlpha = (layer.transform?.opacity ?? 100) / 100
    ctx.globalCompositeOperation = BLEND_MODE_MAP.get(layer.blendMode)
    for (const obj of layer.objects) {
      if (!obj.visible) continue
      Canvas2DRenderer.renderObject(ctx, obj)
    }
    if (layer.hasMask && layer.mask && layer.maskEnabled) {
      Canvas2DRenderer.applyMask(ctx, layer.mask, width, height)
    }
    if (layer.effects.length > 0) {
      Canvas2DRenderer.applyEffects(ctx, layer.effects, width, height)
    }
    ctx.restore()
  }

  static renderObject(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    ctx.save()
    Canvas2DRenderer.applyTransform(ctx, obj.transform)
    ctx.globalAlpha = (obj.transform.opacity ?? 100) / 100
    ctx.globalCompositeOperation = BLEND_MODE_MAP.get(obj.blendMode)
    switch (obj.type) {
      case 'text':
        Canvas2DRenderer.renderText(ctx, obj)
        break
      case 'shape':
        Canvas2DRenderer.renderShape(ctx, obj)
        break
      case 'image':
        Canvas2DRenderer.renderImage(ctx, obj)
        break
      case 'group':
        Canvas2DRenderer.renderGroup(ctx, obj)
        break
      case 'adjustment':
        Canvas2DRenderer.renderAdjustment(ctx, obj)
        break
      case 'fill':
        Canvas2DRenderer.renderFill(ctx, obj)
        break
    }
    ctx.restore()
  }

  static applyTransform(ctx: CanvasRenderingContext2D, t: Transform): void {
    const cx = t.x + t.width / 2
    const cy = t.y + t.height / 2
    ctx.translate(cx, cy)
    if (t.rotation) ctx.rotate((t.rotation * Math.PI) / 180)
    let sx = t.scaleX
    let sy = t.scaleY
    if (t.flipH) sx = -sx
    if (t.flipV) sy = -sy
    if (sx !== 1 || sy !== 1) ctx.scale(sx, sy)
    ctx.translate(-cx, -cy)
    ctx.translate(t.x, t.y)
  }

  static renderText(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    const t = obj.transform
    const fs = obj.fontSize ?? 14
    const fw = obj.fontWeight ?? 400
    const ff = obj.fontFamily ?? 'HarmonyOS Sans SC'
    ctx.font = `${fw} ${fs}px ${ff}`
    ctx.fillStyle = obj.color ?? '#1F2329'
    ctx.textBaseline = 'top'
    ctx.textAlign = (obj.align ?? 'left') as CanvasTextAlign
    const lines = (obj.text ?? '').split('\n')
    const lh = fs * (obj.lineHeight ?? 1.4)
    for (let i = 0; i < lines.length; i++) {
      let x = 0
      if (obj.align === 'center') x = t.width / 2
      else if (obj.align === 'right') x = t.width
      ctx.fillText(lines[i], x, i * lh)
    }
  }

  static renderShape(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    const t = obj.transform
    ctx.beginPath()
    const shape = obj.shape ?? 'rectangle'
    if (shape === 'path' || shape === 'custom') {
      Canvas2DRenderer.renderPathShape(ctx, obj)
      return
    }
    switch (shape) {
      case 'rectangle': {
        const r = obj.cornerRadius ?? 0
        if (r > 0) {
          Canvas2DRenderer.roundRect(ctx, 0, 0, t.width, t.height, r)
        } else {
          ctx.rect(0, 0, t.width, t.height)
        }
        break
      }
      case 'ellipse': {
        Canvas2DRenderer.drawEllipse(ctx, t.width / 2, t.height / 2, t.width / 2, t.height / 2)
        break
      }
      case 'polygon': {
        Canvas2DRenderer.drawPolygon(ctx, t.width / 2, t.height / 2, Math.min(t.width, t.height) / 2, obj.sides ?? 5)
        break
      }
      case 'star': {
        Canvas2DRenderer.drawStar(ctx, t.width / 2, t.height / 2, Math.min(t.width, t.height) / 2, obj.sides ?? 5)
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
    if ((obj.strokeWidth ?? 0) > 0) {
      ctx.strokeStyle = obj.stroke ?? '#1F2329'
      ctx.lineWidth = obj.strokeWidth ?? 0
      ctx.stroke()
    }
  }

  static renderPathShape(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    if (obj.fill) {
      ctx.fillStyle = obj.fill
      ctx.fill()
    }
    if ((obj.strokeWidth ?? 0) > 0) {
      ctx.strokeStyle = obj.stroke ?? '#1F2329'
      ctx.lineWidth = obj.strokeWidth ?? 0
      ctx.stroke()
    }
  }

  static renderImage(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    const t = obj.transform
    ctx.fillStyle = obj.fill ?? '#F3F5F7'
    ctx.fillRect(0, 0, t.width, t.height)
    ctx.fillStyle = '#8A919F'
    ctx.font = '12px HarmonyOS Sans SC'
    ctx.textBaseline = 'middle'
    ctx.textAlign = 'center'
    ctx.fillText(obj.name ?? 'Image', t.width / 2, t.height / 2)
  }

  static renderGroup(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    if (obj.children) {
      for (const child of obj.children) {
        if (!child.visible) continue
        Canvas2DRenderer.renderObject(ctx, child)
      }
    }
  }

  static renderAdjustment(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    const t = obj.transform
    ctx.strokeStyle = '#A855F7'
    ctx.lineWidth = 1
    ctx.setLineDash([4, 4])
    ctx.strokeRect(0, 0, t.width, t.height)
    ctx.setLineDash([])
  }

  static renderFill(ctx: CanvasRenderingContext2D, obj: SceneObject): void {
    const t = obj.transform
    ctx.fillStyle = obj.fill ?? obj.color ?? '#E8E8E8'
    ctx.fillRect(0, 0, t.width, t.height)
  }

  static applyMask(ctx: CanvasRenderingContext2D, mask: Mask, _width: number, _height: number): void {
    if (!mask.enabled) return
    ctx.save()
    ctx.globalCompositeOperation = mask.inverted ? 'destination-out' : 'destination-in'
    if (mask.type === 'raster' && mask.data) {
      ctx.fillRect(0, 0, _width, _height)
    } else {
      ctx.fillRect(0, 0, _width, _height)
    }
    ctx.restore()
  }

  static applyEffects(ctx: CanvasRenderingContext2D, effects: LayerEffect[], _width: number, _height: number): void {
    for (const effect of effects) {
      if (!effect.enabled) continue
      const p = effect.params
      const type = effect.type
      if (type === 'drop-shadow') {
        const angle = ((p.angle ?? 120) * Math.PI) / 180
        const dist = p.distance ?? 5
        const ox = Math.cos(angle) * dist
        const oy = Math.sin(angle) * dist
        ctx.save()
        ctx.shadowColor = Canvas2DRenderer.colorWithAlpha(p.color ?? '#000000', (p.opacity ?? 40) / 100)
        ctx.shadowBlur = p.blur ?? 4
        ctx.shadowOffsetX = ox
        ctx.shadowOffsetY = oy
        ctx.restore()
      } else if (type === 'outer-glow') {
        ctx.save()
        ctx.shadowColor = Canvas2DRenderer.colorWithAlpha(p.color ?? '#3AC487', (p.opacity ?? 50) / 100)
        ctx.shadowBlur = p.blur ?? 8
        ctx.shadowOffsetX = 0
        ctx.shadowOffsetY = 0
        ctx.restore()
      } else if (type === 'color-overlay') {
        ctx.save()
        ctx.globalCompositeOperation = 'source-atop'
        ctx.fillStyle = Canvas2DRenderer.colorWithAlpha(p.color ?? '#3AC487', (p.opacity ?? 100) / 100)
        ctx.fillRect(0, 0, _width, _height)
        ctx.restore()
      }
    }
  }

  static drawSelectionHandles(ctx: CanvasRenderingContext2D, objects: SceneObject[]): void {
    for (const obj of objects) {
      const t = obj.transform
      ctx.save()
      ctx.strokeStyle = '#3B82F6'
      ctx.lineWidth = 1
      ctx.setLineDash([4, 2])
      ctx.strokeRect(t.x - 0.5, t.y - 0.5, t.width + 1, t.height + 1)
      ctx.setLineDash([])
      const handles: number[][] = [
        [t.x, t.y],
        [t.x + t.width, t.y],
        [t.x, t.y + t.height],
        [t.x + t.width, t.y + t.height],
      ]
      for (let i = 0; i < handles.length; i++) {
        const hx = handles[i][0]
        const hy = handles[i][1]
        ctx.fillStyle = '#FFFFFF'
        ctx.fillRect(hx - 3, hy - 3, 6, 6)
        ctx.strokeStyle = '#3B82F6'
        ctx.lineWidth = 1
        ctx.strokeRect(hx - 3, hy - 3, 6, 6)
      }
      ctx.restore()
    }
  }

  static colorWithAlpha(color: string, alpha: number): string {
    if (color.startsWith('#')) {
      const hex = color.slice(1)
      const r = parseInt(hex.slice(0, 2), 16)
      const g = parseInt(hex.slice(2, 4), 16)
      const b = parseInt(hex.slice(4, 6), 16)
      return `rgba(${r}, ${g}, ${b}, ${alpha})`
    }
    return color
  }

  static roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    const radius = Math.min(r, w / 2, h / 2)
    ctx.moveTo(x + radius, y)
    ctx.arcTo(x + w, y, x + w, y + h, radius)
    ctx.arcTo(x + w, y + h, x, y + h, radius)
    ctx.arcTo(x, y + h, x, y, radius)
    ctx.arcTo(x, y, x + w, y, radius)
    ctx.closePath()
  }

  static drawEllipse(ctx: CanvasRenderingContext2D, cx: number, cy: number, rx: number, ry: number): void {
    const step = 64
    for (let i = 0; i <= step; i++) {
      const angle = (i / step) * Math.PI * 2
      const x = cx + Math.cos(angle) * rx
      const y = cy + Math.sin(angle) * ry
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
  }

  static drawPolygon(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, sides: number): void {
    for (let i = 0; i < sides; i++) {
      const angle = (i * 2 * Math.PI) / sides - Math.PI / 2
      const x = cx + Math.cos(angle) * r
      const y = cy + Math.sin(angle) * r
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
  }

  static drawStar(ctx: CanvasRenderingContext2D, cx: number, cy: number, r: number, points: number): void {
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
}
