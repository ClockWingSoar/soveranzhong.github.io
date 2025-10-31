#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // 获取实际组ID和有效组ID
    gid_t real_gid = getgid();
    gid_t effective_gid = getegid();
    
    printf("实际组ID (RGID): %d\n", real_gid);
    printf("有效组ID (EGID): %d\n", effective_gid);
    
    // 演示SGID目录行为
    if (argc > 1) {
        char *dir_path = argv[1];
        char file_path[256];
        
        // 构造文件路径
        snprintf(file_path, sizeof(file_path), "%s/test_file.txt", dir_path);
        
        printf("\n尝试在目录 %s 中创建文件...\n", dir_path);
        
        // 创建一个测试文件
        int fd = open(file_path, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fd != -1) {
            const char *content = "这是一个测试文件，用于演示SGID目录的行为。\n";
            write(fd, content, strlen(content));
            close(fd);
            printf("文件已创建: %s\n", file_path);
            printf("请使用 'ls -l %s' 检查文件的组所有权\n", file_path);
        } else {
            perror("创建文件失败");
        }
    } else {
        printf("\n用法: %s <sgid_dir_path>\n", argv[0]);
        printf("请提供一个设置了SGID位的目录路径\n");
        return 1;
    }
    
    return 0;
}