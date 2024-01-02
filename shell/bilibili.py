#! /usr/bin/env python3

from enum import Enum, auto
import random
from sys import argv
from time import sleep
import requests
import re
import json
import os
from datetime import datetime
from tabulate import tabulate

DEBUG = 'DEBUG' in list(os.environ.keys())


class Title:
    msg = []

    @classmethod
    def _show(cls):
        if len(cls.msg):
            print(f'\033];{cls.msg[-1]}\007', end='')

    @classmethod
    def set(cls, msg):
        msg = str(msg)
        cls.msg.append(msg)
        cls._show()

    @classmethod
    def unset(cls):
        if len(cls.msg):
            cls.msg.pop()
        cls._show()

    @classmethod
    def add(cls, msg):
        msg = str(msg)
        if len(cls.msg):
            cls.msg.append(cls.msg[-1] + msg)
        cls._show()


def print_list(arr):
    debug('formats', '\x1b[2m' + tabulate(arr) + '\x1b[0m')


def debug(tag, *msg):
    print(f'\x1b[31;2m[{str(tag).upper()}]\x1b[0m', *msg)


class Kind(Enum):
    VIDEO = auto()
    VIDEO_HIGH = auto()
    VIDEO_LOW = auto()
    AUDIO_VIDEO = auto()
    AUDIO_ONLY = auto()
    MUSIC_VIDEO = auto()
    MUSIC_ONLY = auto()


def search(reg, text, index=0):
    matched = re.search(reg, text)
    return matched and matched.group(index)


def deep_attr(m, key):
    for k in key.split('.'):
        m = m.get(k, None)
        if m is None:
            break
    return m


def get_bool_answer(msg):
    msg += '(Yy|Nn):'
    while True:
        Title.set(f'waiting... {msg}')
        answer = input(f'\x1b[32m{msg}\x1b[0m')
        Title.unset()
        if answer.lower() == 'y':
            return True
        elif answer.lower() == 'n':
            return False


class Bilibili:
    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'

    @classmethod
    def get_cookie(cls, cookie):
        if cookie:
            if os.access(cookie, os.F_OK):
                with open(cookie) as f:
                    cookie = f.read().strip()
            return { item.split("=")[0]: item.split("=")[1] for item in cookie.split("; ") }
        return {}

    @classmethod
    def get_existed_file(cls, folder, bvid):
        for file in os.scandir(folder):
            if file.is_file() and f'-{bvid}-' in file.name:
                return file.name
        return None

    @classmethod
    def pick_av(cls, videos, audios, kind: Kind = None):
        videos.sort(key=lambda e: deep_attr(e, 'bandwidth'))
        audios.sort(key=lambda e: deep_attr(e, 'bandwidth'))

        print_list(list(map(lambda v: [v['id'], v['height'], v['bandwidth'], v['codecs']], audios)))
        print_list(list(map(lambda v: [v['id'], v['height'], v['bandwidth'], v['codecs']], videos)))

        if kind == Kind.MUSIC_VIDEO or kind == Kind.MUSIC_ONLY:
            audio = audios[-1]
        elif kind == Kind.AUDIO_VIDEO or kind == Kind.AUDIO_ONLY:
            audio = audios[int(len(audios) / 2)]
        elif kind == Kind.VIDEO or kind == Kind.VIDEO_HIGH or kind == Kind.VIDEO_LOW:
            audio = audios[1] if len(audios) > 1 else audios[0]
        else:
            audio = audios[0]

        if kind == Kind.VIDEO_HIGH:
            video = videos[-1]
        elif kind == Kind.VIDEO_LOW:
            video = videos[0]
        elif kind == Kind.MUSIC_VIDEO or kind == Kind.AUDIO_VIDEO:
            for v in videos:
                video = v
                if v['height'] >= 720:
                    break
        else:
            for v in videos:
                video = v
                if v['height'] >= 720:
                    break
        return [video, audio]

    @classmethod
    def download(cls, url: str, kind: Kind = Kind.VIDEO, crf: int = 28, prune: bool = False, cookie: str = None):
        if not url.startswith('https:'):
            url = f'https://www.bilibili.com/video/{url}'
        with requests.Session() as session:
            session.cookies.update(cls.get_cookie(cookie))
            try:
                if DEBUG:
                    with open(f'bilibili.debug.json', mode='r') as f:
                        data = json.load(f)
                    play_info = data.get('__playinfo__')
                    initial_state = data.get('__INITIAL_STATE__')
                else:
                    session.headers.update({'user-agent': cls.user_agent})
                    url = search(r'http\S+', url)
                    res = session.get(url)
                    play_info = json.loads(search(r'<script>window.__playinfo__=([\s\S]+?)</script>', res.text, 1).strip())
                    initial_state = json.loads(
                        search(r'<script>window.__INITIAL_STATE__=([\s\S]+?)(;\(function\(\).*)?</script>', res.text, 1).strip()
                    )
                    if not DEBUG:
                        with open('bilibili.debug.html', mode='w') as f:
                            f.write(res.text)
                aid = deep_attr(initial_state, 'aid')
                bvid = deep_attr(initial_state, 'bvid')
                ctime = deep_attr(initial_state, 'videoData.ctime')
                title = deep_attr(initial_state, 'videoData.title')
                author = deep_attr(initial_state, 'videoData.owner.name')
                authormid = deep_attr(initial_state, 'videoData.owner.mid')
                audio = deep_attr(play_info, 'data.dash.audio')
                video = deep_attr(play_info, 'data.dash.video')
                audio.sort(key=lambda e: deep_attr(e, 'bandwidth'))
                video.sort(key=lambda e: deep_attr(e, 'bandwidth'))
                if not DEBUG:
                    with open(f'bilibili.debug.json', mode='w') as f:
                        f.write(json.dumps({'__playinfo__': play_info, '__INITIAL_STATE__': initial_state}))
            except Exception as err:
                debug(err)
            else:
                Title.add(bvid)
                existed = cls.get_existed_file(os.getcwd(), bvid)
                if existed and not get_bool_answer(f'文件已存在 {existed}，是否覆盖？'):
                    return
                filename = '-'.join([datetime.fromtimestamp(ctime).strftime("%Y%m%d%H%M"), bvid, title]) + '.mp4'
                av = cls.pick_av(video, audio, kind=kind)
                middle_files = []
                cmd_opts = ''
                for i, item in enumerate(av):
                    url_download = deep_attr(item, 'baseUrl')

                    codec = deep_attr(item, 'codecs')
                    if codec:
                        if codec.startswith('avc1'):  # mp4 无需转换
                            cmd_opts += '-vcodec copy '
                        elif codec.startswith('mp4a'):  # mp4 无需转换
                            cmd_opts += '-acodec copy '

                    file = f'{bvid}-{i}.m4s'
                    middle_files.append(file)
                    debug(
                        'download',
                        f'\x1b[33m{bvid} {file}\x1b[0m',
                        f'id:{item["id"]}',
                        f'bandwidth:{item["bandwidth"]}',
                        f'height:{item["height"]}',
                        f'\x1b[2m{url_download}\x1b[0m',
                    )
                    if os.access(file, os.F_OK):
                        if not get_bool_answer(f'\x1b[33m{bvid} {file} 已存在，是否覆盖？\x1b[0m'):
                            continue
                    if not DEBUG:
                        r = session.get(
                            url_download,
                            headers={'user-agent': cls.user_agent, 'referer': res.history[-1].url if len(res.history) else url},
                        )
                        with open(file, mode='wb') as f:
                            f.write(r.content)

                if crf:
                    cmd_opts += f'-crf {crf} '

                cmd = f'ffmpeg -hide_banner -loglevel +level+fatal -stats -i {" -i ".join(middle_files)} '
                cmd += cmd_opts
                cmd += f"'{filename}' "
                debug('ffmpeg', f'\x1b[33m{bvid} cmd \x1b[32m{cmd}\x1b[0m')
                if os.system(cmd) == 0 and not DEBUG and prune:
                    os.system(f'rm {" ".join(middle_files)}')
                return True


if __name__ == '__main__':
    opts = {
        "kind": Kind.VIDEO,
        "crf": None,
        "prune": False,
        "cookie": None,
    }
    from pathlib import Path

    if '-h' in argv:
        nl = '\n'
        print(
            '\n'.join(
                [
                    f'\x1b[32mpython3 {Path(__file__).name}\x1b[0m [options] <url> [[options] <url> ...]',
                    f'   [-<kind>]: \x1b[2m指定视频分类，以选择合理码率下载，默认为:-video\x1b[22m',
                    f'\x1b[33;2m{nl.join(["            " + k.name for k in Kind])}\x1b[0m',
                    f'   [-<N>]: \x1b[2m指定合并视频分段时的crf值，如:-28\x1b[22m',
                    f'   [-prune]: \x1b[2m删除中间文件\x1b[22m',
                    f'   [-c, -cookie]: \x1b[2mcookie，可以获取480P以上\x1b[22m',
                ]
            )
        )
        exit(0)
    argv.pop(0)
    count = 0
    while len(argv):
        arg = argv.pop(0)
        if arg == '-c' or arg == '-cookie':
            opts['cookie'] = argv.pop(0)
        elif arg == '-prune':
            opts['prune'] = True
        elif re.search(r'^-[0-9]+$', arg):
            opts['crf'] = int(arg[1:])
        elif hasattr(Kind, arg[1:].upper()):
            opts['kind'] = getattr(Kind, arg[1:].upper())
        else:
            count += 1
            debug('options', f'\x1b[2m{opts}\x1b[0m')
            Title.set('downloading...')
            Bilibili.download(arg, **opts)
            Title.set('')
            len(argv) and sleep(1)

'''
// https://api.bilibili.com/x/web-interface/wbi/view/detail
console.table(__playinfo__.data.dash.video.map(e => [e.height, ~~(e.bandwidth/1024), e.codecs]))
console.table(__playinfo__.data.dash.audio.map(e => [e.height, ~~(e.bandwidth/1024), e.codecs]))
((keyword) => {
    console.log(temp1.data.View.ugc_season.sections[0].episodes.filter(e => e.title.includes(keyword)))
    console.log(temp1.data.View.ugc_season.sections[0].episodes.filter(e => e.title.includes(keyword)).map(e => 'https://www.bilibili.com/video/'+e.bvid).join(' '))
    console.table(temp1.data.View.ugc_season.sections[0].episodes.filter(e => e.title.includes(keyword)).map(e => [e.title, e.bvid, `${Math.floor(e.arc.duration/3600)}:${Math.floor(e.arc.duration%3600/60)}:${e.arc.duration%60}`]))
})('七政')
'''
