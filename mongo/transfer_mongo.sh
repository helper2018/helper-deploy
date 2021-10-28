#!/bin/bash
#备份
mongodump -h XXX --port XXX -u XXX -p XXX -d XXX -o /data/mongodb-bakup
#恢复 --drop 恢复的时候，先删除当前数据，然后恢复备份的数据。就是说，恢复后，备份后添加修改的数据都会被删除，慎用哦！
mongorestore -h XXX --port XXX -u XXX -p XXX -d XXX  /data/mongodb-bakup