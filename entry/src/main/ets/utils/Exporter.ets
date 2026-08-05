/**
 * Exporter - 文档导出引擎
 *
 * 对应原型 src/fusion/exporter.ts
 * 支持格式：
 *  - HDS: 使用 FusionSerializer 序列化文档
 *  - JSON: 导出为可读 JSON
 *  - PNG/JPEG/SVG: 通过 Canvas API 导出（需 Canvas 渲染上下文）
 */
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { serialize, estimateSize } from '../types/FusionSerializer'

export type ExportFormat = 'hds' | 'json' | 'png' | 'jpeg' | 'svg'

export interface ExportOptions {
  format: ExportFormat
  filename?: string
  quality?: number  // JPEG quality 0-1
}

export interface ExportResult {
  ok: boolean
  filename: string
  format: ExportFormat
  message: string
  bytes?: number
}

const EXT_MAP: Record<ExportFormat, string> = {
  hds: 'hds',
  json: 'json',
  png: 'png',
  jpeg: 'jpg',
  svg: 'svg',
}

export class Exporter {
  private static instance: Exporter
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()

  private constructor() {}

  static getInstance(): Exporter {
    if (!Exporter.instance) {
      Exporter.instance = new Exporter()
    }
    return Exporter.instance
  }

  /** 生成默认文件名 */
  private getDefaultFilename(format: ExportFormat): string {
    const doc = this.fusionStore.getDocument()
    const baseName = doc.scene.name.replace(/\.[^.]+$/, '') || 'Untitled'
    const ext = EXT_MAP[format] ?? format
    return `${baseName}.${ext}`
  }

  /** 导出文档 */
  export(opts: ExportOptions): ExportResult {
    const filename = opts.filename ?? this.getDefaultFilename(opts.format)
    const format = opts.format

    try {
      switch (format) {
        case 'hds':
        case 'json':
          return this.exportJson(format, filename)
        case 'png':
        case 'jpeg':
          return this.exportImage(format, filename, opts.quality ?? 0.92)
        case 'svg':
          return this.exportSvg(filename)
        default:
          return { ok: false, filename, format, message: `不支持的格式: ${format}` }
      }
    } catch (e) {
      return { ok: false, filename, format, message: `导出失败: ${e}` }
    }
  }

  /** 导出为 JSON/HDS */
  private exportJson(format: ExportFormat, filename: string): ExportResult {
    const doc = this.fusionStore.getDocument()
    const json = serialize(doc, format === 'json')
    const bytes = json.length
    // 保存到 AppStorage 供外部读取
    AppStorage.setOrCreate<string>('export_data', json)
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', format === 'json' ? 'application/json' : 'application/octet-stream')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true,
      filename,
      format,
      message: `已导出 ${format.toUpperCase()}，${estimateSize(this.fusionStore.getDocument())}KB`,
      bytes,
    }
  }

  /** 导出为图片（占位，需 Canvas 渲染上下文） */
  private exportImage(format: ExportFormat, filename: string, quality: number): ExportResult {
    const mimeType = format === 'png' ? 'image/png' : 'image/jpeg'
    // 在鸿蒙中，实际导出需要通过 Canvas API 的 getPixelMap 或 toDataURL
    // 这里提供占位实现，保存导出参数到 AppStorage
    AppStorage.setOrCreate<string>('export_data', '')
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', mimeType)
    AppStorage.setOrCreate<number>('export_quality', quality)
    AppStorage.setOrCreate<string>('export_format', format)
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true,
      filename,
      format,
      message: `已准备 ${format.toUpperCase()} 导出，请通过 Canvas API 渲染`,
      bytes: 0,
    }
  }

  /** 导出为 SVG（占位） */
  private exportSvg(filename: string): ExportResult {
    AppStorage.setOrCreate<string>('export_data', '<svg xmlns="http://www.w3.org/2000/svg"></svg>')
    AppStorage.setOrCreate<string>('export_filename', filename)
    AppStorage.setOrCreate<string>('export_mime', 'image/svg+xml')
    AppStorage.setOrCreate<boolean>('export_ready', true)
    return {
      ok: true,
      filename,
      format: 'svg',
      message: '已准备 SVG 导出',
      bytes: 0,
    }
  }
}
