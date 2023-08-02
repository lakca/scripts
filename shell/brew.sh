#!/usr/bin/env bash

[[ "$*" =~ (^| +)-h($| +.*) ]] && echo -e "
  brew.sh deps \x1b[2m- 列出安装的brew包及其依赖的本地包 \x1b[0m
" && exit 0

for pkg in $(brew list); do
  echo -e "\033[31m$pkg\033[0m";
  brew uses --installed $pkg;
  echo
done
