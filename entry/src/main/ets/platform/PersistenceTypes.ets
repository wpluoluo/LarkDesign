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
