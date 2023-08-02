#!/usr/bin/env node

const json = require('./douyin.json')
const https = require('https')
const fs = require('fs')
const path = require('path')
const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
const BIT_RATE = {
  DEFAULT: 1,
  HIGH: 2,
  LOW: 3
}
const TRY_COUNT = 3
const DEFAULT_DEST_DIR = path.join(__dirname, 'douyin/learn')
/**
 * @typedef {Object} Item
 * @property {string} desc
 * @property {string} awemeId
 * @property {string} author
 * @property {string} uid
 * @property {string} secUid
 * @property {number} createTime
 * @property {string} [groupId]
 * @property {string[]} [urls]
 * @property {number[]} [bitRates]
 * @property {number[]} [bitSizes]
 * @property {string[][]} [bitRateUrls]
 * @property {string} [avatar]
 * @property {string} [music]
 * @property {string} [musicId]
 * @property {string} [musicAuthor]
 * @property {string} [musicSecUid]
 * @property {string} [musicAvatar]
 * @property {string} [musicUrl]
 * @property {string[]} [musicUrls]
 * @property {string[][]} [images]
 */

const { argv } = process
argv.shift()
argv.shift()

if (argv.includes('-h')) {
  console.log(`
    \x1b[2m将douyin各api返回数据中的视频或图片项目解析为统一的结构信息，<name>及解析配置见douyin.json\x1b[0m
    transform <name>

    \x1b[2m下载统一结构（经过transform）信息的视频/图片到<dest>目录（默认为工作目录）下的用户目录中\x1b[0m
    curl [<dest>] [-high|-low|-rename|-forcebitrate]

    \x1b[2m下载用户主页中的作品\x1b[0m
    posts -c <cookie> -u <user_sec_uid> [-o <output_dir=cwd()>]

    \x1b[2m例如：\x1b[0m

    \x1b[2m下载用户主页列表文件：\x1b[0m
    \x1b[2mnode douyin.js posts -u ... c ...\x1b[0m
    \x1b[2mpbpaste | node douyin.js posts -u ...\x1b[0m # 通过剪切板获取cookie

    \x1b[2m通过（存在剪切板）原始douyin数据，下载用户主页列表文件：\x1b[0m
    \x1b[2mpbpaste | node douyin.js transform userhome | node douyin.js curl\x1b[0m
  `)
  process.exit(0)
}

const cmd = argv.shift()
/** @type {any} */

if (process.stdin.isTTY) {
  main(cmd)
} else {
  let input = ''
  process.stdin.setEncoding('utf-8').on('data', chunk => {
    input += chunk
  }).on('end', () => main(cmd, input))
}

async function main(cmd, input) {
  switch (cmd) {
    case 'transform': {
      const name = argv.shift()
      const items = JSON.parse(input.trim())
      if (items && Array.isArray(items)) {
        console.log(JSON.stringify([].concat(...items.map(item => getRecords(item, name))), null, 2))
      } else {
        console.log(JSON.stringify(getRecords(items, name), null, 2))
      }
    } break
    case 'curl': {
      const opts = { bitRate: BIT_RATE.DEFAULT }
      let destDir = DEFAULT_DEST_DIR
      for (const arg of argv) {
        if (arg === '-low') opts.bitRate = BIT_RATE.LOW
        else if (arg === '-high') opts.bitRate = BIT_RATE.HIGH
        else if (arg === '-rename') opts.rename = true
        else if (arg === '-forcebitrate') opts.forceBitRate = true
        else destDir = arg
      }
      const items = JSON.parse(input.trim())
      for (const item of Array.isArray(items) ? items : [items]) {
        await curl(item, destDir, opts)
      }
    } break
    case 'archive':
      fs.readdirSync(DEFAULT_DEST_DIR).forEach(file => {
        if (/\.(mp4|jpg)/.test(file)) {
          console.log(`\x1b[32m${file}\x1b[0m`)
          const [_, desc, awemeId, author, uid, secUid, ext] = file.match(/^([\s\S]*?)-([0-9]{10,})-(.+?)-([0-9]{10,})-(.+)(\.[^\.]+)$/)
          const folder = [author, uid, secUid].join('-')
          const basename = [desc, awemeId].join('-') + ext
          console.log(`\x1b[34m${basename}\x1b[0m\x1b[31m in \x1b[0m \x1b[33m${folder}\x1b[0m`)
          !fs.existsSync(folder) && fs.mkdirSync(folder)
          fs.renameSync(file, path.join(folder, basename))
        }
      })
      break
    case 'posts': {
      /** @type {any} */
      const opts = { output: DEFAULT_DEST_DIR, cookie: input.trim(), pages: 1 }
      let arg = null
      while (argv.length) {
        arg = argv.shift()
        if (arg === '-c') opts.cookie = argv.shift()
        if (arg === '-u') opts.user_sec_uid = argv.shift()
        if (arg === '-o') opts.output = argv.shift()
        if (arg === '-p') opts.pages = argv.shift()
      }
      const data = await getUserHome(opts.cookie, opts.user_sec_uid, opts)
      data && fs.writeFileSync(path.join(opts.output, `douyin.user.post.${opts.user_sec_uid}.${Date.now()}.json`), JSON.stringify(data, null, 2))
    } break
    default:
  }
}

function getDef(apiName) {
  return json[apiName] || Object.values(json).find((item) => {
    return 'alias' in item && item.alias === apiName
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
  for (const key of (Array.isArray(keyStr) ? keyStr : [keyStr])) {
    const keys = key.split('.').reverse()
    let k = null
    let v = data
    while (keys.length) {
      if (v == null) {
        return v
      }
      k = keys.pop()
      if (k === '*') {
        return list(v, keys)
      } else {
        v = v[k]
      }
    }
    if (v !== undefined) {
      return v
    }
  }
  function list(value, keys) {
    const keyStr = [...keys].reverse().join('.')
    if (Array.isArray(value)) {
      return value.map(v => propOf(v, keyStr))
    } else if (typeof value === 'object') {
      return Object.values(value).map(v => propOf(v, keyStr))
    } else {
      return []
    }
  }
}

/**
 * @template A
 * @typedef {A extends readonly (infer T)[] ? T : never} ArrayElement
 */
function compact(keys, ...arr) {
  return arr[0].map((e, i) => {
    return keys.reduce((obj, k, j) => {
      obj[k] = arr[j][i]
      return obj
    }, {})
  })
}

/**
 * @param {Item} item
 * @param {string} destDir
 * @param {object} [options]
 * @param {BIT_RATE[keyof BIT_RATE]} [options.bitRate]
 * @param {boolean} [options.dryRun]
 * @param {boolean} [options.rename]
 * @param {boolean} [options.forceBitRate]
 * @returns
 */
async function curl(item, destDir, options = {}) {
  if (!item.awemeId) {
    return
  }
  const date = new Date(item.createTime * 1000)
  const dateStr = [
    date.getFullYear(),
    fixed(date.getMonth() + 1, 2),
    fixed(date.getDate(), 2),
    fixed(date.getHours(), 2),
    fixed(date.getMinutes(), 2)
  ].join('')
  // name: desc-date-awemeId
  const name = (i) => {
    const a = [dateStr, item.desc]
    i && a.push(i)
    a.push(item.awemeId)
    return a.join('-')
  }
  name.toString = () => name()
  // folder: author-uid-secUid
  const folder = [item.author, item.uid, item.secUid].join('-')
  destDir = path.join(destDir, folder)
  fs.mkdirSync(destDir, { recursive: true })
  if (item.images && item.images.length) {
    if (item.musicUrls) {
      const filename = `${name}.mp3`
      const realpath = path.join(destDir, filename)
      const url = getRandom(item.musicUrls)
      await download(ensureUrl(url), realpath) || console.log(red('下载失败'), dim(filename), dim(url))
    }
    return Promise.allSettled(item.images.map((urls, i) => {
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${i + 1}-${item.awemeId}.jpg`))
      const filename = `${name(i + 1)}.jpg`
      if (existed) {
        console.log('文件已存在:', dim(filename))
      } else {
        const realpath = path.join(destDir, filename)
        const url = urls.find(url => /\.jpe?g/.test(url)) || urls[0]
        return download(ensureUrl(url), realpath) || console.log(red('下载失败'), dim(filename), dim(url))
      }
    }))
  } else {
    let url = null
    let bitRateInfo = null
    if (options.bitRate) {
      if (item.bitRates && item.bitRates.length && item.bitRateUrls) {
        const bitRates = compact(['bitRate', 'urls', 'bitSize'], item.bitRates, item.bitRateUrls, item.bitSizes)
        if (options.bitRate === BIT_RATE.HIGH) {
          bitRates.sort((a, b) => b.bitRate - a.bitRate)
        } else if (options.bitRate === BIT_RATE.LOW) {
          bitRates.sort((a, b) => a.bitRate - b.bitRate)
        }
        bitRateInfo = bitRates[0]
        url = getRandom(bitRateInfo.urls)
        console.log('选择比特率:', dim(name), humanRead(bitRateInfo.bitSize))
      }
    } else {
      url = item.urls && getRandom(item.urls)
    }
    if (!url || url.includes('.mp3')) {
      return
    }
    const filename = `${name}.mp4`
    const realpath = path.join(destDir, filename)
    let n = 1
    while (true) {
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${item.awemeId}.mp4`))
      const stat = existed ? fs.statSync(path.join(destDir, existed)) : null
      if (n === 1 && stat && bitRateInfo && Math.abs(stat.size - bitRateInfo.bitSize) > 1024 ** 2 * 2) {
        console.log('文件已存在，但文件比特率不符合:', dim(`${filename}`), yellow(`${humanRead(stat.size)}, ${humanRead(bitRateInfo.bitSize)}`))
        if (!options.forceBitRate) break
      } else if (stat && stat.size > 1024 ** 2) {
        n === 1 ? console.log('文件已存在:', dim(filename)) : console.log(green('下载完成:'), dim(filename))
        if (options.rename && existed && existed !== filename) {
          console.log(yellow('重命名'), filename)
          fs.renameSync(path.join(destDir, existed), path.join(destDir, filename))
        }
        break
      }
      await sleep(Math.random() * 10000 + 3000)
      const downloading = realpath + '.download'
      const success = await download(ensureUrl(url), downloading)
      if (success && Math.abs(fs.statSync(downloading).size - bitRateInfo.bitSize) < 1024) {
        fs.renameSync(downloading, realpath)
      } else {
        fs.rmSync(downloading)
      }
      if (n < TRY_COUNT) {
        n++
      } else {
        console.log(red('下载失败'), dim(filename))
        break
      }
    }
    console.log()
  }
}

function download(url, filename) {
  return new Promise((resolve, reject) => {
    https.get(url, res => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        console.log(dim('重定向'), dim(res.headers.location))
        return download(res.headers.location, filename).then(resolve).catch(() => resolve(false))
      }
      const ws = fs.createWriteStream(filename)
      res.pipe(ws, { end: true }).on('error', () => resolve(false))
      ws.on('close', () => resolve(true))
    })
  })
}

/**
 * @template T
 * @param {T[]} arr
 * @returns {T}
 */
function getRandom(arr) {
  return arr[Math.floor(arr.length * Math.random())]
}

function humanRead(n, base = 1024) {
  if (!n) return n
  const units = ['', 'K', 'M', 'G', 'T']
  let unit = units.shift()
  while (n > base) {
    n = n / base
    unit = units.shift()
  }
  return n.toFixed(2) + unit
}

function fixed(n, l) {
  const m = `${n}`.length
  return m < l ? '0'.repeat(l - m) + n : n
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function dim(text) { return `\x1b[2m${text}\x1b[0m` }
function red(text) { return `\x1b[31m${text}\x1b[0m` }
function green(text) { return `\x1b[32m${text}\x1b[0m` }
function yellow(text) { return `\x1b[33m${text}\x1b[0m` }
function ensureUrl(url) {
  if (url.startsWith('//')) url = 'https:' + url
  url = url.replace('http:', 'https:')
  return url
}

function parseCookie(cookie) {
  return Object.fromEntries(new URLSearchParams(cookie.replace(/;\s*/g, '&').trim()).entries())
}
/**
 * @param {string} dataStr
 * @param {string} [cookie]
 * @param {string} [referer]
 * @returns
 */
function getXBogus(dataStr, cookie, referer) {
  const fnname = '_0x5a8f25'
  // eslint-disable-next-line prefer-const
  let xBogus = ''
  const code = `
  window = global
  window.Request = () => {}
  window.Headers = () => {}
  window.document = {
      cookie: '${cookie}',
      referrer: '${referer}',
      addEventListener: () => {},
  }
  window.navigator = {
      userAgent: '${USER_AGENT}',
  }
  ${fs.readFileSync(path.join(__dirname, './douyin-webmssdk.js')).toString().replace(new RegExp(`function ${fnname}`), e => `;window.${fnname} = ${fnname}; ${e}`)}
  xBogus = window.${fnname}('${dataStr}')
  `
  // eslint-disable-next-line no-eval
  eval(code)
  console.warn(xBogus)
  return xBogus
}

async function getUserHome(cookie, user_sec_uid, opts) {
  opts = { pages: 1, ...opts }
  let max_cursor = 0
  let pages = opts.pages
  const count = 18
  const resp = []
  try {
    while (pages-- > 0) {
      const data = await getUserHomePosts(cookie, user_sec_uid, count, max_cursor)
      resp.push(data)
      if (!data.has_more) {
        break
      } else {
        max_cursor = data.max_cursor
      }
    }
    return resp
  } catch (e) {
    console.error(e)
    return resp
  }
}

/**
 * @param {string} cookie
 * @param {string} user_sec_uid
 * @param {number} max_cursor
 * @param {number} count
 */
function getUserHomePosts(cookie, user_sec_uid, count = 18, max_cursor = 0) {
  const cookieObj = parseCookie(cookie)
  const ms_token = cookieObj.msToken
  const referer = `https://www.douyin.com/user/${user_sec_uid}`
  const query = new URLSearchParams({
    device_platform: 'webapp',
    aid: '6383',
    channel: 'channel_pc_web',
    sec_user_id: `${user_sec_uid}`, // 用户ID
    max_cursor: `${max_cursor}`, // 列表项目的最早时间
    locate_query: 'false',
    show_live_replay_strategy: '1',
    count: `${count}`, // 列表项目数量
    publish_video_strategy_type: '2',
    // 客户端信息
    pc_client_type: '1',
    version_code: '170400',
    version_name: '17.4.0',
    cookie_enabled: 'true',
    screen_width: '912',
    screen_height: '1368',
    browser_language: 'zh-CN',
    browser_platform: 'MacIntel',
    browser_name: 'Chrome',
    browser_version: '98.0.4758.82',
    browser_online: 'true',
    engine_name: 'Blink',
    engine_version: '98.0.4758.82',
    os_name: 'Windows',
    os_version: '10',
    cpu_core_num: '8',
    device_memory: '8',
    platform: 'PC',
    downlink: '1.5',
    effective_type: '3g',
    round_trip_time: '350',
    webid: '7259988089359468032', // 客户端ID（RENDER_DATA.app.odin.user_unique_id）
    msToken: `${ms_token}` // cookie信息
  })
  // 请求ID, X-Bogus
  query.set('X-Bogus', getXBogus(query.toString(), cookie, referer))
  console.warn(query.toString())
  return fetch('https://www.douyin.com/aweme/v1/web/aweme/post?' + query, {
    headers: {
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zh;q=0.9',
      'cache-control': 'no-cache',
      pragma: 'no-cache',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      cookie,
      Referer: referer,
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'User-Agent': USER_AGENT
    },
    body: null,
    method: 'GET'
  }).then(res => res.json())
}

function getUserProfile(user_sec_id) {

}
