#! /usr/bin/env bash

source `dirname $0`/lib.sh

dir=$(pwd)

case $1 in
  package|pkg) # 查找当前目录的package.json
    cur=$dir
    while [ -d $cur ]; do
      [ -f $cur/package.json ] && echo $cur/package.json
      cur=$(dirname $cur)
      [ $cur = '/' ] && break
    done
  ;;
  *)
    help -h
  ;;
esac

help "$@"
