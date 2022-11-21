import sys
sys.path.insert(0, ".")

from lib import tokenize, Pipe, Parser
import json
# print(json.dumps(tokenize('data:(标题)question.title|red|bold|index,(链接)question.url,(时间)question.created|date,(标签)question.topics*.name|join').data, indent=2))
# print(json.dumps(tokenize('data.result|sort(key=data.result:result_type,sorts=[video,user]):(搜索结果类型)result_type,(结果列表)data|hr:(标题)title,(UP主)author,(标签)tag,(类型)typename,(项目类型)type,(链接)arcurl,(图片)upic').data, indent=2))

# print(Pipe.date('Mon Jan 31 20:50:10 +0800 2022'))

# print(Pipe.seekNumber('Mon Jan 31 20:50:10 +0800 2022'))

file='/Users/longpeng/Documents/GitHub/scripts/shell/data/bilibili.search/2022-11-21.17:27:08.json'

with open(file) as f:
    data = json.loads(f.read())
    fmt = 'data.result|sort(key=data.result:result_type,sorts=[video,user]):(搜索结果类型)result_type,(结果列表)data|TABLE|SIMPLE:(标题)title|SIMPLE|tag,(UP主)author|SIMPLE,(标签)tag,(类型)typename|SIMPLE,(链接)arcurl,(图片)upic'
    Parser.output(fmt, data)
    tokens = Parser.getTokens(fmt)
    records = Parser.getValue(data, tokens)
    with open('/Users/longpeng/Documents/GitHub/scripts/shell/demo.tokens.json', 'w') as fa:
        fa.write(json.dumps(tokens))
    with open('/Users/longpeng/Documents/GitHub/scripts/shell/demo.json', 'w') as fa:
        fa.write(json.dumps(records))
    records = Pipe.apply(records, tokens["pipes"])
    for record in records:
        for token in tokens['children']:
            Parser.printToken(record, token)
