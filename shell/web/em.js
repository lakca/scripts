const sp = require('superagent')
const iconv = require('iconv-lite')
const utils = require('./utils')
const vm = require('vm')

function is_trading(force) {
  const date = new Date()
  const hour = date.getHours()
  const minute = date.getMinutes()
  return force || (hour > 9 && hour < 11) || (hour > 12 && hour < 15) || (hour === 9 && minute > 14) || (hour === 11 && minute < 32) || (hour === 15 && minute < 2)
}

function get_symbol_from_code(code) {
  return (['6'].includes(code[0]) ? 'sh' : ['0', '3'].includes(code[0]) ? 'sz' : ['8', '4'].includes(code[0]) ? 'bj' : '') + code
}

/**
 * @template {string[]} K
 * @template {{kv?: boolean, kvi?: number[], vk?: boolean, keys?: K, key?: K[keyof K], sep?: string|RegExp, preserve?: boolean}} T
 * @param {string} text
 * @param {T} opts
 * @return {T['kv'] extends true ? Record<string, string> : T['vk'] extends true ? Record<string, string> : T['keys'] extends string[] ? T['key'] extends T['keys'][keyof T['keys']] ? Record<string, Record<string, string>> : Record<string, string>[] : undefined}
 */
function get_obj_from_text(text, opts) {
  const items = (opts.preserve ? text : text.trim()).split(opts.sep || /\s+/)
  const dict = {}
  const list = []
  if (opts.vk) {
    for (let i = 0; i < items.length; i += 2) {
      dict[items[i + 1]] = items[i]
    }
    return dict
  } else if (opts.kv) {
    const idx = opts.kvi || [0, 1, 2]
    const step = idx[2] || 2
    const [k, v] = idx
    for (let i = 0; i < items.length; i += step) {
      dict[items[i + k]] = items[i + v]
    }
    return dict
  } else if (opts.keys) {
    if (opts.key) {
      for (let i = 0; i < items.length; i += opts.keys.length) {
        const obj = Object.fromEntries(opts.keys.map((k, j) => {
          return [k, items[i + j]]
        }))
        dict[obj[opts.key]] = obj
      }
      return dict
    } else {
      for (let i = 0; i < items.length; i += opts.keys.length) {
        list.push(Object.fromEntries(opts.keys.map((k, j) => {
          return [k, items[i + j]]
        })))
      }
      return list
    }
  }
  return dict
}

/**
 * @template {sp.SuperAgentRequest} T
 * @param {T} req
 * @param {string} jsonp
 * @param {string} [jsonpKey]
 * @returns {T}
 */
function em_jsonp(req, jsonp, jsonpKey) {
  if (jsonpKey) req.query({ [jsonpKey]: jsonp })
  return req
    .buffer(true)
    .parse(function (res, cb) {
      res.text = ''
      res.setEncoding('utf8')
      res.on('data', (chunk) => {
        res.text += chunk
      })
      res.on('end', () => {
        let body;
        let error;
        try {
          // @ts-ignore
          body = JSON.parse(res.text.match(/^[^(]*\((.*)\)[^)]*$/)[1])
        } catch (err) {
          error = err;
          error.rawResponse = res.text || null;
          error.statusCode = res.statusCode;
        } finally {
          cb(error, body);
        }
      })
    })
}

function get_quote(symbol) {
  symbol = Array.isArray(symbol) ? symbol.join(',') : symbol
  if (!symbol) return Promise.resolve([])
  return new Promise((resolve, reject) => {
    sp.get('https://hq.sinajs.cn/list=' + symbol)
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

const CHANGE_TYPES = `
火箭发射 8201 快速反弹 8202 大笔买入 8193 封涨停板 4 打开跌停板 32 有大买盘 64 竞价上涨 8207 高开5日线 8209 向上缺口 8211 60日新高 8213 60日大幅上涨 8215
加速下跌 8204 高台跳水 8203 大笔卖出 8194 封跌停板 8 打开涨停板 16 有大卖盘 128 竞价下跌 8208 低开5日线 8210 向下缺口 8212 60日新低 8214 60日大幅下跌 8216
`
const CHANGE_TYPES_VK_DICT = get_obj_from_text(CHANGE_TYPES, { vk: true })
const UP_CHANGE_TYPES = [8201, 8202, 8193, 4, 32, 64, 8207, 5, 8209, 8211, 60, 8213, 60, 8215]
const DOWN_CHANGE_TYPES = [8204, 8203, 8194, 8, 16, 128, 8208, 5, 8210, 8212, 60, 8214, 60, 8216]
const ALL_CHANGE_TYPES = UP_CHANGE_TYPES.concat(DOWN_CHANGE_TYPES)

const EM_ORDERS = `正序 0 倒序 1`
const EM_ORDER_DICT = get_obj_from_text(EM_ORDERS, { kv: true })

const EM_FIELDS = `
f2   price        最新价
f3   ratio        涨跌幅
f4   change       涨跌额
f5   volume       成交量
f6   amount       成交额
f7   AMP          振幅
f8   TR           换手率
f9   PED          动态市盈率
f10  QRR          量比
f11  ratio5       5分钟涨跌幅
f12  code         证券代码
f13  marketCode   市场编号
f14  name         证券名称
f15  high         最高价
f16  low          最低价
f17  open         开盘价
f18  close        昨天收盘价
f20  MV           总市值
f21  MVF          流通市值
f22  speed        涨速
f23  PB           市净率
f24  ratio60      60日涨跌幅
f25  ratioYear    年初至今涨跌幅
f26  IPO          上市时间
f62  inflow       主力净流入
f115 PE           市盈率
f104 upCount      上涨家数
f105 downCount    下跌家数
f106 sameCount    平盘家数
f128 leading 领涨股票
f136 leadingRatio 领涨股票涨跌幅
f140 leadingCode 领涨股票代码
f141 leadingMarketCode 领涨股票市场代码
`
// f28  昨结
// f30  现量
// f31 priceBuy 买入价
// f32 priceSell 卖出价
// f108 holding 持仓量
// f163 日增
// f211 volumeBuy 买量
// f212 volumeSell 卖量
const EM_FIELD_DICT = get_obj_from_text(EM_FIELDS, { kv: true, kvi: [2, 0, 3] })
const EM_FIELD_FK_DICT = get_obj_from_text(EM_FIELDS, { kv: true, kvi: [1, 0, 3] })
const EM_MARKET_TYPE_DICT = {
  'A股': 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:0+t:81+s:2048',
  '上证A股': 'm:1+t:2,m:1+t:23',
  '深证A股': 'm:0+t:6,m:0+t:80',
  '北证A股': 'm:0+t:81+s:2048',
  '新股': 'm:0+f:8,m:1+f:8',
  '中小板': 'm:0+t:13',
  '创业板': 'm:0+t:80',
  '创业板-注册制': 'm:0+t:80+s:131072',
  '创业板-核准制': 'm:0+t:80+s:!131072',
  '科创板': 'm:1+t:23',
  '北向通': 'b:BK0707,b:BK0804',
  '北向通-沪股通': 'b:BK0707',
  '北向通-深股通': 'b:BK0804',
  '风险警示板': 'm:0+f:4,m:1+f:4',
  '风险警示板-上证': 'm:1+f:4',
  '风险警示板-深证': 'm:0+f:4',
  '风险警示板-科创板': 'm:1+t:23+f:4',
  '风险警示板-创业板': 'm:0+t:80+f:4',
  '两网及退市': 'm:0+s:3',
  '新三板': 'm:0+t:81+s:!2052',
  '新三板-精选层': 'm:0+t:81+s:2048',
  '新三板-创新层': 'm:0+s:512',
  '新三板-基础层': 'm:0+s:256',
  // http'://quote.eastmoney.com/center/hszs.html
  '指数-中证系列指数': 'm:2',
  '指数-指数成分': 'm:1+s:3,m:0+t:5',
  '指数-深证系列指数': 'm:0+t:5',
  '指数-上证系列指数': 'm:1+s:2',
  // http'://quote.eastmoney.com/center/boardlist.html
  '板块-概念板块': 'm:90+t:3+f:!50',
  '板块-地域板块': 'm:90+t:1+f:!50',
  '板块-行业板块': 'm:90+t:2+f:!50',

  '港股': 'm:128+t:3,m:128+t:4,m:128+t:1,m:128+t:2',
  '港股-主板': 'm:128+t:3',
  '港股-创业板': 'm:128+t:4',
  '港股-知名港股': 'b:DLMK0106',
  '港股-港股通': 'b:DLMK0146,b:DLMK0144',
  '港股-蓝筹股': 'b:MK0104',
  '港股-红筹股': 'b:MK0102',
  '港股-红筹指数成分股': 'b:MK0111',
  '港股-国企股': 'b:MK0103',
  '港股-国企指数成分股': 'b:MK0112',
  '港股-港股通成份股': 'b:MK0146,b:MK0144',
  '港股-ADR': 'm:116+s:1',
  '港股-香港指数': 'm:124,m:125,m:305',
  '港股-香港涡轮': 'm:116+t:6',
  '港股-港股通ETF': 'b:MK0837,b:MK0838',
  '港股-港股通ETF-沪': 'b:MK0838',
  '港股-港股通ETF-深': 'b:MK0837',
  '港股-港股牛熊证': 'm:116+t:5',

  '美股': 'm:105,m:106,m:107',
  '美股-中国概念股': 'b:MK0201',
  '美股-美股指数': 'i:100.NDX,i:100.DJIA,i:100.SPX',
  '美股-粉单市场': 'm:153',
  '美股-知名美股': 'b:MK0001',
  '美股-知名美股-科技类': 'b:MK0216',
  '美股-知名美股-金融类': 'b:MK0217',
  '美股-知名美股-医药食品类': 'b:MK0218',
  '美股-知名美股-媒体类': 'b:MK0220',
  '美股-知名美股-汽车能源类': 'b:MK0219',
  '美股-知名美股-制造零售类': 'b:MK0221',
  '美股-互联网中国': 'b:MK0202',

  '全球指数-亚洲股市': 'i:1.000001,i:0.399001,i:0.399005,i:0.399006,i:1.000300,i:100.HSI,i:100.HSCEI,i:124.HSCCI,i:100.TWII,i:100.N225,i:100.KOSPI200,i:100.KS11,i:100.STI,i:100.SENSEX,i:100.KLSE,i:100.SET,i:100.PSI,i:100.KSE100,i:100.VNINDEX,i:100.JKSE,i:100.CSEALL',
  '全球指数-美洲股市': 'i:100.DJIA,i:100.SPX,i:100.NDX,i:100.TSX,i:100.BVSP,i:100.MXX',
  '全球指数-欧洲股市': 'i:100.SX5E,i:100.FTSE,i:100.MCX,i:100.AXX,i:100.FCHI,i:100.GDAXI,i:100.RTS,i:100.IBEX,i:100.PSI20,i:100.OMXC20,i:100.BFX,i:100.AEX,i:100.WIG,i:100.OMXSPI,i:100.SSMI,i:100.HEX,i:100.OSEBX,i:100.ATX,i:100.MIB,i:100.ASE,i:100.ICEXI,i:100.PX,i:100.ISEQ',
  '全球指数-澳洲股市': 'i:100.AS51,i:100.AORD,i:100.NZ50',
  '全球指数-其他指数': 'i:100.UDI,i:100.BDI,i:100.CRB',

  '期货-中金所': 'i:100.UDI,i:100.BDI,i:100.CRB',
  '国债': 'm:8+s:16+f:!8192',
}

function get_highlight_desc(type, value) {
  let t, text
  switch (type) {
    case 8204:
    case 8201:
    case 8203:
    case 8202:
    case 8216:
    case 8215:
    case 8210:
    case 8209:
    case 8208:
    case 8207:
    case 8212:
    case 8211:
      t = 'ratio'
      text = (value * 100).toFixed(2) + '%'
      break
    case 8193:
    case 8194:
    case 128:
    case 64:
      t = 'volume'
      text = ((value / 100) >> 0) + '手'
      break
    case 8214:
    case 8213:
    case 16:
    case 32:
    case 8:
    case 4:
      t = 'price'
      text = +value + ''
      break
    default:
  }
  return { valueType: t, text }
}

function get_highlight(types, opts) {
  const params = utils.getRequestParams(opts, { size: 36 })
  const jsonp = `jQuery35109544115898056558_${Date.now()}`
  return em_jsonp(sp.get(`http://push2ex.eastmoney.com/getAllStockChanges?type=${types.join(',')}`), jsonp, 'cb')
    .query({
      ut: '7eea3edcaed734bea9cbfc24409ed989',
      pageindex: params.page - 1,
      pagesize: params.size,
      dpt: 'wzchanges',
      _: params._,
    }).then(res => {
      return res.body?.data?.allstock.map(e => {
        const [value, price, other] = e.i.split(',')
        const [_, hour, minute, second] = `${e.tm}`.match(/(\d+)(\d{2})(\d{2})/) || []
        return {
          name: e.n,
          code: e.c,
          symbol: get_symbol_from_code(e.c),
          type: CHANGE_TYPES_VK_DICT[e.t],
          dir: UP_CHANGE_TYPES.includes(e.t) ? 1 : -1,
          time: `${+hour > 9 ? hour : '0' + hour}:${minute}:${second}`,
          price: +price,
          value: +value,
          ...get_highlight_desc(e.t, value),
          other,
        }
      })
    })
}

function get_highlight_bk(types, opts) {
  const params = utils.getRequestParams(opts, { size: 36 })
  const jsonp = `jQuery35109544115898056558_${Date.now()}`
  return em_jsonp(sp.get(`http://push2ex.eastmoney.com/getAllBKChanges?type=${types.join(',')}`), jsonp, 'cb')
    .query({
      ut: '7eea3edcaed734bea9cbfc24409ed989',
      pageindex: params.page - 1,
      pagesize: params.size,
      dpt: 'wzchanges',
      _: params._,
    }).then(res => {
      return res.body?.data?.allbk.map(e => {
        const ratio = e.u / 100
        const inflow = e.zjl // 净流入
        const times = e.ct // 异动数
        return {
          name: e.n,
          code: e.c,
          symbol: get_symbol_from_code(e.c),
          ratio,
          inflow,
          times,
          detail: e.ydl.map(e => {
            return [CHANGE_TYPES_VK_DICT[e.t], e.ct]
          }),
          main: {
            code: e.ms.c,
            symbol: get_symbol_from_code(e.ms.c),
            name: e.ms.n,
            type: CHANGE_TYPES_VK_DICT[e.ms.t],
          }
        }
      })
    })
}

function get_rank(opts) {
  const params = utils.getRequestParams(opts, {
    size: 30,
    market: 'A股',
    sortField: '涨跌幅',
    order: '倒序',
  })
  const jsonp = `jQuery112404812956954993921_${Date.now()}`
  return em_jsonp(sp.get(`http://push2.eastmoney.com/api/qt/clist/get`), jsonp, 'cb')
    .query({
      pn: params.page,
      pz: params.size,
      po: EM_FIELD_DICT[params.sortField],
      np: 1,
      ut: 'bd1d9ddb04089700cf9c27f6f7426281',
      fltt: 2,
      invt: 2,
      wbp2u: '9569356073124232|0|0|0|web',
      fid: EM_ORDER_DICT[params.order],
      fs: EM_MARKET_TYPE_DICT[params.market],
      fields: 'f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f12,f13,f14,f15,f16,f17,f18,f20,f21,f23,f24,f25,f22,f11,f62,f128,f136,f115,f152',
      _: params._,
    }).then(res => {
      const fields = [
        'name',  'code',
        'price', 'close',
        'ratio', 'ratio5',
        'speed', 'TR',
        'AMP',   'QRR',
        'PED',   'MV',
        'MVF'
      ]
      return res.body?.data?.diff.map(e => {
        const obj = Object.fromEntries(fields.map(f => ([f, e[EM_FIELD_FK_DICT[f]]])))
        obj.symbol = get_symbol_from_code(obj.code)
        return obj
      })
    })
}

function get_rank_concept(opts) {
  const params = utils.getRequestParams(opts, {
    size: 30,
    sortField: '涨跌幅',
    order: '倒序',
    market: 'A股',
  })
  const jsonp = `jQuery3510780095733559149_${Date.now()}`
  return em_jsonp(sp.get('https://push2.eastmoney.com/api/qt/clist/get'), jsonp, 'cb')
    .query({
      pn: params.page,
      pz: params.size,
      po: EM_ORDER_DICT[params.order],
      np: 1,
      ut: 'fa5fd1943c7b386f172d6893dbfba10b',
      fltt: 2,
      invt: 2,
      fid: EM_FIELD_DICT[params.sortField],
      fs: EM_MARKET_TYPE_DICT[params.market],
      fields: 'f1,f2,f3,f4,f14,f12,f13,f62,f128,f136,f140,f141',
      _: params._,
    }).then(res => {
      const fields = [
        'price',
        'ratio',
        'change',
        'code',
        'marketCode',
        'name',
        'inflow',
        'leading',
        'leadingRatio',
        'leadingCode',
        'leadingMarketCode'
      ]
      return res.body?.data?.diff.map(e => {
        const obj = Object.fromEntries(fields.map(f => [EM_FIELD_FK_DICT[f], e[f]]))
        obj.symbol = get_symbol_from_code(obj.code)
        obj.leadingSymbol = get_symbol_from_code(obj.leadingCode)
        return obj
      })
    })
}

module.exports = {
  is_trading,
  get_quote,
  search,
  get_highlight,
  get_highlight_bk,
  get_rank,
  get_rank_concept,
  ALL_CHANGE_TYPES,
  UP_CHANGE_TYPES,
  DOWN_CHANGE_TYPES,
}
