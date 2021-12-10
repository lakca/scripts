/* eslint-disable new-cap */
module.exports = function({ Value, GM_getValue, GM_setValue }) {
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

  function inHostname(part) {
    const hostname = window.location.hostname
    if (
      hostname.indexOf(part) === 0 ||
      hostname.indexOf(part) === hostname.length - part.length
    )
      return true
    if (part[0] !== '.') part = '.' + part
    if (part[part.length - 1] !== '.') part += '.'
    return hostname.indexOf(part) > -1
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

  function openTab(href) {
    const a = document.createElement('a')
    a.href = href
    a.target = '_blank'
    a.click()
  }

  function toggleValue(key) {
    GM_setValue(key, !GM_getValue(key))
  }

  const NAME = 'myuserscript2021'

  const SEARCHES = [
    ['google', ['谷歌', 'https://www.google.com/search?q=#keyword#']],
    ['baidu', ['百度', 'https://www.baidu.com/s?wd=#keyword#']],
    ['bing', ['Bing', 'https://cn.bing.com/search?q=#keyword#']],
    ['github', ['GitHub', 'https://github.com/search?utf8=✓&q=#keyword#']],
    ['npmjs', ['NPM', 'https://www.npmjs.com/search?q=#keyword#']],
    ['stackoverflow', ['Stackoverflow', 'https://stackoverflow.com/search?q=#keyword#']],
    ['wikipedia', ['维基百科', 'https://zh.wikipedia.org/wiki/#keyword#']],
    ['zhihu', ['知乎搜索', 'https://www.zhihu.com/search?type=content&q=#keyword#']],
    ['google-translate', ['谷歌翻译', 'https://translate.google.com/?hl=zh-CN&tab=wT0#view=home&op=translate&sl=auto&tl=zh-CN&text=#keyword#']],
    ['baidu-translate', ['百度翻译', 'https://fanyi.baidu.com/#en/zh/#keyword#']],
    ['youdao', ['有道词典', 'https://dict.youdao.com/w/#keyword#']],
  ]
  const SEARCHES_DICT = Object.fromEntries(SEARCHES)

  function getQuery() {
    let text = getSelectionText().trim()
    if (text) return text
    if (inHostname('translate') || inHostname('fanyi')) {
      text = document.querySelector('textarea').value
    } else {
      for (const input of document.querySelectorAll(
        'input[type=search], input[type=text], input:not([type])'
      )) {
        if (input.type === 'search') {
          text = input.value
          break
        } else if (!isElementInvisible(input)) {
          text = input.value
          break
        }
      }
    }
    if (!text.trim()) {
      if (inHostname('github.')) {
        text = document.querySelector('h1').innerText.replace(/\n/g, '')
      } else {
        const h1 = document.querySelector('h1')
        if (h1) text = h1.innerText
      }
    }
    return text.trim()
  }

  function search(url, newtab) {
    if (url) {
      const text = getQuery()
      url = SEARCHES_DICT[url] ? SEARCHES_DICT[url][1] : url
      url = url.replace('#keyword#', text)
      if (newtab) {
        openTab(url)
      } else {
        window.location.href = url
      }
    }
  }

  function draggable(el, id) {
    if (!el) return
    el.draggable = true
    const storeKey = id ? 'STORE_POSITION_OF_' + id : null
    const prevent = ev => ev.preventDefault()
    el.addEventListener('dragstart', function(e) {
      document.addEventListener('dragover', prevent, false)
      const rect = this.getBoundingClientRect()
      this.dataset.dx = rect.x - e.clientX
      this.dataset.dy = rect.y - e.clientY
    })
    el.addEventListener('drag', prevent)
    el.addEventListener('dragend', function(e) {
      document.removeEventListener('dragover', prevent, false)
      const x = e.clientX + +this.dataset.dx
      const y = e.clientY + +this.dataset.dy
      this.style.left = x + 'px'
      this.style.top = y + 'px'
      if (storeKey) GM_setValue(storeKey, { x: x, y: y })
      this.dataset.dx = 0
      this.dataset.dy = 0
    })
    if (storeKey) {
      const pos = GM_getValue(storeKey)
      if (pos) {
        el.style.top = pos.y
        el.style.left = pos.x
      }
    }
  }

  return {
    NAME,
    SEARCHES,
    getSelectionText,
    randomId,
    later,
    deleteElement,
    isElementInvisible,
    inHostname,
    getDOMPath,
    callOnElement,
    openTab,
    toggleValue,
    getQuery,
    search,
    draggable,
  }
}
