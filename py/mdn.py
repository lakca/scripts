from tabulate import tabulate
from requests import get
from urllib.parse import urljoin
from utils import colorful, browserCmd


def truncate(s):
    i = s.find('。')
    if not i:
        i = s.find('.')
    return s[0:i+1] if i > -1 else s


if __name__ == '__main__':
    from sys import argv
    if '-h' in argv:
        print(
            f'\n{colorful("搜索MDN文档", "red")}：... {colorful("text", "green")} {colorful("[:filter ...]", "green")} {colorful("[:en]", "green")}')
        print('- 如果只有一个结果，会直接打开链接。')
        print('- 默认搜索中文，要搜索英文文档需要加参数 :en ')
        print('\n  例如: ... path :svg :ele')
        print('''  结果：
        Title  : path
        ...

        Title  : clipPath
        ...

        Title  : textPath
        ...''')
        exit(0)
    filters = []
    kwd = None
    singleton = None
    locale = 'zh-CN'
    for arg in argv[1:]:
        if arg == ':en':
            locale = 'en-US'
        elif arg.startswith(':'):
            filters.append(arg[1:].lower())
        else:
            kwd = arg
    if kwd:
        url = 'https://developer.mozilla.org/api/v1/search'
        json = get(
            f'{url}?q={kwd}&locale={locale}').json()
        count = 0
        for e in json.get('documents', []):
            mdn_url = e.get('mdn_url', '').lower()
            for f in filters:
                if f not in mdn_url:
                    break
            else:
                singleton = urljoin(url, e.get('mdn_url', ''))
                count += 1
                print(f'''
Title  : {colorful(e.get('title', ''), 'red')}
Url    : {colorful(singleton, 'gray')}
Summary: {colorful(truncate(e.get('summary', '')), 'green')}''')
        if count < 2 and singleton:
            from os import system
            system(f'{browserCmd} {singleton}')
