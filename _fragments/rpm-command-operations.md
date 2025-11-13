---
layout: fragment
title: RPM命令操作详解与实践
tags: [Linux, RPM, 包管理, 安装, 升级, 删除, 查询]
description: 详细介绍RPM包管理工具的常用命令，包括下载、安装、升级、删除和查询等操作实践
keywords: Linux, RPM, 包管理, 安装, 升级, 删除, 查询, vsftpd, httpd
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

## 问题记录

1. **如何下载指定版本的RPM包？**
   - 使用wget命令直接从镜像站点下载特定版本的RPM包
   - 例如：`wget https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/Packages/vsftpd-3.0.3-49.el9.x86_64.rpm`

2. **如何安装、升级和删除RPM包？**
   - 安装：`rpm -ivh package.rpm`
   - 升级：`rpm -Uvh package.rpm`
   - 删除：`rpm -evh package`

3. **如何查询已安装的RPM包信息？**
   - 查询是否安装：`rpm -q package`
   - 查询详细信息：`rpm -qi package`
   - 查询文件所属包：`rpm -qf file_path`

4. **如何查看RPM包的内容和文件列表？**
   - 查看本地RPM包内容：`rpm -qpf package.rpm`
   - 查看已安装包内容：`rpm -ql package`

5. **如何查询RPM包的配置文件？**
   - 查询已安装包的配置文件：`rpm -qc package`
   - 查询本地RPM包的配置文件：`rpm -qpc package.rpm`

6. **如何查询RPM包的文档文件？**
   - 查询已安装包的文档文件：`rpm -qd package`
   - 查询本地RPM包的文档文件：`rpm -qpd package.rpm`

7. **如何查询RPM包的安装/卸载脚本？**
   - 查询已安装包的脚本：`rpm -q --scripts package`

8. **如何查询RPM包的变更日志？**
   - 查询已安装包的变更日志：`rpm -q --changelog package`

9. **如何查询RPM包的依赖关系？**
   - 查询已安装包的依赖：`rpm -qR package`
   - 查询本地RPM包的依赖：`rpm -qpR package.rpm`

10. **如何批量处理RPM包查询？**
    - 使用grep过滤查询结果：`rpm -qa | grep keyword`

11. **如何管理RPM数据库？**
    - 初始化RPM数据库：`sudo rpm --initdb`
    - 重建RPM数据库：`sudo rpm --rebuilddb`

## 关键概念

- **RPM**：Red Hat Package Manager，Linux系统中常用的包管理工具
- **安装(Install)**：将RPM包中的文件解压并复制到系统相应位置
- **升级(Upgrade)**：替换旧版本的包为新版本，保留配置文件
- **删除(Erase)**：从系统中移除已安装的包及其文件
- **查询(Query)**：获取包的各种信息，如版本、依赖、文件列表等
  - `-qc`：查询已安装包的配置文件
  - `-qpc`：查询本地RPM包的配置文件
  - `-ql`：查询已安装包包含的所有文件
  - `-qf`：查询文件所属的包
  - `-qpf`：查询本地RPM包包含的文件
  - `-qd`：查询已安装包的文档文件
  - `-qpd`：查询本地RPM包的文档文件
  - `--scripts`：查询已安装包的安装/卸载脚本
  - `--changelog`：查询已安装包的变更日志
  - `-qR`：查询已安装包的依赖关系
  - `-qpR`：查询本地RPM包的依赖关系
- **数据库管理**：维护RPM包数据库
  - `--initdb`：初始化RPM数据库，如果不存在则创建
  - `--rebuilddb`：重建RPM数据库索引

## RPM包管理操作实践

### 1. RPM数据库管理

查看RPM数据库文件：

```bash
[root@rocky9 ~]# ll /var/lib/rpm/
总用量 96620
-rw-r--r--. 1 root root 98906112 11月 13 19:36 rpmdb.sqlite
-rw-r--r--. 1 root root    32768 11月 13 19:36 rpmdb.sqlite-shm
-rw-r--r--. 1 root root        0 11月 13 19:36 rpmdb.sqlite-wal
```

重建RPM数据库（需要管理员权限）：

```bash
[root@rocky9 ~]# rpm --rebuilddb
错误：无法创建 事务 锁定于 /var/lib/rpm/.rpm.lock (权限不够)

[root@rocky9 ~]# sudo rpm --rebuilddb
[sudo] soveran 的密码：
```

查看重建后的RPM数据库文件：

```bash
[root@rocky9 ~]# ll /var/lib/rpm
总用量 81100
-rw-r--r--. 1 root root 82751488 11月 13 19:43 rpmdb.sqlite
-rw-r--r--. 1 root root   294912 11月 13 19:43 rpmdb.sqlite-shm
-rw-r--r--. 1 root root        0 11月 13 19:43 rpmdb.sqlite-wal
```

### 2. 下载RPM包

使用wget命令从镜像站点下载指定版本的RPM包：

```bash
# 下载vsftpd 3.0.3版本
wget https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/Packages/vsftpd-3.0.3-49.el9.x86_64.rpm

# 下载vsftpd 3.0.5版本
wget https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/Packages/vsftpd-3.0.5-6.el9.x86_64.rpm

# 下载httpd 2.4.57版本
wget https://mirrors.aliyun.com/centos-stream/9-stream/AppStream/x86_64/os/Packages/httpd-2.4.57-8.el9.x86_64.rpm

# 查看下载的文件
ll
```

### 2. 安装RPM包

使用`rpm -ivh`命令安装RPM包：

```bash
# 安装vsftpd 3.0.3版本（普通用户）
rpm -ivh vsftpd-3.0.3-49.el9.x86_64.rpm

# 安装vsftpd 3.0.3版本（管理员权限）
sudo rpm -ivh vsftpd-3.0.3-49.el9.x86_64.rpm

# 安装httpd 2.4.57版本（普通用户）
rpm -ivh httpd-2.4.57-8.el9.x86_64.rpm

# 安装httpd 2.4.57版本（管理员权限）
sudo rpm -ivh httpd-2.4.57-8.el9.x86_64.rpm
```

### 3. 升级RPM包

使用`rpm -Uvh`命令升级RPM包：

```bash
# 升级vsftpd到3.0.5版本
sudo rpm -Uvh vsftpd-3.0.5-6.el9.x86_64.rpm

# 降级vsftpd到3.0.3版本（需要管理员权限）
sudo rpm -Uvh vsftpd-3.0.3-49.el9.x86_64.rpm
```

### 4. 删除RPM包

使用`rpm -evh`命令删除RPM包：

```bash
# 删除vsftpd包（普通用户）
rpm -evh vsftpd

# 删除vsftpd包（管理员权限）
sudo rpm -evh vsftpd
```

### 5. 查询RPM包信息

使用各种查询命令获取RPM包信息：

```bash
# 查询vsftpd是否已安装
sudo rpm -q vsftpd

# 条件删除：如果vsftpd已安装则删除
rpm -q vsftpd && rpm -evh vsftpd

# 使用-Fvh选项升级（只升级已安装的包）
rpm -Fvh vsftpd-3.0.3-49.el9.x86_64.rpm

# 再次安装vsftpd 3.0.3版本
sudo rpm -Uvh vsftpd-3.0.3-49.el9.x86_64.rpm

# 条件删除（使用管理员权限）
sudo rpm -q vsftpd && rpm -evh vsftpd

# 条件删除（所有命令都使用管理员权限）
sudo rpm -q vsftpd && sudo rpm -evh vsftpd

# 查询所有与passwd相关的已安装包
sudo rpm -qa | grep passwd

# 查询ssh是否已安装
rpm -q ssh

# 查询tree是否已安装
rpm -q tree

# 查看tree包的详细信息
rpm -qi tree

# 查看本地vsftpd RPM包的详细信息
rpm -qi /tmp/softs/vsftpd-3.0.3-49.el9.x86_64.rpm

# 查询/bin/tree属于哪个包
rpm -qf /bin/tree

# 查看本地vsftpd RPM包包含的文件
rpm -qpf /tmp/softs/vsftpd-3.0.3-49.el9.x86_64.rpm

# 查询/usr/local/bin/tldr属于哪个包
rpm -qf /usr/local/bin/tldr

# 查询已安装的NetworkManager包的配置文件
rpm -qc NetworkManager

# 查询本地vsftpd RPM包的配置文件
rpm -qpc vsftpd-3.0.3-49.el9.x86_64.rpm

# 查询已安装的tree包包含的所有文件
rpm -ql tree

# 查询已安装的tree包的文档文件
rpm -qd tree

# 查询本地vsftpd RPM包的文档文件
rpm -qpd vsftpd-3.0.3-49.el9.x86_64.rpm

# 查询已安装的tree包的依赖关系
```bash
[root@rocky9 ~]# rpm -qR tree
 libc.so.6()(64bit)
 libc.so.6(GLIBC_2.14)(64bit)
 libc.so.6(GLIBC_2.2.5)(64bit)
 libc.so.6(GLIBC_2.3)(64bit)
 libc.so.6(GLIBC_2.3.4)(64bit)
 libc.so.6(GLIBC_2.33)(64bit)
 libc.so.6(GLIBC_2.34)(64bit)
 libc.so.6(GLIBC_2.4)(64bit)
 rpmlib(CompressedFileNames) <= 3.0.4-1
 rpmlib(FileDigests) <= 4.6.0-1
 rpmlib(PayloadFilesHavePrefix) <= 4.0-1
 rpmlib(PayloadIsZstd) <= 5.4.18-1
 rtld(GNU_HASH)
```

# 查询已安装的postfix包的安装/卸载脚本
```bash
[root@rocky9 ~]# rpm -q --scripts postfix
preinstall scriptlet (using /bin/sh):
# Create the postfix user and group if they don't exist
if ! /usr/bin/getent group postfix > /dev/null; then
    /usr/sbin/groupadd -g 89 -r postfix 2>/dev/null || :
fi
if ! /usr/bin/getent passwd postfix > /dev/null; then
    /usr/sbin/useradd -u 89 -r -g postfix -d /var/spool/postfix -s /sbin/nologin \
        -c "Postfix Mail Transport Agent" postfix 2>/dev/null || :
fi
if ! /usr/bin/getent group postdrop > /dev/null; then
    /usr/sbin/groupadd -g 90 -r postdrop 2>/dev/null || :
fi

# Create the postfix user and group for centos-release-oidc
if [ -f /etc/os-release ]; then
    if grep -q -i rocky /etc/os-release; then
        if ! /usr/bin/getent group postfix > /dev/null; then
            /usr/sbin/groupadd -g 89 -r postfix 2>/dev/null || :
        fi
        if ! /usr/bin/getent passwd postfix > /dev/null; then
            /usr/sbin/useradd -u 89 -r -g postfix -d /var/spool/postfix -s /sbin/nologin \
                -c "Postfix Mail Transport Agent" postfix 2>/dev/null || :
        fi
    fi
fi

# Create the postdrop group if it doesn't exist for centos-release-oidc
if [ -f /etc/os-release ]; then
    if grep -q -i rocky /etc/os-release; then
        if ! /usr/bin/getent group postdrop > /dev/null; then
            /usr/sbin/groupadd -g 90 -r postdrop 2>/dev/null || :
        fi
    fi
fi
postinstall scriptlet (using /bin/sh):
# Set up the TLS certificate directory if it doesn't exist
mkdir -p /etc/pki/tls/certs/postfix
chmod 750 /etc/pki/tls/certs/postfix
chown root:postfix /etc/pki/tls/certs/postfix

# Set up the TLS private key directory if it doesn't exist
mkdir -p /etc/pki/tls/private/postfix
chmod 750 /etc/pki/tls/private/postfix
chown root:postfix /etc/pki/tls/private/postfix

# Create a self-signed certificate if one doesn't exist
if [ ! -f /etc/pki/tls/certs/postfix/server.crt ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/pki/tls/private/postfix/server.key \
        -out /etc/pki/tls/certs/postfix/server.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=$(hostname)" \
        > /dev/null 2>&1
    chmod 600 /etc/pki/tls/private/postfix/server.key
    chown root:postfix /etc/pki/tls/private/postfix/server.key
    chmod 644 /etc/pki/tls/certs/postfix/server.crt
    chown root:postfix /etc/pki/tls/certs/postfix/server.crt
fi

# Set up the alternatives for sendmail
update-alternatives --install /usr/sbin/sendmail mta /usr/sbin/sendmail.postfix 30 \
    --slave /usr/bin/mailq mailq /usr/bin/mailq.postfix \
    --slave /usr/bin/newaliases newaliases /usr/bin/newaliases.postfix

# Start the postfix service if it's not already running
systemctl start postfix
preuninstall scriptlet (using /bin/sh):
# Stop the postfix service if it's running
if [ "$1" = 0 ]; then
    systemctl stop postfix
    systemctl disable postfix
fi
postuninstall scriptlet (using /bin/sh):
# Remove the alternatives for sendmail if postfix is being completely removed
if [ "$1" = 0 ]; then
    update-alternatives --remove mta /usr/sbin/sendmail.postfix
fi

# Remove the TLS certificate and private key directories if they're empty
rmdir --ignore-fail-on-non-empty /etc/pki/tls/certs/postfix
rmdir --ignore-fail-on-non-empty /etc/pki/tls/private/postfix
```

# 查询已安装的tree包的变更日志
```bash
[root@rocky9 ~]# rpm -q --changelog tree
* 五 9月 17 2021 Kamil Dudka <kdudka@redhat.com> - 1.8.0-10
- reflect review comments from Fedora Review (#2001467)

* 五 9月 03 2021 Kamil Dudka <kdudka@redhat.com> - 1.8.0-8
- source package renamed to tree-pkg to make it work with Pagure and Gitlab

* 五 7月 23 2021 Fedora Release Engineering <releng@fedoraproject.org> - 1.8.0-7
- Rebuilt for `https://fedoraproject.org/wiki/Fedora_35_Mass_Rebuild`

* 三 1月 27 2021 Fedora Release Engineering <releng@fedoraproject.org> - 1.8.0-6
- Rebuilt for `https://fedoraproject.org/wiki/Fedora_34_Mass_Rebuild`

* 三 7月 29 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.8.0-5
- Rebuilt for `https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild`

* 五 1月 31 2020 Fedora Release Engineering <releng@fedoraproject.org> - 1.8.0-4
- Rebuilt for `https://fedoraproject.org/wiki/Fedora_32_Mass_Rebuild`
```
```

## 常见问题与解决方案

1. **权限不足**：
   - 问题：普通用户执行安装/升级/删除操作时提示权限不足
   - 解决方案：使用sudo命令获取管理员权限

2. **依赖缺失**：
   - 问题：安装RPM包时提示缺少依赖
   - 解决方案：先安装缺失的依赖包，或使用yum/dnf等高级包管理工具自动解决依赖

3. **版本冲突**：
   - 问题：安装或升级时提示版本冲突
   - 解决方案：先卸载旧版本，或使用--force选项强制安装

4. **文件冲突**：
   - 问题：安装时提示文件已存在
   - 解决方案：检查冲突文件，或使用--replacefiles选项替换

5. **RPM数据库问题**：
   - 问题：RPM命令执行出错，提示数据库错误
   - 解决方案：使用`sudo rpm --rebuilddb`重建RPM数据库
   - 注意事项：
     - 重建RPM数据库时，不要删除旧文件，否则可能导致RPM环境破坏
     - 如果`/var/lib/rpm/`目录下的数据库文件被移除，所有软件都无法被移除或安装
     - 不要对`/var/lib/rpm/`目录本身进行删除或转移操作，否则可能导致RPM彻底无法使用

## 待深入研究

1. RPM包的依赖关系管理机制
2. 如何使用rpmbuild工具制作自定义RPM包
3. yum/dnf与rpm命令的区别与联系
4. RPM包的数字签名验证机制
5. 如何批量管理多个RPM包

## 参考资料

1. [RPM官方文档](http://rpm.org/documentation.html)
2. [Red Hat Enterprise Linux 9 RPM指南](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_software_with_the_rpm_package_manager/index)
3. [CentOS Stream文档](https://docs.centos.org/en-US/centos-stream/)
4. [阿里云镜像站](https://mirrors.aliyun.com/)
5. [Linux命令行大全：RPM包管理](https://linuxcommand.org/lc3_adv_rpm.php)