const fs = require('fs')

module.exports = {
  prompt
}

function * _prompt(question) {
  const fd = fs.openSync('/dev/tty', 'rs')
  console.log(fd)
  const begin = () => process.stdout.write('\x1b[31m')
  const end = () => process.stdout.write('\x1b[0m')
  while (true) {
    process.stdout.write(question)
    begin()
    const buf = Buffer.alloc(1)
    const inputBuf = []
    while (true) {
      if (fs.readSync(fd, buf, 0, 1, null)) {
        if (buf.toString() === '\n') break
        inputBuf.push(...buf)
      }
    }
    end()
    const goon = yield Buffer.from(inputBuf).toString()
    if (!goon) {
      break
    }
  }
  fs.closeSync(fd)
}

function prompt(question, type, cb) {
  question = `\x1b[33m${question}\x1b[0m`
  if (cb) {
    const input = _prompt(question)
    let result = input.next()
    while (!result.done) {
      result = input.next(!!cb(result.value))
    }
  } else {
    return new Promise(function(resolve) {
      const input = _prompt(question + '\x1b[2m(是:y, 否:n, 后续全是:Y, 后续全否:N): \x1b[0m')
      let result = input.next()
      /** @type {{ input: any, all: boolean }} */
      const answer = { input: null, all: false }
      while (!result.done) {
        if (type === 'bool') {
          switch (result.value) {
            case 'y':
              answer.input = true
              break
            case 'Y':
              answer.input = true
              answer.all = true
              break
            case 'n':
              answer.input = false
              break
            case 'N':
              answer.input = false
              answer.all = true
              break
            default:
              result = input.next(true)
              continue
          }
          result = input.next(false)
        }
      }
      resolve(answer)
    })
  }
}
