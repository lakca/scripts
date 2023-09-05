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

const authtoken = '3613146b9c1a486b8666e86a78298a1a'
const token = 'd553af9ca51b47c0b9b10e91f306f6b7'
const headers = {
  'Host': 'www.baomi.org.cn',
  "accept": "application/json, text/plain, */*",
  "accept-language": "zh-CN,zhq=0.9,enq=0.8",
  "cache-control": "no-cache",
  'Cookie': 'uuid_c13af0e0-064c-11ed-a8a8-c33dc9621234=529f4cc4-5e19-4f73-8f13-eecc71942fa4; href=http%3A%2F%2Fwww.baomi.org.cn%2F%3Fu_atoken%3D7738e3a9-ee42-450f-87ae-66c239e85ebc%26u_asession%3D01PxaiXJb6k7Ok7pcK7V-wH1sBBjAy2_7jY7EV1XSoXeAzv05ZbyFtAJwN5GABsmupX0KNBwm7Lovlpxjd_P_q4JsKWYrT3W_NKPr8w6oU7K8tZmOq3nYf3-XphMl7w5xFpr4teCvh5VY5Njd5VdG1omBkFo3NEHBv0PZUm6pbxQU%26u_asig%3D05qtuLQ4SiMafsaUEbzg8yUWEsBGzK7TqtWsmo3x6fS6PkV7klqEQk1n8RsDa6-TNhTtp4OtGEIxaoLZDx6Q2klwCVfPYYfBp5c2926_38_weiRl_OSIKVTmMk3WdnH4uEAezkce-DA6fv7H7z_Yowm5yWyOTLO4r02smv6B6Ux4H9JS7q8ZD7Xtz2Ly-b0kmuyAKRFSVJkkdwVUnyHAIJzZwW2jbkT2s3oM3NdWo44ZBwD0GZDhPINiwYhKphmtQAvAnn-RUoQiN9jeSNwt9ne-3h9VXwMyh6PgyDIVSG1W_dvsdBRAEp8DQtlMgL2YQEwT5k5B61pfZ7a7fKvxvU_fZW4hDKgkKQu229mwCAPz2NA0CNtzL9ad_m_u4bAfT2mWspDxyAEEo4kbsryBKb9Q%26u_aref%3DXgadY2hr6%252BP3CN4IRhi2kCiO%252BJI%253D%26siteId%3D95; accessId=c13af0e0-064c-11ed-a8a8-c33dc9621234; p_h5_u=056909AD-9D56-465F-B541-16FEF16B6C80; selectedStreamLevel=FD; qimo_seosource_0=%E7%AB%99%E5%86%85; qimo_seokeywords_0=; qimo_seosource_c13af0e0-064c-11ed-a8a8-c33dc9621234=%E7%AB%99%E5%86%85; qimo_seokeywords_c13af0e0-064c-11ed-a8a8-c33dc9621234=; qimo_xstKeywords_c13af0e0-064c-11ed-a8a8-c33dc9621234=; acw_tc=2760775416904259309417113e786bf80452258d2da8698c85b01d977f2b9e; acw_sc__v3=64c1da53daec5153f634e04405322cba4bb2d886; pageViewNum=22',
  "DNT": "1",
  "pragma": "no-cache",
  "proxy-connection": "keep-alive",
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36',
  "authtoken": authtoken,
  "siteid": "95",
  "token": token
}

async function dirs(coursePacketId) {
  const r = await fetch("http://www.baomi.org.cn/portal/api/v2/coursePacket/getCourseDirectoryList?" + new URLSearchParams({
    scale: '1',
    coursePacketId,
    timestamps: `${Date.now()}`
  }).toString(), {
    cache: 'no-cache',
    "headers": {
      ...headers,
      "accept": "application/json, text/plain, */*",
      "accept-language": "zh-CN,zhq=0.9,enq=0.8",
      "authtoken": authtoken,
      "cache-control": "no-cache",
      "pragma": "no-cache",
      "proxy-connection": "keep-alive",
      "siteid": "95",
      "token": token
    },
    "referrer": `http://www.baomi.org.cn/bmCourseDetail/course?id=${coursePacketId}`,
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": null,
    "method": "GET",
    "mode": "cors",
    "credentials": "include"
  }).then(r => r.json())

  const items = []
  for (const it of r.data) {
    items.push({
      directoryId: it.SYS_UUID,
      name: it.name,
      parent: it.name,
      parentDirectoryId: it.SYS_UUID,
      courseId: coursePacketId,
      coursePacketId,
    })
    it.subDirectory && items.push(...it.subDirectory.map(e => ({
      directoryId: e.SYS_UUID,
      name: e.name,
      parent: it.name,
      parentDirectoryId: it.SYS_UUID,
      courseId: coursePacketId,
      coursePacketId,
    })))
  }
  return items
}

async function list(it) {
  const r = await fetch("http://www.baomi.org.cn/portal/api/v2/coursePacket/getCourseResourceList?" + new URLSearchParams({
    coursePacketId: it.coursePacketId,
    directoryId: it.directoryId,
    token: token,
    timestamps: `${Date.now()}`,
  }).toString(), {
    "headers": {
      ...headers,
      "accept": "application/json, text/plain, */*",
      "accept-language": "zh-CN,zhq=0.9,enq=0.8",
      "authtoken": authtoken,
      "cache-control": "no-cache",
      "pragma": "no-cache",
      "proxy-connection": "keep-alive",
      "siteid": "95",
      "token": token
    },
    "referrer": `http://www.baomi.org.cn/bmCourseDetail/course?id=${it.coursePacketId}`,
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": null,
    "method": "GET",
    "mode": "cors",
    "credentials": "include"
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
      studyTime: len + Math.floor(Math.random() * 20) + 10,
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
    timestamps: `${Date.now()}`,
  })
  return fetch("http://www.baomi.org.cn/portal/api/v2/studyTime/saveCoursePackage.do?" + new URLSearchParams({
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
    timestamps: `${Date.now()}`,
  }).toString(), {
    "headers": {
      ...headers,
      "accept": "application/json, text/plain, */*",
      "accept-language": "zh-CN,zhq=0.9,enq=0.8",
      "authtoken": authtoken,
      "cache-control": "no-cache",
      "pragma": "no-cache",
      "proxy-connection": "keep-alive",
      "siteid": "95",
      "token": token
    },
    "referrer": "http://www.baomi.org.cn/bmVideo?" + new URLSearchParams({
      id: it.courseId, // courseId
      docId: it.studyResourceId, // studyResourceId
      docLibId: '-15', // resourceLibId
      pubId: '',
      siteId: '95',
      title: it.resourceName,
      doclibId: it.resourceLibId, // resourceLibId
      coursePacketId: it.courseId,
      directoryId: it.directoryId,
      resourceId: it.resourceDirectoryId, // resourceDirectoryId
    }).toString(),
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": null,
    "method": "GET",
    "mode": "cors",
    "credentials": "include"
  }).then(r => r.json())
}

async function stat(it) {
  console.error('\x1b[2mstat', it, '\x1b[0m')
  const r = await fetch("http://www.baomi.org.cn/portal/api/v2/coursePacket/getResourceUserStatistic?" + new URLSearchParams({
    coursePacketId: it.courseId,
    token: token,
    resourceDirectoryId: it.resourceDirectoryId,
    timestamps: `${Date.now()}`,
  }).toString(), {
    "headers": {
      ...headers,
      "Referrer-Policy": "strict-origin-when-cross-origin",
      "Referrer": "http://www.baomi.org.cn/bmCourseDetail/course?" + new URLSearchParams({
        id: it.courseId, // courseId
        docId: it.studyResourceId, // studyResourceId
        docLibId: '-15', // resourceLibId
        pubId: it.pubId,
        siteId: '95',
        title: STUDY_TITLE,
      }).toString()
    },
    "body": null,
    "method": "GET",
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
