import {defineCollection, z} from 'astro:content'

const galleries = defineCollection({
  schema: ({image}) =>
    z.object({
      name: z.string(),
      date: z.date(),
      cover: image(),
    }),
})

export const collections = {
  galleries,
}
