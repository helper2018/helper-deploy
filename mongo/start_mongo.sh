#!/bin/bash
/data/tools/mongodb/bin/mongod --config /data/tools/mongodb/conf/mongod.conf --replSet rs
/data/tools/mongodb/bin/mongod --config /data/tools/mongodb-rs1/conf/mongod.conf --replSet rs
/data/tools/mongodb/bin/mongod --config /data/tools/mongodb-rs2/conf/mongod.conf --replSet rs

#MongoDB基本的角色

#1.数据库用户角色：read、readWrite;
#2.数据库管理角色：dbAdmin、dbOwner、userAdmin；
#3.集群管理角色：clusterAdmin、clusterManager、clusterMonitor、hostManager；
#4.备份恢复角色：backup、restore；
#5.所有数据库角色：readAnyDatabase、readWriteAnyDatabase、userAdminAnyDatabase、dbAdminAnyDatabase
#6.超级用户角色：root

##1.配置复制集
#config = {
#_id: 'rs', members: [
#{_id: 0, host: 'XXX:XXX',priority:1},
#{_id: 1, host: 'XXX:XXX'}]
#}
#rs.initiate(config);
#
## 查看复制集状态
#rs.status()
## 在primary节点上查看复制集状态：
#rs.isMaster()

##2.创建用户，授予角色
#db.createUser(
#     {
#       user:"XXX",
#       pwd:"XXX",
#       roles:[{role:"root",db:"admin"}]
#     }
#  )

##3.查询复制集信息
#use local
#show collections
#db.oplog.rs.find()

##查看master的oplog元数据信息：
#db.printReplicationInfo()

##查看salve的同步状态：
#db.printSlaveReplicationInfo()
#db.system.replset.find();

##4.让从库可以读，分担主库的压力
#>db.getMongo().setSlaveOk()
