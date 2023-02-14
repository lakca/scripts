/* eslint-disable indent */
/* eslint-disable new-cap */
const TOGGLES = [
  { name: '新标签打开链接', key: 'OPEN_LINK_IN_NEW_TAB' },
  { name: '固定在右边', key: 'MENU_FIXED_RIGHT' },
]
const BUTTONS = [
  [
    { name: '显示查询文本', key: 'SHOW_TEXT' },
    { name: '查看存储', key: 'SHOW_STORE' },
  ],
  [
    { name: '复制Markdown', key: 'COPY_MD' },
  ],
]
const context = require('./context')
const {
  g,
  GM_addStyle,
  Store,
  DNode,
} = context

/**
 * @typedef {ReturnType<typeof context.g>}  Gelement
 */
class Menu extends context.Base {
  constructor() {
    super()
    /** @type {InstanceType<typeof context.DNode> & { g: Gelement }} */
    this.dNode= null
    this.uid = context.getUid('menu')
  }
  toggleMenu(value) {
    if (this.dNode) {
      this.dNode.node.classList.toggle('hide', value)
    }
  }
  toggleMenuFold(value) {
    if (this.dNode) {
      this.dNode.node.classList.toggle('fold', value)
    }
  }
  fixMenuRight(value, oldVal) {
    console.log(value, oldVal)
    if (value === oldVal) return
    this.dNode._draggable.fix(value ? 'right' : 'left')
  }
  deleteMenu() {
    if (this.dNode) {
      this.dNode.destroy()
      this.dNode= null
    }
  }
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
          .text(Store.Toggle(item.key).get() ? '✅' : '❌')
          .next('span')
          .text(item.name)
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
      case 'button': {
        const li = g('li')
        item.forEach((e, i) => {
          li.down('span')
          .data('action', e.key)
          .text(e.name)
          if(i < item.length - 1)
          li.down('span')
            .text(' | ')
        })
        return li
      }
      default:
        return
    }
  }
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
        case 'TOGGLE_MENU':
          context.event.fire('toggleMenuFold')
          break
        case 'TOGGLE':
          Store.Toggle(value).toggle()
          break
        case 'SHOW_STORE':
          context.event.fire('showStore')
          break
        case 'DEL_SITE':
          context.event.fire('delSite', { site: target.parentNode.dataset.hostname })
          break
        case 'SHOW_TEXT':
          context.event.fire('showQuery')
          break
        case 'COPY_MD':
          context.event.fire('copyMd')
          break
        case 'OPEN_URL':
          context.event.fire('search', { name: value, newtab: true })
          break
        case 'TO_TOP':
          context.event.fire('toTop')
          break
        case 'TO_BOTTOM':
          context.event.fire('toBottom')
          break
        case 'RESET':
          context.event.fire('resetMenu')
          break
        default:
      }
    }
  }
  getGap() {
    return g('li').style('margin-bottom: 12px')
  }
  getTime() {
    const date = new Date()
    return `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`.replace(
      /\b\d\b/g,
      e => '0' + e
    )
  }
  getStyle() {
    const { uid } = this
    return `
      #${uid}.hide {
        display: none;
      }
      #${uid} {
        position: fixed;
        z-index: 999999999999;
        left: 0px;
        top: 0px;
        font-size: 12px;
        margin: 0;
        padding: 5px;
        background: white;
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
        transition: .3s;
        box-shadow: 0 0 10px #ddd;
        display: flex;
        flex-direction: column;
      }
      #${uid} ul {
        transition: .3s;
        max-height: 999px;
        padding-inline-start: 0;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
      }
      #${uid} li {
        color: #25f;
        cursor: pointer;
        padding: 5px;
        list-style: none;
        transition: .3s;
        margin: 0;
      }
      #${uid} li span:not(:last-child) {
        margin-right: 10px;
      }
      #${uid} [data-action]:hover {
        color: #f29;
      }
      #${uid}:hover li {
        max-height: none!important;
        max-width: none!important;
        transform: scale(1)!important;
        padding: 5px!important;
      }
      #${uid}.fold li:not(.pin) {
        max-height: 0;
        max-width: 0;
        padding: 0;
        overflow: hidden;
        transform: scale(0);
      }
    `
  }
  createMenu() {
    try {
      this.deleteMenu()
    } catch(e) {
      console.error(e)
    }
    /** @type {Gelement}  */
    // @ts-ignore
    const gMenu = g('ul')
      .id(this.uid)
      .class({ fold: Store.Toggle('menu_fold').get() })
      .nativeOn('click', this.bound('onclick'))
        .down('li').class('pin')
          .down('span')
            .text('🧲')
          .next('span')
            .data('action', 'TOGGLE_MENU')
            .style('font-weight: bold; margin-bottom: 8px')
            .text('收起/展开')
          .next('span')
            .key('clock')
            .style('font-weight: bold; font-size: 20px; margin-bottom: 8px')
            .text(this.getTime())
          .up()
        .next('li')
          .down('span')
            .data('action', 'TO_TOP')
            .text('👆')
          .next('span')
            .data('action', 'TO_BOTTOM')
            .text('👇')
          .next('span')
            .data('action', 'RESET')
            .text('🧲')
          .up()
        .next('ul')
          .down(BUTTONS.map(e => this.getItem('button', e).start))
          .next(TOGGLES.map(e => this.getItem('toggle', e).start))
          .next(context.SEARCHES.map(e => this.getItem('search', e).start))
          .next(Store.List('sites').get().map(e => this.getItem('site', e).start))
        .up()
      .start
    this.dNode= Object.assign(DNode.of(gMenu.el), { g: gMenu })
    setTimeout(() => this.dNode.draggable('menu', Store.Toggle('FIXED_RIGHT').get() ? 'right' : 'left'))
    this.dNode.mount(document.body)
    return this.dNode
  }
  resetMenu() {
    if (Store.Toggle('MENU_FIXED_RIGHT').get()) {
      const rect = this.dNode.node.getBoundingClientRect()
      const w = document.documentElement.clientWidth
      this.dNode._draggable.setPos(w - rect.width, 0)
    } else {
      this.dNode._draggable.setPos(0, 0)
    }
  }
  mountEvents() {
    context.event.on('toggleMenu', Store.Toggle('MENU').on(this.bound('toggleMenu')).bound('toggle'))
    context.event.on('toggleMenuFold', Store.Toggle('MENU_FOLD').on(this.bound('toggleMenuFold')).bound('toggle'))
    context.event.on('fixMenuRight', Store.Toggle('MENU_FIXED_RIGHT').on(this.bound('fixMenuRight')).bound('toggle'))
    context.event.on('resetMenu', this.bound('resetMenu'))
    const interval = setInterval(() => this.dNode && this.dNode.g.node('clock').text(this.getTime(), true), 1000)
    this.disposeOf('timeInterval', () => clearInterval(interval))
    const createMenu = this.bound('createMenu')
    TOGGLES.forEach(e => {
      this.disposeOf(e.key, Store.Toggle(e.key).on(createMenu).bound('off', createMenu))
    })
  }
  mount() {
    if (window.top !== window) return
    GM_addStyle(this.getStyle())
    this.createMenu()
    this.mountEvents()
    return this
  }
}

module.exports = (new Menu).mount()
