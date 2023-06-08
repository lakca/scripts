#!/usr/bin/env node

const { argv } = process
argv.shift()
argv.shift()

if (argv.includes('-h')) {
  console.log(
    '\n \033[32mnode douyin.js <action> [name]\033[0m\n',
    'transform <name> \033[2m获取douyin各api返回数据，将视频项目解析为统一的结构信息\033[0m\n',
    'curl             \033[2m下载统一结构信息的视频/图片\033[0m\n',
    '\n \033[2mpbpaste | node douyin.js transform userhome | node douyin.js curl\033[0m'
  )
  process.exit(0)
}

const json = require('./douyin.json')
const https = require('https')
const fs = require('fs')
const path = require('path')

let input = ''
process.stdin.setEncoding('utf-8').on('data', chunk => {
  input += chunk
}).on('end', () => {
  try {
    input = JSON.parse(input.trim())
  } catch (e) { console.error(e) }
  const action = argv.shift()
  switch (action) {
    case 'transform':
      console.log(JSON.stringify(getRecords(input, argv.shift()), null, 2))
      break
    case 'curl':
      const dest = argv.shift() || process.cwd()

      if (Array.isArray(input)) {
        (async function () {
          for (const item of input) {
            await curl(item, dest)
          }
        }()).catch(console.error)
      } else {
        curl(input, dest)
      }
      break
    case 'archive':
      fs.readdirSync(process.cwd()).some(file => {
        if (/\.(mp4|jpg)/.test(file)) {
          console.log(`\x1b[32m${file}\x1b[0m`)
          const [_, desc, awemeId, author, uid, secUid, ext] = file.match(/^([\s\S]*?)-([0-9]{10,})-(.+?)-([0-9]{10,})-(.+)(\.[^\.]+)$/)
          const folder = [author, uid, secUid].join('-')
          const basename = [desc, awemeId,].join('-') + ext
          console.log(`\x1b[34m${basename}\x1b[0m\x1b[31m in \x1b[0m \x1b[33m${folder}\x1b[0m`)
          !fs.existsSync(folder) && fs.mkdirSync(folder)
          fs.renameSync(file, path.join(folder, basename))
        }
      })
    case 'remove_secid':
      fs.readdirSync(process.cwd()).some(file => {
        if (/\.(mp4|jpg)/.test(file)) {
          console.log(`\x1b[32m${file}\x1b[0m`)
          const [_1, desc, awemeId, _2, secUid, ext] = file.match(/^([\s\S]*?)-([0-9]{10,})(-(.+))?(\.[^\.]+)$/)
          if (secUid) {
            const basename = [desc, awemeId].join('-') + ext
            console.log(`\x1b[34m${basename}\x1b[0m\x1b[31m`)
            fs.renameSync(file, basename)
          }
        }
      })
  }
})

function getDef(apiName) {
  return json[apiName] || Object.values(json).find((item) => {
    return item?.alias === apiName
  })
}

function getRecords(data, apiName) {
  const { multiple, rootKey, dataPath } = getDef(apiName).responseStruct
  data = propOf(data, rootKey)
  const keys = Object.keys(dataPath)
  if (multiple) {
    return data.map(item => {
      return Object.fromEntries(keys.map(k => {
        return [k, propOf(item, dataPath[k])]
      }))
    })
  } else {
    return Object.fromEntries(keys.map(k => {
      return [k, propOf(data, k)]
    }))
  }
}

function propOf(data, keyStr) {
  return keyStr.split('.').reduce((v, k) => {
    return v == null ? null : v[k] == null ? null : v[k]
  }, data)
}

function curl(item, dest) {
  const basename = [item.desc, item.awemeId].join('-')
  const folder = [item.author, item.uid, item.secUid].join('-')
  dest = path.join(dest, folder)
  if (item.image && item.images.length) {
    return Promise.allSettled(item.images.map((image, i) => {
      return download(image, dest, `${basename}(${i + 1}).jpg`)
    }))
  } else {
    const url = item.urls[0]
    if (!url.includes('.mp3')) return download(url, dest, basename + '.mp4')
  }
}

function download(url, dest, filename) {
  if (dest) {
    if (!path.isAbsolute(dest)) {
      filename = path.join(process.cwd(), dest, filename)
    } else {
      filename = path.join(dest, filename)
    }
  } else {
    filename = path.join(process.cwd(), filename)
  }
  return new Promise((resolve, reject) => {
    if (fs.existsSync(filename) && fs.statSync(filename).size > 144 * 1024) {
      resolve(null)
    } else {
      url = url.replace('http:', 'https:')
      console.log('\033[32mdownload\033[0m', filename)
      https.get(url, res => {
        res.pipe(fs.createWriteStream(filename)).on('close', resolve).on('error', reject)
      })
    }
  })
}
