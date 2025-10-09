export const getGalleryImages = (slug: string) =>
  Promise.all(
    Object.entries(import.meta.glob<{default: ImageMetadata}>('/src/content/galleries/**/*.{jpeg,jpg,png,webp}'))
      .filter(([path, _]) => path.includes(`galleries/${slug}`))
      .map(async ([_, image]) => (await image()).default),
  )
