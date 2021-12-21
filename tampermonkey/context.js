/* eslint-disable new-cap */

const provider = require('./provider')

const {
  Value,
  GM_getValue,
  GM_setValue,
  GM_addValueChangeListener,
  GM_removeValueChangeListener,
  GM_xmlhttpRequest
} = provider

Value.addon({
  prevent(ev) { ev.preventDefault && ev.preventDefault() },
  attr(el, key, value) {
    if (typeof key === 'string') {
      if (value === false) el.removeAttribute(key)
      if (value === void 0) el.setAttribute(key, true)
      else el.setAttribute(key, value)
    } else {
      Object.entries(key).forEach(entry => this.attr(el, ...entry))
    }
  }
})

class Base {
  /** Return the method function with this bound.
   * @param {string} method
   * @param  {...any} [args]
   * @returns {function}
   */
  bound(method, ...args) {
    return this[method].bind(this, ...args)
  }
}

class EventEmitter extends Base {
  static mount(obj) {
    Object.assign(obj, new EventEmitter)
  }
  constructor() {
    super()
    this._listeners = []
    this._state = {}
  }
  on(name, listener) {
    if (name && listener && !this._listeners.some(e => e.name === name && e.listener === listener)) {
      this._listeners.push({ name, listener })
      this._state[name] = true
      return true
    }
    return false
  }
  once(name, listener) {
    if (name && listener) {
      this.on(name, (...data) => {
        listener(...data)
        this.off(name, listener)
      })
      return true
    }
    return false
  }
  off(name, listener) {
    let count = 0
    if (name) {
      if (listener) {
        let state = false
        this._listeners = this._listeners.filter(e => {
          if (e.name === name) {
            if (e.listener === listener) {
              count++
              return false
            } else {
              state = true
            }
          }
          return true
        })
        this._state[name] = state
      } else {
        this._listeners = this._listeners.filter(e => {
          if (e.name === name) {
            count++
            return false
          }
          return true
        })
        this._state[name] = false
      }
    } else {
      count += this._listeners.length
      this._listeners = []
      this._state = {}
    }
    return count
  }
  fire(name, ...data) {
    let count = 0
    if (name && this._state[name]) {
      this._listeners.forEach(e => {
        if (e.name === name) {
          e.listener(...data)
          count++
        }
      })
    }
    return count
  }
}

const NAME = 'myuserscript2021'

const SEARCHES = [
  { key: 'google', name: '谷歌', url: 'https://www.google.com/search?q=#keyword#' },
  { key: 'baidu', name: '百度', url: 'https://www.baidu.com/s?wd=#keyword#' },
  { key: 'bing', name: 'Bing', url: 'https://cn.bing.com/search?q=#keyword#' },
  { key: 'github', name: 'GitHub', url: 'https://github.com/search?utf8=✓&q=#keyword#' },
  { key: 'npmjs', name: 'NPM', url: 'https://www.npmjs.com/search?q=#keyword#' },
  { key: 'stackoverflow', name: 'Stackoverflow', url: 'https://stackoverflow.com/search?q=#keyword#' },
  { key: 'wikipedia', name: '维基百科', url: 'https://zh.wikipedia.org/wiki/#keyword#' },
  { key: 'zhihu', name: '知乎搜索', url: 'https://www.zhihu.com/search?type=content&q=#keyword#' },
  { key: 'google-translate', name: '谷歌翻译', url: 'https://translate.google.com/?hl=zh-CN&tab=wT0#view=home&op=translate&sl=auto&tl=zh-CN&text=#keyword#' },
  { key: 'baidu-translate', name: '百度翻译', url: 'https://fanyi.baidu.com/#en/zh/#keyword#' },
  { key: 'youdao', name: '有道词典', url: 'https://dict.youdao.com/w/#keyword#' },
]

const event = new EventEmitter

/** 获取页面选中的文本 */
function getSelectionText() {
  let text = ''
  if (window.getSelection) {
    text = window.getSelection().toString()
  } else if (document.selection && document.selection.type != 'Control') {
    text = document.selection.createRange().text
  }
  return text
}

function deleteElement(el) {
  if (el && el.parentNode) {
    el.parentNode.removeChild(el)
  }
}

/** 判断元素是否存在（display）*/
function isElementInvisible(el) {
  while (el && el.tagName !== 'HTML') {
    if (el.style.display === 'none') return true
    el = el.parentNode
  }
  return false
}

function callOnElement(el, fnName) {
  while (el && !isElementInvisible(el)) {
    console.debug('call: ', el)
    if (el[fnName]) {
      el[fnName]()
      return true
    }
    el = el.parentNode
  } return false
}

function openTab(href) {
  const a = document.createElement('a')
  a.href = href
  a.target = '_blank'
  a.click()
}

function getDOMPath(dom) {
  const paths = []
  do {
    if (dom === document) {
      continue
    } else if (dom.id) {
      paths.unshift('#' + dom.id)
      break
    } else {
      const tagName = dom.tagName.toLowerCase()
      if (tagName === 'body' || tagName === 'html') {
        paths.unshift(tagName)
      } else {
        const classes = dom.classList.toString().trim()
        const siblings = Array.from(dom.parentNode.children)
        // unique
        if (siblings.length === 1 || !siblings.some(e => e !== dom && e.tagName.toLowerCase() === tagName)) {
          paths.unshift(tagName)
        } else if (classes) {
          paths.unshift(tagName + classes.replace(/(^| )+(?=\S)/g, '.'))
        } else {
          paths.unshift(tagName + `:nth-child(${siblings.indexOf(dom) + 1})`)
        }
      }
    }
  } while (dom = dom.parentNode)

  return paths.join(' > ')
}

function randomId() {
  return Date.now().toString(16)
}

/** 定时器统一（如果队列中存在函数）不间断定时执行 */
function later(fn) {
  if (fn && typeof fn === 'function' && !later.laterQueue.includes(fn)) {
    later.laterQueue.push(fn)
  }
  if (later.timeout === null && later.laterQueue.length) {
    later.timeout = setTimeout(() => {
      console.debug('later timeout')
      const queue = later.laterQueue
      later.laterQueue = []
      for (const fun of queue) fun()
      later.timeout = null
      later()
    }, 100)
  }
}

later.laterQueue = []
later.timeout = null

function draggable(el, id) {
  if (!el) return
  el.draggable = true
  el.addEventListener('dragstart', dragstart)
  el.addEventListener('drag', drag)
  el.addEventListener('dragend', dragend)
  const storeKey = draggable.getStoreKey(id)
  const onchange = draggable.setPosFromStore.bind(null, el, storeKey)
  if (storeKey) {
    addValueChangeListener(storeKey, onchange)
    draggable.setPosFromStore(el, storeKey)
  }
  function dragstart(e) {
    document.addEventListener('dragover', dragover, false)
    const rect = this.getBoundingClientRect()
    this.dataset.dx = rect.x - e.clientX
    this.dataset.dy = rect.y - e.clientY
  }
  function drag(e) {
    e.preventDefault()
  }
  function dragend(e) {
    document.removeEventListener('dragover', dragover, false)
    const x = e.clientX + +this.dataset.dx
    const y = e.clientY + +this.dataset.dy
    this.style.left = x + 'px'
    this.style.top = y + 'px'
    const storeKey = draggable.getStoreKey(id)
    if (storeKey) GM_setValue(storeKey, { x: x, y: y })
    this.dataset.dx = 0
    this.dataset.dy = 0
  }
  function dragover(e) {
    e.preventDefault()
  }
  return function undraggble() {
    el.removeEventListener('dragstart', dragstart)
    el.removeEventListener('drag', drag)
    el.removeEventListener('dragend', dragend)
    removeValueChangeListener(storeKey, onchange)
  }
}

draggable.getStoreKey = function(id) {
  return id ? 'STORE_POSITION_OF_' + id : null
}

draggable.setPosFromStore = function(el, storeKey) {
  if (storeKey) {
    const pos = GM_getValue(storeKey)
    if (pos) {
      el.style.top = pos.y + 'px'
      el.style.left = pos.x + 'px'
    }
  }
}

const listeners = {}

function proxyListener(name, oldVal, newVal, ...more) {
  if (listeners[name]) {
    listeners[name].listeners.forEach(listener => listener.call(null, newVal, oldVal, ...more))
  }
}

function addValueChangeListener(names, listener) {
  names = Array.isArray(names) ? names : [names]
  for (const name of names) {
    if (!listeners[name]) {
      listeners[name] = {
        id: GM_addValueChangeListener(name, proxyListener),
        listeners: [listener],
      }
    } else if (!listeners[name].listeners.includes(listener)) {
      listeners[name].listeners.push(listener)
    }
  }
}

function removeValueChangeListener(names, listener) {
  names = Array.isArray(names) ? names : [names]
  for (const name of names) {
    if (listeners[name]) {
      const i = listeners[name].listeners.indexOf(listener)
      if (~i) listeners[name].listeners.splice(i, 1)
    }
    if (listeners[name].listeners.length === 0) {
      GM_removeValueChangeListener(listeners[name].id)
      delete listeners[name]
    }
  }
}

function pascal(str) {
  return str && str.replace(/(?<=[a-z])(?=[A-Z])|\W+/g, '_').toUpperCase()
}

class Store extends Base {
  static New(name) {
    return new Store(name)
  }
  static Toggle(name) {
    return new Toggle('STORE_TOGGLE_' + pascal(name))
  }
  static Hash(name) {
    return new Hash('STORE_HASH_' + pascal(name))
  }
  static List(name) {
    return new List('STORE_LIST_' + pascal(name))
  }
  constructor(name) {
    super()
    this.name = name
  }
  set(value) {
    return GM_setValue(this.name, value)
  }
  get() {
    return GM_getValue(this.name)
  }
  on(listener) {
    addValueChangeListener(this.name, listener)
    return this
  }
  off(listener) {
    removeValueChangeListener(this.name, listener)
    return this
  }
}
class Toggle extends Store {
  get() {
    return !!super.get()
  }
  /**
   * @param {boolean} [value]
   */
  toggle(value) {
    GM_setValue(this.name, value === void 0 ? !GM_getValue(this.name) : !!value)
    return this
  }
}
class Hash extends Store {
  get() {
    const d = super.get() || []
    return Array.isArray(d) ? d : {}
  }
  attr(k, v) {
    const val = this.get()
    if (arguments.length > 1) {
      val[k] = v
    } else if (v !== void 0) {
      return val[k]
    } else {
      delete val[k]
    }
    this.set(val)
    return this
  }
}
class List extends Store {
  get() {
    const d = super.get() || []
    return Array.isArray(d) ? d : []
  }
  add(v) {
    const val = this.get()
    val.push(v)
    this.set(val)
    return this
  }
  del(v) {
    const val = this.get()
    const i = val.indexOf(v)
    if (~i) {
      val.splice(i, 1)[0]
      this.set(val)
    }
    return this
  }
  has(v) {
    const val = this.get()
    return val.includes(v)
  }
  empty() {
    this.set([])
  }
}

function getUid(name) {
  return NAME + '_' + name
}

function noop() {}

/**  */
/**
 * handle possible promise data with preserving returning data itself
 *
 * @param {*} data
 * @param {function} [onSuccess] default is `noop`
 * @param {function} [onError=onSuccess] default is `onSuccess`
 * @returns
 */
function promisable(data, onSuccess, onError) {
  onSuccess = onSuccess || noop
  onError = onError || onSuccess
  if (data && typeof data.then === 'function' && typeof data.catch === 'function') {
    return data.then((d) => {
      onSuccess(d)
      return d
    }).catch((e) => {
      onError(e)
      return Promise.reject(e)
    })
  } else {
    onSuccess(data)
    return data
  }
}

class UserProxy extends Base {
  get selection() {
    return window.getSelection()
  }
  get text() {
    return window.getSelection().toString()
  }
  static useSelection(cb) {
    const s = window.getSelection()
    const ranges = new Array(s.rangeCount).fill().map((e, i) => s.getRangeAt(i))
    s.removeAllRanges()
    return promisable(cb(s), () => {
      const s = window.getSelection()
      s.removeAllRanges()
      ranges.forEach(r => s.addRange(r))
    })
  }
  static useFocus(cb) {
    const el = document.activeElement
    return promisable(cb(), () => el.focus())
  }
  static fakeElement(textArrayOrTag, cb) {
    const el = Array.isArray(textArrayOrTag)
      ? document.createTextNode(textArrayOrTag.join('\n'))
      : document.createElement(textArrayOrTag)
    document.body.appendChild(el)
    return promisable(cb(el), () => document.body.removeChild(el))
  }
  static read() {
    if (navigator.clipboard) {
      return navigator.clipboard.readText()
    }
    return UserProxy.fakeElement('textarea', el => {
      return UserProxy.useFocus(() => {
        el.focus()
        document.execCommand('paste')
        return el.value
      })
    })
  }
  static write(text) {
    if (navigator.clipboard) {
      return navigator.clipboard.writeText(text)
    }
    return UserProxy.useSelection(s => {
      UserProxy.fakeElement([text], el => {
        const r = document.createRange()
        r.selectNodeContents(el)
        s.addRange(r)
        document.execCommand('copy')
      })
    })
  }
}

/**
 * @see https://www.tampermonkey.net/documentation.php?ext=dhdg#GM_xmlhttpRequest
 *
 * @param {string} url
 * @param {*} more
 * @returns
 */
function request(url, more) {
  const r = new Promise((resolve, reject) => {
    GM_xmlhttpRequest({
      url,
      method: 'GET',
      responseType: 'json', // json, arraybuffer, blob, stream
      ...more,
      onabort(...args) {
        r.fire('abort', ...args)
      },
      ontimeout(...args) {
        r.fire('timeout', ...args)
      },
      onloadstart(...args) {
        r.fire('loadstart', ...args)
      },
      onprogress(...args) {
        r.fire('progress', ...args)
      },
      onreadystatechange(...args) {
        r.fire('readystatechange', ...args)
      },
      onload(res) {
        const response = {
          finalUrl: res.finalUrl,
          status: res.status,
          statusText: res.statusText,
          headers: res.responseHeaders,
          body: res.response, // corresponding with `responseType`
          text: res.responseText,
          xml: res.responseXML
        }
        resolve(response)
      },
      onerror(err) {
        reject(err)
      },
    })
  })
  EventEmitter.mount(r)
  return r
}

class Jira {
  constructor(origin, username, password) {
    this.origin = origin
    this.username = username
    this.password = password
  }
  request(url, more) {
    return request(url, {
      method: 'GET',
      user: this.username,
      password: this.password,
      responseType: 'json',
      anonymous: true,
      nocache: true,
      headers: {
        'Content-Type': 'application/json'
      },
      ...more
    })
  }
  addComment(issueId, comment) {
    return this.request(`${this.origin}/rest/api/2/issue/${issueId}/comment`, {
      body: JSON.stringify({
        body: comment,
      })
    })
  }
}

/**
 * @template {Node} T
 * @param {T} node
 */
class DNode extends EventEmitter {
  static of(node) {
    return new DNode(node)
  }
  static nativeOn(el, name, listener, ...more) {
    el.addEventListener(name, listener, ...more)
    return function nativeOff() {
      el.removeEventListener(name, listener, ...more)
    }
  }
  static get draggable() {
    return draggable
  }
  constructor(node) {
    super()
    this.node = node
    this.disposables = {
      nativeOn: []
    }
  }
  dispose() {
    Object.entries(this.disposables).forEach(([name, fn]) => Array.isArray(fn) ? fn.forEach(f => f()) : fn())
    this.off()
    return this
  }
  nativeOn(...args) {
    const nativeOff = DNode.nativeOn(this.node, ...args)
    this.disposables.nativeOn.push(nativeOff)
    return nativeOff
  }
  draggable(id) {
    if (!this.disposables.draggable) {
      this.disposables.draggable = DNode.draggable(this.node, id)
    }
    return this
  }
  undraggable() {
    this.disposables.draggable()
    delete this.disposables.draggable
    return this
  }
  mount(el) {
    el.appendChild(this.node)
    return this
  }
  unmount() {
    deleteElement(this.node)
    return this
  }
}

module.exports = {
  ...provider,
  addValueChangeListener,
  callOnElement,
  deleteElement,
  draggable,
  event,
  getDOMPath,
  getSelectionText,
  getUid,
  isElementInvisible,
  later,
  openTab,
  randomId,
  removeValueChangeListener,
  SEARCHES,
  promisable,
  request,
  Store,
  UserProxy,
  DNode,
  Jira,
}

module.exports.popup = require('./popup')
