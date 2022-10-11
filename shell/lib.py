# coding=utf-8

import json
import sys
import re
import os
from urllib import request

try:
    IMGCAT = True
    from imgcat import imgcat
except:
    IMGCAT = False


class Node:
    def __init__(self, parent=None):
        self.data = {}
        self.data["key"] = parent.data["key"] + ":" if parent else ""
        self.data["keys"] = []
        self.data["pipes"] = []
        self.data["labels"] = []
        self.data["label"] = ""
        self._key = ""
        self._piped = False
        self._labeled = False

        if parent:
            parent.append(self)

    def key(self, token, skipKeys=False):
        if not skipKeys:
            self._key += token
        if not (self._piped or self._labeled):
            self.data["key"] += token

    def pipe(self):
        self._piped = not self._piped

    def label(self, flag):
        if flag:
            self.keys()
        else:
            self.data["labels"].append(self._key)
            self.data["label"] = self._key
            self._key = ""
        self._labeled = flag

    def keys(self):
        if self._labeled:
            return
        elif self._piped:
            self.data["pipes"].append(self._key)
            self._piped = False
        elif self._key:
            self.data["keys"].append(self._key)
        self._key = ""

    def iter(self):
        if self._labeled:
            return
        self.data["iterKey"] = self.data["key"]
        self.data["iterKeys"] = self.data["keys"]
        self.data["keys"] = []

    def append(self, node=None):
        if self._labeled:
            return
        if node:
            node._parent = self
            self.data["children"] = self.data.get("children") or []
            self.data["children"].append(node.data)
        else:
            node = Node(self)
        return node

    def next(self, node=None):
        if self._labeled:
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
        # raw
        if token == "$" and not escaped:
            raw = not raw
        elif raw:
            node.key(token)
        elif escaped:
            node.key(token)
            escaped = False
        # escape
        elif token == "\\":
            escaped = True
        # label
        elif not node._labeled and token == "(":
            node.label(True)
        elif node._labeled and token == ")":
            node.label(False)
        # list
        elif token == ":":
            node.keys()
            node = node.append()
        # label
        elif token == ".":
            node.key(token, True)
            node.keys()
        # pipe
        elif token == "|":
            node.keys()
            node.pipe()
        # next property
        elif token == ",":
            node.keys()
            node = node.next()
        # parent
        elif token == ";":
            node.keys()
            node = node.parent()
            node = node.next()
        # iterate
        elif token == "*":
            if fmt[index + 1] == ".":
                index += 1
                node.keys()
                node.iter()
                node.key("*.", True)
            else:
                node.key(token)
        else:
            node.key(token)
        index += 1
    node.keys()
    return root


def retrieve(obj, keys, default=None):
    for key in keys:
        if obj and key in obj:
            obj = obj[key]
        else:
            return default
    return obj


class Pipe:
    @classmethod
    def apply(cls, value, pipes, data):
        for pipe in pipes:
            attr = getattr(cls, pipe, None)
            value = (
                attr(value)
                if attr
                else re.sub(r"\{([^\}]+)\}", lambda m: data.get(m.group(1), ""), pipe)
            )
        return value

    @classmethod
    def date(cls, v):
        return

    @classmethod
    def red(cls, v):
        return "\033[31m{}\033[0m".format(v)

    @classmethod
    def green(cls, v):
        return "\033[32m{}\033[0m".format(v)

    @classmethod
    def blue(cls, v):
        return "\033[33m{}\033[0m".format(v)

    @classmethod
    def bold(cls, v):
        return "\033[1m{}\033[0m".format(v)

    @classmethod
    def _image(cls, v):
        if os.environ.get("ITERM_SESSION_ID", None):
            imgcat(request.urlopen(v).read(), height=7)

    @classmethod
    def image(cls, v):
        global IMGCAT
        if IMGCAT:
            cls._image(v)
        return v


class Parser:
    @classmethod
    def getTokens(cls, fmt):
        return tokenize(fmt).data

    @classmethod
    def retrieve(cls, data, node):
        data = retrieve(data, node["keys"])
        result = data
        # if "pipes" in node:
        #     for pipe in node["pipes"]:
        #         result = getattr(Pipe, pipe)(result)
        return result

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

    @classmethod
    def printRecord(cls, value, meta, indent=0):
        INDENT = 2
        red = lambda v: "\033[31m{}\033[0m".format(v or "~")
        green = lambda v: "\033[32m{}\033[0m".format(v or "~")
        blue = lambda v: "\033[33m{}\033[0m".format(v or "~")
        scopedStdout = lambda *args: sys.stdout.write(
            " " * indent + "".join(list(*args))
        )
        for (key, val) in value.items():
            label = meta[key]["label"]
            scopedStdout("{}: ".format(blue(label)))
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
                                green(cls.applyPipes(item, meta[key]["pipes"], value))
                            )
                        )
            else:
                sys.stdout.write(
                    "{}\n".format(green(cls.applyPipes(val, meta[key]["pipes"], value)))
                )

    @classmethod
    def output(cls, fmt, data):
        tokens = cls.getTokens(fmt)
        records = cls.getValue(data, tokens)
        flatted = cls.flatTokens(tokens)
        for record in records:
            cls.printRecord(record, flatted)
            sys.stdout.write("\n------------------\n\n")


if __name__ == "__main__":
    import sys

    fmt = sys.argv[1]
    data = ""
    for line in sys.stdin:
        data += line
    data = json.loads(data)
    # tokens = Parser.getTokens(fmt)
    # records = Parser.getValue(data, tokens)
    # print(json.dumps(tokens, indent=2))
    # print(json.dumps(records, indent=2))
    Parser.output(fmt, data)
