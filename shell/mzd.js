// https://jnt.mfu.com.cn/page/user
/**
 库存：https://jnt.mfu.com.cn/ajax?ugi=bookingquery&action=getSessions&bundleid=com.maiget.tickets&moduleid=6f77be86038c47269f1e00f7ddee9af4
 提交信息页面: https://jnt.mfu.com.cn/page/user/editorder/7047babd63ff4461893c18f2850395fa?date=2023-05-02&begintime=09%3A30&endtime=10%3A15&booking_including_self=1&maxnums=5&minnums=-1
 */
const fs = require('fs')
const path = require('path')
const { sleep, countdown } = require('./utils')
const FORCE = process.argv.includes('force')
//
// 37B0EB487F23956B255E615DD7A2DD2C
// 7F73721493CE1F08414C698967015C50
const cookie = 'i18n_redirected=zh; e2928facd8ee42e3baaaac5ed3ed7875=WyIyMTYxMjQxOTQiXQ; JSESSIONID=0B8F32DE2BE0D597315DE583EE477476'
const session_file = path.join(__dirname, 'mzd.session.json')
const env_file = path.join(__dirname, 'mzd.env.json')
// https://jnt.mfu.com.cn/page/jnt/da57230.js
// 获取MODULEID, SITEID
async function getEnv() {
  if (!FORCE && fs.existsSync(env_file)) return JSON.parse(fs.readFileSync(env_file).toString())
  const text = await fetch('https://jnt.mfu.com.cn/page/jnt/da57230.js', {
    headers: {
      'sec-ch-ua': '"Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"macOS"',
      Referer: 'https://jnt.mfu.com.cn/page/user',
      'Referrer-Policy': 'strict-origin-when-cross-origin'
    },
    body: null,
    method: 'GET'
  }).then(res => res.text())
  const env = {
    baseURL: 'https://jnt.mfu.com.cn',
    ROUTER_BASE: '/page/',
    MODULEID: '6f77be86038c47269f1e00f7ddee9af4',
    BUNDLEID: 'com.maiget.tickets',
    SITEID: '7e97d18d179c4791bab189f8de87ee9d'
  }
  try {
    eval(text.match(/env:{[^}]+}/)[0].replace(':', '='))
  } catch (e) { /**/ }
  fs.writeFileSync(env_file, JSON.stringify(env, null, 2))
  return env
}
// 获取session
const sessionsExample = {
  '2023-04-26': {
    sessions: [
      {
        summary: '2023-04-26 08:00-08:45',
        eventssessionid: '0b4cade29b064a1ca8eb9ba17be8ee57',
        name: '2023-04-26',
        eventsdate: '2023-04-26',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-26 08:45-09:30',
        eventssessionid: '7d34a07cba72402a9d82ae7ecbe43ae3',
        name: '2023-04-26',
        eventsdate: '2023-04-26',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-26 09:30-10:15',
        eventssessionid: '0607a98cf0224c11b87ce542a261d5ce',
        name: '2023-04-26',
        eventsdate: '2023-04-26',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      },
      {
        summary: '2023-04-26 10:15-11:00',
        eventssessionid: 'e7397c463dff4ef09e6b763039a457ce',
        name: '2023-04-26',
        eventsdate: '2023-04-26',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      },
      {
        summary: '2023-04-26 11:00-12:00',
        eventssessionid: '96cdec33875c40a0b6b8ceeafe85a5fc',
        name: '2023-04-26',
        eventsdate: '2023-04-26',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      }
    ],
    remaining_total: -1,
    remaining_check: 1
  },
  code: 'A00006',
  '2023-04-30': {
    sessions: [
      {
        summary: '2023-04-30 08:00-08:45',
        eventssessionid: 'a15fb60014814d859c684f61f2ee17ff',
        name: '2023-04-30',
        eventsdate: '2023-04-30',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-30 08:45-09:30',
        eventssessionid: '9dad9851e9cc4b2c9cb117a2f2b623ea',
        name: '2023-04-30',
        eventsdate: '2023-04-30',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-30 09:30-10:15',
        eventssessionid: '7047babd63ff4461893c18f2850395fa',
        name: '2023-04-30',
        eventsdate: '2023-04-30',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      },
      {
        summary: '2023-04-30 10:15-11:00',
        eventssessionid: '3ba70975222b48f5a2e858361a42cb2b',
        name: '2023-04-30',
        eventsdate: '2023-04-30',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      },
      {
        summary: '2023-04-30 11:00-12:00',
        eventssessionid: '1a3d5dfb0f324916b1a5e5db28d1338f',
        name: '2023-04-30',
        eventsdate: '2023-04-30',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      }
    ],
    remaining_total: -1,
    remaining_check: 1
  },
  '2023-05-01': {
    sessions: [
      {
        summary: '2023-05-01 08:00-08:45',
        eventssessionid: 'a4c38958897f4a5d882df84c30213175',
        name: '2023-05-01',
        eventsdate: '2023-05-01',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-05-01 08:45-09:30',
        eventssessionid: '7cbb908440254de997a2508bd41931cb',
        name: '2023-05-01',
        eventsdate: '2023-05-01',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-05-01 09:30-10:15',
        eventssessionid: '8998f5dee3f34695810cdb8d0b20d869',
        name: '2023-05-01',
        eventsdate: '2023-05-01',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-05-01 10:15-11:00',
        eventssessionid: '830ade82ba0343d88064097c0647abb1',
        name: '2023-05-01',
        eventsdate: '2023-05-01',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-05-01 11:00-12:00',
        eventssessionid: 'e4a17ccf70cc4afe8b26f5f929d8d9ef',
        name: '2023-05-01',
        eventsdate: '2023-05-01',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      }
    ],
    remaining_total: -1,
    remaining_check: 0
  },
  errmsg: 'ok',
  '2023-04-27': {
    sessions: [
      {
        summary: '2023-04-27 08:00-08:45',
        eventssessionid: '9466646d0ced41bca299d42a3c915df5',
        name: '2023-04-27',
        eventsdate: '2023-04-27',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-27 08:45-09:30',
        eventssessionid: '45636021044845deab4943533c817cb0',
        name: '2023-04-27',
        eventsdate: '2023-04-27',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-27 09:30-10:15',
        eventssessionid: 'eacb3028b368456f962176809f1b514b',
        name: '2023-04-27',
        eventsdate: '2023-04-27',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-27 10:15-11:00',
        eventssessionid: '39ae8347ae3f407fb65c03da6af1056c',
        name: '2023-04-27',
        eventsdate: '2023-04-27',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 1
      },
      {
        summary: '2023-04-27 11:00-12:00',
        eventssessionid: 'f12251acb0104cdf9960e4056f062dd1',
        name: '2023-04-27',
        eventsdate: '2023-04-27',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      }
    ],
    remaining_total: -1,
    remaining_check: 1
  },
  '2023-04-28': {
    sessions: [
      {
        summary: '2023-04-28 08:00-08:45',
        eventssessionid: '55ce7e2dcd184297aba676e7ed390420',
        name: '2023-04-28',
        eventsdate: '2023-04-28',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-28 08:45-09:30',
        eventssessionid: 'e7cfe998b06c4ff7ac8d095e3092f41a',
        name: '2023-04-28',
        eventsdate: '2023-04-28',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-28 09:30-10:15',
        eventssessionid: 'db8487c42c634f3da2581a288cfd5fbc',
        name: '2023-04-28',
        eventsdate: '2023-04-28',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-28 10:15-11:00',
        eventssessionid: '65b254c28b8f489baf1ae8943e0fb67d',
        name: '2023-04-28',
        eventsdate: '2023-04-28',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-28 11:00-12:00',
        eventssessionid: '6b03bc199ee340e7bfad82dd16f095d9',
        name: '2023-04-28',
        eventsdate: '2023-04-28',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      }
    ],
    remaining_total: -1,
    remaining_check: 0
  },
  '2023-04-29': {
    sessions: [
      {
        summary: '2023-04-29 08:00-08:45',
        eventssessionid: 'b3faa06f8a3c459cb820fad72d4f1f1e',
        name: '2023-04-29',
        eventsdate: '2023-04-29',
        endtime: '08:45',
        begintime: '08:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-29 08:45-09:30',
        eventssessionid: '7472dfa33aba42b195734e3d55a74bf2',
        name: '2023-04-29',
        eventsdate: '2023-04-29',
        endtime: '09:30',
        begintime: '08:45',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-29 09:30-10:15',
        eventssessionid: 'bbc8b899ddae4b879de2a62baf02bbbd',
        name: '2023-04-29',
        eventsdate: '2023-04-29',
        endtime: '10:15',
        begintime: '09:30',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-29 10:15-11:00',
        eventssessionid: 'ed111a20476d4d939e9933bfe12a3b47',
        name: '2023-04-29',
        eventsdate: '2023-04-29',
        endtime: '11:00',
        begintime: '10:15',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      },
      {
        summary: '2023-04-29 11:00-12:00',
        eventssessionid: 'e18f886e16474a54bc824e5af1976046',
        name: '2023-04-29',
        eventsdate: '2023-04-29',
        endtime: '12:00',
        begintime: '11:00',
        minnums: -1,
        maxnums: 5,
        remaining: -1,
        status: 1,
        remaining_check: 0
      }
    ],
    remaining_total: -1,
    remaining_check: 0
  },
  booking_including_self: 1
}
async function getSessions(moduleid, siteid) {
  if (!FORCE && fs.existsSync(session_file)) return JSON.parse(fs.readFileSync(session_file).toString())
  const res = await fetch(`https://jnt.mfu.com.cn/ajax?ugi=bookingquery&action=getSessions&bundleid=com.maiget.tickets&moduleid=${moduleid}`, {
    headers: {
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
      'content-type': 'application/x-www-form-urlencoded',
      'm-lang': 'zh',
      'sec-ch-ua': '"Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"macOS"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      cookie: cookie,
      Referer: 'https://jnt.mfu.com.cn/page/user',
      'Referrer-Policy': 'strict-origin-when-cross-origin'
    },
    body: `fromtype=PERSONAL&siteid=${siteid}`,
    method: 'POST'
  }).then(res => res.json())
  if (res.code === 'A00006') {
    const sessions = Object.entries(res).filter(e => e[1].sessions).sort().map(e => e[1].sessions).flat()
    fs.writeFileSync(session_file, JSON.stringify(sessions, null, 2))
    return sessions
  }
}
async function submit(moduleid, session) {
  const res = await fetch(`https://jnt.mfu.com.cn/ajax?ugi=bookingorder&action=createTicketOrder&bundleid=com.maiget.tickets&moduleid=${moduleid}`, {
    headers: {
      accept: 'application/json, text/plain, */*',
      'accept-language': 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
      'content-type': 'application/x-www-form-urlencoded',
      'm-lang': 'zh',
      'sec-ch-ua': '"Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"macOS"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      cookie: cookie,
      Referer: `https://jnt.mfu.com.cn/page/user/editorder/${session.eventssessionid}?` + new URLSearchParams({
        date: session.eventsdate,
        begintime: session.begintime,
        endtime: session.endtime,
        booking_including_self: '1',
        maxnums: session.maxnums,
        minnums: session.minnums
      }).toString(),
      'Referrer-Policy': 'strict-origin-when-cross-origin'
    },
    body: new URLSearchParams({
      eventssessionid: session.eventssessionid,
      bookingdata: JSON.stringify([
        {
          realname: '姓名',
          doctype: 'IDCARD',
          idnum: '身份证号'
        },
        {
          realname: '姓名',
          doctype: 'IDCARD',
          idnum: '身份证号'
        },
        {
          realname: '姓名',
          doctype: 'IDCARD',
          idnum: '身份证号'
        }
      ])
    }).toString(),
    method: 'POST'
  }).then(res => res.json()).catch(e => {
    return { code: -1, errmsg: e.message }
  })
  const { code, errmsg } = res
  // {
  //   "code": "A00005",
  //   "errmsg": "余票不足"
  // }
  return res
}

const gap = 1
const count = 60
async function run(dates) {
  const env = await getEnv()
  const sessions = (await getSessions(env.MODULEID, env.SITEID) || []).filter(e => dates.includes(e.eventsdate))
  while (true) {
    for (const session of sessions) {
      if (session.remaining === -1) {
        console.log('\x1b[2m', session.summary, '售罄', '\x1b[0m')
        // await sleep(1)
        // continue
      } else {
        console.log('\x1b[33m', session.summary, '可售', '\x1b[0m')
      }
      console.log('\x1b[2m', '抢票', new Date().toLocaleTimeString(), '\x1b[0m', session.summary)
      const res = await submit(env.MODULEID, session)
      if (res.code === 'A00005') {
        console.log('\x1b[31m', res.code, res.errmsg, '\x1b[0m')
        if (res.errmsg.indexOf('操作过于频繁') > -1) {
          // gap++
          await countdown(count)
          continue
        }
      } else {
        console.log('\x1b[32m', res.code, res.errmsg, '\x1b[0m')
      }
      await sleep(gap)
      console.log(gap)
    }
  }
}

const dates = process.argv.filter(e => /^\d{4}/.test(e))
dates.push(...[
  // '2023-04-29',
  // '2023-04-30',
  // '2023-05-01',
  '2023-05-02'
  // '2023-05-03',
])
run(dates).then(() => { }).catch(e => console.log(e))
