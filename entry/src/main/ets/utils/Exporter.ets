import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { serialize, estimateSize } from '../types/FusionSerializer'
import { Canvas2DRenderer } from './Canvas2DRenderer'
import { Frame, SceneObject, Layer, HdsDocument } from '../types/SceneTypes'
import image from '@ohos.multimedia.image'
import buffer from '@ohos.buffer'
import { NativeEngine } from '../native/NativeEngine'
import { FilePersistence } from '../platform/FilePersistence'
import { copyBytes, verifyImageStructure, verifyPdfStructure } from '../platform/PersistenceTypes'

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
  path?: string
  checksum?: string
  pages?: number
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

function pdfEscape(value: string): string {
  return value.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)')
}

function utf8Length(text: string): number {
  return buffer.from(text, 'utf-8').length
}

/** 按字节计数的 PDF 输出累积器：xref 偏移必须是 UTF-8 字节偏移，含中文时才不会错位。 */
class PdfByteBuilder {
  private chunks: string[] = []
  byteLength: number = 0

  append(chunk: string): void {
    this.chunks.push(chunk)
    this.byteLength += utf8Length(chunk)
  }

  toBuffer(): ArrayBuffer {
    const encoded = buffer.from(this.chunks.join(''), 'utf-8')
    return copyBytes(new Uint8Array(encoded.buffer, encoded.byteOffset, encoded.length))
  }
}

/** 生成单页、可被标准 PDF 阅读器打开的矢量 PDF；偏移按 UTF-8 字节计算。 */
function buildSimplePdf(frame: Frame | null): ArrayBuffer {
  const width = frame?.width ?? 595
  const height = frame?.height ?? 842
  const commands: string[] = []
  commands.push('q 1 1 1 rg 0 0 ' + width + ' ' + height + ' re f Q')
  if (frame !== null) {
    for (const layer of frame.children) {
      if (!layer.visible) continue
      for (const obj of layer.objects) {
        if (!obj.visible) continue
        const t = obj.transform
        if (obj.type === 'text') {
          const text = pdfEscape(obj.text ?? obj.name)
          commands.push('BT /F1 ' + (obj.fontSize ?? 14) + ' Tf 0 0 0 rg 1 0 0 1 ' + t.x + ' ' + (height - t.y - (obj.fontSize ?? 14)) + ' Tm (' + text + ') Tj ET')
        } else {
          const fill = obj.fill ?? '#3AC487'
          let hex = fill.charAt(0) === '#' ? fill.substring(1) : '3AC487'
          if (hex.length === 8) hex = hex.substring(2)
          const r = parseInt(hex.substring(0, 2), 16) / 255
          const g = parseInt(hex.substring(2, 4), 16) / 255
          const b = parseInt(hex.substring(4, 6), 16) / 255
          commands.push(r.toFixed(4) + ' ' + g.toFixed(4) + ' ' + b.toFixed(4) + ' rg ' + t.x + ' ' + (height - t.y - t.height) + ' ' + t.width + ' ' + t.height + ' re f')
        }
      }
    }
  }
  const content = commands.join('\n') + '\n'
  const objects: string[] = []
  objects.push('<< /Type /Catalog /Pages 2 0 R >>')
  objects.push('<< /Type /Pages /Kids [3 0 R] /Count 1 >>')
  objects.push('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ' + width + ' ' + height + '] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>')
  objects.push('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
  objects.push('<< /Length ' + utf8Length(content) + ' >>\nstream\n' + content + 'endstream')
  const pdf = new PdfByteBuilder()
  pdf.append('%PDF-1.4\n%LarkDesign\n')
  const offsets: number[] = []
  for (let i = 0; i < objects.length; i++) {
    offsets.push(pdf.byteLength)
    pdf.append((i + 1) + ' 0 obj\n' + objects[i] + '\nendobj\n')
  }
  const xref = pdf.byteLength
  pdf.append('xref\n0 ' + (objects.length + 1) + '\n0000000000 65535 f \n')
  for (let i = 1; i < offsets.length; i++) {
    pdf.append(offsets[i].toString().padStart(10, '0') + ' 00000 n \n')
  }
  pdf.append('trailer\n<< /Size ' + (objects.length + 1) + ' /Root 1 0 R >>\nstartxref\n' + xref + '\n%%EOF\n')
  return pdf.toBuffer()
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

  async export(opts: ExportOptions): Promise<ExportResult> {
    const filename = opts.filename ?? this.getDefaultFilename(opts.format)
    const format = opts.format
    try {
      if (format === 'hds' || format === 'json') {
        return await this.exportJson(format, filename)
      }
      if (format === 'png' || format === 'jpeg' || format === 'webp') {
        return await this.exportImage(format, filename, opts.quality ?? 0.92, opts.dpi ?? 72)
      }
      if (format === 'svg') {
        return await this.exportSvg(filename)
      }
      if (format === 'pdf') {
        return await this.exportPdf(filename)
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

  private async exportJson(format: ExportFormat, filename: string): Promise<ExportResult> {
    const doc = this.fusionStore.getDocument()
    const json = serialize(doc, format === 'json')
    const bytes = json.length
    const path = await FilePersistence.writeText(filename, json)
    return {
      ok: true,
      filename,
      format,
      message: '已导出 ' + format.toUpperCase() + '，' + estimateSize(this.fusionStore.getDocument()) + 'KB',
      bytes,
      path,
    }
  }

  private async exportImage(format: 'png' | 'jpeg' | 'webp', filename: string, quality: number, dpi: number): Promise<ExportResult> {
    const frame = this.fusionStore.getCurrentFrame()
    if (!frame) {
      return { ok: false, filename, format, message: '没有可导出的画板' }
    }
    let data: ArrayBuffer | null = null
    if (format === 'png') {
      data = await NativeEngine.renderPng(frame)
    } else {
      const pixelMap = await NativeEngine.renderFrame(frame)
      if (pixelMap !== null) {
        const packer = image.createImagePacker()
        try {
          const mime = format === 'jpeg' ? 'image/jpeg' : 'image/webp'
          data = await packer.packToData(pixelMap, { format: mime, quality: Math.round(quality * 100) })
        } catch (error) {
          console.error('Exporter', 'image encode failed: ' + error)
          data = null
        } finally {
          try {
            await packer.release()
          } catch (error) {
            console.error('Exporter', 'release image packer failed: ' + error)
          }
          try {
            await pixelMap.release()
          } catch (error) {
            console.error('Exporter', 'release pixel map failed: ' + error)
          }
        }
      }
    }
    if (data === null || data.byteLength === 0) {
      return { ok: false, filename, format, message: 'Native 渲染或编码失败' }
    }
    const path = await FilePersistence.writeBytes(filename, data)
    const verification = await FilePersistence.verifyWrittenFile(path, data)
    if (!verification.ok || verification.data === null) {
      return { ok: false, filename, format, message: '导出文件读回校验失败: ' + (verification.reason ?? '未知错误'), path }
    }
    const imageCheck = verifyImageStructure(verification.data, format)
    if (!imageCheck.ok) {
      return { ok: false, filename, format, message: '导出图片格式校验失败: ' + (imageCheck.reason ?? '未知错误'), path }
    }
    return {
      ok: true, filename, format,
      message: '已导出 ' + format.toUpperCase() + '，' + dpi + 'DPI',
      bytes: verification.bytes,
      path,
      checksum: verification.checksum,
    }
  }

  private async exportSvg(filename: string): Promise<ExportResult> {
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
    const path = await FilePersistence.writeText(filename, svg)
    return {
      ok: true, filename, format: 'svg',
      message: '已导出 SVG · ' + layersXml.length + ' 层',
      bytes: svg.length,
      path,
    }
  }

  private async exportPdf(filename: string): Promise<ExportResult> {
    const pdf = buildSimplePdf(this.fusionStore.getCurrentFrame())
    const sourceCheck = verifyPdfStructure(pdf)
    if (!sourceCheck.ok) {
      return { ok: false, filename, format: 'pdf', message: 'PDF 生成校验失败: ' + (sourceCheck.reason ?? '未知错误') }
    }
    const path = await FilePersistence.writeBytes(filename, pdf)
    const verification = await FilePersistence.verifyWrittenFile(path, pdf)
    if (!verification.ok || verification.data === null) {
      return { ok: false, filename, format: 'pdf', message: 'PDF 读回校验失败: ' + (verification.reason ?? '未知错误'), path }
    }
    const pdfCheck = verifyPdfStructure(verification.data)
    if (!pdfCheck.ok) {
      return { ok: false, filename, format: 'pdf', message: 'PDF 结构校验失败: ' + (pdfCheck.reason ?? '未知错误'), path }
    }
    return {
      ok: true, filename, format: 'pdf',
      message: '已导出 PDF，' + pdfCheck.pages + ' 页',
      bytes: verification.bytes,
      path,
      checksum: verification.checksum,
      pages: pdfCheck.pages,
    }
  }

  private exportVectorStub(format: ExportFormat, filename: string): ExportResult {
    return {
      ok: false, filename, format,
      message: format.toUpperCase() + ' 当前未实现，未生成伪文件',
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
