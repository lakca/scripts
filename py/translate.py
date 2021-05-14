from sys import argv

if len(argv) < 2:
    exit()

from wcwidth import wcswidth
from translators import baidu, google, youdao, deepl
from utils import print_list, silence


def to_language(text):
    '''翻译的目标语言'''
    for char in text:
        if 19968 <= ord(char) <= 40869:
            return 'en'
    return 'zh'


words = []
headers = {
    'text': '源文本',
    'google': '谷歌',
    'youdao': '有道',
    'baidu': '百度',
    # 'deepl': 'deepl',
}
max = 0

for word in argv[1:]:
    max = len(word)
    lang = to_language(word)
    text = [word]
    words.append(text)
    if 'google' in headers:
        text.append(silence(lambda: google(word, to_language=lang), ''))
    if 'youdao' in headers:
        text.append(silence(lambda: youdao(word, to_language=lang), ''))
    if 'baidu' in headers:
        text.append(silence(lambda: baidu(word, to_language=lang), ''))
    if 'deepl' in headers:
        text.append(silence(lambda: deepl(word, to_language=lang), ''))

print_list(words, headers.values())
