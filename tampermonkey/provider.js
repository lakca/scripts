// @ts-nocheck
/* eslint-disable no-undef */

const g = require('../../gelement/src/index')
const TheValue = require('../../the-value/index')

module.exports = {
  g,
  Value: TheValue.addon(),
  GM_addStyle,
  GM_addElement,
  GM_registerMenuCommand,
  GM_addValueChangeListener,
  GM_removeValueChangeListener,
  GM_setValue,
  GM_getValue,
  GM_deleteValue,
  GM_listValues,
  GM_setClipboard
}
