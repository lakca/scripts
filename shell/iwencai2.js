const fs = require('fs')
const path = require('path')
  async function request() {
    const res = await fetch("http://www.iwencai.com/gateway/urp/v7/landing/getDataList", {
  "headers": {
    "accept": "application/json, text/plain, */*",
    "accept-language": "zh-CN,zh;q=0.9,en;q=0.8",
    "cache-control": "no-cache",
    "content-type": "application/x-www-form-urlencoded",
    "hexin-v": "A6UuhMHeLd9I9kmDd9HuEIsIsmra4mEeo-w_sKaVYIrrXsvUbzJpRDPmTTU0",
    "pragma": "no-cache",
    "proxy-connection": "keep-alive",
    "cookie": "cid=fd60046b76757ba6feab35b50af3b8321666873448; other_uid=Ths_iwencai_Xuangu_07ik8k3fj41l9mp6v28py3izadxil66k; ta_random_userid=nh83m13mih; v=A6UuhMHeLd9I9kmDd9HuEIsIsmra4mEeo-w_sKaVYIrrXsvUbzJpRDPmTTU0",
    "Referer": "http://www.iwencai.com/unifiedwap/result?w=%E9%9D%9EST%E3%80%81%E9%9D%9E%E9%80%80%E5%B8%82%E3%80%81%E4%B8%8A%E5%B8%82%E4%B8%89%E5%B9%B4%E4%BB%A5%E4%B8%8A%EF%BC%8C%E8%82%A1%E4%B8%9C%E4%BA%BA%E6%95%B0%E4%BB%8E%E5%B0%91%E5%88%B0%E5%A4%9A%E6%8E%92%E5%90%8D%EF%BC%8C%E5%88%97%E5%90%8D%E5%8F%AA%E5%8C%85%E5%90%AB%E9%9B%86%E4%B8%AD%E5%BA%A690%E3%80%81%E8%A1%8C%E4%B8%9A%E3%80%81%E4%BC%81%E4%B8%9A%E6%80%A7%E8%B4%A8%E3%80%81%E6%80%BB%E5%B8%82%E5%80%BC%E3%80%81%E6%89%80%E5%B1%9E%E6%A6%82%E5%BF%B5%E3%80%81%E6%8A%80%E6%9C%AF%E5%BD%A2%E6%80%81&querytype=stock",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  },
"body": new URLSearchParams({
  "query": "非ST、非退市、上市三年以上，股东人数从少到多排名，列名只包含集中度90、行业、企业性质、总市值、所属概念、技术形态",
  "urp_sort_way": "asc",
  "urp_sort_index": "最新股东户数",
  "page": "1",
  "perpage": "100",
  "addheaderindexes": "",
  "condition": [
    {
      "chunkedResult": "非st、非退市、上市三年以上,_&_股东人数从少到多排名,_&_列名只包含集中度90、行业、企业性质、总市值、所属概念、技术形态",
      "opName": "and",
      "opProperty": "",
      "sonSize": 19,
      "relatedSize": 0
    },
    {
      "reportType": "null",
      "indexName": "股票简称",
      "indexProperties": [
        "不包含st,退"
      ],
      "valueType": "_股票简称",
      "domain": "abs_股票领域",
      "uiText": "股票简称不包含st",
      "sonSize": 0,
      "queryText": "股票简称不包含st",
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {
        "不包含": "st,退"
      }
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 17,
      "relatedSize": 0
    },
    {
      "reportType": "null",
      "indexName": "股票简称",
      "indexProperties": [
        "不包含st,退"
      ],
      "valueType": "_股票简称",
      "domain": "abs_股票领域",
      "uiText": "股票简称不包含退",
      "sonSize": 0,
      "queryText": "股票简称不包含退",
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {
        "不包含": "st,退"
      }
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 15,
      "relatedSize": 0
    },
    {
      "indexName": "上市天数",
      "indexProperties": [
        "nodate 1",
        "交易日期 20230602",
        "(=1095"
      ],
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {
        "交易日期": "20230602",
        "(=": "1095",
        "nodate": "1"
      },
      "reportType": "TRADE_DAILY",
      "dateType": "交易日期",
      "valueType": "_整型数值(天)",
      "domain": "abs_股票领域",
      "uiText": "上市天数>=1095天",
      "sonSize": 0,
      "queryText": "上市天数>=1095天",
      "relatedSize": 0
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 13,
      "relatedSize": 0
    },
    {
      "opName": "sort",
      "opProperty": "从小到大排名",
      "uiText": "最新股东户数从小到大排名",
      "sonSize": 1,
      "queryText": "最新股东户数从小到大排名",
      "relatedSize": 1
    },
    {
      "reportType": "null",
      "indexName": "最新股东户数",
      "indexProperties": [],
      "valueType": "_整型数值(户|家|人|个)",
      "domain": "abs_股票领域",
      "sonSize": 0,
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {}
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 10,
      "relatedSize": 0
    },
    {
      "indexName": "集中度90",
      "indexProperties": [
        "nodate 1",
        "交易日期 20230602"
      ],
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {
        "交易日期": "20230602",
        "nodate": "1"
      },
      "reportType": "TRADE_DAILY",
      "dateType": "交易日期",
      "valueType": "_浮点型数值(%)",
      "domain": "abs_股票领域",
      "uiText": "集中度90",
      "sonSize": 0,
      "queryText": "集中度90",
      "relatedSize": 0
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 8,
      "relatedSize": 0
    },
    {
      "reportType": "null",
      "indexName": "所属同花顺行业",
      "indexProperties": [],
      "valueType": "_所属同花顺行业",
      "domain": "abs_股票领域",
      "uiText": "所属同花顺行业",
      "sonSize": 0,
      "queryText": "所属同花顺行业",
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {}
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 6,
      "relatedSize": 0
    },
    {
      "reportType": "null",
      "indexName": "企业性质",
      "indexProperties": [],
      "valueType": "_企业性质",
      "domain": "abs_股票领域",
      "uiText": "企业性质",
      "sonSize": 0,
      "queryText": "企业性质",
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {}
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 4,
      "relatedSize": 0
    },
    {
      "indexName": "总市值",
      "indexProperties": [
        "nodate 1",
        "交易日期 20230602"
      ],
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {
        "交易日期": "20230602",
        "nodate": "1"
      },
      "reportType": "TRADE_DAILY",
      "dateType": "交易日期",
      "valueType": "_浮点型数值(元|港元|美元|英镑)",
      "domain": "abs_股票领域",
      "uiText": "总市值",
      "sonSize": 0,
      "queryText": "总市值",
      "relatedSize": 0
    },
    {
      "opName": "and",
      "opProperty": "",
      "sonSize": 2,
      "relatedSize": 0
    },
    {
      "reportType": "null",
      "indexName": "所属概念",
      "indexProperties": [],
      "valueType": "_所属概念",
      "domain": "abs_股票领域",
      "uiText": "所属概念",
      "sonSize": 0,
      "queryText": "所属概念",
      "relatedSize": 0,
      "source": "new_parser",
      "type": "index",
      "indexPropertiesMap": {}
    },
    {
      "indexName": "技术形态",
      "indexProperties": [
        "nodate 1",
        "交易日期 20230602"
      ],
      "source": "new_parser",
      "type": "tech",
      "indexPropertiesMap": {
        "交易日期": "20230602",
        "nodate": "1"
      },
      "reportType": "TRADE_DAILY",
      "dateType": "交易日期",
      "valueType": "_技术形态",
      "domain": "abs_股票领域",
      "uiText": "技术形态",
      "sonSize": 0,
      "queryText": "技术形态",
      "relatedSize": 0
    }
  ],
  "codelist": "",
  "indexnamelimit": "",
  "logid": "dcb8cef456950f75a4f9950a03209564",
  "ret": "json_all",
  "sessionid": "dcb8cef456950f75a4f9950a03209564",
  "source": "Ths_iwencai_Xuangu",
  "date_range[0]": "20230602",
  "date_range[1]": "20230602",
  "iwc_token": "0ac9668416858072771375217",
  "urp_use_sort": "1",
  "user_id": "Ths_iwencai_Xuangu_07ik8k3fj41l9mp6v28py3izadxil66k",
  "uuids[0]": "24087",
  "query_type": "stock",
  "comp_id": "6734520",
  "business_cat": "soniu",
  "uuid": "24087"
}).toString(),
  "method": "POST"
});
    return res.json()
  }
  request().then(data => {
    fs.writeFileSync(path.join('/Users/dgrocsky/Documents/github/scripts/shell', '2023-6-4非ST、非退市、上市三年以上，股东人数从少到多排名，列名只包含集中度90、行业、企业性质、总市值、所属概念、技术形态.1.txt'), JSON.stringify(data, null, 2))
  })
