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

### 6.4 记录和字段

#### 6.4.1 记录

记录（Record）通常由换行符分隔。你可以通过设置内置变量`RS`来控制记录的分隔方式：

- 如果`RS`是单个字符，则该字符作为记录分隔符
- 如果`RS`是正则表达式，则匹配该正则表达式的文本作为记录分隔符
- 如果`RS`设置为空字符串，则记录由空行分隔
- 当`RS`为空字符串时，换行符始终作为字段分隔符，无论`FS`的值是什么

在兼容模式下，`RS`值的字符串中只有第一个字符用于分隔记录。

#### 6.4.2 字段

当读取每条输入记录时，gawk会使用`FS`变量的值作为字段分隔符将记录分割成字段：

- 如果`FS`是单个字符，则该字符作为字段分隔符
- 如果`FS`是空字符串，则每个字符单独成为一个字段
- 否则，`FS`被视为完整的正则表达式
- 特殊情况：如果`FS`是单个空格，则字段由连续的空格、制表符或换行符分隔

**注意：** `IGNORECASE`变量的值也会影响当`FS`为正则表达式时字段的分割方式，以及当`RS`为正则表达式时记录的分隔方式。

除了`FS`外，gawk还提供了两种其他方式来定义字段：

1. **FIELDWIDTHS变量**：设置为以空格分隔的数字列表，每个字段具有固定宽度。每个字段宽度前可选择性地加上冒号分隔的值，指定字段开始前要跳过的字符数。

2. **FPAT变量**：设置为表示正则表达式的字符串，每个字段由匹配该正则表达式的文本组成。在这种情况下，正则表达式描述的是字段本身，而不是分隔字段的文本。

#### 6.4.3 字段操作

输入记录中的每个字段可以通过其位置引用：`$1`、`$2`等。`$0`表示整个记录，包括前导和尾随空白。

- 字段引用不必使用常量：`n = 5; print $n`打印输入记录中的第五个字段
- `NF`变量设置为输入记录中的字段总数
- 引用不存在的字段（即`$NF`之后的字段）会产生空字符串
- 对不存在的字段赋值（例如`$(NF+2) = 5`）会增加`NF`的值，创建任何中间字段（值为空字符串），并导致`$0`的值被重新计算，字段之间用`OFS`的值分隔
- 引用负编号的字段会导致致命错误
- 减少`NF`会导致超过新值的字段值丢失，`$0`的值被重新计算，字段之间用`OFS`的值分隔
- 对现有字段赋值会导致在引用`$0`时重建整个记录
- 对`$0`赋值会导致记录被重新分割，为字段创建新值

### 6.5 内置变量

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
| `PROCINFO` | 此数组的元素提供对运行中的AWK程序信息的访问。主要元素包括：PROCINFO["argv"]（命令行参数）、PROCINFO["pid"]（进程ID）、PROCINFO["uid"]（用户ID）、PROCINFO["gid"]（组ID）、PROCINFO["platform"]（平台信息）、PROCINFO["version"]（gawk版本）、PROCINFO["sorted_in"]（数组排序控制）等 |
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
}'
```
#### 6.5.1 ARGC、ARGV变量详解与NR工作原理

##### 6.5.1.1 ARGC和ARGV变量的作用

`ARGC`和`ARGV`是awk中用于访问命令行参数的内置变量：

- **ARGC**：命令行参数的数量（不包括awk的选项或程序源代码）
- **ARGV**：命令行参数的数组，索引从0开始，`ARGV[0]`通常是awk命令本身，后续元素是处理的文件名或其他参数

##### 6.5.1.2 实际使用示例分析

让我们通过实际案例来理解这些变量的工作原理：

```bash
# 创建测试文件
cat > awk.txt << 'EOF'
nihao awk1 awk2 awk3 
nihao awk4 awk5 awk6 
nihao awk7 awk8 awk9 
EOF

# 测试NR==0的情况（不会执行）
awk 'NR==0{print ARGV[0],ARGV[1]}' awk.txt

# 测试NR==2的情况（第2行执行）
awk 'NR==2{print ARGV[0],ARGV[1]}' awk.txt
# 输出: awk awk.txt

# 测试NR==3的情况（第3行执行）
awk 'NR==3{print ARGV[0],ARGV[1]}' awk.txt
# 输出: awk awk.txt

# 测试NR==4的情况（空行，不会执行）
awk 'NR==4{print ARGV[0],ARGV[1]}' awk.txt

# 查看ARGC的值
awk 'NR==1{print ARGC}' awk.txt
# 输出: 2
```

##### 6.5.1.3 NR变量的工作原理

为什么`NR==0`不会执行，而`NR==1`、`NR==2`、`NR==3`可以正常工作？这涉及到awk的执行机制：

1. **NR的初始值**：`NR`（Number of Records）变量在awk开始处理输入文件之前初始值为0，但只有在真正读取记录后才会递增

2. **执行流程**：
   - awk首先执行`BEGIN`块（如果有），此时`NR`为0
   - 然后开始读取输入文件的记录，每读取一条记录，`NR`就递增1
   - 接着执行主程序块（没有BEGIN/END的部分），此时`NR`至少为1
   - 最后执行`END`块（如果有）

3. **NR==0不工作的原因**：
   - 主程序块中的模式`NR==0`永远不会匹配，因为主程序块只在读取记录后执行，而此时`NR`已经至少为1
   - 如果想在`NR`为0时执行代码，必须将代码放在`BEGIN`块中

4. **测试验证**：
   ```bash
   # 在BEGIN块中访问NR值
   awk 'BEGIN{print "NR in BEGIN:", NR}' awk.txt
   # 输出: NR in BEGIN: 0
   ```

##### 6.5.1.4 ARGC和ARGV的深入理解

1. **参数组成**：
   - `ARGV[0]`：awk命令本身
   - `ARGV[1]`、`ARGV[2]`...：命令行上指定的输入文件或其他参数
   - `ARGC`：参数的总数量

2. **动态修改**：
   - 可以在`BEGIN`块中动态修改`ARGV`数组，从而控制awk处理哪些文件
   - 例如，可以根据条件跳过某些文件的处理

3. **示例应用**：
   ```bash
   # 动态控制处理的文件
   awk 'BEGIN {
       # 显示所有参数
       for (i=0; i<ARGC; i++) {
           print "ARGV["i"] = "ARGV[i]
       }
       
       # 动态移除某个文件
       if (ARGC > 2) {
           delete ARGV[2]
       }
   }' file1.txt file2.txt file3.txt
   ```

##### 6.5.1.5总结

- `ARGC`和`ARGV`提供了访问和控制命令行参数的能力，使awk程序可以根据参数动态调整行为
- `NR`变量在处理输入记录时从1开始计数，因此主程序块中的`NR==0`条件永远不会为真
- 理解这些变量的工作原理有助于编写更灵活、更强大的awk脚本



```sh
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

### 6.6 自定义变量

```bash
# 直接在程序中定义变量
awk 'BEGIN { count=0 } { count++ } END { print "Total lines:", count }' awk_test.txt

# 使用-v参数在命令行定义变量
awk -v threshold=85 '$2 > threshold { print $1 " scored above threshold" }' awk_test.txt
```

#### 6.6.1 awk自定义变量的使用规则

在awk中使用自定义变量时，需要遵循一些重要规则，特别是关于字符串值和变量引用的处理：

##### 字符串变量必须使用引号

```bash
# 正确：字符串值使用双引号
awk 'BEGIN{name="soveran";print name}'
# 输出: soveran

# 错误：字符串值未使用引号（会被当作未定义变量）
awk 'BEGIN{name=soveran;print name}'
# 输出: (空)
```

##### 变量引用不需要$符号

在awk中，直接使用变量名访问变量值，不需要像访问字段那样使用$符号：

```bash
# 正确：直接使用变量名
awk 'BEGIN{name="soveran";print name}'
# 输出: soveran

# 错误：使用$引用变量（$name会被解释为字段引用）
awk 'BEGIN{name="soveran";print $name}'
# 输出: (空)
```

##### 使用-v选项传递变量

使用`-v`选项可以在命令行中定义变量，这种方式定义的变量在BEGIN块和主程序块中都可用：

```bash
# 在命令行使用-v定义变量
awk -v "name=soveran" 'BEGIN{print name}'
# 输出: soveran

# 主程序块中也可使用
awk -v "name=soveran" '{print name}' input.txt
# 每行都会输出: soveran
```

**定义多个变量的正确方法**：

`-v`选项**每次只能定义一个变量**。如果需要定义多个变量，必须为每个变量单独使用一个`-v`选项：

```bash
# 正确：使用多个-v选项定义多个变量
awk -v "name=soveran" -v "address=shanghai" 'BEGIN{print name,address}'
# 输出: soveran shanghai

# 错误：尝试在一个-v选项中使用分号分隔多个变量
awk -v "name=soveran;address=shanghai" 'BEGIN{print name,address}'
# 输出: soveran;address=shanghai  (整个字符串被当作一个变量值)

# 错误：没有为第二个变量使用-v选项
awk -v "name=soveran" "address=shanghai" 'BEGIN{print name,address}'
# 错误: cannot open file `BEGIN{print name,address}' for reading
```

这种设计是因为awk将`-v`选项后面的参数视为单一的变量定义，不会解析分号等分隔符。每个`-v`选项都是一个独立的变量定义单元。

**在BEGIN块中定义多个变量**：

与命令行的`-v`选项不同，在awk程序的BEGIN块中，你可以使用分号分隔多个变量的定义：

```bash
# 在BEGIN块中使用分号定义多个变量
awk 'BEGIN{name="soveran";address="shanghai";print name, address;}'
# 输出: soveran shanghai
```

这种方式在awk程序内部是有效的，因为awk解释器会正确解析BEGIN块中的分号分隔符，将其视为不同语句的结束。这提供了一种在程序内部定义多个变量的简洁方法，而无需使用多个`-v`选项。

**命令区域（主程序块）执行需要输入数据**：

与BEGIN块不同，awk的命令区域（主程序块，用`{}`括起但不属于BEGIN或END的部分）只有在有输入数据时才会执行。如果没有提供输入数据，主程序块中的代码将不会被执行：

```bash
# 没有输入数据，主程序块不会执行
awk '{i=10;print i++,i}'
# 没有输出

# 提供输入数据后，主程序块会执行
# echo提供一行空输入
 echo | awk '{i=10;print i++,i}'
# 输出: 10 11
```

**前缀递增/递减与后缀递增/递减的区别**：

awk支持前缀和后缀形式的递增/递减操作，它们的行为与大多数编程语言相同：

```bash
# 后缀递增：先使用变量值，再递增
 echo | awk '{i=10;print i++,i}'
# 输出: 10 11

# 前缀递增：先递增变量值，再使用
 echo | awk '{i=10;print ++i,i}'
# 输出: 11 11

# 后缀递减：先使用变量值，再递减
 echo | awk '{i=10;print i--,i}'
# 输出: 10 9

# 前缀递减：先递减变量值，再使用
 echo | awk '{i=10;print --i,i}'
# 输出: 9 9
```

**BEGIN块中直接执行的优势**：

BEGIN块不需要输入数据就可以执行，适合进行初始化和计算操作：

```bash
# BEGIN块不需要输入即可执行
awk 'BEGIN{i=0;print i++,i}'
# 输出: 0 1

awk 'BEGIN{i=0;print ++i,i}'
# 输出: 1 1
```

而END块通常用于在处理完所有输入数据后显示总结信息，一般不执行复杂的计算操作。

**条件表达式与递增操作结合使用的执行过程**：

awk的条件表达式如果为真（非零、非空字符串），会自动打印当前记录（$0）。结合后缀递增操作，可以实现选择性打印：

```bash
# 首先查看awk.txt文件内容
cat awk.txt
# 输出:
# nihao awk1 awk2 awk3
# nihao awk4 awk5 awk6
# nihao awk7 awk8 awk9
```

**示例1：使用`n++`作为条件表达式**

```bash
awk -v n=0 'n++' awk.txt
# 输出:
# nihao awk4 awk5 awk6
# nihao awk7 awk8 awk9
```

**执行过程分析**：
1. 使用`-v n=0`定义变量n并初始化为0
2. 对于每一行输入记录，执行条件表达式`n++`
3. 处理第一行时：
   - 先判断条件表达式`n`的值（0）→ 0被视为假
   - 由于条件为假，不打印第一行
   - 然后执行递增操作，n变为1
4. 处理第二行时：
   - 判断条件表达式`n`的值（1）→ 非零被视为真
   - 由于条件为真，自动打印第二行
   - 然后执行递增操作，n变为2
5. 处理第三行时：
   - 判断条件表达式`n`的值（2）→ 非零被视为真
   - 由于条件为真，自动打印第三行
   - 然后执行递增操作，n变为3

**示例2：使用`!n++`作为条件表达式**

```bash
awk -v n=0 '!n++' awk.txt
# 输出:
# nihao awk1 awk2 awk3
```

**执行过程分析**：
1. 使用`-v n=0`定义变量n并初始化为0
2. 对于每一行输入记录，执行条件表达式`!n++`
3. 处理第一行时：
   - 先判断条件表达式`!n`的值（!0 = 1，即真）→ 条件为真
   - 由于条件为真，自动打印第一行
   - 然后执行递增操作，n变为1
4. 处理第二行时：
   - 判断条件表达式`!n`的值（!1 = 0，即假）→ 条件为假
   - 由于条件为假，不打印第二行
   - 然后执行递增操作，n变为2
5. 处理第三行时：
   - 判断条件表达式`!n`的值（!2 = 0，即假）→ 条件为假
   - 由于条件为假，不打印第三行
   - 然后执行递增操作，n变为3

**核心原理总结**：
- awk条件表达式中，0和空字符串被视为假，其他值被视为真
- 后缀递增操作（n++）是先使用变量的当前值，然后再递增
- 这种模式常用于跳过前N行或只打印前N行数据
- `n++`条件会跳过前1行（初始值为0时），然后打印后续所有行
- `!n++`条件会只打印前1行，然后跳过后续所有行
- 可以通过改变n的初始值来控制跳过或打印的行数

##### 变量作用域说明

1. **使用-v选项定义的变量**：在整个awk程序中都可见（包括BEGIN块、主程序块和END块）
2. **在BEGIN块中定义的变量**：在后续的主程序块和END块中都可见
3. **在主程序块中定义的变量**：在当前记录处理和后续记录处理中可见，也在END块中可见

##### 变量类型自动转换

awk中的变量类型会根据上下文自动转换：

```bash
# 数值到字符串的转换
awk 'BEGIN{num=123; print "The number is " num}'
# 输出: The number is 123

# 字符串到数值的转换（如果可能）
awk 'BEGIN{str="456"; print str + 100}'
# 输出: 556
```

##### 使用$的正确场景

$符号在awk中有特殊含义，主要用于：

1. **访问字段**：`$1`, `$2`, `$NF`等
2. **通过变量间接访问字段**：`$i`（当i是数值变量时）

```bash
# 使用变量间接访问字段
awk 'BEGIN{i=2} {print $(i)}' input.txt
# 输出每行的第2个字段
```

##### 最佳实践总结

1. **字符串值必须用引号括起来**（单引号或双引号都可，但双引号内可解析转义字符）
2. **直接使用变量名访问变量值**，不要添加$符号
3. **对于需要在BEGIN块中使用的外部变量**，使用-v选项传递
4. **在awk程序中定义的变量**，确保在使用前已经赋值
5. **避免变量名与awk关键字或内置函数名冲突**

##### awk数组的使用

awk支持关联数组（也称为映射或字典），这是awk中一种强大的数据结构，可以使用数字或字符串作为索引。

###### 数组的基本定义和访问

```bash
# 在BEGIN块中定义和访问数组
awk 'BEGIN{array[0]=100;print array[0]}'
# 输出: 100

# 使用字符串作为索引
awk 'BEGIN{array["name"]="soveran";print array["name"]}'
# 输出: soveran
```

###### 数组的初始化和赋值

```bash
# 初始化多个数组元素
awk 'BEGIN{
    array[0]=100;
    array[1]=200;
    array["two"]=300;
    array["three"]=400;
    # 访问并打印数组元素
    print array[0], array[1], array["two"], array["three"];
}'
# 输出: 100 200 300 400
```

###### 数组的遍历

```bash
# 遍历数组中的所有元素
awk 'BEGIN{
    array["name"]="soveran";
    array["age"]=30;
    array["city"]="shanghai";
    # 使用for循环遍历
    for(i in array){
        print i ": " array[i];
    }
}'
# 输出类似:
# name: soveran
# age: 30
# city: shanghai
# (注意：遍历顺序可能因awk实现而异)
```

###### 数组的实际应用示例

```bash
# 统计字段出现的次数
echo -e "apple\norange\napple\nbanana\napple" | awk '{count[$1]++} END {for(fruit in count) print fruit ": " count[fruit]}'"
# 输出:
# apple: 3
# orange: 1
# banana: 1

# 存储唯一值
echo -e "a\nb\na\nc\nb" | awk '{seen[$1]=1} END {for(item in seen) print item}'
# 输出:
# a
# b
# c
```

###### 数组的删除操作

```bash
# 删除数组元素
awk 'BEGIN{
    array["a"]=1;
    array["b"]=2;
    delete array["a"];  # 删除特定元素
    print "a:" array["a"], "b:" array["b"];  # 删除的元素值为空
}'
# 输出: a: b: 2

# 删除整个数组
awk 'BEGIN{
    array["a"]=1;
    array["b"]=2;
    delete array;  # 删除整个数组
    print "a:" array["a"], "b:" array["b"];  # 所有元素都为空
}'
# 输出: a: b: 
```

#### 6.6.2 awk定制格式化输出

awk提供了强大的格式化输出功能，可以通过`print`和`printf`命令结合自定义变量来实现灵活的输出格式。

##### 使用print命令的基本格式化

`print`命令是awk中最基本的输出命令，它会在参数之间自动插入输出字段分隔符（OFS，默认为空格），并在最后添加输出记录分隔符（ORS，默认为换行符）。

```bash
# 基本用法：输出字段和自定义变量
awk -F: '{age=36;address="shanghai"; print $1,age,address}' passwd.txt
# 输出类似: root 36 shanghai

# 修改OFS改变字段分隔符
awk -F: 'BEGIN{OFS=":"} {age=36;address="shanghai"; print $1,age,address}' passwd.txt
# 输出类似: root:36:shanghai

# 组合字符串和变量
awk -F: '{age=36;address="shanghai"; print "User:", $1, "is", age, "years old, from", address}' passwd.txt
# 输出类似: User: root is 36 years old, from shanghai
```

##### 使用printf命令进行精确格式化

`printf`命令提供了更精确的格式化控制，类似于C语言中的printf函数。它不会自动添加换行符，需要显式指定。

```bash
# 基本格式化输出
awk -F: '{age=36;address="shanghai"; printf "%-10s %3d %s\n", $1, age, address}' passwd.txt
# 输出类似: root         36 shanghai

# 更复杂的格式化
awk -F: '{age=36;address="shanghai"; printf "User %s is %d years old and lives in %s\n", $1, age, address}' passwd.txt
# 输出类似: User root is 36 years old and lives in shanghai

# 表格形式输出
awk -F: 'BEGIN {printf "%-15s %-8s %-20s\n", "USERNAME", "AGE", "ADDRESS"; printf "------------------------------------------\n"} {age=36;address="shanghai"; printf "%-15s %-8d %-20s\n", $1, age, address}' passwd.txt
# 输出格式化表格
```

##### 常用的printf格式说明符

| 格式说明符 | 描述 |
|------------|------|
| %s | 字符串 |
| %d, %i | 十进制整数 |
| %f | 浮点数 |
| %e, %E | 科学记数法 |
| %g, %G | 自动选择%f或%e的紧凑格式 |
| %x, %X | 十六进制整数 |
| %o | 八进制整数 |
| %% | 字面值百分号 |

##### 格式化修饰符

- **宽度修饰符**：`%10s`表示字符串占10个字符宽度
- **左对齐**：`%-10s`表示左对齐，占10个字符宽度
- **精度修饰符**：`%.2f`表示浮点数保留2位小数
- **零填充**：`%05d`表示整数占5位，不足部分用0填充

```bash
# 使用修饰符的示例
awk 'BEGIN {printf "%10s | %-10s | %05d | %.2f\n", "right", "left", 123, 45.6789}'
# 输出:      right | left       | 00123 | 45.68
```

##### 结合条件语句的格式化输出

可以根据条件动态改变输出格式：

```bash
# 根据字段值改变格式
awk -F: '{age=36;address="shanghai"; if ($3 < 1000) {printf "[SYSTEM] %s\n", $1} else {printf "[USER] %s\n", $1}}' passwd.txt

# 交替行格式
awk -F: '{age=36;address="shanghai"; if (NR % 2 == 0) {printf "%s\t%s\t%s\n", $1, age, address} else {printf "%s|%s|%s\n", $1, age, address}}' passwd.txt
```

##### 自定义标题和页脚

结合BEGIN和END块添加格式化的标题和汇总信息：

```bash
# 添加标题和统计信息
awk -F: 'BEGIN {printf "%-15s %-8s %-20s\n", "USERNAME", "AGE", "ADDRESS"; printf "------------------------------------------\n"} {age=36;address="shanghai"; printf "%-15s %-8d %-20s\n", $1, age, address; count++} END {printf "------------------------------------------\n"; printf "Total users: %d\n", count}' passwd.txt
```

##### 颜色输出（在支持的终端中）

可以使用ANSI转义序列添加颜色：

```bash
# 彩色输出示例
awk -F: 'BEGIN {printf "\033[1;34m%-15s %-8s %-20s\033[0m\n", "USERNAME", "AGE", "ADDRESS"} {age=36;address="shanghai"; if (NR % 2 == 0) {printf "\033[32m%-15s %-8d %-20s\033[0m\n", $1, age, address} else {printf "%-15s %-8d %-20s\n", $1, age, address}}' passwd.txt
```

##### 最佳实践

1. **简单输出使用print**：对于简单的字段分隔输出，使用print更简洁
2. **复杂格式使用printf**：需要精确控制格式时，使用printf
3. **设置OFS**：对于print命令，可以通过设置OFS改变默认分隔符
4. **记得换行符**：使用printf时，别忘记添加`\n`换行符
5. **结合变量**：灵活使用自定义变量来构建动态输出内容
6. **测试格式**：复杂格式输出前，先用小样本测试确保格式正确
7. **考虑可读性**：在处理大量数据时，使用清晰的格式分隔符和对齐方式提高可读性

### 6.7 数学函数

```bash
# 使用数学函数
awk 'BEGIN { print "Square root of 25:", sqrt(25) }'
awk 'BEGIN { print "Sine of 90 degrees:", sin(3.14159/2) }'
awk 'BEGIN { print "Random number:", rand() }'

# 计算平均值
awk '{ sum += $2 } END { print "Average:", sum/NR }' awk_test.txt
```

### 6.8 字符串函数

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

## 7. 数组

### 7.1 数组基本操作

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

### 7.2 数组应用示例

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

## 8. 控制结构

### 8.1 正则表达式模式匹配控制

传统UNIX awk使用标准的正则表达式匹配。GNU操作符不被视为特殊字符，并且区间表达式不可用。由八进制和十六进制转义序列描述的字符被视为字面量，即使它们表示正则表达式元字符。

```bash
# 使用--re-interval选项启用区间表达式
awk --re-interval '/[0-9]{2,3}/' file.txt
```

**--re-interval**

允许在正则表达式中使用区间表达式，即使已提供了--traditional选项。

### 8.2 运算符

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

### 8.3 控制语句

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

### 8.4 I/O语句

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

### 8.5 if-else语句示例

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

### 8.6 循环结构

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

### 8.7 switch语句

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

### 8.8 数学函数

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

### 8.9 字符串函数

GNU awk提供了以下内置字符串函数：

### 8.10 时间函数

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

### 8.11 位操作函数

Gawk提供以下位操作函数。它们的工作方式是将双精度浮点值转换为uintmax_t整数，执行操作，然后将结果转换回浮点数。

**注意：** 向这些函数传递负数会导致致命错误。

- **and(v1, v2 [, ...])**: 返回参数列表中提供的值的按位与。至少需要两个参数。

- **compl(val)**: 返回val的按位取反。

- **lshift(val, count)**: 返回val左移count位后的值。

- **or(v1, v2 [, ...])**: 返回参数列表中提供的值的按位或。至少需要两个参数。

- **rshift(val, count)**: 返回val右移count位后的值。

- **xor(v1, v2 [, ...])**: 返回参数列表中提供的值的按位异或。至少需要两个参数。

### 8.12 类型函数

以下函数提供有关其参数的类型相关信息：

- **isarray(x)**: 如果x是数组则返回true，否则返回false。此函数主要用于多维数组的元素和函数参数。

- **typeof(x)**: 返回一个字符串，指示x的类型。字符串将是"array"、"number"、"regexp"、"string"、"strnum"、"unassigned"或"undefined"之一。

### 8.13 国际化函数

以下函数可用于在AWK程序中在运行时翻译字符串：

- **bindtextdomain(directory [, domain])**: 指定gawk查找.gmo文件的目录，以防它们不会或不能放在"标准"位置（例如，在测试期间）。它返回domain被"绑定"的目录。
  默认域是TEXTDOMAIN的值。如果directory是空字符串("")，则bindtextdomain()返回给定域的当前绑定。

- **dcgettext(string [, domain [, category]])**: 返回文本域domain中字符串string的翻译，用于locale类别category。domain的默认值是TEXTDOMAIN的当前值。category的默认值是"LC_MESSAGES"。
  如果您提供category的值，它必须是一个字符串，等于GAWK: Effective AWK Programming中描述的已知locale类别之一。您还必须提供一个文本域。如果要使用当前域，请使用TEXTDOMAIN。

- **dcngettext(string1, string2, number [, domain [, category]])**: 返回文本域domain中字符串string1和string2翻译的复数形式，用于locale类别category，对应于数字number。domain的默认值是TEXTDOMAIN的当前值。category的默认值是"LC_MESSAGES"。
  如果您提供category的值，它必须是一个字符串，等于GAWK: Effective AWK Programming中描述的已知locale类别之一。您还必须提供一个文本域。如果要使用当前域，请使用TEXTDOMAIN。

### 8.14 用户定义函数

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

### 8.15 函数检查与动态加载

#### 函数检查

如果提供了`--lint`选项，gawk会在解析时而不是运行时警告对未定义函数的调用。在运行时调用未定义函数是一个致命错误。

关键字`func`可以用来代替`function`，尽管这种用法已被弃用。

#### 动态加载新函数

您可以使用`@load`语句动态地将用C或C++编写的新函数添加到正在运行的gawk解释器中。完整的详细信息超出了本文档的范围；请参阅GAWK: Effective AWK Programming。

### 8.16 信号处理

Gawk分析器接受两个信号：

- **SIGUSR1**：导致它将分析和函数调用堆栈转储到分析文件中，该文件是awkprof.out或通过`--profile`选项指定的任何文件。然后它继续运行。
- **SIGHUP**：导致gawk转储分析和函数调用堆栈，然后退出。

### 8.17 国际化

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

### 8.18 POSIX兼容性

Gawk的主要目标是与POSIX标准以及Brian Kernighan最新版本的awk兼容。为此，gawk包含以下用户可见的功能，这些功能在AWK书中没有描述，但属于Brian Kernighan版本的awk，并且在POSIX标准中：

- 书中指出命令行变量赋值发生在awk否则会打开参数作为文件时，这是在BEGIN规则执行之后。但是，在早期实现中，当这样的赋值出现在任何文件名之前时，赋值会在BEGIN规则运行之前发生。应用程序依赖于这个"特性"。当awk被更改为与其文档匹配时，添加了`-v`选项用于在程序执行前赋值变量，以适应依赖于旧行为的应用程序。

- 在处理参数时，gawk使用特殊选项"--"来表示参数的结束。在兼容模式下，它会警告但忽略未定义的选项。在正常操作中，这些参数会传递给AWK程序进行处理。

- AWK书没有定义srand()的返回值。POSIX标准规定它返回它正在使用的种子，以允许跟踪随机数序列。因此，gawk中的srand()也返回其当前种子。

- 其他功能包括：使用多个-f选项（来自MKS awk）；ENVIRON数组；\a和\v转义序列（最初在gawk中完成并反馈回Bell Laboratories版本）；tolower()和toupper()内置函数（来自Bell Laboratories版本）；以及printf中的ISO C转换规范（首先在Bell Laboratories版本中完成）。

### 8.19 历史特性

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

### 8.19 GNU扩展

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

### 8.20 环境变量

AWKPATH环境变量可用于提供gawk在查找通过-f、--file、-i和--include选项以及@include指令命名的文件时搜索的目录列表。如果初始搜索失败，则在将.awk附加到文件名后再次搜索路径。

### 7.21 退出状态

如果使用值调用exit语句，则gawk以给定的数值退出。

否则，如果执行过程中没有问题，gawk以C常量EXIT_SUCCESS的值退出。这通常为零。

如果发生错误，gawk以C常量EXIT_FAILURE的值退出。这通常为1。

如果gawk由于致命错误而退出，退出状态为2。在非POSIX系统上，此值可能映射到EXIT_FAILURE。

### 8.22 版本信息

本手册页记录的是gawk，版本5.1。

### 8.23 作者

原始版本的UNIX awk由Bell Laboratories的Alfred Aho、Peter Weinberger和Brian Kernighan设计和实现。Brian Kernighan继续维护和增强它。

自由软件基金会的Paul Rubin和Jay Fenlason编写了gawk，使其与第七版UNIX中分发的原始awk版本兼容。John Woods贡献了许多错误修复。David Trueman在Arnold Robbins的贡献下，使gawk与新版本的UNIX awk兼容。Arnold Robbins是当前的维护者。

有关对gawk及其文档的完整贡献者列表，请参阅GAWK: Effective AWK Programming。

有关维护者和当前支持的端口的最新信息，请参阅gawk发行版中的README文件。

### 8.24 Bug报告

如果您在gawk中发现bug，请发送电子邮件至bug-gawk@gnu.org。请包括您的操作系统及其修订版本、gawk的版本（来自gawk --version）、用于编译它的C编译器，以及尽可能小的测试程序和数据来重现问题。

发送bug报告之前，请执行以下操作。首先，验证您是否拥有最新版本的gawk。每个版本都会修复许多bug（通常是微妙的bug），如果您的版本过时，问题可能已经解决。其次，请查看将环境变量LC_ALL设置为LC_ALL=C是否会导致行为符合您的预期。如果是这样，这是一个区域设置问题，可能是也可能不是真正的bug。最后，请仔细阅读本手册页和参考手册，确保您认为的bug确实是bug，而不仅仅是语言中的怪癖。

无论您做什么，都不要在comp.lang.awk中发布bug报告。虽然gawk开发人员偶尔会阅读这个新闻组，但在那里发布bug报告是一种不可靠的报告bug的方式。同样，不要使用网络论坛（如Stack Overflow）来报告bug。相反，请使用上面给出的电子邮件地址。真的。

如果您使用基于GNU/Linux或BSD的系统，您可能希望向您的发行版供应商提交bug报告。这很好，但也请发送一份副本到官方电子邮件地址，因为不能保证bug报告会转发给gawk维护者。

### 8.25 已知问题

鉴于命令行变量赋值功能，-F选项不是必需的；它仅保留用于向后兼容性。

## 9. 实用示例

### 9.1 处理CSV文件

```bash
# 打印CSV文件中特定列
awk -F, '{ print $1, "lives in", $3, "and earns", $4 }' data.csv

# 过滤CSV文件中符合条件的行
awk -F, '$4 > 100000 { print $1, "has a high salary" }' data.csv

# 计算CSV文件中数值列的总和
awk -F, 'NR>1 { sum += $4 } END { print "Total salary:", sum }' data.csv
```

### 9.2 日志文件分析

```bash
# 提取日志中的错误信息
awk '/ERROR/ { print }' app.log

# 统计每种日志级别的出现次数
awk '{ level[$3]++ } END { for (l in level) print l ":" level[l] }' app.log

# 提取特定时间段的日志
awk '$1 " " $2 >= "2024-02-01 11:00:00" && $1 " " $2 <= "2024-02-01 15:00:00" { print }' app.log
```

### 9.3 文本转换

```bash
# 将空格分隔的文件转换为CSV格式
awk 'BEGIN { OFS="," } { print $1, $2, $3, $4 }' awk_test.txt

# 格式化输出（对齐列）
awk '{ printf "%-10s %5d %5d %5d\n", $1, $2, $3, $4 }' awk_test.txt

# 将文本转换为大写
awk '{ print toupper($0) }' awk_test.txt
```

### 9.4 数据统计

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

## 10. 高级技巧

### 10.1 使用awk脚本文件

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

### 10.2 多文件处理

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

### 10.3 与其他命令结合使用

```bash
# 与sort命令结合
awk '{ print $2, $1 }' awk_test.txt | sort -nr

# 与grep命令结合
ps aux | grep awk | awk '{ print $1, $2, $11 }'

# 读取find命令的输出
find /etc -name "*.conf" -type f -size +1k | xargs ls -lh | awk '{ print $5, $9 }'
```

### 10.4 自定义函数

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

## 11. 常见陷阱与解决方案

### 11.1 字段分隔符问题

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

### 11.2 引号和转义问题

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

### 11.3 性能优化

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

## 12. 常见问题与注意事项

### 12.1 awk中的引号使用规则

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
   #方法1：打破单引号嵌入shell变量
   threshold=80
   awk 'NR > 1 && $2 > '"$threshold"' { print }' data.csv
   
   #方法2：使用-v选项传递变量
   awk -v threshold="$threshold" 'NR > 1 && $2 > threshold { print }' data.csv
   ```

2. **包含单引号的awk程序**：
   - 当awk程序本身需要使用单引号时，可以使用转义或字符串拼接
   
   ```bash
   #使用转义
   awk '{ print "It\'s a test" }' input.txt
   
   #使用字符串拼接
   awk '{ print "It""'"'"""s a test" }' input.txt
   ```

**最佳实践**：

1. **默认使用单引号**：编写awk程序时，默认使用单引号括起整个程序
2. **避免双引号**：除非确实需要在awk程序中引用shell变量，否则不要使用双引号
3. **使用-v选项**：当需要将shell变量传递给awk时，优先使用`-v`选项
4. **程序文件**：对于复杂的awk程序，建议将其保存到文件中，然后使用`-f`选项调用

通过正确理解和使用引号规则，可以避免在使用awk命令时遇到的常见语法错误，确保命令能够按照预期工作。

## 13. 总结

`awk`是一个功能强大的文本处理工具，它结合了命令行工具的便捷性和编程语言的灵活性。掌握`awk`命令的关键在于：

1. 理解其工作原理（逐行处理和字段分割）
2. 熟练掌握模式匹配和操作语法
3. 灵活运用变量、数组和控制结构
4. 学习各种内置函数和自定义函数的使用
5. 掌握与其他命令的组合使用技巧

通过本文介绍的各种技巧和示例，您应该能够在日常工作中充分利用`awk`命令，提高文本处理和数据分析的效率。无论是日志分析、数据转换还是统计计算，`awk`都能成为您得力的助手。

## 14. 参考链接

- [GNU awk 官方文档](https://www.gnu.org/software/gawk/manual/)
- [Linux man 手册 awk(1)](https://man7.org/linux/man-pages/man1/awk.1p.html)
- [awk 编程语言](https://ia802309.us.archive.org/25/items/pdfy-MgN0H1joIoDVoIC7/The_AWK_Programming_Language.pdf)

> 您可以参考我们的[Linux文本处理工具精通指南](https://soveranzhong.github.io/2024/01/20/linux-text-processing-tools.html)获取更多Linux文本处理工具的详细介绍。

## 15. 另请参阅

- egrep(1), sed(1), getpid(2), getppid(2), getpgrp(2), getuid(2), geteuid(2), getgid(2), getegid(2), getgroups(2), printf(3), strftime(3), usleep(3)

- 《The AWK Programming Language》，Alfred V. Aho、Brian W. Kernighan、Peter J. Weinberger 著，Addison-Wesley出版社，1988年。ISBN 0-201-07981-X。

- 《GAWK: Effective AWK Programming》第5.1版，随gawk源代码一起分发。本文档的当前版本可在网上查阅：[https://www.gnu.org/software/gawk/manual](https://www.gnu.org/software/gawk/manual)。

- GNU gettext 文档，可在网上查阅：[https://www.gnu.org/software/gettext](https://www.gnu.org/software/gettext)。

## 16. 示例

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

**RS（记录分隔符）的作用及示例：**

```bash
# 生成1到7的序列，每个数字占一行
seq 7
# 输出示例：
# 1
# 2
# 3
# 4
# 5
# 6
# 7

# 设置RS为空字符串，将所有行作为一个记录处理
seq 7 | awk 'BEGIN{RS=""}{print $1,$2,$3,$4,$5,$6,$7}'
# 输出示例：1 2 3 4 5 6 7
```

**RS的工作原理：**
- RS是awk中的记录分隔符变量，默认值是换行符（\n）
- 当RS设置为空字符串（""）时，awk会将连续的空行作为记录分隔符
- 在没有空行的输入中（如seq命令的输出），所有行将被合并成一个记录
- 此时，原有的每行内容会被视为该记录中的一个字段（由默认的FS分隔符分隔）
- 这就解释了为什么垂直排列的数字会变成水平排列 - 它们从多个记录变成了一个记录中的多个字段

**应用场景：**
- 处理段落格式的文本（每个段落由空行分隔）
- 需要将多行内容合并为一行进行处理
- 对文本块而非单行进行操作

**OFS（输出字段分隔符）用法及列范围访问行为：**

```bash
# 创建测试文件awk.txt
cat awk.txt
# 输出示例：
# nihao awk1 awk2 awk3 
# nihao awk4 awk5 awk6 
# nihao awk7 awk8 awk9 

# 使用-F":"（冒号作为输入分隔符，但文件中没有冒号），OFS="|"（管道作为输出分隔符）
# 打印行号和整行内容
awk -F ":" -v OFS="|" '{print NR,$0}' awk.txt
# 输出：
# 1|nihao awk1 awk2 awk3 
# 2|nihao awk4 awk5 awk6 
# 3|nihao awk7 awk8 awk9 

# 打印行号和$1（由于没有冒号，整行被视为$1）
awk -F ":" -v OFS="|" '{print NR,$1}' awk.txt
# 输出与上面相同，因为$1就是整行内容

# 打印行号和$2（由于没有冒号分隔，$2为空）
awk -F ":" -v OFS="|" '{print NR,$2}' awk.txt
# 输出：
# 1| 
# 2| 
# 3| 
```

**重要原理解释：**

1. **关于超出列范围的访问行为**：
   - 当awk找不到指定的字段（如$2、$3等）时，会返回空字符串
   - 在上面的例子中，由于设置了`-F":"`但文件中没有冒号，每行都被视为一个整体字段$1
   - 因此访问$2、$3等字段时会返回空值
   - 行号NR总是正确显示的，而空字段会输出OFS分隔符和空内容

2. **正确指定分隔符的情况**：

```bash
# 使用空格作为分隔符（默认也是空格）
awk -F " " -v OFS="|" '{print NR,$1,$2,$3,$4}' awk.txt
# 输出：
# 1|nihao|awk1|awk2|awk3 
# 2|nihao|awk4|awk5|awk6 
# 3|nihao|awk7|awk8|awk9 
```

**OFS的用法总结：**

1. **使用-v选项设置OFS**：
   - 通过`-v OFS="分隔符"`可以在命令行中直接设置输出字段分隔符
   - 这比在BEGIN块中设置更灵活，特别是在需要从命令行参数获取分隔符时

2. **OFS的作用时机**：
   - OFS只在使用print命令输出多个字段时生效
   - 当打印$0（整行）时，OFS不会影响原始输入的格式
   - 只有在明确打印多个字段（如$1,$2,$3）时，OFS才会被用作字段间的分隔符

3. **OFS与FS的关系**：
   - FS（输入字段分隔符）决定如何分割输入行
   - OFS（输出字段分隔符）决定如何连接输出字段
   - 这两个设置是独立的，可以设置为不同的值

4. **特殊情况处理**：
   - 当FS设置的分隔符在输入中不存在时，整行被视为一个字段
   - 访问不存在的字段（如超出范围的$N）会返回空字符串
   - 打印空字符串时，OFS仍然会被正确插入

**printf格式化输出详解：**

printf命令提供了更精确的输出格式化控制，比print命令更灵活。以下是各种格式化选项的示例和说明：

```bash
# 使用printf打印单个字段（字符串格式）
awk '{printf "%s\n",$1}' awk.txt
# 输出：
# nihao 
# nihao 
# nihao 

# 打印第二个字段（字符串格式）
awk '{printf "%s\n",$2}' awk.txt
# 输出：
# awk1 
# awk4 
# awk7 

# 注意：printf需要明确指定格式说明符和转义序列
# 下面的例子只有一个格式说明符%s，但提供了两个参数$1和$2
# 此时只有第一个参数$1被使用
awk '{printf "%s\n",$1,$2}' awk.txt
# 输出与第一个例子相同，只有$1被打印
```

**printf格式说明符与多个参数：**

```bash
# 使用两个格式说明符打印两个字段
awk '{printf "%s\n%s",$1,$2}' awk.txt
# 输出：
# nihao 
# awk1nihao 
# awk4nihao 
# （注意：没有最后一个换行符）

# 在一个格式字符串中组合多个字段，使用连字符连接
awk '{printf "%s-%s\n",$1,$2}' awk.txt
# 输出：
# nihao-awk1 
# nihao-awk4 
# nihao-awk7 

# 添加行号NR（整数格式）
awk '{printf "%d-%s-%s\n",NR,$1,$2}' awk.txt
# 输出：
# 1-nihao-awk1 
# 2-nihao-awk4 
# 3-nihao-awk7 
```

**数值格式化选项：**

```bash
# 使用浮点数格式打印行号
awk '{printf "%f-%s-%s\n",NR,$1,$2}' awk.txt
# 输出：
# 1.000000-nihao-awk1 
# 2.000000-nihao-awk4 
# 3.000000-nihao-awk7 

# 控制浮点数精度（4位宽度，2位小数）
awk '{printf "%4.2f-%s-%s\n",NR,$1,$2}' awk.txt
# 输出：
# 1.00-nihao-awk1 
# 2.00-nihao-awk4 
# 3.00-nihao-awk7 

# 使用左对齐格式（8个字符宽度，左对齐）
awk '{printf "%-8s%s\n",NR,$1}' awk.txt
# 输出：
# 1       nihao 
# 2       nihao 
# 3       nihao 
```

**printf格式化输出总结：**

1. **格式说明符的作用**：
   - `%s` - 字符串格式
   - `%d` - 十进制整数格式
   - `%f` - 浮点数格式，可以指定精度如`%4.2f`
   - 格式说明符的数量必须与参数数量匹配，或参数数量是格式说明符数量的整数倍

2. **宽度和对齐控制**：
   - 正数宽度（如`%8s`）- 右对齐，不足部分左侧补空格
   - 负数宽度（如`%-8s`）- 左对齐，不足部分右侧补空格
   - 数值宽度可以与精度结合（如`%4.2f`）- 总宽度4位，其中小数2位

3. **与print的主要区别**：
   - printf不会自动添加换行符，需要显式使用`\n`
   - printf需要显式指定格式说明符
   - printf提供更精确的输出控制，适合需要严格格式的场景

4. **常见转义序列**：
   - `\n` - 换行符
   - `\t` - 制表符
   - `\\` - 反斜杠本身
   - `\"` - 双引号

**print命令与文本标签结合使用：**

print命令可以轻松地将文本标签与字段值结合输出，使结果更具可读性。以下是几个实用示例：

```bash
# 在字段前添加文本标签（英文标签）
awk '{print "first coloum",$1,"second coloum", $2}' awk.txt
# 输出：
# first coloum nihao second coloum awk1 
# first coloum nihao second coloum awk4 
# first coloum nihao second coloum awk7 

# 在标签后添加冒号增强可读性
awk '{print "first coloum:",$1,"second coloum:", $2}' awk.txt
# 输出：
# first coloum: nihao second coloum: awk1 
# first coloum: nihao second coloum: awk4 
# first coloum: nihao second coloum: awk7 

# 使用中文标签并结合END块显示统计信息
awk '{print "第一列:",$1,"第二列:", $2}END{printf "-----------\n行数总计:%2d\n",NR}' awk.txt
# 输出：
# 第一列: nihao 第二列: awk1 
# 第一列: nihao 第二列: awk4 
# 第一列: nihao 第二列: awk7 
# ----------- 
# 行数总计: 3 
```

**print命令与文本标签结合使用总结：**

1. **基本语法**：print命令可以直接将文本字符串与字段值混合输出，字符串需要用引号包围
2. **标签格式化技巧**：可以在标签后添加冒号、空格等符号增强可读性
3. **与控制结构结合**：可以在BEGIN或END块中结合print或printf命令显示统计信息
4. **与printf配合使用**：在需要格式化输出统计信息时，printf比print提供更精确的控制

**printf多参数格式化输出的错误案例与正确用法：**

当在printf中使用多个参数和格式说明符时，需要确保格式字符串和参数的正确匹配。以下是一个常见错误案例及其分析：

```bash
# 错误示例：格式字符串和参数不匹配
awk '{print "第一列:",$1,"第二列:", $2}END{printf "-----------\n行数总计:%2d\n","\n列数总计:"%2d,NF}' awk.txt
# 输出（只有行数信息，没有列数信息）：
# 第一列: nihao 第二列: awk1 
# 第一列: nihao 第二列: awk4 
# 第一列: nihao 第二列: awk7 
# ----------- 
# 行数总计: 3 
```

**错误原因分析：**
- 格式字符串被错误地分割成了多个部分：`"-----------\n行数总计:%2d\n"` 和 `"\n列数总计:"%2d`
- 格式说明符和参数的数量及顺序不匹配
- 字符串和格式说明符的拼接方式不正确

**正确用法示例：**

```bash
# 正确示例1：在一个格式字符串中包含所有格式说明符
awk '{print "第一列:",$1,"第二列:", $2}END{printf "-----------\n行数总计:%2d\n列数总计:%2d\n",NR,NF}' awk.txt
# 输出：
# 第一列: nihao 第二列: awk1 
# 第一列: nihao 第二列: awk4 
# 第一列: nihao 第二列: awk7 
# ----------- 
# 行数总计: 3 
# 列数总计: 2 

# 正确示例2：使用多个printf语句分别格式化输出
awk '{print "第一列:",$1,"第二列:", $2}END{printf "-----------\n"; printf "行数总计:%2d\n",NR; printf "列数总计:%2d\n",NF}' awk.txt
# 输出：
# 第一列: nihao 第二列: awk1 
# 第一列: nihao 第二列: awk4 
# 第一列: nihao 第二列: awk7 
# ----------- 
# 行数总计: 3 
# 列数总计: 2 

# 正确示例3：在数据处理块中计算每行的列数，并在END块中显示
awk '{print "第一列:",$1,"第二列:", $2; max_nf=(NF>max_nf)?NF:max_nf}END{printf "-----------\n行数总计:%2d\n最大列数:%2d\n",NR,max_nf}' awk.txt
# 输出：
# 第一列: nihao 第二列: awk1 
# 第一列: nihao 第二列: awk4 
# 第一列: nihao 第二列: awk7 
# ----------- 
# 行数总计: 3 
# 最大列数: 2 
```

**多参数格式化输出注意事项：**

1. **格式字符串完整性**：所有格式说明符必须包含在同一个格式字符串中
2. **参数数量匹配**：格式说明符的数量必须与后续提供的参数数量匹配
3. **参数顺序对应**：参数的顺序必须与格式说明符的顺序一一对应
4. **字符串连接**：在格式字符串内部可以使用转义序列和普通字符进行连接，而不是在格式字符串外部
5. **多行输出**：可以使用`\n`在格式字符串中创建换行，或使用多个printf语句实现复杂的格式化输出

**NR变量在不同阶段的值与print/printf处理差异：**

NR（Number of Record）变量在awk命令执行的不同阶段具有不同的值，同时print和printf命令处理格式字符串的方式也有明显差异。以下是详细说明和示例：

```bash
# 示例1：NR变量在BEGIN块、命令块和END块中的值
# 以及print与printf处理格式字符串的差异
awk -F: 'BEGIN{printf "BEGIN中的NR值:%2d\n",NR}NR==11{print "命令中的NR值:%2d\n",NR}END{printf "END中的NR值:%2d\n",NR}' /etc/passwd
# 输出：
# BEGIN中的NR值: 0  # BEGIN块中NR为0
# 命令中的NR值:%2d   # print命令直接打印格式字符串
#  11               # print命令单独打印NR的值
# END中的NR值:50    # END块中NR为总记录数

# 示例2：使用printf正确格式化输出NR值
awk -F: 'BEGIN{printf "BEGIN中的NR值:%2d\n",NR}NR==11{printf "命令中的NR值:%2d\n",NR}END{printf "END中的NR值:%2d\n",NR}' /etc/passwd
# 输出：
# BEGIN中的NR值: 0  # BEGIN块中NR为0
# 命令中的NR值:11   # printf正确解析格式说明符
# END中的NR值:50    # END块中NR为总记录数
```

**关键要点说明：**

1. **NR变量在不同阶段的值**：
   - **BEGIN块**：NR初始值为0（在处理任何输入行之前）
   - **命令块（main块）**：NR从1开始递增，每处理一行输入，NR增加1
   - **END块**：NR保持为处理的总行数（最终值）

2. **print与printf处理格式字符串的差异**：
   - **print命令**：不会解析格式说明符（如`%d`），而是直接将其作为普通文本输出
     它会将逗号分隔的参数用OFS（默认空格）连接后输出
   - **printf命令**：会正确解析格式说明符，并将对应的参数按照指定格式输出
     需要显式添加`\n`来实现换行

3. **awk命令执行的优先级顺序**：
   - **BEGIN块**：最先执行，且仅执行一次
   - **命令块（main块）**：对每一行输入执行一次
   - **END块**：最后执行，且仅执行一次

4. **格式字符串使用建议**：
   - 当需要格式化输出（如数字格式化、宽度控制等）时，必须使用printf命令
   - 当只需要简单输出内容时，可以使用更简洁的print命令
   - 在同一个程序中，可以根据需要灵活组合使用print和printf

5. **常见错误避免**：
   - 不要在print命令中使用格式说明符，它们会被当作普通文本
   - 确保printf命令的格式说明符数量与参数数量匹配
   - 记住在printf中显式添加换行符`\n`

**print与printf的详细对比及适用场景：**

print和printf命令各有特点，适用于不同的输出场景。以下是它们的详细对比和使用示例：

```bash
# 示例1：print自动添加换行符，printf需要显式添加
# 使用print命令（自动添加换行）
awk '{print $1"\t"$2}' awk.txt
# 输出（每行自动换行）：
# nihao   awk1
# nihao   awk4
# nihao   awk7

# 使用printf命令（需要显式添加换行符）
awk '{printf $1"\t"$2}' awk.txt
# 输出（所有内容在一行）：
# nihao   awk1nihao       awk4nihao       awk7

# 使用printf命令（显式添加换行符）
awk '{printf $1"\t"$2"\n"}' awk.txt
# 输出（每行换行，与print类似）：
# nihao   awk1
# nihao   awk4
# nihao   awk7
```

**关键区别与适用场景：**

1. **换行处理**：
   - **print命令**：自动在输出末尾添加换行符`\n`
   - **printf命令**：不会自动添加换行符，需要显式使用`\n`
   - **适用场景**：需要自动换行时使用print，需要精确控制换行位置时使用printf

2. **参数处理**：
   - **print命令**：使用逗号分隔参数时，会在参数之间插入OFS（默认空格）
   - **printf命令**：需要使用格式说明符或字符串连接来控制参数之间的分隔
   - **适用场景**：简单分隔输出用print，复杂格式化输出用printf

3. **格式化能力**：
   - **print命令**：格式化能力有限，主要依靠字符串连接和OFS
   - **printf命令**：提供强大的格式化控制（宽度、精度、对齐方式等）
   - **适用场景**：需要格式化数字、对齐文本等精确控制时使用printf

**表格格式化输出综合案例：**

以下是一个完整的表格格式化输出案例，展示如何使用awk的BEGIN块、主命令块和END块协同工作，创建格式化的表格输出：

```bash
# 使用awk格式化输出/etc/passwd文件的用户名和Shell类型，创建美观的表格
head /etc/passwd | awk -F":" 'BEGIN{printf "------------------------\n%-6s|%12s|\n","用户名","Shell 类型"}{printf "------------------------\n%-9s|%14s|\n",$1,$7}END{printf "总行数:%2d\n",NR}'
```

**输出结果：**
```
------------------------ 
用户名   |    Shell 类型|
------------------------ 
root     |     /bin/bash|
------------------------ 
bin      | /sbin/nologin|
------------------------ 
daemon   | /sbin/nologin|
------------------------ 
adm      | /sbin/nologin|
------------------------ 
lp       | /sbin/nologin|
------------------------ 
sync     |     /bin/sync|
------------------------ 
shutdown |/sbin/shutdown|
------------------------ 
halt     |    /sbin/halt|
------------------------ 
mail     | /sbin/nologin|
------------------------ 
operator | /sbin/nologin|
总行数:10 
```

**案例解析：**

1. **字段分隔符设置**：使用`-F":"`将字段分隔符设置为冒号，适配/etc/passwd文件格式

2. **BEGIN块表头定义**：
   - 输出表格顶部分隔线
   - 使用左对齐格式`%-6s`和`%12s`定义表头"用户名"和"Shell 类型"
   - 表头与数据列使用竖线`|`分隔，增强可读性

3. **主命令块数据格式化**：
   - 每行数据前输出分隔线
   - 使用`%-9s`（左对齐9字符宽度）格式化用户名
   - 使用`%14s`（右对齐14字符宽度）格式化Shell路径
   - 保持表格结构的一致性和美观性

4. **END块统计信息**：
   - 使用NR变量获取总行数
   - 输出简洁的统计信息"总行数:10"

5. **格式化技巧**：
   - 使用负号前缀（如`%-6s`）实现左对齐
   - 精确控制字段宽度确保表格对齐
   - 使用分隔线和边框字符增强表格可视化效果
   - 结合BEGIN/主命令/END块实现完整的表格结构

**课程成绩表格格式化案例：**

以下是一个处理课程成绩数据的表格格式化案例，展示了如何使用awk创建更复杂的表格布局：

**数据文件course_score.txt内容：**
```
张三 100 56 99 
李四 90 68 89 
王五 50 78 67 
赵六 80 99 89 
```

**awk命令与输出：**
```bash
# 使用awk格式化输出课程成绩表格
awk 'BEGIN{printf "-----------------------\n|%-3s|%2s|%2s|%2s|\n-----------------------\n","姓名","语文","数学","历史"}NR>=1{printf "|%-3s|%4d|%4d|%4d|\n",$1,$2,$3,$4}END{printf "----------------------\n学生 总数: %2d\n",NR}' course_score.txt
```

**输出结果：**
```
----------------------- 
|姓名 |语文|数学|历史| 
----------------------- 
|张三 | 100|  56|  99| 
|李四 |  90|  68|  89| 
|王五 |  50|  78|  67| 
|赵六 |  80|  99|  89| 
---------------------- 
学生 总数:  4 
```

**案例解析：**

1. **表格边框设计**：
   - 使用连字符`-`创建表格上下边框
   - 使用竖线`|`作为列分隔符，形成完整的表格单元格结构
   - 表头、数据行和表尾分隔线保持一致的视觉风格

2. **字段对齐与宽度控制**：
   - 姓名字段使用`%-3s`实现左对齐，宽度为3个字符
   - 表头中的科目名称使用`%2s`格式
   - 成绩数值使用`%4d`实现右对齐，确保数字对齐，宽度为4个字符

3. **条件处理**：
   - 使用`NR>=1`确保处理所有数据行
   - 表头和分隔线通过BEGIN块统一输出
   - END块中统计并显示学生总数

4. **表格结构完整性**：
   - 完整的表格包含：顶部边框、表头行、表头下边框、数据行、底部边框和统计信息
   - 每个单元格都有明确的边界，提升数据可读性
   - 统计信息单独成段，与表格主体区分开

这个案例展示了如何使用awk处理包含多行多列的结构化数据，并将其格式化为专业、易读的表格形式，特别适合课程成绩等教育数据的展示和分析。

**NF变量在路径处理中的实用技巧：**

NF（Number of Fields）变量不仅可以用于统计字段数量，还可以非常方便地处理文件路径，提取路径中的特定部分（如目录名或文件名）。以下是几个实用示例：

```bash
# 示例1：提取路径中的父目录名（倒数第二部分）
echo /etc/sysconfig/network-scripts/readme-ifcfg-rh.txt | awk -F / '{print $(NF-1)}'
# 输出：
# network-scripts

# 示例2：提取路径中的文件名（最后一部分）
echo /etc/sysconfig/network-scripts/readme-ifcfg-rh.txt | awk -F / '{print $NF}'
# 输出：
# readme-ifcfg-rh.txt

# 示例3：获取当前工作目录名称（不包含完整路径）
echo $PWD | awk -F "/" '{print $NF}'
# 输出示例：
# awk （假设当前在awk目录下）
```

**技术要点解析：**

1. **字段分隔符设置**：
   - 使用 `-F /` 将正斜杠设置为字段分隔符，这样路径字符串会被分割成多个字段
   - 每个目录层级和文件名都会成为独立的字段

2. **NF变量的动态引用**：
   - `$NF` 始终引用最后一个字段，即路径中的文件名或最内层目录名
   - `$(NF-1)` 引用倒数第二个字段，即父目录名
   - 可以根据需要调整索引，如 `$(NF-2)` 获取祖父目录名

3. **实际应用场景**：
   - **获取当前目录名**：在脚本中需要知道当前所在目录名称时非常有用
   - **提取文件名**：从完整路径中分离出文件名，便于进一步处理
   - **路径分析**：快速获取路径中的特定层级信息，无需使用basename或dirname等外部命令

4. **优势特点**：
   - **简洁高效**：一行命令即可完成路径解析，无需编写复杂逻辑
   - **跨平台兼容**：在不同的Unix/Linux系统上都能一致工作
   - **无需额外工具**：仅使用awk即可完成，不依赖其他命令行工具

这种方法在shell脚本编写、日志分析和文件管理任务中特别实用，可以帮助用户快速从路径字符串中提取所需信息，提高工作效率。

4. **表头和表尾处理**：
   - 通常在BEGIN块中用printf创建表头（可精确控制格式）
   - 在main块中根据需要使用print或printf输出数据行
   - 在END块中用printf创建表尾和统计信息

**awk语句分隔符使用规则：**

在awk中，语句分隔符的使用有特定规则，以下是详细说明：

```bash
# 示例2：分号和逗号作为分隔符的区别
# 使用分号分隔多个语句
awk 'BEGIN{printf "表头\n"; total=0}{print $1,$2; total++}END{printf "总行数:%d\n",total}' awk.txt
# 输出：
# 表头
# nihao awk1
# nihao awk4
# nihao awk7
# 总行数:3

# 使用逗号分隔print的参数（不是语句分隔符）
awk '{print "字段1:",$1,"字段2:",$2}' awk.txt
# 输出（逗号被OFS替换）：
# 字段1: nihao 字段2: awk1
# 字段1: nihao 字段2: awk4
# 字段1: nihao 字段2: awk7
```

**语句分隔符规则：**

1. **分号（;）**：
   - 用于分隔同一代码块中的多个语句
   - 在BEGIN、main和END块中，多条语句之间必须用分号分隔
   - 分号可以放在行尾，也可以在同一行分隔多个语句
   - 最后一条语句的分号通常可以省略，但添加分号是良好的编程习惯

2. **逗号（,）**：
   - 在print命令中，逗号用于分隔要输出的多个参数
   - 逗号在输出时会被替换为OFS（默认是空格）
   - 逗号不是语句分隔符，不能用于分隔不同的命令或语句

3. **花括号内的语句分隔**：
   - 同一花括号内的多个语句必须用分号分隔
   - 即使语句分布在不同行，分号仍然是必需的
   - 空语句（多余的分号）通常会被忽略，但应避免使用

**自定义变量vs内置变量NR：**

在awk中，可以使用自定义变量来跟踪计数或存储值，也可以直接使用内置变量NR。以下是它们的对比：

```bash
# 示例3：使用自定义变量total vs 直接使用NR
# 使用自定义变量total
awk 'BEGIN{total=0}{print $1,$2; total++}END{printf "总行数:%2d\n",total}' awk.txt
# 输出：
# nihao awk1
# nihao awk4
# nihao awk7
# 总行数: 3

# 直接使用NR
awk '{print $1,$2}END{printf "总行数:%2d\n",NR}' awk.txt
# 输出（结果相同）：
# nihao awk1
# nihao awk4
# nihao awk7
# 总行数: 3
```

**自定义变量与内置变量NR的对比：**

1. **功能对比**：
   - **NR**：awk内置变量，自动跟踪当前处理的记录（行）号
   - **自定义变量**：需要手动初始化和更新，但提供更大的灵活性

2. **适用场景**：
   - **使用NR的场景**：
     - 简单的行计数需求
     - 需要跟踪原始输入的行号
     - 代码简洁性要求高的场景
   - **使用自定义变量的场景**：
     - 需要特定的计数逻辑（如条件计数）
     - 需要在处理过程中修改计数值
     - 需要多个计数器跟踪不同的统计维度
     - 增强代码可读性（如使用有意义的变量名）

3. **灵活性对比**：
   - NR是只读变量（虽然可以修改，但不建议），值由awk自动维护
   - 自定义变量可以完全控制初始化值、更新逻辑和作用域
   - 对于复杂的统计需求，自定义变量提供更大的灵活性

4. **性能考虑**：
   - NR是内置变量，使用它通常不会增加额外的性能开销
   - 自定义变量需要额外的内存和赋值操作，但对于大多数场景影响微小
   - 在性能关键的场景中，简单的行计数直接使用NR可能更高效

**NR变量在awk命令中的位置写法灵活性：**

在awk命令中，使用NR变量进行行选择时，有两种常见的写法，它们在功能上是等效的：

```bash
# 写法1：在花括号前添加NR条件（推荐的标准写法）
ifconfig ens160 | awk 'NR==2{print $2}'
# 输出：
# 10.0.0.12

# 写法2：直接在单引号后添加NR条件（省略花括号前的空格）
ifconfig ens160 | awk NR==2'{print $2}'
# 输出：
# 10.0.0.12
```

这两种写法之所以都能工作，是因为awk的语法设计允许在模式和动作之间有一定的灵活性。在第二种写法中，awk解释器会自动识别`NR==2`作为模式部分，`{print $2}`作为动作部分，即使它们之间没有空格分隔。

**注意事项：**
- 虽然两种写法都有效，但第一种写法（在模式和动作之间添加空格）更符合大多数awk文档和示例中的标准做法
- 在复杂的awk命令中，添加空格可以提高代码可读性，避免可能的解析错误
- 对于简单的单行命令，第二种写法也很常见，特别是在命令行快速操作时

这种灵活性是awk语言设计的一个特点，允许用户根据个人偏好选择自己习惯的写法。

**获取网络接口IP地址的三种方法对比：**

在Linux系统中，可以使用awk通过多种方式从`ifconfig`命令输出中提取IP地址。以下是三种常用方法及其对比：

```bash
# 方法1：基于关键字匹配（netmask）
ifconfig ens160 | awk '/netmask/{print $2}'
# 输出：
# 10.0.0.12

# 方法2：基于关键字匹配（inet空格）
ifconfig ens160 | awk '/inet /{print $2}'
# 输出：
# 10.0.0.12

# 方法3：基于行号定位
ifconfig ens160 | awk 'NR==2{print $2}'
# 输出：
# 10.0.0.12
```

**三种方法的对比分析：**

1. **关键字匹配 vs 行号定位：**
   - **关键字匹配（方法1和2）**：基于内容特征匹配，不依赖于输出格式的固定行数
   - **行号定位（方法3）**：依赖于ifconfig输出中IP地址信息始终位于第2行

2. **稳定性和兼容性：**
   - **基于"inet "匹配（方法2）**：通常最稳定，因为inet关键字专门标识IPv4地址行
   - **基于"netmask"匹配（方法1）**：较为稳定，但可能受到输出格式变化影响
   - **基于行号（方法3）**：在不同Linux发行版或ifconfig版本中可能不稳定，因为输出格式可能不同

3. **适用场景：**
   - **自动化脚本**：推荐使用基于"inet "的关键字匹配（方法2），具有更好的跨平台兼容性
   - **临时快速操作**：在确定输出格式的情况下，行号定位（方法3）语法最简洁
   - **需要处理多个IP地址**：关键字匹配更容易扩展以处理包含多个IP的复杂输出

4. **实际应用建议：**
   - 对于长期使用的脚本，优先选择基于内容的匹配方法（方法2）
   - 对于特定环境下的临时操作，行号定位可能更快捷
   - 考虑使用更现代的`ip addr`命令替代ifconfig，其输出格式更加规范

这种对比展示了awk在文本处理中的灵活性，用户可以根据具体需求和环境选择最合适的方法。

**NR变量在不同块中的行为差异与获取文件行数：**

NR变量在awk的不同执行阶段（BEGIN块、main命令块、END块）有不同的行为，这决定了我们应该在哪个块中获取文件行数。以下是具体对比：

```bash
# 示例1：在END块中获取文件总行数（推荐方式）
awk -F ":" 'END{print NR}' /etc/passwd
# 输出（总行数）：
# 50

# 示例2：在main命令块中使用NR（会逐行输出行号）
awk -F ":" '{print NR}' /etc/passwd
# 输出（所有行号）：
# 1
# 2
# ...
# 50

# 示例3：在BEGIN块中使用NR（初始值为0）
awk -F: 'BEGIN{print NR}'
# 输出：
# 0
```

**为什么要在END块中执行获取文件行数：**

1. **执行时机与NR值的含义：**
   - **BEGIN块**：在读取输入文件之前执行，此时NR的值为0（还没有处理任何记录）
   - **main命令块**：对每一行输入都执行一次，NR的值从1开始逐行递增
   - **END块**：在处理完所有输入行之后执行，此时NR保存了处理过的总行数

2. **获取总行数的最佳实践：**
   - 在END块中，NR变量已经包含了完整的统计结果
   - 相比main命令块逐行输出，END块只需一次输出即可得到总行数
   - 相比使用其他命令（如wc -l），在awk中使用END{print NR}更加高效，无需额外的管道操作

3. **执行流程解析：**
   - awk首先执行BEGIN块（如果有）
   - 然后对输入文件的每一行执行main命令块，并递增NR计数器
   - 最后执行END块（如果有），此时NR的值就是总行数

4. **实际应用建议：**
   - 当只需要文件总行数时，使用END{print NR}是最简洁高效的方式
   - 当需要同时处理行内容并统计行数时，可以在main命令块中处理内容，在END块中输出最终统计
   - 注意区分NR（所有输入文件的总记录数）和FNR（当前输入文件的记录数）

这种设计体现了awk的流水线处理思想，通过将初始化、处理和收尾工作分离到不同的块中，实现了清晰的数据处理流程。

**FIELDWIDTHS与分隔符优先级：列宽模式vs分隔符模式**

在awk中，FIELDWIDTHS和-F（或FS）是两种不同的字段分隔机制，它们之间存在优先级关系：当同时设置FIELDWIDTHS和-F（或FS）时，FIELDWIDTHS会覆盖-F的行为。以下是具体示例和解释：

```bash
# 示例1：使用FIELDWIDTHS按固定宽度分割字段
awk 'BEGIN{FIELDWIDTHS="5 2 8"}NR==1{print $1,$2,$3}' /etc/passwd
# 输出：
# root: x: 0:0:root

# 示例2：同时使用FIELDWIDTHS和-F分隔符，但FIELDWIDTHS生效
awk -F: 'BEGIN{FIELDWIDTHS="5 2 8"}NR==1{print $1,$2,$3}' /etc/passwd
# 输出（与示例1相同）：
# root: x: 0:0:root

# 示例3：分别查看两个文件的内容并使用FNR显示行号
awk '{print FNR,FILENAME,$0}' /etc/issue /etc/redhat-release
# 输出：
# 1 /etc/issue \S 
# 2 /etc/issue Kernel \r on \m 
# 3 /etc/issue 
# 1 /etc/redhat-release Rocky Linux release 9.6 (Blue Onyx)
```

**优先级机制解析：**

1. **FIELDWIDTHS的优先级高于FS（-F）**：
   - 当在BEGIN块中设置FIELDWIDTHS时，awk会忽略-F（或FS）设置的分隔符
   - 这是因为FIELDWIDTHS启用了"固定宽度字段"模式，与传统的"分隔符分隔"模式互斥

2. **两种模式的工作原理：**
   - **分隔符模式（-F或FS）**：根据指定的分隔符字符串或正则表达式将行分割成字段
   - **固定宽度模式（FIELDWIDTHS）**：根据指定的宽度将行分割成固定长度的字段，不考虑内容

3. **实际应用场景：**
   - **分隔符模式**：适用于CSV、配置文件等使用特定分隔符的文本
   - **固定宽度模式**：适用于某些系统日志、报表等具有固定列宽的格式化文本

4. **FNR变量的特殊用途：**
   - FNR用于跟踪当前文件中的记录号（行号），在处理多个文件时很有用
   - 当处理多个文件时，FNR会在每个新文件开始时重置为1，而NR会继续递增

这种优先级设计允许用户根据需要在不同的字段分割策略之间切换，特别是在处理具有复杂格式的文本文件时非常有用。

1. **基本语法**：
   - `print "文本标签", $字段` - 使用逗号分隔文本和字段
   - print会自动在逗号分隔的参数之间插入OFS（默认是空格）

2. **标签格式化技巧**：
   - 在标签后添加冒号、空格等标点符号增强可读性
   - 支持中英文等多语言标签
   - 可以在一行中组合多个文本标签和字段

3. **与控制结构结合**：
   - 可以在main块中使用print输出处理结果
   - 在END块中可以使用printf进行格式化统计输出
   - NF变量表示当前记录的字段数

4. **与printf的配合**：
   - 通常在main块中使用print进行简单输出
   - 在END块中使用printf进行精确的统计信息格式化
   - 两者结合可以实现灵活的输出需求

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

## 17. 致谢

Brian Kernighan在测试和调试过程中提供了宝贵的帮助。我们向他表示感谢。

## 18. 复制许可

版权所有 © 1989, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2001, 2002, 2003, 2004, 2005, 2007, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020，自由软件基金会。

允许制作和分发本手册页的逐字副本，前提是保留版权声明和本许可声明的所有副本。

允许在逐字复制的条件下复制和分发本手册页的修改版本，前提是整个衍生作品在与本声明相同的许可声明下分发。

允许将本手册页翻译成另一种语言进行复制和分发，条件同上，但本许可声明可以使用基金会批准的翻译版本。