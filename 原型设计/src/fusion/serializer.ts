/**
 * Fusion DOM - 序列化器
 *
 * 实现 HDS 文档的序列化（toJSON）与反序列化（fromJSON）。
 * 同时提供深拷贝、版本兼容与基本校验。
 */
import type { HdsDocument, Scene, Layer, Page, SceneObject, GroupObject } from '../types'

export const HDS_FORMAT_VERSION = '3.0'

/** 深拷贝（结构化克隆，回退到 JSON 方案以兼容非可克隆字段） */
export function deepClone<T>(value: T): T {
  if (typeof structuredClone === 'function') {
    try {
      return structuredClone(value)
    } catch {
      // 部分场景下 value 包含不可克隆字段（如函数、Symbol、DOM 节点），
      // 退回到 JSON 序列化方案（牺牲函数字段但保证可序列化数据完整）
    }
  }
  return JSON.parse(JSON.stringify(value))
}

/** 将文档序列化为 JSON 字符串 */
export function serialize(doc: HdsDocument, pretty = false): string {
  return JSON.stringify(doc, null, pretty ? 2 : 0)
}

/** 从 JSON 字符串反序列化为文档 */
export function deserialize(json: string): HdsDocument {
  const data = JSON.parse(json)
  return normalizeDocument(data)
}

/** 规范化文档（确保字段完整，兼容旧版本） */
export function normalizeDocument(data: unknown): HdsDocument {
  if (!data || typeof data !== 'object') throw new Error('Invalid document: not an object')
  const raw = data as Partial<HdsDocument>
  if (!raw.scene) throw new Error('Invalid document: missing scene')

  return {
    version: raw.version ?? HDS_FORMAT_VERSION,
    scene: normalizeScene(raw.scene),
    metadata: {
      createdAt: raw.metadata?.createdAt ?? new Date().toISOString(),
      modifiedAt: raw.metadata?.modifiedAt ?? new Date().toISOString(),
      author: raw.metadata?.author,
      description: raw.metadata?.description,
      tags: raw.metadata?.tags,
      thumbnail: raw.metadata?.thumbnail,
      fonts: raw.metadata?.fonts,
      swatches: raw.metadata?.swatches,
    },
  }
}

/** 规范化 Scene */
function normalizeScene(s: Partial<Scene> | undefined): Scene {
  if (!s) throw new Error('Invalid scene')
  const children = (s.children ?? []).map(normalizeLayer)
  // 规范化 pages（多页面模式）
  let pages: Page[] | undefined
  if (s.pages && s.pages.length > 0) {
    pages = s.pages.map(normalizePage)
  }
  return {
    id: s.id ?? 'scene_root',
    type: 'scene',
    name: s.name ?? 'Untitled.hds',
    transform: s.transform ?? { x: 0, y: 0, width: 595, height: 842, rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100 },
    blendMode: s.blendMode ?? 'pass-through',
    visible: s.visible ?? true,
    locked: s.locked ?? false,
    // 多页面模式下 children 留空（仅 pages 生效）；单页面模式回退到 children
    children: pages && pages.length > 0 ? [] : children,
    pages,
    currentPageId: pages && pages.length > 0 ? (s.currentPageId ?? pages[0].id) : undefined,
    canvasWidth: s.canvasWidth ?? 595,
    canvasHeight: s.canvasHeight ?? 842,
    unit: s.unit ?? 'mm',
    dpi: s.dpi ?? 300,
    colorSpace: s.colorSpace ?? 'sRGB',
    bleed: s.bleed,
    background: s.background ?? '#FFFFFF',
  }
}

/** 规范化 Page（多页面模式） */
function normalizePage(p: Partial<Page> | undefined, index = 0): Page {
  if (!p) throw new Error('Invalid page')
  return {
    id: p.id ?? `page_${index}`,
    name: p.name ?? `Page ${index + 1}`,
    width: p.width,
    height: p.height,
    background: p.background,
    children: (p.children ?? []).map(normalizeLayer),
    hidden: p.hidden ?? false,
    thumbnail: p.thumbnail,
    createdAt: p.createdAt ?? new Date().toISOString(),
  }
}

/** 规范化 Layer */
function normalizeLayer(l: Partial<Layer> | undefined, index = 0): Layer {
  if (!l) throw new Error('Invalid layer')
  return {
    id: l.id ?? `layer_${index}`,
    type: 'layer',
    name: l.name ?? `Layer ${index + 1}`,
    transform: l.transform ?? { x: 0, y: 0, width: 100, height: 100, rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100 },
    blendMode: l.blendMode ?? 'pass-through',
    visible: l.visible ?? true,
    locked: l.locked ?? false,
    parentId: l.parentId ?? 'scene_root',
    objects: (l.objects ?? []).map(normalizeObject),
    hasMask: l.hasMask ?? false,
    maskEnabled: l.maskEnabled ?? false,
    mask: l.mask,
    effects: l.effects ?? [],
  }
}

/** 规范化 SceneObject（递归处理 Group） */
function normalizeObject(o: Partial<SceneObject> | undefined, index = 0): SceneObject {
  if (!o || !o.type) throw new Error('Invalid object: missing type')
  const base = {
    id: o.id ?? `obj_${index}`,
    type: o.type,
    name: o.name ?? o.type,
    transform: o.transform ?? { x: 0, y: 0, width: 100, height: 100, rotation: 0, scaleX: 1, scaleY: 1, flipH: false, flipV: false, opacity: 100 },
    blendMode: o.blendMode ?? 'normal',
    visible: o.visible ?? true,
    locked: o.locked ?? false,
  }
  switch (o.type) {
    case 'text':
      return { ...base, ...o } as SceneObject
    case 'image':
      return { ...base, ...o } as SceneObject
    case 'shape':
      return { ...base, ...o } as SceneObject
    case 'group': {
      const g = o as Partial<GroupObject>
      return { ...base, children: (g.children ?? []).map(normalizeObject) } as GroupObject
    }
    case 'adjustment':
      return { ...base, ...o } as SceneObject
    case 'fill':
      return { ...base, ...o } as SceneObject
    default:
      throw new Error(`Unknown object type: ${(o as { type: string }).type}`)
  }
}

/** 触发下载（用于本地保存 .hds 文件） */
export function downloadHdsFile(doc: HdsDocument, filename?: string): void {
  const json = serialize(doc, true)
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename ?? doc.scene.name
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

/** 估算文档大小（KB） */
export function estimateSize(doc: HdsDocument): number {
  const json = serialize(doc)
  return Math.round(json.length / 1024)
}
