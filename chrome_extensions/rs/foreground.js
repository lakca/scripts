// This script gets injected into any opened page
// whose URL matches the pattern defined in the manifest
// (see "content_script" key).
// Several foreground scripts can be declared
// and injected into the same or different pages.

console.log("This prints to the console of the page (injected only if the page url matched)")

class WindowKeyListener {
  constructor() {
    /** @type Set<(e: KeyboardEvent) => void> */
    this.keydown = new Set()
    /** @type Set<(e: KeyboardEvent) => void> */
    this.keyup = new Set()
    this.k = []
    this.setup();

    if (window.frameElement?.tagName === "IFRAME") {
      this.withinFrame = true;
      (window.frameElement).addEventListener("load", this.setup, { capture: true, passive: true })
    }
  }
  setup = () => {
    window.addEventListener("keydown", this.handleKeyDown, true)
    window.addEventListener("keyup", this.handleKeyUp, true)
  }
  release = () => {
    window.removeEventListener("keydown", this.handleKeyDown, true)
    window.removeEventListener("keyup", this.handleKeyUp, true)
  }
  handleKeyDown = (e) => {
    this.keydown.forEach(cb => {
      cb(e)
    })
  }
  handleKeyUp = (e) => {
    this.keyup.forEach(cb => {
      cb(e)
    })
  }
}

const keyListener = new WindowKeyListener()

keyListener.keydown.add(e => {
  const tag = e.target.tagName
  if (!['INPUT', 'TEXTAREA'].includes(tag)) {
    if (!(e.altKey || e.ctrlKey || e.metaKey || e.shiftKey)) {
      handleKeydown(e)
    }
  }
})

/**
 * @param {KeyboardEvent} e
 * @returns
 */
function handleKeydown(e) {
  if (window.location.origin === 'https://docs.rs') {
    /** @type HTMLAnchorElement[] */
    const links = [...document.body.querySelectorAll('.pure-menu a.pure-menu-link')]
    /** @type {((name: string|function) => HTMLAnchorElement) & (<T extends boolean>(name: string|function, returnHref: T) => T extends true ? string : HTMLAnchorElement)} */
    const getLink = (name, returnHref) => {
      const link = typeof name === 'function' ? links.find(name) : links.find(el => el.innerText.trim().toLowerCase().includes(name))
      return returnHref ? link?.href : link
    }
    switch (e.key) {
      case 'm': window.open(getLink(el => el.classList.contains('crate-name'), true)); break
      case 'r': case 'g': window.open(getLink('repository', true)); break
      case 'c': window.open(getLink('crates.io', true)); break
      case 's': window.open(getLink('source', true)); break
      case 'd': window.open(getLink('documentation', true)); break
      case 'c': document.getElementById('clipboard')?.click(); break
      case 'f': {
        const mouseoverEvent = new Event('mouseover')
        getLink('feature', false)?.parentElement?.dispatchEvent(mouseoverEvent)
      } break
      case '?':
        alert(`
        m: crate-name
        r|g: repository
        c: crate
        s: source
        d: documentation
        p: documentation
        c: clipboard
        `)
        break
      default:
        return
    }
  } else if (window.location.origin === 'https://crates.io') {
    const headers = [...document.body.querySelectorAll('h2')]
    /** @type {((name: string|function) => Element) & (<T extends boolean>(name: string|function, returnHref: T) => T extends true ? string : Element)} */
    const getEl = (name, returnHref) => {
      const header = typeof name === 'function' ? headers.find(name) : headers.find(el => el.innerText.trim().toLowerCase().includes(name))
      return returnHref ? header?.nextElementSibling?.querySelector('a')?.href : header
    }
    switch (e.key) {
      case 'r': case 'g': window.open(getEl('repository', true)); break
      case 'd': window.open(getEl('documentation', true)); break
      case '?':
        alert(`
          r|g: repository
          d: documentation
          `)
        break
      default:
        return
    }
  }
  console.log('trigger', e.key)
  e.stopPropagation()
}
