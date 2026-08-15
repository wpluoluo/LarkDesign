/** 应用沙箱文件持久化，避免把文档内容伪装成 AppStorage。 */
import fileIo from '@ohos.file.fs'
import { AppContext } from './AppContext'

const DOCUMENT_FILE = 'larkdesign-document.json'

function pathJoin(root: string, name: string): string {
  return root.replace(/\\+$/, '') + '/' + name
}

export class FilePersistence {
  static async readDocument(): Promise<string | null> {
    const context = AppContext.get()
    if (context === null) return null
    const path = pathJoin(context.filesDir, DOCUMENT_FILE)
    try {
      return await fileIo.readText(path)
    } catch (error) {
      console.info('FilePersistence', 'document not found: ' + error)
      return null
    }
  }

  static async writeDocument(json: string): Promise<void> {
    const context = AppContext.get()
    if (context === null) throw new Error('application context is not initialized')
    const path = pathJoin(context.filesDir, DOCUMENT_FILE)
    let file: fileIo.File | null = null
    try {
      file = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      await fileIo.write(file.fd, json)
    } catch (error) {
      throw new Error('write document failed: ' + error)
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
