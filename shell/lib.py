import json

# jsonstr = json.load(open('./weibo.hot.post.json'))

# jsonFormat='statuses:内容(text_raw),来源(source),博主(user.screen_name),空间(user.idstr),地址(mblogid),地区(region_name),视频封面(page_info.page_pic),视频(media_info.mp4_sd_url),图片(pic_infos:原始(original.url),图标(thumbnail.url))'

jsonFormat='statuses:text_raw,source,user.screen_name,user.idstr,mblogid,region_name,page_info.page_pic,media_info.mp4_sd_url,pic_infos:original.url,thumbnail.url;page_info.cards:page_title,page_url;pic_infos*.original.url,page_info.cards*.page_title'

"""
{
  "key": "statuses",
  "keys": [
    "statuses"
  ],
  "children": [
    {
      "key": "text_raw",
      "keys": [
        "text_raw"
      ]
    },
    {
      "key": "source",
      "keys": [
        "source"
      ]
    },
    {
      "key": "user.screen_name",
      "keys": [
        "user",
        "screen_name"
      ]
    },
    {
      "key": "user.idstr",
      "keys": [
        "user",
        "idstr"
      ]
    },
    {
      "key": "mblogid",
      "keys": [
        "mblogid"
      ]
    },
    {
      "key": "region_name",
      "keys": [
        "region_name"
      ]
    },
    {
      "key": "page_info.page_pic",
      "keys": [
        "page_info",
        "page_pic"
      ]
    },
    {
      "key": "media_info.mp4_sd_url",
      "keys": [
        "media_info",
        "mp4_sd_url"
      ]
    },
    {
      "key": "pic_infos",
      "keys": [
        "pic_infos"
      ],
      "children": [
        {
          "key": "original.url",
          "keys": [
            "original",
            "url"
          ]
        },
        {
          "key": "thumbnail.url",
          "keys": [
            "thumbnail",
            "url"
          ]
        }
      ]
    },
    {
      "key": "page_info.cards",
      "keys": [
        "page_info",
        "cards"
      ],
      "children": [
        {
          "key": "page_title",
          "keys": [
            "page_title"
          ]
        },
        {
          "key": "page_url",
          "keys": [
            "page_url"
          ]
        }
      ]
    },
    {
      "key": "original.url",
      "keys": [
        "original",
        "url"
      ],
      "iterKey": "pic_infos",
      "iterKeys": [
        "pic_infos"
      ]
    },
    {
      "key": "page_title",
      "keys": [
        "page_title"
      ],
      "iterKey": "page_info.cards",
      "iterKeys": [
        "page_info",
        "cards"
      ]
    }
  ]
}
"""

class Node:
    def __init__(self, parent = None) -> None:
        self.data = {}
        self.data['key'] = ''
        self.data['keys'] = []
        self.data['pipes'] = []
        self._key = ''
        self._piped = False

        if parent:
            parent.append(self)

    def key(self, token, skipKeys = False):
        if not skipKeys:
            self._key += token
        if not self._piped:
            self.data['key'] += token

    def keys(self):
        if self._piped:
            self.data['pipes'].append(self._key)
            self._piped = False
        elif self._key:
            self.data['keys'].append(self._key)
            self._key = ''

    def iter(self):
        self.data['iterKey'] = self.data['key']
        self.data['iterKeys'] = self.data['keys']
        self.data['key'] = ''
        self.data['keys'] = []

    def pipe(self):
        self._piped = not self._piped

    def parent(self):
        return self._parent

    def append(self, node = None):
        node = node or Node()
        node._parent = self
        self.data['children'] = self.data.get('children') or []
        self.data['children'].append(node.data)
        return node

    def next(self, node = None):
        node = node or Node()
        node._parent = self._parent
        self.parent().append(node)
        return node

class Pipe:
    def date(data):
        return

def tokenize(fmt: str):
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
        # list
        elif token == ':':
            node.keys()
            node = node.append()
        # property
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

class Parser:

    def __init__(self, data, fmt) -> None:
        self.data = data
        self.fmt = fmt

    def getRecords(self):
        tokens = tokenize(self.fmt).data
        return self.getValue(self.data, tokens)

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

if __name__ == '__main__':
    import sys
    data = json.loads(sys.argv[1])
    print(json.dumps(Parser(data, fmt).getRecords(), indent=2))
jsonparser(jsonstr, jsonFormat)
