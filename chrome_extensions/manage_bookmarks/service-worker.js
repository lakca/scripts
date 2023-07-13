import { cleanBookmarks, readTabsLater, sendCurrentTab, sortBookmarkFolder } from './headless.js'
import { config } from './config.js'

chrome.runtime.onInstalled.addListener(() => {
  config.actions.forEach(action => {
    chrome.contextMenus.create(Object.fromEntries(Object.entries(action).filter(([k]) => !k.startsWith('_'))))
  })
})

chrome.contextMenus.onClicked.addListener((info, tab) => {
  onmessage({ action: info.menuItemId }, null, () => { })
})

chrome.omnibox.onInputChanged.addListener((text, suggest) => {
  console.log(text, suggest)
  // suggest()
})

chrome.runtime.onMessage.addListener(onmessage)

function onmessage (msg, sender, /** @type {(...args) => void} */resp) {
  if (msg.action === 'askSortBookmarks') {
    (async function () {
      return sendCurrentTab({
        action: 'askSelectBookmarkFolder',
        bookmarks: (await chrome.bookmarks.getTree())[0].children
      })
    }()).then(resp)
  } else if (msg.action === 'sortBookmarks') {
    sortBookmarkFolder(msg.folder).then(resp)
  } else if (msg.action === 'askReadLeftTabsLater') {
    readTabsLater('L').then(resp)
  } else if (msg.action === 'askReadRightTabsLater') {
    readTabsLater('R').then(resp)
  } else if (msg.action === 'askReadCurrentTabLater') {
    readTabsLater('T').then(resp)
  } else if (msg.action === 'askCleanBookmarks') {
    cleanBookmarks().then(resp)
  }
  return true
}
