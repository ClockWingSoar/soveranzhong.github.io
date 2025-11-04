---
layout: post
title: "Linux tr命令完全指南：字符转换、压缩与删除的艺术"
date: 2024-01-21 08:00:00 +0800
categories: linux command-line
---

# Linux tr命令完全指南：字符转换、压缩与删除的艺术

## 一、tr命令概述

### 1.1 什么是tr命令

tr（translate）命令是Linux/Unix系统中一个强大的字符处理工具，用于从标准输入读取数据，对字符进行转换、压缩或删除操作，然后将结果输出到标准输出。它虽然命令形式简单，但功能丰富，可以解决许多文本处理问题。

### 1.2 tr命令的基本语法

```bash
tr [选项]... SET1 [SET2]
```

tr命令的工作原理是将输入中的SET1中的字符映射到SET2中对应的字符，或者根据选项执行删除、压缩等操作。如果只提供SET1而没有SET2，则主要用于删除操作。

### 1.3 为什么tr命令重要

tr命令在以下场景特别有用：
- 数据清洗和转换
- 文本标准化处理
- 日志文件分析和处理
- 字符编码转换辅助
- 脚本编程中的文本处理

掌握tr命令可以让您在不使用复杂编程语言的情况下，快速完成许多文本处理任务。

## 二、tr命令选项详解

### 2.1 -c, -C, --complement：使用SET1的补集

这个选项告诉tr命令使用SET1的补集（即所有不在SET1中的字符）。

#### 2.1.1 功能说明

当指定`-c`选项时，tr会对不在SET1中的所有字符执行操作，而不是对SET1中的字符本身。

#### 2.1.2 使用案例

```bash
# 保留所有字母和数字，删除其他字符
echo "Hello, World! 123" | tr -cd '[:alnum:]'
# 输出: HelloWorld123

# 仅保留空格和字母，删除其他字符
echo "Hello, World! 123" | tr -cd '[:alpha:] '
# 输出: Hello World

# 将非数字字符替换为换行符，方便统计数字
echo "abc123def456ghi789" | tr -c '[:digit:]' '\n'
# 输出:
# 
# 123
# 456
# 789
# 
```

### 2.2 -d, --delete：删除字符

这个选项用于删除输入中所有出现在SET1中的字符。

#### 2.2.1 功能说明

使用`-d`选项时，tr会删除所有匹配SET1中字符的输入字符，不进行任何替换操作。

#### 2.2.2 使用案例

```bash
# 删除所有数字
echo "abc123def456" | tr -d '0-9'
# 输出: abcdef

# 删除所有元音字母
echo "Hello World" | tr -d 'aeiouAEIOU'
# 输出: Hll Wrld

# 删除Windows换行符(CR)
cat windows_file.txt | tr -d '\r' > unix_file.txt

# 从日志中删除所有控制字符
cat logfile | tr -d '\000-\037' > clean_log.txt
```

### 2.3 -s, --squeeze-repeats：压缩重复字符

这个选项将连续重复的字符压缩为单个字符。

#### 2.3.1 功能说明

使用`-s`选项时，tr会将输入中连续出现的SET中列出的字符序列压缩为单个字符。如果同时指定了SET2，则压缩操作在翻译之后进行。

#### 2.3.2 使用案例

```bash
# 压缩连续的空格为单个空格
echo "Hello    World   with    spaces" | tr -s ' '
# 输出: Hello World with spaces

# 压缩多个换行符为单个换行符
cat multi_newline.txt | tr -s '\n'

# 压缩所有空白字符（空格、制表符等）为单个空格
echo "Hello\t\tWorld\n\n\nTest" | tr -s '[:space:]' ' '
# 输出: Hello World Test

# 先删除数字，再压缩空格
echo "abc  123   def  456" | tr -d '0-9' | tr -s ' '
# 输出: abc def
```

### 2.4 -t, --truncate-set1：截断SET1到SET2的长度

这个选项会将SET1截断为SET2的长度，只在翻译模式下有效。

#### 2.4.1 功能说明

默认情况下，当SET1的长度大于SET2时，SET2会被重复以匹配SET1的长度。使用`-t`选项可以截断SET1，使其长度与SET2相同，忽略SET1中超出的部分。

#### 2.4.2 使用案例

```bash
# 不使用-t选项，SET2会被重复以匹配SET1长度
echo "abcdef" | tr 'abcdef' '12'
# 输出: 121212

# 使用-t选项，SET1会被截断为SET2的长度
echo "abcdef" | tr -t 'abcdef' '12'
# 输出: 12cdef

# 生产环境案例：密码强度分析中，只关心特定字符的转换
echo "P@ssw0rd" | tr -t '[:punct:]' 'x'
# 输出: Pxssw0rd
```

## 三、字符集(SET)详解

### 3.1 基本字符表示

tr命令支持多种方式表示字符集：

#### 3.1.1 字面字符

```bash
# 将a替换为1，b替换为2，c替换为3
echo "abc" | tr 'abc' '123'
# 输出: 123
```

#### 3.1.2 字符范围

使用连字符`-`表示字符范围：

```bash
# 将小写字母转换为大写字母
echo "hello" | tr 'a-z' 'A-Z'
# 输出: HELLO

# 将数字转换为字母
echo "12345" | tr '0-9' 'a-j'
# 输出: abcde
```

#### 3.1.3 特殊字符转义

使用反斜杠`\`转义特殊字符：

```bash
# 转义字符列表
# \NNN  八进制值为NNN的字符
# \\    反斜杠
# \a    终端鸣响
# \b    退格
# \f    换页
# \n    换行
# \r    回车
# \t    水平制表符
# \v    垂直制表符

# 将制表符转换为空格
echo -e "hello\tworld" | tr '\t' ' '
# 输出: hello world

# 使用八进制表示删除控制字符
echo -e "hello\x07world" | tr -d '\007'
# 输出: helloworld
```

### 3.2 字符类

tr提供了预定义的字符类，使用`[:class:]`格式：

| 字符类 | 描述 |
|--------|------|
| `[:alnum:]` | 所有字母和数字 |
| `[:alpha:]` | 所有字母 |
| `[:blank:]` | 所有水平空白字符（空格和制表符） |
| `[:cntrl:]` | 所有控制字符（ASCII 0-31和127） |
| `[:digit:]` | 所有数字 |
| `[:graph:]` | 所有可打印字符，不包括空格 |
| `[:lower:]` | 所有小写字母 |
| `[:print:]` | 所有可打印字符，包括空格 |
| `[:punct:]` | 所有标点符号 |
| `[:space:]` | 所有空白字符（水平和垂直） |
| `[:upper:]` | 所有大写字母 |
| `[:xdigit:]` | 所有十六进制数字（0-9, a-f, A-F） |

#### 3.2.1 使用案例

```bash
# 使用字符类将所有字母转换为大写
echo "Hello World 123!" | tr '[:lower:]' '[:upper:]'
# 输出: HELLO WORLD 123!

# 移除所有不可打印字符
echo -e "hello\x07world\t\n" | tr -cd '[:print:]'
# 输出: helloworld

# 仅保留字母和空格
echo "Hello, World! 123" | tr -cd '[:alpha:] '
# 输出: Hello World
```

### 3.3 等价类

使用`[=char=]`表示与指定字符等价的所有字符：

```bash
# 对于支持重音字符的语言环境，这会匹配所有与e等价的字符（如é, è, ê等）
echo "café résumé" | tr '[=e=]' 'e'
# 输出可能为: cafe resume（取决于语言环境）
```

### 3.4 重复表示

在SET2中，可以使用`[char*]`或`[char*count]`重复字符：

```bash
# 将a替换为三个x
echo "abcabc" | tr 'a' '[x*3]'
# 输出: xxxbcxxxbx

# 将每个数字替换为两个等号
echo "123" | tr '0-9' '[=*2]'
# 输出: ====

# 使用八进制数指定重复次数
echo "abc" | tr 'a-c' '[x*05]'
# 输出: xxxxxxxxxx（5个x）
```

## 四、tr命令实际应用案例

### 4.1 数据清洗

#### 4.1.1 清理CSV文件

```bash
# 移除CSV文件中的非ASCII字符
cat dirty.csv | tr -cd '[:print:]\n' > clean.csv

# 确保CSV文件使用一致的分隔符（将制表符和空格转换为逗号）
cat mixed_separators.txt | tr '\t ' ',' > comma_separated.csv

# 删除CSV文件中的多余引号
cat quoted.csv | tr -d '"' > unquoted.csv
```

#### 4.1.2 清理日志文件

```bash
# 从日志中删除颜色代码
cat colored_log.txt | tr -d '\033\[0-9;]*[a-zA-Z]' > plain_log.txt

# 清理Windows日志格式
cat windows_log.txt | tr -d '\r' | tr -s ' ' > cleaned_log.txt

# 提取日志中的IP地址（保留数字和点）
cat access.log | tr -cd '[:digit:].' | tr '\n' ' ' | tr -s '.' | tr '.' '\n' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
```

### 4.2 文本转换

#### 4.2.1 大小写转换

```bash
# 转换为大写
echo "hello world" | tr '[:lower:]' '[:upper:]'
# 输出: HELLO WORLD

# 转换为小写
echo "HELLO WORLD" | tr '[:upper:]' '[:lower:]'
# 输出: hello world

# 大小写互换
echo "Hello World" | tr '[:upper:][:lower:]' '[:lower:][:upper:]'
# 输出: hELLO wORLD
```

#### 4.2.2 格式转换

```bash
# 将DOS格式文本转换为Unix格式（删除CR）
cat dos.txt | tr -d '\r' > unix.txt

# 将Unix格式转换为DOS格式（添加CR）
cat unix.txt | tr '\n' '\r\n' > dos.txt

# 将多个空格替换为制表符
echo "column1   column2      column3" | tr -s ' ' '\t'
# 输出: column1	column2	column3
```

### 4.3 生成随机数据

```bash
# 生成随机密码（删除特殊字符）
cat /dev/urandom | tr -dc '[:alnum:]' | fold -w 16 | head -n 1

# 生成随机数字序列
cat /dev/urandom | tr -dc '[:digit:]' | fold -w 10 | head -n 5

# 生成随机字母序列
cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 8 | head -n 3
```

### 4.4 文本分析

```bash
# 统计文本中出现的不同字符
cat file.txt | tr -d '\n' | tr -c '[:print:]' '\n' | sort | uniq -c | sort -nr

# 分析单词频率（简化版）
cat text.txt | tr -cs '[:alpha:]' '\n' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr

# 计算文本中非空格字符数
echo "Hello World" | tr -cd '[:graph:]' | wc -c
# 输出: 10
```

### 4.5 生产环境实用脚本

#### 4.5.1 批量重命名文件

```bash
# 将目录中所有文件名中的空格替换为下划线
for file in *\ *; do
  mv "$file" "$(echo "$file" | tr ' ' '_')"
done
```

#### 4.5.2 日志分割工具

```bash
# 将大型日志文件按日期分割
echo "2024-01-20: Error message 1\n2024-01-21: Error message 2" | \
  while read line; do
    date=$(echo "$line" | tr -d '[:alpha:][:punct:][:space:]' | cut -c1-8)
    echo "$line" >> "log_$date.txt"
  done
```

#### 4.5.3 密码强度检查

```bash
# 简单的密码强度检查脚本
check_password() {
  password=$1
  
  # 检查长度
  length=$(echo "$password" | wc -c)
  length=$((length - 1))
  
  # 检查是否包含数字
  has_digit=$(echo "$password" | tr -cd '[:digit:]' | wc -c)
  
  # 检查是否包含小写字母
  has_lower=$(echo "$password" | tr -cd '[:lower:]' | wc -c)
  
  # 检查是否包含大写字母
  has_upper=$(echo "$password" | tr -cd '[:upper:]' | wc -c)
  
  # 检查是否包含特殊字符
  has_special=$(echo "$password" | tr -cd '[:punct:]' | wc -c)
  
  echo "密码长度: $length"
  echo "包含数字: $has_digit"
  echo "包含小写字母: $has_lower"
  echo "包含大写字母: $has_upper"
  echo "包含特殊字符: $has_special"
}

# 使用示例
check_password "MySecureP@ssw0rd123"
```

## 五、tr命令与其他工具结合使用

tr命令的真正强大之处在于与其他命令结合使用，形成强大的数据处理管道。

### 5.1 与管道结合

```bash
# 生成随机密码并复制到剪贴板（Linux）
cat /dev/urandom | tr -dc '[:alnum:]_-!@#$%^&*()' | fold -w 16 | head -n 1 | tee >(xclip -selection clipboard)

# 清理文本并进行排序统计
cat text.txt | tr -s '[:space:]' '\n' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr

# 查找大文件并格式化输出
find /home -type f -size +100M -exec ls -lh {} \; | tr -s ' ' | cut -d' ' -f5,9
```

### 5.2 在脚本中使用

```bash
#!/bin/bash
# 文本处理脚本

# 输入文件
input_file=$1
output_file="${input_file%.txt}_processed.txt"

# 处理流程：清理 -> 转换 -> 排序 -> 去重
cat "$input_file" | \
  tr -d '[:cntrl:]' | \
  tr -s '[:space:]' ' ' | \
  tr '[:upper:]' '[:lower:]' | \
  sort | \
  uniq > "$output_file"

echo "处理完成，输出文件: $output_file"
```

### 5.3 高级组合技巧

```bash
# 提取网页中的所有链接（简化版）
curl -s https://example.com | tr '"' '\n' | grep '^http' | sort | uniq

# 分析Apache访问日志中的客户端浏览器信息
cat access.log | cut -d'"' -f6 | tr ' ' '\n' | grep -i 'mozilla\|chrome' | sort | uniq -c | sort -nr

# 生成文件内容的简单指纹
cat file.txt | tr -d '\n\r' | tr -s '[:space:]' | md5sum
```

## 六、tr命令的常见陷阱和注意事项

### 6.1 常见错误

```bash
# 错误：忘记SET2，但想进行转换
echo "abc" | tr 'abc'  # 这将导致错误
# 正确：提供SET2
echo "abc" | tr 'abc' '123'

# 错误：在使用字符类时忘记括号
echo "abc" | tr :lower: :upper:  # 这将尝试匹配字符':', 'l', 'o'等
# 正确：使用正确的字符类语法
echo "abc" | tr '[:lower:]' '[:upper:]'
```

### 6.2 性能考量

- 对于非常大的文件，tr命令通常比sed或awk更快，因为它是为字符处理而优化的
- 当需要同时进行多种替换时，考虑使用多个tr命令管道，而不是尝试一次性完成所有操作
- 对于复杂的文本转换，可能需要结合使用tr与其他工具如sed、awk

### 6.3 跨平台兼容性

- 在Windows上通过Cygwin或WSL使用tr时，注意行尾字符的差异
- 某些特殊字符在不同shell中的转义方式可能不同
- 字符类在某些非GNU实现的tr中可能不完全支持

## 七、总结

tr命令是Linux文本处理工具箱中的一个强大工具，虽然简单但功能多样。它可以用于字符转换、删除和压缩，适用于各种文本处理场景。

通过掌握tr命令的各种选项和字符集表示方法，您可以快速解决许多文本处理问题，特别是在数据清洗、格式转换和文本分析方面。当与其他命令结合使用时，tr命令的能力将进一步增强，可以处理更复杂的任务。

记住，最好的学习方法是实践。尝试将tr命令应用到您的日常工作中，解决实际问题，这样您就能真正掌握这个强大的工具。

## 八、进一步学习资源

- GNU Coreutils tr文档：https://www.gnu.org/software/coreutils/tr
- 查看tr命令的详细手册：`man tr`
- 《Linux命令行与Shell脚本编程大全》
- 《UNIX Power Tools》