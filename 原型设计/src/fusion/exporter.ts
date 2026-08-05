/**
 * Fusion DOM 导出引擎
 *
 * 支持以下格式：
 *  - PNG / JPEG / WebP：从 Canvas 元素 toDataURL 导出
 *  - SVG：把 Fusion DOM 转换为 SVG 元素
 *  - PDF：通过 window.print 触发浏览器打印对话框（用户选另存为 PDF）
 *  - EPS / CDR：演示阶段，导出 JSON 兜底
 *  - HDS：使用 fusion serializer 序列化文档
 *
 * 原型阶段为简化实现，PNG/JPEG/WebP 从 DOM 中查询 CanvasStage 渲染的
 * <canvas> 元素直接 toDataURL。后续可改为从 CanvasRenderer 注入。
 */
import type { HdsDocument, Layer, SceneObject } from '../types'
import { serialize, downloadHdsFile } from './serializer'

export type ExportFormat = 'png' | 'jpeg' | 'webp' | 'svg' | 'pdf' | 'eps' | 'cdr' | 'hds'

export interface ExportOptions {
  format: ExportFormat
  /** 缩放倍率（默认 1，对应画布原始尺寸） */
  scale?: number
  /** JPEG 质量 0-1（默认 0.92） */
  quality?: number
  /** 文件名（不带扩展名） */
  filename?: string
}

export interface ExportResult {
  ok: boolean
  filename: string
  format: ExportFormat
  message: string
  bytes?: number
}

const MIME_MAP: Record<'png' | 'jpeg' | 'webp', string> = {
  png: 'image/png',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
}

const EXT_MAP: Record<ExportFormat, string> = {
  png: 'png',
  jpeg: 'jpg',
  webp: 'webp',
  svg: 'svg',
  pdf: 'pdf',
  eps: 'eps',
  cdr: 'cdr',
  hds: 'hds',
}

/** 触发文件下载 */
function triggerDownload(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}

/** 触发 dataURL 下载 */
function triggerDataUrlDownload(dataUrl: string, filename: string): void {
  const a = document.createElement('a')
  a.href = dataUrl
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
}

/** 从 DOM 中查找 CanvasStage 渲染的 canvas */
function findCanvasElement(): HTMLCanvasElement | null {
  // CanvasStage.vue 渲染的 canvas 是 .stage canvas，取第一个
  return document.querySelector<HTMLCanvasElement>('canvas.block, main canvas, .stage canvas, body canvas')
}

/** 导出 PNG/JPEG/WebP */
async function exportRasterImage(
  format: 'png' | 'jpeg' | 'webp',
  filename: string,
  quality?: number,
): Promise<ExportResult> {
  const canvas = findCanvasElement()
  if (!canvas) {
    return { ok: false, filename, format, message: '未找到画布元素' }
  }
  try {
    const mime = MIME_MAP[format]
    const dataUrl = canvas.toDataURL(mime, quality ?? 0.92)
    triggerDataUrlDownload(dataUrl, `${filename}.${EXT_MAP[format]}`)
    // 估算字节数：base64 长度 * 0.75
    const bytes = Math.round((dataUrl.length - 22) * 0.75)
    return {
      ok: true,
      filename,
      format,
      message: `已导出 ${format.toUpperCase()} · ${(bytes / 1024).toFixed(1)} KB`,
      bytes,
    }
  } catch (err) {
    return { ok: false, filename, format, message: `导出失败：${(err as Error).message}` }
  }
}

/** 把单个对象转换为 SVG 元素字符串 */
function objectToSvg(obj: SceneObject): string {
  const t = obj.transform
  const opacity = t.opacity < 100 ? ` opacity="${(t.opacity / 100).toFixed(3)}"` : ''
  switch (obj.type) {
    case 'shape': {
      const fill = obj.fill ?? '#000000'
      const stroke = obj.strokeWidth ? ` stroke="${obj.stroke ?? '#000'}" stroke-width="${obj.strokeWidth}"` : ''
      const corner = obj.cornerRadius ? ` rx="${obj.cornerRadius}" ry="${obj.cornerRadius}"` : ''
      return `  <rect x="${t.x}" y="${t.y}" width="${t.width}" height="${t.height}" fill="${fill}"${stroke}${corner}${opacity} />`
    }
    case 'text': {
      const fontSize = obj.fontSize ?? 14
      const fontWeight = obj.fontWeight ?? 400
      const color = obj.color ?? '#000000'
      const fontFamily = obj.fontFamily ?? 'sans-serif'
      const lines = String(obj.text ?? '').split('\n').map((line, i) => {
        return `    <tspan x="${t.x}" y="${t.y + i * fontSize * (obj.lineHeight ?? 1.4)}">${escapeXml(line)}</tspan>`
      })
      return `  <text font-size="${fontSize}" font-weight="${fontWeight}" fill="${color}" font-family="${fontFamily}"${opacity}>${lines.join('')}</text>`
    }
    case 'image': {
      const href = obj.src ?? ''
      return `  <image x="${t.x}" y="${t.y}" width="${t.width}" height="${t.height}" href="${href}"${opacity} />`
    }
    default:
      return ''
  }
}

/** XML 转义 */
function escapeXml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

/** 把整层转换为 SVG 元素 */
function layerToSvg(layer: Layer): string {
  if (!layer.visible) return ''
  const objects = layer.objects
    .filter(o => o.visible)
    .map(objectToSvg)
    .filter(Boolean)
    .join('\n')
  if (!objects) return ''
  const opacity = layer.transform.opacity < 100 ? ` opacity="${(layer.transform.opacity / 100).toFixed(3)}"` : ''
  return `  <g name="${escapeXml(layer.name)}"${opacity}>\n${objects}\n  </g>`
}

/** 导出 SVG */
function exportSvg(doc: HdsDocument, filename: string): ExportResult {
  const w = doc.scene.canvasWidth
  const h = doc.scene.canvasHeight
  const bg = doc.scene.background ?? '#FFFFFF'
  const layersXml = doc.scene.children.map(layerToSvg).filter(Boolean).join('\n')
  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">
  <rect x="0" y="0" width="${w}" height="${h}" fill="${bg}" />
${layersXml}
</svg>
`
  const blob = new Blob([svg], { type: 'image/svg+xml' })
  triggerDownload(blob, `${filename}.svg`)
  return {
    ok: true,
    filename,
    format: 'svg',
    message: `已导出 SVG · ${layersXml.split('\n').length} 行 · ${(blob.size / 1024).toFixed(1)} KB`,
    bytes: blob.size,
  }
}

/** 导出 HDS */
function exportHds(doc: HdsDocument, filename: string): ExportResult {
  try {
    downloadHdsFile(doc, filename)
    const json = serialize(doc, false)
    return {
      ok: true,
      filename,
      format: 'hds',
      message: `已导出 HDS · ${(json.length / 1024).toFixed(1)} KB`,
      bytes: json.length,
    }
  } catch (err) {
    return { ok: false, filename, format: 'hds', message: `导出失败：${(err as Error).message}` }
  }
}

/** 导出 PDF（通过浏览器打印） */
function exportPdf(filename: string): ExportResult {
  // 原型阶段：通过 window.print() 触发浏览器打印对话框
  // 用户可选择"另存为 PDF"
  setTimeout(() => window.print(), 100)
  return {
    ok: true,
    filename,
    format: 'pdf',
    message: '已触发浏览器打印（请在对话框中选择"另存为 PDF"）',
  }
}

/** 导出 EPS / CDR（演示阶段，导出 JSON 兜底） */
function exportVectorStub(
  doc: HdsDocument,
  format: 'eps' | 'cdr',
  filename: string,
): ExportResult {
  const json = serialize(doc, true)
  const blob = new Blob([json], { type: 'application/json' })
  triggerDownload(blob, `${filename}.json`)
  return {
    ok: true,
    filename,
    format,
    message: `${format.toUpperCase()} 格式暂不支持，已导出 HDS JSON 兜底 · ${(json.length / 1024).toFixed(1)} KB`,
    bytes: json.length,
  }
}

/** 统一导出入口 */
export async function exportDocument(doc: HdsDocument, opts: ExportOptions): Promise<ExportResult> {
  const filename = (opts.filename ?? doc.scene.name.replace(/\.hds$/, '')) || '未命名'
  const format = opts.format

  switch (format) {
    case 'png':
      return exportRasterImage('png', filename)
    case 'jpeg':
      return exportRasterImage('jpeg', filename, opts.quality)
    case 'webp':
      return exportRasterImage('webp', filename, opts.quality)
    case 'svg':
      return exportSvg(doc, filename)
    case 'pdf':
      return exportPdf(filename)
    case 'eps':
      return exportVectorStub(doc, 'eps', filename)
    case 'cdr':
      return exportVectorStub(doc, 'cdr', filename)
    case 'hds':
      return exportHds(doc, filename)
    default:
      return { ok: false, filename, format, message: `不支持的导出格式：${format}` }
  }
}

/** 获取所有可用格式 */
export function listExportFormats(): Array<{ format: ExportFormat; label: string; icon: string; supported: boolean }> {
  return [
    { format: 'png', label: 'PNG', icon: 'fa-file-image', supported: true },
    { format: 'jpeg', label: 'JPEG', icon: 'fa-file-image', supported: true },
    { format: 'webp', label: 'WebP', icon: 'fa-file-image', supported: true },
    { format: 'svg', label: 'SVG', icon: 'fa-file-code', supported: true },
    { format: 'pdf', label: 'PDF', icon: 'fa-file-pdf', supported: true },
    { format: 'eps', label: 'EPS', icon: 'fa-file-lines', supported: false },
    { format: 'cdr', label: 'CDR', icon: 'fa-file-lines', supported: false },
    { format: 'hds', label: 'HDS', icon: 'fa-file', supported: true },
  ]
}
