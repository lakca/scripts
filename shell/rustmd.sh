# !/usr/bin/env bash

# rust 帮助文档 markdown修复
# 1. 给代码块加上 rust 标记，以高亮，配合 `bat` 使用, e.g. `rustc --explain E0277 | rustmd | bat -l md`
while read line; do { if [[ $line = '```' ]]; then [[ $count -ne 1 ]] && {
  echo $line'rust'
  count=1
} || {
  count=0
  echo $line
}; else echo $line; fi; }; done
