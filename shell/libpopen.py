from platform import system
from subprocess import Popen

OPENER = "start" if system() == "Windows" else "open"


def browse(url):
    global OPENER
    Popen([OPENER, url])
