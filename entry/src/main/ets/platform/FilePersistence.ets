/** 应用沙箱文件持久化，避免把文档内容伪装成 AppStorage。 */
import fileIo from '@ohos.file.fs'
import { BusinessError } from '@ohos.base'
import buffer from '@ohos.buffer'
import { AppContext } from './AppContext'
import {
  PersistenceReadResult,
  PersistenceWriteResult,
  readOk,
  readFailed,
  writeOk,
  writeFailed,
  textChecksum,
} from './PersistenceTypes'

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
    let encoded: buffer.Buffer
    try {
      encoded = buffer.from(json, 'utf-8')
    } catch (error) {
      const e = error as BusinessError
      console.error('FilePersistence', 'utf-8 encode failed path=' + path + ' code=write-io ' + e.message)
      return writeFailed('write-io', 'utf-8 encode failed: ' + e.message, path)
    }
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      const written = await fileIo.write(file.fd, encoded.buffer)
      if (written !== encoded.length) {
        console.error('FilePersistence', 'short write path=' + path + ' code=short-write ' + written + '/' + encoded.length)
        return writeFailed('short-write', 'written=' + written + ' expected=' + encoded.length, path)
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
      if (written !== data.byteLength) throw new Error('short write: ' + written + '/' + data.byteLength)
    } catch (error) {
      throw new Error('write export failed: ' + error)
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
      throw new Error('write text export failed: ' + error)
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
