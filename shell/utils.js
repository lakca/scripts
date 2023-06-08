module.exports = { sleep, countdown }

function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 10 ** 3))
}

function countdown(seconds) {
  return new Promise((resolve) => {
    const t = setInterval(() => {
      seconds--
      process.stdout.write('\033[1K\r\033[31m' + seconds + '\033[0m')
      if (seconds < 1) {
        process.stdout.write('\033[1K\r')
        clearInterval(t)
        resolve()
      }
    }, 1000)
  })
}
