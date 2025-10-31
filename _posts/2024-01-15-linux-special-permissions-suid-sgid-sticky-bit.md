---
layout: post
title: "Linux特殊权限位详解：SUID、SGID和Sticky Bit"
date: 2024-01-15 10:00:00 +0800
categories: [Linux, 系统管理]
tags: [Linux, 权限管理, SUID, SGID, Sticky Bit, 安全]
---

# Linux特殊权限位详解：SUID、SGID和Sticky Bit

在Linux系统中，除了我们熟悉的读（r）、写（w）、执行（x）权限外，还有三个特殊的权限位：SUID（Set User ID）、SGID（Set Group ID）和Sticky Bit。这些特殊权限位在系统管理和安全配置中扮演着重要角色，正确理解和使用它们对于维护系统安全至关重要。

![Linux特殊权限位示意图](/images/posts/linux/suid/linux_special_permissions.svg)

这个图表直观地展示了三种特殊权限位的基本概念、显示方式和典型特征。接下来，我们将详细介绍每种权限位的工作原理和使用场景。

## 一、SUID（Set User ID）权限位

### 1.1 什么是SUID？

SUID是一种特殊的权限位，当设置在可执行文件上时，无论哪个用户执行该文件，程序都会以文件所有者的身份运行，而不是以执行该程序的用户身份运行。

### 1.2 SUID的显示方式

在`ls -l`命令的输出中，SUID权限位显示为所有者执行权限位上的`s`字符。例如：

```bash
-rwsr-xr-x 1 root root 36000 Jan 10 15:30 /usr/bin/passwd
```

如果文件的所有者原本没有执行权限，但设置了SUID位，则会显示为大写的`S`。

### 1.3 SUID的工作原理

当用户执行一个设置了SUID位的程序时，系统会将进程的有效用户ID（EUID）临时切换为文件所有者的ID，而实际用户ID（RUID）保持不变。这样，程序就获得了文件所有者的权限。

### 1.4 SUID的典型应用场景

SUID最常见的应用场景是允许普通用户执行需要较高权限的操作。例如：

- `/usr/bin/passwd`：允许普通用户修改自己的密码，需要写入`/etc/passwd`或`/etc/shadow`文件
- `/usr/bin/su`：允许用户切换到其他用户账户
- `/usr/bin/sudo`：允许授权用户以其他用户身份执行命令

### 1.5 SUID演示代码

下面是一个演示SUID权限效果的C语言程序：

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    // 获取实际用户ID和有效用户ID
    uid_t real_uid = getuid();
    uid_t effective_uid = geteuid();
    
    printf("实际用户ID (RUID): %d\n", real_uid);
    printf("有效用户ID (EUID): %d\n", effective_uid);
    
    // 演示如何临时放弃特权
    if (real_uid != effective_uid) {
        printf("\n注意：有效用户ID与实际用户ID不同，程序可能设置了SUID位\n");
        
        // 保存有效用户ID，然后临时切换到实际用户ID
        printf("\n临时放弃特权...\n");
        if (seteuid(real_uid) == 0) {
            printf("切换后 - 有效用户ID (EUID): %d\n", geteuid());
            
            // 在这里可以执行非特权操作
            printf("执行非特权操作...\n");
            
            // 恢复特权
            printf("恢复特权...\n");
            if (seteuid(effective_uid) == 0) {
                printf("恢复后 - 有效用户ID (EUID): %d\n", geteuid());
            } else {
                perror("恢复特权失败");
            }
        } else {
            perror("放弃特权失败");
        }
    } else {
        printf("\n有效用户ID与实际用户ID相同，SUID位可能未设置\n");
    }
    
    return 0;
}
```

你可以通过以下步骤编译和测试这个程序：

```bash
# 编译程序
gcc uid_demo.c -o uid_demo

# 设置SUID位（需要root权限）
sudo chown root:root uid_demo
sudo chmod 4755 uid_demo

# 以普通用户身份运行
./uid_demo
```

### 1.6 SUID的工作原理与安全机制深入解析

#### 为什么普通用户不能利用SUID程序做其他事情？

以`/usr/bin/passwd`文件为例，虽然它设置了SUID权限使普通用户能够修改自己的密码，但普通用户为什么不能利用这一点去做其他事情呢？

**核心原因分析：**

- **SUID的本质**：SUID只是把可执行文件的有效UID (EUID) 设置为文件所有者（通常为root），但这只是进程的权限属性，不等同于"把一个交互式root shell交给普通用户"。

- **程序行为受限**：程序行为受限于它本身的代码 —— 只有程序显式执行的操作会以EUID权限发生（例如passwd只实现修改密码所需的文件写入与验证逻辑）。

- **多层安全保护**：
  - 内核与工具链保护：对于setuid程序，动态链接器会忽略LD_PRELOAD/LD_LIBRARY_PATH等环境变量，shell环境也会被清理，避免被注入恶意库或控制流。
  - 文件系统与内核限制：挂载选项（如nosuid）、SELinux/AppArmor、seccomp、CAP_*能力控制等都会限制SUID程序能做的事情。
  - 真实UID（RUID）仍然是调用者的UID，很多操作需要同时满足多种检查或程序主动切换UID（seteuid()/setuid()）。

- **passwd的安全实现**：
  - passwd以EUID=root运行以便写入通常只有root能写的/etc/shadow（或调用PAM接口）。
  - passwd对输入做严格验证，并且不会把控制权交给用户（不会直接spawn一个交互式root shell）。

#### 为什么普通用户不能修改其他用户的密码？

即使passwd程序以EUID=root运行，普通用户仍然不能修改其他用户的密码，这是因为：

- **程序内部权限检查**：EUID=root只是赋予passwd程序在执行时拥有"写/etc/shadow等受限资源"的能力，但程序本身会做权限检查：只有当调用者是该账户本人（非特权用户修改自己的密码）或程序检测到是以root身份（真实或有效UID为0）运行时，才允许修改指定用户的密码。

- **典型实现逻辑**（伪代码）：
  ```
  if caller是root → 允许修改任意用户的密码（无需当前密码）
  else if caller是target user → 要求输入当前密码并验证，验证通过后只修改该用户的条目
  else → 拒绝
  ```

- **PAM安全框架**：PAM（Pluggable Authentication Modules）和shadow库还会进一步强制策略（是否需要当前密码、密码复杂度、锁定等），并由内核/库确保只能通过受控接口修改密码文件（避免任意写入）。

### 1.7 RUID、EUID和SUID的区别与联系

#### 核心概念定义：

- **RUID（Real UID，真实UID）**
  - 启动进程的用户ID（表示是谁启动了进程）。
  - 用于记录归属，部分安全决策与恢复权限时会用到。

- **EUID（Effective UID，有效UID）**
  - 内核做权限检查（访问文件、打开设备等）时使用的UID。
  - 当可执行文件带有文件SUID位或进程调用seteuid()/setuid()时，EUID会不同于RUID。

- **SUID（Set-user-ID）**
  - **文件层面**：在可执行文件上设置的位（chmod 4755），运行该文件时进程的EUID会被设置为该文件的所有者（常为root）。
  - **进程层面**：POSIX还有Saved UID（保存的UID），用于在切换EUID后能恢复之前的EUID。

#### 完整的UID信息查看演示代码

下面的程序可以查看进程的真实UID、有效UID和保存的UID：

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    uid_t r, e, s;
    if (getresuid(&r, &e, &s) == 0) {
        printf("RUID=%d EUID=%d SUID=%d\n", (int)r, (int)e, (int)s);
    }
    return 0;
}
```

编译和测试步骤与前面相同，可以观察三种UID的区别。

### 1.8 SUID的安全风险

SUID是一个强大但危险的机制，如果使用不当，可能导致严重的安全问题：

- 攻击者可能利用有漏洞的SUID程序提升权限
- 错误配置的SUID程序可能被用来绕过系统安全策略

### 1.9 安全使用SUID的最佳实践

- 仅对必要的程序设置SUID位
- 确保SUID程序的所有者是root或其他特权用户
- 限制SUID程序的写权限，确保只有授权用户可以修改
- 定期审查系统中的SUID程序
- 在编写SUID程序时，遵循最小权限原则，及时放弃特权
- 清理环境变量、禁用不安全的行为，避免exec可被利用

## 二、SGID（Set Group ID）权限位

### 2.1 什么是SGID？

SGID类似于SUID，但它影响的是组权限。当设置在可执行文件上时，程序会以文件所属组的身份运行。当设置在目录上时，该目录中创建的新文件和目录将继承该目录的组所有权。

### 2.2 SGID的显示方式

在`ls -l`命令的输出中，SGID权限位显示为组执行权限位上的`s`字符。例如：

```bash
-rwxr-sr-x 1 root staff 10240 Jan 10 15:30 /usr/bin/wall
```

对于目录：

```bash
drwxr-sr-x 2 root shared 4096 Jan 10 15:30 shared_dir
```

### 2.3 SGID的工作原理

- **对可执行文件**：当用户执行设置了SGID位的程序时，进程的有效组ID（EGID）会被设置为文件所属组的ID
- **对目录**：在设置了SGID位的目录中创建的新文件和目录，其组所有权将继承该目录的组所有权，而不是创建者的有效组ID

### 2.4 SGID的应用场景

- **可执行文件**：允许程序以特定组的权限访问资源，如`wall`命令以`tty`组权限运行
- **目录**：在多用户协作环境中，确保团队成员创建的文件自动属于团队组，方便共享

### 2.5 SGID演示代码

以下是一个演示SGID效果的程序：

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // 获取实际组ID和有效组ID
    gid_t real_gid = getgid();
    gid_t effective_gid = getegid();
    
    printf("实际组ID (RGID): %d\n", real_gid);
    printf("有效组ID (EGID): %d\n", effective_gid);
    
    // 演示SGID目录行为
    if (argc > 1) {
        char *dir_path = argv[1];
        char file_path[256];
        
        // 构造文件路径
        snprintf(file_path, sizeof(file_path), "%s/test_file.txt", dir_path);
        
        printf("\n尝试在目录 %s 中创建文件...\n", dir_path);
        
        // 创建一个测试文件
        int fd = open(file_path, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fd != -1) {
            const char *content = "这是一个测试文件，用于演示SGID目录的行为。\n";
            write(fd, content, strlen(content));
            close(fd);
            printf("文件已创建: %s\n", file_path);
            printf("请使用 'ls -l %s' 检查文件的组所有权\n", file_path);
        } else {
            perror("创建文件失败");
        }
    } else {
        printf("\n用法: %s <sgid_dir_path>\n", argv[0]);
        printf("请提供一个设置了SGID位的目录路径\n");
        return 1;
    }
    
    return 0;
}
```

### 2.6 如何设置SGID

- **设置文件的SGID**：`chmod g+s filename` 或 `chmod 2755 filename`
- **设置目录的SGID**：`chmod g+s directory` 或 `chmod 2775 directory`

## 三、Sticky Bit权限位

### 3.1 什么是Sticky Bit？

Sticky Bit（粘着位）主要用于目录，它限制了删除操作：在设置了Sticky Bit的目录中，只有文件的所有者、目录的所有者或root用户才能删除、重命名或移动文件，即使其他用户对该目录具有写权限。

### 3.2 Sticky Bit的显示方式

在`ls -l`命令的输出中，Sticky Bit显示为其他用户执行权限位上的`t`字符。例如：

```bash
drwxrwxrwt 10 root root 4096 Jan 10 15:30 /tmp
```

### 3.3 Sticky Bit的工作原理

当目录设置了Sticky Bit后，Linux内核会在执行删除、重命名或移动操作时进行额外的检查，确保操作执行者有权限执行这些操作。

### 3.4 Sticky Bit的典型应用场景

- `/tmp`和`/var/tmp`目录：这些是系统临时目录，所有用户都可以写入，但不应该允许用户删除其他用户的文件
- 多用户共享目录：确保用户只能管理自己的文件

### 3.5 Sticky Bit演示脚本

以下是一个演示Sticky Bit效果的Shell脚本：

```bash
#!/bin/bash

# Sticky Bit 演示脚本
# 这个脚本演示了在设置了Sticky Bit的目录中，用户只能删除自己的文件

echo "=== Sticky Bit 演示脚本 ==="
echo

# 创建测试目录
TEST_DIR="sticky_test_dir"
echo "1. 创建测试目录: $TEST_DIR"
mkdir -p $TEST_DIR

# 设置目录权限为777（所有用户可读、可写、可执行）
echo "2. 设置目录权限为777"
chmod 777 $TEST_DIR

echo "3. 当前目录权限:"
ls -ld $TEST_DIR

# 创建几个测试文件，模拟不同用户创建的文件
echo "4. 在目录中创建测试文件（模拟不同用户）"
echo "文件内容 - 由用户A创建" > $TEST_DIR/file_by_userA.txt
echo "文件内容 - 由用户B创建" > $TEST_DIR/file_by_userB.txt
echo "文件内容 - 由用户C创建" > $TEST_DIR/file_by_userC.txt

echo "5. 目录中的文件列表:"
ls -l $TEST_DIR

# 演示没有Sticky Bit时的情况
echo "\n=== 没有Sticky Bit的情况 ==="
echo "6. 尝试删除其他用户的文件（没有Sticky Bit时）"
# 在真实环境中，这取决于文件权限和用户权限
# 这里我们只是模拟这个行为
echo "注意：在真实环境中，没有Sticky Bit时，具有写权限的用户可以删除其他用户的文件"

# 设置Sticky Bit
echo "\n=== 设置Sticky Bit后 ==="
echo "7. 设置Sticky Bit:"
chmod +t $TEST_DIR

echo "8. 设置Sticky Bit后的目录权限:"
ls -ld $TEST_DIR
echo "注意：现在权限显示末尾有't'，表示已设置Sticky Bit"

echo "\n9. Sticky Bit效果说明:"
echo "   - 在设置了Sticky Bit的目录中，用户只能删除/重命名/移动自己拥有的文件"
echo "   - 即使目录权限是777，用户也不能删除其他用户的文件"
echo "   - 只有目录的所有者或root用户可以删除任何文件"

echo "\n10. 常见的Sticky Bit使用场景:"
echo "    - /tmp目录：通常设置为1777权限（rwxrwxrwt）"
echo "    - /var/tmp目录：也常设置Sticky Bit"
echo "    - 共享工作目录：多用户协作环境"
```

### 3.6 如何设置Sticky Bit

- **设置目录的Sticky Bit**：`chmod +t directory` 或 `chmod 1777 directory`

## 四、特殊权限位的八进制表示

在使用`chmod`命令设置权限时，可以使用八进制数字来表示特殊权限位：

- SUID: 4（二进制：100）
- SGID: 2（二进制：010）
- Sticky Bit: 1（二进制：001）

这些数字与普通权限数字（r=4, w=2, x=1）结合使用，放在权限数字的最前面。例如：

- `chmod 4755 file`：设置SUID，同时设置普通权限为所有者可读写执行，组和其他用户可读执行
- `chmod 2775 directory`：设置SGID，同时设置普通权限为所有者可读写执行，组可读写执行，其他用户可读执行
- `chmod 1777 directory`：设置Sticky Bit，同时设置普通权限为所有用户可读写执行

## 五、安全注意事项

### 5.1 SUID/SGID的安全风险

- **权限提升**：如果SUID程序存在安全漏洞，攻击者可能利用它获取root权限
- **权限滥用**：不当配置的SUID/SGID程序可能被用于执行未授权操作
- **维护困难**：过多的SUID/SGID程序会增加系统管理和安全审计的难度

### 5.2 安全审计

定期检查系统中的SUID/SGID程序是安全管理的重要部分：

```bash
# 查找所有SUID程序
sudo find / -perm -4000 -type f -ls

# 查找所有SGID程序
sudo find / -perm -2000 -type f -ls

# 查找所有设置了Sticky Bit的目录
sudo find / -perm -1000 -type d -ls
```

### 5.3 最佳实践

- **最小权限原则**：只在必要时使用特殊权限位
- **定期审查**：定期检查系统中的特殊权限设置
- **使用sudo替代**：对于临时需要特权的操作，优先使用sudo而非设置SUID
- **文件完整性监控**：监控SUID/SGID文件的变更
- **禁用不必要的SUID/SGID程序**：对于不需要的SUID/SGID程序，移除特殊权限位

## 六、总结

特殊权限位（SUID、SGID和Sticky Bit）是Linux权限系统中的重要组成部分，它们提供了灵活的权限控制机制，但同时也带来了潜在的安全风险。

SUID只是让指定程序在执行时拥有额外的有效权限；是否能"做其他事"取决于程序本身是否把那种能力暴露出来，以及内核/安全机制是否允许这种行为。好的SUID程序设计会严格限制权限的使用范围，确保即使以root权限运行也只能执行特定的功能。

SGID为多用户协作提供了便利，特别是在共享目录场景下，能够确保新建文件自动继承目录的组所有权。

Sticky Bit则为多用户环境提供了额外的安全保障，确保用户只能管理自己的文件，即使在权限为777的目录中也是如此。

在实际应用中，我们应该始终遵循最小权限原则，定期审查系统中的特殊权限设置，并采取必要的安全措施来防止权限滥用和提升。

通过本文的介绍，相信你已经对Linux特殊权限位有了深入的理解，可以在实际工作中更加安全、有效地使用它们。

## 参考资料

1. Linux man pages: chmod(1), stat(2), getuid(2), setuid(2)
2. Linux Programmer's Manual: Permissions
3. 《Linux系统管理技术手册》
4. 《鸟哥的Linux私房菜》