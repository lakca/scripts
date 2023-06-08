#!/usr/bin/env bash

cmd="openssl enc -aes-256-cbc -md sha512 -pbkdf2 -iter 250000 -salt -base64"

op='encrypt'
format='base64'

for arg in $@; do
  if [ $arg = '-d' ]; then
    cmd="$cmd -d"
    op='decrypt'
  elif [ $arg = '-hex' ]; then
    format=hex
  elif [ $arg = '-h' ]; then
    echo -e "    \033[32maes.sh [-d] [-hex] [text|file|stdin]\033[0m"
    echo -e "    \033[2m通过AES加密/解密标准输入、文件内容或字符串，默认输出base64\033[0m"
    echo -e "    \033[2m标准输入\033[0m                     pbpaste | aes.sh, pbpaste | aes.sh -d"
    echo -e "    \033[2m文件内容\033[0m                     aes.sh hello.txt, aes.sh -d hello.txt"
    echo -e "    \033[2m字符串（若未找到同名文件）\033[0m   aes.sh 'hello world', aes.sh -d 'hello world'"
    exit 0
  else
    input="$arg"
  fi
done

if [[ $op = 'decrypt' && $format = 'hex' ]]; then
  cmd="xxd -p -r | $cmd"
fi

if [[ -f "$input" ]]; then
  cmd="cat $input | $cmd"
else
  cmd="echo $input | $cmd"
fi

output=$(bash <<< "$cmd")

[[ $op = 'encrypt' && $format = 'hex' ]] && xxd -p <<<$output || echo $output
