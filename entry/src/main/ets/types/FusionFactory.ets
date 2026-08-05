/**
 * FusionFactory - ArkTS 版节点工厂
 *
 * 对应原型 src/fusion/factory.ts
 * 适配 ArkTS 语法限制。
 */
import {
  BlendMode, Transform, Scene, Layer, Page, Frame, FrameType,
  InfiniteCanvasConfig, SceneObject, TextObject, ImageObject,
  ShapeObject, GroupObject, AdjustmentObject, FillObject, Mask,
  LayerEffect, Gradient, Unit, ColorSpace, ShapeKind,
} from '../types/SceneTypes'

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

/** ID 生成器 */
let __idCounter = 0
export function genId(prefix: string = 'node'): string {
  __idCounter += 1
  return `${prefix}_${Date.now().toString(36)}_${__idCounter.toString(36)}`
}

/** 默认变换 */
export function defaultTransform(
  x?: number, y?: number, width?: number, height?: number,
): Transform {
  return {
    x: x ?? 0,
    y: y ?? 0,
    width: width ?? 100,
    height: height ?? 100,
    rotation: 0,
    scaleX: 1,
    scaleY: 1,
    flipH: false,
    flipV: false,
    opacity: 100,
  }
}

/** 创建 Scene */
export function createScene(): Scene {
  return {
    id: genId('scene'),
    type: 'scene',
    name: 'Untitled.hds',
    transform: defaultTransform(0, 0, 595, 842),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: [],
    canvasWidth: 595,
    canvasHeight: 842,
    unit: 'mm',
    dpi: 300,
    colorSpace: 'sRGB',
    background: '#FFFFFF',
  }
}

/** 创建 Layer */
export function createLayer(name?: string): Layer {
  return {
    id: genId('layer'),
    type: 'layer',
    name: name ?? 'Layer',
    transform: defaultTransform(),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    parentId: '',
    objects: [],
    hasMask: false,
    maskEnabled: false,
    effects: [],
  }
}

/** Frame 默认配置 */
export interface FrameDefault {
  name: string
  width: number
  height: number
}

export const FRAME_DEFAULTS: Record<FrameType, FrameDefault> = {
  'single': { name: '单页', width: 595, height: 842 },
  'poster': { name: '海报', width: 595, height: 842 },
  'book-page': { name: '书页', width: 297, height: 420 },
  'spread': { name: '对页', width: 594, height: 420 },
}

/** 创建 Frame */
export function createFrame(
  type?: FrameType, name?: string,
  x?: number, y?: number,
  width?: number, height?: number,
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
    background: '#FFFFFF',
    children: [],
    hidden: false,
    createdAt: new Date().toISOString(),
    showPageNumber: t === 'book-page' || t === 'spread',
    pageNumberFormat: '{n}',
  }
}

/** 创建 Text 对象 */
export function createTextObject(
  text?: string, x?: number, y?: number, width?: number, height?: number,
): TextObject {
  return {
    id: genId('text'),
    type: 'text',
    name: 'Text',
    transform: defaultTransform(x, y, width ?? 200, height ?? 40),
    blendMode: 'normal',
    visible: true,
    locked: false,
    text: text ?? 'Lorem ipsum',
    fontFamily: 'HarmonyOS Sans SC',
    fontSize: 14,
    fontWeight: 400,
    fontStyle: 'normal',
    textDecoration: 'none',
    align: 'left',
    lineHeight: 1.4,
    letterSpacing: 0,
    color: '#1F2329',
  }
}

/** 创建 Shape 对象 */
export function createShapeObject(
  shape?: ShapeKind, x?: number, y?: number, width?: number, height?: number,
  fill?: string,
): ShapeObject {
  return {
    id: genId('shape'),
    type: 'shape',
    name: 'Shape',
    transform: defaultTransform(x, y, width ?? 100, height ?? 100),
    blendMode: 'normal',
    visible: true,
    locked: false,
    shape: shape ?? 'rectangle',
    fill: fill ?? '#3AC487',
    stroke: '#1F2329',
    strokeWidth: 0,
    cornerRadius: 0,
    sides: 5,
  }
}

/** 创建 Image 对象 */
export function createImageObject(
  src?: string, x?: number, y?: number, width?: number, height?: number,
): ImageObject {
  return {
    id: genId('image'),
    type: 'image',
    name: 'Image',
    transform: defaultTransform(x, y, width ?? 200, height ?? 150),
    blendMode: 'normal',
    visible: true,
    locked: false,
    src: src ?? '',
    naturalWidth: 0,
    naturalHeight: 0,
  }
}
