const global = {
  tabId: -1,
  windowId: -1
}
chrome.tabs.onActivated.addListener(({ tabId, windowId }) => {
  console.log('actived', windowId, tabId)
  global.windowId = windowId
  global.tabId = tabId
})
chrome.windows.onFocusChanged.addListener(windowId => {
  console.log('focused', windowId)
  global.windowId = windowId
})

/**
 *
 * @param {*} data
 * @param {{window?: number|object, tab?: number|object, forcePopup?: boolean, forceWebpage?: boolean}} [options]
 * @returns
 */
export async function callWindow (data, options) {
  console.log(options, data)
  options = options || {}
  if (options.tab) {
    const tabId = typeof options.tab === 'object' ? options.tab.id : options.tab
    const tab = await chrome.tabs.get(tabId)
    if (tab) {
      return [true, await chrome.tabs.sendMessage(tabId, data)]
    }
  }
  let windowId = global.windowId
  if (options.window) windowId = typeof options.window === 'object' ? options.window.id : options.window
  if (windowId < 0) windowId = (await chrome.windows.getCurrent()).id || -1
  if (!options.forcePopup) {
    /** @type {any} */
    const [tab] = await chrome.tabs.query({ active: true, windowId })
    if (tab && tab.id) {
      try {
        const flag = await chrome.tabs.sendMessage(tab.id, { action: 'pingWebpage' })
        console.log('ping tab', flag)
        return [true, await chrome.tabs.sendMessage(tab.id, data)]
      } catch (e) {
        console.warn('tab is unconnected', tab)
      }
    }
  }
  if (!options.forceWebpage) {
    try {
      // fallback popup
      const flag = await chrome.runtime.sendMessage({ action: 'pingPopup' })
      console.log('ping popup', flag)
      return [true, await chrome.runtime.sendMessage(data)]
    } catch (e) {
      console.warn('fallback is unconnected')
    }
  }
  if (!options.forcePopup && !options.forceWebpage) {
    const tab = await chrome.tabs.create({ windowId: windowId < 0 ? global.windowId : windowId, url: 'other.html' })
    return callWindow(data, { tab })
  }
  return [false]
}

export async function alert (...args) {
  return (await callWindow({ action: 'window.alert', args }))[1]
}

export async function prompt (...args) {
  return (await callWindow({ action: 'window.prompt', args }))[1]
}

export async function confirm (...args) {
  return (await callWindow({ action: 'window.confirm', args }))[1]
}

/**
 * @param {chrome.bookmarks.BookmarkTreeNode|string} folder
 */
export async function sortBookmarkFolder (folder) {
  folder = (await chrome.bookmarks.getSubTree(typeof folder === 'object' ? folder.id : folder))[0]
  if (folder && folder.children) {
    await alert(`总共${folder.children.length}个书签或目录`)
    const sorted = [...folder.children].sort((a, b) => {
      return a.title.toLocaleLowerCase().localeCompare(b.title)
    })
    for (let index = 0; index < sorted.length; index++) {
      const item = sorted[index]
      await chrome.bookmarks.move(item.id, { parentId: item.parentId, index })
    }
  }
  await alert('排序完毕')
}

const CHECK_OPTIONS = {
  sensitiveHash: false, // hash sensitive
  sensitiveQuery: false, // query sensitive
  sensitiveHttps: false, // ssl sensitive
  sensitiveCase: false, // url case-sensitive
  sensitiveTitleCase: false, // title case-sensitive
  sensitiveTitleSpace: false, // space sensitive in title
  insensitiveTitleCharacters: '' // insensitive characters in title
}

/**
 * @param {chrome.bookmarks.BookmarkTreeNode} node
 * @param {Partial<typeof CHECK_OPTIONS>} [options]
 */
function purifyBookmark (node, options) {
  options = { ...CHECK_OPTIONS, ...options }
  let { title, url } = node
  if (!options.sensitiveTitleCase) {
    title = title.toLowerCase()
  }
  if (!options.sensitiveTitleSpace) {
    title = title.replace(/\s/g, '')
  }
  if (options.insensitiveTitleCharacters) {
    title = title.replace(new RegExp(options.insensitiveTitleCharacters, 'g'), '')
  }
  if (url) {
    const urlObj = new URL(url)
    if (!options.sensitiveHash) {
      urlObj.hash = ''
    }
    if (!options.sensitiveHttps) {
      urlObj.protocol = ''
    }
    if (!options.sensitiveQuery) {
      urlObj.search = ''
    }
    url = urlObj.toString()
    if (!options.sensitiveCase) {
      url = url.toLowerCase()
    }
  }
  return { url, title }
}
/**
 * @param {chrome.bookmarks.BookmarkTreeNode} node
 */
async function getBookmarkPath (node) {
  const paths = ['']
  while (node.parentId && +node.parentId > 0) {
    node = (await chrome.bookmarks.get(node.parentId))[0]
    paths.unshift(node.title)
  }
  return paths
}
/**
 * @param {chrome.bookmarks.BookmarkTreeNode} from
 * @param {chrome.bookmarks.BookmarkTreeNode} to
 */
async function mergeBookmark (from, to) {
  if (!await confirm(`
  -------------Merge Bookmark---------------


  "${(await getBookmarkPath(from)).join(' > ')}"

  "${from.title}"

  "${from.url && decodeURIComponent(from.url) || ''}"


  -------------------To---------------------


  "${(await getBookmarkPath(to)).join(' > ')}"

  "${to.title}"

  "${to.url && decodeURIComponent(to.url) || ''}"
  `)) return
  [from, to] = await chrome.bookmarks.get([from.id, to.id])
  if (from && to && !from.children && !to.children) {
    await chrome.bookmarks.update(to.id, { title: from.title })
    await chrome.bookmarks.remove(from.id)
  }
}
/**
 * @param {chrome.bookmarks.BookmarkTreeNode} from
 * @param {chrome.bookmarks.BookmarkTreeNode} to
 */
async function mergeBookmarkFolder (from, to) {
  if (!await confirm(`
  -------------Merge Folder---------------


  "${(await getBookmarkPath(from)).join(' > ')}"

  "${from.title}"

  ------------------To--------------------


  "${(await getBookmarkPath(to)).join(' > ')}"

  "${to.title}"`)) return
  let count = 0
  while (true) {
    from = (await chrome.bookmarks.getSubTree(from.id))[0]
    if (!from || !from.children?.length) break
    for (const item of from.children) {
      await chrome.bookmarks.move(item.id, { parentId: to.id })
      count++
    }
  }
  await chrome.bookmarks.remove(from.id)
  await alert(`移入\n\n${count}\n\n个书签`)
  await cleanBookmarkFolder(to, true)
}
/**
 * @param {chrome.bookmarks.BookmarkTreeNode} folder
 * @param {boolean} recursive
 */
async function cleanBookmarkFolder (folder, recursive) {
  folder = (await chrome.bookmarks.getSubTree(folder.id))[0]
  if (folder.children) {
    const folders = {}
    const files = {}
    for (let item of folder.children) {
      item = (await chrome.bookmarks.getSubTree(item.id))[0]
      if (item.parentId !== folder.id) continue
      const cd = purifyBookmark(item)
      if (item.children) {
        if (folders[cd.title]) {
          await mergeBookmarkFolder(item, folders[cd.title])
        } else {
          folders[cd.title] = item
        }
        recursive && await cleanBookmarkFolder(item, recursive)
      } else {
        if (files[cd.url]) {
          await mergeBookmark(item, files[cd.url])
        } else {
          files[cd.url] = item
        }
      }
    }
  }
}
/**
 * @param {Partial<typeof CHECK_OPTIONS>} options
 */
export async function cleanBookmarks (options = {}) {
  try {
    const single = await confirm('是否只清理单个文件夹?')
    if (single) {
      const folder = await prompt('请输入文件夹名称:')
      if (folder) {
        const item = (await chrome.bookmarks.search(folder)).find(e => folder === e.title && e.dateGroupModified)
        item && await cleanBookmarkFolder(item, false) || await alert('书签没有 ' + folder + ' 文件夹')
      }
    } else {
      const tree = await chrome.bookmarks.getTree()
      if (tree[0].children) {
        for (const e of tree[0].children) {
          await cleanBookmarkFolder(e, true)
        }
      }
    }
    await alert('整理完成')
  } catch (err) {
    await alert('整理出错' + err.message)
    console.error(err)
  }
}

const READ_LATER_FOLDER = '稍后阅读'
const READ_FOLDER_ROOT = '书签栏'

async function getReadLaterBookmarkFolder () {
  const bookmarks = await chrome.bookmarks.getTree()
  const parent = bookmarks[0].children?.find(bk => bk.children && bk.title === READ_FOLDER_ROOT) ||
    bookmarks.find(bk => bk.children && +bk.id === 1)
  if (parent) {
    const setting = await chrome.storage.sync.get('read_later')
    const name = await prompt('输入文件夹', setting.read_later || READ_LATER_FOLDER)
    if (!name) return
    await chrome.storage.sync.set({ read_later: name })
    return parent.children?.find(bk => bk.children && bk.title === name) || chrome.bookmarks.create({
      index: 0,
      parentId: parent.id,
      title: name
    })
  }
}
/**
 * @param {'L'|'R'|'T'} dir
 * @returns
 */
export async function readTabsLater (dir) {
  const tabs = await chrome.tabs.query({ windowId: global.windowId })
  const reading = await getReadLaterBookmarkFolder()
  if (!reading || !reading.children) return
  const tasks = []
  let flag = false
  for (const tab of tabs) {
    if (tab.active) {
      flag = true
    }
    if (tab.url && ((dir === 'T' && tab.active) || (dir === 'L' && !flag) || (dir === 'R' && flag))) {
      const old = reading.children.find(bk => {
        return bk.url === tab.url
      })
      tasks.push(async function (old, tab) {
        if (old) {
          old.title !== tab.title && await chrome.bookmarks.update(old.id, { title: tab.title })
        } else {
          await chrome.bookmarks.create({ parentId: reading.id, title: tab.title, url: tab.url })
        }
        tab.id && await chrome.tabs.remove(tab.id)
      }(old, tab))
    }
  }
  return Promise.all(tasks)
}
