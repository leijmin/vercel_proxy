# 使用基础镜像
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache ca-certificates

# 复制本地构建的 caddy 文件到镜像中
COPY caddy /usr/bin/caddy

# 设置执行权限
RUN chmod +x /usr/bin/caddy

# 复制配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY naiveproxy-config.json /etc/naiveproxy/naiveproxy-config.json

# 暴露端口
EXPOSE 80
EXPOSE 443

# 启动 Caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]