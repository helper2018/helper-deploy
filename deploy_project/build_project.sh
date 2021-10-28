#!/bin/bash
set +e

OFFLINE_WAIT_TIME=35
ONLINE_WAIT_TIME=70

#exit/return code编码：100-异常退出 200-无需执行构建脚本 1-正常 -1-异常退出

#构建日期
today=`date +"%Y_%m_%d_%H%M%S"`
# 构建项目

# 全部项目名
all_project=(healthDataCenter healthcloud)
# 项目目录
project_dir=""
# 项目构建结果
project_build_result="0"
# 发布项目
deploy_project=()
# 日志根目录
log_root_dir="/data/project/log"

print_log(){
  while read line
    do
      echo $line
    done < $1
}

get_project(){
  # 项目源码获取
  cd ${code_root_dir}
  if [ -d "${project_dir}" ]; then
    echo "${project_name}已存在"
  else
    echo "${project_name}不存在"
    git clone ${git_remote_url}
  fi
}

build_project(){
  # 更新源码并打包
  cd ${project_dir}
  git pull origin ${git_branch} | tee ${log_root_dir}/${project_name}_update.log

  grep "Already up-to-date." ${log_root_dir}/${project_name}_update.log > /dev/null
  if [ $? -eq 0 ]; then
    echo "${project_dir}是最新的，不需要更新"
    if [ x${project_build_result} = x1 ];then
      echo "项目最近构建是成功的，不需要重新构建"
      return 200
    fi
  else
    echo "${project_dir}更新成功"
  fi

  echo "===开始构建项目${project_dir}==="
  mvn clean install -DskipTests | tee ${log_root_dir}/${project_name}.log

  grep "BUILD SUCCESS" ${log_root_dir}/${project_name}.log > /dev/null
  if [ $? -eq 0 ]; then
    echo "项目构建成功"
  else
    echo "项目构建失败"
  return 100
  fi
}

backup_jar(){
  #备份jar
  echo "开始备份jar"
  for jar in `ls ${jar_build_dir}/*.jar`;
    do
      echo "开始备份jar=${jar}"
      mv ${jar} ${jar}.${today}
    done
  echo "结束备份jar"
}

copy_jar(){
  echo "开始copy jar"
  for jar_info in `grep "Installing ${code_root_dir}/.*jar$" ${log_root_dir}/${project_name}.log`;
    do
      if [[ ${jar_info} == ${code_root_dir}* ]];then
        if [[ ${jar_info} == *common* ]];then
          continue
        elif [[ ${jar_info} == *base* ]];then
          continue
      elif [[ ${jar_info} == *simulator* ]];then
        continue
      fi
      #备份jar
      jar=${jar_build_dir}/${jar_info##*/}
      if [ -f "$jar" ];then
        mv ${jar} ${jar}.${today}
      fi
      #复制jar
        \cp -rf ${jar_info} ${jar_build_dir}
      fi
    done
  echo "结束copy jar"
}

update_build_result(){
  grep "export ${project_name}_build_result=" ~/.bash_profile > /dev/null
  if [ $? -eq 0 ]; then
    echo "修改环境变量${project_name}_build_result=${project_build_result}"
    sed -i.bak 's/export '${project_name}'_build_result=.*/export '${project_name}'_build_result='${project_build_result}'/g' ~/.bash_profile
  else
    echo "新插入环境变量${project_name}_build_result=${project_build_result}"
    sed -i.bak '$a export '${project_name}'_build_result='${project_build_result} ~/.bash_profile
  fi
  source ~/.bash_profile
}

offline_docker_container(){
  # 停止容器定时监测服务状态
  grep "export SERVICE_LISTENER=" ~/.bash_profile > /dev/null
  if [ $? -eq 0 ]; then
    echo "修改环境变量SERVICE_LISTENER=0"
    sed -i.bak 's/export SERVICE_LISTENER=.*/export SERVICE_LISTENER=0/g' ~/.bash_profile
  else
    echo "新插入环境变量SERVICE_LISTENER=0"
    sed -i.bak '$a export SERVICE_LISTENER=0' ~/.bash_profile
  fi
  source ~/.bash_profile

  #从负载均衡摘除当前节点
  if [ x"${elb_members_name}" != x"xo" ];then
    echo "从负载均衡摘除当前节点: ~/bin/deploy_project/update_elb_nginx.sh ${elb_members_name} ${server_ip} 0"
    ~/bin/deploy_project/update_elb_nginx.sh ${elb_members_name} ${server_ip} 0
  fi
  
  #从注册中心注销该服务
  echo "从注册中心注销该服务: ~/bin/deploy_project/update_registry_status.sh ${server_ip} ${app_check_port} DOWN"
  ~/bin/deploy_project/update_registry_status.sh ${server_ip} ${app_check_port} DOWN

  echo "${server_name}-${container_name}下线,等待${OFFLINE_WAIT_TIME}秒..."
  sleep ${OFFLINE_WAIT_TIME}

  if [ x${server_no} = x"1" ] ; then
    echo "停止容器 ${server_name} docker stop ${container_name}"
    docker stop ${container_name}
  else
    echo "启动服务ssh ${server_name} docker stop ${container_name}"
    ssh ${server_name} docker stop ${container_name}
  fi
}

online_docker_container(){
  echo "开始重启容器"
  for jar_info in `ls ${jar_build_dir}/${jar_name}`;
    do
      jar_path=${jar_info}
      break
    done

  if [ ! -f "${jar_path}" ]; then
    echo "${container_name}jar不存在"
    return 100
  fi

  if [ x"${server_no}" = x"1" ] ; then
    \cp -rf ${jar_path} ${jar_deploy_dir}
    echo "启动服务${server_name}=docker start ${container_name}"
    docker start ${container_name}
  else
    scp ${jar_path} ${server_name}:${jar_deploy_dir}
    echo "启动服务ssh ${server_name} docker start ${container_name}"
    ssh ${server_name} docker start ${container_name}
  fi

  health_check

  if [ $? -eq 100 ];then
    if [ "new" = $1 ];then
      echo "==================发布失败:${container_name},5秒后开始回滚项目，取消请按Ctrl+C=================="
      sleep 5
      rollback_project
    fi
  fi

  #从负载均衡启用当前节点
  if [ x"${elb_members_name}" != x"xo" ];then
    echo "从负载均衡启用当前节点: ~/bin/deploy_project/update_elb_nginx.sh ${elb_members_name} ${server_ip} ${weight}"
    ~/bin/deploy_project/update_elb_nginx.sh ${elb_members_name} ${server_ip} ${weight}
  fi

  #向注册中心注册该服务
  echo "向注册中心注册该服务: ~/bin/deploy_project/update_registry_status.sh ${server_ip} ${app_check_port} UP"
  ~/bin/deploy_project/update_registry_status.sh ${server_ip} ${app_check_port} UP

  # 重新打开容器定时监测服务状态
  echo "修改环境变量SERVICE_LISTENER=1"
  sed -i.bak 's/export SERVICE_LISTENER=.*/export SERVICE_LISTENER=1/g' ~/.bash_profile
  source ~/.bash_profile
}

rollback_project(){
  for jar_info in `ls ${jar_build_dir}/${jar_name}.* -t`;
    do
      mv -f ${jar_info} ${jar_info%.*}
      break
    done
    echo "启动备份的jar"
    online_docker_container old
}

health_check() {
  CHECK_URL=${app_check_url}
  FAIL_COUNT=0
  while true
    do
      status_code=`/usr/bin/curl -L -o /dev/null --connect-timeout 5 -s -w %{http_code} ${CHECK_URL}`
      if [ x$status_code != x200 ];then
        sleep 1
        ((FAIL_COUNT++))
        echo -n -e "\rWait ${container_name} to pass health check: ${FAIL_COUNT}..."
      else
        break
      fi
      if [ ${FAIL_COUNT} -gt ${ONLINE_WAIT_TIME} ]; then
        echo "${container_name} check failed"
        return 100
      fi
    done
  echo "check ${container_name} success"
}

release_project(){
  #加载用户环境变量
  source ~/.bash_profile
  project_build_result=`eval echo "$"${project_name}_build_result`
  echo "上次构建结果${project_name}_build_result=${project_build_result}"
  project_dir=${code_root_dir}/${project_name}
  get_project
  build_project
  rs=$?
  if [ ${rs} == 100 ];then
    project_build_result=0
    update_build_result
    exit -1
  elif [ ${rs} == 200 ];then
    echo "不需要备份和测试jar"
  else
#    backup_jar
    copy_jar
    project_build_result=1
    update_build_result
  fi
  if [ x"${start_container}" = x"start_no" ]; then
    echo "jar已构建,不启动容器"
  else
    offline_docker_container
    online_docker_container new
    if [ $? -eq 0 ];then
      echo "发布成功:${server_name}-${container_name}-${app_check_url}"
    else
      echo "发布失败:${server_name}-${container_name}-${app_check_url}"
    fi
  fi
}

# 读取配置文件
project_config_path="../config/project_config.ini"
if [ -f "${project_config_path}" ];then
  while read line
    do
      if [[ $line != "#"* ]];then
        if [[ -n $line ]];then
          eval $line
        fi
      fi
    done <  "${project_config_path}"
fi

# 传参
server_name=$1
app_name=$2
start_container=$3

server_no=${server_name:0-1:1}
# 根据服务序号设置应用容器名称
container_name=${app_name}${server_no}

for (( i = 0; i < ${#app_names[@]}; i++ )); do
  if [ "x${app_names[i]}" == "x${app_name}" ]; then
    jar_name=${jar_names[i]}
    server_ip=${server_ips[i]}
    weight=${server_weights[i]}
    elb_members_name=${elb_members_names[i]}
    app_check_url=${app_check_urls[i]//127.0.0.1/${server_name}}
    git_remote_url=${git_remote_urls[i]}
    app_check_ports=(${app_expose_ports[i]})
    app_check_port=${app_check_ports[0]}
    break
  fi
done

array=(${git_remote_url//\// })
count=${#array[@]}
((count--))
project_name=${array[${count}]//.git/}

echo $elb_members_name $weight $server_ip $jar_name $app_check_url $project_name $app_check_port
#执行发布
release_project
