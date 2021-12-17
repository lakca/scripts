/* eslint-disable indent */
/* eslint-disable new-cap */
const TOGGLES = [
  { name: '新标签打开链接', key: 'OPEN_LINK_IN_NEW_TAB' }
]
/* eslint-disable new-cap */
/**
 * @param {ReturnType<import('./ctx')> & ReturnType<import('./method')>} param0
 */
module.exports = function ({
  g,
  SEARCHES,
  search,
  openTab,
  deleteElement,
  Value,
  GM_addStyle,
  Store,
  DNode,
  getUid,
  event
}) {
  /** @type {DNode} */
  let MENU
  return {
    uid: getUid('menu'),
    get style() {
      const uid = this.uid
      return `
        #${uid} {
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
        #${uid} {
          box-shadow: 0 0 10px #ddd;
        }
        #${uid}.fold li[data-action=TOGGLE_MENU] ~ li {
          display: none;
        }
        #${uid} li {
          color: #25f;
          cursor: pointer;
          margin: 10px 10px;
          list-style: none;
        }
        #${uid} li span:not(:last-child) {
          margin-right: 10px;
        }
        #${uid} li:hover {
          color: #f29;
        }
      `
    },
    getMenu() {
      return MENU
    },
    toggleMenu() {
      const menu = this.getMenu()
      menu.node.classList.toggle('fold')
      Store.Toggle('menu').toggle(menu.node.classList.contains('fold'))
    },
    deleteMenu() {
      const menu = this.getMenu()
      if (menu) {
        menu.destroy()
      }
    },
    getItem(type, item) {
      switch (type) {
        case 'search':
          return g('li')
            .data('action', 'OPEN_URL')
            .data('value', item.key)
            .down('span')
            .text('🔎')
            .next('span')
            .text(item.name)
        case 'toggle':
          return g('li')
            .data('action', 'TOGGLE')
            .data('value', item.key)
            .down('span')
            .text('🛠')
            .next('span')
            .text(item.name)
            .next('span')
            .text(Store.Toggle(item.key).get() ? '✅' : '❌')
        case 'site':
          return g('li')
            .data('action', 'OPEN_URL')
            .data('value', item)
            .down('span')
            .text('🔗')
            .next('span')
            .text(item)
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
    onclick(e) {
      const target = (t => {
        while (t && (!t.dataset || !t.dataset.action))
          t = t.parentNode
        return t
      })(e.target)
      if (!target) return
      const { action, value } = target.dataset
      if (action) {
        switch (action) {
          case 'TOGGLE':
            Store.Toggle(value).toggle()
            break
          case 'SHOW_STORE':
            event.fire('show', 'store')
            break
          case 'DEL_SITE': {
            event.fire('delSite', { site: target.parentNode.dataset.hostname })
          } break
          case 'TOGGLE_MENU':
            event.fire('toggleMenu')
            break
          case 'SHOW_TEXT':
            event.fire('show', 'query')
            break
          case 'OPEN_URL':
            event.fire('search', { name: value, newtab: true })
            break
          case 'TO_TOP':
            event.fire('toTop')
            break
          case 'TO_BOTTOM':
            event.fire('toBottom')
            break
          default:
        }
      }
    },
    createMenu() {
      this.deleteMenu()
      const menu = g('ul')
        .id(this.uid)
        .class({ fold: Store.Toggle('menu').get() })
        .on('click', this.onclick)
          .down('li')
            .key('clock')
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
            .down('span')
              .data('action', 'SHOW_STORE')
              .text('查看存储')
              .next(this.gap)
              .next(SEARCHES.map(e => this.getItem('search', e).start))
              .next(this.gap)
              .next(TOGGLES.map(e => this.getItem('toggle', e).start))
              .next(this.gap)
              .next(Store.List('sites').get().map(e => this.getItem('site', e).start))
        .start
      const dNode = MENU = DNode.of(menu.el)
      dNode.g = menu
      dNode.draggable('menu')
      dNode.nativeOn('click', this.onclick)
      dNode.mount(document.body)
      const interval = setInterval(() => interval ? menu.node('clock').text(this.time, true) : clearInterval(interval), 1000)

      menu.destroy = () => {
        dNode.dispose()
        clearInterval(interval)
        dNode.unmount()
        MENU = null
      }
      return menu
    },
    mountEvents() {
      event.on('toggleMenu', this.toggleMenu.bind(this))
      TOGGLES.forEach(e => Store.Toggle(e.key).on(this.createMenu.bind(this)))
      document.body.addEventListener(
        'click',
        e => {
          const target = e.target
          const tag = Value(target.tagName.toUpperCase())
          if (tag.is('A') && Store.Toggle('OPEN_LINK_IN_NEW_TAB')) {
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
      this.mountEvents()
    }
  }
}
