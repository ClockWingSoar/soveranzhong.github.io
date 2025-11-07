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
```
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
```
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
```
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
```
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
```
#### 5.1.6 正则表达式语法详解

以下是AWK中正则表达式的完整语法参考：

```
[abc...]   字符列表：匹配abc...中的任意字符。可以使用破折号分隔字符来表示字符范围。要在列表中包含字面意义的破折号，请将其放在最前面或最后面。

        [^abc...]  否定字符列表：匹配除了abc...之外的任意字符。
     
        r1|r2      选择：匹配r1或r2。
     
        r1r2       连接：匹配r1，然后匹配r2。
     
        r+         匹配一个或多个r。
    
        r*         匹配零个或多个r。
     
        r?         匹配零个或一个r。
     
        (r)        分组：匹配r。
     
        r{n}
        r{n,}
        r{n,m}     大括号内的一个或两个数字表示区间表达式。如果大括号内有一个数字，则前面的正则表达式r重复n次。如果有两个由逗号分隔的数字，则r重复n到m次。如果有一个数字后跟逗号，则r至少重复n次。
     
        \y         匹配单词开头或结尾的空字符串。
     
        \B         匹配单词内部的空字符串。
     
        \\         匹配单词开头的空字符串。
     
        \\>        匹配单词结尾的空字符串。
     
        \s         匹配任意空白字符。
     
        \S         匹配任意非空白字符。
     
        \w         匹配任意单词构成字符（字母、数字或下划线）。
     
        \W         匹配任意非单词构成字符。
     
        \`         匹配缓冲区（字符串）开头的空字符串。
     
        \'         匹配缓冲区结尾的空字符串。
```

**POSIX字符类**：

```
[:alnum:]  字母数字字符。

[:alpha:]  字母字符。

[:blank:]  空格或制表符。

[:cntrl:]  控制字符。

[:digit:]  数字字符。

[:graph:]  既可打印又可见的字符。

[:lower:]  小写字母字符。

[:print:]  可打印字符。

[:punct:]  标点符号字符。

[:space:]  空白字符。

[:upper:]  大写字母字符。

[:xdigit:] 十六进制数字字符。
```

**排序符号和等价类**（多字节字符集支持）：

- `[[.ch.]]` - 排序符号，匹配多字符排序元素
- `[[=e=]]` - 等价类，匹配具有相同排序权重的所有字符

**正则表达式模式匹配控制**：

- 默认模式：支持完整POSIX正则表达式和GNU扩展
- `--posix`：仅支持POSIX正则表达式，GNU操作符被视为普通字符
- `--traditional`：使用传统awk的正则表达式语法

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

### 7.1 正则表达式模式匹配控制

传统UNIX awk使用标准的正则表达式匹配。GNU操作符不被视为特殊字符，并且区间表达式不可用。由八进制和十六进制转义序列描述的字符被视为字面量，即使它们表示正则表达式元字符。

```bash
# 使用--re-interval选项启用区间表达式
awk --re-interval '/[0-9]{2,3}/' file.txt
```

**--re-interval**

允许在正则表达式中使用区间表达式，即使已提供了--traditional选项。

### 7.2 运算符

AWK中的运算符按优先级从高到低排列如下：

```bash
(...)       分组

$           字段引用

++ --       递增和递减，前缀和后缀

^           幂运算（也可以使用**，以及**=作为赋值运算符）

+ - !       一元加号、一元减号和逻辑非

* / %       乘法、除法和取模

+ -         加法和减法

空格        字符串连接

|   |&      getline、print和printf的管道I/O

< > <= >= == !=
            常规关系运算符

~ !~        正则表达式匹配、否定匹配。注意：不要在~或!~的左侧使用常量正则表达式(/foo/)。只在右侧使用。表达式/foo/ ~ exp与((($0 ~ /foo/) ~ exp))具有相同的含义。这通常不是您想要的。

in          数组成员资格

&&          逻辑与

||          逻辑或

?:          C条件表达式。形式为expr1 ? expr2 : expr3。如果expr1为真，表达式的值为expr2，否则为expr3。只计算expr2和expr3中的一个。

= += -= *= /= %= ^=
            赋值。支持绝对赋值(var = value)和运算符赋值(其他形式)。
```

### 7.3 控制语句

控制语句如下：

```bash
if (condition) statement [ else statement ]
while (condition) statement
do statement while (condition)
for (expr1; expr2; expr3) statement
for (var in array) statement
break
continue
delete array[index]
delete array
exit [ expression ]
{ statements }
switch (expression) {
case value|regex : statement
...
[ default: statement ]
}
```

### 7.4 I/O语句

输入/输出语句如下：

```bash
close(file [, how])   关闭文件、管道或协同进程。可选的how参数只应在关闭到协同进程的双向管道的一端时使用。它必须是字符串值，"to"或"from"。

getline               从下一个输入记录设置$0；设置NF、NR、FNR、RT。

getline <file         从文件的下一个记录设置$0；设置NF、RT。

getline var           从下一个输入记录设置var；设置NR、FNR、RT。

getline var <file     从文件的下一个记录设置var；设置RT。

command | getline [var]
                      运行命令，将输出通过管道传输到$0或var，并设置RT。

command |& getline [var]
                      运行命令作为协同进程，将输出通过管道传输到$0或var，并设置RT。协同进程是gawk的扩展。（命令也可以是套接字。）

next                  停止处理当前输入记录。读取下一个输入记录，并从AWK程序的第一个模式开始重新处理。到达输入数据末尾时，执行任何END规则。

nextfile              停止处理当前输入文件。下一个读取的输入记录来自下一个输入文件。更新FILENAME和ARGIND，将FNR重置为1，并从AWK程序的第一个模式开始重新处理。到达输入数据末尾时，执行任何ENDFILE和END规则。

print                 打印当前记录。输出记录以ORS的值结束。

print expr-list       打印表达式。每个表达式由OFS的值分隔。输出记录以ORS的值结束。

print expr-list >file 将表达式打印到文件。每个表达式由OFS的值分隔。输出记录以ORS的值结束。

printf fmt, expr-list 格式化并打印。

printf fmt, expr-list >file
                      格式化并打印到文件。

system(cmd-line)      执行命令cmd-line，并返回退出状态。

fflush([file])        刷新与打开的输出文件或管道文件相关联的任何缓冲区。如果file缺失或是空字符串，则刷新所有打开的输出文件和管道。
```

print和printf还允许其他输出重定向：

```bash
print ... >> file       # 将输出追加到文件
print ... | command     # 将输出写入管道
print ... |& command    # 将数据发送到协同进程或套接字
```

#### printf格式说明

AWK版本的printf语句和sprintf()函数接受以下格式说明符：

**基本格式转换符：**
- `%a`, `%A`: 以[-]0xh.hhhhp+-dd形式的十六进制浮点数（C99格式）。%A使用大写字母。
- `%c`: 单个字符。如果参数是数字，则将其视为字符打印；否则，假设参数是字符串，只打印第一个字符。
- `%d`, `%i`: 十进制数字（整数部分）。
- `%e`, `%E`: 以[-]d.dddddde[+-]dd形式的浮点数。%E使用E而不是e。
- `%f`, `%F`: 以[-]ddd.dddddd形式的浮点数。如果系统库支持，%F也可用，对于特殊的"非数字"和"无穷大"值使用大写字母。
- `%g`, `%G`: 使用%e或%f转换，取较短者，去除无意义的零。%G使用%E代替%e。
- `%o`: 无符号八进制数（也是整数）。
- `%u`: 无符号十进制数（同样是整数）。
- `%s`: 字符串。
- `%x`, `%X`: 无符号十六进制数（整数）。%X使用ABCDEF而不是abcdef。
- `%%`: 单个%字符，不需要参数转换。

**可选修饰符（位于%和控制字母之间）：**
- `count$`: 在此时使用第count个参数。这称为位置指定符，主要用于翻译后的格式字符串。
- `-`: 表达式应在其字段内左对齐。
- `space`: 对于数值转换，正数前添加空格，负数前添加减号。
- `+`: 始终为数值转换提供符号，即使要格式化的数据是正数。+会覆盖空格修饰符。
- `#`: 对某些控制字母使用"备用形式"。对于%o，提供前导零。对于%x和%X，对非零结果提供前导0x或0X。对于%e、%E、%f和%F，结果始终包含小数点。对于%g和%G，不从结果中删除尾随零。
- `0`: 前导0表示输出应使用零而不是空格填充。这仅适用于数值输出格式。
- `'`: 单引号字符指示gawk在十进制数中插入区域设置的千位分隔符字符，并在浮点格式中使用区域设置的小数点字符。
- `width`: 字段应填充到此宽度。默认使用空格填充，使用0标志时使用零填充。
- `.prec`: 指定打印时使用的精度。对于%e、%E、%f和%F格式，这指定要打印到小数点右侧的位数。对于%g和%G格式，它指定最大有效数字位数。对于%s格式，它指定应该打印的字符串的最大字符数。

支持ISO C printf()例程的动态宽度和精度功能。格式字符串中宽度或精度规范位置的*会使它们的值从printf或sprintf()的参数列表中获取。

#### 特殊文件名称

当从print或printf重定向到文件，或通过getline从文件读取时，gawk会识别某些特殊的文件名。这些文件名允许访问从gawk父进程（通常是shell）继承的打开文件描述符。这些文件名也可以在命令行上用于命名数据文件。

**标准文件描述符相关文件名：**
- `/dev/stdin`: 标准输入
- `/dev/stdout`: 标准输出
- `/dev/stderr`: 标准错误输出
- `/dev/fd/n`: 与打开的文件描述符n关联的文件

这些在错误消息输出时特别有用，例如：

```bash
print "You blew it!" > "/dev/stderr"
```

而不是使用：

```bash
print "You blew it!" | "cat 1>&2"
```

**网络连接相关文件名（用于|&协同进程运算符）：**

TCP/IP连接：
- `/inet/tcp/lport/rhost/rport`: 在本地端口lport与远程主机rhost的远程端口rport之间建立TCP/IP连接
- `/inet4/tcp/lport/rhost/rport`: 强制使用IPv4连接
- `/inet6/tcp/lport/rhost/rport`: 强制使用IPv6连接

UDP/IP连接：
- `/inet/udp/lport/rhost/rport`: 使用UDP/IP而不是TCP/IP
- `/inet4/udp/lport/rhost/rport`: 强制使用IPv4的UDP连接
- `/inet6/udp/lport/rhost/rport`: 强制使用IPv6的UDP连接

其中，lport设为0表示让系统选择端口。这些特殊文件名只能与|&双向I/O运算符一起使用。

### 7.5 if-else语句示例

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

### 7.6 数学函数

AWK提供了以下内置算术函数：

- **atan2(y, x)**: 返回y/x的反正切值，单位为弧度
- **cos(expr)**: 返回expr的余弦值，expr以弧度为单位
- **exp(expr)**: 指数函数
- **int(expr)**: 将expr截断为整数
- **log(expr)**: 自然对数函数
- **rand()**: 返回0到1之间的随机数N，满足0 ≤ N < 1
- **sin(expr)**: 返回expr的正弦值，expr以弧度为单位
- **sqrt(expr)**: 返回expr的平方根
- **srand([expr])**: 使用expr作为随机数生成器的新种子。如果未提供expr，则使用当前时间。返回随机数生成器的前一个种子

### 7.7 字符串函数

GNU awk提供了以下内置字符串函数：

### 7.8 时间函数

由于AWK程序的主要用途之一是处理包含时间戳信息的日志文件，gawk提供了以下用于获取时间戳和格式化时间的函数：

- **mktime(datespec [, utc-flag])**: 将datespec转换为与systime()返回的形式相同的时间戳，并返回结果。datespec是一个格式为YYYY MM DD HH MM SS[ DST]的字符串。字符串内容是六个或七个数字，分别表示包含世纪的完整年份、1到12的月份、1到31的日期、0到23的小时、0到59的分钟、0到60的秒以及可选的夏令时标志。这些数字的值不必在指定的范围内；例如，-1小时表示午夜前1小时。假定使用从零点开始的公历，其中第0年在第1年之前，第-1年在第0年之前。如果存在utc-flag且为非零或非空，则假定时间在UTC时区；否则，假定时间在本地时区。如果DST夏令时标志为正，则假定时间为夏令时；如果为零，则假定为标准时间；如果为负（默认值），mktime()将尝试确定指定时间是否处于夏令时。如果datespec不包含足够的元素或者生成的时间超出范围，mktime()返回-1。

- **strftime([format [, timestamp[, utc-flag]]])**: 根据format中的规范格式化timestamp。如果存在utc-flag且为非零或非空，则结果为UTC时间，否则为本地时间。timestamp应该与systime()返回的形式相同。如果缺少timestamp，则使用当前时间。如果缺少format，则使用相当于date(1)输出的默认格式。默认格式可在PROCINFO["strftime"]中找到。

- **systime()**: 返回自纪元（1970-01-01 00:00:00 UTC）以来的当前时间，以秒为单位。

- **asort(s [, d [, how] ])**: 返回源数组s中的元素数量。使用gawk的常规规则对s的内容进行排序，并将排序后的值的索引替换为从1开始的连续整数。如果指定了可选的目标数组d，则首先将s复制到d，然后对d进行排序，保留源数组s的索引不变。可选字符串how控制排序方向和比较模式。

- **asorti(s [, d [, how] ])**: 返回源数组s中的元素数量。行为与asort()相同，不同之处在于数组索引用于排序，而不是数组值。完成后，数组按数字索引，值是原始索引的值。原始值将丢失；因此，如果希望保留原始值，请提供第二个数组。

- **gensub(r, s, h [, t])**: 在目标字符串t中搜索正则表达式r的匹配项。如果h是以下划线g或G开头的字符串，则替换r的所有匹配项为s。否则，h是一个数字，表示要替换r的第几个匹配项。如果未提供t，则使用$0。在替换文本s中，序列\n（其中n是1到9之间的数字）可用于表示与第n个带括号的子表达式匹配的文本。序列\0表示整个匹配的文本，字符&也是如此。与sub()和gsub()不同，修改后的字符串作为函数结果返回，原始目标字符串不变。

- **gsub(r, s [, t])**: 对于字符串t中匹配正则表达式r的每个子字符串，替换为字符串s，并返回替换次数。如果未提供t，则使用$0。替换文本中的&会被实际匹配的文本替换。使用\&获取字面上的&（这必须键入为"\\&"）。

- **index(s, t)**: 返回字符串t在字符串s中的索引，如果t不存在则返回0。（这意味着字符索引从1开始。）对t使用正则表达式常量是致命错误。

- **length([s])**: 返回字符串s的长度，如果未提供s，则返回$0的长度。作为非标准扩展，对于数组参数，length()返回数组中的元素数量。

- **match(s, r [, a])**: 返回正则表达式r在s中出现的位置，如果r不存在则返回0，并设置RSTART和RLENGTH的值。请注意，参数顺序与~运算符相同：str ~ re。如果提供了数组a，则清除a并存储捕获组信息。数组索引0包含整个匹配的文本，索引1到n包含各个捕获组的内容。

- **split(s, a [, r [, seps]])**: 使用分隔符正则表达式r将字符串s分割成数组a的元素，并返回元素数量。如果未提供r，则使用FS的值。split()会忽略空字段。如果提供了可选参数seps，它必须是一个数组，该数组将填充分隔符的字符串。

- **sprintf(format, expr-list)**: 根据format中的指令格式化expr-list中的表达式，并返回生成的字符串而不打印。这与printf语句的工作方式相同，但结果是返回而不是打印。

- **sub(r, s [, t])**: 对于字符串t中第一个匹配正则表达式r的子字符串，替换为字符串s，并返回替换次数（0或1）。如果未提供t，则使用$0。替换文本中的&会被实际匹配的文本替换。

- **substr(s, i [, n])**: 返回字符串s中从索引i开始的子字符串。如果提供了n，则返回最多n个字符；否则，返回从i到字符串末尾的所有字符。在awk中，字符串索引从1开始。

- **tolower(str)**: 返回字符串str的副本，其中所有大写字符都转换为相应的小写字符。非字母字符保持不变。

- **toupper(str)**: 返回字符串str的副本，其中所有小写字符都转换为相应的大写字符。非字母字符保持不变。

- **strtonum(str)**: 检查str并返回其数值。如果str以前导0开头，则将其视为八进制数。如果str以0x或0X开头，则将其视为十六进制数。否则，假定为十进制数。

- **patsplit(s, a [, r [, seps]])**: 根据正则表达式r将字符串s分割成数组a，同时将分隔符保存在seps数组中，并返回字段数量。元素值是s中匹配r的部分。seps[i]的值是出现在a[i]之后的可能为空的分隔符。seps[0]的值是可能为空的前导分隔符。如果省略r，则使用FPAT代替。数组a和seps首先被清除。分割行为与使用FPAT的字段分割完全相同。

Gawk支持多字节处理。这意味着index()、length()、substr()和match()都以字符而不是字节为单位工作。

### 7.9 位操作函数

Gawk提供以下位操作函数。它们的工作方式是将双精度浮点值转换为uintmax_t整数，执行操作，然后将结果转换回浮点数。

**注意：** 向这些函数传递负数会导致致命错误。

- **and(v1, v2 [, ...])**: 返回参数列表中提供的值的按位与。至少需要两个参数。

- **compl(val)**: 返回val的按位取反。

- **lshift(val, count)**: 返回val左移count位后的值。

- **or(v1, v2 [, ...])**: 返回参数列表中提供的值的按位或。至少需要两个参数。

- **rshift(val, count)**: 返回val右移count位后的值。

- **xor(v1, v2 [, ...])**: 返回参数列表中提供的值的按位异或。至少需要两个参数。

### 7.10 类型函数

以下函数提供有关其参数的类型相关信息：

- **isarray(x)**: 如果x是数组则返回true，否则返回false。此函数主要用于多维数组的元素和函数参数。

- **typeof(x)**: 返回一个字符串，指示x的类型。字符串将是"array"、"number"、"regexp"、"string"、"strnum"、"unassigned"或"undefined"之一。

### 7.11 国际化函数

以下函数可用于在AWK程序中在运行时翻译字符串：

- **bindtextdomain(directory [, domain])**: 指定gawk查找.gmo文件的目录，以防它们不会或不能放在"标准"位置（例如，在测试期间）。它返回domain被"绑定"的目录。
  默认域是TEXTDOMAIN的值。如果directory是空字符串("")，则bindtextdomain()返回给定域的当前绑定。

- **dcgettext(string [, domain [, category]])**: 返回文本域domain中字符串string的翻译，用于locale类别category。domain的默认值是TEXTDOMAIN的当前值。category的默认值是"LC_MESSAGES"。
  如果您提供category的值，它必须是一个字符串，等于GAWK: Effective AWK Programming中描述的已知locale类别之一。您还必须提供一个文本域。如果要使用当前域，请使用TEXTDOMAIN。

- **dcngettext(string1, string2, number [, domain [, category]])**: 返回文本域domain中字符串string1和string2翻译的复数形式，用于locale类别category，对应于数字number。domain的默认值是TEXTDOMAIN的当前值。category的默认值是"LC_MESSAGES"。
  如果您提供category的值，它必须是一个字符串，等于GAWK: Effective AWK Programming中描述的已知locale类别之一。您还必须提供一个文本域。如果要使用当前域，请使用TEXTDOMAIN。

### 7.12 用户定义函数

AWK中的函数定义如下：

```awk
function name(parameter list) { statements }
```

函数在从模式或操作中的表达式调用时执行。函数调用中提供的实际参数用于实例化函数声明中的形式参数。数组通过引用传递，其他变量通过值传递。

由于函数最初不是AWK语言的一部分，局部变量的规定相当笨拙：它们被声明为参数列表中的额外参数。惯例是通过在参数列表中添加额外空格来分隔局部变量和实际参数。例如：

```awk
function f(p, q,     a, b)   # a和b是局部变量
{
    ...
}

/abc/     { ... ; f(1, 2) ; ... }
```

函数调用中的左括号必须紧跟在函数名称之后，中间不能有任何空格。这避免了与连接运算符的语法歧义。此限制不适用于上面列出的内置函数。

函数可以相互调用，也可以递归调用。用作局部变量的函数参数在函数调用时初始化为空字符串和数字零。

使用`return expr`从函数返回值。如果未提供值，或者函数通过"掉出"末尾返回，则返回值未定义。

作为gawk扩展，函数可以间接调用。为此，将要调用的函数名称（作为字符串）分配给变量。然后使用该变量，就好像它是函数名称一样，并在其前面加上@符号，如下所示：

```awk
function myfunc()
{
    print "myfunc called"
    ...
}

{    ...
    the_func = "myfunc"
    @the_func()    # 通过the_func调用myfunc
    ...
}
```

从版本4.1.2开始，这适用于用户定义函数、内置函数和扩展函数。

### 7.13 函数检查与动态加载

#### 函数检查

如果提供了`--lint`选项，gawk会在解析时而不是运行时警告对未定义函数的调用。在运行时调用未定义函数是一个致命错误。

关键字`func`可以用来代替`function`，尽管这种用法已被弃用。

#### 动态加载新函数

您可以使用`@load`语句动态地将用C或C++编写的新函数添加到正在运行的gawk解释器中。完整的详细信息超出了本文档的范围；请参阅GAWK: Effective AWK Programming。

### 7.14 信号处理

Gawk分析器接受两个信号：

- **SIGUSR1**：导致它将分析和函数调用堆栈转储到分析文件中，该文件是awkprof.out或通过`--profile`选项指定的任何文件。然后它继续运行。
- **SIGHUP**：导致gawk转储分析和函数调用堆栈，然后退出。

### 7.15 国际化

字符串常量是用双引号括起来的字符序列。在非英语环境中，可以将AWK程序中的字符串标记为需要翻译为本地自然语言。这样的字符串在AWK程序中用前导下划线（"_"）标记。例如：

```bash
gawk 'BEGIN { print "hello, world" }'
```

始终打印"hello, world"。但是：

```bash
gawk 'BEGIN { print _"hello, world" }'
```

在法国可能会打印"bonjour, monde"。

生产和运行可本地化的AWK程序涉及几个步骤：

1. 添加BEGIN操作来为TEXTDOMAIN变量赋值，以将文本域设置为与您的程序关联的名称：

```awk
BEGIN { TEXTDOMAIN = "myprog" }
```

这允许gawk找到与您的程序关联的.gmo文件。如果没有此步骤，gawk将使用messages文本域，该文本域可能不包含您程序的翻译。

2. 用前导下划线标记所有应该翻译的字符串。

3. 如果需要，在程序中适当地使用dcgettext()和/或bindtextdomain()函数。

4. 运行`gawk --gen-pot -f myprog.awk > myprog.pot`为您的程序生成.pot文件。

5. 提供适当的翻译，并构建和安装相应的.gmo文件。

### 7.16 POSIX兼容性

Gawk的主要目标是与POSIX标准以及Brian Kernighan最新版本的awk兼容。为此，gawk包含以下用户可见的功能，这些功能在AWK书中没有描述，但属于Brian Kernighan版本的awk，并且在POSIX标准中：

- 书中指出命令行变量赋值发生在awk否则会打开参数作为文件时，这是在BEGIN规则执行之后。但是，在早期实现中，当这样的赋值出现在任何文件名之前时，赋值会在BEGIN规则运行之前发生。应用程序依赖于这个"特性"。当awk被更改为与其文档匹配时，添加了`-v`选项用于在程序执行前赋值变量，以适应依赖于旧行为的应用程序。

- 在处理参数时，gawk使用特殊选项"--"来表示参数的结束。在兼容模式下，它会警告但忽略未定义的选项。在正常操作中，这些参数会传递给AWK程序进行处理。

- AWK书没有定义srand()的返回值。POSIX标准规定它返回它正在使用的种子，以允许跟踪随机数序列。因此，gawk中的srand()也返回其当前种子。

- 其他功能包括：使用多个-f选项（来自MKS awk）；ENVIRON数组；\a和\v转义序列（最初在gawk中完成并反馈回Bell Laboratories版本）；tolower()和toupper()内置函数（来自Bell Laboratories版本）；以及printf中的ISO C转换规范（首先在Bell Laboratories版本中完成）。

### 7.17 历史特性

gawk支持历史AWK实现的一个特性：可以不仅不带参数调用length()内置函数，甚至可以不带括号！因此：

```awk
a = length     # Holy Algol 60, Batman!
```

与以下任一相同：

```awk
a = length()
a = length($0)
```

使用此功能是不良做法，如果在命令行上指定了`--lint`，gawk会发出关于其使用的警告。

### 7.18 GNU扩展

Gawk有太多的扩展超出了POSIX awk。以下是gawk的一些特性，它们在POSIX awk中不可用：

- 对于通过-f选项命名的文件，不会执行路径搜索。因此，AWKPATH环境变量不是特殊的。

- 没有进行文件包含的工具（gawk的@include机制）。

- 没有动态添加用C编写的新函数的工具（gawk的@load机制）。

- \x转义序列。

- 在?和:之后继续行的能力。

- AWK程序中的八进制和十六进制常量。

- ARGIND、BINMODE、ERRNO、LINT、PREC、ROUNDMODE、RT和TEXTDOMAIN变量不是特殊的。

- IGNORECASE变量及其副作用不可用。

- FIELDWIDTHS变量和固定宽度字段分割。

- FPAT变量和基于字段值的字段分割。

- FUNCTAB、SYMTAB和PROCINFO数组不可用。

- 将RS用作正则表达式的能力。

- I/O重定向中可用的特殊文件名不被识别。

- 用于创建协处理的|&运算符。

- BEGINFILE和ENDFILE特殊模式不可用。

- 使用空字符串作为FS的值和split()的第三个参数来分割单个字符的能力。

- split()的可选第四个参数，用于接收分隔符文本。

- close()函数的可选第二个参数。

- match()函数的可选第三个参数。

- 在printf和sprintf()中使用位置说明符的能力。

- 将数组传递给length()的能力。

- and()、asort()、asorti()、bindtextdomain()、compl()、dcgettext()、dcngettext()、gensub()、lshift()、mktime()、or()、patsplit()、rshift()、strftime()、strtonum()、systime()和xor()函数。

- 可本地化字符串。

- 非致命I/O。

- 可重试I/O。

AWK书没有定义close()函数的返回值。当关闭输出文件或管道时，gawk的close()返回fclose(3)或pclose(3)的值，分别。当关闭输入管道时，它返回进程的退出状态。如果命名的文件、管道或协处理没有通过重定向打开，则返回值为-1。

当使用--traditional选项调用gawk时，如果-F选项的fs参数是"t"，那么FS被设置为制表符。请注意，键入gawk -F\t ... 只会导致shell引用"t"，而不会将"\t"传递给-F选项。由于这是一个相当难看的特殊情况，因此它不是默认行为。如果指定了--posix，这种行为也不会发生。要真正获得制表符作为字段分隔符，最好使用单引号：gawk -F'\t' ...。

### 7.19 环境变量

AWKPATH环境变量可用于提供gawk在查找通过-f、--file、-i和--include选项以及@include指令命名的文件时搜索的目录列表。如果初始搜索失败，则在将.awk附加到文件名后再次搜索路径。

### 7.20 退出状态

如果使用值调用exit语句，则gawk以给定的数值退出。

否则，如果执行过程中没有问题，gawk以C常量EXIT_SUCCESS的值退出。这通常为零。

如果发生错误，gawk以C常量EXIT_FAILURE的值退出。这通常为1。

如果gawk由于致命错误而退出，退出状态为2。在非POSIX系统上，此值可能映射到EXIT_FAILURE。

### 7.21 版本信息

本手册页记录的是gawk，版本5.1。

### 7.22 作者

原始版本的UNIX awk由Bell Laboratories的Alfred Aho、Peter Weinberger和Brian Kernighan设计和实现。Brian Kernighan继续维护和增强它。

自由软件基金会的Paul Rubin和Jay Fenlason编写了gawk，使其与第七版UNIX中分发的原始awk版本兼容。John Woods贡献了许多错误修复。David Trueman在Arnold Robbins的贡献下，使gawk与新版本的UNIX awk兼容。Arnold Robbins是当前的维护者。

有关对gawk及其文档的完整贡献者列表，请参阅GAWK: Effective AWK Programming。

有关维护者和当前支持的端口的最新信息，请参阅gawk发行版中的README文件。

### 7.23 Bug报告

如果您在gawk中发现bug，请发送电子邮件至bug-gawk@gnu.org。请包括您的操作系统及其修订版本、gawk的版本（来自gawk --version）、用于编译它的C编译器，以及尽可能小的测试程序和数据来重现问题。

发送bug报告之前，请执行以下操作。首先，验证您是否拥有最新版本的gawk。每个版本都会修复许多bug（通常是微妙的bug），如果您的版本过时，问题可能已经解决。其次，请查看将环境变量LC_ALL设置为LC_ALL=C是否会导致行为符合您的预期。如果是这样，这是一个区域设置问题，可能是也可能不是真正的bug。最后，请仔细阅读本手册页和参考手册，确保您认为的bug确实是bug，而不仅仅是语言中的怪癖。

无论您做什么，都不要在comp.lang.awk中发布bug报告。虽然gawk开发人员偶尔会阅读这个新闻组，但在那里发布bug报告是一种不可靠的报告bug的方式。同样，不要使用网络论坛（如Stack Overflow）来报告bug。相反，请使用上面给出的电子邮件地址。真的。

如果您使用基于GNU/Linux或BSD的系统，您可能希望向您的发行版供应商提交bug报告。这很好，但也请发送一份副本到官方电子邮件地址，因为不能保证bug报告会转发给gawk维护者。

### 7.24 已知问题

鉴于命令行变量赋值功能，-F选项不是必需的；它仅保留用于向后兼容性。

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

**问题**：在shell中使用awk时，引号和特殊字符可能会导致问题，特别是转义字符如制表符`\t`。

**解决方案**：
- 使用单引号包围awk程序
- 对于需要在程序中使用单引号的情况，可以使用转义或变量
- 在awk程序内部，使用双引号包围转义字符

```bash
# 正确处理单引号
awk '\''{ print "It\'s a test" }'\'' file.txt

# 或者使用变量
awk -v quote="'" '{ print "It" quote "s a test" }' file.txt

# 正确处理制表符
awk '{print $1"\t"$3}' file.txt
```

**关于转义字符和字符串的特殊说明**：

在awk中，无论是转义字符还是普通字符串，都必须使用双引号括起来才能被正确处理。这是因为：

1. **awk的字符串处理规则**：
   - 双引号内的字符串会被awk解释转义序列和作为字符串常量
   - 无引号或单引号内的转义字符会被视为普通字符
   - 无引号的普通文本会被awk解释为变量名而非字符串常量

2. **制表符示例**：
   ```bash
   # 错误示例：直接在awk程序中使用\t（无引号包围）
   awk '{print $1\t$3}' file.txt
   # 错误信息：反斜杠不是行的最后一个字符，syntax error
   
   # 正确示例：使用双引号包围\t
   awk '{print $1"\t"$3}' file.txt
   # 正确输出：用制表符分隔的字段
   ```

3. **字符串常量示例**：
   ```bash
   # 错误示例：不使用双引号括起字符串
   awk '{print hello awk}' awk.txt
   # 错误：hello和awk被解释为变量名，而这些变量未定义，结果为空
   
   # 正确示例：使用双引号括起字符串
   awk '{print "hello world"}' awk.txt
   # 正确输出：hello world（每行都打印）
   ```

**总结**：在awk的print语句中，无论是特殊字符（如\t、\n）还是普通字符串，都必须使用双引号括起来。无引号的文本会被awk解释为变量引用，而不是字符串常量，这可能导致意外的行为或错误。

**原因分析**：

- 当在awk程序中直接使用`\t`（无引号包围）时，awk会将其视为两个独立的字符：反斜杠`\`和字母`t`
- 只有当转义序列位于双引号内时，awk才会将`\t`解释为一个制表符字符
- 这与许多编程语言中的字符串处理规则一致

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

## 10. 常见问题与注意事项

### 10.1 awk中的引号使用规则

在使用awk命令时，引号的选择对命令的正确执行至关重要。下面通过实际案例详细解释awk中引号的正确使用方法。

**问题现象**：

```bash
# 错误示例1：使用双引号
$ awk "{print $1, $3}" awk.txt 
awk: 命令行:1: {print , }
awk: 命令行:1:        ^ syntax error
awk: 命令行:1: {print , }
awk: 命令行:1:          ^ syntax error

# 错误示例2：不使用引号
$ awk {print $1, $3} awk.txt 
awk: 命令行:1: {print
awk: 命令行:1:       ^ 未预期的新行或字符串结束

# 正确示例：使用单引号
$ awk '{print $1, $3}' awk.txt 
nihao awk2
nihao awk5
nihao awk8
```

**原因分析**：

1. **shell解析与变量替换**：
   - 在shell中，双引号内的`$`符号会被解释为shell变量引用，而不是awk的字段引用
   - 当使用`"{print $1, $3}"`时，shell会尝试将`$1`和`$3`作为shell变量展开，通常它们是空值
   - 这导致实际传递给awk的命令变成了`{print , }`，这是一个语法错误

2. **无引号的问题**：
   - 不使用引号时，shell会将`{print`视为一个独立的命令，而不是awk程序的一部分
   - 这导致shell解析失败，报出"未预期的新行或字符串结束"错误

3. **单引号的优势**：
   - 单引号内的所有内容（包括`$`符号）都会被shell原样传递给awk
   - 当使用`'{print $1, $3}'`时，awk正确接收到`$1`和`$3`作为字段引用

**其他引号使用场景**：

1. **需要引用shell变量的情况**：
   - 当需要在awk程序中使用shell变量时，可以在单引号中嵌入双引号或打破单引号
   ```bash
   # 方法1：打破单引号嵌入shell变量
   threshold=80
   awk 'NR > 1 && $2 > '"$threshold"' { print }' data.csv
   
   # 方法2：使用-v选项传递变量
   awk -v threshold="$threshold" 'NR > 1 && $2 > threshold { print }' data.csv
   ```

2. **包含单引号的awk程序**：
   - 当awk程序本身需要使用单引号时，可以使用转义或字符串拼接
   ```bash
   # 使用转义
   awk '{ print "It\'s a test" }' input.txt
   
   # 使用字符串拼接
   awk '{ print "It""'"'"""s a test" }' input.txt
   ```

**最佳实践**：

1. **默认使用单引号**：编写awk程序时，默认使用单引号括起整个程序
2. **避免双引号**：除非确实需要在awk程序中引用shell变量，否则不要使用双引号
3. **使用-v选项**：当需要将shell变量传递给awk时，优先使用`-v`选项
4. **程序文件**：对于复杂的awk程序，建议将其保存到文件中，然后使用`-f`选项调用

通过正确理解和使用引号规则，可以避免在使用awk命令时遇到的常见语法错误，确保命令能够按照预期工作。

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

## 13. 另请参阅

- egrep(1), sed(1), getpid(2), getppid(2), getpgrp(2), getuid(2), geteuid(2), getgid(2), getegid(2), getgroups(2), printf(3), strftime(3), usleep(3)

- 《The AWK Programming Language》，Alfred V. Aho、Brian W. Kernighan、Peter J. Weinberger 著，Addison-Wesley出版社，1988年。ISBN 0-201-07981-X。

- 《GAWK: Effective AWK Programming》第5.1版，随gawk源代码一起分发。本文档的当前版本可在网上查阅：[https://www.gnu.org/software/gawk/manual](https://www.gnu.org/software/gawk/manual)。

- GNU gettext 文档，可在网上查阅：[https://www.gnu.org/software/gettext](https://www.gnu.org/software/gettext)。

## 14. 示例

**打印并排序所有用户的登录名：**

```bash
BEGIN     { FS = ":" }
     { print $1 | "sort" }
```

**统计文件行数：**

```bash
     { nlines++ }
END  { print nlines }
```

**在每行前加上其在文件中的行号：**

```bash
# 使用NR变量打印全局行号
awk '{print NR, $0}' awk.txt
# 输出示例：
# 1 nihao awk1 awk2 awk3
# 2 nihao awk4 awk5 awk6
# 3 nihao awk7 awk8 awk9

# 使用FNR变量打印每个文件的行号（多文件处理时有用）
awk '{print FNR, $0}' awk.txt
```

**限定行号打印特定内容：**

```bash
# 打印第1行的第1个和第3个字段
awk 'NR==1{print $1,$3}' awk.txt
# 输出示例：nihao awk2

# 打印第2行的行号和前两个字段（注意行号和$1之间没有空格）
awk 'NR==2{print NR $1,$2}' awk.txt
# 输出示例：2nihao awk4

# 打印第3行的行号和前两个字段
awk 'NR==3{print NR,$1,$2}' awk.txt
# 输出示例：3 nihao awk7
```

**使用-F和-v FS选项指定分隔符：**

```bash
# 默认使用空格分隔，整个行作为$1
awk '{print $1}' passwd.txt  # passwd.txt内容: root:x:0:0:root:/root:/bin/bash
# 输出示例：root:x:0:0:root:/root:/bin/bash

# 使用-F选项设置冒号为分隔符
awk -F: '{print $2}' passwd.txt
# 输出示例：x

# -F选项后可以有空格
awk -F : '{print $2}' passwd.txt
# 输出示例：x

# -F选项可以使用引号包围分隔符
awk -F ":" '{print $2}' passwd.txt
# 输出示例：x

# 使用-v FS选项设置字段分隔符（更灵活的方式）
awk -v FS=":" '{print $1,$7}' passwd.txt
# 输出示例：root /bin/bash

# 在输出中使用分隔符变量
awk -v FS=":" '{print $1 FS $7}' passwd.txt
# 输出示例：root:/bin/bash

# 字段连接（无分隔符）
awk -v FS=":" '{print $1 $7}' passwd.txt
# 输出示例：root/bin/bash
```

**注意：-F和-v FS选项混用的优先级**

```bash
# 当同时使用-F和-v FS选项时，-F选项的优先级更高
awk -v FS="/" -F ":" '{print $1,$2}' passwd.txt
# 输出示例：root x （使用了冒号作为分隔符）

# 单独使用-v FS选项
awk -v FS="/" '{print $1,$2}' passwd.txt
# 输出示例：root:x:0:0:root: root: （使用了斜杠作为分隔符）
```

当需要明确指定分隔符时，建议只使用一种方法，避免混用导致的混淆。如果需要在程序中动态修改分隔符，可以使用-v FS选项。

**FS和OFS设置的注意事项及示例：**

```bash
# 使用-v选项设置OFS（输出字段分隔符）
awk -F ":" -v OFS="~~" '{print $1,$7}' passwd.txt
# 输出示例：root~~/bin/bash

# 在BEGIN块中设置OFS和FS（注意：OFS值需要加引号）
awk -F ':' 'BEGIN{OFS="~~~";FS=":"}{print $1,$3,$7}' passwd.txt
# 输出示例：root~~~0~~~/bin/bash

# 错误示例：OFS值没有加引号会导致语法错误
# awk -F ':' 'BEGIN{OFS=~~~;FS=":"}{print $1,$3,$7}' passwd.txt
# 错误：syntax error

# 错误示例：Begin不是大写会导致设置无效
awk -F: 'Begin{OFS=",";FS=":"}{print $1,$3,$7}' passwd.txt
# 输出示例：root 0 /bin/bash （OFS设置无效，使用默认空格）

# 正确示例：BEGIN必须大写
awk -F: 'BEGIN{OFS=",";FS=":"}{print $1,$3,$7}' passwd.txt
# 输出示例：root,0,/bin/bash

# 可以只设置OFS，使用-F设置的FS
awk -F: 'BEGIN{OFS=","}{print $1,$3,$7}' passwd.txt
# 输出示例：root,0,/bin/bash

# 在BEGIN块中同时设置FS和OFS，不使用-F选项
awk 'BEGIN{OFS=",";FS=":"}{print $1,$3,$7}' passwd.txt
# 输出示例：root,0,/bin/bash

# 重要提示：FS必须是源文件中存在的字符，否则无法正确分割
# 下面示例使用空格作为分隔符，但passwd.txt实际使用冒号分隔
awk 'BEGIN{OFS=",";FS=" "}{print $1,$3,$7}' passwd.txt
# 输出示例：root:x:0:0:root:/root:/bin/bash,, （只识别到第一个字段）
```

**注意事项：**
1. FS必须是源文件中实际存在的字符，否则无法正确分割字段
2. BEGIN必须使用大写形式，否则会被视为普通模式而非特殊块
3. -F选项后面可以跟双引号、单引号或无引号的分隔符
4. 在BEGIN块中设置OFS时，值必须用引号括起来

**提取URL中的域名信息并统计：**

```bash
# 假设domain.txt文件包含URL列表
cat domain.txt
# 输出示例：
# http://www.example.org/index.html
# http://www.example.org/1.html
# http://api.example.org/index.html
# http://upload.example.org/index.html
# http://img.example.org/3.html
# http://search.example.org/2.html

# 使用正则表达式作为分隔符提取域名（/+表示一个或多个斜杠）
awk -F "/+" '{print $2}' domain.txt
# 输出示例：
# www.example.org
# www.example.org
# api.example.org
# upload.example.org
# img.example.org
# search.example.org

# 使用单个斜杠作为分隔符（需要使用$3获取域名）
awk -F "/" '{print $3}' domain.txt
# 输出示例同上

# 统计域名出现次数（结合awk和uniq）
awk -F "/" '{print $3}' domain.txt | uniq -c
# 输出示例：
# 2 www.example.org
# 1 api.example.org
# 1 upload.example.org
# 1 img.example.org
# 1 search.example.org

# 使用字符类正则表达式作为分隔符并添加行号
# 在这个表达式中：
# 1. [] 是字符类，表示匹配括号内的任意一个字符
# 2. / 是要匹配的字符（斜杠）
# 3. + 是量词，表示匹配前面的字符一个或多个
# 所以 [/]+ 表示匹配一个或多个连续的斜杠
# 直接使用 "/+" 也可以，因为 / 不是正则表达式中的特殊字符，不需要转义
awk -F "[/]+" '{print NR,$2}' domain.txt
# 输出示例：
# 1 www.example.org
# 2 www.example.org
# 3 api.example.org
# 4 upload.example.org
# 5 img.example.org
# 6 search.example.org
```

这个示例展示了如何使用正则表达式作为分隔符从URL中提取域名，并结合其他命令进行统计分析。

**提取/etc/fstab中的UUID挂载信息：**

```bash
# 首先使用grep过滤出包含UUID的行，然后用awk提取UUID和文件系统类型
grep "^UUID" /etc/fstab | awk '{print $1, $3}'
# 输出示例：UUID=4e0fed15-9f25-41c0-8a61-fd528964dd3f xfs

# 提取所有挂载点及其文件系统类型
awk '!/^#/ && $0 {print $2, $3}' /etc/fstab
# 输出示例：/	xfs
#          /boot	xfs
#          /home	xfs
#          none	swap

# 格式化输出fstab关键信息，使用制表符分隔
awk '!/^#/ && $0 {printf "挂载点: %-20s 文件系统: %-10s 选项: %s\n", $2, $3, $4}' /etc/fstab
```

这个示例展示了如何结合grep和awk命令高效地处理系统配置文件，提取关键信息进行分析或报告。

```bash
{ print FNR, $0 }
```

**连接文件并添加行号（一个变体）：**

```bash
{ print NR, $0 }
```

**为特定数据行运行外部命令：**

```bash
tail -f access_log |
awk '/myhome.html/ { system("nmap " $1 ">> logdir/myhome.html") }'
```

## 15. 致谢

Brian Kernighan在测试和调试过程中提供了宝贵的帮助。我们向他表示感谢。

## 16. 复制许可

版权所有 © 1989, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004, 2005, 2007, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020，自由软件基金会。

允许制作和分发本手册页的逐字副本，前提是保留版权声明和本许可声明的所有副本。

允许在逐字复制的条件下复制和分发本手册页的修改版本，前提是整个衍生作品在与本声明相同的许可声明下分发。

允许将本手册页翻译成另一种语言进行复制和分发，条件同上，但本许可声明可以使用基金会批准的翻译版本。