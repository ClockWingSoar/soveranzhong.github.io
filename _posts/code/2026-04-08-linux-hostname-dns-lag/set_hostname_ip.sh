#!/bin/bash
# *************************************
# * 功能: 设定主机名和主机ip并优化本地解析
# * 作者: 钟翼翔
# * 联系: clockwingsoar@outlook.com
# * 版本: 2026-4-08
# *************************************
set -e # 遇到错误立即退出

# 1. 提示用户输入IP地址（仅需输入最后一段，如147）
read -p "请输入10.0.0.0/24网段的IP最后一段（如147）：" IP_LAST

# 清理输入，只保留数字（防止带入逗号或特殊字符）
IP_LAST=$(echo "${IP_LAST}" | tr -cd '0-9')

IP_FULL="10.0.0.${IP_LAST}"
HOSTNAME="ubuntu24-${IP_LAST}"

# 2. 设置主机名
echo "正在设置主机名为：${HOSTNAME}"
hostnamectl set-hostname "${HOSTNAME}"

# 3. 强制同步 /etc/hosts 避免 DNS 解析延迟
echo "正在优化 /etc/hosts 配置..."
cat > /etc/hosts << EOF
127.0.0.1 localhost ${HOSTNAME}
::1       localhost ${HOSTNAME} ip6-localhost ip6-loopback
fe00::0   ip6-localnet
ff00::0   ip6-mcastprefix
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# 4. 定制apt源
echo "正在更新 apt 源为阿里云镜像..."
rm -rf /etc/apt/sources.list.d/*
cat > /etc/apt/sources.list <<-eof
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
eof

# 5. 自动获取当前默认网卡名（防止 ens33 不存在的情况）
NIC_NAME=$(ip route | grep default | awk '{print $5}' | head -n1)
: ${NIC_NAME:=ens33} # 如果没搜到则默认为 ens33

# 6. 生成新的netplan配置（网关默认用10.0.0.2，可根据实际修改）
rm -rf /etc/netplan/*
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
echo "正在生成 netplan 网络配置 (IP: ${IP_FULL}/24, 网卡: ${NIC_NAME})"
cat > "${NETPLAN_FILE}" << EOF
network:
  version: 2
  ethernets:
    ${NIC_NAME}:
      addresses:
        - "${IP_FULL}/24"
      nameservers:
        addresses:
          - 10.0.0.2
          - 223.5.5.5 # 添加公共 DNS 作为备选
      routes:
        - to: default
          via: 10.0.0.2
EOF
chmod 600 "${NETPLAN_FILE}"

# 7. 应用netplan配置并验证
echo "正在应用网络配置..."
netplan apply

# 8. 清理并验证
> ~/.bash_history
echo -e "\n配置完成！当前信息："
echo "主机名：$(hostname)"
echo "IP地址：$(hostname -I)"

# 脚本自我删除
rm -f $0 && echo "脚本已成功自我删除"
