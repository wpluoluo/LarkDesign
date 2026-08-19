import {
  BlendMode, Transform, Scene, Layer, Page, Frame, FrameType,
  InfiniteCanvasConfig, SceneObject, Mask,
  LayerEffect, EffectParams, Gradient, Unit, ColorSpace, ShapeKind,
} from './SceneTypes'

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

export interface CreateSceneParams {
  canvasWidth?: number
  canvasHeight?: number
  unit?: Unit
  dpi?: number
  colorSpace?: ColorSpace
  background?: string
  name?: string
}

export interface CreatePageParams {
  name?: string
  width?: number
  height?: number
  background?: string
  children?: Layer[]
}

export interface CreateFrameParams {
  type?: FrameType
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  background?: string
  children?: Layer[]
  order?: number
  showPageNumber?: boolean
}

export interface CreateTextObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  text?: string
  fontFamily?: string
  fontSize?: number
  fontWeight?: number
  fontStyle?: string
  textDecoration?: string
  align?: string
  lineHeight?: number
  letterSpacing?: number
  color?: string
}

export interface CreateShapeObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  shape?: ShapeKind
  fill?: string
  stroke?: string
  strokeWidth?: number
  cornerRadius?: number
  sides?: number
}

export interface CreateImageObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  src?: string
  naturalWidth?: number
  naturalHeight?: number
}

export interface CreateGroupObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  children?: SceneObject[]
}

export interface CreateAdjustmentObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  adjustmentType?: string
}

export interface CreateFillObjectParams {
  name?: string
  x?: number
  y?: number
  width?: number
  height?: number
  visible?: boolean
  locked?: boolean
  blendMode?: BlendMode
  fillType?: string
  color?: string
  gradient?: Gradient
}

let __idCounter = 0
export function genId(prefix: string = 'node'): string {
  __idCounter += 1
  return `${prefix}_${Date.now().toString(36)}_${__idCounter.toString(36)}`
}

function assignTransform(t: Transform, overrides?: Partial<Transform>): void {
  if (overrides === undefined) return
  if (overrides.x !== undefined) t.x = overrides.x
  if (overrides.y !== undefined) t.y = overrides.y
  if (overrides.width !== undefined) t.width = overrides.width
  if (overrides.height !== undefined) t.height = overrides.height
  if (overrides.rotation !== undefined) t.rotation = overrides.rotation
  if (overrides.scaleX !== undefined) t.scaleX = overrides.scaleX
  if (overrides.scaleY !== undefined) t.scaleY = overrides.scaleY
  if (overrides.flipH !== undefined) t.flipH = overrides.flipH
  if (overrides.flipV !== undefined) t.flipV = overrides.flipV
  if (overrides.opacity !== undefined) t.opacity = overrides.opacity
}

export function defaultTransform(overrides?: Partial<Transform>): Transform {
  const t: Transform = {
    x: 0, y: 0, width: 100, height: 100,
    rotation: 0, scaleX: 1, scaleY: 1,
    flipH: false, flipV: false, opacity: 100,
  }
  assignTransform(t, overrides)
  return t
}

export function createScene(params?: CreateSceneParams): Scene {
  const p = params ?? {}
  const scene: Scene = {
    id: genId('scene'),
    type: 'scene',
    name: p.name ?? 'Untitled.hds',
    transform: defaultTransform({ width: p.canvasWidth ?? 595, height: p.canvasHeight ?? 842 }),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: [],
    canvasWidth: p.canvasWidth ?? 595,
    canvasHeight: p.canvasHeight ?? 842,
    unit: p.unit ?? 'mm',
    dpi: p.dpi ?? 300,
    colorSpace: p.colorSpace ?? 'sRGB',
    background: p.background ?? '#FFFFFF',
  }
  return scene
}

export function createLayer(params?: CreateNodeParams): Layer {
  const p = params ?? {}
  const layer: Layer = {
    id: genId('layer'),
    type: 'layer',
    name: p.name ?? 'Layer',
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
  if (p.x !== undefined) layer.transform.x = p.x
  if (p.y !== undefined) layer.transform.y = p.y
  if (p.width !== undefined) layer.transform.width = p.width
  if (p.height !== undefined) layer.transform.height = p.height
  if (p.visible !== undefined) layer.visible = p.visible
  if (p.locked !== undefined) layer.locked = p.locked
  if (p.blendMode !== undefined) layer.blendMode = p.blendMode
  if (p.name !== undefined) layer.name = p.name
  return layer
}

export function createPage(params?: CreatePageParams): Page {
  const p = params ?? {}
  const page: Page = {
    id: genId('page'),
    name: p.name ?? 'Page',
    width: p.width ?? 0,
    height: p.height ?? 0,
    background: p.background ?? '#FFFFFF',
    children: p.children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
  }
  return page
}

export function defaultInfiniteCanvas(overrides?: Partial<InfiniteCanvasConfig>): InfiniteCanvasConfig {
  const cfg: InfiniteCanvasConfig = {
    viewportX: 0,
    viewportY: 0,
    zoom: 1,
    background: 'grid',
    showRulers: false,
  }
  if (overrides === undefined) return cfg
  if (overrides.viewportX !== undefined) cfg.viewportX = overrides.viewportX
  if (overrides.viewportY !== undefined) cfg.viewportY = overrides.viewportY
  if (overrides.zoom !== undefined) cfg.zoom = overrides.zoom
  if (overrides.background !== undefined) cfg.background = overrides.background
  if (overrides.showRulers !== undefined) cfg.showRulers = overrides.showRulers
  return cfg
}

export interface FrameDefault {
  name: string
  width: number
  height: number
  description: string
}

export const FRAME_DEFAULTS: Record<string, FrameDefault> = {
  'single': { name: '单页', width: 595, height: 842, description: 'A4 竖向，标准单页画板' },
  'poster': { name: '海报', width: 595, height: 842, description: 'A4 竖向海报，可自定义大尺寸' },
  'book-page': { name: '书页', width: 297, height: 420, description: 'A4 对折单页，适合书籍内页' },
  'spread': { name: '对页', width: 594, height: 420, description: 'A4 对折展开，左右两页成组' },
}

export function createFrame(params?: CreateFrameParams): Frame {
  const p = params ?? {}
  const t: FrameType = p.type ?? 'single'
  const d = FRAME_DEFAULTS[t]
  const frame: Frame = {
    id: genId('frame'),
    type: t,
    name: p.name ?? d.name,
    x: p.x ?? 0,
    y: p.y ?? 0,
    width: p.width ?? d.width,
    height: p.height ?? d.height,
    background: p.background ?? '#FFFFFF',
    children: p.children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
    order: p.order,
    showPageNumber: p.showPageNumber ?? (t === 'book-page' || t === 'spread'),
    pageNumberFormat: '{n}',
  }
  return frame
}

export interface PosterPreset {
  id: string
  name: string
  width: number
  height: number
  orientation: string
}

export const POSTER_PRESETS: PosterPreset[] = [
  { id: 'a3-portrait', name: 'A3 竖向', width: 297, height: 420, orientation: 'portrait' },
  { id: 'a3-landscape', name: 'A3 横向', width: 420, height: 297, orientation: 'landscape' },
  { id: 'a2-portrait', name: 'A2 竖向', width: 420, height: 594, orientation: 'portrait' },
  { id: 'a2-landscape', name: 'A2 横向', width: 594, height: 420, orientation: 'landscape' },
  { id: 'a1-portrait', name: 'A1 竖向', width: 594, height: 841, orientation: 'portrait' },
  { id: 'a1-landscape', name: 'A1 横向', width: 841, height: 594, orientation: 'landscape' },
  { id: 'b1-portrait', name: 'B1 竖向', width: 728, height: 1030, orientation: 'portrait' },
  { id: 'b1-landscape', name: 'B1 横向', width: 1030, height: 728, orientation: 'landscape' },
]

export interface BookPreset {
  id: string
  name: string
  width: number
  height: number
}

export const BOOK_PRESETS: BookPreset[] = [
  { id: 'a5', name: 'A5 (148×210mm)', width: 148, height: 210 },
  { id: 'b5', name: 'B5 (176×250mm)', width: 176, height: 250 },
  { id: 'a4', name: 'A4 (210×297mm)', width: 210, height: 297 },
  { id: '16k', name: '16K (185×260mm)', width: 185, height: 260 },
  { id: '32k', name: '32K (130×184mm)', width: 130, height: 184 },
  { id: 'pocket', name: '口袋 (100×150mm)', width: 100, height: 150 },
]

export function createSinglePageDocument(): Frame[] {
  return [
    createFrame({ type: 'single', name: '页面 1', x: 0, y: 0 } as CreateFrameParams),
  ]
}

export function createMultiPageDocument(pageCount: number = 3): Frame[] {
  const frames: Frame[] = []
  const gap = 80
  let cursorX = 0
  for (let i = 0; i < pageCount; i++) {
    frames.push(createFrame({
      type: 'single',
      name: `页面 ${i + 1}`,
      x: cursorX,
      y: 0,
    } as CreateFrameParams))
    cursorX += FRAME_DEFAULTS['single'].width + gap
  }
  return frames
}

export function createPosterDocument(presetId: string = 'a3-portrait'): Frame[] {
  let preset: PosterPreset = POSTER_PRESETS[0]
  for (let i = 0; i < POSTER_PRESETS.length; i++) {
    if (POSTER_PRESETS[i].id === presetId) {
      preset = POSTER_PRESETS[i]
      break
    }
  }
  return [
    createFrame({
      type: 'poster',
      name: `海报 ${preset.name}`,
      x: 0,
      y: 0,
      width: preset.width,
      height: preset.height,
    } as CreateFrameParams),
  ]
}

export function createBookDocument(
  pageCount: number = 8,
  pageWidth: number = 148,
  pageHeight: number = 210,
  useSpread: boolean = true,
): Frame[] {
  const frames: Frame[] = []
  const gap = 40
  if (useSpread) {
    const spreadCount = Math.ceil(pageCount / 2)
    let cursorX = 0
    for (let i = 0; i < spreadCount; i++) {
      const leftFrame = createFrame({
        type: 'book-page',
        name: `第 ${i * 2 + 1} 页`,
        x: cursorX,
        y: 0,
        width: pageWidth,
        height: pageHeight,
        order: i * 2 + 1,
        showPageNumber: true,
      } as CreateFrameParams)
      const rightFrame = createFrame({
        type: 'book-page',
        name: `第 ${i * 2 + 2} 页`,
        x: cursorX + pageWidth + gap,
        y: 0,
        width: pageWidth,
        height: pageHeight,
        order: i * 2 + 2,
        showPageNumber: true,
      } as CreateFrameParams)
      leftFrame.spreadWith = rightFrame.id
      leftFrame.spreadSide = 'left'
      rightFrame.spreadWith = leftFrame.id
      rightFrame.spreadSide = 'right'
      frames.push(leftFrame, rightFrame)
      cursorX += (pageWidth * 2) + gap + 40
    }
  } else {
    let cursorX = 0
    for (let i = 0; i < pageCount; i++) {
      frames.push(createFrame({
        type: 'book-page',
        name: `第 ${i + 1} 页`,
        x: cursorX,
        y: 0,
        width: pageWidth,
        height: pageHeight,
        order: i + 1,
        showPageNumber: true,
      } as CreateFrameParams))
      cursorX += pageWidth + gap
    }
  }
  return frames
}

function applyNodeName(t: SceneObject, name?: string): void {
  if (name !== undefined) t.name = name
}

function applyNodePos(t: SceneObject, x?: number, y?: number, w?: number, h?: number): void {
  if (x !== undefined) t.transform.x = x
  if (y !== undefined) t.transform.y = y
  if (w !== undefined) t.transform.width = w
  if (h !== undefined) t.transform.height = h
}

function applyNodeFlags(t: SceneObject, visible?: boolean, locked?: boolean, blendMode?: BlendMode): void {
  if (visible !== undefined) t.visible = visible
  if (locked !== undefined) t.locked = locked
  if (blendMode !== undefined) t.blendMode = blendMode
}

export function createTextObject(params?: CreateTextObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('text'),
    type: 'text',
    name: p.name ?? 'Text',
    transform: defaultTransform({ width: 200, height: 40 }),
    blendMode: 'normal',
    visible: true,
    locked: false,
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
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createShapeObject(params?: CreateShapeObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('shape'),
    type: 'shape',
    name: p.name ?? 'Shape',
    transform: defaultTransform({ width: 100, height: 100 }),
    blendMode: 'normal',
    visible: true,
    locked: false,
    shape: p.shape ?? 'rectangle',
    fill: p.fill ?? '#3AC487',
    stroke: p.stroke ?? '#1F2329',
    strokeWidth: p.strokeWidth ?? 0,
    cornerRadius: p.cornerRadius ?? 0,
    sides: p.sides ?? 5,
  }
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createImageObject(params?: CreateImageObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('image'),
    type: 'image',
    name: p.name ?? 'Image',
    transform: defaultTransform({ width: 200, height: 150 }),
    blendMode: 'normal',
    visible: true,
    locked: false,
    src: p.src ?? '',
    naturalWidth: p.naturalWidth ?? 0,
    naturalHeight: p.naturalHeight ?? 0,
  }
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createGroupObject(params?: CreateGroupObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('group'),
    type: 'group',
    name: p.name ?? 'Group',
    transform: defaultTransform(),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: p.children ?? [],
  }
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createAdjustmentObject(params?: CreateAdjustmentObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('adj'),
    type: 'adjustment',
    name: p.name ?? 'Adjustment',
    transform: defaultTransform(),
    blendMode: 'normal',
    visible: true,
    locked: false,
    adjustmentType: p.adjustmentType ?? 'hue-saturation',
  }
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createFillObject(params?: CreateFillObjectParams): SceneObject {
  const p = params ?? {}
  const obj: SceneObject = {
    id: genId('fill'),
    type: 'fill',
    name: p.name ?? 'Fill',
    transform: defaultTransform(),
    blendMode: 'normal',
    visible: true,
    locked: false,
    fillType: p.fillType ?? 'solid',
    color: p.color ?? '#3AC487',
    gradient: p.gradient,
  }
  applyNodePos(obj, p.x, p.y, p.width, p.height)
  applyNodeFlags(obj, p.visible, p.locked, p.blendMode)
  applyNodeName(obj, p.name)
  return obj
}

export function createMask(type: string = 'raster'): Mask {
  const mask: Mask = {
    type: type,
    data: '',
    enabled: true,
    inverted: false,
  }
  return mask
}

function getEffectDefaults(type: string): EffectParams {
  if (type === 'drop-shadow') {
    const e: EffectParams = { angle: 120, distance: 5, blur: 4, color: '#000000', opacity: 40 }
    return e
  }
  if (type === 'inner-shadow') {
    const e: EffectParams = { angle: 120, distance: 3, blur: 3, color: '#000000', opacity: 40 }
    return e
  }
  if (type === 'outer-glow') {
    const e: EffectParams = { blur: 8, spread: 0, color: '#3AC487', opacity: 50 }
    return e
  }
  if (type === 'inner-glow') {
    const e: EffectParams = { blur: 5, spread: 0, color: '#3AC487', opacity: 50 }
    return e
  }
  if (type === 'bevel') {
    const e: EffectParams = { style: 'inner', depth: 50, direction: 'up', size: 4, soften: 0 }
    return e
  }
  if (type === 'satin') {
    const e: EffectParams = { angle: 19, distance: 11, size: 14, color: '#000000', opacity: 50 }
    return e
  }
  if (type === 'color-overlay') {
    const e: EffectParams = { color: '#3AC487', opacity: 100 }
    return e
  }
  if (type === 'gradient-overlay') {
    const e: EffectParams = { angle: 90, opacity: 100, gradient: '' }
    return e
  }
  if (type === 'pattern-overlay') {
    const e: EffectParams = { scale: 100, opacity: 100, src: '' }
    return e
  }
  const empty: EffectParams = {}
  return empty
}

function mergeParams(a: EffectParams, b?: EffectParams): EffectParams {
  const r: EffectParams = {}
  if (a.color !== undefined) r.color = a.color
  if (a.opacity !== undefined) r.opacity = a.opacity
  if (a.blur !== undefined) r.blur = a.blur
  if (a.distance !== undefined) r.distance = a.distance
  if (a.angle !== undefined) r.angle = a.angle
  if (a.spread !== undefined) r.spread = a.spread
  if (a.style !== undefined) r.style = a.style
  if (a.depth !== undefined) r.depth = a.depth
  if (a.direction !== undefined) r.direction = a.direction
  if (a.size !== undefined) r.size = a.size
  if (a.soften !== undefined) r.soften = a.soften
  if (a.gradient !== undefined) r.gradient = a.gradient
  if (a.scale !== undefined) r.scale = a.scale
  if (a.src !== undefined) r.src = a.src
  if (b === undefined) return r
  if (b.color !== undefined) r.color = b.color
  if (b.opacity !== undefined) r.opacity = b.opacity
  if (b.blur !== undefined) r.blur = b.blur
  if (b.distance !== undefined) r.distance = b.distance
  if (b.angle !== undefined) r.angle = b.angle
  if (b.spread !== undefined) r.spread = b.spread
  if (b.style !== undefined) r.style = b.style
  if (b.depth !== undefined) r.depth = b.depth
  if (b.direction !== undefined) r.direction = b.direction
  if (b.size !== undefined) r.size = b.size
  if (b.soften !== undefined) r.soften = b.soften
  if (b.gradient !== undefined) r.gradient = b.gradient
  if (b.scale !== undefined) r.scale = b.scale
  if (b.src !== undefined) r.src = b.src
  return r
}

export function createLayerEffect(
  type: string,
  params?: EffectParams,
): LayerEffect {
  const defaults: EffectParams = getEffectDefaults(type)
  const fx: LayerEffect = {
    id: genId('fx'),
    type: type,
    enabled: true,
    params: mergeParams(defaults, params),
  }
  return fx
}

export function createObjectByType(type: string, params?: CreateNodeParams): SceneObject {
  if (type === 'text') return createTextObject(params as CreateTextObjectParams)
  if (type === 'image') return createImageObject(params as CreateImageObjectParams)
  if (type === 'shape') return createShapeObject(params as CreateShapeObjectParams)
  if (type === 'group') return createGroupObject(params as CreateGroupObjectParams)
  if (type === 'adjustment') return createAdjustmentObject(params as CreateAdjustmentObjectParams)
  if (type === 'fill') return createFillObject(params as CreateFillObjectParams)
  return createShapeObject(params as CreateShapeObjectParams)
}
