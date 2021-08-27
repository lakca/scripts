/* eslint-disable no-undef */

// ==UserScript==
// @name         New Userscript
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        *://*/*
// @icon         data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==
// @require      https://unpkg.com/the-value@1.1.1/dist/index.min.js
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_deleteValue
// @grant        GM_addStyle
// @grant        GM_addElement
// @grant        GM_setClipboard
// @grant        window.location.href
// @grant        GM_registerMenuCommand
// @grant        GM_addValueChangeListener
// @noframes
// ==/UserScript==


;(function(window) {
  'use strict';
  const addon = {
    prevent(a) { a.preventDefault() }
  }
  const Value = TheValue.addon(addon)
  Object.assign(Value, addon)

  const g = require('/Users/longpeng/Documents/GitHub/gelement/src/index.js')
  const params = {
    g,
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
  const popup = require('./popup')({...params, ...ctx})
  const menu = require('./menu')({...params, ...ctx, popup})
  const action = require('./action')({...params, ...ctx, popup})

  menu.mount()
  action.mount()
  unsafeWindow.popup = popup
})(window);


/*

['谷歌搜索', 'https://www.google.com/search?q=#keyword#'],
['百度搜索', 'https://www.baidu.com/s?wd=#keyword#'],
['Bing搜索', 'https://cn.bing.com/search?q=#keyword#'],
['360搜索', 'https://www.so.com/s?q=#keyword#'],
['搜狗搜索', 'https://www.sogou.com/web?query=#keyword#'],
['雅虎', 'https://search.yahoo.com/search?p=#keyword#] (input[name=p])'],
['Yandex', 'https://yandex.com/search/?text=#keyword#] (input[name=text])'],
['百度翻译', 'https://fanyi.baidu.com/#en/zh/#keyword#'],
['谷歌翻译', 'https://translate.google.com/?hl=zh-CN&tab=wT0#view=home&op=translate&sl=auto&tl=zh-CN&text=#keyword#'],
['搜狗翻译', 'https://fanyi.sogou.com/?keyword=#keyword#'],
['GitHub', 'https://github.com/search?utf8=✓&q=#keyword#'],
['Stackoverflow', 'https://stackoverflow.com/search?q=#keyword#'],
['Segmentfault', 'https://segmentfault.com/search?q=#keyword#'],
['Quora', 'https://www.quora.com/search?q=#keyword#'],
['维基百科', 'https://zh.wikipedia.org/wiki/#keyword#'],
['知乎搜索', 'https://www.zhihu.com/search?type=content&q=#keyword#'],
['豆瓣搜索', 'https://www.douban.com/search?source=suggest&q=#keyword#'],
['博客园', 'https://zzk.cnblogs.com/s?w=#keyword#] (input[name=Keywords]) [右侧'],
['CSDN', 'https://so.csdn.net/so/search/s.do?q=#keyword#] (#toolbar-search-input)'],
['简书', 'https://www.jianshu.com/search?q=#keyword#] (#q)'],
['掘金', 'https://juejin.im/search?query=#keyword#] (.search-input)'],
['MSDN', 'https://docs.microsoft.com/zh-cn/search/?terms=#keyword#'],
['百度图片', 'https://image.baidu.com/search/index?tn=baiduimage&word=#keyword#'],
['Google图片', 'https://www.google.com/search?q=#keyword#&tbm=isch'],
['Bing图片', 'https://cn.bing.com/images/search?q=#keyword#&scenario=ImageBasicHover'],
['有道词典', 'https://dict.youdao.com/w/#keyword#'],
['必应词典', 'https://cn.bing.com/dict/search?q=#keyword#'],
['Vocabulary', 'https://www.vocabulary.com/dictionary/#keyword#'],
['格林斯高阶', 'https://www.collinsdictionary.com/dictionary/english/#keyword#'],
['剑桥词典', 'https://dictionary.cambridge.org/zhs/%E8%AF%8D%E5%85%B8/%E8%8B%B1%E8%AF%AD-%E6%B1%89%E8%AF%AD-%E7%AE%80%E4%BD%93/#keyword#'],
['韦氏词典', 'https://www.learnersdictionary.com/definition/#keyword#'],
['淘宝搜索', 'https://s.taobao.com/search?q=#keyword#'],
['天猫搜索', 'https://list.tmall.com/search_product.htm?q=#keyword#'],
['京东搜索', 'http://search.jd.com/Search?keyword=#keyword#'],
['亚马逊', 'https://www.amazon.cn/s?k=#keyword#'],
['当当网', 'http://search.dangdang.com/?key=#keyword#'],
['孔夫子', 'http://search.kongfz.com/product_result/?key=#keyword#'],
['YouTube', 'https://www.youtube.com/results?search_query=#keyword#'],
['Bilibili', 'http://search.bilibili.com/all?keyword=#keyword#'],
['优酷搜索', 'https://so.youku.com/search_video/q_#keyword#'],
['爱奇艺搜索', 'https://so.iqiyi.com/so/q_#keyword#'],
['腾讯视频', 'https://v.qq.com/x/search/?q=#keyword#'],
['云盘精灵搜', 'https://www.yunpanjingling.com/search/#keyword#'],
['大圣盘搜索', 'https://www.dashengpan.com/search?keyword=#keyword#'],
['大力盘搜索', 'https://www.dalipan.com/search?keyword=#keyword#'],
['小昭来啦', 'https://www.xiaozhaolaila.com/s/search?q=#keyword#'],
['小可搜搜', 'https://www.xiaokesoso.com/s/search?q=#keyword#'],





*/
