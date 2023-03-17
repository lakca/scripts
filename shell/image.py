#! /usr/bin/env python3

from sys import argv
from PIL import Image, ImageGrab
from os import path
from base64 import b64encode, b64decode
import subprocess
import io

op = argv[1]
args = argv[2:]

if '-h' in argv:
    print("""
    image.py

        \033[2m# 截屏并保存到文件\033[0m
        shot <file> [left top width height]

        \033[2m# 保存剪切板中的图片\033[0m
        paste <file>

        \033[2m# 转换图片格式\033[0m
        to <ext> [at <destination>] <...image files>

        \033[2m# （从剪切板或文件）获取图片base64\033[0m
        base64 [file]
    """)
    exit(0)

if op == 'paste':
    file = path.abspath(args.pop(0))
    img = ImageGrab.grabclipboard()
    img.save(file)
    print('保存', file)

elif op == 'shot':
    file = path.abspath(args.pop(0))
    bbox = [int(e) for e in args.pop(0).split(' ')] if args else ()
    if bbox:
        bbox[2] = bbox[0] + bbox[2]
        bbox[3] = bbox[1] + bbox[3]
    img = ImageGrab.grab(bbox)
    img.save(file)
    print('保存', file)

elif op == 'to':
    files = []
    ext = args.pop(0)
    ext = '.' + ext if not ext.startswith('.') else ext
    dest = ''
    while args:
        arg = args.pop(0)
        if arg == 'at':
            dest = path.realpath(args.pop(0))
        else:
            files.append(path.abspath(arg))
    for file in files:
        folder = dest or path.dirname(file)
        filename = path.basename(file).rpartition('.')[0]
        img = Image.open(file)  # 创建图像实例
        dest = path.join(folder, filename + ext)
        img.save(dest)
        print('保存', dest)

elif op == 'base64':
    file = args.pop(0) if args else None
    text = 'data:image/png;base64,'
    img = Image.open(file) if file else ImageGrab.grabclipboard()
    if img:
        buffered = io.BytesIO()
        img.save(buffered, format=img.format)
        text = f"data:image/{img.format.lower()};base64," + str(b64encode(buffered.getvalue()), 'utf8')
        subprocess.Popen('pbcopy', stdin=subprocess.PIPE).communicate(input=text.encode())

