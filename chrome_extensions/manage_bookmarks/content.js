/**
 * @template {keyof HTMLElementTagNameMap | Element} T
 */
class El {
  /**
   * @param {T} tag
   * @param {UI} [ui]
   */
  constructor (tag, ui) {
    this.ui = ui
    /** @type {T extends keyof HTMLElementTagNameMap ? HTMLElementTagNameMap[T] : T} */
    this.el = typeof tag === 'string' ? document.createElement(tag) : tag
  }

  html (html) {
    this.el.innerHTML = html
    return this
  }

  id (id) {
    this.el.id = this.ui ? this.ui.ident(id) : id
    return this
  }

  class (cls, bare) {
    cls = cls.trim()
    if (/\s+/.test(cls)) {
      cls.split(/\s+/).forEach(item => this.class(item, bare))
      return this
    }
    const prefix = cls.replace(/[^~?+-].*$/, v => { cls = v; return '' })
    if (!bare) cls = this.ui ? this.ui.ident(cls) : cls
    if (prefix === '~') this.el.classList.toggle(cls)
    else if (prefix === '-') this.el.classList.remove(cls)
    else this.el.classList.add(cls)
    return this
  }

  bareClass (cls) {
    return this.class(cls, true)
  }

  style (prop, value) {
    let style = this.el.getAttribute('style') || ''
    style = style.replace(new RegExp(prop + '\s*:.*?(;|$)', 'g'), '')
    if (value !== void 0) {
      style += prop + ':' + value + ';'
    }
    this.el.setAttribute('style', style)
    return this
  }

  attr (k, v) {
    if (typeof v === 'boolean') {
      this.el.toggleAttribute(k, v)
    } else {
      this.el.setAttribute(k, v)
    }
    return this
  }

  on (event, listener, options) {
    this.el.addEventListener(event, listener, options)
    return this
  }

  mount (ele) {
    ele = ele.el || ele
    ele.appendChild(this.el)
    return this
  }

  append (ele) {
    this.el.appendChild(ele.el || ele)
    return this
  }
}

class UI {
  constructor () {
    this.prefix = btoa(chrome.runtime.getManifest().name)
  }

  ident (name) {
    return `${this.prefix}-${name}`
  }

  /**
   * @template {keyof HTMLElementTagNameMap | Element} T
   * @param {T} tag
   * @returns {El<T>}
   */
  el (tag) {
    return new El(tag, this)
  }

  /**
   * @param {Element} target
   */
  setRelative (target) {
    if (window.getComputedStyle(target).position === 'static') {
      target.classList.add(this.ident('position-relative'))
    }
    return function unsetRelative () {
      target.classList.remove(this.ident('position-relative'))
    }
  }

  /**
   * @param {Element} target
   */
  createLoading (target) {
    /** @type {El<'div'> & { destroy: typeof destroy }} */
    const loading = this.el('div').class('loading').html(`<!-- By Sam Herbert (@sherb), for everyone. More @ http://goo.gl/7AJzbL -->
    <svg viewBox="0 0 120 30" xmlns="http://www.w3.org/2000/svg" fill="currentColor">
        <circle cx="15" cy="15" r="15">
            <animate attributeName="r" from="15" to="15"
                     begin="0s" dur="0.8s"
                     values="15;9;15" calcMode="linear"
                     repeatCount="indefinite" />
            <animate attributeName="fill-opacity" from="1" to="1"
                     begin="0s" dur="0.8s"
                     values="1;.5;1" calcMode="linear"
                     repeatCount="indefinite" />
        </circle>
        <circle cx="60" cy="15" r="9" fill-opacity="0.3">
            <animate attributeName="r" from="9" to="9"
                     begin="0s" dur="0.8s"
                     values="9;15;9" calcMode="linear"
                     repeatCount="indefinite" />
            <animate attributeName="fill-opacity" from="0.5" to="0.5"
                     begin="0s" dur="0.8s"
                     values=".5;1;.5" calcMode="linear"
                     repeatCount="indefinite" />
        </circle>
        <circle cx="105" cy="15" r="15">
            <animate attributeName="r" from="15" to="15"
                     begin="0s" dur="0.8s"
                     values="15;9;15" calcMode="linear"
                     repeatCount="indefinite" />
            <animate attributeName="fill-opacity" from="1" to="1"
                     begin="0s" dur="0.8s"
                     values="1;.5;1" calcMode="linear"
                     repeatCount="indefinite" />
        </circle>
    </svg>`).mount(target)
    const unsetRelative = this.setRelative(target)
    loading.destroy = destroy
    return loading
    function destroy () {
      console.log('destroy')
      loading.el.remove()
      unsetRelative()
    }
  }

  /**
   * @param {Element} target
   * @param {GlobalEventHandlers["onclick"]} cb
   */
  createCloseButton (target, cb) {
    /** @type {El<'div'> & { destroy: typeof destroy }} */
    const closeBtn = this.el('div').class('button-close').html('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 512 512"><path d="M289.94 256l95-95A24 24 0 0 0 351 127l-95 95l-95-95a24 24 0 0 0-34 34l95 95l-95 95a24 24 0 1 0 34 34l95-95l95 95a24 24 0 0 0 34-34z" fill="currentColor"></path></svg>').mount(target)
    cb && (closeBtn.el.onclick = cb)
    closeBtn.destroy = destroy
    return closeBtn
    function destroy () {
      closeBtn.el.remove()
    }
  }

  /**
   * @param {boolean} [fullscreen]
   */
  createModal (fullscreen) {
    let loadingInstance = null
    const self = this
    /** @type {El<'div'> & { title: typeof title, wrap: typeof wrap, overlay: typeof overlay, inner: typeof inner, bar: typeof bar, loading: typeof loading, destroy: typeof destroy }} */
    const modal = this.el('div').class('modal')
    const overlay = this.el('div').class('overlay').mount(modal)
    const wrap = this.el('div').class('wrap').mount(modal)
    const bar = this.el('div').class('bar').bareClass('twx-flex twx-items-center twx-justify-between').mount(wrap)
    const inner = this.el('div').class('inner').mount(wrap)
    this.createCloseButton(bar.el, destroy)
    const title = this.el('span').bareClass('twx-text-xs twx-text-slate-500').html(chrome.runtime.getManifest().name).mount(bar)
    if (fullscreen) {
      modal.class(this.ident('fullscreen'))
    } else {
    }

    modal.mount(document.body)
    document.body.classList.add(this.ident('overflow-hidden'))

    modal.inner = inner
    modal.wrap = wrap
    modal.title = title
    modal.loading = loading
    modal.destroy = destroy
    return modal
    function loading (force) {
      if (force === false) {
        if (loadingInstance) {
          loadingInstance.destroy()
          loadingInstance = null
        }
      } else if (!loadingInstance) {
        loadingInstance = this.createLoading(modal.el)
      }
    }
    function destroy () {
      modal.el.remove()
      document.body.classList.remove(self.ident('overflow-hidden'))
    }
  }
}

const ui = new UI()

chrome.runtime.onMessage.addListener(function (msg, sender, /** @type {(...args) => void} */resp) {
  console.log('content Got', msg)
  if (msg.action === 'window.alert') {
    resp(window.alert(...msg.args))
  } else if (msg.action === 'window.confirm') {
    resp(window.confirm(...msg.args))
  } else if (msg.action === 'window.prompt') {
    resp(window.prompt(...msg.args))
  } else if (msg.action === 'window.importFile') {
    // importFile().then(resp)
  } else if (msg.action === 'askSelectBookmarkFolder') {
    askSelectBookmarkFolder(msg.bookmarks).then(resp)
  }
  return true
})

/**
 * 选择书签目录
 */
async function askSelectBookmarkFolder (bookmarks) {
  const modal = ui.createModal()
  modal.inner.bareClass('twx-flex twx-flex-col twx-gap-8')
  modal.title.html('选择书签目录')
  const select = ui.el('select').bareClass('twx-select').style('width', '200px')
  ui.el('div').bareClass('twx-flex twx-items-center')
    .append(ui.el('label').html('书签目录').bareClass('twx-px-2'))
    .append(select)
    .mount(modal.inner)
  ui.el('div').bareClass('twx-flex twx-items-center twx-justify-center')
    .append(ui.el('button').bareClass('twx-button-plain twx-mr-2').html('取消').on('click', cancel))
    .append(ui.el('button').bareClass('twx-button').html('确认').on('click', submit))
    .mount(modal.inner)
  renderOptions(bookmarks)
  function cancel () {
    modal.destroy()
  }
  function submit () {
    chrome.runtime.sendMessage({ action: 'sortBookmarks', folder: select.el.value })
  }
  function renderOptions (folders, prefix = []) {
    prefix = prefix.concat([null])
    folders.forEach(folder => {
      if (folder.children) {
        prefix[prefix.length - 1] = folder.title
        ui.el('option').attr('value', folder.id).html(prefix.join('-')).mount(select)
        renderOptions(folder.children, prefix.concat([]))
      }
    })
  }
}
