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

## 实践案例

以下是一个完整的实践案例，展示了如何解决"无法辨识的磁盘卷标"错误并完成磁盘分区：

```bash
# 1. 尝试创建分区，遇到"无法辨识的磁盘卷标"错误
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary 1 1001 
错误: /dev/sdb: 无法辨识的磁盘卷标

# 2. 查看磁盘信息，确认分区表状态
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb print 
错误: /dev/sdb: 无法辨识的磁盘卷标
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：unknown 
磁盘标志：

# 3. 创建GPT分区表
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mklabel gpt 
信息: 你可能需要 /etc/fstab。

# 4. 验证分区表创建成功
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb print 
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt 
磁盘标志：

编号  起始点  结束点  大小  文件系统  名称  标志

# 5. 创建第一个分区（1MB-1001MB）
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary 1 1001 
信息: 你可能需要 /etc/fstab。

# 6. 查看分区创建结果
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb print 
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt 
磁盘标志：

编号  起始点  结束点  大小    文件系统  名称     标志
 1    1049kB  1001MB  1000MB            primary

# 7. 创建第二个分区（1002MB-1102MB）
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary 1002 1102 
信息: 你可能需要 /etc/fstab。

# 8. 创建第三个分区（1102MB-1902MB，指定ext4文件系统）
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb mkpart primary ext4 1102MB 1902MB 
信息: 你可能需要 /etc/fstab。

# 9. 进入parted交互模式
root@ubuntu24,10.0.0.13:~ # parted /dev/sdb 
GNU Parted 3.6 
使用 /dev/sdb 
欢迎使用 GNU Parted！输入 'help' 来查看命令列表。

# 10. 使用百分比创建分区（3%-10%，ext4文件系统）
(parted) mkpart primary ext4 3% 10%

# 11. 使用百分比创建分区（10%-20%，xfs文件系统）
(parted) mkpart primary xfs 10% 20%

# 12. 查看所有分区结果
(parted) print 
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt 
磁盘标志：

编号  起始点  结束点  大小    文件系统  名称     标志
 1    1049kB  1001MB  1000MB            primary
 2    1002MB  1102MB  99.6MB            primary
 3    1102MB  1902MB  800MB             primary
 4    6442MB  21.5GB  15.0GB  ext4      primary
 5    21.5GB  42.9GB  21.5GB  xfs       primary

# 13. 退出parted交互模式
(parted) quit
```

这个实践案例展示了从遇到错误到成功创建多个分区的完整过程，包括使用MB和百分比两种方式指定分区大小，以及指定不同的文件系统类型。

## 扩展：分区管理进阶

除了基本的分区创建，parted还提供了其他实用的分区管理功能。以下是一些常用的进阶操作：

### 1. 查看分区信息

除了使用`parted print`命令，还可以使用`lsblk`和`fdisk`命令查看分区信息：

```bash
# 使用lsblk查看分区信息（简洁视图）
lsblk -l /dev/sdb

# 输出示例：
NAME MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS 
sdb    8:16   0  200G  0 disk 
sdb1   8:17   0  954M  0 part 
sdb2   8:18   0   95M  0 part 
sdb3   8:19   0  763M  0 part 
sdb4   8:20   0   14G  0 part 
sdb5   8:21   0   20G  0 part 

# 使用fdisk查看分区详细信息
fdisk -l /dev/sdb

# 输出示例：
Disk /dev/sdb：200 GiB，214748364800 字节，419430400 个扇区 
Disk model: VMware Virtual S 
单元：扇区 / 1 * 512 = 512 字节 
扇区大小(逻辑/物理)：512 字节 / 512 字节 
I/O 大小(最小/最佳)：512 字节 / 512 字节 
磁盘标签类型：gpt 
磁盘标识符：DF048428-F43B-45B1-8EDB-2AB719D6B685 

设备           起点     末尾     扇区  大小 类型 
/dev/sdb1      2048  1955839  1953792  954M Linux 文件系统 
/dev/sdb2   1957888  2152447   194560   95M Linux 文件系统 
/dev/sdb3   2152448  3715071  1562624  763M Linux 文件系统 
/dev/sdb4  12582912 41943039 29360128   14G Linux 文件系统 
/dev/sdb5  41943040 83886079 41943040   20G Linux 文件系统 
```

### 2. 调整分区大小

使用`resizepart`命令可以调整现有分区的大小。以下是调整分区大小的示例：

```bash
# 调整第3个分区的大小到4000MB
parted /dev/sdb resizepart 3 4000MB

# 查看调整后的分区信息
parted /dev/sdb print

# 输出示例：
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt 
磁盘标志： 

编号  起始点  结束点  大小    文件系统  名称     标志
 1    1049kB  1001MB  1000MB            primary
 2    1002MB  1102MB  99.6MB            primary
 3    1102MB  4000MB  2898MB            primary  # 大小已调整为2898MB
 4    6442MB  21.5GB  15.0GB            primary
 5    21.5GB  42.9GB  21.5GB            primary
```

**注意：** 调整分区大小后，还需要使用相应的文件系统工具（如`resize2fs` for ext4，`xfs_growfs` for XFS）来调整文件系统大小，使其与新的分区大小匹配。

### 3. 删除分区

使用`rm`命令可以删除不再需要的分区。以下是删除分区的示例：

```bash
# 删除第4个分区
parted /dev/sdb rm 4

# 查看删除后的分区信息
parted /dev/sdb print

# 输出示例：
型号：VMware, VMware Virtual S (scsi) 
磁盘 /dev/sdb: 215GB 
扇区大小 (逻辑/物理)：512B/512B 
分区表：gpt 
磁盘标志： 

编号  起始点  结束点  大小    文件系统  名称     标志 
 1    1049kB  1001MB  1000MB            primary 
 2    1002MB  1102MB  99.6MB            primary 
 3    1102MB  4000MB  2898MB            primary 
 5    21.5GB  42.9GB  21.5GB            primary 
```

**注意：** 删除分区前，请确保该分区上的数据已备份，且不再需要。删除分区后，数据将无法恢复。同时，如果该分区已挂载在系统中，需要先卸载分区再进行删除操作。

## 总结

"无法辨识的磁盘卷标"错误是因为新磁盘尚未创建分区表导致的。解决这个问题的步骤是：

1. 使用`parted /dev/sdb print`查看磁盘信息
2. 使用`parted /dev/sdb mklabel gpt`或`msdos`创建分区表
3. 使用`mkpart`命令创建分区
4. 使用`mkfs`命令格式化分区
5. 挂载分区并设置开机自动挂载

通过以上步骤，你可以成功解决"无法辨识的磁盘卷标"错误，完成对新磁盘的分区和使用。同时，掌握`lsblk`、`fdisk`查看分区信息以及`resizepart`调整分区大小等进阶操作，可以帮助你更好地管理磁盘分区。