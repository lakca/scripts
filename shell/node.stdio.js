#!/usr/bin/env node

if (process.argv.includes('-h')) {
  console.log('\033[31mnode pipe\033[0m')
  console.log('pbpaste | node.stdio.js "input.map(e => curl(e))"')
  process.exit(0)
}

const vm = require('vm')
let input = ''
process.stdin.setEncoding('utf-8').on('data', chunk => {
  input += chunk
}).on('end', () => {
  const code = `const input = ${input}; ${process.argv.slice(2).join(' ')}`
  console.log(vm.runInNewContext(code, {
    input,
  }))
})
