export const getAlbumImages = (albumSlug: string) =>
  Promise.all(
    Object.entries(import.meta.glob<{default: ImageMetadata}>('/src/content/albums/**/*.{jpeg,jpg,png,webp}'))
      .filter(([key, _]) => key.includes(albumSlug))
      .map(async ([_, image]) => (await image()).default),
  )
