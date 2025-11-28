---
layout: post
title:  "Ubuntu 24.04 多网卡配置最佳实践：告别 NetworkManager 的混乱"
date:   2025-11-28 11:00:00 +0800
categories: [Linux, Ubuntu, Networking, SRE]
tags: [ubuntu, netplan, networkmanager, devops]
---

在 Ubuntu 24.04 (Noble Numbat) 中配置多张网卡时，很多用户会遇到一个令人头疼的问题：**配置不生效**或者**配置被莫名其妙地覆盖**。

特别是当你试图混合使用命令行（Netplan）和图形界面（Settings/NetworkManager）时，情况会变得非常糟糕。你可能会发现 `/etc/netplan/` 目录下出现了一堆 `90-NM-*.yaml` 文件，而你手写的 `50-cloud-init.yaml` 似乎并没有完全按预期工作，甚至出现 `device not available` 的错误。

本文将深入分析这个问题，并提供一种符合 SRE 最佳实践的解决方案：**回归纯粹的声明式配置**。

## 现象分析

让我们看一个真实的案例。用户在配置双网卡环境时，遇到了如下报错：

```bash
$ nmcli conn up netplan-eth1
错误：连接激活失败：No suitable device found for this connection (device eth0 not available because profile is not compatible with device (mismatching interface name)).
```

检查 `/etc/netplan` 目录，发现了一堆文件：

```bash
$ ll /etc/netplan
-rw-------   1 root root   104  8月  6 00:54 01-network-manager-all.yaml
-rw-------   1 root root   372 11月 27 23:03 50-cloud-init.yaml
-rw-------   1 root root   686 10月 21 06:51 90-NM-142b603d-adea-3fc2-b303-32e8905e87f6.yaml
-rw-------   1 root root   716 10月 21 21:36 90-NM-97e20144-edbe-3696-bdfd-08faa089f236.yaml
```

这里发生了什么？

1.  **`01-network-manager-all.yaml`**: 这是 Ubuntu 桌面版的默认配置，它告诉 Netplan："把所有网络设备交给 NetworkManager 管理 (`renderer: NetworkManager`) "。
2.  **`50-cloud-init.yaml`**: 这是用户（或 cloud-init）手写的配置，试图定义 `eth0` 和 `eth1` 的静态 IP。
3.  **`90-NM-*.yaml`**: 这些是 NetworkManager 在图形界面中修改网络设置后自动生成的 Netplan 配置。

**冲突点在于**：NetworkManager 生成的配置（`90-NM-*`）往往具有很高的优先级（文件名数字大），而且它们通常绑定了特定的 UUID 或 MAC 地址。当你手动修改了底层的虚拟网卡（比如在 VMware 或 OpenStack 中），MAC 地址变了，但 `90-NM-*` 里的配置还死死咬住旧的 UUID/MAC 不放，导致新网卡无法被正确识别或接管。

此外，`renderer: NetworkManager` 意味着 Netplan 只是把配置传给 NetworkManager，如果 NetworkManager 自身的状态（存储在 `/etc/NetworkManager/system-connections/`）与 Netplan 生成的配置冲突，就会出现各种诡异的连接失败。

## 解决方案：拥抱声明式配置 (Declarative Configuration)

作为 SRE 或系统管理员，我们希望网络配置是**可由代码定义的 (Infrastructure as Code)**，而不是依赖于不可控的 UI 操作。

解决这个问题的最佳方案是：**清理 NetworkManager 的自动生成文件，统一使用一个 Netplan 配置文件管理所有网卡。**

### 第一步：备份并清理环境

首先，备份现有的配置，以防万一：

```bash
mkdir -p ~/netplan_backup
cp /etc/netplan/*.yaml ~/netplan_backup/
```

然后，**狠心删除**那些由 NetworkManager 生成的 `90-NM-*.yaml` 文件。这些文件是混乱的根源。

```bash
rm /etc/netplan/90-NM-*.yaml
```

### 第二步：编写统一的 Netplan 配置

我们需要创建一个干净的配置文件。你可以直接修改 `50-cloud-init.yaml`，或者创建一个新的 `01-netcfg.yaml`（确保文件名数字小于 `90`，虽然我们已经删除了干扰项）。

使用 `ip link` 确认你的物理接口名称（例如 `eth0`, `eth1` 或 `ens33` 等）。

编辑文件：

```bash
vi /etc/netplan/50-cloud-init.yaml
```

写入如下内容（根据你的实际网络环境修改 IP）：

```yaml
network:
  version: 2
  renderer: NetworkManager # 在桌面版保留这个，服务器版通常用 networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 10.0.0.13/24
      routes:
        - to: default
          via: 10.0.0.2
      nameservers:
        addresses:
          - 10.0.0.2
          - 8.8.8.8
    eth1:
      dhcp4: no
      addresses:
        - 10.0.0.113/24
      # 注意：通常只有一个默认网关（default route），
      # 除非你做策略路由，否则不要在 eth1 上也配 gateway4/routes to default
```

**关键点：**
1.  **明确指定接口名**：直接对 `eth0`, `eth1` 进行配置。
2.  **不要写 `match` 除非必要**：NetworkManager 生成的文件喜欢用 `match: {name: "ens33"}`，这在虚拟化环境中容易出问题。直接在 `ethernets:` 下声明接口名通常更稳健。
3.  **单一网关**：在一个系统中，通常只能有一个默认网关。不要在两个网卡上都配置 `gateway4` 或 `routes: - to: default`，否则会导致路由冲突，网络时断时续。只在主出口网卡（如 `eth0`）配置网关。

### 第三步：应用配置

清理并应用配置：

```bash
netplan apply
```

此时，Netplan 会重新生成后端配置。

### 第四步：验证

检查 IP 地址是否生效：

```bash
ip addr
```

检查路由表：

```bash
ip route
```

你应该能看到两条干净的路由记录，且没有多余的干扰。

## 常见问题排查 (Troubleshooting)

### 报错：`Unit dbus-org.freedesktop.network1.service not found`

在执行 `netplan apply` 时，你可能会遇到如下报错：

```text
systemd-networkd is not running, output might be incomplete.
Failed to reload network settings: Unit dbus-org.freedesktop.network1.service not found.
Falling back to a hard restart of systemd-networkd.service
```

**原因**：
这通常发生在你的系统中没有安装或启用 `systemd-networkd` 服务，但 Netplan 试图与它交互。这种情况在某些精简版系统或桌面版系统中很常见。

**解决方案**：
既然我们指定了 `renderer: NetworkManager`，我们可以绕过 `netplan apply` 对 `systemd-networkd` 的依赖，直接生成配置并重载 NetworkManager。

1.  **生成配置**：
    ```bash
    netplan generate
    ```
    这会在 `/run/NetworkManager/system-connections/` 下生成对应的配置文件。

2.  **重载 NetworkManager**：
    ```bash
    systemctl reload NetworkManager
    ```

3.  **激活连接**（如果需要）：
    ```bash
    nmcli connection up netplan-eth0
    nmcli connection up netplan-eth1
    ```

通过这种方式，你可以避免 `netplan apply` 的报错，并确保配置被 NetworkManager 正确加载。

### 报错：`No suitable device found for this connection`

如果你在启动连接时遇到如下报错：

```text
错误：连接激活失败：No suitable device found for this connection (device eth0 not available because profile is not compatible with device (mismatching interface name)).
```

**原因**：
这通常意味着你配置文件中指定的网卡名称（例如 `eth1`）在系统中**根本不存在**。NetworkManager 找不到名为 `eth1` 的设备，尝试用 `eth0` 顶替但发现名称不匹配，于是报错。

**解决方案**：
1.  **检查物理网卡**：
    运行 `ip link` 或 `ip a` 查看当前系统实际识别到的网卡。
    ```bash
    ip link
    ```
    如果输出中只有 `lo` 和 `eth0`，没有 `eth1`，说明系统内核没有识别到第二张网卡。

2.  **排查硬件/虚拟化层**：
    *   **虚拟机**：检查 VMware/VirtualBox/KVM 设置，确认是否真的添加了第二张网卡，且网卡已连接。
    *   **驱动**：某些新网卡可能需要安装额外驱动。
    *   **命名规则**：有时网卡可能被识别为 `ens34`、`enp2s0` 等其他名字，而不是 `eth1`。请根据 `ip link` 的实际输出来修改 Netplan 配置文件中的接口名。

### 进阶技巧：没有物理网卡？使用 Dummy 接口模拟

如果你只是想在实验环境中测试多网卡配置，或者需要一个独立的本地 IP，而不想去 VMware 里添加硬件，你可以使用 Linux 的 **Dummy Interface**。

Dummy 接口完全由软件生成，就像 Loopback 一样。

修改 `/etc/netplan/50-cloud-init.yaml`，添加 `modprobe` 逻辑（通常 Netplan 会自动处理，或者我们可以手动声明）：

```yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 10.0.0.13/24
      routes:
        - to: default
          via: 10.0.0.2
      nameservers:
        addresses:
          - 10.0.0.2
          - 8.8.8.8
  # 添加 dummy 设备
  bridges:
    # 这里我们用 bridge 或者直接声明 dummy (Netplan 新版支持 nm-devices 但配置较复杂)
    # 最简单的方法是欺骗系统，或者使用 ip link add
    # 但在 Netplan 中，标准的做法是声明一个虚拟设备
    dummy0:
      interfaces: []
      addresses:
        - 10.0.0.113/24
```

**注意**：标准的 Netplan 对 Dummy 接口的支持依赖于 `networkd`。如果你使用 `NetworkManager` 作为 renderer，最简单的方法是直接用 `nmcli` 生成一个 dummy 接口，或者在 Netplan 中配置但可能需要手动加载模块。

**更简单的替代方案（命令行一键生成）**：

你提到的 `nmcli conn add` 确实可以做到！如果你想用命令行"凭空变出"一张网卡（Dummy Interface），可以使用以下命令：

```bash
# 0. 彻底清理环境（非常重要！）
# 删除所有 NetworkManager 的运行时连接配置
rm -f /run/NetworkManager/system-connections/*
# 重新生成干净的 Netplan 配置
netplan generate
# 重载 NetworkManager
systemctl reload NetworkManager

# 删除旧的虚拟设备
ip link delete eth1 2>/dev/null

# 1. 创建一对 veth 设备，其中一端命名为 eth1
ip link add eth1 type veth peer name v-peer1
ip link set eth1 up
ip link set v-peer1 up

systemctl restart NetworkManager
```

**为什么这样做？**
你的 Netplan 配置 (`ethernets:`) 生成的是 **Ethernet** 类型的连接配置。
之前的 `dummy` 设备在 NetworkManager 中被识别为 `dummy` 类型，导致类型不匹配 (`ethernet` != `dummy`)，所以连接无法激活。

使用 `veth` (Virtual Ethernet) 设备，NetworkManager 会将其视为标准的以太网设备兼容，从而能顺利应用 Netplan 的配置。

**验证**：
执行完上述命令后，执行 `nmcli device`，你应该能看到 `eth1` 变成了 `connected` 状态，且类型显示为 `ethernet` (或 `veth`)。

`ip a` 命令应该能显示 `eth1` (或 `eth1@v-peer1`) 已经获取了 IP `10.0.0.113`。

> **提示**：如果你发现 `nmcli conn show` 中还有一些未使用的"幽灵"连接（如 `eth1`, `eth2` 等），它们可能是你之前手动创建的持久化配置。
> 你可以使用 `nmcli conn delete [UUID]` 删除它们，或者检查 `/etc/NetworkManager/system-connections/` 目录并手动清理。

**注意**：`ip link` 创建的设备重启后会消失。

### 常见误区：`nmcli conn add` 能创建网卡吗？

很多用户尝试使用如下命令来"添加网卡"：

```bash
nmcli conn add type ethernet ifname eth1 con-name netplan-eth1
```

**这是无效的**。这条命令只是创建了一个**配置文件**（Connection Profile），它告诉系统"如果有一个叫 eth1 的设备出现，就用这个配置去连接它"。但它**不会**创建 `eth1` 这个设备本身。

这就是为什么你会遇到 `No suitable device found` 的错误。

**必须使用 `ip link`** 来创建虚拟硬件（veth/dummy），NetworkManager 才能找到设备并应用配置。

### 问：能直接写在 Netplan YAML 里吗？（持久化配置）

你可能会问：*这些 `ip link` 命令能不能直接写进 YAML 文件，让 Netplan 自动创建？*

**答案是：对于 `veth` 设备，Netplan 目前的原生语法（特别是配合 NetworkManager 时）并不支持直接"创建"它们。** Netplan 主要负责**配置**已经存在的接口（或者创建 Bridge/VLAN 等逻辑接口）。

要让这个虚拟网卡在重启后依然存在，我们需要使用 systemd 服务来在开机时自动创建它。

**最佳实践：创建一个 systemd 服务**

创建一个文件 `/etc/systemd/system/setup-veth.service`：

```ini
[Unit]
Description=Setup Veth Interface for Netplan
Before=NetworkManager.service
After=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ip link add eth1 type veth peer name v-peer1
ExecStart=/usr/bin/ip link set eth1 up
ExecStart=/usr/bin/ip link set v-peer1 up
ExecStop=/usr/bin/ip link delete eth1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

启用并运行该服务：

```bash
systemctl enable --now setup-veth.service
```

这样，每次开机时，这个服务都会在 NetworkManager 启动之前先把 `eth1` 这根"虚拟网线"插好，然后 Netplan/NetworkManager 启动时就能顺利接管并配置 IP 了。

**更简单的替代方案（单网卡多 IP）**：
如果你只是需要第二个 IP，不需要第二个物理接口，可以直接在 `eth0` 下写两个 IP：

```yaml
    eth0:
      addresses:
        - 10.0.0.13/24
        - 10.0.0.113/24
```

这样 `eth0` 会同时拥有两个 IP 地址，完全满足服务监听的需求。

## 总结

在 Ubuntu 24.04 中管理多网卡，**"Less is More"**。

1.  **避免使用 UI 配置服务器网络**：UI 生成的配置不透明且难以维护。
2.  **清理 `90-NM-*.yaml`**：这些是混乱之源。
3.  **统一入口**：只维护一个 YAML 文件（如 `50-cloud-init.yaml`）。
4.  **注意路由优先级**：不要配置多个默认网关。

通过这种方式，你将获得一个稳定、可复现且易于排错的网络环境。
