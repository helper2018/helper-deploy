#!/bin/bash
set -e
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

echo "第一台服务器名称:${server_names[1]}"
echo "第一台服务器权重:${server_weights[1]}"
echo "第一个应用名称  :${app_names[1]}"
echo "第一个应用jar   :${jar_names[1]}"
echo "第一个应用端口  :${app_expose_ports[1]}"