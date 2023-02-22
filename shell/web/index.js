const Koa = require('koa')
const KoaRouter = require('koa-router')
const serve = require('koa-static')
const url = require('url')
const wss = require('./wss')
const port = process.env.PORT || 8080
const em = require('./em')
const store = require('./store')

const app = new Koa()
const router = new KoaRouter()
app.use(router.routes())
app.use(serve(__dirname))

router.get('/s/search', async ctx => {
  ctx.body = await em.search(ctx.query.q)
})

const server = app.listen(port)
server.on('upgrade', (request, socket, head) => {
  const {pathname} = url.parse(request.url || '')
  if (pathname === '/ws') {
    wss.handleUpgrade(request, socket, head, ws => {
      wss.emit('connection', ws, request)
    })
  }
})
