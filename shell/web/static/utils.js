if ('Vue' in window) {
  window.Vue.component('RenderBlock', {
    name: 'RenderBlock',
    props: {
      component: [String, Object],
      render: [Array, String, Object, Number]
    },
    render() {
      const children = Array.isArray(this.$props.render) ? this.$props.render : [this.$props.render]
      return h(this.component || 'div', { on: this.$listeners }, children)
    }
  })
}
function h(comp, options, children) {
  if (typeof options === 'function') {
    children = { default: options }
    options = null
  }
  const h = window?.Vue?.createVNode || window?.Vue?.h
  const c = window?.naive?.[comp] || comp
  return h && h(c, options, children)
}
function sign(number) {
  number = `${number}`
  return !number.startsWith('-') ? '+' + number : number
}
function compare(v1, v2 = 0) {
  return v1 > v2 ? 1 : v1 < v2 ? -1 : 0
}
function percentText(v, base) {
  if (base) v = (v - base) / base
  return sign((v * 100).toFixed(2)) + '%'
}
function arr2obj(arr, key) {
  const obj = {}
  for (const e of arr) {
    obj[e[key]] = e
  } return obj
}
function notify(msg, voice) {
  window.__notify__ = msg
  window.__voice__ = voice
  let btn = document.querySelector('#btn')
  if (!btn) {
    btn = document.createElement('button')
    document.body.appendChild(btn)
    btn.style.width = '10px'
    btn.style.height = '10px'
    btn.id = 'btn'
    btn.addEventListener('click', function() {
      console.log('click')
      window.__voice__ && fetch('/say', {
        method: 'POST',
        body: window.__voice__
      })
      window.__notify__ && Notification.requestPermission().then(permission => {
        console.log(permission)
        if (permission === 'granted') new Notification(window.__notify__)
      })
    })
  }
  if (window.__notify__) {
    btn.click()
  }
}
function alert(data, rules, oldData) {
  if (!data || !rules) return
  const equal = oldData && (data.price === oldData.price)
  const equalRatio = oldData && (Math.abs(data.ratio - oldData.ratio) < 0.0001)
  for (const rule of rules) {
    if (!rule || !rule.checked) continue
    const msg = `${data.name} ${data.percent} ${data.price}`
    let voice
    const percentVoice = (data.ratio > 0 ? '当前涨幅' : data.ratio < 0 ? '当前跌幅' : '') + `${data.percent.replace(/[+-]/, '')}`
    if ((rule.type === 'hc' && rule.value <= data.price && !equal)) {
      voice = `价格涨至${data.price} ${percentVoice}`
    }
    if ((rule.type === 'lc' && rule.value >= data.price && !equal)) {
      voice = `价格跌至${data.price} ${percentVoice}`
    }
    if ((rule.type === 'hp' && parseFloat(rule.value) <= data.ratio * 100 && !equalRatio)) {
      voice = `价格涨至${percentVoice}`
    }
    if ((rule.type === 'lp' && parseFloat(rule.value) >= data.ratio * 100 && !equalRatio)) {
      voice = `价格跌至${percentVoice}`
    }
    console.log(data.percent, data.ratio, equalRatio)
    voice && notify(msg, data.name + voice)
    return true
  }
}
function getStorage(key) {
  return JSON.parse(localStorage.getItem(key))
}

function setStorage(key, value) {
  localStorage.setItem(key, JSON.stringify(value))
}
function copy(v) {
  return JSON.parse(JSON.stringify(v))
}
function isTrading(force) {
  const date = new Date()
  const hour = date.getHours()
  const minute = date.getMinutes()
  return force || (hour > 9 && hour < 11) || (hour > 12 && hour < 15) || (hour === 9 && minute > 14) || (hour === 11 && minute < 32) || (hour === 15 && minute < 2)
}
function getFlowText(flow, offset = 0) {
  let unit = ''
  const sign = flow < 0 ? '-' : '+'
  let value = Math.abs(flow)
    ;['万', '亿'].slice(offset).some((e, i) => {
    if (value < (i + 1) * 10000) {
      return true
    } else {
      value /= 10000
      unit = e
    }
  })
  return sign + value.toFixed(2) + unit
}

function convertRadix(v, opts) {
  v = +v
  const { units, base, fixed } = Object.assign({ base: 10000, units: ['', '万', '亿'], fixed: 4 }, opts)
  for (const u of units) {
    if (Math.abs(v) > base) v /= base
    else return +v.toFixed(fixed) + u
  }
}
