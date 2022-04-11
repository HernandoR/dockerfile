#!/usr/bin/env sh

# 当容器作为脚本运行时, 此进程为容器的主进程
# 此脚本的参数, 为当前容器需要定时运行的所有内容. 依次传递


# 清空, 防止容器重启时, 重复写入
echo "" > /etc/cron.d/auto-run
# 接收所有的定时命令并写入到定时执行命令中
for i in "$@";
do
  echo "$i" >> /etc/cron.d/auto-run
done
cron
IsRunning=true
# 这里在接到停止命令的第一时间, 将定时任务清空, 因为后面还要等待, 不能再次运行新的脚本了
trap "echo 'waiting stop...' && IsRunning=false && echo '' > /etc/cron.d/auto-run" TERM QUIT
while $IsRunning; do sleep 1;done
# 等待当前所有进程结束
while  ps -ef | grep -v grep | grep -v /bin/run_cron | grep -v ps | grep -v sleep | grep -v cron | grep -v sed | sed -n '1!p' | grep -c '';do sleep 1;done
