#!/usr/bin/env node
const fs = require('fs')
const fsp = require('fs').promises
const os = require('os')
const path = require('path')
const readline = require('readline')

process.argv.shift()
process.argv.shift()
const opts = {}

for (const arg of process.argv) {
  if (['-r', '--recursive'].includes(arg)) opts.recursive = true
  else if (['-a', '--append'].includes(arg)) opts.append = true
  else if (['-h', '--help'].includes(arg)) {
    console.log(`
    \x1b[2m将文件同步到指定位置\x1b[0m
    sync.js <src> <dest> [--append|-a] [--recursive|-r]

    -a, --append    \x1b[2m- 执行文件追加，默认为完全替换\x1b[0m
    -r, --recursive \x1b[2m- 递归目录\x1b[0m
    `)
    process.exit(0)
  } else if (!opts.src) opts.src = arg
  else if (!opts.dest) opts.dest = arg
}

if (!opts.src) {
  console.log('\x1b[31m缺少源文件\x1b[0m')
  process.exit(1)
}

if (!path.isAbsolute(opts.src)) opts.src = path.join(process.cwd(), opts.src)

if (!opts.dest) opts.dest = path.join(process.cwd(), path.basename(opts.src))

opts.srcIsDir = fs.statSync(opts.src).isDirectory()
opts.srcRoot = opts.srcIsDir ? opts.src : path.dirname(opts.src)
opts.destIsDir = fs.statSync(opts.dest).isDirectory()
opts.destRoot = opts.destIsDir ? opts.dest : path.dirname(opts.dest)

console.log(opts)

let sync = false
fs.watch(opts.src, { recursive: opts.recursive }, async function(type, filename) {
  if (sync) return console.log('waiting')
  console.log('sync...')
  sync = true
  const dest = opts.destIsDir ? path.join(opts.destRoot, filename) : opts.dest
  if (opts.append) {
    await append(dest, fs.readFileSync(path.join(opts.srcRoot, filename)))
    sync = false
    console.log('\x1b[32mappended!\x1b[0m', new Date().toLocaleString())
  } else {
    fs.createReadStream(path.join(opts.srcRoot, filename))
      .pipe(fs.createWriteStream(dest).on('close', () => {
        sync = false
        console.log('\x1b[32msynced!\x1b[0m', new Date().toLocaleString())
      }))
  }
})

async function append(realpath, content, options = {}) {
  const identity = options.identity || 'SYNC'
  const startIndicator = `/*---START:${identity}---*/`
  const endIndicator = `/*---END:${identity}---*/`
  await removeBetween(realpath, new RegExp('^\\s*' + escapeRegExp(startIndicator) + '\\s*$'), new RegExp('^\\s*' + escapeRegExp(endIndicator) + '\\s*$'))
  const fd = fs.openSync(realpath, 'a+')
  ensureNewline(fd)
  fs.appendFileSync(fd, `${startIndicator}\n` + content)
  ensureNewline(fd)
  fs.appendFileSync(fd, `${endIndicator}\n`)
  fs.closeSync(fd)
}

async function removeBetween(filename, startPattern, endPattern) {
  return new Promise((resolve, reject) => {
    const rl = readline.createInterface({
      input: fs.createReadStream(filename)
    })

    const lines = []
    let ignoring = 0
    rl.on('line', function(line) {
      if (startPattern.test(line)) {
        if (ignoring < 0) ignoring = 0
        ignoring += 1
      } else if (endPattern.test(line)) {
        ignoring -= 1
      } else if (ignoring < 1) {
        lines.push(line)
      }
    })

    rl.on('close', function() {
      setTimeout(() => {
        fs.writeFileSync(filename, lines.join(os.EOL))
        resolve(null)
      }, 0)
    })
  })
}

function ensureNewline(pathOrFileDescriptor) {
  const is_fd = typeof pathOrFileDescriptor === 'number'
  const fd = is_fd ? pathOrFileDescriptor : fs.openSync(pathOrFileDescriptor, 'a+')
  const size = fs.fstatSync(fd).size
  const length = 1
  const buffer = Buffer.alloc(length)
  const position = size - length
  fs.readSync(fd, buffer, 0, length, position)
  buffer.toString() === '\n' || fs.writeSync(fd, '\n', size)
  is_fd || fs.closeSync(fd)
}

function escapeRegExp(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') // $& means the whole matched string
}
