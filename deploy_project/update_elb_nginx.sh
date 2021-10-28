#!/bin/bash
set +e
# ./update_elb_nginx.sh app1 127.0.0.1 0

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
server_ip=$2
weight=$3

for (( i = 0; i < ${#app_names[@]}; i++ )); do
  if [ "x${app_names[i]}" == "x${app_name}" ]; then
    app_ports=(${app_expose_ports[i]})
    app_port=${app_check_ports[0]}
    break
  fi
done

server_port=$3
conf_path="/data/tools/nginx/conf/conf.d/${app_name}.conf"
# 修改服务权重
sed -i.bak 's/server '${server_ip}':'${app_port}'.*/server '${server_ip}':'${app_port}' weight='${weight}';/g' ${conf_path}
# 重启nginx服务
/data/tools/nginx/sbin/nginx -s reload