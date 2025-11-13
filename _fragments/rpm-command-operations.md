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

12. **如何验证RPM包的签名和完整性？**
    - 验证RPM包的签名和完整性：`rpm -K package.rpm` 或 `rpm --checksig package.rpm`

13. **如何管理RPM GPG密钥？**
    - 查看系统中的GPG密钥：`rpm -qa "gpg-pubkey"`
    - 查看GPG密钥详情：`rpm -qi gpg-pubkey-<keyid>`
    - 导入GPG密钥：`sudo rpm --import /path/to/keyfile`
    - 删除GPG密钥：`sudo rpm -e gpg-pubkey-<keyid>`

14. **如何验证已安装RPM包的完整性？**
    - 验证已安装包的完整性：`rpm -V package_name` 或 `rpm --verify package_name`

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
- **签名验证**：验证RPM包的完整性和来源
  - `-K, --checksig`：验证RPM包的数字签名和摘要信息
- **GPG密钥管理**：管理用于验证RPM包签名的GPG密钥
  - `--import`：导入GPG公钥到RPM数据库
  - `-qa "gpg-pubkey"`：查询系统中已安装的GPG公钥
  - `-qi gpg-pubkey-<keyid>`：查看特定GPG公钥的详细信息
  - `-e gpg-pubkey-<keyid>`：从系统中删除指定的GPG公钥
- **包验证**：验证已安装RPM包的完整性和文件状态
  - `-V, --verify`：验证已安装包的所有文件的完整性、权限、大小等属性
    - 输出中的符号表示文件的不同属性是否发生变化
    - 常见符号：`c`表示配置文件，`?`表示无法验证的属性

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

### 3. 验证RPM包的签名和完整性

使用`rpm -K`或`rpm --checksig`命令验证RPM包的签名和完整性：

```bash
[root@rocky9 ~]# rpm -K /tmp/softs/vsftpd-3.0.3-49.el9.x86_64.rpm
/tmp/softs/vsftpd-3.0.3-49.el9.x86_64.rpm: digests SIGNATURES 不正确
```

### 4. RPM GPG密钥管理

使用RPM命令管理GPG密钥：

```bash
# 查看系统中的GPG密钥文件
ls /etc/pki/rpm-gpg/
RPM-GPG-KEY-redhat-beta  RPM-GPG-KEY-redhat-release  RPM-GPG-KEY-Rocky-9  RPM-GPG-KEY-Rocky-9-Testing

# 普通用户尝试导入GPG密钥（失败，权限不足）
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
错误：无法创建 事务 锁定于 /var/lib/rpm/.rpm.lock (没有那个文件或目录)
错误：/etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9：导入密钥 1 失败。

# 使用sudo权限导入GPG密钥（成功）
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9

# 查看系统中已安装的GPG公钥
rpm -qa "gpg-pubkey"
gpg-pubkey-350d275d-6279464b

# 查看GPG密钥详情
rpm -qi gpg-pubkey-350d275d-6279464b
Name        : gpg-pubkey
Version     : 350d275d
Release     : 6279464b
Architecture: (none)
Install Date: 2025年10月31日 星期五 21时55分52秒
Group       : Public Keys
Size        : 0
License     : pubkey
Signature   : (none)
Source RPM  : (none)
Build Date  : 2022年05月10日 星期二 00时50分19秒
Build Host  : localhost
Packager    : Rocky Enterprise Software Foundation - Release key 2022 <releng@rockylinux.org>
Summary     : Rocky Enterprise Software Foundation - Release key 2022 <releng@rockylinux.org> public key
Description :
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: rpm-4.16.1.3 (NSS-3)

mQINBGJ5RksBEADF/Lzssm7uryV6+VHAgL36klyCVcHwvx9Bk853LBOuHVEZWsme
kbJF3fQG7i7gfCKGuV5XW15xINToe4fBThZteGJziboSZRpkEQ2z3lYcbg34X7+d
co833lkBNgz1v6QO7PmAdY/x76Q6Hx0J9yiJWd+4j+vRi4hbWuh64vUtTd7rPwk8
```

### 5. 安装RPM包

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

### 6. 升级RPM包

使用`rpm -Uvh`命令升级RPM包：

```bash
# 升级vsftpd到3.0.5版本
sudo rpm -Uvh vsftpd-3.0.5-6.el9.x86_64.rpm

# 降级vsftpd到3.0.3版本（需要管理员权限）
sudo rpm -Uvh vsftpd-3.0.3-49.el9.x86_64.rpm
```

### 7. 删除RPM包

使用`rpm -evh`命令删除RPM包：

```bash
# 删除vsftpd包（普通用户）
rpm -evh vsftpd

# 删除vsftpd包（管理员权限）
sudo rpm -evh vsftpd
```

### 8. 查询RPM包信息

使用各种查询命令获取RPM包信息：

```bash
# 查询vsftpd是否已安装
sudo rpm -q vsftpd

# 条件删除：如果vsftpd已安装则删除
rpm -q vsftpd && rpm -evh vsftpd

# 使用-Fvh选项升级（只升级已安装的包）
rpm -Fvh vsftpd-3.0.3-49.el9.x86_64.rpm

# 再次安装vsftpd 3.0.3版本（未验证签名）
sudo rpm -Uvh vsftpd-3.0.3-49.el9.x86_64.rpm
警告：vsftpd-3.0.3-49.el9.x86_64.rpm: 头V3 RSA/SHA256 Signature, 密钥 ID 8483c65d: NOKEY
Verifying...                          ################################# [100%]
准备中...                          ################################# [100%]
正在升级/安装...
   1:vsftpd-3.0.3-49.el9              ################################# [100%]

# 验证已安装的vsftpd包的完整性
sudo rpm -V vsftpd
..?......  c /etc/vsftpd/ftpusers
..?......  c /etc/vsftpd/user_list
..?......  c /etc/vsftpd/vsftpd.conf

# 查看验证命令的退出码
echo $?
1

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

6. **RPM包签名验证失败**：
   - 问题：执行`rpm -K`验证包签名时提示"digests SIGNATURES 不正确"
   - 可能原因：包文件损坏、来源不可信、签名密钥未导入
   - 解决方案：
     - 重新下载包文件并再次验证
     - 检查包的来源是否可信
     - 如果确认包来源安全，可以使用`--nosignature`选项跳过签名验证进行安装

7. **GPG密钥导入失败**：
   - 问题：执行`rpm --import`时提示"无法创建 事务 锁定于 /var/lib/rpm/.rpm.lock (没有那个文件或目录)"
   - 原因：没有足够的权限操作RPM数据库
   - 解决方案：使用`sudo`命令以管理员权限执行密钥导入操作

8. **包验证失败**：
   - 问题：执行`rpm -V`验证已安装包时显示文件属性变化，退出码为1
   - 可能原因：
     - 配置文件被修改（正常情况，显示为`c`标记）
     - 文件权限、大小、修改时间等属性发生变化
     - 文件内容被篡改（需要警惕）
   - 解释：
     - 输出格式：`..?......  c /path/to/file`
     - 符号含义：`c`表示配置文件，`?`表示无法验证的属性
     - 退出码1表示发现变化，0表示所有文件验证通过
   - 解决方案：
     - 配置文件变化通常是正常的，可以忽略
     - 非配置文件变化需要检查是否有异常修改

## 待深入研究

1. RPM包的依赖关系管理机制
2. 如何使用rpmbuild工具制作自定义RPM包
3. yum/dnf与rpm命令的区别与联系
4. RPM包的数字签名验证机制
5. 如何批量管理多个RPM包

## 更新说明

本次对RPM命令操作详解与实践文档的主要更新内容如下：

1. **命令详解完善**：新增了RPM包下载、安装、升级、删除和查询等操作的详细命令说明，覆盖了常用的RPM命令选项。
2. **关键概念澄清**：明确了RPM包管理的核心概念，包括安装、升级、删除、查询、数据库管理、签名验证等。
3. **实践案例丰富**：添加了基于Rocky Linux 9环境的实际操作示例，包括RPM数据库管理、包下载、签名验证、密钥管理、安装升级删除操作、各种查询命令的使用等。
4. **问题解决方案**：整理了RPM包管理过程中常见的权限不足、依赖缺失、版本冲突、文件冲突、数据库问题、签名验证失败、密钥导入失败、包验证失败等问题及其解决方案。
5. **深入研究方向**：列出了RPM包依赖关系管理、自定义RPM包制作、yum/dnf与rpm的区别、数字签名验证机制、批量管理等待深入研究的主题。
6. **参考资料更新**：提供了RPM官方文档、Red Hat Enterprise Linux 9 RPM指南、CentOS Stream文档、阿里云镜像站、Linux命令行大全等权威参考资源。

## 参考资料

1. [RPM官方文档](http://rpm.org/documentation.html)
2. [Red Hat Enterprise Linux 9 RPM指南](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/managing_software_with_the_rpm_package_manager/index)
3. [CentOS Stream文档](https://docs.centos.org/en-US/centos-stream/)
4. [阿里云镜像站](https://mirrors.aliyun.com/)
5. [Linux命令行大全：RPM包管理](https://linuxcommand.org/lc3_adv_rpm.php)