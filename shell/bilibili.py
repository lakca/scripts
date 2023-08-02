import random
from sys import argv
import requests
import re
import json
import os
from datetime import datetime


def search(reg, text, index=0):
    matched = re.search(reg, text)
    return matched and matched.group(index)


def getdeep(m, key):
    for k in key.split('.'):
        m = m.get(k, None)
        if m is None:
            break
    return m


class Bilibili:

    user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'

    @classmethod
    def download(cls, url: str, highBandwidth: bool = False, crf: int = 28):
        with requests.Session() as session:
            try:
                if 'TEST' in list(os.environ.keys()):
                    with open(f'bilibili.json', mode='r') as f:
                        data = json.load(f)
                    play_info = data.get('__playinfo__')
                    initial_state = data.get('__INITIAL_STATE__')
                else:
                    session.headers.update({'user-agent': cls.user_agent})
                    url = search(r'http\S+', url)
                    res = session.get(url)
                    play_info = json.loads(search(
                        r'<script>window.__playinfo__=([\s\S]+?)</script>', res.text, 1).strip())
                    initial_state = json.loads(search(
                        r'<script>window.__INITIAL_STATE__=([\s\S]+?)(;\(function\(\).*)?</script>', res.text, 1).strip())
                aid = getdeep(initial_state, 'aid')
                bvid = getdeep(initial_state, 'bvid')
                ctime = getdeep(initial_state, 'videoData.ctime')
                title = getdeep(initial_state, 'videoData.title')
                author = getdeep(initial_state, 'videoData.owner.name')
                authormid = getdeep(initial_state, 'videoData.owner.mid')
                audio = getdeep(play_info, 'data.dash.audio')
                video = getdeep(play_info, 'data.dash.video')
                audio.sort(key=lambda e: getdeep(e, 'bandwidth'))
                video.sort(key=lambda e: getdeep(e, 'bandwidth'))
            except:
                with open(f'bilibili.debug.json', mode='w') as f:
                    f.write(json.dumps(
                        {'__playinfo__': play_info, '__INITIAL_STATE__': initial_state}))
                with open('bilibili.debug.html', mode='w') as f:
                    f.write(res.text)
            else:
                av = [audio[-1], video[-1]
                      ] if highBandwidth else [audio[0], video[0]]
                temp = random.getrandbits(128)
                files = []
                for i, item in enumerate(av):
                    downloadurl = getdeep(item, 'baseUrl')
                    print(downloadurl)
                    r = session.get(downloadurl, headers={
                        'user-agent': cls.user_agent,
                        'referer': res.history[-1].url
                    })
                    tempfile = f'{temp}-{i}.m4s'
                    with open(tempfile, mode='wb') as f:
                        f.write(r.content)
                    files.append(tempfile)
                filename = '-'.join([datetime.fromtimestamp(
                    ctime).strftime("%Y%m%d%H%M"), bvid, title]) + '.mp4'
                cmd = f'ffmpeg -i {" ".join(files)} -crf {crf} "{filename}"'
                print(cmd)
                os.system(cmd)


if __name__ == '__main__':
    highBandwidth = False
    crf = 28
    from pathlib import Path
    if '-h' in argv:
        print('\n'.join(['',
                         f'python3 {Path(__file__).name} [options] <url> [[options] <url> ...]',
                         '   -high: high bandwidth',
                         '   -low: low bandwidth',
                         '   -<N>: crf']))
        exit(0)
    for arg in argv[1:]:
        if arg == '-high':
            highBandwidth = True
        elif arg == '-low':
            highBandwidth = False
        elif re.search(r'^-[0-9]+$', arg):
            crf = int(arg[1:])
        else:
            print(Bilibili.download(arg, highBandwidth=highBandwidth, crf=crf))
