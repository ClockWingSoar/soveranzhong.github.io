---
layout: post
title: "Linux磁盘存储完全指南：从MBR到LVM的全面总结"
date: 2025-11-10 10:00:00 +0800
categories: [Linux, 系统管理]
tags: [Linux, 磁盘管理, MBR, GPT, RAID, LVM, 文件系统, Shell脚本]
---

# Linux磁盘存储完全指南：从MBR到LVM的全面总结

磁盘存储管理是Linux系统管理中的核心技能之一。无论是服务器配置、数据存储规划还是系统优化，深入理解磁盘存储概念和管理技术都至关重要。本文将全面总结Linux环境下的磁盘存储术语、分区技术、文件系统管理、RAID配置以及LVM逻辑卷管理，并通过实际案例帮助您掌握这些关键知识点。

## 1. 磁盘存储基础术语

### 1.1 物理磁盘与逻辑磁盘

- **物理磁盘(Physical Disk)**：实际的硬件设备，如硬盘(HDD)、固态硬盘(SSD)等
- **逻辑磁盘(Logical Disk)**：通过分区、RAID或LVM等技术在物理磁盘上创建的逻辑存储单元
- **块设备(Block Device)**：以固定大小的块为单位进行数据传输的设备，Linux中通常以`/dev/sdX`、`/dev/vdX`等命名

### 1.2 分区相关术语

- **分区(Partition)**：将物理磁盘划分为多个独立的逻辑区域
- **主分区(Primary Partition)**：可以直接被操作系统识别和使用的分区
- **扩展分区(Extended Partition)**：一种特殊的主分区，可以容纳多个逻辑分区
- **逻辑分区(Logical Partition)**：在扩展分区内创建的分区
- **分区表(Partition Table)**：记录磁盘分区信息的数据结构，如MBR和GPT

### 1.3 文件系统术语

- **文件系统(File System)**：管理和存储文件数据的方法和数据结构
- **挂载点(Mount Point)**：文件系统与目录树的连接点
- **inode**：存储文件元数据的数据结构
- **块(Block)**：文件系统中数据存储的最小单位
- **超级块(Super Block)**：存储文件系统整体信息的数据结构

## 2. MBR与GPT分区表对比

### 2.1 MBR分区表

**MBR(Master Boot Record)**是一种传统的磁盘分区表格式，存储在磁盘的第一个扇区(512字节)。

**主要特点：**
- 最大支持2TB的磁盘容量
- 最多只能创建4个主分区，或3个主分区+1个扩展分区
- 使用32位数值表示扇区数
- 包含引导代码区域(446字节)、分区表(64字节)和结束标志(2字节)
- 分区表采用16进制格式存储分区信息

**适用场景：**
- 传统BIOS引导的系统
- 磁盘容量小于2TB的系统
- 不需要超过4个主分区的简单配置

### 2.2 GPT分区表

**GPT(GUID Partition Table)**是一种现代的分区表格式，是UEFI规范的一部分。

**主要特点：**
- 支持超过2TB的大容量磁盘，理论上最大支持9.4ZB
- 最多可以创建128个主分区(Windows)或更多(Linux)
- 使用64位数值表示扇区数
- 包含备份分区表，提供更好的数据安全性
- 使用GUID(全局唯一标识符)标识分区类型
- 包含循环冗余校验(CRC)值，提高数据完整性

**适用场景：**
- UEFI引导的系统
- 大容量磁盘(>2TB)
- 需要创建多个分区的复杂配置
- 对数据安全性要求较高的环境

### 2.3 MBR与GPT对比总结

| 特性 | MBR | GPT |
|------|-----|-----|
| 最大磁盘容量 | 2TB | 9.4ZB |
| 最大分区数 | 4个主分区 | 128个+ |
| 引导方式 | BIOS | UEFI/BIOS兼容模式 |
| 分区标识 | 类型ID(1字节) | GUID |
| 数据恢复 | 无内置机制 | 备份分区表 |
| 数据完整性 | 无校验 | CRC校验 |
| 兼容性 | 所有系统 | 现代系统(Windows Vista+) |

## 3. 分区与文件系统管理

### 3.1 分区管理工具

#### fdisk

**功能**：传统的磁盘分区工具，支持MBR和GPT(部分版本)

**基本操作**：
```bash
# 列出所有磁盘和分区
fdisk -l

# 对特定磁盘进行分区
fdisk /dev/sdb

# 在fdisk交互模式中常用命令
d   # 删除分区
n   # 创建新分区
p   # 显示分区表
q   # 退出不保存
w   # 保存并退出
t   # 更改分区类型
```

#### gdisk

**功能**：GPT专用分区工具，是fdisk的GPT版本

**基本操作**：
```bash
# 对磁盘进行GPT分区
gdisk /dev/sdb

# 在gdisk交互模式中常用命令
n   # 创建新分区
d   # 删除分区
p   # 显示分区表
q   # 退出不保存
w   # 保存并退出
```

#### parted

**功能**：高级分区工具，支持MBR和GPT，适合脚本化操作

**基本操作**：
```bash
# 交互式分区
parted /dev/sdb

# 非交互式创建分区
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary ext4 0% 100%

# 列出分区信息
parted /dev/sdb print
```

### 3.2 文件系统管理

#### 常用文件系统

- **ext4**：Linux主流文件系统，稳定性好，性能优秀
- **XFS**：高性能64位文件系统，适合大文件和大容量存储
- **Btrfs**：新一代文件系统，支持快照、校验等高级特性
- **ZFS**：企业级文件系统，强大的数据完整性和存储池功能
- **FAT32/NTFS**：Windows兼容的文件系统

#### 文件系统创建与管理

**格式化分区**：
```bash
# 创建ext4文件系统
mkfs.ext4 /dev/sdb1

# 创建XFS文件系统
mkfs.xfs /dev/sdb1

# 创建Btrfs文件系统
mkfs.btrfs /dev/sdb1
```

**挂载与卸载**：
```bash
# 临时挂载
mount /dev/sdb1 /mnt/data

# 永久挂载（编辑/etc/fstab）
/dev/sdb1  /mnt/data  ext4  defaults  0  2

# 卸载
umount /mnt/data
```

**文件系统检查与修复**：
```bash
# 检查ext4文件系统
e2fsck -f /dev/sdb1

# 检查XFS文件系统
xfs_check /dev/sdb1

# 修复XFS文件系统
xfs_repair /dev/sdb1
```

## 4. RAID技术详解

### 4.1 RAID概述

**RAID(Redundant Array of Independent Disks)**是一种通过将多个物理磁盘组合成逻辑单元来提供数据冗余、提高性能或两者兼有的技术。

### 4.2 RAID级别对比

#### RAID 0

**工作原理**：
- 数据被分割成多个块，并行写入多个磁盘
- 没有数据冗余，注重性能提升

**特点**：
- **利用率**：100%（所有磁盘空间都用于存储数据）
- **冗余性**：无（任何一个磁盘故障都会导致数据丢失）
- **性能**：读写性能显著提升（理论上是单个磁盘的n倍）
- **最少硬盘数**：2个

**适用场景**：
- 对性能要求极高，对数据安全性要求低的场景
- 临时数据存储、视频编辑等

#### RAID 1

**工作原理**：
- 数据完全镜像到另一个磁盘
- 通过数据冗余提供容错能力

**特点**：
- **利用率**：50%（一半空间用于存储，一半用于镜像）
- **冗余性**：高（允许最多一个磁盘故障）
- **性能**：读性能提升，写性能略有下降
- **最少硬盘数**：2个

**适用场景**：
- 对数据安全性要求极高的场景
- 系统盘、数据库日志等关键数据存储

#### RAID 5

**工作原理**：
- 数据和校验信息分布存储在所有磁盘上
- 使用奇偶校验提供容错能力

**特点**：
- **利用率**：(n-1)/n（n为磁盘数量）
- **冗余性**：中等（允许最多一个磁盘故障）
- **性能**：读性能良好，写性能受校验计算影响
- **最少硬盘数**：3个

**适用场景**：
- 文件服务器、应用服务器等对性能和可靠性都有要求的场景

#### RAID 10

**工作原理**：
- 先创建RAID 1镜像，再将多个镜像组合成RAID 0
- 结合了RAID 0的性能和RAID 1的冗余性

**特点**：
- **利用率**：50%（与RAID 1相同）
- **冗余性**：高（允许每个镜像组中最多一个磁盘故障）
- **性能**：读写性能都有显著提升
- **最少硬盘数**：4个（2个镜像组，每组2个磁盘）

**适用场景**：
- 数据库服务器、高IO负载的应用服务器
- 对性能和可靠性都有极高要求的场景

#### RAID 01

**工作原理**：
- 先创建RAID 0条带，再将多个条带组合成RAID 1
- 与RAID 10的实现方式相反

**特点**：
- **利用率**：50%
- **冗余性**：中等（如果同一RAID 0条带中的两个磁盘同时故障，整个RAID将失效）
- **性能**：读写性能良好
- **最少硬盘数**：4个

**与RAID 10的区别**：
- RAID 10的容错性更好，即使两个磁盘故障，只要不在同一镜像组，系统仍可运行
- RAID 01的容错性较差，如果同一RAID 0条带中的两个磁盘故障，整个阵列将崩溃

### 4.3 Linux软件RAID配置

使用mdadm工具配置软件RAID：

```bash
# 安装mdadm
sudo apt install mdadm  # Debian/Ubuntu
sudo yum install mdadm  # CentOS/RHEL

# 创建RAID 10（2个镜像组，每组2个磁盘）
sudo mdadm --create /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

# 查看RAID状态
sudo mdadm --detail /dev/md0

# 监控RAID重建进度
cat /proc/mdstat

# 保存RAID配置
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
```

## 5. LVM逻辑卷管理

### 5.1 LVM基本原理

**LVM(Logical Volume Manager)**是Linux环境下的逻辑卷管理工具，通过抽象物理存储设备，提供灵活的存储管理能力。

**核心概念**：
- **物理卷(PV - Physical Volume)**：物理存储设备（硬盘分区或整个硬盘）
- **卷组(VG - Volume Group)**：由多个物理卷组成的存储池
- **物理扩展(PE - Physical Extent)**：物理卷中可分配的最小存储单元
- **逻辑卷(LV - Logical Volume)**：从卷组中分配的逻辑存储单元，可以被格式化和挂载
- **逻辑扩展(LE - Logical Extent)**：逻辑卷中的最小存储单元，与物理扩展一一对应

**LVM的主要优势**：
- 动态调整卷大小，无需停机
- 支持快照功能，便于备份和恢复
- 可以将多个物理设备合并成一个逻辑存储单元
- 提供更灵活的磁盘空间管理

### 5.2 LVM基本操作

#### 创建LVM

```bash
# 1. 初始化物理卷
pvcreate /dev/sdb1 /dev/sdc1

# 2. 创建卷组
vgcreate data_vg /dev/sdb1 /dev/sdc1

# 3. 创建逻辑卷
lvcreate -L 100G -n data_lv data_vg
# 或按百分比分配
lvcreate -l 100%FREE -n data_lv data_vg

# 4. 创建文件系统
mkfs.ext4 /dev/data_vg/data_lv

# 5. 挂载逻辑卷
mkdir /mnt/data
mount /dev/data_vg/data_lv /mnt/data
```

#### 扩展LVM

```bash
# 1. 添加新的物理卷到卷组
pvcreate /dev/sdd1
vgextend data_vg /dev/sdd1

# 2. 扩展逻辑卷
lvextend -L +50G /dev/data_vg/data_lv
# 或使用全部可用空间
lvextend -l +100%FREE /dev/data_vg/data_lv

# 3. 扩展文件系统
resize2fs /dev/data_vg/data_lv  # 对于ext4文件系统
# 或
xfs_growfs /dev/data_vg/data_lv  # 对于XFS文件系统
```

#### LVM快照

```bash
# 创建快照
lvcreate -L 10G -s -n data_snap /dev/data_vg/data_lv

# 挂载快照\mkdir /mnt/snap
mount /dev/data_vg/data_snap /mnt/snap

# 删除快照
umount /mnt/snap
lvremove /dev/data_vg/data_snap
```

#### 查看LVM信息

```bash
# 查看物理卷
pvs
pvdisplay

# 查看卷组
vgs
vgdisplay

# 查看逻辑卷
lvs
lvdisplay
```

### 5.3 LVM实战实验

#### 实验：创建LVM并实现磁盘扩容

**实验环境**：
- 3个新的磁盘分区：/dev/sdb1, /dev/sdc1, /dev/sdd1
- 初始需求：创建100G逻辑卷
- 扩容需求：将逻辑卷扩展到200G

**实验步骤**：

1. **准备物理卷**
```bash
pvcreate /dev/sdb1 /dev/sdc1
pvs  # 验证物理卷创建成功
```

2. **创建卷组**
```bash
vgcreate project_vg /dev/sdb1 /dev/sdc1
vgs  # 验证卷组创建成功
```

3. **创建初始逻辑卷**
```bash
lvcreate -L 100G -n project_lv project_vg
lvs  # 验证逻辑卷创建成功
```

4. **格式化并挂载**
```bash
mkfs.xfs /dev/project_vg/project_lv
mkdir /mnt/project
mount /dev/project_vg/project_lv /mnt/project
df -h /mnt/project  # 查看挂载情况
```

5. **模拟数据写入**
```bash
dd if=/dev/zero of=/mnt/project/test_file bs=1G count=50
```

6. **扩展逻辑卷**

```bash
#添加新磁盘到卷组
pvcreate /dev/sdd1
vgextend project_vg /dev/sdd1

#扩展逻辑卷
lvextend -L 200G /dev/project_vg/project_lv

#扩展文件系统
xfs_growfs /dev/project_vg/project_lv

#验证扩容成功
df -h /mnt/project
```

## 6. Shell变量与猜数字游戏

### 6.1 Shell变量命名规则

**基本规则**：
- 变量名必须以字母或下划线开头
- 变量名只能包含字母、数字和下划线
- 变量名区分大小写
- 避免使用Shell保留字和特殊字符
- 变量名应该有描述性，便于理解

**命名约定**：
- 环境变量：通常使用大写字母（如PATH, HOME）
- 局部变量：通常使用小写字母（如count, name）
- 只读变量：通常使用大写字母（如VERSION）
- 数组变量：通常使用复数形式（如files, users）

### 6.2 不同类型变量的使用

#### 环境变量

环境变量对当前Shell会话和其子进程可见：

```bash
# 设置环境变量
export PATH=$PATH:/usr/local/bin
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

# 查看环境变量
echo $PATH
echo $JAVA_HOME
printenv  # 显示所有环境变量
```

#### 位置变量

位置变量用于获取脚本或函数的参数：

```bash
# $0: 脚本名称
# $1-$9: 第1-9个参数
# ${10}: 第10个及以上参数
# $*: 所有参数作为单个字符串
# $@: 所有参数作为独立字符串
# $#: 参数个数

#!/bin/bash
echo "脚本名称: $0"
echo "第一个参数: $1"
echo "第二个参数: $2"
echo "参数个数: $#"
echo "所有参数: $@"
```

#### 只读变量

只读变量设置后不能被修改或删除：

```bash
# 设置只读变量
readonly PI=3.14159
declare -r VERSION="2.0.1"

# 尝试修改会报错
# PI=3.14  # 这会失败
```

#### 局部变量

局部变量仅在定义它的函数或代码块中可见：

```bash
#!/bin/bash

# 全局变量
GLOBAL_VAR="这是全局变量"

my_function() {
  # 局部变量
  local LOCAL_VAR="这是局部变量"
  echo "函数内访问局部变量: $LOCAL_VAR"
  echo "函数内访问全局变量: $GLOBAL_VAR"
}

my_function
echo "函数外访问全局变量: $GLOBAL_VAR"
echo "函数外访问局部变量: $LOCAL_VAR"  # 这会是空值
```

#### 状态变量

状态变量用于存储命令执行的结果状态：

```bash
# $?: 上一个命令的退出状态（0表示成功，非0表示失败）
# $$: 当前Shell进程ID
# $!: 上一个后台命令的进程ID
# $_: 上一个命令的最后一个参数

ls -l /nonexistent
if [ $? -ne 0 ]; then
  echo "命令执行失败"
fi

echo "当前进程ID: $$"
sleep 100 &
echo "后台进程ID: $!"
```

### 6.3 猜数字游戏脚本

下面是一个基于Shell的猜数字游戏，包含用户交互和提示功能：

```bash
#!/bin/bash

# 猜数字游戏

echo "=== 猜数字游戏 ==="
echo "我已经想好了一个1到100之间的数字，快来猜猜看吧！"

# 生成1到100之间的随机数
target=$((RANDOM % 100 + 1))
guesses=0

# 游戏主循环
while true; do
  # 提示用户输入
  read -p "请输入你的猜测: " guess
  
  # 增加猜测次数
  guesses=$((guesses + 1))
  
  # 检查输入是否为有效数字
  if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
    echo "错误：请输入有效的数字！"
    continue
  fi
  
  # 检查范围
  if [ "$guess" -lt 1 ] || [ "$guess" -gt 100 ]; then
    echo "错误：请输入1到100之间的数字！"
    continue
  fi
  
  # 比较猜测与目标
  if [ "$guess" -eq "$target" ]; then
    echo "恭喜你猜对了！数字就是 $target！"
    echo "你总共用了 $guesses 次猜测。"
    
    # 根据猜测次数给予评价
    if [ "$guesses" -le 5 ]; then
      echo "太棒了！你是猜数字高手！"
    elif [ "$guesses" -le 10 ]; then
      echo "不错！你的直觉很好！"
    else
      echo "再接再厉，下次会做得更好！"
    fi
    break
  elif [ "$guess" -lt "$target" ]; then
    echo "太小了！试试更大的数字。"
  else
    echo "太大了！试试更小的数字。"
  fi
done

echo "游戏结束，谢谢参与！"
```

**脚本使用说明**：
1. 将脚本保存为`guess_number.sh`
2. 添加执行权限：`chmod +x guess_number.sh`
3. 运行脚本：`./guess_number.sh`
4. 根据提示输入数字，系统会提示你猜的数字是大了还是小了
5. 猜对后会显示猜测次数和相应的评价

## 7. 总结

本文全面介绍了Linux环境下的磁盘存储管理技术，从基本术语到高级配置，涵盖了MBR与GPT分区表、文件系统管理、RAID技术、LVM逻辑卷管理以及Shell变量和脚本。通过掌握这些技术，您可以更有效地管理Linux系统的存储资源，提高系统的可靠性、性能和灵活性。

磁盘存储管理是一个持续学习的过程，随着存储技术的发展，新的技术和工具不断涌现。建议读者通过实际操作来加深理解，并关注最新的存储技术发展动态，不断提升自己的系统管理技能。

最后，希望本文的内容对您有所帮助，让您在Linux系统管理的道路上更进一步！