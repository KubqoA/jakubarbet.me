import {defineCollection, z} from 'astro:content'

const galleries = defineCollection({
  type: 'content',
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