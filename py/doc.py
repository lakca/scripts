import types
import inspect
from os import stat, system
from requests import get
from urllib.parse import urljoin
from bs4 import BeautifulSoup
from tabulate import tabulate
import wcwidth
from utils import browserCmd, print_list, colorful


def lower(*s):
    r = tuple([e.lower() if e else e for e in s])
    return r[0] if len(s) < 2 else r


class Query:

    urls = [
        ['beautifulsoup', 'bs4', 'https://www.crummy.com/software/BeautifulSoup/bs4/', ],
        ['nodejs', 'node', 'https://nodejs.org/api/index.html', ],
        ['rust', 'https://doc.rust-lang.org/book/', ],
        ['crates', 'crate', 'https://docs.rs', ],
        ['bash', 'shell', 'https://www.gnu.org/software/bash/manual/bash.html', ],
        ['mdn', 'https://developer.mozilla.org/zh-CN/', ],
        ['ecma262', 'es', 'https://www.ecma-international.org/publications-and-standards/standards/ecma-262/', ],
        ['es5', 'https://262.ecma-international.org/5.1/', ],
        ['es6', 'https://262.ecma-international.org/6.0/', ],
        ['python', 'py', 'https://docs.python.org/3/reference/index.html', ],
    ]

    @classmethod
    def get_types(cls):
        for url in cls.urls:
            yield ', '.join(url[:-1])
        for name in dir(cls):
            if name.startswith('q_') and inspect.ismethod(getattr(cls, name)):
                yield name

    @staticmethod
    def soup_from(url):
        resp = get(url)
        return (BeautifulSoup(resp.text, 'lxml'), resp)

    @staticmethod
    def open(url, urls=[]):
        if url:
            system(f'{browserCmd} {url}')
        for url in urls:
            system(f'{browserCmd} {url}')

    @staticmethod
    def print(rows, cfg):
        cfg = cfg or {}
        cols = cfg.get('cols', [])
        if cfg.get('table', False):
            print(tabulate(rows, cols, tablefmt="grid"))
        else:
            print_list([[row.get(col, None)
                       for col in cols] for row in rows], cols)

    def query(self, type, query, opts):
        lowertype = lower(type)
        method = f'q_{lowertype}'
        if hasattr(self, method):
            rows, cfg = getattr(self, method)(query, opts)
        if len(rows) > 1:
            return self.print(rows, cfg)
        elif len(rows) == 1:
            return self.open(rows[0].get('url'))
        else:
            for url in self.urls:
                if lowertype in url:
                    return self.open(url[-1])
        print('Not Found')

    def q_crate(self, query, opts={}):
        soup, resp = self.soup_from(
            f'https://docs.rs/releases/search?query={query}')
        rows = []
        cfg = {
            'table': False,
            'cols': ['crate', 'description', 'url'],
        }
        for e in soup.find_all(class_="release"):
            row = {
                'url': urljoin(resp.url, e.attrs.get('href')),
                'name': e.find(class_='name').text.strip(),
                'description': e.find(class_='description').text.strip(),
                'date': e.find(class_='date').text.strip(),
            }
            crate, _, version = row.get('name').rpartition('-')
            row['crate'] = crate
            row['version'] = version
            lowername, lowercrate, lowerquery = lower(
                row.get('name'), row.get('crate'), query)
            if not opts.get('exact') or lowername == lowerquery or lowercrate == lowerquery:
                rows.append(row)
        return (rows, cfg)

    def q_node(self, query, opts):
        soup, resp = self.soup_from('https://nodejs.org/api/index.html')
        rows = []
        cfg = {
            'cols': ['name', 'url'],
        }
        for e in soup.select('#apicontent ul:nth-of-type(2) li a'):
            name = e.text.strip()
            url = urljoin(resp.url, e.attrs.get('href'))
            lowername, lowerquery = lower(name, query)
            if (opts.get('exact') and lowerquery == lowername) or (not opts.get('exact') and lowerquery in lowername):
                rows.append({
                    'name': name,
                    'url': url,
                })

        return (rows, cfg)

    def q_mdn(self, query, opts):
        locale = 'en-US'
        if opts.get('en'):
            locale = 'en-US'
        if opts.get('zh') or opts.get('cn'):
            locale = 'zh-CN'
        filters = opts.get('filters')
        resp = get(
            f'https://developer.mozilla.org/api/v1/search?q={query}&locale={locale}')
        rows = []
        cfg = {
            'table': False,
            'cols': ['name', 'summary', 'url'],
        }
        for e in resp.json().get('documents', []):
            mdn_url = e.get('mdn_url', '').lower()[7:]
            for f in filters:
                if f not in mdn_url:
                    break
            else:
                rows.append({
                    'name': e.get('title', ''),
                    'url': urljoin(resp.url, e.get('mdn_url', '')),
                    'summary': e.get('summary', ''),
                })

        return (rows, cfg)


if __name__ == '__main__':
    from sys import argv
    type = None
    query = None
    opts = {}
    opts['filters'] = []
    if '-h' in argv:
        print('打开文档：doc.py :{type} [::{opt}...] [@{filter}...]')
        print(f'    {colorful("type", "red")}: ')
        for type in Query.get_types():
            print('          ' + colorful(type, 'green'))
        print('    Example: doc.py :mdn ::zh @http headers')
        exit(0)
    for arg in argv[1:]:
        if arg.startswith('::'):
            opts[arg[2:]] = True
        elif arg.startswith(':'):
            type = arg[1:]
        elif arg.startswith('@'):
            opts['filters'].append(arg[1:])
        else:
            query = arg
    q = Query()
    q.query(type, query, opts)
