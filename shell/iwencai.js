const fs = require('fs')
const path = require('path')
const vm = require('vm')
let data = ''
let page = 0
const folder = process.cwd()
let filename = 'iwencai'
while (process.argv.length) {
  if (process.argv.shift() === '--page') page = Number(process.argv.shift())
}

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
