<template>
  <div class="flex flex-row justify-between items-center h-[24px] px-[6px] bg-[var(--color-panel)] border border-[var(--color-border)] rounded-[4px]">
    <span class="text-[9px] leading-[12px] font-[600] font-mono" :style="{ color: labelColor }">{{ label }}</span>
    <div class="flex flex-row items-center gap-[2px]">
      <input
        class="w-[30px] bg-transparent text-[9px] leading-[12px] font-[500] font-mono text-[var(--color-body)] border-none outline-none text-right"
        type="number"
        :value="modelValue"
        :min="min"
        :max="max"
        @input="onInput"
      />
      <span v-if="suffix" class="text-[8px] leading-[10px] font-[400] text-[var(--color-muted)]">{{ suffix }}</span>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  labelColor?: string
  modelValue: number
  suffix?: string
  min?: number
  max?: number
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: number): void
}>()

const onInput = (e: Event) => {
  const val = parseInt((e.target as HTMLInputElement).value)
  if (!isNaN(val)) {
    emit('update:modelValue', val)
  }
}
</script>
