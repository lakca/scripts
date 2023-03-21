#! /usr/bin/env python3

from sys import argv
import time
from PIL import Image, ImageGrab, ImageEnhance
from os import path, getcwd
from base64 import b64encode, b64decode
import subprocess
import io

op = argv[1]
args = argv[2:]

def check_filename(filename):
    if path.isfile(filename):
        name, ext = path.splitext(filename)
        return name + '.' + str(int(time.time())) + ext
    return filename

if '-h' in argv:
    print("""
    image.py

        \033[2m# 截屏并保存到文件\033[0m
        shot <file> [left top width height]

        \033[2m# 保存剪切板中的图片\033[0m
        paste <file>

        \033[2m# 转换图片格式\033[0m
        \033[2m# mode: enhance soften brighten darken sharpen blur\033[0m
        to <[ext|mode...]> [at <destination>] <...image files>

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
    modes = ['']
    ext = ''
    dest = getcwd()
    force = False
    for handle in args.pop(0).split(','):
        if handle.startswith('.'):
            ext = handle
        else:
            modes.append(handle)
    while args:
        arg = args.pop(0)
        if arg == 'at':
            dest = path.realpath(args.pop(0))
        if arg == '!':
            force = True
        elif arg == '--':
            while args:
                files.append(path.abspath(args.pop(0)))
        else:
            files.append(path.abspath(arg))

    filename = ''
    if path.isfile(dest) or not path.isdir(dest):
        filename = dest
        if ext and filename.endswith(ext):
            filename = filename.removesuffix(ext)

    for i, file in enumerate(files):
        to = filename + (f'-{i}' if i > 0 else '') + ext if filename else path.join(dest, path.splitext(path.basename(file))[0] + ext if ext else path.basename(file))

        if not force:
            to = check_filename(to)

        img = Image.open(file)
        if modes:
            for mode in modes:
                params = mode.split(',')
                mode = params.pop(0)
                if mode == 'gray':
                    img = img.convert(mode='L')
                elif mode == 'enhance':
                    img = ImageEnhance.Contrast(img).enhance(float(params[0]) if params else 1.3)
                elif mode == 'soften':
                    img = ImageEnhance.Contrast(img).enhance(float(params[0]) if params else 0.7)
                elif mode == 'brighten':
                    img = ImageEnhance.Brightness(img).enhance(float(params[0]) if params else 1.3)
                elif mode == 'darken':
                    img = ImageEnhance.Brightness(img).enhance(float(params[0]) if params else 0.7)
                elif mode == 'sharpen':
                    img = ImageEnhance.Sharpness(img).enhance(float(params[0]) if params else 1.3)
                elif mode == 'blur':
                    img = ImageEnhance.Sharpness(img).enhance(float(params[0]) if params else 0.7)
                else:
                    print(f'未知模式: {mode}')
        img.save(to)
        print('保存', f'\033[31m{to}\033[0m')

elif op == 'base64':
    file = args.pop(0) if args else None
    text = 'data:image/png;base64,'
    img = Image.open(file) if file else ImageGrab.grabclipboard()
    if img:
        buffered = io.BytesIO()
        img.save(buffered, format=img.format)
        text = f"data:image/{img.format.lower()};base64," + str(b64encode(buffered.getvalue()), 'utf8')
        subprocess.Popen('pbcopy', stdin=subprocess.PIPE).communicate(input=text.encode())
