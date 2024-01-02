#! /usr/bin/env bash
# find demo -type f -not -name '*.mp4'

i=1

while IFS= read -r -d '' line; do
  i=$((i+1))
  dir=$(dirname "$line")
  if [[ $1 && -f "$line" ]]; then
    [[ $1 > 0 ]] && echo '' > "$line"
    [[ $1 > 1 ]] && mv "$line" "$dir/$i"
    [[ $1 > 2 ]] && rm "$dir/$i"
  else
    echo -e "\x1b[31m文件\x1b[0m$line\x1b[31m 中间文件\x1b[0m$dir/$i"
  fi
done
