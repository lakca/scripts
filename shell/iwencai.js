const fs = require('fs')
const path = require('path')
const vm = require('vm')
let data = ''
let page = 0
let query
const folder = process.cwd()
let filename = 'iwencai'
function main() {
  while (process.argv.length) {
    switch (process.argv.shift()) {
      case '-h':
        console.log(`
        --page <n>         下载分页
        --download         根据Node.js Fetch内容下载
        --recommend, --rcmd <query> 根据搜索语句推荐搜索语句
        `)
        break
      case '--page':
        page = Number(process.argv.shift())
        break
      case '--download':
        download().catch(handleError)
        break
      case '--recommend':
      case '--rcmd':
        recommend(process.argv.shift()).then(data => console.table(data?.data, ['tag', 'query'])).catch(handleError)
        break
      default:
    }
  }
}

main()

function handleError(e) {
  console.error("\x1b[2m" + e.stack.split('\n')[1].trim() + "\x1b[0m \x1b[31m" + e.message + "\x1b[0m")
}

async function download() {
  process.stdin.setEncoding('utf-8')
    .on('data', (buf) => data += buf)
    .on('end', () => {
      let text = data.split('\n').map(line => {

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
  return fetch("http://www.iwencai.com/unifiedwap/unified-wap/v1/query/recommend", {
    "headers": {
      "accept": "application/json, text/plain, */*",
      "accept-language": "zh-CN,zh;q=0.9,en;q=0.8",
      "cache-control": "no-cache",
      "content-type": "application/x-www-form-urlencoded",
      "hexin-v": "AxqRpeL3KnZj06Y2rvjJAXhhbcs-S_DHEPsSaCTfxFt4tbQ1DNvuNeBfYoD3",
      "pragma": "no-cache",
      "proxy-connection": "keep-alive",
      "Referrer-Policy": "strict-origin-when-cross-origin"
    },
    "body": new URLSearchParams({
      query,
      query_type: 'stock',
      rsh: '2',
    }).toString(),
    "method": "POST"
  }).then(r => r.json())
}
