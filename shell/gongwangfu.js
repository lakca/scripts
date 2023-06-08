function get_indate(date) {
  return Math.ceil(Math.abs(date - new Date(2010, 0, 1)) / (1000 * 60 * 60 * 24));
}
fetch("https://web.pgm.org.cn/order/valid", {
  "headers": {
    "accept": "application/json, text/javascript, */*; q=0.01",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
    "content-type": "application/json",
    "sec-ch-ua": "\"Not.A/Brand\";v=\"8\", \"Chromium\";v=\"114\", \"Microsoft Edge\";v=\"114\"",
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "\"macOS\"",
    "sec-fetch-dest": "empty",
    "sec-fetch-mode": "cors",
    "sec-fetch-site": "same-origin",
    "x-requested-with": "XMLHttpRequest",
    "cookie": "__jsluid_h=3bcf6147974a1815cddc43f9d6942653; __jsluid_s=46475701f9e45192c1604075906ea8fc; JSESSIONID=A4BAAF32146BB14A7FFE9F79B040F280; cookie_user_token=A4BAAF32146BB14A7FFE9F79B040F280",
    "Referer": "https://web.pgm.org.cn/index",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  },
  "body": JSON.stringify({
    "inDate": "4864",
    "contactTel": "手机号",
    "orderPeriodType": "1",
    "saleTicketList": [
      {
        "venueId": "1",
        "id": "3000148",
        "priceType": "1",
        "price": "40",
        "certificateType": "1",
        "certificateUserName": "姓名",
        "certificateNo": "身份证号",
        "studentNo": ""
      },
      {
        "venueId": "1",
        "id": "3000152",
        "priceType": "4",
        "price": "20",
        "certificateType": "1",
        "certificateUserName": "姓名",
        "certificateNo": "身份证号",
        "studentNo": ""
      },
      {
        "venueId": "1",
        "id": "3000152",
        "priceType": "4",
        "price": "20",
        "certificateType": "1",
        "certificateUserName": "姓名",
        "certificateNo": "身份证号",
        "studentNo": ""
      }
    ]
  }),
  "method": "POST"
});
