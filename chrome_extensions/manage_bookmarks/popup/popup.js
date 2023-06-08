import { getBookmarks } from "../utils.js"

document.body.addEventListener('click', async e => {
  window.tar = e.target
  if (e.target.role === 'menuitem') {
    switch (e.target.dataset.action) {
      case 'export':
        await getBookmarks()
      default:
    }
  }
})
