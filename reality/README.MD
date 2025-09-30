## xray_docker_reality
xray reality docker 镜像

[![xray_docker_reality_docker_image_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml)

> 新的命令中添加了日志大小的限制，可以调整 max-size=100m 的数量来调整日志的最大大小，需要限制日志大小的用户请重新创建容器

> 变更了镜像tag，不影响已经使用的用户

> 本 xray_docker_reality 仓库会每两天在 UTC+8 04:00 自动构建镜像

## 前置要求

如果你没有安装 docker 请先安装 docker

```bash
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

## 方法一：Docker 命令直接运行

### 懒人一键安装（docker已经准备好）
```bash
EXTERNAL_PORT=2333 && docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_reality:latest && sleep 3 && docker exec -it xray_reality cat /config/config_info.txt
```

### 端口映射模式
如果你已经安装 docker，可以直接使用下面的命令，运行后会自动下载镜像并启动容器，
EXTERNAL_PORT 为你想要使用的端口，如下所示，你将使用443端口

```bash
docker pull damncrab/xray_docker_reality:latest
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_reality:latest
```

### host 模式
如果你想使用 host 模式，你可以使用以下命令，运行后会自动下载镜像并启动容器，
HOSTMODE_PORT 为你想要使用的端口，如下所示，你将使用443端口
>请注意，如果你使用 host 模式，EXTERNAL_PORT 变量将不会生效，请使用 HOSTMODE_PORT 变量

```bash
docker pull damncrab/xray_docker_reality:latest
HOSTMODE_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 --network host -e HOSTMODE_PORT=$HOSTMODE_PORT -v ./config:/config damncrab/xray_docker_reality:latest
```

### 查看配置信息
查看日志获取配置信息，如下所示，按照提示配置客户端即可：

```bash
docker logs -f xray_reality 
```

或者直接查看配置文件：

```bash
docker exec -it xray_reality cat /config/config_info.txt
```

### 进阶使用方法
如果你不想使用 443 端口，你可以自定义端口，例如使用 8443 端口，如下所示

```bash
EXTERNAL_PORT=8443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config:/config damncrab/xray_docker_reality:latest
```

如果你想启动多个 reality 服务，你可以使用不同的容器名，并注意端口不要冲突，如下所示你将启动两个 reality 服务，分别使用444和445端口

```bash
EXTERNAL_PORT=444
docker run -d --name xray_reality_1 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config1:/config damncrab/xray_docker_reality:latest

EXTERNAL_PORT=445
docker run -d --name xray_reality_2 --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -v ./config2:/config damncrab/xray_docker_reality:latest
```

如果你不想使用默认参数，你可以自定义参数，例如使用自定义的 UUID,以及自定义目标地址和服务器名称，如下所示，**支持的自定义参数请参考下方环境变量说明**

存在多个 SERVERNAMES 时使用空格分开，例如：www.apple.com images.apple.com

请注意，如果你使用自定义参数，你需要自己保证参数的正确性，否则可能会导致容器无法启动
```bash
EXTERNAL_PORT=443
docker run -d --name xray_reality --restart=always --log-opt max-size=100m --log-opt max-file=3 -p $EXTERNAL_PORT:443 -e EXTERNAL_PORT=$EXTERNAL_PORT -e UUID="XXX" -e SERVERNAMES="www.apple.com images.apple.com" -e DEST="www.apple.com:443" -e PRIVATEKEY="XXX" -v ./config:/config damncrab/xray_docker_reality:latest
```

使用以下命令删除已经创建的容器，如下所示，需要将 xray_reality 替换为你自己的容器名 (--name 所设置的名称)

```bash
docker rm -f xray_reality
```

## 方法二：Docker Compose 运行

### 基础 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_reality:
    image: damncrab/xray_docker_reality:latest
    container_name: xray_reality
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
docker-compose up -d
```

查看配置信息：

```bash
docker-compose exec xray_reality cat /config/config_info.txt
```

查看日志：

```bash
docker-compose logs -f xray_reality
```

停止服务：

```bash
docker-compose down
```

### 自定义参数的 Docker Compose 配置

创建 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  xray_reality:
    image: damncrab/xray_docker_reality:latest
    container_name: xray_reality
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
  xray_reality:
    image: damncrab/xray_docker_reality:latest
    container_name: xray_reality
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
  xray_reality_1:
    image: damncrab/xray_docker_reality:latest
    container_name: xray_reality_1
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

  xray_reality_2:
    image: damncrab/xray_docker_reality:latest
    container_name: xray_reality_2
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


## 环境变量
你可以设置以下环境变量来自定义 XRay 的配置。
* UUID：XRay 的唯一用户标识符。若未设置，脚本将自动生成一个随机 UUID。
* DEST：目标地址。默认值为 www.apple.com:443。
* SERVERNAMES：服务器名称列表。默认值为 www.apple.com images.apple.com。
* PRIVATEKEY：私钥。若未设置，脚本将自动生成一个新的私钥和对应的公钥。
* NETWORK：网络类型。默认值为 tcp。

## 常量
* flow：xtls-rprx-vision
* security：reality
* shortIds：留空

## 注意事项
请确保在使用前已正确安装和配置 XRay 客户端。
为了保证安全和稳定，请勿将 UUID、私钥等敏感信息泄露给他人。

