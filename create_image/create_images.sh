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

#容器构建
mkdir -p /data/project/log
mkdir -p /data/project/jar
mkdir -p /data/project/bin
mkdir -p /data/project/code
log_path="/data/project/log/create_image.log"

echo "输入docker仓库管理员密码"
#登录容器仓库
docker login --username=${docker_registry_user_name} ${docker_registry}

echo "开始构建镜像" > ${log_path}

for (( i = 0; i < ${#app_names[@]}; i++ )); do
  for (( j = 0; j < ${#run_env_profiles[@]}; j++ )); do
    #构建项目
    docker build --tag "${docker_registry}:${app_names[i]}-${image_tag_suffixs[j]}" --build-arg userName=${image_user_name} --build-arg userGroup=${image_user_group} \
           --build-arg appName=${app_names[i]} --build-arg exposePort="${app_expose_ports[i]}" --build-arg jarName=${jar_names[i]} --build-arg runEnvProfile=${run_env_profiles[j]} \
           --build-arg version=${label_version} --build-arg appCheckUrl=${app_check_urls[i]} --build-arg javaOptions="${java_options}" -f common_dockerfile .
    echo "${app_names[i]}-${image_tag_suffixs[j]}容器创建命令" >> ${log_path}
    echo "docker build --tag \"${docker_registry}:${app_names[i]}-${image_tag_suffixs[j]}\" --build-arg userName=${image_user_name} --build-arg userGroup=${image_user_group} --build-arg appName=${app_names[i]} --build-arg exposePort=\"${app_expose_ports[i]}\" --build-arg jarName=${jar_names[i]} --build-arg runEnvProfile=${run_env_profiles[j]} --build-arg version=${label_version} --build-arg appCheckUrl=${app_check_urls[i]} --build-arg javaOptions=\"${java_options}\" -f common_dockerfile ." >> ${log_path}
    # 将构建成功的容器推送到阿里云仓库（先登录）
    docker push ${docker_registry}:${app_names[i]}-${image_tag_suffix}
  done
done
echo "完成构建镜像" >> ${log_path}
