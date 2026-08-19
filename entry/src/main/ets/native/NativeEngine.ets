/**
 * 正式画布 Native 适配层。
 * NAPI 只返回稳定的句柄/ArrayBuffer，PixelMap 在 ArkTS ImageKit 侧创建。
 */
import nativeEngine from 'liblark_engine.so'
import image from '@ohos.multimedia.image'
import { Frame, Layer, SceneObject } from '../domain/SceneTypes'

export interface NativeEngineModule {
  getVersion(): string
  getCapabilities(): number
  createCanvas(width: number, height: number): bigint
  destroyCanvas(canvas: bigint): void
  clearCanvas(canvas: bigint, color: number): void
  drawRect(canvas: bigint, x: number, y: number, width: number, height: number, fill: number, strokeWidth: number, stroke: number): void
  drawRoundRect(canvas: bigint, x: number, y: number, width: number, height: number, rx: number, ry: number, fill: number, strokeWidth: number, stroke: number): void
  drawEllipse(canvas: bigint, x: number, y: number, width: number, height: number, fill: number, strokeWidth: number, stroke: number): void
  drawText(canvas: bigint, text: string, x: number, y: number, size: number, color: number): void
  getPixels(canvas: bigint): ArrayBuffer
  exportPng(canvas: bigint): ArrayBuffer
}

const native: NativeEngineModule = nativeEngine as NativeEngineModule

function colorToArgb(value: string | undefined, fallback: number): number {
  if (value === undefined || value.length === 0) return fallback
  let hex = value.trim()
  if (hex.charAt(0) === '#') hex = hex.substring(1)
  if (hex.length === 6) hex = 'FF' + hex
  if (hex.length !== 8) return fallback
  const parsed = parseInt(hex, 16)
  return Number.isNaN(parsed) ? fallback : parsed >>> 0
}

function drawObject(canvas: bigint, obj: SceneObject): void {
  if (!obj.visible) return
  const t = obj.transform
  const fill = colorToArgb(obj.fill ?? obj.color, 0xFF3AC487)
  const stroke = colorToArgb(obj.stroke, 0xFF1F2329)
  const width = obj.strokeWidth ?? 0
  if (obj.type === 'text') {
    native.drawText(canvas, obj.text ?? obj.name, t.x, t.y + (obj.fontSize ?? 14), obj.fontSize ?? 14,
      colorToArgb(obj.color, 0xFF1F2329))
  } else if (obj.type === 'shape' && obj.shape === 'ellipse') {
    native.drawEllipse(canvas, t.x, t.y, t.width, t.height, fill, width, stroke)
  } else if (obj.type === 'shape' && obj.shape === 'rectangle' && (obj.cornerRadius ?? 0) > 0) {
    const radius = obj.cornerRadius ?? 0
    native.drawRoundRect(canvas, t.x, t.y, t.width, t.height, radius, radius, fill, width, stroke)
  } else if (obj.type === 'group' && obj.children !== undefined) {
    for (const child of obj.children) drawObject(canvas, child)
  } else {
    native.drawRect(canvas, t.x, t.y, t.width, t.height, fill, width, stroke)
  }
}

export class NativeEngine {
  static getVersion(): string { return native.getVersion() }
  static getCapabilities(): number { return native.getCapabilities() }

  static async renderFrame(frame: Frame): Promise<PixelMap | null> {
    if (frame.width <= 0 || frame.height <= 0) return null
    const canvas = native.createCanvas(Math.round(frame.width), Math.round(frame.height))
    try {
      native.clearCanvas(canvas, colorToArgb(frame.background, 0xFFFFFFFF))
      for (const layer of frame.children) {
        if (!layer.visible) continue
        for (const obj of layer.objects) drawObject(canvas, obj)
      }
      const pixels = native.getPixels(canvas)
      return await image.createPixelMap(pixels, {
        size: { width: Math.round(frame.width), height: Math.round(frame.height) },
        srcPixelFormat: image.PixelMapFormat.RGBA_8888,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.UNPREMUL,
      })
    } finally {
      native.destroyCanvas(canvas)
    }
  }

  static async renderPng(frame: Frame): Promise<ArrayBuffer | null> {
    const canvas = native.createCanvas(Math.round(frame.width), Math.round(frame.height))
    try {
      native.clearCanvas(canvas, colorToArgb(frame.background, 0xFFFFFFFF))
      for (const layer of frame.children) {
        if (!layer.visible) continue
        for (const obj of layer.objects) drawObject(canvas, obj)
      }
      return native.exportPng(canvas)
    } finally {
      native.destroyCanvas(canvas)
    }
  }
}
