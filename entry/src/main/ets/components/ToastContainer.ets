/**
 * ToastContainer - 固定一行提示
 *
 * 对应原型 src/components/ToastContainer.vue
 * 精准还原：底部居中 + 单条显示 + 渐隐 + 深色背景 + 状态图标
 * 用户明确要求：固定一行及时更新提示，不要不断弹出
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontSizeToken, RadiusToken, FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

interface ToastItem {
  id: number
  message: string
  icon: string
  type: string  // success | warning | info
}

@Component
export struct ToastContainer {
  // 与 MenuBar 绑定的字段统一（toastMessage/toastIcon/toastType/toastVisible）
  @StorageLink('toastMessage') toastMessage: string = ''
  @StorageLink('toastIcon') toastIcon: string = ''
  @StorageLink('toastType') toastType: string = 'info'
  @StorageLink('toastVisible') toastVisible: boolean = false
  @State opacityValue: number = 0
  // 上一次消息（用于检测变化触发动画）
  @State lastMessage: string = ''

  aboutToAppear(): void {
    // 初始模拟一条提示
    if (this.toastMessage === '') {
      AppStorage.setOrCreate<string>('toastMessage', '已选中 Frame 1')
      AppStorage.setOrCreate<string>('toastIcon', Icon.success)
      AppStorage.setOrCreate<string>('toastType', 'info')
      AppStorage.setOrCreate<boolean>('toastVisible', true)
      setTimeout(() => { this.opacityValue = 1 }, 16)
      setTimeout(() => {
        AppStorage.setOrCreate<boolean>('toastVisible', false)
      }, 3000)
    }
  }

  @Monitor('toastMessage')
  onToastMessageChange(): void {
    if (this.toastVisible && this.toastMessage !== '' && this.lastMessage !== this.toastMessage) {
      this.lastMessage = this.toastMessage
      this.opacityValue = 0
      setTimeout(() => { this.opacityValue = 1 }, 16)
    }
  }

  build(): void {
    if (this.toastVisible && this.toastMessage !== '') {
      // 外层占满宽度 + 底部居中（原型：fixed bottom-[48px] left-1/2 -translate-x-1/2）
      Column() {
        // 内层 Toast 主体（自适应宽度）
        Row() {
          Text(this.getToastIcon())
            .fontSize(11)
            .fontColor(this.getToastColor())

          Text(this.toastMessage)
            .fontSize(FontSizeToken.level3)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.white)
            .margin({ left: 8 })
            .maxLines(1)
        }
        .height(32)
        .padding({ left: 14, right: 14 })
        .borderRadius(RadiusToken.md)
        .backgroundColor(ColorToken.title)
        .shadow({ radius: 16, color: '#0000002E', offsetX: 0, offsetY: 4 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .zIndex(9999)
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
      .padding({ bottom: 48 })
      .opacity(this.opacityValue)
      .animation({ duration: 150, curve: Curve.Ease })
    }
  }

  private getToastIcon(): string {
    if (this.toastIcon !== '') return this.toastIcon
    if (this.toastType === 'success') return Icon.success
    if (this.toastType === 'warning') return Icon.warning
    return Icon.info
  }

  private getToastColor(): string {
    if (this.toastType === 'success') return '#4ADE80'
    if (this.toastType === 'warning') return '#FBBF24'
    return '#60A5FA'
  }
}
