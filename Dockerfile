FROM golang:1.20-alpine

RUN apk add --no-cache gcc g++ make curl git

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

# 配置文件
COPY Caddyfile /etc/caddy/Caddyfile
COPY naiveproxy-config.json /etc/naiveproxy/naiveproxy-config.json

# 暴露端口
EXPOSE 80
EXPOSE 443

# 启动命令
CMD ["sh", "-c", "caddy run --config /etc/caddy/Caddyfile"]