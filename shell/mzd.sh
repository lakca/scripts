#!/usr/bin/env bash

# 获取eventssessionid
curl 'https://jnt.mfu.com.cn/ajax?ugi=bookingquery&action=getSessions&bundleid=com.maiget.tickets&moduleid=6f77be86038c47269f1e00f7ddee9af4' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Cookie: i18n_redirected=zh; Hm_lvt_2a985e9d9884d17b5ed7589beac18720=1682224550; e2928facd8ee42e3baaaac5ed3ed7875=WyIyMTYxMjQxOTQiXQ; JSESSIONID=D791283E7478338E3BFDA0F6E18E0EA4; Hm_lpvt_2a985e9d9884d17b5ed7589beac18720=1682406592' \
  -H 'DNT: 1' \
  -H 'Origin: https://jnt.mfu.com.cn' \
  -H 'Referer: https://jnt.mfu.com.cn/page/user' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0' \
  -H 'm-lang: zh' \
  -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw 'fromtype=PERSONAL&siteid=7e97d18d179c4791bab189f8de87ee9d' \
  --compressed

curl 'https://jnt.mfu.com.cn/ajax?ugi=bookingorder&action=createTicketOrder&bundleid=com.maiget.tickets&moduleid=6f77be86038c47269f1e00f7ddee9af4' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Cookie: i18n_redirected=zh; Hm_lvt_2a985e9d9884d17b5ed7589beac18720=1682224550; e2928facd8ee42e3baaaac5ed3ed7875=WyIyMTYxMjQxOTQiXQ; JSESSIONID=D791283E7478338E3BFDA0F6E18E0EA4; Hm_lpvt_2a985e9d9884d17b5ed7589beac18720=1682407172' \
  -H 'DNT: 1' \
  -H 'Origin: https://jnt.mfu.com.cn' \
  -H 'Referer: https://jnt.mfu.com.cn/page/user/editorder/7047babd63ff4461893c18f2850395fa?date=2023-04-30&begintime=09%3A30&endtime=10%3A15&booking_including_self=1&maxnums=5&minnums=-1' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0' \
  -H 'm-lang: zh' \
  -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw 'eventssessionid=7047babd63ff4461893c18f2850395fa&bookingdata=%5B%7B%22realname%22%3A%22%E9%BE%99%E9%B9%8F%22%2C%22doctype%22%3A%22IDCARD%22%2C%22idnum%22%3A%22身份证号%22%7D%2C%7B%22realname%22%3A%22%E9%BE%99%E6%B3%BD%E7%84%B1%22%2C%22doctype%22%3A%22IDCARD%22%2C%22idnum%22%3A%身份证号%22%7D%2C%7B%22realname%22%3A%22%E5%BE%90%E7%A7%80%E5%85%B0%22%2C%22doctype%22%3A%22IDCARD%22%2C%22idnum%22%3A%身份证号%22%7D%5D' \
  --compressed

# 短信登录
curl 'https://jnt.mfu.com.cn/ajax?ugi=account&action=commonSendSms&bundleid=com.maiget.tickets&moduleid=6f77be86038c47269f1e00f7ddee9af4' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Cookie: i18n_redirected=zh; Hm_lvt_2a985e9d9884d17b5ed7589beac18720=1682224550; e2928facd8ee42e3baaaac5ed3ed7875=WyIyMTYxMjQxOTQiXQ; Hm_lpvt_2a985e9d9884d17b5ed7589beac18720=1682486496; JSESSIONID=6FC1C1752258CD455A2B915D05C80FF5' \
  -H 'DNT: 1' \
  -H 'Origin: https://jnt.mfu.com.cn' \
  -H 'Referer: https://jnt.mfu.com.cn/page/user/login?orderQs=eyJuYW1lIjoidHlwZS1lZGl0b3JkZXItZXZlbnRzc2Vzc2lvbmlkIiwicGFyYW1zIjp7InR5cGUiOiJ1c2VyIiwiZXZlbnRzc2Vzc2lvbmlkIjoiYTg5ZTdkNDZmZDJmNDMyMDg1Mjc0MDU1YzFmNmZiYWYifSwicXVlcnkiOnsiZGF0ZSI6IjIwMjMtMDUtMDIiLCJiZWdpbnRpbWUiOiIwODowMCIsImVuZHRpbWUiOiIwODo0NSIsImJvb2tpbmdfaW5jbHVkaW5nX3NlbGYiOjEsIm1heG51bXMiOjUsIm1pbm51bXMiOi0xfX0%3D' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0' \
  -H 'm-lang: zh' \
  -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw 'accounttype=USER&verifyaction=TICKET-LOGIN&csrf_req=b22606d050634df4a14b242830722c37&csrf_ts=1682486626384&csrf=4ca8b319a9594423e18379f7204e6367&telnum=手机号' \
  --compressed

{
    "code": "A00006",
    "errmsg": "ok"
}

#  短信登录提交验证码
curl 'https://jnt.mfu.com.cn/ajax?ugi=user/account&action=smslogin&bundleid=com.maiget.tickets&moduleid=6f77be86038c47269f1e00f7ddee9af4' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Cookie: i18n_redirected=zh; Hm_lvt_2a985e9d9884d17b5ed7589beac18720=1682224550; e2928facd8ee42e3baaaac5ed3ed7875=WyIyMTYxMjQxOTQiXQ; Hm_lpvt_2a985e9d9884d17b5ed7589beac18720=1682486496; JSESSIONID=D66CD5BBD64EB5F850F6BAFE05F13F64' \
  -H 'DNT: 1' \
  -H 'Origin: https://jnt.mfu.com.cn' \
  -H 'Referer: https://jnt.mfu.com.cn/page/user/login?orderQs=eyJuYW1lIjoidHlwZS1lZGl0b3JkZXItZXZlbnRzc2Vzc2lvbmlkIiwicGFyYW1zIjp7InR5cGUiOiJ1c2VyIiwiZXZlbnRzc2Vzc2lvbmlkIjoiYTg5ZTdkNDZmZDJmNDMyMDg1Mjc0MDU1YzFmNmZiYWYifSwicXVlcnkiOnsiZGF0ZSI6IjIwMjMtMDUtMDIiLCJiZWdpbnRpbWUiOiIwODowMCIsImVuZHRpbWUiOiIwODo0NSIsImJvb2tpbmdfaW5jbHVkaW5nX3NlbGYiOjEsIm1heG51bXMiOjUsIm1pbm51bXMiOi0xfX0%3D' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.0.0' \
  -H 'm-lang: zh' \
  -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Microsoft Edge";v="114"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw 'telnum=手机号&verify=6652&csrf_req=b22606d050634df4a14b242830722c37&csrf_ts=1682486626384&csrf=4ca8b319a9594423e18379f7204e6367' \
  --compressed

Set-Cookie: JSESSIONID=A76046ABFBCE9CFBE9BFA0757AFC987B; Path=/; HttpOnly

{
    "userInfo": {
        "notice_personal": "···    毛主席纪念堂预约账号须使用移动、电信、联通三家运营商自营的手机号码进行实名注册。使用虚拟运营商手机号码注册的账号将被及时清理，相关预约将同时被取消。谢谢您的理解和支持！\r\n·     1．实名预约瞻仰，必须携带身份证等有效证件并接受联网核验。请按照预约的时间段瞻仰参观，无法按时到达请及时取消预约或者改签。\r\n·     2．最多可约5人。老年人、儿童等所有瞻仰参观人员均需要预约。没有二代身份证的老年人、儿童等核验时需提供户口本等其他印有身份证号码的有效证件。\r\n·     3．一般可提前1-6天预约，每天12:30放票，暂不接受当天预约，以实际展示的可预约场次为准。\r\n·     4．每天只可有一个待出行预约。每天可取消2次，取消2次后当天不可再预约。每周可累计取消4次，每月可累计取消6次，每年可累计取消12次。\r\n·     5.每个待出行预约可以改签1次。退票和改签必须在场次开始前10分钟完成。\r\n·     6．预约后未核验入场的人员，被视为爽约。爽约1次将被记为警告状态，仍可正常预约。120天内累计发生2次爽约行为，账号将被锁定，不可再预约。被记为警告或者锁定状态之日起满120天恢复正常状态。\r\n·     7．瞻仰入场须佩戴口罩，接受体温检测。\r\n·     8．严禁携带包、照相机、摄像机、平板电脑、水杯、饮料及各种液体等物品入场。凭预约信息可在广场东侧存包处限时免费寄存。\r\n·     9．如遇特殊情况，毛主席纪念堂暂停开放，预约自动取消。",
        "idtype": "IDCARD",
        "createtime": "2023-04-22 23:22:08",
        "security": 0,
        "warntime": "-",
        "avatar": "https://thirdwx.qlogo.cn/mmopen/vi_32/POgEwh4mIHO4nibH0KlMECNjjGxQUq24ZEaGT4poC6icRiccVGKSyXwibcPq4BWmiaIGuG1icwxaQX6grC9VemZoJ8rg/132",
        "userid": "f4cc68decbb64757a878e03e37f0d56f",
        "idnum": "身份证号",
        "username": "",
        "realname": "姓名",
        "telnum": "手机号",
        "status": 1
    },
    "code": "A00006",
    "errmsg": "ok"
}
