<template>
  <div :class="contentClasses">
    <!-- Header bar: model + BYOK -->
    <div class="flex flex-row items-center justify-between px-[10px] h-[32px] border-b border-[var(--color-border-light)] shrink-0 bg-[var(--color-panel)]">
      <div class="flex flex-row items-center gap-[6px]">
        <i class="fa-solid fa-microchip text-[9px] text-[var(--color-secondary)]"></i>
        <span class="text-[10px] leading-[12px] font-[600] text-[var(--color-body)] truncate max-w-[140px]">{{ byok.isConfigured ? byok.config.modelId : '演示模式' }}</span>
        <span v-if="!byok.isConfigured" class="text-[8px] leading-[10px] font-[500] text-[#C97912] bg-[#FFF8E8] border border-[#F4D48A] px-[4px] py-[1px] rounded-[3px]">未配置</span>
      </div>
      <div class="flex flex-row items-center gap-[6px]">
        <div class="flex flex-row items-center justify-center w-[20px] h-[20px] rounded-[4px] cursor-pointer hover:bg-[var(--color-hover-bg)]" @click="showByokModal = true" title="BYOK 配置">
          <i class="fa-solid fa-gear text-[10px] text-[var(--color-tertiary)]"></i>
        </div>
        <div class="flex flex-row items-center justify-center w-[20px] h-[20px] rounded-[4px] cursor-pointer hover:bg-[var(--color-hover-bg)]" @click="clearConversation()" title="清空对话">
          <i class="fa-solid fa-rotate-left text-[9px] text-[var(--color-tertiary)]"></i>
        </div>
      </div>
    </div>

    <div ref="scrollRef" class="flex flex-col justify-start items-stretch flex-1 min-h-0 overflow-y-auto">
      <!-- 对话气泡 -->
      <div class="flex flex-col gap-[10px] p-[12px]">
        <template v-for="(msg, i) in messages" :key="i">
          <!-- AI message -->
          <div v-if="msg.role === 'assistant'" class="flex flex-row items-start gap-[8px]">
            <div class="flex flex-row justify-center items-center w-[24px] h-[24px] bg-[var(--color-primary)] rounded-[6px] shrink-0 mt-[2px]">
              <i class="fa-solid fa-robot text-[10px] text-[var(--color-white)]"></i>
            </div>
            <div class="flex flex-col gap-[4px] max-w-[80%]">
              <div class="px-[10px] py-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[8px] rounded-tl-[2px]">
                <p class="text-[11px] leading-[16px] font-[400] text-[var(--color-body)] whitespace-pre-wrap break-words">{{ msg.content }}</p>
              </div>
            </div>
          </div>
          <!-- User message -->
          <div v-else-if="msg.role === 'user'" class="flex flex-row items-start justify-end gap-[8px]">
            <div class="flex flex-col items-end gap-[4px] max-w-[80%]">
              <div class="px-[10px] py-[8px] bg-[var(--color-hover-bg)] border border-[#B8EAD4] rounded-[8px] rounded-tr-[2px]">
                <p class="text-[11px] leading-[16px] font-[500] text-[var(--color-body)] whitespace-pre-wrap break-words">{{ msg.content }}</p>
              </div>
            </div>
            <div class="flex flex-row justify-center items-center w-[24px] h-[24px] bg-[var(--color-title)] rounded-[6px] shrink-0 mt-[2px]">
              <span class="text-[8px] leading-[10px] font-[700] text-[var(--color-white)]">U</span>
            </div>
          </div>
          <!-- Tool message（折叠展示） -->
          <div v-else-if="msg.role === 'tool'" class="flex flex-row items-start gap-[8px] ml-[32px]">
            <div class="flex flex-row items-center gap-[6px] px-[8px] py-[4px] bg-[var(--color-white)] border border-[var(--color-border-light)] rounded-[4px]">
              <i class="fa-solid fa-wrench text-[7px] text-[var(--color-tertiary)]"></i>
              <span class="text-[8px] leading-[10px] font-[500] text-[var(--color-muted)]">{{ msg.name }}</span>
              <i class="fa-solid fa-check text-[7px] text-[var(--color-primary)]"></i>
            </div>
          </div>
        </template>

        <!-- Thinking indicator -->
        <div v-if="isThinking" class="flex flex-row items-start gap-[8px]">
          <div class="flex flex-row justify-center items-center w-[24px] h-[24px] bg-[var(--color-primary)] rounded-[6px] shrink-0 mt-[2px]">
            <i class="fa-solid fa-robot text-[10px] text-[var(--color-white)] fa-spin"></i>
          </div>
          <div class="px-[10px] py-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[8px] rounded-tl-[2px]">
            <p class="text-[11px] leading-[16px] font-[400] text-[var(--color-muted)]">思考中...</p>
          </div>
        </div>

        <!-- 演示模式提示 -->
        <div v-if="!byok.isConfigured" class="flex flex-row items-start gap-[8px] bg-[#FFF8E8] border border-[#F4D48A] rounded-[6px] p-[10px]">
          <i class="fa-solid fa-circle-info text-[10px] text-[#C97912] mt-[1px] shrink-0"></i>
          <div class="flex flex-col gap-[4px]">
            <p class="text-[9px] leading-[13px] font-[600] text-[#7A5314]">演示模式</p>
            <p class="text-[9px] leading-[13px] font-[500] text-[#7A5314]">可识别关键词：新建图层 / 列表 / 白底 / 深色背景 / 画布信息。点击右上角齿轮配置 BYOK 以接入真实大模型。</p>
          </div>
        </div>

        <!-- 错误提示 -->
        <div v-if="lastError" class="flex flex-row items-start gap-[8px] bg-[#FEF2F2] border border-[#FCA5A5] rounded-[6px] p-[10px]">
          <i class="fa-solid fa-triangle-exclamation text-[10px] text-[#DC2626] mt-[1px] shrink-0"></i>
          <p class="text-[9px] leading-[13px] font-[500] text-[#7F1D1D]">{{ lastError }}</p>
        </div>
      </div>
    </div>

    <!-- Input Footer -->
    <div class="flex flex-col border-t border-[var(--color-border)] bg-[var(--color-white)] shrink-0">
      <!-- Input row -->
      <div class="flex flex-row items-center gap-[6px] px-[10px] py-[8px]">
        <i class="fa-solid fa-paperclip text-[10px] text-[var(--color-tertiary)] cursor-pointer hover:text-[var(--color-body)]"></i>
        <div class="flex-1 h-[28px] px-[8px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px] flex items-center">
          <input
            ref="aiInput"
            type="text"
            v-model="inputText"
            placeholder="输入设计需求..."
            class="flex-1 text-[10px] leading-[14px] bg-transparent border-none outline-none text-[var(--color-body)] placeholder:text-[#9AA2AC]"
            @keydown.enter.prevent="onSend"
          />
        </div>
        <div
          class="flex flex-row justify-center items-center w-[28px] h-[28px] rounded-[6px] cursor-pointer transition-colors"
          :class="inputText.trim() && !isThinking ? 'bg-[var(--color-primary-dark-700)] hover:bg-[var(--color-primary-dark-900)]' : 'bg-[var(--color-border-light)] cursor-not-allowed'"
          @click="onSend"
        >
          <i class="fa-solid fa-arrow-up text-[10px] text-[var(--color-white)]"></i>
        </div>
      </div>
      <!-- Context info -->
      <div class="flex flex-row items-center gap-[6px] px-[10px] pt-[4px] pb-[2px]">
        <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ fusionDoc.sceneInfo.layerCount }} 个图层</span>
        <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">·</span>
        <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ toolCallLogs.length }} 次工具调用</span>
        <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">·</span>
        <span class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ embedded ? '嵌入' : '独立' }}</span>
      </div>
    </div>

    <!-- BYOK Modal -->
    <ByokConfigModal v-if="showByokModal" @close="showByokModal = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useAiAgent } from '../composables/useAiAgent'
import { useByokStore } from '../stores/byok'
import { useFusionDocumentStore } from '../stores/fusionDocument'
import ByokConfigModal from './ByokConfigModal.vue'

const props = withDefaults(defineProps<{
  embedded?: boolean
}>(), {
  embedded: false,
})

const byok = useByokStore()
const fusionDoc = useFusionDocumentStore()
const { messages, isThinking, toolCallLogs, lastError, send, clearConversation } = useAiAgent({ maxIterations: 6 })

const aiInput = ref<HTMLInputElement | null>(null)
const scrollRef = ref<HTMLElement | null>(null)
const inputText = ref('')
const showByokModal = ref(false)

const contentClasses = computed(() => {
  if (props.embedded) {
    return 'flex flex-col justify-start items-stretch flex-1 min-h-0'
  }
  return 'flex flex-col justify-start items-stretch w-[300px] bg-[#FAFBFB] border-l border-[#C9CED5] shrink-0'
})

async function onSend(): Promise<void> {
  const text = inputText.value.trim()
  if (!text || isThinking.value) return
  inputText.value = ''
  await send(text)
  await nextTick()
  if (scrollRef.value) scrollRef.value.scrollTop = scrollRef.value.scrollHeight
  if (aiInput.value) aiInput.value.focus()
}
</script>