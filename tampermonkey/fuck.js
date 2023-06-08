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

(function () {
    'use strict';
    const document = unsafeWindow.document
    const window = unsafeWindow
    const idp = 'fuck-' + Date.now() + '_'
    const listeners = new Set()
    const hiddenSelector = `.${cls('hidden')}, [${cls('hidden')}]`
    const style = GM_addStyle(`
        ${hiddenSelector} {
            display: none!important;
        }
        .${cls('select-none')}, [${cls('select-none')}] {
            user-select: none;
        }
    `)
    data('显示').watch(flag => {
        if (flag) style.sheet.deleteRule([...style.sheet.rules].findIndex(rule => {
            return rule.selectorText === hiddenSelector
        }))
        else style.sheet.insertRule(`${hiddenSelector} { display: none!important; }`, 0)
    })
    data('显示').save(false)
    function sleep(seconds) {
        return new Promise((resolve, reject) => {
            setTimeout(resolve, seconds * 1000)
        })
    }
    function cls(name, attribute = false) {
        name = name.trim()
        return {
            add(el) {
                attribute ? el?.toggleAttribute(this, true) : el?.classList.add(this.toString())
            },
            remove(el) {
                attribute ? el?.toggleAttribute(this, false) : el?.classList.remove(this.toString())
            },
            toggle(el, force) {
                attribute ? el?.toggleAttribute(this) : el?.classList.toggle(this.toString(), force)
            },
            toString() {
                return `${idp}${name}`
            },
            valueOf() {
                return this.toString()
            },
            get son() {
                cls._cache = cls._cache || {}
                let son = cls._cache[name]
                if (!son) {
                    son = /:scope\s*\>/.test(name) ? name : `:scope > ${name}`
                    cls._cache[name] = son
                }
                return son
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
            clear() {
                this.keys().forEach(e => data(e).drop())
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
    function query(selector, all) {
        const single = (typeof selector === 'string' && !all) || !Array.isArray(selector)
        const elements = typeof selector === 'string' ? all ? Array.from(document.querySelectorAll(selector) || []) : [document.querySelector(selector)] : Array.isArray(selector) ? selector : [selector]
        return {
            remove(hidden = false, force = false) {
                hidden ? this.hidden(force) : elements.forEach(e => e?.remove())
            },
            style(name, value, ...more) {
                if (arguments.length < 2) {
                    const data = elements.map(e => window.getComputedStyle(e).getPropertyValue(name))
                    return single ? data[0] : data
                }
                elements.forEach(e => e?.style?.setProperty(name, value, ...more))
            },
            cls(name, force) {
                const c = cls(name)
                elements.forEach(e => c.toggle(e, force))
            },
            attr(name, force) {
                const c = cls(name, true)
                elements.forEach(e => c.toggle(e, force))
            },
            hidden(force) {
                return this.attr('hidden', force)
            },
            get el() {
                return single ? elements[0] : elements
            },
            all(selector) {
                return Array.from(elements[0].querySelectorAll(selector))
            },
        }
    }
    function observe(dom) {
        /** @type Record<'attributes', Record<string, function[]>> & Record<'addChild' | 'removeChild', function[]> */
        const listeners = {
            addChild: [],
            removeChild: [],
            attributes: {},
        }
        const observer = new window.MutationObserver(function (mutationList) {
            mutationList.forEach((mutation) => {
                switch (mutation.type) {
                    case 'childList':
                        /* 从树上添加或移除一个或更多的子节点；参见 mutation.addedNodes 与
                            mutation.removedNodes */
                        mutation.addedNodes.forEach(node => {
                            listeners.addChild.forEach(e => (node instanceof Element) && e(node, mutation.target))
                        })
                        mutation.removedNodes.forEach(node => {
                            listeners.removeChild.forEach(e => (node instanceof Element) && e(node, mutation.target))
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
            addChild(cb, subtree = false) {
                listeners.addChild.push(cb)
                observer.observe(dom, {
                    childList: true,
                    subtree,
                })
            },
            removeChild(cb, subtree = false) {
                listeners.removeChild.push(cb)
                observer.observe(dom, {
                    childList: true,
                    subtree,
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
        } else if (Array.isArray(pattern)) {
            for (const e of pattern) {
                const r = checkHref(e)
                if (r) return true
            }
        } else {
            return window.Object.keys(pattern).reduce((f, k) => checkHref(pattern[k], k), true)
        }
    }
    const observer = {
        /** @type [Element, string, string, function, boolean?][] */
        _list: [],
        watch(ancestor, type, selector, handler, config = {}) {
            if (selector == null) {
                selector = ancestor
                ancestor = document
            }
            const opts = { remove: false, }
            handler = Array.isArray(handler) ? [handler[0], handler[1] || handler[0]] : [handler, handler]
            ancestor = typeof ancestor === 'string' ? document.querySelector(ancestor) : ancestor
            this._list.push([ancestor, type, selector, handler])
            observe(ancestor).addChild(node => handler[0] && handler[0](ancestor, selector, node, opts), config.subtree)
            this.run()
            return function config(options) { Object.assign(opts, options) }
        },
        in(ancestor, selector, config = {}) {
            return this.watch(ancestor, 'in', selector, [(ancestor, selector, node) => {
                node.parentElement.querySelector(cls(selector).son) === node && query(node).remove(!config.remove, true)
            }, (ancestor, selector) => {
                query(ancestor).all(selector).forEach(e => query(e).remove(!config.remove, true))
            }], config)
        },
        not(ancestor, selector, config = {}) {
            return this.watch(ancestor, 'not', selector, [(ancestor, selector, node) => {
                node.parentElement.querySelector(cls(selector).son) && query(node).remove(!config.remove, true)
            }, (ancestor, selector) => {
                query(ancestor).all(selector).forEach(e => Array.from(e.parentElement.children).forEach(f => f !== e && query(f).remove(!config.remove, true)))
            }], config)
        },
        before(ancestor, selector, config = {}) {
            return this.watch(ancestor, 'before', selector, [(ancestor, selector, node) => {
                const children = Array.from(node.parentElement.children)
                const e = node.parentElement.querySelector(cls(selector).son)
                if (e && (children.indexOf(e) > children.indexOf(node))) {
                    query(node).remove(!config.remove, true)
                }
            }, (ancestor, selector) => {
                query(ancestor).all(selector).forEach(e => Array.from(e.parentElement.children).some(f => f !== e && query(f).remove(!config.remove, true) || true))
            }], config)
        },
        after(ancestor, selector, config = {}) {
            return this.watch(ancestor, 'after', selector, [(ancestor, selector, node) => {
                const children = Array.from(node.parentElement.children)
                const e = node.parentElement.querySelector(cls(selector).son)
                if (e && (children.indexOf(e) < children.indexOf(node))) {
                    query(node).remove(!config.remove, true)
                }
            }, (ancestor, selector) => {
                query(ancestor).all(selector).forEach(e => Array.from(e.parentElement.children).reverse().some(f => f !== e && query(f).remove(!config.remove, true)))
            }], config)
        },
        run() {
            this._list.forEach(e => {
                if (!e[4]) {
                    e[3][1](e[0], e[2])
                    e[4] = true
                }
            })
        },
    }
    async function fuck() {
        if (checkHref('.zhihu.com')) {
            query('[role=banner]').hidden(true)
            observe(document.body).addChild(function (node) {
                if (node?.querySelector('.Modal-wrapper')) {
                    node.querySelector('.Button.Modal-closeButton')?.click()
                }
                else if (/(登陆|注册)/.test(node?.querySelector('Button')?.textContent || '')) {
                    node.remove()
                }
            }, true)
            if (checkHref('zhuanlan.zhihu.com')) {
                await sleep(1)
                observer.before('.Post-content', '.Post-Main')
            }
        } else if (checkHref('.csdn.net')) {
            observer.in(document.body, '.passport-login-container', { remove: true })
            observer.in(document.body, '.passport-container', { remove: true })
            query('#csdn-toolbar').hidden(true)
            query('#toolBarBox').hidden(true)
            query('#blogColumnPayAdvert').hidden(true)
            query('#blogExtensionBox').hidden(true)
            query('#treeSkill').hidden(true)
            query('#recommendNps').hidden(true)
            query('.blog-footer-bottom').hidden(true)
            query('.csdn-side-toolbar').hidden(true)
            query(document.body).style('background-image', 'transparent', 'important')
            observer.not('.blog_container_aside', '#asidedirectory')
        } else if (checkHref('.baidu.com')) {
            Array.from(document.getElementById('content_left')?.children || []).forEach(e => e.classList.contains('result') || e?.hidden(true))
            observer.in('.passport-login-container', null, { remove: true })
        } else if (checkHref(['stackoverflow.com', 'stackexchange.com', 'superuser.com'])) {
            observer.in('.js-consent-banner')
        } else if (checkHref('juejin.cn')) {
            observer.in('#juejin', '.recommend-box')
            observer.in('#juejin', '.login-guide-popup', { remove: true })
            observer.in('#juejin', '.sidebar-bd-entry', true)
            observer.in('#juejin', '.guide-collect-popover', true)
            observer.in('#juejin', '.main-header-box', true)
        }
    }
    function opense(type) {
        const a = document.querySelector('input[type=search], input:not([type=hidden])')
        const word = a?.value.trim() || a?.placeholder.trim() || document.querySelector('h1')?.textContent.trim()
        if (!word) return
        const sites = {
            百度: `https://www.baidu.com/s?wd=${word}`,
            谷歌: `https://www.google.com/search?q=${word}`,
            必应: `https://www.bing.com/search?q=${word}`,
            google: `https://www.google.com/search?q=${word}`,
            有道: `https://youdao.com/result?word=${word}&lang=en`,
        }
        GM_openInTab(sites[type])
    }
    let settings
    function renderSettings() {
        settings && settings.remove()
        settings = el('div')
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
            input.value = data(key).value
            if (typeof val === 'boolean') {
                input.type = 'checkbox'
                input.checked = !!data(key).value
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
        el('button').inner('链接').appendChildTo(p).el.onclick = (e) => GM_setClipboard(`[${document.title}](${window.location.href})`)
        el('button').inner('关闭').appendChildTo(el('p').appendChildTo(wrap)).el.onclick = e => settings.remove()
        settings.appendChild(wrap)
        return settings
    }
    menu('复制链接').register(function () {
        GM_setClipboard(`[${document.title}](${window.location.href})`)
    })
    menu('设置').register(function () {
        document.body.appendChild(renderSettings().el)
    })

    const tamper = window.tamper = {
        cls, el, data, menu, query, observe, observer, checkHref, fuck, opense, renderSettings,
    }
    fuck()
    // Your code here...

    function douyin_user_home() {
        const data = (() => {
            return JSON.parse(decodeURIComponent(RENDER_DATA.textContent))
        })();
        const results = (
            (data) => {
                const idx = Object.keys(data).filter(e => /^\d+$/.test(e) && e > 1)[0]
                return data[idx]?.post?.data?.map(e => {
                    return {
                        desc: e.desc,
                        awemeId: e.awemeId,
                        groudId: e.groudId,
                        download: e.download.url,
                        urls: e.video.playAddr.map(e => 'https:' + e.src),
                        author: e.authorInfo.nickname,
                        uid: e.authorInfo.uid,
                        secUid: e.authorInfo.secUid,
                        avatar: e.authorInfo.avatarUri,
                        music: e.music.musicName,
                        musicAuthor: e.music.author,
                        musicAvatar: e.music.avatarThumb.uri,
                        musicUrl: e.music.playUrl.uri,
                        images: e.images.map(e => e.urlList.find(e => /\.(jpeg|png|jpg)/.test(e)))
                    }
                })
            }
        )(data);
        console.log(results)
    }

    function douyin_share() {
        const data = (() => {
            return JSON.parse(decodeURIComponent(RENDER_DATA.textContent))
        })();
        const results = (
            (data) => {
                const idx = Object.keys(data).filter(e => /^\d+$/.test(e) && e > 1)[0]
                return {
                    desc: data[idx].aweme.detail.desc,
                    awemeId: data[idx].aweme.detail.awemeId,
                    groudId: data[idx].aweme.detail.groudId,
                    author: data[idx].aweme.detail.authorInfo.nickname,
                    uid: data[idx].aweme.detail.authorInfo.uid,
                    secUid: data[idx].aweme.detail.authorInfo.secUid,
                    avatar: data[idx].aweme.detail.authorInfo.avatarUri,
                    urls: data[idx].aweme.detail.video.playAddr.map(e => 'https:' + e.src),
                    music: data[idx].aweme.detail.music.musicName,
                    musicAuthor: data[idx].aweme.detail.music.author,
                    musicAvatar: data[idx].aweme.detail.music.avatarThumb.uri,
                    musicUrl: data[idx].aweme.detail.music.playUrl.uri,
                }
            }
        )(data);
        console.log(results)
    }

    window.douyin_user_home = douyin_user_home
    window.douyin_share = douyin_share

    switch (window.location.hostname) {
        // 毛泽东纪念堂
        case 'jnt.mfu.com.cn':
            mzd(['0429', '0430', '0501', '0502', '0503']).run(); break
        // 抗日战争纪念馆
        case 'bjkzg.hdwbcloud.com':
            kangri().run(); break
        // 军事博物馆
        case 'ticket.jb.mil.cn':
            junbo().run(); break
        // 恭王府
        case 'web.pgm.org.cn':
            gongwangfu().run(); break
    }
    function immeidate() {
        return new Promise((resolve) => {
            window.setTimeout(resolve, 0)
        })
    }
    function waitSelector(selector) {
        return waitFor(() => {
            return document.querySelector(selector)
        })
    }
    function waitFor(fn, cycle = 500) {
        return new Promise((resolve) => {
            const t = setInterval(() => {
                const r = fn()
                if (r) {
                    clearInterval(t)
                    resolve(r)
                }
            }, cycle)
        })
    }
    function input(inputEl, value, isSelect) {
        if (isSelect) return inputSelect(inputEl, value)
        inputEl.value = typeof value === 'function' ? value(inputEl) : value
        inputEl.dispatchEvent(new Event('input', { 'bubbles': true }))
        inputEl.dispatchEvent(new Event('change', { 'bubbles': true }))
        inputEl.dispatchEvent(new Event('blur', { 'bubbles': true }))
    }
    function inputSelect(selectEl, text) {
        const options = Array.from(selectEl.querySelectorAll('option')).map(node => ({ node, value: node.value, text: node.textContent.trim() }))
        for (const opt of options) {
            if (opt.text.indexOf(text) > -1) {
                input(selectEl, opt.value, false)
                return
            }
        }
    }
    function reload() {
        setTimeout(() => {
            let flag = true
            flag = window.confirm('刷新页面？')
            flag && window.location.reload()
        }, 1000)
    }
    function log(type, ...args) {
        switch (type) {
            case 'NO_DATE':
                console.log(`%c没有可选日期`, 'color:inherit'); break
            case 'NO_TIME':
                console.log(`%c${args[0]} 没有可选时间`, 'color:inherit'); break
            case 'NO_ENOUGH':
                console.log(`%c${args[1]} ${args[2]} 只有${args[0]}余票，数量不够`, 'color:orange'); break
            case 'NO_DATE_EXPECTED':
                console.log(`%c${args[0]} 可选，但不在预期`, 'color:orange'); break
            case 'NO_TIME_EXPECTED':
                console.log(`%c${args[0]} ${args[1]} 可选，但不在预期`, 'color:orange'); break
            case 'SUBMIT':
                console.log(`%c${args[0]} ${args[1]} 确认时间✅`, 'color:green;font-weight:bold'); break

        }
    }
    function mzd(dates) {
        return {
            dates: [
                '0429',
                '0430',
                '0501',
                '0502',
                '0503',
            ],
            times: [
                '08:00',
                '08:45',
                '09:30',
                '10:15',
                '11:00',
            ],
            data: [
                { name: "张三", cardno: "身份证号", phone: 手机号 },
                { name: "李四", cardno: "身份证号", phone: 手机号 },
                { name: "赵五", cardno: "身份证号", phone: 手机号 },
            ],
            removePopup() {
                document.querySelector('.yynoticetipicon')?.parentElement?.remove()
                document.querySelector('.v-modal')?.remove()
            },
            async selectDate() {
                this.removePopup()
                observe(document.body).addChild(node => this.removePopup())
                await waitSelector('.selectdate-day li')
                const dates = Array.from((await waitSelector('.selectdate-day')).querySelectorAll('.day:not(.disable)'))
                    .map(node => ({ node, text: node.textContent.replace(/\s/g, '').slice(0, 4) }))
                if (!dates.length) log('NO_DATE')
                for (const date of dates) {
                    if (this.dates.includes(date.text)) {
                        date.node.click()
                        await immeidate()
                        const times = Array.from((await waitSelector('.selectdate-time')).querySelectorAll('.times:not(.disabled)'))
                            .map(node => ({ node, text: node.textContent.trim().replace(/\s/g, '').slice(0, 5) }))
                        if (!times.length) log('NO_TIME', date.text)

                        for (const time of times) {
                            if (this.times.includes(time.text)) {
                                time.node.click()
                                await immeidate()
                                // "个人预约"按钮
                                document.querySelector('.btn-group button').click()
                                log('SUBMIT', date.text, time.text)
                                await immeidate()
                                return
                            } else {
                                log('NO_TIME_EXPECTED', date.text, time.text)
                            }
                        }
                    } else {
                        log('NO_DATE_EXPECTED', date.text)
                    }
                }
                reload()
            },
            async fillInfo() {
                const data = this.data
                await waitSelector('.adduserbtn')
                const addBtn = document.querySelector('.adduserbtn')
                for (const d of data.slice(1)) {
                    await immeidate()
                    addBtn.click()
                    const dialog = await waitFor(() => {
                        const dialogs = Array.from(document.querySelectorAll('.el-dialog__wrapper'))
                        for (const dialog of dialogs) {
                            const title = dialog.querySelector('.header')?.textContent?.trim()
                            if (title === '编辑瞻仰人') return dialog
                        }
                    })
                    const inputs = Array.from(dialog.querySelectorAll('input'))
                    const submitOne = dialog.querySelector('.btn-group button')
                    input(inputs[0], d.name)
                    await sleep(1)
                    input(inputs[2], d.cardno)
                    await sleep(1)
                    submitOne.click()
                    await waitFor(() => {
                        return window.getComputedStyle(dialog).display === 'none'
                    })
                }
                // 确定按钮（填写预约信息）
                document.querySelector('.editeorder-btn button').click()
            },
            async submit() {
                // 提交按钮（确认预约信息）
                const submit = await waitFor(() => {
                    const btns = Array.from(document.querySelectorAll('.editeorder-btn button'))
                    return btns.find(btn => btn.textContent.trim() === '提交')
                })
                const info = document.querySelector('.process-date').textContent.trim()
                if (window.confirm(`${info}\n确认预约？`)) {
                    submit.click()
                    console.log('submit!')
                }
            },
            async run() {
                await waitSelector('.steps')
                const title = () => {
                    const titles = Array.from(document.querySelectorAll('.steps .active')).map(e => e.textContent.trim())
                    return titles[titles.length - 1]
                }
                switch (title()) {
                    case '1-选择瞻仰日期':
                        await this.selectDate()
                        await waitFor(() => title() === '2-填写预约信息')
                        await this.fillInfo()
                        await waitFor(() => title() === '3-确认预约信息')
                        await this.submit()
                        break
                    case '2-填写预约信息':
                        await this.fillInfo()
                        await waitFor(() => title() === '3-确认预约信息')
                        await this.submit()
                        break
                    case '3-确认预约信息':
                        await this.submit()
                        break
                    default:
                        await sleep(3)
                        this.run()
                }
            }
        }
    }
    function kangri() {
        return {
            // ['4月29日', ...]
            dates: [
                // '4月29日',
                '4月30日',
                '5月1日',
                // '5月2日',
                // '5月3日',
            ],
            times: [
                '14:00',
                '11:00',
                '09:00',
            ],
            data: [
                "张三",
                "身份证号",
                "李四",
                "身份证号",
                "赵五",
                "身份证号",
                "手机号"
            ],
            async selectDate() {
                await waitSelector('.date-ul li')
                const dates = Array.from(document.querySelectorAll('.date-ul li:not(.forbid_click)'))
                    .map(node => ({ node, text: node.textContent.trim().split(/\s/)[0] })).sort((a, b) => {
                        return this.dates.indexOf(a.text) - this.dates.indexOf(b.text)
                    })
                if (!dates.length) log('NO_DATE')
                for (const date of dates) {
                    if (this.dates.includes(date.text)) {
                        date.node.click()
                        await immeidate()
                        const times = Array.from(document.querySelectorAll('.time-box li:not(.forbid_click)'))
                            .map(node => ({ node, text: node.textContent.replace(/\s/g, '').slice(0, 5) })).sort((a, b) => {
                                return this.times.indexOf(a.text) - this.times.indexOf(b.text)
                            })
                        if (!times.length) log('NO_TIME', date.text)
                        for (const time of times) {
                            if (this.times.includes(time.text)) {
                                time.node.click()
                                await immeidate()
                                const submit = document.querySelector('.apply-btn')
                                log('SUBMIT', date.text, time.text)
                                submit.click()
                                return
                            } else {
                                log('NO_TIME_EXPECTED', date.text, time.text)
                            }
                        }
                    } else {
                        log('NO_DATE_EXPECTED', date.text)
                    }
                }
                reload()
            },
            async fillData() {
                const data = this.data
                await waitSelector('.add-btn')
                const addBtn = document.querySelector('.add-btn')
                await waitSelector('.visit-info ul li')
                for (let i = ((data.length - 1) / 2 - 1); i--;) {
                    await immeidate()
                    addBtn.click()
                    await immeidate()
                }
                const inputs = Array.from(document.querySelectorAll('input.ivu-input-large'))
                inputs.forEach((el, i) => {
                    input(el, data[i])
                })
                await waitSelector('.next')
                document.querySelector('.next').click()
            },
            async submit() {
                await waitSelector('.submit')
                const info = document.querySelector('.info').textContent.replace(/\s+/g, ' ')
                if (window.confirm(`${info}\n确认预约？`)) {
                    document.querySelector('.submit').click()
                    console.log('submit!')
                }
            },
            async run() {
                await waitSelector('.step-title')
                const title = () => document.querySelector('.step-title').textContent.trim()
                switch (title()) {
                    case '选择参观日期':
                        await this.selectDate()
                        await waitFor(() => title() === '填写观众信息')
                        await this.fillData()
                        await waitFor(() => title() === '确认预约')
                        await this.submit()
                        break
                    case '填写观众信息':
                        await this.fillData()
                        await waitFor(() => title() === '确认预约')
                        await this.submit()
                        break
                    case '确认预约':
                        await this.submit()
                        break
                }
            },
        }
    }
    function junbo() {
        return {
            dates: [
                '0429',
                '0430',
                '0501',
                '0502',
                '0503',
            ],
            times: [
                '08:00',
                '08:45',
                '09:30',
                '10:15',
                '11:00',
            ],
            data: [
                { name: "张三", cardno: "身份证号", phone: 手机号, type: '成人' },
            ],
            async selectDate() {
                await waitSelector('.calen-nav-tab')
                const dates = Array.from(document.querySelectorAll('.calen-nav-tab td'))
                    .map(node => ({ node, text: node.querySelector('.date')?.value?.trim() })).filter(e => e.text)
                if (!dates.length) log('NO_DATE')
                for (const date of dates) {
                    if (this.dates.includes(date.text)) {
                        date.node.click()
                        await immeidate()
                        document.querySelector('#SingleTicket').click()
                    } else {
                        log('NO_DATE_EXPECTED', date.text)
                    }
                }
            },
            async fillInfo() {
                const addBtn = await waitSelector('.add')
                for (let i = this.data.length - 1; i--;) addBtn.click()
                const items = Array.from(document.querySelectorAll('#perbox .addh_541'))
                items.forEach((item, i) => {
                    const selects = Array.from(item.querySelectorAll('select.ticket'))
                    const opt = Array.from(selects[0].querySelectorAll('option')).find(opt => opt.textContent.indexOf(this.data[i].type) > -1)
                    input(selects[0], opt.value)
                    const inputs = Array.from(item.querySelectorAll('input'))
                    input(inputs[0], this.data[i].cardno)
                    input(inputs[1], this.data[i].name)
                })
            },
            async run() {
                const title = () => {
                    const titles = Array.from(document.querySelectorAll('.progress .dot.active')).map(e => e.textContent.trim())
                    return titles[titles.length - 1]
                }
                switch (title()) {
                    case '选择入馆时间':
                        await this.selectDate()
                        await this.fillInfo()
                        break
                    case '录入信息提交':
                        await this.fillInfo()
                        break
                    case '完成':
                        break
                }
            },
        }
    }

    function gongwangfu() {
        return {
            dates: [
                "2023年04月29日",
                "2023年04月30日",
                "2023年05月01日",
                "2023年05月02日",
                "2023年05月03日",
            ],
            times: [
                '08:30',
                '12:01',
            ],
            data: [
                { name: "张三", cardno: "身份证号", phone: 手机号, type: '成人票', passport: '身份证' },
                { name: "李四", cardno: "身份证号", phone: 手机号, type: '老年票', passport: '身份证' },
                { name: "赵五", cardno: "身份证号", phone: 手机号, type: '老年票', passport: '身份证' },
            ],
            async fillInfo() {
                await waitSelector('[data-year-month]')
                const dates = Array.from(document.querySelectorAll('[data-year-month]')).map(node => {
                    const remainings = node.textContent.match(/(?<=余)\d+/g).map(e => +e)
                    return {
                        node, text: node.getAttribute('data-year-month').trim(),
                        remainings: node.textContent.match(/(?<=余)\d+/g).map(e => +e),
                        remaining: remainings.reduce((v, e) => v + e, 0),
                    }
                })
                if (!dates.length) log('NO_DATE')
                for (const date of dates) {
                    if (this.dates.includes(date.text)) {
                        date.node.click()
                        await immeidate()
                        await waitSelector('[period-type]')
                        const times = Array.from(document.querySelectorAll('[period-type]')).map(node => ({ node, text: node.textContent.trim().match(/[0-9]{1,2}:[0-9]{1,2}/)[0] }))
                        if (!times.length) log('NO_TIME', date.text)
                        for (let j = 0; j < times.length; j++) {
                            const time = times[j]
                            const remaining = date.remainings[j]
                            if (remaining < this.data.length) {
                                log('NO_ENOUGH', remaining, date.text, time.text)
                                continue
                            }
                            if (this.times.includes(time.text)) {
                                await immeidate()
                                await waitSelector('.buyt-box-con')
                                const buyBoxes = Array.from(document.querySelectorAll('.buyt-box-con'))
                                    .map(node => ({
                                        node,
                                        text: node.querySelector('dt div')?.textContent?.trim(),
                                        price: Number(node.querySelector('dt div:nth-child(2)')?.textContent?.trim().slice(1)),
                                        addBtn: node.querySelector('.buyt-addbtn'),
                                    }))
                                for (let i = 0; i < this.data.length; i++) {
                                    const d = this.data[i]
                                    const box = buyBoxes.find(e => e.text.indexOf(d.type) > -1)
                                    if (box) {
                                        box?.addBtn?.click()
                                        const dd = await waitFor(() => document.querySelectorAll('.buyticket-box dd')?.[i])
                                        input(dd.querySelector('.buyt-box-name input'), d.name)
                                        inputSelect(dd.querySelector('.buyt-box-selt select'), d.passport)
                                        input(dd.querySelector('.buyt-box-zj input'), d.cardno)
                                    }
                                }
                                input(document.querySelector('.buyt-phobe input'), this.data[0].phone)
                                return
                            } else {
                                log('NO_TIME_EXPECTED', date.text, time.text)
                            }
                        }
                    } else {
                        log('NO_DATE_EXPECTED', date.text)
                    }
                }
            },
            async submit() {
                const submit = await waitSelector('.cash-btn')
                if (window.confirm(`确认提交？`)) {
                    submit.click()
                    console.log('submit!')
                }
            },
            async run() {
                await this.fillInfo()
                await this.submit()
            },
        }
    }
})();
