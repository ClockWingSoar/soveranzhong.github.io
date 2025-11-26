---
layout: post
title: "Network Protocols and Communication: An SRE Perspective"
date: 2025-11-23 00:00:00 +0800
categories: [Network, SRE, DevOps]
tags: [tcp-ip, http, dns, troubleshooting, protocols]
---

作为一名 SRE，网络是我们最常打交道但也最容易"背锅"的基础设施。当服务不可用时，"网络抖动"往往成为最万能的借口。但作为专业的可靠性工程师，我们需要深入理解网络协议的底层机制，才能在复杂的分布式系统中快速定位并解决问题。

本文将从 SRE 的视角出发，重新审视网络协议与通信的核心知识。

## 1. 情境 (Situation)

在微服务架构和云原生时代，网络通信不再是简单的客户端到服务器的连接。
- **服务网格 (Service Mesh)**：引入了 Sidecar 代理，增加了网络跳数。
- **容器网络 (CNI)**：Overlay 网络让数据包的封装解封装变得更加复杂。
- **全球负载均衡**：DNS 解析和 Anycast 技术让流量调度变得不可见。

网络已经成为现代分布式系统的"循环系统"，其健康状况直接决定了业务的可用性。

## 2. 冲突 (Conflict)

然而，我们往往陷入了**"网络是可靠的"**这一误区（分布式计算的第一谬误）。
在实际生产环境中：
- **TCP 连接不释放**：导致文件句柄耗尽 (Too many open files)。
- **DNS 解析延迟**：导致服务间调用出现偶发性超时。
- **拥塞控制算法不匹配**：导致高带宽环境下吞吐量上不去。

当这些问题发生时，如果我们只懂 `ping` 和 `telnet`，面对复杂的抓包数据和内核参数将束手无策。

## 3. 问题 (Question)

如何构建一套完整的网络知识体系，并掌握核心的排查工具，从而在遇到"网络问题"时能够给出确凿的证据，而不是模糊的猜测？

## 4. 答案 (Answer)

我们需要从**模型原理**、**核心协议**、**关键状态**和**排查工具**四个维度来掌握网络通信。

### 4.1 模型原理：OSI vs TCP/IP

虽然教科书上常讲 OSI 七层模型，但在 Linux 内核和实际排查中，**TCP/IP 四层模型**更为实用。

| OSI 七层模型 | TCP/IP 四层模型 | 对应协议/工具 | 关注点 (SRE) |
| :--- | :--- | :--- | :--- |
| 应用层 (Application) | **应用层** | HTTP, DNS, SSH | 状态码, 延迟, 业务逻辑 |
| 表示层 (Presentation) | ^ | SSL/TLS, JSON | 证书过期, 序列化错误 |
| 会话层 (Session) | ^ | RPC Session | 连接池管理 |
| 传输层 (Transport) | **传输层** | TCP, UDP | 端口, 滑动窗口, 拥塞控制 |
| 网络层 (Network) | **网络层** | IP, ICMP, BGP | 路由表, MTU, 防火墙 |
| 数据链路层 (Data Link) | **网络接口层** | ARP, MAC, VLAN | 丢包, CRC 错误 |
| 物理层 (Physical) | ^ | 光纤, 网线 | 物理链路中断 |

### 4.2 传输层核心：TCP 的生与死

TCP 是互联网的基石，理解其状态机和端口机制是排查连接问题的关键。

#### TCP端口号机制

TCP端口号是标识网络通信中不同服务或应用的数字，范围从0到65535（2^16-1）。从SRE视角来看，端口号管理直接影响服务的可用性和安全性。

| 端口范围 | 类型 | 用途 | SRE关注点 |
| :--- | :--- | :--- | :--- |
| **0-1023** | 知名端口 (Well-Known Ports) | 固定分配给常见服务，需管理员权限使用 | 服务占用冲突、未授权访问 |
| **1024-49151** | 注册端口 (Registered Ports) | 分配给程序注册使用，权限要求较宽松 | 应用端口规划、冲突排查 |
| **49152-65535** | 动态/私有端口 (Dynamic/Private Ports) | 操作系统动态分配给客户端进程 | 端口耗尽、连接数限制 |

**知名端口示例**：
- 80/tcp: HTTP 服务
- 20-21/tcp: FTP 服务（20数据传输，21命令控制）
- 25/tcp: SMTP 邮件服务
- 443/tcp: HTTPS 加密服务

**常用注册端口**：
- 1433/tcp: SQL Server 数据库
- 1521/tcp: Oracle 数据库
- 3306/tcp: MySQL 数据库
- 11211/tcp/udp: Memcached 缓存

**动态端口管理**：
```bash
# 查看客户端动态端口范围（Linux）
cat /proc/sys/net/ipv4/ip_local_port_range

# 查看非特权用户可使用的起始端口
cat /proc/sys/net/ipv4/ip_unprivileged_port_start

# 查看系统服务端口映射
cat /etc/services
```

**SRE 常见问题**：
- **端口耗尽**：短连接高并发场景下，客户端动态端口不足导致连接失败
- **端口冲突**：同一主机上多个服务尝试使用相同端口
- **权限问题**：非特权用户尝试绑定1023以下端口

#### 三次握手 (The Handshake)


![image-20251125173915440](/images/posts/2025-11-23-network-protocols-communication-sre/三次握手.png)



**SRE 关注点**：
- **SYN Flood 攻击**：如果 Server 收到大量 SYN 但没收到 ACK，`SYN_RCVD` 队列会满。
  - *优化*：开启 `net.ipv4.tcp_syncookies`。
- **连接超时**：如果 Client 发出 SYN 后无响应，可能是防火墙丢包或 Server 没监听。

### TCP连接实战：使用netcat模拟TCP通信

**netcat** (简称 `nc`) 是 SRE 常用的网络工具，可以用来模拟 TCP/UDP 连接，测试端口连通性，甚至作为简单的服务器使用。

#### 安装netcat
```bash
# Rocky/CentOS 系统
yum install -y nc

# Ubuntu/Debian 系统
apt install -y netcat-openbsd
```

#### 模拟TCP连接过程

**1. 服务端监听端口**
在 Rocky 系统 (10.0.0.12) 上启动一个 TCP 监听服务：
```bash
# 监听 222 端口
nc -l 222
```

**2. 客户端发起连接**
在 Ubuntu 系统 (10.0.0.13) 上连接到服务端：
```bash
# 连接到 10.0.0.12 的 222 端口
nc 10.0.0.12 222
```

**3. 双向通信**
连接建立后，双方可以互相发送数据：
```bash
# 在客户端输入
123
333

# 服务端会收到同样的数据，并可以回复
```

**4. 查看TCP连接状态**
在服务端使用 `ss` 命令查看 TCP 连接状态：
```bash
ss -tn
State      Recv-Q Send-Q Local Address:Port  Peer Address:Port
ESTAB      0      0      10.0.0.12:222       10.0.0.13:51760   # 已建立的TCP连接
```

**5. 查看监听状态的TCP端口**
```bash
# 使用 ss 查看所有监听状态的TCP端口
root@rocky9 ~]# ss -tnl
root@ubuntu24:~# ss -tnl
```

**SRE 实战意义**：
- **快速验证端口连通性**：不需要依赖具体服务，直接测试TCP连接
- **模拟服务行为**：在服务开发完成前，可以用netcat模拟服务响应
- **测试防火墙规则**：验证防火墙是否正确放行特定端口的流量
- **调试网络问题**：通过简单的连接测试，定位是网络问题还是服务问题

### TCP连接实战：实际三次握手和四次挥手分析

#### 案例背景
用户在Rocky Linux主机(10.0.0.12)上执行`curl 10.0.0.13`访问Ubuntu主机(10.0.0.13)上的Nginx服务，同时在Ubuntu主机上使用`tcpdump -S -i eth0 tcp port 80`捕获了完整的TCP连接过程（使用`-S`选项显示绝对序列号）。

#### 捕获结果分析

**1. 三次握手过程**

```bash
# 使用tcpdump -S选项捕获的完整三次握手（显示绝对序列号）

# 1. Client(10.0.0.12)发送SYN包，发起连接请求
10:34:35.592313 IP 10.0.0.12.35300 > ubuntu24.http: Flags [S], seq 734385442, win 64240, options [mss 1460,sackOK,TS val 3595154787 ecr 0,nop,wscale 7], length 0 
# 标志位：[S] = SYN (同步序列编号)
# 含义：Client请求建立连接，初始序列号(ISN)=734385442

# 2. Server(ubuntu24)发送SYN+ACK包，同意建立连接
10:34:35.592336 IP ubuntu24.http > 10.0.0.12.35300: Flags [S.], seq 4168948236, ack 734385443, win 65160, options [mss 1460,sackOK,TS val 3255908001 ecr 3595154787,nop,wscale 7], length 0 
# 标志位：[S.] = SYN+ACK (同步+确认)
# 含义：Server同意连接，Server的ISN=4168948236，确认号=Client的ISN+1

# 3. Client发送ACK包，连接建立完成
10:34:35.592868 IP 10.0.0.12.35300 > ubuntu24.http: Flags [.], ack 4168948237, win 502, options [nop,nop,TS val 3595154788 ecr 3255908001], length 0 
# 标志位：[.] = ACK (确认)
# 含义：Client确认收到Server的SYN+ACK，确认号=Server的ISN+1
# 此时TCP连接建立完成，进入ESTABLISHED状态
```

**TCP包各字段详细解释**

| 字段                                   | 含义                         | 详细解释                                                     |
| :------------------------------------- | :--------------------------- | :----------------------------------------------------------- |
| **IP 10.0.0.12.35300 > ubuntu24.http** | 源IP:端口 > 目标IP:端口      | 表示从10.0.0.12的35300端口发送到ubuntu24主机的80端口(HTTP服务) |
| **Flags [S]**                          | TCP标志位                    | `[S]`表示SYN(同步)标志，用于发起TCP连接                      |
| **Flags [S.]**                         | TCP标志位                    | `[S.]`表示SYN+ACK(同步+确认)标志，用于同意建立TCP连接        |
| **Flags [.]**                          | TCP标志位                    | `[.]`表示ACK(确认)标志，用于确认收到数据                      |
| **Flags [P.]**                         | TCP标志位                    | `[P.]`表示PSH+ACK(推送+确认)标志，用于推送数据到应用层        |
| **seq 734385442**                      | 初始序列号(ISN)              | TCP连接的初始序列号，由客户端随机生成，用于确保连接的唯一性和安全性 |
| **seq 734385443:734385516**            | 数据范围                     | 表示此TCP段包含的数据范围，从seq 734385443到734385516（含） |
| **ack 734385443**                      | 确认号                       | 表示期望接收的下一个序列号，确认已收到所有序列号小于该值的数据 |
| **win 64240**                          | 初始通告窗口大小             | 连接建立时客户端发送的原始通告窗口大小，未经过窗口缩放因子调整 |
| **win 502**                            | 通告窗口值                   | 经过窗口缩放协商后，TCP头部中实际携带的窗口值，需要结合wscale计算实际窗口大小 |
| **options**                            | TCP选项字段                  | TCP头部的扩展选项，包含多种控制信息                          |
| **mss 1460**                           | 最大段大小(Max Segment Size) | 表示客户端能够接收的最大TCP段大小为1460字节，通常等于MTU(1500)减去TCP头部(20)和IP头部(20) |
| **sackOK**                             | 选择性确认支持               | 表示客户端支持SACK(Selective Acknowledgment)选项，允许接收方确认不连续的数据段，提高TCP重传效率 |
| **TS val 3595154787 ecr 0**            | 时间戳选项                   | <br>- `TS val`: 发送方的时间戳值，用于RTT(往返时间)计算和防止序列号回绕<br>- `ecr`: 时间戳回显应答，此处为0表示这是连接建立的第一个包 |
| **TS val 3255908001 ecr 3595154787**   | 时间戳选项(应答)             | <br>- `TS val`: 服务端的时间戳值<br>- `ecr`: 回显客户端的时间戳值，用于RTT计算 |
| **nop**                                | 无操作                       | 用于填充TCP选项字段，确保选项字段总长度为4字节的整数倍，便于协议解析和高效处理<br>**多个nop出现的原因**：TCP选项字段必须是4字节对齐的，当其他选项的总长度不是4的倍数时，会插入多个nop来填充<br>**示例分析**：`options [nop,nop,TS val 3595154788 ecr 3255908002]`<br>- TS选项（时间戳）长度为10字节<br>- 加上2个nop（各1字节），总长度=10+2=12字节，正好是4的倍数<br>- 所以需要两个nop来确保4字节对齐 |
| **wscale 7**                           | 窗口缩放因子                 | 表示窗口缩放比例为2^7=128倍，用于扩展TCP接收窗口大小，支持更大的带宽利用率<br>**计算公式**：实际接收窗口大小 = 通告窗口值 × 2^wscale<br>**示例**：<br>- 客户端SYN包：`win 64240, wscale 7` → 实际窗口=64240×128=8,222,720字节<br>- ACK包中的`win 502` → 实际窗口=502×128=64,256字节（接近初始窗口大小） |
| **length 0**                           | 数据长度                     | 表示此TCP段中没有携带应用层数据，仅用于控制目的             |
| **length 73**                          | 数据长度                     | 表示此TCP段中携带的应用层数据长度为73字节                   |

### 窗口缩放机制详解

TCP头部中的窗口字段只有16位，最大只能表示65535字节的窗口大小，这在高速网络环境下会成为瓶颈。为了解决这个问题，TCP引入了窗口缩放(Window Scaling)选项，通过协商一个缩放因子来扩展实际窗口大小。

#### 窗口缩放的工作原理：
1. **协商阶段**：在三次握手的SYN包和SYN+ACK包中，双方通过`wscale`选项协商窗口缩放因子
2. **存储阶段**：协商完成后，双方会存储对方的窗口缩放因子
3. **传输阶段**：在后续的数据传输中，TCP头部的`win`字段携带的是"通告窗口值"，需要结合之前协商的缩放因子计算出实际接收窗口大小
4. **计算阶段**：实际接收窗口大小 = 通告窗口值 × 2^缩放因子

#### 为什么会有`win 502`？
- TCP头部的窗口字段只有16位，最大能表示65535字节
- 当需要表示更大的窗口时，系统会使用缩放因子
- 在示例中，客户端和服务端协商的`wscale 7`意味着缩放比例为128倍
- 当实际窗口大小为64,256字节时，TCP头部中存储的通告窗口值为：64,256 ÷ 128 = 502
- 所以在抓包中看到的`win 502`，经过计算后实际窗口大小是502 × 128 = 64,256字节

#### 窗口缩放的特点：
- 窗口缩放因子只在连接建立时协商，连接期间保持不变
- 缩放因子的范围是0-14（2^14=16384倍），实际窗口大小最大可达65535×16384≈1GB
- 窗口缩放是单向的，客户端和服务端可以协商不同的缩放因子
- 只有在连接建立的SYN包中才能设置`wscale`选项，其他包中该选项无效

#### 窗口值变化的原因：
在TCP连接过程中，`win`值会动态变化，主要受以下因素影响：
1. **应用层消费速度**：如果应用层处理数据慢，接收缓冲区会被填满，窗口值会减小
2. **网络状况**：网络拥塞时，TCP会通过调整窗口大小进行流量控制
3. **系统资源**：系统内存不足时，会减少TCP接收缓冲区大小，导致窗口值减小
4. **初始窗口策略**：不同操作系统有不同的初始窗口策略（如RFC 6928推荐初始窗口为10个MSS）

## TCP确认机制详解

### 确认号计算规则
TCP的确认号(ack)表示**期望接收的下一个序列号**，其计算规则如下：

| 场景 | 确认号计算公式 | 示例 |
| :--- | :--- | :--- |
| **三次握手阶段** | `ack = 对方的seq + 1` | <br>- 客户端SYN包：`seq 734385442`<br>- 服务端SYN+ACK包：`ack 734385443 = 734385442 + 1` |
| **数据传输阶段** | `ack = 对方的seq + 数据长度` | <br>- 客户端GET请求：`seq 734385443:734385516`，数据长度73<br>- 服务端确认：`ack 734385516 = 734385443 + 73`<br><br>- 服务端HTTP响应：`seq 4168948237:4168949099`，数据长度862<br>- 客户端确认：`ack 4168949099 = 4168948237 + 862` |

### 关键差异说明
1. **三次握手阶段**：
   - SYN包和SYN+ACK包的`length`字段为0（不携带应用层数据）
   - 但SYN标志本身占据一个序列号，所以确认号是`seq + 1`
   - 这是TCP协议的特殊规定，确保连接建立的可靠性

2. **数据传输阶段**：
   - 数据包携带实际应用层数据，`length`字段大于0
   - 确认号是`seq + 数据长度`，表示已收到所有数据直到`seq + 数据长度 - 1`
   - 例如：`seq 734385443:734385516`表示发送了734385443到734385516（共73字节），所以确认号是734385516（期望接收下一个字节）

### 确认机制的作用
- **可靠性保证**：确保数据不丢失，接收方必须确认收到的数据
- **流量控制**：通过窗口大小字段配合，控制发送方的发送速率
- **序列号同步**：确保发送方和接收方的序列号同步，避免数据乱序

### 常见误区
- ❌ 错误：确认号是"已收到的最后一个序列号"
- ✅ 正确：确认号是"期望接收的下一个序列号"，表示已收到所有序列号小于该值的数据

例如：`ack 734385516`表示"我已收到所有序列号小于734385516的数据，下一次请发送从734385516开始的数据"

**重要说明：tcpdump的序列号显示**

- 使用`-S`选项时，tcpdump显示**绝对序列号**，如上面的`seq 734385442`和`ack 734385443`
- 不使用`-S`选项时，tcpdump默认显示**相对序列号**，将ISN视为0的偏移值
- 两种显示方式本质相同，相对序列号更易读，绝对序列号更精确

**2. 数据传输过程**
```bash
# Client发送HTTP GET请求
10:34:35.592869 IP 10.0.0.12.35300 > ubuntu24.http: Flags [P.], seq 734385443:734385516, ack 4168948237, win 502, options [nop,nop,TS val 3595154788 ecr 3255908001], length 73: HTTP: GET / HTTP/1.1 
# 标志位：[P.] = PSH+ACK (推送+确认)
# 含义：Client发送HTTP请求数据，PSH标志要求立即推送数据到应用层
# 数据范围：seq 734385443-734385516（共73字节，即GET请求内容）

# Server确认收到GET请求
10:34:35.592903 IP ubuntu24.http > 10.0.0.12.35300: Flags [.], ack 734385516, win 509, options [nop,nop,TS val 3255908002 ecr 3595154788], length 0 
# 标志位：[.] = ACK (确认)
# 含义：Server已收到Client的GET请求，ack=734385516表示期望接收下一个字节

# Server发送HTTP响应数据
10:34:35.593105 IP ubuntu24.http > 10.0.0.12.35300: Flags [P.], seq 4168948237:4168949099, ack 734385516, win 509, options [nop,nop,TS val 3255908002 ecr 3595154788], length 862: HTTP: HTTP/1.1 200 OK 
# 标志位：[P.] = PSH+ACK (推送+确认)
# 含义：Server发送HTTP响应数据，包含状态码200 OK
# 数据范围：seq 4168948237-4168949099（共862字节，即HTTP响应内容）

# Client确认收到HTTP响应
10:34:35.593249 IP 10.0.0.12.35300 > ubuntu24.http: Flags [.], ack 4168949099, win 496, options [nop,nop,TS val 3595154788 ecr 3255908002], length 0 
# 标志位：[.] = ACK (确认)
# 含义：Client已收到Server的完整响应，ack=4168949099表示期望接收下一个字节
```

**3. 四次挥手过程**
```bash
# Client发起关闭连接请求
10:34:35.594148 IP 10.0.0.12.35300 > ubuntu24.http: Flags [F.], seq 734385516, ack 4168949099, win 496, options [nop,nop,TS val 3595154789 ecr 3255908002], length 0 
# 标志位：[F.] = FIN+ACK (结束+确认)
# 含义：Client完成数据发送，请求关闭连接

# Server确认收到FIN请求 并 同时发送自己的FIN请求
10:34:35.594354 IP ubuntu24.http > 10.0.0.12.35300: Flags [F.], seq 4168949099, ack 734385517, win 509, options [nop,nop,TS val 3255908003 ecr 3595154789], length 0 
# 标志位：[F.] = FIN+ACK (结束+确认)
# 含义：Server确认收到Client的关闭请求，同时发送自己的FIN请求

# Client确认收到Server的FIN请求
10:34:35.594554 IP 10.0.0.12.35300 > ubuntu24.http: Flags [.], ack 4168949100, win 496, options [nop,nop,TS val 3595154790 ecr 3255908003], length 0 
# 标志位：[.] = ACK (确认)
# 含义：Client确认收到Server的关闭请求，Server收到此ACK后连接关闭
# 此时Client进入TIME_WAIT状态，等待2MSL（最大段生存期）时间
```

**四次挥手的优化：FIN+ACK合并机制**

在传统的TCP四次挥手中，关闭连接的过程应该是：
1. **第一次挥手**：Client发送FIN请求关闭连接
2. **第二次挥手**：Server发送ACK确认收到FIN
3. **第三次挥手**：Server发送FIN请求关闭反向连接
4. **第四次挥手**：Client发送ACK确认收到FIN

但在实际抓包中，我们经常看到服务器将**第二次和第三次挥手合并**为一个FIN+ACK包，这是TCP协议的一种优化机制。

**为什么会出现FIN+ACK合并？**

当服务器收到客户端的FIN请求时，如果服务器：
1. 已经没有数据要发送给客户端
2. 准备关闭连接
3. 不需要额外的处理时间

那么服务器可以选择将ACK和FIN合并发送，减少一次网络往返，提高关闭连接的效率。

**结合抓包示例分析：**

在用户提供的抓包中：
- **Client发送FIN**：`Flags [F.], seq 734385516` 表示客户端请求关闭连接
- **Server回复FIN+ACK**：`Flags [F.], seq 4168949099, ack 734385517`
  - `ack 734385517`：表示Server确认收到Client的FIN（完成第二次挥手）
  - `seq 4168949099` 和 `Flags [F]`：表示Server同时发送FIN请求关闭反向连接（完成第三次挥手）

**FIN+ACK合并的条件：**

1. **服务器无数据待发送**：服务器的发送缓冲区已空，没有后续数据要发送给客户端
2. **连接状态允许**：服务器已经准备好关闭连接，不需要额外的处理时间
3. **TCP状态转换**：服务器从`ESTABLISHED`状态直接进入`LAST_ACK`状态，而不是先进入`CLOSE_WAIT`状态（跳过了等待应用层关闭的阶段）
4. **应用层配合**：应用层程序（如Nginx）在处理完请求后立即调用close()或shutdown()关闭连接

**正常四次挥手与合并挥手的对比：**

| 阶段 | 正常四次挥手 | FIN+ACK合并的三次挥手 |
|------|--------------|----------------------|
| 1 | Client → FIN | Client → FIN |
| 2 | Server → ACK | （合并） |
| 3 | Server → FIN | Server → FIN+ACK |
| 4 | Client → ACK | Client → ACK |
| 网络往返次数 | 4次 | 3次 |
| 适用场景 | 服务器需要处理完剩余数据后再关闭 | 服务器已无数据发送，可立即关闭 |

**SRE关注点：**

- **连接关闭效率**：FIN+ACK合并可以减少一次网络往返，提高连接关闭效率，特别适合短连接场景
- **状态转换监控**：通过观察TCP状态转换（如`CLOSE_WAIT`状态的时长），可以判断应用层程序是否存在资源泄漏
- **异常情况排查**：如果服务器长时间处于`CLOSE_WAIT`状态，可能表示应用层程序没有正确关闭连接
- **性能优化**：对于高并发服务，合理的连接关闭策略可以减少TIME_WAIT状态的数量，降低系统资源消耗

**为什么客户端不会合并挥手？**

客户端通常不会合并挥手，因为客户端在发送FIN后，需要等待服务器的确认和服务器的FIN请求，这两个事件的时间点通常不重合。而且客户端作为主动关闭方，需要进入TIME_WAIT状态，这是TCP协议的设计要求，用于确保网络中残留的数据包被正确处理。

**4. 对应的curl命令结果**
```bash
0 ✓ 10:34:35 root@rocky9.6-12,10.0.0.12:~ # curl 10.0.0.13
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<p><em>Thank you for using nginx.</em></p>
</body>
</html>
0 ✓ 10:34:35 root@rocky9.6-12,10.0.0.12:~ #
# 这是curl命令获取到的Nginx默认页面，对应TCP连接中的HTTP响应数据
```

**SRE关注点**：
- **连接建立时间**：三次握手耗时约0.555ms（从SYN到ACK的时间差：10:34:35.592313 → 10:34:35.592868），说明网络延迟很低
- **数据传输效率**：HTTP请求（73字节）和响应（862字节）都在单个TCP段中传输，没有分片
- **连接关闭方式**：使用标准的四次挥手关闭连接，没有出现异常状态
- **TCP参数**：双方都使用了MSS 1460、SACK和窗口缩放等优化参数
- **TIME_WAIT状态**：连接关闭后客户端进入TIME_WAIT状态，符合TCP协议规范

**分析思路**：
1. 首先确认TCP连接是否成功建立（三次握手是否完整）
2. 检查数据传输是否正常（PSH标志位表示数据推送，ACK确认号递增正常）
3. 验证连接关闭是否正常（四次挥手是否完整，序列号和确认号匹配）
4. 关注TCP标志位和序列号的变化，理解连接状态的转换
5. 结合应用层数据（HTTP请求/响应），理解端到端的通信过程
6. 分析TCP参数（MSS、窗口大小、TS选项）对性能的影响

### 网络故障排查案例：Wireshark看不到虚拟机间流量

#### 问题现象
在使用Wireshark监听VMnet8网卡时，只能看到10.0.0.12到10.0.0.1的流量，而看不到10.0.0.12到10.0.0.13的TCP流量，尽管执行`curl 10.0.0.13`能成功获取响应。

#### 排查步骤

**1. 验证网络连通性**
```bash
# 在Rocky主机(10.0.0.12)上ping Ubuntu主机(10.0.0.13)
ping 10.0.0.13
PING 10.0.0.13 (10.0.0.13) 56(84) 比特的数据。
64 比特，来自 10.0.0.13: icmp_seq=1 ttl=64 时间=0.385 毫秒
64 比特，来自 10.0.0.13: icmp_seq=2 ttl=64 时间=0.382 毫秒
# 连通性正常

# 追踪路由，验证直接通信
0 ✓ 08:56:16 root@rocky9.6-12,10.0.0.12:~ # traceroute 10.0.0.13 
 traceroute to 10.0.0.13 (10.0.0.13), 30 hops max, 60 byte packets 
  1  10.0.0.13 (10.0.0.13)  0.379 ms  0.335 ms  0.313 ms 
0 ✓ 08:56:23 root@rocky9.6-12,10.0.0.12:~ #
# 直接到达，只经过1跳，验证虚拟机间直接通信
```

**2. 检查Nginx服务状态**
```bash
# 在Ubuntu主机(10.0.0.13)上检查Nginx配置
cat /etc/nginx/sites-available/default
# 确认监听80端口
listen 80 default_server;
listen [::]:80 default_server;

# 检查Nginx是否正在监听80端口
ss -lntup | grep 80
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*
tcp   LISTEN 0      511             [::]:80            [::]:*
# Nginx正常监听80端口
```

**3. 分析问题原因**

#### VMware NAT 模式的流量转发特性
在 VMware NAT 模式下，同一宿主机内的虚拟机之间通信时，VMware 虚拟交换机 (VMware Virtual Switch) 会直接转发流量，**不经过宿主机的物理网卡**。这是为了提高性能而设计的优化。

#### Wireshark 捕获的限制
Wireshark 运行在宿主机上，只能捕获经过宿主机物理网卡的流量。由于虚拟机间的流量被虚拟交换机直接转发，所以 Wireshark 看不到这些流量。

#### 网关转发的例外情况
如果虚拟机访问外网（如 `curl www.baidu.com`），流量会经过网关 `10.0.0.2`，然后通过宿主机的物理网卡发送出去。此时 Wireshark 可以捕获到这些流量。

#### Wireshark 与 tcpdump 捕获差异的详细解释
**为什么 Wireshark 只有 10.0.0.1 宿主机到 10.0.0.13 的 TCP 流量，而 tcpdump 能捕捉到来自 10.0.0.12 curl 命令的流量？**

这是因为两者运行的位置和捕获范围不同：

| 工具 | 运行位置 | 捕获范围 | 结果差异 |
|------|----------|----------|----------|
| Wireshark | 宿主机 | 仅经过宿主机物理网卡的流量 | 只能看到宿主机(10.0.0.1)与虚拟机(10.0.0.13)的通信，看不到虚拟机间直接通信 |
| tcpdump | 虚拟机内部 | 虚拟机网卡上的所有流量 | 可以看到虚拟机(10.0.0.12)与虚拟机(10.0.0.13)的直接通信 |

**具体原因分析：**

1. **流量路径差异**：
   - 当 10.0.0.12 (Rocky) 访问 10.0.0.13 (Ubuntu) 时，流量直接通过 VMware 虚拟交换机转发，不经过宿主机网卡
   - 当 10.0.0.1 (宿主机) 访问 10.0.0.13 (Ubuntu) 时，流量需要经过宿主机网卡，所以 Wireshark 能捕获到

2. **捕获点不同**：
   - Wireshark 捕获的是宿主机物理网卡的流量，位于虚拟交换机外部
   - tcpdump 捕获的是虚拟机内部网卡的流量，位于虚拟交换机内部

3. **VMware 虚拟网络架构**：
   ```
   +----------------+      +----------------+      +----------------+
   | 宿主机(10.0.0.1)|      | VMware 虚拟交换机 |      | 虚拟机(10.0.0.13) |
   |                |      |                |      |                |
   | Wireshark      |<-----|                |<-----|                |
   | (捕获物理网卡) |      |                |      | tcpdump        |
   +----------------+      |                |      | (捕获虚拟网卡) |
                           |                |      +----------------+
                           |                |      +----------------+
                           |                |      | 虚拟机(10.0.0.12) |
                           |                |<-----|                |
                           +----------------+      +----------------+
   ```

**4. 解决方案**
- 使用虚拟机内部的网络工具（如`tcpdump`）捕获流量：`tcpdump -i eth0 tcp port 80`
- 将VMware网络模式改为**桥接模式**，使虚拟机直接连接到物理网络
- 在VMware网络编辑器中调整NAT设置，让流量经过宿主机网卡以便捕获

### 4.1 VMware网络编辑器具体操作步骤

**1. 打开VMware网络编辑器**
- 在VMware Workstation主界面，点击顶部菜单 `编辑` > `虚拟网络编辑器`
- 或在Windows右下角找到VMware网络图标，右键选择 `虚拟网络编辑器`

**2. 获取管理员权限**
- 点击窗口右下角的 `更改设置` 按钮，输入管理员密码获取权限

**3. 选择NAT网络**
- 在左侧列表中选择 `VMnet8`（NAT模式对应的虚拟网络）
- 确保 `已连接` 选项被勾选

**4. 调整NAT设置**
- 点击下方的 `NAT设置` 按钮，打开NAT设置窗口
- 查看网关IP（通常为 `10.0.0.2`），确认与虚拟机配置一致

**5. 虚拟机间流量捕获的特殊说明**

#### 为什么勾选了虚拟适配器仍无法捕获虚拟机间流量？

即使勾选了 `将主机虚拟适配器连接到此网络` 选项，您仍可能无法捕获到 `10.0.0.12` 和 `10.0.0.13` 之间的直接流量，这是由VMware NAT模式的**内部转发机制**决定的：

1. **虚拟交换机内部转发**：在NAT模式下，同一虚拟网络（VMnet8）内的虚拟机之间通信时，流量直接通过VMware内置的虚拟交换机转发，**不经过宿主机的物理网卡或虚拟适配器**
2. **流量路径差异**：
   - 虚拟机到外部网络：`虚拟机 → 虚拟交换机 → NAT设备 → 宿主机网卡 → 外部网络`
   - 虚拟机到虚拟机：`虚拟机 → 虚拟交换机 → 另一虚拟机`（完全在VMware虚拟网络栈内完成）
3. **Wireshark捕获限制**：Wireshark只能捕获经过宿主机网卡或虚拟适配器的流量，无法直接访问VMware虚拟交换机内部的流量

#### 针对虚拟机间流量的有效捕获方案

以下是专门针对虚拟机间流量捕获的解决方案：

##### 方案1：使用VMware自带的Network Analyzer（推荐）
- VMware Workstation Pro 15+ 内置了 `Network Analyzer` 功能，**可以直接捕获虚拟机间的流量**
- 操作路径：`虚拟机` > `捕获网络流量` > `开始`
- 选择要监控的虚拟机和网络接口
- 捕获的流量会保存为 `.pcap` 文件，可直接用Wireshark打开

##### 方案2：修改虚拟机网络模式为"仅主机模式"
- 在虚拟机设置中，将网络适配器改为 `仅主机模式（VMnet1）`
- 在虚拟网络编辑器中，确保VMnet1的 `将主机虚拟适配器连接到此网络` 被勾选
- 这样同一VMnet1网络内的虚拟机通信流量会经过宿主机的VMnet1虚拟适配器
- 使用Wireshark监听VMnet1适配器即可捕获所有虚拟机间流量

##### 方案3：在虚拟机内直接使用tcpdump
- 在Linux虚拟机中安装tcpdump：`sudo yum install tcpdump` 或 `sudo apt install tcpdump`
- 在 `10.0.0.12` 或 `10.0.0.13` 虚拟机内执行：`sudo tcpdump -i eth0 host 10.0.0.13 and port 3181`
- 这样可以直接在虚拟机内部捕获进出的所有流量，不受VMware虚拟网络架构限制

##### 方案4：使用桥接模式
- 将虚拟机网络适配器改为 `桥接模式`
- 虚拟机将直接连接到宿主机所在的物理网络
- 使用Wireshark监听宿主机物理网卡即可捕获所有虚拟机流量

**6. 应用设置**
- 点击 `确定` 保存所有设置
- 重启VMware虚拟网络服务（可选，确保设置生效）
- 重启相关虚拟机以应用新的网络设置

### 4.2 验证解决方案

#### 验证方法1：使用tcpdump在虚拟机内捕获
```bash
# 在10.0.0.12虚拟机上捕获到10.0.0.13的流量
sudo tcpdump -i eth0 host 10.0.0.13 and tcp port 3181

# 在10.0.0.13虚拟机上捕获到10.0.0.12的流量
sudo tcpdump -i eth0 host 10.0.0.12 and tcp port 3181
```

#### 验证方法2：使用VMware Network Analyzer
- 启动Network Analyzer后，发起虚拟机间通信
- 检查捕获的pcap文件，确认包含虚拟机间的TCP流量
- 分析流量中的三次握手和数据传输过程

### 4.3 常见问题与解决方案

**问题1：为什么Wireshark在宿主机上无法捕获虚拟机间流量？**
- **原因**：NAT模式下虚拟机间流量直接通过VMware虚拟交换机转发，不经过宿主机网卡或虚拟适配器
- **解决方案**：使用VMware Network Analyzer或在虚拟机内使用tcpdump

**问题2：为什么没捕获到ping或traceroute流量？**
- **协议不匹配**：默认捕获命令可能只针对TCP协议，而`ping`使用ICMP，`traceroute`默认使用UDP
- **过滤器限制**：需要调整捕获过滤器以包含相应协议

**捕获不同协议流量的正确命令：**
```bash
# 捕获ICMP流量（包括ping）
sudo tcpdump -i eth0 icmp

# 捕获UDP流量（包括默认traceroute）
sudo tcpdump -i eth0 udp

# 捕获特定端口的TCP流量
sudo tcpdump -i eth0 tcp port 3181

# 捕获所有流量
sudo tcpdump -i eth0
```

**问题3：如何确认VMware虚拟网络设置正确？**
- 检查虚拟机的网络配置：`ip addr` 和 `ip route`
- 验证虚拟机间连通性：`ping 10.0.0.13`
- 检查虚拟网络编辑器中的设置，确保对应网络已连接
- 重启VMware虚拟网络服务：在Windows服务中重启`VMware NAT Service`和`VMware DHCP Service`

**用户实际捕获结果分析**：
```bash
# 用户在10.0.0.13上执行的命令
sudo tcpdump -i eth0 tcp port 80
# 捕获到10.0.0.12访问docker.nju.edu.cn的HTTP流量，这是因为：
# 1. 该流量使用TCP协议且端口为80
# 2. 匹配了当前过滤器条件
# 3. ping和traceroute使用其他协议，因此未被捕获
```

#### SRE 经验总结
- **工具局限性**：不同工具的捕获范围不同，Wireshark无法捕获VMware内部流量
- **网络模式理解**：深入理解VMware各种网络模式的流量路径
- **多工具协作**：结合`ping`、`ss`、`tcpdump`和`Wireshark`等工具进行全面排查
- **配置验证**：确认服务监听配置和网络连通性是排查的基础

> [!TIP]
> netcat 是 SRE 工具箱中的瑞士军刀，掌握它可以快速解决很多网络相关问题。

#### 四次挥手 (The Wave)


![四次挥手](/images/posts/2025-11-23-network-protocols-communication-sre/四次挥手.png)


**SRE 关注点（高频故障点）**：

#### TCP 状态详解

| 状态 | 描述 | 常见角色 |
|------|------|----------|
| **LISTEN** | 套接字正在监听入站连接 | 服务端 |
| **CLOSE** | 套接字未被使用 | 两端 |
| **CLOSE_WAIT** | 远程端已关闭，等待本地关闭套接字（半关闭状态） | 服务端（被动关闭方） |
| **TIME_WAIT** | 主动关闭后等待网络中残余数据包处理 | 客户端（主动关闭方） |
| **FIN_WAIT_1** | 已发送FIN，等待ACK | 主动关闭方 |
| **FIN_WAIT_2** | 已收到FIN的ACK，等待对方的FIN | 主动关闭方 |
| **LAST_ACK** | 已关闭套接字，等待最后一个ACK | 被动关闭方 |
| **CLOSING** | 双方同时关闭，等待所有数据发送完成 | 两端 |
| **UNKNOWN** | 套接字状态未知 | - |

#### 关闭场景分析

- **只有服务端的ACK**：
  客户端发送FIN后，只收到服务端的ACK，会进入FIN_WAIT_2状态。后续收到服务端的FIN时，回应ACK并进入TIME_WAIT状态。

- **只有服务端的FIN**：
  客户端收到服务端的FIN时，回应ACK进入CLOSING状态，然后收到服务端的ACK时进入TIME_WAIT状态。

- **既有服务端的ACK，又有FIN**：
  客户端同时收到服务端的ACK和FIN，直接进入TIME_WAIT状态。

#### 关键状态深入分析

- **CLOSE_WAIT**：**服务端**（被动关闭方）卡在这里，通常是**代码 Bug**。
  - *原因*：程序收到了 FIN，但没有调用 `close()` 关闭 socket。
  - *后果*：占用文件句柄，最终导致服务崩溃。

- **TIME_WAIT**：**客户端**（主动关闭方）卡在这里，是**正常现象**，但过多会有害。
  - *作用*：确保迷路的包在网络中消失；确保 Server 收到最后的 ACK。
  - *持续时间*：默认为2MSL（RFC 1122建议值2分钟），但实际由内核参数控制。
  - *危害*：短连接高并发场景下，耗尽源端口。
  - *持续时间控制*：由内核参数 `net.ipv4.tcp_fin_timeout` 决定，默认值为60秒（如用户实际环境所示）。
  - *查看参数值*：
    ```bash
    # 方法1：使用sysctl命令
    sysctl net.ipv4.tcp_fin_timeout
    # 输出：net.ipv4.tcp_fin_timeout = 60
    
    # 方法2：直接读取/proc文件
    cat /proc/sys/net/ipv4/tcp_fin_timeout
    # 输出：60
    ```

#### TCP 内核参数调整

以下是常见的TCP内核参数调整建议，可在`/etc/sysctl.conf`文件中配置：

```bash
# 查看当前配置
cat /etc/sysctl.conf

# 应用新配置
sysctl -p
```

| 参数 | 描述 | 默认值 | 建议值 | **SRE生产实践案例** |
|------|------|--------|--------|----------------------|
| **net.ipv4.tcp_fin_timeout** | 套接字保持在FIN-WAIT-2状态的时间 | 60秒 | 15-60秒 | **案例**：电商平台大促期间，Web服务器处理10万+ QPS短连接，将该值从60秒调整为30秒，TIME-WAIT连接数从8万降至3万，释放了大量系统资源。<br>**注意**：过低（<15秒）可能导致网络延迟高时连接异常。 |
| **net.ipv4.tcp_tw_reuse** | 允许将TIME-WAIT套接字重新用于新连接 | 0（关闭） | 1（开启） | **案例**：API网关服务器需要同时向200+微服务发起连接，开启该参数后，TIME-WAIT连接复用率达到60%，源端口耗尽问题彻底解决。<br>**适用场景**：高并发outbound连接（微服务调用、CDN回源）。 |
| **net.ipv4.tcp_tw_recycle** | 开启TIME-WAIT套接字快速回收（新内核已废弃） | 0（关闭） | 0（不建议开启） | **案例**：某负载均衡器开启该参数后，NAT环境下的客户端出现"connection reset by peer"错误，关闭后恢复正常。<br>**原理**：该参数基于时间戳判断连接有效性，在NAT环境下会导致不同客户端的连接被错误回收。 |
| **net.ipv4.tcp_syncookies** | 开启SYN Cookies防范SYN攻击 | 1（开启） | 1 | **案例**：某游戏服务器遭受SYN洪水攻击，syn_backlog队列满导致连接拒绝，开启该参数后，服务器能正常处理合法连接，同时抵御攻击。<br>**注意**：会轻微影响TCP性能，但在公网环境下是必要的安全措施。 |
| **net.ipv4.tcp_keepalive_time** | TCP发送keepalive消息的频度 | 7200秒（2小时） | 600秒（10分钟） | **案例**：数据库连接池中的连接因网络波动被中间设备断开，应用层未感知导致大量"broken pipe"错误，将该值从2小时调整为10分钟后，失效连接能被及时检测并重建。<br>**适用场景**：长连接应用（数据库、WebSocket、消息队列）。 |
| **net.ipv4.ip_local_port_range** | 向外连接的端口范围 | 32768 61000 | 2000 65000 | **案例**：爬虫服务器需要同时发起10万+并发连接，默认端口范围仅28233个可用端口，调整为2000-65000后，可用端口数达到63001个，解决了端口耗尽问题。 |
| **net.ipv4.tcp_max_syn_backlog** | SYN队列长度（半连接队列） | 1024 | 16384 | **案例**：直播平台秒杀活动中，服务器每秒收到5万+ SYN请求，默认队列长度导致大量连接被丢弃，调整为16384后，连接成功率从85%提升至99.5%。<br>**配合**：需同时调整`somaxconn`参数。 |
| **net.ipv4.tcp_max_tw_buckets** | 系统同时保持TIME_WAIT套接字的最大数量 | 180000 | 36000 | **案例**：某高并发Web服务器TIME_WAIT连接数经常超过10万，导致系统内存占用过高，调整为36000后，超过阈值的TIME_WAIT连接会被主动回收，系统稳定性提升。<br>**注意**：该值不宜过小，否则会导致连接重置。 |
| **net.ipv4.route.gc_timeout** | 路由缓存过期时间 | - | 100 | **案例**：云环境中虚拟机频繁创建销毁，路由表变化频繁，调整该值从默认值到100秒后，路由缓存更新更快，减少了"no route to host"错误。 |
| **net.ipv4.tcp_syn_retries** | 内核放弃建立连接前发送SYN包的数量 | 6 | 1 | **案例**：微服务架构中，服务间调用超时要求1秒，将该值从6（总超时~1分钟）调整为1（总超时~1秒）后，故障服务能被快速发现，熔断机制及时触发。<br>**适用场景**：对延迟敏感的分布式系统。 |
| **net.ipv4.tcp_synack_retries** | 内核放弃连接前发送SYN+ACK包的数量 | 5 | 1 | **案例**：公网服务器收到大量无效SYN请求，发送SYN+ACK重试消耗了大量带宽，调整为1后，无效连接资源消耗降低80%。<br>**安全建议**：公网服务器建议设置为1-2次。 |
| **net.ipv4.tcp_max_orphans** | 未关联到用户文件句柄的TCP套接字最大数量 | 8192 | 16384 | **案例**：某Web服务器遭受DDoS攻击，大量半开连接导致orphan套接字激增，超过默认值后内核开始丢弃连接，调整为16384后，系统能更好地抵御攻击。<br>**原理**：防止恶意攻击消耗系统资源。 |
| **net.core.somaxconn** | 全连接队列长度 | 128 | 16384 | **案例**：Nginx服务器监听80端口，并发连接数超过128时，`ss -s`显示"SYNs to LISTEN sockets dropped"，调整为16384并修改Nginx的`worker_connections`后，连接丢弃问题消失。<br>**注意**：需与应用层配置（如Nginx、Tomcat的max connections）配合调整。 |
| **net.core.netdev_max_backlog** | 网络接口接收数据包的最大队列长度 | 1000 | 16384 | **案例**：视频流服务器处理40Gbps流量时，网络接口队列经常满导致数据包丢失，调整为16384后，丢包率从0.5%降至0.01%。<br>**适用场景**：高流量服务器（视频、CDN、大文件传输）。 |

#### 生产环境优化策略（SRE实战总结）

**1. 高并发Web服务器**：
- 开启 `tcp_tw_reuse`，调整 `tcp_fin_timeout=30`
- 扩大 `somaxconn=16384` 和 `tcp_max_syn_backlog=16384`
- 开启 `tcp_syncookies=1` 防范攻击

**2. 微服务API网关**：
- 开启 `tcp_tw_reuse=1`，调整 `ip_local_port_range=2000 65000`
- 缩短 `tcp_syn_retries=1` 和 `tcp_synack_retries=1`
- 调整 `tcp_keepalive_time=600` 及时检测失效连接

**3. 数据库服务器**：
- 调整 `tcp_keepalive_time=300`（5分钟）
- 关闭 `tcp_tw_reuse`（数据库连接要求高可靠性）
- 保持 `tcp_syncookies=1` 开启

**4. 负载均衡器**：
- 开启 `tcp_tw_reuse=1`，调整 `tcp_fin_timeout=20`
- 关闭 `tcp_tw_recycle=0`（NAT环境必备）
- 扩大 `netdev_max_backlog=16384` 处理高流量

#### SRE调优注意事项

1. **渐进式调整**：每次只修改1-2个参数，观察24小时后再调整其他参数
2. **监控先行**：调整前开启TCP连接监控（`ss -s`、`netstat -s`、Prometheus）
3. **差异化配置**：不同角色服务器（Web、DB、网关）使用不同的参数配置
4. **内核版本兼容**：部分参数在新内核中已废弃（如`tcp_tw_recycle`）
5. **应用层配合**：TCP参数需与应用层配置（如Nginx的`worker_connections`）协同调优
6. **灰度验证**：先在测试环境验证，再小规模灰度，最后全量推广

**核心调优思路**：TCP参数调优的本质是**在连接可靠性和系统资源利用率之间寻找平衡**，SRE需要根据业务场景、流量模型和硬件资源制定最优配置。

### 4.3 应用层核心：DNS 与 HTTP

#### DNS：网络世界的导航仪

DNS 解析流程通常是：`本地 hosts` -> `本地 DNS 缓存` -> `递归 DNS 服务器` -> `根/顶级/权威 DNS 服务器`。

**常见问题**：
- **解析慢**：递归 DNS 响应慢，或者 UDP 包被限速/丢弃。
- **解析错**：DNS 劫持或缓存污染。
- **ndots 陷阱**：在 Kubernetes 中，默认 `ndots:5` 会导致大量无效的 DNS 查询（如 `google.com.default.svc.cluster.local`），增加延迟。

#### HTTP：从 1.1 到 3.0

- **HTTP/1.1**：文本协议，Keep-Alive 复用连接，但有队头阻塞 (Head-of-Line Blocking)。
- **HTTP/2**：二进制分帧，多路复用 (Multiplexing)，头部压缩 (HPACK)。解决了应用层队头阻塞，但 TCP 层队头阻塞依然存在。
- **HTTP/3 (QUIC)**：基于 UDP，彻底解决了 TCP 的队头阻塞，连接迁移更平滑。

### 4.4 链路层扩展：VLAN (Virtual LAN)

虚拟局域网 (VLAN) 是将物理网络划分为多个逻辑隔离的网段的技术。

**通俗理解**：
想象一个开放式大办公室（物理局域网），所有人说话大家都能听到（广播域）。
VLAN 就像是在这个大办公室里装上了**隔音玻璃**。
- **物理上**：大家还坐在同一个房间里（连接在同一个交换机上）。
- **逻辑上**：只有玻璃房内的人能互相交谈（同一 VLAN 内通信），听不到外面的嘈杂声（隔离广播）。

**核心价值**：
1.  **提升性能（隔绝噪音）**：限制广播报文的范围，避免"广播风暴"阻塞网络。
2.  **简化管理（灵活工位）**：员工换座位（物理位置变动），只需要在交换机上修改 VLAN 配置，不需要重新布线。
3.  **增强安全（部门隔离）**：财务部（VLAN 10）的数据不会被访客（VLAN 20）窃听。

> [!NOTE]
> VLAN 只是逻辑隔离。不同 VLAN 之间要通信，必须通过路由器或三层交换机（相当于在隔音玻璃上开个门，并安排保安检查）。

### 4.5 排查工具箱 (Troubleshooting Toolkit)

工欲善其事，必先利其器。

#### 1. 查看连接状态：`ss` (Socket Statistics)

比 `netstat` 更快更强。

```bash
# 查看所有 TCP 连接并显示进程名
ss -ntlp

# 统计各种状态的连接数（排查 TIME_WAIT/CLOSE_WAIT 神器）
ss -ant | awk '{print $1}' | sort | uniq -c | sort -rn
# 输出示例：
# 800 ESTABLISHED
# 50 TIME_WAIT
# 10 LISTEN
```

#### 2. 抓包分析：`tcpdump`

```bash
# 抓取 eth0 网卡，端口 80，排除 SSH，保存到文件
tcpdump -i eth0 port 80 and not port 22 -w capture.pcap

# 抓取特定 IP 的包，显示详细信息
tcpdump -i any host 192.168.1.100 -nn -vv
```

#### 3. DNS 诊断：`dig`

```bash
# 查询 A 记录，显示查询时间
dig www.google.com

# 指定 DNS 服务器查询
dig @8.8.8.8 www.google.com

# 追踪解析过程
dig +trace www.google.com
```

#### 4. 综合连通性：`curl`

```bash
# 查看详细的连接耗时（DNS、TCP、SSL、TTFB）
curl -w "\nDNS: %{time_namelookup}s\nTCP: %{time_connect}s\nSSL: %{time_appconnect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" -so /dev/null https://www.baidu.com
```

#### 5. 物理链路诊断：`mii-tool` 与 `ethtool`

当怀疑是物理层问题（如网线松动、协商速率不匹配）时，我们需要查看网卡的底层状态。

##### 5.1 传统工具：`mii-tool`

在较老的系统或特定的物理网卡上，`mii-tool` 非常直观。

```bash
root@ubuntu24:~# mii-tool -v ens33
ens33: negotiated 1000baseT-FD flow-control, link ok
# 协商结果：1000Mbps 全双工 (FD)，启用了流量控制。
# link ok：物理连接正常。

  product info: Yukon 88E1011 rev 3
  # 网卡型号信息

  basic mode:   autonegotiation enabled
  # 开启了自动协商，网卡会尝试与对端交换信息以选择最佳模式。

  basic status: autonegotiation complete, link ok
  # 自动协商成功完成。

  capabilities: 1000baseT-FD 100baseTx-FD 100baseTx-HD 10baseT-FD 10baseT-HD
  # 本端网卡支持的能力：1000/100/10 Mbps 的全双工/半双工。

  advertising:  1000baseT-FD 100baseTx-FD 100baseTx-HD 10baseT-FD 10baseT-HD
  # 本端宣告的能力。

  link partner: 1000baseT-HD 1000baseT-FD 100baseTx-FD 100baseTx-HD 10baseT-FD 10baseT-HD
  # 对端设备（交换机）支持的能力。
```

**局限性**：
在现代 Linux 发行版（如 Rocky Linux 9）或虚拟化环境（如 VMware/KVM）中，`mii-tool` 可能会失效，因为它依赖的旧接口可能不被支持。

```bash
[root@rocky9 ~]# mii-tool ens160
SIOCGMIIPHY on 'ens160' failed: Operation not supported
# 原因：网卡驱动不支持 MII 寄存器访问（常见于 vmxnet3 等虚拟网卡）。
```

##### 5.2 现代标准：`ethtool`

`ethtool` 是目前 Linux 下配置和查询网卡参数的标准工具，功能比 `mii-tool` 更强大。

**查看网卡物理状态**：

```bash
[root@rocky9 ~]# ethtool ens160
Settings for ens160:
    Supported ports: [ TP ]
    # 介质类型：双绞线 (Twisted Pair)

    Supported link modes:   1000baseT/Full
                            10000baseT/Full
    # 支持的模式：千兆和万兆全双工

    Supports auto-negotiation: No
    # 不支持自动协商（虚拟网卡常见）

    Speed: 10000Mb/s
    # 当前速率：万兆

    Duplex: Full
    # 双工模式：全双工

    Link detected: yes
    # 物理链路正常
```

**查看驱动与固件信息**：

通过 `ethtool -i` 可以区分物理网卡和虚拟网卡，这对于排查性能问题（如是否需要开启 TSO/GSO Offload）很重要。

```bash
# Ubuntu (VMware e1000 模拟网卡)
root@ubuntu24:~# ethtool -i ens33
driver: e1000
version: 6.8.0-45-generic
bus-info: 0000:02:01.0

# Rocky Linux (VMware vmxnet3 半虚拟化网卡)
[root@rocky9 ~]# ethtool -i ens160
driver: vmxnet3
# vmxnet3 是 VMware 的高性能半虚拟化驱动
version: 1.7.0.0-k-NAPI
bus-info: 0000:03:00.0
```

**SRE 关注点**：
- **Link Status**: `Link detected: no` 意味着网线没插好或交换机端口关闭。
- **Duplex/Speed**: 确认协商速率是否符合预期（比如千兆变百兆），以及是否全双工。

#### 6. 网络接口配置与状态：`ip addr`

`ip addr` 是 `iproute2` 套件中最基础的命令，用于查看 IP 地址和接口状态。相比旧的 `ifconfig`，它能显示更多细节。

```bash
[root@rocky9 ~]# ip addr show ens160
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:b1:f4:54 brd ff:ff:ff:ff:ff:ff
    altname enp3s0
    inet 10.0.0.12/24 brd 10.0.0.255 scope global noprefixroute ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:feb1:f454/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

**详细解读**：

1.  **接口状态与标志**：`<BROADCAST,MULTICAST,UP,LOWER_UP>`
    *   `UP`: **管理状态**为开启（即管理员执行了 `ip link set up`）。
    *   `LOWER_UP`: **物理层状态**为开启（即网线已插好，物理链路正常）。
    *   **SRE 提示**：如果只有 `UP` 没有 `LOWER_UP`，说明网线没插好或交换机端口没开。

2.  **MTU & Qdisc**：`mtu 1500 qdisc mq`
    *   `mtu 1500`: 最大传输单元为 1500 字节（以太网标准）。如果两端 MTU 不一致（如一端开启巨型帧 9000），会导致大包丢弃。
    *   `qdisc mq`: 排队规则 (Queueing Discipline)。`mq` 表示多队列，常见于多核 CPU 和高性能网卡。

3.  **MAC 地址**：`link/ether 00:0c:29:b1:f4:54`
    *   **定义**：48位二进制地址，固化在网卡 ROM 中。
        *   **前 24 位 (OUI)**：组织唯一标识符 (Organizationally Unique Identifier)，标识制造商 (如 `00:0c:29` 代表 VMware)。
        *   **后 24 位 (DUI)**：设备唯一标识符 (Device Unique Identifier)，由厂商分配。
    *   **快速查看命令**：
        *   **Linux**: `ip addr show ens160 | grep ether`
        *   **Windows**: `ipconfig /all`
    *   `brd ff:ff:ff:ff:ff:ff`: 广播地址，代表所有 MAC 地址。

4.  **IPv4 地址**：`inet 10.0.0.12/24`
    *   `brd 10.0.0.255`: 广播地址。
    *   `scope global`: 全局有效，可用于互联网通信。
    *   `noprefixroute`: 不自动添加路由（通常由 NetworkManager 管理）。

5.  **IPv6 地址**：`inet6 fe80::.../64`
    *   `scope link`: 仅在本地链路有效（Link-Local），不可路由到互联网。
    *   `valid_lft forever`: 地址永久有效。

## 5. 总结

网络协议看似枯燥，实则是分布式系统的血管。作为 SRE，我们不需要成为网络专家，但必须掌握：
1.  **分层排查思维**：是 DNS 问题？TCP 连接问题？还是应用层 HTTP 报错？
2.  **状态机理解**：看到 `CLOSE_WAIT` 知道找开发修 Bug，看到 `TIME_WAIT` 知道调内核参数。
3.  **工具熟练度**：能够迅速用 `ss` 看状态，用 `tcpdump` 抓现场。

只有这样，我们才能在故障发生时，从容不迫地定位根因，保障系统的稳定性。
