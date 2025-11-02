# 批量用户创建脚本问题修复指南

## 问题分析

从脚本执行输出中，我们可以看到以下关键错误：

1. 错误信息：`batch-create-users-prod.sh:行125: [3：未找到命令`
2. 用户创建失败，因为脚本尝试一次创建所有用户`sov1 sov2`而不是分别创建每个用户

## 主要问题修复

### 1. 数组处理问题

在`parse_arguments`函数中，用户被添加为字符串而不是数组元素：

```bash
# 错误的代码
USERS+="$1 "  # 这会把所有用户添加到一个字符串中，而不是作为单独的数组元素

# 修复后的代码
USERS+=("$1")  # 正确添加为数组元素
```

### 2. 条件判断语法错误

第125行的条件判断语法不正确，缺少空格：

```bash
# 错误的代码
if [$? -eq 0 ]; then  # 缺少空格

# 修复后的代码
if [ $? -eq 0 ]; then  # 添加空格
```

### 3. 变量引用问题

多处使用`"PASSWORD_FILE"`和`"LOG_FILE"`而不是`"$PASSWORD_FILE"`和`"$LOG_FILE"`：

```bash
# 错误的代码
echo "用户名:密码" > "PASSWORD_FILE"

# 修复后的代码
echo "用户名:密码" > "$PASSWORD_FILE"
```

### 4. 文件读取问题

`read_users_from_file`函数中，正则表达式语法不正确，且用户添加方式有问题：

```bash
# 错误的代码
[[ -z "$user" || "$user=~^#" ]] && continue  # 正则表达式语法错误
USERS+="$user"  # 添加方式错误

# 修复后的代码
[[ -z "$user" || "$user" =~ ^# ]] && continue  # 正确的正则表达式语法
USERS+=("$user")  # 正确添加为数组元素
```

## 完整修复后的脚本

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
  local password=$(openssl rand -base64 16 | head -c $length)
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
    [[ -z "$user" || "$user" =~ ^# ]] && continue  # 修复：正确的正则表达式语法
    USERS+=("$user")  # 修复：添加为数组元素
  done < "$USER_LIST_FILE"
}

# 创建用户并设置密码
create_users(){
  echo "开始创建用户..."
  echo "创建日志将保存到: $LOG_FILE"

  #创建日志文件头
  echo "用户创建日志 - $(date)" > "$LOG_FILE"
  echo "----------------------------" >> "$LOG_FILE"
  echo "用户名 | 密码 | 状态" >> "$LOG_FILE"
  echo "----------------------------" >> "$LOG_FILE"

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
        echo "成功: 创建用户$user并设置密码"
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

  echo "-------------------------------"
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
  read -p "是否继续? (y/n)" confirm
  if [[ "$confirm" =~ ^[Yy] ]]; then
    create_users
  else
    echo "已取消操作"
    exit 0
  fi
}

# 执行主函数
main "$@"
```

## 修复的关键点

1. **数组处理**：正确初始化和使用数组存储用户列表
2. **条件语法**：修复条件判断中的空格问题
3. **变量引用**：确保所有变量使用$符号正确引用
4. **正则表达式**：修复正则表达式的语法错误
5. **退出处理**：在main函数中添加了退出0的语句

## 使用方法

```bash
# 修复后的使用方式相同：
sudo bash batch-create-users-prod.sh user1 user2
```

## 安全建议

1. 定期更新默认密码
2. 考虑实现更复杂的密码策略
3. 添加用户权限和组成员管理功能
4. 实现更详细的日志记录和错误处理

## 总结

通过修复脚本中的数组处理、语法错误和变量引用问题，脚本现在可以正确地批量创建用户并设置密码。每个用户将被单独处理，而不是尝试一次性创建所有用户。