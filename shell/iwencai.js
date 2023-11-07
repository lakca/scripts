#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const vm = require('vm')
let data = ''
let page = 0
let perpage = 0
let folder = path.join(__dirname, 'iwencai')
let filename = 'iwencai'
function main(argv) {
  while (argv.length) {
    switch (argv.shift()) {
      case '-h':
        console.log(`
        \x1b[2m下载分页\x1b[0m
        --page <n>
        \x1b[2m根据iwencai的Node.js Fetch内容下载结果\x1b[0m
        --download
        \x1b[2m根据搜索语句推荐搜索语句\x1b[0m
        --recommend, --rcmd <query>
        \x1b[2m下载目录\x1b[0m
        --dest <dest=${folder}>
        \x1b[2m打印推荐问句\x1b[0m
        --question

        \x1b[2m例如：\x1b[0m

        \x1b[2mpbpaste | node iwencai.js --download --page 5\x1b[0m
        `)
        main(['--question'])
        break
      case '--page':
        page = Number(argv.shift())
        break
      case '--perpage':
        perpage = Number(argv.shift())
        break
      case '--dest':
        folder = argv.shift() || folder
        fs.mkdirSync(folder, { recursive: true })
        break
      case '--download':
        download().catch(handleError)
        break
      case '--recommend':
      case '--rcmd':
        recommend(argv.shift()).then(data => console.table(data?.data, ['tag', 'query'])).catch(handleError)
        break
      case '--question': {
        const qs = ['非ST，非退市，股东人数从少到多排名，列名包含前复权历史最高价、前复权历史最低价、股东数、集中度90、流通市值、近一年涨跌幅、所属概念、所属板块、所属行业、技术形态、选股动向、资产负债率、股息率、PEG']
        if (argv.length) {
          qs.unshift(argv)
          const qss = qs.join('，')
          console.log(qss)
          require('child_process').execSync(`open http://iwencai.com/unifiedwap/result?w=${qss}&querytype=stock`)
        } else {
          console.log(`
        \x1b[33;2m虚拟现实概念，${qs}\x1b[0m
        `)
        }
        return
      }
      default:
    }
  }
}

main(process.argv)

function handleError(e) {
  console.error('\x1b[2m' + e.stack.split('\n')[1].trim() + '\x1b[0m \x1b[31m' + e.message + '\x1b[0m')
}

async function download() {
  process.stdin.setEncoding('utf-8')
    .on('data', (buf) => { data += buf })
    .on('end', () => {
      const text = data.split('\n').map(line => {
        if (line.trim().startsWith('"body"')) {
          const e = JSON.parse(`{${line.replace(/,$/, '')}}`)
          e.body = Object.fromEntries(new URLSearchParams(e.body))
          e.body.condition = JSON.parse(e.body.condition)
          if (e.body.page) {
            if (page) {
              e.body.page = page
            } else {
              page = e.body.page
            }
          }
          if (e.body.perpage) {
            if (perpage) {
              e.body.perpage = perpage
            } else {
              perpage = e.body.perpage
            }
          }
          if (e.body.query) filename = e.body.query
          return `"body": new URLSearchParams(${JSON.stringify(e.body, null, 2)}).toString(),`
        }
        return line
      }).join('\n')

      const code = `
    async function request() {
      const res = await ${text}
      return res.json()
    }
    request().then(data => {
      fs.writeFileSync(path.join('${folder}', '${filename}.${new Date().toLocaleDateString().replaceAll('/', '-')}.${page}.json'), JSON.stringify(data, null, 2))
    })
    `
      vm.runInNewContext(code, { fs, path, fetch, URLSearchParams })
    })
}

async function recommend(query) {
  if (!query) throw new Error('没有问句')
  return fetch('http://www.iwencai.com/unifiedwap/unified-wap/v1/query/recommend', {
    headers: {
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'cache-control': 'no-cache',
      'content-type': 'application/x-www-form-urlencoded',
      'hexin-v': 'AxqRpeL3KnZj06Y2rvjJAXhhbcs-S_DHEPsSaCTfxFt4tbQ1DNvuNeBfYoD3',
      pragma: 'no-cache',
      'proxy-connection': 'keep-alive',
      'Referrer-Policy': 'strict-origin-when-cross-origin'
    },
    body: new URLSearchParams({
      query,
      query_type: 'stock',
      rsh: '2'
    }).toString(),
    method: 'POST'
  }).then(r => r.json())
}
