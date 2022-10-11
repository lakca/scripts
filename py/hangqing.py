#! /usr/bin/env python3

import requests
import time
import re
import sys
import pinyin
import asyncio
import datetime

headers = {
    'Referer': 'http://finance.sina.com.cn/',
}

def search(name):
    res = requests.get(
        "https://suggest3.sinajs.cn/suggest/type=&key=" + name + "&name=suggestdata", headers=headers)
    rs = []
    for e in res.text.split('"')[1].split(";"):
        if not e.strip():
            continue
        f = e.split(',')
        rs.append({
            'symbol': f[2],
            'code': f[3],
            'name': f[4],
        })
    return rs


def getStrAllAlpha(str):
    return pinyin.get_initial(str, delimiter="").upper()


def getStrFirstAlpha(str):
    str = getStrAllAlpha(str)
    str = str[0:1]
    return str.upper()


def prop(a_dict, attr, default=None):
    return a_dict[attr] if a_dict and attr in a_dict else default


def red(text):
    return '\033[31m' + text + '\033[0m'


def green(text):
    return '\033[32m' + text + '\033[0m'


def getColor(val, old_val):
    return red if float(val) > float(old_val) else green


def parse(text):
    r = {}
    for e in text.split(';'):
        if not e.strip():
            continue
        t = e.split('"')[1].split(',')
        code = re.search(r'[^_]+(?==)', e)[0]
        price = float(t[3])
        close = float(t[2])
        percent = str(round(100 * (price - close) / close, 2)) + '%'
        percent = percent if price < close else '+' + percent
        r[code] = {
            'alpha': getStrAllAlpha(t[0]),
            'code': code,
            'name': t[0],
            'price': t[3],
            'percent': percent,
            'time': t[len(t) - 1],
            's1': t[20],
        }
    return r


def pad(s, l):
    while len(s) < l:
        s += ' '
    return s

global LINES
LINES = 0

def clear(line=0):
    sys.stdout.write('\033[2K')
    sys.stdout.write('\033[1A\033[2K'*line)

def print_result(list_map, old_list_map):
    global LINES
    gaps = {
        'alpha': 0,
        'price': 0,
        'percent': 0,
        's1': 0,
        'name': 0,
    }
    for key in list_map.keys():
        gaps['name'] = max(gaps['name'], len(prop(list_map[key], 'name')))
        gaps['alpha'] = max(gaps['alpha'], len(prop(list_map[key], 'alpha')))
        gaps['price'] = max(gaps['price'], len(prop(list_map[key], 'price')))
        gaps['percent'] = max(gaps['percent'], len(
            prop(list_map[key], 'percent')))
        gaps['s1'] = max(gaps['s1'], len(prop(list_map[key], 's1')))
    clear(LINES)
    LINES = len(list_map.keys())
    for key in list_map.keys():
        cur = list_map[key]
        prev = prop(old_list_map, key, {})
        color = getColor(prop(cur, 'price', 0), prop(prev, 'price', 0))
        percent = prop(cur, 'percent')
        sys.stdout.write(''.join([
            red(pad(prop(cur, 'name'), 1 + gaps['name'])),
            # red(pad(prop(cur, 'alpha'), 1 + gaps['alpha'])),
            green(pad(percent, 1 + gaps['percent'])) if percent[0] == '-' else red(pad(percent, 1 + gaps['percent'])),
            color(pad(prop(cur, 'price', 0), 1 + gaps['price'])),
            red(pad(prop(cur, 's1'), 1 + gaps['s1'])),
        ]) + "\n")


def getHQ(code):
    res = requests.get('https://hq.sinajs.cn/list=' + code, headers=headers)
    cur = parse(res.text)
    return cur


def loopHQ(symbol, once=False):
    cur = None
    prev = cur
    while True:
        try:
            prev, cur = cur, getHQ(symbol)
        except BaseException as err:
            print(time.strftime('%Y-%m-%d %H:%M:%S'))
        finally:
            time.sleep(1)
            yield (cur, prev)
        if once:
           return


if __name__ == '__main__':
    import sys
    once = 'o' in sys.argv
    if sys.argv[1] == 's':
        print(search(sys.argv[2]))
    else:
        for (cur, prev) in loopHQ(sys.argv[1], once=once):
            print_result(cur, prev)


# sh000001,sz399006,sh601233,sz300059,sh603786,sz300675
