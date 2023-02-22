const sp = require('superagent')
const iconv = require('iconv-lite')

function getQuote(code) {
  code = Array.isArray(code) ? code.join(',') : code
  if (!code) return Promise.resolve([])
  return new Promise((resolve, reject) => {
    sp.get('https://hq.sinajs.cn/list=' + code)
    .set('Referer', 'http://finance.sina.com.cn/')
    .pipe(iconv.decodeStream('gb18030'))
    .collect((err, body) => {
      if (err) reject(err)
      const data = body.trim().split('\n').map(line => {
        const symbol = line.split('=')[0].split('_')[2]
        const values = line.split('"')[1].split(',')
        // ['名称', '开盘价', '收盘价', '当前价', '最高价', '最低价', '买一价', '卖一价', '成交量', '成交额', '买一量', '买一价', '买二量', '买二价', '买三量', '买三价', '买四量', '买四价', '买五量', '买五价', '买一量', '卖一价', '卖二量', '卖二价', '卖三量', '卖三价', '卖四量', '卖四价', '卖五量', '卖五价', '日期', '时间']
        return {
          symbol,
          name: values[0],
          open: Number(values[1]),
          close: Number(values[2]),
          price: Number(values[3]),
          high: Number(values[4]),
          low: Number(values[5]),
          b1: Number(values[6]),
          s1: Number(values[7]),
          volume: Number(values[8]),
          amount: Number(values[9]),
          buy: [
            { v: Number(values[10]), a: Number(values[11]) },
            { v: Number(values[12]), a: Number(values[13]) },
            { v: Number(values[14]), a: Number(values[15]) },
            { v: Number(values[16]), a: Number(values[17]) },
            { v: Number(values[18]), a: Number(values[19]) },
          ],
          sell: [
            { v: Number(values[20]), a: Number(values[21]) },
            { v: Number(values[22]), a: Number(values[23]) },
            { v: Number(values[24]), a: Number(values[25]) },
            { v: Number(values[26]), a: Number(values[27]) },
            { v: Number(values[28]), a: Number(values[29]) },
          ],
          date: values[30],
          time: values[31],
        }
      })
      resolve(data)
    })
  })
}

function search(q) {
  return new Promise((resolve, reject) => {
    sp.get(`https://suggest3.sinajs.cn/suggest/type=&key=${q}&name=suggestdata_${Date.now()}`)
    .set('Referer', 'http://finance.sina.com.cn/')
    .pipe(iconv.decodeStream('gb18030'))
    .collect((err, body) => {
      const lines = body.split('"')[1].split(';').map(e => e.split(','))
      const data = lines.map(line => {
        return {
          name: line[0],
          code: line[2],
          symbol: line[3],
        }
      })
      if (err) reject(err)
      else resolve(data)
    })
  })
}

module.exports = {
  getQuote,
  search,
}
