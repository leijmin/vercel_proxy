# 使用 Debian 作为基础镜像
FROM debian:latest

# 设置环境变量以避免交互式安装问题
ENV DEBIAN_FRONTEND=noninteractive

# 更新系统并安装必要工具
RUN apt-get update && apt-get install -y \
    curl git gcc g++ cmake make libssl-dev build-essential ca-certificates wget unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 xcaddy 工具
RUN cp xcaddy /usr/bin

# 使用 xcaddy 编译带 http.forwardproxy 插件的 Caddy
RUN xcaddy build --with github.com/caddyserver/forwardproxy && \
    mv caddy /usr/bin/caddy && \
    chmod +x /usr/bin/caddy

# 验证 Caddy 是否安装成功
RUN caddy version

# 安装 NaiveProxy
RUN git clone --depth=1 https://github.com/klzgrad/naiveproxy.git && \
    cd naiveproxy/src && \
    ./get-clang.sh && \
    gn gen out/Release && \
    ninja -C out/Release naive && \
    mv out/Release/naive /usr/bin/naive && \
    cd ../../ && rm -rf naiveproxy

# 将配置文件复制到镜像中
COPY Caddyfile /etc/caddy/Caddyfile
COPY naiveproxy-config.json /etc/naiveproxy/naiveproxy-config.json

# 暴露必要端口
EXPOSE 80
EXPOSE 443

# 健壮性优化：确保启动失败时自动退出
HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost || exit 1

# 启动 Caddy 和 NaiveProxy
CMD ["sh", "-c", "caddy run --config /etc/caddy/Caddyfile & naive --config /etc/naiveproxy/naiveproxy-config.json"]