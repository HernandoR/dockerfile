#!/usr/bin/env bash
# 下载配置文件

ConfFile=$1
ConfPath=`dirname $ConfFile`
mkdir -p $ConfPath
wget -O $ConfFile  "$CONF_URL"
# 若文件下载失败, 则返回并报错
if [ $? -ne 0 ];
then
  echo "config file download fail"
  exit $?
fi

# 写入 API端口
if [[ ! -z "$EXTERNAL_BIND" ]];
then
 EXTERNAL_BIND="127.0.0.1"
fi
if [[ ! -z "$EXTERNAL_PORT" ]];
then
 EXTERNAL_PORT="9090"
fi
if [[ ! -z "$EXTERNAL_SECRET" ]];
then
 EXTERNAL_SECRET="\"\""
fi

sed -i 's|external-controller:.*|external-controller: $EXTERNAL_BIND:$EXTERNAL_PORT|g' $ConfFile
sed -i 's|secret:.*|secret: "$EXTERNAL_SECRET"|g' $ConfFile
sed -i 's|allow-lan:.*|allow-lan: true|g' $ConfFile

