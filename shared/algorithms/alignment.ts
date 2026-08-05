/**
 * 对齐与分布算法（跨端共享）
 *
 * 对应原型 Inspector.vue 中的对齐分布逻辑
 * 纯函数，不依赖任何框架，可在 Vue/ArkTS 中共享。
 */
import { SceneObject } from '../types/scene'

/** 计算对象包围盒 */
export interface BBox {
  minX: number
  minY: number
  maxX: number
  maxY: number
  width: number
  height: number
}

export function getObjectBBox(obj: SceneObject): BBox {
  const t = obj.transform
  return {
    minX: t.x,
    minY: t.y,
    maxX: t.x + t.width,
    maxY: t.y + t.height,
    width: t.width,
    height: t.height,
  }
}

/** 计算多个对象的合并包围盒 */
export function getCombinedBBox(objects: SceneObject[]): BBox | null {
  if (objects.length === 0) return null
  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (const o of objects) {
    const b = getObjectBBox(o)
    minX = Math.min(minX, b.minX)
    minY = Math.min(minY, b.minY)
    maxX = Math.max(maxX, b.maxX)
    maxY = Math.max(maxY, b.maxY)
  }
  return { minX, minY, maxX, maxY, width: maxX - minX, height: maxY - minY }
}

/** 对齐类型 */
export type AlignType =
  | 'left' | 'center-h' | 'right'
  | 'top' | 'center-v' | 'bottom'

/** 对齐对象（修改第一个参数 objects 的 transform） */
export function alignObjects(objects: SceneObject[], type: AlignType): void {
  if (objects.length < 2) return
  const bbox = getCombinedBBox(objects)
  if (!bbox) return
  for (const o of objects) {
    const t = o.transform
    switch (type) {
      case 'left':
        t.x = bbox.minX
        break
      case 'center-h':
        t.x = bbox.minX + (bbox.width - t.width) / 2
        break
      case 'right':
        t.x = bbox.maxX - t.width
        break
      case 'top':
        t.y = bbox.minY
        break
      case 'center-v':
        t.y = bbox.minY + (bbox.height - t.height) / 2
        break
      case 'bottom':
        t.y = bbox.maxY - t.height
        break
    }
  }
}

/** 分布类型 */
export type DistributeType = 'horizontal' | 'vertical'

/** 分布对象（均匀间距） */
export function distributeObjects(objects: SceneObject[], type: DistributeType): void {
  if (objects.length < 3) return
  // 按位置排序
  const sorted = [...objects].sort((a, b) => {
    return type === 'horizontal'
      ? a.transform.x - b.transform.x
      : a.transform.y - b.transform.y
  })
  if (type === 'horizontal') {
    const first = sorted[0]
    const last = sorted[sorted.length - 1]
    const totalWidth = (last.transform.x + last.transform.width) - first.transform.x
    const sumObjWidth = sorted.reduce((s, o) => s + o.transform.width, 0)
    const gapCount = sorted.length - 1
    const gap = (totalWidth - sumObjWidth) / gapCount
    let cursor = first.transform.x + first.transform.width + gap
    for (let i = 1; i < sorted.length - 1; i++) {
      sorted[i].transform.x = cursor
      cursor += sorted[i].transform.width + gap
    }
  } else {
    const first = sorted[0]
    const last = sorted[sorted.length - 1]
    const totalHeight = (last.transform.y + last.transform.height) - first.transform.y
    const sumObjHeight = sorted.reduce((s, o) => s + o.transform.height, 0)
    const gapCount = sorted.length - 1
    const gap = (totalHeight - sumObjHeight) / gapCount
    let cursor = first.transform.y + first.transform.height + gap
    for (let i = 1; i < sorted.length - 1; i++) {
      sorted[i].transform.y = cursor
      cursor += sorted[i].transform.height + gap
    }
  }
}
