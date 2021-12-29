/* eslint-disable new-cap */
const STORE_ACTION_CLICK = 'STORE_ACTION_CLICK'
/* eslint-disable new-cap */
const context = require('./context')
const {
  getDOMPath,
  later,
  event,
  callOnElement,
  GM_registerMenuCommand,
  GM_setValue,
  GM_getValue,
  GM_deleteValue,
  popup,
  g
} = context

class Action extends context.Base {
  constructor() {
    super()
  }
  removeRecord(host, domPath) {
    const store = GM_getValue(STORE_ACTION_CLICK, {})
    console.debug('remove', host, domPath)
    if (store[host]) {
      store[host] = store[host].filter(e => e !== domPath)
      GM_setValue(STORE_ACTION_CLICK, store)
    }
  }
  show() {
    const clicks = GM_getValue(STORE_ACTION_CLICK, {})
    console.debug('clicks', clicks)
    const content = g('ul')
      .down(Object.entries(clicks).map(([host, domPaths]) =>
        g('li')
          .down('span').class('host').text(host)
          .next('ul')
          .down(domPaths.map(domPath =>
            g('li')
              .down('button@like:link').text('删除').nativeOn('click', this.bound('removeRecord', host, domPath))
              .next('code').text(domPath)
              .down()))
          .down()
          .down()
      )).start
    popup(content, { destroy: true, style: id => `
    ` })
  }
  recordClick() {
    document.body.addEventListener('click', record)
    function record(e) {
      const host = location.host
      const domPath = getDOMPath(e.target)
      const store = GM_getValue(STORE_ACTION_CLICK, {})
      if (!store[host]) store[host] = []
      if (!store[host].includes(domPath)) store[host].push(domPath)
      GM_setValue(STORE_ACTION_CLICK, store)
      document.body.removeEventListener('click', record)
    }
  }
  dispatch(domPaths, times = 0) {
    if (times > 10) return
    console.debug('dispatch', times, domPaths)
    if (domPaths && domPaths.length) {
      const left = domPaths.filter(domPath => !callOnElement(document.querySelector(domPath), 'click'))
      if (left.length) later(this.bound('dispatch', left, times + 1))
    }
  }
   mount() {
    GM_registerMenuCommand('隐藏菜单', event.bound('fire', 'toggleMenu'))
    GM_registerMenuCommand('重置菜单', event.bound('fire', 'resetMenu'))
    GM_registerMenuCommand('显示存储', event.bound('fire', 'showStore'))
    GM_registerMenuCommand('添加点击记忆', this.bound('recordClick'))
    GM_registerMenuCommand('显示点击记忆', this.bound('show'))
    GM_registerMenuCommand('清空点击记忆', () => GM_deleteValue(STORE_ACTION_CLICK))
    GM_registerMenuCommand('添加网站', event.bound('fire', 'addSite'))
    GM_registerMenuCommand('清空网站', event.bound('fire', 'clearSites'))
    this.dispatch(GM_getValue(STORE_ACTION_CLICK, {})[location.host])
  }
}

module.exports = (new Action).chained('mount')
