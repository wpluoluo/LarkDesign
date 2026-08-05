/**
 * 命中检测算法（跨端共享）
 *
 * 对应原型 useCanvasInteraction.ts 中的命中检测逻辑
 */

import { SceneObject } from '../types/scene'

/** 点是否在对象内（AABB 命中） */
export function hitTestPoint(obj: SceneObject, x: number, y: number): boolean {
  const t = obj.transform
  // 考虑旋转：简化为 AABB，实际场景下旋转角度通常较小
  // 如需精确旋转命中，需要将点反向旋转到局部坐标系
  return x >= t.x && x <= t.x + t.width && y >= t.y && y <= t.y + t.height
}

/** 在对象列表中查找点命中的对象（返回最上层，即数组末尾优先） */
export function hitTestObjects(objects: SceneObject[], x: number, y: number): SceneObject | undefined {
  // 从后往前遍历（末尾对象在视觉最上层）
  for (let i = objects.length - 1; i >= 0; i--) {
    const obj = objects[i]
    if (!obj.visible) continue
    if (hitTestPoint(obj, x, y)) return obj
    // 递归 Group
    if (obj.type === 'group' && obj.children) {
      const found = hitTestObjects(obj.children, x, y)
      if (found) return found
    }
  }
  return undefined
}

/** 矩形是否与对象相交（用于框选） */
export function rectIntersectsObject(
  obj: SceneObject,
  rectX: number, rectY: number, rectW: number, rectH: number,
): boolean {
  const t = obj.transform
  return !(
    t.x + t.width < rectX ||
    t.x > rectX + rectW ||
    t.y + t.height < rectY ||
    t.y > rectY + rectH
  )
}

/** 查找矩形框选中的所有对象 */
export function hitTestRect(
  objects: SceneObject[],
  rectX: number, rectY: number, rectW: number, rectH: number,
): SceneObject[] {
  const result: SceneObject[] = []
  for (const obj of objects) {
    if (!obj.visible) continue
    if (rectIntersectsObject(obj, rectX, rectY, rectW, rectH)) {
      result.push(obj)
    }
  }
  return result
}

/** handle 位置类型 */
export type HandlePosition = 'nw' | 'n' | 'ne' | 'e' | 'se' | 's' | 'sw' | 'w'

/** handle 的命中区域大小 */
export const HANDLE_SIZE = 8

/** 检测点是否命中某个 handle */
export function hitTestHandle(
  obj: SceneObject,
  px: number, py: number,
): HandlePosition | null {
  const t = obj.transform
  const half = HANDLE_SIZE / 2
  const positions: Array<{ pos: HandlePosition; x: number; y: number }> = [
    { pos: 'nw', x: t.x, y: t.y },
    { pos: 'n', x: t.x + t.width / 2, y: t.y },
    { pos: 'ne', x: t.x + t.width, y: t.y },
    { pos: 'e', x: t.x + t.width, y: t.y + t.height / 2 },
    { pos: 'se', x: t.x + t.width, y: t.y + t.height },
    { pos: 's', x: t.x + t.width / 2, y: t.y + t.height },
    { pos: 'sw', x: t.x, y: t.y + t.height },
    { pos: 'w', x: t.x, y: t.y + t.height / 2 },
  ]
  for (const h of positions) {
    if (px >= h.x - half && px <= h.x + half && py >= h.y - half && py <= h.y + half) {
      return h.pos
    }
  }
  return null
}
