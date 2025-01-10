# 使用精简的 debian:bullseye-slim 作为基础镜像
FROM debian:bullseye-slim

# 安装必要的运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 将本地编译好的 Caddy 文件复制到容器中
COPY caddy /usr/bin/caddy

# 复制 NaiveProxy 文件（本地已有的）
COPY naiveproxy /usr/bin/naiveproxy

# 设置运行时文件的权限
RUN chmod +x /usr/bin/caddy
RUN chmod +x /usr/bin/naiveproxy

# 复制 Caddy 和 NaiveProxy 的配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY config.json /etc/naiveproxy/config.json

# 复制本地证书到容器
COPY certs/fullchain.pem /etc/caddy/certs/fullchain.pem
COPY certs/privkey.pem /etc/caddy/certs/privkey.pem

# 设置运行时环境变量
ENV NAIVEPROXY_CONFIG=/etc/naiveproxy/config.json

# 暴露 HTTPS 端口
EXPOSE 443

# 启动 Caddy 和 NaiveProxy 服务
CMD ["sh", "-c", "/usr/bin/caddy run --config /etc/caddy/Caddyfile & /usr/bin/naiveproxy -config /etc/naiveproxy/config.json"]