---
layout: post
title: 解决Linux parted命令"无法辨识的磁盘卷标"错误
categories: [linux, disk]
description: 详细解释如何解决Linux系统中使用parted命令分区时遇到的"无法辨识的磁盘卷标"错误
keywords: linux, parted, disk, partition, unknown disk label
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

## 情境(Situation)

在VMware虚拟机环境中，当尝试使用`parted`命令对新添加的磁盘（`/dev/sdb`）进行分区操作时，系统返回了"无法辨识的磁盘卷标"错误信息。具体操作和错误信息如下：

```bash
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary 1 1001 
错误: /dev/sdb: 无法辨识的磁盘卷标

root@ubuntu24,10.0.0.13:~ # parted /dev/sdb print 
错误: /dev/sdb: 无法辨识的磁盘卷标
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：unknown 
磁盘标志：

root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary ext4 1102MB 1902MB 
错误: /dev/sdb: 无法辨识的磁盘卷标
```

## 冲突(Conflict)

用户期望能够直接使用`parted`命令对新磁盘进行分区，但系统提示"无法辨识的磁盘卷标"，导致所有分区操作都失败。这是因为新添加的磁盘尚未创建分区表，而`parted`命令需要先有分区表才能进行分区操作。

## 问题(Question)

如何解决"无法辨识的磁盘卷标"错误，成功对新磁盘进行分区操作？

## 答案(Answer)

解决这个问题的关键是先为磁盘创建分区表，然后再进行分区操作。以下是详细的解决步骤：

### 步骤1：查看磁盘信息

首先，使用`parted`命令查看磁盘的详细信息，确认磁盘状态：

```bash
parted /dev/sdb print
```

如果磁盘没有分区表，会看到类似以下输出：

```
错误: /dev/sdb: 无法辨识的磁盘卷标
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：unknown 
磁盘标志：
```

### 步骤2：创建分区表

使用`mklabel`命令为磁盘创建分区表。常用的分区表类型有：
- `msdos`：适用于传统BIOS系统，支持最多4个主分区
- `gpt`：适用于UEFI系统，支持更多分区和更大的磁盘容量

根据你的系统类型选择合适的分区表类型。对于现代系统，推荐使用GPT分区表：

```bash
parted /dev/sdb mklabel gpt
```

或者使用传统的MSDOS分区表：

```bash
parted /dev/sdb mklabel msdos
```

### 步骤3：验证分区表创建成功

再次使用`print`命令查看磁盘信息，确认分区表已成功创建：

```bash
parted /dev/sdb print
```

成功创建分区表后，会看到类似以下输出（以GPT为例）：

```
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt
磁盘标志：

编号  开始：  结束：   大小：    文件系统  名称  标志
```

### 步骤4：创建分区

现在可以使用`mkpart`命令创建分区了。以下是一些示例：

1. 创建一个主分区（从1MB开始，到1000MB结束，使用ext4文件系统）：

```bash
parted /dev/sdb mkpart primary ext4 1MB 1000MB
```

2. 使用百分比创建分区（从3%开始，到10%结束）：

```bash
parted /dev/sdb mkpart primary ext4 3% 10%
```

3. 创建一个交换分区：

```bash
parted /dev/sdb mkpart primary linux-swap 1001MB 2000MB
```

### 步骤5：格式化分区

分区创建完成后，需要使用`mkfs`命令格式化分区：

```bash
# 格式化第一个分区为ext4
mkfs.ext4 /dev/sdb1

# 格式化第二个分区为交换分区
mkswap /dev/sdb2
```

### 步骤6：挂载分区

最后，将分区挂载到系统中使用：

```bash
# 创建挂载点
mkdir -p /mnt/data

# 挂载分区
mount /dev/sdb1 /mnt/data

# 设置开机自动挂载
echo '/dev/sdb1 /mnt/data ext4 defaults 0 2' >> /etc/fstab
```

## 总结

"无法辨识的磁盘卷标"错误是因为新磁盘尚未创建分区表导致的。解决这个问题的步骤是：

1. 使用`parted /dev/sdb print`查看磁盘信息
2. 使用`parted /dev/sdb mklabel gpt`或`msdos`创建分区表
3. 使用`mkpart`命令创建分区
4. 使用`mkfs`命令格式化分区
5. 挂载分区并设置开机自动挂载

通过以上步骤，你可以成功解决"无法辨识的磁盘卷标"错误，完成对新磁盘的分区和使用。