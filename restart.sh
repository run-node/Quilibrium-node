#!/bin/bash

# 无限循环
while true; do
    # 获取当前时间
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # 发送 SIGTERM 信号终止指定的进程
    echo "[$timestamp] Terminating process node-2.0.1-linux-amd64..."
    pkill -SIGTERM -f node-2.0.1-linux-amd64

    # 等待10秒
    echo "[$timestamp] Waiting for 10 seconds..."
    sleep 10

    # 关闭所有匹配条件的 screen 会话
    echo "[$timestamp] Closing detached screen sessions..."
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话并执行指定命令
    echo "[$timestamp] Starting new screen session for Quili..."
    screen -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./node-2.0.1-linux-amd64'

    # 等待10分钟
    echo "[$timestamp] Waiting for 10 minutes..."
    sleep 600

    # 更新时间戳
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] Cycle completed. Restarting process..."
done
