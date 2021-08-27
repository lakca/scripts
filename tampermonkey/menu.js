/* eslint-disable new-cap */
const g = require('/Users/longpeng/Documents/GitHub/gelement/src/index.js')

const TOGGLES = [
  ['新标签打开链接', 'OPEN_LINK_IN_NEW_TAB']
]

const STORE_SITES = 'STORE_SITES'
const STORE_MENU_POSITION = 'STORE_MENU_POSITION'
const STORE_TOGGLE_MENU = 'STORE_TOGGLE_MENU'
const STORE_TOGGLE_OPEN_LINK_IN_NEW_TAB = 'STORE_TOGGLE_OPEN_LINK_IN_NEW_TAB'

module.exports = function ({
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
            .attr('data-action', 'OPEN_URL')
            .attr('data-url', item[1])
            .down('span')
            .text('🔎')
            .next('span')
            .text(item[0])
        case 'toggle':
          return g('li')
            .attr('data-action', 'TOGGLE')
            .attr('data-toggle', item[1])
            .down('span')
            .text('🛠')
            .next('span')
            .text(item[0])
            .next('span')
            .text(GM_getValue('STORE_TOGGLE_' + item[1]) ? '✅' : '❌')
        case 'site':
          return g('li')
            .attr('data-action', 'OPEN_URL')
            .attr('data-hostname', item[0])
            .attr('data-url', item[1])
            .down('span')
            .text('🔗')
            .next('span')
            .text(item[0])
            .next('span')
            .text('🗑')
            .attr('data-action', 'DEL_SITE')
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
        .attr('data-action', 'TO_TOP')
        .text('🔝')
        .next('span')
        .attr('data-action', 'TO_BOTTOM')
        .style('float: right; display: inline-block; transform: rotate(180deg)')
        .text('🔝')
        .down()
        .next('li')
        .attr('data-action', 'TOGGLE_MENU')
        .style('font-weight: bold; margin-bottom: 8px')
        .text('收起/展开')
        .next('li')
        .attr('data-action', 'SHOW_TEXT')
        .text('显示查询文本')
        .next(this.gap)
        .next(SEARCHES.map(e => this.getItem('search', e[1]).start))
        .next(this.gap)
        .next(TOGGLES.map(e => this.getItem('toggle', e).start))
        .next(this.gap)
        .next(Object.entries(sites).map(e => this.getItem('site', e).start))
        .start.el
      const pos = GM_getValue(STORE_MENU_POSITION, { x: 0, y: 0 })
      ul.id = NAME
      ul.draggable = true
      ul.style.left = pos.x + 'px'
      ul.style.top = pos.y + 'px'
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
        const { action, actionType } = target.dataset
        console.log(action, actionType)
        if (action) {
          if (actionType) {
            switch (actionType) {
              case 'TOGGLE':
                toggleValue(`STORE_TOGGLE_${action}`)
                break
              default:
            }
          } else {
            switch (action) {
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
                alert(getQuery())
                break
              case 'OPEN_URL':
                search(target.dataset.url, true)
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
      }
      ul.ondragstart = function (e) {
        document.addEventListener('dragover', Value.prevent, false)
        const rect = self.getBoundingClientRect()
        this.dataset.dx = rect.x - e.clientX
        this.dataset.dy = rect.y - e.clientY
      }
      ul.ondrag = function (e) {
        Value.prevent(e)
      }
      ul.ondragend = function (e) {
        document.removeEventListener('dragover', Value.prevent, false)
        const x = e.clientX + +this.dataset.dx
        const y = e.clientY + +this.dataset.dy
        this.style.left = x + 'px'
        this.style.top = y + 'px'
        GM_setValue(STORE_MENU_POSITION, { x: x, y: y })
        this.dataset.dx = 0
        this.dataset.dy = 0
      }
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
