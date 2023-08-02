import { cleanBookmarks, readTabsLater, callWindow, sortBookmarkFolder, alert } from './headless.js'
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
  console.log('worker', msg, sender)
  if (msg.action === 'askSortBookmarks') {
    (async function () {
      const [connected, result] = await callWindow({
        action: 'askSelectBookmarkFolder',
        bookmarks: (await chrome.bookmarks.getTree())[0].children
      }, { forceWebpage: true })
      if (connected) {
        return result
      } else {
        alert('由于弹窗的限制，请在网页（页面地址以https,https,file或ftp开头）中执行此命令!如果已经在，请刷新当前页面后再执行此命令')
      }
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
