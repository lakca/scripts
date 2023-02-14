// ==UserScript==
// @name         New Userscript
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        *://*/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=zhihu.com
// @grant        unsafeWindow
// ==/UserScript==

(function() {
    'use strict';
    const document = unsafeWindow.document
    const window = unsafeWindow
    const console = window.console
    function observe(dom, config, cb) {
        return new window.MutationObserver(function(records) {
            records.forEach(cb)
        }).observe(dom, config)
    }
    function observeChildren(dom, cb, added) {
        observe(dom, { attributes: false, childList: true, subtree: false }, function(record) {
            if (record.type === 'childList') {
                added === true ? record.addedNodes.forEach(node => {
                    cb(node)
                }) :
                added === false ? record.removedNodes.forEach(node => {
                    cb(node)
                }) :
                cb(record.addedNodes, record.removedNodes)
            }
        })
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
            document.body.querySelector('[role=banner]')?.remove()
            observeChildren(document.body, function(node) {
                if (node && node.querySelector('.Modal-wrapper')) {
                    node.querySelector('.Button.Modal-closeButton')?.click()
                }
                else if (/(登陆|注册)/.test(node && node.querySelector('Button')?.textContent || '')) {
                    node.remove()
                }
            }, true)
        } else if (checkHref('.csdn.net')) {
            observeChildren(document.body, function(node) {
                node.classList.contains('passport-login-container') && node.remove()
            }, true)
        }
    }
    window.fuck = fuck
    fuck()
    // Your code here...
})();
