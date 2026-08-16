/** 应用沙箱文件持久化，避免把文档内容伪装成 AppStorage。 */
import fileIo from '@ohos.file.fs'
import { BusinessError } from '@ohos.base'
import buffer from '@ohos.buffer'
import cryptoFramework from '@ohos.security.cryptoFramework'
import { AppContext } from './AppContext'
import {
  PersistenceReadResult,
  PersistenceWriteResult,
  readOk,
  readFailed,
  writeOk,
  writeFailed,
  textChecksum,
  copyBytes,
} from './PersistenceTypes'

/** 导出写回校验结果：data 为读回的磁盘字节，checksum 为 SHA-256。 */
export interface FileVerifyResult {
  ok: boolean
  reason: string | null
  path: string | null
  bytes: number
  checksum: string
  data: ArrayBuffer | null
}

const DOCUMENT_FILE = 'larkdesign-document.json'

function pathJoin(root: string, name: string): string {
  return root.replace(/\\+$/, '') + '/' + name
}

export class FilePersistence {
  static documentPath(): string | null {
    const context = AppContext.get()
    if (context === null) return null
    return pathJoin(context.filesDir, DOCUMENT_FILE)
  }

  /** 读取文档。not-found 表示首次启动；read-io 表示权限/文件系统故障，调用方不得静默当作无文件。 */
  static async readDocument(): Promise<PersistenceReadResult> {
    const path = FilePersistence.documentPath()
    if (path === null) {
      return readFailed('no-context', 'application context is not initialized', null)
    }
    try {
      const exists = await fileIo.access(path)
      if (!exists) {
        return readFailed('not-found', 'document file does not exist', path)
      }
    } catch (error) {
      const e = error as BusinessError
      return readFailed('read-io', 'access failed code=' + e.code + ' ' + e.message, path)
    }
    try {
      const json = await fileIo.readText(path)
      console.info('FilePersistence', 'read ok path=' + path + ' chars=' + json.length + ' checksum=' + textChecksum(json))
      return readOk(json, path)
    } catch (error) {
      const e = error as BusinessError
      console.error('FilePersistence', 'read failed path=' + path + ' code=read-io errno=' + e.code + ' ' + e.message)
      return readFailed('read-io', 'read failed code=' + e.code + ' ' + e.message, path)
    }
  }

  /** 写入文档：UTF-8 编码后按字节校验写入完整性，成功时返回字节数与校验和。 */
  static async writeDocument(json: string): Promise<PersistenceWriteResult> {
    const path = FilePersistence.documentPath()
    if (path === null) {
      return writeFailed('no-context', 'application context is not initialized', null)
    }
    let encoded: ArrayBuffer
    try {
      const source = buffer.from(json, 'utf-8')
      encoded = copyBytes(new Uint8Array(source.buffer, source.byteOffset, source.length))
    } catch (error) {
      const e = error as BusinessError
      console.error('FilePersistence', 'utf-8 encode failed path=' + path + ' code=write-io ' + e.message)
      return writeFailed('write-io', 'utf-8 encode failed: ' + e.message, path)
    }
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      const written = await fileIo.write(file.fd, encoded)
      if (written !== encoded.byteLength) {
        console.error('FilePersistence', 'short write path=' + path + ' code=short-write ' + written + '/' + encoded.byteLength)
        return writeFailed('short-write', 'written=' + written + ' expected=' + encoded.byteLength, path)
      }
      const checksum = textChecksum(json)
      console.info('FilePersistence', 'write ok path=' + path + ' bytes=' + written + ' checksum=' + checksum)
      return writeOk(path, written, checksum)
    } catch (error) {
      const e = error as BusinessError
      console.error('FilePersistence', 'write failed path=' + path + ' code=write-io errno=' + e.code + ' ' + e.message)
      return writeFailed('write-io', 'write failed code=' + e.code + ' ' + e.message, path)
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file)
        } catch (error) {
          console.error('FilePersistence', 'close document failed: ' + error)
        }
      }
    }
  }

  /** 删除已保存文档；文件不存在视为成功（幂等）。 */
  static async deleteDocument(): Promise<PersistenceWriteResult> {
    const path = FilePersistence.documentPath()
    if (path === null) {
      return writeFailed('no-context', 'application context is not initialized', null)
    }
    try {
      const exists = await fileIo.access(path)
      if (!exists) {
        return writeOk(path, 0, '')
      }
    } catch (error) {
      const e = error as BusinessError
      return writeFailed('delete-io', 'access failed code=' + e.code + ' ' + e.message, path)
    }
    try {
      await fileIo.unlink(path)
      console.info('FilePersistence', 'delete ok path=' + path)
      return writeOk(path, 0, '')
    } catch (error) {
      const e = error as BusinessError
      console.error('FilePersistence', 'delete failed path=' + path + ' code=delete-io errno=' + e.code + ' ' + e.message)
      return writeFailed('delete-io', 'delete failed code=' + e.code + ' ' + e.message, path)
    }
  }

  /** 按字节读回指定文件；用于导出后的写回校验。 */
  static async readFileBytes(path: string): Promise<ArrayBuffer> {
    let file: fileIo.File | null = null
    try {
      const size = (await fileIo.stat(path)).size
      const buf = new ArrayBuffer(size)
      file = await fileIo.open(path, fileIo.OpenMode.READ_ONLY)
      const read = await fileIo.read(file.fd, buf)
      if (read !== size) {
        throw new Error('读取长度不足: ' + read + '/' + size)
      }
      return buf
    } catch (error) {
      console.error('FilePersistence', 'read file bytes failed path=' + path + ' ' + error)
      throw new Error('读取文件失败: ' + error)
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file)
        } catch (error) {
          console.error('FilePersistence', 'close read-back failed: ' + error)
        }
      }
    }
  }

  /** 读取文本文件（UTF-8），用于文本导出的往返校验。 */
  static async readFileText(path: string): Promise<string> {
    try {
      return await fileIo.readText(path)
    } catch (error) {
      console.error('FilePersistence', 'read file text failed path=' + path + ' ' + error)
      throw new Error('读取文本失败: ' + error)
    }
  }

  /** 计算 SHA-256 十六进制摘要，作为导出文件的正式哈希证据。 */
  static async sha256Hex(data: ArrayBuffer): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256')
      const blob: cryptoFramework.DataBlob = { data: new Uint8Array(data) }
      await md.update(blob)
      const digest = await md.digest()
      let hex = ''
      for (let i = 0; i < digest.data.length; i++) {
        const part = digest.data[i].toString(16)
        hex += part.length === 1 ? '0' + part : part
      }
      return hex
    } catch (error) {
      console.error('FilePersistence', 'SHA-256 计算失败: ' + error)
      throw new Error('SHA-256 计算失败: ' + error)
    }
  }

  /** 导出后写回校验：重新读磁盘、比对字节数并计算 SHA-256。 */
  static async verifyWrittenFile(path: string, expected: ArrayBuffer): Promise<FileVerifyResult> {
    let expectedChecksum = ''
    try {
      expectedChecksum = await FilePersistence.sha256Hex(expected)
    } catch (error) {
      return { ok: false, reason: '源数据 SHA-256 计算失败: ' + error, path: path, bytes: expected.byteLength, checksum: '', data: null }
    }
    let data: ArrayBuffer
    try {
      data = await FilePersistence.readFileBytes(path)
    } catch (error) {
      return { ok: false, reason: '读回失败: ' + error, path: path, bytes: 0, checksum: '', data: null }
    }
    if (data.byteLength !== expected.byteLength) {
      return {
        ok: false,
        reason: '长度不符 read=' + data.byteLength + ' expected=' + expected.byteLength,
        path: path,
        bytes: data.byteLength,
        checksum: '',
        data: null,
      }
    }
    let checksum = ''
    try {
      checksum = await FilePersistence.sha256Hex(data)
    } catch (error) {
      return { ok: false, reason: 'SHA-256 计算失败: ' + error, path: path, bytes: data.byteLength, checksum: '', data: null }
    }
    if (checksum !== expectedChecksum) {
      return {
        ok: false,
        reason: 'SHA-256 不符 read=' + checksum + ' expected=' + expectedChecksum,
        path: path,
        bytes: data.byteLength,
        checksum: '',
        data: null,
      }
    }
    console.info('FilePersistence', 'verify ok path=' + path + ' bytes=' + data.byteLength + ' sha256=' + checksum)
    return { ok: true, reason: null, path: path, bytes: data.byteLength, checksum: checksum, data: data }
  }

  static async writeBytes(name: string, data: ArrayBuffer): Promise<string> {
    const context = AppContext.get()
    if (context === null) throw new Error('application context is not initialized')
    const directory = pathJoin(context.filesDir, 'exports')
    try {
      await fileIo.mkdir(directory)
    } catch (error) {
      // 已存在时 mkdir 会报错，后续 open/write 仍是安全的。
      console.info('FilePersistence', 'export directory exists: ' + error)
    }
    const path = pathJoin(directory, name)
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      const written = await fileIo.write(file.fd, data)
      if (written !== data.byteLength) throw new Error('写入长度不足: ' + written + '/' + data.byteLength)
    } catch (error) {
      throw new Error('写入导出文件失败: ' + error)
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file)
        } catch (error) {
          console.error('FilePersistence', 'close export failed: ' + error)
        }
      }
    }
    return path
  }

  static async writeText(name: string, text: string): Promise<string> {
    const context = AppContext.get()
    if (context === null) throw new Error('application context is not initialized')
    const directory = pathJoin(context.filesDir, 'exports')
    try {
      await fileIo.mkdir(directory)
    } catch (error) {
      console.info('FilePersistence', 'export directory exists: ' + error)
    }
    const path = pathJoin(directory, name)
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      await fileIo.write(file.fd, text)
    } catch (error) {
      throw new Error('写入文本导出失败: ' + error)
    } finally {
      if (file !== null) {
        try {
          await fileIo.close(file)
        } catch (error) {
          console.error('FilePersistence', 'close text export failed: ' + error)
        }
      }
    }
    return path
  }
}
