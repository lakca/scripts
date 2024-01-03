# Edge Dev

https://www.douyin.com/aweme/v1/web/danmaku/get_v2/?device_platform=webapp&aid=6383&channel=channel_pc_web&app_name=aweme&format=json&group_id=7318249089613810984&item_id=7318249089613810984&start_time=0&end_time=9567&authentication_token=MS4wLjAAAAAAkVeZHp0pu_G-zjDm_RF2AxfEIINEGckiP1PwjfVDjEnzEvObHWaMqAUaliT2WzrceIZwmxnSqB7Il1dPvGwPymOKK9Nkq9AKd9ZGHAb-a-y0SkO1b4L6HCTM2JR4GkhWokKtw6G-a53_LrAIBTpJlCiHyy4AF7f7MkAyU9mnA--RIia6XTTOg_L9r7UHRiC7zlhkVluBFfkiYB_-uQI84JSGRmMdU0wEkhpZUHE3w-s3hoEy-lhqI293Puq6IZ9q&duration=9567&pc_client_type=1&version_code=170400&version_name=17.4.0&cookie_enabled=true&screen_width=1440&screen_height=900&browser_language=zh-CN&browser_platform=MacIntel&browser_name=Edge&browser_version=114.0.1788.0&browser_online=true&engine_name=Blink&engine_version=114.0.0.0&os_name=Mac+OS&os_version=10.15.7&cpu_core_num=8&device_memory=8&platform=PC&downlink=1.25&effective_type=3g&round_trip_time=400&webid=7319767823827289639&msToken=QeuFg6oD0H0302MuiDQdycfQVAl8g5aAQbzyYGiV3WmuHcHgGT3lcGCqjKi5f66o_MZxJ__OLbr8XC_2yYSzT-6hw8Z0S7VpJmz31PFD2EiM1VqBfY6V&X-Bogus=DFSzswVLSpTANcsjt7Z/sDok/RKX


# 抖音网页版加载流程（匿名用户生成流程）

1. 打开页面，返回用户（客户端）ID`user_unique_id`, `webid`

```http
GET https://www.douyin.com/
```

返回的页面代码中的js会生成 `window.__pace_f`属性。

`JSON.parse(decodeURIComponent(window.__pace_f[4][1]))`与`window.SSR_RENDER_DATA`相同，里面有客户端的很多信息，包括`SSR_RENDER_DATA.app.odin.user_unique_id`。

```json
{
  "user_unique_id": 7319800910800111115
}
```

响应：

```
Set-Cookie: ttwid=1%7C5aVZ4z_ys6dSrpcZUNdZHTej2ETBnb0FNzkIkTZ61Yg%7C1704273972%7C28f88c21ee1b96c06031939ae720a1a13c9789852821d27d10568246d0d016a0; Domain=.douyin.com; Path=/; Expires=Sat, 28 Dec 2024 09:26:12 GMT; HttpOnly
```
`decodeURIComponent`解码后：
```
1|5aVZ4z_ys6dSrpcZUNdZHTej2ETBnb0FNzkIkTZ61Yg|1704273972|28f88c21ee1b96c06031939ae720a1a13c9789852821d27d10568246d0d016a0
```

2. 获取生成`X-Bogus`的文件

```
GET https://lf-c-flwb.bytetos.com/obj/rc-client-security/c-webmssdk/1.0.0.20/webmssdk.es5.js
```

该js文件保存有生成`X-Bogus`的方法，具体如何使用见`./douyin.js`。

3. 查询用户信息

```http
GET https://www.douyin.com/aweme/v1/web/query/user/?device_platform=webapp&aid=6383&channel=channel_pc_web&publish_video_strategy_type=2&pc_client_type=1&version_code=170400&version_name=17.4.0&cookie_enabled=true&screen_width=1920&screen_height=1080&browser_language=zh-CN&browser_platform=MacIntel&browser_name=Edge&browser_version=114.0.1788.0&browser_online=true&engine_name=Blink&engine_version=114.0.0.0&os_name=Mac+OS&os_version=10.15.7&cpu_core_num=8&device_memory=8&platform=PC&downlink=1.55&effective_type=3g&round_trip_time=350&webid=7319800910800111115&msToken=&X-Bogus=DFSzswVOc4bANahVt7ZuIEok/RK1

Cookie: IsDouyinActive=false; stream_player_status_params=%22%7B%5C%22is_auto_play%5C%22%3A0%2C%5C%22is_full_screen%5C%22%3A0%2C%5C%22is_full_webscreen%5C%22%3A0%2C%5C%22is_mute%5C%22%3A1%2C%5C%22is_speed%5C%22%3A1%2C%5C%22is_visible%5C%22%3A0%7D%22; __ac_nonce=065952833007d6ea27bbd; __ac_signature=_02B4Z6wo00f010ZBbIwAAIDAFjYodejuZxtGYWgAALQQ68; ttwid=1%7C5aVZ4z_ys6dSrpcZUNdZHTej2ETBnb0FNzkIkTZ61Yg%7C1704273972%7C28f88c21ee1b96c06031939ae720a1a13c9789852821d27d10568246d0d016a0; douyin.com; device_web_cpu_core=8; device_web_memory_size=8
```

响应：
```
Cookie_ttwidinfo_webid: 7319800910800111115
```
```json
{
  "id": "7319800910800111115",
  "create_time": "1704273972",
  "last_time": "1704273972",
  "user_uid": "2192878539383555",
  "user_uid_type": 0,
  "firebase_instance_id": "",
  "user_agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36 Edg/114.0.1788.0",
  "browser_name": "Chrome"
}
```

## 指纹`s_v_web_id`, `fp`, `verifyFp`，登录相关的API用到

通过debugger可以找到，生成指纹的代码比较简单：

```js
function() {
    var e = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split("")
      , t = e.length
      , r = Date.now().toString(36)
      , n = [];
    n[8] = n[13] = n[18] = n[23] = "_",
    n[14] = "4";
    for (var o = 0, i = void 0; o < 36; o++)
        n[o] || (i = 0 | Math.random() * t,
        n[o] = e[19 == o ? 3 & i | 8 : i]);
    return "verify_" + r + "_" + n.join("")
}
```

## 其他请求：

- 获取客户端的设置

```
GET https://mon.zijieapi.com/monitor_web/settings/browser-settings?bid=douyin_web&store=1
```

响应：
```json
{
  "data": {
    "sample": {
      "sample_rate": 1,
      "include_users": [
        "7162101629725476383",
        "7203185376801605172"
      ],
      "sample_granularity": "session",
      "rules": [
        {
          "name": "js_error",
          "enable": true,
          "sample_rate": 1,
          "conditional_sample_rules": []
        },
        {
          "name": "http",
          "enable": true,
          "sample_rate": 0.01,
          "conditional_sample_rules": []
        },
        {
          "name": "performance",
          "enable": true,
          "sample_rate": 0.5,
          "conditional_sample_rules": []
        },
        {
          "name": "resource_error",
          "enable": true,
          "sample_rate": 1,
          "conditional_sample_rules": []
        },
        {
          "name": "resource",
          "enable": true,
          "sample_rate": 0.01,
          "conditional_sample_rules": []
        },
        {
          "name": "custom",
          "enable": true,
          "sample_rate": 1,
          "conditional_sample_rules": [
            {
              "sample_rate": 0.01,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[WARN][风控]登录弹框"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.01,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[WARN][风控]验证码弹框"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.01,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[INFO][新首页]模块FEED返回视频个数与请求不一致"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.01,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[WARN][全局]视频播放卡顿"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.001,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "imsdk.network.request"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.001,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "regex",
                    "groupKey": "",
                    "values": [
                      "imsdk.*"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.0001,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "im-sdk-error"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.0001,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[INFO][新首页]新首页模块请求"
                    ]
                  }
                ]
              }
            },
            {
              "sample_rate": 0.0001,
              "filter": {
                "type": "and",
                "children": [
                  {
                    "type": "rule",
                    "field": "payload.name",
                    "op": "eq",
                    "groupKey": "",
                    "values": [
                      "[ERROR][直播]影响直播播放"
                    ]
                  }
                ]
              }
            }
          ]
        },
        {
          "name": "performance_timing",
          "enable": true,
          "sample_rate": 0.01,
          "conditional_sample_rules": []
        },
        {
          "name": "performance_longtask",
          "enable": true,
          "sample_rate": 0.01,
          "conditional_sample_rules": []
        },
        {
          "name": "pageview",
          "enable": true,
          "sample_rate": 0.1,
          "conditional_sample_rules": []
        },
        {
          "name": "action",
          "enable": true,
          "sample_rate": 1,
          "conditional_sample_rules": []
        },
        {
          "name": "blank_screen",
          "enable": true,
          "sample_rate": 1,
          "conditional_sample_rules": []
        }
      ]
    },
    "user_id": "c17827fb-2199-32f8-3f8f-2ebf8d994fde",
    "plugins": {
      "heatmap": {
        "open_list": [],
        "url": "https://lf3-short.bytegoofy.com/slardar/heatmap/resource/heatmap.cn.js"
      }
    },
    "quota_rate": 1,
    "timestamp": 1704273976880
  },
  "errmsg": "success",
  "errno": 200
}
```

- 获取用户信息

```
https://www.douyin.com/aweme/v1/web/user/profile/self/?device_platform=webapp&aid=6383&channel=channel_pc_web&publish_video_strategy_type=2&source=channel_pc_web&personal_center_strategy=1&pc_client_type=1&version_code=170400&version_name=17.4.0&cookie_enabled=true&screen_width=1920&screen_height=1080&browser_language=zh-CN&browser_platform=MacIntel&browser_name=Edge&browser_version=114.0.1788.0&browser_online=true&engine_name=Blink&engine_version=114.0.0.0&os_name=Mac+OS&os_version=10.15.7&cpu_core_num=8&device_memory=8&platform=PC&downlink=10&effective_type=4g&round_trip_time=150&webid=7319789018961561127&msToken=&X-Bogus=DFSzswVO4jsANahVt7Z2pfok/RBz
```

- 获取验证码

```http
POST https://sso.douyin.com/send_activation_code/v2/?device_platform=web_app&aid=6383&account_sdk_source=sso&sdk_version=2.2.7-beta.6&language=zh&verifyFp=verify_lqxlwa9w_GHsxx6F6_eS6G_4aJX_9zFp_1fsvbx13tuDL&fp=verify_lqxlwa9w_GHsxx6F6_eS6G_4aJX_9zFp_1fsvbx13tuDL&msToken=zs01K4SLZMXrWD6nLkITIRR8tfFX8yZgUwvcmVseWuBTm8Zq073ZRIVmN1hBn-36Jrx0xMRzKDHh6w_hLtJC6hDzZcbxLp3cZcHEqNdN5NK-XL7b1sOpR0aqn27bBw==&X-Bogus=DFSzswVuigyYR3H9t7ZPLLHB7t1q

Content-Type: application/x-www-form-urlencoded

mix_mode=1&mobile=2e3d33253433303630303636343d3d&type=31&is6Digits=1&fixed_mix_mode=1
```

```http
Set-Cookie: msToken=...
```

## 帮助

### 手机号加密

```js
L = function(e) {
  var t, r = [];
  if (void 0 === e)
      return "";
  t = function(e) {
      for (var t, r = e.toString(), n = [], o = 0; o < r.length; o++)
          0 <= (t = r.charCodeAt(o)) && t <= 127 ? n.push(t) : 128 <= t && t <= 2047 ? (n.push(192 | 31 & t >> 6),
          n.push(128 | 63 & t)) : (2048 <= t && t <= 55295 || 57344 <= t && t <= 65535) && (n.push(224 | 15 & t >> 12),
          n.push(128 | 63 & t >> 6),
          n.push(128 | 63 & t));
      for (var i = 0; i < n.length; i++)
          n[i] &= 255;
      return n
  }(e);
  for (var n = 0, o = t.length; n < o; ++n)
      r.push((5 ^ t[n]).toString(16));
  return r.join("")
}
function R(e, t) {
    var r, n = 0, o = 0;
    if ("object" != typeof e || !t || t.length <= 0)
        return e;
    for (var i = Object.assign({
        mix_mode: n
    }, e), a = 0, u = t.length; a < u; ++a)
        void 0 !== (r = i[t[a]]) && (n |= 1,
        o |= 1,
        i[t[a]] = L(r));
    return i.mix_mode = n,
    i.fixed_mix_mode = o,
    i
}

encrypted={
    "mix_mode": 1,
    "mobile": "2e3d33253433303630303636343d3d",
    "type": "31",
    "is6Digits": 1,
    "fixed_mix_mode": 1
}

R({
    "mobile": "+86 16535533188",
    "type": 4,
    "is6Digits": 1
}, ["mobile", "type"])
```
