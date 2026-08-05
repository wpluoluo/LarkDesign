/**
 * Fusion DOM - 节点工厂（跨端共享）
 *
 * 对应原型 src/fusion/factory.ts
 * 适配 ArkTS：移除联合类型、Partial<T>、as 类型断言等不支持语法。
 * 使用显式可选参数对象代替 Partial。
 */
import {
  BlendMode, Transform, BaseNode, LayerEffect, Mask, Gradient,
  Scene, Layer, Page, Frame, FrameType, InfiniteCanvasConfig,
  SceneObject, TextObject, ImageObject, ShapeObject, GroupObject,
  AdjustmentObject, FillObject, Unit, ColorSpace, ShapeKind,
} from '../types/scene'

/** 通用创建参数 */
export interface CreateNodeParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
}

/** 简易 ID 生成器 */
let __idCounter = 0
export function genId(prefix: string = 'node'): string {
  __idCounter += 1
  return `${prefix}_${Date.now().toString(36)}_${__idCounter.toString(36)}`
}

/** 默认变换 */
export function defaultTransform(
  x?: number, y?: number, width?: number, height?: number,
  rotation?: number, opacity?: number,
): Transform {
  return {
    x: x ?? 0,
    y: y ?? 0,
    width: width ?? 100,
    height: height ?? 100,
    rotation: rotation ?? 0,
    scaleX: 1,
    scaleY: 1,
    flipH: false,
    flipV: false,
    opacity: opacity ?? 100,
  }
}

/** 创建 Scene */
export function createScene(
  canvasWidth?: number, canvasHeight?: number,
  unit?: Unit, dpi?: number,
  colorSpace?: ColorSpace, background?: string, name?: string,
): Scene {
  const w = canvasWidth ?? 595
  const h = canvasHeight ?? 842
  return {
    id: genId('scene'),
    type: 'scene',
    name: name ?? 'Untitled.hds',
    transform: defaultTransform(0, 0, w, h),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: [],
    canvasWidth: w,
    canvasHeight: h,
    unit: unit ?? 'mm',
    dpi: dpi ?? 300,
    colorSpace: colorSpace ?? 'sRGB',
    background: background ?? '#FFFFFF',
  }
}

/** 创建 Layer */
export function createLayer(params?: CreateNodeParams): Layer {
  const p = params ?? {}
  return {
    id: genId('layer'),
    type: 'layer',
    name: p.name ?? 'Layer',
    transform: defaultTransform(p.x, p.y, p.width, p.height),
    blendMode: p.blendMode ?? 'pass-through',
    visible: p.visible ?? true,
    locked: p.locked ?? false,
    parentId: '',
    objects: [],
    hasMask: false,
    maskEnabled: false,
    effects: [],
  }
}

/** 创建 Page */
export function createPage(
  name?: string, width?: number, height?: number,
  background?: string, children?: Layer[],
): Page {
  return {
    id: genId('page'),
    name: name ?? 'Page',
    width: width,
    height: height,
    background: background,
    children: children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
  }
}

/** 默认无限画布配置 */
export function defaultInfiniteCanvas(
  viewportX?: number, viewportY?: number, zoom?: number,
): InfiniteCanvasConfig {
  return {
    viewportX: viewportX ?? 0,
    viewportY: viewportY ?? 0,
    zoom: zoom ?? 1,
    background: 'grid',
    showRulers: false,
  }
}

/** Frame 默认配置 */
export interface FrameDefault {
  name: string
  width: number
  height: number
  description: string
}

/** 各类型 Frame 的默认尺寸 */
export const FRAME_DEFAULTS: Record<FrameType, FrameDefault> = {
  'single': { name: '单页', width: 595, height: 842, description: 'A4 竖向，标准单页画板' },
  'poster': { name: '海报', width: 595, height: 842, description: 'A4 竖向海报' },
  'book-page': { name: '书页', width: 297, height: 420, description: 'A4 对折单页' },
  'spread': { name: '对页', width: 594, height: 420, description: 'A4 对折展开' },
}

/** 创建 Frame */
export function createFrame(
  type?: FrameType, name?: string,
  x?: number, y?: number,
  width?: number, height?: number,
  background?: string, children?: Layer[],
  order?: number, showPageNumber?: boolean,
): Frame {
  const t: FrameType = type ?? 'single'
  const d = FRAME_DEFAULTS[t]
  return {
    id: genId('frame'),
    type: t,
    name: name ?? d.name,
    x: x ?? 0,
    y: y ?? 0,
    width: width ?? d.width,
    height: height ?? d.height,
    background: background ?? '#FFFFFF',
    children: children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
    order: order,
    showPageNumber: showPageNumber ?? (t === 'book-page' || t === 'spread'),
    pageNumberFormat: '{n}',
  }
}

/** 创建 Text 对象 */
export function createTextObject(params?: CreateNodeParams & {
  text?: string; fontFamily?: string; fontSize?: number; fontWeight?: number;
  fontStyle?: string; textDecoration?: string; align?: string;
  lineHeight?: number; letterSpacing?: number; color?: string;
}): TextObject {
  const p = params ?? {}
  return {
    id: genId('text'),
    type: 'text',
    name: p.name ?? 'Text',
    transform: defaultTransform(p.x, p.y, p.width ?? 200, p.height ?? 40),
    blendMode: p.blendMode ?? 'normal',
    visible: p.visible ?? true,
    locked: p.locked ?? false,
    text: p.text ?? 'Lorem ipsum',
    fontFamily: p.fontFamily ?? 'HarmonyOS Sans SC',
    fontSize: p.fontSize ?? 14,
    fontWeight: p.fontWeight ?? 400,
    fontStyle: p.fontStyle ?? 'normal',
    textDecoration: p.textDecoration ?? 'none',
    align: p.align ?? 'left',
    lineHeight: p.lineHeight ?? 1.4,
    letterSpacing: p.letterSpacing ?? 0,
    color: p.color ?? '#1F2329',
  }
}

/** 创建 Shape 对象 */
export function createShapeObject(params?: CreateNodeParams & {
  shape?: ShapeKind; fill?: string; stroke?: string; strokeWidth?: number;
  cornerRadius?: number; sides?: number;
}): ShapeObject {
  const p = params ?? {}
  return {
    id: genId('shape'),
    type: 'shape',
    name: p.name ?? 'Shape',
    transform: defaultTransform(p.x, p.y, p.width ?? 100, p.height ?? 100),
    blendMode: p.blendMode ?? 'normal',
    visible: p.visible ?? true,
    locked: p.locked ?? false,
    shape: p.shape ?? 'rectangle',
    fill: p.fill ?? '#3AC487',
    stroke: p.stroke ?? '#1F2329',
    strokeWidth: p.strokeWidth ?? 0,
    cornerRadius: p.cornerRadius ?? 0,
    sides: p.sides ?? 5,
  }
}

/** 创建 Image 对象 */
export function createImageObject(params?: CreateNodeParams & {
  src?: string; naturalWidth?: number; naturalHeight?: number;
}): ImageObject {
  const p = params ?? {}
  return {
    id: genId('image'),
    type: 'image',
    name: p.name ?? 'Image',
    transform: defaultTransform(p.x, p.y, p.width ?? 200, p.height ?? 150),
    blendMode: p.blendMode ?? 'normal',
    visible: p.visible ?? true,
    locked: p.locked ?? false,
    src: p.src ?? '',
    naturalWidth: p.naturalWidth ?? 0,
    naturalHeight: p.naturalHeight ?? 0,
  }
}

/** 创建 Group 对象 */
export function createGroupObject(params?: CreateNodeParams & {
  children?: SceneObject[];
}): GroupObject {
  const p = params ?? {}
  return {
    id: genId('group'),
    type: 'group',
    name: p.name ?? 'Group',
    transform: defaultTransform(p.x, p.y, p.width, p.height),
    blendMode: p.blendMode ?? 'pass-through',
    visible: p.visible ?? true,
    locked: p.locked ?? false,
    children: p.children ?? [],
  }
}

/** 创建 Mask */
export function createMask(type?: string): Mask {
  return {
    type: (type ?? 'raster') as 'raster' | 'vector',
    data: '',
    enabled: true,
    inverted: false,
  }
}

/** 文档预设：单页 */
export function createSinglePageDocument(): Frame[] {
  return [createFrame('single', '页面 1', 0, 0)]
}

/** 文档预设：多页 */
export function createMultiPageDocument(pageCount?: number): Frame[] {
  const count = pageCount ?? 3
  const frames: Frame[] = []
  const gap = 80
  let cursorX = 0
  for (let i = 0; i < count; i++) {
    frames.push(createFrame('single', `页面 ${i + 1}`, cursorX, 0))
    cursorX += FRAME_DEFAULTS['single'].width + gap
  }
  return frames
}
