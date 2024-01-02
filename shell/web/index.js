const https = require('https')
const fs = require('fs')
const fsp = require('fs').promises
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

async function ensureFolder(filename, isFolder) {
  const dir = isFolder ? filename : path.dirname(filename)
  return fsp.mkdir(dir, { recursive: true })
}

const app = new Koa()
const router = new KoaRouter()
app.use(koaBody({
  jsonLimit: '1kb',
  multipart: true
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
router.post('/upload', async ctx => {
  const dest = ctx.request.body.dest
  const overwritten = ctx.request.body.overwritten
  const files = ctx.request.files
  if (!dest) {
    ctx.status = 400
    ctx.body = '未指定存储目录。'
    return
  }
  try {
    await fsp.access(dest, fsp.constants.F_OK | fsp.constants.W_OK)
  } catch (e) {
    ctx.body = '给定目录不存在或无写入权限。'
    ctx.status = 400
    return
  }
  const destStat = await fsp.stat(dest)
  if (!destStat.isDirectory()) {
    ctx.body = '存储的目标位置不是目录。'
    ctx.status = 400
    return
  }
  if (!files) {
    ctx.body = '未上传文件。'
    ctx.status = 400
    return
  }
  const skipped = []
  for (const relativePath of Object.keys(files)) {
    const file = files[relativePath]
    // @ts-ignore
    const srcPath = file.filepath
    const filepath = path.join(dest, relativePath)
    await ensureFolder(filepath)
    if (fs.existsSync(filepath)) {
      if (!overwritten) {
        await fsp.unlink(srcPath)
        skipped.push(relativePath)
        continue
      }
    }
    await fsp.copyFile(srcPath, filepath)
    await fsp.unlink(srcPath)
  }
  ctx.body = { skipped }
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
