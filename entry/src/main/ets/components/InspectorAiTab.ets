/**
 * InspectorAiTab - AI 智能面板
 *
 * 对应原型 src/components/Inspector.vue 的 AI Tab 部分
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'
import { BYOKStore } from '../stores/BYOKStore'

/** AI 对话消息 */
interface AiMessage {
  role: string
  content: string
  name?: string
}

@Component
export struct InspectorAiTab {
  @State byokConfigured: boolean = false
  @State byokModelId: string = '演示模式'
  @State aiInputText: string = ''
  @State aiMessages: AiMessage[] = [
    { role: 'assistant', content: '你好！我是 AI 设计助手。我可以帮你生成设计元素、调整布局、应用样式。\n\n试试输入"新建一个白底图层"或"查看画布信息"来开始吧。' },
  ]
  @State aiThinking: boolean = false
  @State aiLastError: string = ''
  @State aiToolCallCount: number = 0
  @State aiLayerCount: number = 1
  @State showByokModal: boolean = false
  @State hoveredAiHeaderBtn: string = ''
  @State hoveredAiSend: boolean = false
  @State hoveredAiAttach: boolean = false
  private byokStore: BYOKStore = BYOKStore.getInstance()

  aboutToAppear(): void {
    this.byokConfigured = this.byokStore.isConfigured
    this.byokModelId = this.byokStore.config.modelId
  }

  build(): void {
    Column() {
      Row() {
        Row() {
          Text(Icon.microchip)
            .fontSize(9)
            .fontColor(ColorToken.secondary)
            .margin({ right: 6 })
          Text(this.byokConfigured ? this.byokModelId : '演示模式')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: 140 })
          if (!this.byokConfigured) {
            Text('未配置')
              .fontSize(8)
              .fontWeight(FontWeightConstant.medium)
              .fontColor('#C97912')
              .backgroundColor('#FFF8E8')
              .border({ width: 1, color: '#F4D48A' })
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .borderRadius(3)
              .margin({ left: 6 })
          }
        }
        .alignItems(VerticalAlign.Center)

        Blank()
        Row() {
          Column() {
            Text(Icon.gear)
              .fontSize(10)
              .fontColor(this.hoveredAiHeaderBtn === 'byok' ? ColorToken.body : ColorToken.tertiary)
              .textAlign(TextAlign.Center)
          }
          .width(20)
          .height(20)
          .borderRadius(4)
          .backgroundColor(this.hoveredAiHeaderBtn === 'byok' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onHover((isHover: boolean) => { this.hoveredAiHeaderBtn = isHover ? 'byok' : '' })
          .onClick(() => { this.showByokModal = true })

          Column() {
            Text(Icon.refresh)
              .fontSize(9)
              .fontColor(this.hoveredAiHeaderBtn === 'clear' ? ColorToken.body : ColorToken.tertiary)
              .textAlign(TextAlign.Center)
          }
          .width(20)
          .height(20)
          .borderRadius(4)
          .backgroundColor(this.hoveredAiHeaderBtn === 'clear' ? ColorToken.hover_bg : Color.Transparent)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 6 })
          .onHover((isHover: boolean) => { this.hoveredAiHeaderBtn = isHover ? 'clear' : '' })
          .onClick(() => { this.clearAiConversation() })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(32)
      .padding({ left: 10, right: 10 })
      .backgroundColor(ColorToken.panel)
      .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          ForEach(this.aiMessages, (msg: AiMessage, idx: number) => {
            if (msg.role === 'assistant') {
              Row() {
                Column() {
                  Text(Icon.robot)
                    .fontSize(10)
                    .fontColor(ColorToken.white)
                }
                .width(24)
                .height(24)
                .backgroundColor(ColorToken.primary)
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ top: 2 })

                Column() {
                  Text(msg.content)
                    .fontSize(11)
                    .fontWeight(FontWeightConstant.regular)
                    .fontColor(ColorToken.body)
                    .maxLines(20)
                }
                .constraintSize({ maxWidth: '80%' })
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor(ColorToken.panel)
                .border({ width: 1, color: ColorToken.border })
                .borderRadius({ topLeft: 2, topRight: 8, bottomLeft: 8, bottomRight: 8 })
                .margin({ left: 8 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            } else if (msg.role === 'user') {
              Row() {
                Column() {
                  Text(msg.content)
                    .fontSize(11)
                    .fontWeight(FontWeightConstant.medium)
                    .fontColor(ColorToken.body)
                    .maxLines(20)
                }
                .constraintSize({ maxWidth: '80%' })
                .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                .backgroundColor(ColorToken.hover_bg)
                .border({ width: 1, color: '#B8EAD4' })
                .borderRadius({ topLeft: 8, topRight: 2, bottomLeft: 8, bottomRight: 8 })

                Column() {
                  Text('U')
                    .fontSize(8)
                    .fontWeight(FontWeightConstant.bold)
                    .fontColor(ColorToken.white)
                }
                .width(24)
                .height(24)
                .backgroundColor(ColorToken.title)
                .borderRadius(6)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .margin({ top: 2, left: 8 })
              }
              .width('100%')
              .justifyContent(FlexAlign.End)
              .alignItems(VerticalAlign.Top)
            } else if (msg.role === 'tool') {
              Row() {
                Column() {
                  Row() {
                    Text(Icon.wand)
                      .fontSize(7)
                      .fontColor(ColorToken.tertiary)
                      .margin({ right: 6 })
                    Text(msg.name ? msg.name : 'tool')
                      .fontSize(8)
                      .fontWeight(FontWeightConstant.medium)
                      .fontColor(ColorToken.muted)
                    Text(Icon.check)
                      .fontSize(7)
                      .fontColor(ColorToken.primary)
                      .margin({ left: 6 })
                  }
                  .alignItems(VerticalAlign.Center)
                }
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(ColorToken.white)
                .border({ width: 1, color: ColorToken.border_light })
                .borderRadius(4)
              }
              .width('100%')
              .padding({ left: 32 })
              .alignItems(VerticalAlign.Top)
            }
          }, (msg: AiMessage) => msg.role + msg.content)

          if (this.aiThinking) {
            Row() {
              Column() {
                Text(Icon.robot)
                  .fontSize(10)
                  .fontColor(ColorToken.white)
              }
              .width(24)
              .height(24)
              .backgroundColor(ColorToken.primary)
              .borderRadius(6)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .margin({ top: 2 })

              Column() {
                Text('思考中...')
                  .fontSize(11)
                  .fontWeight(FontWeightConstant.regular)
                  .fontColor(ColorToken.muted)
              }
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor(ColorToken.panel)
              .border({ width: 1, color: ColorToken.border })
              .borderRadius({ topLeft: 2, topRight: 8, bottomLeft: 8, bottomRight: 8 })
              .margin({ left: 8 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }

          if (!this.byokConfigured) {
            Row() {
              Text(Icon.info_circle)
                .fontSize(10)
                .fontColor('#C97912')
                .margin({ top: 1 })
              Column() {
                Text('演示模式')
                  .fontSize(9)
                  .fontWeight(FontWeightConstant.bold)
                  .fontColor('#7A5314')
                Text('可识别关键词：新建图层 / 列表 / 白底 / 深色背景 / 画布信息。点击右上角齿轮配置 BYOK 以接入真实大模型。')
                  .fontSize(9)
                  .fontWeight(FontWeightConstant.medium)
                  .fontColor('#7A5314')
                  .margin({ top: 4 })
              }
              .margin({ left: 8 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF8E8')
            .border({ width: 1, color: '#F4D48A' })
            .borderRadius(6)
            .alignItems(VerticalAlign.Top)
          }

          if (this.aiLastError !== '') {
            Row() {
              Text(Icon.warning)
                .fontSize(10)
                .fontColor('#DC2626')
                .margin({ top: 1 })
              Text(this.aiLastError)
                .fontSize(9)
                .fontWeight(FontWeightConstant.medium)
                .fontColor('#7F1D1D')
                .margin({ left: 8 })
                .layoutWeight(1)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FEF2F2')
            .border({ width: 1, color: '#FCA5A5' })
            .borderRadius(6)
            .alignItems(VerticalAlign.Top)
          }
        }
        .width('100%')
        .padding(12)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      Column() {
        Row() {
          Text(Icon.copy)
            .fontSize(10)
            .fontColor(this.hoveredAiAttach ? ColorToken.body : ColorToken.tertiary)
            .onHover((isHover: boolean) => { this.hoveredAiAttach = isHover })

          Row() {
            TextInput({ text: this.aiInputText, placeholder: '输入设计需求...' })
              .fontSize(10)
              .fontColor(ColorToken.body)
              .placeholderColor('#9AA2AC')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .layoutWeight(1)
              .onChange((val: string) => { this.aiInputText = val })
              .onSubmit(() => { this.onAiSend() })
          }
          .layoutWeight(1)
          .height(28)
          .padding({ left: 8, right: 8 })
          .backgroundColor(ColorToken.panel)
          .border({ width: 1, color: ColorToken.border })
          .borderRadius(4)
          .margin({ left: 6 })
          .alignItems(VerticalAlign.Center)

          Column() {
            Text(Icon.arrow_up)
              .fontSize(10)
              .fontColor(ColorToken.white)
              .textAlign(TextAlign.Center)
          }
          .width(28)
          .height(28)
          .borderRadius(6)
          .backgroundColor(
            this.aiInputText.trim() !== '' && !this.aiThinking
              ? (this.hoveredAiSend ? ColorToken.primary_dark_900 : ColorToken.primary_dark_700)
              : ColorToken.border_light
          )
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ left: 6 })
          .onHover((isHover: boolean) => { this.hoveredAiSend = isHover })
          .onClick(() => { this.onAiSend() })
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(`${this.aiLayerCount} 个图层`)
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
          Text('·')
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ left: 6, right: 6 })
          Text(`${this.aiToolCallCount} 次工具调用`)
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
          Text('·')
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ left: 6, right: 6 })
          Text('嵌入')
            .fontSize(8)
            .fontWeight(FontWeightConstant.regular)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 4, bottom: 2 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .border({ width: { top: 1 }, color: { top: ColorToken.border } })
      .backgroundColor(ColorToken.white)
    }
    .width('100%')
    .height('100%')
  }

  private async onAiSend(): Promise<void> {
    const text = this.aiInputText.trim()
    if (text === '' || this.aiThinking) return
    this.aiInputText = ''
    this.aiMessages.push({ role: 'user', content: text })
    this.aiThinking = true
    try {
      const reply = await this.byokStore.complete(text)
      this.aiThinking = false
      this.aiMessages.push({ role: 'assistant', content: reply })
    } catch (error) {
      this.aiThinking = false
      this.aiLastError = String(error)
      this.aiMessages.push({ role: 'assistant', content: '请求失败：' + this.aiLastError })
    }
  }

  private clearAiConversation(): void {
    this.aiMessages = []
    this.aiLastError = ''
    this.aiToolCallCount = 0
  }

}
