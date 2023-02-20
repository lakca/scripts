const Koa = require('koa')
const KoaRouter = require('koa-router')
const serve = require('koa-static')
const WebSocket = require('ws')
const http = require('http')
const url = require('url')
const fs = require('fs')
const { EventEmitter } = require('events')
const sp = require('superagent')
const iconv = require('iconv-lite')
const port = process.env.PORT || 8080

const app = new Koa()
const router = new KoaRouter()
app.use(router.routes())
app.use(serve(__dirname))

router.get('/s/search', async ctx => {
  ctx.body = await search(ctx.query.q)
})

const server = app.listen(port)
const wss = new WebSocket.WebSocketServer({ noServer: true })
server.on('upgrade', (request, socket, head) => {
  const {pathname} = url.parse(request.url || '')
  if (pathname === '/ws') {
    wss.handleUpgrade(request, socket, head, ws => {
      wss.emit('connection', ws, request)
    })
  }
})

class Collect extends EventEmitter {
  constructor() {
    super()
    /** @type Object<string, Array> */
    this._vectors = {}
    /** @type Object<string, Set> */
    this._sets = {}
    /** @type string */
    this._key = ''
    this._deepKeys = new Set()
  }
  type(...types) {
    return types.reduce((r, t) => r + (r ? ':' : '') + (Array.isArray(t) ? t.join(':') : t), '')
  }
  key(...keys) {
    this._key = this.type(...keys)
    return this
  }
  add(data) {
    const key = this._key
    if (!this._sets[key]) this._sets[key] = new Set()
    if (!this._sets[key].size) this.emit(this.type('ADD', key))
    this._sets[key].add(data)
    this.emit(this.type('add', key))
    return this
  }
  addDeep(data) {
    this._deepKeys.add(this._key)
    return this.add(JSON.stringify(data))
  }
  delete(data) {
    const key = this._key
    if (!this._sets[key]) return
    this._sets[key].delete(data)
    this.emit(this.type('delete', key))
    if (!this._sets[key].size) this.emit(this.type('DELETE', key))
    return this
  }
  get() {
    const r =  Array.from(this._sets[this._key] || [])
    return this._deepKeys.has(this._key) ? r.map(e => JSON.parse(e)) : r
  }
}

const collect = new Collect()

collect.on('ADD:action:quote', async () => {
  const get = async () => {
    // console.log(collect.key('data', 'quote', 'code').get())
    const data = JSON.stringify(await getQuote(collect.key('data', 'quote', 'code').get()))
    const clients = collect.key('action', 'quote').get()
    for (const client of clients) {
      client.send(data)
    }
  }
  polling(3000, get)
})

wss.on('connection', ws => {
  ws.on('error', console.error)
  ws.on('message', msg => {
    const { type, action, code } = JSON.parse(msg.toString())
    if (type === 'begin') {
      collect.key('action', action).add(ws)
      if (action === 'quote') {
        collect.key('data', 'quote', 'code').addDeep(code)
      }
    } else if (type === 'end') {
      collect.key('action', action).delete(ws)
    }
  })
})

function polling(options, fn, ...args) {
  if (typeof options === 'number') options = { interval: options }
  const data = { options, fn, args }
  let t = null
  function handler() {
    t = setTimeout(async () => {
      const r = data.fn(...data.args)
      if (data.options.wait && r.then) {
        await r
      }
      handler()
    }, data.options.interval)
  }
  handler()
  return (updateOptions) => {
    if (updateOptions) {
      Object.assign(data.options, updateOptions)
    } else {
      clearTimeout(t)
    }
  }
}

function getQuote(code) {
  return new Promise((resolve, reject) => {
    sp.get('https://hq.sinajs.cn/list=' + (Array.isArray(code) ? code.join('\n') : code))
    .set('Referer', 'http://finance.sina.com.cn/')
    .pipe(iconv.decodeStream('gb18030'))
    .collect((err, body) => {
      if (err) reject(err)
      const data = body.trim().split('\n').map(line => {
        const symbol = line.split('=')[0].split('_')[2]
        const values = line.split('"')[1].split(',')
        // ['名称', '开盘价', '收盘价', '当前价', '最高价', '最低价', '买一价', '卖一价', '成交量', '成交额', '买一量', '买一价', '买二量', '买二价', '买三量', '买三价', '买四量', '买四价', '买五量', '买五价', '买一量', '卖一价', '卖二量', '卖二价', '卖三量', '卖三价', '卖四量', '卖四价', '卖五量', '卖五价', '日期', '时间']
        return {
          symbol,
          name: values[0],
          open: Number(values[1]),
          close: Number(values[2]),
          price: Number(values[3]),
          high: Number(values[4]),
          low: Number(values[5]),
          b1: Number(values[6]),
          s1: Number(values[7]),
          volume: Number(values[8]),
          amount: Number(values[9]),
          buy: [
            { v: Number(values[10]), a: Number(values[11]) },
            { v: Number(values[12]), a: Number(values[13]) },
            { v: Number(values[14]), a: Number(values[15]) },
            { v: Number(values[16]), a: Number(values[17]) },
            { v: Number(values[18]), a: Number(values[19]) },
          ],
          sell: [
            { v: Number(values[20]), a: Number(values[21]) },
            { v: Number(values[22]), a: Number(values[23]) },
            { v: Number(values[24]), a: Number(values[25]) },
            { v: Number(values[26]), a: Number(values[27]) },
            { v: Number(values[28]), a: Number(values[29]) },
          ],
          date: values[30],
          time: values[31],
        }
      })
      resolve(data)
    })
  })
}

function search(q) {
  return new Promise((resolve, reject) => {
    sp.get(`https://suggest3.sinajs.cn/suggest/type=&key=${q}&name=suggestdata_${Date.now()}`)
    .set('Referer', 'http://finance.sina.com.cn/')
    .pipe(iconv.decodeStream('gb18030'))
    .collect((err, body) => {
      const lines = body.split('"')[1].split(';').map(e => e.split(','))
      const data = lines.map(line => {
        return {
          name: line[0],
          code: line[2],
          symbol: line[3],
        }
      })
      if (err) reject(err)
      else resolve(data)
    })
  })
}
