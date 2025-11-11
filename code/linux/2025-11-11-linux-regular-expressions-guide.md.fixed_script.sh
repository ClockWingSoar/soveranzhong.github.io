#!/bin/bash 
# ************************************** 
# *  定制管理界面的登录注册功能 
# *  作者：钟翼翔 
# *  联系：clockwingsoar@outlook.com 
# *  版本：2025-11-11 
# ************************************** 

# 定制目标类型变量 
target_type=(登录 注册) 
# 定制普通变量 - 修复正则表达式
user_regex='^[a-zA-Z0-9_@.]{6,15}$' 
passwd_regex='^[a-zA-Z0-9.]{6,8}$' 
phone_regex='^\b1[3-9][0-9]{9}\b$' 
email_regex='^[a-zA-Z0-9_]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,5}$' 

# 检测用户名规则 
check_func(){
    # 接收函数参数 
    target=$1 
    target_regex=$2 
    # 判断目标格式是否有效 
    echo "$target" | egrep "${target_regex}" >/dev/null && echo "true" || echo "false" 
}

# 定制服务的操作提示功能函数 
menu(){
    echo -e "\e[31m---------------管理平台登录界面---------------"
    echo -e " 1: 登录  2: 注册"
    echo -e "-------------------------------------------\033[0m"
}

# 定制帮助信息 
Usage(){
    echo "请输入正确的操作类型"
}

# 管理平台用户注册过程 
user_register_check(){
    read -p "> 请输入用户名: " login_user 
    user_result=$(check_func "${login_user}" "${user_regex}") 
    if [ "${user_result}" == "true" ];then 
        read -p "> 请输入密码: " login_passwd 
        passwd_result=$(check_func "${login_passwd}" "${passwd_regex}") 
        if [ "${passwd_result}" == "true" ];then 
            read -p "> 请输入手机号: " login_phone 
            phone_result=$(check_func "${login_phone}" "${phone_regex}") 
            if [ "${phone_result}" == "true" ];then 
                read -p "> 请输入邮箱: " login_email
                email_result=$(check_func "${login_email}" "${email_regex}") 
                if [ "${email_result}" == "true" ];then 
                    echo -e "\e[31m----用户注册信息内容----"
                    echo -e " 用户名称: ${login_user}"
                    echo -e " 登录密码: ${login_passwd}"
                    echo -e " 手机号码: ${login_phone}"
                    echo -e " 邮箱地址: ${login_email}"
                    echo -e "------------------------\033[0m"
                    read -p "> 是否确认注册[yes|no]: " login_status 
                    [ "${login_status}" == "yes" ] && echo "用户 ${login_user} 注册成功" && exit || return 
                else 
                    echo "邮箱地址格式不规范"
                fi 
            else 
                echo "手机号码格式不规范"
            fi 
        else 
            echo "登录密码格式不规范"
        fi 
    else 
        echo "用户名称格式不规范"
    fi 
}

# 定制业务逻辑 
while true 
do 
    menu 
    read -p "> 请输入要操作的目标类型: " target_id 
    if [ "${target_type[$target_id-1]}" == "登录" ];then 
        echo "开始登录管理平台..."
    elif [ "${target_type[$target_id-1]}" == "注册" ];then 
        user_register_check 
    else 
        Usage 
    fi 
done