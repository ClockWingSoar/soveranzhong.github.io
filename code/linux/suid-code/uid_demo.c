#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    // 获取实际用户ID和有效用户ID
    uid_t real_uid = getuid();
    uid_t effective_uid = geteuid();
    
    printf("实际用户ID (RUID): %d\n", real_uid);
    printf("有效用户ID (EUID): %d\n", effective_uid);
    
    // 演示如何临时放弃特权
    if (real_uid != effective_uid) {
        printf("\n注意：有效用户ID与实际用户ID不同，程序可能设置了SUID位\n");
        
        // 保存有效用户ID，然后临时切换到实际用户ID
        printf("\n临时放弃特权...\n");
        if (seteuid(real_uid) == 0) {
            printf("切换后 - 有效用户ID (EUID): %d\n", geteuid());
            
            // 在这里可以执行非特权操作
            printf("执行非特权操作...\n");
            
            // 恢复特权
            printf("恢复特权...\n");
            if (seteuid(effective_uid) == 0) {
                printf("恢复后 - 有效用户ID (EUID): %d\n", geteuid());
            } else {
                perror("恢复特权失败");
            }
        } else {
            perror("放弃特权失败");
        }
    } else {
        printf("\n有效用户ID与实际用户ID相同，SUID位可能未设置\n");
    }
    
    return 0;
}