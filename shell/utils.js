module.exports = { sleep, countdown }

function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 10 ** 3))
}

function countdown(seconds) {
  return new Promise((resolve) => {
    const t = setInterval(() => {
      seconds--
      process.stdout.write('\x1b[1K\r\x1b[31m' + seconds + '\x1b[0m')
      if (seconds < 1) {
        process.stdout.write('\x1b[1K\r')
        clearInterval(t)
        resolve(null)
      }
    }, 1000)
  })
}
