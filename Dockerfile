FROM davidpenya77/squid:latest
RUN apk add --no-cache wget jq apache2-utils
WORKDIR /app
ARG FRP_VERSION="0.59.0"
RUN wget https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz -O /app/frp.tar.gz
RUN tar xvzf /app/frp.tar.gz && mv -f frp_${FRP_VERSION}_linux_amd64 frp
COPY squid.conf /etc/squid/squid.conf
COPY frpc.toml /app/frp
COPY start.sh /app
ENTRYPOINT ["/app/start.sh"]