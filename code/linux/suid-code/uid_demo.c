#include <stdio.h>
#include <unistd.h>

/**
 * 演示SUID程序中的真实UID和有效UID差异
 * 
 * 编译方法：gcc uid_demo.c -o uid_demo
 * 设置SUID（需要root权限）：sudo chown root:root uid_demo && sudo chmod 4755 uid_demo
 * 运行方式：./uid_demo
 * 
 * 当以普通用户运行时，会看到RUID是当前用户的ID，而EUID是0（root）
 */
int main(void) {
    printf("RUID=%d EUID=%d\n", (int)getuid(), (int)geteuid());
    return 0;
}