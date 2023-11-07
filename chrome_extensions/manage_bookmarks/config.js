export const config = {
  actions: [
    {
      type: 'normal',
      contexts: ['all'],
      id: 'googleTranslate',
      title: '谷歌翻译',
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'goPrevActiveTab',
      title: '上个标签',
      _inline: true,
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'goNextActiveTab',
      title: '下个标签',
      _inline: true,
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askReadCurrentTabLater',
      title: '稍后阅读',
      _group: true,
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 20 20"><g fill="none"><path d="M14 3H6a1 1 0 0 0-1 1v11h4.022c.031.343.094.678.185 1H5a1 1 0 0 0 1 1h3.6c.183.358.404.693.657 1H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v5.207a5.48 5.48 0 0 0-1-.185V4a1 1 0 0 0-1-1zM6 5v1a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V5a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1zm1 0h6v1H7V5zm12 9.5a4.5 4.5 0 1 1-9 0a4.5 4.5 0 0 1 9 0zm-4-2a.5.5 0 0 0-1 0V14h-1.5a.5.5 0 0 0 0 1H14v1.5a.5.5 0 0 0 1 0V15h1.5a.5.5 0 0 0 0-1H15v-1.5z" fill="currentColor"></path></g></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askReadLeftTabsLater',
      title: '稍后阅读左侧标签页',
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 12h10"></path><path d="M10 12l4 4"></path><path d="M10 12l4-4"></path><path d="M4 4v16"></path></g></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askReadRightTabsLater',
      title: '稍后阅读右侧标签页',
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 12H4"></path><path d="M14 12l-4 4"></path><path d="M14 12l-4-4"></path><path d="M20 4v16"></path></g></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askSortBookmarks',
      title: '排序书签',
      _group: true,
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 24 24"><path d="M14.94 4.66h-4.72l2.36-2.36l2.36 2.36zm-4.69 14.71h4.66l-2.33 2.33l-2.33-2.33zM6.1 6.27L1.6 17.73h1.84l.92-2.45h5.11l.92 2.45h1.84L7.74 6.27H6.1zm-1.13 7.37l1.94-5.18l1.94 5.18H4.97zm10.76 2.5h6.12v1.59h-8.53v-1.29l5.92-8.56h-5.88v-1.6h8.3v1.26l-5.93 8.6z" fill="currentColor"></path></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askCleanBookmarks',
      title: '去重书签',
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 32 32"><path d="M26 20h-6v-2h6z" fill="currentColor"></path><path d="M30 28h-6v-2h6z" fill="currentColor"></path><path d="M28 24h-6v-2h6z" fill="currentColor"></path><path d="M17.003 20a4.895 4.895 0 0 0-2.404-4.173L22 3l-1.73-1l-7.577 13.126a5.699 5.699 0 0 0-5.243 1.503C3.706 20.24 3.996 28.682 4.01 29.04a1 1 0 0 0 1 .96h14.991a1 1 0 0 0 .6-1.8c-3.54-2.656-3.598-8.146-3.598-8.2zm-5.073-3.003A3.11 3.11 0 0 1 15.004 20c0 .038.002.208.017.469l-5.9-2.624a3.8 3.8 0 0 1 2.809-.848zM15.45 28A5.2 5.2 0 0 1 14 25h-2a6.5 6.5 0 0 0 .968 3h-2.223A16.617 16.617 0 0 1 10 24H8a17.342 17.342 0 0 0 .665 4H6c.031-1.836.29-5.892 1.803-8.553l7.533 3.35A13.025 13.025 0 0 0 17.596 28z" fill="currentColor"></path></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askExportBookmarks',
      title: '导出书签',
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 32 32"><path d="M13 21h13.17l-2.58 2.59L25 25l5-5l-5-5l-1.41 1.41L26.17 19H13v2z" fill="currentColor"></path><path d="M22 14v-4a1 1 0 0 0-.29-.71l-7-7A1 1 0 0 0 14 2H4a2 2 0 0 0-2 2v24a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2h-2v2H4V4h8v6a2 2 0 0 0 2 2h6v2zm-8-4V4.41L19.59 10z" fill="currentColor"></path></svg>'
    },
    {
      type: 'normal',
      contexts: ['all'],
      id: 'askImportBookmarks',
      title: '导入书签',
      _icon: '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 32 32"><path d="M28 19H14.83l2.58-2.59L16 15l-5 5l5 5l1.41-1.41L14.83 21H28v-2z" fill="currentColor"></path><path d="M24 14v-4a1 1 0 0 0-.29-.71l-7-7A1 1 0 0 0 16 2H6a2 2 0 0 0-2 2v24a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2h-2v2H6V4h8v6a2 2 0 0 0 2 2h6v2zm-8-4V4.41L21.59 10z" fill="currentColor"></path></svg>'
    },
  ]
}
