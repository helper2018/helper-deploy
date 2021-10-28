#!/bin/bash
set -e

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

app_name=$1

if [ "x${app_name}" == "x" ];then
   echo "可使用的发布应用名为:${app_names[@]}  命令格式为:./all_server.sh app_name"
   exit -1
fi

search_app_name=""
app_check_internal_url=""
for (( i = 0; i < ${#app_names[@]}; i++ )); do
  if [ "x${app_names[i]}" == "x${app_name}" ]; then
    search_app_name=${app_name}
    app_check_internal_url=${app_check_urls[i]}
    break
  fi
done

if [ "x${search_app_name}" == "x" ];then
  echo "${app_name}是否正确?包含在${app_names[@]}其中"
  exit -1
fi

if [ "x${app_check_internal_url}" == "x" ]; then
  echo "没有找到${app_name}对应的app_check_url，请检查project_config.ini配置" >> ${log_path}
  exit -1
fi

for (( i = 0; i < ${#deploy_list[@]}; i++ )); do
  run_container_on_server=${deploy_list[i]}
  parms=(${run_container_on_server//,/ })

  server_name=${parms[0]}
  docker_image_tag=${parms[1]}
  image_tags=(${docker_image_tag//-/ })
  deploy_app_name=${image_tags[0]}
  if [ "x${app_name}" == "x${deploy_app_name}" ]; then
#    echo "~/bin/deploy_project/build_project.sh ${server_name} ${app_name}"
    ~/bin/deploy_project/build_project.sh ${server_name} ${app_name}
  fi
done
