const fs = require('fs')

const fp = $SWIFT_NOTE_MD

const f = fs.readFileSync(fp).toString()

const reg = /\(https:[^)]*?swift[^)]*?documentation\/the-swift-programming-language\/[^)]+\)/g

const m = f.match(reg)

const rpl = e => {
  e = e.slice(1, -1)
  return `[${new URL(e).hash.slice(1) ||  new URL(e).pathname.split('/').reverse().reduce((v, e) => v || e, '')}]`
}

let r = f.replace(reg, rpl)

let d = m?.map(e => `${rpl(e)}: ${e.slice(1, -1)}`)

const fl = f.split('\n').map(e => e.trim())

d = d?.filter(e => !fl.includes(e.trim()))

if (d?.length) {
  r += (r.endsWith('\n') ? '\n'  : '') + d?.join('\n')
}

fs.writeFileSync(fp, r)
