const https = require('https')
const fs = require('fs')
const cp = require('child_process')
const Koa = require('koa')
const KoaRouter = require('koa-router')
const serve = require('koa-static')
const { koaBody } = require('koa-body')
const url = require('url')
const wss = require('./wss')
const port = process.env.PORT || 8080
const em = require('./em')
const store = require('./store')
const path = require('path')

const app = new Koa()
const router = new KoaRouter()
app.use(koaBody({
  jsonLimit: '1kb'
}))
app.use(router.routes())
app.use(serve(path.join(__dirname, '/static')))
app.use(serve(path.join(__dirname, '/node_modules')))
app.use(async function(ctx, next) {
  try {
    await next()
  } catch (e) {
    console.log(e)
    ctx.body = e
    ctx.status = 500
  }
})

router.get('/s/search', async ctx => {
  ctx.body = await em.search(ctx.query.q)
})
router.get('/quote', async ctx => {
  console.log('quote')
  ctx.set('Access-Control-Allow-Origin', '*')
  const codestring = ctx.query.q
  if (codestring) {
    const codes = typeof codestring === 'string' ? codestring.trim().split(',') : codestring
    if (codes.length) {
      ctx.body = await em.get_quote(codes)
      return
    }
  }
  return ctx.body = []
})
router.post('/say', async ctx => {
  console.log(ctx.request.body)
  ctx.request.body && cp.execSync('say ' + ctx.request.body)
  ctx.status = 200
})
router.get('/download', async ctx => {
  console.log('download')
  ctx.body = fs.createReadStream('static/audio.html')
  ctx.set('content-disposition', 'attachment;filename=download.html')
  ctx.status = 200
})

const server = https.createServer({
  key: fs.readFileSync('./server.key'),
  cert: fs.readFileSync('./server.crt'),
  passphrase: '1234'
}, app.callback()).listen(port, '0.0.0.0')
server.on('upgrade', (request, socket, head) => {
  const { pathname } = url.parse(request.url || '')
  if (pathname === '/ws') {
    wss.handleUpgrade(request, socket, head, ws => {
      wss.emit('connection', ws, request)
    })
  }
})

process.on('unhandledRejection', (e) => {
  console.error(e)
})
