---
layout: post
title: Hexo博客部署完全指南
categories: [Blog]
description: 本教程将详细介绍如何下载安装 Hexo博客系统
keywords: Blog, Hexo
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---
# Hexo博客部署完全指南

## 1. 准备工作

### 系统要求

- Linux服务器（推荐Ubuntu 20.04 LTS或Rocky Linux 8）
- 至少1GB RAM（推荐2GB或更多）
- 至少10GB磁盘空间
- 具有root或sudo权限的用户
- 稳定的网络连接

### 预先安装的依赖

在开始安装Node.js和Hexo之前，先确保系统已更新并安装了必要的构建工具：

```bash
# Ubuntu/Debian系统
apt update && apt upgrade -y
apt install -y curl git build-essential

# Rocky Linux/CentOS系统
dnf update -y
dnf install -y curl git gcc-c++ make
```

## 2. Node.js和npm安装

Node.js是运行Hexo博客框架的必要环境，npm（Node Package Manager）用于管理Node.js包。

### 方法一：使用NodeSource仓库安装（推荐）

NodeSource提供了最新稳定版的Node.js安装包：

```bash
# 添加NodeSource仓库（以Node.js 16.x为例）
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt install -y nodejs

# Rocky Linux/CentOS
curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
dnf install -y nodejs
```

### 方法二：使用nvm（Node Version Manager）安装

nvm允许你同时管理多个Node.js版本，适合需要灵活切换Node.js版本的用户：

```bash
# 安装nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# 重新加载bash配置文件
source ~/.bashrc  # 或 source ~/.zshrc 如果你使用zsh

# 安装Node.js（以Node.js 16为例）
nvm install 16

# 设置默认Node.js版本
nvm use 16
```

### 验证安装

安装完成后，验证Node.js和npm是否正确安装：

```bash
# 检查Node.js版本
node -v

# 检查npm版本
npm -v
```

## 3. Hexo安装与配置

### 3.1 全局安装Hexo CLI

使用npm全局安装Hexo命令行工具：

```bash
npm install -g hexo-cli
```

### 3.2 创建Hexo博客项目

选择一个目录作为Hexo博客的根目录，然后初始化项目：

```bash
# 创建并进入博客目录
mkdir -p ~/hexo-blog
cd ~/hexo-blog

# 初始化Hexo项目
hexo init

# 安装依赖
npm install
```

### 3.3 Hexo目录结构说明

```
.├── _config.yml      # 站点配置文件├── package.json     # 项目依赖配置├── scaffolds/       # 文章模板├── source/          # 源文件目录│   ├── _drafts/     # 草稿│   └── _posts/      # 文章├── themes/          # 主题目录└── public/          # 生成的静态文件（部署用）
```

### 3.4 配置Hexo站点

编辑站点配置文件`_config.yml`，设置博客的基本信息：

```yaml
# 网站基本信息
title: 我的Hexo博客
description: 个人技术博客
author: 你的名字
language: zh-CN
timezone: Asia/Shanghai

# 网址配置
url: https://你的域名或IP
directory_index: true

# 主题设置
theme: landscape  # 默认主题，后续可以更换

# 部署配置
deploy:
  type: ''
```

## 4. Hexo基本使用

### 4.1 创建新文章

```bash
# 创建新文章
hexo new "文章标题"

# 创建草稿
hexo new draft "草稿标题"

# 将草稿发布为正式文章
hexo publish draft "草稿标题"
```

### 4.2 本地预览

```bash
# 生成静态文件
hexo generate  # 或简写为 hexo g

# 启动本地服务器
hexo server    # 或简写为 hexo s

# 指定端口启动（默认4000）
hexo server -p 8080
```

启动后，可以通过浏览器访问`http://localhost:4000`预览博客。

### 4.3 清理缓存

```bash
# 清理生成的静态文件和缓存
hexo clean
```

## 5. Nginx安装与配置

### 5.1 安装Nginx

```bash
# Ubuntu/Debian
apt install -y nginx

# Rocky Linux/CentOS
dnf install -y nginx
```

### 5.2 启动并设置开机自启

```bash
# 启动Nginx
systemctl start nginx

# 设置开机自启
systemctl enable nginx

# 检查Nginx状态
systemctl status nginx
```

### 5.3 配置防火墙（如果已启用）

```bash
# Ubuntu/Debian (ufw)
ufw allow 'Nginx Full'

# Rocky Linux/CentOS (firewalld)
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

### 5.4 创建Nginx站点配置

创建一个新的Nginx配置文件来托管Hexo博客：

```bash
# 创建配置文件
nano /etc/nginx/conf.d/hexo.conf
```

在配置文件中添加以下内容（根据你的实际情况修改）：

```nginx
server {
    listen 80;
    server_name 你的域名或IP;
    
    # 设置字符集
    charset utf-8;
    
    # 访问日志
    access_log /var/log/nginx/hexo_access.log;
    error_log /var/log/nginx/hexo_error.log;
    
    # 设置根目录为Hexo生成的静态文件目录
    root /home/你的用户名/hexo-blog/public;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 配置压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 设置过期时间
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
}
```

### 5.5 测试并应用Nginx配置

```bash
# 测试Nginx配置
nginx -t

# 重新加载Nginx配置
systemctl reload nginx
```

## 6. Hexo博客部署

### 6.1 方法一：手动部署（直接复制静态文件）

每次修改博客后，生成静态文件并复制到Nginx的根目录：

```bash
# 在Hexo博客目录中
cd ~/hexo-blog

# 清理并生成静态文件
hexo clean && hexo generate

# 将生成的静态文件复制到Nginx目录（需要sudo权限）
sudo cp -r public/* /var/www/html/
```

### 6.2 方法二：使用Hexo部署插件（推荐）

安装hexo-deployer-rsync插件，用于自动部署：

```bash
# 安装部署插件
npm install hexo-deployer-rsync --save
```

修改`_config.yml`文件，配置部署选项：

```yaml
deploy:
  type: rsync
  host: 127.0.0.1  # 本地部署，远程部署则填写远程服务器IP
  user: root       # 用户名
  root: /var/www/html/  # Nginx根目录
  port: 22         # SSH端口
  delete: true     # 删除目标目录中不存在的文件
  verbose: true    # 显示详细信息
  ignore_errors: false  # 忽略错误
```

使用命令部署：

```bash
hexo clean && hexo deploy
```

### 6.3 方法三：使用CI/CD自动部署（高级）

对于频繁更新的博客，可以设置CI/CD流程自动部署。这里以GitHub Actions为例：

1. 在GitHub上创建一个仓库，存放Hexo博客源码
2. 创建`.github/workflows/deploy.yml`文件：

```yaml
name: Deploy Hexo Blog

on:
  push:
    branches: [ main ]  # 主分支名

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 0
        
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '16'
        
    - name: Install dependencies
      run: |
        npm install
        npm install -g hexo-cli
        
    - name: Generate static files
      run: |
        hexo clean
        hexo generate
        
    - name: Deploy to server
      uses: easingthemes/ssh-deploy@v2.1.5
      env:
        SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
        ARGS: "-rltgoDzvO --delete"
        SOURCE: "public/"
        REMOTE_HOST: ${{ secrets.REMOTE_HOST }}
        REMOTE_USER: ${{ secrets.REMOTE_USER }}
        TARGET: ${{ secrets.REMOTE_TARGET }}
```

3. 在GitHub仓库的Settings > Secrets中添加以下密钥：
   - SSH_PRIVATE_KEY：用于连接服务器的SSH私钥
   - REMOTE_HOST：服务器IP地址
   - REMOTE_USER：服务器用户名
   - REMOTE_TARGET：Nginx根目录路径

## 7. 自定义Hexo主题

Hexo支持丰富的主题，可以根据个人喜好更换：

### 7.1 安装新主题

以安装流行的NexT主题为例：

```bash
# 进入Hexo博客目录
cd ~/hexo-blog

# 克隆NexT主题到themes目录
git clone https://github.com/theme-next/hexo-theme-next themes/next
```

### 7.2 启用主题

修改`_config.yml`文件：

```yaml
theme: next
```

### 7.3 主题配置

主题配置文件位于`themes/next/_config.yml`，可以根据需要进行定制。也可以在站点根目录创建`_config.next.yml`文件进行配置，这样可以避免在主题更新时丢失配置。

## 8. Hexo插件推荐

### 8.1 常用插件

```bash
# 代码高亮增强
npm install hexo-prism-plugin --save

# 图片懒加载
npm install hexo-lazyload-image --save

# 站点地图
npm install hexo-generator-sitemap --save
npm install hexo-generator-baidu-sitemap --save

# RSS订阅
npm install hexo-generator-feed --save

# 搜索功能
npm install hexo-generator-search --save
```

### 8.2 插件配置示例

在`_config.yml`中添加插件配置：

```yaml
# 代码高亮
prism_plugin:
  mode: 'preprocess'    # 实时页面渲染
  theme: 'tomorrow'
  line_number: true     # 显示行号

# 站点地图
sitemap:
  path: sitemap.xml

# RSS订阅
feed:
  type: atom
  path: atom.xml
  limit: 20
```

## 9. 博客优化技巧

### 9.1 性能优化

- **启用压缩**：确保Nginx已配置gzip压缩
- **图片优化**：压缩图片大小，使用适当的格式
- **静态资源CDN**：将静态资源托管到CDN上
- **预加载**：对关键资源使用preload
- **缓存策略**：合理设置缓存过期时间

### 9.2 SEO优化

- **添加站点地图**：安装并配置sitemap插件
- **设置meta标签**：在主题配置中设置description等元数据
- **使用语义化HTML**：确保主题使用适当的HTML标签
- **添加robots.txt**：在source目录下创建robots.txt文件
- **结构化数据**：添加Schema.org结构化数据

### 9.3 安全加固

- **使用HTTPS**：配置SSL证书（可使用Let's Encrypt免费证书）
- **限制访问**：根据需要配置访问控制
- **更新依赖**：定期更新Hexo和插件版本
- **Nginx安全配置**：隐藏版本信息，限制请求方法等

## 10. 常见问题排查

### 10.1 本地预览问题

- **端口被占用**：使用`hexo s -p 其他端口`指定不同端口
- **页面空白**：检查主题配置和站点URL设置
- **资源加载失败**：检查路径是否正确，确保使用绝对路径

### 10.2 Nginx部署问题

- **404错误**：检查Nginx配置中的root路径是否正确
- **权限问题**：确保Nginx用户有访问静态文件的权限
- **502错误**：检查服务是否正常运行，日志文件位于`/var/log/nginx/`

### 10.3 部署后样式丢失

- **路径问题**：确保站点配置中的url设置正确
- **相对路径问题**：修改主题配置，使用绝对URL

### 10.4 命令执行失败

- **依赖冲突**：删除`node_modules`目录和`package-lock.json`文件，重新运行`npm install`
- **Node.js版本问题**：尝试使用不同版本的Node.js（使用nvm）

## 11. 总结

通过本指南，我们完成了以下任务：

1. 安装并配置了Node.js和npm
2. 安装了Hexo博客框架并创建了项目
3. 安装并配置了Nginx作为Web服务器
4. 学习了多种Hexo博客部署方法
5. 了解了主题自定义和插件使用
6. 掌握了博客优化和问题排查技巧

现在，你已经拥有了一个功能完整的Hexo博客，可以开始创作和分享你的内容了！

## 12. 扩展资源

- [Hexo官方文档](https://hexo.io/zh-cn/docs/)
- [Nginx官方文档](http://nginx.org/en/docs/)
- [Node.js官方文档](https://nodejs.org/en/docs/)
- [Let's Encrypt文档](https://letsencrypt.org/docs/)
- [GitHub Actions文档](https://docs.github.com/cn/actions)