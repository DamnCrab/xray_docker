## xray_docker_reality
xray reality docker 镜像 - damncrab版本

[![xray_docker_reality_docker_image_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml/badge.svg)](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_reality.yml)
![xray_docker_xhttp_reality_docker_image_build](https://github.com/damncrab/xray_docker/actions/workflows/xray_docker_xhttp_reality.yml/badge.svg)

## 功能特性

- 🔧 **自动配置**: 支持环境变量自动配置Xray参数
- 📁 **配置持久化**: 配置文件和连接信息保存在 `/config` 目录，方便挂载
- 📊 **日志管理**: 内置日志轮转，防止日志文件过大
- 🌐 **双协议支持**: 支持 Reality 和 XHTTP Reality 两种协议
- 📱 **二维码生成**: 自动生成订阅连接和二维码

## 快速开始

### Reality 版本

```bash
docker run -d \
  --name xray-reality \
  -p 443:443 \
  -v /path/to/config:/config \
  -e UUID=your-uuid \
  -e DEST=www.apple.com:443 \
  -e SERVERNAMES="www.apple.com images.apple.com" \
  damncrab/xray_docker_reality:latest
```

### XHTTP Reality 版本

```bash
docker run -d \
  --name xray-xhttp-reality \
  -p 443:443 \
  -v /path/to/config:/config \
  -e UUID=your-uuid \
  -e DEST=www.apple.com:443 \
  -e SERVERNAMES="www.apple.com images.apple.com" \
  damncrab/xray_docker_xhttp_reality:latest
```

## 环境变量

| 变量名 | 描述 | 默认值 |
|--------|------|--------|
| `UUID` | 用户ID | 自动生成 |
| `DEST` | 目标地址 | www.apple.com:443 |
| `SERVERNAMES` | 服务器名称列表 | www.apple.com images.apple.com |
| `PRIVATEKEY` | 私钥 | 自动生成 |
| `NETWORK` | 网络类型 | tcp (Reality) / xhttp (XHTTP Reality) |
| `EXTERNAL_PORT` | 外部端口 | 443 |
| `HOSTMODE_PORT` | 主机模式端口 | - |
| `XHTTP_PATH` | XHTTP路径 (仅XHTTP版本) | 自动生成 |

## 目录挂载

建议挂载 `/config` 目录来持久化配置：

```bash
-v /host/path/config:/config
```

挂载后的目录结构：
```
/config/
├── config.json          # Xray配置文件
└── config_info.txt      # 连接信息和二维码
```

## 日志管理

容器内置了日志轮转功能：
- 日志文件位置：`/var/log/xray/`
- 轮转策略：每日轮转，保留7天
- 自动压缩旧日志文件

## 构建信息

- 基于最新的 Xray-core 构建
- 支持多架构：linux/amd64, linux/arm64, linux/arm/v7, linux/arm/v6
- 自动跟踪 Xray-core 最新版本

## 许可证

本项目基于原项目修改，遵循相同的开源许可证。

