#!/usr/bin/env bash

[[ $* =~ (^| +)-h($| +.*) ]] && echo -e "
  \x1b[2m打包pake应用\x1b[0m
  pash.sh <url> <name> <icon_url_or_file>

  name             \x1b[2m- 应用名称\x1b[0m
  url              \x1b[2m- 网站地址\x1b[0m
  icon_url_or_file \x1b[2m- 应用logo，可以是.icns或者.png（jpg之类的也可以）\x1b[0m
" && exit 0

if ! command -v pake &>/dev/null; then
  function pake() {
    node $PAKE_REPO_DIR/cli.js $@
  }
fi

url="$1"
name="$2"
icon="$3"
args="${@:4}"

if [[ $icon ]]; then
  if [[ $icon != *.icns ]]; then
    $(dirname $0)/icns.sh "$icon" "$name"
    icon="$name.icns"
  fi
  echo "pake --show-menu --debug --width 1200 --height 720 "$url" --name "$2" --icon "$icon" "${args[*]}""
  pake --show-menu --debug --width 1200 --height 720 "$url" --name "$2" --icon "$icon" "${args[*]}"
else
  pake --show-menu --debug --width 1200 --height 720 "$url" --name "$2" "${args[*]}"
fi

[[ $(pwd) != $ASSET_FOLDER ]] && mv *.{dmg,icns,png,iconset} $ASSET_FOLDER
