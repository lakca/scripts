const WebSocket = require('ws')
const store = require('./store')
const em = require('./em')

const wss = new WebSocket.WebSocketServer({ noServer: true })

module.exports = wss

wss.on('connection', ws => {
  ws.on('message', function(msg) {
    const { type, action, data } = JSON.parse(msg.toString())
    if (type === 'begin') {
      store.scope('ws::client').key(action).add(this)
      action === 'quote' && data && data.symbol && store.tag('symbol').add(...data.symbol)
    } else if (type === 'end') {
      store.scope('ws::client').key(action).delete(this)
      action === 'quote' && data && data.symbol && store.tag('symbol').delete(...data.symbol)
    }
  })
  ws.on('close', function() {
    const actions = store.scope('ws::client').records.filter(e => e.tag == null).map(e => e.key)
    for (const action of actions) {
      store.scope('ws::client').key(action).delete(this)
    }
  })
})

function polling(options, fn) {
  const id = Date.now()
  if (typeof options === 'number') options = { interval: options }
  const data = { options, fn }
  let t = null
  function handler() {
    t = setTimeout(async () => {
      const r = data.fn(id)
      if (data.options.wait && r.then) {
        await r
      }
      t !== null && handler()
    }, data.options.interval)
  }
  if (options.immediate) {
    const r = fn()
    data.options.wait && r.then && r.then(handler) || handler()
  }
  return (updateOptions) => {
    if (updateOptions) {
      Object.assign(data.options, updateOptions)
    } else {
      clearTimeout(t)
      t = null
    }
  }
}

function makePolling(name, opts, callback, check) {
  const stop = store.scope('polling').key(name).value
  if (stop) {
    stop()
    store.scope('polling').key(name).unset()
  } else {
    const newStop = polling(opts, async function(...args) {
      let checker = check()
      if (checker.then) checker = await checker
      if (checker.result) {
        console.log('polling', name, args[0], new Date().toLocaleString())
        const r = callback(checker, ...args)
        r.then && await r
      } else {
        const stop = store.scope('polling').key(name).value
        if (stop) {
          stop()
          store.scope('polling').key(name).unset()
          console.log('end', name, args[0], new Date().toLocaleString())
        }
      }
    })
    store.scope('polling').key(name).set(newStop)
  }
}

function sendMsg(ws, action, data) {
  ws.send(JSON.stringify({ action, data }))
}

store.on('begin::record', record => {
  if (record.scope === 'ws::client' && record.key === 'quote' && record.tag == null) {
    makePolling('quote', { interval: 3000, wait: true, immediate: true }, async function(checker, id) {
      const data = await em.get_quote(checker.symbols)
      checker.clients.forEach(ws => sendMsg(ws, 'quote', data))
    }, function check() {
      const symbols = store.scope('ws::client').key('quote').tag('symbol').values
      const clients = store.scope('ws::client').key('quote').values
      return { symbols, clients, result: symbols && symbols.length && clients && clients.length }
    })
  } else if (record.scope === 'ws::client' && record.key === 'highlight' && record.tag === null) {
    makePolling('highlight', { interval: 5000, wait: true, immediate: true }, async function callback(checker, id) {
      const data = await em.get_highlight(em.ALL_CHANGE_TYPES)
      checker.clients.forEach(ws => sendMsg(ws, 'highlight', data))
    }, function check() {
      const clients = store.scope('ws::client').key('highlight').values
      return { clients, result: clients && clients.length }
    })
  } else if (record.scope === 'ws::client' && record.key === 'highlightBK' && record.tag === null) {
    makePolling('highlightBK', { interval: 10000, wait: true, immediate: true }, async function callback(checker, id) {
      const data = await em.get_highlight_bk(em.ALL_CHANGE_TYPES)
      checker.clients.forEach(ws => sendMsg(ws, 'highlightBK', data))
    }, function check() {
      const clients = store.scope('ws::client').key('highlightBK').values
      return { clients, result: clients && clients.length }
    })
  }
})
