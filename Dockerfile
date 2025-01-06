# 使用基础镜像
FROM debian:bullseye-slim

# 安装运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 复制本地构建的 caddy 文件到镜像中
COPY caddy /usr/bin/caddy
COPY naiveproxy /usr/bin/naiveproxy

# 设置执行权限
RUN chmod +x /usr/bin/caddy
RUN chmod +x /usr/bin/naiveproxy

# 复制配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY config.json /etc/naiveproxy/config.json

# 设置运行时环境变量
ENV NAIVEPROXY_CONFIG=/etc/naiveproxy/config.json

# 暴露端口
EXPOSE 80
EXPOSE 443
EXPOSE 10808

# 启动命令，运行 Caddy 和 naiveproxy
CMD ["sh", "-c", "/usr/bin/caddy run --config /etc/caddy/Caddyfile & /usr/bin/naiveproxy -config /etc/naiveproxy/config.json"]