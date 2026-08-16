/**
 * 持久化结果的稳定契约与纯算法。
 * 本文件不得引入任何 @ohos.* 依赖，保证可被本地单元测试（entry/src/test）直接引用。
 */

/** 持久化错误码：跨日志、UI 状态和测试的稳定标识；message 只用于日志，不用于判断。 */
export type PersistenceErrorCode =
  'no-context'    // 应用上下文未初始化（Ability 尚未挂载）
  | 'not-found'   // 目标文件不存在；首次启动属于正常路径
  | 'read-io'     // 读取失败：权限、损坏或文件系统错误
  | 'write-io'    // 写入失败：磁盘满、权限或文件系统错误
  | 'short-write' // 实际写入字节数与编码后长度不符
  | 'delete-io'   // 删除失败
  | 'serialize'   // 文档序列化/反序列化失败

export interface PersistenceReadResult {
  ok: boolean
  code: PersistenceErrorCode | null
  message: string | null
  path: string | null
  json: string | null
}

export interface PersistenceWriteResult {
  ok: boolean
  code: PersistenceErrorCode | null
  message: string | null
  path: string | null
  bytes: number
  checksum: string
}

export function readOk(json: string, path: string): PersistenceReadResult {
  return { ok: true, code: null, message: null, path: path, json: json }
}

export function readFailed(code: PersistenceErrorCode, message: string, path: string | null): PersistenceReadResult {
  return { ok: false, code: code, message: message, path: path, json: null }
}

export function writeOk(path: string, bytes: number, checksum: string): PersistenceWriteResult {
  return { ok: true, code: null, message: null, path: path, bytes: bytes, checksum: checksum }
}

export function writeFailed(code: PersistenceErrorCode, message: string, path: string | null): PersistenceWriteResult {
  return { ok: false, code: code, message: message, path: path, bytes: 0, checksum: '' }
}

function toHex8(value: number): string {
  const masked = value >>> 0
  let hex = masked.toString(16)
  while (hex.length < 8) {
    hex = '0' + hex
  }
  return hex
}

/**
 * FNV-1a 双通道 32 位校验和，输出 16 位十六进制。
 * 按 UTF-16 码元计算，用于日志中的保存/恢复往返核对；
 * 它不是加密哈希，正式证据仍需在主机侧对拉取文件计算 SHA-256。
 */
export function textChecksum(text: string): string {
  let h1 = 0x811c9dc5
  let h2 = 0xc2b2ae35
  for (let i = 0; i < text.length; i++) {
    const unit = text.charCodeAt(i)
    h1 = Math.imul(h1 ^ unit, 0x01000193)
    h2 = Math.imul(h2 ^ unit, 0x85ebca6b)
  }
  return toHex8(h1) + toHex8(h2)
}

/** 字节序列校验和：与 textChecksum 同算法，输入为二进制数据。 */
export function bytesChecksum(data: ArrayBuffer): string {
  const bytes = new Uint8Array(data)
  let h1 = 0x811c9dc5
  let h2 = 0xc2b2ae35
  for (let i = 0; i < bytes.length; i++) {
    h1 = Math.imul(h1 ^ bytes[i], 0x01000193)
    h2 = Math.imul(h2 ^ bytes[i], 0x85ebca6b)
  }
  return toHex8(h1) + toHex8(h2)
}

/** 复制 Uint8Array 当前视图，排除其底层 ArrayBuffer 的前后无关字节。 */
export function copyBytes(source: Uint8Array): ArrayBuffer {
  const target = new ArrayBuffer(source.length)
  new Uint8Array(target).set(source)
  return target
}

/** 把 ASCII 字符串转为字节魔数，供 matchesMagic 使用。 */
export function asciiMagic(text: string): number[] {
  const result: number[] = []
  for (let i = 0; i < text.length; i++) {
    result.push(text.charCodeAt(i))
  }
  return result
}

/** 校验 data 在 offset 处是否以指定魔数开头。 */
export function matchesMagic(data: ArrayBuffer, magic: number[], offset: number): boolean {
  if (data.byteLength < offset + magic.length) return false
  const bytes = new Uint8Array(data)
  for (let i = 0; i < magic.length; i++) {
    if (bytes[offset + i] !== magic[i]) return false
  }
  return true
}

export const PNG_MAGIC: number[] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
export const JPEG_MAGIC: number[] = [0xFF, 0xD8, 0xFF]
export const WEBP_RIFF_MAGIC: number[] = asciiMagic('RIFF')
export const WEBP_BRAND_MAGIC: number[] = asciiMagic('WEBP')
export const PDF_MAGIC: number[] = asciiMagic('%PDF-')

export type ImageExportFormat = 'png' | 'jpeg' | 'webp'

export interface ImageCheckResult {
  ok: boolean
  reason: string | null
}

export interface PdfCheckResult {
  ok: boolean
  pages: number
  reason: string | null
}

/** 校验图片编码格式的必要文件头，防止编码失败时误把错误数据当成导出成功。 */
export function verifyImageStructure(data: ArrayBuffer, format: ImageExportFormat): ImageCheckResult {
  if (format === 'png') {
    return matchesMagic(data, PNG_MAGIC, 0)
      ? { ok: true, reason: null }
      : { ok: false, reason: '缺少 PNG 文件头' }
  }
  if (format === 'jpeg') {
    return matchesMagic(data, JPEG_MAGIC, 0)
      ? { ok: true, reason: null }
      : { ok: false, reason: '缺少 JPEG 文件头' }
  }
  return matchesMagic(data, WEBP_RIFF_MAGIC, 0) && matchesMagic(data, WEBP_BRAND_MAGIC, 8)
    ? { ok: true, reason: null }
    : { ok: false, reason: '缺少 WebP RIFF/WEBP 文件头' }
}

function lastIndexOfAscii(bytes: Uint8Array, needle: string): number {
  const n = needle.length
  for (let i = bytes.length - n; i >= 0; i--) {
    let match = true
    for (let j = 0; j < n; j++) {
      if (bytes[i + j] !== needle.charCodeAt(j)) {
        match = false
        break
      }
    }
    if (match) return i
  }
  return -1
}

/**
 * PDF 结构自检：头/尾标记、startxref 偏移必须精确指向 xref 表、至少一个页对象。
 * 通过自检的文件可被标准解析器按正常路径读取，无需修复模式。
 */
export function verifyPdfStructure(data: ArrayBuffer): PdfCheckResult {
  const bytes = new Uint8Array(data)
  if (!matchesMagic(data, PDF_MAGIC, 0)) {
    return { ok: false, pages: 0, reason: '缺少 %PDF- 文件头' }
  }
  if (lastIndexOfAscii(bytes, '%%EOF') < 0) {
    return { ok: false, pages: 0, reason: '缺少 %%EOF 尾标记' }
  }
  const startxrefAt = lastIndexOfAscii(bytes, 'startxref')
  if (startxrefAt < 0) {
    return { ok: false, pages: 0, reason: '缺少 startxref 偏移' }
  }
  let pos = startxrefAt + 'startxref'.length
  while (pos < bytes.length && (bytes[pos] === 0x20 || bytes[pos] === 0x0D || bytes[pos] === 0x0A)) {
    pos++
  }
  let value = 0
  let digits = 0
  while (pos < bytes.length && bytes[pos] >= 0x30 && bytes[pos] <= 0x39) {
    value = value * 10 + (bytes[pos] - 0x30)
    digits++
    pos++
  }
  if (digits === 0) {
    return { ok: false, pages: 0, reason: 'startxref 缺少偏移值' }
  }
  if (value + 4 > bytes.length) {
    return { ok: false, pages: 0, reason: 'startxref 偏移越界: ' + value }
  }
  if (bytes[value] !== 0x78 || bytes[value + 1] !== 0x72 || bytes[value + 2] !== 0x65 || bytes[value + 3] !== 0x66) {
    return { ok: false, pages: 0, reason: 'startxref 未指向 xref 表（偏移=' + value + '）' }
  }
  let pages = 0
  const marker = '/Type /Page'
  for (let i = 0; i + marker.length <= bytes.length; i++) {
    let match = true
    for (let j = 0; j < marker.length; j++) {
      if (bytes[i + j] !== marker.charCodeAt(j)) {
        match = false
        break
      }
    }
    if (match && bytes[i + marker.length] !== 0x73) {
      pages++
    }
  }
  if (pages <= 0) {
    return { ok: false, pages: 0, reason: '未找到页面对象' }
  }
  return { ok: true, pages: pages, reason: null }
}
