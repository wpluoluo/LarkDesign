/**
 * KeyboardShortcuts - 全局键盘快捷键系统
 *
 * 对应原型 src/composables/useKeyboardShortcuts.ts
 * 在 Index.ets 或 WorkspaceLayout.ets 中通过 onKeyEvent 调用。
 *
 * 快捷键映射：
 *  - 工具切换：V/R/O/T/I/H/Z
 *  - 编辑：Ctrl+Z/Y/C/V/X/D/A、Delete/Backspace
 *  - 视图：Ctrl+0/1/=/-、方向键微调
 *  - 其他：Esc、Space
 */
import { ToolStore, ToolId } from '../stores/ToolStore'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { DocumentStore } from '../stores/DocumentStore'

export class KeyboardShortcuts {
  private static instance: KeyboardShortcuts
  private toolStore: ToolStore = ToolStore.getInstance()
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private docStore: DocumentStore = DocumentStore.getInstance()

  private constructor() {}

  static getInstance(): KeyboardShortcuts {
    if (!KeyboardShortcuts.instance) {
      KeyboardShortcuts.instance = new KeyboardShortcuts()
    }
    return KeyboardShortcuts.instance
  }

  /** 处理键盘事件，返回 true 表示已消费 */
  handleKeyEvent(event: KeyEvent): boolean {
    const key: string = event.keyText
    const code: number = event.keyCode as number
    const ctrl: boolean = event.getModifierKeyState(['Ctrl'])
    const shift: boolean = event.getModifierKeyState(['Shift'])

    // 工具切换快捷键（无 Ctrl 修饰）
    if (!ctrl) {
      const toolMap: Record<string, string> = {
        'v': 'select',
        'V': 'select',
        'r': 'rectangle',
        'R': 'rectangle',
        'o': 'ellipse',
        'O': 'ellipse',
        't': 'text',
        'T': 'text',
        'i': 'eyedropper',
        'I': 'eyedropper',
        'h': 'hand',
        'H': 'hand',
        'z': 'zoom',
        'Z': 'zoom',
      }
      const toolName: string | undefined = toolMap[key]
      if (toolName !== undefined) {
        this.toolStore.setTool(toolName as ToolId)
        return true
      }

      // Delete / Backspace 删除选中对象
      if (key === 'Delete' || key === 'Backspace') {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          sel.forEach(o => this.fusionStore.removeObjectById(o.id))
        }
        return true
      }

      // Esc 取消选择
      if (key === 'Escape') {
        this.fusionStore.selectObject(null)
        return true
      }

      // 方向键微调
      const step: number = shift ? 10 : 1
      let dx: number = 0
      let dy: number = 0
      if (key === 'ArrowUp') {
        dy = -step
      } else if (key === 'ArrowDown') {
        dy = step
      } else if (key === 'ArrowLeft') {
        dx = -step
      } else if (key === 'ArrowRight') {
        dx = step
      }
      if (dx !== 0 || dy !== 0) {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          sel.forEach(o => {
            this.fusionStore.moveObject(o.id, o.transform.x + dx, o.transform.y + dy, true)
          })
        }
        return true
      }
    }

    // Ctrl+ 组合键
    if (ctrl) {
      switch (key) {
        case 'z':
        case 'Z':
          if (shift) {
            this.fusionStore.redo()
          } else {
            this.fusionStore.undo()
          }
          return true
        case 'y':
        case 'Y':
          this.fusionStore.redo()
          return true
        case 'c':
        case 'C':
          this.fusionStore.copySelectedToClipboard()
          return true
        case 'x':
        case 'X':
          this.fusionStore.cutSelectedToClipboard()
          return true
        case 'v':
        case 'V':
          this.fusionStore.pasteFromClipboard()
          return true
        case 'd':
        case 'D':
          {
            const sel = this.fusionStore.getSelectedObjects()
            if (sel.length > 0) {
              this.fusionStore.duplicateObject(sel[0].id)
            }
          }
          return true
        case 'a':
        case 'A':
          // 全选（暂缺简化实现）
          return true
        case '0':
          this.docStore.setZoom(100)
          return true
        case '=':
          this.docStore.zoomIn()
          return true
        case '-':
          this.docStore.zoomOut()
          return true
      }
    }

    return false
  }
}
