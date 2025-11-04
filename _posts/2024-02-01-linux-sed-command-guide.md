---
layout: post
title: "Linux sed命令完全指南：流式文本编辑的艺术"
date: 2024-02-01 10:00:00 +0800
categories: [Linux, 命令行工具]
tags: [Linux, sed, 文本处理, 命令行, 正则表达式]
---

# Linux sed命令完全指南：流式文本编辑的艺术

在Linux命令行的工具箱中，`sed`命令是一个强大的流式文本编辑器，它能够以非交互式的方式对文本进行高效处理。无论是简单的文本替换，还是复杂的模式匹配和转换，`sed`都能胜任。本文将深入探讨`sed`命令的各种用法、选项和最佳实践，帮助您掌握这一强大的文本处理工具。

## 1. 命令概述

`sed`（Stream EDitor）是一种流式文本编辑器，它通过在内存中创建一个模式空间（pattern space），逐行读取文件内容并进行处理。这种设计使得`sed`能够高效地处理大型文件，而不会占用过多内存。

### 1.1 工作原理

1. `sed`在内存中创建一个模式空间（pattern space）
2. 逐行读取输入文件（或标准输入）的内容到模式空间
3. 对模式空间中的内容执行用户指定的命令
4. 默认将处理后的内容输出到标准输出
5. 清空模式空间，准备读取下一行

### 1.2 基本语法

```bash
sed [参数] '<匹配条件> [动作]' [文件名]
```

**重要说明：**
- 匹配条件和动作需要用单引号包裹
- 多个动作可以在同一个单引号内，用分号分隔，如 `'2p;4p'`
- 当不指定文件名时，`sed`会从标准输入读取内容

### 1.3 准备测试数据

在开始学习`sed`命令之前，让我们创建一些测试数据文件，以便后续示例使用：

```bash
# 创建基本的测试文件
cat > sed_test.txt << 'EOF'
ihao sed1 sed2 sed3
ihao sed4 sed5 sed6
ihao sed7 sed8 sed9
EOF

# 创建配置文件测试数据
cat > config_test.conf << 'EOF'
# 这是一个配置文件示例
# 下面是主要配置项

# 数据库配置
db_host = localhost
db_port = 3306
db_user = admin
db_password = secret123

# 服务器配置
server_port = 8000
server_timeout = 300

# 日志配置
log_level = info
log_file = /var/log/app.log
EOF

# 创建简单的nginx配置示例
cat > nginx_sample.conf << 'EOF'
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       8000;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
EOF

# 创建一个操作脚本文件
cat > sed_commands.txt << 'EOF'
1p
3p
EOF
```

## 2. 常用参数详解

`sed`命令支持多种参数，这些参数可以控制`sed`的行为方式：

| 参数 | 描述 |
|------|------|
| `-n`, `--quiet`, `--silent` | 取消自动打印模式空间内容，只显示经过特殊处理（如`p`命令）的行 |
| `-e 脚本`, `--expression=脚本` | 添加脚本到程序的运行列表，允许在同一命令行中指定多个编辑命令 |
| `-f 脚本文件`, `--file=脚本文件` | 从指定文件读取编辑命令 |
| `-r`, `-E`, `--regexp-extended` | 支持使用扩展正则表达式 |
| `-i[扩展名]`, `--in-place[=扩展名]` | 直接修改文件内容，并可选择创建备份（如`-i.bak`） |
| `--debug` | 对程序运行进行标注，显示详细的处理过程 |
| `--follow-symlinks` | 直接修改文件时跟随软链接 |
| `-c`, `--copy` | 在`-i`模式中使用复制而不是重命名来处理文件 |
| `-b`, `--binary` | 二进制模式，不特殊处理CR+LF（主要用于Windows/Cygwin兼容性） |
| `-l N`, `--line-length=N` | 指定`l`命令的换行期望长度 |
| `--posix` | 关闭所有GNU扩展，确保符合POSIX标准 |
| `-s`, `--separate` | 将输入文件视为各个独立的文件而不是单个长的连续输入流 |
| `--sandbox` | 在沙盒模式中进行操作（禁用e/r/w命令） |
| `-u`, `--unbuffered` | 从输入文件读取最少的数据，更频繁地刷新输出 |
| `-z`, `--null-data` | 使用NUL字符分隔各行 |

**注意事项：**
- 在macOS的bash中使用`-i`参数时，必须在后面单独加上一个空字符串：`-i ''`
- 参数组合使用时，`-i`和`-r`可以组合为`-ri`，但不可以写作`-ir`
- `ni`是一个危险的选项组合，可能会清空文件内容
- 对于可移植性，建议使用`-E`而不是`-r`来启用扩展正则表达式（POSIX标准）

## 3. 匹配条件

`sed`支持多种匹配条件，用于指定要操作的行：

### 3.1 基于行号的匹配

- `空`：表示所有行
- `n`：表示第n行
- `$`：表示最后一行
- `n,m`：表示第n到m行
- `n,+m`：表示第n行到第n+m行
- `first~step`：步进语法，表示从第first行开始，每隔step-1行匹配一次
  - `1~2`：表示奇数行（从第1行开始，每隔1行匹配一次）
  - `2~2`：表示偶数行（从第2行开始，每隔1行匹配一次）

### 3.2 基于内容的匹配

- `'/关键字/'`：匹配包含关键字的行
- `'/关键字1/,/关键字2/'`：匹配从包含关键字1的行到包含关键字2的行
- `'n,/关键字/'`：匹配从第n行到包含关键字的行
- `'/关键字/,n'`：匹配从包含关键字的行到第n行
- `'/关键字/,+m'`：匹配从包含关键字的行到其后m行

**注意：**
- 分隔符号`/`可以替换为`@`、`#`、`!`等符号，当关键字中包含分隔符号时特别有用
- 可以使用`!`符号对匹配条件取反，如`'2!p'`表示打印除第2行外的所有行

## 4. 常用动作

`sed`支持多种动作，可以对匹配到的行执行不同的操作：

| 动作 | 描述 |
|------|------|
| `p` | 打印模式空间中的内容 |
| `P` | 打印当前模式空间中直到第一个嵌入换行符的部分 |
| `d` | 删除模式空间中的内容，开始下一个周期 |
| `D` | 如果模式空间不包含换行符，则开始新周期；否则删除模式空间中直到第一个换行符的文本，重启周期不读取新行 |
| `s/原内容/替换内容/` | 替换模式空间中的内容 |
| `a\text` | 在匹配行后追加文本 |
| `i\text` | 在匹配行前插入文本 |
| `c\text` | 替换整个匹配行为新文本 |
| `r file` | 读取指定文件的内容到匹配行后 |
| `R file` | 从文件中读取一行并追加（GNU扩展） |
| `w file` | 将模式空间中的内容写入指定文件 |
| `W file` | 将模式空间的第一行写入指定文件（GNU扩展） |
| `x` | 交换模式空间和保持空间的内容 |
| `=` | 打印当前行的行号 |
| `l` | 以"视觉上明确"的形式列出当前行 |
| `l width` | 以"视觉上明确"的形式列出当前行，在指定宽度处换行（GNU扩展） |
| `n` | 读取下一行到模式空间 |
| `N` | 读取下一行并追加到模式空间 |
| `h` | 将模式空间复制到保持空间 |
| `H` | 将模式空间追加到保持空间 |
| `g` | 将保持空间复制到模式空间 |
| `G` | 将保持空间追加到模式空间 |
| `y/字符集1/字符集2/` | 字符转换，将字符集1中的每个字符替换为字符集2中对应的字符 |
| `b [label]` | 跳转到标签；如果省略标签，跳到脚本末尾 |
| `t [label]` | 如果自上次读取输入行和上次t或T命令以来s///命令成功替换，则跳转到标签 |
| `T [label]` | 如果自上次读取输入行和上次t或T命令以来s///命令未成功替换，则跳转到标签（GNU扩展） |
| `q [exit-code]` | 立即退出sed脚本，不再处理更多输入，但如果自动打印未禁用则打印当前模式空间 |
| `Q [exit-code]` | 立即退出sed脚本，不再处理更多输入（GNU扩展） |

## 5. 打印操作

打印是`sed`最基本的操作之一，可以用来查看文件的特定部分。

### 5.1 基本打印

```bash
# 打印第2行（默认也会输出所有行）
sed '2p' sed_test.txt

# 只打印第2行（使用-n参数抑制默认输出）
sed -n '2p' sed_test.txt

# 打印第1行和第3行
sed -n '1p;3p' sed_test.txt

# 打印包含sed4的行
sed -n '/sed4/p' sed_test.txt
```

### 5.2 条件打印

```bash
# 打印奇数行（从第1行开始，每隔1行打印一次）
sed -n '1~2p' sed_test.txt

# 打印偶数行（从第0行开始，每隔1行打印一次）
sed -n '0~2p' sed_test.txt

# 实际应用示例
# 以下是用户在系统中执行的实际示例，展示了步进语法的效果：
# 从第1行开始，每隔1行打印一次（奇数行）
```
0 ✓ 22:08:55 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n '1~2p' sed.txt 
 nihao sed1 sed2 sed3 
 nihao sed7 sed8 sed9 
```

# 步进语法说明：'1~2'表示从第1行开始，每隔1行（步长为2）打印一次
# 语法格式：start~step，其中start是起始行号，step是步长值
# 当使用p命令时，会打印所有匹配的行（在这个例子中是奇数行）

# 引号使用规则说明
# 在sed命令中，引号的使用有以下特点：
# 1. 单引号('')：最常用，shell不会解析单引号内的变量、反斜杠等特殊字符
# 2. 双引号("")：shell会解析双引号内的变量和反斜杠转义字符
# 3. 无引号：在某些简单的sed命令中（不包含shell特殊字符），也可以不使用引号

# 实际验证示例：以下命令都能正常工作
```
0 ✓ 22:09:15 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n "0~2p" sed.txt 
 nihao sed4 sed5 sed6 
0 ✓ 22:22:12 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n 0~2p sed.txt 
 nihao sed4 sed5 sed6 
0 ✓ 22:22:24 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n '0~2p' sed.txt 
 nihao sed4 sed5 sed6 
```

# 引号使用建议：
# - 对于简单的模式，三种引号方式都可以使用
# - 当模式中包含shell特殊字符（如$、`、\、*）时，建议使用单引号
# - 当需要在sed命令中使用shell变量时，必须使用双引号
# - 无引号方式虽然简洁，但不推荐在复杂脚本中使用，因为容易与shell特殊字符冲突

# 打印除第2行外的所有行
sed -n '2!p' sed_test.txt

# 实际应用示例：取反操作
# 以下是用户在系统中执行的实际示例，展示了取反操作的效果：
```
0 ✓ 22:30:03 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n '2!p' sed.txt 
nihao sed1 sed2 sed3 
nihao sed7 sed8 sed9 
```

# 对比：打印第2行的效果
```
0 ✓ 22:36:18 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n '2p' sed.txt 
nihao sed4 sed5 sed6 
```

# 说明：
# 1. 感叹号(!)用于对匹配条件取反
# 2. '2!p'表示打印除了第2行以外的所有行
# 3. 对比'2p'命令（只打印第2行），可以看到'2!p'命令的互补效果
# 打印从第1行到包含sed4的行
sed -n '1,/sed4/p' sed_test.txt
```

### 5.3 多点打印

```bash
# 使用-e参数指定多个打印命令
sed -n -e '1p' -e '3p' sed_test.txt

# 从文件中读取打印命令
sed -n -f sed_commands.txt sed_test.txt

# 实际应用示例：创建sed脚本文件并执行
# 以下是用户在系统中执行的实际示例，展示了如何创建和使用sed脚本文件：
```sh
0 ✓ 22:28:52 soveran@rocky9.6-12,10.0.0.12:~ $ echo -e '1p\n3p' >sed-script.txt 
0 ✓ 22:29:41 soveran@rocky9.6-12,10.0.0.12:~ $ cat sed-script.txt 
1p 
3p 
0 ✓ 22:29:45 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n -f sed-script.txt sed.txt 
nihao sed1 sed2 sed3 
nihao sed7 sed8 sed9 


# 说明：
# 1. 使用echo -e '1p\n3p' >sed-script.txt 创建包含两个打印命令的脚本文件
# 2. 第一个命令1p表示打印第1行，第二个命令3p表示打印第3行
# 3. 使用sed -n -f sed-script.txt sed.txt 执行脚本文件中的命令
# 4. -n选项确保只输出脚本中明确指定要打印的行（第1行和第3行）
```

### 5.4 打印行号

```bash
# 打印匹配行的行号
sed -n '/sed4/=' sed_test.txt


# 实际应用示例：显示匹配行号
# 以下是用户在系统中执行的实际示例，展示了如何显示匹配特定模式的行号：

0 ✓ 22:36:31 soveran@rocky9.6-12,10.0.0.12:~ $ sed -n '/sed4/=' sed.txt 
2


# 说明：
# 1. 等号(=)命令用于打印当前行的行号
# 2. '/sed4/='表示打印所有包含'sed4'字符串的行的行号
# 3. 在这个示例中，'sed4'出现在第2行，因此命令输出数字2
# 4. -n选项确保只输出行号，而不输出匹配的行内容
```
### 5.5 打印部分内容（P命令）

```bash
# 使用N读取下一行并P只打印第一行
cat > multi_line.txt << 'EOF'
line1
line2
line3
line4
EOF
sed -n 'N;P' multi_line.txt  # 输出line1和line3
```

### 5.6 可视化打印（l命令）

```bash
# 创建包含特殊字符的测试文件
cat > special_chars.txt << 'EOF'
line with tab	and space
line with newline

EOF

# 使用l命令以可视化方式显示特殊字符
sed -n 'l' special_chars.txt

# 指定行宽进行换行显示
sed -n 'l 20' special_chars.txt

### 5.3 多点打印

```bash
# 使用-e参数指定多个打印命令
sed -n -e '1p' -e '3p' sed_test.txt

# 从文件中读取打印命令
sed -n -f sed_commands.txt sed_test.txt
```

### 5.4 打印行号

```bash
# 打印匹配行的行号
sed -n '/sed4/=' sed_test.txt
```

## 6. 文本替换

替换是`sed`最常用的功能之一，可以用来修改文件中的文本内容。

### 6.1 基本替换

```bash
# 替换每行的第一个sed为SED
sed 's/sed/SED/' sed_test.txt

# 替换每行的所有sed为SED（使用g标志）
sed 's/sed/SED/g' sed_test.txt
```

### 6.2 限定替换

```bash
# 只替换第2行的第一个SED为sed
sed '2s/SED/sed/' sed_test.txt

# 替换每行的第二个SED为sed
sed 's/SED/sed/2' sed_test.txt

# 替换第3行的第二个SED为sed
sed '3s/SED/sed/2' sed_test.txt
```

### 6.3 字符转换

```bash
# 将所有大写SED转换为小写sed
sed 'y/SED/sed/' sed_test.txt
```

### 6.4 使用&符号

```bash
# 在匹配内容后添加额外内容（&代表原内容）
echo "root:x:0:0:root:/root:/bin/bash" | sed 's/root/&user/'

# 为所有root添加user后缀
echo "root:x:0:0:root:/root:/bin/bash" | sed 's/root/&user/g'
```

### 6.5 正则表达式替换

```bash
# 提取IP地址（使用捕获组）
ifconfig eth0 | sed -n '2p' | sed -r 's/.*inet (.*) net.*/\1/'

# 提取文件路径和文件名
echo "/etc/sysconfig/network" | sed -r 's#(.*\/)([^/]+/?$)#\1#'
echo "/etc/sysconfig/network" | sed -r 's#(.*\/)([^/]+/?$)#\2#'
```

## 7. 增删改操作

### 7.1 添加内容

#### 7.1.1 追加内容（a命令）

```bash
# 在第2行后追加内容
sed '2a\zengjia-2' sed_test.txt

# 在第1-3行后都追加内容
sed '1,3a\tongshi-2' sed_test.txt

# 在包含listen的行后追加内容
sed '/listen/a\tlisten\t\t80;' nginx_sample.conf
```

#### 7.1.2 插入内容（i命令）

```bash
# 在第1行前插入内容
sed '1i\insert-1' sed_test.txt

# 在第1-3行前都插入内容
sed '1,3i\insert-2' sed_test.txt

# 在包含listen的行前插入多行内容（使用\n换行）
sed '/listen/i\tlisten\t\t80;\n\tlisten\t\t8080;' nginx_sample.conf
```

### 7.2 删除内容（d命令）

```bash
# 删除第4行
sed '4d' sed_test.txt

# 删除第1-6行
sed '1,6d' sed_test.txt

# 删除所有空行
sed '/^$/d' config_test.conf

# 删除所有注释行（以#开头的行）
sed '/^#/d' config_test.conf

# 删除注释行和空行
sed '/^#/d;/^$/d' config_test.conf
```

### 7.3 替换整行（c命令）

```bash
# 替换第3行
sed '3c\tihuan-1' sed_test.txt

# 替换第1-3行为一行内容
sed '1,3c\tihuan-3' sed_test.txt

# 替换包含server_name的行
sed '/server_name/c\tserver_name example.com;' nginx_sample.conf
```

### 7.4 加载和保存内容

#### 7.4.1 加载文件内容（r命令）

```bash
# 在第2行后加载sed_test.txt的内容
sed '2r sed_test.txt' sed_test.txt

# 在第2-4行后加载sed_commands.txt的内容
sed '2,4r sed_commands.txt' sed_test.txt
```

#### 7.4.2 保存内容到文件（w命令和W命令）

```bash
# 将第2行保存到sed_output.txt
sed -n '2w sed_output.txt' sed_test.txt

# 将第1-4行保存到sed_output.txt
sed -n '1,4w sed_output.txt' sed_test.txt

# 使用N和W命令只保存模式空间的第一行
cat > multi_line_save.txt << 'EOF'
first line with multiple
second line with multiple
third line with multiple
EOF
sed -n 'N;W first_lines.txt' multi_line_save.txt
cat first_lines.txt  # 只包含first line with multiple和third line with multiple
```

## 7.5 快速退出（Q命令）

```bash
# 处理到第3行后立即退出，不打印当前模式空间
cat > sample.txt << 'EOF'
line 1
line 2
line 3
line 4
line 5
EOF
sed '3Q' sample.txt  # 只输出line 1和line 2

# 与q命令对比：q命令会打印当前模式空间
sed '3q' sample.txt  # 输出line 1、line 2和line 3
```

### 7.6 处理多行（N和D命令）

```bash
# 使用N连接行，D删除第一部分后继续处理
cat > paragraph.txt << 'EOF'
This is line 1.
This is line 2.
This is line 3 with ERROR.
This is line 4.
This is line 5 with WARNING.
EOF

# 删除包含ERROR的行及其下一行
sed '/ERROR/{N;d;}' paragraph.txt

# 使用D实现删除空行后的合并处理
sed '/^$/{N;/\n$/D}' paragraph.txt
```

## 8. 模式空间和保持空间操作

`sed`使用两个重要的缓冲区来处理文本：模式空间（pattern space）和保持空间（hold space）。这些缓冲区允许我们执行更复杂的文本处理操作。

### 8.1 基本操作

```bash
# 创建测试文件
cat > buffer_test.txt << 'EOF'
line 1: first line
line 2: second line
line 3: third line
EOF

# 使用h和g命令复制缓冲区内容
sed -n '2h;3g;p' buffer_test.txt  # 用第2行替换第3行后打印

# 使用H和G命令追加缓冲区内容
sed -n '1h;2H;3G;p' buffer_test.txt  # 第3行后追加第1、2行
```

### 8.2 实际应用 - 行替换

```bash
# 将偶数行替换为奇数行
cat > num_lines.txt << 'EOF'
Line A - should be kept
Line B - should be replaced
Line C - should be kept
Line D - should be replaced
EOF

sed -n '1{h;p};2{g;p};3{h;p};4{g;p}' num_lines.txt
```

### 8.3 使用x命令交换缓冲区

```bash
# 创建测试文件
cat > buffer_swap.txt << 'EOF'
header line
content line 1
content line 2
footer line
EOF

# 使用x命令交换模式空间和保持空间
# 保存第一行到保持空间，处理完所有内容后再打印第一行
sed -n '1{h;d};$G;p' buffer_swap.txt  # 不使用x

# 使用x命令实现相同功能
sed -n '1h;2,$p;$x;p' buffer_swap.txt  # 使用x交换
```

## 9. 跳转和条件执行命令

### 9.1 t命令（替换成功后跳转）

```bash
# 创建测试文件
cat > jump_test.txt << 'EOF'
Item: apple, Price: $1.50
Item: banana, Price: $0.75
Item: orange, Price: $1.25
EOF

# 使用t命令在替换成功后跳转
sed -r ':loop; s/\$([0-9]+\.[0-9][0-9])/USD \1/; t loop' jump_test.txt
```

### 9.2 T命令（替换失败后跳转，GNU扩展）

```bash
# 尝试替换，如果没有找到匹配项则添加默认值
cat > config_items.txt << 'EOF'
port=8080
host=localhost
# timeout未设置
EOF

sed -r '/timeout/!{T add_default
};b
:add_default
a\timeout=300' config_items.txt
```

## 10. 高级匹配技巧

### 10.1 内容范围匹配

```bash
# 匹配包含sendfile的行
sed -n '/sendfile/p' nginx_sample.conf

# 匹配从包含sendfile的行到包含server的行
sed -n '/sendfile/,/server/p' nginx_sample.conf

# 匹配从包含sendfile的行到第6行
sed -n '/sendfile/,6p' nginx_sample.conf

# 匹配从包含sendfile的行及其后3行
sed -n '/sendfile/,+3p' nginx_sample.conf
```

### 10.1.1 特殊地址匹配形式

```bash
# 0,addr2 形式：从开始到匹配addr2的行，与1,addr2不同的是如果addr2匹配第一行
# 则0,addr2已结束，而1,addr2仍在范围内
cat > address_test.txt << 'EOF'
first line - match here
second line
third line
EOF

# 使用0,/match/ 只匹配第一行
sed -n '0,/match/p' address_test.txt

# 使用1,/match/ 同样只匹配第一行（因为第一行匹配了）
sed -n '1,/match/p' address_test.txt

# 但当第一行就匹配时，两者行为不同
cat > first_match.txt << 'EOF'
match here - first line
second line
match again
EOF

# addr1,~N 形式：匹配addr1及其后的行，直到行号是N的倍数
# 例如匹配第一行直到下一个5的倍数行
seq 1 10 | sed -n '1,~5p'  # 匹配1-5行

# first~step 形式：从first行开始，每隔step行匹配一次（之前已介绍）
seq 1 10 | sed -n '2~3p'  # 匹配2,5,8行

### 10.2 取反匹配

```bash
# 打印非空行
sed -n '/^$/!p' nginx_sample.conf

# 打印非注释行和非空行
sed -rn '/^(\s*#|$)/!p' nginx_sample.conf
```

### 10.3 正则表达式高级用法

```bash
# 使用捕获组提取MAC地址
ifconfig eth0 | sed -nr 's/.*(\w{2}:\w{2}:\w{2}:\w{2}:\w{2}:\w{2}).*/\1/p'

# 提取配置文件中的键值对
sed -rn 's/^\s*([^#\s=]+)\s*=\s*(.*)/\1 => \2/p' config_test.conf
```

### 10.3.1 正则表达式支持说明

GNU sed支持标准的正则表达式，并提供了一些扩展：

```bash
# 使用\n在正则表达式中匹配换行符
cat > multi_line_regex.txt << 'EOF'
start
middle
end
EOF

sed -n '/start\nmiddle/p' multi_line_regex.txt

# 使用\a, \t等转义序列
cat > escape_seq.txt << 'EOF'
line with tab	character
line with newline
EOF

sed -n '/\t/p' escape_seq.txt  # 匹配包含tab的行

# 使用\cregexpc形式定义正则表达式分隔符
# 当正则表达式中包含斜杠时特别有用
sed -n '\#/etc/p' /etc/passwd  # 使用#作为分隔符

sed -n '\|/bin/bash|p' /etc/passwd  # 使用|作为分隔符

# 分隔符使用规则说明
# 在sed命令中，不同场景下分隔符的使用规则有所不同：
# 1. 默认分隔符的使用场景：在sed -n '/pattern/p'这种格式中，斜杠/是正则表达式的默认分隔符，用于包围要匹配的模式
# 2. #分隔符的特殊情况：虽然sed允许在替换命令(s/old/new/)中使用其他字符作为分隔符，但在-n选项结合p命令的场景下，
#    #不能直接替代/作为正则表达式的分隔符，除非使用\#regexp#p的转义形式
# 3. 正确的替换分隔符方法：在替换命令中使用#作为分隔符，应该这样写：sed 's#pattern#replacement#'，但这种替换只适用于s命令
# 4. 转义问题：在使用#^\/dev\/sd#p时，sed无法正确识别#作为分隔符，因为这种语法结构下sed期望使用/作为模式分隔符

```sh

  0 ✓ 21:26:00 soveran@rocky9.6-12,10.0.0.12:~ $ df -h | sed -n '#^\/dev\/sd#p'
  0 ✓ 21:26:41 soveran@rocky9.6-12,10.0.0.12:~ $ df -h | sed -n '/^\/dev\/sd/p'
/dev/sda1            960M  481M  480M   51% /boot

```
# 经验验证：在替换命令中使用#作为分隔符（注意需要p标志才会打印结果）
df -h | sed -n 's#/dev#/dav#p'  # 成功将/dev替换为/dav并打印结果



## 11. 多点操作和文件处理

### 11.1 多点编辑

```bash
# 使用分号分隔多个操作
sed -r '/listen/s/8000/80/;/server_name/c\tserver_name localhost:80;' nginx_sample.conf

# 使用-e参数指定多个编辑命令
sed -r -e 's/listen.*;/listen\t80;/' -e '/server_name/c\tserver_name localhost:80;' nginx_sample.conf
```

### 11.2 文件备份和编辑

```bash
# 编辑文件并创建备份
sed -i.bak '/^#/d;/^$/d' config_test.conf

# 查看备份文件
cat config_test.conf.bak
```

### 11.3 环境变量的使用

```bash
# 设置环境变量
port=8080

# 在sed中使用环境变量（注意使用双引号）
sed -r -e "s/listen.*;/listen\t$port;/" -e "/server_name/c\tserver_name $(hostname):$port;" nginx_sample.conf
```

## 12. 实用案例

### 12.1 配置文件处理

```bash
# 提取配置文件中所有非注释、非空行的配置项
sed -rn '/^\s*([^#\s=]+)\s*=\s*(.*)/p' config_test.conf

# 备份并清理配置文件（移除注释和空行）
sed -i.bak '/^#/d;/^$/d' config_test.conf

# 将非注释行添加注释符号
sed -rn '/^#/!s@^@#@p' config_test.conf
```

### 12.2 系统信息提取

```bash
# 提取网卡IP地址
iptables -L | grep -A 2 "Chain INPUT" | sed -n '2p' | sed -r 's/.*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/'

# 提取磁盘使用情况
df -h | sed -n '2p' | awk '{print $5}' | sed 's/%//'
```

### 12.3 日志处理

```bash
# 提取日志中的错误信息
sed -n '/ERROR/p' /var/log/syslog

# 过滤指定时间范围的日志
sed -n '/2024-02-01 10:00:00/,/2024-02-01 11:00:00/p' /var/log/application.log

# 清理日志文件中的颜色代码
sed 's/\x1b\[[0-9;]*[mK]//g' colored_log.txt > clean_log.txt
```

### 12.4 代码处理

```bash
# 移除代码中的注释
sed '/\/\//d' source_code.js

# 替换代码中的变量名
sed 's/oldVarName/newVarName/g' source_code.js

# 格式化JSON文件（简单示例）
sed 's/{/&\n/g;s/,/&\n/g;s/}/\n&/g' compact.json > formatted.json
```

## 13. 常见陷阱与解决方案

### 13.1 引号和转义

**问题**：在使用`sed`时，经常会遇到引号嵌套和特殊字符转义的问题。

**解决方案**：
- 当需要在`sed`命令中使用变量时，使用双引号而不是单引号
- 对于复杂的模式，使用不同的分隔符（如`#`、`@`等）来避免与模式中的斜杠冲突
- 正确转义特殊字符，如`\`、`*`、`.`、`[`、`]`等

```bash
# 正确使用双引号包含变量
sed -r "s/port = [0-9]+/port = $new_port/" config.conf

# 使用#作为分隔符，避免与URL中的/冲突
sed 's#http://#https://#g' urls.txt
```

### 13.2 修改文件的安全问题

**问题**：使用`-i`参数直接修改文件可能导致意外的数据丢失。

**解决方案**：
- 始终先备份文件再编辑：`sed -i.bak 's/old/new/g' file.txt`
- 对于重要文件，先使用不修改原文件的方式查看效果：`sed 's/old/new/g' file.txt > preview.txt`

### 13.3 性能优化

**问题**：处理大型文件时，`sed`可能会变慢。

**解决方案**：
- 尽可能使用更精确的匹配条件，减少不必要的处理
- 对于非常大的文件，可以先用其他工具（如`head`、`tail`）缩小范围
- 避免在循环中多次调用`sed`，尽量一次处理完成

## 14. 总结

`sed`命令是Linux系统中功能强大的文本处理工具，它通过流式处理的方式，能够高效地对文本文件进行各种操作。掌握`sed`命令的关键在于：

1. 理解其工作原理（模式空间和逐行处理）
2. 熟练掌握各种匹配条件和动作
3. 灵活运用正则表达式
4. 掌握与其他命令的组合使用

通过本文介绍的各种技巧和最佳实践，您应该能够在日常工作中充分利用`sed`命令，提高文本处理和系统管理的效率。无论是配置文件修改、日志分析还是代码处理，`sed`都能成为您得力的助手。

## 15. 参考链接

- [GNU sed 官方文档](https://www.gnu.org/software/sed/manual/)
- [Linux man 手册 sed(1)](https://man7.org/linux/man-pages/man1/sed.1.html)
- [正则表达式教程](https://www.regular-expressions.info/)

> 您可以参考我们的[Linux文本处理工具精通指南](https://soveranzhong.github.io/2024/01/20/linux-text-processing-tools.html)获取更多Linux文本处理工具的详细介绍。