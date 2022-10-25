#! /usr/bin/env bash

source `dirname $0`/lib.sh

function color() {
  local v=7
  [[ $2 > $3 ]] && v=1
  [[ $2 < $3 ]] && v=2
  echo -e "\033[3${v}m$1\033[0m"
}

PRICES=()

function quote() {
  while getopts 'a:' opt; do
    case $opt in
      a)

      ;;
    esac
  done
  local url="https://hq.sinajs.cn/list=$1&_=$(date +%s)"
  local list=($(curl -s "$url" -H 'Referer:http://finance.sina.com.cn/' | iconv -f gb18030 -t utf8 | cut -d '"' -f2))
  # https://www.jianshu.com/p/fabe3811a01d
  local keys=(name open close price high low buy sell volume amount bv1 bp1 bv2 bp2 bv3 bp3 bv4 bp4 bv5 bp5 sv1 sp1 sv2 sp2 sv3 sp3 sv4 sp4 sv5 sp5 date time)
  local aliases=(名称 开盘价 收盘价 当前价 最高价 最低价 买一价 卖一价 成交量 成交额 买一量 买一价 买二量 买二价 买三量 买三价 买四量 买四价 买五量 买五价 买一量 卖一价 卖二量 卖二价 卖三量 卖三价 卖四量 卖四价 卖五量 卖五价 日期 时间)

  local result=''
  [[ ${#PRICES[@]} ]] && result=$result"\033[$((1 + ${#PRICES[@]}))A\033[2K\033[1A\n"
  result=$result'\033[2;37m名称 幅度 价格 成交额 时间\033[0m\n'
  for i in ${!list[@]}; do
    fields=($(sed "s/,/ /g" <<< "${list[@]:$i:1}"))
    name=${fields[@]:0:1}
    open=${fields[@]:1:1}
    close=${fields[@]:2:1}
    price=${fields[@]:3:1}
    amount=${fields[@]:9:1}
    time=${fields[@]:31:1}
    percent=$(bc <<< "scale=2;100*($price-$close)/$close" | xargs printf "%+.2f")%
    # echo $price, $close 1>&2
    result=$result"$(color $name $open $close) $(color $percent $price $close) $(color $price $price ${PRICES[@]:$i:1}) $(printf "%'.0f" $amount) $time\n"
    PRICES[$i]=$price
  done
  echo -e $result | tabulate -f plain
  sleep 1
  quote $*
}

quote sz300556,sh600352,sh600678,sh000001
