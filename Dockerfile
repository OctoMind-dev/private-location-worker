FROM alpine:latest

LABEL maintainer="stefan.rinke@octomind.dev"

RUN apk update && apk add --no-cache wget jq apache2-utils squid curl
WORKDIR /app
ARG FRP_VERSION="0.64.0"
RUN wget https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz -O /app/frp.tar.gz
RUN tar xvzf /app/frp.tar.gz && mv -f frp_${FRP_VERSION}_linux_amd64 frp && rm /app/frp/frps && rm /app/frp.tar.gz
COPY squid.conf /etc/squid/squid.conf
COPY frpc.toml /app/frp
COPY start.sh /app
ENTRYPOINT ["/app/start.sh"]