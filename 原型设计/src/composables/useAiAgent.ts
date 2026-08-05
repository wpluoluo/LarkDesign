/**
 * useAiAgent - AI Agent composable
 *
 * 实现 OpenAI 兼容的 chat/completions 调用循环，支持 tool calling：
 * 1. 把 MCP tools 注册表转换为 OpenAI function 格式
 * 2. 发送对话历史到 LLM
 * 3. 如果模型返回 tool_calls，调用 MCP registry 执行对应工具
 * 4. 把工具结果作为 tool message 追加到历史
 * 5. 循环直到模型不再请求工具调用
 *
 * 若未配置 BYOK，则降级为"演示模式"：根据关键词触发预设工具调用。
 */
import { ref } from 'vue'
import type { Ref } from 'vue'
import { useByokStore } from '../stores/byok'
import { useToastStore } from '../stores/toast'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import { listTools, callTool, createToolCallLog, type ToolCallLog, type ToolContext } from '../ai/mcp'

/** 消息角色 */
export type ChatRole = 'system' | 'user' | 'assistant' | 'tool'

/** 对话消息 */
export interface ChatMessage {
  role: ChatRole
  content: string
  tool_calls?: Array<{
    id: string
    type: 'function'
    function: { name: string; arguments: string }
  }>
  tool_call_id?: string
  name?: string
}

/** 演示模式的关键词 → 工具调用映射 */
const DEMO_KEYWORD_MAP: Array<{ keywords: string[]; tool: string; args: () => Record<string, unknown>; reply: string }> = [
  {
    keywords: ['新建图层', '加图层', '新增图层'],
    tool: 'layer.create',
    args: () => ({ name: 'AI 新图层' }),
    reply: '已为你新建一个图层「AI 新图层」，你可以在右侧图层面板查看。',
  },
  {
    keywords: ['列表', '看看图层', '都有什么'],
    tool: 'layer.list',
    args: () => ({}),
    reply: '已读取当前图层数据，请在右侧面板查看完整列表。',
  },
  {
    keywords: ['白底', '白色背景', '背景白'],
    tool: 'canvas.background',
    args: () => ({ color: '#FFFFFF' }),
    reply: '画布背景已切换为白色。',
  },
  {
    keywords: ['深色背景', '黑底', '黑色背景'],
    tool: 'canvas.background',
    args: () => ({ color: '#1F2329' }),
    reply: '画布背景已切换为深色。',
  },
  {
    keywords: ['画布信息', '文档信息', '当前画布'],
    tool: 'canvas.info',
    args: () => ({}),
    reply: '已读取画布信息，可在状态栏查看尺寸与图层数。',
  },
]

export interface UseAiAgentOptions {
  /** 最大工具调用循环次数（防死循环） */
  maxIterations?: number
}

export function useAiAgent(opts: UseAiAgentOptions = {}) {
  const byok = useByokStore()
  const toast = useToastStore()
  const fusion = useFusionDocumentStore()

  const messages: Ref<ChatMessage[]> = ref<ChatMessage[]>([
    {
      role: 'assistant',
      content: '你好！我是 Harmony AI。可以帮你读取/修改图层、调整画布、生成对象等。试试说「新建一个图层」或「把背景设为白色」。',
    },
  ])
  const isThinking = ref(false)
  const toolCallLogs: Ref<ToolCallLog[]> = ref<ToolCallLog[]>([])
  const lastError = ref<string | null>(null)

  /** 构建 ToolContext */
  function buildToolContext(): ToolContext {
    return { fusion }
  }

  /** 把 MCP tools 转为 OpenAI function 格式 */
  function buildToolsForOpenAI() {
    return listTools().map(t => ({
      type: 'function' as const,
      function: {
        name: t.name,
        description: t.description,
        parameters: t.inputSchema,
      },
    }))
  }

  /** 演示模式：根据关键词匹配工具调用 */
  async function runDemoReply(userInput: string): Promise<{ reply: string; toolCalls: ToolCallLog[] }> {
    const ctx = buildToolContext()
    const lower = userInput.toLowerCase()
    const match = DEMO_KEYWORD_MAP.find(m => m.keywords.some(k => lower.includes(k.toLowerCase())))
    const logs: ToolCallLog[] = []
    let reply = '我目前处于演示模式（未配置 BYOK），无法连接到真实大模型。'
    if (match) {
      const args = match.args()
      const start = performance.now()
      const result = await callTool(match.tool, args, ctx)
      const log = createToolCallLog(match.tool, args, result, performance.now() - start)
      logs.push(log)
      reply = match.reply
    } else {
      reply = '我目前处于演示模式（未配置 BYOK）。可识别的关键词：新建图层 / 列表 / 白底 / 深色背景 / 画布信息。要使用真实大模型，请点击齿轮配置 BYOK。'
    }
    return { reply, toolCalls: logs }
  }

  /** 调用 OpenAI 兼容 API（非流式） */
  async function callChatCompletion(history: ChatMessage[]): Promise<{
    content: string
    tool_calls?: ChatMessage['tool_calls']
  }> {
    const url = `${byok.config.baseUrl.replace(/\/$/, '')}/chat/completions`
    const body = {
      model: byok.config.modelId,
      messages: history,
      temperature: byok.config.temperature,
      tools: buildToolsForOpenAI(),
      tool_choice: 'auto',
    }
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${byok.config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })
    if (!res.ok) {
      const text = await res.text().catch(() => '')
      throw new Error(`HTTP ${res.status} · ${text.slice(0, 200) || res.statusText}`)
    }
    const data = await res.json()
    const choice = data?.choices?.[0]?.message
    if (!choice) throw new Error('响应中缺少 choices[0].message')
    return {
      content: choice.content ?? '',
      tool_calls: choice.tool_calls,
    }
  }

  /** 发送用户消息 */
  async function send(userInput: string): Promise<void> {
    if (!userInput.trim()) return
    lastError.value = null

    // 追加用户消息
    messages.value.push({ role: 'user', content: userInput })

    // 演示模式
    if (!byok.isConfigured) {
      const { reply, toolCalls } = await runDemoReply(userInput)
      toolCallLogs.value.push(...toolCalls)
      messages.value.push({ role: 'assistant', content: reply })
      return
    }

    // 真实模式：循环调用直到不再有 tool_calls
    isThinking.value = true
    try {
      const maxIter = opts.maxIterations ?? 8
      let iter = 0
      while (iter < maxIter) {
        iter++
        const resp = await callChatCompletion(messages.value)
        // 追加 assistant 消息
        const assistantMsg: ChatMessage = {
          role: 'assistant',
          content: resp.content,
          tool_calls: resp.tool_calls,
        }
        messages.value.push(assistantMsg)

        if (!resp.tool_calls || resp.tool_calls.length === 0) {
          // 没有工具调用，结束循环
          break
        }

        // 执行所有工具调用
        const ctx = buildToolContext()
        for (const tc of resp.tool_calls) {
          const args = JSON.parse(tc.function.arguments || '{}') as Record<string, unknown>
          const start = performance.now()
          const result = await callTool(tc.function.name, args, ctx)
          const log = createToolCallLog(tc.function.name, args, result, performance.now() - start)
          toolCallLogs.value.push(log)
          // 追加 tool 消息
          messages.value.push({
            role: 'tool',
            content: JSON.stringify(result),
            tool_call_id: tc.id,
            name: tc.function.name,
          })
        }
      }
      if (iter >= maxIter) {
        toast.show('工具调用次数达上限', 'fa-triangle-exclamation', 'warning')
      }
    } catch (err) {
      lastError.value = (err as Error).message
      messages.value.push({
        role: 'assistant',
        content: `调用失败：${(err as Error).message}`,
      })
      toast.show('AI 调用失败', 'fa-triangle-exclamation', 'warning')
    } finally {
      isThinking.value = false
    }
  }

  /** 清空对话 */
  function clearConversation(): void {
    messages.value = [
      {
        role: 'assistant',
        content: '对话已清空。请告诉我你想做什么？',
      },
    ]
    toolCallLogs.value = []
    lastError.value = null
  }

  return {
    messages,
    isThinking,
    toolCallLogs,
    lastError,
    send,
    clearConversation,
  }
}
