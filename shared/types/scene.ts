/**
 * LarkDesign - 核心类型定义（ArkTS 版本）
 *
 * 对应原型 src/types/index.ts
 * 移除 TS 联合类型中 ArkTS 不支持的部分，改为枚举或字符串常量。
 */

/** 混合模式 */
export type BlendMode =
  | 'normal' | 'multiply' | 'screen' | 'overlay'
  | 'darken' | 'lighten' | 'color-dodge' | 'color-burn'
  | 'hard-light' | 'soft-light' | 'difference' | 'exclusion'
  | 'hue' | 'saturation' | 'color' | 'luminosity'
  | 'pass-through' | 'dissolve'

/** 单位 */
export type Unit = 'mm' | 'cm' | 'px' | 'pt' | 'in'

/** 色彩空间 */
export type ColorSpace = 'sRGB' | 'AdobeRGB' | 'DisplayP3' | 'CMYK'

/** 节点类型 */
export type NodeType =
  | 'scene'
  | 'layer'
  | 'group'
  | 'text'
  | 'image'
  | 'shape'
  | 'adjustment'
  | 'fill'

/** Shape 子类型 */
export type ShapeKind =
  | 'rectangle' | 'ellipse' | 'polygon'
  | 'star' | 'line' | 'path' | 'custom'

/** Frame 类型 */
export type FrameType = 'single' | 'poster' | 'book-page' | 'spread'

/** 变换矩阵 */
export interface Transform {
  x: number
  y: number
  width: number
  height: number
  rotation: number
  scaleX: number
  scaleY: number
  flipH: boolean
  flipV: boolean
  opacity: number
}

/** 蒙版 */
export interface Mask {
  type: 'raster' | 'vector'
  data: string
  enabled: boolean
  inverted: boolean
}

/** 图层效果 */
export interface LayerEffect {
  id: string
  type: 'drop-shadow' | 'inner-shadow' | 'outer-glow' | 'inner-glow'
    | 'bevel' | 'satin' | 'color-overlay' | 'gradient-overlay' | 'pattern-overlay'
  enabled: boolean
  params: Map<string, number | string | boolean>
}

/** 基础节点 */
export interface BaseNode {
  id: string
  type: NodeType
  name: string
  transform: Transform
  blendMode: BlendMode
  visible: boolean
  locked: boolean
  metadata?: Map<string, Object>
}

/** 文本对象 */
export interface TextObject extends BaseNode {
  text: string
  fontFamily: string
  fontSize: number
  fontWeight: number
  fontStyle: 'normal' | 'italic'
  textDecoration: 'none' | 'underline' | 'line-through'
  align: 'left' | 'center' | 'right' | 'justify'
  lineHeight: number
  letterSpacing: number
  color: string
}

/** 位图对象 */
export interface ImageObject extends BaseNode {
  src: string
  naturalWidth: number
  naturalHeight: number
  filters?: ImageFilter[]
}

/** 矢量形状 */
export interface ShapeObject extends BaseNode {
  shape: ShapeKind
  fill: string
  stroke: string
  strokeWidth: number
  path?: string
  cornerRadius?: number
  sides?: number
}

/** 组对象 */
export interface GroupObject extends BaseNode {
  children: SceneObject[]
}

/** 调整图层 */
export interface AdjustmentObject extends BaseNode {
  adjustmentType: 'hue-saturation' | 'brightness-contrast' | 'curves' | 'levels'
    | 'color-balance' | 'invert' | 'threshold' | 'posterize'
  params: Map<string, number>
}

/** 填充图层 */
export interface FillObject extends BaseNode {
  fillType: 'solid' | 'gradient' | 'pattern'
  color: string
  gradient?: Gradient
  patternSrc?: string
}

/** 渐变 */
export interface Gradient {
  type: 'linear' | 'radial' | 'conic'
  angle: number
  stops: GradientStop[]
}

/** 渐变停止点 */
export interface GradientStop {
  offset: number
  color: string
  opacity?: number
}

/** Image 滤镜 */
export interface ImageFilter {
  type: 'blur' | 'sharpen' | 'brightness' | 'contrast' | 'hue-rotate'
    | 'saturate' | 'grayscale' | 'sepia' | 'invert'
  value: number
}

/** 场景对象联合类型（ArkTS 不支持 union，用 type 字段区分） */
export interface SceneObject extends BaseNode {
  // text
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
  // image
  src?: string
  naturalWidth?: number
  naturalHeight?: number
  filters?: ImageFilter[]
  // shape
  shape?: ShapeKind
  fill?: string
  stroke?: string
  strokeWidth?: number
  path?: string
  cornerRadius?: number
  sides?: number
  // group
  children?: SceneObject[]
  // adjustment
  adjustmentType?: string
  params?: Map<string, number>
  // fill
  fillType?: string
  gradient?: Gradient
  patternSrc?: string
}

/** 图层容器 */
export interface Layer extends BaseNode {
  parentId: string
  objects: SceneObject[]
  hasMask: boolean
  maskEnabled: boolean
  mask?: Mask
  effects: LayerEffect[]
}

/** 无限画布视口配置 */
export interface InfiniteCanvasConfig {
  viewportX: number
  viewportY: number
  zoom: number
  background: 'grid' | 'dots' | 'plain'
  showRulers: boolean
}

/** Frame（画板） */
export interface Frame {
  id: string
  type: FrameType
  name: string
  x: number
  y: number
  width: number
  height: number
  background?: string
  children: Layer[]
  hidden?: boolean
  thumbnail?: string
  createdAt?: string
  order?: number
  spreadWith?: string
  spreadSide?: string
  showPageNumber?: boolean
  pageNumberFormat?: string
}

/** 页面 */
export interface Page {
  id: string
  name: string
  width?: number
  height?: number
  background?: string
  children: Layer[]
  hidden?: boolean
  thumbnail?: string
  createdAt?: string
}

/** 文档场景 */
export interface Scene extends BaseNode {
  children: Layer[]
  pages?: Page[]
  currentPageId?: string
  frames?: Frame[]
  selectedFrameId?: string
  canvas?: InfiniteCanvasConfig
  canvasWidth: number
  canvasHeight: number
  unit: Unit
  dpi: number
  colorSpace: ColorSpace
  bleed?: { top: number; right: number; bottom: number; left: number }
  background?: string
}

/** 文档元数据 */
export interface DocumentMetadata {
  createdAt: string
  modifiedAt: string
  author?: string
  description?: string
  tags?: string[]
  fonts?: string[]
  swatches?: string[]
  thumbnail?: string
}

/** HDS 文档 */
export interface HdsDocument {
  version: string
  scene: Scene
  metadata: DocumentMetadata
}
