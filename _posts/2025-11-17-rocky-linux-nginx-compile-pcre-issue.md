---
layout: post
title: "Rocky Linux 9.6与Ubuntu 24手动编译安装Nginx详细指南"
date: 2025-11-17 14:00:00
categories: linux
tags: [rocky-linux, ubuntu, nginx, 编译安装, 依赖管理]
---

# Rocky Linux 9.6与Ubuntu 24手动编译安装Nginx详细指南

## 情境与问题

### 为什么需要手动编译Nginx？
在生产环境中，我们经常需要手动编译Nginx以获得以下优势：
- 定制化模块支持（如特定版本的SSL、自定义模块）
- 性能优化（针对特定硬件和业务场景）
- 版本控制（使用特定稳定版本）
- 更灵活的安装路径和配置

### Rocky Linux 9.6环境下的问题
在Rocky Linux 9.6系统上手动编译Nginx 1.23.0时，执行以下命令：

```bash
./configure --prefix=/lnmp/nginx --with-http_ssl_module
```

遇到了如下错误：

```bash
./configure: error: the HTTP rewrite module requires the PCRE library.
You can either disable the module by using --without-http_rewrite_module
option, or install the PCRE library into the system, or build the PCRE library
statically from the source with nginx by using --with-pcre=<path> option.
```

尝试安装PCRE库：

```bash
yum install -y pcre
```

但系统提示：

```bash
软件包 pcre-8.44-4.el9.x86_64 已安装。
依赖关系解决。
无需任何处理。
```

明明已经安装了PCRE库，为什么编译Nginx时仍然提示找不到呢？

### Ubuntu 24环境下的类似问题
在Ubuntu 24系统中编译Nginx时，也会遇到类似的依赖问题。尽管系统可能已安装某些库，但缺少开发包仍然会导致编译失败。

## 问题分析

这个问题的核心在于：**Nginx编译时需要的是PCRE库的开发文件，而不仅仅是运行时库**。

在Linux系统中，软件包通常分为两种类型：
1. **运行时包**：包含程序运行所需的二进制文件，通常命名为`package-name`
2. **开发包**：包含编译时所需的头文件、静态库等，在RHEL系（如Rocky Linux）中命名为`package-name-devel`，在Debian系（如Ubuntu）中命名为`package-name-dev`

在这个案例中，虽然安装了`pcre`包（运行时库），但缺少对应的开发包（`pcre-devel`或`libpcre3-dev`），导致Nginx编译时无法找到必要的头文件和库文件。

## 解决方案

### 一、Rocky Linux 9.6编译安装Nginx

#### 1. 安装开发工具链

首先需要安装基础的开发工具：

```bash
yum groupinstall -y "Development Tools"
yum install -y wget
```

#### 2. 安装必要的依赖包

编译Nginx需要以下依赖：

```bash
yum install -y pcre-devel openssl-devel zlib-devel
```

这些依赖包的作用：
- `pcre-devel`：支持Nginx的rewrite模块
- `openssl-devel`：支持Nginx的SSL/TLS功能
- `zlib-devel`：支持Nginx的数据压缩功能

#### 3. 下载Nginx源码

```bash
mkdir -p /root/softs
cd /root/softs
wget http://nginx.org/download/nginx-1.23.0.tar.gz
tar xf nginx-1.23.0.tar.gz
cd nginx-1.23.0/
```

#### 4. 配置编译选项

```bash
./configure --prefix=/lnmp/nginx --with-http_ssl_module
```

#### 5. 编译与安装

```bash
make
make install
```

#### 6. 验证安装

```bash
/lnmp/nginx/sbin/nginx -V
```

输出应该包含以下内容：
```
nginx version: nginx/1.23.0
built with OpenSSL ...
configure arguments: --prefix=/lnmp/nginx --with-http_ssl_module
```

#### 7. 启动Nginx

```bash
/lnmp/nginx/sbin/nginx
```

验证Nginx是否正常运行：

```bash
curl http://localhost
```

#### 8. 设置环境变量和man文档

```bash
echo "export PATH=/lnmp/nginx/sbin:$PATH" >> /etc/bashrc
source /etc/bashrc
cp man/nginx.8 /usr/share/man/man8
```

### 二、Ubuntu 24编译安装Nginx

#### 1. 安装开发工具链

首先更新包列表并安装基础开发工具：

```bash
apt update
apt install -y build-essential wget
```

#### 2. 安装必要的依赖包

在Ubuntu系统中，依赖包的命名与Rocky Linux略有不同：

```bash
apt install -y libpcre3-dev libssl-dev zlib1g-dev
```

这些依赖包的作用与Rocky Linux中的对应包相同。

#### 3. 下载Nginx源码（方式一：直接下载）

```bash
mkdir -p /root/softs
cd /root/softs
wget http://nginx.org/download/nginx-1.24.0.tar.gz
tar xf nginx-1.24.0.tar.gz
cd nginx-1.24.0/
```

#### 4. 下载Nginx源码（方式二：通过apt source获取）

Ubuntu也支持通过`apt source`命令获取官方打包的Nginx源码：

```bash
mkdir -p /root/nginx
cd /root/nginx
apt source nginx
```

这将下载当前Ubuntu版本中打包的Nginx源码及其补丁。

#### 5. 配置编译选项

```bash
./configure --prefix=/data/server/nginx --with-http_ssl_module
```

#### 6. 编译与安装

```bash
make
make install
```

#### 7. 验证安装

```bash
/data/server/nginx/sbin/nginx -V
```

输出示例：
```
nginx version: nginx/1.24.0 (Ubuntu)
built by gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04)
built with OpenSSL 3.0.13 30 Jan 2024
TLS SNI support enabled
configure arguments: --prefix=/data/server/nginx --with-http_ssl_module
```

#### 8. 启动Nginx

```bash
/data/server/nginx/sbin/nginx
```

#### 9. 安装curl并验证Nginx运行状态

```bash
apt install curl -y
curl http://localhost/
```

输出示例：
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

#### 10. 设置环境变量和man文档

```bash
echo "export PATH=/data/server/nginx/sbin:$PATH" >> /etc/bashrc
source /etc/bashrc
cp man/nginx.8 /usr/share/man/man8/
```

现在可以直接使用`nginx`命令并查看man文档：
```bash
man nginx
```

### 三、可选方案：使用源码编译PCRE

如果系统提供的PCRE版本不符合要求，或者需要特定版本的PCRE，可以选择从源码编译：

#### 1. 下载PCRE源码

```bash
wget https://ftp.pcre.org/pub/pcre/pcre-8.45.tar.gz
```

#### 2. 编译安装PCRE

```bash
tar -zxvf pcre-8.45.tar.gz
cd pcre-8.45
./configure
make
make install
```

#### 3. 使用源码PCRE编译Nginx

```bash
cd nginx-1.23.0
./configure --prefix=/lnmp/nginx --with-http_ssl_module --with-pcre=/path/to/pcre-8.45
make
make install
```

## 验证安装

安装完成后，可以验证Nginx是否正确编译并包含了所需的模块：

对于Rocky Linux：
```bash
/lnmp/nginx/sbin/nginx -V
```

对于Ubuntu：
```bash
/data/server/nginx/sbin/nginx -V
```

输出示例（Rocky Linux）：
```
nginx version: nginx/1.23.0
built with OpenSSL 3.2.2 4 Jun 2024
TLS SNI support enabled
configure arguments: --prefix=/lnmp/nginx --with-http_ssl_module
```

输出示例（Ubuntu 24）：
```
nginx version: nginx/1.24.0 (Ubuntu)
built by gcc 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04)
built with OpenSSL 3.0.13 30 Jan 2024
TLS SNI support enabled
configure arguments: --prefix=/data/server/nginx --with-http_ssl_module
```

## 总结与最佳实践

### 核心要点总结

1. **区分运行时包和开发包**：
   - RHEL系（Rocky Linux）：开发包以`-devel`结尾
   - Debian系（Ubuntu）：开发包以`-dev`结尾
   - 编译软件时必须安装对应的开发包

2. **依赖管理最佳实践**：
   - **优先使用系统包管理器**：避免手动编译带来的版本兼容性问题
   - **安装完整的依赖链**：除了主要依赖，还要安装相关的依赖包
   - **查看编译日志**：仔细阅读错误信息，定位具体的依赖缺失

3. **编译安装流程**：
   - 安装开发工具链
   - 安装必要的依赖包
   - 下载并解压源码
   - 配置编译选项
   - 编译与安装
   - 验证安装
   - 设置环境变量

### FAB分析：手动编译Nginx的优势

| 特点(Features) | 优势(Advantages) | 利益(Benefits) |
|---------------|-----------------|---------------|
| 定制化模块支持 | 可以选择需要的模块，移除不需要的模块 | 减少内存占用，提高性能 |
| 性能优化 | 针对特定硬件和业务场景进行编译优化 | 提升Nginx处理能力和响应速度 |
| 版本控制 | 可以使用特定的稳定版本或最新版本 | 确保系统稳定性或获取最新特性 |
| 灵活的安装路径 | 可以自定义安装位置 | 便于系统管理和权限控制 |
| 源码级别的修改 | 可以修改源码以满足特殊需求 | 实现独特的业务功能 |

### 故障排除建议

1. **依赖问题**：
   - 错误信息：`./configure: error: the HTTP rewrite module requires the PCRE library`
   - 解决方案：安装对应的开发包（`pcre-devel`或`libpcre3-dev`）

2. **编译错误**：
   - 错误信息：`make: *** [Makefile:1096: objs/src/core/ngx_murmurhash.o] Error 1`
   - 解决方案：检查是否缺少依赖包，或源码是否完整

3. **启动失败**：
   - 错误信息：`nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)`
   - 解决方案：检查端口是否被占用，使用`ss -lntup`命令查看

通过本文的详细指南，您应该能够在Rocky Linux 9.6和Ubuntu 24系统上成功编译安装Nginx。在实际工作中，建议根据具体需求调整编译选项，以获得最佳的性能和功能。