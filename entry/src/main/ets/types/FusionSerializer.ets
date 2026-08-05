/**
 * FusionSerializer - 文档序列化器
 *
 * 对应原型 src/fusion/serializer.ts
 * 实现 HDS 文档的序列化（toJSON）与反序列化（fromJSON）。
 * 同时提供深拷贝、版本兼容与基本校验。
 * 
 * ArkTS 适配：使用 JsonObj 替代 Record<string, object | undefined>
 * 使 as string / as number 等类型转换合法。
 */
import {
  HdsDocument, Scene, Layer, Page, SceneObject, GroupObject,
  Transform, DocumentMetadata, FrameType, ShapeKind, BlendMode,
  ColorSpace, Unit, NodeType, BaseNode, Frame, LayerEffect,
  Mask, Gradient, InfiniteCanvasConfig
} from '../types/SceneTypes'

export const HDS_FORMAT_VERSION = '3.0'

/** JsonObj 包含所有 JSON 基本类型，使 as 类型转换合法 */
type JsonObj = Record<string, string | number | boolean | object | undefined>

/** 深拷贝 */
export function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as object as T
}

/** 将文档序列化为 JSON 字符串 */
export function serialize(doc: HdsDocument, pretty: boolean = false): string {
  return JSON.stringify(doc, null, pretty ? 2 : 0)
}

/** 从 JSON 字符串反序列化为文档 */
export function deserialize(json: string): HdsDocument {
  const data = JSON.parse(json) as object
  return normalizeDocument(data)
}

/** 规范化文档（确保字段完整，兼容旧版本） */
export function normalizeDocument(data: object): HdsDocument {
  const raw = data as JsonObj
  if (!raw || !raw['scene']) throw new Error('Invalid document: missing scene')

  const doc: HdsDocument = {
    version: (raw['version'] as string) ?? HDS_FORMAT_VERSION,
    scene: normalizeScene(raw['scene'] as object as JsonObj),
    metadata: normalizeMetadata(raw['metadata'] as object as JsonObj),
  }
  return doc
}

/** 规范化元数据 */
function normalizeMetadata(m: JsonObj | undefined): DocumentMetadata {
  const result: DocumentMetadata = {
    createdAt: (m?.['createdAt'] as string) ?? new Date().toISOString(),
    modifiedAt: (m?.['modifiedAt'] as string) ?? new Date().toISOString(),
    author: m?.['author'] as string | undefined,
    description: m?.['description'] as string | undefined,
    tags: m?.['tags'] as object as string[] | undefined,
    thumbnail: m?.['thumbnail'] as string | undefined,
    fonts: m?.['fonts'] as object as string[] | undefined,
    swatches: m?.['swatches'] as object as string[] | undefined,
  }
  return result
}

/** 规范化 Scene */
function normalizeScene(s: JsonObj | undefined): Scene {
  if (!s) throw new Error('Invalid scene')
  const base = getBaseNode(s, 'scene', 'Untitled.hds')
  let pages: Page[] = []
  if (s['pages']) {
    pages = (s['pages'] as object as Page[]).slice()
    for (let i = 0; i < pages.length; i++) {
      pages[i] = normalizePage(pages[i] as object as JsonObj, i)
    }
  }
  let children: Layer[] = []
  if (s['children']) {
    children = (s['children'] as object as Layer[]).slice()
    for (let i = 0; i < children.length; i++) {
      children[i] = normalizeLayer(children[i] as object as JsonObj, i)
    }
  }
  const result: Scene = {
    id: base.id,
    type: base.type,
    name: base.name,
    transform: base.transform,
    blendMode: base.blendMode,
    visible: base.visible,
    locked: base.locked,
    children: pages && pages.length > 0 ? [] : children,
    pages: pages,
    currentPageId: pages && pages.length > 0 ? ((s['currentPageId'] as string) ?? pages[0].id) : undefined,
    frames: s['frames'] as object as Frame[] | undefined,
    selectedFrameId: s['selectedFrameId'] as string | undefined,
    canvas: s['canvas'] as object as InfiniteCanvasConfig | undefined,
    canvasWidth: (s['canvasWidth'] as number) ?? 595,
    canvasHeight: (s['canvasHeight'] as number) ?? 842,
    unit: (s['unit'] as Unit) ?? 'px',
    dpi: (s['dpi'] as number) ?? 72,
    colorSpace: (s['colorSpace'] as ColorSpace) ?? 'sRGB',
    background: (s['background'] as string) ?? '#FFFFFF',
  }
  return result
}

/** 规范化 Page */
function normalizePage(p: JsonObj, index: number): Page {
  let children: Layer[] = []
  if (p['children']) {
    children = (p['children'] as object as Layer[]).slice()
    for (let i = 0; i < children.length; i++) {
      children[i] = normalizeLayer(children[i] as object as JsonObj, i)
    }
  }
  const result: Page = {
    id: (p['id'] as string) ?? `page_${index}`,
    name: (p['name'] as string) ?? `Page ${index + 1}`,
    width: p['width'] as number | undefined,
    height: p['height'] as number | undefined,
    background: p['background'] as string | undefined,
    children: children,
    hidden: (p['hidden'] as boolean) ?? false,
    createdAt: (p['createdAt'] as string) ?? new Date().toISOString(),
  }
  return result
}

/** 规范化 Layer */
function normalizeLayer(l: JsonObj, index: number): Layer {
  let objects: SceneObject[] = []
  if (l['objects']) {
    objects = (l['objects'] as object as SceneObject[]).slice()
    for (let i = 0; i < objects.length; i++) {
      objects[i] = normalizeObject(objects[i] as object as JsonObj, i)
    }
  }
  const result: Layer = {
    id: (l['id'] as string) ?? `layer_${index}`,
    type: 'layer',
    name: (l['name'] as string) ?? `Layer ${index + 1}`,
    transform: normalizeTransform(l['transform'] as object as JsonObj),
    blendMode: (l['blendMode'] as string) as BlendMode ?? 'pass-through',
    visible: (l['visible'] as boolean) ?? true,
    locked: (l['locked'] as boolean) ?? false,
    parentId: (l['parentId'] as string) ?? 'scene_root',
    objects: objects,
    hasMask: (l['hasMask'] as boolean) ?? false,
    maskEnabled: (l['maskEnabled'] as boolean) ?? false,
    mask: l['mask'] as object as Mask | undefined,
    effects: (l['effects'] as object as LayerEffect[] | undefined) ?? [],
  }
  return result
}

/** 标准化 Transform */
function normalizeTransform(t: JsonObj | undefined): Transform {
  const result: Transform = {
    x: (t?.['x'] as number) ?? 0,
    y: (t?.['y'] as number) ?? 0,
    width: (t?.['width'] as number) ?? 100,
    height: (t?.['height'] as number) ?? 100,
    rotation: (t?.['rotation'] as number) ?? 0,
    scaleX: (t?.['scaleX'] as number) ?? 1,
    scaleY: (t?.['scaleY'] as number) ?? 1,
    flipH: (t?.['flipH'] as boolean) ?? false,
    flipV: (t?.['flipV'] as boolean) ?? false,
    opacity: (t?.['opacity'] as number) ?? 100,
  }
  return result
}

/** 获取基础节点字段 */
function getBaseNode(s: JsonObj, type: string, name: string): BaseNode {
  const result: BaseNode = {
    id: (s['id'] as string) ?? `${type}_root`,
    type: type as NodeType,
    name: (s['name'] as string) ?? name,
    transform: normalizeTransform(s['transform'] as object as JsonObj),
    blendMode: (s['blendMode'] as string) as BlendMode ?? 'pass-through',
    visible: (s['visible'] as boolean) ?? true,
    locked: (s['locked'] as boolean) ?? false,
  }
  return result
}

/** 规范化 SceneObject */
function normalizeObject(o: JsonObj, index: number): SceneObject {
  if (!o || !o['type']) throw new Error('Invalid object: missing type')
  const objType = o['type'] as string
  const objId = (o['id'] as string) ?? `obj_${index}`
  const objName = (o['name'] as string) ?? objType
  const objTransform = normalizeTransform(o['transform'] as object as JsonObj)
  const objBlendMode = (o['blendMode'] as string) as BlendMode ?? 'normal'
  const objVisible = (o['visible'] as boolean) ?? true
  const objLocked = (o['locked'] as boolean) ?? false

  if (objType === 'group') {
    return {
      id: objId,
      type: objType,
      name: objName,
      transform: objTransform,
      blendMode: objBlendMode,
      visible: objVisible,
      locked: objLocked,
      children: (o['children'] as object as SceneObject[]).slice().map((child: SceneObject, ci: number) =>
        normalizeObject(child as object as JsonObj, ci)
      ),
    } as SceneObject
  }
  return {
    id: objId,
    type: objType,
    name: objName,
    transform: objTransform,
    blendMode: objBlendMode,
    visible: objVisible,
    locked: objLocked,
  } as SceneObject
}

/** 估算文档大小 */
export function estimateSize(doc: HdsDocument): number {
  const json = JSON.stringify(doc)
  return Math.round(json.length / 1024)
}