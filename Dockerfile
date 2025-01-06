# 继承预先构建好的基础镜像
FROM leijmin/debian-tools:latest

# 设置环境变量以避免交互式安装问题
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/go/bin:${PATH}"

# 安装 Go 编译器
RUN curl -fsSL https://golang.org/dl/go1.20.6.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    go version

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