#!/bin/bash
set -e

# 读取配置文件
project_config_path="../config/project_config.ini"
if [ -f "${project_config_path}" ];then
  while read line
    do
      if [[ $line != "#"* ]];then
        if [[ -n $line ]];then
          echo $line
          eval $line
        fi
      fi
    done <  "${project_config_path}"
fi

if [ "$#" -lt 1 ];then
    echo "USAGE: $0 ${deploy_list[0]}"
    exit -1
fi

run_container_on_server=$1
parms=(${run_container_on_server//,/ })

server_name=${parms[0]}
docker_image_tag=${parms[1]}
image_tags=(${docker_image_tag//-/ })
app_name=${image_tags[0]}

echo "server_name=${server_name},docker_image_tag=${docker_image_tag},app_name=${app_name}"

#开始首次运行容器
if [ ! -d "/data/project/log" ];then
    sudo mkdir -p /data/project/log&chown -R app:app /data/project/log
fi
if [ ! -d "/data/project/jar" ];then
    sudo mkdir -p /data/project/jar&chown -R app:app /data/project/jar
fi
if [ ! -d "/data/project/bin" ];then
    sudo mkdir -p /data/project/bin&chown -R app:app /data/project/bin
fi
log_path="/data/project/log/run_container.log"

echo "开始在${server_name}首次运行容器${docker_image_tag}" >> ${log_path}

#登录容器仓库
echo "登录容器仓库,请输入密码:"
ssh -t app@${server_name} docker login --username=${docker_registry_user_name} ${docker_registry}

server_no=${server_name:0-1:1}
# 根据服务序号设置应用容器名称
container_name=${app_name}${server_no}

app_check_url=""
jar_name=""
for (( i = 0; i < ${#app_names[@]}; i++ )); do
  if [ x"${app_names[i]}" == x"${app_name}" ]; then
        jar_name=${jar_names[i]}
        app_check_url=${app_check_urls[i]//127.0.0.1/${server_name}}
        break
  fi
done

if [ "x${jar_name}" == "x" ]; then
  echo "没有找到${app_name}对应的jar，请检查project_config.ini配置" >> ${log_path}
  exit -1
fi

if [ "x${app_check_url}" == "x" ]; then
  echo "没有找到${app_name}对应的app_check_url，请检查project_config.ini配置" >> ${log_path}
  exit -1
fi

# 构建项目 start_container="start_no" 只构建项目，不重启容器
../deploy_project/build_project.sh ${server_name} ${app_name} "start_no"


#运行项目(本机)
if [ x"$server_no" = x"1" ]; then
  if [ ! -d "${jar_deploy_dir}" ];then
      mkdir -pv ${jar_deploy_dir}
  fi
  if [ ! -d "${project_root_dir}/${app_name}/log" ];then
       mkdir -pv ${project_root_dir}/${app_name}/log
  fi
  \cp -rf ${jar_build_dir}/${jar_name} ${jar_deploy_dir}
  docker run  -h app --network host -m ${app_run_configs[i]} --memory-swap ${app_run_configs[i]} -c ${app_run_priorities[i]} --restart=on-failure:3  \
  -it -d -v ${jar_deploy_dir}/${jar_name}:${jar_deploy_dir}/${jar_name} -v ${project_root_dir}/${app_name}:${project_root_dir}/${app_name} \
  -v ${project_root_dir}/${app_name}/log:${project_root_dir}/${app_name}/log \
  --name ${container_name} ${docker_registry}:${docker_image_tag}
else
  ssh app@${server_name} mkdir -pv ${jar_deploy_dir}/
  ssh app@${server_name} mkdir -pv ${project_root_dir}/${app_name}/log
  scp ${jar_build_dir}/${jar_name} app@${server_name}:${jar_deploy_dir}
  ssh app@${server_name} docker run -h app --network host -m ${app_run_configs[i]} --memory-swap ${app_run_configs[i]} -c ${app_run_priorities[i]} --restart=on-failure:3  \
  -it -d -v ${jar_deploy_dir}/${jar_name}:${jar_deploy_dir}/${jar_name} -v ${project_root_dir}/${app_name}:/${project_root_dir}/${app_name} \
  -v /${project_root_dir}/${app_name}/log:/${project_root_dir}/${app_name}/log \
  --name ${container_name} ${docker_registry}:${docker_image_tag}
fi
echo "docker run  -h app --network host -m ${app_run_configs[i]} --memory-swap ${app_run_configs[i]} -c ${app_run_priorities[i]} --restart=on-failure:3 -it -d -v ${jar_deploy_dir}/${jar_name}:${jar_deploy_dir}/${jar_name} -v ${project_root_dir}/${app_name}:${project_root_dir}/${app_name} -v ${project_root_dir}/${app_name}/log:${project_root_dir}/${app_name}/log --name ${container_name} ${docker_registry}:${docker_image_tag}" >> ${log_path}

