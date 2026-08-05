import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import './style.css'
import { useThemeStore } from './stores/theme'

const app = createApp(App)
const pinia = createPinia()
app.use(pinia)

// 在挂载前恢复主题，避免闪烁
const themeStore = useThemeStore(pinia)
themeStore.restoreTheme()
themeStore.bindSystemListener()

app.mount('#app')
