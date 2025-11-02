---
layout: post
title: Linux系统中批量创建用户并设置密码的完整指南
categories: [linux, shell, system]
description: 详细介绍在Linux系统中如何高效批量创建用户并设置密码，包括多种方法和安全最佳实践
keywords: 批量创建用户, Linux, shell脚本, 用户管理, 密码设置
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

# Linux系统中批量创建用户并设置密码的完整指南

在系统管理工作中，经常会遇到需要批量创建多个用户账户的场景，例如新员工入职、学生实验室环境搭建、服务器集群初始化等。手动逐个创建用户不仅效率低下，还容易出错。本文将详细介绍几种在Linux系统中批量创建用户并设置密码的方法，并提供一个功能完善的批量用户创建脚本。

## 一、批量创建用户的常用方法

### 1.1 使用简单的Shell循环

最简单直接的方法是使用Shell循环语句结合`useradd`和`chpasswd`命令。这种方法适用于需要创建少量用户的场景。

```bash
#!/bin/bash
# 简单的批量用户创建脚本

# 定义要创建的用户列表
users=("user1" "user2" "user3" "user4" "user5")
# 定义默认密码
default_password="InitialPass@2024"

echo "开始创建用户..."

# 循环创建用户
for user in "${users[@]}"; do
    # 检查用户是否已存在
    if id "$user" &>/dev/null; then
        echo "警告: 用户 '$user' 已存在，跳过创建"
        continue
    fi
    
    # 创建用户并设置密码
    useradd -m -s /bin/bash "$user" &>/dev/null
    if [ $? -eq 0 ]; then
        # 设置密码
        echo "$user:$default_password" | chpasswd
        
        # 强制用户首次登录修改密码
        chage -d 0 "$user"
        
        echo "成功: 创建用户 '$user' 并设置密码"
    else
        echo "错误: 创建用户 '$user' 失败"
    fi
done

echo "用户创建完成!"
```

这种方法的优点是简单直观，但缺点是不够灵活，当需要创建大量用户或有复杂需求时可能不够高效。

### 1.2 使用newusers命令

Linux系统提供了`newusers`命令，专门用于批量创建用户。这种方法需要先准备一个符合特定格式的用户数据文件。

#### 准备用户数据文件

用户数据文件的格式为：`用户名:密码:UID:GID:描述:主目录:登录Shell`

例如，创建一个名为`users.txt`的文件：

```
user1:加密密码:1001:1001:User One:/home/user1:/bin/bash
user2:加密密码:1002:1002:User Two:/home/user2:/bin/bash
user3:加密密码:1003:1003:User Three:/home/user3:/bin/bash
```

注意：这里的密码应该是加密后的密码，可以使用`openssl`命令生成：

```bash
openssl passwd -1 "YourPassword"
```

#### 使用newusers命令

准备好用户数据文件后，使用以下命令批量创建用户：

```bash
sudo newusers users.txt
```

`newusers`命令会根据文件中的信息自动创建用户及其主目录，并设置密码。

### 1.3 使用awk和chpasswd组合

对于已经创建的用户或需要从简单列表批量设置密码的场景，可以结合使用`awk`和`chpasswd`命令：

```bash
#!/bin/bash

# 假设users.txt包含用户名列表，每行一个用户名
echo "设置用户密码中..."
sudo awk '{print $1":NewPassword123"}' users.txt | sudo chpasswd
echo "密码设置完成!"
```

这种方法适用于快速为多个用户重置密码的场景。

## 二、高级批量用户创建脚本

### 2.1 脚本功能介绍

为了满足更复杂的批量用户创建需求，我们可以开发一个功能完善的Shell脚本，该脚本具有以下特点：

- 支持从命令行参数或文件读取用户列表
- 可设置统一密码或为每个用户生成随机密码
- 自动记录操作日志和生成密码文件
- 强制用户首次登录修改密码
- 检查用户是否已存在，避免重复创建
- 提供详细的帮助信息和使用说明

### 2.2 完整脚本实现

以下是一个功能完善的批量用户创建脚本。在实际使用过程中，我们发现并解决了一些关键问题，使脚本更加健壮：

```bash
#!/bin/bash
# **************************************
# *  生产级别的批量创建用户并设置密码的脚本
# *  作者：钟翼翔
# *  联系：clockwingsoar@outlook.com
# *  版本：2025-11-01
# **************************************

# 检查是否以root运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 请以root用户运行此脚本！"
    exit 1
fi

# default password file and user list file
DEFAULT_PASSWORD="ChangeMe@123"
USER_LIST_FILE=""
USERS=()  # 初始化空数组
GENERATE_RANDOM_PASSWORD=false
LOG_FILE="user_creation_$(date +%Y%m%d_%H%M%S).log"

# 显示帮助信息
show_help(){  
  echo "用法: $0 [选项] [用户1 用户2...]"
  echo ""
  echo "选项: "
  echo " -f, --file <文件>       从指定文件读取用户列表, 每行一个用户名"
  echo " -p, --password <密码>   设置默认密码, 默认为'ChangeMe@123'"
  echo " -r, --random            为每个用户生成随机密码"
  echo " -h, --help              显示此帮助信息"
  echo ""
  echo "示例: "
  echo " $0 user1 user2 user3"
  echo " $0 -f users.txt -p SecurePass123"
  echo " $0 -f users.txt -r"
}

# 生成随机密码
generate_password(){
  local length=12
  local password=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c $length)
  echo "$password"
}


# 解析命令行参数
parse_arguments(){
  while [[ $# -gt 0 ]];do
    case $1 in
      -f|--file)
        USER_LIST_FILE="$2"
        shift 2        ;;
      -p|--password)
        DEFAULT_PASSWORD="$2"
        shift 2
        ;;
      -r|--random)
        GENERATE_RANDOM_PASSWORD=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      -*)
        echo "未知选项: $1"
        show_help
        exit 1
        ;;
      *)
        USERS+=("$1")  # 修复：添加为数组元素
        shift
        ;;
    esac
  done
}

# 从文件读取用户列表
read_users_from_file(){
  if [ ! -f "$USER_LIST_FILE" ]; then
    echo "错误: 用户列表文件'$USER_LIST_FILE'不存在"
    exit 1
  fi

  echo "从文件'$USER_LIST_FILE'读取用户列表..."
  while IFS= read -r user || [ -n "$user" ]; do
    # 忽略空行和以#开头的注释行
    # 重要修复：确保变量引用包含在双引号中，避免语法错误
    [[ -z "$user" || "$user" =~ ^# ]] && continue
    # 重要修复：正确添加用户到数组，使用双引号确保变量正确展开
    USERS+=("$user")
  done < "$USER_LIST_FILE"
}

# 创建用户并设置密码
create_users(){
  echo "开始创建用户..."
  echo "创建日志将保存到: $LOG_FILE"

  #创建日志文件头
  echo "用户创建日志 - $(date)" > "$LOG_FILE"
  echo "----------------------------------" >> "$LOG_FILE"
  echo "用户名 | 密码 | 状态" >> "$LOG_FILE"
  echo "----------------------------------" >> "$LOG_FILE"

  # 创建用户文件, 用于存储用户名和密码
  PASSWORD_FILE="users_passwords_$(date +%Y%m%d_%H%M%S).txt"
  echo "用户名:密码" > "$PASSWORD_FILE"  # 修复：添加$符号

  for user in "${USERS[@]}"; do  # 现在循环遍历正确的数组元素
    # 检查用户是否已经存在
    if id "$user" &> /dev/null; then
      echo "警告: 用户'$user'已存在, 跳过创建"
      echo "$user | - | 已存在" >> "$LOG_FILE"  # 修复：添加$符号
      continue
    fi

    # 设置密码
    if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
      password=$(generate_password)
    else
      password="$DEFAULT_PASSWORD"
    fi

    # 创建用户
    useradd -m -s /bin/bash "$user" &> /dev/null
    if [ $? -eq 0 ]; then  # 修复：添加空格
      # 设置密码
      echo "$user:$password" | chpasswd
      if [ $? -eq 0 ]; then
        echo "成功: 创建用户'$user'并设置密码"
        echo "$user | $password | 成功" >> "$LOG_FILE"  # 修复：添加$符号
        echo "$user:$password" >> "$PASSWORD_FILE"  # 修复：添加$符号

        # 强制用户首次登录时更改密码
        chage -d 0 "$user"
      else
        echo "错误: 为用户'$user'设置密码失败"
        echo "$user | - | 密码设置失败" >> "$LOG_FILE"  # 修复：添加$符号
      fi
    else
      echo "错误: 创建用户'$user' 失败"
      echo "$user | - | 创建失败" >> "$LOG_FILE"  # 修复：添加$符号
    fi
  done

  echo "----------------------------------"
  echo "用户创建完成!"
  echo "详细日志: $LOG_FILE"
  echo "用户密码文件: $PASSWORD_FILE"
  echo "注意: 请妥善保管密码文件, 建议创建后立即删除或加密存储"

}

# 主函数
main(){
  parse_arguments "$@"

  # 如果指定了文件, 则从文件读取用户列表
  if [ -n "$USER_LIST_FILE" ]; then
    read_users_from_file
  fi

  # 检查是否有用户需要创建
  if [ ${#USERS[@]} -eq 0 ]; then
    echo "错误: 未指定要创建的用户, 请使用-f选项指定用户列表文件或者直接在命令行中指定用户名"
    show_help
    exit 1
  fi

  #显示创建计划
  echo "即将创建以下用户: ${USERS[*]}"
  if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
    echo "将为每个用户生成随机密码"
  else
    echo "默认密码: $DEFAULT_PASSWORD"
  fi

  # 确认创建
  read -p "是否继续? (y/n) " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    create_users
  else
    echo "已取消操作"
    exit 0
  fi
}

# 执行主函数
main "$@"
```

### 2.3 脚本使用方法

1. **保存脚本并添加执行权限**：
   ```bash
   chmod +x batch_create_users.sh
   ```

2. **直接在命令行指定用户**：
   ```bash
   sudo ./batch_create_users.sh user1 user2 user3
   ```

3. **从文件读取用户列表**：
   ```bash
   sudo ./batch_create_users.sh -f users.txt
   ```

4. **自定义默认密码**：
   ```bash
   sudo ./batch_create_users.sh -p SecurePass123 user1 user2
   ```

5. **生成随机密码**：
   ```bash
   sudo ./batch_create_users.sh -r -f users.txt
   ```

6. **查看帮助信息**：
   ```bash
   ./batch_create_users.sh --help
   ```

### 2.4 常见问题与解决方案

在使用脚本过程中，我们可能会遇到一些常见问题，以下是解决方案：

**快速解决：** 您可以直接下载修复后的完整脚本文件：[batch_create_users_fixed.sh](/code/linux/batch_create_users_fixed.sh)

#### 2.4.1 数组处理问题

**问题**：脚本尝试一次创建所有用户（如`sov1 sov2`）作为单个用户，而不是分别创建每个用户。

**原因**：在`parse_arguments`函数中，用户被错误地添加为字符串而不是数组元素。

**解决方案**：
```bash
# 错误的代码
USERS+="$1 "  # 这会把所有用户添加到一个字符串中

# 修复后的代码
USERS+=("$1")  # 正确添加为数组元素
```

#### 2.4.2 条件判断语法错误

**问题**：出现错误信息：`batch-create-users-prod.sh:行125: [3：未找到命令`

**原因**：条件判断语法不正确，缺少必要的空格。

**解决方案**：
```bash
# 错误的代码
if [$? -eq 0 ]; then  # 缺少空格

# 修复后的代码
if [ $? -eq 0 ]; then  # 添加空格
```

#### 2.4.3 变量引用问题

**问题**：密码文件和日志文件未能正确生成。

**原因**：在代码中多处使用了`"PASSWORD_FILE"`和`"LOG_FILE"`而不是`"$PASSWORD_FILE"`和`"$LOG_FILE"`，导致写入到了字面值文件中。

**解决方案**：
```bash
# 错误的代码
echo "用户名:密码" > "PASSWORD_FILE"

# 修复后的代码
echo "用户名:密码" > "$PASSWORD_FILE"
```

#### 2.4.4 文件读取问题

**问题**：从文件读取用户列表时，正则表达式语法错误，且用户添加方式有问题。

**解决方案**：
```bash
# 错误的代码
[[ -z "$user" || "$user=~^#" ]] && continue  # 正则表达式语法错误
USERS+="$user"  # 添加方式错误

# 修复后的代码
[[ -z "$user" || "$user" =~ ^# ]] && continue  # 正确的正则表达式语法
USERS+=("$user")  # 正确添加为数组元素
```

#### 2.4.5 文件读取语法错误

**问题**：出现错误信息：`batch-create-users-prod.sh:行86: -r：未找到命令`

**原因**：在`read_users_from_file`函数中，`IFS=`和`read`命令之间缺少必要的空格，导致`IFS=read`被当作一个整体，而`-r`被当作单独的命令执行。

**解决方案**：
```bash
# 错误的代码
while IFS=read -r user || [ -n "$user" ]; do  # 缺少空格

# 修复后的代码
while IFS= read -r user || [ -n "$user" ]; do  # 添加空格
```

#### 2.4.6 变量引用和数组添加语法错误

**问题**：脚本能够读取文件，但所有用户名都被错误地当作注释行跳过，导致出现"未指定要创建的用户"错误。

**原因**：在条件判断中，变量引用缺少双引号，导致Shell解析出错；数组添加语法不正确，影响用户列表的正确构建。

**解决方案**：
```bash
# 错误的代码
[[ -z $user || $user=~^# ]] && continue  # 缺少双引号，正则表达式语法错误
USERS+=$user  # 添加方式错误

# 修复后的代码
[[ -z "$user" || "$user" =~ ^# ]] && continue  # 正确的正则表达式语法，添加双引号
USERS+=("$user")  # 正确添加为数组元素，使用双引号
```

#### 2.4.7 脚本执行流程总结

修复后的脚本执行流程如下：

1. 检查是否以root权限运行
2. 解析命令行参数，正确构建用户数组
3. 可选：从文件读取用户列表（注意IFS=和read之间必须有空格）
4. 显示创建计划并确认
5. 循环创建每个用户，正确处理每个数组元素
6. 记录操作日志和生成密码文件

这些修复确保了脚本能够正确处理多个用户，避免了常见的Shell脚本语法错误，使脚本更加健壮和可靠。

## 三、安全最佳实践

在批量创建用户时，安全性是一个重要的考虑因素。以下是一些安全最佳实践：

### 3.1 密码管理

- **使用强密码**：确保密码足够复杂，包含大小写字母、数字和特殊字符
- **随机密码生成**：对于大量用户，优先使用随机密码生成功能
- **首次登录强制修改**：使用`chage -d 0 username`强制用户首次登录时修改密码
- **密码存储安全**：脚本生成的密码文件应妥善保管，建议使用后立即删除或加密存储

### 3.2 用户权限控制

- **最小权限原则**：为用户分配最小必要的权限
- **组管理**：考虑将用户添加到适当的组中进行权限管理
- **sudo权限**：谨慎分配sudo权限，必要时使用sudoers配置文件进行精细化控制

### 3.3 日志记录与审计

- **记录操作日志**：脚本自动生成详细的操作日志，便于后续审计
- **定期审计用户账户**：定期检查系统中的用户账户，删除不再使用的账户
- **监控异常登录**：配置登录失败次数限制和通知机制

## 四、用户批量管理的其他操作

除了创建用户，系统管理中还经常需要执行其他批量用户管理操作。

### 4.1 批量删除用户

当需要清理大量用户账户时，可以使用以下脚本：

```bash
#!/bin/bash

# 批量删除用户脚本

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    exit 1
fi

# 从文件读取用户列表
if [ -f "users.txt" ]; then
    echo "从文件读取用户列表..."
    while IFS= read -r user || [ -n "$user" ]; do
        # 忽略空行和以#开头的注释行
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # 检查用户是否存在
        if id "$user" &>/dev/null; then
            echo "删除用户: $user"
            # 删除用户及其家目录
            userdel -r "$user"
        else
            echo "用户 '$user' 不存在，跳过"
        fi
    done < "users.txt"
    
    echo "用户删除操作完成!"
else
    echo "错误：文件 'users.txt' 不存在"
    exit 1
fi
```

### 4.2 批量修改用户密码

当需要为多个用户重置密码时：

```bash
#!/bin/bash

# 批量修改用户密码脚本

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    exit 1
fi

# 设置新密码
new_password="NewPassword123"

# 从文件读取用户列表
if [ -f "users.txt" ]; then
    echo "开始修改用户密码..."
    
    # 使用chpasswd批量设置密码
    while IFS= read -r user || [ -n "$user" ]; do
        # 忽略空行和以#开头的注释行
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # 检查用户是否存在
        if id "$user" &>/dev/null; then
            echo "$user:$new_password" | chpasswd
            # 强制用户下次登录修改密码
            chage -d 0 "$user"
            echo "已修改用户 '$user' 的密码"
        else
            echo "用户 '$user' 不存在，跳过"
        fi
    done < "users.txt"
    
    echo "密码修改完成!"
else
    echo "错误：文件 'users.txt' 不存在"
    exit 1
fi
```

### 4.3 批量添加用户到组

将多个用户添加到指定组：

```bash
#!/bin/bash

# 批量添加用户到组脚本

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    exit 1
fi

# 指定目标组
target_group="developers"

# 检查组是否存在
if ! grep -q "^$target_group:" /etc/group; then
    echo "错误：组 '$target_group' 不存在"
    exit 1
fi

# 从文件读取用户列表
if [ -f "users.txt" ]; then
    echo "开始添加用户到组 '$target_group'..."
    
    while IFS= read -r user || [ -n "$user" ]; do
        # 忽略空行和以#开头的注释行
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # 检查用户是否存在
        if id "$user" &>/dev/null; then
            # 添加用户到组
            usermod -aG "$target_group" "$user"
            echo "已将用户 '$user' 添加到组 '$target_group'"
        else
            echo "用户 '$user' 不存在，跳过"
        fi
    done < "users.txt"
    
    echo "用户添加到组操作完成!"
else
    echo "错误：文件 'users.txt' 不存在"
    exit 1
fi
```

## 五、总结

批量用户管理是Linux系统管理中的一项常见任务。本文介绍了多种批量创建用户并设置密码的方法，从简单的Shell循环到功能完善的自动化脚本，以及相关的安全最佳实践和其他批量用户管理操作。

选择哪种方法应根据具体需求和环境决定：

- 对于少量用户，简单的Shell循环即可满足需求
- 对于格式规范的用户数据，`newusers`命令是一个不错的选择
- 对于复杂的用户管理需求，功能完善的自动化脚本提供了最大的灵活性和安全性

无论使用哪种方法，都应该遵循安全最佳实践，确保密码安全和用户权限的适当管理。自动化脚本不仅可以提高工作效率，还可以减少人为错误，是大规模用户管理的理想选择。

通过掌握这些批量用户管理技术，系统管理员可以更高效地完成日常管理任务，为用户提供更好的服务体验。