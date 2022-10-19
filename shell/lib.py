# coding=utf-8

from curses.ascii import isdigit
import json
import sys
import re
import os
import time
from urllib import request

IMGCAT = False
SIMPLE = False

if os.environ.get("IMGCAT", None):
    IMGCAT = True

if os.environ.get("SIMPLE", None):
    SIMPLE = True

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
            pipe = self.data["pipes"].pop()
            if isinstance(pipe, list):
                pipe.append(self._key)
            else:
                pipe = [pipe, self._key]
            self.data["pipes"].append(pipe)
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
        # 下级对象
        elif token == ":":
            if not node.usingArgs:
                node.keys()
                node = node.append()
        # 属性路径
        elif token == ".":
            if not node.usingArgs:
                node.token(token, True)
                node.keys()
        # 管道（函数）
        elif token == "|":
            if not node.usingArgs:
                node.keys()
                node.pipe()
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
            if key.isdigit() and isinstance(obj, list):
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
    return obj


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
    def apply(cls, v, pipes, data={}):
        for pipe in pipes:
            args = []
            if isinstance(pipe, list):
                args = pipe[1:]
                pipe = pipe[0]
            attr = getattr(cls, pipe, None)
            v = (
                attr(v, *args, data=data)
                if attr
                else re.sub(r"\{([^\}]+)\}", lambda m: data.get(m.group(1), ""), pipe)
            )
        return v

    @classmethod
    def date(cls, v, *args, **kwargs):
        if v.isdigit() or isinstance(v, int):
            v = int(v)
            v = v / 1000 if len(str(v)) == 13 else v
            return time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(v))
        else:
            # time.strptime(v, '')
            return v
        return

    @classmethod
    def number(cls, v, type=',', *args, **kwargs):
        if not v: return v
        if type == ',':
            return '{:,}'.format(v)
        elif type == '%':
            return '{:.2%}'.format(v)
        elif type == '+%':
            return '{:+.2%}'.format(v)
        else:
            return type.format(v)

    @classmethod
    def style(cls, v, styles=[], *args, **kwargs):
        codes = []
        for style in styles:
            if style in cls.STYLES:
                codes.append(cls.STYLES[style])
        return "\033[" + ";".join(codes) + f"m{v}\033[0m"

    @classmethod
    def red(cls, v, *args, **kwargs):
        return cls.style(v, styles=["red"])

    @classmethod
    def green(cls, v, *args, **kwargs):
        return cls.style(v, styles=["green"])

    @classmethod
    def yellow(cls, v, *args, **kwargs):
        return cls.style(v, styles=["yellow"])

    @classmethod
    def blue(cls, v, *args, **kwargs):
        return cls.style(v, styles=["blue"])

    @classmethod
    def magenta(cls, v, *args, **kwargs):
        return cls.style(v, styles=["magenta"])

    @classmethod
    def cyan(cls, v, *args, **kwargs):
        return cls.style(v, styles=["cyan"])

    @classmethod
    def white(cls, v, *args, **kwargs):
        return cls.style(v, styles=["white"])

    @classmethod
    def bold(cls, v, *args, **kwargs):
        return cls.style(v, styles=["bold"])

    @classmethod
    def dim(cls, v, *args, **kwargs):
        return cls.style(v, styles=["dim"])

    @classmethod
    def italic(cls, v, *args, **kwargs):
        return cls.style(v, styles=["italic"])

    @classmethod
    def underline(cls, v, *args, **kwargs):
        return cls.style(v, styles=["underline"])

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
            cls._image(re.sub(r"\/orj\d+\/", "/orj180/", v))
        return v

    @classmethod
    def prepend(cls, v, text="", *args, **kwargs):
        return text + v

    @classmethod
    def index(cls, v, *args, **kwargs):
        index = kwargs.get("data", {}).get("__index", "")
        return cls.white(f"【{index}】") + v

    @classmethod
    def newline(cls, v, number=1, *args, **kwargs):
        number = int(number)
        return "\n" * -number + v if number < 0 else v + "\n" * number

    @classmethod
    def join(cls, v, delimiter=', ', number=1, *args, **kwargs):
        return delimiter.join(v) if isinstance(v, list) else v


class Parser:
    @classmethod
    def getTokens(cls, fmt):
        return tokenize(fmt).data

    @classmethod
    def retrieve(cls, data, node):
        return retrieve(data, node["keys"])

    @classmethod
    def getValue(cls, data, node):
        if data and "iterKeys" in node:
            items = retrieve(data, node["iterKeys"], [])
            items = items.values() if isinstance(items, dict) else items
            return [retrieve(item, node["keys"]) for item in items]

        data = cls.retrieve(data, node)
        if data and "children" in node:
            data = data.values() if isinstance(data, dict) else data
            results = []
            for item in data:
                result = {}
                results.append(result)
                for child in node["children"]:
                    value = (
                        cls.getValue(item, child)
                        if "children" in child or "iterKeys" in child
                        else cls.retrieve(item, child)
                    )
                    result[child["key"]] = value
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
        return Pipe.apply(value, pipes, data)

    def applyListPipes(cls, value, pipes, data):
        return Pipe.apply(value, pipes, data)

    @classmethod
    def printRecord(cls, record, meta, indent=0):
        global SIMPLE
        INDENT = 2
        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        index = 0
        for (key, val) in record.items():
            index += 1

            if key.startswith("__"):
                continue

            label = meta[key].get("label", key)

            if SIMPLE and index != 1 and label not in ['链接']: continue

            scopedStdout("{}: ".format(Pipe.apply(label, ["yellow", "italic"])))

            if isinstance(val, dict):
                cls.printRecord(val, meta, indent + INDENT)

            elif isinstance(val, list):
                scopedStdout("\n")

                for item in val:
                    if isinstance(item, dict):
                        cls.printRecord(item, meta, indent + INDENT)
                    else:
                        scopedStdout(
                            "  {}\n".format(
                                Pipe.green(
                                    cls.applyPipes(
                                        item or "", meta[key]["pipes"], record
                                    )
                                )
                            )
                        )
            else:
                sys.stdout.write(
                    "{}\n".format(
                        Pipe.green(
                            cls.applyPipes(val or "", meta[key]["pipes"], record)
                        )
                    )
                )

    @classmethod
    def output(cls, fmt, data):
        # print(data)
        if fmt.startswith(":") and not isinstance(data, list):
            data = [data]
        tokens = cls.getTokens(fmt)
        # print(json.dumps(tokens, indent=2))
        records = cls.getValue(data, tokens)
        # print(json.dumps(records, indent=2))
        flatted = cls.flatTokens(tokens)

        if not records:
            return print('没有数据')

        for i, record in enumerate(records):
            record["__index"] = i + 1
            cls.printRecord(record, flatted)
            sys.stdout.write("\n" + "-" * 50 + "\n\n")


if __name__ == "__main__":
    import sys

    fmt = sys.argv[1]
    # fmt = "statuses:(内容)text_raw|red|bold|newline(-1)|index,(来源)source,(博主)user.screen_name,(空间)user.idstr,(地址)mblogid|$https://weibo.com/{statuses:user.idstr}/{statuses:mblogid}$,(地区)region_name,(视频封面)page_info.page_pic|image,(视频)page_info.media_info.mp4_sd_url,(图片)pic_infos*.original.url|image"
    data = ""
    for line in sys.stdin:
        data += line
    try:
        data = json.loads(data)
    except:
        print(data)
    Parser.output(fmt, data)
