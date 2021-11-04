#!/bin/bash
PROGRESS_NAME=$0
ACTION=$1
source ~/.bash_profile
if [ "x${SERVICE_LISTENER}" != "x1" ];then
    echo "服务发布中，暂停健康检查"
    exit 0
else
    echo "`date \"+%Y-%m-%d %H:%M:%S\"` 开始服务健康检查"
fi

## 读取配置文件
#project_config_path="/home/app/bin/config/project_config.ini"
#if [ -f "${project_config_path}" ];then
#  while read line
#    do
#      if [[ $line != "#"* ]];then
#        if [[ -n $line ]];then
#          echo $line
#          eval $line
#        fi
#      fi
#    done <  "${project_config_path}"
#fi

echo "开启服务监控预警 `date +%Y%m%d_%H%M%S`"
declare -i FAIL_COUNT=0    # 失败次数
declare -i RETRY_COUNT=0   # 重试次数
declare server_name        # 服务名
declare container_name     # 容器名
declare check_url          # 服务名checkUrl
SERVICE_CHECK_TIMEOUT=60   # 等待服务检查的时间

mobiles=["1XXXXXXXXXX"]    # 短信发送电话号码
sms_url="http://XXX"       # 短信发送地址
declare aliasName          # 服务器别名
declare appName            # docker容器名称(含应用名)

# 应用名及服务器序号(多个实例用_分隔)，如app1_1_2代表dev1、dev2上有应用app1
container_names=("app1_1" "app2_2")
check_ports=("8001" "8002")

usage() {
    echo "Usage: $PROGRESS_NAME {check}"
    exit 2
}

health_check() {
    FAIL_COUNT=0
    echo "start checking ${container_name} ${check_url}"
    while true
    do
        status_code=`/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w %{http_code}  ${check_url}`
        if [ x$status_code != x200 ];then
            sleep 1
            ((FAIL_COUNT++))
            echo -n -e "\rWait $container_name to pass health check: $FAIL_COUNT..."
        else
            break
        fi
        if [ $FAIL_COUNT -gt ${SERVICE_CHECK_TIMEOUT} ]; then
            echo "$container_name check failed"
            aliasName="$aliasName|$server_name"
            appName="$appName|$container_name"
            break
            # exit 1
        fi
    done
    echo "check ${container_name} ${check_url} success"
}

check_service_status(){
  # 当发布时检测项目最近的构建结果 0：项目构建失败
  if [ "x${XXX_build_result}" != "x1" ]; then
    exit 1
  fi
  aliasName="server"
  appName="docker"
  for(( i=0;i<${#container_names[@]};i++))
    do
      app_container_names=(${container_names[i]//_/ })
      app_name=${app_container_names[0]}
      for(( j=1;j<${#app_container_names[@]};j++))
        do
          server_no=${app_container_names[j]}
          echo "server_no===${server_no}"
          server_name=prod${server_no}
          container_name=${app_name}${server_no}
          # check_url应用统一提供/init/health-check接口
          check_url="http://${server_name}:${check_ports[i]}/init/health-check"
          echo "容器名==========${container_name}"
          echo "checkUrl========${check_url}"
          # 调用服务health_check
          health_check
        done
    done
  # 检查是否有重启失败的应用
  if [ "xserver" != "x${aliasName}" ]; then
    if [ ${RETRY_COUNT} -eq 0 ]; then
      restart_docker
      ((RETRY_COUNT++))
      sleep ${SERVICE_CHECK_TIMEOUT}
      check_service_status
    else
      send_sms
    fi
  fi
}

send_sms(){
  # 短信发送 需要公共服务可用
  if [ x"server" != x${aliasName} ]; then
    #发送短信(限制参数长度)
    server_names=${aliasName:7:27}
    docker_names=${appName:7:27}
    echo "短信参数aliasName="${server_names}" appName="${docker_names}
    # 参数根据自己的接口定义
    curl -i -X POST -H "Content-type:application/json" --data '{"mobiles": '${mobiles}',"templateCode": "XXX","templateParam": {"aliasName":"'${server_names}'","appName":"'${docker_names}'"}}' $sms_url
  fi
}

restart_docker(){
  sName="${aliasName#*|}|"
  dockerName="${appName#*|}|"
  echo "未启动的服务=="${aliasName}-${appName}

  while true
  do
    echo "重启服务开始=="${sName%%|*}${dockerName%%|*}
    server_name=${sName%%|*}
    server_no=${server_name:0-1:1}
    if [ x${server_no} = x"1" ] ; then
      echo "启动服务${server_name}=docker start ${dockerName%%|*}"
      docker start ${dockerName%%|*}
    else
      echo "启动服务ssh ${server_name} docker start ${dockerName%%|*}"
      ssh ${server_name} docker start ${dockerName%%|*}
    fi
    sName=${sName#*|}
    dockerName=${dockerName#*|}
    echo "重启服务结束=="${sName}${dockerName}
    if [ x${sName} = "x" ]; then
      break
    fi
  done
}

case "$ACTION" in
    check)
        check_service_status
    ;;
    *)
        usage
    ;;
esac

