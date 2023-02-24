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
      action === 'quote' && store.tag('symbol').add(...data.symbol)
    } else if (type === 'end') {
      store.scope('ws::client').key(action).delete(this)
      action === 'quote' && store.tag('symbol').delete(...data.symbol)
    }
  })
  ws.on('close', function() {
    const actions = store.scope('ws::client').records.filter(e => e.tag == null).map(e => e.key)
    for (const action of actions) {
      store.scope('ws::client').key(action).delete(this)
    }
  })
})

function polling(options, fn, ...args) {
  const id = Date.now()
  if (typeof options === 'number') options = { interval: options }
  const data = { options, fn, args }
  let t = null
  function handler() {
    t = setTimeout(async () => {
      const r = data.fn(id, ...data.args)
      if (data.options.wait && r.then) {
        await r
      }
      t !== null && handler()
    }, data.options.interval)
  }
  handler()
  return (updateOptions) => {
    if (updateOptions) {
      Object.assign(data.options, updateOptions)
    } else {
      clearTimeout(t)
      t = null
    }
  }
}

store.on('begin::record', record => {
  if (record.scope === 'ws::client' && record.key === 'quote' && record.tag == null) {
    const stop = store.scope('polling').key('quote').value
    if (stop) {
      stop()
      store.scope('polling').key('quote').unset()
      console.log('renew', record.id)
    } else {
      console.log('begin', record.id)
    }
    const newStop = polling(3000, async function(id) {
      console.log(id, new Date().toLocaleString())
      const symbols = store.scope('ws::client').key('quote').tag('symbol').values
      const clients = store.scope('ws::client').key('quote').values
      if (symbols && symbols.length && clients && clients.length) {
        const data = await em.getQuote(symbols)
        clients && clients.forEach(ws => {
          ws.send(JSON.stringify(data))
        })
      } else {
        const stop = store.scope('polling').key('quote').value
        if (stop) {
          stop()
          store.scope('polling').key('quote').unset()
          console.log('end')
        }
      }
    })
    store.scope('polling').key('quote').set(newStop)
  }
})
