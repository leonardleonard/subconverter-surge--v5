# Surge 5 后端 Docker 部署

这是支持 Surge 5 IOS 和 Surge 5 MacOS 的 subconverter 后端。

## 快速开始

### 方法 1：直接构建和运行

```bash
# 进入目录
cd /Users/edz/Desktop/github_repo/convertsub/subconverter-surge--v5

# 构建镜像
docker build -t subconverter-surge5:latest .

# 运行容器
docker run -d \
  --name subconverter-surge5 \
  --restart always \
  -p 25500:25500 \
  subconverter-surge5:latest

# 查看日志
docker logs -f subconverter-surge5

# 测试服务
curl http://localhost:25500/version
```

### 方法 2：使用 docker-compose（推荐）

在项目根目录已经有 `docker-compose.yml`：

```bash
# 返回项目根目录
cd /Users/edz/Desktop/github_repo/convertsub

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

## 测试 Surge 5 功能

### Surge 5 IOS
```bash
curl "http://localhost:25500/sub?target=surge-ios&ver=5&url=订阅链接&insert=false"
```

### Surge 5 MacOS
```bash
curl "http://localhost:25500/sub?target=surge-macos&ver=5&url=订阅链接&insert=false"
```

### 传统 Surge 4（向后兼容）
```bash
curl "http://localhost:25500/sub?target=surge&ver=4&url=订阅链接"
```

## 支持的目标类型

- `surge-ios&ver=5` - Surge 5 for iOS
- `surge-macos&ver=5` - Surge 5 for MacOS
- `surge&ver=4` - Surge 4
- `surge&ver=3` - Surge 3
- `clash` - Clash
- `quanx` - Quantumult X
- 等等...

## 配置管理

### 自定义配置

如果需要自定义配置文件：

```bash
# 1. 复制默认配置
docker cp subconverter-surge5:/base/pref.ini ./pref.ini

# 2. 修改配置文件
nano pref.ini

# 3. 更新到容器
docker cp ./pref.ini subconverter-surge5:/base/pref.ini

# 4. 重启容器
docker restart subconverter-surge5
```

### 持久化配置（推荐）

使用 volume 挂载配置：

```bash
docker run -d \
  --name subconverter-surge5 \
  --restart always \
  -p 25500:25500 \
  -v $(pwd)/base:/base \
  subconverter-surge5:latest
```

## 管理命令

```bash
# 查看容器状态
docker ps | grep subconverter

# 查看实时日志
docker logs -f subconverter-surge5

# 查看最近100行日志
docker logs --tail 100 subconverter-surge5

# 重启容器
docker restart subconverter-surge5

# 停止容器
docker stop subconverter-surge5

# 启动容器
docker start subconverter-surge5

# 删除容器
docker rm -f subconverter-surge5

# 删除镜像
docker rmi subconverter-surge5:latest
```

## 性能优化

### 多核构建

构建时指定更多线程：

```bash
docker build --build-arg THREADS=8 -t subconverter-surge5:latest .
```

### 资源限制

限制容器资源使用：

```bash
docker run -d \
  --name subconverter-surge5 \
  --restart always \
  -p 25500:25500 \
  --memory="512m" \
  --cpus="1" \
  subconverter-surge5:latest
```

## 公网部署

### 使用 Nginx 反向代理

```nginx
server {
    listen 80;
    server_name sub.yourdomain.com;

    location / {
        proxy_pass http://localhost:25500;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 添加 HTTPS

```bash
# 使用 certbot 获取 SSL 证书
certbot --nginx -d sub.yourdomain.com
```

## 故障排查

### 容器无法启动

```bash
# 查看详细日志
docker logs subconverter-surge5

# 检查端口占用
lsof -i :25500

# 清理并重启
docker rm -f subconverter-surge5
docker run -d --name subconverter-surge5 -p 25500:25500 subconverter-surge5:latest
```

### 服务返回错误

```bash
# 进入容器检查
docker exec -it subconverter-surge5 sh

# 检查配置文件
cat /base/pref.ini

# 手动运行查看错误
/usr/bin/subconverter
```

### 构建失败

```bash
# 清理 Docker 缓存
docker system prune -a

# 重新构建（不使用缓存）
docker build --no-cache -t subconverter-surge5:latest .
```

## 更新版本

```bash
# 1. 拉取最新代码
cd /Users/edz/Desktop/github_repo/convertsub/subconverter-surge--v5
git pull

# 2. 重新构建
docker build -t subconverter-surge5:latest .

# 3. 停止并删除旧容器
docker rm -f subconverter-surge5

# 4. 启动新容器
docker run -d --name subconverter-surge5 --restart always -p 25500:25500 subconverter-surge5:latest
```

## 系统要求

- Docker 20.10+
- 最低 1GB RAM
- 最低 2GB 磁盘空间
- 支持 x86_64 架构

## 技术支持

- GitHub Issues: 在仓库中提出问题
- 查看日志: `docker logs subconverter-surge5`
- 健康检查: `curl http://localhost:25500/version`
