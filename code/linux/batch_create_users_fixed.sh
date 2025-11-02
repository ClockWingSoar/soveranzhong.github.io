#!/bin/bash

# 批量创建用户脚本 - 修复版 v2025-11-02
# 作者: DevOps Team
# 功能: 从文件或命令行批量创建用户，支持随机密码生成
# 修复内容: 数组处理问题、条件判断语法错误、变量引用问题、文件读取语法错误

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_PASSWORD="ChangeMe@123"
USER_LIST_FILE=""
USERS=()
GENERATE_RANDOM_PASSWORD=false
LOG_FILE="user_creation_$(date +%Y%m%d_%H%M%S).log"

# 显示帮助信息
show_help() {
  echo -e "${YELLOW}用法: $0 [选项] [用户1 用户2...]${NC}"
  echo
  echo "选项:"
  echo " -f, --file <文件>       从指定文件读取用户列表, 每行一个用户名"
  echo " -p, --password <密码>   设置默认密码, 默认为'$DEFAULT_PASSWORD'"
  echo " -r, --random            为每个用户生成随机密码"
  echo " -h, --help              显示此帮助信息"
  echo
  echo "示例:"
  echo " $0 user1 user2 user3"
  echo " $0 -f users.txt -p SecurePass123"
  echo " $0 -f users.txt -r"
}

# 生成随机密码
generate_password() {
  # 生成12位随机密码，包含大小写字母、数字和特殊字符
  local password=$(openssl rand -base64 12 | tr -d '/+' | head -c 12)
  echo "$password"
}

# 解析命令行参数
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -f|--file)
        USER_LIST_FILE="$2"
        shift 2
        ;;
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
        echo -e "${RED}错误: 未知选项 $1${NC}"
        show_help
        exit 1
        ;;
      *)
        # 将非选项参数作为用户名添加到数组
        USERS+=(("$1"))
        shift
        ;;
    esac
  done
}

# 从文件读取用户列表
read_users_from_file() {
  # 检查文件是否存在
  if [ ! -f "$USER_LIST_FILE" ]; then
    echo -e "${RED}错误: 用户列表文件 '$USER_LIST_FILE' 不存在${NC}"
    exit 1
  fi

  echo "从文件'$USER_LIST_FILE'读取用户列表..."
  # 关键修复：IFS= 和 read 之间必须有空格
  while IFS= read -r user || [ -n "$user" ]; do
    # 忽略空行和以#开头的注释行
    # 重要修复：确保变量引用包含在双引号中，避免语法错误
    # 重要修复：确保=~运算符前后都有空格
    [[ -z "$user" || "$user" =~ ^# ]] && continue
    # 重要修复：正确添加用户到数组，使用双引号确保变量正确展开
    USERS+=(("$user"))
  done < "$USER_LIST_FILE"
}

# 创建用户并设置密码
create_users() {
  echo "开始创建用户..."
  echo "创建日志将保存到: $LOG_FILE"

  # 创建日志文件头
  echo "用户创建日志 - $(date)" > "$LOG_FILE"
  echo "----------------------------------" >> "$LOG_FILE"
  echo "用户名 | 密码 | 状态" >> "$LOG_FILE"
  echo "----------------------------------" >> "$LOG_FILE"

  # 修复：确保检查数组是否为空的正确语法
  if [ ${#USERS[@]} -eq 0 ]; then
    echo -e "${RED}错误: 未指定要创建的用户, 请使用-f选项指定用户列表文件或者直接在命令行中指定用户名${NC}"
    show_help
    exit 1
  fi

  # 创建密码文件
  PASSWORD_FILE="user_passwords_$(date +%Y%m%d_%H%M%S).txt"
  echo "用户密码将保存在: $PASSWORD_FILE"
  echo "用户名: 密码" > "$PASSWORD_FILE"

  # 遍历用户数组创建用户
  for user in "${USERS[@]}"; do
    # 检查用户是否已存在
    if id "$user" &>/dev/null; then
      echo -e "${YELLOW}警告: 用户 '$user' 已存在，跳过创建${NC}"
      echo "$user | - | 已存在" >> "$LOG_FILE"
      continue
    fi

    # 设置用户密码
    if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
      password=$(generate_password)
    else
      password="$DEFAULT_PASSWORD"
    fi

    # 创建用户
    # 重要修复：确保命令参数正确引用
    useradd -m -s /bin/bash "$user" 2>/dev/null
    if [ $? -eq 0 ]; then
      # 设置密码
      echo "$user:$password" | chpasswd
      echo -e "${GREEN}成功: 创建用户 '$user'${NC}"
      echo "$user | $password | 成功" >> "$LOG_FILE"
      echo "$user: $password" >> "$PASSWORD_FILE"
    else
      echo -e "${RED}失败: 创建用户 '$user'${NC}"
      echo "$user | - | 失败" >> "$LOG_FILE"
    fi
  done

  echo "----------------------------------" >> "$LOG_FILE"
  echo "用户创建完成。日志文件: $LOG_FILE"
  echo "密码文件: $PASSWORD_FILE"
}

# 主函数
main() {
  # 检查是否以root用户运行
  if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 脚本需要以root用户权限运行${NC}"
    exit 1
  fi

  # 解析命令行参数
  parse_arguments "$@"

  # 如果指定了用户列表文件，则从文件读取
  if [ -n "$USER_LIST_FILE" ]; then
    read_users_from_file
  fi

  # 创建用户
  create_users
}

# 调用主函数
main "$@"