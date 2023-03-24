// ==UserScript==
// @name         Fuck
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @noframes
// @match        *://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=zhihu.com
// @grant        unsafeWindow
// @grant        GM_addElement
// @grant        GM_addStyle
// @grant        GM_download
// @grant        GM_getResourceText
// @grant        GM_getResourceURL
// @grant        GM_info
// @grant        GM_log
// @grant        GM_notification
// @grant        GM_openInTab
// @grant        GM_registerMenuCommand
// @grant        GM_unregisterMenuCommand
// @grant        GM_setClipboard
// @grant        GM_getTab
// @grant        GM_saveTab
// @grant        GM_getTabs
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_deleteValue
// @grant        GM_listValues
// @grant        GM_addValueChangeListener
// @grant        GM_removeValueChangeListener
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function() {
    'use strict';
    const document = unsafeWindow.document
    const window = unsafeWindow
    const idp = 'fuck-' + Date.now() + '_'
    const listeners = new Set()
    function cls(name) {
        return {
            add(el) {
                el.classList.add(this.toString())
            },
            remove(el) {
                el.classList.remove(this.toString())
            },
            toggle(el, force) {
                el.classList.toggle(this.toString(), force)
            },
            toString() {
                return `${idp}${name}`
            },
            valueOf() {
                return this.toString()
            },
        }
    }
    function el(tag) {
        const el = document.createElement(tag)
        return {
            get el() {
                return el
            },
            inner(html) {
                el.innerHTML = html
                return this
            },
            appendChild(...e) {
                e.forEach(i => el.appendChild(i.el || i))
                return this
            },
            appendChildTo(e) {
                (e.el || e).appendChild(el)
                return this
            },
            remove() {
                el.parentElement?.removeChild(el)
                return this
            }
        }
    }
    function data(name) {
        return {
            print() {
                return GM_log(this)
            },
            copy() {
                GM_setClipboard(name, 'text')
                return this
            },
            save(value) {
                GM_setValue(name, value)
                return this
            },
            drop() {
                GM_deleteValue(name)
                return this
            },
            watch(handler) {
                const id = GM_addValueChangeListener(name, (key, oldValue, newValue, remote) => handler(newValue, oldValue, remote, key))
                listeners.add(id)
                return id
            },
            unwatch(id) {
                GM_removeValueChangeListener(id)
                return this
            },
            /** @return {string[]} */
            keys() {
                return GM_listValues()
            },
            valueOf() {
                return GM_getValue(name)
            },
            get value() {
                return this.valueOf()
            }
        }
    }
    function menu(name) {
        return {
            register(handler, accessKey) {
                return GM_registerMenuCommand(name, handler, accessKey)
            },
            unregister(id) {
                return GM_unregisterMenuCommand(id)
            },
        }
    }
    function query(selector, all=false) {
        const single = (typeof selector === 'string' && !all) || !Array.isArray(selector)
        const elements = typeof selector === 'string' ? all ? Array.from(document.body.querySelectorAll(selector) || []) : [document.body.querySelector(selector)] : Array.isArray(selector) ? selector : [selector]
        return {
            remove() {
                elements.forEach(e => e?.remove())
            },
            style(name, value, ...more) {
                if (arguments.length < 2) {
                    const data = elements.map(e => window.getComputedStyle(e).getPropertyValue(name))
                    return single ? data[0] : data
                }
                elements.forEach(e => e?.style?.setProperty(name, value, ...more))
            },
        }
    }
    GM_addStyle(`
        .${cls('hidden')} {
            display: none!important;
        }
        .${cls('select-none')} {
            user-select: none;
        }
    `)
    function observe(dom) {
        /** @type Record<'attributes', Record<string, function[]>> & Record<'addChild' | 'removeChild', function[]> */
        const listeners = {
            addChild: [],
            removeChild: [],
            attributes: {},
        }
        const observer = new window.MutationObserver(function(mutationList) {
            mutationList.forEach((mutation) => {
                switch(mutation.type) {
                    case 'childList':
                    /* 从树上添加或移除一个或更多的子节点；参见 mutation.addedNodes 与
                        mutation.removedNodes */
                        mutation.addedNodes.forEach(node => {
                            listeners.addChild.forEach(e => e(node))
                        })
                        mutation.removedNodes.forEach(node => {
                            listeners.removeChild.forEach(e => e(node))
                        })
                    break;
                    case 'attributes':
                    /* mutation.target 中某节点的一个属性值被更改；该属性名称在 mutation.attributeName 中，
                        该属性之前的值为 mutation.oldValue */
                        listeners.attributes[mutation.attributeName]?.forEach(e => e(mutation.target.getAttribute(mutation.attributeName), mutation.oldValue))
                    break;
                }
            });
        })
        return {
            addChild(cb) {
                listeners.addChild.push(cb)
                observer.observe(dom, {
                    childList: true,
                })
            },
            removeChild(cb) {
                listeners.removeChild.push(cb)
                observer.observe(dom, {
                    childList: true,
                })
            },
            attribute(attributes, cb) {
                attributes = Array.isArray(attributes) ? attributes : [attributes]
                attributes.forEach(e => {
                    listeners.attributes[e] = listeners.attributes[e] || []
                    listeners.attributes[e].push(cb)
                })
                observer.observe(dom, {
                    attributeFilter: attributes,
                    attributeOldValue: true,
                })
            },
            all() {
                observer.observe(dom, {
                    subtree: true,
                    childList: true,
                    attributes: true,
                    attributeFilter: true,
                    attributeOldValue: true,
                    characterData: true,
                    characterOldData: true,
                })
            },
        }
    }
    function checkHref(pattern, key = 'hostname') {
        if (pattern instanceof window.RegExp) {
            return pattern.test(window.location[key])
        } else if (typeof pattern === 'string') {
            return window.location[key].indexOf(pattern) > -1
        } else {
            return window.Object.keys(pattern).reduce((f, k) => checkHref(pattern[k], k), true)
        }
    }
    function fuck() {
        if (checkHref('.zhihu.com')) {
            const banner = document.body.querySelector('[role=banner]')
            data('知乎Banner').save(true).watch((val) => {
                cls('hidden').toggle(banner, !!val)
            })
            observe(document.body).addChild(function(node) {
                if (node && node.querySelector('.Modal-wrapper')) {
                    node.querySelector('.Button.Modal-closeButton')?.click()
                }
                else if (/(登陆|注册)/.test(node && node.querySelector('Button')?.textContent || '')) {
                    node.remove()
                }
            })
        } else if (checkHref('.csdn.net')) {
            observe(document.body).addChild(function(node) {
                node.classList.contains('passport-login-container') && node.remove()
            })
            query('#csdn-toolbar').remove()
            query('#toolBarBox').remove()
            query('#blogColumnPayAdvert').remove()
            query('#blogExtensionBox').remove()
            query('#treeSkill').remove()
            query('#recommendNps').remove()
            query('.blog-footer-bottom').remove()
            query(document.body).style('background', query('.blog-content-box').style('background-color'), 'important')
            Array.from(document.body.querySelector('.blog_container_aside')?.children || []).forEach(e => e.id !== 'asidedirectory' && e?.remove())
        } else if (checkHref('.baidu.com')) {
            Array.from(document.getElementById('content_left')?.children || []).forEach(e => e.classList.contains('result') || e?.remove())
        }
    }
    window.fuck = fuck
    fuck()
    function opense(type) {
        const a = document.body.querySelector('input[type=search], input:not([type=hidden])')
        const word = a?.value.trim() || a?.placeholder.trim() || document.querySelector('h1')?.textContent.trim()
        if (!word ) return
        const sites = {
            百度: `https://www.baidu.com/s?wd=${word}`,
            谷歌: `https://www.google.com/search?q=${word}`,
            必应: `https://www.bing.com/search?q=${word}`,
            google: `https://www.google.com/search?q=${word}`,
            有道: `https://youdao.com/result?word=${word}&lang=en`,
        }
        console.log(type, sites[type])
        GM_openInTab(sites[type])
    }
    function renderSettings() {
        const settings = el('div')
        cls('settings').add(settings.el)
        settings.el.style = 'position: fixed; z-index: 99999999; left: 0; top: 0px; max-width: 500px; max-height: 600px; background: white; padding: 20px;border: solid 1px lightgray; box-shadow: 2px 2px 10px gray'
        const keys = data().keys()
        const wrap = document.createDocumentFragment()
        keys.forEach(key => {
            const val = data(key).value
            const p = el('p').appendChildTo(wrap)
            const label = el('label').appendChildTo(p).inner(key).el
            label.setAttribute('for', key)
            cls('select-none').add(label)
            const input = el('input').appendChildTo(p).el
            input.id = key
            if (typeof val === 'boolean') {
                input.type = 'checkbox'
                input.onchange = e => data(key).save(e.target.checked)
            } else if (typeof val === 'string') {
                input.type = 'text'
                input.onchange = e => data(key).save(e.target.value)
            } else if (typeof val === 'number') {
                input.type = 'number'
                input.onchange = e => data(key).save(e.target.value)
            }
        })

        const p = el('p').appendChildTo(wrap)
        el('button').inner('百度').appendChildTo(p).el.onclick = (e) => opense(e.target.textContent)
        el('button').inner('谷歌').appendChildTo(p).el.onclick = (e) => opense(e.target.textContent)
        el('button').inner('必应').appendChildTo(p).el.onclick = (e) => opense(e.target.textContent)
        el('button').inner('关闭').appendChildTo(el('p').appendChildTo(wrap)).el.onclick = e => settings.remove()
        settings.appendChild(wrap)
        return settings
    }
    menu('设置').register(function() {
        document.body.appendChild(renderSettings().el)
    })
    // Your code here...
})();
