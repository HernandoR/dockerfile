FROM nginx:1.21-perl

COPY sources.list /etc/apt/
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY ./script/start.bash /opt/start.bash
COPY ./script/run-request.pl /opt/run/run-request.pl
COPY ./script/response.pl /bin/response
COPY ./script/init.bash /opt/init.bash
COPY ./script/add-header.pl /bin/add-header
COPY ./script/set-status.pl /bin/set-status


# 此为脚本运行目录
ENV WORKSPACE /opt/script
# 是否需要将请求从文件中读出来
ENV INIT_FORM_CONTENT 1
# fcgiwrap启动进程数量, 既最大并发数
ENV MAX_CONCURRENT 4

RUN apt update && apt update \
    && apt install -y \
    fcgiwrap \
    && chmod +x /opt/start.bash \
    && chmod +x /opt/run/run-request.pl \
    && chmod +x /bin/response \
    && chmod +x /opt/init.bash \
    && chmod +x /bin/add-header \
    && chmod +x /bin/set-status \
    && mkdir "/var/run/http_cron"

ENTRYPOINT ["/opt/start.bash"]