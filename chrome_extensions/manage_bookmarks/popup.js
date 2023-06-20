import { cleanBookmarks, exportBookmarks, importBookmarks, readTabsLater } from "./utils.js"

document.body.addEventListener('click', async e => {
  if (e.target.role === 'menuitem') {
    switch (e.target.dataset.action) {
      case 'clean':
        await cleanBookmarks()
        break
      case 'export':
        await exportBookmarks()
        break
      case 'import':
        await importBookmarks()
        break
      case 'readLeftTabsLater':
        await readTabsLater('L')
        break
      case 'readRightTabsLater':
        await readTabsLater('R')
        break
      default:
    }
  }
})
