# Xray Docker

Xray Reality Docker 镜像，支持两种协议：**Reality** 和 **XHTTP Reality**

[![reality_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml)
[![xhttp_reality_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_xhttp_reality.yml/badge.svg)](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_xhttp_reality.yml)

## 新特性

- ✅ **配置持久化**：配置文件挂载到本地，重启容器不会丢失
- ✅ **日志轮转**：自动切割日志，防止占用过多磁盘空间（50MB 自动轮转）
- ✅ **幂等初始化**：已有配置时不会重新生成，迁移更方便
- ✅ **Docker Compose 支持**：通过环境变量快速配置和部署

## 快速开始

### 1. 安装 Docker

如果还未安装 Docker，执行：
```bash
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
```

### 2. 选择协议

#### Reality (TCP)
适用于常规使用场景，性能稳定。

```bash
cd reality
docker-compose up -d
```

#### XHTTP Reality
使用 XHTTP 协议，适用于需要更强伪装能力的场景。

```bash
cd xhttp_reality
docker-compose up -d
```

### 3. 查看连接信息

启动后，查看日志获取订阅链接和二维码：

```bash
# Reality
docker-compose logs

# XHTTP Reality
docker-compose logs
```

## 使用 Docker Compose（推荐）

### 基础配置

编辑 `docker-compose.yml`，设置环境变量：

```yaml
environment:
  - UUID=                    # 留空自动生成
  - DEST=www.apple.com:443   # 目标地址
  - SERVERNAMES=www.apple.com images.apple.com
  - PRIVATEKEY=              # 留空自动生成
  - NETWORK=tcp              # reality: tcp, xhttp_reality: xhttp
  - EXTERNAL_PORT=443
  - HOSTMODE_PORT=443
```

### 常用命令

```bash
# 启动服务
docker-compose up -d

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重新构建并启动
docker-compose up -d --build
```

### 配置文件位置

- **配置文件**：`./config/config.json`
- **日志文件**：`./logs/access.log` 和 `./logs/error.log`
- **公钥备份**：`./config/public.key`（重启时恢复订阅链接用）

## 环境变量说明

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `UUID` | 用户唯一标识符 | 自动生成 | 否 |
| `DEST` | Reality 目标地址 | `www.apple.com:443` | 否 |
| `SERVERNAMES` | 服务器名称列表（空格分隔） | `www.apple.com images.apple.com` | 否 |
| `PRIVATEKEY` | Reality 私钥 | 自动生成 | 否 |
| `NETWORK` | 网络协议类型 | reality: `tcp`<br>xhttp: `xhttp` | 否 |
| `XHTTP_PATH` | XHTTP 路径 | 随机生成 | 否（仅 xhttp） |
| `EXTERNAL_PORT` | 外部端口（端口映射模式） | `443` | 否 |
| `HOSTMODE_PORT` | Host 模式端口 | `443` | 否 |

## 传统 Docker 命令

如果不使用 Docker Compose，也可以直接使用 `docker run`：

### Reality

```bash
docker run -d \
  --name xray_reality \
  --restart always \
  --network host \
  -v ./config:/etc/xray \
  -v ./logs:/var/log/xray \
  -e EXTERNAL_PORT=443 \
  -e HOSTMODE_PORT=443 \
  damncrab/xray_docker_reality:latest
```

### XHTTP Reality

```bash
docker run -d \
  --name xray_xhttp_reality \
  --restart always \
  --network host \
  -v ./config:/etc/xray \
  -v ./logs:/var/log/xray \
  -e EXTERNAL_PORT=443 \
  -e HOSTMODE_PORT=443 \
  damncrab/xray_docker_xhttp_reality:latest
```

## 迁移指南

1. **备份配置**：复制 `config` 目录到新服务器
2. **启动容器**：使用相同的 `docker-compose.yml` 启动
3. **自动恢复**：容器会自动使用已有配置，无需重新生成

## 常见问题

### 如何自定义参数？

编辑 `docker-compose.yml`，在 `environment` 中设置对应的环境变量。

### 如何查看实时日志？

```bash
docker-compose logs -f
```

### 如何强制重新生成配置？

删除 `./config/config.json` 后重启容器：
```bash
rm -f ./config/config.json
docker-compose restart
```

### 日志文件太大怎么办？

容器内置日志轮转功能，当日志达到 50MB 时自动切割并压缩，保留最近 3 个备份。

### 如何寻找合适的 SERVERNAMES 和 DEST？

可以使用默认值 `www.apple.com`，也可以参考 [RealiTLScanner](https://github.com/XTLS/RealiTLScanner) 寻找更适合的目标。

## 项目链接

- [Reality 版本](https://github.com/damncrab/xray_docker/tree/master/reality)
- [XHTTP Reality 版本](https://github.com/damncrab/xray_docker/tree/master/xhttp_reality)

## 注意事项

- 确保已正确安装和配置 Xray 客户端
- 请勿泄露 UUID、私钥等敏感信息
- 首次启动会生成配置，后续重启会复用已有配置
