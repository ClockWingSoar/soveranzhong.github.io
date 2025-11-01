#!/bin/bash

# 批量创建用户并设置密码的脚本
# 使用方法：
# 1. 直接在命令行指定用户：sudo ./batch_create_users.sh user1 user2 user3 ...
# 2. 从文件读取用户列表：sudo ./batch_create_users.sh -f users.txt

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root权限运行此脚本"
    exit 1
fi

# 默认密码文件和用户列表文件
DEFAULT_PASSWORD="ChangeMe@123"
USER_LIST_FILE=""
USERS=()
GENERATE_RANDOM_PASSWORD=false
LOG_FILE="user_creation_$(date +%Y%m%d_%H%M%S).log"

# 显示帮助信息
show_help() {
    echo "用法：$0 [选项] [用户1 用户2 ...]"
    echo ""
    echo "选项："
    echo "  -f, --file <文件>    从指定文件读取用户列表，每行一个用户名"
    echo "  -p, --password <密码> 设置默认密码，默认为'ChangeMe@123'"
    echo "  -r, --random         为每个用户生成随机密码"
    echo "  -h, --help           显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 user1 user2 user3"
    echo "  $0 -f users.txt -p SecurePass123"
    echo "  $0 -f users.txt -r"
}

# 生成随机密码
generate_password() {
    local length=12
    local password=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c $length)
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
                echo "未知选项：$1"
                show_help
                exit 1
                ;;
            *)
                USERS+="$1"
                shift
                ;;
        esac
    done
}

# 从文件读取用户列表
read_users_from_file() {
    if [ ! -f "$USER_LIST_FILE" ]; then
        echo "错误：用户列表文件 '$USER_LIST_FILE' 不存在"
        exit 1
    fi
    
    echo "从文件 '$USER_LIST_FILE' 读取用户列表..."
    while IFS= read -r user || [ -n "$user" ]; do
        # 忽略空行和以#开头的注释行
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        USERS+="$user"
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
    
    # 创建用户文件，用于存储用户名和密码
    PASSWORD_FILE="users_passwords_$(date +%Y%m%d_%H%M%S).txt"
    echo "用户名:密码" > "$PASSWORD_FILE"
    
    for user in "${USERS[@]}"; do
        # 检查用户是否已存在
        if id "$user" &>/dev/null; then
            echo "警告: 用户 '$user' 已存在，跳过创建"
            echo "$user | - | 已存在" >> "$LOG_FILE"
            continue
        fi
        
        # 设置密码
        if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
            password=$(generate_password)
        else
            password="$DEFAULT_PASSWORD"
        fi
        
        # 创建用户
        useradd -m -s /bin/bash "$user" &>/dev/null
        if [ $? -eq 0 ]; then
            # 设置密码
            echo "$user:$password" | chpasswd
            if [ $? -eq 0 ]; then
                echo "成功: 创建用户 '$user' 并设置密码"
                echo "$user | $password | 成功" >> "$LOG_FILE"
                echo "$user:$password" >> "$PASSWORD_FILE"
                
                # 强制用户首次登录时修改密码
                chage -d 0 "$user"
            else
                echo "错误: 为用户 '$user' 设置密码失败"
                echo "$user | - | 密码设置失败" >> "$LOG_FILE"
            fi
        else
            echo "错误: 创建用户 '$user' 失败"
            echo "$user | - | 创建失败" >> "$LOG_FILE"
        fi
    done
    
    echo "----------------------------------"
    echo "用户创建完成!"
    echo "详细日志: $LOG_FILE"
    echo "用户密码文件: $PASSWORD_FILE"
    echo "注意: 请妥善保管密码文件，建议创建后立即删除或加密存储"
}

# 主函数
main() {
    parse_arguments "$@"
    
    # 如果指定了文件，则从文件读取用户列表
    if [ -n "$USER_LIST_FILE" ]; then
        read_users_from_file
    fi
    
    # 检查是否有用户需要创建
    if [ ${#USERS[@]} -eq 0 ]; then
        echo "错误：未指定要创建的用户，请使用 -f 选项指定用户列表文件或直接在命令行中列出用户名"
        show_help
        exit 1
    fi
    
    # 显示创建计划
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