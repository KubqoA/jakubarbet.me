const baseUrl = 'https://drive.jakubarbet.me' // Seafile base URL
const shareDir = process.env.SHARE_DIR // Public Photos share link ID
const photographyDir = './src/content/galleries'

type FileDirent = {
  file_path: string
  file_name: string
}

const fetchFileEntries = (path = '/') =>
  fetch(`${baseUrl}/api/v2.1/share-links/${shareDir}/dirents/?thumbnail_size=48&path=${encodeURIComponent(path)}`)
    .then((response) => response.json())
    .then((data) => data.dirent_list.filter(({is_dir}: any) => !is_dir) as FileDirent[])

const downloadFile = async (path: string) => {
  const response = await fetch(`${baseUrl}/d/${shareDir}/files/?p=${encodeURIComponent(path)}&raw=1`)
  const buffer = await response.arrayBuffer()
  await Bun.write(`${photographyDir}${path}`, buffer)
}

console.log('Fetching galleries...')
const galleryMetadataFiles = (await fetchFileEntries()).filter((file) => file.file_name.endsWith('.md'))
await Promise.all(
  galleryMetadataFiles.flatMap(async (metadata) => {
    const galleryPath = metadata.file_path.replace('.md', '')
    const photos = await fetchFileEntries(metadata.file_path.replace('.md', ''))
    console.log(`${galleryPath}: Fetching ${photos.length} photos...`)

    return [metadata, ...photos].map((entry) => downloadFile(entry.file_path))
  }),
)

export {}