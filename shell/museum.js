// https://m.ctrip.com/webapp/tnt/booking?spotid=62722&date=2023-04-25&resourcetype=undefined&isscan=T&ctm_ref=vactang_page_20390&token=&salesPropertyIds=14981&optid=46403856&fromSkuType=commonSku
// https://m.ctrip.com/webapp/tnt/booking?spotid=62722&date=2023-04-30&resourcetype=undefined&isscan=T&ctm_ref=vactang_page_20390&token=&salesPropertyIds=8978&optid=40007737&fromSkuType=commonSku
// https://m.ctrip.com/webapp/tnt/booking?spotid=62722&date=2023-05-01&resourcetype=undefined&isscan=T&ctm_ref=vactang_page_20390&token=&salesPropertyIds=14981&optid=46403856&fromSkuType=commonSku
// getSearch((d) => ({
//   "spotid": "62722",
//   "date": d.date,
//   "resourcetype": "undefined",
//   "isscan": "T",
//   "ctm_ref": "vactang_page_20390",
//   "token": "",
//   "salesPropertyIds": d.salesPropertyId,
//   "optid": d.ooptid,
//   "fromSkuType": "commonSku"
// }), '2023-04-25', '上午')

// function getSearch(obj, date, period) {
//   return new URLSearchParams(obj).toString()
// }

// console.log()

const aday = 1000 * 3600 * 24

var cfg = {
  pages: [{
    salesPropertyId: 14981, desc: '上午', optid: 46403856,
  }, {
    salesPropertyId: 14982, desc: '下午', optid: 46403857,
  }],
  future: 7 * aday, // seconds
  offset: 0, // seconds differences from 00:00
  jetlag: 8 * 3600 * 1000,
  users: [
    { name: "姓名1", cardno: "身份证号1", phone: "手机号1", "infoid": 11111111, },
    { name: "姓名2", cardno: "身份证号2", phone: "手机号2", "infoid": 11111111, },
    { name: "姓名3", cardno: "身份证号3", phone: "手机号3", "infoid": 11111111, },
  ],
}

cfg.dates = () => ['2023-05-01', '2023-04-29', '2023-04-30'].filter(e => futurestart(e) <= new Date())

var over = false
const ALL = process.argv.includes('all')

function todate(date /* 2023-04-29 */) {
  // @ts-ignore
  return new Date(new Date(date) - cfg.jetlag)
}
function futurestart(date /* 2023-04-29 */) {
  // @ts-ignore
  return new Date(todate(date) - cfg.future)
}
function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 10 ** 3))
}
function firstDate(incr = cfg.future) {
  const d = new Date(Date.now() + incr + cfg.jetlag)
  return d.toISOString().slice(0, 10)
}
function shuffle(list) {
  return list.sort((a, b) => Math.random() > 0.5)
}

async function snap(page, users, minInterval = 5, maxInterval = 10, maxCount = 10000) {
  let count = 0
  while (true) {
    const date = firstDate()
    console.log(`开始抢票\x1b[2m${new Date().toLocaleTimeString()}\x1b[0m：${date} ${page.desc}`)
    count++
    const res = await order(date, page.salesPropertyId, page.optid, users)
    if (res.ok) {
      console.log(`\x1b[32m抢票成功：${date} ${page.desc}, ${res.code} ${res.msg}\x1b[0m`)
    } else {
      console.log(`\x1b[2m抢票失败：${date} ${page.desc}, ${res.code} ${res.msg}\x1b[0m`)
      if (res.warning) await sleep(15)
    }
    await sleep(minInterval + (maxInterval - minInterval) * Math.random())
    if (over || maxCount <= count) return console.log('\x1b[31m结束抢票\x1b[0m')
  }
}

async function seperateSnap(minInterval = 5, maxInterval = 8, maxCount = 10000) {
  for (const page of shuffle(cfg.pages)) {
    for (const user of shuffle(cfg.users)) {
      snap(page, [user], minInterval, maxInterval, maxCount)
      await sleep(2)
    }
  }
}

async function pick(minInterval = 5, maxInterval = 10, maxCount = 10000) {
  let count = 0
  while (true) {
    for (const date of shuffle(cfg.dates())) {
      for (const page of shuffle(cfg.pages)) {
        for (const user of shuffle(cfg.users)) {
          console.log(`开始抢票\x1b[2m${new Date().toLocaleTimeString()}\x1b[0m：${date} ${page.desc} ${ALL ? cfg.users.map(us => us.name) : user.name}`)
          count++
          const res = await order(date, page.salesPropertyId, page.optid, ALL ? cfg.users : [user])
          if (res.ok) {
            console.log(`\x1b[32m抢票成功：${date} ${page.desc}, ${res.code} ${res.msg}\x1b[0m`)
          } else {
            console.log(`\x1b[2m抢票失败：${date} ${page.desc}, ${res.code} ${res.msg}\x1b[0m`)
            if (res.warning) await sleep(20)
          }
          await sleep(minInterval + (maxInterval - minInterval) * Math.random())
        }
        if (over || maxCount <= count) return console.log('\x1b[31m结束抢票\x1b[0m')
      }
    }
  }
}

function order(date = '2023-04-29', salesPropertyId = 14981, optid = 46403856, users = []) {

  const req = fetch(`https://m.ctrip.com/restapi/soa2/14921/CreateTicketOrder?_fxpcqlniredt=09031079118039639625&x-traceID=09031079118039639625-${(new Date).getTime() + "-" + Math.floor(1e7 * Math.random())}`, {
    "headers": {
      "content-type": "application/json",
      "cookieorigin": "https://m.ctrip.com",
      "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Microsoft Edge\";v=\"114\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"macOS\"",
      "Referer": `https://m.ctrip.com/webapp/tnt/booking?spotid=62722&date=${date}&resourcetype=undefined&isscan=T&ctm_ref=vactang_page_20390&token=&salesPropertyIds=${salesPropertyId}&optid=optid&fromSkuType=commonSku`,
      "Referrer-Policy": "strict-origin-when-cross-origin",
      "cookie": `Session=smartlinkcode=U130026&smartlinklanguage=zh&SmartLinkKeyWord=&SmartLinkQuary=&SmartLinkHost=; GUID=09031079118039639625; MKT_CKID=1680774277125.6h24x.nq9m; __zpspc=9.1.1680774277.1680774277.1%232%7Cwww.baidu.com%7C%7C%7C%7C%23; _jzqco=%7C%7C%7C%7C%7C1.1614135070.1680774277128.1680774277128.1680774277128.1680774277128.1680774277128.0.0.0.1.1; _RSG=YYKWMLLs.T6g1lEKf_lIdA; _RDG=28083e6c80a244228739ae5f4d4ddd3e4d; _RGUID=677ed955-5681-48a2-a9d2-bffa543af06a; _bfaStatusPVSend=1; tangram_city_id=2; librauuid=; nfes_isSupportWebP=1; nfes_isSupportWebP=1; AHeadUserInfo=VipGrade=0&VipGradeName=%C6%D5%CD%A8%BB%E1%D4%B1&UserName=&NoReadMessageCount=0; _abtest_userid=2ec3451a-6c3b-4b14-a066-66a252475f61; cticket=3FC9F4ED698909B3E75F7106C56D69F0EB8AC622F00AA67BD71C085BF79D5B59; login_type=0; login_uid=3FBB3109ADDCEE59C1266FACD2F6640B; DUID=u=EC09CB4D79189597DCD8E1C93DB907A6&v=0; IsNonUser=F; UUID=40F314DC259042F4A0175175A50F3D9F; _bfi=p1%3D153002%26p2%3D153002%26v1%3D10%26v2%3D8; _bfaStatus=send; _RF1=114.254.10.169; hotelhst=1164390341; Union=OUID=&AllianceID=3791798&SID=20920823&SourceID=&AppID=&OpenID=&exmktID=&createtime=1682234535&Expires=1682839334820; MKT_OrderClick=ASID=379179820920823&AID=3791798&CSID=20920823&OUID=&CT=1682234534821&CURL=https%3A%2F%2Fm.ctrip.com%2Fwebapp%2Ftaro%2Fpages%2Ftnt%2Fdetail%2Fproduct-sku%2Findex%3FresourceId%3D46403856%26scenicSpotId%3D62722%26ctm_ref%3Dvactang_page_20390%26sid%3D20920823%26allianceid%3D3791798%26isscan%3DT&VAL={"h5_vid":"1680774276924.49t4m"}; _pd=%7B%22_o%22%3A5%2C%22s%22%3A133%2C%22_s%22%3A0%7D; _bfa=1.1680774276924.49t4m.1.1682220986775.1682234550895.8.82.10650051852; _ubtstatus=%7B%22vid%22%3A%221680774276924.49t4m%22%2C%22sid%22%3A8%2C%22pvid%22%3A82%2C%22pid%22%3A10650051852%7D`,
    },

    "body": JSON.stringify({
      "clientInfo": {
        "currency": "CNY",
        "locale": "zh-CN",
        "pageId": "10650051852",
        "channelId": 116,
        "appPlatform": "",
        "extension": [],
        "syscode": "09",
        "oriSyscode": "09"
      },
      "enviroment": "PROD",
      "head": {
        "cid": "09031079118039639625",
        "ctok": "",
        "cver": "1.0",
        "lang": "01",
        "sid": "8888",
        "syscode": "09",
        "auth": "",
        "xsid": "",
        "extension": [
          {
            "name": "protocal",
            "value": "https"
          },
          {
            "name": "crawlerKey",
            "value": ""
          },
          {
            "name": "MiniType",
            "value": "WAP/WECHATAPP"
          },
          {
            "name": "H5",
            "value": "H5"
          }
        ]
      },
      "pageid": 10650051852,
      "contentType": "json",
      "amt": "0",
      "chargetype": 0,
      "ispayisc": false,
      "rebate": false,
      "title": "中国国家博物馆",
      "insurs": [],
      "prominput": [],
      "ostype": 2,
      "from": `https://m.ctrip.com/webapp/tnt/booking?spotid=62722&date=${date}&resourcetype=undefined&isscan=T&ctm_ref=vactang_page_20390&token=&salesPropertyIds=${salesPropertyId}&optid=optid&fromSkuType=commonSku`,
      "skid": 0,
      "replayToken": "",
      "extraParams": {
        "isRepeatOrderCheck": "1",
        "IsSupportRemind": "1",
        "IsRemindCheck": "1",
        "IsSupportMedicalsRemind": "1",
        "IsSupportStudentRemind": "1",
        "hasRemindPopup": "0",
        "hasAdditionalSale": "0",
        "needAdditionalSaleRemind": "0",
        "hasInsurance": "0",
        "isSupportPeopleRemind": "1",
        "needInsuranceRemind": "0",
        "IsSupportRemindHtml": "0",
        "needSignDateTemplate": "1",
        "ordersource": "{\"IsCtripPreferred\":\"\"}",
        "isscan": "T"
      },
      "alliance": {
        "aid": "3791798",
        "sid": "20920823",
        "ouId": "",
        "ext": []
      },
      "marketinfo": JSON.stringify({
        "allianceid": "3791798",
        "sid": "20920823",
        "ouid": "",
        "innersid": "",
        "innerouid": "",
        "pushcode": "",
        "click_time": `${Date.now()}`,
        "click_url": "https%3A%2F%2Fm.ctrip.com%2Fwebapp%2Ftaro%2Fpages%2Ftnt%2Fdetail%2Fproduct-sku%2Findex%3FresourceId%3D46403856%26scenicSpotId%3D62722%26ctm_ref%3Dvactang_page_20390%26sid%3D20920823%26allianceid%3D3791798%26isscan%3DT",
        "ext_value": "{\"h5_vid\":\"1680774276924.49t4m\"}"
      }),
      "payVersion": "2.0",
      "rmsToken": "fp=9a331s-1w9u5zq-o6jt7e&vid=1680774276924.49t4m&pageId=10650051852&r=677ed955568148a2a9d2bffa543af06a&ip=114.254.10.169&rg=fin&screen=1440x900&tz=+8&blang=zh-CN&oslang=zh-CN&ua=Mozilla%2F5.0%20(Macintosh%3B%20Intel%20Mac%20OS%20X%2010_15_7)%20AppleWebKit%2F537.36%20(KHTML%2C%20like%20Gecko)%20Chrome%2F114.0.0.0%20Safari%2F537.36%20Edg%2F114.0.0.0&v=m17&bl=false&clientid=",
      "passengers": users.map(user => ({
        "infoid": user.infoid,
        "resid": optid,
        "name": user.name,
        "cardtype": 1,
        "cardno": user.cardno,
        "phone": user.phone,
        "phonecode": "86"
      })),
      "contact": {
        "name": "姓名",
        "phone": "手机号",
        "phonecode": "86"
      },
      "tickets": [
        {
          "destcid": 1,
          "pid": 40005808,
          "pname": "中国国家博物馆参观预约不限人群(身份证/外国人永久居留身份证预约)",
          "pricemode": "S",
          "quantity": users.length,
          "spotid": 62722,
          "tid": optid,
          "tname": "不限人群（身份证/外国人永久居留身份证预约）",
          "ttype": "",
          "roeinfos": [],
          "price": "0",
          "consdate": `${date}`,
          "contractTemplateId": 1301
        }
      ],
      "insurpros": [],
      "insurextends": [],
      "orderSummary": {
        "payTitleInfo": {
          "mainTitle": "中国国家博物馆",
          "titleInfoList": [
            "请在{{petime}}分钟内完成支付,否则该订单将被自动取消"
          ]
        },
        "detailList": [
          {
            "detailName": "费用明细",
            "detailInfoList": [
              {
                "detailTitle": "景点门票",
                "detailValue": "¥0x3",
                "detailComment": `${date}-不限人群（身份证/外国人永久居留身份证预约）`
              }
            ]
          },
          {
            "detailName": "出行人",
            "detailInfoList": users.map(user => ({
              "detailTitle": user.name,
              "detailComment": `身份证  ${user.cardno}\n手机号  ${user.phone}`
            }))
          }
        ]
      }
    }),
    "method": "POST"
  })

  return req.then(res => res.json()).then(data => {
    const code = data?.head?.errcode
    const msg = data?.head?.errmsg
    const warning = [2295 /* 操作频繁 */].includes(code)
    return {
      ok: ![
        13001 /* 没票 */,
        13003 /* 库存不足 */,
        2295 /* 操作频繁 */,
        17002 /* 库存不足 */,
        11006 /* 产品已失效 */,
      ].includes(code), msg, warning, code
    }
  }).catch(e => ({ ok: false, msg: e.message, warning: false, code: -1 }))
}

function getResources() {
  fetch("https://m.ctrip.com/restapi/soa2/14580/getProductPriceCalendar?_fxpcqlniredt=09031079118039639625&x-traceID=09031079118039639625-1682500491162-4974791", {
    "headers": {
      "accept": "*/*",
      "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
      "content-type": "application/json",
      "cookieorigin": "https://m.ctrip.com",
      "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Microsoft Edge\";v=\"114\"",
      "sec-ch-ua-mobile": "?0",
      "sec-ch-ua-platform": "\"macOS\"",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
      "cookie": "Session=smartlinkcode=U130026&smartlinklanguage=zh&SmartLinkKeyWord=&SmartLinkQuary=&SmartLinkHost=; GUID=09031079118039639625; MKT_CKID=1680774277125.6h24x.nq9m; __zpspc=9.1.1680774277.1680774277.1%232%7Cwww.baidu.com%7C%7C%7C%7C%23; _jzqco=%7C%7C%7C%7C%7C1.1614135070.1680774277128.1680774277128.1680774277128.1680774277128.1680774277128.0.0.0.1.1; _RSG=YYKWMLLs.T6g1lEKf_lIdA; _RDG=28083e6c80a244228739ae5f4d4ddd3e4d; _RGUID=677ed955-5681-48a2-a9d2-bffa543af06a; _bfaStatusPVSend=1; nfes_isSupportWebP=1; nfes_isSupportWebP=1; AHeadUserInfo=VipGrade=0&VipGradeName=%C6%D5%CD%A8%BB%E1%D4%B1&UserName=&NoReadMessageCount=0; _abtest_userid=2ec3451a-6c3b-4b14-a066-66a252475f61; cticket=3FC9F4ED698909B3E75F7106C56D69F0EB8AC622F00AA67BD71C085BF79D5B59; login_type=0; login_uid=3FBB3109ADDCEE59C1266FACD2F6640B; DUID=u=EC09CB4D79189597DCD8E1C93DB907A6&v=0; IsNonUser=F; UUID=40F314DC259042F4A0175175A50F3D9F; _ga=GA1.2.1218605105.1682246849; _lizard_LZ=0OYgAVN+D5Xhr8emHFJMRL7b6lfc4B9EszIGtUQpdSPvwqoCZyWKa1iTj-3unk2x; _RF1=61.148.244.253; _gid=GA1.2.944540376.1682484741; _bfi=p1%3D10650083748%26p2%3D153002%26v1%3D145%26v2%3D144; _bfaStatus=send; librauuid=; hotelhst=1164390341; _pd=%7B%22_o%22%3A5%2C%22s%22%3A101%2C%22_s%22%3A0%7D; _bfa=1.1680774276924.49t4m.1.1682484769693.1682500490112.20.172.600001234; _ubtstatus=%7B%22vid%22%3A%221680774276924.49t4m%22%2C%22sid%22%3A20%2C%22pvid%22%3A172%2C%22pid%22%3A600001234%7D; Union=OUID=&AllianceID=3791798&SID=20920823&SourceID=&AppID=&OpenID=&exmktID=&createtime=1682500491&Expires=1683105290833; MKT_OrderClick=ASID=379179820920823&AID=3791798&CSID=20920823&OUID=&CT=1682500490836&CURL=https%3A%2F%2Fm.ctrip.com%2Fwebapp%2Ftaro%2Fpages%2Ftnt%2Fdetail%2Fproduct-sku%2Findex%3FresourceId%3D46403856%26scenicSpotId%3D62722%26ctm_ref%3Dvactang_page_20390%26sid%3D20920823%26allianceid%3D3791798%26isscan%3DT&VAL={\"h5_vid\":\"1680774276924.49t4m\"}",
      "Referer": "https://m.ctrip.com/webapp/taro/pages/tnt/detail/product-sku/index?resourceId=46403856&scenicSpotId=62722&ctm_ref=vactang_page_20390&sid=20920823&allianceid=3791798&isscan=T",
      "Referrer-Policy": "strict-origin-when-cross-origin"
    },
    "body": "{\"clientInfo\":{\"currency\":\"CNY\",\"locale\":\"zh-CN\",\"pageId\":\"600001234\",\"channelId\":116,\"appPlatform\":\"\",\"extension\":[],\"syscode\":\"09\",\"oriSyscode\":\"09\"},\"enviroment\":\"PROD\",\"head\":{\"cid\":\"09031079118039639625\",\"ctok\":\"\",\"cver\":\"1.0\",\"lang\":\"01\",\"sid\":\"8888\",\"syscode\":\"09\",\"auth\":\"\",\"xsid\":\"\",\"extension\":[{\"name\":\"fingerprintKeys\",\"value\":\"tZ6RM9IFvo5JF3ekAebZENpWm0IFNWSPESYcvTmvSmEdnYBfEkTxX9vNMIZYhgE4GITtecAeT7EsNjp7WmlyFNjd1rOYnDwSfjHkrsbjdOwTQvQ8jUJh3jOFwMXvtsjXJafjMmwQGv7djqJNlvq0vhXYLgw6TJDmemhiMkYTdrNowqnWPYoQy67E7OeQhytnjk1vN7Ec1vDhWQXjScEt4rZtWoYFpYc4YtQK8DYL4i0qwk1RzXEgTWAQizmEfdEXY5MWMTKgQRlgIafKFNi6YNTJLlJ8UytE9FW4XEBYdPykMIa3xXlvPZY7syAkj3zvdHeogYfFj0aykJmPvbqYhOytGjs0vfZeqhYtSjhLyNJsmRZZxpkiQOiBYgtIpUroXRb6rfXE0TwFBxmBYLpj1ZjTtWtvdyhXWTYbGrGFe9qegLvp0yhmj7YT6ehsY3PJc1iG6in6jSY9bEzdrDLxc7Yz4iaQi8kiZfjctYFPEh8KpYDgvX5jqXWa3jsOEBOYtpwDOy9oEfUY90whsIAMy00x4YLoWD5eocjQtRnOwczjZhYPoJcPW9GWB5EDTvnhWd1i9bvMGvQmRDjGfIcYqUrfBYOnJBOYzkwpnxNY8fIZbezdWkMR9ZwaSjQpWqDyZFydQE8AYSqyXgwPZvfnYPXEAaRHlv8HjfYztJh4wNkIN6jg6ws9vofj1QIcge4PidYcBwOSizgIqpRfFvN4YAgWBse6cRnZWdBjtgWFGxakjOqWbY0gwfEP0id0R1fvgSY7fWt8eUARMbWBGJU8JU1EAbv3pxlYk7JLMvkHRbBRNTwsMj4BYHsJ5DWQmWZ3EgmvZbWsTiaPjl9E3ti7aEqcy8Y0cIoav7JSdEt6jgHWq3WldWz3YksY6zY8BRsoYNSW1ZYSkYNAYX6jGmeZoEP8W7Ze4Fw8UeOMjalY5fykZEZqjlXEdZr9Gjs8wBbynZrtaINbiQY4FRfcW9gWFbWoGWZhYtYLFK0hIUSjH4vs1EUZW1NypqjkJbzvsME7lWZkyF7jZ9i09IgFIFY0MIfzrXpe5FEaZE6sESkR95Egsvm8EkFRhYm3K0pifdI15EtmE4aEkNYLdYg8Y53YA3xpXx4o\"},{\"name\":\"crawlerKey\",\"value\":\"fe85932c63aa3f6e16879ab82bd388c8c8d87e76070ead92c7373455846b10b3\"},{\"name\":\"H5\",\"value\":\"H5\"}]},\"scenicSpotId\":\"62722\",\"bizLineType\":4,\"id\":\"\",\"filter\":{\"recommendScan\":true,\"beginDate\":\"\",\"endDate\":\"\"},\"token\":\"\",\"needAggregations\":false,\"tags\":[{\"key\":\"relatedResource\",\"value\":\"newLogic\"},{\"key\":\"needReturnUnavailableDate\",\"value\":\"true\"},{\"key\":\"needPackingVersion3\",\"value\":\"true\"},{\"key\":\"seckill\",\"value\":\"newSeckill\"},{\"key\":\"needResourceMinPriceInfo\",\"value\":\"true\"}],\"mainResourceIds\":[46403856],\"needBasicInfo\":true,\"needSaleProperties\":true,\"needUnavailableSaleDates\":true}",
    "method": "POST"
  });
}

over = false

async function run() {
  process.argv.includes('pick') && pick().then(() => { })
  if (process.argv.includes('snap')) {
    snap(cfg.pages[0], cfg.users).then(() => { })
    await sleep(2)
    snap(cfg.pages[1], cfg.users).then(() => { })
  }
  process.argv.includes('seperateSnap') && seperateSnap().then(() => { })
}

run().then(() => { })
