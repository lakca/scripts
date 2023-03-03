
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
  function compare(v1, v2) {
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
  function alert(data, rules) {
    if (!data || !rules) return
    for (const rule of rules) {
      if (!rule || !rule.checked) continue
      if ((rule.type === 'hc' && rule.value <= data.price)
        || (rule.type === 'lc' && rule.value >= data.price)
        || (rule.type === 'hp' && parseFloat(rule.value) <= data.ratio * 100)
        || (rule.type === 'lp' && parseFloat(rule.value) >= data.ratio * 100)
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
