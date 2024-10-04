export async function getAlbumImages(albumSlug: string) {
  let images = import.meta.glob<{default: ImageMetadata}>('/src/content/albums/**/*.{jpeg,jpg}')
  images = Object.fromEntries(Object.entries(images).filter(([key]) => key.includes(albumSlug)))

  // Images are promises, so we need to resolve the glob promises
  return await Promise.all(Object.values(images).map((image) => image().then((mod) => mod.default)))
}
