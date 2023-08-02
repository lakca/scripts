#!/usr/bin/env bash

root=$(git rev-parse --show-toplevel)
files=$(git ls-files --full-name $root)
found=0

while read line; do
  line=$root/$line
  # 身份证
  grep -IirEnH --color=always --exclude-dir={node_modules,target,data} --exclude='*.log' '[^0-9][1-6][0-7][0-9]{15}[0-9X][^0-9.]' $line
  [[ $? = 0 ]] && found=1
  # 手机号
  grep -IirEnH --color=always --exclude-dir={node_modules,target,data} --exclude='*.log' '[^0-9.]1[3-9][0-9]{9}[^0-9.]' $line
  [[ $? = 0 ]] && found=1
  # 环境变量
  if [[ $filter_words ]]; then
    for arg in $filter_words; do
      grep -IirEnH --color=always --exclude-dir={node_modules,target,data} --exclude='*.log' "$arg" $line
      [[ $? = 0 ]] && found=1
    done
  fi
done <<< "$files"

[[ $found = 1 ]] && echo -e "\033[31m检测出敏感字符，中断执行！\033[0m" && exit 1
