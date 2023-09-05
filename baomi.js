const PACKAET_ID = '897ed48c-b420-4b43-844b-280147eb422a'
const STUDY_TITLE = '2023年度保密教育线上培训'
process.argv.shift()
process.argv.shift()
const action = process.argv.shift()
const readline = require('readline')

async function prompt() {
  return new Promise(resolve => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    })
    // ask user for the anme input
    rl.question(`已看过，回车跳过: `, (yes) => {
      resolve(!!yes)
      rl.close()
    })
  })
}

function log(action, ...text) {
  console.log(`\x1b[33m${action}\x1b[0m \x1b[2m${text.join(' ')}\x1b[0m`)
}

const authtoken = ''
const token = ''
const headers = {
  Host: 'www.baomi.org.cn',
  accept: 'application/json, text/plain, */*',
  'accept-language': 'zh-CN,zhq=0.9,enq=0.8',
  'cache-control': 'no-cache',
  Cookie: '',
  DNT: '1',
  pragma: 'no-cache',
  'proxy-connection': 'keep-alive',
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',
  authtoken: authtoken,
  siteid: '95',
  token: token
}

async function dirs(coursePacketId) {
  const r = await fetch('http://www.baomi.org.cn/portal/api/v2/coursePacket/getCourseDirectoryList?' + new URLSearchParams({
    scale: '1',
    coursePacketId,
    timestamps: `${Date.now()}`
  }).toString(), {
    cache: 'no-cache',
    headers: {
      ...headers,
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zhq=0.9,enq=0.8',
      authtoken: authtoken,
      'cache-control': 'no-cache',
      pragma: 'no-cache',
      'proxy-connection': 'keep-alive',
      siteid: '95',
      token: token
    },
    referrer: `http://www.baomi.org.cn/bmCourseDetail/course?id=${coursePacketId}`,
    referrerPolicy: 'strict-origin-when-cross-origin',
    body: null,
    method: 'GET',
    mode: 'cors',
    credentials: 'include'
  }).then(r => r.json())

  const items = []
  for (const it of r.data) {
    items.push({
      directoryId: it.SYS_UUID,
      name: it.name,
      parent: it.name,
      parentDirectoryId: it.SYS_UUID,
      courseId: coursePacketId,
      coursePacketId
    })
    it.subDirectory && items.push(...it.subDirectory.map(e => ({
      directoryId: e.SYS_UUID,
      name: e.name,
      parent: it.name,
      parentDirectoryId: it.SYS_UUID,
      courseId: coursePacketId,
      coursePacketId
    })))
  }
  return items
}

async function list(it) {
  const r = await fetch('http://www.baomi.org.cn/portal/api/v2/coursePacket/getCourseResourceList?' + new URLSearchParams({
    coursePacketId: it.coursePacketId,
    directoryId: it.directoryId,
    token: token,
    timestamps: `${Date.now()}`
  }).toString(), {
    headers: {
      ...headers,
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zhq=0.9,enq=0.8',
      authtoken: authtoken,
      'cache-control': 'no-cache',
      pragma: 'no-cache',
      'proxy-connection': 'keep-alive',
      siteid: '95',
      token: token
    },
    referrer: `http://www.baomi.org.cn/bmCourseDetail/course?id=${it.coursePacketId}`,
    referrerPolicy: 'strict-origin-when-cross-origin',
    body: null,
    method: 'GET',
    mode: 'cors',
    credentials: 'include'
  }).then(r => r.json())
  function time2number(time) {
    return time.split(':').reverse().reduce((r, e, i) => +e * 60 ** i + r, 0)
  }
  return r.data.listdata && r.data.listdata.map(it => {
    const len = time2number(it.timeLength)
    return {
      courseId: it.coursePacketID,
      coursePacketID: it.coursePacketID,
      directoryId: it.directoryId,
      resourceName: it.name,
      resourceId: it.resourceID,
      resourceDirectoryId: it.SYS_UUID,
      studyResourceId: it.SYS_DOCUMENTID,
      pubId: it.pubId || 29711,
      resourceType: it.resourceType,
      resourceLibId: it.SYS_DOCLIBID,
      resourceLength: len,
      studyLength: len,
      startTime: Date.now(),
      timestamps: Date.now(),
      studyTime: len + Math.floor(Math.random() * 20) + 10
    }
  }) || []
}

async function submit(it, time) {
  console.error('submit', {
    courseId: it.coursePacketID,
    resourceId: it.resourceId,
    resourceDirectoryId: it.resourceDirectoryId,
    resourceLength: it.resourceLength,
    studyLength: time ? it.studyTime : 14,
    studyTime: time ? it.studyTime : 10,
    startTime: `${Date.now()}`,
    resourceName: it.resourceName,
    resourceType: it.resourceType,
    resourceLibId: it.resourceLibId,
    studyResourceId: it.studyResourceId,
    token: token,
    timestamps: `${Date.now()}`
  })
  return fetch('http://www.baomi.org.cn/portal/api/v2/studyTime/saveCoursePackage.do?' + new URLSearchParams({
    courseId: it.coursePacketID,
    resourceId: it.resourceId,
    resourceDirectoryId: it.resourceDirectoryId,
    resourceLength: it.resourceLength,
    studyLength: time ? it.studyTime : 14,
    studyTime: time ? it.studyTime : 10,
    startTime: `${Date.now()}`,
    resourceName: it.resourceName,
    resourceType: it.resourceType,
    resourceLibId: it.resourceLibId,
    studyResourceId: it.studyResourceId,
    token: token,
    timestamps: `${Date.now()}`
  }).toString(), {
    headers: {
      ...headers,
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zhq=0.9,enq=0.8',
      authtoken: authtoken,
      'cache-control': 'no-cache',
      pragma: 'no-cache',
      'proxy-connection': 'keep-alive',
      siteid: '95',
      token: token
    },
    referrer: 'http://www.baomi.org.cn/bmVideo?' + new URLSearchParams({
      id: it.courseId, // courseId
      docId: it.studyResourceId, // studyResourceId
      docLibId: '-15', // resourceLibId
      pubId: '',
      siteId: '95',
      title: it.resourceName,
      doclibId: it.resourceLibId, // resourceLibId
      coursePacketId: it.courseId,
      directoryId: it.directoryId,
      resourceId: it.resourceDirectoryId // resourceDirectoryId
    }).toString(),
    referrerPolicy: 'strict-origin-when-cross-origin',
    body: null,
    method: 'GET',
    mode: 'cors',
    credentials: 'include'
  }).then(r => r.json())
}

async function stat(it) {
  console.error('\x1b[2mstat', it, '\x1b[0m')
  const r = await fetch('http://www.baomi.org.cn/portal/api/v2/coursePacket/getResourceUserStatistic?' + new URLSearchParams({
    coursePacketId: it.courseId,
    token: token,
    resourceDirectoryId: it.resourceDirectoryId,
    timestamps: `${Date.now()}`
  }).toString(), {
    headers: {
      ...headers,
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      Referrer: 'http://www.baomi.org.cn/bmCourseDetail/course?' + new URLSearchParams({
        id: it.courseId, // courseId
        docId: it.studyResourceId, // studyResourceId
        docLibId: '-15', // resourceLibId
        pubId: it.pubId,
        siteId: '95',
        title: STUDY_TITLE
      }).toString()
    },
    body: null,
    method: 'GET'
  }).then(r => r.json())
  console.error(r)
  return !!r.data && r.data.isFinish === 1
}

function sleep(s) {
  return new Promise(resolve => {
    setTimeout(resolve, s * 1000)
  })
}

async function study() {
  const directories = await dirs(PACKAET_ID)
  const startName = process.argv.shift()
  let started = !startName
  for (const e of directories) {
    log('开始学习', [e.parent, e.name])
    const items = await list(e)
    e.items = items
    require('fs').writeFileSync(__filename + '.json', JSON.stringify(directories, null, 2))
    log('课程总数\x1b[33m', items.length)

    for (const it of items) {
      if (!started && it.resourceName.includes(startName)) started = true
      if (!started) continue
      const fullname = [e.parent, e.name, it.resourceName]
      log('学习', fullname)
      const read = await stat(it)
      read ? log('已学习完成', fullname) : log('还未学习', fullname)
      if (action === 'submit') {
        if (process.env.PROMPT ? (await prompt()) : !read) {
          console.error('submit response:', await submit(it))
          const time = Math.random() * 20 + 10
          await sleep(time)
          console.error('submit response:', await submit(it, time))
        }
      } else {
        return
      }
    }
  }
}

study().catch(console.error)
