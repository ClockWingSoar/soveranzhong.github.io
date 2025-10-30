# Linux 文件和目录操作命令详解

## 1. 基本概念

在 Linux 中，文件和目录操作是最基本也是最常用的任务。Linux 提供了丰富的命令集来管理文件和目录，从简单的创建和查看，到复杂的搜索和权限管理。本指南将详细介绍这些常用操作命令。

### 文件和目录的基本属性

- **名称**：文件或目录的标识符
- **类型**：普通文件、目录、符号链接、设备文件等
- **大小**：占用的磁盘空间
- **权限**：读写执行权限
- **所有者**：创建文件的用户
- **所属组**：文件所属的用户组
- **时间戳**：创建时间、修改时间、访问时间

## 2. 文件操作命令

### 2.1 创建文件

#### touch 命令

**功能**：创建空文件或更新文件时间戳

**语法**：`touch [选项] 文件名...`

**常用选项**：
- `-a`：仅更新访问时间
- `-m`：仅更新修改时间
- `-d`：使用指定的日期时间
- `-r`：参考另一个文件的时间戳

**示例**：
```bash
# 创建空文件
touch file.txt

# 创建多个文件
touch file1.txt file2.txt file3.txt

# 创建指定日期的文件
touch -d "2023-01-01 12:00" oldfile.txt

# 基于另一个文件的时间戳创建文件
touch -r reference.txt newfile.txt
```

#### echo 命令创建文件

**功能**：将文本写入文件

**语法**：`echo "内容" > 文件名` 或 `echo "内容" >> 文件名`

**示例**：
```bash
# 创建包含内容的文件
echo "Hello, World!" > hello.txt

# 追加内容到文件
echo "This is a new line." >> hello.txt
```

### 2.2 查看文件内容

#### cat 命令

**功能**：连接并显示文件内容

**语法**：`cat [选项] 文件名...`

**常用选项**：
- `-n`：显示行号
- `-b`：显示行号，但不包括空行
- `-s`：压缩连续的空行为一行
- `-A`：显示所有字符（包括制表符、换行符等）

**示例**：
```bash
# 显示单个文件内容
cat file.txt

# 显示文件内容并添加行号
cat -n file.txt

# 合并多个文件的内容
cat file1.txt file2.txt > combined.txt
```

#### less 命令

**功能**：分页查看文件内容，适用于大文件

**语法**：`less [选项] 文件名`

**常用选项**：
- `-N`：显示行号
- `-S`：不换行显示长行
- `-I`：忽略搜索时的大小写

**在 less 中导航**：
- **空格键**：向下翻一页
- **b**：向上翻一页
- **Enter**：向下翻一行
- **k**：向上翻一行
- **G**：跳转到文件末尾
- **g**：跳转到文件开头
- **/pattern**：向下搜索 pattern
- **?pattern**：向上搜索 pattern
- **n**：查找下一个匹配项
- **N**：查找上一个匹配项
- **q**：退出

**示例**：
```bash
# 分页查看文件
less largefile.txt

# 显示行号并分页查看
less -N largefile.txt
```

#### head 命令

**功能**：显示文件的开头部分

**语法**：`head [选项] 文件名`

**常用选项**：
- `-n`：指定显示的行数，默认显示前 10 行
- `-c`：指定显示的字节数

**示例**：
```bash
# 显示文件前 10 行
head file.txt

# 显示文件前 20 行
head -n 20 file.txt
# 或者简写为
head -20 file.txt

# 显示文件前 100 个字节
head -c 100 file.txt
```

#### tail 命令

**功能**：显示文件的末尾部分，常用于查看日志文件

**语法**：`tail [选项] 文件名`

**常用选项**：
- `-n`：指定显示的行数，默认显示最后 10 行
- `-c`：指定显示的字节数
- `-f`：实时监控文件更新（常用）
- `-F`：与 `-f` 类似，但如果文件被删除并重新创建，会继续跟踪

**示例**：
```bash
# 显示文件最后 10 行
tail file.txt

# 显示文件最后 20 行
tail -n 20 file.txt
# 或者简写为
tail -20 file.txt

# 实时监控日志文件更新
tail -f /var/log/syslog

# 显示文件最后 10 行并实时监控
tail -f -n 10 logfile.txt
```

### 2.3 复制文件

#### cp 命令

**功能**：复制文件或目录

**语法**：`cp [选项] 源文件 目标文件` 或 `cp [选项] 源文件... 目标目录`

**常用选项**：
- `-i`：交互式复制，覆盖前提示
- `-r`, `-R`：递归复制目录及其内容
- `-p`：保留文件属性（权限、所有者、时间戳等）
- `-v`：详细模式，显示复制的文件
- `-a`：归档模式，相当于 `-dR --preserve=all`，常用于备份
- `-u`：仅当源文件比目标文件新或目标文件不存在时才复制
- `-b`：在覆盖文件前创建备份

**示例**：
```bash
# 复制单个文件
cp file.txt backup.txt

# 复制多个文件到目录
cp file1.txt file2.txt backup/

# 交互式复制，避免意外覆盖
cp -i file.txt existing.txt

# 复制目录及其内容
cp -r dir1 dir2

# 复制文件并保留属性
cp -p important.txt backup/

# 详细模式复制，显示每个复制的文件
cp -v *.txt archive/
```

### 2.4 移动和重命名文件

#### mv 命令

**功能**：移动文件或目录，或重命名文件和目录

**语法**：`mv [选项] 源文件 目标文件` 或 `mv [选项] 源文件... 目标目录`

**常用选项**：
- `-i`：交互式移动，覆盖前提示
- `-v`：详细模式，显示移动的文件
- `-f`：强制移动，不提示
- `-b`：在覆盖文件前创建备份

**示例**：
```bash
# 重命名文件
mv oldname.txt newname.txt

# 移动文件到目录
mv file.txt documents/

# 移动多个文件到目录
mv *.txt archive/

# 交互式移动，避免意外覆盖
mv -i file.txt existing.txt

# 详细模式移动
mv -v file.txt newlocation/
```

### 2.5 删除文件

#### rm 命令

**功能**：删除文件或目录

**语法**：`rm [选项] 文件...` 或 `rm [选项] 目录...`

**常用选项**：
- `-i`：交互式删除，删除前提示
- `-f`：强制删除，不提示
- `-r`, `-R`：递归删除目录及其内容
- `-v`：详细模式，显示删除的文件

**示例**：
```bash
# 删除单个文件
rm file.txt

# 删除多个文件
rm file1.txt file2.txt file3.txt

# 删除所有 .tmp 文件
rm *.tmp

# 交互式删除，避免意外删除
rm -i important.txt

# 删除目录及其所有内容（危险操作，谨慎使用！）
rm -rf old_directory/

# 详细模式删除，显示删除的每个文件
rm -v *.backup
```

**安全注意事项**：
- `rm -rf` 命令非常危险，会永久删除文件，无法恢复
- 建议在执行删除操作前先确认文件内容
- 对于重要文件，可以使用 `rm -i` 进行交互式确认

### 2.6 查找文件

#### find 命令

**功能**：在指定目录中查找文件和目录

**语法**：`find [路径] [表达式]`

**常用选项和表达式**：
- `-name 模式`：按文件名查找
- `-type 类型`：按文件类型查找（f:文件, d:目录, l:链接）
- `-size 大小`：按文件大小查找（+n:大于, -n:小于, n:等于）
- `-mtime 天数`：按修改时间查找
- `-atime 天数`：按访问时间查找
- `-user 用户名`：按所有者查找
- `-group 组名`：按所属组查找
- `-perm 权限`：按权限查找
- `-exec 命令 {} \;`：对找到的文件执行命令
- `-delete`：删除找到的文件

**示例**：
```bash
# 在当前目录查找所有 .txt 文件
find . -name "*.txt"

# 在 /home 目录查找特定文件
find /home -name "report.pdf"

# 查找目录
find . -type d -name "logs"

# 查找大于 10MB 的文件
find /var -type f -size +10M

# 查找 7 天内修改的文件
find /home -type f -mtime -7

# 查找特定用户的文件
find /home -user john -type f

# 查找并删除所有 .tmp 文件（危险操作，谨慎使用！）
find /tmp -name "*.tmp" -delete

# 查找文件并执行命令（例如查看详细信息）
find /home -name "*.conf" -exec ls -la {} \;

# 查找并复制文件到指定目录
find /source -name "*.doc" -exec cp {} /destination/ \;
```

#### locate 命令

**功能**：使用索引数据库快速查找文件

**语法**：`locate [选项] 模式`

**常用选项**：
- `-i`：忽略大小写
- `-r`：使用正则表达式
- `-n`：限制输出数量

**注意**：`locate` 使用的是预建的文件索引数据库，需要定期更新（使用 `updatedb` 命令）。

**示例**：
```bash
# 查找包含 "report" 的文件
locate report

# 忽略大小写查找
locate -i report

# 使用正则表达式
locate -r "^/home/.*\.txt$"

# 限制输出数量为 10 个
locate -n 10 document
```

### 2.7 比较文件

#### diff 命令

**功能**：比较两个文件的内容差异

**语法**：`diff [选项] 文件1 文件2`

**常用选项**：
- `-u`：以统一格式显示差异
- `-c`：以上下文格式显示差异
- `-i`：忽略大小写
- `-w`：忽略空白字符
- `-b`：忽略空格和制表符的差异

**示例**：
```bash
# 比较两个文件的差异
diff file1.txt file2.txt

# 以统一格式显示差异（更易读）
diff -u file1.txt file2.txt

# 忽略大小写比较
diff -i file1.txt file2.txt
```

#### cmp 命令

**功能**：逐字节比较两个文件

**语法**：`cmp [选项] 文件1 文件2`

**常用选项**：
- `-l`：显示所有不同字节的位置和值
- `-s`：仅返回状态码，不显示差异内容

**示例**：
```bash
# 比较两个文件，只显示第一个不同之处
cmp file1.bin file2.bin

# 显示所有不同字节的位置
cmp -l file1.bin file2.bin
```

#### comm 命令

**功能**：逐行比较已排序的两个文件

**语法**：`comm [选项] 文件1 文件2`

**常用选项**：
- `-1`：不显示只在文件1中出现的行
- `-2`：不显示只在文件2中出现的行
- `-3`：不显示在两个文件中都出现的行

**示例**：
```bash
# 比较两个排序文件
comm sorted1.txt sorted2.txt

# 只显示在两个文件中都出现的行
comm -12 sorted1.txt sorted2.txt
```

## 3. 目录操作命令

### 3.1 创建目录

#### mkdir 命令

**功能**：创建新目录

**语法**：`mkdir [选项] 目录名...`

**常用选项**：
- `-p`：递归创建目录，必要时创建父目录
- `-m`：设置创建目录的权限
- `-v`：详细模式，显示创建的目录

**示例**：
```bash
# 创建单个目录
mkdir newdir

# 创建多个目录
mkdir dir1 dir2 dir3

# 递归创建多级目录
mkdir -p project/src/main/java/com/example

# 创建具有特定权限的目录
mkdir -m 755 public_html

# 详细模式创建目录
mkdir -v -p documents/work/reports
```

### 3.2 删除目录

#### rmdir 命令

**功能**：删除空目录

**语法**：`rmdir [选项] 目录名...`

**常用选项**：
- `-p`：递归删除目录，同时删除父目录（如果为空）
- `-v`：详细模式，显示删除的目录

**示例**：
```bash
# 删除空目录
rmdir emptydir

# 删除多个空目录
rmdir dir1 dir2 dir3

# 递归删除空目录树
rmdir -p project/src/main/java

# 详细模式删除
rmdir -v emptydir
```

#### rm 命令删除目录

**功能**：删除非空目录（使用 `-r` 选项）

**语法**：`rm -r [选项] 目录名`

**常用选项**：
- `-f`：强制删除，不提示
- `-i`：交互式删除，删除前提示
- `-v`：详细模式，显示删除的文件和目录

**示例**：
```bash
# 删除非空目录（危险操作，谨慎使用！）
rm -r directory/

# 强制删除目录，不提示
rm -rf directory/

# 交互式删除目录
rm -ri directory/
```

### 3.3 切换和显示目录

#### cd 命令

**功能**：更改当前工作目录

**语法**：`cd [目录]`

**特殊目录表示**：
- `~`：用户主目录
- `.`：当前目录
- `..`：父目录
- `-`：上一个工作目录

**示例**：
```bash
# 切换到指定目录
cd /home/user/documents

# 切换到主目录
cd ~
# 或简写为
cd

# 切换到父目录
cd ..

# 切换到上一个工作目录
cd -

# 切换到当前目录的子目录
cd subdirectory
```

#### pwd 命令

**功能**：显示当前工作目录的绝对路径

**语法**：`pwd [选项]`

**常用选项**：
- `-P`：显示物理路径，不跟随符号链接

**示例**：
```bash
# 显示当前目录路径
pwd

# 显示物理路径（不跟随符号链接）
pwd -P
```

### 3.4 列出目录内容

#### ls 命令

**功能**：列出目录中的文件和子目录

**语法**：`ls [选项] [文件或目录]`

**常用选项**：
- `-l`：长格式显示，包含详细信息
- `-a`：显示所有文件，包括隐藏文件（以 . 开头的文件）
- `-h`：以人类可读的格式显示文件大小
- `-t`：按修改时间排序（最新的在前）
- `-r`：反向排序
- `-S`：按文件大小排序
- `-R`：递归列出子目录内容
- `-d`：仅列出目录本身，不列出其内容

**示例**：
```bash
# 列出当前目录内容
ls

# 长格式列出，显示详细信息
ls -l

# 显示所有文件，包括隐藏文件
ls -a

# 以人类可读格式显示文件大小
ls -lh

# 按修改时间排序
ls -lt

# 递归列出目录内容
ls -R /home/user

# 仅列出目录信息，不显示其内容
ls -ld /var/log

# 组合选项示例：长格式、所有文件、人类可读、按大小排序
ls -laSh
```

## 4. 文件和目录权限管理

### 4.1 查看权限

**使用 ls -l 命令查看文件权限**：
```bash
ls -l file.txt
# 输出示例：-rw-r--r-- 1 user group 4096 Jul 10 14:30 file.txt
```

**权限字段解析**：
- 第一个字符：文件类型（-:普通文件, d:目录, l:符号链接, b:块设备, c:字符设备）
- 接下来3个字符：所有者权限（rwx）
- 接下来3个字符：组权限（rwx）
- 最后3个字符：其他用户权限（rwx）

**权限含义**：
- `r`（读取）：查看文件内容或列出目录内容
- `w`（写入）：修改文件内容或在目录中创建/删除文件
- `x`（执行）：执行文件或进入目录

### 4.2 更改权限

#### chmod 命令

**功能**：更改文件或目录的访问权限

**语法**：`chmod [选项] 模式 文件...`

**权限表示方法**：

1. **数字表示法**：
   - 4：读取权限 (r)
   - 2：写入权限 (w)
   - 1：执行权限 (x)
   - 每个权限组（所有者、组、其他用户）的值相加
   - 例如：755 = rwxr-xr-x, 644 = rw-r--r--

2. **符号表示法**：
   - **用户类型**：
     - u：所有者
     - g：组
     - o：其他用户
     - a：所有用户
   - **操作符**：
     - +：添加权限
     - -：移除权限
     - =：设置权限
   - **权限**：
     - r：读取
     - w：写入
     - x：执行

**常用选项**：
- `-R`：递归更改目录及其内容的权限
- `-v`：详细模式，显示权限更改

**示例**：
```bash
# 使用数字表示法设置权限
chmod 755 script.sh  # 所有者可读写执行，组和其他用户可读执行
chmod 644 document.txt  # 所有者可读写，组和其他用户可读

# 使用符号表示法设置权限
chmod u+x file.sh  # 为所有者添加执行权限
chmod go-w file.txt  # 移除组和其他用户的写入权限
chmod a+rwx file  # 为所有用户添加读写执行权限
chmod g=rx directory/  # 设置组权限为可读执行

# 递归更改目录权限
chmod -R 755 project/

# 详细模式显示权限更改
chmod -v 644 *.txt
```

### 4.3 更改所有者

#### chown 命令

**功能**：更改文件或目录的所有者和/或组

**语法**：`chown [选项] [所有者][:[组]] 文件...`

**常用选项**：
- `-R`：递归更改目录及其内容的所有权
- `-v`：详细模式，显示所有权更改

**示例**：
```bash
# 更改文件所有者
chown john file.txt

# 同时更改所有者和组
chown john:users file.txt

# 仅更改组（注意冒号前为空）
chown :admin file.txt

# 递归更改目录所有权
chown -R john:users project/

# 详细模式显示所有权更改
chown -v john file.txt
```

### 4.4 更改组

#### chgrp 命令

**功能**：更改文件或目录的组所有权（chown 的子集功能）

**语法**：`chgrp [选项] 组 文件...`

**常用选项**：
- `-R`：递归更改目录及其内容的组所有权
- `-v`：详细模式，显示组更改

**示例**：
```bash
# 更改文件组
chgrp admin file.txt

# 递归更改目录组
chgrp -R users project/
```

## 5. 文件内容搜索和过滤

### 5.1 grep 命令

**功能**：在文件中搜索指定的模式

**语法**：`grep [选项] 模式 [文件...]`

**常用选项**：
- `-i`：忽略大小写
- `-r`, `-R`：递归搜索目录
- `-n`：显示匹配行的行号
- `-v`：反向搜索，显示不匹配的行
- `-c`：只显示匹配的行数
- `-A`：显示匹配行及其后的 N 行
- `-B`：显示匹配行及其前的 N 行
- `-l`：只显示包含匹配项的文件名
- `-L`：只显示不包含匹配项的文件名
- `-E`：使用扩展正则表达式

**示例**：
```bash
# 在文件中搜索关键字
grep "error" log.txt

# 忽略大小写搜索
grep -i "warning" system.log

# 显示匹配行的行号
grep -n "TODO" code.cpp

# 递归搜索目录中的所有文件
grep -r "function" /path/to/code/

# 反向搜索，显示不包含指定模式的行
grep -v "#" config.txt

# 统计匹配行数
grep -c "failed" access.log

# 显示匹配行及其前后各2行
grep -A 2 -B 2 "exception" app.log
```

### 5.2 管道和重定向

**管道符 `|`**：将一个命令的输出作为另一个命令的输入

**重定向符号**：
- `>`：将输出重定向到文件（覆盖）
- `>>`：将输出追加到文件
- `<`：从文件读取输入
- `2>`：将错误输出重定向到文件
- `2>>`：将错误输出追加到文件
- `&>`：将标准输出和错误输出都重定向到文件

**示例**：
```bash
# 管道使用：查找特定用户的进程
ps aux | grep john

# 组合多个命令：查找大文件并排序
find /home -type f -size +10M | xargs ls -lh | sort -rh

# 输出重定向到文件
echo "Hello" > output.txt
ls -la > directory_contents.txt

# 输出追加到文件
echo "New line" >> output.txt

# 错误重定向
echo "Testing error redirect" > /root/test 2> error.log

# 同时重定向标准输出和错误
echo "Testing all output" > /root/test &> all_output.log
```

### 5.3 文本过滤命令

#### sort 命令

**功能**：对文本文件的行进行排序

**语法**：`sort [选项] [文件]`

**常用选项**：
- `-n`：按数值排序
- `-r`：反向排序
- `-k`：指定排序的字段
- `-u`：删除重复行
- `-f`：忽略大小写
- `-t`：指定字段分隔符
- `-o`：将结果输出到文件

**示例**：
```bash
# 按字母顺序排序
sort file.txt

# 按数值排序
sort -n numbers.txt

# 反向排序
sort -r file.txt

# 删除重复行
sort -u duplicates.txt

# 按第二列排序
sort -k2 data.txt

# 指定分隔符并按特定字段排序
sort -t"," -k3 -n csvfile.csv
```

#### uniq 命令

**功能**：从排序文件中删除重复行

**语法**：`uniq [选项] [文件]`

**常用选项**：
- `-c`：显示每行出现的次数
- `-d`：仅显示重复的行
- `-u`：仅显示不重复的行
- `-i`：忽略大小写

**示例**：
```bash
# 删除重复行（通常与 sort 结合使用）
sort file.txt | uniq

# 显示每行出现次数
sort file.txt | uniq -c

# 仅显示重复的行
sort file.txt | uniq -d
```

#### cut 命令

**功能**：从文件的每一行中提取指定部分

**语法**：`cut [选项] [文件]`

**常用选项**：
- `-d`：指定分隔符，默认为制表符
- `-f`：指定要提取的字段（列）
- `-c`：指定要提取的字符位置

**示例**：
```bash
# 提取 CSV 文件的第一列
cut -d"," -f1 data.csv

# 提取多个字段
cut -d":" -f1,6 /etc/passwd

# 提取每行的前 10 个字符
cut -c1-10 text.txt
```

#### awk 命令

**功能**：强大的文本处理工具，用于模式扫描和处理

**语法**：`awk [选项] 'pattern {action}' [文件]`

**基本用法**：
- 默认按空格分隔字段，可通过 `-F` 指定分隔符
- `$0` 表示整行，`$1`, `$2` 等表示第1、第2个字段

**示例**：
```bash
# 显示文件的第一和第三个字段
awk '{print $1, $3}' data.txt

# 使用逗号作为分隔符
awk -F"," '{print $2}' csvfile.csv

# 显示包含特定模式的行
awk '/error/ {print $0}' log.txt

# 计算数字的总和
awk '{sum += $1} END {print sum}' numbers.txt
```

## 6. 高级文件操作

### 6.1 文件压缩和归档

#### tar 命令

**功能**：创建、提取和管理归档文件

**语法**：`tar [选项] [归档文件] [文件...]`

**常用选项**：
- `-c`：创建新归档
- `-x`：从归档中提取文件
- `-v`：详细显示处理的文件
- `-f`：指定归档文件
- `-z`：使用 gzip 压缩/解压缩
- `-j`：使用 bzip2 压缩/解压缩
- `-J`：使用 xz 压缩/解压缩
- `-t`：列出归档内容
- `-C`：指定提取目录

**常用组合**：
- `tar -cvf archive.tar files/`：创建未压缩归档
- `tar -czvf archive.tar.gz files/`：创建 gzip 压缩归档
- `tar -cjvf archive.tar.bz2 files/`：创建 bzip2 压缩归档
- `tar -xzvf archive.tar.gz`：提取 gzip 归档
- `tar -tvf archive.tar`：查看归档内容

**示例**：
```bash
# 创建归档
tar -cvf backup.tar /home/user/documents/

# 创建压缩归档（gzip）
tar -czvf backup.tar.gz /home/user/documents/

# 列出归档内容
tar -tvf backup.tar.gz

# 提取归档到当前目录
tar -xzvf backup.tar.gz

# 提取归档到指定目录
tar -xzvf backup.tar.gz -C /tmp
```

#### zip 和 unzip 命令

**功能**：创建和提取 ZIP 格式的压缩文件

**zip 语法**：`zip [选项] 压缩文件 文件...`
**unzip 语法**：`unzip [选项] 压缩文件`

**zip 常用选项**：
- `-r`：递归压缩目录
- `-9`：最大压缩率
- `-q`：静默模式，不显示输出

**unzip 常用选项**：
- `-d`：指定提取目录
- `-l`：列出压缩文件内容
- `-q`：静默模式

**示例**：
```bash
# 创建 ZIP 压缩文件
zip archive.zip file1.txt file2.txt

# 递归压缩目录
zip -r backup.zip /home/user/documents/

# 列出 ZIP 文件内容
unzip -l archive.zip

# 提取 ZIP 文件到当前目录
unzip archive.zip

# 提取 ZIP 文件到指定目录
unzip archive.zip -d /tmp
```

### 6.2 文件属性和元数据

#### stat 命令

**功能**：显示文件或文件系统的详细状态信息

**语法**：`stat [选项] 文件`

**常用选项**：
- `-f`：显示文件系统状态而非文件状态
- `-t`：以简洁格式显示信息

**示例**：
```bash
# 显示文件的详细信息
stat file.txt

# 以简洁格式显示
stat -t file.txt

# 显示文件系统信息
stat -f /home
```

#### file 命令

**功能**：确定文件类型

**语法**：`file [选项] 文件...`

**常用选项**：
- `-b`：仅显示文件类型，不显示文件名
- `-z`：尝试查看压缩文件内容以确定类型

**示例**：
```bash
# 确定文件类型
file document.pdf
file image.jpg
file script.sh

# 批量检查文件类型
file *

# 查看压缩文件类型
file -z archive.tar.gz
```

### 6.3 符号链接和硬链接

#### ln 命令

**功能**：创建文件链接

**语法**：
- 创建硬链接：`ln [选项] 源文件 链接名`
- 创建符号链接：`ln -s [选项] 源文件 链接名`

**常用选项**：
- `-s`：创建符号链接（软链接）
- `-f`：强制创建链接，覆盖已存在的链接
- `-v`：详细模式，显示链接创建

**示例**：
```bash
# 创建硬链接
ln file.txt hardlink.txt

# 创建符号链接
ln -s /path/to/original/file.txt symlink.txt

# 强制创建链接
ln -sf /path/to/new/file.txt symlink.txt

# 创建目录的符号链接
ln -s /path/to/directory linkdir
```

**硬链接和符号链接的区别**：
- **硬链接**：指向文件的 inode，与原文件共享相同的数据块，删除原文件不影响硬链接
- **符号链接**：指向原文件的路径，类似于快捷方式，原文件删除后符号链接失效
- 硬链接不能跨文件系统，符号链接可以
- 硬链接不能链接目录，符号链接可以

## 7. 实用工具和技巧

### 7.1 批量文件重命名

#### rename 命令

**功能**：批量重命名文件

**语法**：`rename [选项] 表达式 替换 文件名...`

**示例**：
```bash
# 将所有 .txt 文件重命名为 .bak 文件
rename 's/\.txt$/\.bak/' *.txt

# 将所有文件中的空格替换为下划线
rename 's/ /_/g' *

# 添加前缀
rename 's/^/prefix_/' *
```

#### 结合其他命令进行批量重命名

**示例**：
```bash
# 使用循环批量重命名
for file in *.txt; do
  mv "$file" "new_$file"
done

# 使用 find 和 xargs 批量重命名
find . -name "*.txt" -print0 | xargs -0 -I {} mv {} {}.bak
```

### 7.2 文件内容计数

#### wc 命令

**功能**：计算文件的行数、字数和字节数

**语法**：`wc [选项] [文件]`

**常用选项**：
- `-l`：只计行数
- `-w`：只计字数
- `-c`：只计字节数
- `-m`：只计字符数

**示例**：
```bash
# 显示文件的行数、字数和字节数
wc file.txt

# 只显示行数
wc -l file.txt

# 统计多个文件
wc -l *.txt

# 统计目录中的文件数
ls -l | wc -l
```

### 7.3 文件备份技巧

```bash
# 创建带时间戳的备份
cp file.txt file.txt.$(date +%Y%m%d)

# 压缩备份
tar -czvf backup_$(date +%Y%m%d).tar.gz /path/to/backup/

# 增量备份示例（使用 rsync）
rsync -av --link-dest=/path/to/previous/backup /path/to/source /path/to/current/backup
```

### 7.4 查找和处理大文件

```bash
# 查找大于 100MB 的文件
find /home -type f -size +100M -exec ls -lh {} \;

# 按文件大小排序显示前 20 个最大文件
find / -type f -exec ls -la {} \; 2>/dev/null | sort -k5 -rh | head -20

# 查找并清理临时文件
find /tmp -type f -atime +7 -delete
```

## 8. 总结

Linux 提供了强大而灵活的文件和目录操作命令，从基本的创建、查看、复制，到复杂的搜索、过滤和权限管理。熟练掌握这些命令对于高效使用 Linux 系统至关重要。

通过本指南介绍的各种命令和技巧，你可以：
- 有效管理文件和目录结构
- 快速定位和处理文件
- 控制文件访问权限
- 压缩和归档数据
- 执行批量操作和自动化任务

记住，实践是掌握这些命令的最佳方式。尝试在不同场景中应用这些命令，你将逐渐熟悉它们的用法和特性，从而提高在 Linux 环境中的工作效率。