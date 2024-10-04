import fs from 'node:fs/promises'
import {getPlaiceholder} from 'plaiceholder'

export const getPlaceholder = async (fsPath: string) => {
  const file = await fs.readFile(fsPath)
  const {css} = await getPlaiceholder(file)
  return css
}

export async function getAlbumImages(albumSlug: string) {
  let imagesGlob = import.meta.glob<{default: ImageMetadata}>('/src/content/albums/**/*.{jpeg,jpg}')
  imagesGlob = Object.fromEntries(Object.entries(imagesGlob).filter(([key]) => key.includes(albumSlug)))

  // Images are promises, so we need to resolve the glob promises
  const images = await Promise.all(Object.values(imagesGlob).map((image) => image().then((mod) => mod.default)))

  const imagesWithPlaceholders = await Promise.all(
    images.map(async (image) => ({
      ...image,
      placeholder: getPlaceholder(image.src.slice(4).split('?')[0]),
    })),
  )

  return imagesWithPlaceholders
}
