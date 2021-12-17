/* eslint-disable indent */
/* eslint-disable new-cap */
/**
 * @param {ReturnType<import('./ctx')>} context
 */
module.exports = function(context) {
  const { Store, UserProxy, Value, event, g, popup, getSelectionText, isElementInvisible, SEARCHES, openTab, GM_listValues, GM_getValue } = context

  function inHostname(part) {
    const hostname = window.location.hostname
    if (
      hostname.indexOf(part) === 0 ||
      hostname.indexOf(part) === hostname.length - part.length
    )
      return true
    if (part[0] !== '.') part = '.' + part
    if (part[part.length - 1] !== '.') part += '.'
    return hostname.indexOf(part) > -1
  }

  function getQuery() {
    let text = getSelectionText().trim()
    if (text) return text
    if (inHostname('translate') || inHostname('fanyi')) {
      text = document.querySelector('textarea').value
    } else {
      for (const input of document.querySelectorAll(
        'input[type=search], input[type=text], input:not([type])'
      )) {
        if (input.type === 'search') {
          text = input.value
          break
        } else if (!isElementInvisible(input)) {
          text = input.value
          break
        }
      }
    }
    if (!text.trim()) {
      if (inHostname('github.')) {
        text = document.querySelector('h1').innerText.replace(/\n/g, '')
      } else {
        const h1 = document.querySelector('h1')
        if (h1) text = h1.innerText
      }
    }
    return text.trim()
  }

  function search(key, text, newtab) {
    if (key) {
      const item = SEARCHES.find(e => e.key === key)
      if (item) {
        const url = item.url.replace('#keyword#', text)
        newtab ? openTab(url) : window.location.href = url
      }
    }
  }

  function addSite(site) {
    Store.List('sites').add(site)
  }

  function delSite(site) {
    Store.List('sites').del(site)
  }

  function clearSites() {
    Store.List('sites').empty()
  }

  function toTop() {
    window.scrollTo({ top: 0, behavior: 'auto' })
  }

  function toBottom() {
    window.scrollTo({ top: 99999, behavior: 'auto' })
  }

  function showStore() {
    popup(g('ul').down(GM_listValues().map(k => {
      const v = GM_getValue(k)
      const el = g('li')
      el.down('span').text(k)
        .next('pre').text(typeof v === 'object' ? JSON.stringify(v, null, 2) : v)
      return el
    })).up())
  }

  function showQuery() {
    popup(getQuery())
  }

  function jiraMention(data) {
    const form = g('div')
    popup(form)
    const jiraKinds = Store.List('jira:kind').get()
    const jiraRoot = Store.New('jira:root').get()
    const repos = Store.List('git:repo').get()
    Store.List('git:repo').add({
      repo: 'narsissus',
      branch: 'v2'
    }).add({
      repo: 'narsissus',
      branch: 'v2'
    }).add({
      repo: 'narsissus',
      branch: 'v2'
    })
    form
      .down('label').text('Jira')
      .next('select').key('kind').attr('value', jiraKinds[0])
        .down(jiraKinds.map(kind => g('option').attr('value', kind)))
      .next('input').key('jira').attr('value', Value(data).get('jira')).attr('placeholder', '数字或者URL')
      .next('label').text('Git')
      .next('input').key('git').attr('value', Value(data).get('git')).attr('placeholder', 'git commit id')
      .next('button').text('copy').on('click', getComment)
    function getComment() {
      // http://jira.mizar.icu/browse/MIZAR-451
      let kind = form.node('kind').value.trim()
      let jira = form.node('jira').value.trim()
      let git = form.node('git').value.trim()
      if (!jira.startsWith('http')) jira = `${jiraRoot}/browse/${kind}-${jira.match(/\d+/)[0]}`
      if (!git.startsWith('http')) git = ``
      // return `[龙鹏|https://git.mizar.icu/longpeng] mentioned this issue in ` +
      // `[a commit|https://git.mizar.icu/acms/${repo}/-/commit/${id}] of ` +
      // `[ACMS / ${repo}|https://git.mizar.icu/acms/${repo}] on branch [${branch}|https://git.mizar.icu/acms/${repo}/-/tree/${branch}]:` +
      // `{quote}${msg}{quote}`
    }
  }

  const SHOWS = {
    store: showStore,
    query: showQuery
  }
  event.on('search', data => search(data.name, data.text || getQuery(), data.newtab))
  event.on('show', data => SHOWS[data] && SHOWS[data]())
  event.on('addSite', data => addSite(data || window.location.hostname))
  event.on('delSite', data => delSite(data || window.location.hostname))
  event.on('clearSites', clearSites)
  event.on('toTop', toTop)
  event.on('toBottom', toBottom)
  event.on('jiraMention', jiraMention)

  return {
    getQuery,
    search,
    addSite,
    delSite,
    showStore
  }
}
