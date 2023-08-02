#!/usr/bin/env node

if (process.argv.includes('-h')) {
  console.log(`
  从stdio读取数据（input），执行js代码
  \x1b[2mpbpaste | node.stdio.js "input.map(e => curl(e))"\x1b[0m
  `)
  process.exit(0)
}

const vm = require('vm')
let input = ''
process.stdin.setEncoding('utf-8').on('data', chunk => {
  input += chunk
}).on('end', () => {
  const code = `const input = ${input}; ${process.argv.slice(2).join(' ')}`
  console.log(vm.runInNewContext(code, {
    input
  }))
})
