#! /usr/bin/env node

const crypto = require('crypto')
const http = require('http')
const path = require('path')
const fs = require('fs')
const { colorful } = require('./lib')

function getfd(fd) {
  return fd % 1 === 0 ? +fd : null
}

function hash(str, algo, encoding) {
  return crypto.createHash(algo).update(str).digest(encoding)
}

function hashResp(url, algo, encoding) {
  return new Promise((resolve, reject) => {
    const hashing = crypto.createHash(algo)
    http.get(url)
      .end()
      .on('response', res => {
        res.pipe(hashing)
        res.on('end', () => {
          resolve(hashing.digest(encoding))
        }).on('error', reject)
      })
      .on('error', reject)
  })
}

function hashFile(filename, algo, encoding) {
  return new Promise((resolve, reject) => {
    filename = filename.replace('file://', '')
    const fd = getfd(filename)
    if (!path.isAbsolute(filename)) filename = path.join(process.cwd(), filename)
    const hashing = crypto.createHash(algo)
    const stream = fs.createReadStream(filename, { fd })
    stream.pipe(hashing)
    stream.on('end', () => {
      resolve(hashing.digest(encoding))
    })
    stream.on('error', reject)
  })
}

if (require.main.filename === __filename) {
  const opts = { algo: 'md5', encoding: 'base64' }
  const hashes = crypto.getHashes().map(e => ':' + e)
  const encodings = ['base64', 'hex'].map(e => ':' + e)
  for (const arg of process.argv) {
    if (arg === '-h') {
      console.log(`\n${colorful('计算哈希值', 'red')}，... text [:url] [:file] [:algorithm] [:encoding]
      ${colorful(`
      - :url: text当作url，计算get url返回内容的哈希值
      - :file: text当作文件名，计算对应文件的哈希值
      - :algorithm: ${encodings}
      - :encoding: ${hashes}
      `, 'gray')}
      `)
      process.exit(0)
    }
    if (arg === ':url') opts.url = arg
    else if (arg === ':file') opts.file = arg
    else if (hashes.includes(arg)) opts.algo = arg.slice(1)
    else if (encodings.includes(arg)) opts.encoding = arg.slice(1)
    else opts.text = arg
  }
  if (opts.url) hashResp(opts.text, opts.algo, opts.encoding).then(console.log)
  else if (opts.file) hashFile(opts.text, opts.algo, opts.encoding).then(console.log)
  else if (opts.text) console.log(hash(opts.text, opts.algo, opts.encoding))
}

process.on('unhandledRejection', console.error)
