#!/bin/bash

log_path="/data/project/log/log-clear.log"

# 服务器名称
server_names=("dev1" "dev2")

# 清理jar
echo "`date +%Y%m%d_%H%M%S` 开始清理构建服务器过时jar" >> ${log_path}
cd /data/project/bin
rm -rf *.jar.*

echo "`date +%Y%m%d_%H%M%S` 开始清理容器日志" >> ${log_path}

for server_name in ${server_names[@]}
    do
        server_no=${server_name:0-1:1}
        if [ x${server_no} = x"1" ] ; then
            logs=`find /var/lib/docker/containers/ -name *-json.log`
            for container_log in $logs
                do
                    # 清空容器日志
                    echo "日志：${container_log}"
                    cat /dev/null > ${container_log}
                done
        else
            logs=`ssh ${server_name} find /var/lib/docker/containers/ -name *-json.log`
            for container_log in $logs
                do
                    # 清空容器日志
                    echo "日志：${container_log}"
                    ssh ${server_name} "cat /dev/null > ${container_log}"
                done
        fi
    done
