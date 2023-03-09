
  function h(comp, options, children) {
    if (typeof options === 'function') {
      children = { default: options }
      options = null
    }
    return Vue.createVNode(naive[comp] || comp, options, children)
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
  function notify(msg) {
    Notification.requestPermission().then(permission => {
      if (permission === 'granted') new Notification(msg)
    })
  }
  function alert(data, rules, oldData) {
    if (!data || !rules) return
    const equal = oldData && (data.price === oldData.price)
    for (const rule of rules) {
      if (!rule || !rule.checked) continue
      if ((rule.type === 'hc' && rule.value <= data.price && !equal)
        || (rule.type === 'lc' && rule.value >= data.price && !equal)
        || (rule.type === 'hp' && parseFloat(rule.value) <= data.ratio * 100 && !equal)
        || (rule.type === 'lp' && parseFloat(rule.value) >= data.ratio * 100 && !equal)
      ) {
        notify(`${data.name} ${data.percent} ${data.price}`)
        return true
      }
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
  let sign = flow < 0 ? '-' : '+'
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
