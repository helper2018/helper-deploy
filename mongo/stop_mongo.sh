#!/bin/bash
# 登录数据库执行：db.shutdownServer();
# 带数据目录，关闭服务器，安全
/data/tools/mongodb/bin/mongod --shutdown --config /data/tools/mongodb/conf/mongod.conf
/data/tools/mongodb/bin/mongod --shutdown --config /data/tools/mongodb-rs1/conf/mongod.conf
/data/tools/mongodb/bin/mongod --shutdown --config /data/tools/mongodb-rs2/conf/mongod.conf

