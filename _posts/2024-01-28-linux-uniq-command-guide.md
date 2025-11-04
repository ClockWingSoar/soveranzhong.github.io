---
title: Linux uniq命令完全指南：文本去重与重复行处理
categories: [Linux]
tags: [linux, command, text-processing, uniq]
date: 2024-01-28 10:00:00
---

# Linux uniq命令完全指南：文本去重与重复行处理

## 1. 概述

`uniq`命令是Linux/Unix系统中用于处理文本文件中重复行的强大工具。它能够检测并处理文件中相邻的重复行，支持多种去重、计数和展示重复行的操作。`uniq`命令通常与`sort`命令结合使用，因为它只能检测相邻的重复行。

`uniq`命令的主要功能包括：
- 移除重复的相邻行
- 统计每行出现的次数
- 仅显示重复或唯一的行
- 忽略大小写差异
- 跳过指定数量的字段或字符
- 自定义比较的字符数量

## 2. 基本用法

### 2.1 命令格式

```bash
uniq [选项] [输入文件 [输出文件]]
```

### 2.2 常用操作

当不使用任何选项时，`uniq`命令默认会从输入中删除所有相邻的重复行，并输出结果到标准输出（通常是终端）。

```bash
# 基本使用示例
uniq file.txt

# 将结果保存到新文件
uniq file.txt output.txt

# 从标准输入读取数据
cat file.txt | uniq
```

### 2.3 与sort结合使用

由于`uniq`只能处理相邻的重复行，因此通常需要先使用`sort`命令将文件排序，确保相同的行相邻。

```bash
# 先排序再去重
sort file.txt | uniq

# 或者使用sort的-u选项直接去重（等同于sort | uniq）
sort -u file.txt
```

## 3. 选项详解

### 3.1 -c, --count

显示每行出现的次数，在每行前面加上计数值。

```bash
# 显示每行出现的次数
sort file.txt | uniq -c

# 示例输出
   3 apple
   2 banana
   1 orange
```

### 3.2 -d, --repeated

仅显示重复出现的行，每个重复的行只显示一次。

```bash
# 仅显示重复的行
sort file.txt | uniq -d
```

### 3.3 -f, --skip-fields=N

忽略前N个字段后再进行比较。字段由空格或制表符分隔。

```bash
# 忽略前2个字段进行去重
cat data.txt | uniq -f 2

# 示例：对于类似 "2024-01-28 user1 login" 的日志，可以忽略日期字段
cat access.log | uniq -f 1
```

### 3.4 -i, --ignore-case

比较时忽略大小写差异。

```bash
# 忽略大小写进行去重
cat mixed-case.txt | uniq -i

# 示例输出："Apple" 和 "apple" 会被视为相同
apple
banana
```

### 3.5 -s, --skip-chars=N

忽略每行前N个字符后再进行比较。

```bash
# 忽略前5个字符进行去重
cat data.txt | uniq -s 5

# 示例：对于带前缀序号的行 "001: apple", "002: apple" 会被视为相同
cat numbered.txt | uniq -s 4
```

### 3.6 -u, --unique

仅显示唯一的行（即没有重复出现的行）。

```bash
# 仅显示唯一的行
sort file.txt | uniq -u
```

### 3.7 -z, --zero-terminated

使用空字符（NUL）作为行分隔符，而不是换行符。这在处理可能包含换行符的文件名或数据时特别有用。

```bash
# 使用空字符作为分隔符
find . -type f -name "*.txt" -print0 | sort -z | uniq -z
```

### 3.8 -w, --check-chars=N

每行仅比较前N个字符。

```bash
# 仅比较前3个字符
echo -e "apple\napricot\nbanana" | uniq -w 3

# 输出：只显示 "apple" 和 "banana"，因为前3个字符 "app" 被视为相同
apple
banana
```

### 3.9 --group[=METHOD]

显示所有行，但用空行分隔不同的组。METHOD可以是以下值：
- separate：默认值，组之间用空行分隔
- prepend：在每个组前添加空行
- append：在每个组后添加空行
- both：在每个组前后都添加空行

```bash
# 用空行分隔不同的组
sort file.txt | uniq --group

# 在每个组前添加空行
sort file.txt | uniq --group=prepend
```

## 4. 高级用法

### 4.1 组合多个选项

`uniq`命令支持组合多个选项以实现更复杂的文本处理需求。

```bash
# 忽略前1个字段和前3个字符，同时忽略大小写，显示重复行
sort file.txt | uniq -f 1 -s 3 -i -d

# 计算重复行的数量，忽略前2个字段
sort data.txt | uniq -f 2 -c
```

### 4.2 与其他命令结合

`uniq`常与其他文本处理命令结合使用，构建强大的数据处理管道。

```bash
# 查找日志中出现频率最高的IP地址
cat access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10

# 统计代码库中不同类型的文件数量
find . -type f | grep -o '\.[^.]*$' | sort | uniq -c | sort -nr
```

## 5. 实用案例

### 5.1 日志分析

```bash
# 找出访问网站最频繁的用户代理
cat access.log | awk -F'"' '{print $6}' | sort | uniq -c | sort -nr | head -5

# 统计每天的错误日志数量
grep "ERROR" error.log | awk '{print $1}' | sort | uniq -c
```

### 5.2 数据去重

```bash
# 从CSV文件中去重，基于前两列
cat data.csv | sort -t, -k1,2 | uniq -f 1 -s 1

# 处理包含重复行的配置文件，保留第一个出现的值
sort config.txt | uniq
```

### 5.3 监控文件变化

```bash
# 定期检查文件中是否有新的唯一条目
while true; do
  cat logfile.txt | sort | uniq > current.uniq
  if [ -f previous.uniq ]; then
    comm -13 previous.uniq current.uniq
  fi
  cp current.uniq previous.uniq
  sleep 300
done
```

## 6. 与sort的结合使用

由于`uniq`只能处理相邻的重复行，它通常与`sort`命令结合使用。以下是一些常用的组合方式：

```bash
# 基本的排序去重
sort file.txt | uniq

# 排序并显示每行计数
sort file.txt | uniq -c

# 排序并仅显示重复行
sort file.txt | uniq -d

# 排序并仅显示唯一行
sort file.txt | uniq -u

# 注意：sort -u 等同于 sort | uniq，但效率更高
sort -u file.txt
```

## 7. 常见陷阱与注意事项

### 7.1 只能处理相邻的重复行

这是`uniq`最常见的陷阱。记住，`uniq`不会检测非相邻的重复行，所以通常需要先用`sort`排序。

```bash
# 错误的用法 - 如果重复行不相邻，uniq将无法正确去重
uniq unsorted_file.txt

# 正确的用法
sort unsorted_file.txt | uniq
```

### 7.2 字段和字符的处理

当使用`-f`和`-s`选项时，要注意字段的定义是连续的空白字符加上非空白字符。

```bash
# 对于"  apple"和"apple"（前面有空格），使用-f 0不会将它们视为相同
# 但使用-s 1可以忽略前1个空格字符
```

### 7.3 性能考虑

对于非常大的文件，考虑使用`sort -u`而不是`sort | uniq`，因为`sort -u`在内部优化了去重过程，可能更快。

```bash
# 对于大文件，更高效的去重方式
sort -u large_file.txt
```

## 8. 总结

`uniq`命令是Linux文本处理工具箱中的重要工具，特别适合处理需要去重或统计重复行的数据。它与`sort`命令的结合使用，使得文本数据的去重和分析变得简单高效。通过掌握`uniq`的各种选项和用法，您可以更灵活地处理各种文本数据处理需求。

记住`uniq`的基本特性：它只处理相邻的重复行，所以在大多数情况下，先使用`sort`排序是必要的。同时，`uniq`提供了丰富的选项，可以满足不同的文本处理场景，从简单的去重到复杂的统计和分组展示。