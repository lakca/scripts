#!/usr/bin/env python3
from sys import argv
import re

reg = r'([^:]):([^:])'
prefix = 'twx-'

while len(argv) > 0:
    arg = argv.pop(0)
    if (arg == '-h'):
        print(
            f"""
            tailwind添加类名前缀

            \x1b[2m用法：\x1b[0m
            pbpaste | \x1b[31mtw-prefix.py [-p <prefix={prefix}>]\x1b[0m | pbcopy
            """)
        exit()
    if (arg == '-p'):
        prefix = argv.pop(0)


def mapping(item):
    found = re.search(reg, item)
    if found:
        return re.sub(reg, rf'\1:{prefix}\2', item)
    else:
        return prefix + item


print(' '.join(map(mapping, re.split(r'\s+', input()))))
