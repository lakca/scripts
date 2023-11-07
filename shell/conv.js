#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const crypto = require('crypto')
const { prompt } = require('./lib')

// bytes of file (absolute path) name <= 256 ** 2, or length of file (absolute path) name string (4 bytes chars) <= 16384
const FILENAME_BYTES = 2
const SUFFIX = process.env.SUFFIX || '.dtaa'
const SALT = process.env.SALT || 'retyui'

function intToBuffer(int) {
  let s = int.toString(16)
  if (s.length % 2 === 1) {
    s = '0' + s
  }
  const arr = []
  for (let i = 0; i < s.length; i += 2) {
    arr.push(parseInt(s[i] + s[i + 1], 16))
  }
  return Buffer.from(arr)
}

/**
 * @param {Buffer} buffer
 * @param {number} bytes
 */
function alignIntBuffer(buffer, bytes) {
  const arr = Array.from(buffer)
  while (arr.length < bytes) {
    arr.unshift(0)
  }
  return Buffer.from(arr)
}

function hash(text) {
  return crypto.createHmac('md5', SALT).update(text).digest('hex')
}

/**
 *  Buffer: [2 bytes nameLengthBuffer] [nameBuffer] [fileBuffer]
 *  @param {string} filename - absolute path
 */
async function conv(filename, opts) {
  const { dest, remove } = opts
  if (!path.isAbsolute(filename)) {
    filename = path.join(process.cwd(), filename)
  }
  if (filename.endsWith(SUFFIX) || !fs.existsSync(filename) || !fs.statSync(filename).isFile()) {
    console.log(`\x1b[2m跳过（目录/文件后缀不符合/文件不存在） ${filename}\x1b[0m`)
    return
  }
  const nameBuffer = Buffer.from(filename, 'utf-8')
  const newfilename = hash(nameBuffer) + SUFFIX
  const nameLengthBuffer = intToBuffer(nameBuffer.length)
  const alignedNameLengthBuffer = alignIntBuffer(nameLengthBuffer, FILENAME_BYTES)
  const metaBuffer = Buffer.concat([alignedNameLengthBuffer, nameBuffer])
  const fileBuffer = fs.readFileSync(filename).map(byte => byte + 1)
  const buffer = Buffer.concat([metaBuffer, fileBuffer])
  const realpath = path.join(dest ? path.isAbsolute(dest) ? dest : path.join(process.cwd(), dest) : process.cwd(), newfilename)
  if (fs.existsSync(realpath)) {
    const result = arguments.callee.result || await prompt(`${realpath} 已有同名文件存在，是否替换？`, 'bool')
    if (!result.value) {
      console.log(`\x1b[2m跳过 ${realpath}!\x1b[0m`)
      if (result.all) {
        arguments.callee.result = result
      }
      return
    }
  }
  fs.writeFileSync(realpath, buffer)
  console.log(`\x1b[31m原始文件位于:\x1b[0m \x1b[2m${filename}\x1b[0m \x1b[31m 新文件位于:\x1b[0m \x1b[2m${realpath}\x1b[0m`)
  if (remove) {
    fs.unlinkSync(filename)
  }
}

async function rconv(filename, opts) {
  const { dest, remove } = opts
  if (!path.isAbsolute(filename)) {
    filename = path.join(process.cwd(), filename)
  }
  if (!filename.endsWith(SUFFIX) || !fs.existsSync(filename) || !fs.statSync(filename).isFile()) {
    console.log(`\x1b[2m跳过（目录/文件后缀不符合/文件不存在） ${filename}\x1b[0m`)
    return
  }
  if (!filename.endsWith(SUFFIX)) return
  const buffer = fs.readFileSync(filename)
  const nameBytesLength = parseInt(buffer.slice(0, FILENAME_BYTES).join(''))
  const orignanlFilename = buffer.slice(FILENAME_BYTES, nameBytesLength + FILENAME_BYTES).toString('utf-8')
  const realpath = dest ? path.join(path.isAbsolute(dest) ? dest : path.join(process.cwd(), dest), path.basename(orignanlFilename)) : orignanlFilename
  if (fs.existsSync(realpath)) {
    const result = arguments.callee.result || await prompt(`${realpath} 已有同名文件存在，是否替换？`, 'bool')
    if (!result.value) {
      console.log(`\x1b[2m跳过 ${realpath}!\x1b[0m`)
      if (result.all) {
        arguments.callee.result = result
      }
      return
    }
  }
  fs.writeFileSync(realpath, buffer.slice(nameBytesLength + FILENAME_BYTES).map(byte => byte - 1))
  console.log(`\x1b[31m原始文件位于:\x1b[0m \x1b[2m${orignanlFilename}\x1b[0m \x1b[31m 新文件位于:\x1b[0m \x1b[2m${realpath}\x1b[0m`)
  if (remove) {
    fs.unlinkSync(filename)
  }
}

async function run(files, opts, reverse) {
  for (const file of files) {
    await (reverse ? rconv(file, opts) : conv(file, opts))
  }
}

if (require.main && require.main.filename === __filename) {
  process.argv.shift()
  process.argv.shift()
  if (process.argv.includes('-h') || process.argv.includes('--help')) {
    console.log(`
    \x1b[31mSimple encryption (conversion) for file.\x1b[0m

    Args:

    \x1b[31m-r\x1b[0m               \x1b[2m- revert conv.\x1b[0m
    \x1b[31m-u\x1b[0m               \x1b[2m- delete source file.\x1b[0m
    \x1b[31m-d\x1b[0m <dest_folder> \x1b[2m- folder where generated files save to.\x1b[0m
    \x1b[31mfiles\x1b[0m            \x1b[2m- read from stdin (line by line) or rest arguments.\x1b[0m

    \x1b[31m-h, --help\x1b[0m       \x1b[2m- show this help message.\x1b[0m

    Envs:

    \x1b[31mSUFFIX\x1b[0m           \x1b[2m- extensions of encrypted files, default is \x1b[32m${SUFFIX}\x1b[0m
    \x1b[31mSALT\x1b[0m             \x1b[2m- hash salt for name of encrypted files, default is \x1b[32m${SALT}\x1b[0m
    \x1b[31mNAME_BYTES\x1b[0m       \x1b[2m- max bytes of raw file absolute path name, default is \x1b[32m${FILENAME_BYTES}\x1b[0m\x1b[2m,
                       that's to say number of characters (as per 4 bytes) in abs name is <= 256 ** 2 / 4, i.e 16384\x1b[0m

    Example:

    \x1b[2mls -1 | conv.js\x1b[0m
    \x1b[2mls *${SUFFIX} -1 | conv.js -r\x1b[0m
    `)
    process.exit(0)
  }

  const opts = {}
  const files = []
  let reverse = false
  while (process.argv.length) {
    if (process.argv[0] === '-r') {
      reverse = true
    } else if (process.argv[0] === '-u') {
      opts.remove = process.argv[0]
    } else if (process.argv[0] === '-d') {
      process.argv.shift()
      opts.dest = process.argv[0]
    } else {
      files.push(process.argv[0])
    }
    process.argv.shift()
  }
  run(files, opts, reverse)
  if (!process.stdin.isTTY) {
    let pipe = ''
    process.stdin
      .setEncoding('utf-8')
      .once('data', s => {
        pipe += s
      })
      .once('end', () => {
        const files = pipe.split(/\r?\n/).filter(v => v)
        run(files, opts, reverse)
      })
  }
}
