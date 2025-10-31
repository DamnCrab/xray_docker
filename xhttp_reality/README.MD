# Xray-REALITY-xhttp

xray docker，采用 REALITY 协议和 xhttp 网络，支持 host 模式和 bridge 模式。

## 配置参数

下表详细说明了本项目中所有可调整的配置参数。通过这些参数，您可以自定义 Xray 代理服务的行为，以满足您的特定需求。

| 变量 | 描述 | 默认值 |
|---|---|---|
| `UUID` | 指定用户的唯一标识符用于身份验证。如果未提供，将生成一个随机的 UUID。 | 随机生成 |
| `XHTTP_PATH` | 定义 xhttp 网络的路径。如果未设置，将生成一个随机路径。 | 随机生成 |
| `EXTERNAL_PORT` | 设置代理服务的外部端口。 | `443` |
| `HOSTMODE_PORT` | 在 host 模式下，此参数指定要使用的端口。它会覆盖 `EXTERNAL_PORT`。 | `443` |
| `DEST` | REALITY 协议的目标地址和端口。 | `www.apple.com:443` |
| `SERVERNAMES` | REALITY 协议的服务器名称列表，以空格分隔。 | `www.apple.com images.apple.com` |
| `PRIVATEKEY` | REALITY 协议的私钥。如果未提供，将生成一个新的密钥对。 | 随机生成 |
| `NETWORK` | 指定网络类型。 | `xhttp` |

## 如何使用

您可以使用 Docker Compose 或标准的 `docker run` 命令来运行此项目。为方便起见，下面两种方法都有说明。

### Docker Compose

要使用 Docker Compose 运行项目，您需要一个包含以下内容的 `docker-compose.yml` 文件：

```yaml
version: "3"
services:
  xray:
    image: damncrab/xray_docker_xhttp_reality
    container_name: xray
    restart: always
    network_mode: "host"
    environment:
      - UUID=your_uuid
      - XHTTP_PATH=/your_path
      - HOSTMODE_PORT=your_port
      - DEST=your_dest
      - SERVERNAMES=your_servernames
      - PRIVATEKEY=your_privatekey
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
```

### Docker Run

或者，您可以使用 `docker run` 命令来启动容器：

```bash
docker run -d --name xray --restart always --network host \
  -e UUID=your_uuid \
  -e XHTTP_PATH=/your_path \
  -e HOSTMODE_PORT=your_port \
  -e DEST=your_dest \
  -e SERVERNAMES="your_servernames" \
  -e PRIVATEKEY=your_privatekey \
  -v ./config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  damncrab/xray_docker_xhttp_reality
```

## 构建 Docker 镜像

如果您需要从源代码构建 Docker 镜像，可以使用以下命令：

```bash
docker build -t damncrab/xray_docker_xhttp_reality .
```

此命令将创建一个带有 `damncrab/xray_docker_xhttp_reality` 标签的新 Docker 镜像，然后您可以使用该镜像来运行容器。

