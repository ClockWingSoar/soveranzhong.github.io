# Docker命令详解与生产环境最佳实践

## 情境与背景

Docker作为容器化技术的核心，其命令是日常运维的基础。掌握常用Docker命令对于高效管理容器、镜像、网络和数据卷至关重要。作为高级DevOps/SRE工程师，需要深入理解每个命令的用法和适用场景，以及生产环境中的最佳实践。

## 一、容器管理命令

### 1.1 创建与启动容器

**docker run命令详解**：

```bash
# 基本用法
docker run nginx

# 指定名称
docker run --name my-nginx nginx

# 后台运行
docker run -d nginx

# 端口映射
docker run -p 80:80 nginx
docker run -p 8080:80 nginx

# 端口随机映射
docker run -P nginx

# 挂载数据卷
docker run -v /host/path:/container/path nginx

# 设置环境变量
docker run -e ENV=prod -e PORT=8080 nginx

# 指定用户
docker run --user www-data nginx

# 限制资源
docker run --cpus="2" --memory="2g" nginx

# 网络配置
docker run --network=host nginx
docker run --network=my-network nginx

# 重启策略
docker run --restart=always nginx
docker run --restart=on-failure:3 nginx
```

### 1.2 容器生命周期管理

**常用容器管理命令**：

```bash
# 启动容器
docker start my-nginx

# 停止容器
docker stop my-nginx

# 重启容器
docker restart my-nginx

# 强制停止
docker kill my-nginx

# 删除容器
docker rm my-nginx

# 删除所有停止的容器
docker rm $(docker ps -aq)

# 暂停/恢复容器
docker pause my-nginx
docker unpause my-nginx

# 进入容器
docker exec -it my-nginx bash
docker exec -it my-nginx sh

# 复制文件
docker cp host-file.txt my-nginx:/path/
docker cp my-nginx:/path/file.txt host-path/
```

### 1.3 查看容器信息

**查看命令**：

```bash
# 查看运行中的容器
docker ps

# 查看所有容器（包括停止的）
docker ps -a

# 查看容器详情
docker inspect my-nginx

# 查看容器日志
docker logs my-nginx
docker logs -f my-nginx  # 实时查看
docker logs --tail 100 my-nginx  # 查看最后100行
docker logs --since "2024-01-01" my-nginx  # 指定时间

# 查看容器进程
docker top my-nginx

# 查看容器资源使用
docker stats my-nginx
```

## 二、镜像管理命令

### 2.1 镜像拉取与推送

**镜像操作命令**：

```bash
# 拉取镜像
docker pull nginx
docker pull nginx:latest
docker pull nginx:1.24.0

# 推送镜像
docker push my-registry.com/nginx:1.24.0

# 打标签
docker tag nginx:latest my-registry.com/nginx:1.24.0

# 删除镜像
docker rmi nginx
docker rmi $(docker images -aq)

# 查看镜像
docker images
docker images -q  # 只显示ID
```

### 2.2 镜像构建

**Dockerfile构建**：

```bash
# 基本构建
docker build -t my-app:1.0 .

# 指定Dockerfile路径
docker build -t my-app:1.0 -f Dockerfile.prod .

# 构建时传递参数
docker build --build-arg ENV=prod -t my-app:1.0 .

# 多阶段构建
docker build --target production -t my-app:1.0 .

# 从URL构建
docker build https://github.com/user/repo.git
```

### 2.3 镜像导出与导入

**镜像备份恢复**：

```bash
# 导出镜像
docker save nginx:latest > nginx.tar

# 导入镜像
docker load < nginx.tar

# 导出容器（包含运行状态）
docker export my-nginx > container.tar

# 导入为镜像
docker import container.tar my-nginx:exported
```

## 三、网络管理命令

### 3.1 网络创建与管理

**网络命令**：

```bash
# 创建网络
docker network create my-network
docker network create --driver bridge my-network
docker network create --driver overlay my-overlay-network

# 查看网络
docker network ls

# 查看网络详情
docker network inspect my-network

# 删除网络
docker network rm my-network

# 连接容器到网络
docker network connect my-network my-nginx

# 断开容器连接
docker network disconnect my-network my-nginx
```

### 3.2 网络模式

**网络模式对比**：

| 模式 | 说明 | 适用场景 |
|:----:|------|----------|
| **bridge** | 默认模式，隔离网络 | 容器间通信 |
| **host** | 共享宿主机网络 | 高性能场景 |
| **none** | 无网络 | 安全隔离 |
| **container** | 共享其他容器网络 | 容器间共享网络栈 |

## 四、数据卷管理命令

### 4.1 数据卷操作

**数据卷命令**：

```bash
# 创建数据卷
docker volume create my-volume

# 查看数据卷
docker volume ls

# 查看数据卷详情
docker volume inspect my-volume

# 删除数据卷
docker volume rm my-volume

# 删除未使用的数据卷
docker volume prune
```

### 4.2 挂载方式

**挂载类型对比**：

| 类型 | 命令 | 特点 |
|:----:|------|------|
| **数据卷** | `-v my-volume:/path` | 持久化存储，独立于容器 |
| **绑定挂载** | `-v /host/path:/path` | 直接挂载宿主机目录 |
| **tmpfs挂载** | `--tmpfs /path` | 临时存储，容器退出后消失 |

## 五、Docker Compose

### 5.1 基本命令

**Compose命令**：

```bash
# 启动服务
docker-compose up
docker-compose up -d

# 停止服务
docker-compose down

# 查看服务
docker-compose ps

# 查看日志
docker-compose logs
docker-compose logs -f

# 构建镜像
docker-compose build

# 重启服务
docker-compose restart

# 执行命令
docker-compose exec web bash

# 查看服务状态
docker-compose top
```

### 5.2 docker-compose.yml示例

**Compose配置示例**：

```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - web-data:/usr/share/nginx/html
    networks:
      - app-network
    restart: always

  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://db:5432/mydb
    depends_on:
      - db
    networks:
      - app-network

  db:
    image: postgres:14
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=secret
    networks:
      - app-network

volumes:
  web-data:
  db-data:

networks:
  app-network:
    driver: bridge
```

## 六、生产环境最佳实践

### 6.1 安全最佳实践

**安全建议**：

```yaml
security_best_practices:
  - "使用非root用户运行容器"
  - "避免使用latest标签"
  - "定期更新镜像"
  - "限制容器资源"
  - "启用Docker Content Trust"
  - "扫描镜像漏洞"
```

**安全命令**：

```bash
# 启用内容信任
export DOCKER_CONTENT_TRUST=1

# 扫描镜像漏洞
docker scan my-app:latest

# 使用非root用户
docker run --user 1000:1000 my-app
```

### 6.2 性能优化

**性能建议**：

```yaml
performance_best_practices:
  - "使用多阶段构建减小镜像大小"
  - "清理无用镜像和容器"
  - "限制日志大小"
  - "使用高效的基础镜像"
  - "启用镜像压缩"
```

**清理命令**：

```bash
# 清理未使用的资源
docker system prune
docker system prune -a

# 清理悬空镜像
docker images prune

# 清理未使用的数据卷
docker volume prune
```

### 6.3 监控与日志

**监控命令**：

```bash
# 查看Docker系统信息
docker system info

# 查看磁盘使用
docker system df

# 实时监控容器资源
docker stats

# 日志驱动配置
docker run --log-driver=json-file --log-opt max-size=10m --log-opt max-file=5 my-app
```

## 七、实战案例

### 7.1 案例一：部署Web应用

**步骤**：

```bash
# 1. 创建网络
docker network create web-network

# 2. 创建数据卷
docker volume create web-data

# 3. 启动应用
docker run -d \
  --name my-web \
  --network web-network \
  --volume web-data:/var/www/html \
  --publish 80:80 \
  --restart always \
  --cpus="1" \
  --memory="512m" \
  nginx:1.24.0

# 4. 验证
curl http://localhost
```

### 7.2 案例二：数据库备份

**步骤**：

```bash
# 1. 创建备份目录
mkdir -p /backup

# 2. 执行备份
docker exec my-postgres pg_dump -U admin mydb > /backup/db_backup.sql

# 3. 定时备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec my-postgres pg_dump -U admin mydb > /backup/db_backup_$DATE.sql

# 4. 恢复备份
cat /backup/db_backup.sql | docker exec -i my-postgres psql -U admin mydb
```

### 7.3 案例三：多容器应用

**使用Compose部署**：

```yaml
# docker-compose.yml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - api

  api:
    image: my-api:latest
    environment:
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis

  redis:
    image: redis:7
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

**部署命令**：

```bash
docker-compose up -d
docker-compose logs -f
```

## 八、面试1分钟精简版（直接背）

**完整版**：

常用Docker命令包括：容器管理类（docker run创建容器、docker start/stop/restart管理容器、docker rm删除容器）；镜像管理类（docker pull拉取镜像、docker build构建镜像、docker tag打标签、docker push推送镜像）；查看类（docker ps查看容器、docker images查看镜像、docker logs查看日志、docker inspect查看详情）；网络和数据卷管理（docker network/volume create/ls/rm）。这些是日常运维最常用的命令。

**30秒超短版**：

docker run启动容器，docker pull拉取镜像，docker ps查看容器，docker logs查看日志，docker build构建镜像。

## 九、总结

### 9.1 命令速查表

| 类别 | 命令 | 作用 |
|:----:|------|------|
| **容器管理** | `docker run/start/stop/restart/rm` | 容器生命周期管理 |
| **镜像管理** | `docker pull/build/tag/push/rmi` | 镜像生命周期管理 |
| **查看** | `docker ps/images/logs/inspect` | 查看信息 |
| **网络** | `docker network create/ls/rm` | 网络管理 |
| **数据卷** | `docker volume create/ls/rm` | 数据卷管理 |
| **Compose** | `docker-compose up/down/logs` | 多容器编排 |

### 9.2 最佳实践清单

```yaml
best_practices:
  - "使用--restart=always确保容器自动重启"
  - "限制容器资源使用"
  - "使用非root用户运行容器"
  - "定期清理无用资源"
  - "使用数据卷持久化数据"
  - "避免使用latest标签"
```

### 9.3 记忆口诀

```
Docker命令要记牢，容器管理run/start/stop，
镜像操作pull/build/tag，查看信息ps/images/logs，
网络创建network，数据卷用volume，
Compose编排多容器，生产环境要安全。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})