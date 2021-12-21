/* eslint-disable indent */
/* eslint-disable new-cap */
const TOGGLES = [
  { name: '新标签打开链接', key: 'OPEN_LINK_IN_NEW_TAB' }
]
const {
  g,
  SEARCHES,
  GM_addStyle,
  Store,
  DNode,
  getUid,
  event
} = require('./context')

/** @type {InstanceType<DNode>} */
let MENU

const disposables = []

const uid = getUid('menu')

function toggleMenu(value) {
  if (MENU) {
    MENU.node.classList.toggle('fold', value)
  }
}
function deleteMenu() {
  if (MENU) {
    MENU.dispose()
    MENU.unmount()
    MENU = null
  }
}
function getItem(type, item) {
  switch (type) {
    case 'search':
      return g('li')
        .data('action', 'OPEN_URL')
        .data('value', item.key)
        .down('span')
        .text('🔎')
        .next('span')
        .text(item.name)
    case 'toggle': console.log(item.key, Store.Toggle(item.key).get())
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
      return
  }
}
function onclick(e) {
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
        event.fire('showStore')
        break
      case 'DEL_SITE':
        event.fire('delSite', { site: target.parentNode.dataset.hostname })
        break
      case 'TOGGLE_MENU':
        event.fire('toggleMenu')
        break
      case 'SHOW_TEXT':
        event.fire('showQuery')
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
}
function getGap() {
  return g('li').style('margin-bottom: 12px')
}
function getTime() {
  const date = new Date()
  return `${date.getHours()}:${date.getMinutes()}:${date.getSeconds()}`.replace(
    /\b\d\b/g,
    e => '0' + e
  )
}
function createMenu() {
  try {
    deleteMenu()
  } catch(e) {
    console.error(e)
  }
  console.log('createMenu')
  const gMenu = g('ul')
    .id(uid)
    .class({ fold: Store.Toggle('menu').get() })
    .nativeOn('click', onclick)
      .down('li')
        .key('clock')
        .style('font-weight: bold; font-size: 20px; margin-bottom: 8px')
        .text(getTime())
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
          .next(getGap())
          .next(SEARCHES.map(e => getItem('search', e).start))
          .next(getGap())
          .next(TOGGLES.map(e => getItem('toggle', e).start))
          .next(getGap())
          .next(Store.List('sites').get().map(e => getItem('site', e).start))
    .start
  const dNode = DNode.of(gMenu.el)
  MENU = dNode
  dNode.g = gMenu
  dNode.draggable('menu')
  dNode.mount(document.body)
  return dNode
}
function getStyle() {
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
}
function mountEvents() {
  event.on('toggleMenu', Store.Toggle('menu').on(toggleMenu).bound('toggle'))
  const interval = setInterval(() => MENU && MENU.g.node('clock').text(getTime(), true), 1000)
  disposables.push(() => clearInterval(interval))
  TOGGLES.forEach(e => disposables.push(Store.Toggle(e.key).on(createMenu).bound('off', createMenu)))
}
function mount() {
  if (window.top !== window) return
  GM_addStyle(getStyle())
  createMenu()
  mountEvents()
}

mount()
