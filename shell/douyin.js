#!/usr/bin/env node

const cp = require('child_process')
const json = require('./douyin.json')
const https = require('https')
const fs = require('fs')
const path = require('path')
const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36'
const BIT_RATE = {
  DEFAULT: 1,
  HIGH: 2,
  LOW: 3
}
const TRY_COUNT = 3
const MIN_SIZE = 0.1
const SIZE_GAP = 0.5
const DEFAULT_DEST_DIR = path.join(__dirname, 'douyin')
const SKIP_IMAGE = !!process.env.SKIP_IMAGE

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

const readline = require('readline')
const assert = require('assert')

const bool_mapper = { Y: true, y: true, N: false, n: false }
const is_number = s => s !== '' && !isNaN(Number(s))
const is_not_null = s => !!s

function debug(...args) {
  process.env.DEBUG && log(...args)
}
function log(...args) {
  console.warn(`${yellow('[' + getCodeLineno(1)) + ']'}`, ...args)
}
function getCodeLineno(offset = 0) {
  const foo = {}
  Error.captureStackTrace(foo)
  const lineno = foo.stack.split('\n')[2 + offset].match(/([0-9]+):[0-9]+\)?$/)[1]
  return lineno
}
/**
 *
 * @param {string|(string|number)[][]} query - [question, desc, example, default]
 * @param {object} [opts]
 * @param {string[]} [opts.range] - 输入值范围
 * @param {object|function} [opts.mapper] - 输入值映射
 * @param {(s: string) => void} [opts.each] - 每次输入时调用
 * @param {boolean} [opts.bool] - 布尔值预设
 * @param {(answer: string) => boolean} [opts.checker] - 判断输入
 * @param {boolean} [opts.optional]
 * @param {boolean} [opts.raw] - 是否对原始输入进行处理：trim()
 * @param {any} [opts.defaultValue] - 默认值
 * @param {number} [opts.lineno] - 调用栈偏移数
 *
 * @example
 * ask('question...')
 * ask([
 *  ['question...', 'desc...' 'example...', 'default value....'],
 *  ['question...', 'desc...' 'example...', 'default value....'],
 * ])
 */
function ask(query, opts) {
  const _opts = { lineno: 0, ...opts }
  if (_opts.bool) {
    _opts.range = Object.keys(bool_mapper)
    _opts.mapper = bool_mapper
  }
  const lineno = getCodeLineno(1 + _opts.lineno)
  // @ts-ignore
  // eslint-disable-next-line no-caller
  !arguments.callee.initialized && console.log(dim([
    '如何回答：',
    '  - 如果回答是，则输入Y或y',
    '  - 如果回答否，则输入N或n'
  ].join('\n')))
  // @ts-ignore
  // eslint-disable-next-line no-caller
  arguments.callee.initialized = true
  const { range, mapper, checker, optional, raw, defaultValue, each } = _opts
  const _checker = Array.isArray(checker) ? v => checker.reduce((r, c) => r && c(v), true) : checker
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
    rl.question(querify(query, _opts), answer => {
      if (!raw) answer = answer.trim()
      process.stdout.write('\x1b[0m')
      if (each) {
        each(answer)
      }
      if (
        ((defaultValue !== undefined || optional) && answer === '') ||
        !(range || _checker) ||
        (range && range.includes(answer)) ||
        (_checker && _checker(answer))
      ) {
        rl.close()
        answer = defaultValue !== undefined && answer === '' ? defaultValue : answer
        if (mapper) {
          answer = typeof mapper === 'function' ? mapper(answer) : answer in mapper ? mapper[answer] : answer
        }
        resolve(answer)
      } else {
        rl.close()
        ask(query, _opts).then(resolve)
      }
    })
  })
  function querify(query, opts) {
    if (Array.isArray(query)) {
      return ((opts && opts.optional) ? red(`[可选:${lineno}]`) : red(`[必填:${lineno}]`)) + query.map(phrase => {
        const [question, desc, example, defaultValue] = phrase
        let appendix = ''
        if (desc) {
          appendix += dim(desc)
        }
        if (example) {
          appendix += dim(yellow(underline(example)))
        }
        if (defaultValue !== undefined) {
          appendix += dim('默认值为') + green(defaultValue)
        }
        if (appendix) {
          appendix = dim('(') + appendix + dim(')')
        }
        return yellow(question) + appendix
      }).join('，或') + yellow(':') + '\x1b[31m'
    } else {
      return querify([[query, '', '', opts && opts.defaultValue]], opts)
    }
  }
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
function updateStore(nickname, user_sec_uid, uid) {
  const file = __filename + '.store'
  fs.appendFileSync(file, '\n' + [`nickname:${nickname}`, `user_sec_uid:${user_sec_uid}`, `uid:${uid}`].join('\n'))
  // const lines = fs.readFileSync(file).toString().split(/\r?\n/).filter(e => e.trim())
  // const found = lines.find(e => e.trim() === user_sec_uid)
}
/**
 * Get today date string, likes `2024-01-01`
 * @param {string|number|Date} [date]
 * @returns
 */
function getDateString(date) {
  return (date ? new Date(date) : new Date()).toISOString().slice(0, 10)
}
function makeHomeListFileName(nickname, uid, sec_uid) {
  return `${nickname}.${uid}.${sec_uid}.${getDateString()}.json`
}
function parseHomeListFileName(file) {
  /** @type {string[]} */
  let parsed = file.match(/^(.+)\.([0-9]+)\.([^.]+)\.([0-9]{4}-[0-9]{2}-[0-9]{2})\.json$/)
  if (parsed) return { nickname: parsed[1], uid: parsed[2], secUid: parsed[3], date: parsed[4] }
  parsed = file.match(/^(.+)\.([0-9]+)\.([0-9]{4}-[0-9]{2}-[0-9]{2})\.json$/)
  if (parsed) return { nickname: parsed[1], uid: parsed[2], date: parsed[3] }
  parsed = file.match(/^(.+)\.([^.]+)\.([0-9]{4}-[0-9]{2}-[0-9]{2})\.json$/)
  if (parsed) return { nickname: parsed[1], secUid: parsed[2], date: parsed[3] }
}
/**
 * @param {string} file
 * @param {string} [sec_uid]
 * @returns
 */
function checkHomeListFile(file, sec_uid) {
  let reg = null
  if (sec_uid) {
    reg = new RegExp(`.+\\.${sec_uid}\\.[0-9]{4}-[0-9]{2}-[0-9]{2}\\.json$`)
  } else {
    reg = /^(.+)\.([0-9]{4}-[0-9]{2}-[0-9]{2})\.json$/
  }
  return new RegExp(reg).test(file)
}
/**
 * 在目录中查找目录文件
 * @param {string} folder_dir
 * @param {string} sec_uid
 * @param {number} [gap_ms]
 * @returns
 */
function findHomeListFile(folder_dir, sec_uid, gap_ms) {
  for (const file of fs.readdirSync(folder_dir)) {
    if (checkHomeListFile(file, sec_uid)) {
      if (gap_ms == null) return file
      const parsed = parseHomeListFileName(file)
      const inGap = gap_ms ? (new Date().getTime() - new Date(parsed.date).getTime()) <= gap_ms * 1000 * 3600 * 24 : getDateString() === parsed.date
      if (inGap) {
        return file
      }
    }
  }
}
function getItemFolder(destDir, uid, secUid, nickname) {
  for (const file of fs.readdirSync(destDir)) {
    const realpath = path.join(destDir, file)
    if (fs.statSync(realpath).isDirectory() && file.endsWith(`${uid}-${secUid}}`)) {
      return realpath
    }
  }
  const folder = path.join(destDir, [nickname, uid, secUid].join('-'))
  fs.mkdirSync(folder, { recursive: true })
  return folder
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

    \x1b[2m通过配置文件自动下载主页列表\x1b[0m
    \x1b[32m-c\x1b[0m
        <conffile>
        [-gap <days>] \x1b[2m- 间隔天数\x1b[0m
        [-curl]       \x1b[2m- 同时下载媒体文件\x1b[0m
        [-force]      \x1b[2m- （同名时）强制覆盖列表文件\x1b[0m

    \x1b[32mtransform\x1b[0m
        <name> \x1b[2m- 见douyin.json key 或 alias\x1b[0m

    \x1b[2m下载统一结构（经过transform）信息的视频/图片到<dest>目录（默认为工作目录）下的用户目录中\x1b[0m
    \x1b[32mcurl\x1b[0m
        [<jsonfile>]       \x1b[2m- 通过主页列表文件下载媒体文件（如果不提供该选项，则从stdin获取Raw Response）\x1b[0m
        [-dest <dest>]     \x1b[2m- 默认为${DEFAULT_DEST_DIR}\x1b[0m
        [-high]            \x1b[2m- 下载高比特率\x1b[0m
        [-low]             \x1b[2m- 下载低比特略\x1b[0m
        [-rename]          \x1b[2m- 对已存在的文件（文件名以{item.awemeId}.mp4判断）重命名（以符合最新命名规则）\x1b[0m
        [-forcebitrate]    \x1b[2m- 文件已存在，但比特率不符合时也要下载（覆盖）\x1b[0m
        [-minsize <n>]     \x1b[2m- 文件小于多少MB（默认${MIN_SIZE}）就判定为无效文件 \x1b[0m
        [-sizegap <n>]     \x1b[2m- 文件大小差小于多少MB（默认${SIZE_GAP}）就判定为同一文件 \x1b[0m

    \x1b[2m下载用户主页中的作品
    web_id与cookie紧密相关，获取方式: SSR_RENDER_DATA.app.odin.user_unique_id\x1b[0m
    \x1b[32mposts\x1b[0m
        -c,-cookie       <cookie>            \x1b[2m- 网页cookie\x1b[0m
        -w,-user_sec_uid <web_id>            \x1b[2m- 客户端ID，需要同cookie保持来源一致（SSR_RENDER_DATA.app.odin.user_unique_id）\x1b[0m
        -u,-web_id       <user_sec_uid>      \x1b[2m- 用户sec_id\x1b[0m
        [-o,-output      <output_dir=cwd()>] \x1b[2m- 保存目录\x1b[0m
        [-p,-max_page    <number>]           \x1b[2m- 最小时间戳\x1b[0m
        [-n,-max_number  <number>]           \x1b[2m- 最小时间，会传入Date进行构造\x1b[0m
        [-t,-max_time    <time>]             \x1b[2m- 最多页面（以18条每页计）\x1b[0m

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
    log(green('完成!'))
    process.exit(0)
  })
} else {
  let input = ''
  process.stdin.setEncoding('utf-8').on('data', chunk => {
    input += chunk
  }).on('end', () => {
    main(cmd, input).then(() => {
      log(green('完成!'))
      process.exit(0)
    })
  })
}

async function main(cmd, input = '') {
  switch (cmd) {
    case '-c': {
      /** @type {any} */
      const opts = {}
      let file = null
      while (argv.length) {
        const arg = argv.shift()
        if (arg === '-curl') opts.shouldCurl = true
        else if (arg === '-force') opts.forceDownloadHomeList = true
        else if (arg === '-gap') opts.gap = Number(argv.shift())
        else file = arg
      }
      file && await downloadFromConfig(file, opts)
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
      /** @type {any} */
      const opts = { bitRate: BIT_RATE.DEFAULT, minSize: MIN_SIZE, sizeGap: SIZE_GAP, destDir: DEFAULT_DEST_DIR }
      const files = []
      while (argv.length) {
        const arg = argv.shift()
        if (arg === '-dest') opts.destDir = argv.shift()
        else if (arg === '-low') opts.bitRate = BIT_RATE.LOW
        else if (arg === '-high') opts.bitRate = BIT_RATE.HIGH
        else if (arg === '-rename') opts.rename = true
        else if (arg === '-forcebitrate') opts.forceBitRate = true
        else if (typeof arg === 'string' && arg.startsWith('-minsize')) opts.minSize = +arg.slice('-minsize'.length)
        else if (typeof arg === 'string' && arg.startsWith('-sizegap')) opts.sizeGap = +arg.slice('-sizegap'.length)
        else if (arg) files.push(path.isAbsolute(arg) ? arg : path.join(process.cwd(), arg))
      }
      if (files.length) {
        await downloadMediasFromListFile(files, opts)
      } else {
        await downloadMediasFromHomeRawResponse(input, opts)
      }
    } break
    case 'posts': {
      /** @type {any} */
      const opts = {
        output: DEFAULT_DEST_DIR,
        cookie: input.trim(),
        web_id: '7268870306478261795'
      }
      let arg = null
      while (argv.length) {
        arg = argv.shift()
        if (arg === '-c' || arg === '-cookie') opts.cookie = argv.shift()
        if (arg === '-u' || arg === '-user_sec_uid') opts.user_sec_uid = argv.shift()
        if (arg === '-w' || arg === '-web_id') opts.web_id = argv.shift()
        if (arg === '-o' || arg === '-output') opts.output = argv.shift()
        if (arg === '-p' || arg === '-max_page') opts.max_page = argv.shift()
        if (arg === '-n' || arg === '-max_number') opts.max_number = argv.shift()
        if (arg === '-t' || arg === '-max_time') opts.max_time = argv.shift()
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

/**
 * @param {string} [defaultValue]
 * @returns {Promise<Partial<LimitOpts> & { limit: string }>}
 */
async function askLimit(defaultValue) {
  const limit = await ask([
    ['请输入最早时间', '任何可传入Date进行构造的数据', '2020-01-01'],
    ['或毫秒时间戳', '格式同', Date.now()],
    ['或最大数量', '小于', '100000'],
    ['或最大页面', '小于', 'p100']
  ], {
    checker: v => {
      return !!(is_number(v) || /p[0-9]+/i.test(v) || !isNaN(new Date(v).valueOf()))
    },
    defaultValue,
    lineno: 1
  })
  const limitOpts = { limit }
  if (is_number(limit)) {
    if (limit < 10 ** 10) {
      limitOpts.max_number = Number(limit)
    } else {
      limitOpts.max_cursor = Number(limit)
    }
  } else if (/p[0-9]+/i.test(limit)) {
    limitOpts.max_page = Number(limit.slice(1))
  } else {
    limitOpts.max_time = limit
  }
  return limitOpts
}
async function askWebId(defaultValue) {
  return ask([
    ['客户端ID', '需要同cookie保持来源一致，从控制台获取', 'SSR_RENDER_DATA.app.odin.user_unique_id']
  ], {
    checker: is_number,
    defaultValue,
    lineno: 1
  })
}
async function askUserSecUid(defaultValue) {
  return ask([
    ['用户sec_uid', '', 'MS4wLjABAAAAKxPOisbl6kuP6LlgT'],
    ['用户主页链接', '', 'https://www.douyin.com/user/MS4wLjABAAAAKxPOisbl6kuP6LlgT']
  ], {
    checker: is_not_null,
    mapper: v => v.split('/').pop() || '',
    defaultValue,
    lineno: 1
  })
}
async function stepByStep() {
  const destDir = await ask('下载的文件存放目录', { defaultValue: DEFAULT_DEST_DIR })
  const cache = caching(destDir)
  let listFile = await ask('posts文件路径', { optional: true })
  if (listFile && !path.isAbsolute(listFile)) {
    listFile = path.join(destDir, listFile)
  }
  /** @type {DownloadUserHomeListOpts & { limit: any }} */
  const homeOpts = {
    cookie: readFileSync(path.join(destDir, 'cookie.jar')).trim(),
    ...cache.homeOpts
  }
  if (!listFile) {
    homeOpts.output = destDir
    homeOpts.cookie = await ask('网页cookie', { defaultValue: homeOpts.cookie, checker: is_not_null })

    homeOpts.web_id = await askWebId(homeOpts.web_id)

    homeOpts.user_sec_uid = await askUserSecUid(homeOpts.user_sec_uid)

    Object.assign(homeOpts, await askLimit(homeOpts.limit))
  }

  /** @type {CurlOptions} */
  const curlOpts = {
    bitRate: BIT_RATE.DEFAULT,
    rename: false,
    forceBitRate: false,
    sizeGap: SIZE_GAP,
    minSize: MIN_SIZE,
    ...cache.curlOpts
  }
  curlOpts.bitRate = await ask('请问下载高码率（2）还是低码率（3），抑或是默认码率（1）？', { range: ['1', '2', '3'], mapper: { 1: 1, 2: 2, 3: 3 }, defaultValue: curlOpts.bitRate })
  curlOpts.rename = await ask('如果命名规则有变化，是否根据最新规则重命名已存在的文件', { bool: true, defaultValue: curlOpts.rename })
  curlOpts.forceBitRate = await ask('如果码率不一致，是否覆盖已存在的文件', { bool: true, defaultValue: curlOpts.forceBitRate })
  curlOpts.sizeGap = Number(await ask(`如果要覆盖已存在的文件，新旧文件至少相差多少MB才执行`, { checker: is_number, defaultValue: curlOpts.sizeGap }))
  curlOpts.minSize = Number(await ask(`多少MB的文件才是有效的`, { checker: is_number, defaultValue: curlOpts.minSize }))
  curlOpts.destDir = destDir

  if (!listFile) log('[逐步操作]', homeOpts)
  log('[逐步操作]', curlOpts)
  if (await ask('是否继续', { bool: true })) {
    caching(destDir, Object.assign(cache, { homeOpts, curlOpts }))
    const items = transform('userhome', listFile ? require(listFile) : await downloadUserHomeList(homeOpts))
    if (await ask('是否下载具体内容', { bool: true })) {
      for (const item of items) {
        await curl(item, curlOpts)
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
        log(dim(`[首个评论]第${number}个 ${aweme_id}`))
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
    console.error('[首个评论]', e)
    return sec_uids
  } finally {
    log('[首个评论]', sec_uids)
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
  // 根据已存在的文件判断最早时间
  if (opts.max_time?.toLowerCase() === 'auto') {
    const dates = fs.readdirSync(opts.output)
      .filter(file => checkHomeListFile(file, opts.user_sec_uid))
      .map(file => parseHomeListFileName(file).date)
      .sort()
    if (dates.length) {
      opts.max_time = getDateString(dates[0])
    } else {
      Object.assign(opts, await askLimit())
    }
    if (!(await ask(`自动判断的最早时间是${opts.max_time}，是否确定`, { bool: true }))) {
      delete opts.max_time
      Object.assign(opts, await askLimit())
    }
  }
  const data = await getUserHome(opts)
  if (!data[0].aweme_list.length) {
    log(dim('[下载主页列表]没有内容'))
    return []
  }
  const { author } = data[0].aweme_list[0]
  const { nickname, uid, sec_uid } = author
  const file = makeHomeListFileName(nickname, uid, sec_uid)
  if (data) {
    fs.writeFileSync(path.join(opts.output, file), JSON.stringify(data, null, 2))
    log(green('[下载主页列表]保存:'), file)
    updateStore(nickname, sec_uid, uid)
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
async function downloadMediasFromHomeRawResponse(list, opts) {
  const items = typeof list === 'string' ? JSON.parse(list.trim()) : list
  for (const item of (Array.isArray(items) ? items : [items]).reverse()) {
    const r = await curl(item, opts)
    if (r !== RESULT.OK_RENAME_VIDEO) {
      await sleep(Math.random() * 10000 + 1000)
    }
  }
}
/**
 * @param {string|string[]} listFile
 * @param {object} opts
 * @param {string} opts.destDir
 * @param {BIT_RATE[keyof BIT_RATE]} [opts.bitRate]
 * @param {boolean} [opts.rename]
 * @param {boolean} [opts.forceBitRate]
 * @param {Number} opts.minSize
 * @param {Number} opts.sizeGap
 * @returns
 */
async function downloadMediasFromListFile(listFile, opts) {
  for (const file of Array.isArray(listFile) ? listFile : [listFile]) {
    const items = transform('userhome', require(file))
    for (const item of items) {
      const r = await curl(item, opts)
      if (r !== RESULT.OK_RENAME_VIDEO) {
        await sleep(Math.random() * 2000 + 1000)
      }
    }
  }
}
function parseConfig(text) {
  const opts = {
    cookie: '',
    output: '',
    web_id: '',
    user_sec_uid: '',

    bitRate: BIT_RATE.DEFAULT,
    rename: false,
    forceBitRate: false,
    sizeGap: SIZE_GAP,
    minSize: MIN_SIZE,
    destDir: ''
  }
  const user_sec_ids = []
  const users = []
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
      if (!user_sec_ids.includes(val)) {
        user_sec_ids.push(val)
        _checkOpts(opts, opts)
        users.push(JSON.parse(JSON.stringify({ opts })))
      }
      opts.name = ''
    }
  }
  return users
}
/**
 * @param {string} configfile
 * @param {object} options
 * @param {boolean} options.shouldCurl - 是否下载项目
 * @param {boolean} options.forceDownloadHomeList - 是否强制下载列表文件
 * @param {boolean} options.gap - 最小间隔天数
 */
async function downloadFromConfig(configfile, options) {
  const users = parseConfig(fs.readFileSync(configfile).toString())
  for (const user of users) {
    const inGapFile = findHomeListFile(user.opts.destDir, user.opts.user_sec_uid, user.opts.gap || options.gap || 0)
    if (options.forceDownloadHomeList || !inGapFile) {
      let name = user.opts.name
      if (!name) {
        const file = findHomeListFile(user.opts.destDir, user.opts.user_sec_uid)
        name = file ? parseHomeListFileName(file).nickname : user.opts.user_sec_uid
      }
      let folder
      if (await ask(`[主页列表]是否下载${name}`, {
        range: ['y', 'n'],
        mapper: { y: true, n: false },
        each(v) {
          if (v === 'o') {
            if (!folder) {
              folder = fs.readdirSync(user.opts.destDir, { withFileTypes: true })
                .filter(file => file.isDirectory())
                .find(file => file.name.startsWith(name))
            }
            if (folder) {
              cp.execSync(`open ${path.join(folder.path, folder.name)}`)
            } else {
              log('未找到文件夹')
            }
          }
        }
      })) {
        const items = transform('userhome', await downloadUserHomeList(user.opts))
        if (options.shouldCurl) {
          for (const item of items) {
            await curl(item, user.opts)
            await sleep(Math.random() * 2000)
          }
        }
        await sleep(Math.random() * 5000)
      }
    } else {
      log(yellow(`[主页列表]已经存在: ${inGapFile}`))
    }
  }
}
/**
 * @param {DownloadUserHomeListOpts} homeOpts
 * @param {CurlOptions} curlOpts
 */
function _checkOpts(homeOpts, curlOpts) {
  if (homeOpts) {
    assert(homeOpts.cookie, '没有提供cookie')
    assert(homeOpts.user_sec_uid, '没有提供用户user_sec_uid')
    assert(homeOpts.web_id, '没有提供web_id')
    assert(homeOpts.output, '没有提供json文件下载目录output')
    assert(homeOpts.max_page || homeOpts.max_cursor || homeOpts.max_time, '没有提供max_page，或max_cursor，或max_time')
  }
  if (curlOpts) {
    assert(curlOpts.destDir, '没有提供多媒体下载目录destDir')
    assert(curlOpts.bitRate, '没有提供bitRate')
    assert(typeof curlOpts.rename === 'boolean', '没有提供rename')
    assert(typeof curlOpts.forceBitRate === 'boolean', '没有提供forceBitRate')
    assert(curlOpts.minSize, '没有提供minSize')
    assert(curlOpts.sizeGap, '没有提供sizeGap')
  }
}
/**
 * @param {string} name - API名称（或alias），参照douyin.json
 * @param {string|array} input - API原始数据
 */
function transform(name, input) {
  const items = typeof input === 'string' ? JSON.parse(input.trim()) : input
  if (Array.isArray(items)) {
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
  destDir = getItemFolder(destDir, item.uid, item.secUid, item.author)
  if (item.images && item.images.length && !SKIP_IMAGE) {
    if (item.musicUrls && item.musicUrls.length) {
      const filename = `${name}.mp3`
      const realpath = path.join(destDir, filename)
      const url = getRandom(item.musicUrls)
      await download(ensureUrl(url), realpath) || console.error(red('[媒体文件]下载失败:'), dim(filename), dim(url))
    }
    return Promise.allSettled(item.images.map((urls, i) => {
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${i + 1}-${item.awemeId}.jpg`))
      const filename = `${name(i + 1)}.jpg`
      if (existed) {
        console.error(yellow('[媒体文件]文件已存在:'), dim(filename))
        return RESULT.IMAGE_EXIST
      } else {
        const realpath = path.join(destDir, filename)
        const url = urls.find(url => /\.jpe?g/.test(url)) || urls[0]
        return download(ensureUrl(url), realpath).then((...args) => {
          return RESULT.OK_IMAGE
        }).catch(e => {
          console.error(red('[媒体文件]下载失败:'), dim(filename), dim(url))
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
        bitRateInfo.urls = bitRateInfo.urls.reverse()
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
    let n = 0
    const tryCount = Math.max(bitRateInfo.urls.length, TRY_COUNT)
    while (true) {
      url = bitRateInfo.urls[n % bitRateInfo.urls.length]
      // 文件存在的判定标准是，awemeId 相同，即最后一个字段相同
      const existed = fs.readdirSync(destDir).find(e => e.endsWith(`${item.awemeId}.mp4`))
      const stat = existed ? fs.statSync(path.join(destDir, existed)) : null
      const gapped = stat && bitRateInfo && (Math.abs(stat.size - bitRateInfo.bitSize) > 1024 ** 2 * options.sizeGap)
      const bigger = stat && (options.bitRate === BIT_RATE.HIGH && stat.size > bitRateInfo.bitSize)
      const smaller = stat && (options.bitRate === BIT_RATE.LOW && stat.size < bitRateInfo.bitSize)
      const anyway = options.bitRate === BIT_RATE.DEFAULT
      if (n === 1 && (!anyway && !bigger && !smaller) && gapped) {
        log(yellow('[媒体文件]文件已存在，但文件比特率不符合:'), dim(`${filename}`), yellow(`当前文件${humanRead(stat.size)}, 应该${humanRead(bitRateInfo.bitSize)}`))
        if (!options.forceBitRate) {
          return RESULT.VIDEO_EXIST
        }
      } else if (stat && stat.size > 1024 ** 2 * options.minSize) {
        n === 0 ? log(yellow('[媒体文件]文件已存在:'), dim(filename)) : log(green('[媒体文件]下载完成:'), dim(filename))
        if (options.rename && existed && existed !== filename) {
          log(yellow('[媒体文件]重命名:'), filename)
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
      n++
      if (n > tryCount) {
        log(red('[媒体文件]下载失败:'), dim(filename))
        return RESULT.DOWNLOAD_FAIL_VIDEO
      }
    }
  }
}

function download(url, filename) {
  return new Promise((resolve, reject) => {
    const oldResolve = resolve
    resolve = (v) => {
      // console.log(dim(`[下载]${v ? '完成' : '失败'}${filename}`))
      oldResolve(v)
    }
    https.get(url, res => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        debug(dim(green('[下载]重定向:')), dim(res.headers.location))
        return download(res.headers.location, filename).then(resolve).catch(() => resolve(false))
      }
      const ws = fs.createWriteStream(filename)
      res.pipe(ws, { end: true }).on('error', () => resolve(false))
      res.on('end', () => {
        res.destroyed || res.destroy()
        if (!ws.closed) {
          ws.close(() => {
            resolve(true)
          })
        } else {
          resolve(true)
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
function underline(text) { return `\x1b[4m${text}\x1b[24m` }
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
 * @typedef LimitOpts
 * @property {number} [max_page]
 * @property {number} [max_cursor]
 * @property {string} [max_time] - date string, param of `Date`
 * @property {number} [max_number]
 *
 * @typedef GetUserHomeOtherOpts
 * @property {string} cookie
 * @property {string} user_sec_uid
 * @property {string} web_id - 客户端ID（SSR_RENDER_DATA.app.odin.user_unique_id）
 * @property {string} [name]
 *
 * @typedef {GetUserHomeOtherOpts & LimitOpts} GetUserHomeOpts
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
      log(dim(`[下载主页列表]下载 ${opts.name || ''} 第${page}页 max_time:${opts.max_time} max_page:${opts.max_page} max_number:${opts.max_number} max_cursor:${max_cursor} ${new Date(max_cursor).toLocaleString()}`))
      const data = await getUserHomePosts({
        cookie: opts.cookie,
        user_sec_uid: opts.user_sec_uid,
        web_id: opts.web_id,
        count,
        max_cursor
      })
      if (!data.aweme_list) {
        break
      }
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
    console.error('[下载主页列表]', e)
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
    need_time_list: '1',
    time_list_query: '0',
    whale_cut_token: '',
    cut_version: '1',
    count: `${count}`, // 列表项目数量
    publish_video_strategy_type: '2',
    // 客户端信息
    pc_client_type: '1',
    version_code: '170400',
    version_name: '17.4.0',
    cookie_enabled: 'true',
    screen_width: '1440',
    screen_height: '900',
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
    downlink: '10',
    effective_type: '4g',
    round_trip_time: '50',
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
  }).then(data => {
    if (data.status_code !== 0) {
      log('[主页列表] https://www.douyin.com/aweme/v1/web/aweme/post?' + query)
      console.error('[主页列表]', Object.fromEntries(query.entries()))
      console.error('[主页列表]', data)
    }
    return data
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
