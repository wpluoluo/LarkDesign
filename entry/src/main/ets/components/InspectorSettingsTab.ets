/**
 * InspectorSettingsTab - 设置面板
 *
 * 对应原型 src/components/Inspector.vue 的 Settings Tab 部分
 */
import { ColorToken } from '../tokens/DesignTokens'
import { FontWeightConstant, ShadowToken, ZIndexToken } from '../tokens/DesignTokens'
import { IconCharToken as Icon } from '../tokens/IconToken'

/** MCP 工具 */
interface McpTool {
  name: string
  icon: string
  calls: number
  enabled: boolean
}

/** 智能体技能 */
interface AgentSkill {
  label: string
  desc: string
  icon: string
  agent: string
  connected: boolean
}

@Component
export struct InspectorSettingsTab {
  @State mcpExpanded: boolean = false
  @State modelExpanded: boolean = false
  @State skillExpanded: boolean = false
  @State sysInfoExpanded: boolean = false
  @State modelProtocol: string = 'OpenAI'
  @State modelProvider: string = 'DeepSeek'
  @State modelUrl: string = 'https://api.deepseek.com/v1'
  @State modelToken: string = 'sk-••••••••••••••••'
  @State modelTokenVisible: boolean = false
  @State modelId: string = 'deepseek-v4-flash'
  @State modelAdvanced: boolean = false
  @State modelMaxTokens: number = 8192
  @State modelTemperature: number = 0.7
  @State modelTimeout: number = 60
  @State modelRetries: number = 3
  @State modelStream: boolean = true
  @State modelThinking: boolean = true
  @State hoveredSettingsRow: string = ''

  build(): void {
    Scroll() {
      Column() {
        this.settingsSection('mcp', 'MCP 协议', Icon.tower_broadcast, this.mcpExpanded, (v: boolean) => { this.mcpExpanded = v })
        this.settingsSection('model', '模型信息配置', Icon.microchip, this.modelExpanded, (v: boolean) => { this.modelExpanded = v })
        this.settingsSection('skill', '智能体技能', Icon.robot, this.skillExpanded, (v: boolean) => { this.skillExpanded = v })
        this.settingsSection('sysInfo', '系统信息', Icon.info_circle, this.sysInfoExpanded, (v: boolean) => { this.sysInfoExpanded = v })

        Row() {
          Text(Icon.refresh)
            .fontSize(10)
            .fontColor(ColorToken.white)
            .margin({ right: 8 })
          Text('检查更新')
            .fontSize(10)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.white)
        }
        .width('100%')
        .height(32)
        .borderRadius(6)
        .backgroundColor(ColorToken.primary_dark_700)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 12, right: 12, top: 10, bottom: 10 })
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  settingsSection(id: string, title: string, icon: string, expanded: boolean, toggle: (v: boolean) => void): void {
    Column() {
      Row() {
        Row() {
          Text(icon)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
          Text(title)
            .fontSize(13)
            .fontWeight(FontWeightConstant.bold)
            .fontColor(ColorToken.body)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        if (id === 'skill') {
          Text('4 个')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
            .margin({ right: 8 })
        }
        Text(expanded ? Icon.chevron_down : Icon.chevron_up)
          .fontSize(8)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor(this.hoveredSettingsRow === id ? ColorToken.panel : Color.Transparent)
      .alignItems(VerticalAlign.Center)
      .onClick(() => { toggle(!expanded) })
      .onHover((isHover: boolean) => { this.hoveredSettingsRow = isHover ? id : '' })

      if (!expanded) {
        if (id === 'mcp') {
          this.mcpContent()
        } else if (id === 'model') {
          this.modelContent()
        } else if (id === 'skill') {
          this.skillContent()
        } else if (id === 'sysInfo') {
          this.sysInfoContent()
        }
      }
    }
    .border({ width: { bottom: 1 }, color: { bottom: ColorToken.border_light } })
  }

  @Builder
  mcpContent(): void {
    Column() {
      Row() {
        Row() {
          Column()
            .width(6)
            .height(6)
            .borderRadius(3)
            .backgroundColor(ColorToken.primary)
          Text('服务运行中')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.body)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        Text('PID 2847')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .borderRadius(4)
      .backgroundColor(ColorToken.panel)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      Column() {
        this.mcpInfoRow('端点地址', 'localhost:11435')
        this.mcpInfoRow('协议版本', '2025-03-26')
        this.mcpInfoRow('RPC 通道', 'Streamable HTTP · SSE')
        this.mcpInfoRow('会话数', '3 个活跃会话')
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text('暴露的工具 (Tools)')
        .fontSize(10)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })

      Column() {
        ForEach(this.mcpTools, (tool: McpTool) => {
          Row() {
            Row() {
              Text(tool.icon)
                .fontSize(8)
                .fontColor(ColorToken.secondary)
              Text(tool.name)
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.body)
                .margin({ left: 8 })
            }
            .alignItems(VerticalAlign.Center)
            .layoutWeight(1)

            Text(`${tool.calls} 次`)
              .fontSize(10)
              .fontColor(ColorToken.muted)
              .margin({ right: 4 })

            Row() {
              Column()
                .width(6)
                .height(6)
                .borderRadius(3)
                .backgroundColor(ColorToken.white)
                .position({ x: tool.enabled ? 11 : 1, y: 2 })
            }
            .width(18)
            .height(10)
            .borderRadius(5)
            .backgroundColor(tool.enabled ? ColorToken.primary : ColorToken.border)
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text('暴露的资源 (Resources)')
        .fontSize(10)
        .fontWeight(FontWeightConstant.semibold)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })

      Column() {
        ForEach(this.mcpResources, (res: string) => {
          Row() {
            Text(Icon.file)
              .fontSize(8)
              .fontColor(ColorToken.secondary)
            Text(res)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(ColorToken.body)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .borderRadius(3)
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')

      Row() {
        Row() {
          Text(Icon.refresh)
            .fontSize(8)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('重启服务')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(Icon.copy)
            .fontSize(8)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('复制端点')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .padding({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  @Builder
  mcpInfoRow(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Blank()
      Text(value)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
    }
    .width('100%')
    .height(24)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(ColorToken.panel)
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 4 })
  }

  @Builder
  modelContent(): void {
    Column() {
      Column() {
        Text('协议')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.modelProtocols, (proto: string) => {
            Text(proto)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.modelProtocol === proto ? ColorToken.primary_dark_700 : ColorToken.muted)
              .height(24)
              .padding({ left: 8, right: 8 })
              .borderRadius(3)
              .border({ width: 1, color: this.modelProtocol === proto ? ColorToken.primary : ColorToken.border })
              .backgroundColor(this.modelProtocol === proto ? ColorToken.hover_bg : Color.Transparent)
              .margin({ right: 4, bottom: 4 })
              .onClick(() => { this.modelProtocol = proto })
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        Text('提供商')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.modelProviders, (prov: string) => {
            Text(prov)
              .fontSize(10)
              .fontWeight(FontWeightConstant.medium)
              .fontColor(this.modelProvider === prov ? ColorToken.primary_dark_700 : ColorToken.muted)
              .height(24)
              .padding({ left: 8, right: 8 })
              .borderRadius(3)
              .border({ width: 1, color: this.modelProvider === prov ? ColorToken.primary : ColorToken.border })
              .backgroundColor(this.modelProvider === prov ? ColorToken.hover_bg : Color.Transparent)
              .margin({ right: 4, bottom: 4 })
              .onClick(() => { this.modelProvider = prov })
          })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        Text('API 端点 URL')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.link)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelUrl, placeholder: 'https://api.openai.com/v1' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
          Text(Icon.paste)
            .fontSize(8)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        Text('API 令牌')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.key)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelToken, placeholder: 'sk-xxxxxxxxxxxxxxxx' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
            .type(this.modelTokenVisible ? InputType.Normal : InputType.Password)
          Text(this.modelTokenVisible ? Icon.eye : Icon.eye_off)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
            .onClick(() => { this.modelTokenVisible = !this.modelTokenVisible })
          Text(Icon.paste)
            .fontSize(8)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      Column() {
        Text('模型 ID')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ bottom: 4 })
        Row() {
          Text(Icon.tag)
            .fontSize(8)
            .fontColor(ColorToken.muted)
            .margin({ right: 4 })
          TextInput({ text: this.modelId, placeholder: 'deepseek-v4-flash' })
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.body)
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(28)
        .padding({ left: 8, right: 8 })
        .borderRadius(4)
        .backgroundColor(ColorToken.white)
        .border({ width: 1, color: ColorToken.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ bottom: 6 })

      Row() {
        Text(this.modelAdvanced ? Icon.chevron_down : Icon.chevron_right)
          .fontSize(10)
          .fontColor(ColorToken.muted)
        Text('高级选项')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 6 })
      .onClick(() => { this.modelAdvanced = !this.modelAdvanced })

      if (this.modelAdvanced) {
        Column() {
          Row() {
            this.modelNumberInput('最大 Token', this.modelMaxTokens, (v: number) => { this.modelMaxTokens = v })
            this.modelNumberInput('温度 (0-2)', this.modelTemperature, (v: number) => { this.modelTemperature = v })
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            this.modelNumberInput('超时 (秒)', this.modelTimeout, (v: number) => { this.modelTimeout = v })
            this.modelNumberInput('重试次数', this.modelRetries, (v: number) => { this.modelRetries = v })
          }
          .width('100%')
          .margin({ bottom: 4 })

          Row() {
            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.modelStream ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.modelStream ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.modelStream = !this.modelStream })
              Text('流式输出')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
            .margin({ right: 8 })

            Row() {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(ColorToken.white)
                  .position({ x: this.modelThinking ? 9 : 1, y: 2 })
              }
              .width(16)
              .height(10)
              .borderRadius(5)
              .backgroundColor(this.modelThinking ? ColorToken.primary : ColorToken.border)
              .onClick(() => { this.modelThinking = !this.modelThinking })
              Text('推理模式')
                .fontSize(10)
                .fontWeight(FontWeightConstant.medium)
                .fontColor(ColorToken.secondary)
                .margin({ left: 4 })
            }
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 8 })
        .border({ width: { left: 1 }, color: { left: ColorToken.border_light } })
        .margin({ bottom: 6 })
      }

      Row() {
        Row() {
          Text(Icon.plug)
            .fontSize(10)
            .fontColor(ColorToken.secondary)
            .margin({ right: 4 })
          Text('测试连接')
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.secondary)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.border })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(Icon.save)
            .fontSize(10)
            .fontColor(ColorToken.primary_dark_700)
            .margin({ right: 4 })
          Text('保存配置')
            .fontSize(10)
            .fontWeight(FontWeightConstant.semibold)
            .fontColor(ColorToken.primary_dark_700)
        }
        .layoutWeight(1)
        .height(28)
        .borderRadius(4)
        .border({ width: 1, color: ColorToken.primary })
        .backgroundColor(ColorToken.hover_bg)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .padding({ top: 6 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  @Builder
  modelNumberInput(label: string, value: number, onChange: (v: number) => void): void {
    Column() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
        .margin({ bottom: 4 })
      TextInput({ text: `${value}` })
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
        .height(24)
        .padding({ left: 4, right: 4 })
        .borderRadius(3)
        .border({ width: 1, color: ColorToken.border })
        .backgroundColor(ColorToken.white)
        .type(InputType.Number)
        .onChange((val: string) => { onChange(Number(val) || 0) })
    }
    .layoutWeight(1)
    .margin({ right: 4 })
  }

  @Builder
  skillContent(): void {
    Column() {
      Row() {
        Text(Icon.search)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 6 })
        TextInput({ placeholder: '搜索可用技能...' })
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.body)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(28)
      .padding({ left: 8, right: 8 })
      .borderRadius(4)
      .backgroundColor(ColorToken.panel)
      .border({ width: 1, color: ColorToken.border })
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      ForEach(this.agentSkills, (skill: AgentSkill) => {
        Row() {
          Row() {
            Column()
              .width(6)
              .height(6)
              .borderRadius(3)
              .backgroundColor(skill.connected ? ColorToken.primary : ColorToken.muted)
            Text(skill.icon)
              .fontSize(10)
              .fontColor(ColorToken.secondary)
              .margin({ left: 8 })
            Column() {
              Text(skill.label)
                .fontSize(10)
                .fontWeight(FontWeightConstant.semibold)
                .fontColor(ColorToken.body)
              Text(skill.desc)
                .fontSize(10)
                .fontColor(ColorToken.muted)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 8 })
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)

          Text(skill.agent)
            .fontSize(10)
            .fontWeight(FontWeightConstant.medium)
            .fontColor(ColorToken.muted)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .borderRadius(4)
        .alignItems(VerticalAlign.Center)
        .opacity(skill.connected ? 1 : 0.6)
      })

      Row() {
        Text(Icon.plus)
          .fontSize(8)
          .fontColor(ColorToken.muted)
          .margin({ right: 8 })
        Text('注册新智能体...')
          .fontSize(10)
          .fontWeight(FontWeightConstant.medium)
          .fontColor(ColorToken.muted)
      }
      .width('100%')
      .padding({ left: 4, right: 4, top: 8, bottom: 8 })
      .borderRadius(4)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 8 })
      .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  @Builder
  sysInfoContent(): void {
    Column() {
      Row() {
        this.sysInfoCell('版本', '3.0.0')
        this.sysInfoCell('构建', '2026.07.19')
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        this.sysInfoCell('模型', 'deepseek-v4')
        this.sysInfoCell('引擎', 'OpenClaw v2.3')
      }
      .width('100%')
      .margin({ bottom: 4 })

      Row() {
        this.sysInfoCell('网关', '百炼 + 中转')
        this.sysInfoCell('凭证', '已绑定')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 12 })
    .border({ width: { top: 1 }, color: { top: ColorToken.border_light } })
  }

  @Builder
  sysInfoCell(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.muted)
      Blank()
      Text(value)
        .fontSize(10)
        .fontWeight(FontWeightConstant.medium)
        .fontColor(ColorToken.body)
    }
    .layoutWeight(1)
    .height(24)
    .padding({ left: 8, right: 8 })
    .borderRadius(4)
    .backgroundColor(ColorToken.panel)
    .alignItems(VerticalAlign.Center)
    .margin({ right: 4 })
  }

  private mcpTools: McpTool[] = [
    { name: 'canvas.read', icon: '👁', calls: 47, enabled: true },
    { name: 'canvas.write', icon: '✎', calls: 23, enabled: true },
    { name: 'layer.list', icon: '▤', calls: 12, enabled: true },
    { name: 'layer.modify', icon: '✒', calls: 18, enabled: true },
    { name: 'page.manage', icon: '📄', calls: 0, enabled: false },
    { name: 'export.render', icon: '⤓', calls: 6, enabled: true },
    { name: 'doc.info', icon: 'ℹ', calls: 34, enabled: true },
    { name: 'style.apply', icon: '◐', calls: 0, enabled: false },
  ]

  private mcpResources: string[] = [
    'harmony://canvas/current',
    'harmony://layers',
    'harmony://pages',
    'harmony://pages/{id}',
    'harmony://assets',
    'harmony://styles',
  ]

  private modelProtocols: string[] = ['OpenAI', 'Anthropic', 'Google', '本地', '自定义']

  private modelProviders: string[] = ['OpenAI', 'Azure', 'DeepSeek', '通义千问', '百度文心', '智谱GLM', '讯飞星火', 'Moonshot', '本地', '其他']

  private agentSkills: AgentSkill[] = [
    { label: 'AI 图像生成', desc: '文生图/图生图/智能扩图', icon: '✦', agent: '创作引擎', connected: true },
    { label: '智能配色', desc: '色彩提取/配色方案/色盲优化', icon: '◐', agent: '创作引擎', connected: true },
    { label: '版式智能', desc: '自动排版/网格生成/布局建议', icon: '▦', agent: '创作引擎', connected: true },
    { label: '字体助手', desc: '字体匹配/字距优化/字体推荐', icon: 'T', agent: '创作引擎', connected: true },
    { label: '文案生成', desc: '广告文案/标题生成/多语言翻译', icon: '✎', agent: '创作引擎', connected: true },
    { label: '矢量创作', desc: '路径简化/形状生成/图标创作', icon: '✒', agent: '创作引擎', connected: true },
    { label: '样机生成', desc: '3D 样机/场景合成/贴图映射', icon: '◆', agent: '渲染引擎', connected: true },
    { label: '滤镜引擎', desc: '风格迁移/图像增强/特效滤镜', icon: '✦', agent: '渲染引擎', connected: false },
  ]
}