---
layout: post
title: "Docker Compose最佳实践：从开发到生产"
date: 2026-05-03 10:00:00 +0800
categories: [SRE, Docker, 容器编排]
tags: [Docker, Compose, 容器编排, 最佳实践, 开发环境, 生产环境]
---

# Docker Compose最佳实践：从开发到生产

## 情境(Situation)

Docker Compose是容器编排的重要工具，它允许开发者和运维人员使用YAML文件定义和管理多容器应用。在实际应用中，从开发环境到生产环境，Docker Compose都发挥着重要作用。

作为SRE工程师，我们需要掌握Docker Compose的最佳实践，确保应用在不同环境中稳定运行，同时提高开发和部署效率。

## 冲突(Conflict)

在实际应用中，SRE工程师经常面临以下挑战：

- **配置管理**：不同环境的配置管理复杂
- **性能优化**：容器资源分配和性能调优
- **安全性**：敏感信息的管理和安全配置
- **可维护性**：配置文件的可读性和可维护性
- **部署一致性**：确保开发、测试和生产环境的一致性

## 问题(Question)

如何使用Docker Compose构建高效、安全、可维护的多容器应用，从开发环境平滑过渡到生产环境？

## 答案(Answer)

本文将从SRE视角出发，详细介绍Docker Compose的最佳实践，提供一套完整的从开发到生产的容器编排解决方案。核心方法论基于 [SRE面试题解析：docker compose支持哪种格式的配置文件？]({% post_url 2026-04-15-sre-interview-questions %}#55-docker-compose支持哪种格式的配置文件)。

---

## 一、Docker Compose概述

### 1.1 配置文件格式

**Docker Compose配置文件格式**：

| 格式 | 推荐文件名 | 说明 | 推荐度 | 适用场景 |
|:------|:------|:------|:------|:----------|
| **YAML** | `compose.yaml` | 标准格式，可读性好 | ⭐⭐⭐⭐⭐ | 新项目、标准环境 |
| **YAML** | `docker-compose.yml` | 旧格式，兼容 | ⭐⭐⭐⭐ | 现有项目、旧环境 |
| **JSON** | `docker-compose.json` | 早期支持，已很少用 | ⭐ | 自动化生成、特殊场景 |

### 1.2 YAML语法要点

**YAML语法规则**：

| 规则 | 正确写法 | 错误写法 | 说明 |
|:------|:------|:------|:------|
| **缩进** | 2个空格 | Tab | 必须使用空格，不能使用Tab |
| **键值对** | `key: value` | `key:value` | 冒号后必须加空格 |
| **列表** | `- item` | `* item` | 列表项以减号开头，后跟空格 |
| **注释** | `# 注释` | `// 注释` | 只能使用#开头的注释 |
| **字符串** | `string` 或 `"string"` | 无 | 空格或特殊字符需用引号 |
| **多行字符串** | `>-` 或 `|` | 无 | 保留换行或折叠换行 |
| **布尔值** | `true`/`false` | `True`/`False` | 小写字母 |
| **数字** | `123` | `"123"` | 直接写数字，无需引号 |

### 1.3 配置文件结构

**基本配置结构**：

```yaml
# compose.yaml
version: '3.8'      # 版本声明
name: "my-project"  # 项目名称（可选）
services:           # 服务定义（必须）
  web:
    image: nginx
    ports:
      - "80:80"
    networks:
      - custom-net
    volumes:
      - app-data:/data
    environment:
      - DEBUG=false
    restart: always
    deploy:          # Swarm部署配置
      replicas: 3
      resources:
        limits:
          cpus: "1"
          memory: "1G"
networks:           # 网络定义
  custom-net: {}
volumes:            # 卷定义
  app-data: {}
configs:            # 配置文件（Swarm）
  app-config: {}
secrets:            # 敏感信息（Swarm）
  db-password: {}
profiles:           # 配置分组（可选）
  - debug
  - production
```

---

## 二、开发环境最佳实践

### 2.1 开发环境配置

**开发环境配置示例**：

```yaml
# compose.yaml (开发环境)
version: '3.8'
name: "dev-project"
services:
  web:
    build: .
    ports:
      - "8080:80"
    volumes:
      - .:/app
      - node_modules:/app/node_modules
    environment:
      - NODE_ENV=development
      - DEBUG=true
    command: npm run dev
    depends_on:
      - db
  db:
    image: postgres:14
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
volumes:
  postgres-data:
  node_modules:
```

**开发环境特点**：
- 使用`build`构建本地镜像
- 挂载代码目录，支持热重载
- 暴露所有端口，方便调试
- 使用简单的环境变量
- 依赖服务使用默认配置

### 2.2 多环境配置

**多环境配置方法**：

1. **覆盖文件**：

```yaml
# compose.override.yaml (开发环境覆盖)
services:
  web:
    environment:
      - DEBUG=true
    ports:
      - "3000:3000"
  db:
    ports:
      - "5432:5432"
```

2. **指定多个文件**：

```bash
# 开发环境
docker compose -f compose.yaml -f compose.dev.yaml up

# 测试环境
docker compose -f compose.yaml -f compose.test.yaml up

# 生产环境
docker compose -f compose.yaml -f compose.prod.yaml up
```

3. **环境变量文件**：

```bash
# .env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=app
DB_USER=user
DB_PASSWORD=password
```

4. **变量引用**：

```yaml
# compose.yaml
services:
  db:
    image: postgres
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
```

### 2.3 开发工具集成

**开发工具集成**：

1. **VS Code Dev Containers**：

```json
// .devcontainer/devcontainer.json
{
  "name": "Node.js & Postgres",
  "dockerComposeFile": ["../compose.yaml"],
  "service": "web",
  "workspaceFolder": "/app"
}
```

2. **Docker Desktop**：
- 集成Docker Compose，支持一键启动
- 提供图形化界面管理容器
- 支持容器日志查看和终端访问

3. **CI/CD集成**：

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and test
        run: |
          docker compose -f compose.yaml -f compose.test.yaml up --build --exit-code-from web
```

---

## 三、生产环境最佳实践

### 3.1 生产环境配置

**生产环境配置示例**：

```yaml
# compose.yaml (生产环境)
version: '3.8'
name: "prod-project"
services:
  web:
    image: myapp/web:latest
    ports:
      - "80:80"
    networks:
      - frontend
      - backend
    volumes:
      - static-files:/app/static
    environment:
      - NODE_ENV=production
      - DEBUG=false
    restart: always
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: "1"
          memory: "1G"
        reservations:
          cpus: "0.5"
          memory: "512M"
      update_config:
        parallelism: 2
        delay: 10s
      restart_policy:
        condition: on-failure
  api:
    image: myapp/api:latest
    networks:
      - backend
    environment:
      - NODE_ENV=production
    restart: always
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: "0.5"
          memory: "512M"
  db:
    image: postgres:14
    networks:
      - backend
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
    secrets:
      - db-password
    restart: always
    deploy:
      resources:
        limits:
          cpus: "1"
          memory: "2G"
networks:
  frontend:
  backend:
    internal: true
volumes:
  postgres-data:
  static-files:
secrets:
  db-password:
    external: true
```

**生产环境特点**：
- 使用预构建的镜像，不使用`build`
- 限制资源使用，设置CPU和内存限制
- 使用网络隔离，内外网分离
- 使用secrets管理敏感信息
- 配置部署策略，支持滚动更新
- 不挂载代码目录，确保环境一致性

### 3.2 安全最佳实践

**安全配置**：

1. **敏感信息管理**：

```yaml
# 使用secrets
secrets:
  db-password:
    file: ./secrets/db-password.txt

# 或使用外部secrets
secrets:
  db-password:
    external: true
```

2. **非root用户**：

```dockerfile
# Dockerfile
FROM node:16-alpine

# 创建非root用户
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001

# 切换到非root用户
USER appuser

WORKDIR /app

COPY --chown=appuser:appgroup package*.json ./
RUN npm install

COPY --chown=appuser:appgroup . .

EXPOSE 3000

CMD ["npm", "start"]
```

3. **网络安全**：

```yaml
# 内部网络
networks:
  backend:
    internal: true
  frontend:
    driver: bridge
```

4. **镜像安全**：
- 使用官方镜像
- 定期更新镜像
- 扫描镜像漏洞
- 使用最小化基础镜像

### 3.3 性能优化

**性能优化配置**：

1. **资源限制**：

```yaml
deploy:
  resources:
    limits:
      cpus: "1"
      memory: "1G"
    reservations:
      cpus: "0.5"
      memory: "512M"
```

2. **健康检查**：

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:80/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

3. **启动顺序**：

```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_started
```

4. **网络优化**：

```yaml
networks:
  app-network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
      com.docker.network.bridge.host_binding_ipv4: "0.0.0.0"
```

---

## 四、高级功能

### 4.1 服务编排

**服务编排功能**：

1. **服务依赖**：

```yaml
services:
  web:
    depends_on:
      - db
      - redis
  db:
    image: postgres
  redis:
    image: redis
```

2. **服务健康检查**：

```yaml
services:
  web:
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3
```

3. **服务更新策略**：

```yaml
deploy:
  update_config:
    parallelism: 2
    delay: 10s
    order: start-first
  rollback_config:
    parallelism: 1
    delay: 10s
```

### 4.2 网络配置

**网络配置**：

1. **自定义网络**：

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.18.0.0/16
  backend:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.19.0.0/16
```

2. **外部网络**：

```yaml
networks:
  external-net:
    external: true
    name: existing-network
```

3. **Overlay网络**（Swarm）：

```yaml
networks:
  overlay-net:
    driver: overlay
    attachable: true
```

### 4.3 卷配置

**卷配置**：

1. **命名卷**：

```yaml
volumes:
  db-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/data
```

2. **外部卷**：

```yaml
volumes:
  db-data:
    external: true
    name: existing-volume
```

3. **临时卷**：

```yaml
services:
  app:
    volumes:
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100m
```

### 4.4 配置文件和 Secrets

**配置文件**：

```yaml
configs:
  app-config:
    file: ./config/app.conf
  nginx-config:
    file: ./config/nginx.conf

services:
  app:
    configs:
      - source: app-config
        target: /app/config.conf
  nginx:
    configs:
      - source: nginx-config
        target: /etc/nginx/nginx.conf
```

**Secrets**：

```yaml
secrets:
  db-password:
    file: ./secrets/db-password.txt
  api-key:
    external: true

services:
  db:
    secrets:
      - db-password
  api:
    secrets:
      - api-key
```

---

## 五、Docker Compose命令

### 5.1 常用命令

**基本命令**：

| 命令 | 功能 | 示例 |
|:------|:------|:------|
| **up** | 启动服务 | `docker compose up` |
| **down** | 停止并移除服务 | `docker compose down` |
| **build** | 构建服务 | `docker compose build` |
| **ps** | 查看服务状态 | `docker compose ps` |
| **logs** | 查看服务日志 | `docker compose logs` |
| **exec** | 进入容器 | `docker compose exec web bash` |
| **pull** | 拉取镜像 | `docker compose pull` |
| **push** | 推送镜像 | `docker compose push` |
| **config** | 验证配置 | `docker compose config` |
| **scale** | 缩放服务 | `docker compose scale web=3` |

**高级命令**：

| 命令 | 功能 | 示例 |
|:------|:------|:------|
| **up --build** | 构建并启动 | `docker compose up --build` |
| **up -d** | 后台启动 | `docker compose up -d` |
| **down -v** | 移除卷 | `docker compose down -v` |
| **logs -f** | 实时日志 | `docker compose logs -f` |
| **exec -it** | 交互式进入 | `docker compose exec -it web bash` |
| **run --rm** | 临时运行 | `docker compose run --rm web ls` |
| **config --quiet** | 静默验证 | `docker compose config --quiet` |
| **config --resolve-image-digests** | 解析镜像摘要 | `docker compose config --resolve-image-digests` |

### 5.2 命令技巧

**实用技巧**：

1. **快速启动开发环境**：

```bash
# 启动并构建
docker compose up --build -d

# 查看日志
docker compose logs -f

# 进入容器
docker compose exec web bash

# 停止并清理
docker compose down -v
```

2. **多环境管理**：

```bash
# 开发环境
docker compose -f compose.yaml -f compose.dev.yaml up

# 测试环境
docker compose -f compose.yaml -f compose.test.yaml up

# 生产环境
docker compose -f compose.yaml -f compose.prod.yaml up
```

3. **镜像管理**：

```bash
# 构建特定服务
docker compose build web

# 拉取最新镜像
docker compose pull

# 推送镜像
docker compose push
```

4. **配置验证**：

```bash
# 验证配置
docker compose config

# 验证并输出配置文件
docker compose config > docker-compose.yml

# 检查配置语法
docker compose config --quiet
```

---

## 六、常见问题与解决方案

### 6.1 YAML语法错误

**问题**：YAML语法错误导致配置文件无法解析

**解决方案**：
- 使用2个空格缩进，不要使用Tab
- 键值对冒号后加空格
- 字符串包含空格或特殊字符时使用引号
- 使用YAML验证工具检查语法
- 查看错误信息，定位具体错误位置

**验证工具**：
- onlineyamltools.com
- yamllint
- VS Code YAML插件

### 6.2 环境变量不生效

**问题**：环境变量在容器中不生效

**解决方案**：
- 检查.env文件路径，确保在compose.yaml同目录
- 检查环境变量名格式，确保正确
- 使用`docker compose config`查看解析后的配置
- 检查容器内环境变量：`docker compose exec web env`
- 确保环境变量在正确的服务中定义

### 6.3 服务启动顺序问题

**问题**：服务启动顺序不当，依赖服务未就绪

**解决方案**：
- 使用`depends_on`指定依赖关系
- 使用`condition`设置启动条件
- 实现健康检查，确保服务就绪
- 在应用中实现重试机制

**示例**：

```yaml
depends_on:
  db:
    condition: service_healthy
  redis:
    condition: service_started
```

### 6.4 网络通信问题

**问题**：容器间网络通信失败

**解决方案**：
- 确保服务在同一网络中
- 检查网络配置，确保网络正确创建
- 使用服务名作为主机名，而不是IP地址
- 检查防火墙规则，确保端口开放
- 使用`docker compose exec`测试网络连通性

**测试命令**：

```bash
# 测试容器间通信
docker compose exec web ping db

# 测试服务端口
docker compose exec web curl http://api:8000
```

### 6.5 性能问题

**问题**：容器性能不佳，资源使用过高

**解决方案**：
- 设置合理的资源限制和预留
- 优化应用代码和配置
- 使用健康检查，及时发现问题
- 监控容器资源使用情况
- 考虑使用更轻量的基础镜像

**监控命令**：

```bash
# 查看资源使用
docker stats

# 查看容器详细信息
docker inspect <container-id>
```

---

## 七、企业级最佳实践

### 7.1 项目结构

**推荐项目结构**：

```
project/
├── compose.yaml           # 基础配置
├── compose.dev.yaml       # 开发环境配置
├── compose.test.yaml      # 测试环境配置
├── compose.prod.yaml      # 生产环境配置
├── .env                   # 环境变量
├── .env.example           # 环境变量示例
├── Dockerfile             # 应用镜像构建
├── dockerfiles/           # 其他服务Dockerfile
│   ├── nginx.Dockerfile
│   └── redis.Dockerfile
├── config/                # 配置文件
│   ├── nginx.conf
│   └── app.conf
├── secrets/               # 敏感信息（不提交到版本控制）
│   └── db-password.txt
└── src/                   # 应用代码
```

### 7.2 CI/CD集成

**CI/CD配置示例**：

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build images
        run: |
          docker compose build
      - name: Push images
        run: |
          docker login -u ${{ secrets.DOCKER_USERNAME }} -p ${{ secrets.DOCKER_PASSWORD }}
          docker compose push
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: |
          ssh ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }} << 'EOF'
            cd /app
            git pull
            docker compose -f compose.yaml -f compose.prod.yaml pull
            docker compose -f compose.yaml -f compose.prod.yaml up -d
          EOF
```

### 7.3 监控与日志

**监控配置**：

1. **Prometheus + Grafana**：

```yaml
# compose.monitoring.yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
volumes:
  grafana-data:
```

2. **ELK Stack**：

```yaml
# compose.logging.yaml
services:
  elasticsearch:
    image: elasticsearch:7.14.0
    volumes:
      - es-data:/usr/share/elasticsearch/data
    environment:
      - discovery.type=single-node
  logstash:
    image: logstash:7.14.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf
  kibana:
    image: kibana:7.14.0
    ports:
      - "5601:5601"
volumes:
  es-data:
```

### 7.4 灾难恢复

**灾难恢复策略**：

1. **数据备份**：

```bash
# 备份数据库
 docker compose exec db pg_dump -U postgres app > backup.sql

# 备份卷
docker run --rm -v myapp_db-data:/data -v $(pwd)/backup:/backup busybox tar cvf /backup/db-data.tar /data
```

2. **高可用配置**：

```yaml
# compose.ha.yaml
services:
  web:
    deploy:
      replicas: 3
      placement:
        max_replicas_per_node: 1
      restart_policy:
        condition: any
  db:
    deploy:
      replicas: 1
      restart_policy:
        condition: any
    volumes:
      - db-data:/var/lib/postgresql/data
volumes:
  db-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: :/path/to/db-data
```

---

## 八、最佳实践总结

### 8.1 核心原则

**Docker Compose核心原则**：

1. **配置分离**：将不同环境的配置分离，使用多文件管理
2. **环境变量**：使用环境变量管理配置，避免硬编码
3. **资源限制**：设置合理的资源限制，确保系统稳定
4. **安全优先**：使用非root用户，管理敏感信息
5. **健康检查**：实现健康检查，确保服务就绪
6. **网络隔离**：使用网络隔离，提高安全性
7. **卷管理**：合理使用卷，确保数据持久化
8. **版本控制**：将配置文件纳入版本控制
9. **监控与日志**：建立监控和日志系统
10. **文档化**：记录配置和部署流程

### 8.2 配置建议

**生产环境配置清单**：
- [ ] 使用`compose.yaml`标准文件名
- [ ] 设置资源限制和预留
- [ ] 实现健康检查
- [ ] 使用非root用户运行容器
- [ ] 管理敏感信息（secrets或环境变量）
- [ ] 配置网络隔离
- [ ] 设置合理的重启策略
- [ ] 配置部署策略（滚动更新）
- [ ] 建立监控和日志系统
- [ ] 定期备份数据

**开发环境配置清单**：
- [ ] 使用`build`构建本地镜像
- [ ] 挂载代码目录，支持热重载
- [ ] 暴露所有端口，方便调试
- [ ] 使用简单的环境变量
- [ ] 配置开发工具集成
- [ ] 实现快速启动和清理

### 8.3 经验总结

**常见误区**：
- **硬编码配置**：将敏感信息硬编码在配置文件中
- **资源无限制**：不设置资源限制，导致资源竞争
- **网络配置不当**：容器间网络通信失败
- **启动顺序问题**：服务依赖未正确配置
- **环境不一致**：开发和生产环境配置差异大
- **监控不足**：缺乏对容器的监控和日志

**成功经验**：
- **标准化配置**：建立统一的配置标准和结构
- **自动化部署**：使用CI/CD自动化部署流程
- **环境一致性**：确保开发、测试和生产环境一致
- **定期维护**：定期更新镜像和配置
- **文档化**：记录配置和部署流程
- **持续优化**：根据实际运行情况优化配置

---

## 总结

Docker Compose是容器编排的强大工具，通过本文介绍的最佳实践，您可以构建高效、安全、可维护的多容器应用。从开发环境到生产环境，Docker Compose提供了一致的配置和部署体验。

**核心要点**：

1. **配置管理**：使用多文件和环境变量管理不同环境的配置
2. **安全配置**：使用非root用户，管理敏感信息，配置网络隔离
3. **性能优化**：设置资源限制，实现健康检查，优化网络配置
4. **部署策略**：配置滚动更新，实现高可用
5. **监控与日志**：建立监控和日志系统，及时发现问题
6. **灾难恢复**：定期备份数据，制定灾难恢复策略

通过遵循这些最佳实践，我们可以确保应用在不同环境中稳定运行，提高开发和部署效率，为业务应用提供可靠的容器化解决方案。

> **延伸学习**：更多面试相关的Docker Compose知识，请参考 [SRE面试题解析：docker compose支持哪种格式的配置文件？]({% post_url 2026-04-15-sre-interview-questions %}#55-docker-compose支持哪种格式的配置文件)。

---

## 参考资料

- [Docker Compose官方文档](https://docs.docker.com/compose/)
- [Docker Compose文件格式参考](https://docs.docker.com/compose/compose-file/)
- [Docker Compose最佳实践](https://docs.docker.com/compose/best-practices/)
- [YAML语法参考](https://yaml.org/spec/1.2.2/)
- [Docker官方示例](https://github.com/docker/awesome-compose)
- [Docker安全最佳实践](https://docs.docker.com/engine/security/)
- [容器编排最佳实践](https://kubernetes.io/docs/concepts/configuration/)
- [CI/CD集成指南](https://docs.github.com/en/actions/automating-builds-and-tests)
- [监控与日志最佳实践](https://prometheus.io/docs/introduction/overview/)
- [灾难恢复策略](https://docs.docker.com/storage/volumes/)
- [网络配置指南](https://docs.docker.com/network/)
- [资源管理最佳实践](https://docs.docker.com/config/containers/resource_constraints/)
- [Docker Compose命令参考](https://docs.docker.com/compose/reference/)
- [多环境配置管理](https://docs.docker.com/compose/environment-variables/)
- [Docker Compose与Swarm集成](https://docs.docker.com/engine/swarm/stack-deploy/)
- [企业级Docker实践](https://www.docker.com/blog/enterprise-docker-best-practices/)
- [容器性能优化](https://www.docker.com/blog/container-performance-optimization/)
- [DevOps最佳实践](https://aws.amazon.com/devops/what-is-devops/)
- [微服务架构设计](https://microservices.io/patterns/microservices.html)