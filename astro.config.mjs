import { defineConfig } from 'astro/config';
import tailwind from "@astrojs/tailwind";
import markdownIntegration from "@astropub/md";

// https://astro.build/config
export default defineConfig({
  image: {
    domains: ["drive.jakubarbet.me"],
  },
  integrations: [tailwind(), markdownIntegration(),]
});