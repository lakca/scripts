from sys import argv

if len(argv) < 2:
    exit()

from wcwidth import wcswidth
from utils import colorful, silence
import translators
from threading import Thread


def to_language(text):
    '''翻译的目标语言'''
    for char in text:
        if 19968 <= ord(char) <= 40869:
            return 'en'
    return 'zh'


headers = [
    ['google', '谷歌'],
    ['youdao', '有道'],
    ['baidu', '百度'],
    ['deepl', 'deepl'],
    ['tencent', '腾讯'],
    ['alibaba', '阿里巴巴'],
    ['sogou', '搜狗'],
]


word = ' '.join(argv[1:]).strip()
lang = to_language(word)
width = max([wcswidth(e[1]) for e in headers])

print()
print(colorful(word, 'magenta'))
print()

for [k, col] in headers:
    Thread(target=lambda col: print(colorful(col.ljust(width - wcswidth(col) + len(col)), 'green') + ': ' + colorful(silence(lambda: getattr(translators, k)
           (word, to_language=lang), ''), 'red')), args=(col,)).start()
