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

function window_user_defined_properties() {
  // create an iframe and append to body to load a clean window object
  const iframe = document.createElement('iframe')
  iframe.style.display = 'none'
  document.body.appendChild(iframe)
  // get the current list of properties on window
  const currentWindow = Object.getOwnPropertyNames(window)
  // filter the list against the properties that exist in the clean window
  const results = currentWindow.filter(function(prop) {
    // @ts-ignore
    return !iframe.contentWindow.hasOwnProperty(prop)
  })
  // log an array of properties that are different
  document.body.removeChild(iframe)
  return {
    w: Object.fromEntries(results.map(n => [n, window[n]])),
    k: results
  }
}
