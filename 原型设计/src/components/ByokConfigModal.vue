<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="visible" class="fixed inset-0 z-[300] flex flex-col justify-center items-center bg-black/40" @click.self="onClose">
        <div class="bg-[var(--color-white)] rounded-[12px] shadow-[0_24px_60px_rgba(0,0,0,0.25)] w-[460px] max-w-[92vw] overflow-hidden">
          <!-- Header -->
          <div class="flex flex-row justify-between items-center px-[20px] h-[52px] border-b border-[var(--color-border)]">
            <div class="flex flex-row items-center gap-[10px]">
              <div class="flex flex-row justify-center items-center w-[26px] h-[26px] bg-[var(--color-primary)] rounded-[6px]">
                <i class="fa-solid fa-key text-[11px] text-[var(--color-white)]"></i>
              </div>
              <div class="flex flex-col">
                <span class="text-[13px] leading-[16px] font-[700] text-[var(--color-title)]">BYOK 配置</span>
                <span class="text-[9px] leading-[11px] font-[400] text-[var(--color-muted)]">自带模型 API Key · 仅本地存储</span>
              </div>
            </div>
            <div class="flex flex-row justify-center items-center w-[24px] h-[24px] rounded-[4px] cursor-pointer hover:bg-[var(--color-hover-bg)]" @click="onClose">
              <i class="fa-solid fa-xmark text-[12px] text-[var(--color-tertiary)]"></i>
            </div>
          </div>

          <!-- Body -->
          <div class="flex flex-col gap-[14px] p-[20px]">
            <!-- Provider -->
            <div class="flex flex-col gap-[6px]">
              <label class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">提供商</label>
              <div class="flex flex-row gap-[6px]">
                <div
                  v-for="p in providers"
                  :key="p.value"
                  class="flex flex-row justify-center items-center h-[28px] px-[10px] rounded-[6px] border cursor-pointer text-[10px] leading-[12px] font-[500] transition-colors"
                  :class="byok.config.provider === p.value ? 'bg-[var(--color-primary)] border-[var(--color-primary)] text-[var(--color-white)]' : 'bg-[var(--color-panel)] border-[var(--color-border)] text-[var(--color-body)] hover:bg-[var(--color-hover-bg)]'"
                  @click="byok.setProvider(p.value)"
                >
                  {{ p.label }}
                </div>
              </div>
            </div>

            <!-- Base URL -->
            <div class="flex flex-col gap-[6px]">
              <label class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">Base URL</label>
              <input
                v-model="byok.config.baseUrl"
                type="text"
                placeholder="https://api.deepseek.com/v1"
                class="h-[32px] px-[10px] text-[11px] leading-[14px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[6px] outline-none focus:border-[var(--color-primary)] text-[var(--color-body)]"
              />
            </div>

            <!-- API Key -->
            <div class="flex flex-col gap-[6px]">
              <label class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">API Key</label>
              <div class="flex flex-row items-center gap-[6px]">
                <input
                  v-model="byok.config.apiKey"
                  :type="showKey ? 'text' : 'password'"
                  placeholder="sk-..."
                  class="flex-1 h-[32px] px-[10px] text-[11px] leading-[14px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[6px] outline-none focus:border-[var(--color-primary)] text-[var(--color-body)]"
                />
                <div class="flex flex-row justify-center items-center w-[32px] h-[32px] rounded-[6px] border border-[var(--color-border)] cursor-pointer hover:bg-[var(--color-hover-bg)]" @click="showKey = !showKey">
                  <i :class="['fa-solid', showKey ? 'fa-eye-slash' : 'fa-eye', 'text-[10px] text-[var(--color-tertiary)]']"></i>
                </div>
              </div>
            </div>

            <!-- Model ID -->
            <div class="flex flex-col gap-[6px]">
              <label class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">Model ID</label>
              <input
                v-model="byok.config.modelId"
                type="text"
                placeholder="deepseek-chat"
                list="model-list"
                class="h-[32px] px-[10px] text-[11px] leading-[14px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[6px] outline-none focus:border-[var(--color-primary)] text-[var(--color-body)]"
              />
              <datalist id="model-list">
                <option v-for="m in byok.lastTestResult?.models ?? []" :key="m" :value="m" />
              </datalist>
            </div>

            <!-- Temperature -->
            <div class="flex flex-col gap-[6px]">
              <div class="flex flex-row justify-between items-center">
                <label class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)]">采样温度</label>
                <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-secondary)]">{{ byok.config.temperature.toFixed(2) }}</span>
              </div>
              <input
                v-model.number="byok.config.temperature"
                type="range"
                min="0"
                max="2"
                step="0.05"
                class="w-full h-[4px] accent-[var(--color-primary)]"
              />
            </div>

            <!-- Test result -->
            <div v-if="byok.lastTestResult" class="flex flex-row items-start gap-[8px] p-[10px] rounded-[6px]" :class="byok.lastTestResult.ok ? 'bg-[#ECFDF5] border border-[#A7F3D0]' : 'bg-[#FEF2F2] border border-[#FCA5A5]'">
              <i :class="['fa-solid', byok.lastTestResult.ok ? 'fa-circle-check' : 'fa-circle-exclamation', 'text-[11px] mt-[1px]', byok.lastTestResult.ok ? 'text-[#059669]' : 'text-[#DC2626]']"></i>
              <p class="text-[10px] leading-[13px] font-[500] flex-1" :class="byok.lastTestResult.ok ? 'text-[#065F46]' : 'text-[#7F1D1D]'">{{ byok.lastTestResult.message }}</p>
            </div>
          </div>

          <!-- Footer -->
          <div class="flex flex-row justify-between items-center px-[20px] py-[12px] border-t border-[var(--color-border)] bg-[var(--color-panel)]">
            <div class="flex flex-row items-center gap-[8px]">
              <button class="text-[11px] leading-[14px] font-[500] text-[var(--color-muted)] hover:text-[var(--color-error)] px-[8px] py-[4px] rounded-[4px] hover:bg-[var(--color-hover-bg)]" @click="onClear">清除</button>
              <span v-if="byok.isConfigured" class="flex flex-row items-center gap-[4px] text-[9px] leading-[11px] font-[500] text-[#059669]">
                <i class="fa-solid fa-check-circle text-[8px]"></i>
                <span>已配置</span>
              </span>
            </div>
            <div class="flex flex-row items-center gap-[8px]">
              <button
                class="flex flex-row items-center gap-[6px] h-[30px] px-[12px] rounded-[6px] border border-[var(--color-border)] bg-[var(--color-white)] text-[11px] leading-[14px] font-[500] text-[var(--color-body)] hover:bg-[var(--color-hover-bg)] disabled:opacity-50 disabled:cursor-not-allowed"
                :disabled="byok.isTesting"
                @click="onTest"
              >
                <i :class="['fa-solid', byok.isTesting ? 'fa-circle-notch fa-spin' : 'fa-plug', 'text-[9px]']"></i>
                <span>{{ byok.isTesting ? '测试中...' : '测试连接' }}</span>
              </button>
              <button
                class="flex flex-row items-center gap-[6px] h-[30px] px-[14px] rounded-[6px] bg-[var(--color-primary)] text-[11px] leading-[14px] font-[600] text-[var(--color-white)] hover:bg-[var(--color-primary-dark-700)]"
                @click="onSave"
              >
                <i class="fa-solid fa-floppy-disk text-[9px]"></i>
                <span>保存</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useByokStore } from '../stores/byok'
import { useToastStore } from '../stores/toast'

const emit = defineEmits<{ (e: 'close'): void }>()

const byok = useByokStore()
const toast = useToastStore()

const visible = ref(true)
const showKey = ref(false)

const providers = [
  { label: 'DeepSeek', value: 'deepseek' as const },
  { label: 'OpenAI', value: 'openai' as const },
  { label: '通义千问', value: 'qwen' as const },
  { label: 'Moonshot', value: 'moonshot' as const },
  { label: '自定义', value: 'custom' as const },
]

function onClose(): void {
  visible.value = false
  emit('close')
}

function onSave(): void {
  byok.save()
  toast.show(`配置已保存 · ${byok.config.modelId}`, 'fa-floppy-disk', 'success')
  emit('close')
}

async function onTest(): Promise<void> {
  const result = await byok.testConnection()
  toast.show(result.message, result.ok ? 'fa-circle-check' : 'fa-triangle-exclamation', result.ok ? 'success' : 'warning')
}

function onClear(): void {
  byok.clear()
  toast.show('已清除配置', 'fa-trash', 'info')
}
</script>

<style scoped>
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.15s ease;
}
.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}
</style>
