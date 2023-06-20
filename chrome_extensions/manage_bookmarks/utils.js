
export async function exportBookmarks() {
  const bookmarks = await chrome.bookmarks.getTree()
  const blob = new Blob([JSON.stringify(bookmarks, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `chrome.bookmarks.${new Date().toLocaleDateString().replace(/[\/]/g, '-')}.json`
  a.click()
}

export async function importBookmarks() {
  // const localState = await (await fetch('file:///Users/dgrocsky/Library/Application Support/Google/Chrome/Local State')).json()
  // console.log(localState)
  // const importedBookmarks = JSON.parse(await importTextFile('application/json'))
  // const bookmarks = await getBookmarks()
  // Request file system access
  const handle = await window.showOpenFilePicker();
  // Get the file handle
  const file = await handle[0].getFile();
  // Read the file contents
  const content = await file.text();
}

const CHECK_OPTIONS = {
  sensitiveHash: false, // hash sensitive
  sensitiveQuery: false, // query sensitive
  sensitiveHttps: false, // ssl sensitive
  sensitiveCase: false, // url case-sensitive
  sensitiveTitleCase: false, // title case-sensitive
  sensitiveTitleSpace: false, // space sensitive in title
  insensitiveTitleCharacters: '', // insensitive characters in title
}

/**
 * @param {chrome.bookmarks.BookmarkTreeNode} node
 * @param {Partial<typeof CHECK_OPTIONS>} [options]
 */
function getComparingData(node, options) {
  options = { ...CHECK_OPTIONS, ...options, }
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
    let urlObj = new URL(url)
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
async function getNodePath(node) {
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
async function mergeFolder(from, to) {
  if (!window.confirm(`
  -------------Merge Folder---------------


  "${(await getNodePath(from)).join(' > ')}"

  "${from.title}"

  ------------------To--------------------


  "${(await getNodePath(to)).join(' > ')}"

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
  window.alert(`移入\n\n${count}\n\n个书签`)
  await walkChildren(to)
}
/**
 * @param {chrome.bookmarks.BookmarkTreeNode} from
 * @param {chrome.bookmarks.BookmarkTreeNode} to
 */
async function mergeFile(from, to) {
  if (!window.confirm(`
  -------------Merge Bookmark---------------


  "${(await getNodePath(from)).join(' > ')}"

  "${from.title}"

  "${from.url && decodeURIComponent(from.url) || ''}"


  -------------------To---------------------


  "${(await getNodePath(to)).join(' > ')}"

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
 * @param {chrome.bookmarks.BookmarkTreeNode} folder
 */
async function walkChildren(folder) {
  folder = (await chrome.bookmarks.getSubTree(folder.id))[0]
  if (folder.children) {
    const folders = {}
    const files = {}
    for (let item of folder.children) {
      item = (await chrome.bookmarks.getSubTree(item.id))[0]
      if (item.parentId !== folder.id) continue
      const cd = getComparingData(item)
      if (item.children) {
        if (folders[cd.title]) {
          await mergeFolder(item, folders[cd.title])
        } else {
          folders[cd.title] = item
        }
        await walkChildren(item)
      } else {
        if (files[cd.url]) {
          await mergeFile(item, files[cd.url])
        } else {
          files[cd.url] = item
        }
      }
    }
  }
}

/**
 * @param {Partial<typeof CHECK_OPTIONS>} options
 * @returns
 */
export async function cleanBookmarks(options = {}) {
  try {
    const tree = await chrome.bookmarks.getTree()
    if (tree[0].children) {
      for (const e of tree[0].children) {
        await walkChildren(e)
      }
    }
    window.alert('整理完成')
  } catch(err) {
    window.alert('整理出错' + err.message)
    console.error(err)
  }
}

export async function importTextFile(type) {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = type
  return new Promise((resolve) => {
    input.addEventListener('change', async e => {
      const file = e.target.files[0]
      if (file.type === type) {
        const fr = new FileReader()
        fr.readAsText(file)
        fr.addEventListener('loadend', e => {
          resolve(e.target.result)
        })
      } else {
        alert(`请提供${type}文件`)
      }
    })
    input.click()
  })
}
const READING_LIST = '稍后阅读'
const READING_LIST_PARENT = '书签栏'
/**
 * @returns {Promise<chrome.bookmarks.BookmarkTreeNode & { children: chrome.bookmarks.BookmarkTreeNode[] } | undefined>}
 */
export async function getReadingFolder() {
  const bookmarks = await chrome.bookmarks.getTree()
  const parent = bookmarks[0].children.find(bk => bk.children && bk.title === READING_LIST_PARENT)
    || bookmarks.find(bk => bk.children && bk.id == '1')
  if (parent) {
    return parent.children.find(bk => bk.children && bk.title === READING_LIST) || chrome.bookmarks.create({
      index: 0,
      parentId: parent.id,
      title: READING_LIST,
    })
  }
}

/**
 * @param {'L'|'R'} dir
 * @returns
 */
export async function readTabsLater(dir) {
  const tabs = await chrome.tabs.query({ currentWindow: true, lastFocusedWindow: true })
  const reading = await getReadingFolder()
  if (!reading) return
  const tasks = []
  let flag = false
  for (const tab of tabs) {
    if (tab.active) {
      flag = true
      continue
    }
    if (tab.url && ((dir === 'L' && !flag) || (dir === 'R' && flag))) {
      const old = reading.children.find(bk => {
        return bk.url === tab.url
      })
      tasks.push(async function (old, tab) {
        if (old) {
          old.title !== tab.title && await chrome.bookmarks.update(old.id, { title: tab.title })
        } else {
          await chrome.bookmarks.create({ parentId: reading.id, title: tab.title, url: tab.url, })
        }
        tab.id && await chrome.tabs.remove(tab.id)
      }(old, tab))
    }
  }
  return Promise.all(tasks)
}
