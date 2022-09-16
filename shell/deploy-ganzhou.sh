#! /usr/bin/env bash

harbor="local.harbor.io"
harboruser=""
harborpass=""
pass=""
publisher=""
controller=""
defaultServiceType="deployment"
service=$SERVICE
folder=$HOME

PRX_RESET=$'\e[0m'
STYLE=(BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE)
for i in "${!STYLE[@]}"; do
  eval PRX_${STYLE[$i]}=$'\e[3${i}m'
done

while getopts "n:r:f:s:h" opt; do
  case $opt in
    n) namespace=$OPTARG;;
    r) repo=$OPTARG;;
    f) filepath=$OPTARG;;
    s) service=$OPTARG;;
    h) echo "
      -n <namespace>
      -r <repository> e.g. caasportal/omp, omp (<namespace> is used)
      -f <local image file path>
      -s <service> e.g. deployment/omp, omp (deployment/omp)
      "
  esac
done

if [[ "$service" != *'/'* ]]; then
  service="$defaultServiceType/$service"
fi

if [[ "$repo" = *'/'* ]]; then
  [[ -z "$namespace" ]] && namespace=${repo%%/*}
else
  repo="$namespace/$repo"
fi

if [ ! -f "$filepath" ]; then

  ping -c4 "$harbor" >/dev/null 2>&1

  if [ $? = 0 ]; then
    [[ -z "$namespace" ]] && echo '未提供namespace，退出' && exit 0

    tag=`harbor.sh -c tags -n $repo | tail -1 | cut -f1 | xargs`

    read -p "是否使用最新镜像 $tag ？(y)" goon

    if [[ "$goon" != y ]]; then
      harbor.sh tags -n "$repo"
      read -p '输入目标镜像:' tag
    fi

    file="$tag.tar"

    declare -p | grep '^[a-z]'

    read -p '继续执行？（y）:' goon

    [[ $goon != 'y' ]] && echo '退出' && exit 0

    goon=''
    if [ -f "$file" ]; then
      read -p '镜像文件已存在，是否继续下载进行覆盖？(y)' goon
    else
      goon='y'
    fi
    [[ "$goon" = 'y' ]] && regctl image export "$harbor/$repo:$tag" >$file
  else
    echo "${PRX_RED}\n注意: 检测到镜像仓库地址$harbor无法连通，如果本地没有镜像文件而需要从仓库下载，请确认是否未连接正确的VPN或连接了其他VPN。
    \r如果是，请退出此次执行，连好正确的VPN后再次执行。\n${PRX_RESET}"
    while true; do
      read -p '本地镜像文件：' filepath
      filepath=`realpath $filepath`
      if [ -f "$filepath" ]; then
        file=`basename $filepath`
        break
      else
        echo "${PRX_RED}镜像文件不存在：$filepath${PRX_RESET}"
      fi
    done
  fi

else
  filepath=`realpath $filepath`
  file=`basename $filepath`
fi

ssh -o ConnectTimeout=3 "$publisher" 'true'

if [ $? -ne 0 ]; then
  echo "${PRX_RED}publisher($publisher)网络不通，VPN未连接？${PRX_RESET}"
  exit 0
fi

echo 'upload to publisher...'

ssh "$publisher" "file $folder/$file 2>/dev/null"

echo 'status:'$?

[ $? -ne 0 ] && scp "$file" "$publisher:$folder/" || echo 'publisher文件已存在'

echo 'upload to controller...'

ssh "$publisher" "{ssh $controller file $folder/$file 2>/dev/null;} || exit 1"

echo 'status:'$?

[ $? -ne 0 ] && ssh "$publisher" "scp $folder/$file $controller:$folder/" || echo 'controller文件已存在'

# ssh "$publisher" "ssh $controller docker image inspect $folder/$file" >/dev/null 2>&1`

imageResult=`ssh $publisher "ssh $controller docker load -i $folder/$file"`

echo "$imageResult"

imageName=`echo $imageResult | grep -i 'loaded image:' | sed 's/[^:]*:\s*//'`

echo image name: "$imageName"

exit 0

while [ -z "$service" ]; do read -p '输入服务名称：' service; done

ssh "$publisher" "ssh $controller docker push $imageName\
  && kubectl set image $service $containerName=$imageName -n $namespace\
  && kubectl rollout status $service -n $namespace"

