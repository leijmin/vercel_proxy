# 第一阶段: 使用官方 caddy builder 构建自定义 caddy 二进制文件
FROM caddy:builder AS builder

# 添加 NaiveProxy 和 Cloudflare DNS 插件
RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4 \
    --with github.com/caddyserver/forwardproxy

# 第二阶段: 基于精简的 debian 运行环境
FROM debian:bullseye-slim

# 安装必要的运行时依赖
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# 从 builder 阶段复制编译好的 caddy 文件
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# 复制 NaiveProxy 文件（需要手动下载或构建）
COPY naiveproxy /usr/bin/naiveproxy

# 设置运行时文件的权限
RUN chmod +x /usr/bin/caddy
RUN chmod +x /usr/bin/naiveproxy

# 复制 Caddy 和 NaiveProxy 的配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY config.json /etc/naiveproxy/config.json

# 设置运行时环境变量
ENV NAIVEPROXY_CONFIG=/etc/naiveproxy/config.json

# 暴露 HTTPS 端口
EXPOSE 443

# 启动 Caddy 和 NaiveProxy 服务
CMD ["sh", "-c", "/usr/bin/caddy run --config /etc/caddy/Caddyfile & /usr/bin/naiveproxy -config /etc/naiveproxy/config.json"]