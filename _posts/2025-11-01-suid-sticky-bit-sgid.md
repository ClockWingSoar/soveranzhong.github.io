---
layout: post
title: suid, sticky bit, sgid usage
categories: [Linux]
description: 关于特殊权限位suid,sgid,sticky bit的详细介绍
keywords: linux, suid, sgid, sticky bit
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

# 关于特殊权限位suid,sgid,sticky bit的详细介绍
## 普通用户为啥不能去做其他事情，既然已经获得了root的身份

以/usr/bin/passwd文件为例，Linux系统中的/usr/bin/passwd文件就具有SUID权限。这使得普通
用户能够修改自己的密码，因为passwd程序在执行时会暂时获得root权限，从而能够写入只有root才能访问
的/etc/shadow文件
那普通用户为啥不能去做其他事情，既然已经获得了root的身份

简短回答要点：

- SUID 是把可执行文件的有效 UID (EUID) 设置为文件所有者（通常为 root），所以运行该程序时程序的 EUID 暂时是 root。但这只是进程的权限属性，不等同于“把一个交互式 root shell 交给普通用户”。
- 普通用户不能“做其他事”的原因：
  - 程序行为受限于它本身的代码 —— 只有程序显式执行的操作会以 EUID 权限发生（例如 passwd 只实现修改密码所需的文件写入与验证逻辑）。
  - 内核与工具链保护：对于 setuid 程序，动态链接器会忽略 LD_PRELOAD/LD_LIBRARY_PATH 等环境变量，shell 环境也会被清理，避免被注入恶意库或控制流。
  - 文件系统与内核限制：挂载选项（如 nosuid）、SELinux/AppArmor、seccomp、CAP_* 能力控制等都会限制 SUID 程序能做的事情。
  - 真实 UID（RUID）仍然是调用者的 UID，很多操作需要同时满足多种检查或程序主动切换 UID （seteuid()/setuid()），程序通常会在完成需要的提升后降回普通权限。
- passwd 的实现要点：
  - passwd 以 EUID=root 运行以便写入通常只有 root 能写的 /etc/shadow（或调用 PAM 接口）。
  - passwd 对输入做严格验证，并且不会把控制权交给用户（不会直接 spawn 一个交互式 root shell）。如果 passwd 有安全漏洞（例如调用 system() 且使用不安全参数），就可能被利用进行提权。
- 如果想查看或验证：
  - 查看权限： ls -l /usr/bin/passwd  （通常显示 -rwsr-xr-x）
  - 列出系统中所有 SUID 文件：
    ```bash
    find / -perm -4000 -type f 2>/dev/null
    ```
  - 简单 C 程序演示 RUID/EUID（编译后对可执行文件设置 SUID 来测试）：
    ```c
    #include <stdio.h>
    #include <unistd.h>

    int main(void) {
        printf("RUID=%d EUID=%d\n", (int)getuid(), (int)geteuid());
        return 0;
    }
    ```
    编译：gcc demo.c -o demo  
    设置 SUID（需 root）：sudo chown root:root demo && sudo chmod 4755 demo  
    运行普通用户时可见 RUID/ EUID 差异。

总结：SUID 只是让指定程序在执行时拥有额外的有效权限；是否能“做其他事”取决于程序本身是否把那种能力暴露出来，以及内核/安全机制是否允许这种行为。若 SUID 程序存在设计或实现缺陷，则可能被利用为提权入口。
要点说明（简短）：

## 那是怎么做到不去更改其他用户的密码的，既然passwd只是用来改密码，他可以改root的密码吗

- EUID=root 只是赋予 passwd 程序在执行时拥有“写 /etc/shadow 等受限资源”的能力，但程序本身会做权限检查：只有当调用者是该账户本人（非特权用户修改自己的密码）或程序检测到是以 root 身份（真实或有效 UID 为 0）运行时，才允许修改指定用户的密码。也就是说 passwd 会核对目标用户名与调用者身份／权限，未经授权会拒绝操作。
- 常见实现逻辑（伪代码）：
  - 如果 caller 是 root → 允许修改任意用户的密码（无需当前密码）。
  - 否则如果 caller 是 target user → 要求输入当前密码并验证，验证通过后只修改该用户的条目。
  - 否则 → 拒绝。
- PAM（Pluggable Authentication Modules）和 shadow 库还会进一步强制策略（是否需要当前密码、密码复杂度、锁定等），并由内核/库确保只能通过受控接口修改密码文件（避免任意写入）。
- 因此普通用户不能随便改别人的密码，也不能直接改 root 的密码（除非使用 sudo/以 root 执行 passwd，或者系统有 passwd 的安全漏洞被利用）。
- 验证方法：
  - 查看 shadow 权限： ls -l /etc/shadow
  - 普通用户尝试改别人的密码会被拒绝： passwd otheruser → permission denied（或提示需要 root）。
  - 以 root 改密码： sudo passwd root（root 可以直接修改任意账户密码）。

总结：SUID 只是给程序必要的能力，但程序的行为（检查、验证、受限接口）决定了普通用户只能用它做“被设计允许”的事情（例如修改自己的密码），不能任意以 root 身份做其他操作，除非程序有漏洞或你实际以 root 身份运行它。

## SUID， EUID, RUID的区别和解释
简短说明 — 区别与要点：

- RUID（Real UID，真实 UID）
  - 启动进程的用户 ID（表示是谁启动了进程）。
  - 用于记录归属，部分安全决策与恢复权限时会用到。

- EUID（Effective UID，有效 UID）
  - 内核做权限检查（访问文件、打开设备等）时使用的 UID。
  - 当可执行文件带有文件 SUID 位或进程调用 seteuid()/setuid() 时，EUID 会不同于 RUID。

- SUID（Set-user-ID，既指文件权限位，也常指“保存的 UID”）
  - 文件层面：在可执行文件上设置的位（chmod 4755），运行该文件时进程的 EUID 会被设置为该文件的所有者（常为 root）。例如 /usr/bin/passwd 的文件 SUID 使得运行 passwd 的进程 EUID=0，从而能写 /etc/shadow。
  - 进程层面：POSIX 还有 Saved UID（保存的 UID），用于在切换 EUID 后能恢复之前的 EUID（getresuid 可以读取 real,effective,saved）。

为什么普通用户不能滥用 SUID 程序做任意事情（以 passwd 为例）
- SUID 只改变进程的 EUID，实际能做什么由程序的代码决定。passwd 只实现修改密码的受控逻辑（验证当前用户/密码策略、写入 shadow），不会给用户一个交互式 root shell。
- 好的 SUID 程序会：
  - 做权限检查（判断调用者是不是目标用户或 root）；
  - 在不需要提升时降回普通权限（seteuid(RUID) 等）；
  - 清理环境变量、禁用不安全的行为，避免 exec 可被利用；
  - 受内核、安全模块（SELinux/AppArmor）和挂载选项（nosuid）限制。
- 如果 SUID 程序存在漏洞（缓冲区溢出、错误的 system()/popen 使用、不安全的路径处理等），就可能被利用进行提权。

快速演示（查看/验证 / 示例代码）

- 查看 passwd 的 SUID 位：
```bash
ls -l /usr/bin/passwd     # 通常显示 -rwsr-xr-x（s 表示 SUID）
```

- 列出系统上的 SUID 文件：
```bash
find / -perm -4000 -type f 2>/dev/null
```

- 使用 ps 查看某进程的真实/有效用户（示例）：
```bash
ps -o pid,ruser,euser,cmd -p <pid>
```

- 小 C 程序打印 real/effective/saved UID（编译后设置 SUID 可观察差异）：

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


编译与测试（需要 root 权限设置 SUID）：

```bash
gcc demo.c -o demo
sudo chown root:root demo
sudo chmod 4755 demo
./demo    # 普通用户运行会看到 RUID=你的UID EUID=0 SUID=0（或文件所有者 UID）
```

要点总结：
- RUID 标识谁启动了进程；EUID 决定进程可以做什么；文件 SUID 位会使执行该文件时进程的 EUID 变为文件所有者（通常是 root）。
- 控制权在程序本身：只要程序没有把任意执行权交给用户，普通用户就只能通过该程序做设计允许的事情。若程序有缺陷，则可能被利用提权。

