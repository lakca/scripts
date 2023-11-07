#! /usr/bin/env python3

from sys import argv
from subprocess import Popen
from platform import system
from urllib.parse import quote

cmd = "start" if system() == "Windows" else "open"


def start(url):
    Popen([cmd, url])


if __name__ == "__main__":
    arg = argv[1]
    words = argv[2:]
    for word in words:
        if arg == "rs" or arg == "rust":
            start("https://docs.rs/{0}".format(quote(word)))
        if arg == "npm" or arg == "js":
            start("https://www.npmjs.com/package/{0}".format(quote(word)))
