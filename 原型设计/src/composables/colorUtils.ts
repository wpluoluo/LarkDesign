/**
 * 色彩工具函数 — HEX / RGB / HSL / CMYK 互转
 */

export function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result
    ? { r: parseInt(result[1], 16), g: parseInt(result[2], 16), b: parseInt(result[3], 16) }
    : null
}

export function rgbToHex(r: number, g: number, b: number): string {
  return '#' + [r, g, b].map(x => Math.max(0, Math.min(255, Math.round(x))).toString(16).padStart(2, '0')).join('')
}

export function rgbToHsl(r: number, g: number, b: number): { h: number; s: number; l: number } {
  r /= 255; g /= 255; b /= 255
  const max = Math.max(r, g, b), min = Math.min(r, g, b)
  let h = 0, s = 0, l = (max + min) / 2
  if (max !== min) {
    const d = max - min
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
    switch (max) {
      case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break
      case g: h = ((b - r) / d + 2) / 6; break
      case b: h = ((r - g) / d + 4) / 6; break
    }
  }
  return { h: Math.round(h * 360), s: Math.round(s * 100), l: Math.round(l * 100) }
}

export function hslToRgb(h: number, s: number, l: number): { r: number; g: number; b: number } {
  const hh = h / 60, ss = s / 100, ll = l / 100
  const c = (1 - Math.abs(2 * ll - 1)) * ss
  const x = c * (1 - Math.abs((hh % 2) - 1))
  const m = ll - c / 2
  let r = 0, g = 0, b = 0
  if (hh < 1) { r = c; g = x }
  else if (hh < 2) { r = x; g = c }
  else if (hh < 3) { g = c; b = x }
  else if (hh < 4) { g = x; b = c }
  else if (hh < 5) { r = x; b = c }
  else { r = c; b = x }
  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255)
  }
}

export function rgbToCmyk(r: number, g: number, b: number): { c: number; m: number; y: number; k: number } {
  const rr = r / 255, gg = g / 255, bb = b / 255
  const k = 1 - Math.max(rr, gg, bb)
  if (k === 1) return { c: 0, m: 0, y: 0, k: 100 }
  return {
    c: Math.round(((1 - rr - k) / (1 - k)) * 100),
    m: Math.round(((1 - gg - k) / (1 - k)) * 100),
    y: Math.round(((1 - bb - k) / (1 - k)) * 100),
    k: Math.round(k * 100),
  }
}

export function cmykToRgb(c: number, m: number, y: number, k: number): { r: number; g: number; b: number } {
  const cc = c / 100, mm = m / 100, yy = y / 100, kk = k / 100
  return {
    r: Math.round(255 * (1 - cc) * (1 - kk)),
    g: Math.round(255 * (1 - mm) * (1 - kk)),
    b: Math.round(255 * (1 - yy) * (1 - kk)),
  }
}

export function hexToCmyk(hex: string): { c: number; m: number; y: number; k: number } {
  const rgb = hexToRgb(hex)
  if (!rgb) return { c: 0, m: 0, y: 0, k: 100 }
  return rgbToCmyk(rgb.r, rgb.g, rgb.b)
}

export function cmykToHex(c: number, m: number, y: number, k: number): string {
  const rgb = cmykToRgb(c, m, y, k)
  return rgbToHex(rgb.r, rgb.g, rgb.b)
}

/** Parse HSL string like "152,54,50" to {h,s,l} */
export function parseHsl(str: string): { h: number; s: number; l: number } | null {
  const parts = str.split(',').map(s => parseInt(s.trim()))
  if (parts.length !== 3 || parts.some(isNaN)) return null
  return { h: Math.max(0, Math.min(360, parts[0])), s: Math.max(0, Math.min(100, parts[1])), l: Math.max(0, Math.min(100, parts[2])) }
}
