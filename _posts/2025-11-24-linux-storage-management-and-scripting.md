---
layout: post
title: "Linux Disk Storage Management & Shell Scripting Essentials"
date: 2025-11-24
categories: [Linux, Shell, Storage]
tags: [LVM, RAID, MBR, GPT, Scripting]
---

As an SRE or System Administrator, managing storage and writing automation scripts are two of the most fundamental skills. Whether you are expanding a server's capacity or writing a monitoring script, understanding the underlying principles is crucial.

In this post, we will dive deep into **Disk Storage**, **RAID**, **LVM**, and **Shell Scripting Variables**, concluding with a fun scripting challenge.

---

## 1. Disk Storage Terminology & Structure

Before we manage disks, we must understand how they are structured.

### 1.1 Physical Structure
- **Head**: Reads and writes data.
- **Track**: Concentric circles on the platter.
- **Sector**: The smallest storage unit on a track (usually 512 bytes).
- **Cylinder**: The set of tracks at the same position across all platters.

### 1.2 Partition Tables: MBR vs. GPT

| Feature | MBR (Master Boot Record) | GPT (GUID Partition Table) |
| :--- | :--- | :--- |
| **Max Size** | 2 TB | 18 EB (Exabytes) |
| **Partitions** | Max 4 Primary (or 3 Primary + 1 Extended) | Unlimited (Windows limits to 128) |
| **Redundancy** | No backup of partition table | Backup header at the end of disk |
| **Boot Mode** | BIOS (Legacy) | UEFI |

> [!IMPORTANT]
> For modern servers with drives larger than 2TB, **GPT** is mandatory.

---

## 2. Partitions & File Systems

### 2.1 Partition Types
- **Primary Partition**: Bootable, limited to 4 on MBR.
- **Extended Partition**: A container for logical partitions.
- **Logical Partition**: Created inside an extended partition to bypass the 4-partition limit.

### 2.2 Common File Systems
- **ext4**: The default for many Linux distros. Stable and reliable.
- **xfs**: High performance, great for large files and parallel I/O. Default in RHEL/CentOS 7+.
- **swap**: Virtual memory used when RAM is full.

---

## 3. RAID (Redundant Array of Independent Disks)

RAID combines multiple physical disks into a single logical unit for redundancy, performance, or both.

| RAID Level | Description | Min Disks | Utilization | Redundancy | Performance |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **RAID 0** | Striping | 2 | 100% | None (1 fails, all data lost) | High (Read/Write) |
| **RAID 1** | Mirroring | 2 | 50% | High (1 disk can fail) | Good Read, Normal Write |
| **RAID 5** | Striping + Parity | 3 | $(N-1)/N$ | Good (1 disk can fail) | High Read, Slower Write |
| **RAID 10** | Mirroring + Striping | 4 | 50% | High (1 disk/span can fail) | High (Read/Write) |
| **RAID 01** | Striping + Mirroring | 4 | 50% | High (Riskier than RAID 10) | High |

> [!TIP]
> **RAID 10** is generally preferred over RAID 01 because it offers better fault tolerance during a rebuild.

---

## 4. LVM (Logical Volume Manager)

LVM allows for flexible disk management, enabling you to resize volumes without unmounting or rebooting (in many cases).

### 4.1 Core Concepts
- **PV (Physical Volume)**: The raw disk or partition initialized for LVM.
- **VG (Volume Group)**: A pool of storage created from one or more PVs.
- **LV (Logical Volume)**: The usable partition created from the VG.
- **PE (Physical Extent)**: The smallest chunk of data (default 4MB) managed by LVM.

### 4.2 LVM Experiment: Creation & Expansion

#### Step 1: Create LVM
```bash
# 1. Create Physical Volumes
pvcreate /dev/sdb /dev/sdc

# 2. Create Volume Group 'data_vg'
vgcreate data_vg /dev/sdb /dev/sdc

# 3. Create Logical Volume 'data_lv' (10GB)
lvcreate -L 10G -n data_lv data_vg

# 4. Format and Mount
mkfs.xfs /dev/data_vg/data_lv
mkdir /data
mount /dev/data_vg/data_lv /data
```

#### Step 2: Extend LVM
Suppose we need more space.
```bash
# 1. Check available space in VG
vgs

# 2. Extend the Logical Volume by 5GB
lvextend -L +5G /dev/data_vg/data_lv

# 3. Resize the File System (xfs_growfs for XFS, resize2fs for ext4)
xfs_growfs /data
```

---

## 5. Shell Scripting Variables

In shell scripting, understanding variable scope and types is key to writing robust code.

### 5.1 Variable Types
1.  **Local Variables**: Defined in current shell or function.
    ```bash
    name="John"
    ```
2.  **Environment Variables**: Available to child processes.
    ```bash
    export PATH=$PATH:/opt/bin
    ```
3.  **Positional Variables**: Arguments passed to script.
    - `$1`, `$2`: First, second argument.
    - `$#`: Total number of arguments.
    - `$@`: All arguments.
4.  **Read-only Variables**: Cannot be changed.
    ```bash
    readonly PI=3.14
    ```
5.  **Status Variables**:
    - `$?`: Exit status of the last command (0 = success, non-zero = failure).
    - `$$`: Process ID of the current script.

### 5.2 Naming Rules
-   Use **UPPERCASE** for environment variables (e.g., `HOME`, `PATH`).
-   Use **lowercase** for local variables (e.g., `count`, `filename`).
-   No spaces around `=`.
-   Start with a letter or underscore, not a number.

---

## 6. Scripting Challenge: Guess the Number

Let's put our scripting skills to the test with a simple game.

### The Script: `guess_number.sh`

This script generates a random number between 1 and 100 and guides the user to guess it.

```bash
#!/bin/bash

# Function to generate a random number between 1 and 100
generate_target() {
    echo $((RANDOM % 100 + 1))
}

# Main game logic
play_game() {
    local target=$(generate_target)
    local guess=0
    local attempts=0

    echo "Welcome to the Number Guessing Game!"
    echo "I have selected a number between 1 and 100."
    echo "Can you guess what it is?"

    while [[ $guess -ne $target ]]; do
        read -p "Enter your guess: " guess

        # Validate input is a number
        if ! [[ "$guess" =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid integer."
            continue
        fi

        ((attempts++))

        if [[ $guess -lt $target ]]; then
            echo "Too small! Try again."
        elif [[ $guess -gt $target ]]; then
            echo "Too big! Try again."
        else
            echo "Congratulations! You guessed the number $target in $attempts attempts."
        fi
    done
}

# Start the game
play_game
```

### Key Takeaways
-   **`$RANDOM`**: A built-in variable that returns a random integer.
-   **`read -p`**: Prompts the user for input.
-   **`[[ ... ]]`**: Advanced test command for string and numeric comparisons.
-   **`=~`**: Regex matching operator for validation.

---

## Conclusion

Mastering storage management ensures your systems are reliable and scalable, while shell scripting empowers you to automate routine tasks. Combine these skills, and you're well on your way to becoming a proficient SRE.
