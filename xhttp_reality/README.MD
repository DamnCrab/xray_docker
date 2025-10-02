## xray_docker_xhttp_reality
xray xhttp reality docker 镜像

[![xray_docker_xhttp_reality_docker_image_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_xhttp_reality.yml/badge.svg)](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_xhttp_reality.yml)

> 本 xray_docker_xhttp_reality 仓库会每两天在 UTC+8 05:00 自动构建镜像

## 前置要求

如果你没有安装 docker 请先安装 docker

```bash
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

## 方法一：Docker 命令直接运行

### 懒人一键安装（docker已经准备好）
```bash
EXTERNAL_PORT=23333 && docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_xhttp_reality:latest && sleep 3 && docker exec -it xray_xhttp_reality cat /config/config_info.txt
```

### 端口映射模式

如果你已经安装 docker，可以直接使用下面的命令，运行后会自动下载镜像并启动容器，
EXTERNAL_PORT 为你想要使用的端口，如下所示，你将使用443端口

```bash
docker pull damncrab/xray_docker_xhttp_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_xhttp_reality:latest
```

### host模式

如果你想使用 host 模式，你可以使用以下命令，运行后会自动下载镜像并启动容器，
HOSTMODE_PORT 为你想要使用的端口，如下所示，你将使用443端口

```bash
docker pull damncrab/xray_docker_xhttp_reality:latest
HOSTMODE_PORT=443
docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 --network host -e HOSTMODE_PORT=$HOSTMODE_PORT -v ./config:/config damncrab/xray_docker_xhttp_reality:latest
```

### 查看配置信息
查看日志获取配置信息，如下所示，按照提示配置客户端即可：

```bash
docker logs -f xray_xhttp_reality 
```

或者直接查看配置文件：

```bash
docker exec -it xray_xhttp_reality cat /config/config_info.txt
```

### 进阶使用方法
如果你不想使用 443 端口，你可以自定义端口，例如使用 8443 端口，如下所示

```bash
EXTERNAL_PORT=8443
docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_xhttp_reality:latest
```

如果你想启动多个 xhttp_reality 服务，你可以使用不同的容器名，并注意端口不要冲突，如下所示你将启动两个 xhttp_reality 服务，分别使用444和445端口

```bash
EXTERNAL_PORT=444
docker run -d --name xray_xhttp_reality_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config1:/config damncrab/xray_docker_xhttp_reality:latest

EXTERNAL_PORT=445
docker run -d --name xray_xhttp_reality_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config2:/config damncrab/xray_docker_xhttp_reality:latest
```

如果你想使用自定义参数，例如使用自定义的 UUID,以及自定义目标地址和服务器名称，如下所示，**支持的自定义参数请参考下方环境变量说明**

存在多个 SERVERNAMES 时使用空格分开，例如：www.apple.com images.apple.com

请注意，如果你使用自定义参数，你需要自己保证参数的正确性，否则可能会导致容器无法启动
```bash
EXTERNAL_PORT=443
docker run -d --name xray_xhttp_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" -v ./config:/config damncrab/xray_docker_xhttp_reality:latest
```

使用以下命令删除已经创建的容器，如下所示，需要将 xray_xhttp_reality 替换为你自己的容器名 (--name 所设置的名称)

```bash
docker rm -f xray_xhttp_reality
```

## 方法二：Docker Compose 运行

### 基础 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_xhttp_reality:
    image: damncrab/xray_docker_xhttp_reality:latest
    container_name: xray_xhttp_reality
    restart: always
    ports:
      - "443:443"
    environment:
      - EXTERNAL_PORT=443
    volumes:
      - ./config:/config
      - ./logs:/var/log/xray
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

启动服务：

```bash
docker compose up -d
```

查看配置信息：

```bash
docker compose exec xray_xhttp_reality cat /config/config_info.txt
```

查看日志：

```bash
docker compose logs -f xray_xhttp_reality
```

停止服务：

```bash
docker compose down
```

### 自定义参数的 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_xhttp_reality:
    image: damncrab/xray_docker_xhttp_reality:latest
    container_name: xray_xhttp_reality
    restart: always
    ports:
      - "8443:443"
    environment:
      - EXTERNAL_PORT=8443
      - UUID=your-custom-uuid-here
      - SERVERNAMES=www.apple.com images.apple.com
      - DEST=www.apple.com:443
      - PRIVATEKEY=your-private-key-here
    volumes:
      - ./config:/config
      - ./logs:/var/log/xray
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

### Host 模式的 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_xhttp_reality:
    image: damncrab/xray_docker_xhttp_reality:latest
    container_name: xray_xhttp_reality
    restart: always
    network_mode: host
    environment:
      - HOSTMODE_PORT=443
    volumes:
      - ./config:/config
      - ./logs:/var/log/xray
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

### 多实例 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_xhttp_reality_1:
    image: damncrab/xray_docker_xhttp_reality:latest
    container_name: xray_xhttp_reality_1
    restart: always
    ports:
      - "444:443"
    environment:
      - EXTERNAL_PORT=444
    volumes:
      - ./config1:/config
      - ./logs1:/var/log/xray
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

  xray_xhttp_reality_2:
    image: damncrab/xray_docker_xhttp_reality:latest
    container_name: xray_xhttp_reality_2
    restart: always
    ports:
      - "445:443"
    environment:
      - EXTERNAL_PORT=445
    volumes:
      - ./config2:/config
      - ./logs2:/var/log/xray
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

## 配置持久化

为了避免每次重启容器时重新生成配置，请确保正确挂载 `/config` 目录：

- 首次运行时，容器会自动生成配置文件和连接信息
- 后续重启时，如果检测到 `/config/config.json` 和 `/config/config_info.txt` 都存在，将跳过配置生成
- 这样可以保持连接信息的一致性，避免每次都需要手动更新客户端

**重要提示**：
- 必须挂载 `/config` 目录到宿主机，否则配置无法持久化
- 如需重新生成配置，删除挂载目录中的配置文件即可

## 环境变量
你可以设置以下环境变量来自定义 XRay 的配置。
* UUID：XRay 的唯一用户标识符。若未设置，脚本将自动生成一个随机 UUID。
* DEST：目标地址。默认值为 www.apple.com:443。
* SERVERNAMES：服务器名称列表。默认值为 www.apple.com images.apple.com。
* PRIVATEKEY：私钥。若未设置，脚本将自动生成一个新的私钥和对应的公钥。
* NETWORK：网络类型。默认值为 xhttp，不要进行修改。

## 常量及默认值
* flow：留空
* security：reality
* shortIds：留空
* XHTTP_PATH：随机生成

## 注意事项
请确保在使用前已正确安装和配置 XRay 客户端。
为了保证安全和稳定，请勿将 UUID、私钥等敏感信息泄露给他人。

