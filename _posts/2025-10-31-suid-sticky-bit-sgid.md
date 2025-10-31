---
layout: post
title: 关于特殊权限位suid,sgid,sticky bit的详细介绍
categories: [linux, security]
description: 深入解析Linux系统中的特殊权限位SUID、SGID和Sticky Bit，包括它们的工作原理、安全机制和实际应用案例
keywords: suid, sgid, sticky bit, linux权限, 特殊权限位
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

# 关于特殊权限位suid,sgid,sticky bit的详细介绍

在Linux系统中，除了常见的读（r）、写（w）、执行（x）权限外，还有三个特殊的权限位：SUID、SGID和Sticky Bit。这些特殊权限位在系统安全和权限管理中扮演着重要的角色。本文将详细解析这些特殊权限位的工作原理、安全机制和实际应用。

## 一、SUID权限的工作原理与安全限制

### 普通用户为啥不能去做其他事情，既然已经获得了root的身份

以`/usr/bin/passwd`文件为例，Linux系统中的该文件具有SUID权限。这使得普通用户能够修改自己的密码，因为passwd程序在执行时会暂时获得root权限，从而能够写入只有root才能访问的`/etc/shadow`文件。但普通用户为什么不能利用这一点去做其他事情呢？

#### 核心原因分析：

- **SUID的本质**：SUID只是把可执行文件的有效UID (EUID) 设置为文件所有者（通常为root），所以运行该程序时程序的EUID暂时是root。但这只是进程的权限属性，不等同于"把一个交互式root shell交给普通用户"。

- **程序行为受限**：程序行为受限于它本身的代码 —— 只有程序显式执行的操作会以EUID权限发生（例如passwd只实现修改密码所需的文件写入与验证逻辑）。

- **多层安全保护**：
  - 内核与工具链保护：对于setuid程序，动态链接器会忽略LD_PRELOAD/LD_LIBRARY_PATH等环境变量，shell环境也会被清理，避免被注入恶意库或控制流。
  - 文件系统与内核限制：挂载选项（如nosuid）、SELinux/AppArmor、seccomp、CAP_*能力控制等都会限制SUID程序能做的事情。
  - 真实UID（RUID）仍然是调用者的UID，很多操作需要同时满足多种检查或程序主动切换UID（seteuid()/setuid()）。

- **passwd的安全实现**：
  - passwd以EUID=root运行以便写入通常只有root能写的/etc/shadow（或调用PAM接口）。
  - passwd对输入做严格验证，并且不会把控制权交给用户（不会直接spawn一个交互式root shell）。

#### 如何查看和验证SUID权限：

```bash
# 查看passwd的SUID位
ls -l /usr/bin/passwd     # 通常显示 -rwsr-xr-x（s表示SUID）

# 列出系统中所有SUID文件
find / -perm -4000 -type f 2>/dev/null
```

#### 代码演示：SUID程序中的RUID与EUID差异

下面的C程序可以演示运行SUID程序时的真实UID和有效UID差异：

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("RUID=%d EUID=%d\n", (int)getuid(), (int)geteuid());
    return 0;
}
```

**编译与测试步骤**（需要root权限设置SUID）：
```bash
gcc demo.c -o demo
sudo chown root:root demo
sudo chmod 4755 demo
./demo    # 普通用户运行会看到RUID和EUID的差异
```

## 二、权限控制机制：为什么普通用户不能修改其他用户的密码

### 那是怎么做到不去更改其他用户的密码的，既然passwd只是用来改密码，他可以改root的密码吗

即使passwd程序以EUID=root运行，普通用户仍然不能修改其他用户的密码，这是因为：

- **程序内部权限检查**：EUID=root只是赋予passwd程序在执行时拥有"写/etc/shadow等受限资源"的能力，但程序本身会做权限检查：只有当调用者是该账户本人（非特权用户修改自己的密码）或程序检测到是以root身份（真实或有效UID为0）运行时，才允许修改指定用户的密码。

- **典型实现逻辑**（伪代码）：
  ```
  if caller是root → 允许修改任意用户的密码（无需当前密码）
  else if caller是target user → 要求输入当前密码并验证，验证通过后只修改该用户的条目
  else → 拒绝
  ```

- **PAM安全框架**：PAM（Pluggable Authentication Modules）和shadow库还会进一步强制策略（是否需要当前密码、密码复杂度、锁定等），并由内核/库确保只能通过受控接口修改密码文件（避免任意写入）。

- **权限验证示例**：
  ```bash
  # 查看shadow权限
  ls -l /etc/shadow
  
  # 普通用户尝试改别人的密码会被拒绝
  passwd otheruser  # permission denied（或提示需要root）
  
  # 以root改密码
  sudo passwd root  # root可以直接修改任意账户密码
  ```

## 三、SUID、EUID、RUID的区别与联系

### SUID，EUID, RUID的区别和解释

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

#### 安全的SUID程序设计原则：

- 做权限检查（判断调用者是不是目标用户或root）；
- 在不需要提升时降回普通权限（seteuid(RUID)等）；
- 清理环境变量、禁用不安全的行为，避免exec可被利用；
- 受内核、安全模块（SELinux/AppArmor）和挂载选项（nosuid）限制。

#### 代码演示：完整的UID信息查看

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

## 四、总结

SUID只是让指定程序在执行时拥有额外的有效权限；是否能"做其他事"取决于程序本身是否把那种能力暴露出来，以及内核/安全机制是否允许这种行为。好的SUID程序设计会严格限制权限的使用范围，确保即使以root权限运行也只能执行特定的功能。

如果SUID程序存在设计或实现缺陷（例如缓冲区溢出、不安全的system()调用、路径遍历等），就可能被利用为提权入口。因此，系统管理员需要定期审计系统中的SUID文件，确保没有不必要或存在漏洞的SUID程序。

理解SUID、EUID和RUID的工作原理对于系统安全管理和程序设计都至关重要，它是Linux权限模型中非常精巧的一部分。

