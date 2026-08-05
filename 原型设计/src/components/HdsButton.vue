<template>
  <button
    :class="[
      'inline-flex items-center justify-center font-[600] transition-all duration-150',
      sizeClasses,
      variantClasses,
      stateClasses,
      { 'cursor-not-allowed': state === 'disabled' },
    ]"
    :disabled="state === 'disabled'"
    @click="handleClick"
  >
    <i v-if="icon" :class="['fa-solid', icon, iconPosition === 'left' ? 'mr-[8px]' : 'ml-[8px]', iconSize]"></i>
    <span v-if="state === 'loading'" class="mr-[6px]">
      <i class="fa-solid fa-circle-notch animate-spin text-[inherit]"></i>
    </span>
    <slot />
    <i v-if="iconRight" :class="['fa-solid', iconRight, 'ml-[8px]', iconSize]"></i>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { ButtonVariant, ButtonSize, ButtonState } from '../types'

const props = withDefaults(defineProps<{
  variant?: ButtonVariant
  size?: ButtonSize
  state?: ButtonState
  icon?: string
  iconRight?: string
  iconPosition?: 'left' | 'right'
}>(), {
  variant: 'primary',
  size: 'md',
  state: 'default',
  iconPosition: 'left',
})

const emit = defineEmits<{
  click: [e: MouseEvent]
}>()

const handleClick = (e: MouseEvent) => {
  if (props.state !== 'disabled' && props.state !== 'loading') {
    emit('click', e)
  }
}

const sizeClasses = computed(() => {
  switch (props.size) {
    case 'sm': return 'h-[32px] px-[12px] text-[12px] leading-[16px] rounded-[6px] gap-[4px]'
    case 'md': return 'h-[40px] px-[20px] text-[14px] leading-[18px] rounded-[8px] gap-[6px]'
    case 'lg': return 'h-[48px] px-[24px] text-[16px] leading-[20px] rounded-[10px] gap-[8px]'
  }
})

const iconSize = computed(() => {
  switch (props.size) {
    case 'sm': return 'text-[10px]'
    case 'md': return 'text-[12px]'
    case 'lg': return 'text-[14px]'
  }
})

const variantClasses = computed(() => {
  switch (props.variant) {
    case 'primary':
      return 'bg-[var(--color-primary)] text-[var(--color-white)] border-none'
    case 'secondary':
      return 'bg-[var(--color-white)] text-[var(--color-body)] border border-[var(--color-border)]'
    case 'text':
      return 'bg-transparent text-[var(--color-body)] border-none hover:bg-[var(--color-panel)]'
    case 'danger':
      return 'bg-[var(--color-error)] text-[var(--color-white)] border-none'
    case 'success':
      return 'bg-[var(--color-success)] text-[var(--color-white)] border-none'
  }
})

const stateClasses = computed(() => {
  if (props.state === 'disabled') return 'opacity-50'
  if (props.state === 'loading') return 'opacity-80 cursor-wait'
  return ''
})
</script>