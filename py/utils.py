
from wcwidth import wcswidth
from os import environ
import re

browserCmd = environ.get('BROWSER', 'open')


def silence(fn, default):
    try:
        return fn()
    except:
        return default


def colorful(s, color='red'):
    s = str(s)
    colors = ['red', 'green', 'yellow', 'purple',
              'magenta', 'cyan', 'gray', 'black']
    return f'\033[3{str(colors.index(color) + 1)}m{s}\033[0m'


def print_list(rows, cols, titleIndex=0):
    maxWidth = max([wcswidth(col) for col in cols])
    for row in rows:
        for i, col in enumerate(cols):
            if len(row) > i:
                l = maxWidth - wcswidth(col) + len(col)
                l = colorful(col.ljust(l), 'magenta')
                r = colorful(row[i]) if i == titleIndex else colorful(
                    row[i], 'green')
                print(f'{l}: {r}')
        print()


def fuzzyMatch(s: str, patternStr: str) -> bool:

    rs = fuzzyMatch.cache[s] if s in fuzzyMatch.cache else re.sub(pattern=r'(^|.)', repl=r'\1.*', string=s,
                                                                  count=0, flags=re.IGNORECASE | re.DOTALL)

    fuzzyMatch.cache[s] = rs

    return not not re.search(pattern=rf'{rs}', string=patternStr, flags=re.DOTALL | re.IGNORECASE)


fuzzyMatch.cache = {}
