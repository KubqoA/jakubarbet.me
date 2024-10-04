import fs from 'node:fs/promises'
import {getPlaiceholder} from 'plaiceholder'
import {join, dirname} from 'path'
import {fileURLToPath} from 'url'

export const getPlaceholder = async (fsPath: string) => {
  const file = await fs.readFile(fsPath)
  const {css} = await getPlaiceholder(file)
  return css
}

export async function getAlbumImages(albumSlug: string) {
  const imagesGlob = import.meta.glob<{default: ImageMetadata}>('/src/content/albums/**/*.{jpeg,jpg,png,webp}', {
    eager: true,
  })

  const albumImages = Object.entries(imagesGlob).filter(([key]) => key.includes(albumSlug))

  const images = await Promise.all(
    albumImages.map(async ([key, imageModule]) => {
      // Convert the URL-style path to a file system path
      const __filename = fileURLToPath(import.meta.url)
      const __dirname = dirname(__filename)

      // Construct the path relative to the project root
      const projectRoot = join(__dirname, '../..')
      const fsPath = join(projectRoot, key)

      const image = imageModule.default
      const placeholder = await getPlaceholder(fsPath)

      return {...image, placeholder}
    }),
  )

  return images
}
