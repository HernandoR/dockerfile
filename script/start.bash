#!/usr/bin/env bash

# 调用 init 脚本
chmod +x /opt/init.bash
/opt/init.bash
# 启动 4 个 worker 进程
rm /run/fcgiwrap.socket # 防止容器上次强制停止, socket 仍然存在
nohup fcgiwrap -f -c $MAX_CONCURRENT -s unix:/run/fcgiwrap.socket > /dev/stderr 2>&1 &
# 这里等待 socket 文件创建出来. 若立马执行 chown 命令, 文件可能不存在
until ls /run/fcgiwrap.socket; do sleep 0.1; done
chown nginx:nginx /run/fcgiwrap.socket

# 启动 nginx
exec /docker-entrypoint.sh nginx -g "daemon off;"