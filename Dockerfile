FROM debian:10.10

COPY sources.list /etc/apt/sources.list
COPY ./script/start.pl /opt/start.pl
COPY ./script/response.pl /opt/response.pl
COPY ./script/init.bash /opt/init.bash
COPY ./script/add-header.pl /opt/add-header.pl
COPY ./script/set-status.pl /opt/set-status.pl

# 此为脚本运行目录
ENV WORKSPACE /opt/script
ENV LISTEN_PORT 80

RUN apt update && apt update && \
    apt upgrade -y && \
    apt install -y socat && \
    chmod +x /opt/start.pl && \
    chmod +x /opt/response.pl && \
    chmod +x /opt/add-header.pl && \
    chmod +x /opt/set-status.pl && \
    ln -s /opt/response.pl /bin/response && \
    ln -s /opt/add-header.pl /bin/add-header && \
    ln -s /opt/set-status.pl /bin/set-status && \
    mkdir "/var/run/http_cron"

ENTRYPOINT chmod +x /opt/init.bash && /opt/init.bash && socat TCP4-LISTEN:$LISTEN_PORT,reuseaddr,fork EXEC:/opt/start.pl