#!/bin/bash
# 生产环境暂时不使用自动构建项目
log_path="/data/project/log/auto_build_project.log"
echo "`date +%Y%m%d_%H%M%S` 开始自动构建和发布以下项目" >> ${log_path}
#进入bin目录自动构建项目
cd ~/bin/deploy_project
# 需要定时发布的app_name
#./all_server.sh XXX >> ${log_path}
echo "`date +%Y%m%d_%H%M%S` 完成" >> ${log_path}


