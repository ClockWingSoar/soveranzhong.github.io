---
layout: post
title: "A Detailed Guide to Linux Special Permissions: SUID, SGID, and Sticky Bit"
date: 2024-01-15 10:00:00 +0800
categories: [Linux, System Administration]
tags: [Linux, Permissions, SUID, SGID, Sticky Bit, Security]
---

# A Detailed Guide to Linux Special Permissions: SUID, SGID, and Sticky Bit

In Linux systems, besides the familiar read (r), write (w), and execute (x) permissions, there are three special permission bits: SUID (Set User ID), SGID (Set Group ID), and Sticky Bit. These special permission bits play important roles in system administration and security configuration, and understanding them correctly is crucial for maintaining system security.

![Linux Special Permissions Diagram](/images/posts/linux/suid/linux_special_permissions.svg)

This diagram visually illustrates the basic concepts, display methods, and typical features of the three special permission bits. Next, we will detailedly introduce the working principles and usage scenarios of each permission bit.

## 1. SUID (Set User ID) Permission

### 1.1 What is SUID?

SUID is a special permission bit that, when set on an executable file, causes the program to run with the privileges of the file's owner, regardless of which user executes it.

### 1.2 How SUID is Displayed

In the output of the `ls -l` command, the SUID permission bit is displayed as an `s` character in the owner's execute permission position. For example:

```bash
-rwsr-xr-x 1 root root 36000 Jan 10 15:30 /usr/bin/passwd
```

If the owner of the file doesn't originally have execute permission but the SUID bit is set, it will be displayed as a capital `S`.

### 1.3 How SUID Works

When a user executes a program with the SUID bit set, the system temporarily changes the process's effective user ID (EUID) to the ID of the file's owner, while the real user ID (RUID) remains unchanged. This allows the program to run with the privileges of the file's owner.

### 1.4 Typical Applications of SUID

The most common application of SUID is to allow ordinary users to perform operations that require higher privileges. For example:

- `/usr/bin/passwd`: Allows ordinary users to change their passwords, which requires writing to `/etc/passwd` or `/etc/shadow` files
- `/usr/bin/su`: Allows users to switch to other user accounts
- `/usr/bin/sudo`: Allows authorized users to execute commands as other users

### 1.5 SUID Demonstration Code

Here is a C program that demonstrates the effect of SUID permissions:

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    // Get real user ID and effective user ID
    uid_t real_uid = getuid();
    uid_t effective_uid = geteuid();
    
    printf("Real User ID (RUID): %d\n", real_uid);
    printf("Effective User ID (EUID): %d\n", effective_uid);
    
    // Demonstrate how to temporarily drop privileges
    if (real_uid != effective_uid) {
        printf("\nNote: Effective user ID is different from real user ID, SUID bit may be set\n");
        
        // Save effective user ID, then temporarily switch to real user ID
        printf("\nTemporarily dropping privileges...\n");
        if (seteuid(real_uid) == 0) {
            printf("After switching - Effective User ID (EUID): %d\n", geteuid());
            
            // Non-privileged operations can be performed here
            printf("Performing non-privileged operations...\n");
            
            // Restore privileges
            printf("Restoring privileges...\n");
            if (seteuid(effective_uid) == 0) {
                printf("After restoration - Effective User ID (EUID): %d\n", geteuid());
            } else {
                perror("Failed to restore privileges");
            }
        } else {
            perror("Failed to drop privileges");
        }
    } else {
        printf("\nEffective user ID is the same as real user ID, SUID bit may not be set\n");
    }
    
    return 0;
}
```

You can compile and test this program with the following steps:

```bash
# Compile the program
gcc uid_demo.c -o uid_demo

# Set SUID bit (requires root privileges)
sudo chown root:root uid_demo
sudo chmod 4755 uid_demo

# Run as an ordinary user
./uid_demo
```

### 1.6 In-depth Analysis of SUID Working Principle and Security Mechanisms

#### Why Can't Regular Users Do Other Things with SUID Programs?

Taking `/usr/bin/passwd` as an example, this file has SUID permission in Linux systems. This allows regular users to change their own passwords because the passwd program temporarily gains root privileges when executed, thus being able to write to the `/etc/shadow` file which is normally accessible only by root. But why can't regular users use this to do other things?

**Core Reasons Analysis:**

- **SUID Essence**: SUID only sets the executable file's effective UID (EUID) to the file owner (usually root), but this is just a permission attribute of the process, not equivalent to "handing over an interactive root shell to a regular user".

- **Program Behavior is Limited**: Program behavior is limited by its code — only operations explicitly performed by the program will occur with EUID privileges (for example, passwd only implements the file writing and verification logic needed for password modification).

- **Multiple Security Layers**: 
  - Kernel and toolchain protections: For setuid programs, the dynamic linker ignores environment variables like LD_PRELOAD/LD_LIBRARY_PATH, and the shell environment is cleaned up to prevent injection of malicious libraries or control flows.
  - File system and kernel restrictions: Mount options (like nosuid), SELinux/AppArmor, seccomp, CAP_* capability controls, etc., all limit what SUID programs can do.
  - Real UID (RUID) remains the caller's UID, and many operations require multiple checks or the program to actively switch UIDs (seteuid()/setuid()).

- **Secure Implementation of passwd**:
  - passwd runs with EUID=root to write to /etc/shadow (or call PAM interfaces) which is normally writable only by root.
  - passwd performs strict validation on input and does not hand over control to the user (it doesn't directly spawn an interactive root shell).

#### Why Can't Regular Users Change Other Users' Passwords?

Even though the passwd program runs with EUID=root, regular users still can't change other users' passwords because:

- **Program Internal Permission Checks**: EUID=root only gives the passwd program the ability to "write to restricted resources like /etc/shadow" when executing, but the program itself performs permission checks: modification of a specified user's password is allowed only if the caller is that account itself (non-privileged users changing their own passwords) or the program detects it's running as root (real or effective UID is 0).

- **Typical Implementation Logic** (pseudocode):
  ```
  if caller is root → allow changing any user's password (no current password required)
  else if caller is target user → require current password input and verification, after verification only modify that user's entry
  else → refuse
  ```

- **PAM Security Framework**: PAM (Pluggable Authentication Modules) and the shadow library further enforce policies (whether current password is required, password complexity, locking, etc.) and ensure that password files can only be modified through controlled interfaces (avoiding arbitrary writes).

### 1.7 Differences and Relationships Between RUID, EUID, and SUID

#### Core Concept Definitions:

- **RUID (Real UID)**
  - The user ID that started the process (indicating who started the process).
  - Used for attribution, some security decisions, and when restoring privileges.

- **EUID (Effective UID)**
  - The UID used by the kernel for permission checks (accessing files, opening devices, etc.).
  - When an executable file has the SUID bit set or a process calls seteuid()/setuid(), the EUID will differ from the RUID.

- **SUID (Set-user-ID)**
  - **File Level**: A bit set on an executable file (chmod 4755), when the file is run, the process's EUID is set to the owner of the file (often root).
  - **Process Level**: POSIX also has a Saved UID, used to restore a previous EUID after switching EUIDs.

#### Complete UID Information Viewing Demo Code

The following program can view a process's real UID, effective UID, and saved UID:

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    uid_t r, e, s;
    if (getresuid(&r, &e, &s) == 0) {
        printf("RUID=%d EUID=%d SUID=%d\n", (int)r, (int)e, (int)s);
    }
    return 0;
}
```

Compilation and testing steps are the same as before, allowing observation of the differences between the three UIDs.

### 1.8 Security Risks of SUID

SUID is a powerful but dangerous mechanism that can lead to serious security issues if used improperly:

- Attackers may exploit vulnerable SUID programs to elevate privileges
- Misconfigured SUID programs may be used to bypass system security policies

### 1.9 Best Practices for Using SUID Safely

- Set the SUID bit only for necessary programs
- Ensure the owner of SUID programs is root or another privileged user
- Restrict write permissions for SUID programs to ensure only authorized users can modify them
- Regularly audit SUID programs in the system
- Follow the principle of least privilege when writing SUID programs, dropping privileges promptly
- Clean up environment variables, disable unsafe behaviors, and avoid exploitable exec calls

## 2. SGID (Set Group ID) Permission

### 2.1 What is SGID?

SGID is similar to SUID but affects group permissions. When set on an executable file, the program runs with the privileges of the file's group. When set on a directory, new files and directories created within it inherit the group ownership of the directory.

### 2.2 How SGID is Displayed

In the output of the `ls -l` command, the SGID permission bit is displayed as an `s` character in the group's execute permission position. For example:

```bash
-rwxr-sr-x 1 root staff 10240 Jan 10 15:30 /usr/bin/wall
```

For directories:

```bash
drwxr-sr-x 2 root shared 4096 Jan 10 15:30 shared_dir
```

### 2.3 How SGID Works

- **For executable files**: When a user executes a program with the SGID bit set, the process's effective group ID (EGID) is set to the ID of the file's group
- **For directories**: New files and directories created within a directory with the SGID bit set inherit the group ownership of the directory, rather than the effective group ID of the creator

### 2.4 Applications of SGID

- **Executable files**: Allow programs to access resources with specific group privileges, such as the `wall` command running with `tty` group privileges
- **Directories**: In multi-user collaboration environments, ensure files created by team members automatically belong to the team group for easy sharing

### 2.5 SGID Demonstration Code

Here is a program that demonstrates the effect of SGID:

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

int main(int argc, char *argv[]) {
    // Get real group ID and effective group ID
    gid_t real_gid = getgid();
    gid_t effective_gid = getegid();
    
    printf("Real Group ID (RGID): %d\n", real_gid);
    printf("Effective Group ID (EGID): %d\n", effective_gid);
    
    // Demonstrate SGID directory behavior
    if (argc > 1) {
        char *dir_path = argv[1];
        char file_path[256];
        
        // Construct file path
        snprintf(file_path, sizeof(file_path), "%s/test_file.txt", dir_path);
        
        printf("\nAttempting to create a file in directory %s...\n", dir_path);
        
        // Create a test file
        int fd = open(file_path, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fd != -1) {
            const char *content = "This is a test file to demonstrate SGID directory behavior.\n";
            write(fd, content, strlen(content));
            close(fd);
            printf("File created: %s\n", file_path);
            printf("Please use 'ls -l %s' to check the file's group ownership\n", file_path);
        } else {
            perror("Failed to create file");
        }
    } else {
        printf("\nUsage: %s <sgid_dir_path>\n", argv[0]);
        printf("Please provide a directory path with SGID bit set\n");
        return 1;
    }
    
    return 0;
}
```

### 2.6 How to Set SGID

- **Set SGID on a file**: `chmod g+s filename` or `chmod 2755 filename`
- **Set SGID on a directory**: `chmod g+s directory` or `chmod 2775 directory`

## 3. Sticky Bit Permission

### 3.1 What is Sticky Bit?

The Sticky Bit is primarily used for directories, and it restricts deletion operations: in a directory with the Sticky Bit set, only the owner of the file, the owner of the directory, or the root user can delete, rename, or move files, even if other users have write permission to the directory.

### 3.2 How Sticky Bit is Displayed

In the output of the `ls -l` command, the Sticky Bit is displayed as a `t` character in the other users' execute permission position. For example:

```bash
drwxrwxrwt 10 root root 4096 Jan 10 15:30 /tmp
```

### 3.3 How Sticky Bit Works

When the Sticky Bit is set on a directory, the Linux kernel performs additional checks during delete, rename, or move operations to ensure the executor has permission to perform these operations.

### 3.4 Typical Applications of Sticky Bit

- `/tmp` and `/var/tmp` directories: These are system temporary directories where all users can write, but users should not be allowed to delete files belonging to other users
- Multi-user shared directories: Ensure users can only manage their own files

### 3.5 Sticky Bit Demonstration Script

Here is a shell script that demonstrates the effect of the Sticky Bit:

```bash
#!/bin/bash

# Sticky Bit demonstration script
# This script demonstrates that in a directory with Sticky Bit set, users can only delete their own files

echo "=== Sticky Bit Demonstration Script ==="
echo

# Create test directory
TEST_DIR="sticky_test_dir"
echo "1. Creating test directory: $TEST_DIR"
mkdir -p $TEST_DIR

# Set directory permissions to 777 (read, write, execute for all users)
echo "2. Setting directory permissions to 777"
chmod 777 $TEST_DIR

echo "3. Current directory permissions:"
ls -ld $TEST_DIR

# Create several test files, simulating files created by different users
echo "4. Creating test files in the directory (simulating different users)"
echo "File content - created by user A" > $TEST_DIR/file_by_userA.txt
echo "File content - created by user B" > $TEST_DIR/file_by_userB.txt
echo "File content - created by user C" > $TEST_DIR/file_by_userC.txt

echo "5. List of files in the directory:"
ls -l $TEST_DIR

# Demonstrate the situation without Sticky Bit
echo "\n=== Without Sticky Bit ==="
echo "6. Attempting to delete files belonging to other users (without Sticky Bit)"
# In a real environment, this depends on file permissions and user permissions
# Here we just simulate this behavior
echo "Note: In a real environment, without Sticky Bit, users with write permission can delete files belonging to other users"

# Set Sticky Bit
echo "\n=== With Sticky Bit Set ==="
echo "7. Setting Sticky Bit:"
chmod +t $TEST_DIR

echo "8. Directory permissions after setting Sticky Bit:"
ls -ld $TEST_DIR
echo "Note: Now the permission display ends with 't', indicating Sticky Bit is set"

echo "\n9. Explanation of Sticky Bit effect:"
echo "   - In a directory with Sticky Bit set, users can only delete/rename/move files they own"
echo "   - Even if the directory permissions are 777, users cannot delete files belonging to other users"
echo "   - Only the directory owner or root user can delete any file"

echo "\n10. Common use cases for Sticky Bit:"
echo "    - /tmp directory: usually set to 1777 permissions (rwxrwxrwt)"
echo "    - /var/tmp directory: also often has Sticky Bit set"
echo "    - Shared working directories: multi-user collaboration environments"
```

### 3.6 How to Set Sticky Bit

- **Set Sticky Bit on a directory**: `chmod +t directory` or `chmod 1777 directory`

## 4. Octal Representation of Special Permissions

When using the `chmod` command to set permissions, you can use octal numbers to represent special permission bits:

- SUID: 4 (binary: 100)
- SGID: 2 (binary: 010)
- Sticky Bit: 1 (binary: 001)

These numbers are combined with the regular permission numbers (r=4, w=2, x=1) and placed at the beginning of the permission number. For example:

- `chmod 4755 file`: Sets SUID and regular permissions to read, write, execute for owner, and read, execute for group and others
- `chmod 2775 directory`: Sets SGID and regular permissions to read, write, execute for owner and group, and read, execute for others
- `chmod 1777 directory`: Sets Sticky Bit and regular permissions to read, write, execute for all users

## 5. Security Considerations

### 5.1 Security Risks of SUID/SGID

- **Privilege Escalation**: If an SUID program has security vulnerabilities, attackers may use it to gain root privileges
- **Privilege Abuse**: Improperly configured SUID/SGID programs may be used to perform unauthorized operations
- **Maintenance Difficulties**: Too many SUID/SGID programs increase the difficulty of system management and security auditing

### 5.2 Security Auditing

Regularly checking SUID/SGID programs in the system is an important part of security management:

```bash
# Find all SUID programs
sudo find / -perm -4000 -type f -ls

# Find all SGID programs
sudo find / -perm -2000 -type f -ls

# Find all directories with Sticky Bit set
sudo find / -perm -1000 -type d -ls
```

### 5.3 Best Practices

- **Principle of Least Privilege**: Use special permission bits only when necessary
- **Regular Auditing**: Regularly check special permission settings in the system
- **Use sudo Instead**: For operations temporarily requiring privileges, prefer sudo over setting SUID
- **File Integrity Monitoring**: Monitor changes to SUID/SGID files
- **Disable Unnecessary SUID/SGID Programs**: Remove special permission bits from SUID/SGID programs that are not needed

## 6. Summary

Special permission bits (SUID, SGID, and Sticky Bit) are important components of the Linux permission system. They provide flexible permission control mechanisms but also bring potential security risks.

SUID simply gives a specified program additional effective permissions when executing; whether it can "do other things" depends on whether the program itself exposes that capability and whether the kernel/security mechanisms allow such behavior. Good SUID program design strictly limits the scope of permission use, ensuring that even when running with root privileges, it can only perform specific functions.

SGID provides convenience for multi-user collaboration, especially in shared directory scenarios, ensuring that new files automatically inherit the directory's group ownership.

Sticky Bit provides additional security guarantees for multi-user environments, ensuring users can only manage their own files, even in directories with 777 permissions.

In practical applications, we should always follow the principle of least privilege, regularly audit special permission settings in the system, and take necessary security measures to prevent privilege abuse and escalation.

Through this article, I believe you have gained a deep understanding of Linux special permission bits and can use them more safely and effectively in your actual work.

## References

1. Linux man pages: chmod(1), stat(2), getuid(2), setuid(2)
2. Linux Programmer's Manual: Permissions
3. "Linux System Administration Handbook"
4. "鸟哥的Linux私房菜" ("Bird's Linux Private Kitchen")