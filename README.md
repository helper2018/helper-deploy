# helper-deploy
spring boot 项目生产级、轻量级自动部署脚本及流程

### 1.服务器配置(doc/)
* 请按server_config.md步骤配置您的应用服务器

## ***以下命令请用app用户执行***
### 2.修改项目配置文件(config/)
* 请按说明修改***project_config.ini***配置，完成后执行 *./load_project_config.sh* ，查看配置是否正确。
```shell
# 进入 config/ 目录执行
./load_project_config.sh
```

### 3.创建docker镜像并推送到docker镜像仓库(create_image/)
```shell
# 进入 create_image/ 目录执行
./create_images.sh
```

### 4.首次构建项目并运行容器(run_container/)
```shell
# 进入 run_container/ 目录执行，请提前配置号deploy_list属性
./run_container
```

### 5.后续发布项目(deploy_project/)
```shell
# 进入 deploy_project/ 目录执行(project_config.ini中app_names中的应用名)
./all_server.sh 应用名称
```

### 6.应用状态监控(配置定时任务实现)(monitor/)
* auto_build_project.sh 自动构建发布应用(开发、测试环境使用)
* server_clear.sh 发布jar清理、docker容器日期清理
* monitor_service.sh 服务监控并发送短信通知

### 7.mongo自建常用命令(mongo/)
* mongo 常用命令

### 8.使用ssh批量执行命令(server/)(默认使用root执行命令且配置了免密ssh)(可选)
```shell
# 进入 server/ 目录执行
# server_host 设置你要执行命令的服务器IP地址
# 修改 init_server.sh 需要执行的命令
./server_ssh.sh server_host init_server.sh 
```