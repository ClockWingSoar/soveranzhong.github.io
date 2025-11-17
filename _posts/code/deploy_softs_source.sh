#!/bin/bash
# *************************************
# * 功能: Shell一键定制Linux系统软件源
# * 作者: 钟翼翔
# * 联系: clockwingsoar@outlook.com
# * 版本: 2025-11-17
# * 优化: 添加错误处理、日志记录、动态版本检测
# *************************************

# 日志函数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理函数
error_exit() {
    log "错误: $1"
    exit 1
}

# 检查root权限
log "检查root权限..."
if [ "$(id -u)" -ne 0 ]; then
    error_exit "请使用root权限运行此脚本"
fi
log "root权限检查通过"

# 加载系统信息
source /etc/os-release 2>/dev/null || error_exit "无法加载系统信息，请确保/etc/os-release文件存在"

# 定义支持的镜像源
readonly ROCKY_MIRRORS=(
    "mirrors.aliyun.com/rockylinux"    # 阿里云
    "mirrors.sjtug.sjtu.edu.cn/rocky"  # 上海交大
    "mirror.nju.edu.cn/rocky"          # 南京大学
)

readonly UBUNTU_MIRRORS=(
    "mirrors.aliyun.com"               # 阿里云
    "mirrors.tuna.tsinghua.edu.cn"     # 清华源
    "mirror.nju.edu.cn"                # 南京大学
)

# 主程序
main() {
    log "检测操作系统类型..."
    local os_id="${ID}"
    local os_version="${VERSION_ID}"
    log "当前操作系统: ${os_id} ${os_version}"

    case "${os_id}" in
        "rocky")
            if [ "${os_version}" != "9" ]; then
                error_exit "当前脚本仅支持Rocky Linux 9"
            fi
            configure_rocky
            ;;
        "ubuntu")
            if [[ "${os_version}" != "24.04" ]]; then
                error_exit "当前脚本仅支持Ubuntu 24.04"
            fi
            configure_ubuntu
            ;;
        *)
            error_exit "不支持的操作系统: ${os_id}"
            ;;
    esac

    log "软件源配置完成!"
}

# 配置Rocky Linux
configure_rocky() {
    log "开始配置Rocky Linux 9软件源"
    
    # 选择镜像源
    log "可选择的镜像源:"
    echo "1) 阿里云"
    echo "2) 上海交大"
    echo "3) 南京大学"
    
    local mirror_choice
    while true; do
        read -p "请输入选择(1-3): " mirror_choice
        if [[ "${mirror_choice}" =~ ^[1-3]$ ]]; then
            break
        fi
        log "无效输入，请重新选择"
    done
    
    local mirror_url="${ROCKY_MIRRORS[$((mirror_choice-1))]}"
    log "选择的镜像源: ${mirror_url}"
    
    # 备份原有源
    log "备份原有软件源配置..."
    mkdir -p /etc/yum.repos.d/backup
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ 2>/dev/null || error_exit "备份失败"
    
    # 配置新源
    log "配置新的软件源..."
    cat > /etc/yum.repos.d/rocky.repo <<EOF
[baseos]
name=Rocky Linux BaseOS from ${mirror_url}
baseurl=https://${mirror_url}/\$releasever/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0

[appstream]
name=Rocky Linux AppStream from ${mirror_url}
baseurl=https://${mirror_url}/\$releasever/AppStream/\$basearch/os/
enabled=1
gpgcheck=0

[extras]
name=Rocky Linux Extras from ${mirror_url}
baseurl=https://${mirror_url}/\$releasever/extras/\$basearch/os/
enabled=1
gpgcheck=0
EOF
    
    if [ $? -ne 0 ]; then
        error_exit "创建软件源配置文件失败"
    fi
    
    # 更新缓存
    log "更新软件源缓存..."
    dnf makecache -y >/dev/null 2>&1 || error_exit "更新缓存失败"
    log "Rocky Linux 9软件源配置完成"
}

# 配置Ubuntu
configure_ubuntu() {
    log "开始配置Ubuntu 24.04软件源"
    
    # 选择镜像源
    log "可选择的镜像源:"
    echo "1) 阿里云"
    echo "2) 清华源"
    echo "3) 南京大学"
    
    local mirror_choice
    while true; do
        read -p "请输入选择(1-3): " mirror_choice
        if [[ "${mirror_choice}" =~ ^[1-3]$ ]]; then
            break
        fi
        log "无效输入，请重新选择"
    done
    
    local mirror_url="${UBUNTU_MIRRORS[$((mirror_choice-1))]}"
    log "选择的镜像源: ${mirror_url}"
    
    # 选择是否需要src源
    local enable_src
    while true; do
        read -p "是否需要src源(yes/no): " enable_src
        if [[ "${enable_src}" =~ ^(yes|no)$ ]]; then
            break
        fi
        log "无效输入，请输入yes或no"
    done
    
    # 备份原有源
    log "备份原有软件源配置..."
    cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || error_exit "备份失败"
    
    # 清理sources.list.d目录
    log "清理第三方源..."
    rm -rf /etc/apt/sources.list.d/*
    
    # 获取Ubuntu版本代号
    local ubuntu_codename="$(lsb_release -cs 2>/dev/null || echo "noble")"
    log "Ubuntu版本代号: ${ubuntu_codename}"
    
    # 配置新源
    log "配置新的软件源..."
    cat > /etc/apt/sources.list <<EOF
$(for repo in "" "-updates" "-backports" "-security"; do
    echo "deb http://${mirror_url}/ubuntu/ ${ubuntu_codename}${repo} main restricted universe multiverse"
    if [ "${enable_src}" == "yes" ]; then
        echo "deb-src http://${mirror_url}/ubuntu/ ${ubuntu_codename}${repo} main restricted universe multiverse"
    fi
done)
EOF
    
    if [ $? -ne 0 ]; then
        error_exit "创建软件源配置文件失败"
    fi
    
    # 更新缓存
    log "更新软件源缓存..."
    apt-get update >/dev/null 2>&1 || error_exit "更新缓存失败"
    log "Ubuntu 24.04软件源配置完成"
}

# 执行主程序
main