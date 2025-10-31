#!/bin/bash

# Sticky Bit 演示脚本
# 这个脚本演示了在设置了Sticky Bit的目录中，用户只能删除自己的文件

echo "=== Sticky Bit 演示脚本 ==="
echo

# 创建测试目录
TEST_DIR="sticky_test_dir"
echo "1. 创建测试目录: $TEST_DIR"
mkdir -p $TEST_DIR

# 设置目录权限为777（所有用户可读、可写、可执行）
echo "2. 设置目录权限为777"
chmod 777 $TEST_DIR

echo "3. 当前目录权限:"
ls -ld $TEST_DIR

# 创建几个测试文件，模拟不同用户创建的文件
echo "4. 在目录中创建测试文件（模拟不同用户）"
echo "文件内容 - 由用户A创建" > $TEST_DIR/file_by_userA.txt
echo "文件内容 - 由用户B创建" > $TEST_DIR/file_by_userB.txt
echo "文件内容 - 由用户C创建" > $TEST_DIR/file_by_userC.txt

echo "5. 目录中的文件列表:"
ls -l $TEST_DIR

# 演示没有Sticky Bit时的情况
echo "\n=== 没有Sticky Bit的情况 ==="
echo "6. 尝试删除其他用户的文件（没有Sticky Bit时）"
# 在真实环境中，这取决于文件权限和用户权限
# 这里我们只是模拟这个行为
echo "注意：在真实环境中，没有Sticky Bit时，具有写权限的用户可以删除其他用户的文件"

# 设置Sticky Bit
echo "\n=== 设置Sticky Bit后 ==="
echo "7. 设置Sticky Bit:"
chmod +t $TEST_DIR

echo "8. 设置Sticky Bit后的目录权限:"
ls -ld $TEST_DIR
echo "注意：现在权限显示末尾有't'，表示已设置Sticky Bit"

echo "\n9. Sticky Bit效果说明:"
echo "   - 在设置了Sticky Bit的目录中，用户只能删除/重命名/移动自己拥有的文件"
echo "   - 即使目录权限是777，用户也不能删除其他用户的文件"
echo "   - 只有目录的所有者或root用户可以删除任何文件"

echo "\n10. 常见的Sticky Bit使用场景:"
echo "    - /tmp目录：通常设置为1777权限（rwxrwxrwt）"
echo "    - /var/tmp目录：也常设置Sticky Bit"
echo "    - 共享工作目录：多用户协作环境"

echo "\n=== 清理 ==="
echo "11. 清理测试文件和目录？(y/n)"
read -r clean_up

if [ "$clean_up" = "y" ] || [ "$clean_up" = "Y" ]; then
    rm -rf $TEST_DIR
    echo "测试目录已清理"
else
    echo "测试目录 $TEST_DIR 已保留，请手动清理"
fi

echo "\n=== 演示完成 ==="