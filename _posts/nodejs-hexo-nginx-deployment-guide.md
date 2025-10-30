# Node.js、Hexo和Nginx安装与博客部署完整指南

## 1. Node.js安装

Node.js是一个基于Chrome V8引擎的JavaScript运行时环境，我们将使用它来运行Hexo博客框架。

### 1.1 Linux系统安装Node.js

#### 在Ubuntu/Debian系统上安装

```bash
# 更新系统包
sudo apt update

# 安装必要的依赖
sudo apt install -y ca-certificates curl gnupg

# 添加Node.js官方GPG密钥
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

# 设置Node.js 20.x存储库（长期支持版本）
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/nodesource.list

# 再次更新包并安装Node.js
sudo apt update
sudo apt install -y nodejs

# 验证安装
node -v
npm -v
```

#### 在Rocky Linux/CentOS系统上安装

```bash
# 更新系统包
sudo dnf update -y

# 添加Node.js官方存储库（使用NodeSource）
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -

# 安装Node.js
sudo dnf install -y nodejs

# 验证安装
node -v
npm -v
```

### 1.2 macOS系统安装Node.js

#### 使用Homebrew安装（推荐）

```bash
# 如果没有安装Homebrew，请先安装
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装Node.js
brew install node

# 验证安装
node -v
npm -v
```

#### 使用官方安装包

1. 访问Node.js官方网站：https://nodejs.org/
2. 下载LTS（长期支持）版本的macOS安装包
3. 双击安装包并按照提示完成安装
4. 打开终端验证安装：`node -v` 和 `npm -v`

### 1.3 Windows系统安装Node.js

1. 访问Node.js官方网站：https://nodejs.org/
2. 下载LTS版本的Windows安装包（.msi）
3. 双击安装包，勾选"Add Node.js to PATH"选项
4. 按照向导完成安装
5. 打开命令提示符或PowerShell验证安装：`node -v` 和 `npm -v`

## 2. Hexo博客框架安装与配置

Hexo是一个快速、简洁且高效的博客框架，基于Node.js。

### 2.1 安装Hexo CLI

```bash
# 全局安装Hexo CLI
sudo npm install -g hexo-cli

# 验证安装
hexo -v
```

### 2.2 创建Hexo博客项目

```bash
# 创建博客目录并初始化Hexo项目
mkdir -p ~/hexo-blog
cd ~/hexo-blog
hexo init

# 安装依赖
npm install
```

### 2.3 Hexo基本配置

编辑Hexo配置文件`_config.yml`，设置博客基本信息：

```bash
# 打开配置文件进行编辑（使用你喜欢的编辑器）
# 在Linux/macOS上
nano ~/hexo-blog/_config.yml

# 在Windows上可以使用记事本或VS Code
# notepad %USERPROFILE%\hexo-blog\_config.yml
```

主要配置项说明：

```yaml
title: 我的Hexo博客     # 博客标题
author: Your Name       # 作者名称
description: 描述信息   # 博客描述
language: zh-CN         # 语言
url: https://your-domain.com  # 网站URL
root: /                 # 网站根目录
theme: landscape        # 主题，默认为landscape
```

### 2.4 Hexo常用命令

```bash
# 生成静态文件
hexo generate  # 或简写为 hexo g

# 启动本地服务器
hexo server    # 或简写为 hexo s

# 创建新文章
hexo new "文章标题"  # 或简写为 hexo n "文章标题"

# 部署网站
hexo deploy    # 或简写为 hexo d

# 清理缓存文件
hexo clean
```

### 2.5 创建你的第一篇博客文章

```bash
# 创建新文章
cd ~/hexo-blog
hexo new "我的第一篇博客文章"

# 编辑文章（位于source/_posts/目录下）
nano source/_posts/我的第一篇博客文章.md
```

文章使用Markdown格式，你可以添加内容，例如：

```markdown
# 我的第一篇博客文章

> 这是我的第一篇Hexo博客文章！

## 介绍

欢迎来到我的Hexo博客。这是使用Hexo框架搭建的个人博客站点。

## 关于我

我是一名开发者，热衷于技术分享和学习。

## 总结

希望你喜欢我的博客！
```

## 3. Nginx安装与配置

Nginx是一个高性能的HTTP和反向代理服务器，我们将使用它来托管Hexo生成的静态博客。

### 3.1 Linux系统安装Nginx

#### 在Ubuntu/Debian系统上安装

```bash
# 更新系统包
sudo apt update

# 安装Nginx
sudo apt install -y nginx

# 启动Nginx服务
sudo systemctl start nginx

# 设置Nginx开机自启
sudo systemctl enable nginx

# 检查Nginx状态
sudo systemctl status nginx
```

#### 在Rocky Linux/CentOS系统上安装

```bash
# 更新系统包
sudo dnf update -y

# 安装Nginx
sudo dnf install -y nginx

# 启动Nginx服务
sudo systemctl start nginx

# 设置Nginx开机自启
sudo systemctl enable nginx

# 检查Nginx状态
sudo systemctl status nginx
```

### 3.2 配置防火墙（Linux）

如果你的系统启用了防火墙，需要允许HTTP和HTTPS流量：

#### Ubuntu/Debian系统

```bash
# 允许HTTP (80端口)和HTTPS (443端口)
sudo ufw allow 'Nginx Full'

# 验证防火墙规则
sudo ufw status
```

#### Rocky Linux/CentOS系统

```bash
# 允许HTTP和HTTPS流量
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 验证防火墙规则
sudo firewall-cmd --list-all
```

### 3.3 配置Nginx虚拟主机

创建Nginx配置文件来托管Hexo博客：

```bash
# 创建配置文件
sudo nano /etc/nginx/sites-available/hexo-blog
```

添加以下配置内容：

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;  # 替换为你的域名
    
    root /var/www/hexo-blog;  # Hexo静态文件的部署目录
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # 启用gzip压缩提升性能
    gzip on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 添加安全相关的HTTP头
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-XSS-Protection "1; mode=block";
}
```

创建符号链接并启用配置：

```bash
# 创建符号链接到sites-enabled目录
sudo ln -s /etc/nginx/sites-available/hexo-blog /etc/nginx/sites-enabled/

# 移除默认配置（可选）
sudo rm /etc/nginx/sites-enabled/default

# 测试Nginx配置是否正确
sudo nginx -t

# 重新加载Nginx服务
sudo systemctl reload nginx
```

## 4. 部署Hexo博客到Nginx

### 4.1 配置Hexo部署设置

编辑Hexo的配置文件，设置部署选项：

```bash
nano ~/hexo-blog/_config.yml
```

在文件末尾添加或修改部署配置：

```yaml
deploy:
  type: 'rsync'
  host: localhost  # 本地部署，如果你要部署到远程服务器，则填写远程服务器地址
  user: root       # 部署用户
  root: /var/www/hexo-blog  # Nginx的网站目录
  port: 22         # SSH端口
  delete: true     # 部署前删除旧文件
  verbose: true    # 显示详细信息
  ignore_errors: false
```

### 4.2 创建部署目录并设置权限

```bash
# 创建部署目录
sudo mkdir -p /var/www/hexo-blog

# 设置权限，允许你的用户访问该目录
sudo chown -R $USER:$USER /var/www/hexo-blog
sudo chmod -R 755 /var/www
```

### 4.3 安装部署插件

```bash
# 安装rsync部署插件
cd ~/hexo-blog
npm install hexo-deployer-rsync --save
```

### 4.4 生成并部署Hexo博客

```bash
# 清理缓存
hexo clean

# 生成静态文件
hexo generate

# 部署到Nginx
hexo deploy
```

### 4.5 手动部署（可选）

如果不想使用Hexo的部署功能，也可以手动将生成的静态文件复制到Nginx目录：

```bash
# 生成静态文件
cd ~/hexo-blog
hexo clean
hexo generate

# 复制文件到Nginx目录
sudo cp -r public/* /var/www/hexo-blog/
```

## 5. 自定义Hexo博客

### 5.1 更换主题

Hexo有丰富的主题生态，你可以选择一个喜欢的主题来美化你的博客：

```bash
# 进入主题目录
cd ~/hexo-blog/themes

# 克隆Next主题（一个流行的主题）
git clone https://github.com/next-theme/hexo-theme-next.git next
```

然后编辑Hexo配置文件，将主题设置为新安装的主题：

```bash
nano ~/hexo-blog/_config.yml
```

修改主题设置：

```yaml
theme: next  # 更改为新安装的主题名称
```

### 5.2 安装常用插件

```bash
# 安装代码高亮插件
npm install hexo-prism-plugin --save

# 安装站点地图插件
npm install hexo-generator-sitemap --save
npm install hexo-generator-baidu-sitemap --save

# 安装RSS插件
npm install hexo-generator-feed --save
```

## 6. 自动化部署（高级）

### 6.1 使用Git实现自动化部署

1. 在服务器上创建Git仓库：

```bash
# 创建Git仓库目录
sudo mkdir -p /var/repo/hexo-blog.git
cd /var/repo/hexo-blog.git

# 初始化裸仓库
sudo git init --bare

# 创建钩子脚本
sudo nano hooks/post-receive
```

添加以下内容到钩子脚本：

```bash
#!/bin/bash
GIT_REPO=/var/repo/hexo-blog.git
TMP_GIT_CLONE=/tmp/hexo-blog
PUBLIC_WWW=/var/www/hexo-blog

sudo rm -rf $TMP_GIT_CLONE
sudo mkdir -p $TMP_GIT_CLONE
sudo git clone $GIT_REPO $TMP_GIT_CLONE

cd $TMP_GIT_CLONE
sudo hexo clean
sudo hexo generate
sudo rm -rf $PUBLIC_WWW/*
sudo cp -r public/* $PUBLIC_WWW

sudo rm -rf $TMP_GIT_CLONE
exit 0
```

设置脚本权限：

```bash
sudo chmod +x hooks/post-receive
```

2. 在本地配置Git部署：

编辑`_config.yml`文件：

```yaml
deploy:
  type: git
  repo: user@your-server:/var/repo/hexo-blog.git
  branch: master
```

安装Git部署插件：

```bash
npm install hexo-deployer-git --save
```

现在可以使用`hexo deploy`命令将更改推送到服务器，服务器会自动构建和部署博客。

## 7. 故障排除

### 7.1 常见问题与解决方案

1. **Nginx无法访问网站**
   - 检查Nginx服务是否运行：`sudo systemctl status nginx`
   - 检查配置是否正确：`sudo nginx -t`
   - 检查防火墙设置
   - 确保网站目录有正确的权限

2. **Hexo生成失败**
   - 检查Node.js和npm版本是否兼容
   - 尝试重新安装依赖：`rm -rf node_modules && npm install`
   - 查看详细错误信息，通常是主题或插件不兼容导致

3. **部署后页面不显示最新内容**
   - 确保使用了`hexo clean`清理缓存
   - 检查Nginx是否有缓存，尝试重启Nginx
   - 确认文件权限正确

4. **访问页面出现404错误**
   - 检查Nginx配置中的root路径是否正确
   - 确保Hexo生成的文件已正确复制到Nginx目录
   - 检查URL路径是否正确

## 8. 最佳实践

1. **定期备份**
   - 备份Hexo源文件和配置
   - 备份Nginx配置文件

2. **安全性**
   - 定期更新Node.js、npm和Hexo
   - 保持Nginx更新到最新版本
   - 使用HTTPS保护网站
   - 限制SSH访问和使用密钥认证

3. **性能优化**
   - 启用Nginx缓存
   - 使用CDN加速静态资源
   - 优化图片大小
   - 启用Gzip压缩

4. **SEO优化**
   - 配置站点地图
   - 设置适当的meta标签
   - 使用语义化的Markdown
   - 为文章设置适当的分类和标签

## 9. 总结

通过本指南，我们已经完成了以下任务：

1. 安装了Node.js运行环境
2. 安装并配置了Hexo博客框架
3. 安装并配置了Nginx服务器
4. 部署了Hexo博客到Nginx
5. 学习了如何自定义博客和故障排除

现在，你已经拥有了一个功能完善的Hexo博客站点，可以开始撰写和发布你的博客文章了！随着你的博客成长，你可以继续学习和探索更多高级功能，如添加评论系统、访问统计、社交分享等功能。