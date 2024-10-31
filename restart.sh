#!/bin/bash

# 第一轮等待时间（20分钟）
initial_wait_time=1200

# 后续循环等待时间（10分钟）
subsequent_wait_time=600

# 无限循环
while true; do
    # 获取当前时间
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # 发送 SIGTERM 信号终止指定的进程
    echo "[$timestamp] Terminating process node-2.0.2.3-linux-amd64..."
    pkill -SIGTERM -f node-2.0.2.3-linux-amd64

    # 等待10秒
    echo "[$timestamp] Waiting for 10 seconds..."
    sleep 10

    # 关闭所有匹配条件的 screen 会话
    echo "[$timestamp] Closing detached screen sessions..."
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话并执行指定命令
    echo "[$timestamp] Starting new screen session for Quili..."
    > /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./node-2.0.2.3-linux-amd64'

    # 等待第一轮的20分钟
    if [ "$initial_wait_time" -eq 1200 ]; then
        echo "[$timestamp] Waiting for the initial 20 minutes..."
        sleep "$initial_wait_time"
    else
        # 等待后续的10分钟
        echo "[$timestamp] Waiting for 10 minutes..."
        sleep "$subsequent_wait_time"
    fi

    # 更新时间戳
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] Cycle completed. Restarting process..."

    # 设置初始等待时间为后续循环的等待时间
    initial_wait_time=0
done
