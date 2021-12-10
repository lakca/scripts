/* eslint-disable new-cap */
const TOGGLES = [
  ['新标签打开链接', 'OPEN_LINK_IN_NEW_TAB']
]

const STORE_SITES = 'STORE_SITES'
const STORE_TOGGLE_MENU = 'STORE_TOGGLE_MENU'
const STORE_TOGGLE_OPEN_LINK_IN_NEW_TAB = 'STORE_TOGGLE_OPEN_LINK_IN_NEW_TAB'

module.exports = function ({
  g,
  NAME,
  SEARCHES,
  getQuery,
  search,
  toggleValue,
  openTab,
  deleteElement,
  Value,
  GM_getValue,
  GM_setValue,
  GM_deleteValue,
  GM_addStyle,
  GM_addValueChangeListener,
  GM_registerMenuCommand,
  popup,
  draggable,
}) {
  return {
    get style() {
      return `
        #${NAME} {
          position: fixed;
          z-index: 999999999999;
          left: 0px;
          top: 0px;
          font-size: 12px;
          margin: 0;
          padding: 0;
          background: white;
          -webkit-user-select: none;
          -moz-user-select: none;
          -ms-user-select: none;
          user-select: none;
        }
        #${NAME} {
          box-shadow: 0 0 10px #ddd;
        }
        #${NAME}.fold li[data-action=TOGGLE_MENU] ~ li {
          display: none;
        }
        #${NAME} li {
          color: #25f;
          cursor: pointer;
          margin: 10px 10px;
          list-style: none;
        }
        #${NAME} li span:not(:last-child) {
          margin-right: 10px;
        }
        #${NAME} li:hover {
          color: #f29;
        }
      `
    },
    addSite() {
      const sites = GM_getValue(STORE_SITES, {})
      const origin = window.location.origin
      const hostname = window.location.hostname
      sites[hostname] = origin
      GM_setValue(STORE_SITES, sites)
      this.createMenu()
    },
    clearSites() {
      GM_deleteValue(STORE_SITES)
      this.createMenu()
    },
    deleteMenu() {
      const el = document.getElementById(NAME)
      if (el) {
        el.ondrag = null
        el.ondragstart = null
        el.ondragend = null
        el.onclick = null
      }
      deleteElement(el)
    },
    getItem(type, item) {
      switch (type) {
        case 'search':
          return g('li')
            .data('action', 'OPEN_URL')
            .data('actionTarget', item[1])
            .down('span')
            .text('🔎')
            .next('span')
            .text(item[0])
        case 'toggle':
          return g('li')
            .data('action', 'TOGGLE')
            .data('actionTarget', item[1])
            .down('span')
            .text('🛠')
            .next('span')
            .text(item[0])
            .next('span')
            .text(GM_getValue('STORE_TOGGLE_' + item[1]) ? '✅' : '❌')
        case 'site':
          return g('li')
            .data('action', 'OPEN_URL')
            .data('actionTarget', item[1])
            .data('hostname', item[0])
            .down('span')
            .text('🔗')
            .next('span')
            .text(item[0])
            .next('span')
            .text('🗑')
            .data('action', 'DEL_SITE')
        default:
          return ''
      }
    },
    get gap() {
      return g('li').style('margin-bottom: 12px')
    },
    get time() {
      const date = new Date()
      return `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`.replace(
        /\b\d\b/g,
        e => '0' + e
      )
    },
    createMenu() {
      const self = this
      this.deleteMenu()
      const sites = GM_getValue(STORE_SITES, {})
      const ul = g('ul')
        .down('li')
        .attr('id', 'clock')
        .style('font-weight: bold; font-size: 20px; margin-bottom: 8px')
        .text(this.time)
        .next('li')
        .down('span')
        .data('action', 'TO_TOP')
        .text('🔝')
        .next('span')
        .data('action', 'TO_BOTTOM')
        .style('float: right; display: inline-block; transform: rotate(180deg)')
        .text('🔝')
        .down()
        .next('li')
        .data('action', 'TOGGLE_MENU')
        .style('font-weight: bold; margin-bottom: 8px')
        .text('收起/展开')
        .next('li')
        .data('action', 'SHOW_TEXT')
        .text('显示查询文本')
        .next(this.gap)
        .next(SEARCHES.map(e => this.getItem('search', e[1]).start))
        .next(this.gap)
        .next(TOGGLES.map(e => this.getItem('toggle', e).start))
        .next(this.gap)
        .next(Object.entries(sites).map(e => this.getItem('site', e).start))
        .start.el
      ul.id = NAME
      if (GM_getValue(STORE_TOGGLE_MENU, false)) {
        ul.classList.add('fold')
      }
      document.body.appendChild(ul)
      ul.onclick = function (e) {
        const target = (t => {
          while (t && (!t.dataset || !t.dataset.action))
            t = t.parentNode
          return t
        })(e.target)
        if (!target) return
        const { action, actionTarget } = target.dataset
        console.log(target.dataset)
        if (action) {
          switch (action) {
            case 'TOGGLE':
              toggleValue(`STORE_TOGGLE_${actionTarget}`)
              self.createMenu()
              break
            case 'DEL_SITE': {
              const hostname = target.parentNode.dataset.hostname
              delete sites[hostname]
              GM_setValue(STORE_SITES, sites)
              self.createMenu()
            } break
            case 'TOGGLE_MENU':
              ul.classList.toggle('fold')
              GM_setValue(STORE_TOGGLE_MENU, ul.classList.contains('fold'))
              break
            case 'SHOW_TEXT':
              popup(getQuery())
              break
            case 'OPEN_URL':
              search(target.dataset.actionTarget, true)
              break
            case 'TO_TOP':
              window.scrollTo({ top: 0, behavior: 'auto' })
              break
            case 'TO_BOTTOM':
              window.scrollTo({ top: 99999, behavior: 'auto' })
              break
            default:
          }
        }
      }
      draggable(ul, 'menu')
    },
    mountCommands() {
      SEARCHES[1].forEach(e => GM_registerMenuCommand(e[0], search.bind(null, e[1])))
      GM_registerMenuCommand('添加网站', this.addSite.bind(this))
      GM_registerMenuCommand('清空网站', this.clearSites.bind(this))
    },
    mountEvents() {
      document.body.addEventListener(
        'click',
        e => {
          const target = e.target
          const tag = Value(target.tagName.toUpperCase())
          if (tag.is('A') && GM_getValue(STORE_TOGGLE_OPEN_LINK_IN_NEW_TAB)) {
            Value.prevent(e)
            openTab(target.getAttribute('href'))
          }
        },
        true
      )
    },
    mount() {
      if (window.top !== window) return
      GM_addStyle(this.style)
      this.createMenu()
      this.mountCommands()
      this.mountEvents()
      GM_addValueChangeListener(NAME, () => this.createMenu())

      setInterval(() => {
        document.getElementById('clock').innerHTML = this.time
      }, 1000)
    }
  }
}
