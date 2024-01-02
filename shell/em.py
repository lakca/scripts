#! /usr/bin/env python3

from os import path
import re
import time
from sys import argv
from librequest import get
from libpopen import browse


def search(keyword, count=20):
    timestamp = int(time.time() * 1000)
    url = 'https://searchapi.eastmoney.com/api/suggest/get'
    query = {
        'cb': f'jQuery1124007392431488856332_{timestamp}',
        'input': keyword,
        'token': 'D43BF722C8E33BDC906FB84D85E326E8',
        'markettype': '',
        'mktnum': '',
        'jys': '',
        'classify': '',
        'securitytype': '',
        'status': '',
        'count': count,
        '_': timestamp,
        'type': 14,
    }
    # 1 沪A 2 深A 5 指数 _TB 三板 7 美股 8 基金 9 板块
    data = get(url, query=query, jsonp=True, returnJson=True)
    # {'QuotationCodeTable': {'Data': [{'Code': '002049', 'Name': '紫光国微', 'PinYin': 'ZGGW', 'ID': '0020492', 'JYS': '6', 'Classify': 'AStock', 'MarketType': '2', 'SecurityTypeName': '深A', 'SecurityType': '2', 'MktNum': '0', 'TypeUS': '6', 'QuoteID': '0.002049', 'UnifiedCode': '002049', 'InnerCode': '46125458803238'}], 'Status': 0, 'Message': '成功', 'TotalCount': 1, 'BizCode': '', 'BizMsg': ''}}
    data = data['QuotationCodeTable']['Data']

    if len(data) > 1:
        for e in data:
            print(
                e['Code'],
                e['PinYin'],
                e['Name'],
            )
        s = input('请选择:')

        for e in data:
            if e['Code'] == s or data['Name'].startswith(s) or data['PinYin'].lower().startswith(s.lower()):
                data = [e]
                break

    if len(data) == 1:
        data = data[0]
        return (
            (
                'sz'
                if data['SecurityTypeName'].startswith('深')
                else 'sh'
                if data['SecurityTypeName'].startswith('沪')
                else 'bj'
                if data['SecurityTypeName'].startswith('京')
                else ''
            )
            + data['Code'],
            data['Name'],
        )


def generate_url(url, symbol, name):
    url = re.sub(r'\b(sz|sh|bj|bk)[0-9]{4,6}\b', symbol, url, flags=re.IGNORECASE)
    url = re.sub(r'\b[0-9]{6}\b', re.search(r'[0-9]+', symbol).group(0), url)
    if name:
        url = url.replace('紫光国微', name)
    return url


SINGLE_LINKS = {
    '个股主页': 'https://quote.eastmoney.com/sz002049.html',
    '极速行情': 'https://quote.eastmoney.com/concept/sz002049.html',
    '数据中心': {
        '公司简介': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gsgk',
        '主要高管': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gsgg',
        '数据中心': 'https://data.eastmoney.com/stockdata/002049.html',
        '资金流向': ('https://data.eastmoney.com/zjlx/002049.html', 1),
        '板块资金流向': ('https://data.eastmoney.com/bkzj/BK1031.html', 1),
        '千股千评': 'https://data.eastmoney.com/stockcomment/002049.html',
        '公告': 'https://data.eastmoney.com/notices/stock/002049.html',
        '个股日历': ('https://data.eastmoney.com/stockcalendar/002049.html', 1),
        '财务数据': 'https://data.eastmoney.com/bbsj/002049.html',
        '核心题材': ('https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/hxtc', 1),
        '主力持仓': 'https://data.eastmoney.com/zlsj/detail/002049.html',
        '股东分析': 'https://data.eastmoney.com/gdfx/stock/002049.html',
        '股东户数': 'https://data.eastmoney.com/gdhs/detail/002049.html',
        '分红送配': 'https://data.eastmoney.com/yjfp/detail/002049.html',
        '分时': 'https://quote.eastmoney.com/unify/r/0.002049',
        'K线': 'https://quote.eastmoney.com/unify/r/0.002049',
        '重点关注': 'https://data.eastmoney.com/stockcalendar/002049.html',
        '行业排名': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/glgg',
        '核心题材': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/hxtc',
        '融资融券': ('https://data.eastmoney.com/rzrq/detail/002049.html', 1),
        '千股千评': 'https://data.eastmoney.com/stockcomment/002049.html',
        '龙虎榜单': 'https://data.eastmoney.com/stock/lhb/lcsb/002049.html',
        '大宗交易': 'https://data.eastmoney.com/dzjy/detail/002049.html',
        '个股资讯': ('https://so.eastmoney.com/Search.htm?q=(002049)(紫光国微)&m=0&t=2', 1),
        '行业资讯': 'https://stock.eastmoney.com/hangye/hy1036.html',
        '公告': 'https://data.eastmoney.com/notices/stock/002049.html',
        '互动易': 'https://gb.eastmoney.com/qa/qa_search.aspx?company=002049',
        '个股研报': 'https://data.eastmoney.com/report/002049.html',
        '行业研报': 'https://data.eastmoney.com/report/1036yb.html',
        '机构评级': 'https://data.eastmoney.com/report/hyyl,002049_1.html',
        '业绩预测': 'https://data.eastmoney.com/report/hyyl,002049_1.html',
        '股权质押': 'https://data.eastmoney.com/gpzy/detail/002049.html',
        '并购重组': ('https://data.eastmoney.com/bgcz/detail/002049.html', 1),
        '股票回购': 'https://data.eastmoney.com/gphg/002049.html',
        '重大合同': 'https://data.eastmoney.com/zdht/detail/002049.html',
        '关联交易': 'https://data.eastmoney.com/gljy/detail/002049.html',
        '证券投资': 'https://data.eastmoney.com/gstz/stock/002049.html',
        '长期股权投资': 'https://data.eastmoney.com/gstz/stock/002049.html?type=2',
        '委托理财': 'https://data.eastmoney.com/wtlc/detail/002049.html',
        '机构调研': ('https://data.eastmoney.com/jgdy/gsjsdy/002049.html', 1),
        '主力持仓': ('https://data.eastmoney.com/zlsj/detail/002049.html', 1),
        '十大流通股东': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gdyj',
        '十大股东': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gdyj',
        '一致行动人': 'https://data.eastmoney.com/yzxdr/stock/002049.html',
        '股东户数': ('https://data.eastmoney.com/gdhs/detail/002049.html', 1),
        '股东大会': 'https://data.eastmoney.com/gddh/list/002049.html',
        '限售解禁': ('https://data.eastmoney.com/dxf/q/002049.html', 1),
        '股东增减持': ('https://data.eastmoney.com/executive/gdzjc/002049.html', 1),
        '高管持股变动': 'https://data.eastmoney.com/executive/002049.html',
        '一致行动人': 'https://data.eastmoney.com/yzxdr/stock/002049.html',
        '股本结构': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gbjg',
        '派现与募资对比': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/fhrz',
        '新股发行': 'https://data.eastmoney.com/xg/xg/detail/002049.html',
        '增发': ('https://data.eastmoney.com/other/gkzf.html', 1),
        '配股': 'https://data.eastmoney.com/xg/pg/detail/002049.html',
        '可转债': 'https://data.eastmoney.com/kzz/default.html',
        '分红送配': 'https://data.eastmoney.com/yjfp/detail/002049.html',
    },
    '行情中心': {
        '行情中心': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049',
        '操盘必读': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/cpbd',
        '股东研究': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gdyj',
        '经营分析': ('https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/jyfx', 1),
        '核心题材': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/hxtc',
        '资讯公告': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/zxgg',
        '公司大事': ('https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gsds', 1),
        '公司概况': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gsgk',
        '同行比较': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/thbj',
        '盈利预测': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/ylyc',
        '研究报告': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/yjbg',
        '财务分析': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/cwfx',
        '分红融资': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/fhrz',
        '股本结构': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gbjg',
        '公司高管': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/gsgg',
        '资本运作': 'https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/zbyz',
        '关联个股': ('https://emweb.securities.eastmoney.com/pc_hsf10/pages/index.html?type=web&code=SZ002049&color=b#/glgg', 1),
        '资金流向': 'https://data.eastmoney.com/zjlx/002049.html',
        '龙虎榜单': 'https://data.eastmoney.com/stock/lhb/002049.html',
        '机构评级': 'https://data.eastmoney.com/report/002049.html',
        '智能点评': ('https://data.eastmoney.com/stockcomment/stock/002049.html', 1),
        '股吧': 'http://guba.eastmoney.com/list,002049.html',
        '机构散户': 'http://data.eastmoney.com/stockcomment/002049.html',
        '大单成交': 'http://quote.eastmoney.com/f1.html?code=002049&market=0',
        '盈利预测': 'http://data.eastmoney.com/report/002049.html',
        '问董秘': 'http://guba.eastmoney.com/qa/qa_search.aspx?company=002049&keyword=&questioner=&qatype=1',
    },
}

BOARD_LINKS = {
    '板块资金': ('https://data.eastmoney.com/bkzj/BK1038.html', 1),
}

DATA_LINKS = {
    '资讯中心': {
        '首页': 'http://www.eastmoney.com/',
        '7*24全球直播': ('https://kuaixun.eastmoney.com/', 1),
        '焦点': ('https://kuaixun.eastmoney.com/yw.html', 1),
        '股市直播': 'https://kuaixun.eastmoney.com/zhibo.html',
        '上市公司': 'https://kuaixun.eastmoney.com/ssgs.html',
        '地区': 'https://kuaixun.eastmoney.com/dq.html',
        '中国': 'https://kuaixun.eastmoney.com/dq_zg.html',
        '美国': 'https://kuaixun.eastmoney.com/dq_mg.html',
        '欧元区': 'https://kuaixun.eastmoney.com/dq_oyq.html',
        '英国': 'https://kuaixun.eastmoney.com/dq_yg.html',
        '日本': 'https://kuaixun.eastmoney.com/dq_rb.html',
        '加拿大': 'https://kuaixun.eastmoney.com/dq_jnd.html',
        '澳洲': 'https://kuaixun.eastmoney.com/dq_oz.html',
        '新兴市场': 'https://kuaixun.eastmoney.com/dq_xxsc.html',
        '全球央行': 'https://kuaixun.eastmoney.com/qqyh.html',
        '中国央行': 'https://kuaixun.eastmoney.com/qqyh_zgyh.html',
        '美联储': 'https://kuaixun.eastmoney.com/qqyh_mlc.html',
        '欧洲央行': 'https://kuaixun.eastmoney.com/qqyh_ozyh.html',
        '英国央行': 'https://kuaixun.eastmoney.com/qqyh_ygyh.html',
        '日本央行': 'https://kuaixun.eastmoney.com/qqyh_rbyh.html',
        '加拿大央行': 'https://kuaixun.eastmoney.com/qqyh_jndyh.html',
        '澳洲联储': 'https://kuaixun.eastmoney.com/qqyh_ozlc.html',
        '经济数据': 'https://kuaixun.eastmoney.com/jjsj.html',
        '中国数据': 'https://kuaixun.eastmoney.com/jjsj_zgsj.html',
        '美国数据': 'https://kuaixun.eastmoney.com/jjsj_mgsj.html',
        '欧元区数据': 'https://kuaixun.eastmoney.com/jjsj_oyqsj.html',
        '英国数据': 'https://kuaixun.eastmoney.com/jjsj_ygsj.html',
        '日本数据': 'https://kuaixun.eastmoney.com/jjsj_rbsj.html',
        '加拿大数据': 'https://kuaixun.eastmoney.com/jjsj_jndsj.html',
        '澳洲数据': 'https://kuaixun.eastmoney.com/jjsj_ozsj.html',
        '全球股市': 'https://kuaixun.eastmoney.com/qqgs.html',
        '商品': 'https://kuaixun.eastmoney.com/sp.html',
        '外汇': 'https://kuaixun.eastmoney.com/wh.html',
        '债券': 'https://kuaixun.eastmoney.com/zq.html',
        '基金': 'https://kuaixun.eastmoney.com/jj.html',
    },
    '行情中心': {
        '行情中心': 'https://quote.eastmoney.com/center/',
        '行情异动': ('https://quote.eastmoney.com/changes/', 1),
    },
    '公告中心': {
        '公告中心': ('https://data.eastmoney.com/notices/', 1),
        '重大事项': ('https://data.eastmoney.com/notices/hsa/5.html', 1),
        '财务报告': ('https://data.eastmoney.com/notices/hsa/1.html', 1),
        '融资公告': 'https://data.eastmoney.com/notices/hsa/2.html',
        '风险提示': ('https://data.eastmoney.com/notices/hsa/3.html', 1),
        '资产重组': ('https://data.eastmoney.com/notices/hsa/6.html', 1),
        '信息变更': 'https://data.eastmoney.com/notices/hsa/4.html',
        '持股变动': 'https://data.eastmoney.com/notices/hsa/7.html',
    },
    '数据中心': {
        '数据中心': 'https://data.eastmoney.com/rzrq/',
        '热门数据': {
            '沪深港通持股': 'http://data.eastmoney.com/hsgtcg/',
            '最新业绩报表': ('http://data.eastmoney.com/bbsj/', 1),
            '新股申购': 'http://data.eastmoney.com/xg/xg/default.html',
            '龙虎榜单': ('http://data.eastmoney.com/stock/lhb.html', 1),
            '注册审核企业': 'http://data.eastmoney.com/xg/zczsh.html',
            '估值分析': ('http://data.eastmoney.com/gzfx/', 1),
        },
        '资金流向': {
            '资金流向': ('http://data.eastmoney.com/zjlx/', 1),
            '大盘资金流': ('http://data.eastmoney.com/zjlx/dpzjlx.html', 1),
            '个股资金流': ('http://data.eastmoney.com/zjlx/detail.html', 1),
            '主力排名': 'http://data.eastmoney.com/zjlx/list.html',
            '板块资金': 'http://data.eastmoney.com/bkzj/',
            '行业资金流': ('http://data.eastmoney.com/bkzj/hy.html', 1),
            '概念资金流': ('http://data.eastmoney.com/bkzj/gn.html', 1),
            '地域资金流': ('http://data.eastmoney.com/bkzj/dy.html', 1),
            '资金流监测': 'http://data.eastmoney.com/bkzj/jlr.html',
            '沪深港通资金': 'http://data.eastmoney.com/hsgt/index.html',
            '沪深港通成交': 'http://data.eastmoney.com/hsgt/top10.html',
            '沪深港通持股': 'http://data.eastmoney.com/hsgtcg/',
        },
        '特色数据': {
            '特色数据': 'http://data.eastmoney.com/stock/lhb.html',
            'AB股比价': 'http://quote.eastmoney.com/center/list.html#absh_0_4',
            'AH股比价': 'http://quote.eastmoney.com/center/list.html#ah_1',
            '并购重组': 'http://data.eastmoney.com/bgcz/',
            '财经日历': 'http://data.eastmoney.com/dcrl/',
            '成分股数据': 'https://data.eastmoney.com/other/index/',
            '大宗交易': 'http://data.eastmoney.com/dzjy/default.html',
            '分红送配': ('http://data.eastmoney.com/yjfp/', 1),
            '分析师指数': 'http://data.eastmoney.com/invest/invest/default.html',
            '个税计算器': 'http://data.eastmoney.com/other/gs.html',
            '公司题材': 'http://data.eastmoney.com/gstc/',
            '公司投资': 'http://data.eastmoney.com/gstz/',
            '估值分析': ('http://data.eastmoney.com/gzfx/', 1),
            '股东大会': 'http://data.eastmoney.com/gddh/',
            '股东高管持股': 'http://data.eastmoney.com/gdggcg/',
            '股票回购': ('http://data.eastmoney.com/gphg/', 1),
            '股票统计': 'http://data.eastmoney.com/cjsj/gpjytj.html',
            '股票账户统计(月)': 'http://data.eastmoney.com/cjsj/gpkhsj.html',
            '股权质押': 'http://data.eastmoney.com/gpzy/',
            '关联交易': 'http://data.eastmoney.com/gljy/',
            '机构调研': 'http://data.eastmoney.com/jgdy/',
            '交易结算资金': 'http://data.eastmoney.com/cjsj/bankTransfer.html',
            '龙虎榜单': ('http://data.eastmoney.com/stock/lhb.html', 1),
            'LPR数据': 'http://data.eastmoney.com/cjsj/globalRateLPR.html',
            '千股千评': 'http://data.eastmoney.com/stockcomment/',
            '券商业绩月报': 'http://data.eastmoney.com/other/qsjy.html',
            '融资融券': ('http://data.eastmoney.com/rzrq/', 1),
            '融资融券账户统计': 'http://data.eastmoney.com/rzrq/zhtjday.html',
            '商誉专题': 'http://data.eastmoney.com/sy/',
            '停复牌信息': ('http://data.eastmoney.com/tfpxx/', 1),
            '委托理财': 'http://data.eastmoney.com/wtlc/',
            '选股器': 'http://data.eastmoney.com/xuangu/',
            '油价': 'http://data.eastmoney.com/cjsj/oil_default.html',
            '战略配售可出借': 'http://data.eastmoney.com/kcb/zlpskcj.html',
            '智能选股V2': 'https://xuangu.eastmoney.com/',
            '重大合同': 'http://data.eastmoney.com/zdht/',
            '重要机构持股': 'http://data.eastmoney.com/gjdcg/',
            '主力数据': 'http://data.eastmoney.com/zlsj/',
            '注册审核': 'http://data.eastmoney.com/xg/zczsh.html',
            '转融通': 'http://data.eastmoney.com/zrt/',
        },
        '新股数据': {
            '新股数据': 'http://data.eastmoney.com/xg/',
            '新股申购': 'http://data.eastmoney.com/xg/xg/default.html',
            'Reits申购': 'https://data.eastmoney.com/reits/',
            '可转债': 'http://data.eastmoney.com/kzz/default.html',
            'IPO审核信息': 'https://data.eastmoney.com/xg/ipo',
            '新股日历': 'http://data.eastmoney.com/xg/xg/calendar.html',
            '新股上会': 'http://data.eastmoney.com/xg/gh/default.html',
            '备案辅导信息': 'https://data.eastmoney.com/xg/ipo/fd.html',
            '新股解析': 'http://data.eastmoney.com/xg/xg/chart/zql.html',
            '增发': 'http://data.eastmoney.com/other/gkzf.html',
            '配股': 'http://data.eastmoney.com/zrz/pg.html',
            '三板达标企业': 'https://data.eastmoney.com/xg/ipo/dbqy.html',
        },
        '沪深港通': {
            '沪深港通': 'http://data.eastmoney.com/hsgt/index.html',
            '沪深港通资金': 'http://data.eastmoney.com/hsgt/index.html',
            '沪深港通成交': 'http://data.eastmoney.com/hsgt/top10.html',
            '沪深港通持股': 'http://data.eastmoney.com/hsgtcg/',
        },
        '公告大全': {
            '公告大全': ('http://data.eastmoney.com/notices/', 1),
            '沪深京A股公告': 'http://data.eastmoney.com/notices/',
            '沪市A股公告': 'http://data.eastmoney.com/notices/sha.html',
            '深市A股公告': 'http://data.eastmoney.com/notices/sza.html',
            '京市A股公告': 'http://data.eastmoney.com/notices/bja.html',
            '创业板公告': 'http://data.eastmoney.com/notices/cyb.html',
            '沪市B股公告': 'http://data.eastmoney.com/notices/shb.html',
            '深市B股公告': 'http://data.eastmoney.com/notices/szb.html',
            '科创板公告': 'http://data.eastmoney.com/notices/kcb.html',
            '待上市A股公告': 'http://data.eastmoney.com/notices/dss.html',
            '三板公告': 'http://xinsanban.eastmoney.com/Article/NoticeList',
            '港股公告': 'http://data.eastmoney.com/notices/gg.html',
            '美股公告': 'http://data.eastmoney.com/notices/mg.html',
            '债券公告': 'http://data.eastmoney.com/notices/zq.html',
        },
        '研究报告': {
            '研究报告': 'http://data.eastmoney.com/report/',
            '研报中心': 'http://data.eastmoney.com/report/',
            '个股研报': 'http://data.eastmoney.com/report/stock.jshtml',
            '盈利预测': 'http://data.eastmoney.com/report/profitforecast.jshtml',
            '行业研报': 'http://data.eastmoney.com/report/industry.jshtml',
            '策略报告': 'http://data.eastmoney.com/report/strategyreport.jshtml',
            '券商晨会': 'http://data.eastmoney.com/report/brokerreport.jshtml',
            '宏观研究': 'http://data.eastmoney.com/report/macresearch.jshtml',
        },
        '年报季报': {
            '年报季报': 'http://data.eastmoney.com/bbsj/',
            '最新业绩报表': ('http://data.eastmoney.com/bbsj/', 1),
            '分红送配': ('http://data.eastmoney.com/yjfp/', 1),
            '2022年年报': 'https://data.eastmoney.com/bbsj/202212.html',
            '2022年业绩快报': 'https://data.eastmoney.com/bbsj/202212/yjkb.html',
            '2023年一季报': 'https://data.eastmoney.com/bbsj/202303.html',
            '2023年一季报预告': 'https://data.eastmoney.com/bbsj/202303/yjyg.html',
            '2021年年报': 'https://data.eastmoney.com/bbsj/202112.html',
            '2020年年报': 'https://data.eastmoney.com/bbsj/202012.html',
            '资产负债表': 'http://data.eastmoney.com/bbsj/zcfz.html',
            '利润表': 'http://data.eastmoney.com/bbsj/lrb.html',
            '现金流量表': 'http://data.eastmoney.com/bbsj/xjll.html',
        },
        '股东股本': {
            '股东股本': 'http://data.eastmoney.com/gdfx/',
            '股东分析': 'http://data.eastmoney.com/gdfx/',
            '股东户数': ('http://data.eastmoney.com/gdhs/', 1),
            '股东增减持': ('http://data.eastmoney.com/executive/gdzjc.html', 1),
            '限售解禁': ('http://data.eastmoney.com/dxf/default.html', 1),
            '一致行动人': 'http://data.eastmoney.com/yzxdr/',
            '高管持股': 'http://data.eastmoney.com/executive/',
        },
        '期货期权': {
            '期货期权': 'http://data.eastmoney.com/futures/sh/data.html',
            '期货龙虎榜': 'http://data.eastmoney.com/futures/sh/data.html',
            '期货库存': 'http://data.eastmoney.com/ifdata/kcsj.html',
            'COMEX库存': 'http://data.eastmoney.com/pmetal/comex/by.html',
            '股指期货持仓': 'http://data.eastmoney.com/IF/Data/Contract.html?va=IF',
            '沪深300': 'http://data.eastmoney.com/IF/Data/Contract.html?va=IF',
            '中证500': 'http://data.eastmoney.com/IF/Data/Contract.html?va=IC',
            '上证50': 'http://data.eastmoney.com/IF/Data/Contract.html?va=IH',
            '中证1000': 'https://data.eastmoney.com/IF/Data/Contract.html?va=IM',
            '国债期货持仓': 'http://data.eastmoney.com/Contract/Data/Contracttf.html?va=T',
            '30年国债': 'https://data.eastmoney.com/Contract/Data/Contracttf.html?va=TL',
            '10年国债': 'http://data.eastmoney.com/Contract/Data/Contracttf.html?va=T',
            '5年国债': 'http://data.eastmoney.com/Contract/Data/Contracttf.html?va=TF',
            '2年国债': 'http://data.eastmoney.com/Contract/Data/Contracttf.html?va=TS',
            'CFTC持仓': 'http://data.eastmoney.com/pmetal/cftc/baiyin.html',
            'ETF持仓': 'http://data.eastmoney.com/pmetal/etf/by.html',
            '现货与股票': 'http://data.eastmoney.com/ifdata/xhgp.html',
            '期货价差矩阵': 'http://data.eastmoney.com/ifdata/jcjz.html',
            '可交割国债': 'http://data.eastmoney.com/tf/tf.html',
            '期权龙虎榜单': 'http://data.eastmoney.com/other/qqlhb.html',
            '期权价值分析': 'http://data.eastmoney.com/other/valueAnal.html',
            '期权风险分析': 'http://data.eastmoney.com/other/riskanal.html',
            '期权折溢价': 'http://data.eastmoney.com/other/premium.html',
        },
        '经济数据': {
            '经济数据': 'http://data.eastmoney.com/cjsj/cpi.html',
            '中国经济数据': 'http://data.eastmoney.com/cjsj/cpi.html',
            '美国经济数据': 'http://data.eastmoney.com/cjsj/foreign_0_0.html',
            '德国经济数据': 'http://data.eastmoney.com/cjsj/foreign_1_0.html',
            '瑞士经济数据': 'http://data.eastmoney.com/cjsj/foreign_2_0.html',
            '日本经济数据': 'http://data.eastmoney.com/cjsj/foreign_3_0.html',
            '英国经济数据': 'http://data.eastmoney.com/cjsj/foreign_4_0.html',
            '澳大利亚数据': 'http://data.eastmoney.com/cjsj/foreign_5_0.html',
            '加拿大经济数据': 'http://data.eastmoney.com/cjsj/foreign_7_0.html',
            '欧元区经济数据': 'http://data.eastmoney.com/cjsj/foreign_6_0.html',
            '香港经济数据': 'http://data.eastmoney.com/cjsj/foreign_8_0.html',
            '行业指数': 'http://data.eastmoney.com/cjsj/hyzs.html',
            '主要国家利率': 'http://data.eastmoney.com/cjsj/globalRate.html',
            '中美国债收益率': 'http://data.eastmoney.com/cjsj/zmgzsyl.html',
            'LPR数据': 'http://data.eastmoney.com/cjsj/globalRateLPR.html',
        },
        '基金数据': {
            '基金数据': 'http://fund.eastmoney.com/data/',
            '基金排名': ('http://fund.eastmoney.com/data/fundranking.html', 1),
            '基金评级': 'http://fund.eastmoney.com/data/fundrating.html',
            '场内基金': ('http://fund.eastmoney.com/cnjy_jzzzl.html', 1),
            '新发基金': 'http://fund.eastmoney.com/data/xinfund.html',
            '基金定投': 'http://fund.eastmoney.com/dingtou/syph_yndt.html',
            '基金导购': 'http://fund.eastmoney.com/daogou/',
            '基金分红': 'http://fund.eastmoney.com/data/fundfenhong.html#DJR,desc,1,,,',
            '基金公司': 'http://fund.eastmoney.com/company/default.html',
            '私募基金': 'http://simu.eastmoney.com/data/smranklist.aspx',
        },
    },
}


def get_item_opt(item, index):
    item = item if isinstance(item, tuple) else (item,)
    if len(item) > index:
        return item[index]


def help(items, prefixes=[], keep=False, index=0):
    count = 0
    for k, v in items.items():
        if isinstance(v, (str, tuple)):
            index += 1
            print(f'\x1b[2m{index}.\x1b[0m\x1b[{"31" if get_item_opt(v, 1) else "37"}m{k}\x1b[0m', end='  ')
            count += 1
            if count > 8:
                count = 0
                print()
        else:
            print(f'\n\x1b[32;2m{"-".join(prefixes + [k])}\x1b[0m')
            index = help(v, prefixes + [k], keep=True, index=index)

    if not keep:
        print()
    return index


def find(items, s: str, index=0):
    indexed = False
    if s.isdecimal():
        indexed = True
    for k, v in items.items():
        if isinstance(v, (str, tuple)):
            index += 1
            if indexed and s == f'{index}' or s == k:
                return (get_item_opt(v, 0), k, index)
        else:
            (r, k2, index) = find(v, s, index)
            if r:
                return (r, k2, index)
    return (None, None, index)


if __name__ == '__main__':
    from sys import argv

    if len(argv) > 1:
        help(SINGLE_LINKS)
        s = input('请输入:')
        (url, key, _) = find(SINGLE_LINKS, s)
        (symbol, name) = search(argv[1])
        print(key, url, symbol, name)
        browse(generate_url(url, symbol, name))
    else:
        help(DATA_LINKS)
        s = input('请输入:')
        (url, key, _) = find(DATA_LINKS, s)
        browse(url)
