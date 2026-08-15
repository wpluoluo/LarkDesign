import http from '@ohos.net.http'
import preferences from '@ohos.data.preferences'
import { AppContext } from '../platform/AppContext'

export interface ByokConfig {
  provider: string
  baseUrl: string
  apiKey: string
  modelId: string
  temperature: number
}

export interface TestResult {
  ok: boolean
  message: string
  models?: string[]
}

interface ChatMessage {
  role: string
  content: string
}

interface ChatRequest {
  model: string
  temperature: number
  messages: ChatMessage[]
}

class ProviderPresets {
  static getBaseUrl(provider: string): string {
    if (provider === 'openai') return 'https://api.openai.com/v1'
    if (provider === 'deepseek') return 'https://api.deepseek.com/v1'
    if (provider === 'qwen') return 'https://dashscope.aliyuncs.com/compatible-mode/v1'
    if (provider === 'moonshot') return 'https://api.moonshot.cn/v1'
    return ''
  }

  static getModelId(provider: string): string {
    if (provider === 'openai') return 'gpt-4o-mini'
    if (provider === 'deepseek') return 'deepseek-chat'
    if (provider === 'qwen') return 'qwen-plus'
    if (provider === 'moonshot') return 'moonshot-v1-8k'
    return ''
  }
}

function defaultConfig(): ByokConfig {
  return {
    provider: 'deepseek',
    baseUrl: ProviderPresets.getBaseUrl('deepseek'),
    apiKey: '',
    modelId: ProviderPresets.getModelId('deepseek'),
    temperature: 0.7,
  }
}

export class BYOKStore {
  private static instance: BYOKStore
  private _config: ByokConfig = defaultConfig()
  private _isTesting: boolean = false
  private _lastTestResult: TestResult | null = null
  private _preferences: preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): BYOKStore {
    if (!BYOKStore.instance) {
      BYOKStore.instance = new BYOKStore()
    }
    return BYOKStore.instance
  }

  init(): void {
    const context = AppContext.get()
    if (context === null) return
    void preferences.getPreferences(context, 'larkdesign-byok').then((store: preferences.Preferences) => {
      this._preferences = store
      return store.get('config', '')
    }).then((raw: preferences.ValueType) => {
      if (typeof raw !== 'string' || raw.length === 0) return
      try {
        const value = JSON.parse(raw) as Partial<ByokConfig>
        this.updateConfig(value)
        AppStorage.setOrCreate<number>('byokVersion', Date.now())
      } catch (error) {
        console.error('BYOKStore', 'load failed: ' + error)
      }
    }).catch((error: Error) => {
      console.error('BYOKStore', 'preferences unavailable: ' + error.message)
    })
  }

  get config(): ByokConfig {
    return this._config
  }

  get isTesting(): boolean {
    return this._isTesting
  }

  get lastTestResult(): TestResult | null {
    return this._lastTestResult
  }

  get isConfigured(): boolean {
    return this._config.baseUrl.length > 0 && this._config.apiKey.length > 0 && this._config.modelId.length > 0
  }

  setProvider(provider: string): void {
    this._config.provider = provider
    const baseUrl = ProviderPresets.getBaseUrl(provider)
    const modelId = ProviderPresets.getModelId(provider)
    if (baseUrl.length > 0) this._config.baseUrl = baseUrl
    if (modelId.length > 0) this._config.modelId = modelId
  }

  updateConfig(patch: Partial<ByokConfig>): void {
    if (patch.provider !== undefined) this._config.provider = patch.provider
    if (patch.baseUrl !== undefined) this._config.baseUrl = patch.baseUrl
    if (patch.apiKey !== undefined) this._config.apiKey = patch.apiKey
    if (patch.modelId !== undefined) this._config.modelId = patch.modelId
    if (patch.temperature !== undefined) this._config.temperature = patch.temperature
  }

  save(): void {
    const json = JSON.stringify(this._config)
    void this.persistConfig(json).then(() => {
      AppStorage.setOrCreate<number>('byokVersion', Date.now())
    }).catch((error: Error) => {
      console.error('BYOKStore', 'save failed: ' + error.message)
    })
  }

  private async persistConfig(json: string): Promise<void> {
    try {
      const context = AppContext.get()
      if (context === null) throw new Error('application context is not initialized')
      if (this._preferences === null) {
        this._preferences = await preferences.getPreferences(context, 'larkdesign-byok')
      }
      await this._preferences.put('config', json)
      await this._preferences.flush()
    } catch (error) {
      throw new Error('persist BYOK config failed: ' + error)
    }
  }

  clear(): void {
    this._config = defaultConfig()
    this._lastTestResult = null
    if (this._preferences !== null) {
      void this.clearPersistedConfig().catch((error: Error) => {
        console.error('BYOKStore', 'clear failed: ' + error.message)
      })
    }
  }

  private async clearPersistedConfig(): Promise<void> {
    try {
      if (this._preferences === null) return
      await this._preferences.delete('config')
      await this._preferences.flush()
    } catch (error) {
      throw new Error('clear BYOK config failed: ' + error)
    }
  }

  async testConnection(): Promise<TestResult> {
    if (this._config.baseUrl.length === 0 || this._config.apiKey.length === 0) {
      const result: TestResult = { ok: false, message: '请填写 baseUrl 与 apiKey' }
      this._lastTestResult = result
      return result
    }
    this._isTesting = true
    try {
      const url = this._config.baseUrl.replace(/\/+$/, '') + '/models'
      const httpRequest = http.createHttp()
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': 'Bearer ' + this._config.apiKey,
          'Content-Type': 'application/json',
        },
        connectTimeout: 10000,
        readTimeout: 10000,
      })
      const statusCode = response.responseCode
      if (statusCode !== 200) {
        const result: TestResult = { ok: false, message: 'HTTP ' + statusCode }
        this._lastTestResult = result
        httpRequest.destroy()
        return result
      }
      const dataStr = response.result as string
      let data: Record<string, Object> = {}
      try {
        data = JSON.parse(dataStr) as Record<string, Object>
      } catch (e) {
        // ignore
      }
      const rawData = data['data']
      let models: string[] = []
      if (rawData instanceof Array) {
        for (let i = 0; i < rawData.length; i++) {
          const item = rawData[i] as Record<string, Object>
          if (item['id'] !== undefined) {
            models.push(String(item['id']))
          }
        }
      }
      const result: TestResult = {
        ok: true,
        message: '连接成功 · 可用模型 ' + models.length + ' 个',
        models: models,
      }
      this._lastTestResult = result
      httpRequest.destroy()
      return result
    } catch (err) {
      const result: TestResult = { ok: false, message: '连接失败 · ' + (err as Error).message }
      this._lastTestResult = result
      return result
    } finally {
      this._isTesting = false
    }
  }

  async complete(userText: string): Promise<string> {
    if (!this.isConfigured) throw new Error('请先在 BYOK 中配置 baseUrl、apiKey 和 modelId')
    const request = http.createHttp()
    try {
      const messages: ChatMessage[] = [{ role: 'user', content: userText }]
      const payload: ChatRequest = {
        model: this._config.modelId,
        temperature: this._config.temperature,
        messages,
      }
      const response = await request.request(this._config.baseUrl.replace(/\/+$/, '') + '/chat/completions', {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': 'Bearer ' + this._config.apiKey,
          'Content-Type': 'application/json',
        },
        extraData: JSON.stringify(payload),
        connectTimeout: 15000,
        readTimeout: 60000,
      })
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error('HTTP ' + response.responseCode)
      }
      const root = JSON.parse(response.result as string) as Record<string, Object>
      const choices = root['choices']
      if (!(choices instanceof Array) || choices.length === 0) throw new Error('响应缺少 choices')
      const first = choices[0] as Record<string, Object>
      const message = first['message'] as Record<string, Object>
      const content = message['content']
      if (typeof content !== 'string' || content.length === 0) throw new Error('响应缺少 message.content')
      return content
    } catch (error) {
      throw new Error('BYOK request failed: ' + error)
    } finally {
      try {
        request.destroy()
      } catch (error) {
        console.error('BYOKStore', 'destroy HTTP request failed: ' + error)
      }
    }
  }

  reset(): void {
    this._config = defaultConfig()
  }
}
