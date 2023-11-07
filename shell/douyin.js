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
const MIN_SIZE = 1
const SIZE_GAP = 0.1
const DEFAULT_DEST_DIR = path.join(__dirname, 'douyin')

const readline = require('readline')
const assert = require('assert')

const bool_mapper = { Y: true, y: true, N: false, n: false }
const is_number = s => s !== '' && !isNaN(Number(s))
const is_not_null = s => !!s

function debug(...args) {
  process.env.DEBUG && console.warn(...args)
}
/**
 *
 * @param {string} query
 * @param {object} [opts]
 * @param {string[]} [opts.range]
 * @param {object} [opts.mapper]
 * @param {(answer: string) => boolean} [opts.checker]
 * @param {boolean} [opts.optional]
 * @param {boolean} [opts.raw] - 是否对原始输入进行处理：trim()
 * @param {any} [opts.defaultValue] - 默认值
 */
function ask(query, opts) {
  !arguments.callee.initialized && console.log(dim([
    '如何回答：',
    '  - 如果回答是，则输入Y或y',
    '  - 如果回答否，则输入N或n'
  ].join('\n')))
  arguments.callee.initialized = true
  const { range, mapper, checker, optional, raw, defaultValue } = opts || {}
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
    rl.question(`\x1b[33m${query}${defaultValue == null ? '' : dim('，默认值为' + defaultValue)}：\x1b[31m`, answer => {
      if (!raw) answer = answer.trim()
      process.stdout.write('\x1b[0m')
      if (((defaultValue !== undefined || optional) && answer === '') || !(range || checker) || (range && range.includes(answer)) || (checker && checker(answer))) {
        rl.close()
        resolve((mapper && answer in mapper) ? mapper[answer] : (defaultValue !== undefined && answer === '' ? defaultValue : answer))
      } else {
        rl.close()
        ask(query, opts).then(resolve)
      }
    })
  })
}
function caching(destDir, data) {
  const cacheFile = path.join(destDir, '.douyin.js.cache')
  return arguments.length > 1 ? syncJSONFile(cacheFile, data) : syncJSONFile(cacheFile)
}
function syncJSONFile(filename, data) {
  if (arguments.length > 1) {
    fs.writeFileSync(filename, typeof data === 'string' ? data : JSON.stringify(data))
  } else {
    return fs.existsSync(filename) && JSON.parse(fs.readFileSync(filename).toString().trim())
  }
}
function readFileSync(filename) {
  return fs.existsSync(filename) ? fs.readFileSync(filename).toString() : ''
}

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
    \x1b[32m-c\x1b[0m
        <configfile> \x1b[2m- 通过配置文件自动下载\x1b[0m

    \x1b[32mtransform\x1b[0m
        <name> \x1b[2m- 见douyin.json key 或 alias\x1b[0m

    \x1b[2m下载统一结构（经过transform）信息的视频/图片到<dest>目录（默认为工作目录）下的用户目录中\x1b[0m
    \x1b[32mcurl\x1b[0m
        [<dest>]        \x1b[2m- 默认为当前工作目录\x1b[0m
        [-high]         \x1b[2m- 下载高比特率\x1b[0m
        [-low]          \x1b[2m- 下载低比特略\x1b[0m
        [-rename]       \x1b[2m- 对已存在的文件（文件名以{item.awemeId}.mp4判断）重命名（以符合最新命名规则）\x1b[0m
        [-forcebitrate] \x1b[2m- 文件已存在，但比特率不符合时也要下载（覆盖）\x1b[0m
        [-minsize]      \x1b[2m- 文件小于多少MB（默认${MIN_SIZE}）就判定为无效文件 \x1b[0m
        [-sizegap]      \x1b[2m- 文件大小差小于多少MB（默认${SIZE_GAP}）就判定为同一文件 \x1b[0m

    \x1b[2m下载用户主页中的作品
    web_id与cookie紧密相关，获取方式: SSR_RENDER_DATA.app.odin.user_unique_id\x1b[0m
    \x1b[32mposts\x1b[0m
        -c,-cookie       <cookie>            \x1b[2m- 网页cookie\x1b[0m
        -w,-user_sec_uid <web_id>            \x1b[2m- 客户端ID，需要同cookie保持来源一致（SSR_RENDER_DATA.app.odin.user_unique_id）\x1b[0m
        -u,-web_id       <user_sec_uid>      \x1b[2m- 用户sec_id\x1b[0m
        [-o,-output       <output_dir=cwd()>] \x1b[2m- 保存目录\x1b[0m
        [-d,-max_page        <max_cursor>]       \x1b[2m- 最小时间戳\x1b[0m
        [-D,-max_cursor   <max_time>]         \x1b[2m- 最小时间，会传入Date进行构造\x1b[0m
        [-p,-max_time     <max_max_page>]        \x1b[2m- 最多页面（以18条每页计）\x1b[0m

    \x1b[2m下载首个评论中的连接@用户\x1b[0m
    \x1b[32mcomment\x1b[0m

    \x1b[2m例如：

    # 获取用户主页作品列表，通过剪切板获取cookie:
    > pbpaste | douyin.js posts -u ... -w 7268870306478261795 -D 2023-08-18

    # 下载用户主页列表文件，通过（存在剪切板）原始douyin数据：
    > pbpaste | douyin.js transform userhome | douyin.js curl -low -forcebitrate\x1b[0m
  `)
  process.exit(0)
}

const cmd = argv.shift()
/** @type {any} */

if (process.stdin.isTTY) {
  main(cmd).then(() => {
    console.warn(red('完成!'))
  })
} else {
  let input = ''
  process.stdin.setEncoding('utf-8').on('data', chunk => {
    input += chunk
  }).on('end', () => {
    main(cmd, input).then(() => {
      console.warn(red('完成!'))
    })
  })
}

async function main(cmd, input = '') {
  switch (cmd) {
    case '-c': {
      const arg = argv.shift()
      arg && downloadFromConfig(arg)
    }
      break
    case 'transform': {
      const name = argv.shift()
      if (name) console.log(JSON.stringify(transform(name, input), null, 2))
      else {
        console.error('未提供API名称')
        process.exit(1)
      }
    } break
    case 'curl': {
      const opts = { bitRate: BIT_RATE.DEFAULT, minSize: MIN_SIZE, sizeGap: SIZE_GAP, destDir: DEFAULT_DEST_DIR }
      for (const arg of argv) {
        if (arg === '-low') opts.bitRate = BIT_RATE.LOW
        else if (arg === '-high') opts.bitRate = BIT_RATE.HIGH
        else if (arg === '-rename') opts.rename = true
        else if (arg === '-forcebitrate') opts.forceBitRate = true
        else if (arg.startsWith('-minsize')) opts.minSize = +arg.slice('-minsize'.length)
        else if (arg.startsWith('-sizegap')) opts.sizeGap = +arg.slice('-sizegap'.length)
        else opts.destDir = arg
      }
      await downloadUserHomePosts(input, opts)
    } break
    case 'posts': {
      /** @type {any} */
      const opts = {
        output: DEFAULT_DEST_DIR,
        cookie: input.trim(),
        max_page: 1,
        web_id: '7268870306478261795',
        max_cursor: 0,
        max_number: 0
      }
      let arg = null
      while (argv.length) {
        arg = argv.shift()
        if (arg === '-c' || arg === '-cookie') opts.cookie = argv.shift()
        if (arg === '-u' || arg === '-user_sec_uid') opts.user_sec_uid = argv.shift()
        if (arg === '-w' || arg === '-web_id') opts.web_id = argv.shift()
        if (arg === '-o' || arg === '-output') opts.output = argv.shift()
        if (arg === '-p' || arg === '-max_page') opts.max_page = argv.shift()
        if (arg === '-d' || arg === '-max_cursor') opts.max_cursor = argv.shift()
        if (arg === '-D' || arg === '-max_time') opts.max_time = argv.shift()
      }
      await downloadUserHomeList(opts)
    } break
    case 'comment':
      await stepFirstComment()
      break
    default:
      await stepByStep()
  }
}

async function stepByStep() {
  const range = Object.keys(bool_mapper)

  const destDir = await ask(`请输入下载的文件存放目录`, { defaultValue: DEFAULT_DEST_DIR })
  const cache = caching(destDir)
  let listFile = await ask(`可选，请输入posts文件路径`)
  if (listFile && !path.isAbsolute(listFile)) {
    listFile = path.join(destDir, listFile)
  }
  /** @type {DownloadUserHomeListOpts & { limit: any }} */
  const opts1 = {
    cookie: readFileSync(path.join(destDir, 'cookie.jar')).trim(),
    limit: '2022-01-01',
    ...cache.opts1
  }
  if (!listFile) {
    opts1.output = destDir
    opts1.cookie = await ask(`网页cookie`, { defaultValue: opts1.cookie })
    opts1.web_id = await ask(`客户端ID，需要同cookie保持来源一致（${dim('从控制台获取 SSR_RENDER_DATA.app.odin.user_unique_id')} ）`, { checker: is_number, defaultValue: opts1.web_id })
    opts1.user_sec_uid = await ask(`用户sec_id（如 ${dim('MS4wLjABAAAAKxPOisbl6kuP6LlgTLeUcbhXRNR291byPMYPjxwdKdRQmZXFlIorOmeFnZyZ39Ar')} ）`, { checker: is_not_null, defaultValue: opts1.user_sec_uid })
    opts1.user_sec_uid = opts1.user_sec_uid.split('/').pop() || ''
    opts1.limit = await ask(`请输入${yellow('最小时间戳')}、或${yellow('最早时间')}（${dim('可传入Date进行构造，如2020-01-01')})、或${yellow('最大数量')}`, { checker: is_not_null, defaultValue: opts1.limit })
    if (is_number(opts1.limit)) {
      if (opts1.limit < 10 ** 4) {
        opts1.max_number = Number(opts1.limit)
        delete opts1.max_cursor
        delete opts1.max_page
        delete opts1.max_time
      } else {
        delete opts1.max_number
        opts1.max_cursor = Number(opts1.limit)
        delete opts1.max_page
        delete opts1.max_time
      }
    } else {
      delete opts1.max_number
      delete opts1.max_cursor
      delete opts1.max_page
      opts1.max_time = opts1.limit
    }
  }

  /** @type {CurlOptions} */
  const opts2 = {
    bitRate: BIT_RATE.DEFAULT,
    rename: false,
    forceBitRate: false,
    sizeGap: SIZE_GAP,
    minSize: MIN_SIZE,
    ...cache.opts2
  }
  opts2.bitRate = await ask('请问下载高码率（2）还是低码率（3），抑或是默认码率（1）？', { range: ['1', '2', '3'], mapper: { 1: 1, 2: 2, 3: 3 }, defaultValue: opts2.bitRate })
  opts2.rename = await ask('如果命名规则有变化，是否根据最新规则重命名已存在的文件', { range, mapper: bool_mapper, defaultValue: opts2.rename })
  opts2.forceBitRate = await ask('如果码率不一致，是否覆盖已存在的文件', { range, mapper: bool_mapper, defaultValue: opts2.forceBitRate })
  opts2.sizeGap = Number(await ask(`如果要覆盖已存在的文件，新旧文件至少相差多少MB才执行`, { checker: is_number, defaultValue: opts2.sizeGap }))
  opts2.minSize = Number(await ask(`多少MB的文件才是有效的`, { checker: is_number, defaultValue: opts2.minSize }))
  opts2.destDir = destDir

  if (!listFile) console.log(opts1)
  console.log(opts2)
  if (await ask('是否继续', { range, mapper: bool_mapper })) {
    caching(destDir, Object.assign(cache, { opts1, opts2 }))
    const items = transform('userhome', listFile ? require(listFile) : await downloadUserHomeList(opts1))
    if (await ask('是否下载具体内容', { range, mapper: bool_mapper })) {
      for (const item of items) {
        await curl(item, opts2)
      }
    }
  }
  process.exit(0)
}
async function stepFirstComment() {
  const destDir = await ask(`请输入下载的文件存放目录`, { defaultValue: DEFAULT_DEST_DIR })
  const cache = caching(destDir)
  /** @type {DownloadFirstCommentLinkFromJSON} */
  const firstCommentOpts = {
    skip: 0,
    max_number: 0,
    ...cache.firstCommentOpts
  }
  firstCommentOpts.cookie = await ask(`网页cookie`, { defaultValue: firstCommentOpts.cookie || propOf(cache, 'opts1.cookie') || readFileSync(path.join(destDir, 'cookie.jar')).trim() })
  firstCommentOpts.web_id = await ask(`客户端ID，需要同cookie保持来源一致（${dim('从控制台获取 SSR_RENDER_DATA.app.odin.user_unique_id')} ）`, { checker: is_number, defaultValue: firstCommentOpts.web_id || propOf(cache, 'opts1.web_id') })
  firstCommentOpts.jsonfile = await ask(`json文件`, { defaultValue: firstCommentOpts.jsonfile, checker: is_not_null })
  firstCommentOpts.skip = await ask(`跳过数量`, { defaultValue: firstCommentOpts.skip, checker: is_number })
  firstCommentOpts.max_number = await ask(`最大数量`, { defaultValue: firstCommentOpts.max_number, checker: is_number })
  if (firstCommentOpts.jsonfile && !path.isAbsolute(firstCommentOpts.jsonfile)) {
    firstCommentOpts.jsonfile = path.join(destDir, firstCommentOpts.jsonfile)
  }
  caching(destDir, Object.assign(cache, { firstCommentOpts }))
  await downloadFirstCommentLinkFromJSON(firstCommentOpts)
}
/**
 * @typedef DownloadFirstCommentLinkFromJSON
 * @property {string} jsonfile
 * @property {string} cookie
 * @property {string} web_id
 * @property {number} [skip]
 * @property {number} [max_number]
 * @param {DownloadFirstCommentLinkFromJSON} opts
 */
async function downloadFirstCommentLinkFromJSON(opts) {
  let number = 0
  let skip = opts.skip || 0
  const max_number = opts.max_number || 0
  const sec_uids = []
  const file = 'sec_uid.txt'
  try {
    for (const item of require(opts.jsonfile)) {
      for (const e of item.aweme_list) {
        if (skip > 0) {
          skip--
          continue
        }
        if (max_number && max_number <= number) {
          break
        }
        number++
        const aweme_id = e.aweme_id
        console.warn(dim(`第${number}个 ${aweme_id}`))
        const data = await getPostComments({ aweme_id, cookie: opts.cookie, web_id: opts.web_id })
        const comment = data.comments[0]
        for (const extra of comment.text_extra) {
          sec_uids.push(extra.sec_uid)
          fs.appendFileSync(file, (extra.sec_uid || '') + '\n')
        }
        await sleep(5000 * Math.random())
      }
    }
    return sec_uids
  } catch (e) {
    console.error(e)
    return sec_uids
  } finally {
    console.log(sec_uids)
  }
}
/**
 * @typedef {GetUserHomeOpts & { output: string }} DownloadUserHomeListOpts
 * @param {DownloadUserHomeListOpts} opts
 * @return downloaded data.
 */
async function downloadUserHomeList(opts) {
  if (fs.existsSync(opts.cookie)) {
    opts.cookie = fs.readFileSync(opts.cookie).toString().trim()
  }
  const data = await getUserHome(opts)
  const { author } = data[0].aweme_list[0]
  const { nickname, uid } = author
  const file = `${nickname}.${uid}.${new Date().toISOString().slice(0, 10)}.json`
  if (data) {
    fs.writeFileSync(path.join(opts.output, file), JSON.stringify(data, null, 2))
    console.warn(green('Saved:'), file)
  }
  return data
}
/**
 * @param {string|array} list
 * @param {object} opts
 * @param {string} opts.destDir
 * @param {BIT_RATE[keyof BIT_RATE]} [opts.bitRate]
 * @param {boolean} [opts.rename]
 * @param {boolean} [opts.forceBitRate]
 * @param {Number} opts.minSize
 * @param {Number} opts.sizeGap
 * @returns
 */
async function downloadUserHomePosts(list, opts) {
  const items = typeof list === 'string' ? JSON.parse(list.trim()) : list
  for (const item of (Array.isArray(items) ? items : [items]).reverse()) {
    debug(dim(new Date()))
    const r = await curl(item, opts)
    if (r !== RESULT.OK_RENAME_VIDEO) {
      await sleep(Math.random() * 10000 + 1000)
    }
  }
}
/**
 * @param {string} configfile
 */
async function downloadFromConfig(configfile) {
  const text = fs.readFileSync(configfile).toString()
  const users = []
  const opts = {
    cookie: '',
    output: '',
    web_id: '',
    user_sec_uid: '',
    max_page: 100,
    max_cursor: 0,
    max_time: '2022-01-01',

    bitRate: BIT_RATE.DEFAULT,
    rename: false,
    forceBitRate: false,
    sizeGap: SIZE_GAP,
    minSize: MIN_SIZE,
    destDir: ''
  }
  for (const line of text.split(/\r?\n/)) {
    if (!line.trim() || line.trim().startsWith('#')) continue
    const idx = line.indexOf(':')
    const key = (idx > -1 ? line.slice(0, idx) : line).trim()
    /** @type {any} */
    let val = (idx > -1 ? line.slice(idx + 1) : '').trim()
    if (val === 'true') val = true
    if (val === 'false') val = false
    if (/^[0-9][0-9]*\.?[0-9]*$/.test(val)) val = Number(val)
    if (/^('|").*\1$/.test(val)) val = val.slice(1, -1)
    if (key === 'cookie') {
      opts.cookie = fs.existsSync(val) ? fs.readFileSync(val).toString().trim() : ''
    } else {
      opts[key] = val
    }
    if (key === 'user_sec_uid') {
      _checkOpts(opts, opts)
      users.push(JSON.parse(JSON.stringify({ opts })))
    }
  }
  for (const user of users) {
    debug(green(`下载${user.opts.user_sec_uid}`))
    const items = transform('userhome', await downloadUserHomeList(user.opts))
    for (const item of items) {
      await curl(item, user.opts)
      sleep(Math.random() * 2000)
    }
  }
}
/**
 * @param {DownloadUserHomeListOpts} opts1
 * @param {CurlOptions} opts2
 */
function _checkOpts(opts1, opts2) {
  assert(opts1.cookie, '没有提供cookie')
  assert(opts1.user_sec_uid, '没有提供用户user_sec_uid')
  assert(opts1.web_id, '没有提供web_id')
  assert(opts1.output, '没有提供json文件下载目录output')
  assert(opts1.max_page || opts1.max_cursor || opts1.max_time, '没有提供max_page，或max_cursor，或max_time')
  assert(opts2.destDir, '没有提供多媒体下载目录destDir')
  assert(opts2.bitRate, '没有提供bitRate')
  assert(typeof opts2.rename === 'boolean', '没有提供rename')
  assert(typeof opts2.forceBitRate === 'boolean', '没有提供forceBitRate')
  assert(opts2.minSize, '没有提供minSize')
  assert(opts2.sizeGap, '没有提供sizeGap')
}
/**
 * @param {string} name - API名称（或alias），参照douyin.json
 * @param {string|array} input - API原始数据
 */
function transform(name, input) {
  const items = typeof input === 'string' ? JSON.parse(input.trim()) : input
  if (items && Array.isArray(items)) {
    const data = [].concat(...items.map(item => getRecords(item, name)))
    return data
  } else {
    const data = getRecords(items, name)
    return data
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

const RESULT = {
  OK_VIDEO: 0,
  OK_RENAME_VIDEO: 1,
  NO_AWEME_ID: 2,
  DOWNLOAD_FAIL_VIDEO: 3,
  SKIP_AUDIO: 4,
  IMAGE_EXIST: 5,
  DOWNLOAD_FAIL_IMAGE: 6,
  OK_IMAGE: 7,
  VIDEO_EXIST: 8
}

/**
 * @typedef CurlOptions
 * @property {string} destDir
 * @property {BIT_RATE[keyof BIT_RATE]} [bitRate]
 * @property {boolean} [rename]
 * @property {boolean} [forceBitRate]
 * @property {Number} minSize - MB
 * @property {Number} sizeGap - MB
 *
 * @param {Item} item
 * @param {CurlOptions} options
 * @returns
 */
async function curl(item, options) {
  let destDir = options.destDir
  if (!item.awemeId) {
    return RESULT.NO_AWEME_ID
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
  !fs.existsSync(destDir) && fs.mkdirSync(destDir, { recursive: true })
  if (item.images && item.images.length) {
    if (item.musicUrls && item.musicUrls.length) {
      const filename = `${name}.mp3`
      const realpath = path.join(destDir, filename)
      const url = getRandom(item.musicUrls)
      await download(ensureUrl(url), realpath) || console.error(red('下载失败:'), dim(filename), dim(url))
    }
    return Promise.allSettled(item.images.map((urls, i) => {
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${i + 1}-${item.awemeId}.jpg`))
      const filename = `${name(i + 1)}.jpg`
      if (existed) {
        console.error(red('文件已存在:'), dim(filename))
        return RESULT.IMAGE_EXIST
      } else {
        const realpath = path.join(destDir, filename)
        const url = urls.find(url => /\.jpe?g/.test(url)) || urls[0]
        return download(ensureUrl(url), realpath).then((...args) => {
          return RESULT.OK_IMAGE
        }).catch(e => {
          console.error(red('下载失败:'), dim(filename), dim(url))
          return RESULT.DOWNLOAD_FAIL_IMAGE
        })
      }
    }))
  } else {
    let url = null
    let bitRateInfo = null
    let bitRates
    if (options.bitRate) {
      if (item.bitRates && item.bitRates.length && item.bitRateUrls) {
        bitRates = compact(['bitRate', 'urls', 'bitSize'], item.bitRates, item.bitRateUrls, item.bitSizes)
        if (options.bitRate === BIT_RATE.HIGH) {
          bitRates.sort((a, b) => b.bitRate - a.bitRate)
        } else if (options.bitRate === BIT_RATE.LOW) {
          bitRates.sort((a, b) => a.bitRate - b.bitRate)
        }
        bitRateInfo = bitRates[0]
        url = getRandom(bitRateInfo.urls)
        debug(dim(green('选择比特率:')), dim(name), bitRates.map(e => humanRead(e.bitSize)).join(', '), green(humanRead(bitRateInfo.bitSize)))
      }
    } else {
      url = item.urls && getRandom(item.urls)
    }
    if (!url || url.includes('.mp3')) {
      return RESULT.SKIP_AUDIO
    }
    const filename = `${name}.mp4`
    const realpath = path.join(destDir, filename)
    let n = 1
    while (true) {
      // 文件存在的判定标准是，awemeId 相同，即最后一个字段相同
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${item.awemeId}.mp4`))
      const stat = existed ? fs.statSync(path.join(destDir, existed)) : null
      const gapped = stat && bitRateInfo && (Math.abs(stat.size - bitRateInfo.bitSize) > 1024 ** 2 * options.sizeGap)
      const bigger = stat && (options.bitRate === BIT_RATE.HIGH && stat.size > bitRateInfo.bitSize)
      const smaller = stat && (options.bitRate === BIT_RATE.LOW && stat.size < bitRateInfo.bitSize)
      const anyway = options.bitRate === BIT_RATE.DEFAULT
      if (n === 1 && (!anyway && !bigger && !smaller) && gapped) {
        console.warn(yellow('文件已存在，但文件比特率不符合:'), dim(`${filename}`), yellow(`当前文件${humanRead(stat.size)}, 应该${humanRead(bitRateInfo.bitSize)}`))
        if (!options.forceBitRate) {
          return RESULT.VIDEO_EXIST
        }
      } else if (stat && stat.size > 1024 ** 2 * options.minSize) {
        n === 1 ? console.warn(yellow('文件已存在:'), dim(filename)) : console.warn(green('下载完成:'), dim(filename))
        if (options.rename && existed && existed !== filename) {
          console.warn(yellow('重命名:'), filename)
          fs.renameSync(path.join(destDir, existed), path.join(destDir, filename))
        }
        return RESULT.OK_RENAME_VIDEO
      }
      await sleep(Math.random() * 3000)
      const downloading = realpath + '.download'
      const success = await download(ensureUrl(url), downloading)
      if (success && Math.abs(fs.statSync(downloading).size - bitRateInfo.bitSize) < 1024) {
        fs.renameSync(downloading, realpath)
      } else {
        fs.rmSync(downloading, { force: true })
      }
      if (n < TRY_COUNT) {
        n++
      } else {
        console.warn(red('下载失败:'), dim(filename))
        return RESULT.DOWNLOAD_FAIL_VIDEO
      }
    }
  }
}

function download(url, filename) {
  return new Promise((resolve, reject) => {
    https.get(url, res => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        debug(dim(green('重定向:')), dim(res.headers.location))
        return download(res.headers.location, filename).then(resolve).catch(() => resolve(false))
      }
      const ws = fs.createWriteStream(filename)
      res.pipe(ws, { end: true }).on('error', () => resolve(false))
      res.on('close', () => {
        if (!ws.closed) {
          ws.close(() => {
            resolve(true)
          })
        }
      })
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

function dim(text) { return `\x1b[2m${text}\x1b[22m` }
function red(text) { return `\x1b[31m${text}\x1b[39m` }
function green(text) { return `\x1b[32m${text}\x1b[39m` }
function yellow(text) { return `\x1b[33m${text}\x1b[39m` }
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
  debug(green('xBogus:'), dim(xBogus))
  return xBogus
}

/**
 * @typedef GetUserHomeOpts
 * @property {string} cookie
 * @property {string} user_sec_uid
 * @property {string} web_id - 客户端ID（SSR_RENDER_DATA.app.odin.user_unique_id）
 * @property {number} [max_page]
 * @property {number} [max_cursor]
 * @property {string} [max_time] - date string, param of `Date`
 * @property {number} [max_number]
 * @property {string} [name]
 *
 * @param {GetUserHomeOpts} opts
 */
async function getUserHome(opts) {
  if (opts.max_time && !opts.max_cursor) {
    opts.max_cursor = new Date(opts.max_time).getTime()
  }
  const count = 18
  const resp = []
  try {
    let page = 0
    let number = 1
    let max_cursor = 0
    while (++page) {
      console.warn(dim(`下载 ${opts.name || ''} 第${page}页 ${new Date(max_cursor).toLocaleString()}`))
      const data = await getUserHomePosts({
        cookie: opts.cookie,
        user_sec_uid: opts.user_sec_uid,
        web_id: opts.web_id,
        count,
        max_cursor
      })
      number += data.aweme_list.length
      max_cursor = data.max_cursor
      resp.push(data)
      const is_top = data.aweme_list?.[0]?.is_top
      if (!data.has_more) break
      if (!is_top) {
        if (opts.max_cursor && (data.max_cursor <= opts.max_cursor)) break
        if (opts.max_page && (opts.max_page <= page)) break
        if (opts.max_number && (opts.max_number <= number)) break
      }
      await sleep(Math.random() * 10000)
    }
    return resp
  } catch (e) {
    console.error(e)
    return resp
  }
}

/**
 * @typedef GetUserHomePostsOpts
 * @property {string} cookie
 * @property {string} user_sec_uid
 * @property {string} web_id - 客户端ID（SSR_RENDER_DATA.app.odin.user_unique_id）
 * @property {number} [max_cursor]
 * @property {number} [count]
 *
 * @param {GetUserHomePostsOpts} opts
 */
function getUserHomePosts(opts) {
  const { cookie, user_sec_uid, web_id, count = 18, max_cursor = 0 } = opts
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
    webid: `${web_id}`, // 客户端ID（SSR_RENDER_DATA.app.odin.user_unique_id）
    msToken: `${ms_token}` // cookie中获取
  })
  // 请求ID, X-Bogus
  query.set('X-Bogus', getXBogus(query.toString(), cookie, referer))
  debug(green('query:'), dim(query.toString()))
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
  }).then(res => {
    debug(res.status, dim(res.url))
    return res.json()
  })
}

function getUserProfile(user_sec_id) {

}

/**
 * @typedef GetPostCommentsOpts
 * @property {string} cookie
 * @property {string} web_id
 * @property {string} aweme_id
 *
 * @param {GetPostCommentsOpts} opts
 * @returns
 */
function getPostComments(opts) {
  const { cookie, web_id, aweme_id } = opts
  const cookieObj = parseCookie(cookie)
  const ms_token = cookieObj.msToken
  const url = 'https://www.douyin.com/aweme/v1/web/comment/list/'
  const referer = `https://www.douyin.com/`
  const query = new URLSearchParams({
    device_platform: 'webapp',
    aid: '6383',
    channel: 'channel_pc_web',
    aweme_id,
    cursor: '0',
    count: '10',
    item_type: '0',
    insert_ids: '',
    whale_cut_token: '',
    cut_version: '1',
    rcFT: '',
    pc_client_type: '1',
    version_code: '170400',
    version_name: '17.4.0',
    cookie_enabled: 'true',
    screen_width: '1920',
    screen_height: '1200',
    browser_language: 'zh-CN',
    browser_platform: 'MacIntel',
    browser_name: 'Chrome',
    browser_version: '117.0.0.0',
    browser_online: 'true',
    engine_name: 'Blink',
    engine_version: '117.0.0.0',
    os_name: 'Mac OS',
    os_version: '10.15.7',
    cpu_core_num: '8',
    device_memory: '8',
    platform: 'PC',
    downlink: '1.75',
    effective_type: '4g',
    round_trip_time: '0',
    webid: `${web_id}`, // 客户端ID（SSR_RENDER_DATA.app.odin.user_unique_id）
    msToken: `${ms_token}` // cookie中获取
  })
  // 请求ID, X-Bogus
  query.set('X-Bogus', getXBogus(query.toString(), cookie, referer))
  debug(green('query:'), dim(query.toString()))
  return fetch(url + '?' + query, {
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
  }).then(res => {
    debug(res.status, dim(res.url))
    return res.json()
  })
}
