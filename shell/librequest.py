from urllib import request
from urllib.parse import parse_qs, quote, urlencode, urlparse, urlunparse
from json import dumps, loads
from typing import Optional, Union
from hashlib import md5


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
    jsonp: Optional[bool] = None,
):
    if query:
        query = query if isinstance(query, str) else urlencode(query)
        urlObj = urlparse(url)
        url = urlObj._replace(query=urlObj.query + "&" + query if urlObj.query else query).geturl()
    if data:
        data = urlencode(data)

    text = None

    if text is None:
        req = request.Request(url)
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)
        with request.urlopen(req, data=data) as f:
            text = f.read().decode("utf-8")
    if jsonp:
        text = text.partition('(')[2][:-1]
    if returnJson:
        return loads(text)
    return text
