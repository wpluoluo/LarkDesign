/**
 * BYOKStore - BYOK 配置状态管理
 *
 * 对应原型 src/stores/byok.ts
 * 管理 Bring Your Own Key 配置
 */
export interface ByokConfig {
  enabled: boolean
  provider: string
  apiKey: string
  model: string
  endpoint: string
}

export class BYOKStore {
  private static instance: BYOKStore
  private _config: ByokConfig = {
    enabled: false,
    provider: 'openai',
    apiKey: '',
    model: 'gpt-4o',
    endpoint: 'https://api.openai.com/v1',
  }

  private constructor() {}

  static getInstance(): BYOKStore {
    if (!BYOKStore.instance) {
      BYOKStore.instance = new BYOKStore()
    }
    return BYOKStore.instance
  }

  get config(): ByokConfig {
    return this._config
  }

  get isConfigured(): boolean {
    return this._config.enabled && this._config.apiKey.length > 0
  }

  updateConfig(config: Partial<ByokConfig>): void {
    if (config.enabled !== undefined) this._config.enabled = config.enabled
    if (config.provider !== undefined) this._config.provider = config.provider
    if (config.apiKey !== undefined) this._config.apiKey = config.apiKey
    if (config.model !== undefined) this._config.model = config.model
    if (config.endpoint !== undefined) this._config.endpoint = config.endpoint
  }

  reset(): void {
    this._config = {
      enabled: false,
      provider: 'openai',
      apiKey: '',
      model: 'gpt-4o',
      endpoint: 'https://api.openai.com/v1',
    }
  }
}
