#!/bin/bash
#创建用户
#db.createUser(
#     {
#       user:"root",
#       pwd:"123456",
#       roles:[{role:"root",db:"admin"}]
#     }
#  )

#https://docs.mongodb.com/manual/reference/program/mongostat/index.html
#inserts
#每秒插入数据库的对象数。如果后跟星号（例如*），则数据指的是复制操作。
#query
#每秒查询操作的数量。
#update
#每秒更新操作的数量。
#delete
#每秒删除操作的数量。
#getmore
#每秒获得更多（即游标批处理）操作的数量。
#command
#每秒的命令数。在 辅助系统上，以命令的形式mongostat呈现由管道字符（例如|） 分隔的两个值local|replicated。
#flushes
#在3.0版中更改。
#对于WiredTiger存储引擎，flushes指的是在每个轮询间隔之间触发的WiredTiger检查点的数量。
#对于MMAPv1存储引擎，flushes表示每秒的 fsync操作数。
#dirty
#3.0版中的新功能。
#仅适用于WiredTiger存储引擎。带有脏字节的WiredTiger缓存的百分比，由 / 计算 。wiredTiger.cache.tracked dirty bytes in the cachewiredTiger.cache.maximum bytes configured
#used
#3.0版中的新功能。
#仅适用于WiredTiger存储引擎。正在使用的WiredTiger缓存的百分比，由/ 计算 。wiredTiger.cache.bytes currently in the cachewiredTiger.cache.maximum bytes configured
#mapped
#在3.0版中更改。
#仅适用于MMAPv1存储引擎。以兆字节为单位映射的数据总量。这是上次mongostat呼叫时的总数据大小 。
#vsize
#上次mongostat调用时进程使用的虚拟内存量（兆字节）。
#non-mapped
#在3.0版中更改。
#仅适用于MMAPv1存储引擎。
#可选。在最后一次mongostat调用时排除所有映射内存的虚拟内存总量。
#mongostat使用该--all选项启动时仅返回此值 。
#res
#上次mongostat调用时进程使用的驻留内存量（兆字节）。
#faults
#在3.0版中更改。
#仅适用于MMAPv1存储引擎。每秒页面错误的数量。
#版本2.1中已更改：在版本2.1之前，此值仅适用于在Linux主机上运行的MongoDB实例。
#lr
#版本3.2中的新功能。
#仅适用于MMAPv1存储引擎。必须等待的读锁定获取百分比。 锁定获取等待时mongostat显示lr|lw。
#lw
#版本3.2中的新功能。
#仅适用于MMAPv1存储引擎。写锁定获取的百分比必须等待。 锁定获取等待时mongostat显示lr|lw。
#lrt
#版本3.2中的新功能。
#仅适用于MMAPv1存储引擎。等待读取锁定采集的平均获取时间（以微秒为单位）。 锁定获取等待时mongostat显示lrt|lwt。
#lwt
#版本3.2中的新功能。
#仅适用于MMAPv1存储引擎。等待的写锁定采集的平均获取时间（以微秒为单位）。 锁定获取等待时mongostat显示lrt|lwt。
#locked
#在3.0版中更改：仅在mongostat针对3.0之前版本的MongoDB实例运行时出现。
#全局写锁定中的时间百分比。
#idx miss
#在3.0版中更改。
#仅适用于MMAPv1存储引擎。需要页面错误才能加载btree节点的索引访问尝试的百分比。这是一个采样值。
#qr
#等待从MongoDB实例读取数据的客户端队列的长度。
#qw
#等待从MongoDB实例写入数据的客户端队列的长度。
#ar
#执行读取操作的活动客户端数。
#aw
#执行写入操作的活动客户端数。
#netIn
#MongoDB实例接收的网络流量（以字节为单位）。
#这包括来自mongostat自己的流量。
#netOut
#MongoDB实例发送的网络流量（以字节为单位）。
#这包括来自mongostat自己的流量。
#conn
#打开连接的总数。
#set
#副本集的名称（如果适用）。
#repl
#成员的复制状态。
#值	复制类型
#中号	主
#SEC	次要
#REC	恢复
#UNK	未知
#RTR	mongos进程（“路由器”）
#ARB	仲裁者
/data/tools/mongodb/bin/mongostat -h XXX --port XXX -u admin -p admin --authenticationDatabase=admin --rowcount 0  60
/data/tools/mongodb/bin/mongotop -h XXX --port XXX -u admin -p admin --authenticationDatabase=admin --rowcount 0  60

