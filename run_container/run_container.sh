#!/bin/bash

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

for (( i = 0; i < ${#deploy_list[@]}; i++ )); do
  ./run_container_on_server.sh ${deploy_list[i]}
done

