---
layout: post
title: "Linux awk命令全面详解"
date: 2024-02-02 10:00:00
categories: Linux
permalink: /archivers/linux-awk-command-guide
tags:
- Linux
- awk
- 文本处理
- Shell
---

# Linux awk命令全面详解

`awk`是一种强大的文本处理工具，它不仅是一个命令，更是一门完整的编程语言。`awk`特别擅长处理结构化数据，如表格、日志文件等。本文将详细介绍`awk`命令的各种功能和用法，帮助您掌握这一强大的文本处理工具。

## 1. 命令概述

`awk`是一个模式扫描和处理语言，它可以：

- 从文件或标准输入读取文本
- 根据指定的模式匹配行
- 对匹配的行执行指定的操作
- 输出结果到标准输出或文件

`awk`的名称来源于其创始人 Alfred Aho、Peter Weinberger 和 Brian Kernighan 的姓氏首字母。在Linux系统中，通常使用的是 GNU 版本的 awk，称为 gawk。

### 1.1 工作原理

`awk`的工作原理可以概括为：

1. 按行读取输入（默认情况下）
2. 将每一行分割成字段（默认以空格或制表符为分隔符）
3. 根据指定的模式匹配行
4. 对匹配的行执行相应的操作
5. 处理完所有行后执行可选的 END 块

### 1.2 程序执行流程

gawk执行AWK程序的详细顺序如下：

1. 首先，执行通过`-v`选项指定的所有变量赋值
2. 然后，gawk将程序编译成内部形式
3. 接着，执行BEGIN规则中的代码（如果有）
4. 然后，读取ARGV数组中命名的每个文件（最多到ARGV[ARGC-1]）
   - 如果命令行上没有指定文件，则读取标准输入
   - 如果ARGV中的元素为空字符串("")，gawk会跳过它
   - 对于每个输入文件，如果存在BEGINFILE规则，则在处理文件内容前执行相关代码
   - 对于每个输入记录，gawk测试它是否匹配程序中的任何模式，对每个匹配的模式执行关联的操作
   - 处理完文件后，如果存在ENDFILE规则，则执行相关代码
5. 最后，在所有输入用完后，执行END规则中的代码（如果有）

**注意：** 如果命令行上的文件名形式为`var=val`，它会被视为变量赋值，在BEGIN规则运行后执行。这对于动态分配控制输入如何分成字段和记录的变量值特别有用。

### 1.2 基本语法

`awk`命令的基本语法如下：

```bash
awk [选项] '程序' [文件...]
```

其中，`程序`的基本结构为：

```bash
/pattern/ { action }
```

或者更完整的结构：

```bash
BEGIN { action }
/pattern/ { action }
END { action }
```

### 1.3 准备测试数据

在开始学习`awk`命令之前，让我们创建一些测试数据文件，以便后续示例使用：

```bash
# 创建基本的测试文件
cat > awk_test.txt << 'EOF'
Alice 85 90 95
Bob 75 80 85
Charlie 90 95 100
David 60 65 70
EOF

# 创建CSV格式文件
cat > data.csv << 'EOF'
name,age,city,salary
Alice,28,New York,80000
Bob,32,Boston,95000
Charlie,45,Chicago,120000
David,36,San Francisco,110000
EOF

# 创建日志文件示例
cat > app.log << 'EOF'
2024-02-01 10:05:23 INFO User login: alice
2024-02-01 10:07:34 ERROR Database connection failed
2024-02-01 10:10:12 INFO User logout: alice
2024-02-01 11:15:45 INFO User login: bob
2024-02-01 14:30:22 WARNING Disk usage high (85%)
EOF
```

## 2. 常用参数详解

`awk`命令支持多种参数，这些参数可以控制`awk`的行为方式：

| 参数 | 长选项 | 描述 |
|------|--------|------|
| `-f 脚本文件` | `--file=脚本文件` | 从指定文件读取awk程序 |
| `-F fs` | `--field-separator=fs` | 指定字段分隔符 |
| `-v var=val` | `--assign=var=val` | 在执行程序前定义变量 |
| `-b` | `--characters-as-bytes` | 将每个字符视为单个字节，忽略区域设置信息 |
| `-c` | `--traditional` | 以传统模式运行，与Brian Kernighan的awk行为一致 |
| `-C` | `--copyright` | 显示版权信息 |
| `-d[文件]` | `--dump-variables[=文件]` | 输出全局变量信息到指定文件，默认awkvars.out |
| `-D[文件]` | `--debug[=文件]` | 启用调试功能，可选指定调试命令文件 |
| `-e '程序文本'` | `--source='程序文本'` | 直接在命令行指定程序 |
| `-E 文件` | `--exec=文件` | 类似于-f，但作为最后处理的选项，适用于#!脚本和CGI应用，禁用命令行变量赋值 |
| `-g` | `--gen-pot` | 扫描并解析awk程序，生成GNU .pot格式文件，不执行程序 |
| `-h` | `--help` | 显示帮助信息 |
| `-i 包含文件` | `--include=包含文件` | 加载awk源库，使用AWKPATH环境变量搜索，自动添加.awk后缀 |
| `-l 库` | `--load=库` | 从共享库加载gawk扩展，使用AWKLIBPATH环境变量搜索 |
| `-L[模式]` | `--lint[=模式]` | 提供可疑或不可移植构造的警告。模式可以是fatal、invalid或no-ext |
| `-M` | `--bignum` | 强制使用任意精度算术，需要编译时支持GNU MPFR和GMP库 |
| `-n` | `--non-decimal-data` | 识别输入数据中的八进制和十六进制值，使用时需谨慎！ |
| `-N` | `--use-lc-numeric` | 使用区域设置的小数点字符解析输入数据 |
| `-o[文件]` | `--pretty-print[=文件]` | 将格式化的程序输出到文件，默认awkprof.out，隐含--no-optimize |
| `-O` | `--optimize` | 启用默认优化，包括简单常量折叠，默认开启 |
| `-p[prof-file]` | `--profile[=prof-file]` | 启动性能分析会话，发送分析数据到指定文件，默认awkprof.out，隐含--no-optimize |
| `-P` | `--posix` | 以POSIX兼容模式运行，有额外限制如不识别\x转义序列等 |
| `-r` | `--re-interval` | 允许正则表达式中的区间表达式 |
| `-s` | `--no-optimize` | 禁用gawk的默认优化 |
| `-S` | `--sandbox` | 以沙箱模式运行，禁用system()函数、重定向等功能 |
| `-t` | `--lint-old` | 提供与原始UNIX awk不兼容的警告 |
| `-V` | `--version` | 显示gawk版本信息 |
| `--` | | 标记选项结束，允许后续参数以"-"开头 |

**注意事项：**
- 参数顺序可能会影响命令的执行结果
- 多个参数可以组合使用
- 对于复杂的程序，建议使用`-f`参数从文件读取
- 使用`--`选项可以确保gawk正确处理以"-"开头的参数，这与大多数POSIX程序的参数解析惯例一致

### 2.1 gawk特定功能说明

GNU awk (gawk)提供了一些标准awk之外的高级功能：

- **程序分析器**：使用`--profile`选项可以收集程序执行的统计信息，帮助优化awk程序性能。虽然会使程序运行速度变慢，但会在执行完毕后自动生成分析报告到awkprof.out文件。报告包含每条语句的执行计数和用户定义函数的调用次数。

- **集成调试器**：通过`--debug`选项可以启动交互式调试会话。在调试模式下，gawk会加载awk源代码并提示输入调试命令。注意，调试器只能调试通过`-f`和`--include`选项提供的awk程序源代码。

- **命名空间支持**：gawk支持命名空间功能，可以避免变量名和函数名冲突。使用`@namespace`指令可以定义命名空间。这对于大型程序和库的开发特别有用。

- **扩展正则表达式**：gawk提供了完整的正则表达式支持，包括区间表达式等高级功能。使用`--re-interval`选项可以启用正则表达式中的区间表达式。

- **POSIX兼容模式**：通过`--posix`选项，gawk可以严格按照POSIX标准运行，有一些额外限制：不识别`\x`转义序列、不能在`?`和`:`后换行、不识别`func`作为`function`的同义词等。

- **沙箱模式**：`--sandbox`选项使gawk在沙箱模式下运行，禁用`system()`函数、`getline`输入重定向、`print`和`printf`输出重定向以及动态扩展加载。这有效阻止脚本访问除命令行指定文件外的本地资源，提高安全性。

- **代码优化**：gawk提供了代码优化功能，通过`--optimize`选项启用（默认开启），包括简单常量折叠等优化。使用`--no-optimize`可以禁用这些优化。

- **程序格式化**：`--pretty-print`选项可以将awk程序输出为格式化、易读的版本，有助于理解和维护复杂程序。

- **国际化支持**：通过`--gen-pot`选项可以生成GNU .pot格式文件，用于awk程序的国际化和本地化。

- **变量检查**：`--dump-variables`选项输出全局变量的列表、类型和最终值，有助于查找拼写错误和确保函数不会无意中使用全局变量。

- **代码检查**：`--lint`系列选项提供对可疑或不可移植构造的警告，帮助开发更干净、更可移植的awk程序。

- **环境变量支持**：gawk支持以下重要的环境变量：
  - `AWKPATH`：指定查找通过`-f`和`--include`选项指定的源文件的搜索路径。默认为".:/usr/local/share/awk"
  - `AWKLIBPATH`：指定查找通过`--load`选项指定的扩展模块的搜索路径。默认为"/usr/local/lib/gawk"

- **命令行目录处理**：在gawk 4.0及以上版本中，命令行上的目录会产生警告但被跳过。使用`--posix`或`--traditional`选项时，目录会被视为致命错误（符合POSIX标准）。

#### 2.1.1 gawk高级功能示例

```bash
# 示例1：使用程序分析器
# 创建一个简单的awk程序文件
cat > analyze_program.awk << 'EOF'
BEGIN { print "Starting analysis" }
{ 
    sum += $2 
    if ($2 > max) max = $2
    if ($2 < min || NR == 1) min = $2
}
END { 
    print "Sum:", sum
    print "Avg:", sum/NR
    print "Max:", max
    print "Min:", min
}
EOF

# 使用分析器运行程序
awk --profile -f analyze_program.awk awk_test.txt

# 查看生成的分析报告
# cat awkprof.out

# 示例2：命名空间的使用
cat > namespace_example.awk << 'EOF'
@namespace "math";

function add(a, b) {
    return a + b
}

function multiply(a, b) {
    return a * b
}

@namespace "string";

function add(a, b) {
    return a b  # 字符串连接
}

@namespace "";

{ 
    # 访问不同命名空间的函数
    print "Math sum:", math::add($2, $3)
    print "String concat:", string::add($1, ": ")
}
EOF

# 运行命名空间示例
# awk -f namespace_example.awk awk_test.txt

# 示例3：使用调试器（交互式，这里仅展示命令）
# awk --debug -f analyze_program.awk awk_test.txt
# 调试命令示例:
# break BEGIN  # 在BEGIN块设置断点
# run          # 运行程序
# print sum    # 打印变量值
# next         # 执行下一条语句
# quit         # 退出调试器

# 示例4：沙箱模式的使用
# 创建一个包含潜在危险操作的脚本
cat > sandbox_test.awk << 'EOF'
{ 
    print "Processing:", $0
    # 尝试执行系统命令（在沙箱模式下会被禁止）
    # system("echo \\"This could be dangerous\\"")
    # 尝试读取其他文件（在沙箱模式下会被禁止）
    # getline < "/etc/passwd"
}
EOF

# 使用沙箱模式运行
# awk -S -f sandbox_test.awk awk_test.txt

# 示例5：使用lint选项检查程序问题
cat > lint_test.awk << 'EOF'
{ 
    # 可疑的构造：使用未初始化变量
    print "Total:", total + $2
    # 使用gawk扩展功能
    if (match($0, /[0-9]{2,3}/, arr)) {
        print "Found number:", arr[0]
    }
}
EOF

# 使用lint选项检查
# awk --lint -f lint_test.awk awk_test.txt
# 使用lint=fatal使警告成为错误
# awk --lint=fatal -f lint_test.awk awk_test.txt

# 示例6：使用--dump-variables检查变量
# 创建一个使用多个变量的程序
cat > var_dump_test.awk << 'EOF'
BEGIN {
    counter = 0
    threshold = 85
}
{ 
    counter++
    if ($2 > threshold) {
        high_scores++
    }
    total += $2
}
END {
    avg = total / counter
    print "Results calculated"
}
EOF

# 运行并导出变量信息
# awk --dump-variables=vars.out -f var_dump_test.awk awk_test.txt
# 查看变量信息
# cat vars.out

# 示例7：处理非十进制数据
cat > hex_oct_test.txt << 'EOF'
Decimal: 100
Hex: 0x64
Octal: 0144
EOF

# 启用非十进制数据识别
# awk -n '{ print $1, "value:", $2 + 0 }' hex_oct_test.txt

# 示例8：使用pretty-print格式化程序
# 创建一个格式混乱的程序
cat > messy_program.awk << 'EOF'
BEGIN{print "Start"} {if($2>80){print $1" passed"}else{print $1" failed"}} END{print "Done"}
EOF

# 格式化程序
# awk --pretty-print=formatted.awk -f messy_program.awk
# 查看格式化后的程序
# cat formatted.awk

# 示例9：生成国际化模板文件
cat > i18n_program.awk << 'EOF'
BEGIN {
    print "欢迎使用awk程序"
    print "This is an awk program"
}
{ 
    printf "处理第%d行: %s\n", NR, $0
}
END {
    print "程序执行完毕"
    print "Program completed"
}
EOF

# 生成.pot文件
# awk --gen-pot -f i18n_program.awk > program.pot
# 查看生成的模板文件
# cat program.pot


## 3. 基本使用方法

### 3.1 打印整个文件

最简单的`awk`命令是打印整个文件的内容：

```bash
# 打印整个文件内容
awk '{ print }' awk_test.txt

# 等价于
awk '{ print $0 }' awk_test.txt
```

这里的`$0`表示整行内容。

### 3.2 打印指定字段

`awk`会自动将每行分割成字段，默认以空格或制表符为分隔符，字段编号从1开始：

```bash
# 打印每行的第一个字段
awk '{ print $1 }' awk_test.txt

# 打印每行的第一个和第三个字段
awk '{ print $1, $3 }' awk_test.txt

# 使用不同的输出分隔符
awk '{ print $1 " - " $3 }' awk_test.txt
```

### 3.3 指定字段分隔符

使用`-F`参数可以指定不同的字段分隔符：

```bash
# 使用逗号作为分隔符
awk -F, '{ print $1, $4 }' data.csv

# 使用多个字符作为分隔符（使用正则表达式）
awk -F'[, ]' '{ print $1, $3 }' data.csv

# 使用多个可能的分隔符
awk -F'[:; ]' '{ print $1 }' /etc/passwd
```

### 3.4 使用BEGIN和END块

`BEGIN`块在处理任何输入行之前执行，`END`块在处理完所有输入行之后执行：

```bash
# 使用BEGIN块设置标题，END块计算总数
awk 'BEGIN { print "Name\tTotal" } { total = $2 + $3 + $4; print $1 "\t" total } END { print "-----------------\nDone processing" }' awk_test.txt

# 计算文件中的行数
awk 'END { print "Total lines: " NR }' awk_test.txt
```

## 4. 模式匹配

### 4.1 使用正则表达式匹配

```bash
# 匹配包含"Bob"的行
awk '/Bob/ { print }' awk_test.txt

# 匹配以"A"开头的行
awk '/^A/ { print }' awk_test.txt

# 匹配以数字结尾的行
awk '/[0-9]$/ { print }' awk_test.txt
```

### 4.2 使用比较运算符

```bash
# 打印第二个字段大于80的行
awk '$2 > 80 { print }' awk_test.txt

# 打印第一个字段等于"Alice"的行
awk '$1 == "Alice" { print }' awk_test.txt

# 打印第三个字段不等于90的行
awk '$3 != 90 { print }' awk_test.txt
```

### 4.3 使用逻辑运算符

```bash
# 逻辑与：打印第二个字段大于80且第三个字段小于95的行
awk '$2 > 80 && $3 < 95 { print }' awk_test.txt

# 逻辑或：打印第一个字段是"Alice"或"Bob"的行
awk '$1 == "Alice" || $1 == "Bob" { print }' awk_test.txt

# 逻辑非：打印第一个字段不是"David"的行
awk '$1 != "David" { print }' awk_test.txt
```

### 4.4 范围模式

```bash
# 匹配从包含"Alice"的行到包含"Charlie"的行
awk '/Alice/,/Charlie/ { print }' awk_test.txt

# 匹配从第1行到第3行
awk 'NR >= 1 && NR <= 3 { print }' awk_test.txt
```

## 5. 变量和函数

### 5.1 变量概述

`awk`变量是动态的，它们在首次使用时自动创建。变量的值可以是浮点数、字符串或两者兼具，具体取决于它们的使用方式。此外，gawk还允许变量具有正则表达式类型。

**变量特点：**
- 无需声明，首次使用时自动创建
- 支持数字、字符串和正则表达式类型
- 支持一维数组，多维数组可通过模拟实现
- gawk提供真正的数组的数组功能

### 5.1.1 变量类型转换

`awk`根据上下文自动转换变量类型，但也可以手动控制：

```bash
# 变量类型转换示例
awk 'BEGIN {
    # 未初始化变量
    print "Uninitialized variable:"  
    print "Numeric value:", uninitialized + 0  # 输出0
    print "String value:", uninitialized ""   # 输出空字符串
    
    # 强制类型转换
    num = "123.45"
    str = 678.90
    
    print "\nType conversion:"
    print "Force numeric:", num + 0      # 输出123.45
    print "Force string:", str ""       # 输出678.9
    
    # CONVFMT控制数字到字符串的转换
    print "\nCONVFMT effect:"
    CONVFMT = "%.2f"
    a = 12
    b = a ""  # 即使CONVFMT设置为%.2f，整数仍会转换为整数形式
    print "Integer conversion:", b  # 输出12
    
    c = 12.345
    d = c ""  # 使用CONVFMT格式
    print "Float conversion:", d  # 输出12.35
}'

### 5.1.2 命名空间

gawk提供简单的命名空间功能，帮助解决变量全局化的问题：

```bash
# 命名空间示例
awk 'BEGIN {
    # 使用默认命名空间（awk）
    var1 = "global variable"
    
    # 定义带命名空间的变量
    myns::var2 = "in my namespace"
    
    # 访问命名空间变量
    print "Default namespace variable:", var1
    print "myns namespace variable:", myns::var2
    
    # 切换当前命名空间
    @namespace "myns"
    
    # 现在直接定义的变量属于myns命名空间
    var3 = "in current namespace"
    
    # 访问不同命名空间的变量
    print "Current namespace variable:", var3
    print "Default namespace variable:", awk::var1
    
    # 大写变量始终属于awk命名空间
    UPPERCASE = "uppercase in awk namespace"
    print "UPPERCASE in awk namespace:", awk::UPPERCASE
}'

### 5.1.3 八进制和十六进制常量

可以在awk程序中使用C风格的八进制和十六进制常量：

```bash
# 八进制和十六进制常量示例
awk 'BEGIN {
    # 八进制常量
    octal = 011  # 十进制9
    # 十六进制常量
    hex = 0x11   # 十进制17
    
    print "Octal 011 = decimal", octal
    print "Hex 0x11 = decimal", hex
    print "Sum =", octal + hex
}'

### 5.1.4 字符串常量和转义序列

字符串常量用双引号括起来，支持多种转义序列：

```bash
# 字符串转义序列示例
awk 'BEGIN {
    # 基本转义序列
    print "Newline:\nTab:\tBackslash:\\"
    print "Alert(beep):\a"
    print "Backspace:\b"
    print "Form-feed:\f"
    print "Carriage return:\r"
    print "Vertical tab:\v"
    
    # 打印包含引号的字符串
    print "String with \"quotes\""
    
    # 十六进制转义序列（最多两位十六进制数字）
    print "\nHex escape sequence:"
    print "ESC character (\x1B):", "\x1B"
    print "ASCII 65 (A):", "\x41"
    
    # 八进制转义序列（1-3位八进制数字）
    print "\nOctal escape sequence:"
    print "ESC character (\033):", "\033"
    print "ASCII 65 (A):", "\101"
    
    # 字面字符转义
    print "\nLiteral character escape:"
    print "Backslash: \\c where c is any character"
}'

### 5.1.5 正则表达式常量

正则表达式常量用斜杠（/）括起来，gawk还支持强类型正则表达式常量：

```bash
# 正则表达式常量示例
awk 'BEGIN {
    # 基本正则表达式匹配
    print "Basic regex matching:"
    text = "Hello, World!"
    if (text ~ /World/) {
        print "Text contains 'World'"
    }
    
    # 正则表达式中的转义序列
    print "\nRegex with escape sequences:"
    whitespace = "Line1\nLine2\tLine3"
    gsub(/[ \t\f\n\r\v]+/, ", ", whitespace)
    print "Normalized whitespace:", whitespace
    
    # gawk强类型正则表达式常量（使用@前缀）
    print "\ngawk strongly typed regex constants:"
    
    # 创建强类型正则表达式变量
    number_regex = @/[0-9]+/
    word_regex = @/[a-zA-Z]+/
    
    # 使用强类型正则表达式
    test_text = "abc123def"
    
    if (test_text ~ number_regex) {
        print "Text contains numbers"
    }
    
    if (test_text ~ word_regex) {
        print "Text contains words"
    }
    
    # 将正则表达式作为参数传递给函数
    function check_pattern(str, pattern) {
        if (str ~ pattern) {
            return "Match found"
        } else {
            return "No match"
        }
    }
    
    print "Check with number pattern:", check_pattern("42 is the answer", number_regex)
    print "Check with word pattern:", check_pattern("Only words here", word_regex)
}'

## 6. 模式和动作

AWK是一种面向行的语言，由模式和动作组成。模式在前，动作用花括号（{}）括起来。模式或动作可以缺失，但不能同时缺失。

### 6.1 基本概念

```bash
# 基本模式-动作结构
# 模式缺失：对每一行执行动作
awk '{ print $1 }' awk_test.txt

# 动作缺失：等同于 { print }
awk '/Alice/' awk_test.txt

# 完整的模式-动作
awk '$2 > 80 { print $1 " passed" }' awk_test.txt

# 语句分隔符和行继续符
awk 'BEGIN { print "Start"; count=0 } { count++ } END { print "Total:", count }' awk_test.txt

# 使用反斜杠进行行继续
awk 'BEGIN { \
    print "Multi-line\nstatement" \
}'
```

### 6.2 特殊模式

#### 6.2.1 BEGIN和END模式

```bash
# BEGIN和END模式示例
awk 'BEGIN {
    print "Student Grades Report"
    print "====================="
    sum = 0
    count = 0
} {
    # 处理每一行
    sum += $2
    count++
    print $1 ": " $2
} END {
    print "====================="
    print "Average: " sum / count
}' awk_test.txt
```

#### 6.2.2 BEGINFILE和ENDFILE模式（gawk特有）

```bash
# BEGINFILE和ENDFILE模式示例
cat > file1.txt << 'EOF'
Line 1 in file1
Line 2 in file1
EOF

cat > file2.txt << 'EOF'
Line 1 in file2
Line 2 in file2
EOF

# 使用BEGINFILE和ENDFILE处理多个文件
awk 'BEGINFILE {
    print "\nProcessing file: " FILENAME
    # 检查文件是否成功打开
    if (ERRNO) {
        print "Error opening file: " ERRNO
        nextfile  # 跳过无法打开的文件
    }
    file_count++
} {
    line_count++
} ENDFILE {
    print "Lines in " FILENAME ": " FNR
} END {
    print "\nTotal files processed: " file_count
    print "Total lines processed: " line_count
}' file1.txt file2.txt nonexistent.txt
```

### 6.3 模式类型

#### 6.3.1 正则表达式模式

```bash
# 正则表达式模式示例
awk '/^A/' awk_test.txt  # 匹配以A开头的行
awk '/9$/' awk_test.txt  # 匹配以9结尾的行
awk '/[0-9]{2,3}/' awk_test.txt  # 匹配包含2-3位数字的行

# 使用变量作为正则表达式
awk 'BEGIN { pattern = "Bob"; } $0 ~ pattern { print }' awk_test.txt
```

#### 6.3.2 关系表达式模式

```bash
# 关系表达式模式示例
awk '$2 > 80' awk_test.txt  # 第二个字段大于80
awk '$1 == "Alice"' awk_test.txt  # 第一个字段等于Alice
awk 'NF >= 3' awk_test.txt  # 字段数大于等于3
awk '$0 !~ /error/i' app.log  # 不包含error（忽略大小写）
```

#### 6.3.3 逻辑运算符组合

```bash
# 逻辑运算符组合模式
awk '$2 > 80 && $3 > 85' awk_test.txt  # 逻辑与：第二个字段>80且第三个字段>85
awk '$1 == "Alice" || $1 == "Bob"' awk_test.txt  # 逻辑或：名字是Alice或Bob
awk '!($1 ~ /^D/)' awk_test.txt  # 逻辑非：不以D开头

# 使用括号改变优先级
awk '$2 > 80 && ($3 > 85 || $4 > 90)' awk_test.txt
```

#### 6.3.4 三元运算符模式

```bash
# 三元运算符模式
awk '$2 >= 90 ? "Excellent" : ($2 >= 80 ? "Good" : "Average") { print $1 ": " $2 ": " $0 }' awk_test.txt
```

#### 6.3.5 范围模式

```bash
# 范围模式示例
# 匹配从包含Alice的行到包含Charlie的行
awk '/Alice/,/Charlie/' awk_test.txt

# 使用数值范围
awk 'NR >= 2 && NR <= 4' awk_test.txt

# 注意：范围模式不能与其他模式组合
# 下面的写法是错误的：awk '/Alice/,/Charlie/ && $2 > 80' awk_test.txt

# 可以使用变量来模拟复杂的范围条件
awk 'BEGIN { in_range = 0 } 
     /Alice/ { in_range = 1 }
     in_range && $2 > 80 { print }
     /Charlie/ { in_range = 0 }' awk_test.txt
```

### 6.2 记录和字段

#### 6.2.1 记录

记录（Record）通常由换行符分隔。你可以通过设置内置变量`RS`来控制记录的分隔方式：

- 如果`RS`是单个字符，则该字符作为记录分隔符
- 如果`RS`是正则表达式，则匹配该正则表达式的文本作为记录分隔符
- 如果`RS`设置为空字符串，则记录由空行分隔
- 当`RS`为空字符串时，换行符始终作为字段分隔符，无论`FS`的值是什么

在兼容模式下，`RS`值的字符串中只有第一个字符用于分隔记录。

#### 6.2.2 字段

当读取每条输入记录时，gawk会使用`FS`变量的值作为字段分隔符将记录分割成字段：

- 如果`FS`是单个字符，则该字符作为字段分隔符
- 如果`FS`是空字符串，则每个字符单独成为一个字段
- 否则，`FS`被视为完整的正则表达式
- 特殊情况：如果`FS`是单个空格，则字段由连续的空格、制表符或换行符分隔

**注意：** `IGNORECASE`变量的值也会影响当`FS`为正则表达式时字段的分割方式，以及当`RS`为正则表达式时记录的分隔方式。

除了`FS`外，gawk还提供了两种其他方式来定义字段：

1. **FIELDWIDTHS变量**：设置为以空格分隔的数字列表，每个字段具有固定宽度。每个字段宽度前可选择性地加上冒号分隔的值，指定字段开始前要跳过的字符数。

2. **FPAT变量**：设置为表示正则表达式的字符串，每个字段由匹配该正则表达式的文本组成。在这种情况下，正则表达式描述的是字段本身，而不是分隔字段的文本。

#### 6.2.3 字段操作

输入记录中的每个字段可以通过其位置引用：`$1`、`$2`等。`$0`表示整个记录，包括前导和尾随空白。

- 字段引用不必使用常量：`n = 5; print $n`打印输入记录中的第五个字段
- `NF`变量设置为输入记录中的字段总数
- 引用不存在的字段（即`$NF`之后的字段）会产生空字符串
- 对不存在的字段赋值（例如`$(NF+2) = 5`）会增加`NF`的值，创建任何中间字段（值为空字符串），并导致`$0`的值被重新计算，字段之间用`OFS`的值分隔
- 引用负编号的字段会导致致命错误
- 减少`NF`会导致超过新值的字段值丢失，`$0`的值被重新计算，字段之间用`OFS`的值分隔
- 对现有字段赋值会导致在引用`$0`时重建整个记录
- 对`$0`赋值会导致记录被重新分割，为字段创建新值

### 6.3 内置变量

`awk`提供了许多内置变量：

| 变量 | 描述 |
|------|------|
| `$0` | 整行内容 |
| `$1, $2, ...` | 各个字段的值 |
| `ARGC` | 命令行参数的数量（不包括gawk的选项或程序源代码） |
| `ARGIND` | 当前正在处理的文件在ARGV中的索引 |
| `ARGV` | 命令行参数的数组，索引从0到ARGC-1。动态更改ARGV的内容可以控制用于数据的文件 |
| `BINMODE` | 在非POSIX系统上，指定所有文件I/O使用"二进制"模式。数值1、2或3分别指定输入文件、输出文件或所有文件应使用二进制I/O |
| `CONVFMT` | 数字的转换格式，默认为"%.6g" |
| `ENVIRON` | 包含当前环境值的数组，索引为环境变量，每个元素为该变量的值（例如ENVIRON["HOME"]可能为"/home/user"） |
| `ERRNO` | 当在getline重定向、读取或close()过程中发生系统错误时，设置为描述错误的字符串。在非英语环境中可能会被翻译。如果ERRNO中的字符串对应于errno(3)变量中的系统错误，则可以在PROCINFO["errno"]中找到数值。对于非系统错误，PROCINFO["errno"]将为零 |
| `FNR` | 当前输入文件中的记录号 |
| `FILENAME` | 当前文件名。如果命令行上未指定文件，则FILENAME的值为"-"。但是，FILENAME在BEGIN规则内未定义（除非由getline设置） |
| `FIELDWIDTHS` | 以空格分隔的字段宽度列表。设置后，gawk会将输入解析为固定宽度的字段，而不是使用FS变量的值作为字段分隔符。每个字段宽度前可选择性地加上冒号分隔的值，指定字段开始前要跳过的字符数 |
| `FPAT` | 描述记录中字段内容的正则表达式。设置后，gawk会将输入解析为字段，其中字段与正则表达式匹配，而不是使用FS的值作为字段分隔符 |
| `FS` | 输入字段分隔符，默认为空格 |
| `FUNCTAB` | 一个数组，其索引和对应值是程序中所有用户定义或扩展函数的名称。注意：不能对FUNCTAB数组使用delete语句 |
| `IGNORECASE` | 控制所有正则表达式和字符串操作的大小写敏感性。如果IGNORECASE具有非零值，则字符串比较和规则中的模式匹配、使用FS和FPAT进行字段分割、使用RS进行记录分隔、使用~和!~进行正则表达式匹配，以及gensub()、gsub()、index()、match()、patsplit()、split()和sub()内置函数在执行正则表达式操作时都忽略大小写。注意：数组下标不受影响，但asort()和asorti()函数会受影响 |
| `LINT` | 从AWK程序内动态控制--lint选项。当为true时，gawk打印lint警告；当为false时，不打印。--lint选项允许的值也可以赋给LINT，具有相同的效果。任何其他true值都只打印警告 |
| `NF` | 当前输入记录中的字段数 |
| `NR` | 到目前为止看到的输入记录总数 |
| `OFMT` | 数字的输出格式，默认为"%.6g" |
| `OFS` | 输出字段分隔符，默认为空格 |
| `ORS` | 输出记录分隔符，默认为换行符 |
| `PREC` | 任意精度浮点数的工作精度，默认为53 |
| `PROCINFO` | 此数组的元素提供对运行中的AWK程序信息的访问。在某些系统上，数组中可能有元素"group1"到"groupn"（n为进程拥有的补充组数量）。使用in运算符测试这些元素。保证可用的元素包括：
  - PROCINFO["argv"]: gawk在C语言级别接收到的命令行参数，下标从0开始
  - PROCINFO["egid"]: getegid(2)系统调用的值
  - PROCINFO["errno"]: 当ERRNO设置为关联错误消息时，errno(3)的值
  - PROCINFO["euid"]: geteuid(2)系统调用的值
  - PROCINFO["FS"]: 字段分割使用FS时为"FS"，使用FPAT时为"FPAT"，使用FIELDWIDTHS时为"FIELDWIDTHS"，或API输入解析器字段分割时为"API"
  - PROCINFO["gid"]: getgid(2)系统调用的值
  - PROCINFO["identifiers"]: 子数组，索引为AWK程序文本中使用的所有标识符名称。这些值表示gawk在完成程序解析后对标识符的了解，程序运行时不会更新。每个标识符的值为以下之一：
    - "array": 标识符是数组
    - "builtin": 标识符是内置函数
    - "extension": 标识符是通过@load或--load加载的扩展函数
    - "scalar": 标识符是标量
    - "untyped": 标识符是未类型化的（可以用作标量或数组，gawk尚不知道）
    - "user": 标识符是用户定义的函数
  - PROCINFO["pgrpid"]: getpgrp(2)系统调用的值
  - PROCINFO["pid"]: getpid(2)系统调用的值
  - PROCINFO["platform"]: 指示gawk编译平台的字符串。它是以下之一：
    - "djgpp", "mingw": 使用DJGPP或MinGW的Microsoft Windows
    - "os2": OS/2
    - "posix": GNU/Linux、Cygwin、Mac OS X和传统Unix系统
    - "vms": OpenVMS或Vax/VMS
  - PROCINFO["ppid"]: getppid(2)系统调用的值
  - PROCINFO["strftime"]: strftime()的默认时间格式字符串。更改其值会影响strftime()调用时格式化时间值的方式
  - PROCINFO["uid"]: getuid(2)系统调用的值
  - PROCINFO["version"]: gawk的版本
  - PROCINFO["api_major"]: 扩展API的主版本号（当加载动态扩展可用时）
  - PROCINFO["api_minor"]: 扩展API的次版本号（当加载动态扩展可用时）
  - PROCINFO["gmp_version"]: GNU GMP库的版本（当编译了MPFR支持时）
  - PROCINFO["mpfr_version"]: GNU MPFR库的版本（当编译了MPFR支持时）
  - PROCINFO["prec_max"]: GNU MPFR库支持的任意精度浮点数的最大精度（当编译了MPFR支持时）
  - PROCINFO["prec_min"]: GNU MPFR库允许的任意精度浮点数的最小精度（当编译了MPFR支持时）
  - PROCINFO["NONFATAL"]: 如果存在，则所有重定向的I/O错误变为非致命
  - PROCINFO["name", "NONFATAL"]: 使name的I/O错误变为非致命
  - PROCINFO["command", "pty"]: 使用伪终端与command进行双向通信，而不是设置两个单向管道
  - PROCINFO["input", "READ_TIMEOUT"]: 从input读取数据的超时时间（毫秒），input是重定向字符串或文件名
  - PROCINFO["input", "RETRY"]: 如果在从input读取数据时发生可能重试的I/O错误，则getline返回-2而不是-1
  - PROCINFO["sorted_in"]: 控制for循环中数组元素的遍历顺序。支持的值包括"@ind_str_asc"、"@ind_num_asc"等，也可以是自定义比较函数名称
| `RS` | 输入记录分隔符，默认为换行符 |
| `ROUNDMODE` | 任意精度算术的舍入模式，默认为"N"（IEEE-754 roundTiesToEven模式）。接受的值包括："A"/"a"（舍入远离零）、"D"/"d"（向负无穷舍入）、"N"/"n"（偶数舍入）、"U"/"u"（向正无穷舍入）、"Z"/"z"（向零舍入） |
| `RT` | 记录终止符。gawk将RT设置为由RS指定的字符或正则表达式匹配的输入文本 |
| `RSTART` | match()匹配的第一个字符的索引；无匹配时为0（字符索引从1开始） |
| `RLENGTH` | match()匹配的字符串长度；无匹配时为-1 |
| `SUBSEP` | 用于分隔数组元素中多个下标的字符串，默认为"\034" |
| `SYMTAB` | 一个数组，其索引是程序中所有当前定义的全局变量和数组的名称。可用于间接访问读取或修改变量的值 |
| `TEXTDOMAIN` | AWK程序的文本域；用于查找程序字符串的本地化翻译 |

```bash
# 打印行号和字段数
awk '{ print "Line", NR, ":", NF, "fields" }' awk_test.txt

# 使用FS和OFS变量
awk 'BEGIN { FS=","; OFS=" - " } { print $1, $2, $3 }' data.csv

# 使用FIELDWIDTHS处理固定宽度字段
# 创建一个固定宽度格式的测试文件
cat > fixed_width.txt << 'EOF'
John    28   Engineer
Alice   32   Designer
Bob     45   Manager
EOF

# 使用FIELDWIDTHS分隔固定宽度字段
awk 'BEGIN { FIELDWIDTHS="10 5 10" } { print "Name:", $1, "Age:", $2, "Job:", $3 }' fixed_width.txt

# 使用FPAT处理复杂格式（匹配字段而不是分隔符）
# 创建一个复杂格式的测试文件
cat > complex_data.txt << 'EOF'
{name:"John", age:28, role:"Engineer"}
{name:"Alice", age:32, role:"Designer"}
{name:"Bob", age:45, role:"Manager"}
EOF

# 使用FPAT提取字段内容
awk 'BEGIN { FPAT="[a-zA-Z]+" } { print "Name:", $2, "Role:", $6 }' complex_data.txt

# 使用ENVIRON数组访问环境变量
awk 'BEGIN {
    # 访问HOME环境变量
    print "Home directory:", ENVIRON["HOME"]
    # 访问PATH环境变量
    print "PATH:", ENVIRON["PATH"]
    # 访问当前用户环境变量（根据不同系统可能有所不同）
    print "Current user:", ENVIRON["USER"] || ENVIRON["USERNAME"]
    
    # 遍历所有环境变量
    print "\nAll environment variables:"
    for (var in ENVIRON) {
        print var ": " ENVIRON[var]
    }
}'

# 使用PROCINFO数组获取进程信息
awk 'BEGIN {
    print "Process ID:", PROCINFO["pid"]
    print "Parent Process ID:", PROCINFO["ppid"]
    print "Process Group ID:", PROCINFO["pgrpid"]
    print "Platform:", PROCINFO["platform"]
    print "Current effective user ID:", PROCINFO["euid"]
    print "Current effective group ID:", PROCINFO["egid"]
    print "Current real group ID:", PROCINFO["gid"]
    print "Current real user ID:", PROCINFO["uid"]
    
    # 获取gawk版本信息
    print "\nGAWK Version:", PROCINFO["version"]
    
    # 检查扩展API版本（如果可用）
    if ("api_major" in PROCINFO) {
        print "Extension API Version:", PROCINFO["api_major"] "." PROCINFO["api_minor"]
    }
    
    # 检查GMP/MPFR版本（如果可用）
    if ("gmp_version" in PROCINFO) {
        print "GMP Version:", PROCINFO["gmp_version"]
    }
    if ("mpfr_version" in PROCINFO) {
        print "MPFR Version:", PROCINFO["mpfr_version"]
    }
    
    # 获取命令行参数
    print "\nCommand line arguments:"
    for (i=0; i < length(PROCINFO["argv"]); i++) {
        print "Arg", i, ":", PROCINFO["argv"][i]
    }
    
    # 检查平台类型
    print "\nPlatform type check:"
    if (PROCINFO["platform"] == "posix") {
        print "Running on POSIX compatible system (Linux, Unix, macOS, Cygwin)"
    } else if (PROCINFO["platform"] ~ /^(djgpp|mingw)$/) {
        print "Running on Microsoft Windows"
    } else if (PROCINFO["platform"] == "os2") {
        print "Running on OS/2"
    } else if (PROCINFO["platform"] == "vms") {
        print "Running on OpenVMS or Vax/VMS"
    }
    
    # 检查当前使用的字段分隔模式
    print "\nField splitting mode:"
    print "Current field splitting in use:", PROCINFO["FS"]
}'

# 演示PROCINFO["identifiers"]子数组的使用
awk 'BEGIN {
    # 定义一些变量和函数以便在identifiers中显示
    scalar_var = 10
    array_var["index"] = 20
    
    function user_func() {}
    
    print "\nIdentifiers information:"
    # 遍历identifiers子数组
    for (id in PROCINFO["identifiers"]) {
        # 只显示我们定义的标识符类型
        if (PROCINFO["identifiers"][id] ~ /^(array|scalar|user)$/) {
            print "Identifier:", id, "Type:", PROCINFO["identifiers"][id]
        }
    }
}'

# 使用ERRNO处理文件操作错误
awk 'BEGIN {
    # 尝试打开一个不存在的文件
    if ((getline < "nonexistent_file.txt") == -1) {
        print "Error reading file:", ERRNO
        print "Error number:", PROCINFO["errno"]
    }
}'

# 演示PROCINFO["FS"]在不同字段分隔模式下的变化
# 1. 默认FS模式
awk 'BEGIN {
    print "Default field splitting mode:", PROCINFO["FS"]
}
END {
    print "After processing with default FS:", PROCINFO["FS"]
}' /dev/null

# 2. 使用FPAT模式
awk 'BEGIN {
    FPAT = "[a-zA-Z]++"
    print "FPAT field splitting mode:", PROCINFO["FS"]
}
END {
    print "After processing with FPAT:", PROCINFO["FS"]
}' /dev/null

# 3. 使用FIELDWIDTHS模式
awk 'BEGIN {
    FIELDWIDTHS = "3 2 4"
    print "FIELDWIDTHS field splitting mode:", PROCINFO["FS"]
}
END {
    print "After processing with FIELDWIDTHS:", PROCINFO["FS"]
}' /dev/null

# 演示PROCINFO["sorted_in"]控制数组遍历顺序
awk 'BEGIN {
    # 创建一个关联数组
    data["banana"] = 5
    data["apple"] = 10
    data["cherry"] = 3
    data["date"] = 7
    
    print "\nDefault traversal order:"
    for (key in data) {
        print key, "=", data[key]
    }
    
    print "\nSorted by index (ascending):"
    PROCINFO["sorted_in"] = "@ind_str_asc"
    for (key in data) {
        print key, "=", data[key]
    }
    
    print "\nSorted by value (descending):"
    PROCINFO["sorted_in"] = "@val_num_desc"
    for (key in data) {
        print key, "=", data[key]
    }
    
    # 演示自定义比较函数
    print "\nCustom sort (by value length):"
    function by_value_length(i1, v1, i2, v2) {
        if (v1 < v2) return -1
        if (v1 > v2) return 1
        return 0
    }
    PROCINFO["sorted_in"] = "by_value_length"
    for (key in data) {
        print key, "=", data[key]
    }
}'

# 演示SYMTAB数组间接访问变量
awk 'BEGIN {
    # 定义一些变量
    my_var = 42
    another_var = "Hello, World!"
    
    print "\nUsing SYMTAB for indirect access:"
    print "my_var value:", SYMTAB["my_var"]
    print "another_var value:", SYMTAB["another_var"]
    
    # 修改变量值
    SYMTAB["my_var"] = 100
    print "Modified my_var value:", my_var
    
    # 列出所有定义的变量
    print "\nAll defined variables:"
    for (var in SYMTAB) {
        if (typeof(SYMTAB[var]) != "array") {
            print var, "=", SYMTAB[var]
        }
    }
}'

# 演示ROUNDMODE控制舍入模式
awk 'BEGIN {
    # 设置高精度
    PREC = 53
    
    # 测试不同的舍入模式
    test_num = 1.25
    
    print "\nTesting different rounding modes:"
    
    ROUNDMODE = "N"  # 默认的偶数舍入
    print "ROUNDMODE=N (even):", int(test_num + 0.5)
    
    ROUNDMODE = "Z"  # 向零舍入
    print "ROUNDMODE=Z (toward zero):", int(test_num)
    
    ROUNDMODE = "U"  # 向正无穷舍入
    print "ROUNDMODE=U (up):", int(test_num + 1)
    
    ROUNDMODE = "D"  # 向负无穷舍入
    print "ROUNDMODE=D (down):", int(test_num)
}'

# 演示RT变量（记录终止符）
echo "Line1;Line2;Line3" | awk 'BEGIN { RS = ";" } {
    print "Record:", $0, "RT:", RT
}'

# 演示RSTART和RLENGTH（正则表达式匹配）
awk 'BEGIN {
    text = "Hello, World! This is a test."
    pattern = "World"
    
    if (match(text, pattern)) {
        print "Pattern found at position:", RSTART
        print "Pattern length:", RLENGTH
        print "Matched text:", substr(text, RSTART, RLENGTH)
    }
}'

# 演示SUBSEP（多维数组分隔符）
awk 'BEGIN {
    # 创建多维数组
    multidim["first", "second", "third"] = "value"
    
    # 显示SUBSEP的默认值
    print "SUBSEP default value is a control character (^\\034)", ""
    print "Accessing multidimensional array:" 
    print multidim["first", "second", "third"]
    
    # 手动构建键来访问数组
    key = "first" SUBSEP "second" SUBSEP "third"
    print "Using constructed key:", multidim[key]
}'

# 演示TEXTDOMAIN（本地化）
awk 'BEGIN {
    # 设置文本域
    TEXTDOMAIN = "myapp"
    print "Text domain set to:", TEXTDOMAIN
    # 注意：实际本地化需要相应的.mo文件
}'

# 使用IGNORECASE忽略大小写
# 创建一个测试文件
cat > mixed_case.txt << 'EOF'
Apple banana ORANGE Mango
GrapE PEAR Kiwi
EOF

# 不使用IGNORECASE（区分大小写）
awk '/apple/ { print "Found with case sensitivity:", $0 }' mixed_case.txt

# 使用IGNORECASE（忽略大小写）
awk 'BEGIN { IGNORECASE = 1 } /apple/ { print "Found with IGNORECASE:", $0 }' mixed_case.txt

# 使用LINT控制警告输出
awk 'BEGIN {
    # 启用lint警告
    LINT = 1
    # 尝试使用未初始化的变量作为数组下标（会产生警告）
    print "Trying to use uninitialized variable as array index"
    arr[undefined_var] = 1
}'

# 使用OFMT控制数字输出格式
awk 'BEGIN {
    num = 123.456789
    print "Default format:", num
    
    # 设置自定义输出格式
    OFMT = "%.2f"
    print "Custom format (2 decimal places):", num
    
    OFMT = "%08.2f"
    print "Zero-padded format:", num
}'

# 使用FUNCTAB访问函数信息（GNU awk特有）
awk 'function my_function() { return "Hello" }
BEGIN {
    print "Available functions:"
    for (func in FUNCTAB) {
        print func
    }
    print "\nIs my_function defined?", "my_function" in FUNCTAB ? "Yes" : "No"
}'
```

### 6.4 自定义变量

```bash
# 直接在程序中定义变量
awk 'BEGIN { count=0 } { count++ } END { print "Total lines:", count }' awk_test.txt

# 使用-v参数在命令行定义变量
awk -v threshold=85 '$2 > threshold { print $1 " scored above threshold" }' awk_test.txt
```

### 6.5 数学函数

```bash
# 使用数学函数
awk 'BEGIN { print "Square root of 25:", sqrt(25) }'
awk 'BEGIN { print "Sine of 90 degrees:", sin(3.14159/2) }'
awk 'BEGIN { print "Random number:", rand() }'

# 计算平均值
awk '{ sum += $2 } END { print "Average:", sum/NR }' awk_test.txt
```

### 6.6 字符串函数

```bash
# 字符串长度
awk '{ print $1, "length:", length($1) }' awk_test.txt

# 字符串匹配
awk 'BEGIN { if (match("Hello World", "World")) print "Found at position:", RSTART }'

# 字符串截取
awk 'BEGIN { print substr("Hello World", 7, 5) }'  # 输出"World"

# 字符串替换
awk 'BEGIN { print gensub("World", "Linux", "g", "Hello World") }'
```

## 6. 数组

### 6.1 数组基本操作

`awk`支持关联数组，可以使用字符串作为索引：

```bash
# 基本数组操作
awk 'BEGIN {
    # 创建数组
    fruits["apple"] = "red"
    fruits["banana"] = "yellow"
    fruits["grape"] = "purple"
    
    # 访问数组元素
    print "Apple is", fruits["apple"]
    
    # 遍历数组
    for (fruit in fruits) {
        print fruit, "is", fruits[fruit]
    }
}'

# 使用in运算符检查数组索引
awk 'BEGIN {
    arr["key"] = "value"
    if ("key" in arr) {
        print "Key exists: ", arr["key"]
    }
    # 删除数组元素
    delete arr["key"]
    if (! ("key" in arr)) {
        print "Key no longer exists"
    }
}

### 6.3 多维数组

#### 6.3.1 模拟多维数组

传统的awk通过SUBSEP分隔符模拟多维数组，SUBSEP默认为ASCII控制字符\034（^\）：

```bash
# 模拟多维数组（使用SUBSEP）
awk 'BEGIN {
    # 创建多维数组
    i = "A"; j = "B"; k = "C"
    x[i, j, k] = "hello, world\n"
    
    # 直接访问
    print x[i, j, k]
    
    # 检查多维索引是否存在
    if ((i, j, k) in x) {
        print "Multidimensional index exists"
    }
    
    # 使用SUBSEP构建键
    key = i SUBSEP j SUBSEP k
    print "Using constructed key:", x[key]
    
    # 显示SUBSEP的值
    print "SUBSEP value is a control character (^\\034)"
}'

#### 6.3.2 GAWK真正的多维数组

gawk支持真正的多维数组（数组的数组），不需要矩形结构：

```bash
# gawk真正的多维数组示例
awk 'BEGIN {
    # 创建真正的多维数组
    a[1] = 5
    a[2][1] = 6
    a[2][2] = 7
    
    # 访问多维数组元素
    print "a[1]:", a[1]
    print "a[2][1]:", a[2][1]
    print "a[2][2]:", a[2][2]
    
    # 遍历多维数组
    print "\nTraversing a[2]:"
    for (i in a[2]) {
        print "a[2][" i "]:", a[2][i]
    }
}'

# 演示数组的数组作为函数参数
awk 'BEGIN {
    # 创建子数组
    subarr[1] = "one"
    subarr[2] = "two"
    
    # 将子数组赋值给父数组
    parent[1] = subarr
    
    # 注意：需要先创建子数组元素再删除以确保正确类型
    delete parent[2][1]  # 确保parent[2]是数组类型
    
    # 在父数组中添加新的子数组元素
    parent[2][3] = "three"
    
    print "parent[1][1]:", parent[1][1]
    print "parent[2][3]:", parent[2][3]
}
```

### 6.2 数组应用示例

```bash
# 统计单词出现次数
cat > words.txt << 'EOF'
apple banana apple orange banana apple
orange mango apple banana
EOF

awk '{ 
    for (i=1; i<=NF; i++) {
        count[$i]++
    }
} 
END { 
    print "Word counts:"
    for (word in count) {
        print word ":", count[word]
    }
}' words.txt

# 统计日志中每个级别的消息数量
awk '{
    level = $3
    count[level]++
} 
END {
    print "Log level counts:"
    for (l in count) {
        print l ":", count[l]
    }
}' app.log
```

## 7. 控制结构

### 7.1 if-else语句

```bash
# 使用if-else语句
awk '{ 
    total = $2 + $3 + $4
    if (total >= 270) {
        grade = "A"
    } else if (total >= 240) {
        grade = "B"
    } else if (total >= 210) {
        grade = "C"
    } else {
        grade = "F"
    }
    print $1, "Total:", total, "Grade:", grade
}' awk_test.txt
```

### 6.7 循环结构

```bash
# for循环
awk 'BEGIN { 
    for (i=1; i<=5; i++) {
        print "Count:", i
    }
}'

# while循环
awk 'BEGIN { 
    i=1
    while (i<=5) {
        print "Count:", i
        i++
    }
}'

# do-while循环
awk 'BEGIN { 
    i=1
    do {
        print "Count:", i
        i++
    } while (i<=5)
}'
```

### 7.3 switch语句

GNU awk支持switch语句：

```bash
# switch语句
awk '{
    switch ($1) {
        case "Alice":
            print "Hello Alice"
            break
        case "Bob":
            print "Hello Bob"
            break
        default:
            print "Hello Stranger"
    }
}' awk_test.txt
```

## 8. 实用示例

### 8.1 处理CSV文件

```bash
# 打印CSV文件中特定列
awk -F, '{ print $1, "lives in", $3, "and earns", $4 }' data.csv

# 过滤CSV文件中符合条件的行
awk -F, '$4 > 100000 { print $1, "has a high salary" }' data.csv

# 计算CSV文件中数值列的总和
awk -F, 'NR>1 { sum += $4 } END { print "Total salary:", sum }' data.csv
```

### 8.2 日志文件分析

```bash
# 提取日志中的错误信息
awk '/ERROR/ { print }' app.log

# 统计每种日志级别的出现次数
awk '{ level[$3]++ } END { for (l in level) print l ":" level[l] }' app.log

# 提取特定时间段的日志
awk '$1 " " $2 >= "2024-02-01 11:00:00" && $1 " " $2 <= "2024-02-01 15:00:00" { print }' app.log
```

### 8.3 文本转换

```bash
# 将空格分隔的文件转换为CSV格式
awk 'BEGIN { OFS="," } { print $1, $2, $3, $4 }' awk_test.txt

# 格式化输出（对齐列）
awk '{ printf "%-10s %5d %5d %5d\n", $1, $2, $3, $4 }' awk_test.txt

# 将文本转换为大写
awk '{ print toupper($0) }' awk_test.txt
```

### 8.4 数据统计

```bash
# 计算第二列的总和、平均值、最大值和最小值
awk '{
    sum += $2
    if (NR == 1 || $2 > max) max = $2
    if (NR == 1 || $2 < min) min = $2
} 
END {
    print "Sum:", sum
    print "Average:", sum/NR
    print "Max:", max
    print "Min:", min
}' awk_test.txt

# 计算每行的总和和平均值
awk '{
    sum = 0
    for (i=2; i<=NF; i++) sum += $i
    avg = sum / (NF-1)
    print $1, "Total:", sum, "Average:", avg
}' awk_test.txt
```

## 9. 高级技巧

### 9.1 使用awk脚本文件

对于复杂的处理任务，可以将awk程序保存到文件中：

```bash
# 创建awk脚本文件
cat > analyze.awk << 'EOF'
BEGIN {
    print "Student Analysis Report"
    print "====================="
    print "Name\tTotal\tAverage"
    print "---------------------"
}
{
    total = $2 + $3 + $4
    avg = total / 3
    print $1 "\t" total "\t" avg
    all_total += total
    count++
}
END {
    print "---------------------"
    print "Class Average:\t" all_total/count
}
EOF

# 运行awk脚本
awk -f analyze.awk awk_test.txt
```

### 9.2 多文件处理

```bash
# 处理多个文件
awk '{
    print FILENAME ":" NR ":" $0
}' awk_test.txt data.csv

# 在多文件处理中使用FNR（每个文件的行号）
awk '{
    print FILENAME ":" FNR ":" $0
}' awk_test.txt data.csv
```

### 9.3 与其他命令结合使用

```bash
# 与sort命令结合
awk '{ print $2, $1 }' awk_test.txt | sort -nr

# 与grep命令结合
ps aux | grep awk | awk '{ print $1, $2, $11 }'

# 读取find命令的输出
find /etc -name "*.conf" -type f -size +1k | xargs ls -lh | awk '{ print $5, $9 }'
```

### 9.4 自定义函数

```bash
# 定义和使用自定义函数
awk 'function calculate_average(num1, num2, num3) {
    return (num1 + num2 + num3) / 3
}
{
    avg = calculate_average($2, $3, $4)
    print $1 "\'s average:", avg
}' awk_test.txt
```

## 10. 常见陷阱与解决方案

### 10.1 字段分隔符问题

**问题**：默认的字段分隔符可能无法正确处理某些格式的文件。

**解决方案**：
- 使用`-F`参数明确指定字段分隔符
- 对于复杂的分隔符模式，使用正则表达式

```bash
# 处理包含多个空格或制表符的文件
awk -F'[[:space:]]+' '{ print $1, $2 }' file.txt

# 处理混合分隔符
awk -F'[,;\t ]+' '{ print $1, $2 }' mixed_separators.txt
```

### 10.2 引号和转义问题

**问题**：在shell中使用awk时，引号和特殊字符可能会导致问题。

**解决方案**：
- 使用单引号包围awk程序
- 对于需要在程序中使用单引号的情况，可以使用转义或变量

```bash
# 正确处理单引号
awk '\''{ print "It\'s a test" }'\'' file.txt

# 或者使用变量
awk -v quote="'" '{ print "It" quote "s a test" }' file.txt
```

### 10.3 性能优化

**问题**：处理大型文件时，awk可能会变慢。

**解决方案**：
- 尽可能使用简单的模式
- 避免在循环中进行复杂的计算
- 对于非常大的文件，可以先用其他工具过滤

```bash
# 先过滤再处理，提高性能
grep "ERROR" large.log | awk '{ print $1, $2 }'

# 使用next跳过不需要处理的行
awk '$1 == "skip" { next } { print }' large_file.txt
```

## 11. 总结

`awk`是一个功能强大的文本处理工具，它结合了命令行工具的便捷性和编程语言的灵活性。掌握`awk`命令的关键在于：

1. 理解其工作原理（逐行处理和字段分割）
2. 熟练掌握模式匹配和操作语法
3. 灵活运用变量、数组和控制结构
4. 学习各种内置函数和自定义函数的使用
5. 掌握与其他命令的组合使用技巧

通过本文介绍的各种技巧和示例，您应该能够在日常工作中充分利用`awk`命令，提高文本处理和数据分析的效率。无论是日志分析、数据转换还是统计计算，`awk`都能成为您得力的助手。

## 12. 参考链接

- [GNU awk 官方文档](https://www.gnu.org/software/gawk/manual/)
- [Linux man 手册 awk(1)](https://man7.org/linux/man-pages/man1/awk.1p.html)
- [awk 编程语言](https://ia802309.us.archive.org/25/items/pdfy-MgN0H1joIoDVoIC7/The_AWK_Programming_Language.pdf)

> 您可以参考我们的[Linux文本处理工具精通指南](https://soveranzhong.github.io/2024/01/20/linux-text-processing-tools.html)获取更多Linux文本处理工具的详细介绍。