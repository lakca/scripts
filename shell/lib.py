# coding=utf-8

from datetime import datetime
from functools import cmp_to_key
import json
import sys
import re
import os
import time
from urllib import request

IMGCAT = False
SIMPLE = False
LINK = False

if os.environ.get("IMGCAT", None):
    IMGCAT = True

if os.environ.get("SIMPLE", None):
    SIMPLE = True

if os.environ.get("LINK", None):
    LINK = True

TABLE = os.environ.get("TABLE")

try:
    from imgcat import imgcat
except:
    IMGCAT = False


class Node:
    def __init__(self, parent=None):
        self.data = {}
        # 属性的绝对路径名（属性id）
        self.data["key"] = parent.data["key"] + ":" if parent else ""
        # 属性相对（语法支对象）路径
        self.data["keys"] = []
        # 修饰函数及参数
        self.data["pipes"] = []
        # 字段标签（名称等）
        self.data["labels"] = []
        # 最新的（最后定义的）字段标签
        self.data["label"] = ""
        # 当前分词（语法单元）
        self._key = ""
        self.usingPipe = False
        self.usingLabel = False
        self.usingArgs = False
        self.usingList = False
        self.usingKarg = False

        if parent:
            parent.append(self)

    def token(self, token, ignoreKeys=False):
        # 对于属性id（key）而言，所有token都是必须的；
        if not (self.usingPipe or self.usingLabel or self.usingArgs):
            self.data["key"] += token
        # 但对于属性路径（keys）而言，符号是需要去掉的
        if not ignoreKeys:
            self._key += token

    # 进出管道
    def pipe(self):
        self.usingPipe = not self.usingPipe

    # 进出管道参数
    def args(self):
        self.usingArgs = not self.usingArgs
        if self.usingArgs:
            pipe = self.data["pipes"].pop()
            self.data["pipes"].append([pipe])

    # 进出管道数组类型参数
    def list(self):
        self.usingList = not self.usingList
        if self.usingList:
            prev = self.data["pipes"][-1][-1]
            if isinstance(prev, tuple):
                self.data["pipes"][-1][-1] = (prev[0], [])
            else:
                self.data["pipes"][-1].append([])

    def karg(self):
        self.usingKarg = not self.usingKarg
        if self.usingKarg:
            arg = self.data["pipes"][-1].pop()
            self.data["pipes"][-1].append((arg,))

    # 进出字段标签
    def label(self):
        # 退出标签语法
        if self.usingLabel:
            self.data["labels"].append(self._key)
            self.data["label"] = self._key
            # 重置语法单元内容
            self._key = ""
        # 进入标签语法
        else:
            # 结束上一个语法单元
            self.keys()
        self.usingLabel = not self.usingLabel

    # 切割语法单元
    def keys(self):
        # 如果在标签语法内
        if self.usingLabel:
            return
        # 如果在参数语法内
        elif self.usingArgs:
            # 列表
            if self.usingList:
                if isinstance(self.data["pipes"][-1][-1], tuple):
                    self.data["pipes"][-1][-1][-1].append(self._key)
                else:
                    self.data["pipes"][-1][-1].append(self._key)
            elif self.usingKarg:
                tup = self.data["pipes"][-1][-1]
                arg = tup[0]
                val = tup[1] if len(tup) > 1 else self._key
                if not val:
                    return
                self.data["pipes"][-1].pop()
                if isinstance(self.data["pipes"][-1][-1], dict):
                    self.data["pipes"][-1][-1][arg] = val
                else:
                    obj = dict.fromkeys([arg], val)
                    obj["__kwarg"] = True
                    self.data["pipes"][-1].append(obj)
                self.karg()
            else:
                self.data["pipes"][-1].append(self._key)
        # 如果在管道语法内
        elif self.usingPipe:
            self.data["pipes"].append(self._key)
            self.usingPipe = False
        # 如果在普通语法内（即处于最外层的属性定义语法）
        elif self._key:
            self.data["keys"].append(self._key)
        # 重置语法单元内容
        self._key = ""

    # 注明这之前的语法单元是一个遍历键，而不是属性相对路径
    # 数组类型的深度属性如：colors*.name, colors*.vectors.red
    def iter(self):
        if self.usingLabel or self.usingPipe:
            return
        self.data["iterKey"] = self.data["key"]
        self.data["iterKeys"] = self.data["keys"]
        self.data["keys"] = []

    def append(self, node=None):
        if self.usingLabel:
            return
        if node:
            node._parent = self
            self.data["children"] = self.data.get("children") or []
            self.data["children"].append(node.data)
        else:
            node = Node(self)
        return node

    def next(self, node=None):
        if self.usingLabel:
            return
        if node:
            self.parent().append(node)
        else:
            node = Node(self.parent())
        return node

    def parent(self):
        return self._parent


def tokenize(fmt):
    root = Node()
    node = root
    escaped = False
    raw = False
    index = 0
    length = len(fmt)
    while index < length:
        token = fmt[index]
        # 魔术语法，纯字面量
        if token == "$" and not escaped:
            raw = not raw
        elif raw:
            node.token(token)
        elif escaped:
            node.token(token)
            escaped = False
        # 转义
        elif token == "\\":
            escaped = True
        # 属性标签、管道参数
        elif token == "(":
            # 管道参数
            if node.usingPipe and not node.usingArgs:
                node.keys()
                node.args()
            # 属性标签
            elif not node.usingLabel:
                node.keys()
                node.label()
        elif token == ")":
            if node.usingArgs:
                node.keys()
                node.args()
            elif node.usingLabel:
                node.keys()
                node.label()
        # 命名参数
        elif token == "=":
            if node.usingArgs and not node.usingList:
                node.keys()
                node.karg()
            else:
                node.token(token)
        # 数组
        elif token == "[" or token == "]":
            if node.usingArgs:
                node.keys()
                node.list()
            else:
                node.token(token)
        # 下级对象
        elif token == ":":
            if node.usingArgs:
                node.token(token)
            else:
                node.keys()
                node = node.append()
        # 属性路径
        elif token == ".":
            if node.usingArgs:
                node.token(token)
            else:
                node.token(token, True)
                node.keys()
        # 管道（函数）
        elif token == "|":
            if not node.usingArgs:
                node.keys()
                node.pipe()
                if fmt[index + 1] == "$":
                    index += 1
                    node.token("$")
                    raw = True
        # 分割同级（属性、参数...）
        elif token == ",":
            node.keys()
            if not node.usingArgs:
                node = node.next()
        # 分割父级（结束当前级别的分支对象）
        elif token == ";":
            if not node.usingArgs:
                node.keys()
                node = node.parent()
                node = node.next()
        # 遍历键
        elif token == "*":
            if not node.usingArgs:
                if fmt[index + 1] == ".":
                    index += 1
                    node.keys()
                    node.iter()
                    node.token("*.", True)
                else:
                    node.token(token)
        else:
            node.token(token)
        index += 1
    node.keys()
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
    def apply(cls, v, pipes, data={}, **opts):
        for pipe in pipes:
            if pipe == "true" and not v:
                return v
            args = []
            kwargs = {}
            if isinstance(pipe, list):
                for e in pipe[1:]:
                    if isinstance(e, dict) and e["__kwarg"]:
                        kwargs = e
                    else:
                        args.append(e)
                pipe = pipe[0]

            if "interpolate" in opts and pipe.startswith(opts["interpolate"]):
                v = cls._interpolate(pipe[1:], data)
            else:
                attr = getattr(cls, pipe, None)
                if attr:
                    v = attr(v, *args, data=data, **kwargs)

        return v

    @classmethod
    def _interpolate(cls, template, data, *args, **kwargs):
        def replacer(m):
            token = tokenize(m.group(1)).data
            key = token["key"]
            keys = token["keys"]
            if key.startswith("."):
                value = str(retrieve(data.get("__", ""), key.split(".")[1:], ""))
            else:
                value = str(retrieve(data, keys, ""))
            return cls.apply(value, token["pipes"], data)

        return re.sub(r"\{([^\}]+)\}", replacer, template)

    @classmethod
    def date(cls, v, *args, **kwargs):
        sv = str(v)
        try:
            nv = float(v)
        except:
            pass
        for case in (
            # timestamp 1667632623
            lambda: datetime.fromtimestamp(nv / 1000 if nv > 9999999999 else nv),
            # ISO 2022-11-01T00:00:00, 2022-11-01 00:00:00 ...
            lambda: datetime.fromisoformat(sv),
            # UTC "Tue, 18 Oct 2022 23:00:23 +0800"
            lambda: datetime.strptime(sv, "%a, %d %b %Y %H:%M:%S %z"),
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
                kwargs.get("format") or (len(args) and args[0]), "%Y-%m-%d %H:%M:%S"
            ),
        )

    @classmethod
    def toNumber(cls, v, *args, **kwargs):
        """v: str<int|float>"""
        return v if isinstance(v, (int, float)) else float(v) if "." in v else int(v)

    @classmethod
    def numberOf(cls, v, *args, **kwargs):
        """v: str<number + any>"""
        v = re.sub(r"[^\d]*$", "", str(v))
        return cls.toNumber(v)

    @classmethod
    def number(cls, v, type=",", *args, **kwargs):
        if not v:
            return v
        v = cls.toNumber(v)

        if type == ",":
            return "{:,}".format(v)
        elif type == "%":
            return "{:.2%}".format(v)
        elif type == "+%":
            return "{:+.2%}".format(v)
        elif type == "+":
            return "{:+.2f}".format(v)
        elif type == "cn":
            for e in ["", "万", "亿", "兆"]:
                if abs(v) > 10000:
                    v = v / 10000
                else:
                    return str(v) + e if isinstance(v, int) else "{:.4f}".format(v) + e
        else:
            return type.format(v)

    @classmethod
    def indicator(cls, v, *args, **kwargs):
        data = kwargs.get("data")
        interpolate = lambda tpl: cls._interpolate(str(tpl), data) if data else tpl
        ops = []
        if "cmp" in kwargs:
            ops = [cls.numberOf(interpolate(kwargs["cmp"])), 0]
        elif len(args):
            if len(args) == 1:
                ops = [float(v), float(interpolate(args[0]))]
            else:
                ops = [float(interpolate(args[0])), float(interpolate(args[1]))]
        else:
            ops = [cls.numberOf(v), 0]
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
        return cls.white(f"【{index}】") + v

    @classmethod
    def newline(cls, v, number=1, *args, **kwargs):
        number = int(number)
        return "\n" * -number + v if number < 0 else v + "\n" * number

    @classmethod
    def join(cls, v, delimiter=", ", *args, **kwargs):
        return delimiter.join(v) if isinstance(v, list) else v

    @classmethod
    def hr(cls, v, dividing="-" * 50 + "\n", *args, **kwargs):
        return v + dividing

    @classmethod
    def sort(cls, v, *args, **kwargs):
        if not v:
            return v
        useKwargs = {}
        if kwargs["key"]:
            getVal = lambda e: e[kwargs["key"]]
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
        if isinstance(v, list):
            v.reverse()
        return v

    @classmethod
    def _getLeftStyleANSI(cls, text, *args, **kwargs):
        text = str(text)
        start = kwargs.get("start", 0)
        end = kwargs.get("end", len(text) - 1)
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
        regTag = re.compile(r"<(\w+)(\s+[^>]*)*>([\s\S]*?)</\1>")
        start = 0
        # print(text)
        # print(repr(text))
        def replacer(match):
            nonlocal start
            nonlocal text
            end = match.start()
            ansi = cls._getLeftStyleANSI(text, start=start, end=end)
            start = end
            return "\033[7m" + match.group(3) + "\033[0m" + "".join(ansi)

        return regTag.sub(replacer, text)

    @classmethod
    def striptags(cls, v, *args, **kwargs):
        return re.sub(r"</?\w+(\s+[^>]*)*>", "", str(v))

    @classmethod
    def slice(cls, v, *args, **kwargs):
        return v[slice(*list(map(lambda e, *argss: int(e), args)))]


def trim_ansi(a):
    ESC = r"\x1b"
    CSI = ESC + r"\["
    OSC = ESC + r"\]"
    CMD = "[@-~]"
    ST = ESC + r"\\"
    BEL = r"\x07"
    pattern = (
        "(" + CSI + ".*?" + CMD + "|" + OSC + ".*?" + "(" + ST + "|" + BEL + ")" + ")"
    )
    return re.sub(pattern, "", a)


xxx = False


class Parser:
    @classmethod
    def getTokens(cls, fmt):
        return tokenize(fmt).data

    @classmethod
    def retrieve(cls, data, node):
        return retrieve(data, node["keys"])

    @classmethod
    def getValue(cls, data, node):
        if "iterKeys" in node:
            if data:
                items = retrieve(data, node["iterKeys"], [])
                items = items.values() if isinstance(items, dict) else items
                return [retrieve(item, node["keys"]) for item in items]
            else:
                return []

        data = cls.retrieve(data, node)

        results = []

        if "children" in node:
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

    @classmethod
    def flatTokens(cls, tokens):
        flatted = {}
        flatted[tokens["key"]] = tokens
        if "children" in tokens:
            for child in tokens["children"]:
                flatted.update(cls.flatTokens(child))
        return flatted

    @classmethod
    def applyPipes(cls, value, pipes, data):
        return Pipe.apply(value, pipes, data, interpolate="$")

    @classmethod
    def shouldHidden(cls, token, index):
        key = token.get("key", "")
        pipes = token.get("pipes", [])
        label = token.get("label", key)
        global SIMPLE
        return "HIDE" in pipes or (
            SIMPLE
            and index != 0
            and not (LINK and label in ["链接"])
            and "SIMPLE" not in pipes
        )

    @classmethod
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

            if cls.shouldHidden(meta[key], index):
                continue

            pipes = meta[key].get("pipes", [])
            labeled = len(meta[key].get("labels"))
            label = meta[key].get("label")
            downgrade = "DOWNGRADE" in pipes

            if downgrade:
                indent -= INDENT

            if labeled:
                scopedStdout("{}: ".format(Pipe.apply(label, ["yellow", "italic"])))

            if isinstance(val, dict):
                cls.printRecord(val, meta, indent + INDENT)

            elif isinstance(val, list):
                scopedStdout("\n")

                if "TABLE" in pipes and TABLE != "0":
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

    @classmethod
    def printTable(cls, records, tokens, indent=0):

        children = []

        for index, token in enumerate(tokens["children"]):
            if not cls.shouldHidden(token, index):
                children.append(token)

        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        bodies = [
            [Pipe.apply("序号", ["yellow"])]
            + list(
                map(
                    lambda child: str(
                        Pipe.apply(
                            child.get("label", child["key"]), ["yellow", "italic"]
                        )
                    ),
                    children,
                )
            )
        ]
        widths = [list(map(lambda e: Unicode.simpleWidth(trim_ansi(e)), bodies[0]))]
        maxWidths = widths[0].copy()

        for i, record in enumerate(records):
            bodies.append([Pipe.apply(str(i + 1), ["dim", "italic"])])
            widths.append([len(str(i + 1))])
            for j, child in enumerate(children):
                "index" in child["pipes"] and child["pipes"].remove("index")
                text = str(
                    cls.applyPipes(
                        retrieve(record, [child["key"]], ""), child["pipes"], record
                    )
                )
                bodies[-1].append(text)
                widths[-1].append(Unicode.simpleWidth(trim_ansi(text)))
                maxWidths[j + 1] = max(widths[-1][-1], maxWidths[j + 1])
        for i, body in enumerate(bodies):
            for j, text in enumerate(body):
                scopedStdout(text + " " * (maxWidths[j] - widths[i][j] + 4))
            sys.stdout.write("\n")

    @classmethod
    def output(cls, fmt, data, file):
        # print(data)
        if fmt.startswith(":") and not isinstance(data, list):
            data = [data]
        tokens = cls.getTokens(fmt)
        # print(json.dumps(tokens, indent=2))
        records = cls.getValue(data, tokens)
        # print(json.dumps(records, indent=2))
        flatted = cls.flatTokens(tokens)

        if file:
            with open(file, "w") as f:
                f.write(json.dumps(records))

        if not records:
            return print("没有数据")

        records = Pipe.apply(records, tokens["pipes"])

        global TABLE

        if ("TABLE" in tokens["pipes"] and TABLE != "0") or TABLE == "1":
            cls.printTable(records, tokens)
        else:
            for i, record in enumerate(records):
                cls.printRecord(record, flatted)
                sys.stdout.write("-" * 50 + "\n")


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
