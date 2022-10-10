# coding=utf-8

import json
import sys
class Node:
    def __init__(self, parent = None):
        self.data = {}
        self.data['key'] = parent.data['key'] + ':' if parent else ''
        self.data['keys'] = []
        self.data['pipes'] = []
        self.data['labels'] = []
        self.data['label'] = ''
        self._key = ''
        self._piped = False
        self._labeled = False

        if parent:
            parent.append(self)

    def key(self, token, skipKeys = False):
        if not skipKeys:
            self._key += token
        if not (self._piped or self._labeled):
            self.data['key'] += token

    def pipe(self):
        self._piped = not self._piped

    def label(self, flag):
        if flag:
            self.keys()
        else:
            self.data['labels'].append(self._key)
            self.data['label'] = self._key
            self._key = ''
        self._labeled = flag

    def keys(self):
        if self._labeled:
            return
        elif self._piped:
            self.data['pipes'].append(self._key)
            self._piped = False
        elif self._key:
            self.data['keys'].append(self._key)
        self._key = ''

    def iter(self):
        if self._labeled:
            return
        self.data['iterKey'] = self.data['key']
        self.data['iterKeys'] = self.data['keys']
        self.data['keys'] = []

    def append(self, node = None):
        if self._labeled:
            return
        if node:
            node._parent = self
            self.data['children'] = self.data.get('children') or []
            self.data['children'].append(node.data)
        else:
            node = Node(self)
        return node

    def next(self, node = None):
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
    index = 0
    length = len(fmt)
    while index < length:
        token = fmt[index]
        if escaped:
            node.key(token)
            escaped = False
        # escape
        elif token == '\\':
            escaped = True
        # label
        elif not node._labeled and token == '(':
            node.label(True)
        elif node._labeled and token == ')':
            node.label(False)
        # list
        elif token == ':':
            node.keys()
            node = node.append()
        # label
        elif token == '.':
            node.key(token, True)
            node.keys()
        # pipe
        elif token == '|':
            node.keys()
            node.pipe()
        # next property
        elif token == ',':
            node.keys()
            node = node.next()
        # parent
        elif token == ';':
            node.keys()
            node = node.parent()
            node = node.next()
        # iterate
        elif token == '*':
            if fmt[index + 1] == '.':
                index += 1
                node.keys()
                node.iter()
                node.key('*.', True)
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
        else: return default
    return obj

class Pipe:
    @classmethod
    def apply(cls, value, pipes):
        for pipe in pipes:
            value = cls[pipe](value)
        return value
    @classmethod
    def date(v):
        return
    @classmethod
    def red(v):
        return '\033[31m{}\033[0m'.format(v)
    @classmethod
    def green(v):
        return '\033[32m{}\033[0m'.format(v)
    @classmethod
    def blue(v):
        return '\033[33m{}\033[0m'.format(v)

class Parser:

    @classmethod
    def getTokens(cls, fmt):
        return tokenize(fmt).data

    @classmethod
    def retrieve(cls, data, node):
        data = retrieve(data, node['keys'])
        result = data
        if 'pipes' in node:
            for pipe in node['pipes']:
                result = Pipe[pipe](result, data)
        return result

    @classmethod
    def getValue(cls, data, node):
        if data and 'iterKeys' in node:
            items = retrieve(data, node['iterKeys'], [])
            items = items.values() if isinstance(items, dict) else items
            return [retrieve(item, node['keys']) for item in items]

        data = cls.retrieve(data, node)
        if data and 'children' in node:
            data = data.values() if isinstance(data, dict) else data
            results = []
            for item in data:
                result = {}
                results.append(result)
                for child in node['children']:
                    value = cls.getValue(item, child) if 'children' in child or 'iterKeys' in child else cls.retrieve(item, child)
                    result[child['key']] = value
            return results

    @classmethod
    def flatTokens(cls, tokens):
        flatted = {}
        flatted[tokens['key']] = tokens
        if 'children' in tokens:
            for child in tokens['children']:
                flatted.update(cls.flatTokens(child))
        return flatted

    @classmethod
    def applyPipes(cls, value, pipes):
        return Pipe.apply(value, pipes)

    @classmethod
    def printValue(cls, value, meta, indent=0):
        red = lambda v: '\033[31m{}\033[0m'.format(v or '~')
        green = lambda v: '\033[32m{}\033[0m'.format(v or '~')
        blue = lambda v: '\033[33m{}\033[0m'.format(v or '~')
        scopedStdout = lambda *args: sys.stdout.write(' ' * indent + ''.join(list(*args)))
        if isinstance(value, list):
            scopedStdout('\n')
            for item in value: cls.printValue(item, meta, indent + 2)
        elif isinstance(value, dict):
            for (key, val) in value.items():
                label = meta[key]['label']
                scopedStdout('{}: '.format(red(label)))
                if isinstance(val, (list, dict)):
                    cls.printValue(val, meta, indent + 2)
                else:
                    sys.stdout.write('{}\n'.format(cls.applyPipes(val, meta[key]['pipes'])))
        else:
            scopedStdout('{}\n'.format(cls.applyPipes(value, meta['pipes'])))

    @classmethod
    def print(cls, fmt, data):
        tokens = cls.getTokens(fmt)
        records = cls.getValue(data, tokens)
        flatted = cls.flatTokens(tokens)
        for record in records:
            cls.printValue(record, flatted)
            sys.stdout.write('\n------------------\n\n')


if __name__ == '__main__':
    import sys
    fmt = sys.argv[1]
    data = ''
    for line in sys.stdin: data += line
    # data = data.replace('\\', '\\\\')
    data = json.loads(data)
    # tokens = Parser.getTokens(fmt)
    # records = Parser.getValue(data, tokens)
    # print(json.dumps(tokens, indent=2))
    # print(json.dumps(records, indent=2))
    Parser.print(fmt, data)
