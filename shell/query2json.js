let data = ''

process.stdin.setEncoding('utf-8')
  .on('data', (buf) => { data += buf })
  .on('end', () => {
    const obj = Object.fromEntries(new URLSearchParams(decodeURI(data)))
    obj.condition = JSON.parse(obj.condition)
    process.stdout.write('encodeURI(JSON.stringify(' + JSON.stringify(obj, null, 2) + '))')
  })
