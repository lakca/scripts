async function importFile () {
  // const localState = await (await fetch('file:///Users/dgrocsky/Library/Application Support/Google/Chrome/Local State')).json()
  // console.log(localState)
  // const importedBookmarks = JSON.parse(await importTextFile('application/json'))
  // const bookmarks = await getBookmarks()
  // Request file system access
  const handle = await window.showOpenFilePicker()
  // Get the file handle
  const file = await handle[0].getFile()
  // Read the file contents
  const content = await file.text()
}
