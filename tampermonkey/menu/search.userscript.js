/* eslint-disable new-cap */
/* eslint-disable no-undef */

(function(window) {
  const Value = TheValue.addon()
  const params = {
    Value,
    GM_addStyle,
    GM_addElement,
    GM_registerMenuCommand,
    GM_addValueChangeListener,
    GM_setValue,
    GM_getValue,
    GM_deleteValue,
    GM_setClipboard
  }
  const ctx = require('./ctx')(params)

  GM_registerMenuCommand('百度', () => ctx.search('baidu'))
}())
