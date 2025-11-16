---
layout: post
title: "Linux包管理完全指南：从yum到dnf的演进与应用"
date: 2025-11-13 10:00:00 +0800
categories: [Linux, 系统管理]
tags: [Linux, 包管理, yum, dnf, rpm]
---

# Linux包管理完全指南：从yum到dnf的演进与应用

在Linux系统管理和开发工作中，包管理是一项基础但至关重要的技能。无论是安装软件、更新系统、解决依赖关系，还是管理软件仓库，掌握高效的包管理工具都能大幅提升工作效率。本文将全面介绍RHEL系Linux发行版中两款最重要的包管理工具——yum和dnf，从基础概念到高级应用，帮助您精通Linux包管理操作。

## 1. 包管理的基础概念

### 1.1 什么是包管理

**包管理（Package Management）**是指在Linux系统中对软件包进行安装、更新、卸载、查询等操作的过程。一个完整的包管理系统通常包括：

- **包格式**：软件的打包格式（如RPM、DEB）
- **包管理器**：执行包操作的工具（如yum、dnf、apt）
- **软件仓库**：存储和分发软件包的服务器
- **依赖解析**：自动处理软件间的依赖关系

### 1.2 RPM包格式

Red Hat系列Linux发行版（如RHEL、CentOS、Fedora）使用RPM（Red Hat Package Manager）作为基本包格式。RPM包包含：

- 软件的二进制文件、配置文件和文档
- 软件的版本信息和依赖关系
- 安装和卸载脚本

RPM包的文件名通常遵循以下格式：
```
package-name-version-release.architecture.rpm
```

例如：`nginx-1.24.0-1.el9.x86_64.rpm`

### 1.3 yum与dnf的C/S架构模式

yum和dnf都采用**客户端/服务器（C/S）架构模式**，其工作原理如下：

- **服务器端（Repository）**：
  - 存放RPM包和相关的元数据库
  - 创建yum repository（仓库）时，会在仓库中存储众多RPM包
  - 元数据文件存储在特定目录`repodata`下，包含包的版本、依赖关系等信息

- **客户端（yum/dnf工具）**：
  - 访问yum服务器进行安装、查询等操作
  - 自动下载`repodata`中的元数据
  - 查询元数据以确定是否存在相关包及依赖关系
  - 自动从仓库中找到相关包下载并安装

### 1.4 yum与dnf的历史演进

- **yum**（Yellowdog Updater, Modified）：
  - 2003年发布，基于Python 2开发
  - 作为rpm的前端工具，提供自动依赖解析
  - 广泛应用于RHEL 5-7、CentOS 5-7

- **dnf**（Dandified Yum）：
  - 2015年首次发布，基于Python 3开发
  - 作为yum的下一代替代品，解决了yum的性能问题
  - 自RHEL 8/CentOS 8起成为默认包管理器

## 2. yum命令基础

### 2.1 yum命令语法

```bash
yum [选项] [命令] [包名/组名]
```

### 2.2 yum常用命令

#### 软件包查询

```bash
# 查询可用的软件包
yum list available

# 查询已安装的软件包
yum list installed

# 查询所有软件包（已安装和可用）
yum list all

# 查询特定软件包
yum list nginx

# 查询软件包信息
yum info nginx

# 搜索包含特定关键字的软件包
yum search python3

# 查找哪个软件包提供了特定文件
yum provides /usr/bin/python3
```

#### 软件包安装

```bash
# 安装指定软件包
yum install nginx

# 安装多个软件包
yum install nginx mysql-server php

# 安装本地RPM包（并解决依赖）
yum localinstall package.rpm

# 重新安装软件包
yum reinstall nginx
```

#### 软件包更新

```bash
# 检查可用更新
yum check-update

# 更新所有软件包
yum update

# 更新特定软件包
yum update nginx

# 升级系统到新版本
yum upgrade
```

#### 软件包卸载

```bash
# 卸载软件包
yum remove nginx

# 卸载软件包但保留配置文件
yum erase nginx
```

### 2.3 yum仓库管理

```bash
# 列出所有启用的仓库
yum repolist enabled

# 列出所有仓库（包括禁用的）
yum repolist all

# 启用仓库
yum-config-manager --enable repo-name

# 禁用仓库
yum-config-manager --disable repo-name

# 安装EPEL扩展仓库
yum install epel-release
```

### 2.4 yum配置与仓库管理实践

#### yum主配置文件

在现代RHEL 9系统中，`yum`命令实际上是`dnf`的符号链接，因此`yum`的主配置文件`/etc/yum.conf`也是`/etc/dnf/dnf.conf`的符号链接：

```bash
ll /etc/yum.conf
```

实际输出示例：

```
lrwxrwxrwx. 1 root root 12  5月  4  2025 /etc/yum.conf -> dnf/dnf.conf
```

查看配置文件内容：

```bash
cat /etc/yum.conf
```

实际输出示例（带注释说明）：

```
[main]
gpgcheck=1
#安装包前要做包的合法和完整性校验
installonly_limit=3
#同时可以安装3个包，最小值为2，如设为0或1，为不限制
clean_requirements_on_remove=True
#删除包时，是否将不再使用的包删除
best=True
#升级时，自动选择安装最新版，即使缺少包的依赖
skip_if_unavailable=False
#跳过不可用的

[repositoryID]
name=Some name for this repository
#仓库名称
baseurl=url://path/to/repository/
#仓库地址，支持多种协议格式：
# 本地光盘：baseurl=file:///cdrom/AppStream/
# HTTPS镜像：baseurl=https://mirrors.aliyun.com/rockylinux/9.4/AppStream/x86_64/os/
# HTTP镜像：baseurl=http://mirrors.aliyun.com/rockylinux/9.4/AppStream/x86_64/os/
# FTP服务器：baseurl=ftp://10.0.0.159/
# 注意：baseurl指向的路径必须是repodata目录所在的目录
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever
#仓库地址列表，支持使用变量动态生成镜像列表
#常用变量说明：
#  $arch - CPU架构：aarch64|i586|i686|x86_64
#  $basearch - 系统基本体系结构：i386|x86_64
#  $releasever - 系统版本号
#
#带变量的mirrorlist会自动替换为实际值，例如：
#  原始：mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever
#  替换后：mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=x86_64&repo=BaseOS-9
#
#mirrorlist返回的是所有可用镜像地址的列表，
#系统会自动选择最新且距离最近的可用镜像地址
enabled={1|0}
#是否启用,默认值为1，启用
gpgcheck={1|0}
#是否对包进行校验，默认值为1
gpgkey={URL|file://FILENAME}
#校验key的地址
enablegroups={1|0}
#是否启用yum group,默认值为 1
failovermethod={roundrobin|priority}
#有多个baseurl，此项决定访问规则，
#roundrobin 随机，priority:按顺序访问
cost=1000
#开销，或者是成本，
#YUM程序会根据此值来决定优先访问哪个源,默认为1000
metadata_expire=6h
#rocky-9中新增配置，metadata 过期时间
countme=1
#rocky-9中新增配置，默认值false，
#附加在mirrorlist之后，便于仓库收集客户端信息
```

#### 仓库配置文件

每个软件仓库都有独立的配置文件，存放在`/etc/yum.repos.d/`目录下：

```bash
ll /etc/yum.repos.d/
```

实际输出示例：

```
总用量 20
-rw-r--r--. 1 root root 6610  5月 17 11:07 rocky-addons.repo
-rw-r--r--. 1 root root 1165  5月 17 11:07 rocky-devel.repo
-rw-r--r--. 1 root root 2387  5月 17 11:07 rocky-extras.repo
-rw-r--r--. 1 root root 3417  5月 17 11:07 rocky.repo
```

#### Rocky Linux国内镜像源

为了提高软件包下载速度，用户可以配置国内的镜像源。以下是几个常用的Rocky Linux国内镜像源：

| 来源机构 | 地址 |
| --- | --- |
| 阿里云 | `https://mirrors.aliyun.com/rockylinux/` |
| 中国科学技术大学 | `http://mirrors.ustc.edu.cn/rocky/` |
| 南京大学 | `https://mirrors.nju.edu.cn/rocky/` |
| 上海交通大学 | `https://mirrors.sjtug.sjtu.edu.cn/rocky/` |
| 东软信息学院 | `http://mirrors.neusoft.edu.cn/rocky/` |

#### 实际配置示例：阿里云镜像源

以下是使用阿里云镜像源的完整配置示例：

1. 创建阿里云BaseOS仓库配置文件：

```bash
sudo vim /etc/yum.repos.d/aliyun-baseos.repo
```

2. 添加以下配置内容：

```ini
[aliyun-baseos]
name=aliyun.baseos
baseurl=https://mirrors.aliyun.com/rockylinux/9.6/BaseOS/x86_64/os/
gpgcheck=0
```

3. 生成元数据缓存：

```bash
yum makecache
```

实际输出示例：

```
aliyun.baseos                                                                                                                         5.0 MB/s | 2.5 MB     00:00
Rocky Linux 9 - BaseOS                                                                                                                2.2 kB/s | 4.1 kB     00:01
Rocky Linux 9 - AppStream                                                                                                             1.8 kB/s | 4.5 kB     00:02
Rocky Linux 9 - Extras                                                                                                                1.9 kB/s | 2.9 kB     00:01
元数据缓存已建立。
```

4. 验证仓库配置：

```bash
yum repolist
```

实际输出示例：

```
仓库 id                                                                      仓库名称
aliyun-baseos                                                                aliyun.baseos
appstream                                                                    Rocky Linux 9 - AppStream
baseos                                                                       Rocky Linux 9 - BaseOS
```

5. 查看详细仓库信息：

```bash
yum repolist -v --repoid=aliyun-baseos
```

实际输出示例：

```
加载插件：builddep, changelog, config-manager, copr, debug, debuginfo-install, download, generate_completion_cache, groups-manager, kpatch, needs-restarting, notify-packagekit, playground, repoclosure, repodiff, repograph, repomanage, reposync, system-upgrade
YUM version: 4.14.0
cachedir: /var/tmp/dnf-soveran-akvddr2r
上次元数据过期检查：0:01:00 前，执行于 2025年11月13日 星期四 22时22分53秒。
仓库ID            : aliyun-baseos
仓库名称          : aliyun.baseos
软件仓库修订版      : 1762376584
更新的软件仓库       : 2025年11月06日 星期四 05时03分04秒
软件仓库的软件包          : 1,171
软件仓库的可用软件包: 1,171
软件仓库大小          : 1.5 G
软件仓库基本 URL       : https://mirrors.aliyun.com/rockylinux/9.6/BaseOS/x86_64/os/ 
软件仓库过期时间        : 172,800 秒 （最近 2025年11月13日 星期四 22时22分53秒）
仓库文件名      : /etc/yum.repos.d/aliyun-baseos.repo
软件包总数：1,171
```

#### 实际配置示例：南京大学镜像源

以下是使用南京大学镜像源的完整配置示例，包含AppStream、BaseOS和extras三个仓库：

1. 创建南京大学镜像源配置文件：

```bash
sudo vim /etc/yum.repos.d/nju-extras.repo
```

2. 添加以下配置内容：

```ini
[nju-appstream]
name=nju AppStream
baseurl=https://mirrors.nju.edu.cn/rocky/9.6/AppStream/x86_64/os/
gpgcheck=0

[nju-baseos]
name=nju BaseOS
baseurl=https://mirrors.nju.edu.cn/rocky/9.6/BaseOS/x86_64/os/
gpgcheck=0

[nju-extras]
name=nju extras
baseurl=https://mirrors.nju.edu.cn/rocky/9.6/extras/x86_64/os/
gpgcheck=0
```

3. 生成元数据缓存：

```bash
yum makecache
```

实际输出示例：

```
aliyun.baseos                                                                                                                          22 kB/s | 4.1 kB     00:00
nju AppStream                                                                                                                          23 MB/s | 9.5 MB     00:00
nju BaseOS                                                                                                                            7.6 MB/s | 2.5 MB     00:00
nju extras                                                                                                                             85 kB/s |  17 kB     00:00
Rocky Linux 9 - BaseOS                                                                                                                1.7 kB/s | 4.1 kB     00:02
Rocky Linux 9 - AppStream                                                                                                             4.1 kB/s | 4.5 kB     00:01
Rocky Linux 9 - Extras                                                                                                                3.1 kB/s | 2.9 kB     00:00
元数据缓存已建立。
```

#### 实际配置示例：本地光盘源

在没有网络连接或需要使用特定版本软件时，可以使用本地光盘作为软件源。以下是在Rocky Linux 9中配置本地光盘源的完整示例：

1. **挂载光盘到/mnt目录**
   ```bash
   mount /dev/cdrom /mnt/
   ```
   实际输出示例：
   ```
mount: /mnt: WARNING: source write-protected, mounted read-only.
   ```

2. **验证光盘内容**
   ```bash
   df -h
   ```
   实际输出示例：
   ```
   文件系统             容量  已用  可用 已用% 挂载点
   devtmpfs             4.0M     0  4.0M    0% /dev
   tmpfs                1.8G     0  1.8G    0% /dev/shm
   tmpfs                725M   16M  710M    3% /run
   /dev/mapper/rl-root   70G  6.9G   64G   10% /
   /dev/sda1            960M  562M  399M   59% /boot
   /dev/mapper/rl-home  126G  1.1G  124G    1% /home
   tmpfs                363M   52K  363M    1% /run/user/42
   tmpfs                363M   36K  363M    1% /run/user/1000
   /dev/sr0              12G   12G     0  100% /mnt
   ```

   ```bash
   ls /mnt/
   ```
   实际输出示例：
   ```
   AppStream  BaseOS  EFI  images  isolinux  LICENSE  media.repo
   ```

3. **创建本地光盘源配置文件**
   ```bash
   sudo vim /etc/yum.repos.d/cdrom.repo
   ```

4. **添加以下配置内容**
   ```ini
   [cdrom-appstream]
   name=cdrom appstream
   baseurl=file:///mnt/AppStream/
   gpgcheck=0

   [cdrom-baseos]
   name=cdrom baseos
   baseurl=file:///mnt/BaseOS/
   gpgcheck=0
   ```

5. **生成元数据缓存**
   ```bash
   yum makecache
   ```

6. **验证光盘源配置**
   ```bash
   yum repolist
   ```

**BaseOS和AppStream目录说明：**
- **BaseOS目录**
  - **内容**：存储着操作系统的核心组件和基本系统工具，如内核、shell工具、系统服务等。
  - **功能**：提供操作系统的基本功能和支持，确保系统的正常运行。

- **AppStream目录**
  - **内容**：存储着用户可能需要的应用程序和软件包的元数据信息，以及软件包依赖关系等。
  - **功能**：使用户可以方便地安装和管理这些软件，通常包含用户界面软件、开发工具、数据库工具等应用程序。

- **关联关系**：
  - BaseOS和AppStream两个目录之间的关系是互补的。
  - 在安装和管理软件时，系统会从这两个目录中获取所需的软件包和依赖关系，以确保系统的完整性和稳定性。

使用`yum makecache`命令可以预先生成软件仓库的元数据缓存，提高后续操作的速度。这在配置新仓库后特别有用，可以立即验证仓库的可用性。

#### 详细查看仓库信息

使用`yum repolist -v`命令可以查看详细的仓库信息，包括仓库ID、名称、大小、镜像地址等。如果需要查看特定仓库的详细信息，可以使用`yum repolist -v --repoid=仓库ID`命令。

通过这些命令，用户可以全面了解当前系统中配置的所有仓库，以及每个仓库的具体状态和配置详情。

#### 使用yum-config-manager管理仓库

yum-config-manager是一个用于管理yum仓库的命令行工具，它可以方便地添加、启用、禁用和修改仓库配置。以下是使用yum-config-manager的实际操作示例：

1. **安装yum-utils包（包含yum-config-manager工具）**
   ```bash
   sudo yum install yum-utils
   ```

2. **验证yum-config-manager工具安装**
   ```bash
   rpm -qf `which yum-config-manager`
   ```
   实际输出示例：
   ```
   yum-utils-4.3.0-20.el9.noarch
   ```

3. **添加仓库**
   ```bash
   sudo yum-config-manager --add-repo=https://mirrors.nju.edu.cn/epel/9/Everything/x86_64
   ```
   实际输出示例：
   ```
   添加仓库自： https://mirrors.nju.edu.cn/epel/9/Everything/x86_64
   ```

4. **查看创建的仓库配置文件**
   ```bash
   cat /etc/yum.repos.d/mirrors.nju.edu.cn_epel_9_Everything_x86_64.repo
   ```
   实际输出示例：
   ```
   [mirrors.nju.edu.cn_epel_9_Everything_x86_64]
   name=created by dnf config-manager from https://mirrors.nju.edu.cn/epel/9/Everything/x86_64
   baseurl=https://mirrors.nju.edu.cn/epel/9/Everything/x86_64
   enabled=1
   ```

5. **禁用仓库**
   ```bash
   sudo yum-config-manager --disable mirrors.nju.edu.cn_epel_9_Everything_x86_64
   ```

6. **启用仓库**
   ```bash
   sudo yum-config-manager --enable mirrors.nju.edu.cn_epel_9_Everything_x86_64
   ```

使用yum-config-manager工具可以快速方便地管理仓库，避免手动编辑配置文件的繁琐和可能的错误。

## 3. dnf命令基础

### 3.1 dnf命令语法

```bash
dnf [选项] [命令] [包名/组名]
```

### 3.2 dnf常用命令

#### 软件包查询

```bash
# 查询可用的软件包
dnf list available

# 查询已安装的软件包
dnf list installed

# 查询所有软件包（已安装和可用）
dnf list all

# 查询特定软件包
dnf list nginx

# 查询软件包信息
dnf info nginx

# 查询已安装软件包的详细信息
dnf info --installed sos

实际输出示例：
```bash
已安装的软件包

 名称         : sos
 版本         : 4.10.0
 发布         : 4.el9_6
 架构         : noarch
 大小         : 3.3 M
 源           : sos-4.10.0-4.el9_6.src.rpm
 仓库         : @System
 来自仓库     : baseos
 概况         : A set of tools to gather troubleshooting information from a system
 URL          : `https://github.com/sosreport/sos` 
 协议         : GPL-2.0-or-later
 描述         : Sos is a set of tools that gathers information about system
              : hardware and configuration. The information can then be used for
              : diagnostic purposes and debugging. Sos is commonly used to help
              : support technicians and developers.
```

# 使用rpm查询软件包详细信息
rpm -qi sos

实际输出示例：
```bash
Name        : sos
Version     : 4.10.0
Release     : 4.el9_6
Architecture: noarch
Install Date: 2025年10月31日 星期五 22时29分08秒
Group       : Applications/System
Size        : 3468129
License     : GPL-2.0-or-later
Signature   : RSA/SHA256, 2025年10月06日 星期一 23时22分28秒, Key ID 702d426d350d275d
Source RPM  : sos-4.10.0-4.el9_6.src.rpm
Build Date  : 2025年10月06日 星期一 23时22分15秒
Build Host  : pb-2da088e8-e0a2-47e5-9218-08f149dcb385-b-noarch
Packager    : Rocky Linux Build System (Peridot) <releng@rockylinux.org>
Vendor      : Rocky Enterprise Software Foundation
URL         : `https://github.com/sosreport/sos` 
Summary     : A set of tools to gather troubleshooting information from a system
Description :
Sos is a set of tools that gathers information about system
hardware and configuration. The information can then be used for
diagnostic purposes and debugging. Sos is commonly used to help
support technicians and developers.
```

# 搜索包含特定关键字的软件包
dnf search python3

# 查找哪个软件包提供了特定文件
dnf provides /usr/bin/python3

# 查找提供sos命令的软件包
dnf provides /usr/sbin/sos

实际输出示例：
```bash
上次元数据过期检查：0:32:59 前，执行于 2025年11月15日 星期六 21时00分58秒。
sos-4.8.2-2.el9_5.noarch : A set of tools to gather troubleshooting information from a system
仓库        ：cdrom-baseos
匹配来源：
文件名    ：/usr/sbin/sos

sos-4.10.0-4.el9_6.noarch : A set of tools to gather troubleshooting information from a system
仓库        ：@System
匹配来源：
文件名    ：/usr/sbin/sos

sos-4.10.0-4.el9_6.noarch : A set of tools to gather troubleshooting information from a system
仓库        ：aliyun-baseos
匹配来源：
文件名    ：/usr/sbin/sos

sos-4.10.0-4.el9_6.noarch : A set of tools to gather troubleshooting information from a system
仓库        ：nju-baseos
匹配来源：
文件名    ：/usr/sbin/sos

sos-4.10.0-4.el9_6.noarch : A set of tools to gather troubleshooting information from a system
仓库        ：baseos
匹配来源：
文件名    ：/usr/sbin/sos
```

# 在特定仓库中查找提供nginx命令的软件包
dnf provides /usr/sbin/nginx --repoid=cdrom-appstream

实际输出示例：
```bash
上次元数据过期检查：0:35:23 前，执行于 2025年11月15日 星期六 21时00分02秒。
nginx-core-2:1.20.1-22.el9_6.2.x86_64 : nginx minimal core
仓库        ：cdrom-appstream
匹配来源：
文件名    ：/usr/sbin/nginx

nginx-core-2:1.20.1-22.el9_6.3.x86_64 : nginx minimal core
仓库        ：@System
匹配来源：
文件名    ：/usr/sbin/nginx
```

# 查找命令的位置和相关文件
whereis sos

实际输出示例：
```bash
sos: /usr/sbin/sos /etc/sos /usr/share/man/man1/sos.1.gz
```

# 查看命令的简短描述
whatis sos

实际输出示例：
```bash
sos (1)              - A unified tool for collecting system logs and other debug information
```

# 查看sos命令的帮助信息

```bash
sos
usage: sos <component> [options]


Available components:
        report, rep                   Collect files and command output in an archive
        clean, cleaner, mask          Obfuscate sensitive networking information in a report
        help                          Detailed help infomation
        upload                        Upload a file to a user or policy defined remote location
        collect, collector            Collect an sos report from multiple nodes simultaneously
sos: error: the following arguments are required: component
```

# 查看软件包的依赖关系
# `deplist`命令用于显示指定软件包的所有依赖关系以及提供这些依赖的软件包

```bash
yum deplist nginx
```

实际输出示例：
```bash
上次元数据过期检查：0:38:33 前，执行于 2025年11月15日 星期六 21时00分58秒。
package: nginx-2:1.20.1-22.el9_6.2.x86_64
  dependency: /bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: /usr/bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: nginx-core = 2:1.20.1-22.el9_6.2
   provider: nginx-core-2:1.20.1-22.el9_6.2.x86_64
  dependency: nginx-filesystem = 2:1.20.1-22.el9_6.2
   provider: nginx-filesystem-2:1.20.1-22.el9_6.2.noarch
  dependency: pcre
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
  dependency: system-logos-httpd
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
  dependency: systemd
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686

package: nginx-2:1.20.1-22.el9_6.3.x86_64
  dependency: /bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: /usr/bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: nginx-core = 2:1.20.1-22.el9_6.3
   provider: nginx-core-2:1.20.1-22.el9_6.3.x86_64
   provider: nginx-core-2:1.20.1-22.el9_6.3.x86_64
  dependency: nginx-filesystem = 2:1.20.1-22.el9_6.3
   provider: nginx-filesystem-2:1.20.1-22.el9_6.3.noarch
   provider: nginx-filesystem-2:1.20.1-22.el9_6.3.noarch
  dependency: pcre
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
  dependency: system-logos-httpd
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
  dependency: systemd
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686

package: nginx-2:1.20.1-22.el9_6.3.x86_64
  dependency: /bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: /usr/bin/sh
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
   provider: bash-5.1.8-9.el9.x86_64
  dependency: nginx-core = 2:1.20.1-22.el9_6.3
   provider: nginx-core-2:1.20.1-22.el9_6.3.x86_64
   provider: nginx-core-2:1.20.1-22.el9_6.3.x86_64
  dependency: nginx-filesystem = 2:1.20.1-22.el9_6.3
   provider: nginx-filesystem-2:1.20.1-22.el9_6.3.noarch
   provider: nginx-filesystem-2:1.20.1-22.el9_6.3.noarch
  dependency: pcre
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
   provider: pcre-8.44-4.el9.i686
   provider: pcre-8.44-4.el9.x86_64
  dependency: system-logos-httpd
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
   provider: rocky-logos-httpd-90.16-1.el9.noarch
  dependency: systemd
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
   provider: systemd-252-51.el9_6.3.rocky.0.1.x86_64
   provider: systemd-252-51.el9_6.3.rocky.0.1.i686
```

**说明**：`deplist`命令展示了nginx软件包的所有依赖项，包括shell解释器、核心组件、文件系统、pcre库、系统日志和systemd服务等。输出中显示了每个依赖项的提供程序，即哪些软件包可以满足这些依赖。
```

#### 软件包安装

```bash
# 安装指定软件包
dnf install nginx

# 安装多个软件包
dnf install nginx mysql-server php

# 安装本地RPM包（并解决依赖）
dnf install package.rpm

# 重新安装软件包
dnf reinstall nginx
```

#### 软件包更新

```bash
# 检查可用更新
dnf check-update

# 更新所有软件包
dnf update

# 更新特定软件包
dnf update nginx

# 升级系统到新版本
dnf upgrade
```

#### 软件包卸载

```bash
# 卸载软件包
dnf remove nginx

# 卸载软件包（与remove命令完全相同）
dnf erase nginx
```

**说明**：在YUM/DNF包管理系统中，`erase`和`remove`是完全相同的命令，它们是彼此的别名。无论是使用`yum erase`还是`yum remove`，或者是`dnf erase`还是`dnf remove`，都会执行相同的操作 - 删除指定的软件包及其不再被其他包依赖的依赖项。

这两个命令在功能上没有任何区别，只是命令名称不同。通常`remove`命令更为常用，因为它的名称更直观地表达了删除操作的含义。

### 3.3 dnf仓库管理

```bash
# 列出所有启用的仓库
dnf repolist enabled

# 列出所有仓库（包括禁用的）
dnf repolist all

# 启用仓库
dnf config-manager --enable repo-name

# 禁用仓库
dnf config-manager --disable repo-name

# 安装EPEL扩展仓库
dnf install epel-release
```

## 4. yum与dnf的对比

| 特性 | yum | dnf |
|------|-----|-----|
| 开发语言 | Python 2 | Python 3 |
| 性能 | 较慢，尤其是处理大量包时 | 更快，使用libsolv解决依赖 |
| 内存占用 | 较高 | 较低 |
| 命令兼容性 | - | 兼容大部分yum命令 |
| 错误处理 | 较简单 | 更完善的错误报告 |
| 依赖解析 | 基于算法，有时不准确 | 基于libsolv，更准确 |
| 事务支持 | 有限 | 完整的事务支持 |
| 配置文件位置 | /etc/yum.conf, /etc/yum.repos.d/ | /etc/dnf/dnf.conf, /etc/yum.repos.d/ |
| 默认发行版 | RHEL 5-7, CentOS 5-7 | RHEL 8+, CentOS 8+, Fedora 22+ |

### 4.1 现代系统中的实际关系

在现代RHEL系系统中，yum实际上是dnf的别名，两者最终都指向同一个二进制文件。以下是在Rocky Linux 9.6系统中的实际输出：

```bash
# 验证nginx包的完整性
rpm -V nginx
   0 ✓ 19:56:21 soveran@rocky9.6-12,10.0.0.12:/tmp/softs $

# 查看yum命令的实际指向
ll /usr/bin/yum
lrwxrwxrwx. 1 root root 5  5月  4  2025 /usr/bin/yum -> dnf-3
   0 ✓ 20:04:34 soveran@rocky9.6-12,10.0.0.12:/tmp/softs $

# 查看dnf命令的实际指向
ll /usr/bin/dnf
lrwxrwxrwx. 1 root root 5  5月  4  2025 /usr/bin/dnf -> dnf-3
   0 ✓ 20:04:42 soveran@rocky9.6-12,10.0.0.12:/tmp/softs $
```

这个输出表明：
1. `rpm -V nginx` 验证了nginx包的完整性（无输出表示验证通过）
2. `yum` 和 `dnf` 都是指向 `dnf-3` 二进制文件的符号链接
3. 在现代系统中，无论使用 `yum` 还是 `dnf` 命令，实际上执行的都是相同的程序

## 5. 高级用法

### 5.1 软件组管理

```bash
# 列出所有软件组
dnf grouplist

# 查看软件组详细信息
dnf groupinfo "Development Tools"

# 安装软件组
dnf groupinstall "Development Tools"

# 更新软件组
dnf groupupdate "Development Tools"

# 移除软件组
dnf groupremove "Development Tools"
```

### 5.2 缓存管理

```bash
# 查看缓存信息
dnf clean all

# 清除元数据缓存
dnf clean metadata

# 清除软件包缓存
dnf clean packages

# 构建缓存
dnf makecache
```

#### 实际输出示例（yum makecache）：

```bash
$ yum makecache
警告：加载 '/etc/yum.repos.d/private.repo' 失败，跳过。
Rocky Linux 9 - BaseOS                                                                                                                651 kB/s | 2.5 MB     00:03
Rocky Linux 9 - AppStream                                                                                                             5.6 MB/s | 9.5 MB     00:01
Rocky Linux 9 - Extras                                                                                                                 11 kB/s |  17 kB     00:01
元数据缓存已建立。
```

#### 私有仓库配置示例

可以通过配置文件创建自定义私有仓库，以下是一个私有仓库配置示例：

```bash
$ cat /etc/yum.repos.d/private.repo
[private-extras]
name=private extras
baseurl= http://10.0.0.12/nju-extras/ 
gpgcheck=0

[private-baseos]
name=private baseos
baseurl= http://10.0.0.12/BaseOS/ 
gpgcheck=0
```

**说明**：
- `yum makecache`命令用于建立元数据缓存，可提高后续包管理操作的速度
- 如果仓库配置有误（如示例中的private.repo），系统会显示警告但仍会处理其他有效仓库
- 私有仓库配置通常包含仓库ID、名称、基础URL和GPG检查设置
- 设置`gpgcheck=0`会禁用GPG签名检查，这在测试环境中常见，但在生产环境中建议启用以确保包的完整性和安全性

### 创建和管理私有仓库

私有仓库通常需要在服务器端创建和维护。以下是在Rocky Linux上创建和配置私有仓库的完整流程：

#### 1. 准备仓库目录和软件包

```bash
# 在服务器上创建仓库目录
mkdir -p /var/www/html/my-extras/Packages

# 复制现有仓库内容（示例：从nju-extras复制到my-extras）
sudo cp nju-extras/ -r my-extras

# 删除旧的元数据
sudo rm -rf my-extras/repodata/
```

#### 2. 安装createrepo工具

```bash
# 安装createrepo工具（用于生成仓库元数据）
sudo yum install createrepo -y
```

#### 3. 生成仓库元数据

```bash
# 生成仓库元数据
# 注意：需要以root权限运行，否则会出现权限错误
sudo createrepo my-extras/

# 查看生成的元数据文件
ls my-extras/repodata/
```

**输出示例**：
```bash
Directory walk started
Directory walk done - 56 packages
Temporary output repo path: my-extras/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished

ls my-extras/repodata/
1a19326166f536935eaeebeab1cf9cb32645a74e06c3b0b17163a14c9c119910-filelists.sqlite.bz2
7206488f911b80d3cec3e29e1e214887d6ec7540497fd523ff38417a058f1cb4-filelists.xml.gz
8b7151c6cf0d2e9d92700b188f6a61287610fbe16ca3cc38380c9f1c7aa1dcf1-other.sqlite.bz2
b2b38d461faa99b789697a8619f7bfdf40bbad078786657d3261850c0592db31-primary.xml.gz
e761810282a88f36e26d0593175e291a5febcc6ff92b49a55771fb25370efb4b-primary.sqlite.bz2
f1c335aceb6e54ba07b2f53f125b65b59e580c0c75af8647af3902224350be9a-other.xml.gz
repomd.xml
```

#### 4. 配置多私有仓库

可以在同一配置文件中定义多个私有仓库：

```bash
$ cat /etc/yum.repos.d/private.repo
[private-extras1]
name=private extras1
baseurl=http://10.0.0.12/nju-extras/
gpgcheck=0

[private-extras2]
name=private extras2
baseurl=http://10.0.0.12/my-extras/
gpgcheck=0

[private-baseos]
name=private baseos
baseurl=http://10.0.0.12/BaseOS/
gpgcheck=0
```

#### 5. 验证私有仓库配置

```bash
# 重新生成缓存，检查所有私有仓库是否正常加载
sudo yum makecache

# 查看特定私有仓库中的软件包
yum list --repo="private-extras2" anaconda-live
```

**验证结果示例**：
```bash
sudo yum makecache
aliyun.baseos                                                                                                                          26 kB/s | 4.1 kB     00:00
cdrom appstream                                                                                                                       4.4 MB/s | 4.5 kB     00:00
cdrom baseos                                                                                                                          4.0 MB/s | 4.1 kB     00:00
Extra Packages for Enterprise Linux 9 - x86_64                                                                                        638  B/s | 9.7 kB     00:15
Extra Packages for Enterprise Linux 9 openh264 (From Cisco) - x86_64                                                                  718  B/s | 993  B  `https://mirrors.nju.edu.cn/epel/9/Everything/x86_64`                                                  37 kB/s | 4.0 kB     00:00
nju AppStream                                                                                                                          43 kB/s | 4.5 kB     00:00
nju BaseOS                                                                                                                             41 kB/s | 4.1 kB     00:00
nju extras                                                                                                                             29 kB/s | 2.9 kB     00:00
private extras1                                                                                                                       1.1 MB/s |  17 kB     00:00
private extras2                                                                                                                       6.7 MB/s |  17 kB     00:00
private baseos                                                                                                                        179 MB/s | 2.5 MB     00:00
Rocky Linux 9 - BaseOS                                                                                                                4.2 kB/s | 4.1 kB     00:00
Rocky Linux 9 - AppStream                                                                                                             5.9 kB/s | 4.5 kB     00:00
Rocky Linux 9 - Extras                                                                                                                3.1 kB/s | 2.9 kB     00:00
元数据缓存已建立。

yum list --repo="private-extras2" anaconda-live
private extras2                                                                                                                       1.1 MB/s |  17 kB     00:00
可安装的软件包
anaconda-live.x86_64                                                   34.25.5.17-1.el9_6.rocky.0.3                                                    private-extras2
```

**关键点说明**：
- 私有仓库需要在服务器端使用`createrepo`工具生成元数据文件
- 每个私有仓库应具有唯一的仓库ID（如[private-extras1]、[private-extras2]）
- 可以通过`--repo`参数指定从特定仓库查询或安装软件包
- 定期更新仓库内容后，需要重新运行`createrepo`更新元数据

### 修复私有仓库加载失败的方法

当遇到"加载 '/etc/yum.repos.d/private.repo' 失败，跳过"错误时，可以通过以下步骤排查和修复：

#### 1. 检查仓库配置文件语法

```bash
# 使用dnf命令检查仓库配置语法
dnf repolist -v

# 或使用yum命令检查
yum repolist -v
```

#### 2. 验证仓库服务器连接

```bash
# 测试仓库服务器是否可访问
ping 10.0.0.12

# 测试HTTP连接
telnet 10.0.0.12 80

# 使用curl检查仓库路径是否存在
curl -I http://10.0.0.12/nju-extras/
curl -I http://10.0.0.12/BaseOS/
```

#### 3. 检查仓库配置文件权限

```bash
# 确保配置文件权限正确
chmod 644 /etc/yum.repos.d/private.repo

# 检查文件所有者
ls -l /etc/yum.repos.d/private.repo
```

#### 4. 修复配置文件格式问题

配置文件中的URL不应有多余空格，修复后的配置示例：

```bash
$ cat /etc/yum.repos.d/private.repo
[private-extras]
name=private extras
baseurl=http://10.0.0.12/nju-extras/
gpgcheck=0

enabled=0  # 可选：设置为0临时禁用仓库

[private-baseos]
name=private baseos
baseurl=http://10.0.0.12/BaseOS/
gpgcheck=0

enabled=1  # 可选：设置为1启用仓库
```

**常见问题与解决方案**：
- **URL格式错误**：确保`baseurl`后没有多余空格或特殊字符
- **服务器不可达**：检查网络连接和防火墙设置
- **仓库路径不存在**：确认服务器上的仓库路径正确配置
- **语法错误**：确保每个配置项使用`key=value`格式，没有拼写错误
- **隐藏特殊字符**：检查文件末尾是否有隐藏字符（如`~`符号）或错误的引号类型（如中文引号、反引号`` ` ``）
- **权限问题**：确保配置文件对系统包管理器可读

#### 实际修复案例

用户在排查中发现，私有仓库配置文件的最后一行存在一个隐藏的`~`字符，这是导致仓库加载失败的根本原因：

```bash
# 修复前（存在隐藏~字符）
[private-baseos]
name=private baseos
baseurl= `http://10.0.0.12/BaseOS/`  
gpgcheck=0~

# 修复后（移除隐藏~字符）
[private-baseos]
name=private baseos
baseurl=http://10.0.0.12/BaseOS/
gpgcheck=0
```

修复后，`yum makecache`命令成功执行：

```bash
$ yum makecache
private extras                                                                                                                        971 kB/s |  17 kB     00:00
private baseos                                                                                                                        134 MB/s | 2.5 MB     00:00
Rocky Linux 9 - BaseOS                                                                                                                3.6 kB/s | 4.1 kB     00:01
Rocky Linux 9 - AppStream                                                                                                             5.1 kB/s | 4.5 kB     00:00
Rocky Linux 9 - Extras                                                                                                                2.1 kB/s | 2.9 kB     00:01
元数据缓存已建立。
```

**提示**：使用`cat -A /etc/yum.repos.d/private.repo`命令可以显示文件中的隐藏字符，帮助排查类似问题。

### 5.3 事务管理

```bash
# 查看事务历史
dnf history

# 查看特定事务的详细信息
dnf history info 1

# 查看与特定包相关的事务历史
dnf history nginx

# 撤销特定事务
dnf history undo 1

# 重做特定事务
dnf history redo 1
```

#### 查看事务历史示例
```bash
ID     | 命令行                                                                                                          | 日期和时间       | 操作           | 更改 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    17 | localinstall /tmp/httpd/nginx-1.20.1-22.el9_6.3.x86_64.rpm                                                      | 2025-11-15 21:15 | Install        |    4
    16 | remove nginx                                                                                                    | 2025-11-15 21:13 | Removed        |    4
    15 | erase httpd                                                                                                     | 2025-11-15 21:11 | Removed        |   10
    14 | install httpd                                                                                                   | 2025-11-15 21:09 | Install        |   10
    13 | install yum-utils
```

#### 查看特定事务的详细信息示例
```bash
yum history info 4 
 事务 ID： 4 
 起始时间    ： 2025年11月10日 星期一 20时48分30秒 
 起始 RPM 数据库     ： 8231f40f3bbd7f8f56adf4e7ff7330133f557d7df715c2ac74bf21546ded0c8c 
 结束时间       ： 2025年11月10日 星期一 20时48分30秒 （0 秒） 
 结束 RPM 数据库      : ed1ba878be3f50843bcc844475fe6d64f5dfae561b198d6190db94c61efc492c 
 用户           ： soveran <soveran> 
 返回码    ： 成功 
 发行版     : 9 
 命令行   ： install -y nginx 
 注释        : 
 已改变的包： 
     安装 nginx-filesystem-2:1.20.1-22.el9_6.3.noarch @appstream 
     安装 rocky-logos-httpd-90.16-1.el9.noarch        @appstream 
     安装 nginx-2:1.20.1-22.el9_6.3.x86_64            @appstream 
     安装 nginx-core-2:1.20.1-22.el9_6.3.x86_64       @appstream 
```

#### 查看与特定包相关的事务历史示例
```bash
yum history nginx 
 ID     | 命令行                                                                                                          | 日期和时间       | 操作           | 更改 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
     17 | localinstall /tmp/httpd/nginx-1.20.1-22.el9_6.3.x86_64.rpm                                                      | 2025-11-15 21:15 | Install        |    4 
     16 | remove nginx                                                                                                    | 2025-11-15 21:13 | Removed        |    4  < 
      8 | install -y nginx                                                                                                | 2025-11-13 19:56 | Install        |    4 >< 
      6 | remove nginx                                                                                                    | 2025-11-13 15:51 | Removed        |    4 >< 
      4 | install -y nginx                                                                                                | 2025-11-10 20:48 | Install        |    4 > 
```

**说明**：事务历史记录了系统中所有包管理操作的详细信息，包括命令行、执行时间、操作类型（安装、移除等）以及更改的包数量。通过事务历史，可以追踪系统软件包的变更历史，方便进行故障排除和系统恢复。使用`history info <ID>`可以查看特定事务的详细信息，包括影响的具体软件包；使用`history <package>`可以筛选出与特定软件包相关的所有事务历史。

# 查看DNF日志文件
# DNF会将操作记录到多个日志文件中，便于问题排查和审计

```bash
ls /var/log/dnf.*
```

实际输出示例：
```bash
/var/log/dnf.librepo.log  /var/log/dnf.log  /var/log/dnf.rpm.log
```

**说明**：DNF使用多个日志文件记录不同类型的信息：
- `dnf.log`：主要记录DNF操作的一般信息，如命令执行、依赖解析、包安装等
- `dnf.rpm.log`：记录与RPM包相关的详细操作，如包的安装、移除、验证等
- `dnf.librepo.log`：记录与librepo库相关的日志，主要用于调试仓库访问和元数据下载问题

### 5.4 安全更新

```bash
# 列出安全更新
dnf updateinfo list security

# 安装所有安全更新
dnf update --security

# 安装特定类型的安全更新
dnf update --sec-severity=Critical
```

## 6. 配置文件详解

### 6.1 主配置文件

**dnf主配置文件：** `/etc/dnf/dnf.conf`

```ini
[main]
cachedir=/var/cache/dnf
keepcache=0
debuglevel=2
logfile=/var/log/dnf.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=3
autoremove_keep_current=10
best=1
```

**主要配置项说明：**
- `cachedir`：缓存目录位置
- `keepcache`：是否保留下载的包（0=不保留，1=保留）
- `gpgcheck`：是否检查GPG签名（0=不检查，1=检查）
- `plugins`：是否启用插件（0=禁用，1=启用）
- `installonly_limit`：保留多少个内核版本
- `best`：是否总是尝试安装最新版本

### 6.2 仓库配置文件

仓库配置文件位于 `/etc/yum.repos.d/` 目录下，通常以 `.repo` 为扩展名。

**示例：EPEL仓库配置**

```ini
[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
baseurl=https://download.fedoraproject.org/pub/epel/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-$releasever
```

**主要配置项说明：**
- `name`：仓库名称
- `baseurl`：仓库的基础URL
- `metalink`：仓库的元数据链接（用于自动选择最快的镜像）
- `enabled`：是否启用该仓库（0=禁用，1=启用）
- `gpgcheck`：是否检查GPG签名
- `gpgkey`：GPG密钥文件路径

## 7. 实用案例

### 7.1 案例：搭建Web服务器

```bash
# 安装Web服务器组件
dnf install nginx php php-fpm php-mysqlnd mysql-server

# 启动并启用服务
systemctl start nginx php-fpm mysqld
systemctl enable nginx php-fpm mysqld

# 查看服务状态
systemctl status nginx php-fpm mysqld
```

### 7.2 案例：安装开发环境

```bash
# 安装开发工具组
dnf groupinstall "Development Tools"

# 安装额外的开发库
dnf install gcc-c++ make cmake git

# 安装Python开发环境
dnf install python3 python3-devel python3-pip
```

### 7.3 案例：从旧版本迁移到dnf

```bash
# 在CentOS 7上安装dnfyum install dnf

# 比较yum和dnf的性能
time yum list available > /dev/null
time dnf list available > /dev/null
```

### 7.4 案例：解决依赖冲突

```bash
# 查看依赖问题
dnf repoquery --requires --resolve nginx

# 使用--allowerasing选项解决冲突
dnf install new-package --allowerasing

# 使用--skip-broken选项跳过损坏的依赖
dnf update --skip-broken
```

## 8. 最佳实践

### 8.1 安全最佳实践

```bash
# 定期检查安全更新
dnf updateinfo list security

# 只安装安全更新
dnf update --security

# 启用GPG检查（默认已启用）
gpgcheck=1

# 使用官方仓库和受信任的第三方仓库
```

### 8.2 性能优化

```bash
# 清理缓存以节省磁盘空间
dnf clean all

# 启用 fastestmirror 插件（自动选择最快的镜像）
# 在 /etc/dnf/dnf.conf 中添加：
plugins=1
fastestmirror=1

# 增加并行下载数量
deltarpm=1
max_parallel_downloads=10
```

### 8.3 维护最佳实践

```bash
# 定期更新系统
dnf update

# 移除不再需要的软件包
dnf autoremove

# 检查系统中可能存在的问题
dnf check

# 备份重要的配置文件
tar -czvf dnf-config-backup.tar.gz /etc/dnf/ /etc/yum.repos.d/
```

## 9. 常见问题与解决方案

### 9.1 仓库连接失败

**问题：** `Failed to download metadata for repo 'epel': Cannot prepare internal mirrorlist`

**解决方案：**
```bash
# 检查网络连接
ping download.fedoraproject.org

# 清理缓存并重新构建
dnf clean all
dnf makecache

# 检查仓库配置
dnf config-manager --dump epel
```

### 9.2 依赖冲突

**问题：** `Error: package1 conflicts with package2`

**解决方案：**
```bash
# 使用--allowerasing选项
dnf install package --allowerasing

# 手动移除冲突的包
dnf remove conflicting-package
dnf install package
```

### 9.3 GPG签名检查失败

**问题：** `GPG key retrieval failed: [Errno 14] curl#37 - "Couldn't open file /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8"`

**解决方案：**
```bash
# 安装缺失的GPG密钥
dnf install fedora-repos-archive

# 手动导入GPG密钥
rpm --import https://download.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
```

## 10. 总结与未来趋势

### 10.1 主要知识点回顾

1. **yum和dnf的关系**：dnf是yum的下一代替代品，提供更好的性能和功能
2. **核心功能**：软件包的安装、更新、卸载、查询和依赖管理
3. **仓库管理**：配置和管理软件仓库，扩展可用软件源
4. **高级特性**：软件组、缓存管理、事务历史、安全更新
5. **最佳实践**：安全、性能和维护方面的推荐做法

### 10.2 未来发展趋势

- **模块化包管理**：Fedora已开始采用模块化包管理，允许安装同一软件的多个版本
- **容器化软件分发**：Docker和Podman等容器技术正在改变软件分发方式
- **扁平化包管理**：减少依赖层级，提高系统稳定性
- **人工智能辅助**：使用AI优化依赖解析和包选择过程

通过掌握yum和dnf这两款强大的包管理工具，您可以高效地管理Linux系统中的软件，确保系统安全、稳定地运行。无论是系统管理员还是开发人员，熟练使用包管理工具都是Linux技能体系中不可或缺的一部分。

## 11. 趣味命令与小技巧

除了常规的系统管理功能，Linux还提供了一些有趣的命令，可以为您的工作增添一些乐趣。以下是一些通过yum/dnf安装和使用的趣味命令示例：

### 11.1 火车命令 (sl) 和 奶牛说命令 (cowsay)

在Rocky Linux 9中，`cowsay`和`sl`这两个包默认不在官方的基础仓库中，需要启用EPEL（Extra Packages for Enterprise Linux）仓库才能安装。

**解决步骤：**
1. **安装EPEL仓库**
   EPEL提供了许多企业版Linux额外的常用软件包，执行以下命令安装：
   ```bash
   sudo dnf install epel-release -y
   ```
   （Rocky Linux推荐使用`dnf`替代`yum`，两者功能类似，`dnf`是更新的包管理器）

2. **更新仓库缓存**
   ```bash
   sudo dnf makecache
   ```

3. **安装cowsay和sl**
   ```bash
   sudo dnf install cowsay sl -y
   ```

4. **验证安装**
   - 运行`cowsay "Hello World"`测试cowsay
   - 运行`sl`测试小火车动画

### 11.2 扩展：更多趣味命令

**安装fortune和animalsay**
```bash
# 需要先安装EPEL仓库
sudo dnf install fortune-mod cowsay-animals -y
```

**使用示例：**
```bash
# 基本使用
cowsay "Hello Linux!"

# 管道使用
fortune | cowsay

# 使用不同的动物
animalsay cat "Meow!"

# 查看可用的动物
ls /usr/share/cowsay/cows/
```

这些趣味命令虽然没有实际的系统管理功能，但它们展示了Linux系统的灵活性和社区的创造力，也可以在学习和工作中带来一些轻松的时刻。EPEL仓库还包含很多其他实用工具，后续安装其他软件时也可能会用到。