
from wcwidth import wcswidth


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
    maxWidth = max(*[wcswidth(col) for col in cols])
    for row in rows:
        print()
        for i, col in enumerate(cols):
            l = maxWidth - wcswidth(col) + len(col)
            l = colorful(col.ljust(l), 'magenta')
            r = colorful(row[i]) if i == titleIndex else colorful(
                row[i], 'green')
            print(f'{l}: {r}')
