/* ── TypeScript Types for Harmony Design Studio ── */

/** Button variants */
export type ButtonVariant = 'primary' | 'secondary' | 'text' | 'danger' | 'success'

/** Button sizes */
export type ButtonSize = 'sm' | 'md' | 'lg'

/** Button states */
export type ButtonState = 'default' | 'hover' | 'focus' | 'disabled' | 'loading'

/** Menu item */
export interface MenuItem {
  label?: string
  shortcut?: string
  icon?: string
  children?: MenuItem[]
  divider?: boolean
  disabled?: boolean
}

/** Component library category */
export interface ComponentCategory {
  name: string
  count: number
  icon?: string
  items: ComponentItem[]
}

/** Component library item */
export interface ComponentItem {
  name: string
  description?: string
  icon?: string
}

/** Color token group */
export interface ColorGroup {
  name: string
  colors: ColorToken[]
}

/** Color token */
export interface ColorToken {
  name: string
  value: string
  hex: string
  cssVar?: string
}

/** Page tab */
export interface PageTab {
  id: string
  name: string
  thumb?: string
  isActive?: boolean
}

/** Tool rail item */
export interface ToolItem {
  name: string
  icon: string
  active?: boolean
}

/** Layer item */
export interface LayerItem {
  name: string
  type: 'text' | 'image' | 'shape' | 'group' | 'adjustment' | 'fill'
  visible: boolean
  locked?: boolean
  active?: boolean
  icon?: string
  iconColor?: string
}

/** Context menu item (通用右键菜单) */
export interface ContextMenuItem {
  label?: string
  icon?: string
  shortcut?: string
  action?: string
  children?: ContextMenuItem[]
  divider?: boolean
  disabled?: boolean
  danger?: boolean
}

/** Inspector section */
export interface PositionSize {
  x: number
  y: number
  width: number
  height: number
  unit: string
}

/* ── Fusion DOM 类型系统 ── */

/** 混合模式（PS 标准 + CSS mix-blend-mode） */
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
  | 'scene'        // 文档场景（根）
  | 'layer'        // 图层容器
  | 'group'        // 组对象
  | 'text'         // 文本对象
  | 'image'        // 位图对象
  | 'shape'        // 矢量形状
  | 'adjustment'   // 调整图层
  | 'fill'         // 填充图层

/** 变换矩阵（位置/尺寸/旋转/缩放/翻转） */
export interface Transform {
  x: number
  y: number
  width: number
  height: number
  rotation: number      // 度，0-360
  scaleX: number        // 1 = 100%
  scaleY: number
  flipH: boolean
  flipV: boolean
  opacity: number       // 0-100
}

/** 蒙版 */
export interface Mask {
  type: 'raster' | 'vector'
  data: string          // dataURL 或 SVG path
  enabled: boolean
  inverted: boolean
}

/** 图层效果（FX） */
export interface LayerEffect {
  id: string
  type:
    | 'drop-shadow' | 'inner-shadow'
    | 'outer-glow' | 'inner-glow'
    | 'bevel' | 'satin'
    | 'color-overlay' | 'gradient-overlay' | 'pattern-overlay'
  enabled: boolean
  params: Record<string, number | string | boolean>
}

/** 基础节点（所有节点共享字段） */
export interface BaseNode {
  id: string
  type: NodeType
  name: string
  transform: Transform
  blendMode: BlendMode
  visible: boolean
  locked: boolean
  metadata?: Record<string, unknown>
}

/** Shape 子类型 */
export type ShapeKind =
  | 'rectangle' | 'ellipse' | 'polygon'
  | 'star' | 'line' | 'path' | 'custom'

/** 渐变 */
export interface Gradient {
  type: 'linear' | 'radial' | 'conic'
  angle: number
  stops: { offset: number; color: string; opacity?: number }[]
}

/** Image 滤镜 */
export interface ImageFilter {
  type: 'blur' | 'sharpen' | 'brightness' | 'contrast' | 'hue-rotate' | 'saturate' | 'grayscale' | 'sepia' | 'invert'
  value: number
}

/** 文本对象 */
export interface TextObject extends BaseNode {
  type: 'text'
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
  type: 'image'
  src: string
  naturalWidth: number
  naturalHeight: number
  filters?: ImageFilter[]
}

/** 矢量形状 */
export interface ShapeObject extends BaseNode {
  type: 'shape'
  shape: ShapeKind
  fill: string
  stroke: string
  strokeWidth: number
  path?: string         // SVG path data（仅 shape='path' 或 'custom'）
  cornerRadius?: number  // 仅 rectangle
  sides?: number         // 仅 polygon/star
}

/** 组对象 */
export interface GroupObject extends BaseNode {
  type: 'group'
  children: SceneObject[]
}

/** 调整图层 */
export interface AdjustmentObject extends BaseNode {
  type: 'adjustment'
  adjustmentType:
    | 'hue-saturation'
    | 'brightness-contrast'
    | 'curves'
    | 'levels'
    | 'color-balance'
    | 'invert'
    | 'threshold'
    | 'posterize'
  params: Record<string, number>
}

/** 填充图层 */
export interface FillObject extends BaseNode {
  type: 'fill'
  fillType: 'solid' | 'gradient' | 'pattern'
  color: string
  gradient?: Gradient
  patternSrc?: string
}

/** 场景对象（联合类型） */
export type SceneObject =
  | TextObject
  | ImageObject
  | ShapeObject
  | GroupObject
  | AdjustmentObject
  | FillObject

/** 图层容器 */
export interface Layer extends BaseNode {
  type: 'layer'
  parentId: string          // Scene ID 或 GroupLayer ID
  objects: SceneObject[]
  hasMask: boolean
  maskEnabled: boolean
  mask?: Mask
  effects: LayerEffect[]
}

/** 文档场景（根节点） */
export interface Scene extends BaseNode {
  type: 'scene'
  /**
   * 顶层图层列表。
   * - 单页面模式：直接存放图层
   * - 多页面模式：留空，改用 pages
   * 兼容性：序列化时若 pages 非空，children 会被忽略。
   */
  children: Layer[]
  /**
   * 多页面列表（可选）。
   * 当存在时，渲染器按 currentPageId 切换页面。
   * 若为空数组或 undefined，则回退到 children 单页面模式。
   */
  pages?: Page[]
  /** 当前激活页面 ID（多页面模式下使用） */
  currentPageId?: string
  /**
   * Frame 列表（新架构：融合多重模式）。
   * 当存在时，渲染器使用无限画布 + Frame 容器模式。
   * 兼容性：序列化时若 frames 非空，pages/children 会被忽略。
   */
  frames?: Frame[]
  /** 当前激活 Frame ID（无限画布模式下使用） */
  selectedFrameId?: string
  /** 无限画布配置（仅 frames 模式下使用） */
  canvas?: InfiniteCanvasConfig
  canvasWidth: number
  canvasHeight: number
  unit: Unit
  dpi: number
  colorSpace: ColorSpace
  bleed?: { top: number; right: number; bottom: number; left: number }
  background?: string        // 画布背景色
}

/** 页面（多页面文档的基本单元） */
export interface Page {
  id: string
  name: string
  /** 页面尺寸（继承自 Scene，可单独覆盖） */
  width?: number
  height?: number
  /** 页面背景色（可覆盖 Scene.background） */
  background?: string
  /** 页面内的图层列表 */
  children: Layer[]
  /** 是否隐藏 */
  hidden?: boolean
  /** 缩略图（dataURL） */
  thumbnail?: string
  /** 创建时间 */
  createdAt?: string
}

/* ── 无限画布 + Frame 架构 ── */

/** Frame 类型：决定画板的组织方式与交互特性 */
export type FrameType =
  | 'single'      // 单页画板
  | 'poster'      // 海报画板（大尺寸）
  | 'book-page'   // 书籍单页
  | 'spread'      // 书籍对页（左右两页成组）

/** 无限画布视口配置 */
export interface InfiniteCanvasConfig {
  /** 视口中心坐标（画布坐标系） */
  viewportX: number
  viewportY: number
  /** 缩放比例（1 = 100%） */
  zoom: number
  /** 背景样式 */
  background: 'grid' | 'dots' | 'plain'
  /** 是否显示标尺 */
  showRulers: boolean
}

/** Frame（画板）：无限画布上的创作单元 */
export interface Frame {
  id: string
  /** Frame 类型：决定组织方式 */
  type: FrameType
  /** Frame 名称（如"页面 1"、"海报 A"、"第 3 页"） */
  name: string
  /** 在无限画布上的 X 坐标 */
  x: number
  /** 在无限画布上的 Y 坐标 */
  y: number
  /** Frame 宽度 */
  width: number
  /** Frame 高度 */
  height: number
  /** Frame 背景色（默认白色） */
  background?: string
  /** Frame 内的图层列表 */
  children: Layer[]
  /** 是否隐藏 */
  hidden?: boolean
  /** 缩略图（dataURL） */
  thumbnail?: string
  /** 创建时间 */
  createdAt?: string
  /** 书籍模式：在书中的页码顺序（从1开始） */
  order?: number
  /** 书籍模式：对页关联的 Frame ID（spread 模式下使用） */
  spreadWith?: string
  /** 书籍模式：左页/右页标识（spread 模式下使用） */
  spreadSide?: 'left' | 'right'
  /** 是否显示页码 */
  showPageNumber?: boolean
  /** 页码格式（如"{n}"表示数字） */
  pageNumberFormat?: string
}

/** 文档元数据 */
export interface DocumentMetadata {
  createdAt: string
  modifiedAt: string
  author?: string
  description?: string
  tags?: string[]
  thumbnail?: string
  fonts?: string[]
  swatches?: string[]
}

/** HDS 文档（序列化根结构） */
export interface HdsDocument {
  version: string            // 文件格式版本，如 "3.0"
  scene: Scene
  metadata: DocumentMetadata
}

/** 创建节点参数（用于工厂方法） */
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
