#!/usr/bin/env node
const fs = require('fs')
const path = require('path')

const folders = [
  process.env.HOME + '/Library/Containers/com.netease.163music/Data/Library/Caches/online_play_cache/',
  process.env.HOME + '/Library/Containers/com.netease.163music/Data/Caches/online_play_cache/',
]
const metadata = (id) => `https://music.163.com/api/song/detail/?ids=[${id}]`
const lyric = (id) => `http://music.163.com/api/song/lyric?id=${id}&lv=1&tv=-1`

function getSourceFilename(file) {
  if (!path.isAbsolute(file)) {
    for (const folder of folders) {
      if (fs.existsSync(path.join(folder, file))) {
        file = path.join(folder, file)
      }
    }
  }
  return file
}

function getTargetFileName(target, file) {
  target = target || ''
  if (!path.isAbsolute(target)) {
    target = path.join(process.cwd(), target)
  }
  if (fs.existsSync(target) && fs.statSync(target).isDirectory()) {
    target = path.join(target, path.basename(file))
  }
  if (!target.endsWith('.mp3')) {
    target += '.mp3'
  }
  return target
}

function convert(file, target) {
  file = getSourceFilename(file)
  target = getTargetFileName(target, file)

  console.log(file, target)

  const w = fs.createWriteStream(target, { autoClose: true });
  fs.createReadStream(file)
    .on('data', chunk => {
      for (const byte of chunk) {
        w.write(Buffer.from([byte ^ 0xa3]))
      }
    })
}

// one by one
async function migrate(target) {
  for (const folder of folders) {
    for (const name of fs.readdirSync(folder).filter(e => e.endsWith('.uc!'))) {
      const filename = path.join(folder, name)
      await saveCache(filename, target)
    }
  }
}

function unit(value, type) {
  switch(type) {
    case 'bitrate':
      return value / 1000 + 'kb/s'
    case 'size':
      return (value / 1024 / 1024).toFixed(2) + 'MB'
    default:
      return value
  }
}

async function getMetadata(id) {
  const data = await fetch(metadata(id)).then(res => res.json())
  const { songs } = data
  return songs.map(e => {
    return {
      id: e.id,
      name: e.name,
      artists: e.artists.map(e => ({
        id: e.id,
        name: e.name,
        picUrl: e.picUrl,
      })),
      album: {
        id: e.album.id,
        name: e.album.name,
        picUrl: e.album.picUrl,
      },
      musics: [
        { id: e.bMusic.id, bitrate: unit(e.bMusic.bitrate, 'bitrate'), size: unit(e.bMusic.size, 'size'), },
        { id: e.lMusic.id, bitrate: unit(e.lMusic.bitrate, 'bitrate'), size: unit(e.lMusic.size, 'size'), },
        { id: e.mMusic.id, bitrate: unit(e.mMusic.bitrate, 'bitrate'), size: unit(e.mMusic.size, 'size'), },
        { id: e.hMusic.id, bitrate: unit(e.hMusic.bitrate, 'bitrate'), size: unit(e.hMusic.size, 'size'), },
      ],
    }
  })
}

async function getLyric(id) {
  const data = await fetch(lyric(id)).then(res => res.json())
  const { lrc, tlyric } = data
  return {
    lyric: lrc.lyric,
    translation: tlyric.lyric,
  }
}

async function saveCache(file, target) {
  file = getSourceFilename(file)
  target = getTargetFileName(target, file)
  const id = path.basename(file).match(/\d+/)?.[0]
  const meta = (await getMetadata(id))[0]
  target = path.join(path.dirname(target), `${meta.name}-${meta.artists.map(e => e.name).join('&')}`)
  return convert(file, target)
}

const args = process.argv
args.shift()
args.shift()

if (args.includes('-h')) {
  console.log(`
  \x1b[32mmeta\x1b[0m <music_id> \x1b[2m获取歌曲信息\x1b[0m
  \x1b[32mlyric\x1b[0m <music_id> \x1b[2m获取歌词\x1b[0m
  \x1b[32msave\x1b[0m <cache_file_name> [target_dir] \x1b[2m缓存移储\x1b[0m
  \x1b[32mmigrate\x1b[0m \x1b[2m迁移所有缓存\x1b[0m
  `)
} else if (args.includes('meta')) {
  const id = args.find(e => /^\d+$/.test(e))
  getMetadata(id).then(e => console.log(JSON.stringify(e, null, 2)))
} else if (args.includes('lyric')) {
  const id = args.find(e => /^\d+$/.test(e))
  getLyric(id).then(e => console.log(JSON.stringify(e, null, 2)))
} else if (args.includes('save')) {
  const file = args.find(e => e.endsWith('.uc!'))
  const target = args.find(e => e !== file && e !== 'cache')
  saveCache(file, target)
} else if (args.includes('migrate')) {
  const target = args.find(e => e !== 'migrate')
  migrate(target)
}

