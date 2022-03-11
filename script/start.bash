#!/usr/bin/env bash

# 调用 init 脚本
chmod +x /opt/init.bash
/opt/init.bash
# 启动 4 个 worker 进程
nohup fcgiwrap -f -c 4 -s unix:/run/fcgiwrap.socket </dev/null &>/dev/null &
# 这里等待 socket 文件创建出来. 若立马执行 chown 命令, 文件可能不存在
until ls /run/fcgiwrap.socket; do sleep 0.1; done
chown nginx:nginx /run/fcgiwrap.socket

# 根据环境变量 修改 nginx 配置文件
sed -i "s/listen 80 default_server;/listen $LISTEN_PORT default_server;/" /etc/nginx/conf.d/default.conf

# 启动 nginx
exec /docker-entrypoint.sh nginx -g "daemon off;"