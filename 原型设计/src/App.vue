<template>
  <SplashScreen v-if="showSplash" @enter-workspace="showSplash = false" />
  <WorkspaceLayout v-else @home="showSplash = true" />
  <ToastContainer />
</template>

<script setup lang="ts">
import { ref } from 'vue'
import SplashScreen from './components/SplashScreen.vue'
import WorkspaceLayout from './components/WorkspaceLayout.vue'
import ToastContainer from './components/ToastContainer.vue'

// 支持 URL hash #workspace 直接进入工作区（便于调试与自动化测试）
const showSplash = ref(!location.hash.includes('workspace'))
</script>