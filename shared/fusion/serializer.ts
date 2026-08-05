/**
 * Fusion DOM - 序列化器（跨端共享）
 *
 * 对应原型 src/fusion/serializer.ts
 * 纯算法，无平台依赖，可在鸿蒙/Android/iOS/Web 端共享。
 */
export interface SerializableDocument {
  version: string
  scene: Record<string, unknown>
  metadata: Record<string, unknown>
}

export const HDS_FORMAT_VERSION = '3.0'

/** 深拷贝 */
export function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value))
}

/** 将文档序列化为 JSON 字符串 */
export function serialize(doc: SerializableDocument, pretty = false): string {
  return JSON.stringify(doc, null, pretty ? 2 : 0)
}

/** 从 JSON 字符串反序列化为文档 */
export function deserialize(json: string): SerializableDocument {
  const data = JSON.parse(json)
  return normalizeDocument(data)
}

/** 规范化文档 */
export function normalizeDocument(data: unknown): SerializableDocument {
  if (!data || typeof data !== 'object') throw new Error('Invalid document: not an object')
  const raw = data as Record<string, unknown>
  if (!raw.scene) throw new Error('Invalid document: missing scene')
  return {
    version: (raw.version as string) ?? HDS_FORMAT_VERSION,
    scene: normalizeScene(raw.scene as Record<string, unknown>),
    metadata: {
      createdAt: (raw.metadata as Record<string, unknown>)?.['createdAt'] ?? new Date().toISOString(),
      modifiedAt: (raw.metadata as Record<string, unknown>)?.['modifiedAt'] ?? new Date().toISOString(),
    },
  }
}

function normalizeScene(s: Record<string, unknown>): Record<string, unknown> {
  return {
    id: s.id ?? 'scene_root',
    name: s.name ?? 'Untitled.hds',
    canvasWidth: s.canvasWidth ?? 595,
    canvasHeight: s.canvasHeight ?? 842,
    unit: s.unit ?? 'mm',
    dpi: s.dpi ?? 300,
    colorSpace: s.colorSpace ?? 'sRGB',
    background: s.background ?? '#FFFFFF',
    children: Array.isArray(s.children) ? s.children.map((l: unknown) => normalizeLayer(l as Record<string, unknown>)) : [],
    frames: s.frames ?? [],
    selectedFrameId: s.selectedFrameId ?? '',
  }
}

function normalizeLayer(l: Record<string, unknown>): Record<string, unknown> {
  return {
    id: l.id ?? 'layer',
    name: l.name ?? 'Layer',
    visible: l.visible ?? true,
    locked: l.locked ?? false,
    objects: Array.isArray(l.objects) ? l.objects : [],
  }
}

/** 估算文档大小（KB） */
export function estimateSize(json: string): number {
  return Math.round(json.length / 1024)
}

