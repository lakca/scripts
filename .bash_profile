#n
export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

# man 用 Safari 打开
export PAGER="col -b  | open -a /Applications/Safari.app -f"

alias cnpm='npm --registry=http://registry.npm.taobao.org'
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias p=python3

function c.blue(){ # 蓝色输出
  echo -e "\033[34m$*\033[0m"
}
function c.green(){ # 绿色输出
  echo -e "\033[32m$*\033[0m"
}
function c.red(){ # 红色输出
  echo -e "\033[31m\033[01m$*\033[0m"
}
function c.magenta(){ # 洋色输出
  echo -e "\033[35m\033[01m$*\033[0m"
}
pad_left() {
  r=$1
  c=$(expr $2 - ${#r} + 1)
  for i in {1..$c}; do
    r=$r' '
  done
  echo $r
}
function c.help() { # 显示自定义命令列表, 同 `help`, `h`
  { setopt BASH_REMATCH } || {} # zsh
  reg='^ *(function) +([a-zA-Z0-9\.]+)[^#]*#? *(.*)'
  func_list=()
  func_desc=()
  max=0
  meet=0
  cat ~/.bash_profile | while read line
  do
    if [[ meet -eq 1 ]] && [[ $line =~ '^ *#(.*)' ]]
      then
        func_desc[${#func_desc[@]}]+="\n                > ${BASH_REMATCH[2]}"
    elif [[ $line =~ $reg ]]
      then
        meet=1
        func_list[${#func_list[@]}+1]="${BASH_REMATCH[3]}"
        if [[ ${#BASH_REMATCH[3]} -gt max ]]; then
          max=${#BASH_REMATCH[3]}
        fi
        if [[  $BASH_REMATCH[4] ]]
          then; func_desc[${#func_desc[@]}+1]="${BASH_REMATCH[4]}"
        fi
    else
      meet=0
    fi
  done

  i=0
  for fn in ${func_list[@]}; do
    i=$(expr $i + 1)
    s=`pad_left $fn $(expr $max + 2)`
    s=`c.red $s`
    s='  '$s': '`c.magenta ${func_desc[$i]}`

    if [[ $1 ]]; then
      if [[ $fn =~ $1 ]]; then
        echo -e '\n'$s
      fi
    else
      echo -e '\n'$s
    fi
  done
}
help() {
  c.help $@
}
h() {
  c.help $@
}
function c.addPath() { # 临时添加系统路径
  PATH=$PATH:$1
}
function c.qt() { # 打开 qt 文档
  open "https://doc.qt.io/qtforpython-6/PySide6/$1/$2.html"
}
function c.reload() { # 重新加载 bash profile，同 `c.r`
  source ~/.bash_profile
}
c.r() {
  c.reload
}
function c.translate() { # 翻译，同 `c.t`
  python3 ~/Documents/backward/translate.py "$@"
}
c.t() {
  c.translate $@
}
function c.resou() { # 热搜
  python3 ~/Documents/backward/resou.py "$@"
}
function c.baidu() { # 百度搜索，同 `c.b`
  open "https://www.baidu.com/s?wd=$*"
}
c.b() {
  c.baidu $@
}
function c.google() { # 谷歌搜索，同 `c.g`
  open "https://www.google.com/search?q=$*"
}
c.g() {
 c.google $@
}
function c.gt() { # 谷歌翻译
  open "https://translate.google.cn/?sl=auto&tl=zh-CN&text=$*&op=translate"
}
function c.bing() { # bing搜索，同 `c.bi`
  open "https://cn.bing.com/search?q=$*"
}
c.bi() {
  c.bing $@
}
function c.github() { # github搜索，同 `c.git`
  # 搜索的文本所在地: `in:name`, `in:description`, `in:readme`, `in:file`, `in:path`
  # 仓库      : `repo:OWNER/NAME`
  # 语言      : `language:LANGUAGE`
  # 用户      : `user:USERNAME`
  # 组织      : `org:ORGNAME`
  # 主题      : `topic:TOPIC`
  # 文件名     : `filename:FILENAME`
  # 后缀名     : `extension:EXTENSION`
  # 关注数     : `followers:n` (:n, :>n, :<n, :m..n)
  # fork数   : `forks:n` (:n, :>=n, :<n, :m..n)
  # star数   : `stars:n` (:n, :>n, :<n, :m..n)
  # 创建时间    : `created:YYYY-MM-DD`
  # 推送时间    : `pushed:YYYY-MM-DD`
  # 仓库的可见性  : `is:public`, `is:private`, `is:internal`
  # 是否是镜像   : `mirror:true`, `mirror:false`
  # 是否已归档   : `archived:true`, `archived:false`
  #
  # 更多见：https://docs.github.com/en/github/searching-for-information-on-github/searching-on-github
  open "https://github.com/search?q=$1&l=$2"
}
c.git() {
  c.github $@
}
