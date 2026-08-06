/**
 * CanvasRenderer - 画布渲染辅助引擎
 *
 * 对应原型 src/composables/useCanvasRenderer.ts + src/fusion/renderer.ts
 * 职责：
 *  - Frame/图层/对象的扁平化查询
 *  - 对象显示样式计算（颜色、圆角、描边）
 *  - 选中对象包围盒计算
 *  - Frame 类型图标映射
 *  - 导出辅助（PixelMap / dataURL）
 *
 * 设计说明：
 *  - 本类为无状态工具类，所有方法均为纯函数或静态方法
 *  - @Builder 渲染方法仍保留在 CanvasStage 组件中
 *  - 本类只提供数据计算与查询，不涉及 ArkUI UI 树
 */
import { Frame, Layer, SceneObject, Transform, ShapeKind, Size } from '../types/SceneTypes'

/** 画布对象与图层ID的映射 */
export interface ObjectWithLayer {
  obj: SceneObject
  layerId: string
}

export class CanvasRenderer {
  private static instance: CanvasRenderer

  private constructor() {}

  static getInstance(): CanvasRenderer {
    if (!CanvasRenderer.instance) {
      CanvasRenderer.instance = new CanvasRenderer()
    }
    return CanvasRenderer.instance
  }

  // ─── 对象查询 ───
  /**
   * 扁平化 Frame 的所有图层对象
   * @param frame 目标 Frame，null 时返回空数组
   * @returns 对象列表（含 layerId）
   */
  static getObjectsFromFrame(frame: Frame | null): ObjectWithLayer[] {
    if (!frame) return []
    const result: ObjectWithLayer[] = []
    for (const layer of frame.children) {
      if (!layer.visible) continue
      for (const obj of layer.objects) {
        if (!obj.visible) continue
        result.push({ obj: obj, layerId: layer.id } as ObjectWithLayer)
      }
    }
    return result
  }

  /**
   * 在对象列表中查找指定 ID 的对象
   */
  static findObjectById(objects: ObjectWithLayer[], id: string): ObjectWithLayer | null {
    for (const item of objects) {
      if (item.obj.id === id) return item
    }
    return null
  }

  /**
   * 获取对象所在图层
   */
  static findLayerOfObject(frame: Frame | null, objId: string): Layer | null {
    if (!frame) return null
    for (const layer of frame.children) {
      for (const obj of layer.objects) {
        if (obj.id === objId) return layer
      }
    }
    return null
  }

  // ─── 显示样式计算 ───
  /**
   * 获取对象填充色（按类型回退）
   * 矩形/形状 → fill，文字 → color，图片 → backgroundColor
   */
  static getObjectFill(obj: SceneObject): string {
    if (obj.type === 'text') {
      return obj.color ?? '#1F2329'
    }
    if (obj.type === 'image') {
      return obj.fill ?? '#F3F5F7'
    }
    return obj.fill ?? '#3AC487'
  }

  /** 获取对象描边色 */
  static getObjectStroke(obj: SceneObject): string {
    return obj.stroke ?? '#00000000'
  }

  /** 获取对象描边宽度 */
  static getObjectStrokeWidth(obj: SceneObject): number {
    return obj.strokeWidth ?? 0
  }

  /** 获取对象圆角（仅矩形） */
  static getObjectCornerRadius(obj: SceneObject): number {
    return obj.cornerRadius ?? 0
  }

  /** 获取对象字号（文字） */
  static getObjectFontSize(obj: SceneObject): number {
    return obj.fontSize ?? 14
  }

  /** 获取对象字重（文字） */
  static getObjectFontWeight(obj: SceneObject): number {
    return obj.fontWeight ?? 400
  }

  /** 判断是否为椭圆 */
  static isEllipse(obj: SceneObject): boolean {
    return obj.type === 'shape' && obj.shape === 'ellipse'
  }

  /** 判断是否为线条 */
  static isLine(obj: SceneObject): boolean {
    return obj.type === 'shape' && obj.shape === 'line'
  }

  /** 判断是否为文字 */
  static isText(obj: SceneObject): boolean {
    return obj.type === 'text'
  }

  /** 判断是否为图片 */
  static isImage(obj: SceneObject): boolean {
    return obj.type === 'image'
  }

  /** 获取对象显示文本（文字对象） */
  static getDisplayText(obj: SceneObject): string {
    return obj.text ?? obj.name
  }

  // ─── 选中包围盒 ───
  /**
   * 计算多个对象的包围盒
   * @returns 包围盒 Transform，无对象时返回 null
   */
  static computeBounds(objects: SceneObject[]): Transform | null {
    if (objects.length === 0) return null
    let minX = Infinity
    let minY = Infinity
    let maxX = -Infinity
    let maxY = -Infinity
    for (const obj of objects) {
      minX = Math.min(minX, obj.transform.x)
      minY = Math.min(minY, obj.transform.y)
      maxX = Math.max(maxX, obj.transform.x + obj.transform.width)
      maxY = Math.max(maxY, obj.transform.y + obj.transform.height)
    }
    return {
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
      rotation: 0,
      scaleX: 1,
      scaleY: 1,
      flipH: false,
      flipV: false,
      opacity: 1,
    } as Transform
  }

  // ─── Frame 类型图标 ───
  /**
   * 获取 Frame 类型图标字符
   * @param iconProvider 图标提供函数（注入 IconCharToken 映射）
   */
  static getFrameTypeIcon(type: string, iconProvider: (key: string) => string): string {
    const map: Record<string, string> = {
      'single': iconProvider('rect'),
      'poster': iconProvider('image'),
      'book-page': iconProvider('book'),
      'spread': iconProvider('book_open'),
    }
    return map[type] ?? iconProvider('rect')
  }

  // ─── 导出辅助 ───
  /** 渲染状态标记（用于 UI 显示加载中） */
  isRendering: boolean = false

  /** 标记渲染开始 */
  beginRender(): void {
    this.isRendering = true
  }

  /** 标记渲染结束 */
  endRender(): void {
    this.isRendering = false
  }

  /**
   * 计算导出尺寸（考虑 DPI）
   * @param width/Height 画布尺寸
   * @param dpi 目标 DPI（默认 72）
   */
  static computeExportSize(width: number, height: number, dpi: number = 72): Size {
    const scale = dpi / 72
    return {
      width: Math.round(width * scale),
      height: Math.round(height * scale),
    } as Size
  }

  /**
   * 将 Frame 内容导出为 PixelMap 的尺寸参数
   */
  static getFrameExportSize(frame: Frame, dpi: number = 72): Size {
    return CanvasRenderer.computeExportSize(frame.width, frame.height, dpi) as Size
  }
}
