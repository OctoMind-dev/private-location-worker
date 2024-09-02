# private location worker

simple local squid proxy (password protected) accessable by a frp tunnel.

![plw overview](/images/plw-overview.png)

# proxy flows

## new proxy / open proxy

```mermaid
sequenceDiagram
    autonumber
    title: private location worker: open a proxy with frp
    frp-client->>+frp-server: NewProxy (proxyname)
    frp-server->>+frp-server-plugin: create proxy allowed?
    frp-server-plugin->>octo-service: known APIKEY, proxyname?
    octo-service->>frp-server-plugin: yes
    frp-server-plugin->>+frp-server: yes
    frp-server->>frp-client: created
    Note over frp-server-plugin,frp-server: short delay
    frp-server-plugin->>frp-server: getProxyInfo( proxyname )
    frp-server->>frp-server-plugin: info incl. ip & port
    frp-server-plugin->>octo-service: update proxy
    Note over octo-service: proxy will marked as active with IP & port
```

## close proxy

```mermaid
sequenceDiagram
    autonumber
    title: private location worker: close  a proxy with frp
    frp-client->>+frp-server: CloseProxy (name)
    frp-server->>+frp-server-plugin: close proxy (name)
    frp-server-plugin->>octo-service: close proxy ( name )
    Note over octo-service: proxy will marked as closed
    octo-service->>frp-server-plugin: void
    frp-server-plugin->>+frp-server: void
    frp-server->>frp-client: close
```

# use

customer can run and build the private location worker on their premises using a container.

container image will be provided by octomind see [registry](https://hub.docker.com) or it can be build on your own see [below](#build)

to run the container a few environment variables are needed
## environment vars

- APIKEY: the octomind APIKEY for your organization
- PLW_NAME: name of the private locations worker as registered in the octomind platform (name must match)
- PROXY_USER: username for the (squid) proxy
- PROXY_PASS: password for the (squid) proxy

The PROXY_USER and PROXY_PASS will protect your local proxy from authenticated access. When the worker starts it will register with the octomind platform and set the proxy user and pass, so that the octomind agent and test runner can of course use the proxy.

You can start as many private location worker as you like, but each must be registered by name with octomind first. The name must
be unique for your organization.

NYI: for scaling we will also support multiple instances of worker with the same name, but currently only one instance is supported.

## run

private location worker can simply run as docker container:
```
docker run --rm -e PLW_NAME=worker1 -e APIKEY=12345 -e PROXY_PASS=secret -e PROXY_USER=octo octomind/plw:latest
```
