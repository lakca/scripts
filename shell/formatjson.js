let data = '';

process.stdin.setEncoding('utf-8')
.on('data', (buf) => data += buf)
.on('end', () => process.stdout.write(JSON.stringify(JSON.parse(data), null, 2)))
