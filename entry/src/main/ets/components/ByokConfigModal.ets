/**
 * ByokConfigModal - BYOK 配置弹窗
 *
 * 对应原型 src/components/ByokConfigModal.vue
 * 配置外部 AI 服务的 API Key 和端点
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, SpacingToken, RadiusToken, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { BYOKStore } from '../stores/BYOKStore'

@Component
export struct ByokConfigModal {
  @State isVisible: boolean = false
  @State provider: string = 'openai'
  @State apiKey: string = ''
  @State model: string = 'gpt-4o'
  @State endpoint: string = 'https://api.openai.com/v1'
  @State hoveredClose: boolean = false
  @State hoveredSave: boolean = false

  private byokStore: BYOKStore = BYOKStore.getInstance()

  show(): void {
    const config = this.byokStore.config
    this.provider = config.provider
    this.apiKey = config.apiKey
    this.model = config.model
    this.endpoint = config.endpoint
    this.isVisible = true
  }

  hide(): void {
    this.isVisible = false
  }

  build(): void {
    if (this.isVisible) {
      Stack({ alignContent: Alignment.Center }) {
        // 遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#0F172A66')
          .onClick(() => { this.hide() })

        // 弹窗主体
        Column() {
          // 标题
          Row() {
            Text(Icon.gear)
              .fontSize(14)
              .fontColor(ColorToken.primary)
            Text('BYOK 配置')
              .fontSize(14)
              .fontWeight(FontWeightConstant.bold)
              .fontColor(ColorToken.title)
              .margin({ left: 8 })
            Blank()
            Column() {
              Text(Icon.xmark)
                .fontSize(10)
                .fontColor(ColorToken.muted)
            }
            .width(24)
            .height(24)
            .borderRadius(5)
            .backgroundColor(this.hoveredClose ? ColorToken.panel : Color.Transparent)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredClose = isHover })
            .onClick(() => { this.hide() })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .alignItems(VerticalAlign.Center)

          // 表单
          Column() {
            // Provider
            Text('AI 服务商')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .margin({ bottom: 4 })
            Row() {
              Text(this.provider === 'openai' ? 'OpenAI' : this.provider === 'anthropic' ? 'Anthropic' : this.provider)
                .fontSize(12)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .layoutWeight(1)
              Text(Icon.chevron_down)
                .fontSize(7)
                .fontColor(ColorToken.muted)
            }
            .width('100%')
            .height(32)
            .padding({ left: 10, right: 10 })
            .backgroundColor(ColorToken.white)
            .border({ width: 1, color: ColorToken.border })
            .borderRadius(6)
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 10 })
            .onClick(() => {
              this.provider = this.provider === 'openai' ? 'anthropic' : 'openai'
            })

            // API Key
            Text('API Key')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .margin({ bottom: 4 })
            TextInput({ text: this.apiKey, placeholder: 'sk-...' })
              .type(InputType.Password)
              .fontSize(12)
              .fontColor(ColorToken.body)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius(6)
              .width('100%')
              .height(32)
              .padding({ left: 10, right: 10 })
              .onChange((val: string) => { this.apiKey = val })
              .margin({ bottom: 10 })

            // Model
            Text('模型')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .margin({ bottom: 4 })
            TextInput({ text: this.model, placeholder: 'gpt-4o' })
              .fontSize(12)
              .fontColor(ColorToken.body)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius(6)
              .width('100%')
              .height(32)
              .padding({ left: 10, right: 10 })
              .onChange((val: string) => { this.model = val })
              .margin({ bottom: 10 })

            // Endpoint
            Text('API Endpoint')
              .fontSize(10)
              .fontWeight(FontWeightConstant.semibold)
              .fontColor(ColorToken.muted)
              .margin({ bottom: 4 })
            TextInput({ text: this.endpoint, placeholder: 'https://api.openai.com/v1' })
              .fontSize(12)
              .fontColor(ColorToken.body)
              .backgroundColor(ColorToken.white)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius(6)
              .width('100%')
              .height(32)
              .padding({ left: 10, right: 10 })
              .onChange((val: string) => { this.endpoint = val })
              .margin({ bottom: 16 })
          }
          .width('100%')
          .padding({ left: 20, right: 20 })

          // 按钮
          Row() {
            Blank()
            Row() {
              Text('取消')
                .fontSize(12)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
            }
            .height(32)
            .padding({ left: 16, right: 16 })
            .borderRadius(6)
            .backgroundColor(ColorToken.white)
            .border({ width: 1, color: ColorToken.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8 })
            .onClick(() => { this.hide() })

            Row() {
              Text('保存')
                .fontSize(12)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(Color.White)
            }
            .height(32)
            .padding({ left: 16, right: 16 })
            .borderRadius(6)
            .backgroundColor(ColorToken.primary)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onHover((isHover: boolean) => { this.hoveredSave = isHover })
            .onClick(() => {
              this.byokStore.updateConfig({
                provider: this.provider,
                apiKey: this.apiKey,
                model: this.model,
                endpoint: this.endpoint,
                enabled: true,
              })
              this.hide()
            })
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 16 })
          .alignItems(VerticalAlign.Center)
        }
        .width(400)
        .backgroundColor(ColorToken.white)
        .borderRadius(12)
        .shadow(ShadowToken.xl)
        .border({ width: 1, color: ColorToken.border_light })
      }
      .width('100%')
      .height('100%')
    }
  }
}
