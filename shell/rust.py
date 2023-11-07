#!/usr/bin/env python3

from hashlib import md5
from json import dumps, loads
from os import path
from subprocess import Popen
from platform import system
from urllib import request
from urllib.parse import parse_qs, quote, urlencode, urlparse, urlunparse
from sys import argv
from typing import Callable, KeysView, Optional, TypeAlias, Union
from datetime import datetime


def ask(query):
    return input(query)


CACHE_FILE = path.expanduser("~/.rust.py.cache")
OPENER = "start" if system() == "Windows" else "open"

argv.pop(0)

requestCache = {}


def loadCache():
    global requestCache
    with open(CACHE_FILE, "r+") as f:
        requestCache = loads(f.read())


def flushCache():
    global requestCache
    with open(CACHE_FILE, "w") as f:
        f.write(dumps(requestCache))


def browse(url):
    global OPENER
    Popen([OPENER, url])


def hash(text: str):
    if text is None:
        return ""
    else:
        hl = md5()
        hl.update(text.encode())
        return hl.hexdigest()


def get(
    url: str,
    returnJson: Optional[bool] = None,
    headers: Optional[dict] = None,
    query: Optional[Union[str, dict]] = None,
    data: Optional[dict] = None,
    force: Optional[bool] = False,
):
    global requestCache
    if query:
        query = query if isinstance(query, str) else urlencode(list(query.items()))
        urlObj = urlparse(url)
        urlObj._replace(query=urlObj.query + "&" + query if urlObj.query else query)
        url = urlunparse(urlObj)

    if data:
        data = urlencode(data)

    text = None

    hs = hash(url) + hash(data)
    if not force and requestCache.get(hs):
        text = requestCache.get(hs)

    if text is None:
        req = request.Request(url)
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)
        with request.urlopen(req, data=data) as f:
            text = f.read().decode("utf-8")
            requestCache[hs] = text
    if returnJson:
        return loads(text)
    return text


def print_list(
    items: list[dict],
    keys: list,
    labels: Optional[list] = [],
    mappers: Optional[Callable] = [],
):
    print("\t".join([(labels[i] or k) if len(labels) > i else k for (i, k) in enumerate(keys)]))
    dmp = lambda v: v or "-"
    mp = lambda i: (mappers[i] or dmp) if len(mappers) > i else dmp
    if items:
        for item in items:
            print("\t".join([mp(i)(item.get(k, "") if k else "") for (i, k) in enumerate(keys)]))


loadCache()

COMMANDS = {
    "open": {
        "_comment": "打开页面",
        "_cmd": ["open"],
        "crate": {
            "_comment": "crates.io主页",
            "_cmd": [
                "crate",
                "c",
            ],
        },
        "crate-version": {
            "_comment": "crates.io的版本历史页面",
            "_cmd": [
                "crate-version",
                "cv",
            ],
        },
    },
    "versions": {"_comment": "获取crate版本列表", "_cmd": ["versions"]},
    "dependencies": {
        "_comment": "获取crate依赖列表",
        "_cmd": ["dependencies", "deps"],
        "_args": {
            "crate": ['-c', '--crate'],
            "version": ['-v', '--version', '--ver'],
        },
    },
}


class Command:
    BIG_LETTERS = range(ord('A'), ord('Z'))

    def createCommands(cls, commands: dict) -> dict[str, 'Command']:
        return dict(zip([[k, cls(v)] for k, v in commands.items()]))

    def __init__(self, commandOptions: dict):
        self.commandOptions = commandOptions
        self.args = {}
        self.subcommands = self.createCommands(commandOptions['_args'])

    def match(self, cmd):
        return cmd in self.commandOptions["_cmd"]

    def parseArgs(self, args: list[str]):
        while len(args):
            arg = args.pop(0)
            for k, v in self.commandOptions['_args'].items():
                if arg in v:
                    self.args[k] = True if k[0] in self.BIG_LETTERS else args.pop(0)


commands: dict[str, 'Command'] = Command.createCommands(COMMANDS)


def help(commands: list, depth=0):
    lines = []
    for command in commands:
        lines.append(
            [
                "  " * depth + f"\x1b[31;2m{', '.join(command['_cmd'])}\x1b[0m",
                f"\x1b[2m- {command['_comment']}\x1b[0m",
            ]
        )
        for k in filter(lambda e: not e.startswith("_"), command.keys()):
            lines.extend(help([command[k]], depth=depth + 1))
    if depth == 0:
        width = max(map(lambda e: len(e[0]), lines))
        for line in lines:
            line[0] = line[0] + " " * (width - len(line[0]) + 1)
            print("".join(line))
    else:
        return lines


if __name__ == "__main__":
    cmd = argv.pop(0)

    if "-h" not in argv:
        if commands['open'].match(cmd):
            subCmd = argv.pop(0)
            if commands['open'].subcommands["crate"].match(subCmd):
                browse(f"https://crates.io/crates/{argv[0]}")

            elif commands['open'].subcommands["crate-version"].match(subCmd):
                browse(f"https://crates.io/crates/{argv[0]}/versions?sort=semver")

        elif commands["versions"].match(cmd):
            """
            ref: https://crates.io/crates/clap/versions?sort=semver
            """
            items = get(f"https://crates.io/api/v1/crates/{argv[0]}", returnJson=True).get("versions")
            filter(lambda e: e.get('rust_version', 0).split('.'))
            print_list(
                items,
                keys=["num", "rust_version", "created_at"],
                labels=["Version", "Rustc", "Release"],
                mappers=[
                    None,
                    None,
                    lambda v: v[0:10] if v else "",
                ],
            )

        elif commands["dependencies"].match(cmd):
            """ """
            commands["dependencies"].parseArgs()
            item = get(f"https://crates.io/api/v1/crates/{argv[0]}/{argv[1]}/dependencies")
        else:
            help(list(commands.values()))
    else:
        help(list(commands.values()))

flushCache()
