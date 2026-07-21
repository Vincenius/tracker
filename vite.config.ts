import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    port: 3024,
    host: true,
    // Im Dev-Modus läuft das Backend daneben auf 3025 (npm run dev:all).
    proxy: { '/api': { target: 'http://localhost:3025', changeOrigin: true } },
  },
});
