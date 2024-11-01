#!/bin/bash

# 发送 SIGTERM 信号终止指定的进程
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Terminating process node-2.0.2.3-linux-amd64..."
pkill -SIGTERM -f node-2.0.2.3-linux-amd64

# 等待10秒
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Waiting for 10 seconds..."
sleep 10

# 关闭所有匹配条件的 screen 会话
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Closing detached screen sessions..."
screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

# 启动新的 screen 会话并执行指定命令
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting new screen session for Quili..."
> /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./node-2.0.2.3-linux-amd64'

# 无限循环
while true; do
    # 初始化上一个 ts 和 increment 值
    previous_ts=""
    previous_increment=""

    # 循环监听 increment 值
    while true; do
        # 从日志中获取最新的 increment 值
        line=$(grep "increment" /root/screen_log.txt | tail -n 1)
        
        if [[ -z "$line" ]]; then
            echo "没有找到 increment 值，等待..."
            sleep 5
            continue
        fi

        ts=$(echo "$line" | grep -oP '"ts":\K[0-9.]+')
        increment=$(echo "$line" | grep -oP '"increment":\K[0-9]+')
        
        # 格式化时间
        formatted_time=$(date -u -d @"${ts}" +"%Y-%m-%d %H:%M:%S" --utc)
        formatted_time=$(date -d "${formatted_time} +8 hours" +"%Y-%m-%d %H:%M:%S")

        # 输出当前时间和 increment 值
        echo "当前时间: ${formatted_time} ---- increment: ${increment}"

        # 检查条件：如果 ts 不同且 increment 相同
        if [[ "$increment" == "$previous_increment" && "$ts" != "$previous_ts" ]]; then
            echo "Increment 值相同且 ts 不同，准备进行下一轮循环..."
            break  # 退出内层循环，进行下一轮的重启过程
        fi

        # 检查当前时间戳是否大于10分钟
        current_ts=$(date +%s)
        ts_int=${ts%.*}  # 去掉小数部分
        if (( current_ts - ts_int > 600 )); then
            echo "当前时间戳大于10分钟，准备进行重启..."
            break  # 退出内层循环，进行下一轮的重启过程
        fi

        # 更新上一个 ts 和 increment 值
        previous_ts="$ts"
        previous_increment="$increment"

        # 等待一段时间再继续监听
        sleep 5
    done

    # 发送 SIGTERM 信号终止指定的进程
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Terminating process node-2.0.2.3-linux-amd64..."
    pkill -SIGTERM -f node-2.0.2.3-linux-amd64

    # 等待10秒
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Waiting for 10 seconds..."
    sleep 10

    # 关闭所有匹配条件的 screen 会话
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Closing detached screen sessions..."
    screen -ls | grep Detached | grep Qui | awk -F '[.]' '{print $1}' | xargs -I {} screen -S {} -X quit

    # 启动新的 screen 会话并执行指定命令
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting new screen session for Quili..."
    > /root/screen_log.txt && screen -L -Logfile /root/screen_log.txt -dmS Quili bash -c 'cd ~/ceremonyclient/node && ./node-2.0.2.3-linux-amd64'
done
