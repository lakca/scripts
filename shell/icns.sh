#!/usr/bin/env bash

[[ "$*" =~ (^| +)-h($| +.*) ]] && echo -e "
  icns.sh <png_or_svg> <icon_name> \x1b[2m- 将png转换成icns\x1b[0m
" && exit 0

tmp="pake.icon.$RANDOM.png"
if [[ -p /dev/stdin ]]; then
  cut -d ',' -f 2 | base64 --decode > $tmp
  icon=$tmp
  name=$1
else
  icon="$1"
  name=${2:-${icon%.*}}
fi
folder="$name.iconset"

type=$(tr "[:upper:]" "[:lower:]" <<< ${icon:$(expr ${#icon} - 3):3})

if [[ "$icon" == http* ]]; then
  curl "$icon" -o "$name.$type"
  icon="$name.$type"
fi

mkdir -p "$folder"

SIZES="
16,16x16
32,16x16@2x
32,32x32
64,32x32@2x
128,128x128
256,128x128@2x
256,256x256
512,256x256@2x
512,512x512
1024,512x512@2x
"

for PARAMS in $SIZES; do
    SIZE=$(echo $PARAMS | cut -d, -f1)
    LABEL=$(echo $PARAMS | cut -d, -f2)
    [[ $type == 'png' ]] && sips --resampleWidth $SIZE --padToHeightWidth $SIZE $SIZE "$icon" --out "$folder/icon_$LABEL.png"
    [[ $type == 'svg' ]] && svg2png -w $SIZE -h $SIZE "$icon" "$folder/icon_$LABEL.png"
done

iconutil -c icns "$folder" -o "$name.icns"

[[ -f $tmp ]] && mv $tmp $name.png
