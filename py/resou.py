from urllib.parse import urljoin
import requests
from bs4 import BeautifulSoup
from re import search as reSearch
from inspect import getmembers, isfunction
from urllib.parse import urljoin
from json import loads as jsonloads
from utils import print_list

WEIBO_HOT_URL = 'https://s.weibo.com/top/summary?Refer=top_hot&topnav=1&wvr=6'
BAIDU_HOT_URL = 'https://top.baidu.com/buzz?b=1&fr=topindex'
ZHIHU_HOT_URL = 'https://www.zhihu.com/billboard'
ZHIHU_HOT_SEARCH_URL = 'https://www.zhihu.com/api/v4/topics/19964449/feeds/top_activity?limit=10'

HEADERS = {
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36'
}


def setValue(ls, index, value):
    if isinstance(ls, list):
        if len(ls) > index:
            ls[index] = value
        else:
            index -= 1
            while index > len(ls):
                ls.append(None)
            ls.append(value)


def getdeep(m, *keys):
    r = m
    for k in keys:
        if k in r:
            r = r[k]
        else:
            return None
    return r


def tryNumber(s: str):
    if s == '' or s == '.':
        return s
    r = reSearch(r'^\d*(\.?)\d*$', s)
    return s if not r else float(s) if r.group(1) else int(s)


def strip(s):
    return str(s).strip() if not s is None else None


class hot_list:

    @ classmethod
    def describe(cls):
        return [f'{e[0]}: {e[1].__doc__}' for e in getmembers(cls, predicate=isfunction)]

    @ staticmethod
    def weibo():
        '''微博热搜'''
        rows = []
        headers = {}
        headers.update(HEADERS)
        cookies = 'tid=rOZvrfn1Nsoc/GA35Nai17PcrJ9WssHqfxYLRDLwdeU=__095; SRT=D.QqHBTrsP4qRuV-RtOeYoWr9NUdRrSGYQUcb8dQAo5eV3MdbbN-bFJORqNbHi5mYNUCsuTZbgVdsBTeMNAZSAKGPCSqH-T-khA4yqidi-OqbsSrWPUQYHIQE9KDWGSX77*B.vAflW-P9Rc0lR-ykKDvnJqiQVbiRVPBtS!r3J8sQVqbgVdWiMZ4siOzu4DbmKPWFiESPOPWpi-i3TPYkNmo4OcV-VZEa; SRF=1662459995'
        response = requests.get(WEIBO_HOT_URL, headers=headers, cookies=cookies)
        print(response.text, response.headers, response.request.headers)
        soup = BeautifulSoup(response.content, 'lxml')
        trs = soup.find(id='pl_top_realtimehot').find('tbody').find_all('tr')
        cols = list(map(lambda col: strip(col.text), soup.find(
            id='pl_top_realtimehot').find('thead').find_all('th')))
        cols.append('趋势')
        cols.append('链接')
        setValue(cols, 2, '热度')
        setValue(cols, 3, '标签')

        for tr in trs:
            row = []
            rows.append(row)
            tds = tr.find_all('td')
            row.append(tds[0].text)
            link = tds[1].find('a')
            row.append(strip(getattr(link, 'text', '')))
            row.append(strip(getattr(tds[1].find('span'), 'text', '')))
            row.append(strip(getattr(tds[2].find('i'), 'text', '')))
            row.append(urljoin(response.url, strip(link.attrs.get('href'))))
        return (rows, cols, 1)

    @ staticmethod
    def zhihuresou(count=10):
        '''[count=10] 知乎热搜'''
        url = ZHIHU_HOT_SEARCH_URL
        rows = []
        cols = ('标题', '描述', '地址')
        while url and len(rows) < count:
            response = requests.get(url, headers=HEADERS)
            content = response.json()
            rows += content['data']
            url = content['paging']['next']
            if content['paging']['is_end']:
                break
        rows = list(map(lambda item: [
            getdeep(item, *('target', 'title')
                    ) or getdeep(item, *('target', 'question', 'title')),
            getdeep(item, *('target', 'excerpt')),
            getdeep(item, *('target', 'url')),
        ], rows))
        return (rows, cols)

    @ staticmethod
    def zhihu():
        '''知乎热榜（客户端热榜）'''
        text = requests.get(ZHIHU_HOT_URL, headers=HEADERS).text
        cols = ['索引', '标题', '描述', '回答数', '热度', '链接']
        rows = []

        text = reSearch(
            r'<script id="js-initialData" type="text/json">(?P<jsonstr>[\s\S]+?)</script>', text)

        if text:
            jsonstr = strip(text.group('jsonstr'))
            obj = jsonloads(jsonstr)
            for i, item in enumerate(getdeep(obj, 'initialState', 'topstory', 'hotList') or []):
                rows.append([
                    i + 1,
                    getdeep(item, 'target', 'titleArea', 'text'),
                    getdeep(item, 'target', 'excerptArea', 'text'),
                    getdeep(item, 'target', 'metricsArea', 'text'),
                    getdeep(item, 'feedSpecific', 'answerCount'),
                    # getdeep(item, 'target', 'imageArea', 'url'),
                    getdeep(item, 'target', 'link', 'url'),
                ])
        return (rows, cols, 1)

    @ staticmethod
    def baidu():
        '''百度热搜'''
        response = requests.get(BAIDU_HOT_URL, headers=HEADERS)
        soup = BeautifulSoup(response.content, 'lxml')
        rows = []
        cols = list(map(lambda col: strip(col.text), soup.find(
            'table', class_='list-table').find_all('th')))
        cols.append('趋势')
        rank_tds = soup.find(
            'table', class_='list-table').find_all('td', class_='first')
        for td in rank_tds:
            row = []
            cursor = td
            rows.append(row)
            row.append(strip(cursor.text))

            cursor = cursor.find_next_sibling('td', class_='keyword')
            link = cursor.find('a', class_='list-title')
            row.append(strip(link.text))
            row.append(strip(link.attrs.get('href')))

            cursor = cursor.find_next_sibling('td', class_='last')
            row.append(strip(cursor.text))

            row.append(1 if cursor.find(
                class_='icon-rise') else -1 if cursor.find(class_='icon-fall') else 0)
        return (rows, cols, 1)

    @ staticmethod
    def east(code):
        '''[code] 个股公告'''
        response = requests.get(
            'http://quote.eastmoney.com/' + code.lower() + '.html', headers=HEADERS)
        soup = BeautifulSoup(response.content, 'lxml')
        canlander = list(map(lambda e: [
            e.text,
            e.attrs['href'],
            reSearch(r'\d+年\d+月\d+日', e.text)[0],
        ], soup.find(id='stockcanlendar').find_all('a')))
        return (canlander, ('标题', '链接', '日期'))

    @ staticmethod
    def code(text):
        '''[text] 代码搜索'''
        res = requests.get(
            "https://suggest3.sinajs.cn/suggest/type=&key=" + text + "&name=suggestdata")
        rows = []
        cols = ('编号', '代码', '名称')
        for e in res.text.split('"')[1].split(";"):
            if not e.strip():
                continue
            f = e.split(',')
            rows.append([
                f[2],
                f[3],
                f[4],
            ])
        return (rows, cols)

    @ staticmethod
    def quote(*code):
        '''[code] 行情'''
        def parse(text):
            rows = []
            for e in text.split(';'):
                if not e.strip():
                    continue
                t = e.split('"')[1].split(',')
                name = t[0]
                code = reSearch(r'[^_]+(?==)', e)[0]
                price = float(t[3])
                close = float(t[2])
                percent = str(round(100 * (price - close) / close, 2)) + '%'
                percent = percent if price < close else '+' + percent
                date = t[30]
                time = t[31]
                print(time)
                rows.append([code, name, price, percent, time])
            cols = ('代码', '名称', '价格', '涨跌幅', '时间')
            return (rows, cols)
        res = requests.get('https://hq.sinajs.cn/list=' + ','.join(code))
        return parse(res.text)


if __name__ == '__main__':
    from sys import argv
    if '-h' in argv:
        print('热搜：... [command] [...arguments]')
        print('  '+'\n  '.join(hot_list.describe()))

    hot = hot_list()
    if len(argv) > 1:
        args = []
        for arg in argv[1:]:
            if hasattr(hot, arg):
                # 执行掉前一个指令
                if len(args):
                    print(args[0])
                    print_list(*getattr(hot, args[0])(*args[1:]))
                    args.clear()
                # 暂存指令，可能会有参数
                args.append(arg)
            else:
                # 指令参数
                if len(args):
                    args.append(arg)
        if len(args):
            print(args[0])
            print_list(*getattr(hot, args[0])(*args[1:]))
