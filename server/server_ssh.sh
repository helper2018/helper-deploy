#!/bin/bash
if [ "$#" -ne 2 ];then
    echo "USAGE: $0 -f server-host cmd"
    exit -1
fi

server_host=$1
cmd_str=$2

if [ ! -e $server_host ];then
    echo "server host not exist"
    exit 0
fi

while read server
do
    if [ -n "$server" ];then
        echo "server $server start excute"
        ssh -t root@$server $cmd_str < /dev/null
        if [ $? -eq 0 ];then
            echo "$server $cmd_str success"
        else
            echo "$server error: $?"
        fi
    fi
done < $server_host
