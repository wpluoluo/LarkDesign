/**
 * 坐标转换算法（跨端共享）
 *
 * 对应原型 useInfiniteCanvas.ts 中的坐标转换逻辑
 */

/** 屏幕坐标 → 画布坐标 */
export function screenToCanvas(
  screenX: number, screenY: number,
  viewportX: number, viewportY: number,
  zoom: number, viewportWidth: number, viewportHeight: number,
): { x: number; y: number } {
  return {
    x: (screenX - viewportWidth / 2) / zoom + viewportX,
    y: (screenY - viewportHeight / 2) / zoom + viewportY,
  }
}

/** 画布坐标 → 屏幕坐标 */
export function canvasToScreen(
  canvasX: number, canvasY: number,
  viewportX: number, viewportY: number,
  zoom: number, viewportWidth: number, viewportHeight: number,
): { x: number; y: number } {
  return {
    x: (canvasX - viewportX) * zoom + viewportWidth / 2,
    y: (canvasY - viewportY) * zoom + viewportHeight / 2,
  }
}

/** 以指定点为中心缩放（计算新的 viewport） */
export function zoomAtPoint(
  anchorScreenX: number, anchorScreenY: number,
  newZoom: number, oldZoom: number,
  oldViewportX: number, oldViewportY: number,
  viewportWidth: number, viewportHeight: number,
): { viewportX: number; viewportY: number; zoom: number } {
  // 将锚点转换为画布坐标（使用旧 zoom）
  const anchor = screenToCanvas(
    anchorScreenX, anchorScreenY,
    oldViewportX, oldViewportY, oldZoom, viewportWidth, viewportHeight,
  )
  // 新 viewport：使锚点在屏幕上保持不动
  // anchor.x = (anchorScreenX - viewportWidth/2) / newZoom + newViewportX
  // => newViewportX = anchor.x - (anchorScreenX - viewportWidth/2) / newZoom
  const newViewportX = anchor.x - (anchorScreenX - viewportWidth / 2) / newZoom
  const newViewportY = anchor.y - (anchorScreenY - viewportHeight / 2) / newZoom
  return { viewportX: newViewportX, viewportY: newViewportY, zoom: newZoom }
}

/** 限制 zoom 范围 */
export function clampZoom(zoom: number, min: number = 0.05, max: number = 8): number {
  return Math.max(min, Math.min(max, zoom))
}

/** 计算画布变换矩阵字符串（用于 CSS transform） */
export function canvasTransform(
  viewportX: number, viewportY: number, zoom: number,
  viewportWidth: number, viewportHeight: number,
): string {
  const tx = viewportWidth / 2 - viewportX * zoom
  const ty = viewportHeight / 2 - viewportY * zoom
  return `translate(${tx}px, ${ty}px) scale(${zoom})`
}
