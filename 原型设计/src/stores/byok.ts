/**
 * BYOK (Bring Your Own Key) 配置 Store
 *
 * 持久化用户自带的 LLM 配置：
 * - provider: 提供商（openai / deepseek / qwen / moonshot / 自定义）
 * - baseUrl: 模型 API 地址
 * - apiKey: 用户的 API Key
 * - modelId: 模型 ID（如 deepseek-chat, gpt-4o-mini）
 * - temperature: 采样温度
 *
 * 持久化到 localStorage（key: harmony.byok.config）。
 * 提供 testConnection() 通过简单的 /models 接口测试连接。
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

/** BYOK 配置 */
export interface ByokConfig {
  provider: 'openai' | 'deepseek' | 'qwen' | 'moonshot' | 'custom'
  baseUrl: string
  apiKey: string
  modelId: string
  temperature: number
}

/** 预设提供商的默认配置 */
export const PROVIDER_PRESETS: Record<ByokConfig['provider'], Partial<ByokConfig>> = {
  openai: { baseUrl: 'https://api.openai.com/v1', modelId: 'gpt-4o-mini' },
  deepseek: { baseUrl: 'https://api.deepseek.com/v1', modelId: 'deepseek-chat' },
  qwen: { baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1', modelId: 'qwen-plus' },
  moonshot: { baseUrl: 'https://api.moonshot.cn/v1', modelId: 'moonshot-v1-8k' },
  custom: { baseUrl: '', modelId: '' },
}

const STORAGE_KEY = 'harmony.byok.config'

function loadConfig(): ByokConfig {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw) as Partial<ByokConfig>
      return {
        provider: parsed.provider ?? 'deepseek',
        baseUrl: parsed.baseUrl ?? PROVIDER_PRESETS.deepseek.baseUrl ?? '',
        apiKey: parsed.apiKey ?? '',
        modelId: parsed.modelId ?? PROVIDER_PRESETS.deepseek.modelId ?? '',
        temperature: typeof parsed.temperature === 'number' ? parsed.temperature : 0.7,
      }
    }
  } catch {
    // localStorage 不可用或解析失败，使用默认值
  }
  return {
    provider: 'deepseek',
    baseUrl: PROVIDER_PRESETS.deepseek.baseUrl ?? '',
    apiKey: '',
    modelId: PROVIDER_PRESETS.deepseek.modelId ?? '',
    temperature: 0.7,
  }
}

export const useByokStore = defineStore('byok', () => {
  const config = ref<ByokConfig>(loadConfig())
  const isTesting = ref(false)
  const lastTestResult = ref<{ ok: boolean; message: string; models?: string[] } | null>(null)

  const isConfigured = computed(
    () => Boolean(config.value.baseUrl && config.value.apiKey && config.value.modelId),
  )

  /** 持久化到 localStorage */
  function persist(): void {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config.value))
    } catch {
      // localStorage 不可用，忽略
    }
  }

  /** 切换提供商，自动填充默认 baseUrl 与 modelId */
  function setProvider(provider: ByokConfig['provider']): void {
    config.value.provider = provider
    const preset = PROVIDER_PRESETS[provider]
    if (preset.baseUrl) config.value.baseUrl = preset.baseUrl
    if (preset.modelId) config.value.modelId = preset.modelId
  }

  /** 更新配置（部分字段） */
  function updateConfig(patch: Partial<ByokConfig>): void {
    Object.assign(config.value, patch)
  }

  /** 保存配置 */
  function save(): void {
    persist()
  }

  /** 测试连接（调用 /models 接口） */
  async function testConnection(): Promise<{ ok: boolean; message: string; models?: string[] }> {
    if (!config.value.baseUrl || !config.value.apiKey) {
      lastTestResult.value = { ok: false, message: '请填写 baseUrl 与 apiKey' }
      return lastTestResult.value
    }
    isTesting.value = true
    try {
      const url = `${config.value.baseUrl.replace(/\/$/, '')}/models`
      const res = await fetch(url, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${config.value.apiKey}`,
          'Content-Type': 'application/json',
        },
      })
      if (!res.ok) {
        const text = await res.text().catch(() => '')
        lastTestResult.value = {
          ok: false,
          message: `HTTP ${res.status} · ${text.slice(0, 100) || res.statusText}`,
        }
        return lastTestResult.value
      }
      const data = await res.json().catch(() => ({}))
      const models: string[] = Array.isArray(data?.data)
        ? data.data.map((m: { id?: string }) => m.id).filter(Boolean)
        : []
      lastTestResult.value = {
        ok: true,
        message: `连接成功 · 可用模型 ${models.length} 个`,
        models,
      }
      return lastTestResult.value
    } catch (err) {
      lastTestResult.value = {
        ok: false,
        message: `连接失败 · ${(err as Error).message}`,
      }
      return lastTestResult.value
    } finally {
      isTesting.value = false
    }
  }

  /** 清除配置 */
  function clear(): void {
    config.value = {
      provider: 'deepseek',
      baseUrl: PROVIDER_PRESETS.deepseek.baseUrl ?? '',
      apiKey: '',
      modelId: PROVIDER_PRESETS.deepseek.modelId ?? '',
      temperature: 0.7,
    }
    try {
      localStorage.removeItem(STORAGE_KEY)
    } catch {
      // ignore
    }
    lastTestResult.value = null
  }

  return {
    config,
    isTesting,
    lastTestResult,
    isConfigured,
    setProvider,
    updateConfig,
    save,
    testConnection,
    clear,
  }
})
