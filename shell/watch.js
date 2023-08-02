#!/usr/bin/env node

const cp = require('child_process')
const fs = require('fs')
const util = require('util')
const exec = util.promisify(cp.exec)

function main() {
  process.argv.shift()
  process.argv.shift()
  /** @type {any} */
  const opts = {
    files: [],
    handlers: []
  }
  let arg = null
  while (process.argv.length) {
    arg = process.argv.shift()
    switch (arg) {
      case '-h':
        console.log(`
        \x1b[32mwatch.js\x1b[0m [options] <file> [<file>...]
          -s, --silent     \x1b[2m命令执行错误时不退出监听\x1b[0m
          -r, --recursive  \x1b[2m递归目录\x1b[0m
          -c <cmd>         \x1b[2m命令顺序执行\x1b[0m
          -C <cmd>         \x1b[2m命令并发执行\x1b[0m
        `)
        process.exit(0)
        break
      case '-r':
      case '--recursive':
        opts.recursive = true
        break
      case '-s':
      case '--silent':
        opts.silent = true
        break
      case '-C':
      case '--concurrent': {
        const last = opts.handlers[opts.handlers.length - 1]
        if (last && Array.isArray(last)) {
          last.push(process.argv.shift())
        } else {
          opts.handlers.push([process.argv.shift()])
        }
      } break
      case '-c':
      case '--cmd':
        opts.handlers.push(process.argv.shift())
        break
      default:
        opts.files.push(arg)
    }
  }

  watch(opts)
}

let idle = true
let tail = false
function watch(opts) {
  for (const file of opts.files) {
    fs.watch(file, { recursive: opts.recursive }, async function(type, filename) {
      console.log(`\n\x1b[2m${new Date().toLocaleString()} ${type} ${filename}\x1b[0m`)
      if (idle) {
        if (tail) tail = false
        await run(opts)
        if (tail) {
          idle && await run(opts)
        }
      } else {
        tail = true
      }
    })
  }
}

async function run(opts) {
  idle = false
  for (const handler of opts.handlers) {
    if (Array.isArray(handler)) {
      await Promise.allSettled(handler.map(h => execAsync(h, opts.silent)))
    } else {
      await execAsync(handler, opts.silent)
    }
  }
  idle = true
}

function execAsync(cmd, silent) {
  const r = exec(cmd).then(({ stdout, stderr }) => {
    process.stdout.write(stdout)
    process.stderr.write(stderr)
  })
  if (silent) {
    return r.catch(e => {
      process.stderr.write(e.stderr)
    })
  } else {
    return r
  }
}

if (require.main?.filename === __filename) {
  main()
}
