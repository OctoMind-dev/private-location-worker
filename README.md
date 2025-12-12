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
    frp-server-plugin->>octo-service: register proxy (name, info)
    Note over octo-service: proxy will marked as online with IP & port
```

## close proxy

```mermaid
sequenceDiagram
    autonumber
    title: private location worker: close  a proxy with frp
    frp-client->>+frp-server: CloseProxy (name)
    frp-server->>+frp-server-plugin: close proxy (name)
    frp-server-plugin->>octo-service: unregister proxy ( name )
    Note over octo-service: proxy will marked as offline
    octo-service->>frp-server-plugin: void
    frp-server-plugin->>+frp-server: void
    frp-server->>frp-client: close
```

# use

customer can run and build the private location worker on their premises using a container.

container image will be provided by octomind see [registry](eu.gcr.io/octomind-dev/plw:latest) or it can be build on your own see [below](#build)

to run the container a few environment variables are needed
## environment vars

- APIKEY: the octomind APIKEY for your organization
- PLW_NAME: name of the private locations worker as registered in the octomind platform (name must match)
- PROXY_USER: username for the (squid) proxy
- PROXY_PASS: password for the (squid) proxy
- SERVER_ADDR: the address of the server that the worker will connect (one of our proxy server addresses 35.192.162.70 or 34.159.153.198)
- IGNORE_SSL_ERRORS: (optional) set to `1` to ignore SSL certificate errors when proxying HTTPS traffic. Use this when connecting to services with self-signed or invalid certificates

The PROXY_USER and PROXY_PASS will protect your local proxy from authenticated access. When the worker starts it will register with the octomind platform and set the proxy user and pass, so that the octomind agent and test runner can of course use the proxy.

You can start as many private location worker as you like, but each must be registered by name with octomind first. The name must
be unique for your organization.

NYI: for scaling we will also support multiple instances of worker with the same name, but currently only one instance is supported.

## run

private location worker can simply run as docker container:
```sh
docker run --rm -e PLW_NAME=worker1 -e APIKEY=12345 -e PROXY_PASS=secret -e PROXY_USER=octo eu.gcr.io/octomind-dev/plw:latest
```

or use docker compose like this.

```yaml
services:
  private-location-worker:
    image: eu.gcr.io/octomind-dev/plw:latest
    environment:
      APIKEY: 1234
      PLW_NAME: worker1
      PROXY_USER: foo
      PROXY_PASS: bar
    restart: on-failure
```
### kubernetes

if you want to run the private location worker inside a k8s cluster you clould use:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-location-worker
spec:
  containers:
  - name: plw
    image: eu.gcr.io/octomind-dev/plw:latest
    env:
    - name: APIKEY
      value: <your api key>
    - name: PLW_NAME
      value: staging
    - name: PROXY_USER
      value: proxy
    - name: PROXY_PASS
      value: secret11
```
### podman

As podman is build a *drop in* replacement for docker the private location worker can be used with podman as well:

```sh
podman run --rm -e PLW_NAME=worker1 -e APIKEY=12345 -e PROXY_PASS=secret -e PROXY_USER=octo eu.gcr.io/octomind-dev/plw:latest
```

### podman on windows

If you run the private location worker with podman on windows be aware that the networking in wsl (windows subsystem for linux)
behaves slightly different to podman on linux. E.g. if you want to connect to a service running on the same host as the
private location worker, you need to configure your network see [here](https://stackoverflow.com/questions/79098571/podman-container-cannot-connect-to-windows-host) or [on github](https://github.com/eriksjolund/podman-networking-docs?tab=readme-ov-file#outbound-tcpudp-connections-to-the-hosts-localhost)

For example if you want to access a service on the host machine on port 8080 you need to add:

```sh
podman run --rm ... --network=pasta:-T,8080:8080 eu.gcr.io/octomind-dev/plw:latest
```

but this only one option, see [github doc](https://github.com/eriksjolund/podman-networking-docs?tab=readme-ov-file#outbound-tcpudp-connections-to-the-hosts-localhost)

