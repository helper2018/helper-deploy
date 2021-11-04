## 以 centos 7 服务器为例搭建服务器环境
***说明:***
* (root)：表示以root用户执行下面的指令
* (app)：表示以app用户执行下面的指令
----
[toc]
## 一. 服务器环境搭建
### 1.创建用户(root)
```shell
# 新增app用户
adduser app

# 设置密码
passwd app

# 设置sudo权限
usermod -aG wheel app

# 修改用户的uid和gid，记住这个2000，后续docker需要用到
usermod -u 2000 app
groupmod -g 2000 app

# 检查sudo权限、uid、gid是否生效
cat /etc/group |grep app

# 其他命令
#查看系统中有哪些用户：cut -d : -f 1 /etc/passwd
#查看可以登录系统的用户：cat /etc/passwd | grep -v /sbin/nologin | cut -d : -f 1
#查看用户操作：w (需要root权限)
#查看某一用户：w 用户名
#查看登录用户：who
#查看用户登录历史记录：last
```
### 2.系统升级并安装toa内核(toa内核在centos 7.6系统测试通过，其他版本未测试)(root)(可选)
* toa内核升级非必须，toa主要解决tcp协议应用通过负载均衡后获取不到客户端的真实IP的场景，如果无此问题可只更新系统
```shell
# 修改yum源(先备份，替换为阿里云的yum源)
sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bakup
sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

# 生成缓存
yum makecache

# 更新系统
yum -y update

# 下载toa内核
cd ~
wget http://docs-aliyun.cn-hangzhou.oss.aliyun-inc.com/assets/attach/44520/intl_en/1565937758425/kernel-3.10.0-957.21.3.el7.toa.x86_64.rpm

# 安装内核和相关依赖
sudo yum localinstall kernel-3.10.0-957.21.3.el7.toa.x86_64.rpm

# 查看已安装内核
rpm -qa |grep kernel

# 查看可用启动内核
sudo cat /boot/grub2/grub.cfg

# 设置使用toa内核作为系统启动默认内核
sudo grub2-set-default 'CentOS Linux (3.10.0-957.21.3.el7.toa.x86_64) 7 (Core)'

# 设置开启加载toa模块
vi toa.modules
chmod +x toa.modules
sudo cp toa.modules /etc/sysconfig/modules/

> cat toa.modules
!/bin/bash
if [ -e /lib/modules/`uname -r`/kernel/net/toa/toa.ko.xz ] ; then
  modprobe toa > /dev/null 2>&1
fi

# 重启服务器
sudo reboot
```

### 3.ssh保活设置(root)(可选)
```shell
# 找到 TCPKeepAlive yes 把前面的#去掉
# 找到 ClientAliveInterval 把前面的#去掉
# ClientAliveInterval 60  把后面的0改成60
vi /etc/ssh/sshd_config
service sshd restart
```

### 4.根据服务器的环境属性修改hostname方便管理，重新登录后生效(root)
```shell
hostnamectl set-hostname prod1
```

### 5.检查系统文件资源限制(root)
```shell
# 查看系统允许打开文件的最大个数（和内存有关）
cat /proc/sys/fs/file-max

# 查看资源限制的详细信息：
cat /proc/self/limits

# 查看程序默认资源的限制
ulimit -a

# 修改限制
vi /etc/security/limits.conf
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
```

### 6.配置ssh免密登录(app)
```shell
# 在自己的电脑上执行，一直回车，不输入密码。参考 https://code.aliyun.com/help/ssh/README
ssh-keygen -t rsa -C "xxx@qq.com"

# 打印到控制台，下面会用到
# linux or mac
cat ~/.ssh/id_rsa.pub
# Windows:
clip < ~/.ssh/id_rsa.pub

# 服务器上执行(app)
# 创建并修改权限
mkdir ~/.ssh
chmod 700 ~/.ssh

# 新建authorized_keys文件并粘贴id_rsa.pub内容
vi ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 测试免密登录
ssh app@prod1
```

## 二. 项目构建环境搭建
### 1.项目目录创建及授权(建议项目和构建工具统一放在/data目录下)(root)
```shell
mkdir -p /data/project
mkdir -p /data/tools
mkdir -p /data/tools/src
sudo chown -R app:app /data
```
### 2.安装jdk(和开发环境使用相同的jdk版本)(app)
```shell
# 从本地复制jdk并解压缩到/data/tools/java目录下，配置Java环境变量
scp jdk-8u181-linux-x64.tar.gz app@prod1:/data/tools/
```
### 3.安装git(app)
```shell
sudo yum install git
```
### 4.安装mvn(app)
```shell
# 下载并解压缩到/data/tools/maven目录下，配置MVN环境变量
wget https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
```
### 5.安装jq(app)(可选)
```shell
# 编写shell命令时用于解析接口的返回值(json解析)，无此需求可不用安装
sudo yum install jq
```
### 6.安装nginx(app)(可选)
```shell
# 增加nginx用户
sudo adduser nginx --system --no-create-home --user-group

# 下载并解压缩到/data/tools/src目录并安装相关软件依赖
wget http://nginx.org/download/nginx-1.16.1.tar.gz
sudo yum -y install openssl-devel
sudo yum -y install pcre-devel
sudo yum -y install gd-devel
sudo yum -y install GeoIP-devel
sudo yum -y install gperftools-devel

# 执行configure --help 查看帮助
cd /data/tools/src/nginx-1.16.1
./configure --prefix=/data/tools/nginx --sbin-path=/data/tools/nginx/sbin/nginx --modules-path=/data/tools/nginx/modules --conf-path=/data/tools/nginx/conf/nginx.conf --error-log-path=/data/tools/nginx/logs/error.log --http-log-path=/data/tools/nginx/logs/access.log --pid-path=/data/tools/nginx/run/nginx.pid --lock-path=/data/tools/nginx/run/nginx.lock --http-client-body-temp-path=/data/tools/nginx/cache/client_temp --http-proxy-temp-path=/data/tools/nginx/cache/proxy_temp --http-fastcgi-temp-path=/data/tools/nginx/cache/fastcgi_temp --http-uwsgi-temp-path=/data/tools/nginx/cache/uwsgi_temp --http-scgi-temp-path=/data/tools/nginx/cache/scgi_temp --user=nginx --group=nginx --build=nginx --builddir=/data/tools/nginx-build --with-threads --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_addition_module --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_gzip_static_module --with-http_auth_request_module --with-http_slice_module --with-http_stub_status_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-google_perftools_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'

# 开始编译并安装
make&make install

# 增加配置文件(详见nginx.conf)
cd /data/tools/nginx/conf
vi /data/tools/nginx/conf/nginx.conf

# http、https配置文件目录(详见nginx.conf)
mkdir conf.d

# tcp、udp配置文件目录
mkdir stream.d
mkdir -p /data/tools/nginx/cache/client_temp
# 大文件执行时需要用到，无权限时时会报错
sudo chomod +777 /data/tools/nginx/cache

# 启动nginx
sudo /data/tools/nginx/sbin/nginx
sudo /data/tools/nginx/sbin/nginx -t
sudo /data/tools/nginx/sbin/nginx -s reload

# nginx设置开机启动
cd /lib/systemd/system/
# 增加nginx服务
sudo vi nginx.service

> sudo cat nginx.service
[Unit]
Description=nginx service
After=network.target

[Service]
Type=forking
ExecStart=/data/tools/nginx/sbin/nginx
ExecReload=/data/tools/nginx/sbin/nginx -s reload
ExecStop=/data/tools/nginx/sbin/nginx -s quit
PrivateTmp=true

[Install]

# 设置开机启动
sudo systemctl enable nginx
```

### 7.增加maven、java、nginx环境变量(app)
```shell
# 增加环境变量配置
vi  ~/.bash_profile
#修改如下
PATH=$PATH:/data/tools/maven/bin:/data/tools/java/bin:/data/tools/nginx/sbin
# maven编译参数，根据配置定(可选)
MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=512m"
export MAVEN_OPTS
```

## 三. 数据迁移
### 1.mysql数据库迁移
```shell
# 找一台安装有mysql服务端的服务器来执行备份mysql数据库
mkdir mysql
cd mysql
mysqldump --host 127.0.0.1 --port 3306 --user XXX --password=XXX XXX  > XXX.sql
# 创建SCHEMA
CREATE SCHEMA `XXX` DEFAULT CHARACTER SET utf8mb4 ;
# 创建用户
CREATE USER 'XXX'@'%' IDENTIFIED BY 'XXX';

# 上一步的备份sql可以直接在新的数据库执行sql
# mysql/XXX.sql数据文件
docker cp mysql mysql:/
docker exec -it mysql /bin/bash
> mysql --host 127.0.0.1 --port 3306 --user XXX --password=XXX XXX < /mysql/XXX.sql
```

### 2.mongo迁移
```shell
# 备份文档结构
# 安装命令工具
wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel70-x86_64-100.5.1.tgz
# 备份
./mongodump --host 127.0.0.1 --port 27071 -u XXX -p XXX --excludeCollection=XXX --excludeCollection=XXX -d XXX -o /home/app/bakup/mongo

# 登录mongo数据库
mongo --host 数据库主机host --port 数据库端口 -u 数据库用户名 -p 数据库密码 -d 数据库名称

# 使用root用户(先创建，角色root)创建数据库，创建用户
mongo >
db.runCommand({
"createUser":"用户名",
"pwd":"数据库密码",
"roles":[
{
"db":"数据库名称",
"role":"readWrite"
}
]
});

# 恢复文档结构
# mongo/XXX数据文件
docker cp mongo mongo:/
docker exec -it mongo mongorestore --host 127.0.0.1 --port 27017 -u XXX -p XXX -d XXX /mongo/XXX
docker exec -it mongo rm -rf /mongo
```

## 四. 容器环境搭建
### 1.安装docker(app)
```shell
# 下载并执行安装
curl -sSL https://get.docker.com/ | sh

# 容器加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://5h6t1v1q.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

# 执行完成后需退出重新登录
sudo usermod -aG docker app

# 启动
systemctl start docker
service docker start

# 守护进程重启
sudo systemctl daemon-reload

# 重启docker服务
systemctl restart docker
sudo service docker restart

# 关闭docker
systemctl stop docker
service docker stop

# 查看版本
docker --version

# 设置开机启动
systemctl enable docker
```

## 五. 项目构建及发布(将***远邦益安阿里云生产环境配置***下的文件夹复制到~/bin目录下)
### 1.代码下载(先配置代码库ssh免密访问)(app)
```shell
mkdir -p data/project/code
cd data/project/code
git clone ssh://xxx@xxx:xxx/xxx.git
```

### 2.创建容器(bin目录：~/bin/create_image)(app)
```shell
cd ~/bin/create_image
./create-image.sh
```

### 3.首次运行容器(bin目录：~/bin/run_container)(app)
```shell
cd ~/bin/run_container/
./run_container.sh
```

### 4.迭代发布应用(bin目录：~/bin/deploy_project)(app)
cd ~/bin/deploy_project
./all_server.sh 应用名

### 5.负载均衡配置
* 为应用添加nginx配置文件(/data/tools/nginx/conf/conf.d/):应用名.conf
```text
upstream app1 {
    server 192.168.0.1: weight=7;
    server 192.168.0.2: weight=0;
}

server {
    listen       8010;
    server_name  127.0.0.1;

    location / {
         proxy_pass http://app1;
    }
}
```

### 7.容器批量清理(app)
```shell
docker rm $(docker stop $(docker ps -aq))
docker rmi $(docker images -aq)
rm -rf /data/project/*
```

### 8.访问https://hub.docker.com/拉取mysql、mongo、rabbitmq、redis镜像
```shell
# mysql
docker pull mysql:5.7.36
docker run  -h mysql --network host -m 2g --memory-swap 2g -c 2048 --restart=on-failure:3 \
  -it -d -v /data/project/mysql/data:/var/lib/mysql -v /data/project/mysql/conf:/etc/mysql/conf.d \
  -e MYSQL_ROOT_PASSWORD=XXX --name mysql mysql:5.7.36

# mongo
docker pull mongo:4.4
/var/log/mongodb/mongod.log /var/lib/mongodb
docker run  -h mongo --network host -m 2g --memory-swap 2g -c 2048 --restart=on-failure:3 \
  -it -d -v /data/project/mongo/configdb:/data/configdb -v /data/project/mongo/db:/data/db \
  --name mongo mongo:4.4 --auth
docker exec -it mongo mongo admin
db.createUser({ user:'XXX',pwd:'XXX',roles:[ { role:'root', db: 'admin'}]});
use XXX
db.createUser({ user:'XXX',pwd:'XXX',roles:[ { role:'readWrite', db: 'XXX'}]});

# rabbit
docker pull rabbitmq:3.9.8-management
docker run  -h rabbitmq --network host -m 512m --memory-swap 521m -c 512 --restart=on-failure:3 \
  -it -d -v /data/project/rabbitmq:/var/lib/rabbitmq \
  -e RABBITMQ_DEFAULT_USER=XXX -e RABBITMQ_DEFAULT_PASS=XXX \
  --name rabbitmq rabbitmq:3.9.8-management
# 新增用户

# redis
docker pull redis:6.2.6
docker run  -h redis --network host -m 512m --memory-swap 512m -c 1024 --restart=on-failure:3 \
  -it -d -v /data/project/redis/data:/data \
  --name redis redis:6.2.6 --appendonly yes --requirepass XXX
```

## 六. 服务器运维
### 1.定时任务脚本(app)

* auto_build_project.sh
* monitor_service.sh
* server_clear.sh
```text
# 配置定时任务
service crond restart
service crond status
sudo vi /etc/crontab

*/10 * * * * app ~/bin/monitor/monitor_service.sh check >> /data/project/log/monitor_service.log
0 0 * * * root /home/app/bin/monitor/server_clear.sh >> /data/project/log/server_clear.log
0 2 * * * app ~/bin/monitor/auto_build_project.sh >> /data/project/log/auto_build_project.log
```
### 2.长时间未执行完成的sql kill
* mysql_long_running_query_monitor
* mysql 长时间查询事件监控：每过10分钟超过10秒没有执行完成的sql直接kill
```sql
begin
  declare v_sql varchar(500);
  declare no_more_long_running_query integer default 0;
  declare c_tid cursor for
    select concat ('kill ',id,';') from
    information_schema.processlist
    where time >= 10
    and user = substring(current_user(),1,instr(current_user(),'@')-1)
    and command not in ('sleep')
    and state not like ('waiting for table%lock');
  declare continue handler for not found
    set no_more_long_running_query=1;

  open c_tid;
  repeat
    fetch c_tid into v_sql;
    set @v_sql=v_sql;
    prepare stmt from @v_sql;
    execute stmt;
    deallocate prepare stmt;
  until no_more_long_running_query end repeat;
  close c_tid;
end

```

```sql
drop event `mysql_long_running_query_monitor`;

delimiter |
CREATE EVENT `mysql_long_running_query_monitor`
  ON SCHEDULE EVERY 10 MINUTE
  STARTS  '2019-03-27 15:48:29'  ON COMPLETION PRESERVE
  ENABLE
  COMMENT 'mysql 长时间查询事件监控：每过10分钟超过10秒没有执行完成的sql直接kill'
  DO begin
  declare v_sql varchar(500) default "select 1;";
  declare no_more_long_running_query integer default 0;
  declare c_tid cursor for
    select concat ('kill ',id,';') from
    information_schema.processlist
    where time >= 10
    and user = substring(current_user(),1,instr(current_user(),'@')-1)
    and command not in ('sleep')
    and state not like ('waiting for table%lock');
  declare continue handler for not found
    set no_more_long_running_query=1;

  open c_tid;
  repeat
    fetch c_tid into v_sql;
    set @v_sql=v_sql;
    prepare stmt from @v_sql;
    execute stmt;
    deallocate prepare stmt;
  until no_more_long_running_query end repeat;
  close c_tid;
end |
delimiter ;
```

## 七. 其他配置

### 1.配置websocket 证书

```shell
# 下载Nginx类型的证书
openssl pkcs8 -topk8 -nocrypt -in XXX.key -out server.key
mv XXX.pem server.crt
```