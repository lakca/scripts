# !/bin/bash

################# 预定义参数
ssh_host_52="10.208.0.114"
ssh_host_tc="128.196.1.28"
repo="local.harbor.io"

################# 样式定义

PRX_RESET=$'\e[0m'
STYLE=(BLACK RED GREEN YELLOW BLUE PURPLE CYAN WHITE)
for i in "${!STYLE[@]}"; do
  eval PRX_${STYLE[$i]}=$'\e[3${i}m'
done

################# 获取输入参数

# 输入：部署环境

ssh_host=""
ssh_user="root"
targetEnv=""

while [ -z $ssh_host ]; do
  read -p "${PRX_CYAN}部署环境${PRX_RESET}(${PRX_CYAN}52${PRX_RESET}, ${PRX_CYAN}tc${PRX_RESET})：" targetEnv;
  eval ssh_host='${'ssh_host_"$targetEnv"'}';
done

# 输入：ssh用户名

read -p "${PRX_CYAN}SSH用户名${PRX_RESET}(默认值：${PRX_CYAN}root${PRX_RESET})：" ssh_user; if [ -z $ssh_user ]; then ssh_user="root"; fi

remote=$ssh_user@$ssh_host

# 测试ssh密钥 #
# if [ ! `ssh $ssh_user@$ssh_host "true"` ]; then
#   echo "${PRX_YELLOW}无法使用密钥登录，后续需要持续输入密码操作～${PRX_RESET}"
# fi

# 输入：项目空间 (默认值：caasportal)

namespace=""

read -p "${PRX_CYAN}项目空间${PRX_RESET}(默认值：${PRX_CYAN}caasportal${PRX_RESET})${PRX_RESET}：" namespace;
if [ -z $namespace ];
  then namespace="caasportal"
fi

# 输入：部署名称

deploymentName=""

while [ -z $deploymentName ]; do
  ssh $remote "kubectl get deployment -n $namespace \
  -o custom-columns=NAME:.metadata.name,CONTAINERS:.spec.template.spec.containers[*].name,IMAGES:.spec.template.spec.containers[*].image"
  read -p "${PRX_CYAN}部署名称${PRX_RESET}（deployment名称）：" deploymentName
done

# 输入：需要更新的Container名称

containerName=""

while [ -z $containerName ]; do
  containerNames=`ssh $remote "kubectl get deployment $deploymentName -n $namespace \
  -o jsonpath='{range .spec.template.spec.containers[*]}{.name}{\", \"}'"`
  read -a containerName -p "${PRX_CYAN}需要更新的Container名称${PRX_RESET}（值：$containerNames*，其中*，表示更新所有）："
done

# 输入：镜像文件本地路径

imageFilePath=""

while [[ -z $imageFilePath || ! -f $imageFilePath ]]; do
  read -e -p "${PRX_CYAN}镜像路径${PRX_RESET}(本地镜像文件位置)：" imageFilePath
done

imageFileName=`basename $imageFilePath`

# 输入：服务器上面的临时目录

remoteDir=""

while [ -z $remoteDir ]; do
  read -p "${PRX_CYAN}临时目录${PRX_RESET}(远程文件暂存位置)：" remoteDir
done
if [[ $remoteDir != '/root/'* ]]; then echo "${PRX_RED}！输入的远程临时目录为：${remoteDir}，请确认已悉知危险！${PRX_RESET}"; fi

# 确认输入

_goon=''
while [ -z $_goon ]; do
  echo "${PRX_YELLOW}部署环境${PRX_RESET}: ${PRX_CYAN}$targetEnv${PRX_RESET}，${PRX_YELLOW}地址为${PRX_RESET}：${PRX_CYAN}$ssh_host${PRX_RESET}"
  echo "${PRX_YELLOW}SSH用户${PRX_RESET}: ${PRX_CYAN}$ssh_user${PRX_RESET}"
  echo "${PRX_YELLOW}项目空间${PRX_RESET}: ${PRX_CYAN}$namespace${PRX_RESET}"
  echo "${PRX_YELLOW}Deployment名称${PRX_RESET}: ${PRX_CYAN}$deploymentName${PRX_RESET}"
  echo "${PRX_YELLOW}Container名称${PRX_RESET}: ${PRX_CYAN}$containerName${PRX_RESET}"
  echo "${PRX_YELLOW}镜像路径${PRX_RESET}: ${PRX_CYAN}$imageFilePath${PRX_RESET}，${PRX_YELLOW}文件名${PRX_RESET}：${PRX_CYAN}$imageFileName${PRX_RESET}"
  echo "${PRX_YELLOW}临时目录${PRX_RESET}: ${PRX_CYAN}$remoteDir${PRX_RESET}"
  read -p "请确认输入的内容无误 [Y/N]? " _goon
  case $_goon in
    Y|y)
      echo "${PRX_CYAN}已确认，继续执行!${PRX_RESET}"
      ;;
    N|n)
      echo "${PRX_RED}未确认，退出执行!${PRX_RESET}"
      exit 0
      ;;
    *)
      _goon=''
      ;;
  esac
done

################# 执行流程

# 上传文件
_goon=''
read -p "${PRX_CYAN}是否跳过上传本地镜像文件？${PRX_RESET}(Y)：" _goon
if [[ $_goon != 'Y' && $_goon != 'y' ]]; then
  echo "${PRX_CYAN}上传镜像${PRX_RESET}"
  scp $imageFilePath $remote:$remoteDir
else
  echo "${PRX_RED}跳过上传镜像${PRX_RESET}"
fi

# 导入镜像
echo "${PRX_CYAN}导入镜像${PRX_RESET}"
imageResult=`ssh $remote "docker load -i $remoteDir/$imageFileName"`

echo $imageResult

imageId=`echo $imageResult | grep -i 'loaded image id:' |  grep -o '\b[a-f0-9]\{64\}\b'`
imageName=`echo $imageResult | grep -i 'loaded image:' | sed 's/[^:]*:\s*//'`
imageTag=''

if [ -z $imageName ]; then
  # imageName=`ssh $remote "docker image inspect -f '{{index .RepoTags 0}}'"`
  if [ -z $imageId ]; then
    echo "${PRX_RED}未找到镜像名称和ID，退出执行！${PRX_RESET}"
    exit 1;
  fi
  _goon=''
  while [ -z $_goon ]; do
    read -p "${PRX_YELLOW}该镜像没有名称，是否输入镜像名称继续进行${PRX_RESET}（Y/N）：" _goon
    case $_goon in
      Y|y)
        echo "${PRX_CYAN}已确认，继续执行!${PRX_RESET}"
        imagePartialTag=''
        while [ -z $imagePartialTag ]; do
          # 输入镜像标签
          read -p "${PRX_CYAN}请输入镜像部分名称（repository:tag，如输入：omp:v1.0，等同于：$repo/$namespace/omp:v1.0）：${PRX_RESET}" imagePartialTag
          if [ -n $imagePartialTag ]; then
            imageName="$repo/$namespace/$imagePartialTag"
            _goon2=''
            read -p "完整镜像名称为：$imageName，继续执行输入Y，其他将重新输入：" _goon2
            if [[ $_goon2 == 'Y' || $_goon2 == 'y' ]]; then break; fi
          fi
        done
        tagResult=`ssh $remote "docker tag $imageId $imageName"`
        ;;
      N|n)
        echo "${PRX_RED}未确认，退出执行!${PRX_RESET}"
        exit 0
        ;;
      *)
        _goon=''
        ;;
    esac
  done
fi

# # 是否推送镜像

_goon=''
while [ -z $_goon ]; do
  read -p "${PRX_CYAN}是否推送镜像${PRX_RESET}（Y/N）：" _goon
  case $_goon in
  Y|y)
    echo "${PRX_CYAN}推送镜像${PRX_RESET}"
    ssh $remote "docker push $imageName"
    ;;
  N|n)
    echo "${PRX_RED}不推送镜像${PRX_RESET}"
    ;;
  *)
    _goon=''
    ;;
  esac
done

# # 替换镜像

echo "${PRX_CYAN}替换Deployment镜像${PRX_RESET}"
ssh $remote "\
kubectl set image deployment/$deploymentName $containerName=$imageName -n $namespace"

# # 获取状态
echo "${PRX_CYAN}获取Deployment状态${PRX_RESET}"
ssh $remote "\
kubectl rollout status deployment/$deploymentName -n $namespace"

echo "${PRX_CYAN}部署成功！${PRX_RESET}"
