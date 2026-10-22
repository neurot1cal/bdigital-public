import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

// Static site deployed to Cloudflare Workers via wrangler.
// No SSR adapter needed: every page is pre-rendered at build time
// and Workers serves the dist/ directory as static assets.
export default defineConfig({
  site: 'https://public.bdigitalmedia.io',
  integrations: [tailwind()],
  output: 'static',
  // Preserve inline text spacing from the pre-Astro 7 HTML compressor.
  compressHTML: true,
  build: {
    assets: 'assets',
  },
});
