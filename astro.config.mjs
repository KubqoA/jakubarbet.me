import {defineConfig} from 'astro/config'
import tailwind from '@astrojs/tailwind'
import markdownIntegration from '@astropub/md'
import {imageService} from '@unpic/astro/service'

// https://astro.build/config
export default defineConfig({
  image: {
    service: imageService({placeholder: 'blurhash', fallbackService: 'sharp'}),
  },
  integrations: [tailwind(), markdownIntegration()],
})
