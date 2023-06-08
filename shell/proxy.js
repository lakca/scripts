
const fs = require('fs')
const cp = require('child_process')
const httpProxy = require('http-proxy')
const proxy = httpProxy.createProxyServer({})
const http = require('http')

http.createServer(function (req, res) {
  console.log(req)
  req.
  // const protocol = req.protocol
  // const host = req.host
  // proxy.web(req, res, { target: protocol + '://' + host }, (err, res) => {
  // })
}).listen(process.env.PORT || 8978)
