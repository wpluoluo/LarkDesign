/**
 * Fusion DOM - 节点工厂
 *
 * 提供创建各类节点的工厂方法，统一生成默认值与唯一 ID。
 */
import type {
  AdjustmentObject,
  BlendMode,
  CreateNodeParams,
  FillObject,
  Frame,
  FrameType,
  Gradient,
  GroupObject,
  ImageObject,
  InfiniteCanvasConfig,
  Layer,
  LayerEffect,
  Mask,
  Page,
  Scene,
  SceneObject,
  ShapeObject,
  ShapeKind,
  TextObject,
  Transform,
  Unit,
  ColorSpace,
} from '../types'

/** 简易 ID 生成器：递增 + 时间戳，确保唯一性 */
let __idCounter = 0
export function genId(prefix = 'node'): string {
  __idCounter += 1
  return `${prefix}_${Date.now().toString(36)}_${__idCounter.toString(36)}`
}

/** 默认变换 */
export function defaultTransform(overrides: Partial<Transform> = {}): Transform {
  return {
    x: 0,
    y: 0,
    width: 100,
    height: 100,
    rotation: 0,
    scaleX: 1,
    scaleY: 1,
    flipH: false,
    flipV: false,
    opacity: 100,
    ...overrides,
  }
}

/** 应用通用节点参数 */
function applyParams<T extends { name: string; transform: Transform; blendMode: BlendMode; visible: boolean; locked: boolean }>(
  base: T,
  params: CreateNodeParams = {},
): T {
  if (params.name !== undefined) base.name = params.name
  if (params.x !== undefined) base.transform.x = params.x
  if (params.y !== undefined) base.transform.y = params.y
  if (params.width !== undefined) base.transform.width = params.width
  if (params.height !== undefined) base.transform.height = params.height
  if (params.visible !== undefined) base.visible = params.visible
  if (params.locked !== undefined) base.locked = params.locked
  if (params.blendMode !== undefined) base.blendMode = params.blendMode
  return base
}

/** 创建 Scene（根场景） */
export function createScene(params: {
  canvasWidth?: number
  canvasHeight?: number
  unit?: Unit
  dpi?: number
  colorSpace?: ColorSpace
  background?: string
  name?: string
} = {}): Scene {
  return {
    id: genId('scene'),
    type: 'scene',
    name: params.name ?? 'Untitled.hds',
    transform: defaultTransform({ width: params.canvasWidth ?? 595, height: params.canvasHeight ?? 842 }),
    blendMode: 'pass-through',
    visible: true,
    locked: false,
    children: [],
    canvasWidth: params.canvasWidth ?? 595,
    canvasHeight: params.canvasHeight ?? 842,
    unit: params.unit ?? 'mm',
    dpi: params.dpi ?? 300,
    colorSpace: params.colorSpace ?? 'sRGB',
    background: params.background ?? '#FFFFFF',
  }
}

/** 创建 Layer（图层容器） */
export function createLayer(params: CreateNodeParams = {}): Layer {
  return applyParams(
    {
      id: genId('layer'),
      type: 'layer',
      name: params.name ?? 'Layer',
      transform: defaultTransform(),
      blendMode: 'pass-through',
      visible: true,
      locked: false,
      parentId: '',
      objects: [],
      hasMask: false,
      maskEnabled: false,
      effects: [],
    },
    params,
  )
}

/** 创建 Page（多页面文档的页面） */
export function createPage(params: {
  name?: string
  width?: number
  height?: number
  background?: string
  children?: Layer[]
} = {}): Page {
  return {
    id: genId('page'),
    name: params.name ?? 'Page',
    width: params.width,
    height: params.height,
    background: params.background,
    children: params.children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
  }
}

/* ════════════════ 无限画布 + Frame 架构 ════════════════ */

/** 默认无限画布配置 */
export function defaultInfiniteCanvas(overrides: Partial<InfiniteCanvasConfig> = {}): InfiniteCanvasConfig {
  return {
    viewportX: 0,
    viewportY: 0,
    zoom: 1,
    background: 'grid',
    showRulers: false,
    ...overrides,
  }
}

/** 创建 Frame（画板） */
export function createFrame(params: {
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
} = {}): Frame {
  const type = params.type ?? 'single'
  const defaults = FRAME_DEFAULTS[type]
  return {
    id: genId('frame'),
    type,
    name: params.name ?? defaults.name,
    x: params.x ?? 0,
    y: params.y ?? 0,
    width: params.width ?? defaults.width,
    height: params.height ?? defaults.height,
    background: params.background ?? '#FFFFFF',
    children: params.children ?? [],
    hidden: false,
    createdAt: new Date().toISOString(),
    order: params.order,
    showPageNumber: params.showPageNumber ?? (type === 'book-page' || type === 'spread'),
    pageNumberFormat: '{n}',
  }
}

/** 各类型 Frame 的默认尺寸与名称 */
export const FRAME_DEFAULTS: Record<FrameType, { name: string; width: number; height: number; description: string }> = {
  single: {
    name: '单页',
    width: 595,
    height: 842,
    description: 'A4 竖向，标准单页画板',
  },
  poster: {
    name: '海报',
    width: 595,
    height: 842,
    description: 'A4 竖向海报，可自定义大尺寸',
  },
  'book-page': {
    name: '书页',
    width: 297,
    height: 420,
    description: 'A4 对折单页，适合书籍内页',
  },
  spread: {
    name: '对页',
    width: 594,
    height: 420,
    description: 'A4 对折展开，左右两页成组',
  },
}

/** 海报尺寸预设（常用 ISO A 系列 + B 系列） */
export const POSTER_PRESETS: Array<{ id: string; name: string; width: number; height: number; orientation: 'portrait' | 'landscape' }> = [
  { id: 'a3-portrait', name: 'A3 竖向', width: 297, height: 420, orientation: 'portrait' },
  { id: 'a3-landscape', name: 'A3 横向', width: 420, height: 297, orientation: 'landscape' },
  { id: 'a2-portrait', name: 'A2 竖向', width: 420, height: 594, orientation: 'portrait' },
  { id: 'a2-landscape', name: 'A2 横向', width: 594, height: 420, orientation: 'landscape' },
  { id: 'a1-portrait', name: 'A1 竖向', width: 594, height: 841, orientation: 'portrait' },
  { id: 'a1-landscape', name: 'A1 横向', width: 841, height: 594, orientation: 'landscape' },
  { id: 'b1-portrait', name: 'B1 竖向', width: 728, height: 1030, orientation: 'portrait' },
  { id: 'b1-landscape', name: 'B1 横向', width: 1030, height: 728, orientation: 'landscape' },
]

/** 书籍尺寸预设（成品尺寸） */
export const BOOK_PRESETS: Array<{ id: string; name: string; width: number; height: number }> = [
  { id: 'a5', name: 'A5 (148×210mm)', width: 148, height: 210 },
  { id: 'b5', name: 'B5 (176×250mm)', width: 176, height: 250 },
  { id: 'a4', name: 'A4 (210×297mm)', width: 210, height: 297 },
  { id: '16k', name: '16K (185×260mm)', width: 185, height: 260 },
  { id: '32k', name: '32K (130×184mm)', width: 130, height: 184 },
  { id: 'pocket', name: '口袋 (100×150mm)', width: 100, height: 150 },
]

/** 创建单页文档预设（1个 single Frame） */
export function createSinglePageDocument(): Frame[] {
  return [
    createFrame({
      type: 'single',
      name: '页面 1',
      x: 0,
      y: 0,
    }),
  ]
}

/** 创建多页文档预设（N个独立 single Frame，横向排列） */
export function createMultiPageDocument(pageCount: number = 3): Frame[] {
  const frames: Frame[] = []
  const gap = 80 // Frame 间距
  let cursorX = 0
  for (let i = 0; i < pageCount; i++) {
    frames.push(createFrame({
      type: 'single',
      name: `页面 ${i + 1}`,
      x: cursorX,
      y: 0,
    }))
    cursorX += FRAME_DEFAULTS.single.width + gap
  }
  return frames
}

/** 创建海报文档预设（1个 poster Frame） */
export function createPosterDocument(
  presetId: string = 'a3-portrait',
): Frame[] {
  const preset = POSTER_PRESETS.find(p => p.id === presetId) ?? POSTER_PRESETS[0]
  return [
    createFrame({
      type: 'poster',
      name: `海报 ${preset.name}`,
      x: 0,
      y: 0,
      width: preset.width,
      height: preset.height,
    }),
  ]
}

/** 创建书籍文档预设（N个 book-page Frame，支持对页 spread） */
export function createBookDocument(
  pageCount: number = 8,
  pageWidth: number = 148,
  pageHeight: number = 210,
  useSpread: boolean = true,
): Frame[] {
  const frames: Frame[] = []
  const gap = 40
  if (useSpread) {
    // 对页模式：每两个单页组成一个 spread
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
      })
      const rightFrame = createFrame({
        type: 'book-page',
        name: `第 ${i * 2 + 2} 页`,
        x: cursorX + pageWidth + gap,
        y: 0,
        width: pageWidth,
        height: pageHeight,
        order: i * 2 + 2,
        showPageNumber: true,
      })
      // 建立对页关联
      leftFrame.spreadWith = rightFrame.id
      leftFrame.spreadSide = 'left'
      rightFrame.spreadWith = leftFrame.id
      rightFrame.spreadSide = 'right'
      frames.push(leftFrame, rightFrame)
      cursorX += (pageWidth * 2) + gap + 40
    }
  } else {
    // 单页模式：顺序排列
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
      }))
      cursorX += pageWidth + gap
    }
  }
  return frames
}

/** 创建 Text 对象 */
export function createTextObject(params: CreateNodeParams & {
  text?: string
  fontFamily?: string
  fontSize?: number
  fontWeight?: number
  fontStyle?: 'normal' | 'italic'
  textDecoration?: 'none' | 'underline' | 'line-through'
  align?: 'left' | 'center' | 'right' | 'justify'
  lineHeight?: number
  letterSpacing?: number
  color?: string
} = {}): TextObject {
  return applyParams(
    {
      id: genId('text'),
      type: 'text',
      name: params.name ?? 'Text',
      transform: defaultTransform({ width: 200, height: 40 }),
      blendMode: 'normal',
      visible: true,
      locked: false,
      text: params.text ?? 'Lorem ipsum',
      fontFamily: params.fontFamily ?? 'HarmonyOS Sans SC',
      fontSize: params.fontSize ?? 14,
      fontWeight: params.fontWeight ?? 400,
      fontStyle: params.fontStyle ?? 'normal',
      textDecoration: params.textDecoration ?? 'none',
      align: params.align ?? 'left',
      lineHeight: params.lineHeight ?? 1.4,
      letterSpacing: params.letterSpacing ?? 0,
      color: params.color ?? '#1F2329',
    },
    params,
  )
}

/** 创建 Shape 对象 */
export function createShapeObject(params: CreateNodeParams & {
  shape?: ShapeKind
  fill?: string
  stroke?: string
  strokeWidth?: number
  cornerRadius?: number
  sides?: number
} = {}): ShapeObject {
  return applyParams(
    {
      id: genId('shape'),
      type: 'shape',
      name: params.name ?? 'Shape',
      transform: defaultTransform({ width: 100, height: 100 }),
      blendMode: 'normal',
      visible: true,
      locked: false,
      shape: params.shape ?? 'rectangle',
      fill: params.fill ?? '#3AC487',
      stroke: params.stroke ?? '#1F2329',
      strokeWidth: params.strokeWidth ?? 0,
      cornerRadius: params.cornerRadius ?? 0,
      sides: params.sides ?? 5,
    },
    params,
  )
}

/** 创建 Image 对象 */
export function createImageObject(params: CreateNodeParams & {
  src?: string
  naturalWidth?: number
  naturalHeight?: number
} = {}): ImageObject {
  return applyParams(
    {
      id: genId('image'),
      type: 'image',
      name: params.name ?? 'Image',
      transform: defaultTransform({ width: 200, height: 150 }),
      blendMode: 'normal',
      visible: true,
      locked: false,
      src: params.src ?? '',
      naturalWidth: params.naturalWidth ?? 0,
      naturalHeight: params.naturalHeight ?? 0,
      filters: [],
    },
    params,
  )
}

/** 创建 Group 对象 */
export function createGroupObject(params: CreateNodeParams & {
  children?: SceneObject[]
} = {}): GroupObject {
  return applyParams(
    {
      id: genId('group'),
      type: 'group',
      name: params.name ?? 'Group',
      transform: defaultTransform(),
      blendMode: 'pass-through',
      visible: true,
      locked: false,
      children: params.children ?? [],
    },
    params,
  )
}

/** 创建 Adjustment 对象 */
export function createAdjustmentObject(params: CreateNodeParams & {
  adjustmentType?: AdjustmentObject['adjustmentType']
} = {}): AdjustmentObject {
  return applyParams(
    {
      id: genId('adj'),
      type: 'adjustment',
      name: params.name ?? 'Adjustment',
      transform: defaultTransform(),
      blendMode: 'normal',
      visible: true,
      locked: false,
      adjustmentType: params.adjustmentType ?? 'hue-saturation',
      params: { hue: 0, saturation: 0, lightness: 0 },
    },
    params,
  )
}

/** 创建 Fill 对象 */
export function createFillObject(params: CreateNodeParams & {
  fillType?: 'solid' | 'gradient' | 'pattern'
  color?: string
  gradient?: Gradient
} = {}): FillObject {
  return applyParams(
    {
      id: genId('fill'),
      type: 'fill',
      name: params.name ?? 'Fill',
      transform: defaultTransform(),
      blendMode: 'normal',
      visible: true,
      locked: false,
      fillType: params.fillType ?? 'solid',
      color: params.color ?? '#3AC487',
      gradient: params.gradient,
    },
    params,
  )
}

/** 创建 Mask */
export function createMask(type: 'raster' | 'vector' = 'raster'): Mask {
  return {
    type,
    data: '',
    enabled: true,
    inverted: false,
  }
}

/** 创建 LayerEffect */
export function createLayerEffect(
  type: LayerEffect['type'],
  params: Record<string, number | string | boolean> = {},
): LayerEffect {
  const defaults: Record<LayerEffect['type'], Record<string, number | string | boolean>> = {
    'drop-shadow': { angle: 120, distance: 5, blur: 4, color: '#000000', opacity: 40 },
    'inner-shadow': { angle: 120, distance: 3, blur: 3, color: '#000000', opacity: 40 },
    'outer-glow': { blur: 8, spread: 0, color: '#3AC487', opacity: 50 },
    'inner-glow': { blur: 5, spread: 0, color: '#3AC487', opacity: 50 },
    'bevel': { style: 'inner', depth: 50, direction: 'up', size: 4, soften: 0 },
    'satin': { angle: 19, distance: 11, size: 14, color: '#000000', opacity: 50 },
    'color-overlay': { color: '#3AC487', opacity: 100 },
    'gradient-overlay': { angle: 90, opacity: 100, gradient: '' },
    'pattern-overlay': { scale: 100, opacity: 100, src: '' },
  }
  return {
    id: genId('fx'),
    type,
    enabled: true,
    params: { ...defaults[type], ...params },
  }
}

/** 根据类型创建任意对象 */
export function createObjectByType(type: SceneObject['type'], params: CreateNodeParams = {}): SceneObject {
  switch (type) {
    case 'text': return createTextObject(params)
    case 'image': return createImageObject(params)
    case 'shape': return createShapeObject(params)
    case 'group': return createGroupObject(params)
    case 'adjustment': return createAdjustmentObject(params)
    case 'fill': return createFillObject(params)
    default: throw new Error(`Unknown object type: ${type}`)
  }
}
