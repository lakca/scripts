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
EXTENSIONS = list(Image.registered_extensions().keys())

def check_filename(filename):
    if path.isfile(filename):
        name, ext = path.splitext(filename)
        return name + '.' + str(int(time.time())) + ext
    return filename

def soft_get_filename(dest, file, index, ext, extensions, force):
    if path.isdir(dest):
        _name, _ext = path.splitext(path.basename(file))
        ext = (_ext or ext) if not extensions or (_ext in extensions) else ext
        filename = path.join(dest, _name + ext)
        if path.exists(filename):
            if index is not None: _name = _name + f'-{index}'
            filename = path.join(dest, _name + ext)
            while not force and path.exists(filename):
                filename = path.join(dest, _name + f'.{str(int(time.time()))}' + ext)
                time.sleep(1)
        return filename
    else:
        _name, _ext = path.splitext(dest)
        if _ext and ((not extensions) or (_ext in extensions)):
            ext = _ext
        else:
            _name = dest
        filename = _name + ext
        if path.exists(filename):
            if index is not None: _name = _name + f'-{index}'
            while not force and path.exists(filename):
                filename = _name + f'.{str(int(time.time()))}' + ext
                time.sleep(1)
        return filename

def resolveIOArgs(args):
    dest = ''
    force = False
    files = []
    while args:
        arg = args.pop(0)
        if arg == 'at':
            dest = args.pop(0)
            if dest not in ['io', 'pb']:
                dest = path.realpath(dest)
        if arg == '!':
            force = True
        elif arg == '--':
            while args:
                files.append(path.abspath(args.pop(0)))
        else:
            files.append(path.abspath(arg))
    ext = path.splitext(dest)[1].lower()
    return dest, force, files, ext

if '-h' in argv:
    print("""
    image.py

        \033[2m# 截屏并保存到文件\033[0m
        shot <file> [left top width height]

        \033[2m# 保存剪切板中的图片\033[0m
        paste <file> [open]

        \033[2m# 转换图片格式\033[0m
        \033[2m# mode: enhance soften brighten darken sharpen blur\033[0m
        to <[ext|mode...]> [at <destination>] <image_files...>

        \033[2m# （从剪切板或文件）编码图片base64\033[0m
        64 [at <destination>] <files...>

        \033[2m# （从剪切板或文件）解码图片base64\033[0m
        d64 [at <destination>] <files...>
    """)
    exit(0)

if op == 'paste':
    file = path.abspath(args.pop(0))
    img = ImageGrab.grabclipboard()
    img.save(file)
    if args and 'open' in args:
        f"open {file}"
    print('保存', file)

elif op == 'shot':
    file = path.abspath(args.pop(0))
    bbox = []
    if args:
        bbox = [int(e) for e in args[0:4]]
        bbox[2] = bbox[0] + bbox[2]
        bbox[3] = bbox[1] + bbox[3]
    img = ImageGrab.grab(bbox)
    img.save(file)
    print('保存', file)

elif op == 'to':
    modes = ['']
    ext = ''
    for handle in args.pop(0).split(','):
        if handle.startswith('.'):
            ext = handle
        else:
            modes.append(handle)
    dest, force, files, *_ = resolveIOArgs(args)
    dest = dest or getcwd()

    # filename = ''
    # if path.isfile(dest) or not path.isdir(dest):
    #     filename = dest
    #     if ext and filename.endswith(ext):
    #         filename = filename.removesuffix(ext)

    for i, file in enumerate(files):
        # to = filename + (f'-{i}' if i > 0 else '') + ext if filename else path.join(dest, path.splitext(path.basename(file))[0] + ext if ext else path.basename(file))

        # if not force:
        #     to = check_filename(to)

        to = soft_get_filename(dest=dest, file=file, index=i, ext=ext, extensions=EXTENSIONS, force=force)
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

elif op == '64':
    dest, force, files, ext = resolveIOArgs(args)
    dest = dest or getcwd()
    def encodeBase64(img):
        text = 'data:image/png;base64,'
        buffered = io.BytesIO()
        img.save(buffered, format=img.format)
        text = f"data:image/{img.format.lower()};base64," + str(b64encode(buffered.getvalue()), 'utf8')
        return text
    texts = [encodeBase64(Image.open(file)) for file in files] if files else [encodeBase64(ImageGrab.grabclipboard())]
    if dest == 'pb':
        subprocess.Popen('pbcopy', stdin=subprocess.PIPE).communicate(input='\n'.join(texts).encode())
    print('\n'.join(texts))

elif op == 'd64':
    dest, force, files, ext = resolveIOArgs(args)
    dest = dest or getcwd()
    def decodeBase64(text):
        if isinstance(text, io.IO):
            with text as f: text = str(f.read(), 'utf8')
        text = text.partition(',')[0]
        return Image.open(b64decode(text))

    if files:
        for i, file in enumerate(files):
            img = decodeBase64(open(file))
            filename = soft_get_filename(dest=dest, original=file, index=i, ext='.png', extensions=EXTENSIONS)
            img.save(filename)
    else:
        img = decodeBase64(subprocess.Popen('pbpaste', stdout=subprocess.PIPE).stdout)
        img.save(dest if ext in EXTENSIONS else dest + '.png')
