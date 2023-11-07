import { config } from './config.js'

chrome.runtime.onMessage.addListener(function (msg, sender, /** @type {(...args) => void} */resp) {
  console.log('\x1b[32mpopup onmessage:\x1b[0m', msg, sender)
  if (msg.action === 'pingPopup') {
    resp(true)
  } else if (msg.action === 'window.alert') {
    resp(window.alert(...msg.args))
  } else if (msg.action === 'window.confirm') {
    resp(window.confirm(...msg.args))
  } else if (msg.action === 'window.prompt') {
    resp(window.prompt(...msg.args))
  }
  return true
})

document.body.addEventListener('click', async e => {
  if (e?.target?.role === 'menuitem') {
    chrome.runtime.sendMessage({ action: e?.target?.dataset?.action })
  }
})

document.addEventListener('DOMContentLoaded', () => {
  const div = document.createElement('div')
  div.setAttribute('class', 'twx-w-56 twx-origin-top-right twx-divide-y twx-divide-gray-100 twx-rounded-md twx-bg-white twx-shadow-lg twx-ring-1 twx-ring-black twx-ring-opacity-5')
  let group
  let inline
  const newGroup = () => {
    group = document.createElement('div')
    group.classList.add('twx-py-1')
    div.appendChild(group)
  }
  const newInline = () => {
    inline = document.createElement('div')
    inline.classList.add('twx-flex')
    group.appendChild(inline)
  }
  newGroup()
  config.actions.forEach(action => {
    if (action._group) {
      newGroup()
    }
    const frag = document.createElement('div')
    if (action._icon) {
      frag.innerHTML = action._icon
      frag.children[0].classList.add('twx-icon')
    }
    const html = `
    <div class="twx-action ${action._inline && 'twx-inline'}" role="menuitem" tabindex="-1" data-action="${action.id}">
      ${frag.innerHTML}
      ${action.title}
    </div>
    `
    if (action._inline) {
      inline || newInline()
      inline.innerHTML += html
    } else {
      if (inline) {
        inline = null
      }
      group.innerHTML += html
    }
  })
  document.body.appendChild(div)
})
