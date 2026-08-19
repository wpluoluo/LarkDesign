/**
 * AiAgent - AI 对话引擎
 *
 * 对应原型 src/composables/useAiAgent.ts
 * 实现 OpenAI 兼容的 chat/completions 调用循环，支持 tool calling。
 * 未配置 BYOK 时降级为演示模式：根据关键词触发预设工具调用。
 */
import { BYOKStore } from '../state/BYOKStore'
import { FusionDocumentStore } from '../../../domain/FusionDocumentStore'
import { getToolAt, getToolCount, callTool, createToolCallLog, ToolResult, ToolDef } from './MCPRegistry'
import http from '@ohos.net.http'

export interface ChatMessage {
  role: string
  content: string
  tool_calls?: string
  tool_call_id?: string
  name?: string
}

export interface AiAgentState {
  messages: ChatMessage[]
  isThinking: boolean
  toolCallLogs: string
  lastError: string
}

function makeRecord(key: string, value: string): Record<string, string> {
  const r: Record<string, string> = {}
  if (key.length > 0) {
    r[key] = value
  }
  return r
}

export class AiAgent {
  private byokStore: BYOKStore = BYOKStore.getInstance()
  private fusionStore: FusionDocumentStore = FusionDocumentStore.getInstance()
  private msgs: ChatMessage[] = []
  private _isThinking: boolean = false
  private _logs: string = '[]'
  private _lastError: string = ''

  constructor() {
    const initMsg: ChatMessage = {
      role: 'assistant',
      content: '你好！我是 Harmony AI。可以帮你读取/修改图层、调整画布、生成对象等。试试说「新建一个图层」或「把背景设为白色」。',
    }
    this.msgs.push(initMsg)
  }

  getState(): AiAgentState {
    const state: AiAgentState = {
      messages: this.msgs.slice(),
      isThinking: this._isThinking,
      toolCallLogs: this._logs,
      lastError: this._lastError,
    }
    return state
  }

  private findDemoMatch(userInput: string): string {
    const lower = userInput.toLowerCase()
    const rules: string[][] = [
      ['新建图层', '加图层', '新增图层'],
      ['列表', '看看图层', '都有什么'],
      ['白底', '白色背景', '背景白'],
      ['深色背景', '黑底', '黑色背景'],
      ['画布信息', '文档信息', '当前画布'],
    ]
    const toolNames: string[] = ['layer.create', 'layer.list', 'canvas.background', 'canvas.background', 'canvas.info']
    const replies: string[] = [
      '已为你新建一个图层「AI 新图层」，你可以在右侧图层面板查看。',
      '已读取当前图层数据，请在右侧面板查看完整列表。',
      '画布背景已切换为白色。',
      '画布背景已切换为深色。',
      '已读取画布信息，可在状态栏查看尺寸与图层数。',
    ]
    const argBuilders: (() => Record<string, string>)[] = [
      (): Record<string, string> => { return makeRecord('name', 'AI 新图层') },
      (): Record<string, string> => { return makeRecord('', '') },
      (): Record<string, string> => { return makeRecord('color', '#FFFFFF') },
      (): Record<string, string> => { return makeRecord('color', '#1F2329') },
      (): Record<string, string> => { return makeRecord('', '') },
    ]
    for (let i = 0; i < rules.length; i++) {
      for (let j = 0; j < rules[i].length; j++) {
        if (lower.includes(rules[i][j].toLowerCase())) {
          const args = argBuilders[i]()
          const start = Date.now()
          const result = callTool(toolNames[i], args, this.fusionStore)
          const log = createToolCallLog(toolNames[i], args, result, Date.now() - start)
          const existingLogs = JSON.parse(this._logs) as object[]
          existingLogs.push(log)
          this._logs = JSON.stringify(existingLogs)
          return replies[i]
        }
      }
    }
    return '我目前处于演示模式（未配置 BYOK）。可识别的关键词：新建图层 / 列表 / 白底 / 深色背景 / 画布信息。要使用真实大模型，请配置 BYOK。'
  }

  private buildOpenAIToolsStr(): string {
    const items: string[] = []
    const count = getToolCount()
    for (let i = 0; i < count; i++) {
      const t: ToolDef = getToolAt(i)
      let schema: string = t.inputSchema
      if (schema === '{}') {
        schema = '{"type":"object","properties":{}}'
      }
      const item = '{"type":"function","function":{"name":"' + t.name + '","description":"' + t.description + '","parameters":' + schema + '}}'
      items.push(item)
    }
    return '[' + items.join(',') + ']'
  }

  async send(userInput: string): Promise<ChatMessage[]> {
    if (!userInput.trim()) return this.msgs
    this._lastError = ''
    const userMsg: ChatMessage = { role: 'user', content: userInput }
    this.msgs.push(userMsg)

    if (!this.byokStore.isConfigured) {
      const reply = this.findDemoMatch(userInput)
      const assistantMsg: ChatMessage = { role: 'assistant', content: reply }
      this.msgs.push(assistantMsg)
      return this.msgs
    }

    this._isThinking = true
    try {
      const maxIter = 8
      let iter = 0
      while (iter < maxIter) {
        iter++
        const resp = await this.callChatCompletion(this.msgs)
        const assistantMsg: ChatMessage = { role: 'assistant', content: resp.content }
        if (resp.toolCallsStr.length > 0) {
          assistantMsg.tool_calls = resp.toolCallsStr
        }
        this.msgs.push(assistantMsg)

        if (resp.toolCallsStr.length === 0) {
          break
        }

        let tcArr: ToolCallItem[] = []
        try {
          tcArr = JSON.parse(resp.toolCallsStr) as ToolCallItem[]
        } catch (_e) {
          tcArr = []
        }

        for (let ti = 0; ti < tcArr.length; ti++) {
          const tc = tcArr[ti]
          const fnName = tc.function?.name ?? ''
          const fnArgsStr = tc.function?.arguments ?? '{}'
          let fnArgs: Record<string, string> = {}
          try {
            const parsed = JSON.parse(fnArgsStr) as Record<string, string>
            fnArgs = parsed
          } catch (_e) {
            fnArgs = {}
          }
          const start = Date.now()
          const result = callTool(fnName, fnArgs, this.fusionStore)
          const log = createToolCallLog(fnName, fnArgs, result, Date.now() - start)
          const existingLogs = JSON.parse(this._logs) as object[]
          existingLogs.push(log)
          this._logs = JSON.stringify(existingLogs)
          const toolMsg: ChatMessage = {
            role: 'tool',
            content: JSON.stringify(result),
            tool_call_id: tc.id,
            name: fnName,
          }
          this.msgs.push(toolMsg)
        }
      }
    } catch (err) {
      this._lastError = (err as Error).message
      const errMsg: ChatMessage = {
        role: 'assistant',
        content: `调用失败：${(err as Error).message}`,
      }
      this.msgs.push(errMsg)
    } finally {
      this._isThinking = false
    }
    return this.msgs
  }

  private async callChatCompletion(history: ChatMessage[]): Promise<ChatCompletionResult> {
    const config = this.byokStore.config
    const baseUrl: string = config.baseUrl.replace(/\/$/, '')
    const url: string = baseUrl + '/chat/completions'

    const httpRequest = http.createHttp()
    const toolsStr: string = this.buildOpenAIToolsStr()
    const body: string = '{"model":"' + config.modelId + '","messages":' + JSON.stringify(history) + ',"temperature":0.7,"tools":' + toolsStr + ',"tool_choice":"auto"}'

    return new Promise((resolve, reject) => {
      httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${config.apiKey}`,
          'Content-Type': 'application/json',
        },
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 60000,
      }).then((resp: http.HttpResponse) => {
        httpRequest.destroy()
        if (resp.responseCode !== 200) {
          reject(new Error(`HTTP ${resp.responseCode}`))
          return
        }
        const data = JSON.parse(resp.result as string) as ChatResponse
        const choice = data?.choices?.[0]?.message
        if (!choice) {
          reject(new Error('响应中缺少 choices[0].message'))
          return
        }
        let toolCallsStr = ''
        if (choice.tool_calls) {
          toolCallsStr = JSON.stringify(choice.tool_calls)
        }
        const result: ChatCompletionResult = { content: choice.content ?? '', toolCallsStr }
        resolve(result)
      }).catch((err: Error) => {
        httpRequest.destroy()
        reject(new Error(`请求失败: ${err.message}`))
      })
    })
  }

  clearConversation(): void {
    this.msgs = []
    const msg: ChatMessage = { role: 'assistant', content: '对话已清空。请告诉我你想做什么？' }
    this.msgs.push(msg)
    this._logs = '[]'
    this._lastError = ''
  }
}

interface ToolCallFunc {
  name: string
  arguments: string
}

interface ToolCallItem {
  id: string
  type: string
  function?: ToolCallFunc
}

interface ChatChoiceMessage {
  content?: string
  tool_calls?: object[]
}

interface ChatChoice {
  message?: ChatChoiceMessage
}

interface ChatResponse {
  choices?: ChatChoice[]
}

interface ChatCompletionResult {
  content: string
  toolCallsStr: string
}
