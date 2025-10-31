#include <stdio.h>
#include <unistd.h>

/**
 * 演示进程的真实UID、有效UID和保存的UID
 * 
 * 编译方法：gcc uid_full_demo.c -o uid_full_demo
 * 设置SUID（需要root权限）：sudo chown root:root uid_full_demo && sudo chmod 4755 uid_full_demo
 * 运行方式：./uid_full_demo
 * 
 * 当以普通用户运行时，会看到RUID是当前用户的ID，而EUID和SUID是0（root）
 */
int main(void) {
    uid_t r, e, s;
    if (getresuid(&r, &e, &s) == 0) {
        printf("RUID=%d EUID=%d SUID=%d\n", (int)r, (int)e, (int)s);
        printf("\n说明：\n");
        printf("- RUID (Real UID): %d - 启动进程的用户ID\n", (int)r);
        printf("- EUID (Effective UID): %d - 用于权限检查的用户ID\n", (int)e);
        printf("- SUID (Saved UID): %d - 用于恢复之前的有效UID\n", (int)s);
    } else {
        perror("获取UID信息失败");
    }
    return 0;
}