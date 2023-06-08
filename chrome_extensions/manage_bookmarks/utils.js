const browsers = {
  'edge': ''
}

export async function getBookmarks() {
  const bookmarks = await chrome.bookmarks.getTree()
  console.log(bookmarks)
}
