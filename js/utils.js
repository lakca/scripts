const util = require('util')

module.exports = {
  colorful,
}

function colorful(str, color) {
  const code = util.inspect.colors[color]
  return `\x1B[${code[0]}m${str}\x1B[${code[1]}m`
}
