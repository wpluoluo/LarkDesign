/**
 * AIAssistant - AI 助手面板
 *
 * 对应原型 src/components/AIAssistant.vue
 * AI 辅助设计对话界面，连接 AiAgent 后端引擎
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, FontSizeToken, SpacingToken, RadiusToken, ShadowToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { AiAgent, ChatMessage } from '../utils/AiAgent'

@Component
export struct AIAssistant {
  private aiAgent: AiAgent = new AiAgent()
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State isExpanded: boolean = true
  @State isThinking: boolean = false

  aboutToAppear(): void {
    this.messages = this.aiAgent.getState().messages
  }

  private doSend(): void {
    if (this.inputText.length === 0) return
    const text = this.inputText
    this.inputText = ''
    this.isThinking = true
    this.aiAgent.send(text).then((msgs: ChatMessage[]) => {
      this.messages = msgs
      this.isThinking = false
    }).catch(() => {
      this.messages = this.aiAgent.getState().messages
      this.isThinking = false
    })
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Row() {
          Text(Icon.wand)
            .fontSize(12)
            .fontColor(ColorToken.primary)
          Text('AI 助手')
            .fontSize(12)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.title)
            .margin({ left: 6 })
        }
        .layoutWeight(1)

        Text(Icon.chevron_down)
          .fontSize(8)
          .fontColor(ColorToken.tertiary)
          .rotate({ angle: this.isExpanded ? 0 : 180 })
          .onClick(() => { this.isExpanded = !this.isExpanded })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      if (this.isExpanded) {
        // 消息列表
        Scroll() {
          Column() {
            if (this.messages.length === 0) {
              Column() {
                Text(Icon.wand)
                  .fontSize(24)
                  .fontColor(ColorToken.border)
                Text('输入问题，AI 帮你设计')
                  .fontSize(11)
                  .fontColor(ColorToken.muted)
                  .margin({ top: 8 })
                Text('例如：创建一个 3 列卡片布局')
                  .fontSize(9)
                  .fontColor(ColorToken.border)
                  .margin({ top: 4 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 40, bottom: 40 })
            } else {
              ForEach(this.messages, (msg: ChatMessage) => {
                Column() {
                  Text(msg.content)
                    .fontSize(11)
                    .fontColor(msg.role === 'user' ? ColorToken.primary_dark_700 : ColorToken.body)
                    .backgroundColor(msg.role === 'user' ? ColorToken.primary_light_100 : ColorToken.panel)
                    .borderRadius(8)
                    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                    .constraintSize({ maxWidth: '80%' })
                }
                .width('100%')
                .alignItems(msg.role === 'user' ? HorizontalAlign.End : HorizontalAlign.Start)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              })
              if (this.isThinking) {
                Row() {
                  Text('思考中...')
                    .fontSize(10)
                    .fontColor(ColorToken.muted)
                }
                .width('100%')
                .padding({ left: 12, top: 4 })
              }
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 输入区
        Row() {
          TextInput({ text: this.inputText, placeholder: '输入 AI 指令...' })
            .fontSize(11)
            .fontColor(ColorToken.body)
            .backgroundColor(ColorToken.panel)
            .border({ width: 1, color: ColorToken.border })
            .borderRadius(8)
            .layoutWeight(1)
            .height(32)
            .padding({ left: 8, right: 8 })
            .onChange((val: string) => { this.inputText = val })

          Column() {
            Text(Icon.arrow_right)
              .fontSize(10)
              .fontColor(ColorToken.white)
          }
          .width(32)
          .height(32)
          .borderRadius(8)
          .backgroundColor(ColorToken.primary)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 6 })
          .onClick(() => { this.doSend() })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 10 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .backgroundColor(ColorToken.white)
    .borderRadius(8)
    .border({ width: 1, color: ColorToken.border_light })
  }
}