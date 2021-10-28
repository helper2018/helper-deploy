#!/bin/bash
config_path="/data/project/${DK_APP_NAME}/${DK_APP_NAME}-config"
if [ -f "${config_path}" ];then
    echo "修改默认环境变量如下"
    while read line
        do
            echo $line
            eval $line
        done <  "${config_path}"
else
    echo "# 容器项目运行环境配置文件，可通过修改配置改变运行配置，重启容器后生效-谨慎修改，主要用于参数调优" > ${config_path}
    echo "DK_RUN_ENV_PROFILE=\"${DK_RUN_ENV_PROFILE}\"" >> ${config_path}
    echo "DK_JAVA_OPTIONS=\"${DK_JAVA_OPTIONS}\"" >> ${config_path}
    echo "DK_APP_NAME=\"${DK_APP_NAME}\"" >> ${config_path}
    echo "DK_JAR_NAME=\"${DK_JAR_NAME}\"" >> ${config_path}
    echo "DK_APP_CHECK_URL=\"${DK_APP_CHECK_URL}\"" >> ${config_path}
    echo "# 默认使用应用配置文件的端口server.port" >> ${config_path}
    echo "DK_SERVER_PORT=" >> ${config_path}
fi

if [ -z "${DK_SERVER_PORT}" ];then
    echo "未指定端口运行应用"
    exec java ${DK_JAVA_OPTIONS} -jar /data/project/jar/${DK_JAR_NAME} --spring.profiles.active=${DK_RUN_ENV_PROFILE}
else
    echo "指定端口：${DK_SERVER_PORT}运行应用"
    exec java ${DK_JAVA_OPTIONS} -jar /data/project/jar/${DK_JAR_NAME} --server.port=${DK_SERVER_PORT} --spring.profiles.active=${DK_RUN_ENV_PROFILE}
fi