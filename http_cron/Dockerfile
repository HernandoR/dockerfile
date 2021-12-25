FROM debian:10.10

COPY sources.list /etc/apt/sources.list
COPY start.pl /opt/start.pl
COPY response.pl /opt/response.pl
COPY init.bash /opt/init.bash

# 此为脚本运行目录
ENV WORKSPACE /opt/script
ENV LISTEN_PORT 80

RUN apt update && apt update && \
    apt upgrade -y && \
    apt install -y socat && \
    chmod +x /opt/start.pl && \
    chmod +x /opt/response.pl && \
    ln -s /opt/response.pl /bin/response

ENTRYPOINT chmod +x /opt/init.bash && /opt/init.bash && socat TCP4-LISTEN:$LISTEN_PORT,reuseaddr,fork EXEC:/opt/start.pl