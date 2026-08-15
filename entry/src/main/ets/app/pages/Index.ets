/**
 * LarkDesign - 主页面入口
 *
 * 对应原型 src/App.vue + SplashScreen.vue
 * 首屏根据状态切换：启动屏 / 工作区
 * 集成全局键盘快捷键系统
 */
import { ThemeStore } from '../../stores/ThemeStore'
import { DocumentStore } from '../../stores/DocumentStore'
import { FusionDocumentStore } from '../../stores/FusionDocumentStore'
import { ToolStore } from '../../stores/ToolStore'
import { ColorStore } from '../../stores/ColorStore'
import { ToastStore } from '../../stores/ToastStore'
import { LayerStore } from '../../stores/LayerStore'
import { KeyboardShortcuts } from '../../utils/KeyboardShortcuts'
import { SplashScreen } from '../../components/SplashScreen'
import { WorkspaceLayout } from '../../components/WorkspaceLayout'
import { BYOKStore } from '../../stores/BYOKStore'

@Entry
@Component
struct Index {
  @StorageLink('currentRoute') currentRoute: string = 'splash'
  private shortcuts: KeyboardShortcuts = KeyboardShortcuts.getInstance()

  aboutToAppear(): void {
    // 初始化所有 stores
    ThemeStore.getInstance().init()
    DocumentStore.getInstance().init()
    FusionDocumentStore.getInstance().init()
    BYOKStore.getInstance().init()
    ToolStore.getInstance()
    ColorStore.getInstance()
    ToastStore.getInstance()
    LayerStore.getInstance()
  }

  build(): void {
    Stack() {
      if (this.currentRoute === 'splash') {
        SplashScreen({ onEnter: (mode: string) => this.enterWorkspace(mode) })
      } else {
        WorkspaceLayout()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg'))
.onKeyEvent((event: KeyEvent) => {
      if (event.type === KeyType.Down) {
        this.shortcuts.handleKeyEvent(event)
      } else if (event.type === KeyType.Up) {
        this.shortcuts.handleKeyUp(event)
      }
    })
  }

  private enterWorkspace(mode: string): void {
    console.info('LarkDesign', `enterWorkspace: ${mode}`)
    // 根据模式创建对应类型的 Frame
    const fusion = FusionDocumentStore.getInstance()
    const frame = fusion.newFrame(mode, '', 60, 60)
    fusion.switchFrame(frame.id)
    console.info('LarkDesign', `created frame=${frame.id} total=${fusion.getFrames().length}`)
    AppStorage.setOrCreate<string>('currentRoute', 'workspace')
  }
}
