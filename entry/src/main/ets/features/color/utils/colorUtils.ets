/**
 * colorUtils - 颜色转换工具
 *
 * 对应原型 src/composables/colorUtils.ts
 * HEX / RGB / HSL / CMYK 互转
 */

export interface RgbColor {
  r: number
  g: number
  b: number
}

export interface HslColor {
  h: number
  s: number
  l: number
}

export interface CmykColor {
  c: number
  m: number
  y: number
  k: number
}

/** HEX 字符串转 RGB */
export function hexToRgb(hex: string): RgbColor | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if (!result) return null
  return {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16),
  }
}

/** RGB 转 HEX */
export function rgbToHex(r: number, g: number, b: number): string {
  const toHex = (n: number): string => {
    const v = Math.max(0, Math.min(255, Math.round(n)))
    const s = v.toString(16)
    return s.length === 1 ? '0' + s : s
  }
  return '#' + toHex(r) + toHex(g) + toHex(b)
}

/** RGB 转 HSL */
export function rgbToHsl(r: number, g: number, b: number): HslColor {
  const rr = r / 255
  const gg = g / 255
  const bb = b / 255
  const max = Math.max(rr, gg, bb)
  const min = Math.min(rr, gg, bb)
  let h = 0
  let s = 0
  const l = (max + min) / 2
  if (max !== min) {
    const d = max - min
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
    if (max === rr) {
      h = ((gg - bb) / d + (gg < bb ? 6 : 0)) / 6
    } else if (max === gg) {
      h = ((bb - rr) / d + 2) / 6
    } else {
      h = ((rr - gg) / d + 4) / 6
    }
  }
  return {
    h: Math.round(h * 360),
    s: Math.round(s * 100),
    l: Math.round(l * 100),
  }
}

/** HSL 转 RGB */
export function hslToRgb(h: number, s: number, l: number): RgbColor {
  const hh = h / 60
  const ss = s / 100
  const ll = l / 100
  const c = (1 - Math.abs(2 * ll - 1)) * ss
  const x = c * (1 - Math.abs((hh % 2) - 1))
  const m = ll - c / 2
  let r = 0
  let g = 0
  let b = 0
  if (hh < 1) {
    r = c; g = x
  } else if (hh < 2) {
    r = x; g = c
  } else if (hh < 3) {
    g = c; b = x
  } else if (hh < 4) {
    g = x; b = c
  } else if (hh < 5) {
    r = x; b = c
  } else {
    r = c; b = x
  }
  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255),
  }
}

/** RGB 转 CMYK */
export function rgbToCmyk(r: number, g: number, b: number): CmykColor {
  const rr = r / 255
  const gg = g / 255
  const bb = b / 255
  const k = 1 - Math.max(rr, gg, bb)
  if (k === 1) return { c: 0, m: 0, y: 0, k: 100 }
  return {
    c: Math.round(((1 - rr - k) / (1 - k)) * 100),
    m: Math.round(((1 - gg - k) / (1 - k)) * 100),
    y: Math.round(((1 - bb - k) / (1 - k)) * 100),
    k: Math.round(k * 100),
  }
}

/** CMYK 转 RGB */
export function cmykToRgb(c: number, m: number, y: number, k: number): RgbColor {
  const cc = c / 100
  const mm = m / 100
  const yy = y / 100
  const kk = k / 100
  return {
    r: Math.round(255 * (1 - cc) * (1 - kk)),
    g: Math.round(255 * (1 - mm) * (1 - kk)),
    b: Math.round(255 * (1 - yy) * (1 - kk)),
  }
}

/** HEX 转 CMYK */
export function hexToCmyk(hex: string): CmykColor {
  const rgb = hexToRgb(hex)
  if (!rgb) return { c: 0, m: 0, y: 0, k: 100 }
  return rgbToCmyk(rgb.r, rgb.g, rgb.b)
}

/** CMYK 转 HEX */
export function cmykToHex(c: number, m: number, y: number, k: number): string {
  const rgb = cmykToRgb(c, m, y, k)
  return rgbToHex(rgb.r, rgb.g, rgb.b)
}

/** HSL 转 HEX */
export function hslToHex(h: number, s: number, l: number): string {
  const rgb = hslToRgb(h, s, l)
  return rgbToHex(rgb.r, rgb.g, rgb.b)
}

/** HEX 转 HSL */
export function hexToHsl(hex: string): HslColor {
  const rgb = hexToRgb(hex)
  if (!rgb) return { h: 0, s: 0, l: 0 }
  return rgbToHsl(rgb.r, rgb.g, rgb.b)
}

/** 判断是否为合法的 HEX 颜色 */
export function isValidHex(hex: string): boolean {
  return /^#[0-9a-fA-F]{6}$/.test(hex)
}

/** 将 HEX 转为大写（若合法） */
export function normalizeHex(hex: string): string {
  return isValidHex(hex) ? hex.toUpperCase() : hex
}
