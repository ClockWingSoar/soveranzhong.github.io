---
layout: post
title: "Linux基础命令全面总结"
date: 2024-03-10 10:00:00
categories: Linux
permalink: /archivers/linux-essential-commands-guide
tags:
- Linux
- Shell
- 命令行
- 基础操作
---

# Linux基础命令全面总结

Linux命令行是系统管理员和开发者的强大工具。本文将全面总结Linux系统中的核心概念和常用命令，包括通配符、管道、重定向、用户管理、权限控制、文件时间戳、查找命令以及压缩工具的使用方法。

## 1. 通配符、管道和重定向

### 1.1 通配符（Wildcards）

通配符是用于匹配文件名或路径的特殊字符，可以大大提高命令行操作效率：

```bash
# 1. 星号(*)：匹配任意数量的任意字符
ls *.txt  # 列出当前目录下所有.txt文件
ls report-*.pdf  # 列出所有以report-开头的pdf文件

# 2. 问号(?)：匹配单个字符
ls file-?.txt  # 匹配file-1.txt, file-2.txt等，但不匹配file-10.txt
ls report-2024-??-??.pdf  # 匹配2024年任意月份和日期的报告

# 3. 方括号([])：匹配方括号内的任意一个字符
ls file-[123].txt  # 匹配file-1.txt, file-2.txt, file-3.txt
ls image-[a-z].jpg  # 匹配image-a.jpg到image-z.jpg
ls report-[0-9][0-9].txt  # 匹配两位数编号的报告文件

# 4. 花括号({})：扩展生成多个模式
mkdir dir-{1,2,3}  # 创建dir-1, dir-2, dir-3三个目录
touch file-{a,b,c}.txt  # 创建file-a.txt, file-b.txt, file-c.txt三个文件
cp report.txt backup-{$(date +%Y%m%d),latest}.txt  # 创建带日期和latest后缀的备份文件

# 5. 转义字符(\)：用于转义特殊字符
ls file\*.txt  # 匹配文件名中包含*字符的文件，而不是通配符
```

### 1.2 管道（Pipes）

管道允许将一个命令的输出作为另一个命令的输入，实现命令的串联执行：

```bash
# 1. 基本管道操作
ls -la | grep "txt"  # 列出所有文件，然后筛选出包含"txt"的行
ps aux | sort -nrk 3  # 显示进程并按CPU使用率降序排序

# 2. 多管道串联
find /etc -type f -name "*.conf" | grep "network" | wc -l  # 查找网络配置文件并统计数量
cat access.log | grep "404" | awk '{print $7}' | sort | uniq -c | sort -nr  # 分析404错误并统计URL访问次数

# 3. 结合过滤器使用
ls -lh | head -5  # 显示前5个文件的详细信息
df -h | grep -v tmpfs  # 显示磁盘使用情况，排除tmpfs文件系统

# 4. 管道与文本处理
cat file.txt | tr '[:upper:]' '[:lower:]'  # 将文件内容转换为小写
cat log.txt | sed 's/error/warning/g'  # 将日志中的error替换为warning
```

### 1.3 重定向（Redirection）

重定向用于控制命令的输入和输出方向：

```bash
# 1. 标准输出重定向(>)：覆盖文件
ls -la > file_list.txt  # 将ls输出保存到file_list.txt，覆盖原有内容

# 2. 标准输出追加重定向(>>)：追加到文件
echo "New line" >> file_list.txt  # 将文本追加到文件末尾

# 3. 标准错误重定向(2>)：重定向错误输出
ls non_existent_dir 2> error.log  # 将错误信息保存到error.log

# 4. 标准输出和错误重定向(&>)：重定向所有输出
command &> output.log  # 将标准输出和错误都保存到output.log

# 5. 合并标准输出和错误(2>&1)
echo "Normal output" > output.log 2>&1  # 将错误也重定向到output.log

# 6. 标准输入重定向(<)
cat < input.txt  # 从input.txt读取内容作为cat的输入

# 7. Here文档(<<)
cat << EOF > config.txt  # 创建配置文件
line1
line2
line3
EOF

# 8. Here字符串(<<<)
echo "hello" | grep -i "HE"  # 等同于 grep -i "HE" <<< "hello"
```

## 2. Linux用户和用户组管理

### 2.1 用户和用户组的基本概念

- **用户(User)**: 系统中的认证实体，每个用户有唯一的UID
- **用户组(Group)**: 用户的集合，每个组有唯一的GID
- **主组(Primary Group)**: 用户默认所属的组
- **附加组(Supplementary Group)**: 用户额外加入的组

### 2.2 用户管理命令

```bash
# 1. 创建用户
useradd username  # 创建新用户
useradd -m username  # 创建用户并自动创建主目录
useradd -d /path/to/home -s /bin/bash username  # 指定主目录和默认shell
useradd -G group1,group2 username  # 将用户添加到附加组

# 2. 设置/修改密码
passwd username  # 设置用户密码
passwd -l username  # 锁定用户账户
passwd -u username  # 解锁用户账户
passwd -d username  # 删除用户密码

# 3. 修改用户属性
usermod -l new_username old_username  # 修改用户名
usermod -d /new/home/directory username  # 修改用户主目录
usermod -s /bin/zsh username  # 修改用户默认shell
usermod -aG group1,group2 username  # 添加用户到附加组（不覆盖现有组）

# 4. 删除用户
userdel username  # 删除用户但保留主目录
userdel -r username  # 删除用户及其主目录

# 5. 用户信息查看
id username  # 显示用户ID和所属组ID
whoami  # 显示当前登录用户
w  # 显示当前系统中的登录用户
finger username  # 显示用户的详细信息
```

### 2.3 用户组管理命令

```bash
# 1. 创建用户组
groupadd groupname  # 创建新的用户组
groupadd -g 1000 groupname  # 创建指定GID的用户组

# 2. 修改用户组属性
groupmod -n new_groupname old_groupname  # 修改用户组名称
groupmod -g 2000 groupname  # 修改用户组GID

# 3. 删除用户组
groupdel groupname  # 删除用户组（必须确保组中没有用户）

# 4. 管理组成员
gpasswd -a username groupname  # 添加用户到组
gpasswd -d username groupname  # 从组中删除用户
gpasswd -M user1,user2 groupname  # 设置组成员列表（覆盖现有成员）

# 5. 组信息查看
groups username  # 显示用户所属的所有组
cat /etc/group  # 查看所有用户组信息
getent group | grep username  # 查找用户所在的组
```

### 2.4 重要配置文件

```bash
# 1. /etc/passwd：存储用户账户信息
# 格式：username:x:UID:GID:GECOS:home_directory:shell

# 2. /etc/shadow：存储用户密码信息（加密）
# 格式：username:encrypted_password:last_change:min_age:max_age:warn:inactive:expire:flag

# 3. /etc/group：存储用户组信息
# 格式：groupname:x:GID:member1,member2,...

# 4. /etc/gshadow：存储组密码信息（很少使用）
# 格式：groupname:encrypted_password:admin:member1,member2,...
```

## 3. 文件权限管理

### 3.1 权限位基础知识

文件权限由9个字符表示，分为三组，每组三个字符：

```
-rwxr-xr-- 1 user group size date file.txt
│││││││││
││││││││└─ 其他用户(o)的读取权限(r)
│││││││└── 其他用户(o)的写入权限(w)
││││││└─── 其他用户(o)的执行权限(x)
│││││└──── 组用户(g)的读取权限(r)
││││└───── 组用户(g)的写入权限(w)
│││└────── 组用户(g)的执行权限(x)
││└─────── 所有者(u)的读取权限(r)
│└──────── 所有者(u)的写入权限(w)
└───────── 所有者(u)的执行权限(x)
```

### 3.2 权限表示方法

```bash
# 1. 符号表示法
# u: 用户(user) g: 组(group) o: 其他(others) a: 全部(all)
# +: 添加权限 -: 移除权限 =: 设置权限
chmod u+x file.txt  # 给文件所有者添加执行权限
chmod g-w file.txt  # 移除组用户的写入权限
chmod o=rx file.txt  # 设置其他用户只有读取和执行权限
chmod a+r file.txt  # 给所有用户添加读取权限
chmod ug+x,o-r file.txt  # 组合操作：给用户和组添加执行权限，移除其他用户的读取权限

# 2. 数字表示法
# r=4, w=2, x=1, -=0
chmod 644 file.txt  # 设置权限为：所有者读写，组和其他用户只读 (rw-r--r--)
chmod 755 script.sh  # 设置权限为：所有者读写执行，组和其他用户读执行 (rwxr-xr-x)
chmod 700 private.txt  # 设置权限为：只有所有者可以读写执行 (rwx------)
chmod 660 shared.txt  # 设置权限为：所有者和组可以读写，其他用户无权限 (rw-rw----)

# 3. 递归设置权限
chmod -R 755 directory/  # 递归设置目录及其所有内容的权限
chmod -R --reference=file1 file2  # 将file2的权限设置为与file1相同
```

### 3.3 特殊权限

```bash
# 1. SUID (Set User ID)：执行文件时以文件所有者身份运行
chmod u+s /usr/bin/passwd  # 为passwd命令设置SUID权限
ls -l /usr/bin/passwd  # 查看结果：-rwsr-xr-x

# 2. SGID (Set Group ID)：执行文件时以文件所属组身份运行，对目录设置时新文件继承目录组
chmod g+s /var/www/html  # 为Web目录设置SGID
chmod 2755 /var/www/html  # 使用数字表示法设置SGID (2表示SGID)

# 3. Sticky Bit：对目录设置时，只有文件所有者和root可以删除文件
chmod +t /tmp  # 为/tmp目录设置粘滞位
chmod 1777 /tmp  # 使用数字表示法设置粘滞位 (1表示粘滞位)

# 4. 特殊权限的数字表示
# SUID = 4, SGID = 2, Sticky Bit = 1
# 这些数字放在权限数字的前面
chmod 4755 file  # 设置SUID和rwxr-xr-x权限
chmod 2775 dir  # 设置SGID和rwxrwxr-x权限
chmod 1777 dir  # 设置粘滞位和rwxrwxrwx权限
chmod 6775 file  # 同时设置SUID和SGID
```

### 3.4 ACL (访问控制列表)

ACL提供了比标准Linux权限更细粒度的访问控制：

```bash
# 1. 查看文件的ACL
getfacl file.txt  # 显示文件的访问控制列表

# 2. 设置基本ACL
setfacl -m u:username:rwx file.txt  # 给特定用户设置权限
setfacl -m g:groupname:rx file.txt  # 给特定组设置权限
setfacl -m o::r file.txt  # 设置其他用户的权限

# 3. 递归设置ACL
setfacl -R -m u:username:rwx directory/  # 递归设置目录ACL

# 4. 设置默认ACL（影响新创建的文件和目录）
setfacl -d -m u:username:rwx directory/  # 设置默认ACL

# 5. 删除ACL
setfacl -x u:username file.txt  # 删除特定用户的ACL
setfacl -b file.txt  # 删除所有ACL

# 6. 复制ACL
getfacl file1 | setfacl --set-file=- file2  # 将file1的ACL复制到file2

# 7. 查看目录中所有文件的ACL
ls -la | awk '{print $9}' | xargs getfacl
```

### 3.5 权限管理最佳实践

```bash
# 1. 定期检查敏感文件权限
find /etc -type f -perm /6000 -ls  # 查找所有设置了SUID/SGID的文件

# 2. 修复权限
find /path -type f -name "*.sh" -exec chmod 755 {} \;  # 修复脚本权限
find /path -type f -not -perm /100 -exec chmod -x {} \;  # 移除不必要的执行权限

# 3. 备份当前权限
getfacl -R /path > permissions.bak  # 备份目录的ACL权限

# 4. 还原权限
setfacl --restore=permissions.bak  # 从备份还原ACL权限
```

## 4. 文件时间戳

### 4.1 Linux文件的三种时间戳

Linux文件系统维护三种时间戳：

- **atime (Access Time)**: 最后一次访问文件内容的时间
- **mtime (Modify Time)**: 最后一次修改文件内容的时间
- **ctime (Change Time)**: 最后一次修改文件属性（权限、所有者、链接数等）的时间

### 4.2 查看文件时间戳

```bash
# 1. 基本查看
ls -l file.txt  # 默认显示mtime
ls -la file.txt  # 详细列表也显示mtime

# 2. 查看所有三种时间戳
ls -l --time=atime file.txt  # 显示atime
ls -l --time=mtime file.txt  # 显示mtime
ls -l --time=ctime file.txt  # 显示ctime

# 3. 同时显示所有时间戳
stat file.txt  # 显示文件的详细信息，包括所有时间戳

# 4. 格式化为易读形式
date -r file.txt  # 显示文件的mtime，使用date命令格式化
```

### 4.3 修改文件时间戳

```bash
# 1. touch命令的基本用法
touch file.txt  # 更新文件的atime和mtime为当前时间
touch -a file.txt  # 只更新atime
touch -m file.txt  # 只更新mtime

# 2. 设置特定时间
touch -d "2024-01-01 12:00:00" file.txt  # 设置为指定日期时间
touch -t 202401011200 file.txt  # 使用YYYYMMDDhhmm格式

# 3. 参考其他文件的时间戳
touch -r reference.txt target.txt  # 将target.txt的时间戳设置为与reference.txt相同

# 4. 创建空文件并设置时间戳
touch -d "2023-01-01" newfile.txt  # 创建新文件并设置时间戳

# 5. 批量修改时间戳
find /path -type f -name "*.txt" -exec touch {} \;  # 更新所有txt文件的时间戳
find /path -type f -mtime +30 -exec touch -d "2024-01-01" {} \;  # 修改30天前的文件时间戳
```

### 4.4 使用时间戳进行文件查找和管理

```bash
# 1. 根据修改时间查找文件
find /path -type f -mtime 0  # 查找今天修改的文件
find /path -type f -mtime -7  # 查找7天内修改的文件
find /path -type f -mtime +30  # 查找30天前修改的文件
find /path -type f -newermt "2024-01-01"  # 查找2024年1月1日后修改的文件
find /path -type f -newermt "2024-01-01" ! -newermt "2024-02-01"  # 查找2024年1月修改的文件

# 2. 根据访问时间查找
find /path -type f -atime +30  # 查找30天未访问的文件

# 3. 根据状态改变时间查找
find /path -type f -ctime -7  # 查找7天内状态改变的文件

# 4. 比较文件时间
find /path -type f -newer file1.txt  # 查找比file1.txt更新的文件

# 5. 归档长期未访问的文件
find /path -type f -atime +90 -exec tar -rvf archive.tar {} \;  # 将90天未访问的文件添加到归档
```

## 5. find和xargs命令

### 5.1 find命令基础

```bash
# 1. 基本查找
find /path -name "*.txt"  # 按名称查找文件
find /path -type f  # 查找所有普通文件
find /path -type d  # 查找所有目录

# 2. 按大小查找
find /path -size +10M  # 查找大于10MB的文件
find /path -size -100k  # 查找小于100KB的文件
find /path -size 1M  # 查找正好1MB的文件

# 3. 按权限查找
find /path -perm 644  # 查找权限为644的文件
find /path -perm /222  # 查找任何人都有写入权限的文件
find /path -perm -111  # 查找所有人都有执行权限的文件

# 4. 按用户和组查找
find /path -user username  # 查找属于特定用户的文件
find /path -group groupname  # 查找属于特定组的文件
find /path -nouser  # 查找无所有者的文件
find /path -nogroup  # 查找无所属组的文件

# 5. 组合条件查找
find /path -name "*.log" -type f -mtime +7  # 查找7天前的log文件
find /path -name "*.txt" -o -name "*.md"  # 查找txt或md文件
find /path -not -name "*.tmp"  # 查找不是tmp文件的文件
find /path \( -name "*.txt" -o -name "*.md" \) -size +100k  # 查找大于100KB的txt或md文件
```

### 5.2 find的执行命令功能

```bash
# 1. -exec选项（为每个匹配文件执行命令）
find /path -name "*.txt" -exec ls -l {} \;  # 列出找到的txt文件的详细信息
find /path -type f -name "*.old" -exec rm -f {} \;  # 删除所有.old文件

# 2. -exec选项的{} +变体（将所有文件作为参数传递给单个命令）
find /path -name "*.txt" -exec ls -l {} +  # 更高效的方式，只执行一次ls命令

# 3. -ok选项（交互式确认）
find /path -name "*.tmp" -ok rm -f {} \;  # 删除前要求确认

# 4. 使用管道到xargs
find /path -name "*.txt" | xargs ls -l  # 使用xargs处理找到的文件
find /path -name "*.txt" -print0 | xargs -0 ls -l  # 处理包含空格的文件名
```

### 5.3 xargs命令详解

```bash
# 1. 基本用法
ls -1 *.txt | xargs cat  # 连接所有txt文件的内容
ls -1 *.log | xargs grep "error"  # 在所有log文件中搜索error

# 2. 处理特殊文件名
find /path -name "*.txt" -print0 | xargs -0 rm  # 安全删除包含空格的文件
ls "file with spaces.txt" | xargs -I{} cp {} {}.backup  # 使用占位符处理

# 3. 限制参数数量
find /path -type f | xargs -n 5 ls -l  # 每次传递5个文件给ls命令

# 4. 使用占位符
find /path -name "*.txt" | xargs -I{} cp {} {}.backup  # 为每个文件创建备份
find /path -name "*.old" | xargs -I{} mv {} archive/{}  # 移动文件到归档目录

# 5. 并行执行
find /path -name "*.jpg" | xargs -P 4 -I{} convert {} -resize 50% {}.small.jpg  # 并行处理图像

# 6. 与其他命令结合
find /path -name "*.zip" | xargs -I{} unzip {} -d extracted/{}  # 解压所有zip文件
find /path -type f -exec grep -l "pattern" {} \; | xargs wc -l  # 统计包含特定模式的文件行数
```

### 5.4 实用组合示例

```bash
# 1. 查找并修复权限
find /var/www -type f -name "*.php" -exec chmod 644 {} \;  # 修复PHP文件权限
find /var/www -type d -exec chmod 755 {} \;  # 修复目录权限

# 2. 清理临时文件
find /tmp -type f -atime +7 -delete  # 删除7天未访问的临时文件
find /var/log -name "*.log.*" -mtime +30 -exec rm {} \;  # 删除30天前的日志归档

# 3. 磁盘空间分析
find / -type f -size +100M -exec ls -lh {} \; | sort -k5 -hr  # 查找大文件并按大小排序

# 4. 批量重命名
find /path -name "*.jpeg" | xargs -I{} rename 's/\.jpeg$/\.jpg/' {}

# 5. 文件内容分析
find /path -name "*.txt" | xargs grep -l "important" | xargs cat > important_content.txt
```

## 6. 压缩工具使用方法

### 6.1 tar命令（归档）

```bash
# 1. 创建归档
 tar -cvf archive.tar file1 file2 directory/  # 创建tar归档
 tar -czvf archive.tar.gz file1 file2  # 创建gzip压缩的tar归档
 tar -cjvf archive.tar.bz2 file1 file2  # 创建bzip2压缩的tar归档
 tar -cJvf archive.tar.xz file1 file2  # 创建xz压缩的tar归档

# 2. 查看归档内容
 tar -tvf archive.tar  # 列出tar归档中的文件
 tar -tzvf archive.tar.gz  # 列出gzip压缩归档中的文件

# 3. 提取归档
 tar -xvf archive.tar  # 提取tar归档
 tar -xzvf archive.tar.gz  # 提取gzip压缩的tar归档
 tar -xjvf archive.tar.bz2  # 提取bzip2压缩的tar归档
 tar -xJvf archive.tar.xz  # 提取xz压缩的tar归档

# 4. 提取到指定目录
 tar -xvf archive.tar -C /path/to/destination  # 提取到指定目录

# 5. 增量备份
 tar -cvf backup.tar --listed-incremental=backup.snar /path/to/backup  # 创建增量备份

# 6. 排除文件
 tar -czvf archive.tar.gz --exclude="*.tmp" --exclude="/path/to/exclude" /path/to/backup

# 7. 压缩特定文件类型
 find /path -name "*.log" | xargs tar -czvf logs.tar.gz  # 只压缩log文件
```

### 6.2 gzip/gunzip命令

```bash
# 1. 基本压缩
 gzip file.txt  # 压缩文件，生成file.txt.gz，删除原文件
 gzip -c file.txt > file.txt.gz  # 压缩并保留原文件
 gzip -r directory/  # 递归压缩目录中的所有文件

# 2. 压缩级别（1-9，默认为6）
 gzip -1 file.txt  # 最快压缩（压缩率最低）
 gzip -9 file.txt  # 最高压缩率（最慢）

# 3. 解压
 gunzip file.txt.gz  # 解压，生成file.txt，删除压缩文件
 gunzip -c file.txt.gz > file.txt  # 解压并保留压缩文件
 gunzip -r directory/  # 递归解压目录中的所有.gz文件

# 4. 查看压缩文件内容
 zcat file.txt.gz  # 查看压缩文件内容而不解压

# 5. 批量操作
 find /path -name "*.txt" -exec gzip {} \;  # 压缩所有txt文件
 find /path -name "*.gz" -exec gunzip {} \;  # 解压所有gz文件
```

### 6.3 bzip2/bunzip2命令

```bash
# 1. 基本压缩
 bzip2 file.txt  # 压缩文件，生成file.txt.bz2，删除原文件
 bzip2 -c file.txt > file.txt.bz2  # 压缩并保留原文件
 bzip2 -r directory/  # 递归压缩目录中的所有文件

# 2. 压缩级别（1-9，默认为9）
 bzip2 -1 file.txt  # 最快压缩
 bzip2 -9 file.txt  # 最高压缩率

# 3. 解压
 bunzip2 file.txt.bz2  # 解压，生成file.txt，删除压缩文件
 bunzip2 -c file.txt.bz2 > file.txt  # 解压并保留压缩文件
 bunzip2 -r directory/  # 递归解压目录中的所有.bz2文件

# 4. 查看压缩文件内容
 bzcat file.txt.bz2  # 查看压缩文件内容而不解压
```

### 6.4 xz/unxz命令

```bash
# 1. 基本压缩
 xz file.txt  # 压缩文件，生成file.txt.xz，删除原文件
 xz -c file.txt > file.txt.xz  # 压缩并保留原文件
 xz -r directory/  # 递归压缩目录中的所有文件

# 2. 压缩级别（0-9，默认为6）
 xz -0 file.txt  # 最快压缩
 xz -9 file.txt  # 最高压缩率

# 3. 解压
 unxz file.txt.xz  # 解压，生成file.txt，删除压缩文件
 xz -d file.txt.xz  # 等价于unxz
 xz -dc file.txt.xz > file.txt  # 解压并保留压缩文件

# 4. 查看压缩文件内容
 xzcat file.txt.xz  # 查看压缩文件内容而不解压
```

### 6.5 zip/unzip命令

```bash
# 1. 创建ZIP文件
 zip archive.zip file1 file2 directory/  # 创建ZIP归档
 zip -r archive.zip directory/  # 递归压缩目录

# 2. 设置压缩级别（0-9）
 zip -0 archive.zip file1  # 无压缩（仅打包）
 zip -9 archive.zip file1  # 最高压缩率

# 3. 排除文件
 zip -r archive.zip directory/ -x "*.tmp" -x "*/tmp/"

# 4. 解压ZIP文件
 unzip archive.zip  # 解压到当前目录
 unzip archive.zip -d /path/to/destination  # 解压到指定目录
 unzip -l archive.zip  # 列出ZIP文件内容但不解压

# 5. 解压特定文件
 unzip archive.zip file1 file2  # 只解压指定文件

# 6. 密码保护
 zip -e archive.zip file1  # 创建加密ZIP文件
 unzip -P password archive.zip  # 使用密码解压
```

### 6.6 不同压缩工具的比较

```
压缩工具 | 文件扩展名 | 压缩率 | 压缩速度 | 解压速度
---------|------------|--------|----------|----------
tar      | .tar       | 无压缩  | 最快      | 最快
tar+gzip | .tar.gz    | 中      | 中        | 中
tar+bzip2| .tar.bz2   | 高      | 慢        | 中
tar+xz   | .tar.xz    | 最高    | 最慢      | 较慢
zip      | .zip       | 中      | 中        | 中
```

## 7. 总结

本文详细总结了Linux系统中的核心概念和常用命令，包括：

1. **通配符、管道和重定向**：提高命令行操作效率的基础技巧
2. **用户和用户组管理**：系统安全和权限控制的关键
3. **文件权限管理**：包括基本权限、特殊权限和ACL细粒度控制
4. **文件时间戳**：文件访问、修改和状态变更的时间记录与管理
5. **find和xargs命令**：强大的文件查找和批量处理工具
6. **压缩工具**：不同压缩格式和工具的使用方法与比较

掌握这些基础知识和技能，将大大提高您在Linux环境中的工作效率和系统管理能力。