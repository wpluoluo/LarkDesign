/**
 * HdsButton - 通用按钮组件
 *
 * 对应原型 src/components/HdsButton.vue
 * 支持 primary / secondary / text / danger / success 变体
 * 支持 sm / md / lg 尺寸，以及 disabled / loading 状态
 */
import { ColorToken } from '../tokens/DesignTokens'
import { RadiusToken, FontWeightConstant, FontSizeToken } from '../tokens/DesignTokens'

export type ButtonVariant = 'primary' | 'secondary' | 'text' | 'danger' | 'success'
export type ButtonSize = 'sm' | 'md' | 'lg'
export type ButtonState = 'default' | 'disabled' | 'loading'

@Component
export struct HdsButton {
  @Prop variant: ButtonVariant = 'primary'
  @Prop size: ButtonSize = 'md'
  @Prop state: ButtonState = 'default'
  @Prop icon: string = ''
  @Prop iconRight: string = ''
  @Prop label: string = ''
  onClick: () => void = () => {}

  @State hovered: boolean = false

  build(): void {
    Column() {
      Row() {
        // 左侧图标
        if (this.icon.length > 0) {
          Text(this.icon)
            .fontSize(this.iconSize())
            .fontColor(this.textColor())
            .margin({ right: 8 })
        }

        // 加载动画
        if (this.state === 'loading') {
          Text('⟳')
            .fontSize(this.iconSize())
            .fontColor(this.textColor())
            .margin({ right: 6 })
        }

        // 标签文本
        Text(this.label)
          .fontSize(this.textSize())
          .fontWeight(FontWeightConstant.semibold)
          .fontColor(this.textColor())

        // 右侧图标
        if (this.iconRight.length > 0) {
          Text(this.iconRight)
            .fontSize(this.iconSize())
            .fontColor(this.textColor())
            .margin({ left: 8 })
        }
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .width(this.buttonWidth())
    .height(this.buttonHeight())
    .padding({ left: this.hPadding(), right: this.hPadding() })
    .borderRadius(this.borderRadius())
    .backgroundColor(this.bgColor())
    .border({ width: this.borderWidth(), color: this.borderColor() })
    .opacity(this.state === 'disabled' ? 0.5 : (this.state === 'loading' ? 0.8 : 1))
    .onHover((isHover: boolean) => { this.hovered = isHover })
    .onClick(() => {
      if (this.state !== 'disabled' && this.state !== 'loading') {
        this.onClick()
      }
    })
  }

  private textSize(): number {
    if (this.size === 'sm') return 12
    if (this.size === 'md') return 14
    return 16
  }

  private iconSize(): number {
    if (this.size === 'sm') return 10
    if (this.size === 'md') return 12
    return 14
  }

  private buttonHeight(): number {
    if (this.size === 'sm') return 32
    if (this.size === 'md') return 40
    return 48
  }

  private buttonWidth(): string {
    return 'auto'
  }

  private hPadding(): number {
    if (this.size === 'sm') return 12
    if (this.size === 'md') return 20
    return 24
  }

  private borderRadius(): number {
    if (this.size === 'sm') return 6
    if (this.size === 'md') return 8
    return 10
  }

  private borderWidth(): number {
    if (this.variant === 'secondary') return 1
    return 0
  }

  private borderColor(): ResourceColor {
    if (this.variant === 'secondary') return ColorToken.border
    return Color.Transparent
  }

  private bgColor(): ResourceColor {
    if (this.hovered && this.variant === 'text') return ColorToken.panel
    if (this.hovered && this.variant === 'secondary') {
      return ColorToken.panel
    }
    switch (this.variant) {
      case 'primary':
        return ColorToken.primary
      case 'secondary':
        return ColorToken.white
      case 'text':
        return Color.Transparent
      case 'danger':
        return ColorToken.error
      case 'success':
        return ColorToken.success
      default:
        return ColorToken.primary
    }
  }

  private textColor(): ResourceColor {
    switch (this.variant) {
      case 'primary':
      case 'danger':
      case 'success':
        return Color.White
      case 'secondary':
        return ColorToken.body
      case 'text':
        return ColorToken.body
      default:
        return Color.White
    }
  }
}
