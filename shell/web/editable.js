const fs = require('fs')
const http = require('http')

const MIME = {
  'html': 'text/html',
  'js': 'text/javascript',
  'json': 'application/json',
}

http.createServer((req, res) => {
  const pathname = req.url
  const method = req.method
  if (pathname) {
    if (method === 'GET') {
      if (!fs.existsSync(pathname)) {
        res.statusCode = 404
        res.end('Not Found')
        return
      }
      const ext = pathname.slice(pathname.lastIndexOf('.') + 1)
      MIME[ext] && res.setHeader('content-type', MIME[ext])
      const rs = fs.createReadStream(pathname)
      rs.on('data', buf => {
        res.write(buf)
      })
      rs.on('end', () => {
        if (ext === 'html') {
          res.write(`<script>
          function upload() {
            return fetch(window.location.href, {
              method: 'POST',
              body: document.documentElement.outerHTML,
            })
          }
          document.body.setAttribute('contenteditable', 'true')
          document.body.addEventListener('input', e => { if (e.data) window._dirty = true })
          document.addEventListener('keydown', e => {
            if (e.key === 's' && e.metaKey) {
              e.preventDefault()
              upload().then(res => {
                if (res.status === 200) {
                  window._dirty = false
                  console.log(new Date().toLocaleTimeString(), 'Saved!')
                }
              })
            }
          })
          window.addEventListener('beforeunload', e => {
            if (window._dirty) {
              e.preventDefault()
              e.returnValue = ''
              window.confirm('是否保存数据？') &&
              upload().then(res => {
                if (res.status === 200) {
                  window.confirm('数据上传完成，即将关闭当前页面') && window.close()
                }
              })
            }
          })
          </script>`)
        }
        res.end()
      })
    } else if (method === 'POST') {
      // const filename = pathname.replace(/\.[^\.]+$/, e => '.revision' + e)
      const filename = pathname
      const ws = fs.createWriteStream(filename)
      req.on('data', buf => {
        ws.write(buf)
      }).on('end', () => {
        res.end()
      })
    }
  }
  res.statusCode = 200
}).listen(process.env.PORT || 8970)
