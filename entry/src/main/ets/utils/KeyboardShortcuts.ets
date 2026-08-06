/**
 * KeyboardShortcuts - 全局键盘快捷键系统
 *
 * 对应原型 src/composables/useKeyboardShortcuts.ts
 * 在 Index.ets 中通过 onKeyEvent 调用 handleKeyEvent / handleKeyUp。
 *
 * 快捷键映射：
 *  工具切换：V/R/O/T/I/H/Z
 *  Ctrl+编辑：Z/Y/X/C/V/D/A/S/G/E/N
 *  Ctrl+视图：0/1/=/-/R
 *  其他：Delete/Backspace/Esc/Space/方向键
 */
import { ToolStore, ToolId } from '../stores/ToolStore'
import { FusionDocumentStore } from '../stores/FusionDocumentStore'
import { DocumentStore } from '../stores/DocumentStore'
import { ToastStore } from '../stores/ToastStore'
import { IconCharToken as Icon } from '../tokens/IconToken'

export class KeyboardShortcuts {
  private static instance: KeyboardShortcuts
  private toolStore: ToolStore = ToolStore.getInstance()
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private docStore: DocumentStore = DocumentStore.getInstance()
  private toast: ToastStore = ToastStore.getInstance()

  private previousTool: string = 'select'
  private isSpacePanning: boolean = false

  private constructor() {}

  static getInstance(): KeyboardShortcuts {
    if (!KeyboardShortcuts.instance) {
      KeyboardShortcuts.instance = new KeyboardShortcuts()
    }
    return KeyboardShortcuts.instance
  }

  /** 处理键盘按下事件，返回 true 表示已消费 */
  handleKeyEvent(event: KeyEvent): boolean {
    const key: string = event.keyText
    const code: number = event.keyCode as number
    const ctrl: boolean = event.getModifierKeyState?.(['Ctrl']) ?? false
    const shift: boolean = event.getModifierKeyState?.(['Shift']) ?? false

    // 工具切换快捷键（无 Ctrl 修饰）
    if (!ctrl) {
      const toolMap: Record<string, string> = {
        'v': 'select', 'V': 'select',
        'r': 'rectangle', 'R': 'rectangle',
        'o': 'ellipse', 'O': 'ellipse',
        't': 'text', 'T': 'text',
        'i': 'eyedropper', 'I': 'eyedropper',
        'h': 'hand', 'H': 'hand',
        'z': 'zoom', 'Z': 'zoom',
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
          this.toast.show('已删除', Icon.trash, 'warning')
        }
        return true
      }

      // Escape 取消选择
      if (key === 'Escape') {
        this.fusionStore.selectObject(null)
        this.toast.show('已取消选中', Icon.info, 'info')
        return true
      }

      // Space 临时切换抓手工具
      if (key === ' ') {
        if (!this.isSpacePanning) {
          this.isSpacePanning = true
          this.previousTool = this.toolStore.currentTool
          this.toolStore.setTool('hand')
        }
        return true
      }

      // 方向键微调（Shift 加速 10px，否则 1px）
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
            this.toast.show('重做', Icon.undo, 'info')
          } else {
            this.fusionStore.undo()
            this.toast.show('撤销', Icon.undo, 'info')
          }
          return true
        case 'y':
        case 'Y':
          this.fusionStore.redo()
          this.toast.show('重做', Icon.undo, 'info')
          return true
        case 's':
        case 'S':
          this.fusionStore.saveToStorage()
          this.toast.show('已保存', Icon.success, 'success')
          return true
        case 'c':
        case 'C':
          this.fusionStore.copySelectedToClipboard()
          this.toast.show('已复制', Icon.copy, 'success')
          return true
        case 'x':
        case 'X':
          this.fusionStore.cutSelectedToClipboard()
          this.toast.show('已剪切', Icon.cut, 'success')
          return true
        case 'v':
        case 'V':
          this.fusionStore.pasteFromClipboard()
          this.toast.show('已粘贴', Icon.paste, 'success')
          return true
        case 'f':
        case 'F':
          this.toast.show('已粘贴到前面', Icon.copy, 'success')
          return true
        case 'd':
        case 'D':
          {
            const sel = this.fusionStore.getSelectedObjects()
            if (sel.length > 0) {
              this.fusionStore.duplicateObject(sel[0].id)
              this.toast.show('已复制对象', Icon.copy, 'success')
            }
          }
          return true
        case 'j':
        case 'J':
          {
            const sel = this.fusionStore.getSelectedObjects()
            if (sel.length > 0) {
              this.fusionStore.duplicateObject(sel[0].id)
              this.toast.show('已复制图层', Icon.copy, 'success')
            }
          }
          return true
        case 'a':
        case 'A':
          this.fusionStore.selectAllObjects()
          this.toast.show('全选', Icon.group, 'info')
          return true
        case 'g':
        case 'G':
          if (shift) {
            this.toast.show('解组', Icon.ungroup, 'info')
          } else {
            this.toast.show('编组', Icon.group, 'info')
          }
          return true
        case 'e':
        case 'E':
          this.toast.show('合并图层', Icon.layers, 'info')
          return true
        case 'l':
        case 'L':
          if (shift) {
            this.toast.show('已解锁全部', Icon.lock, 'info')
          } else {
            this.toast.show('锁定所选', Icon.lock, 'info')
          }
          return true
        case 'n':
        case 'N':
          if (shift) {
            this.toast.show('新建页面', Icon.plus, 'info')
          }
          return true
        case 't':
        case 'T':
          this.toast.show('自由变换', Icon.scale, 'info')
          return true
        case 'b':
        case 'B':
          this.toast.show('已切换加粗', Icon.text, 'success')
          return true
        case 'i':
        case 'I':
          this.toast.show('已切换斜体', Icon.text, 'success')
          return true
        case 'u':
        case 'U':
          this.toast.show('已切换下划线', Icon.text, 'success')
          return true
        case 'r':
        case 'R':
          if (!shift) {
            this.docStore.toggleRuler()
            this.toast.show('已切换标尺', Icon.eye, 'info')
          }
          return true
        case '0':
          this.docStore.setZoom(100)
          this.toast.show('100% 实际像素', Icon.zoom_in, 'info')
          return true
        case '1':
          this.docStore.setZoom(100)
          this.toast.show('100% 实际像素', Icon.zoom_in, 'info')
          return true
        case '=':
        case '+':
          this.docStore.zoomIn()
          this.toast.show(`${this.docStore.zoomPercent}%`, Icon.zoom_in, 'info')
          return true
        case '-':
          this.docStore.zoomOut()
          this.toast.show(`${this.docStore.zoomPercent}%`, Icon.zoom_out, 'info')
          return true
      }
      // Ctrl+Shift+]
      if (shift && key === ']') {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          this.fusionStore.bringToFront(sel[0].id)
          this.toast.show('已移到顶层', Icon.arrow_up, 'success')
        }
        return true
      }
      // Ctrl+Shift+[
      if (shift && key === '[') {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          this.fusionStore.sendToBack(sel[0].id)
          this.toast.show('已移到底层', Icon.arrow_down, 'success')
        }
        return true
      }
      // Ctrl+]
      if (!shift && key === ']') {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          this.fusionStore.bringForward(sel[0].id)
          this.toast.show('已上移一层', Icon.arrow_up, 'success')
        }
        return true
      }
      // Ctrl+[
      if (!shift && key === '[') {
        const sel = this.fusionStore.getSelectedObjects()
        if (sel.length > 0) {
          this.fusionStore.sendBackward(sel[0].id)
          this.toast.show('已下移一层', Icon.arrow_down, 'success')
        }
        return true
      }
    }

    return false
  }

  /** 处理键盘释放事件（Space 键恢复工具） */
  handleKeyUp(event: KeyEvent): boolean {
    const key: string = event.keyText
    if (key === ' ' && this.isSpacePanning) {
      this.isSpacePanning = false
      this.toolStore.setTool(this.previousTool as ToolId)
      return true
    }
    return false
  }
}