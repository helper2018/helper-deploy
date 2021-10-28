#!/bin/bash
set +e

host_ip=$1
host_port=$2
instance_status=$3

curl -s -X "POST" -H "Content-type:text/plain;charset=utf8" --data "${instance_status}" "http://${host_ip}:${host_port}/service-monitor/service-registry/instance-status"

# 查看状态
#curl -s -X "GET" -H "Content-type:text/plain;charset=utf8" "http://${host_ip}:${host_port}/service-monitor/service-registry/instance-status"
