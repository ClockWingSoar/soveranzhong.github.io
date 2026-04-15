# 运维面试题

## 1. 如何知道一个进程是多线程

可以用pstree -p 看括号中的数字，也可以直接ps aux |grep 进程， 如果有l在也是多线程

```sh
   0 ✓ 14:17:44 root@redis-master,10.0.0.30:/data/softs # pstree -p | grep zabbix
           `-zabbix_agent2(5352)-+-{zabbix_agent2}(5361)
                                 |-{zabbix_agent2}(5362)
                                 |-{zabbix_agent2}(5363)
                                 |-{zabbix_agent2}(5364)
                                 |-{zabbix_agent2}(5376)
                                 `-{zabbix_agent2}(5390)
  0 ✓ 14:26:10 root@redis-master,10.0.0.30:/data/softs #

 0 ✓ 13:42:11 root@redis-master,10.0.0.30:/data/softs # ps aux | grep zabbix
zabbix      5352  0.0  0.5 1695696 21944 ?       Ssl  13:42   0:00 /usr/sbin/zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf
root        5541  0.0  0.0   6552  2340 pts/0    S+   14:16   0:00 grep --color=auto zabbix

```



## 2 shell       写过哪些脚本？

分类：部署k8s,nginx,mysql,zabbix，参数优化，安全加固，备份，监控，自定义业务



## 3. Zabbix 架构？





## 4.iptables 表，链

五表五链



## 5. 四层，七层代理区别



## 6. 存储类型

- DAS 直连存储，块设备
- NAS 网络附加存储，NFS，SAMBA，FTP，文件
- SAN 存储区域网络，块设备 ，iSCSI 



## 7. 网络设备

- 路由器：*3层，路由表：来源？静态，动态（*路由协议，RIP，OSPF，BGP）
- 交换机：2层 *VLAN 功能？隔离广播域，冲突域

## 8. 源代码构建工具

- JAVA：maven mvn clean package -Dmaven.test.skip=true
- GO: go build 
- Python: python3 xxx.py
- C:  configure;make;make install 

容器化: docker 



## 9. SRE 工程师岗位职责

- 应用发布：发版
- 变更：优化，升级，构架，扩缩容
- 故障恢复： 发现故障，Zabbix

## 10. MySQL日志

- 二进制日志：备份
- 慢查询 
- 事务 ACID
- 错误
- 中继日志

MySQL主从复制

- 原理：总 二个角色，二个日志，三个线程dump,io,sql， 分
- 配置过程： 主：server_id,二进制日志，用户授权，备份 从： server_id，read_only,还原,change master to ; start slave

## 11. 你都知道哪些linux命令

分类法 Linux 命令  系统，文件，权限，磁盘，进程，网络



## 12. HTTP协议 和响应码

- 版本：
- 工作原理：报文结构
- 响应码：1XX,2XX,3XX 301 302 4XX 401 500

## 13. 监控系统包括什么

- 指标采集
- 存储
- 展示
- 告警
- 。。。

## 14. 你都写过什么脚本

- shell       写过哪些脚本？分类：部署k8s,nginx,mysql,zabbix，参数优化，安全加固，备份，监控，自定义业务
- python

## 15. 如何配置zabbix监控

监控主机或通用应用

- 安装Zabbix Server (Zabbix Server,MySQL,nginx/apache+php)
- 安装Agent
- 配置Agent
- 在ZabbixServer 添加主机
- 关联对应模板（内置监控项）



自定义应用监控

- 自定义监控