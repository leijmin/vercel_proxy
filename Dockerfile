# 使用官方 Go 镜像作为基础镜像
FROM golang:1.20

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl git gcc g++ cmake make libssl-dev build-essential ca-certificates wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 将 xcaddy 文件复制到镜像中
COPY xcaddy /usr/bin/xcaddy

# 添加执行权限
RUN chmod +x /usr/bin/xcaddy

# 使用 xcaddy 编译带 http.forwardproxy 插件的 Caddy
RUN /usr/bin/xcaddy build --with github.com/caddyserver/forwardproxy && \
    mv caddy /usr/bin/caddy && \
    chmod +x /usr/bin/caddy

# 验证 Caddy 是否安装成功
RUN caddy version

# 将本地缓存的 naiveproxy 代码复制到镜像中
COPY naiveproxy /app/naiveproxy

# 安装 NaiveProxy
RUN cd /app/naiveproxy/src && \
    ./get-clang.sh && \
    gn gen out/Release && \
    ninja -C out/Release naive && \
    mv out/Release/naive /usr/bin/naive && \
    cd ../../ && rm -rf /app/naiveproxy

# 配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY naiveproxy-config.json /etc/naiveproxy/naiveproxy-config.json

# 暴露端口
EXPOSE 80
EXPOSE 443

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost || exit 1

# 启动命令
CMD ["sh", "-c", "caddy run --config /etc/caddy/Caddyfile & naive --config /etc/naiveproxy/naiveproxy-config.json"]