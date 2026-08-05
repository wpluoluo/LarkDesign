import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  server: {
    // 固定端口 5175，若被占用则直接退出（避免端口漂移）
    port: 5175,
    strictPort: true,
    host: '127.0.0.1',
  },
  preview: {
    port: 5175,
    strictPort: true,
    host: '127.0.0.1',
  },
})