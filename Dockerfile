FROM debian:11-slim

STOPSIGNAL SIGTERM

# 更换中国源
COPY sources.list /etc/apt/sources.list
COPY run_cron.sh /bin/run_cron

RUN apt update && apt update \
    && apt install -y cron \
    procps \
    && chmod +x /bin/run_cron

ENTRYPOINT ["run_cron"]
