#! /usr/bin/env bash

source `dirname $0`/lib.sh

function indicate() {
  local v=7
  [[ $2 > $3 ]] && v=1
  [[ $2 < $3 ]] && v=2
  echo -e "\033[3${v}m$1\033[0m"
}

function prettyAmount() {
  local unit amount=$(printf %.0f $1)
  if [[ $amount -ge 10000 ]]; then
    for unit in 万 亿; do
      amount=$(bc <<< "scale=1;$amount / 10000" | xargs printf %.0f)
      [[ $amount -lt 10000 ]] && break
    done
  fi
  echo $amount$unit
}

function quote() {
  local OPTIND key codes alertLowPrices alertHighPrices alertLowPercents alertHighPercents
  if [[ $1 == '-x' ]]; then
    for arg in "${@:1}"; do
      case "$arg" in
        --low-price|-v) key=QUOTE_ALERT_LOW_PRICES;;
        --high-price|+v) key=QUOTE_ALERT_HIGH_PRICES;;
        --low-percent|-p) key=QUOTE_ALERT_LOW_PERCENTS;;
        --high-percent|+p) key=QUOTE_ALERT_HIGH_PERCENTS;;
        *)
          if [[ $key ]]; then
            declare $key="$arg"
            unset key
          else
            IFS=',' read -r -a codes <<< "$arg"
          fi
        ;;
      esac
    done
    IFS=',;: ' read -r -a alertLowPrices <<< "$QUOTE_ALERT_LOW_PRICES"
    IFS=',;: ' read -r -a alertHighPrices <<< "$QUOTE_ALERT_HIGH_PRICES"
    IFS=',;: ' read -r -a alertLowPercents <<< "$QUOTE_ALERT_LOW_PERCENTS"
    IFS=',;: ' read -r -a alertHighPercents <<< "$QUOTE_ALERT_HIGH_PERCENTS"
  else
    local index
    while getopts 'c:v:V:p:P:h' opt; do
      case $opt in
        c)
          codes+=("$OPTARG")
          [[ $index ]] && index=$((index + 1)) || index=0
          ;;
        v) alertLowPrices[$index]="$OPTARG" ;;
        V) alertHighPrices[$index]="$OPTARG" ;;
        p) alertLowPercents[$index]="$OPTARG" ;;
        P) alertHighPercents[$index]="$OPTARG" ;;
        h)
           echo -e '\033[32m-c\033[0m \033[2m<code>         如：-c sh000001\033[0m'
           echo -e '\033[32m-v\033[0m \033[2m<low_price>\033[0m'
           echo -e '\033[32m-V\033[0m \033[2m<high_price>\033[0m'
           echo -e '\033[32m-p\033[0m \033[2m<low_percent>\033[0m'
           echo -e '\033[32m-P\033[0m \033[2m<high_percent>\033[0m'
           echo -e '\033[2m例如：\033[0m'
           echo -e '\033[2m  em.sh quote -c sh000001 -p 0 -V 3300 -c sh600352 -p 0 -P 5\033[0m'
           exit 0
        ;;
      esac
    done
  fi
  local prices=($PRICES)

  local url="https://hq.sinajs.cn/list="$(tr ' ' , <<< ${codes[*]})
  local list=($(curl -s "$url" -H 'Referer:http://finance.sina.com.cn/' | iconv -f gb18030 -t utf8 | cut -d '"' -f2))
  # https://www.jianshu.com/p/fabe3811a01d
  local keys=(name open close price high low buy sell volume amount bv1 bp1 bv2 bp2 bv3 bp3 bv4 bp4 bv5 bp5 sv1 sp1 sv2 sp2 sv3 sp3 sv4 sp4 sv5 sp5 date time)
  local aliases=(名称 开盘价 收盘价 当前价 最高价 最低价 买一价 卖一价 成交量 成交额 买一量 买一价 买二量 买二价 买三量 买三价 买四量 买四价 买五量 买五价 买一量 卖一价 卖二量 卖二价 卖三量 卖三价 卖四量 卖四价 卖五量 卖五价 日期 时间)

  if [[ ${#list[@]} -gt 0 ]]; then
    local result=''
    [[ ${#prices[@]} -gt 0 ]] && result=$result"\033[$((1 + ${#prices[@]}))A\033[2K"
    result=$result'\033[2;37m名称 最低 幅度 最高 价格 成交额 时间\033[0m\n'
    for i in ${!list[@]}; do
      local fields=($(sed "s/,/ /g" <<< "${list[@]:$i:1}"))
      local name=${fields[@]:0:1}
      local open=${fields[@]:1:1}
      local close=${fields[@]:2:1}
      local price=${fields[@]:3:1}
      local high=${fields[@]:4:1}
      local low=${fields[@]:5:1}
      local amount=${fields[@]:9:1}
      local time=${fields[@]:31:1}
      local percent=$(bc <<< "scale=2;100*($price-$close)/$close")
      local percentText=$(printf "%+.2f" $percent)%
      local highPercentText=$(printf "%+.2f" $(bc <<< "scale=2;100*($high-$close)/$close"))%
      local lowPercentText=$(printf "%+.2f" $(bc <<< "scale=2;100*($low-$close)/$close"))%
      local result=$result"$(indicate $name $open $close) \033[2m$(indicate $lowPercentText $low $close) $(indicate $percentText $price $close) \033[2m$(indicate $highPercentText $high $close) $(indicate $price $price ${prices[@]:$i:1}) $(prettyAmount $amount) \033[2m$time\033[0m\n"
      [[ $i == 0 ]] && echo -en "\033];$percentText\007"

      local alertHighPrice=${alertHighPrices[@]:$i:1}
      local alertLowPrice=${alertLowPrices[@]:$i:1}
      local alertHighPercent=${alertHighPercents[@]:$i:1}
      local alertLowPercent=${alertLowPercents[@]:$i:1}
      local script=''
      [[ $price = ${prices[@]:$i:1} ]] && continue
      if [[ $alertHighPrice && 1 -eq $(bc <<< "$price >= $alertHighPrice") ]]; then
        script="display notification (\"涨幅 $percentText\" as Unicode text) with title (\"🔥 $name $price\" as Unicode text) subtitle (\"-\" as Unicode text)"
      fi
      if [[ $alertLowPrice && 1 -eq $(bc <<< "$price <= $alertLowPrice") ]]; then
        script="display notification (\"涨幅 $percentText\" as Unicode text) with title (\"💚 $name $price\" as Unicode text) subtitle (\"-\" as Unicode text)"
      fi
      if [[ $alertHighPercent && 1 -eq $(bc <<< "$percent >= $alertHighPercent") ]]; then
        script="display notification (\"涨幅 $percentText\" as Unicode text) with title (\"🔥 $name $price\" as Unicode text) subtitle (\"-\" as Unicode text)"
      fi
      if [[ $alertLowPercent && 1 -eq $(bc <<< "$percent <= $alertLowPercent") ]]; then
        script="display notification (\"涨幅 $percentText\" as Unicode text) with title (\"💚 $name $price\" as Unicode text) subtitle (\"-\" as Unicode text)"
      fi
      [[ $script ]] && osascript -e "$script"
      prices[$i]=$price
    done
    echo -en $result | tabulate -f plain
  else
    echo "$url" >> debug
    echo "${#}:${@}" >> debug
  fi
  sleep 1
  PRICES="${prices[*]}" quote "$@"
}

# QUOTE_ALERT_LOW_PRICES=",17.22,8.90,5.11" quote sh000001,sz300556,sh600352,sh600678
# em.sh quote sh000001,sz300556,sh600352,sh600678 -v ",17.22,8.90,5.11" +v '3000'

case $1 in
  quote) quote "${@:2}";;
esac
