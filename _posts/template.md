我现在需要针对以下内容写一篇博客：请根据blog-rule.md的规则编写
0 ✓ 02:34:02 root@ubuntu24-13,10.0.0.13:~ # cat set.sh
#!/bin/bash
# *************************************
# * 功能: 设定主机名和主机ip
# * 作者: 钟翼翔
# * 联系: clockwingsoar@outlook.com
# * 版本: 2026-4-08
# *************************************
set -e # 遇到错误立即退出
# 1. 提示用户输入IP地址（仅需输入最后一段，如147）
read -p "请输入10.0.0.0/24网段的IP最后一段（如147）：" IP_LAST
IP_FULL="10.0.0.${IP_LAST}"
HOSTNAME="ubuntu24-${IP_LAST}"
# 2. 设置主机名
echo "正在设置主机名为：${HOSTNAME}"
hostnamectl set-hostname "${HOSTNAME}"
source /etc/profile
# 3. 定制apt源
rm -rf /etc/apt/sources.list.d/*
cat > /etc/apt/sources.list <<-eof
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
eof
# 4. 生成新的netplan配置（网关默认用10.0.0.2，可根据实际修改）
rm -rf /etc/netplan/*
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
echo "正在生成netplan网络配置（IP：${IP_FULL}/24）"
cat > "${NETPLAN_FILE}" << EOF
network:
  version: 2
  ethernets:
    ens33: # 注意：需确保网卡名正确（可通过ip a查看）
      addresses:
        - "${IP_FULL}/24"
      nameservers:
        addresses:
          - 10.0.0.2 # DNS服务器可根据实际修改
      routes:
        - to: default
          via: 10.0.0.2 # 网关地址可根据实际修改
EOF
chmod 600 "${NETPLAN_FILE}"
# 5. 应用netplan配置并验证
echo "正在应用网络配置..."
netplan apply
> ~/.bash_history
# 6. 验证结果
echo -e "\n配置完成！当前信息："
echo "主机名：$(hostname)"
echo "IP地址：$(hostname -I)"
rm -f $0 && echo "脚本已成功自我删除"
我用整个脚本更改ip和hostname之后，在bash中运行所有命令都变得特别慢，是什么原因呢，如何修复， 这是我在gemini上的提问，给的回复是：这个问题通常是由 DNS 解析延迟 或 主机名无法本地解析 引起的。在 Linux 系统中，许多命令（如 sudo、bash 启动、或者某些网络工具）在执行前会尝试通过主机名反查 IP 或验证域名。如果配置不当，系统会一直等待超时，导致操作感官上非常“卡顿”。

以下是导致卡顿的主要原因及修复方案：

1. /etc/hosts 缺少本地解析（最常见原因）
你使用 hostnamectl set-hostname 更改了主机名，但没有同步更新 /etc/hosts 文件。当 Bash 或其他程序调用 getaddrinfo 函数查询当前主机名 ${HOSTNAME} 时，系统无法在本地映射中找到它，转而请求 DNS 服务器（10.0.0.2）。如果 DNS 也没有记录，就会等到超时（通常是 5-30 秒）。

修复方法：
手动或通过脚本将新主机名映射到 127.0.0.1。

Bash
# 执行此命令，确保 localhost 和你的新主机名都指向回环地址
echo "127.0.0.1 localhost ${HOSTNAME}" > /etc/hosts
echo "::1 localhost ${HOSTNAME}" >> /etc/hosts
2. Netplan 中的 DNS/网关配置不可达
脚本中硬编码了网关和 DNS 为 10.0.0.2。如果该 IP 在你的物理网络中并不存在，或者它不具备 DNS 转发功能，系统在尝试更新或解析时会陷入长连接等待。

修复方案：

检查连通性： ping 10.0.0.2 看是否通畅。

修改 DNS： 如果内网没有 DNS 转发器，建议增加一个公共 DNS（如 223.5.5.5 或 114.114.114.114）。

3. 反向 DNS 解析 (Reverse DNS)
在使用 SSH 连接或某些交互式 shell 时，系统会尝试对连接的 IP 进行反向域名解析。如果 10.0.0.2 响应缓慢，会导致登录后操作极慢。

建议优化的脚本片段
为了防止以后出现同样的问题，建议在脚本的 第 2 步 之后添加自动更新 hosts 的逻辑，并检查网卡名称：

Bash
# ... 原脚本第 2 步后 ...
echo "127.0.0.1 localhost ${HOSTNAME}" > /etc/hosts
echo "::1 localhost ${HOSTNAME}" >> /etc/hosts

# 自动获取当前默认网卡名（防止 ens33 不存在的情况）
NIC_NAME=$(ip route | grep default | awk '{print $5}' | head -n1)
: ${NIC_NAME:=ens33} # 如果没搜到则默认为 ens33
快速修复步骤汇总
如果你现在机器已经很卡，请立即执行以下三步：

编辑 Hosts： sudo vi /etc/hosts，在第一行添加 127.0.0.1 ubuntu24-xxx（xxx 为你的 IP 末段）。

测试 DNS： ping www.baidu.com。如果 ping 不通，说明 10.0.0.2 这个 DNS 地址有问题，请修改 /etc/netplan/ 下的配置文件并再次 netplan apply。

重启会话： 退出当前 SSH 重新连接，或者直接输入 exec bash 刷新环境。

小提示： 脚本中 source /etc/profile 在非交互式脚本中对当前 Shell 进程的主机名显示生效有限，通常直接重启 Shell 或使用 exec bash 效果更好。
Last login: Wed Apr  8 05:19:03 2026 from 10.0.0.1
  0 ✓ 05:43:11 root@ubuntu24-148,10.0.0.148:~ # ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:13:01:70 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet 10.0.0.148/24 brd 10.0.0.255 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe13:170/64 scope link
       valid_lft forever preferred_lft forever
  0 ✓ 05:56:44 root@,10.0.0.148:~ # cat /etc/hosts
127.0.0.1 localhost
127.0.0.1 ubuntu24-148

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
  0 ✓ 05:57:13 root@,10.0.0.148:~ #
我怀疑问题出在dns上，目前只要我切换vpn就可以，估计是网络不可达，直接用本地的dns，一旦切换回正常网络，又开始很慢，有什么方法去debug或修复这个问题
你这个现象**完全符合 DNS 解析超时**：
- 切 VPN → 走内部/可用 DNS → 飞快
- 切回正常网络 → 系统在**超时等待 DNS 响应** → 每条命令都卡几秒

从你的提示符也能看出来：
`root@,10.0.0.148:~#`
主机名那一段**空了**，说明系统在**反向解析主机名**时卡住，直接导致 bash 极慢。

# 一、最快定位：直接测试 DNS 超时
运行这两条，看是不是要等很久才有结果：
```bash
time nslookup ubuntu24-148
time getent hosts ubuntu24-148
```
如果明显等待 2~5 秒，**100% 是 DNS 问题**。

# 二、根本原因
1. **主机名没有正确写进 /etc/hosts**
2. **DNS 服务器 10.0.0.2 在你正常网络下不可达**
3. 每条 bash 命令都会尝试解析主机名，解析超时就卡
重点：最终的修复是要么加入10.0.0.148 ubuntu24-148 到/etc/hosts，要么更改DNS为公共DNS223.5.5.5，223.6.6.6
# 三、立即修复（不用改网络，本地强制解析）
## 1）先修复 /etc/hosts（最关键）
```bash
cat > /etc/hosts <<EOF
127.0.0.1   localhost
10.0.0.148  ubuntu24-148
::1         ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
```

## 2）把 DNS 改成本地或公共 DNS（不再依赖 10.0.0.2）
```bash
cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 10.0.0.148/24
      nameservers:
        addresses:
          - 127.0.0.53
          - 223.5.5.5
          - 8.8.8.8
      routes:
        - to: default
          via: 10.0.0.2
EOF

chmod 600 /etc/netplan/50-cloud-init.yaml
netplan apply
```

## 3）再检查主机名解析
```bash
hostname
hostname -f
getent hosts $(hostname)
```
这三条应该**瞬间返回**，不再卡顿。

# 四、如果还慢，彻底关闭 bash 反向解析
编辑全局 bash 配置，禁止每次命令都去解析主机名：
```bash
echo 'export HOSTNAME=$(hostname)' >> /etc/profile
echo 'export PROMPT_COMMAND=""' >> /etc/profile
source /etc/profile
exec bash
```

# 五、Debug 命令（你可以自己复现问题）
```bash
# 跟踪 DNS 调用
strace -e trace=hostname,socket,sendto getent hosts $(hostname)

# 看 DNS 超时时间
time resolvectl query $(hostname)
```

---

# 最终结论
你慢的原因就是：
**主机名未在 hosts 中正确绑定 + DNS 服务器 10.0.0.2 外网不可达 → bash 每次解析主机名超时**

按我上面三步修复后，**立刻恢复正常速度**。
需要我帮你把脚本也改成**自动写入正确 hosts** 的最终版吗？这样以后再也不会卡。