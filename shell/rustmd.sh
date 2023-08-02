#! /usr/bin/env bash

[[ $* =~ (^| +)-h($| +.*) ]] && echo -e "
  rust 帮助文档 markdown修复：

  \x1b[2m1. 给代码块加上 rust 标记，以高亮，配合 bat 使用。例如：rustc --explain E0277 | rustmd.sh | bat -l md\x1b[0m
" && exit 0

while read line; do { if [[ $line = '```' ]]; then [[ $count -ne 1 ]] && {
  echo $line'rust'
  count=1
} || {
  count=0
  echo $line
}; else echo $line; fi; }; done
