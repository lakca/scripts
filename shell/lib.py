# coding=utf-8

from time import mktime
from datetime import datetime
from functools import cmp_to_key, reduce
import inspect
import io
import json
import random
import sys
import re
import os
from typing import MutableSequence, Sequence, get_type_hints
from urllib import request
from urllib.parse import quote

NUMBER_REG = r"-?([0-9]+\.?[0-9]*|\.[0-9]*)"

DEBUG = os.environ.get("DEBUG")
DEBUG = "({})".format(DEBUG.replace(
    ",", "|").replace("*", ".*")) if DEBUG else DEBUG
SHOULD_STORE = bool(os.environ.get("SHOULD_STORE"))
TABLE = bool(os.environ.get("TABLE"))
NO_TABLE = bool(os.environ.get("NO_TABLE"))
IMGCAT = bool(os.environ.get("IMGCAT"))
SIMPLE = bool(os.environ.get("SIMPLE"))
LINK = bool(os.environ.get("LINK"))
TABLE_NO_HEADER = bool(os.environ.get("TABLE_NO_HEADER"))
NO_EMPTY_DASH = bool(os.environ.get("NO_EMPTY_DASH"))
OFFSET = int(os.environ.get("OFFSET") or 0)

ENABLED_PLOT = True
STORAGE_FILE = None

try:
    from imgcat import imgcat
except:
    IMGCAT = False

try:
    import matplotlib as mp
    import matplotlib.pyplot as plt
    import matplotlib.ticker as mpticker
    import matplotlib.dates as mpdates
    import mplfinance as mpf
    import numpy as np
    import pandas as pd

    mp.rcParams["font.family"] = ["Heiti TC"]
except:
    ENABLED_PLOT = False


def noop(*args):
    return args[0] if len(args) else None


def debug(*args):
    if DEBUG:
        frame = inspect.stack()[1]
        if re.search(DEBUG, frame.function):
            print(
                f"\033[2m[\033[31mDEBUG:{frame.filename}:{frame.lineno} \033[32m{frame.function}\033[0m\033[2m]",
                *args,
                "\033[0m",
            )


class Node:
    def __init__(self, parent: "Node" = None):
        self.data = {}
        # 当前分词（语法单元）
        self._word = ""
        # 属性的绝对路径名（属性id）
        self._keyPrefix = parent.data["key"] + ":" if parent else ""
        self.data["key"] = self._keyPrefix
        self.data["key_or"] = []
        # 属性相对（语法支对象）路径
        self.data["keys"] = []
        # 修饰函数及参数
        self.data["pipes"] = []
        # 字段标签（名称等）
        self.data["labels"] = []
        # 最新的（最后定义的）字段标签
        self.data["label"] = ""

        self.usingKey = False

        self.usingLabel = False

        self.usingPipe = False
        self.usingArgs = False
        self.usingKarg = False
        self.usingList = False

        self.using = []

        self.usingKeyOr = False
        self.usingKey = False

        self._parent = parent
        if parent:
            parent.append(self)

    @property
    def parent(self):
        return self._parent

    @property
    def worded(self):
        return len(self._word) > 0

    @property
    def keyed(self):
        return self.data["key"] != self._keyPrefix

    def token(self, token, ignoreKeys=False):
        # 对于属性id（key）而言，所有token都是必须的；
        if not (self.usingPipe or self.usingLabel or self.usingArgs):
            self.data["key"] += token
        # 但对于属性路径（keys）而言，符号是需要去掉的
        if not ignoreKeys:
            self._word += token
        return self

    def keyor(self):
        self.usingKeyOr = not self.usingKeyOr
        return self

    def key(self):
        self.usingKey = True
        return self

    # 进出管道
    def pipe(self):
        self.usingPipe = not self.usingPipe
        return self

    # 进出管道参数
    def args(self):
        self.usingArgs = not self.usingArgs
        if self.usingArgs:
            pipe = self.data["pipes"].pop()
            self.data["pipes"].append([pipe])
        return self

    # 进出管道数组类型参数
    def list(self):
        self.usingList = not self.usingList
        if self.usingList:
            prev = self.data["pipes"][-1][-1]
            if isinstance(prev, tuple):
                self.data["pipes"][-1][-1] = (prev[0], [])
            else:
                self.data["pipes"][-1].append([])
        return self

    def karg(self):
        self.usingKarg = not self.usingKarg
        if self.usingKarg:
            arg = self.data["pipes"][-1].pop()
            self.data["pipes"][-1].append((arg,))
        return self

    # 进出字段标签
    def label(self):
        # 退出标签语法
        if self.usingLabel:
            self.data["labels"].append(self._word)
            self.data["label"] = self._word
            # 重置语法单元内容
            self._word = ""
        # 进入标签语法
        else:
            # 结束上一个语法单元
            self.word()
        self.usingLabel = not self.usingLabel
        return self

    # 切割语法单元
    def word(self):
        # 如果在标签语法内
        if self.usingLabel:
            return self
        # 如果在参数语法内
        elif self.usingArgs:
            # 列表
            if self.usingList:
                if isinstance(self.data["pipes"][-1][-1], tuple):
                    self.data["pipes"][-1][-1][-1].append(self._word)
                else:
                    self.data["pipes"][-1][-1].append(self._word)
            elif self.usingKarg:
                tup = self.data["pipes"][-1][-1]
                arg = tup[0]
                val = tup[1] if len(tup) > 1 else self._word
                if not val:
                    return self
                self.data["pipes"][-1].pop()
                if isinstance(self.data["pipes"][-1][-1], dict):
                    self.data["pipes"][-1][-1][arg] = val
                else:
                    obj = dict.fromkeys([arg], val)
                    obj["__kwarg"] = True
                    self.data["pipes"][-1].append(obj)
                self.karg()
            else:
                self.data["pipes"][-1].append(self._word)
        # 如果在管道语法内
        elif self.usingPipe:
            self.data["pipes"].append(self._word)
            self.usingPipe = False
        # 如果在普通语法内（即处于最外层的属性定义语法）
        elif self.worded:
            if self.usingKeyOr and self.usingKey:
                self.data["key_or"].append(
                    [
                        {
                            "key": self.data["key"],
                            "keys": self.data["keys"],
                            "iterKey": self.data["iterKey"],
                            "iterKeys": self.data["iterKeys"],
                        }
                    ]
                )
                self.data["key"] = ""
                self.data["keys"] = []
                self.data["iterKey"] = ""
                self.data["iterKeys"] = []
                self.usingKey = False
            else:
                self.data["keys"].append(self._word)
        # 重置语法单元内容
        self._word = ""
        return self

    # 注明这之前的语法单元是一个遍历键，而不是属性相对路径
    # 数组类型的深度属性如：colors*.name, colors*.vectors.red
    def iter(self):
        if self.usingLabel or self.usingPipe:
            return self
        self.data["iterKey"] = self.data["key"]
        self.data["iterKeys"] = self.data["keys"]
        self.data["keys"] = []
        return self

    def append(self, node: "Node" = None) -> "Node":
        if node:
            node._parent = self
            self.data["children"] = self.data.get("children") or []
            self.data["children"].append(node.data)
            return node
        else:
            return Node(self)

    def next(self, node: "Node" = None) -> "Node":
        if node:
            self.parent.append(node)
            return node
        else:
            return Node(self.parent)


def tokenize(fmt):
    root = Node()
    node = root
    escaped = False
    raw = False
    index = 0
    length = len(fmt)
    while index < length:
        token = fmt[index]
        # 开启或关闭纯字面量
        if token == "$" and not escaped:
            raw = not raw
            if not raw and node.usingPipe:
                node.word().pipe()
        # 已开启字面量
        elif raw:
            node.token(token)
        # 已开启转义
        elif escaped:
            node.token(token)
            escaped = False
        # 开启转义
        elif token == "\\":
            escaped = True
        # 开启分组，如管道参数、数组类型参数值、及标签等
        elif token == "[":
            if not node.usingPipe and not node.usingLabel:
                node.word().keyor()
            else:
                node.token(token)
        elif token == "]":
            if node.usingKeyOr:
                node.key().word().keyor()
            else:
                node.token(token)
        elif token == "(":
            # 开启管道参数
            if node.usingPipe:
                # 开启数组类型参数值
                if node.usingArgs:
                    if not node.worded:
                        node.word().list()
                # 开启参数列表
                else:
                    node.word().args()
            # 开启标签
            elif not node.usingLabel:
                node.word().label()
        # 关闭分组
        elif token == ")":
            # 关闭管道参数
            if node.usingArgs:
                # 关闭数组类型参数值
                if node.usingList:
                    node.word().list()
                # 关闭参数列表
                else:
                    node.word().args()
            # 关闭标签
            elif node.usingLabel:
                node.word().label()
        # 命名参数
        elif token == "=":
            if node.usingArgs and not node.usingList:
                node.word().karg()
            else:
                node.token(token)
        # 属性路径
        elif token == ".":
            if node.usingArgs:
                node.token(token)
            else:
                node.token(token, True).word()
        # 下级对象
        elif token == ":":
            if node.usingArgs:
                node.token(token)
            else:
                node = node.word().append()
        # 管道（函数）
        elif token == "|":
            if not node.usingArgs:
                node.word().pipe()
                if fmt[index + 1] == "$":
                    index += 1
                    node.token("$")
                    raw = True
        # 分割同级（属性、参数...）
        elif token == ",":
            if node.usingKeyOr:
                node.key().word()
            elif not node.usingArgs and not node.usingLabel:
                node = node.word().next()
            else:
                node.word()
        # 分割父级（结束当前级别的分支对象）
        elif token == ";":
            if not node.usingArgs:
                node = node.word().parent.next()
        # 遍历键
        elif token == "*":
            if not node.usingArgs:
                if fmt[index + 1] == ".":
                    index += 1
                    node.word().iter().token("*.", True)
                else:
                    node.token(token)
        # 其他
        else:
            node.token(token)
        index += 1
    node.word()
    return root


def retrieve(obj, keys, default=None):
    for key in keys:
        if obj:
            if str(key).isdecimal() and isinstance(obj, (list, int)):
                index = int(key)
                if len(obj) > index:
                    obj = obj[index]
                else:
                    return default
            else:
                if key in obj:
                    obj = obj[key]
                else:
                    return default
        else:
            return default
    return default if obj is None else obj


class Unicode:
    # https://blog.oasisfeng.com/2006/10/19/full-cjk-unicode-range/
    cjk = [
        (0x3400, 0x4DB5),  # 1）标准CJK文字
        (0x4E00, 0x9FA5),
        (0x9FA6, 0x9FBB),
        (0xF900, 0xFA2D),
        (0xFA30, 0xFA6A),
        (0xFA70, 0xFAD9),
        (0x20000, 0x2A6D6),
        (0x2F800, 0x2FA1D),
        (0xFF00, 0xFFEF),  # 2）全角ASCII、全角中英文标点、半宽片假名、半宽平假名、半宽韩文字母
        (0x2E80, 0x2EFF),  # 3）CJK部首补充
        (0x3000, 0x303F),  # 4）CJK标点符号
        (0x31C0, 0x31EF),  # 5）CJK笔划
        (0x2F00, 0x2FDF),  # 6）康熙部首
        (0x2FF0, 0x2FFF),  # 7）汉字结构描述字符
        (0x3100, 0x312F),  # 8）注音符号
        (0x31A0, 0x31BF),  # 9）注音符号（闽南语、客家语扩展）
        (0x3040, 0x309F),  # 10）日文平假名
        (0x30A0, 0x30FF),  # 11）日文片假名
        (0x31F0, 0x31FF),  # 12）日文片假名拼音扩展
        (0xAC00, 0xD7AF),  # 13）韩文拼音
        (0x1100, 0x11FF),  # 14）韩文字母
        (0x3130, 0x318F),  # 15）韩文兼容字母
        (0xD300, 0x1D35F),  # 16）太玄经符号：
        (0x4DC0, 0x4DFF),  # 17）易经六十四卦象
        (0xA000, 0xA48F),  # 18）彝文音节
        (0xA490, 0xA4CF),  # 19）彝文部首
        (0x2800, 0x28FF),  # 20）盲文符号
        (0x3200, 0x32FF),  # 21）CJK字母及月份
        (0x3300, 0x33FF),  # 22）CJK特殊符号（日期合并）
        (0x2700, 0x27BF),  # 23）装饰符号（非CJK专用）
        (0x2600, 0x26FF),  # 24）杂项符号（非CJK专用）
        (0xFE10, 0xFE1F),  # 25）中文竖排标点
        (0xFE30, 0xFE4F),  # 26）CJK兼容符号（竖排变体、下划线、顿号）
    ]

    # https://unicode.org/emoji/charts/full-emoji-list.html
    emoji = [
        (0x1F600, 0x1F3F3),
    ]

    ascii = [
        (0x20, 0x7E),
    ]

    zero = [
        (0x0, 0x0),
    ]

    @classmethod
    def isrange(cls, v, range):
        for range in getattr(cls, range):
            if range[1] >= ord(v) >= range[0]:
                return True
        return False

    @classmethod
    def simpleWidth(cls, text):
        w = 0
        for char in text:
            w += (
                1
                if cls.isrange(char, "ascii")
                else 2
                if cls.isrange(char, "cjk")
                else 1
            )
        return w


class Pipe:
    STYLES = {
        "red": "31",
        "green": "32",
        "yellow": "33",
        "blue": "34",
        "magenta": "35",
        "cyan": "36",
        "white": "37",
        "bold": "1",
        "dim": "2",
        "italic": "3",
        "underline": "4",
        "blink": "5",
        "reverse": "7",
        "invisible": "8",
    }

    @classmethod
    def apply(cls, v, pipes=[], data={}, interpolate=None, signed=None):
        for pipe in pipes:
            if pipe == "true" and not v:
                return v
            args = []
            kwargs = {}
            kwargs["__interpolate"] = (
                lambda tpl: cls._interpolate(str(tpl), data) if data else tpl
            )
            if isinstance(pipe, list):
                for e in pipe[1:]:
                    if isinstance(e, dict) and e["__kwarg"]:
                        kwargs.update(e)
                    else:
                        args.append(e)
                pipe = pipe[0]

            if isinstance(signed, bool):
                if signed:
                    if not pipe.startswith("+"):
                        continue
                    pipe = pipe[1:]
                elif pipe.startswith("+"):
                    continue
            elif isinstance(signed, str) and signed:
                if not pipe.startswith(signed):
                    continue
                pipe = pipe[slice(len(signed))]

            if interpolate is not None and pipe.startswith(interpolate):
                v = cls._interpolate(pipe[1:], data)
            else:
                attr = getattr(cls, pipe, None)
                if attr:
                    v = attr(v, *args, data=data, **kwargs)

        return v

    @classmethod
    def _interpolate(cls, template, data, *args, **kwargs):
        debug("template:", template)

        def replacer(m):
            key = m.group(1)
            escaped = False
            index = -1
            token = None
            debug("replace:", key)
            # 兼容定义中的绝对路径，如 data.band_list:word
            for (i, char) in enumerate(key):
                if char == "\\":
                    escaped = True
                elif char == "|" and not escaped:
                    index = i
                    break
                else:
                    escaped = False
            if index > -1:
                token = tokenize(key[index:]).data
                key = key[0:index]
            if key.startswith("."):  # 所在对象的后代属性
                value = str(retrieve(data.get("__", ""),
                            key.split(".")[1:], ""))
            elif key.startswith("/"):  # 绝对路径
                key_token = tokenize(key[1:]).data
                value = str(Parser.retrieve(data, key_token, ""))
            else:  # 无必要，仅作兼容用
                value = str(retrieve(data, [key], ""))
            debug("index:", index)
            debug("key:", key)
            debug("value:", value)
            token and debug("pipes:", value, token["pipes"])
            return cls.apply(value, token["pipes"], data) if token else value

        return re.sub(r"\{([^\}]+)\}", replacer, template)

    @classmethod
    def date(cls, v, *args, **kwargs):
        sv = str(v)
        try:
            nv = float(v)
        except:
            pass
        for case in (
            # custom
            lambda: datetime.strptime(
                sv, kwargs["from"]) if kwargs["from"] else 0 / 0,
            # timestamp 1667632623
            lambda: datetime.fromtimestamp(
                nv / 1000 if nv > 9999999999 else nv),
            # UTC "Tue, 18 Oct 2022 23:00:23 +0800"
            lambda: datetime.strptime(sv, "%a, %d %b %Y %H:%M:%S %z"),
            # Mon Jan 31 20:50:10 +0800 2022
            lambda: datetime.strptime(sv, "%a %b %d %H:%M:%S %z %Y"),
            # ISO 2022-11-01T00:00:00, 2022-11-01 00:00:00 ...
            lambda: datetime.fromisoformat(sv),
        ):
            try:
                v = case()
                break
            except:
                pass
        else:
            return v
        fmts = {
            "date": "%Y-%m-%d",
            "time": "%H:%M:%S",
            "year": "%Y",
            "md": "%m-%d",
            "hm": "%H:%M",
        }
        return v.strftime(
            fmts.get(
                kwargs.get("format") or (
                    len(args) and args[0]), "%Y-%m-%d %H:%M:%S"
            ),
        )

    @classmethod
    def string2Number(cls, v, *args, **kwargs):
        """v: str<int|float>"""
        if v is None:
            return v
        if isinstance(v, (float, int)):
            return v
        return (
            0
            if v == "."
            else float(v)
            if "." in v
            else int(v)
            if re.match(NUMBER_REG + "$", str(v))
            else None
        )

    @classmethod
    def seekNumber(cls, v, *args, **kwargs):
        """v: str<number + any>"""
        if isinstance(v, (float, int)):
            return v
        match = re.search(NUMBER_REG, str(v))
        return match and cls.string2Number(match.group()) or 0

    @classmethod
    def number(cls, v, type=",", *args, **kwargs):
        if v is None or not re.match(NUMBER_REG + "$", str(v)):
            return v
        v = cls.string2Number(v)

        # 添加千位分隔符
        if type == ",":
            return "{:,}".format(v)
        # 转换为百分比
        elif type == "%":
            return "{:.2%}".format(v)
        # 转换为带正负号百分比
        elif type == "+%":
            return "{:+.2%}".format(v)
        # 添加正负号
        elif type == "+":
            return "{:+.2f}".format(v)
        # 固定小数位
        elif type == "fixed":
            return ("{:0" + str(kwargs["n"]) + "d}").format(v)
        # 转换为中文单位
        elif type == "cn":
            for e in ["", "万", "亿", "兆"]:
                if abs(v) > 10000:
                    v = v / 10000
                else:
                    return str(v) + e if isinstance(v, int) else "{:.4f}".format(v) + e
        # 四舍五入
        elif type.isdecimal():
            return round(v, int(type))
        else:
            return type.format(v)

    @classmethod
    def format(cls, v, kind=",", *args, **kwargs):
        if isinstance(kind, list):
            return reduce(lambda r, e: cls.format(r, e, *args, **kwargs), v)
        n = cls.string2Number(v)
        if kind == "%":
            return "{:}%".format(n) if n is not None else ""
        elif kind == "+%":
            return "{:+}%".format(n) if n is not None else ""
        return ""

    @classmethod
    def discount(cls, v, *args, **kwargs):
        interpolate = kwargs.get("__interpolate", noop)
        if len(args) > 1:
            v = interpolate(args[1])
        if len(args) > 0:
            b = interpolate(args[0])
            b = cls.seekNumber(b)
            v = cls.seekNumber(v)
            return "{:+.2%}".format((v - b) / b) if b != 0 else ""

    @classmethod
    def _exp(cls, v, *args, **kwargs):
        basharr = cls._rsv_bash_args(**kwargs)
        target = kwargs.get("target")
        if kwargs["exp"] == "in":
            return str(v) in (basharr["arr"] if basharr else target if target else "")

    @classmethod
    def indicator(cls, v, *args, **kwargs):
        interpolate = kwargs.get("__interpolate", noop)
        ops = []
        if "cmp" in kwargs:
            ops = [cls.seekNumber(interpolate(kwargs["cmp"])), 0]
        elif "exp" in kwargs:
            return Pipe.red(v) if cls._exp(v, *args, **kwargs) else Pipe.green(v)
        elif len(args):
            if len(args) == 1:
                ops = [cls.seekNumber(v), cls.seekNumber(interpolate(args[0]))]
            else:
                ops = [
                    cls.seekNumber(interpolate(args[0])),
                    cls.seekNumber(interpolate(args[1])),
                ]
        else:
            ops = [cls.seekNumber(v), 0]
        return (
            Pipe.green(v)
            if ops[0] < ops[1]
            else Pipe.red(v)
            if ops[0] > ops[1]
            else str(v)
        )

    @classmethod
    def style(cls, v, styles=[], *args, **kwargs):
        codes = []
        for style in styles:
            if style in cls.STYLES:
                codes.append(cls.STYLES[style])
        text = "\033[" + ";".join(codes) + "m" + str(v) + "\033[0m"
        # if kwargs.get('preserve', False):
        #     regReset = re.compile(r"\033\[0m")
        return text

    @classmethod
    def red(cls, v, *args, **kwargs):
        return cls.style(v, styles=["red"], *args, **kwargs)

    @classmethod
    def green(cls, v, *args, **kwargs):
        return cls.style(v, styles=["green"], *args, **kwargs)

    @classmethod
    def yellow(cls, v, *args, **kwargs):
        return cls.style(v, styles=["yellow"], *args, **kwargs)

    @classmethod
    def blue(cls, v, *args, **kwargs):
        return cls.style(v, styles=["blue"], *args, **kwargs)

    @classmethod
    def magenta(cls, v, *args, **kwargs):
        return cls.style(v, styles=["magenta"], *args, **kwargs)

    @classmethod
    def cyan(cls, v, *args, **kwargs):
        return cls.style(v, styles=["cyan"], *args, **kwargs)

    @classmethod
    def white(cls, v, *args, **kwargs):
        return cls.style(v, styles=["white"], *args, **kwargs)

    @classmethod
    def bold(cls, v, *args, **kwargs):
        return cls.style(v, styles=["bold"], *args, **kwargs)

    @classmethod
    def dim(cls, v, *args, **kwargs):
        return cls.style(v, styles=["dim"], *args, **kwargs)

    @classmethod
    def italic(cls, v, *args, **kwargs):
        return cls.style(v, styles=["italic"], *args, **kwargs)

    @classmethod
    def underline(cls, v, *args, **kwargs):
        return cls.style(v, styles=["underline"], *args, **kwargs)

    @classmethod
    def _image(cls, v, *args, **kwargs):
        if v and v.startswith("http") and os.environ.get("ITERM_SESSION_ID", None):
            try:
                imgcat(request.urlopen(v).read(), height=7)
            except:
                pass

    @classmethod
    def image(cls, v, *args, **kwargs):
        global IMGCAT
        if v and IMGCAT:
            v = v if v.startswith("http") else "https:" + v
            cls._image(re.sub(r"\/orj\d+\/", "/orj180/", v))
        return v

    @classmethod
    def prepend(cls, v, text="", *args, **kwargs):
        return text + str(v)

    @classmethod
    def append(cls, v, text="", *args, **kwargs):
        return str(v) + text

    @classmethod
    def index(cls, v, *args, **kwargs):
        index = (kwargs.get("data", {}).get("__index", 0)) + (
            (int(args[0]) if len(args) else 0)
        )
        return cls.white(f"【{index}】") + str(v)

    @classmethod
    def newline(cls, v, number=1, *args, **kwargs):
        number = int(number)
        return "\n" * -number + str(v) if number < 0 else str(v) + "\n" * number

    @classmethod
    def join(cls, v, delimiter=", ", *args, **kwargs):
        return delimiter.join(v) if isinstance(v, list) else v

    @classmethod
    def hr(cls, v, dividing="-" * 50 + "\n", *args, **kwargs):
        return str(v) + dividing

    @classmethod
    def sort(cls, v, *args, **kwargs):
        if not isinstance(v, list):
            return v
        useKwargs = {}
        if kwargs["key"]:
            def getVal(e): return e[kwargs["key"]]
            if kwargs["sorts"]:
                getIndex = (
                    lambda k: kwargs["sorts"].index(k)
                    if k in kwargs["sorts"]
                    else float("inf")
                )
                useKwargs["key"] = cmp_to_key(
                    lambda a, b: getIndex(getVal(a)) - getIndex(getVal(b))
                )
            else:
                useKwargs["key"] = getVal
        v.sort(**useKwargs)
        return v

    @classmethod
    def reverse(cls, v, *args, **kwargs):
        if isinstance(v, MutableSequence):
            v.reverse()
        return v

    @classmethod
    def _getLeftStyleANSI(cls, text, *args, **kwargs):
        text = str(text)
        start = kwargs.get("start", 0)
        end = kwargs.get("end", len(text))
        regStyle = re.compile(r"\033\[(?:\d;?)+m")
        regReset = re.compile(r"\033\[0m")
        resetMatch = None
        styleStart = start
        for resetMatch in regReset.finditer(text, start, end):
            pass
        if resetMatch:
            styleStart = resetMatch.end()
        ansi = regStyle.findall(text, styleStart, end)
        return ansi

    @classmethod
    def _rebaseNestedStyleANSI(cls, text, *args, **kwargs):
        reg = re.compile(r"((?P<reset>\033\[0m)|(?P<style>\033\[(?:\d;?)+m))")
        style = []

        def replacer(match):
            nonlocal style
            # print(match.groupdict(), repr(match.group('reset')), repr(match.group('style')))
            r = match.group()
            if match.group("style"):
                style.append(match.group("style"))
            elif match.group("reset"):
                len(style) and style.pop()
                r += "".join(style)
                style = ""
            # print(repr(r))
            return r

        return reg.sub(replacer, text)

    @classmethod
    def tag(cls, text, *args, **kwargs):
        if not isinstance(text, str):
            return
        regTag = re.compile(r"<(\w+)(\s+[^>]*)*>([\s\S]*?)</\1>")
        start = 0
        ansi = []
        # print(text)
        # print(repr(text))

        def replacer(match):
            nonlocal start
            nonlocal ansi
            end = match.start()
            ansi = cls._getLeftStyleANSI(
                "".join(ansi) + match.string[start:end])
            start = end
            return "\033[7m" + match.group(3) + "\033[0m" + "".join(ansi)

        return regTag.sub(replacer, text)

    @classmethod
    def striptags(cls, v, *args, **kwargs):
        return re.sub(r"</?\w+(\s+[^>]*)*>", "", v) if isinstance(v, str) else v

    @classmethod
    def slice(cls, v, *args, **kwargs):
        if not isinstance(v, Sequence):
            v = str(v)
        return v[slice(*list(map(lambda e, *argss: int(e), args)))]

    @classmethod
    def _rsv_bash_args(cls, **kwargs):
        args = {}
        for (k, v) in kwargs.items():
            if k.startswith("bash:"):
                args[k[5:]] = v
        if "arr" in args:  # bash array
            args["arr"] = args["arr"].split(args.get("arrsep", " "))
        # int
        for k in ("arrdim", "arridx"):
            if k in args:
                args[k] = int(args[k])
        return args

    @classmethod
    def map(cls, v, *args, **kwargs):
        bash_args = cls._rsv_bash_args(**kwargs)
        arr = bash_args.get("arr")
        arrdim = bash_args.get("arrdim", 1)
        arridx = bash_args.get("arridx", 0)
        if "arr" in bash_args:
            for (i, e) in enumerate(bash_args["arr"]):
                if e == str(v):
                    return arr[i - i % arrdim + arridx]
        return v

    @classmethod
    def urlencode(cls, v, *args, **kwargs):
        return quote(v) if isinstance(v, str) else v

    @classmethod
    def dashempty(cls, v, *args, **kwargs):
        return "-" if v is None or v == "" else v

    @classmethod
    def _em_a_stock_int_time(cls, t, *args, **kwargs):
        """
        Args:
            t: int
                e.g. 930, 1059, 1300 ...

        Returns:
            (t, seconds_diff_to_AStock_day_start_time)

        Examples:
            - 930 -> (930, 0)
            - 1030 -> (930, 60)
            - 1330 -> (930, 150)
        """
        t = "{:04d}".format(t)
        tl = t[0:2] + ":" + t[2:4]
        t = 60 * (int(t[0:2]) - 9) + int(t[2:4]) - 30
        t = t if t <= 120 else t - 90
        return (t, tl)

    @classmethod
    def _em_a_stock_time_axis(cls, ax, *args, **kwargs):
        ax.set_xlim((0, 240))
        ax.xaxis.set_ticks((0, 30, 60, 90, 120, 150, 180, 210, 240))
        kwargs.get('no_labels', False) and ax.set_xticklabels([]) or ax.xaxis.set_ticklabels(
            (
                "09:30",
                "10:00",
                "10:30",
                "11:00",
                "11:30/13:00",
                "13:30",
                "14:00",
                "14:30",
                "15:00",
            )
        )

    @classmethod
    def time_diff(cls, t, time_points):
        delta = None
        if not time_points:
            time_points = [
                t.replace(hour=9, minute=30, second=0),
                t.replace(hour=11, minute=30, second=0),
                t.replace(hour=13, minute=0, second=0),
                t.replace(hour=15, minute=0, second=0),
            ]
        if t >= time_points[0] and t <= time_points[1]:
            delta = t - time_points[0]
        if t >= time_points[2] and t <= time_points[3]:
            delta = t - time_points[2] + \
                time_points[1] - time_points[0]
        return (divmod(delta.seconds, 60)[0], time_points) if delta is not None else None

    @classmethod
    def plot(cls, dt, *args, **kwargs):
        interpolate = kwargs.get("__interpolate", noop)
        meta = {}
        for (k, v) in kwargs.items():
            if k.startswith("m:"):
                meta[k[2:]] = interpolate(kwargs.get(k))
        debug(meta)
        global ENABLED_PLOT
        transparent = not True
        fig = None
        ax: plt.Axes = None
        ax2: plt.Axes = None
        buf: io.BytesIO = None
        texts: plt.Text = []
        barLabels: list[plt.Text] = []
        if not ENABLED_PLOT:
            sys.stderr.write("matplotlib and numpy are not installed.")
            return dt

        def indicate(a, b):
            return "red" if a > b else "green" if a < b else "white"

        if kwargs["type"] == "zdfb":  # 涨跌分布
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax = fig.add_axes((0.05, 0.05, 0.9, 0.9))
            x = []
            xt = []
            y = []
            for item in dt:
                (k, v) = list(item.items())[0]
                x.append(int(k))
                y.append(v)
                xt.append(
                    "跌停"
                    if k == "-11"
                    else "涨停"
                    if k == "11"
                    else "平盘"
                    if k == "0"
                    else "<9%"
                    if k == "-10"
                    else ">9%"
                    if k == "10"
                    else k + "%"
                )
            bar = ax.bar(
                x,
                y,
                tick_label=xt,
                color=list(
                    map(lambda e: "red" if e >
                        0 else "gray" if e == 0 else "green", x)
                ),
            )
            barLabels = ax.bar_label(bar, padding=3)
            texts.append(ax.set_title("涨跌分布"))

        elif kwargs["type"] == "zdtdb":  # 涨跌停对比
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax = fig.add_axes((0.05, 0.05, 0.9, 0.9))
            y1 = []
            y2 = []
            x = []
            xt = []
            for item in dt:
                t, tl = cls._em_a_stock_int_time(item["t"])
                xt.append(tl)
                x.append(t)
                y1.append(item["ztc"])
                y2.append(item["dtc"])
            cls._em_a_stock_time_axis(ax)
            ax.plot(x, y1, "red")
            ax.plot(x, y2, "green")
            texts.append(ax.text(x[-1], y1[-1], y1[-1]))
            texts.append(ax.text(x[-1], y2[-1], y2[-1]))
            texts.append(ax.set_title(f"涨跌停对比\t{xt[-1]}"))

        elif kwargs["type"] == "fbws":  # 封板未遂
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax = fig.add_axes((0.05, 0.05, 0.9, 0.9))
            y1 = []
            y2 = []
            x = []
            xt = []
            for item in dt:
                t, tl = cls._em_a_stock_int_time(item["t"])
                xt.append(tl)
                x.append(t)
                y1.append(item["c"])  # 炸板数
                y2.append(item["zbp"])  # 炸板率
            cls._em_a_stock_time_axis(ax)
            ax.plot(x, y1, "green")
            texts.append(ax.set_ylabel("炸板数", loc="top"))
            ax.text(x[-1], y1[-1], "炸板数{}".format(y1[-1]), color="green")
            ax2 = ax.twinx()
            ax2.plot(x, y2, "black")
            texts.append(ax2.set_ylabel("炸板率", loc="top"))
            ax2.text(x[-1], y2[-1], "炸板率{:.2f}%".format(y2[-1]), color="green")
            texts.append(ax.set_title(f"封板未遂\t{xt[-1]}"))

        elif kwargs["type"] == "gbqx":  # 股吧情绪
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax = fig.add_axes((0.05, 0.05, 0.9, 0.9))
            x = []
            y = []
            for item in dt:
                x.append(datetime.strptime(item["name"], "%H:%M"))
                y.append(item["val"])
            ax.plot(x, y, "gray")
            now = datetime.now()
            xticks = []
            xtick_labels = []
            if now.hour < 16:
                xticks = list(
                    map(
                        lambda t: datetime.strptime(t, "%H:%M"),
                        ["08:00", "10:00", "12:00", "14:00", "16:00"],
                    )
                )
                xtick_labels = ["08:00", "10:00", "12:00", "14:00", "16:00"]
            else:
                xticks = list(
                    map(
                        lambda t: datetime.strptime(t, "%H:%M"),
                        ["16:00", "18:00", "20:00", "22:00", "23:59"],
                    )
                )
                xtick_labels = ["16:00", "18:00", "20:00", "22:00", "24:00"]
            ax.xaxis.set_ticks(xticks)
            ax.xaxis.set_ticklabels(xtick_labels)
            ax.set_xlim(xticks[0], xticks[-1])
            ax.set_ylim(-1, 1)
            ax.fill_between([xticks[0], xticks[-1]], 0,
                            1, color="red", alpha=0.2)
            ax.fill_between([xticks[0], xticks[-1]], -1,
                            0, color="green", alpha=0.2)
            texts.append(ax.set_title(f"股吧情绪"))

        elif kwargs["type"] == "yddb":  # 盘口异动数据对比
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax = fig.add_axes((0.05, 0.05, 0.9, 0.9))
            up = "火箭发射 8201 快速反弹 8202 大笔买入 8193 封涨停板 4 打开跌停板 32 有大买盘 64 竞价上涨 8207 高开5日线 8209 向上缺口 8211 60日新高 8213 60日大幅上涨 8215"
            down = "加速下跌 8204 高台跳水 8203 大笔卖出 8194 封跌停板 8 打开涨停板 16 有大卖盘 128 竞价下跌 8208 低开5日线 8210 向下缺口 8212 60日新低 8214 60日大幅下跌 8216"
            xtick_labels = []
            up_nums = []
            down_nums = []
            for (i, (a, b)) in enumerate(zip(up.split(" "), down.split(" "))):
                if not (i % 2):
                    xtick_labels.append(a + "\n" + b)
                else:
                    up_nums.append(a)
                    down_nums.append(b)
            x = [i for (i, _) in enumerate(up_nums)]
            y_up = [0] * len(x)
            y_down = [0] * len(x)
            for item in dt:
                t = str(item["t"])
                if t in up_nums:
                    y_up[up_nums.index(t)] = int(item["ct"])
                elif t in down_nums:
                    y_down[down_nums.index(t)] = int(item["ct"])
            ax.set_xticks(x)
            ax.set_xticklabels(xtick_labels)
            ax.set_position((0.05, 0.1, 0.9, 0.8))
            ax.set_ylim(0, np.max(np.add(y_up, y_down)) + 100)
            bar_down = ax.bar(x, y_down, width=0.5, color="green")
            ax.bar_label(bar_down, padding=3, color="white")
            bar_up = ax.bar(x, y_up, width=0.5, color="red", bottom=y_down)
            ax.bar_label(bar_up, labels=y_up, padding=16, color="red")
            texts.append(ax.set_title("盘口异动对比（情绪指标）"))

        elif kwargs["type"] == "fst":  # 分时图
            fig = plt.figure(figsize=(11, 5.6), dpi=100)
            ax: list[plt.Axes] = (fig.add_axes((0.06, 0.35, 0.88, 0.6)),
                                  fig.add_axes((0.06, 0.05, 0.88, 0.25)))
            x_data_n: list[int] = []
            y_close = []
            y_volume = []
            y_average = []
            y_percent = []
            pre_close = float(meta["close"])
            time_points = None

            for item in dt:
                [time, open, close, high, low, vol,
                    amount, avg] = item.split(",")
                diff, time_points = cls.time_diff(
                    datetime.strptime(time, "%Y-%m-%d %H:%M"), time_points)
                x_data_n.append(diff)
                y_close.append(float(close))
                y_volume.append(int(vol))
                y_average.append(float(avg))
                y_percent.append(
                    round((float(close) - pre_close) / pre_close, 4))

            cls._em_a_stock_time_axis(ax[0])
            ax[0].plot(x_data_n, y_close, color="red")
            ax[0].plot(x_data_n, y_average, color="orange")

            texts.append(ax[0].text(0, ax[0].get_ylim()[
                         1], f"{meta.get('code', '')}", horizontalalignment="left", verticalalignment="bottom"))

            ax[0].text(ax[0].get_xlim()[1], ax[0].get_ylim()[1], cls.number(y_percent[-1], '+%'), color=indicate(
                y_percent[-1], 0), horizontalalignment="right", verticalalignment="bottom", fontsize="x-large", fontweight="bold")

            ax[0].annotate(y_close[-1], (x_data_n[-1], y_close[-1]),
                           color=indicate(y_close[-1], y_close[-2]), fontsize="large")

            cls._em_a_stock_time_axis(ax[1], no_labels=True)
            ax[1].bar(x_data_n, y_volume, color=["red" if y_close[i] > y_close[i-1]
                      else "lightgray" if y_close[i] == y_close[i-1] else "green" for (i, e) in enumerate(y_volume)])

            ax2 = ax[0].twinx()
            ax2.set_ylim(ax[0].get_ylim())
            ax2.set_yticks(ax[0].get_yticks())

            for tick in ax[0].yaxis.get_major_ticks():
                tick.label1.set_color(indicate(tick, pre_close))

            ax2.yaxis.set_major_formatter(
                lambda e, pos: cls.discount(e, pre_close))

            texts.append(ax[0].set_title(
                f"{meta.get('name', '')}-分时图"))

        else:
            fig = None
            ax = None

        if fig:
            global STORAGE_FILE
            global SHOULD_STORE
            if STORAGE_FILE and SHOULD_STORE:
                fig.savefig(
                    STORAGE_FILE
                    + "."
                    + kwargs["type"]
                    + str(random.randint(101, 999))
                    + ".png"
                )

            global IMGCAT
            if IMGCAT:
                if ax:
                    ax = ax if isinstance(ax, list) else [ax]
                    for a in ax:
                        transparent and a.tick_params(labelcolor="white")
                        transparent and a.spines["left"].set_color("gray")
                        transparent and a.spines["bottom"].set_color("gray")
                        transparent and a.spines["top"].set_color("none")
                        transparent and a.spines["right"].set_color("none")
                if ax2:
                    ax2 = ax2 if isinstance(ax2, list) else [ax2]
                    for a in ax:
                        transparent and a.tick_params(labelcolor="white")
                        transparent and a.spines["right"].set_color("gray")
                        transparent and a.spines["bottom"].set_color("gray")
                        transparent and a.spines["top"].set_color("none")
                        transparent and a.spines["left"].set_color("none")
                if barLabels:
                    for label in barLabels:
                        transparent and label.set_color("white")
                for text in texts:
                    transparent and text.set_color("white")
                if not buf:
                    buf = io.BytesIO()
                    savekargs = {}
                    if transparent:
                        savekargs["edgecolor"] = "white"
                    fig.savefig(buf, transparent=transparent)
                    buf.seek(0)
                imgcat(io.BufferedReader(buf))
            else:
                plt.show()


def trim_ansi(a):
    ESC = r"\x1b"
    CSI = ESC + r"\["
    OSC = ESC + r"\]"
    CMD = "[@-~]"
    ST = ESC + r"\\"
    BEL = r"\x07"
    pattern = (
        "(" + CSI + ".*?" + CMD + "|" + OSC +
        ".*?" + "(" + ST + "|" + BEL + ")" + ")"
    )
    return re.sub(pattern, "", a)


xxx = False


class Parser:
    @ classmethod
    def getTokens(cls, fmt):
        return tokenize(fmt).data

    @ classmethod
    def retrieve(cls, data, node, default=None, iter=False):
        key = "iterKeys" if iter else "keys"
        if "key_or" in node and len(node["key_or"]):
            for k in node["key_or"]:
                r = retrieve(data, k[key], default)
                if r is not None:
                    return r
        else:
            return retrieve(data, node[key], default)

    @ classmethod
    def getValue(cls, data, node):
        if "iterKeys" in node:
            if data:
                items = cls.retrieve(data, node, default=[], iter=True)
                items = items.values() if isinstance(items, dict) else items
                return [cls.retrieve(item, node) for item in items]
            else:
                return []

        data = cls.retrieve(data, node)

        if "children" in node:
            results = []
            if data:
                if isinstance(data, list):
                    results = []
                    for i, item in enumerate(data):
                        if not isinstance(item, dict):
                            item = {"value": item}
                        result = {"__": item, "__index": i + 1}
                        results.append(result)
                        for child in node["children"]:
                            value = (
                                cls.getValue(item, child)
                                if "children" in child or "iterKeys" in child
                                else cls.retrieve(item, child)
                            )
                            result[child["key"]] = value
                elif isinstance(data, dict):
                    results = {"__": data}
                    for child in node["children"]:
                        value = (
                            cls.getValue(data, child)
                            if "children" in child or "iterKeys" in child
                            else cls.retrieve(data, child)
                        )
                        results[child["key"]] = value

            return results

        else:
            return data

    @ classmethod
    def flatTokens(cls, tokens):
        flatted = {}
        flatted[tokens["key"]] = tokens
        if "children" in tokens:
            for child in tokens["children"]:
                flatted.update(cls.flatTokens(child))
        return flatted

    @ classmethod
    def applyPipes(cls, value, pipes: list, data: dict, signed=None):
        realPipes = pipes.copy()
        global NO_EMPTY_DASH
        if not NO_EMPTY_DASH:
            realPipes.append("dashempty")

        return Pipe.apply(value, realPipes, data, interpolate="$", signed=signed)

    @ classmethod
    def shouldHidden(cls, token, **kwargs):
        key = token.get("key", "")
        pipes = token.get("pipes", [])
        label = token.get("label", key)
        global SIMPLE
        return "HIDE" in pipes or (
            SIMPLE
            and ("index" in kwargs and kwargs["index"] != 0)
            and not (LINK and label in ["链接"])
            and "SIMPLE" not in pipes
        )

    @ classmethod
    def printRecord(cls, record, meta, indent=0):
        INDENT = 2
        _indent = indent
        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        index = 0
        for (key, val) in record.items():

            indent = _indent

            if key.startswith("__"):
                continue

            if cls.shouldHidden(meta[key], index=index):
                continue

            pipes = meta[key].get("pipes", [])
            labeled = len(meta[key].get("labels"))
            label = meta[key].get("label")
            downgrade = "DOWNGRADE" in pipes

            if downgrade:
                indent -= INDENT

            if labeled:
                scopedStdout("{}: ".format(
                    Pipe.apply(label, ["yellow", "italic"])))

            if isinstance(val, dict):
                cls.printRecord(val, meta, indent + INDENT)

            elif isinstance(val, list):
                scopedStdout("\n")
                global TABLE, NO_TABLE
                if (TABLE or "TABLE" in pipes) and not NO_TABLE:
                    cls.printTable(val, meta[key], indent + INDENT)
                else:
                    for i, item in enumerate(val):
                        if isinstance(item, dict):
                            cls.printRecord(item, meta, indent + INDENT)
                            i + 1 < len(val) and scopedStdout(
                                cls.applyPipes(
                                    (indent + INDENT) * " " + "-" * 50 + "\n",
                                    pipes,
                                    record,
                                )
                            )
                        else:
                            scopedStdout(
                                "  {}\n".format(
                                    cls.applyPipes(item or "", pipes, record)
                                )
                            )
            else:
                sys.stdout.write(
                    "{}\n".format(cls.applyPipes(val or "", pipes, record))
                )

    @ classmethod
    def printTable(cls, records, tokens, indent=0, header=True):

        children = []

        for index, token in enumerate(tokens["children"]):
            if (
                not cls.shouldHidden(token, index=index)
                and not "HIDE_IN_TABLE" in token["pipes"]
            ):
                children.append(token)

        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        bodies = []
        widths = [[0] * (len(children) + 1)]
        if header:
            bodies = [
                [Pipe.apply("序号", ["yellow"])]
                + list(
                    map(
                        lambda child: str(
                            Pipe.apply(
                                child.get("label", child["key"]), [
                                    "yellow", "italic"]
                            )
                        ),
                        children,
                    )
                )
            ]
            widths = [
                list(map(lambda e: Unicode.simpleWidth(trim_ansi(e)), bodies[0]))]

        maxWidths = widths[0].copy()

        global OFFSET
        for i, record in enumerate(records):
            bodies.append([Pipe.apply(str(i + 1 + OFFSET), ["dim", "italic"])])
            widths.append([len(str(i + 1))])
            for j, child in enumerate(children):
                "index" in child["pipes"] and child["pipes"].remove("index")
                text = str(
                    cls.applyPipes(
                        cls.retrieve(record["__"], child,
                                     ""), child["pipes"], record
                    )
                )
                bodies[-1].append(text)
                widths[-1].append(Unicode.simpleWidth(trim_ansi(text)))
                maxWidths[j + 1] = max(widths[-1][-1], maxWidths[j + 1])
        for i, body in enumerate(bodies):
            for j, text in enumerate(body):
                scopedStdout(text + " " * (maxWidths[j] - widths[i][j] + 4))
            sys.stdout.write("\n")

    @ classmethod
    def output(cls, fmt, data, file=None):
        # print(data)
        if fmt.startswith(":") and not isinstance(data, list):
            data = [data]
        tokens = cls.getTokens(fmt)
        # print(json.dumps(tokens, indent=2))
        records = cls.getValue(data, tokens)
        # print(json.dumps(records, indent=2))
        # flatted = cls.flatTokens(tokens)
        global SHOULD_STORE
        if file and SHOULD_STORE:
            global STORAGE_FILE
            STORAGE_FILE = file
            with open(file, "w") as f:
                f.write(json.dumps(records))

        if not records:
            return print("没有数据")

        records = Pipe.apply(records, pipes=tokens["pipes"], data=data)

        if not records:
            return

        global TABLE, NO_TABLE, TABLE_NO_HEADER

        if (TABLE or "TABLE" in tokens["pipes"]) and not NO_TABLE:
            cls.printTable(records, tokens, header=not TABLE_NO_HEADER)
        else:
            # for record in records:
            #     cls.printRecord(record, flatted)
            #     sys.stdout.write("-" * 50 + "\n")
            for record in records:
                for token in tokens["children"]:
                    Parser.printToken(record, token)
                sys.stdout.write("-" * 50 + "\n")

    @ classmethod
    def printToken(cls, data, token: dict, indent=0, INDENT=2):
        key = token.get("key")
        pipes = token.get("pipes")
        label = token.get("label")
        children = token.get("children")
        rawValue = data.get(key) if data else None
        useDowngrade = "DOWNGRADE" in pipes
        useTable = "TABLE" in pipes
        value = cls.applyPipes(rawValue, pipes, data, signed=False)
        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        scopedStdout(
            "{}: ".format(
                Pipe.apply(label if label is not None else key,
                           ["yellow", "italic"])
            )
        )
        if cls.shouldHidden(token):
            return
        if useDowngrade:
            indent -= max(indent, INDENT)
        if children:
            if isinstance(value, list):
                scopedStdout("\n")
                if useTable:
                    cls.printTable(value, token, indent + INDENT)
                else:
                    for val in value:
                        for child in children:
                            cls.printToken(
                                val, child, indent=indent + INDENT, INDENT=INDENT
                            )
                        scopedStdout(" " * INDENT + "-" * 50 + "\n")
            else:
                for child in children:
                    cls.printToken(value, child, indent=indent +
                                   INDENT, INDENT=INDENT)
        elif isinstance(value, list):
            for item in value:
                scopedStdout("\n")
                scopedStdout("{}\n".format(item))
        else:
            scopedStdout("{}\n".format(value))

        scopedStdout(cls.applyPipes("", pipes, data, signed=True))


if __name__ == "__main__":
    import sys

    fmt = sys.argv[1]
    file = sys.argv[2]
    data = ""
    for line in sys.stdin:
        data += line
    try:
        data = json.loads(data.rstrip())
    except Exception as e:
        print(data)
        print(e)
    Parser.output(fmt, data, file)
