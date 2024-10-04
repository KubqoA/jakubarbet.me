import {defineCollection, z} from 'astro:content'

const albums = defineCollection({
  schema: ({image}) =>
    z.object({
      name: z.string(),
      date: z.date(),
      cover: image(),
    }),
})

export const collections = {
  albums,
}
