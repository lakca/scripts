/* eslint-disable new-cap */

const provider = require('./provider')

const {
  Value,
  GM_getValue,
  GM_setValue,
  GM_openInTab,
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
  constructor() {
    this.disposables = {}
  }
  /** Return the method with `this` bound.
   * @param {string} method
   * @param  {...any} [args]
   * @returns {function}
   *
   * @example
   *    this.bound('dispose')
   *    this.bound.call(console, 'log')
   */
  bound(method, ...args) {
    return this[method].bind(this, ...args)
  }
  /** Return `this` with calling the method.
   * @param {string} method
   * @param  {...any} args
   */
  chained(method, ...args) {
    this[method](...args)
    return this
  }
  /** Add disposable
   * @param {string} name
   * @param {function} fn
   * @returns
   */
  disposeOf(name, fn) {
    if (this.disposables[name]) {
      Array.isArray(this.disposables[name]) ? this.disposables[name].push(fn)
      : this.disposables[name] = [this.disposables[name], fn]
    } else {
      this.disposables[name] = [fn]
    }
    return this
  }
  /** Dispose
   * @param {string} [name]
   * @returns
   */
  dispose(name) {
    if (name) {
      const fn = this.disposables[name]
      if (fn) if (Array.isArray(fn)) fn.forEach(f => f())
                    else fn()
      delete this.disposables[name]
    } else {
      Object.keys(this.disposables).forEach(name => this.dispose(name))
    }
    return this
  }
}

class EventEmitter extends Base {
  /**
   *  @template T
   * @param {T} obj
   * @returns {T & EventEmitter}
   */
  static mount(obj) {
    return Object.assign(obj, new EventEmitter)
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
  GM_openInTab(href)
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

const listeners = {}

function proxyListener(name, oldVal, newVal, ...more) {
  console.log('changed', name)
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

addValueChangeListener.listeners = listeners

function removeValueChangeListener(names, listener) {
  if (!names) return
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

/**
 * handle possible promise data with preserving returning data itself
 * @template T
 * @param {T} data
 * @param {function} [onSuccess] default is `noop`
 * @param {function} [onError=onSuccess] default is `onSuccess`
 * @returns {T extends Promise ? Promise<Awaited<T>> : T}
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
  static get selection() {
    return window.getSelection()
  }
  static get text() {
    if (window.getSelection) {
      return window.getSelection().toString()
    // @ts-ignore
    } else if (document.selection && document.selection.type != 'Control') {
      // @ts-ignore
      return document.selection.createRange().text
    }
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
  const r = EventEmitter.mount(new Promise((resolve, reject) => {
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
  }))
  return r
}

class Draggable extends Base {
  static new(el, id, direction) {
    return new Draggable(el, id, direction)
  }
  constructor(el, id, direction) {
    super()
    this.el = el
    this.id = id
    this._draggable = false
    this._direction = 'left'
    this.fix(direction)
    this.draggble(true)
    this._clientWidth = document.documentElement.clientWidth
    this._sync = setInterval(() => {
      if (this._direction === 'right' && document.visibilityState === 'visible') {
        const w = document.documentElement.clientWidth
        if (this._clientWidth !== w) {
          this._clientWidth = w
        }
        this.savePos()
      }
    }, 5000)
    this.disposeOf('savePos', () => clearInterval(this._sync))
  }
  get storeKey() {
    return this.id ? 'STORE_POSITION_OF_' + this.id : null
  }
  init() {
    if (this._draggable) return this
    const { storeKey } = this
    const self = this
    this.el.draggable = true
    this.el.addEventListener('dragstart', dragstart)
    this.el.addEventListener('drag', drag)
    this.el.addEventListener('dragend', dragend)
    this.disposeOf('dragstart', this.bound.call(this.el, 'removeEventListener', 'dragstart', dragstart))
    this.disposeOf('drag', this.bound.call(this.el, 'removeEventListener', 'drag', drag))
    this.disposeOf('dragend', this.bound.call(this.el, 'removeEventListener', 'dragend', dragend))
    this.listenChange(true)
    this._draggable = true
    return this
    function dragstart(e) {
      document.addEventListener('dragover', dragover, false)
      const rect = this.getBoundingClientRect()
      this.dataset.dx = rect.x - e.clientX
      this.dataset.dy = rect.y - e.clientY
    }
    function drag(e) {
      e.preventDefault()
    }
    function dragover(e) {
      e.preventDefault()
    }
    function dragend(e) {
      document.removeEventListener('dragover', dragover, false)
      const x = e.clientX + +this.dataset.dx
      const y = e.clientY + +this.dataset.dy
      self.setPos(x, y)
      this.dataset.dx = 0
      this.dataset.dy = 0
    }
  }
  setPos(x, y) {
    Object.assign(this.el.style, this.getPos(x, y))
    if (this.storeKey) GM_setValue(this.storeKey, { x, y })
  }
  getPos(x, y) {
    switch (this._direction) {
      case 'right':
        const rect = this.el.getBoundingClientRect()
        const width = document.documentElement.clientWidth
        return {
          top: y + 'px',
          right: (width - rect.width - x) + 'px',
          left: 'auto',
          bottom: 'auto',
        }
      case 'left':
        return {
          top: y + 'px',
          left: x + 'px',
          right: 'auto',
          bottom: 'auto',
        }
    }
  }
  savePos() {
    const rect = this.el.getBoundingClientRect()
    const x = rect.x
    const y = rect.y
    if (this.storeKey) GM_setValue(this.storeKey, { x, y })
  }
  uninit() {
    this.el.draggable = false
    this.dispose()
    this._draggable = false
    return this
  }
  listenChange(flag) {
    if (this.storeKey) {
      if (flag) {
        const onchange = this.bound('setPosFromStore', this.el)
        addValueChangeListener(this.storeKey, onchange)
        this.disposeOf('addValueChangeListener', () => removeValueChangeListener(this.storeKey, onchange))
        this.setPosFromStore()
      } else {
        this.dispose('addValueChangeListener')
      }
    }
    return this
  }
  setPosFromStore() {
    if (this.storeKey) {
      const pos = GM_getValue(this.storeKey)
      if (pos) {
        Object.assign(this.el.style, this.getPos(pos.x, pos.y))
      }
    }
    return this
  }
  draggble(flag) {
    if (flag) {
      this.init()
    } else {
      this.uninit()
    }
    return this
  }
  /**
   * @param {'right'|'left'} [direction='left']
   */
  fix(direction) {
    const oldDirection = this._direction
    if (['left', 'right'].includes(direction)) {
      this._direction = direction
      if (direction === 'left' && oldDirection === 'right') {
        const rect = this.el.getBoundingClientRect()
        this.setPos(rect.x, rect.y)
      }
      else if (oldDirection === 'left' && direction === 'right') {
        this.setPosFromStore()
      }
    }
    return this
  }
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
  constructor(node) {
    super()
    this.node = node
    this._draggable = null
  }
  nativeOn(...args) {
    const nativeOff = DNode.nativeOn(this.node, ...args)
    this.disposeOf('nativeOn', nativeOff)
    return nativeOff
  }
  draggable(id, direction) {
    if (!this._draggable) {
      this._draggable = Draggable.new(this.node, id, direction).draggble(true)
      this.disposeOf('draggable', this._draggable.bound('dispose'))
    } else {
      this._draggable.fix(direction)
      this._draggable.draggble(true)
    }
    return this
  }
  undraggable() {
    this._draggable.draggble(false)
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
  destroy() {
    this.unmount()
    this.dispose()
  }
}

module.exports = {
  ...provider,
  addValueChangeListener,
  callOnElement,
  deleteElement,
  event,
  getDOMPath,
  getUid,
  isElementInvisible,
  later,
  openTab,
  removeValueChangeListener,
  SEARCHES,
  promisable,
  request,
  Store,
  UserProxy,
  DNode,
  Jira,
  Base,
  Draggable,
  EventEmitter,
}

module.exports.popup = require('./popup')
