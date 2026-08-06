import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { serialize, estimateSize } from '../types/FusionSerializer'
import { Canvas2DRenderer } from './Canvas2DRenderer'
import { Frame, SceneObject, Layer, HdsDocument } from '../types/SceneTypes'

export type ExportFormat = 'hds' | 'json' | 'png' | 'jpeg' | 'webp' | 'svg' | 'pdf' | 'eps' | 'cdr'

export interface ExportOptions {
  format: ExportFormat
  filename?: string
  quality?: number
  dpi?: number
}

export interface ExportResult {
  ok: boolean
  filename: string
  format: ExportFormat
  message: string
  bytes?: number
}

export interface ExportFormatInfo {
  format: ExportFormat
  label: string
  icon: string
  supported: boolean
}

function extForKey(key: string): string {
  if (key === 'hds') return 'hds'
  if (key === 'json') return 'json'
  if (key === 'png') return 'png'
  if (key === 'jpeg') return 'jpg'
  if (key === 'webp') return 'webp'
  if (key === 'svg') return 'svg'
  if (key === 'pdf') return 'pdf'
  if (key === 'eps') return 'eps'
  if (key === 'cdr') return 'cdr'
  return key
}

function escapeXml(s: string): string {
  let result = s
  result = result.replace(/&/g, '&amp;')
  result = result.replace(/</g, '&lt;')
  result = result.replace(/>/g, '&gt;')
  result = result.replace(/"/g, '&quot;')
  result = result.replace(/'/g, '&apos;')
  return result
}

function objectToSvg(obj: SceneObject): string {
  const t = obj.transform
  const opacity = t.opacity < 100 ? ' opacity="' + (t.opacity / 100).toFixed(3) + '"' : ''
  if (obj.type === 'shape') {
    const fill = obj.fill ?? '#000000'
    let stroke = ''
    if ((obj.strokeWidth ?? 0) > 0) {
      stroke = ' stroke="' + (obj.stroke ?? '#000') + '" stroke-width="' + obj.strokeWidth + '"'
    }
    let corner = ''
    if ((obj.cornerRadius ?? 0) > 0) {
      corner = ' rx="' + obj.cornerRadius + '" ry="' + obj.cornerRadius + '"'
    }
    const rot = t.rotation !== 0 ? ' transform="rotate(' + t.rotation + ' ' + (t.x + t.width / 2) + ' ' + (t.y + t.height / 2) + ')"' : ''
    return '  <rect x="' + t.x + '" y="' + t.y + '" width="' + t.width + '" height="' + t.height + '" fill="' + fill + '"' + stroke + corner + rot + opacity + ' />'
  }
  if (obj.type === 'text') {
    const fontSize = obj.fontSize ?? 14
    const fontWeight = obj.fontWeight ?? 400
    const color = obj.color ?? '#000000'
    const fontFamily = obj.fontFamily ?? 'sans-serif'
    const lines = (obj.text ?? '').split('\n')
    let tspans = ''
    for (let i = 0; i < lines.length; i++) {
      tspans += '    <tspan x="' + t.x + '" y="' + (t.y + (i + 1) * fontSize * 1.4) + '">' + escapeXml(lines[i]) + '</tspan>\n'
    }
    const rot = t.rotation !== 0 ? ' transform="rotate(' + t.rotation + ' ' + t.x + ' ' + t.y + ')"' : ''
    return '  <text font-size="' + fontSize + '" font-weight="' + fontWeight + '" fill="' + color + '" font-family="' + fontFamily + '"' + rot + opacity + '>\n' + tspans + '  </text>'
  }
  if (obj.type === 'image') {
    const href = obj.src ?? ''
    const rot = t.rotation !== 0 ? ' transform="rotate(' + t.rotation + ' ' + (t.x + t.width / 2) + ' ' + (t.y + t.height / 2) + ')"' : ''
    return '  <image x="' + t.x + '" y="' + t.y + '" width="' + t.width + '" height="' + t.height + '" href="' + href + '"' + rot + opacity + ' />'
  }
  return ''
}

function layerToSvg(layer: Layer): string {
  if (!layer.visible) return ''
  const lines: string[] = []
  for (let i = 0; i < layer.objects.length; i++) {
    const obj = layer.objects[i]
    if (obj.visible) {
      const svg = objectToSvg(obj)
      if (svg.length > 0) lines.push(svg)
    }
  }
  if (lines.length === 0) return ''
  const opacity = layer.transform.opacity < 100 ? ' opacity="' + (layer.transform.opacity / 100).toFixed(3) + '"' : ''
  return '  <g name="' + escapeXml(layer.name) + '"' + opacity + '>\n' + lines.join('\n') + '\n  </g>'
}

export class Exporter {
  private static instance: Exporter
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private canvasContext: CanvasRenderingContext2D | null = null

  private constructor() {}

  static getInstance(): Exporter {
    if (!Exporter.instance) {
      Exporter.instance = new Exporter()
    }
    return Exporter.instance
  }

  bindCanvasContext(ctx: CanvasRenderingContext2D): void {
    this.canvasContext = ctx
  }

  private getDefaultFilename(format: ExportFormat): string {
    const doc = this.fusionStore.getDocument()
    const raw = doc.scene.name
    const dotIdx = raw.lastIndexOf('.')
    const baseName = dotIdx >= 0 ? raw.substring(0, dotIdx) : (raw.length > 0 ? raw : 'Untitled')
    const ext = extForKey(format)
    return baseName + '.' + ext
  }

  export(opts: ExportOptions): ExportResult {
    const filename = opts.filename ?? this.getDefaultFilename(opts.format)
    const format = opts.format
    try {
      if (format === 'hds' || format === 'json') {
        return this.exportJson(format, filename)
      }
      if (format === 'png' || format === 'jpeg' || format === 'webp') {
        return this.exportImage(format, filename, opts.quality ?? 0.92, opts.dpi ?? 72)
      }
      if (format === 'svg') {
        return this.exportSvg(filename)
      }
      if (format === 'pdf') {
        return this.exportPdf(filename)
      }
      if (format === 'eps' || format === 'cdr') {
        return this.exportVectorStub(format, filename)
      }
      return { ok: false, filename, format, message: '不支持的格式: ' + format }
    } catch (e) {
      return { ok: false, filename, format, message: '导出失败: ' + e }
    }
  }

  exportCanvasToPixelMap(ctx: CanvasRenderingContext2D, width: number, height: number, dpi: number): PixelMap | null {
    const scale = dpi / 72
    const w = Math.round(width * scale)
    const h = Math.round(height * scale)
    ctx.save()
    ctx.scale(scale, scale)
    const frame = this.fusionStore.getCurrentFrame()
    if (frame) {
      Canvas2DRenderer.renderFrame(ctx, frame, width, height)
    }
    ctx.restore()
    return ctx.getPixelMap(0, 0, w, h)
  }

  private exportJson(format: ExportFormat, filename: string): ExportResult {
    const doc = this.fusionStore.getDocument()
    const json = serialize(doc, format === 'json')
    const bytes = json.length
    AppStorage.setOrCreate<string>('export_data', json)
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', format === 'json' ? 'application/json' : 'application/octet-stream')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true,
      filename,
      format,
      message: '已导出 ' + format.toUpperCase() + '，' + estimateSize(this.fusionStore.getDocument()) + 'KB',
      bytes,
    }
  }

  private exportImage(format: ExportFormat, filename: string, quality: number, dpi: number): ExportResult {
    let mimeType = 'image/png'
    if (format === 'jpeg') mimeType = 'image/jpeg'
    if (format === 'webp') mimeType = 'image/webp'
    const frame = this.fusionStore.getCurrentFrame()
    if (!frame) {
      return { ok: false, filename, format, message: '没有可导出的画板' }
    }
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', mimeType)
    AppStorage.setOrCreate<number>('export_quality', quality)
    AppStorage.setOrCreate<number>('export_dpi', dpi)
    AppStorage.setOrCreate<number>('export_frame_width', frame.width)
    AppStorage.setOrCreate<number>('export_frame_height', frame.height)
    AppStorage.setOrCreate<string>('export_format', format)
    if (this.canvasContext) {
      const pm = this.exportCanvasToPixelMap(this.canvasContext, frame.width, frame.height, dpi)
      if (pm) {
        AppStorage.setOrCreate<object>('export_pixelmap', pm as object)
        AppStorage.setOrCreate<boolean>('export_ready', true)
        return {
          ok: true, filename, format,
          message: '已导出 ' + format.toUpperCase() + '，' + dpi + 'DPI',
          bytes: frame.width * frame.height * 4,
        }
      }
    }
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true, filename, format,
      message: '已准备 ' + format.toUpperCase() + ' 导出，请通过 Canvas API 渲染',
      bytes: 0,
    }
  }

  private exportSvg(filename: string): ExportResult {
    const doc = this.fusionStore.getDocument()
    const w = doc.scene.canvasWidth
    const h = doc.scene.canvasHeight
    const bg = doc.scene.background ?? '#FFFFFF'
    const layersXml: string[] = []
    for (let i = 0; i < doc.scene.children.length; i++) {
      const svg = layerToSvg(doc.scene.children[i])
      if (svg.length > 0) layersXml.push(svg)
    }
    const svg = '<?xml version="1.0" encoding="UTF-8"?>\n' +
      '<svg xmlns="http://www.w3.org/2000/svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '">\n' +
      '  <rect x="0" y="0" width="' + w + '" height="' + h + '" fill="' + bg + '" />\n' +
      layersXml.join('\n') + '\n' +
      '</svg>'
    AppStorage.setOrCreate<string>('export_data', svg)
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', 'image/svg+xml')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true, filename, format: 'svg',
      message: '已导出 SVG · ' + layersXml.length + ' 层',
      bytes: svg.length,
    }
  }

  private exportPdf(filename: string): ExportResult {
    AppStorage.setOrCreate<string>('export_data', '')
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', 'application/pdf')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true, filename, format: 'pdf',
      message: 'PDF 导出请使用系统打印功能',
      bytes: 0,
    }
  }

  private exportVectorStub(format: ExportFormat, filename: string): ExportResult {
    const doc = this.fusionStore.getDocument()
    const json = serialize(doc, true)
    AppStorage.setOrCreate<string>('export_data', json)
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', 'application/json')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true, filename, format,
      message: format.toUpperCase() + ' 格式暂不支持，已导出 JSON 兜底',
      bytes: json.length,
    }
  }
}

export function listExportFormats(): ExportFormatInfo[] {
  const formats: ExportFormatInfo[] = []
  formats.push({ format: 'png', label: 'PNG', icon: 'fa-file-image', supported: true })
  formats.push({ format: 'jpeg', label: 'JPEG', icon: 'fa-file-image', supported: true })
  formats.push({ format: 'webp', label: 'WebP', icon: 'fa-file-image', supported: true })
  formats.push({ format: 'svg', label: 'SVG', icon: 'fa-file-code', supported: true })
  formats.push({ format: 'pdf', label: 'PDF', icon: 'fa-file-pdf', supported: true })
  formats.push({ format: 'eps', label: 'EPS', icon: 'fa-file-lines', supported: false })
  formats.push({ format: 'cdr', label: 'CDR', icon: 'fa-file-lines', supported: false })
  formats.push({ format: 'hds', label: 'HDS', icon: 'fa-file', supported: true })
  return formats
}