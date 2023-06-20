// import { readLeftTabsLater } from "./utils"

chrome.runtime.onInstalled.addListener(() => {
  const readRightTabsLater = chrome.contextMenus.create({
    type: 'normal',
    contexts: ['all'],
    id: 'readRightTabsLater',
    title: '稍后阅读右侧标签页',
  })
  const readLeftTabsLater = chrome.contextMenus.create({
    type: 'normal',
    contexts: ['all'],
    id: 'readLeftTabsLater',
    title: '稍后阅读左侧标签页',
  })
})

chrome.contextMenus.onClicked.addListener((info, tab) => {
  console.log(info.menuItemId)
  switch (info.menuItemId) {
    case 'readLeftTabsLater':
      // readLeftTabsLater()
      break
    case 'readRightTabsLater':
      break
    default:
  }
})

chrome.omnibox.onInputChanged.addListener((text, suggest) => {
  console.log(text, suggest)
})
