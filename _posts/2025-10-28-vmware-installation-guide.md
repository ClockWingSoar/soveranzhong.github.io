---
layout: post
title: VMware 17.x pro虚拟机安装Rocky9&&Ubuntu24保姆级教程
categories: [GitHub]
description: 本教程将详细介绍如何下载安装 VMware Workstation 17.x Pro，以及在其中安装 Rocky Linux 和 Ubuntu 系统，并使用推荐的远程工具（Windows 推荐 Xshell或MobaXterm，Mac 推荐 iTerm2）通过 IP 地址远程登录到这些 Linux 系统。
keywords: VMware, Rocky, Ubuntu, Xshell,MobaXterm
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---
# VMware 17.x pro虚拟机安装Rocky9&&Ubuntu24保姆级教程

## 0. 概述

本教程将详细介绍如何下载安装 VMware Workstation 17.x Pro，以及在其中安装 Rocky Linux 和 Ubuntu 系统，并使用推荐的远程工具（Windows 推荐 Xshell或MobaXterm，Mac 推荐 iTerm2）通过 IP 地址远程登录到这些 Linux 系统。本指南采用逐步说明的方式，确保即使是初学者也能顺利完成整个过程。

### 为什么选择 VMware Workstation Pro？

- **强大的虚拟化能力**：支持多种操作系统同时运行
- **丰富的功能集**：快照、克隆、共享文件夹等高级特性
- **良好的兼容性**：广泛支持各种 Linux 和 Windows 版本
- **专业的技术支持**：适合开发和测试环境

### 为什么选择 Rocky Linux 和 Ubuntu？

- **Rocky Linux**：企业级稳定性，完全兼容 RHEL，适合服务器环境
- **Ubuntu**：用户友好，社区活跃，桌面体验优秀，适合开发和学习

## 1. VMware Workstation Pro 下载与安装

### 1.1 下载 VMware Workstation Pro

1. **访问官方网站**：
   - 打开浏览器，访问 VMware [官方网站](https://www.vmware.com)，然后搜索 DESKTOP HYPERVISORS，或者直接点击 [workstation pro evaluation page](https://www.vmware.com/products/workstation-pro/workstation-pro-evaluation.html)![image-20251028212859309](./vmware-installation-guide.assets/image-20251028212859309.png)
   - 选择列表中的第一项，进入如下页面，选择Fusion and Workstation<img src="./vmware-installation-guide.assets/image-20251028212921636.png" alt="image-20251028212921636" style="zoom:50%;" />
   - 点击 "DOWNLOAD NOW" 按钮![image-20251028212945523](./vmware-installation-guide.assets/image-20251028212945523.png)
   - VMware被博通收购了，所以需要注册博通账号，点击REGISTER按钮![image-20251028213001188](./vmware-installation-guide.assets/image-20251028213001188.png)
   - 填入邮箱信息和验证码![image-20251028213017540](./vmware-installation-guide.assets/image-20251028213017540.png)
   - 进入邮箱，获取验证码![image-20251028213032579](./vmware-installation-guide.assets/image-20251028213032579.png)
   - 输入其他个人信息，完成账号注册，然后进入下载页面(My Downloads)，打开速度很慢，可能需要魔法上网
   - 输入关键词VMware Workstation Pro ![image-20251028213046791](./vmware-installation-guide.assets/image-20251028213046791.png)
   - 选择windows版的vmware17 pro
     ![image-20251028213102870](./vmware-installation-guide.assets/image-20251028213102870.png)
   - 选择最新的17.6.4![image-20251028213240081](./vmware-installation-guide.assets/image-20251028213240081.png)
   - 进入下载页，需要先点击term链接，勾选同意，再下载![image-20251028213256567](./vmware-installation-guide.assets/image-20251028213256567.png)
   - 弹出页面，选择yes![image-20251028213314240](./vmware-installation-guide.assets/image-20251028213314240.png)
   - 进入地址信息填写，填完提交，终于可以让你下载了![image-20251028213333090](./vmware-installation-guide.assets/image-20251028213333090.png)
   - 如果下载速度较慢，可以复制下载链接到迅雷等下载工具中加速下载

2. **版本选择建议**：
   - 建议下载最新稳定版本，目前为 VMware Workstation Pro 17.x
   - 对于系统配置较低的用户，可以考虑使用免费的 VMware Workstation Player

### 1.2 安装 VMware Workstation Pro

#### 1.2.1 Windows 系统安装步骤

1. 双击下载好的安装程序（通常是 `.exe` 文件）

2. 在欢迎页面点击 "下一步"

   <img src="./vmware-installation-guide.assets/image-20251028222431240.png" alt="image-20251028222431240" style="zoom:50%;" />

   

3. 阅读并接受许可协议，点击 "下一步"

   <img src="./vmware-installation-guide.assets/image-20251028222534222.png" alt="image-20251028222534222" style="zoom:50%;" />

4. 选择安装位置（建议保留默认位置）

   <img src="./vmware-installation-guide.assets/image-20251028222624731.png" alt="image-20251028222624731" style="zoom:50%;" />

5. 取消更新软件和客户体验提升计划选项

   <img src="./vmware-installation-guide.assets/image-20251028222846566.png" alt="image-20251028222846566" style="zoom:50%;" />

   

6. 创建桌面快捷键和开始菜单程序文件夹快捷方式，点击下一步

   <img src="./vmware-installation-guide.assets/image-20251028223002515.png" alt="image-20251028223002515" style="zoom:50%;" />

7. 点击 "安装" 开始安装过程

   <img src="./vmware-installation-guide.assets/image-20251028223123259.png" alt="image-20251028223123259" style="zoom:50%;" />

   <img src="./vmware-installation-guide.assets/image-20251028223316922.png" alt="image-20251028223316922" style="zoom:50%;" />

8. 安装完成后，点击 "完成"

   <img src="./vmware-installation-guide.assets/image-20251028223543932.png" alt="image-20251028223543932" style="zoom:50%;" />

9. 双击VMware图标，打开软件，无需注册即可免费使用

   ![image-20251028223726029](./vmware-installation-guide.assets/image-20251028223726029.png)

#### 1.2.2 Linux 系统安装步骤

1. 打开终端，导航到下载目录
2. 为安装文件添加执行权限：
   ```bash
   chmod +x VMware-Workstation-Full-*.bundle
   ```
3. 运行安装程序：
   ```bash
   sudo ./VMware-Workstation-Full-*.bundle
   ```
4. 按照屏幕提示完成安装
5. 安装完成后，启动 VMware Workstation

## 2. Rocky Linux 系统安装

### 2.1 下载 Rocky Linux ISO 镜像

1. 访问 Rocky Linux 官方下载页面：https://rockylinux.org/download
2. 选择适合您需求的版本（推荐 Rocky Linux 9.x）
3. 选择下载方式（直接下载或通过 torrent）
4. 下载完整安装镜像（DVD 版本）以获取全部功能

### 2.2 在 VMware 中创建 Rocky Linux 虚拟机

#### 2.2.1 虚拟机创建过程

1. 打开 VMware Workstation

2. 点击 "创建新的虚拟机"

   ![image-20251028221904343](./vmware-installation-guide.assets/image-20251028221904343.png)

3. 选择 "典型（推荐）"，点击 "下一步"

   <img src="./vmware-installation-guide.assets/image-20251028224124333.png" alt="image-20251028224124333" style="zoom:50%;" />

4. 选择 "安装程序光盘映像文件（iso）"，点击 "浏览" 找到下载的 Rocky Linux ISO 文件，VMware 会自动检测操作系统，确认是 Rocky Linux，点击 "下一步"

   <img src="./vmware-installation-guide.assets/image-20251028225852578.png" alt="image-20251028225852578" style="zoom:50%;" />

5. 输入虚拟机名称和存放位置

   <img src="./vmware-installation-guide.assets/image-20251028230100258.png" alt="image-20251028230100258" style="zoom:50%;" />

6. 输入硬盘容量200G，这并不会马上分配200G的硬盘，VMware会按照你实际使用的容量分配，但是如果一开始输入的值过小，再扩容会很麻烦, 选择创建单个文件，点击下一步

   <img src="./vmware-installation-guide.assets/image-20251028230348691.png" alt="image-20251028230348691" style="zoom:50%;" />

7. 选择自定义硬件，按照自身电脑配置调整cpu，内存等大小

   <img src="./vmware-installation-guide.assets/image-20251028230554455.png" alt="image-20251028230554455" style="zoom:50%;" />

8. 我这里给4G的内存，这里只是起始内存，后期也都可以随时调整
   

  <img src="./vmware-installation-guide.assets/image-20251028230725424.png" alt="image-20251028230725424" style="zoom:50%;" />

9. 点击关闭，然后回到新建虚拟机向导，选择完成

   <img src="./vmware-installation-guide.assets/image-20251028231006686.png" alt="image-20251028231006686" style="zoom:50%;" />

   ​            

#### 2.2.2 安装 Rocky Linux

1. 右键点击刚新建的虚拟机，或者直接点击，在右侧的主页面开启虚拟机

   <img src="./vmware-installation-guide.assets/image-20251028231142081.png" alt="image-20251028231142081" style="zoom:50%;" />



2. 在启动菜单中选择 "Install Rocky Linux 9.6"，默认选项是Test this media & Install Rocky Linux 9.6，建议选择第一项，会省很多时间，注意白色代表选中

   <img src="./vmware-installation-guide.assets/image-20251028232154226.png" alt="image-20251028232154226" style="zoom: 67%;" />

3. 如果你没有勾选，会进入自检环节，会持续数小时

   <img src="./vmware-installation-guide.assets/image-20251028231919009.png" alt="image-20251028231919009" style="zoom:50%;" />

4. 选中第一项后按enter，等待大概10分钟左右，看到图形界面，选择安装语言（推荐英语或中文）

   <img src="./vmware-installation-guide.assets/image-20251028232801128.png" alt="image-20251028232801128" style="zoom:50%;" />

5. 进入安装摘要页面：

   <img src="./vmware-installation-guide.assets/image-20251028233128098.png" alt="image-20251028233128098" style="zoom:50%;" />

- **时间和日期**：选择您的时区，如果你在上一步选择了中文，这里默认为亚洲上海时区

- **键盘布局**：选择适合的键盘布局，如果你在上一步选择了中文，这里默认为简体中文键盘

- **安装目标**：然后是需要点击并配置的地方，第1，选择自动分区或自定义分区

  <img src="./vmware-installation-guide.assets/image-20251028233356166.png" alt="image-20251028233356166" style="zoom:50%;" />

- **网络和主机名**：第2，启用网络连接，设置为ipv4手动地址，设置主机名为Rocky9.6-15, ip地址为10.0.0.15，网关10.0.0.2，子网掩码可以是24，或者255.255.255.0， DNS服务器可以填阿里云的DNS地址223.5.5.5，223.6.6.6

  ![image-20251028233833161](./vmware-installation-guide.assets/image-20251028233833161.png)![image-20251028234131427](./vmware-installation-guide.assets/image-20251028234131427.png)

- **根密码**：第3， 设置根用户密码

  <img src="./vmware-installation-guide.assets/image-20251028234244284.png" alt="image-20251028234244284" style="zoom:50%;" />

- **用户创建**：第4， 创建普通用户并设置密码

  <img src="./vmware-installation-guide.assets/image-20251028234346715.png" alt="image-20251028234346715" style="zoom:50%;" />

6. 点击 "开始安装"

   <img src="./vmware-installation-guide.assets/image-20251028234459640.png" alt="image-20251028234459640" style="zoom:50%;" />

   <img src="./vmware-installation-guide.assets/image-20251028234712868.png" alt="image-20251028234712868" style="zoom:50%;" />

7. 等待大概半小时，安装完成后，点击 "重启系统"

   <img src="./vmware-installation-guide.assets/image-20251029062203924.png" alt="image-20251029062203924"  /><img src="./vmware-installation-guide.assets/image-20251029062447871.png" alt="image-20251029062447871" style="zoom:50%;" />![image-20251029062539362](./vmware-installation-guide.assets/image-20251029062539362.png)

注意，安装的过程会提示你安装VMware Tools, 大部分时候是要手动安装的，方法如下，有的系统比如Rocky，自动安装了，最直观的效果是屏幕和分辨率会变得更大，跟正常的系统一样。

### 2.3 安装 VMware Tools（增强功能）

安装 VMware Tools 可以显著提升虚拟机性能和用户体验：

1. 虚拟机启动后，登录系统

2. 在 VMware 菜单中选择 "虚拟机" > "安装 VMware Tools"

3. 挂载 VMware Tools 镜像：
   ```bash
   sudo mount /dev/cdrom /mnt
   ```

4. 复制安装文件到临时目录：
   ```bash
   cp /mnt/VMwareTools-*.tar.gz /tmp/
   cd /tmp
   ```

5. 解压并安装：
   ```bash
   tar -xzf VMwareTools-*.tar.gz
   cd vmware-tools-distrib
   sudo ./vmware-install.pl -d
   ```

6. 安装完成后重启虚拟机

> 有些时候，直接用iso镜像文件中的Vmware Tools会安装失败，原因可能是软件已经deprecated了，他会提示你用另一种方式就是去安装open-vm-tools

## 3. Ubuntu 系统安装

### 3.1 下载 Ubuntu ISO 镜像

1. 访问 Ubuntu 官方下载页面：https://ubuntu.com/download/desktop
2. 选择 Ubuntu 24.04 LTS（长期支持版本）或最新版本
3. 点击 "下载" 按钮获取 ISO 镜像

### 3.2 在 VMware 中创建 Ubuntu 虚拟机

#### 虚拟机创建过程

1. 打开 VMware Workstation

2. 点击 "创建新的虚拟机"

3. 选择 "典型（推荐）"，点击 "下一步"

4. 选择 "安装程序光盘映像文件（iso）"，点击 "浏览" 找到下载的 Ubuntu ISO 文件

   <img src="./vmware-installation-guide.assets/image-20251029222828542.png" alt="image-20251029222828542" style="zoom:50%;" />

5. VMware 会自动检测操作系统，确认是 Ubuntu，点击 "下一步"

6. 输入简易安装信息（这里的信息只是摆设，不会真的应用到系统中）

   <img src="./vmware-installation-guide.assets/image-20251029223117134.png" alt="image-20251029223117134" style="zoom:50%;" />

7. 输入虚拟机的名字，并找到存放的文件夹

   <img src="./vmware-installation-guide.assets/image-20251029223324702.png" alt="image-20251029223324702" style="zoom:50%;" />

8. 其余设置参考Rocky Linux的安装过程

   <img src="./vmware-installation-guide.assets/image-20251029223510155.png" alt="image-20251029223510155" style="zoom:50%;" />

9. 点击完成，结束虚拟机的创建

 

#### 安装 Ubuntu24.04

1. 选中创建的虚拟机，点击 "开启此虚拟机"

2. Ubuntu 安装程序会自动启动

   <img src="./vmware-installation-guide.assets/image-20251029223640351.png" alt="image-20251029223640351" style="zoom:50%;" />

3. 选择安装语言（推荐英语或中文）

   <img src="./vmware-installation-guide.assets/image-20251029223846952.png" alt="image-20251029223846952" style="zoom:50%;" /><img src="./vmware-installation-guide.assets/image-20251029224037361.png" alt="image-20251029224037361" style="zoom:50%;" />

4. 可访问下直接点击下一步

   <img src="./vmware-installation-guide.assets/image-20251029224137455.png" alt="image-20251029224137455" style="zoom:50%;" />

5. 键盘布局，也是直接下一步

   <img src="./vmware-installation-guide.assets/image-20251029224219122.png" alt="image-20251029224219122" style="zoom:50%;" />

6. 可以暂时不连接互联网，后面在配置，这样可以加速安装进程

   <img src="./vmware-installation-guide.assets/image-20251029224305607.png" alt="image-20251029224305607" style="zoom:50%;" />

7. 试用或安装ubuntu，选择默认选项，下一步

   <img src="./vmware-installation-guide.assets/image-20251029224353590.png" alt="image-20251029224353590" style="zoom:50%;" />

8. 选择安装类型（推荐 "交互式安装"）

   <img src="./vmware-installation-guide.assets/image-20251029224418167.png" alt="image-20251029224418167" style="zoom:50%;" />

9. 应用程序与更新，默认集合就行，后期可以按需求安装其他软件

   <img src="./vmware-installation-guide.assets/image-20251029224607988.png" alt="image-20251029224607988" style="zoom:50%;" />

10. 优化计算机，直接下一步

    <img src="./vmware-installation-guide.assets/image-20251029224659238.png" alt="image-20251029224659238" style="zoom:50%;" />

11. 选择磁盘分区方式（推荐 "清除整个磁盘并安装 Ubuntu"）

    <img src="./vmware-installation-guide.assets/image-20251029224739675.png" alt="image-20251029224739675" style="zoom:50%;" />

12. 设置账户信息，默认root用户是禁用的，后面可以命令行配置

    <img src="./vmware-installation-guide.assets/image-20251029224858012.png" alt="image-20251029224858012" style="zoom:50%;" />

    

13. 选择您的时区为中国上海

    <img src="./vmware-installation-guide.assets/image-20251029224936981.png" alt="image-20251029224936981" style="zoom:50%;" />

14. 确认用户信息（已在之前步骤中设置）

    <img src="./vmware-installation-guide.assets/image-20251029225004420.png" alt="image-20251029225004420" style="zoom:50%;" />

15. 点击安装并等待安装完成

    <img src="./vmware-installation-guide.assets/image-20251029225042622.png" alt="image-20251029225042622" style="zoom:50%;" />

16. 大概2分钟后，安装完成，点击 "现在重启"

    <img src="./vmware-installation-guide.assets/image-20251029225303660.png" alt="image-20251029225303660" style="zoom:50%;" />

17. 启动完成，输入账号密码，进入系统

    <img src="./vmware-installation-guide.assets/image-20251029225541258.png" alt="image-20251029225541258" style="zoom:50%;" />

18. 设置网络信息，右上角关机按钮邮件选择有线连接中的有线设置

    <img src="./vmware-installation-guide.assets/image-20251029225927840.png" alt="image-20251029225927840" style="zoom:50%;" />

19. 选择网络-->有线-->齿轮图标

    <img src="./vmware-installation-guide.assets/image-20251029230111494.png" alt="image-20251029230111494" style="zoom:50%;" />

20. 设置为ipv4手动地址，设置 ip地址为10.0.0.22，网关10.0.0.2，子网掩码可以是24，或者255.255.255.0， DNS服务器可以填阿里云的DNS地址223.5.5.5，223.6.6.6,设置完成点击应用

    <img src="./vmware-installation-guide.assets/image-20251029230344128.png" alt="image-20251029230344128" style="zoom:50%;" />

21. 显示网络已连接（注意在做这些之前你需要设置VMware的网关地址）

    <img src="./vmware-installation-guide.assets/image-20251029230518145.png" alt="image-20251029230518145" style="zoom:50%;" />

    ​                

### 3.3 安装 VMware Tools（新版本中为open-vm-tools）

1. 打开一个bash终端

   <img src="./vmware-installation-guide.assets/image-20251029230818159.png" alt="image-20251029230818159" style="zoom:50%;" />

2. 在 bash中输入如下命令,输入用户密码，等待系统更新之后安装open-vm-tools

   ```bash
   sudo apt udpate && sudo apt install open-vm-tools -y
   ```

   <img src="./vmware-installation-guide.assets/image-20251029231011470.png" alt="image-20251029231011470" style="zoom:50%;" />

3. 安装完成后系统屏幕和分辨率会变得更正常系统一致

   ![image-20251029231352689](./vmware-installation-guide.assets/image-20251029231352689.png)

## 4. 远程连接工具配置与使用

### 4.1 Windows 用户推荐工具：Xshell 和 MobaXterm

#### 安装 Xshell

1. 访问官方网站：https://www.netsarang.com/zh/xshell-download/
2. 下载 Xshell 免费版或试用版
3. 安装程序并按照提示完成安装

#### 安装 MobaXterm

1. 访问官方网站：https://mobaxterm.mobatek.net/download.html
2. 下载 MobaXterm Home Edition（免费版）或 Professional Edition
3. 安装程序并按照提示完成安装

#### 配置 Linux 虚拟机网络

1. 在 VMware 中，确保虚拟机网络适配器设置为 "桥接模式" 或 "NAT 模式"
2. 启动 Linux 虚拟机
3. 打开终端，运行以下命令获取 IP 地址：
   ```bash
   ip addr show
   ```
4. 记录 IPv4 地址（通常以 192.168.x.x 或 10.x.x.x 开头）

#### 使用 Xshell 连接 Linux 虚拟机

1. 打开 Xshell
2. 点击 "新建" 按钮创建新会话
3. 在 "名称" 字段输入会话名称
4. 在 "主机" 字段输入 Linux 虚拟机的 IP 地址
5. 点击 "确定"
6. 在会话列表中，双击新创建的会话
7. 输入用户名和密码
8. 成功连接后，您可以在 Xshell 中操作 Linux 系统

#### 使用 MobaXterm 连接 Linux 虚拟机

1. 打开 MobaXterm
2. 点击左侧工具栏的 "Session" 按钮
3. 在弹出的窗口中选择 "SSH"
4. 在 "Remote host" 字段输入 Linux 虚拟机的 IP 地址
5. 在 "Specify username" 字段输入用户名（可选）
6. 点击 "OK" 按钮
7. 如果之前未指定用户名，会提示输入用户名
8. 输入密码
9. 成功连接后，您可以在 MobaXterm 的终端窗口中操作 Linux 系统

### 4.2 Mac 用户推荐工具：iTerm2

#### 安装 iTerm2

1. 访问官方网站：https://iterm2.com/downloads.html
2. 下载并安装 iTerm2

#### 配置 Linux 虚拟机网络

步骤同 Windows 用户的网络配置部分

#### 使用 iTerm2 连接 Linux 虚拟机

1. 打开 iTerm2
2. 输入 SSH 命令连接到 Linux 虚拟机：
   ```bash
   ssh 用户名@虚拟机IP地址
   ```
3. 例如：`ssh john@192.168.1.100`
4. 输入密码
5. 成功连接后，您可以在 iTerm2 中操作 Linux 系统

## 5. 远程连接故障排除

### 5.1 常见问题及解决方案

#### 无法连接到虚拟机

- 检查虚拟机是否已启动并运行
- 确认虚拟机的网络设置（桥接或 NAT）
- 验证 IP 地址是否正确
- 检查防火墙设置（临时禁用防火墙测试）：
  ```bash
  # Rocky Linux/CentOS
  sudo systemctl stop firewalld
  
  # Ubuntu
  sudo ufw disable
  ```

#### 连接被拒绝

- 确保 SSH 服务已安装并运行：
  ```bash
  # 检查 SSH 服务状态
  systemctl status sshd  # Rocky/CentOS
  systemctl status ssh   # Ubuntu
  
  # 启动 SSH 服务
  sudo systemctl start sshd  # Rocky/CentOS
  sudo systemctl start ssh   # Ubuntu
  ```

#### 密码验证失败

- 确认用户名和密码正确
- 检查 Caps Lock 键是否开启
- 尝试重置密码（如果有权限）

### 5.2 网络连接测试

如果您遇到网络连接问题，可以使用以下命令进行诊断：

```bash
# 检查网络接口状态
ip link show

# 测试网络连通性
ping 8.8.8.8

# 检查 DNS 解析
dig google.com

# 检查 SSH 服务端口
netstat -tuln | grep 22
```

## 6. 安全建议

### 6.1 使用密钥认证替代密码

使用 SSH 密钥对可以提高安全性并避免频繁输入密码：

1. 生成 SSH 密钥对
2. 将公钥复制到 Linux 服务器
3. 配置 SSH 客户端使用私钥连接

### 6.2 定期更新系统

保持系统更新是维护安全的重要措施：

```bash
# Rocky Linux/CentOS
sudo dnf update -y

# Ubuntu
sudo apt update && sudo apt upgrade -y
```

### 6.3 限制 SSH 访问

- 考虑更改默认 SSH 端口
- 配置防火墙仅允许特定 IP 地址访问
- 禁用 root 远程登录

## 7. 高级配置与优化

### 7.1 VMware 性能优化

- 为虚拟机分配适当的内存和 CPU 资源
- 启用硬件加速功能
- 使用 SSD 存储虚拟机文件
- 定期压缩虚拟磁盘

### 7.2 Linux 系统优化

- 安装常用开发工具
- 配置自动登录（仅适用于个人开发环境）
- 优化桌面环境性能
- 设置自动更新

## 8. 总结与下一步

通过本指南，您已经成功完成了：

1. 下载并安装 VMware Workstation Pro
2. 在虚拟机中安装 Rocky Linux 和 Ubuntu 系统
3. 配置 VMware Tools 增强功能
4. 使用 Xshell 或 iTerm2 远程连接到 Linux 系统
5. 学习了常见问题的故障排除方法

### 推荐的下一步学习内容

- Linux 命令行基础
- 系统管理和服务配置
- 网络配置和安全加固
- 应用程序部署和容器化技术

---
**注意**：本文档中提到的版本和界面可能会随着软件更新而有所变化，请以最新版本为准。如有任何问题，请参考官方文档或寻求社区支持。