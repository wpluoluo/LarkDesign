import re

with open(r'F:\LarkDesign\entry\src\main\ets\stores\FusionDocumentStore.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add serializer import
old_import = "import { FusionDocumentStoreInfo } from './FusionDocumentStoreInfo'"
new_import = "import { FusionDocumentStoreInfo } from './FusionDocumentStoreInfo'\nimport { serialize, deserialize, deepClone, estimateSize } from '../types/FusionSerializer'"
content = content.replace(old_import, new_import, 1)

# 2. Add persistence methods after init()
old_init = '''  /** 初始化 */
  init(): void {
    this.pushHistory()
  }'''
new_init = '''  /** 初始化 */
  init(): void {
    this.loadFromStorage()
    this.pushHistory()
  }

  /** 自动保存（防抖 500ms） */
  private autoSaveTimer: number = -1
  private scheduleAutoSave(): void {
    if (this.autoSaveTimer >= 0) {
      clearTimeout(this.autoSaveTimer)
    }
    this.autoSaveTimer = setTimeout(() => {
      this.saveToStorage()
    }, 500)
  }

  /** 保存文档到 AppStorage */
  saveToStorage(): void {
    try {
      const json = serialize(this.doc, true)
      AppStorage.setOrCreate<string>('hds_document', json)
      AppStorage.setOrCreate<string>('hds_last_saved', new Date().toISOString())
    } catch (e) {
      console.error('FusionDocumentStore', 'saveToStorage failed: ' + e)
    }
  }

  /** 从 AppStorage 加载文档 */
  loadFromStorage(): void {
    try {
      const json = AppStorage.get<string>('hds_document')
      if (json and json.length > 0) {
        this.doc = deserialize(json)
        console.info('FusionDocumentStore', 'Loaded document from storage, size: ' + estimateSize(this.doc) + 'KB')
      }
    } catch (e) {
      console.error('FusionDocumentStore', 'loadFromStorage failed: ' + e)
    }
  }

  /** 清除存储的文档 */
  clearStorage(): void {
    AppStorage.delete('hds_document')
    AppStorage.delete('hds_last_saved')
  }'''

content = content.replace(old_init, new_init, 1)

# 3. Update pushHistory to also schedule auto-save
old_push = '  private pushHistory(): void {'
new_push = '  private pushHistory(): void {\n    this.scheduleAutoSave()'
content = content.replace(old_push, new_push, 1)

with open(r'F:\LarkDesign\entry\src\main\ets\stores\FusionDocumentStore.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print('FusionDocumentStore updated with persistence')
