---
layout: post
title: A Complete Guide to Batch Creating Users and Setting Passwords in Linux
categories: [linux, shell, system]
description: A detailed guide on how to efficiently batch create users and set passwords in Linux systems, including multiple methods and security best practices
keywords: batch create users, Linux, shell script, user management, password setting
mermaid: false
sequence: false
flow: false
mathjax: false
mindmap: false
mindmap2: false
---

# A Complete Guide to Batch Creating Users and Setting Passwords in Linux

In system administration work, we often encounter scenarios where we need to create multiple user accounts in batches, such as new employee onboarding, student lab environment setup, server cluster initialization, etc. Manually creating users one by one is not only inefficient but also error-prone. This article will detail several methods for batch creating users and setting passwords in Linux systems, and provide a fully functional batch user creation script.

## I. Common Methods for Batch Creating Users

### 1.1 Using Simple Shell Loops

The simplest and most straightforward method is to use Shell loop statements combined with the `useradd` and `chpasswd` commands. This method is suitable for scenarios where a small number of users need to be created.

```bash
#!/bin/bash
# Simple batch user creation script

# Define the list of users to create
users=("user1" "user2" "user3" "user4" "user5")
# Define default password
default_password="InitialPass@2024"

echo "Starting to create users..."

# Loop to create users
for user in "${users[@]}"; do
    # Check if user already exists
    if id "$user" &>/dev/null; then
        echo "Warning: User '$user' already exists, skipping creation"
        continue
    fi
    
    # Create user and set password
    useradd -m -s /bin/bash "$user" &>/dev/null
    if [ $? -eq 0 ]; then
        # Set password
        echo "$user:$default_password" | chpasswd
        
        # Force user to change password on first login
        chage -d 0 "$user"
        
        echo "Success: Created user '$user' and set password"
    else
        echo "Error: Failed to create user '$user'"
    fi
done

echo "User creation completed!"
```

The advantage of this method is its simplicity and intuitiveness, but the disadvantage is that it's not flexible enough and may not be efficient enough when a large number of users need to be created or when there are complex requirements.

### 1.2 Using the newusers Command

Linux systems provide the `newusers` command, which is specifically designed for batch creating users. This method requires first preparing a user data file in a specific format.

#### Preparing the User Data File

The format of the user data file is: `username:password:UID:GID:description:homedirectory:loginshell`

For example, create a file named `users.txt`:

```
user1:encrypted_password:1001:1001:User One:/home/user1:/bin/bash
user2:encrypted_password:1002:1002:User Two:/home/user2:/bin/bash
user3:encrypted_password:1003:1003:User Three:/home/user3:/bin/bash
```

Note: The password here should be an encrypted password, which can be generated using the `openssl` command:

```bash
openssl passwd -1 "YourPassword"
```

#### Using the newusers Command

After preparing the user data file, use the following command to batch create users:

```bash
sudo newusers users.txt
```

The `newusers` command will automatically create users and their home directories based on the information in the file, and set passwords.

### 1.3 Using awk and chpasswd Combination

For users who have already been created or for scenarios where passwords need to be set in batches from a simple list, you can combine the `awk` and `chpasswd` commands:

```bash
#!/bin/bash

# Assuming users.txt contains a list of usernames, one per line
echo "Setting user passwords..."
sudo awk '{print $1":NewPassword123"}' users.txt | sudo chpasswd
echo "Password setting completed!"
```

This method is suitable for quickly resetting passwords for multiple users.

## II. Advanced Batch User Creation Script

### 2.1 Script Function Introduction

To meet more complex batch user creation needs, we can develop a fully functional Shell script with the following features:

- Support for reading user lists from command line arguments or files
- Ability to set a unified password or generate random passwords for each user
- Automatic logging of operations and generation of password files
- Force users to change passwords on first login
- Check if users already exist to avoid duplicate creation
- Provide detailed help information and usage instructions

### 2.2 Complete Script Implementation

Here is a fully functional batch user creation script:

```bash
#!/bin/bash

# Batch create users and set passwords script
# Usage:
# 1. Specify users directly on the command line: sudo ./batch_create_users.sh user1 user2 user3 ...
# 2. Read user list from file: sudo ./batch_create_users.sh -f users.txt

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Please run this script with root privileges"
    exit 1
fi

# Default password and user list file
DEFAULT_PASSWORD="ChangeMe@123"
USER_LIST_FILE=""
USERS=()
GENERATE_RANDOM_PASSWORD=false
LOG_FILE="user_creation_$(date +%Y%m%d_%H%M%S).log"

# Display help information
show_help() {
    echo "Usage: $0 [options] [user1 user2 ...]"
    echo ""
    echo "Options:"
    echo "  -f, --file <file>    Read user list from specified file, one username per line"
    echo "  -p, --password <password>  Set default password, default is 'ChangeMe@123'"
    echo "  -r, --random         Generate random password for each user"
    echo "  -h, --help           Display this help information"
    echo ""
    echo "Examples:"
    echo "  $0 user1 user2 user3"
    echo "  $0 -f users.txt -p SecurePass123"
    echo "  $0 -f users.txt -r"
}

# Generate random password
generate_password() {
    local length=12
    local password=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*()' | head -c $length)
    echo "$password"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--file)
                USER_LIST_FILE="$2"
                shift 2
                ;;
            -p|--password)
                DEFAULT_PASSWORD="$2"
                shift 2
                ;;
            -r|--random)
                GENERATE_RANDOM_PASSWORD=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                USERS+="$1"
                shift
                ;;
        esac
    done
}

# Read user list from file
read_users_from_file() {
    if [ ! -f "$USER_LIST_FILE" ]; then
        echo "Error: User list file '$USER_LIST_FILE' does not exist"
        exit 1
    fi
    
    echo "Reading user list from file '$USER_LIST_FILE'..."
    while IFS= read -r user || [ -n "$user" ]; do
        # Ignore empty lines and comment lines starting with #
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        USERS+="$user"
    done < "$USER_LIST_FILE"
}

# Create users and set passwords
create_users() {
    echo "Starting to create users..."
    echo "Creation log will be saved to: $LOG_FILE"
    
    # Create log file header
    echo "User creation log - $(date)" > "$LOG_FILE"
    echo "----------------------------------" >> "$LOG_FILE"
    echo "Username | Password | Status" >> "$LOG_FILE"
    echo "----------------------------------" >> "$LOG_FILE"
    
    # Create password file for storing usernames and passwords
    PASSWORD_FILE="users_passwords_$(date +%Y%m%d_%H%M%S).txt"
    echo "Username:Password" > "$PASSWORD_FILE"
    
    for user in "${USERS[@]}"; do
        # Check if user already exists
        if id "$user" &>/dev/null; then
            echo "Warning: User '$user' already exists, skipping creation"
            echo "$user | - | Exists" >> "$LOG_FILE"
            continue
        fi
        
        # Set password
        if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
            password=$(generate_password)
        else
            password="$DEFAULT_PASSWORD"
        fi
        
        # Create user
        useradd -m -s /bin/bash "$user" &>/dev/null
        if [ $? -eq 0 ]; then
            # Set password
            echo "$user:$password" | chpasswd
            if [ $? -eq 0 ]; then
                echo "Success: Created user '$user' and set password"
                echo "$user | $password | Success" >> "$LOG_FILE"
                echo "$user:$password" >> "$PASSWORD_FILE"
                
                # Force user to change password on first login
                chage -d 0 "$user"
            else
                echo "Error: Failed to set password for user '$user'"
                echo "$user | - | Password set failed" >> "$LOG_FILE"
            fi
        else
            echo "Error: Failed to create user '$user'"
            echo "$user | - | Creation failed" >> "$LOG_FILE"
        fi
    done
    
    echo "----------------------------------"
    echo "User creation completed!"
    echo "Detailed log: $LOG_FILE"
    echo "User password file: $PASSWORD_FILE"
    echo "Note: Please keep the password file safe, it is recommended to delete or encrypt it immediately after creation"
}

# Main function
main() {
    parse_arguments "$@"
    
    # If file is specified, read user list from file
    if [ -n "$USER_LIST_FILE" ]; then
        read_users_from_file
    fi
    
    # Check if there are users to create
    if [ ${#USERS[@]} -eq 0 ]; then
        echo "Error: No users specified to create, please use the -f option to specify a user list file or list usernames directly on the command line"
        show_help
        exit 1
    fi
    
    # Display creation plan
    echo "About to create the following users: ${USERS[*]}"
    if [ "$GENERATE_RANDOM_PASSWORD" = true ]; then
        echo "Random passwords will be generated for each user"
    else
        echo "Default password: $DEFAULT_PASSWORD"
    fi
    
    # Confirm creation
    read -p "Continue? (y/n) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        create_users
    else
        echo "Operation cancelled"
        exit 0
    fi
}

# Execute main function
main "$@"
```

### 2.3 Script Usage

1. **Save the script and add execute permission**:
   ```bash
   chmod +x batch_create_users.sh
   ```

2. **Specify users directly on the command line**:
   ```bash
   sudo ./batch_create_users.sh user1 user2 user3
   ```

3. **Read user list from file**:
   ```bash
   sudo ./batch_create_users.sh -f users.txt
   ```

4. **Customize default password**:
   ```bash
   sudo ./batch_create_users.sh -p SecurePass123 user1 user2
   ```

5. **Generate random passwords**:
   ```bash
   sudo ./batch_create_users.sh -r -f users.txt
   ```

6. **View help information**:
   ```bash
   ./batch_create_users.sh --help
   ```

## III. Security Best Practices

When batch creating users, security is an important consideration. Here are some security best practices:

### 3.1 Password Management

- **Use strong passwords**: Ensure passwords are complex enough, containing uppercase and lowercase letters, numbers, and special characters
- **Random password generation**: For a large number of users, prioritize using the random password generation feature
- **Force change on first login**: Use `chage -d 0 username` to force users to change their password on first login
- **Secure password storage**: The password file generated by the script should be properly kept, it is recommended to delete or encrypt it immediately after use

### 3.2 User Permission Control

- **Principle of least privilege**: Assign users the minimum necessary permissions
- **Group management**: Consider adding users to appropriate groups for permission management
- **sudo permissions**: Carefully assign sudo permissions, if necessary, use the sudoers configuration file for fine-grained control

### 3.3 Logging and Auditing

- **Record operation logs**: The script automatically generates detailed operation logs for subsequent auditing
- **Regularly audit user accounts**: Regularly check user accounts in the system and delete accounts that are no longer in use
- **Monitor abnormal logins**: Configure login failure count limits and notification mechanisms

## IV. Other Batch User Management Operations

In addition to creating users, system management often requires performing other batch user management operations.

### 4.1 Batch Deleting Users

When you need to clean up a large number of user accounts, you can use the following script:

```bash
#!/bin/bash

# Batch delete users script

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Please run this script with root privileges"
    exit 1
fi

# Read user list from file
if [ -f "users.txt" ]; then
    echo "Reading user list from file..."
    while IFS= read -r user || [ -n "$user" ]; do
        # Ignore empty lines and comment lines starting with #
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # Check if user exists
        if id "$user" &>/dev/null; then
            echo "Deleting user: $user"
            # Delete user and their home directory
            userdel -r "$user"
        else
            echo "User '$user' does not exist, skipping"
        fi
    done < "users.txt"
    
    echo "User deletion operation completed!"
else
    echo "Error: File 'users.txt' does not exist"
    exit 1
fi
```

### 4.2 Batch Modifying User Passwords

When you need to reset passwords for multiple users:

```bash
#!/bin/bash

# Batch modify user passwords script

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Please run this script with root privileges"
    exit 1
fi

# Set new password
new_password="NewPassword123"

# Read user list from file
if [ -f "users.txt" ]; then
    echo "Starting to modify user passwords..."
    
    # Use chpasswd to set passwords in batch
    while IFS= read -r user || [ -n "$user" ]; do
        # Ignore empty lines and comment lines starting with #
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # Check if user exists
        if id "$user" &>/dev/null; then
            echo "$user:$new_password" | chpasswd
            # Force user to change password next login
            chage -d 0 "$user"
            echo "Password for user '$user' has been modified"
        else
            echo "User '$user' does not exist, skipping"
        fi
    done < "users.txt"
    
    echo "Password modification completed!"
else
    echo "Error: File 'users.txt' does not exist"
    exit 1
fi
```

### 4.3 Batch Adding Users to Groups

Add multiple users to a specified group:

```bash
#!/bin/bash

# Batch add users to group script

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: Please run this script with root privileges"
    exit 1
fi

# Specify target group
target_group="developers"

# Check if group exists
if ! grep -q "^$target_group:" /etc/group; then
    echo "Error: Group '$target_group' does not exist"
    exit 1
fi

# Read user list from file
if [ -f "users.txt" ]; then
    echo "Starting to add users to group '$target_group'..."
    
    while IFS= read -r user || [ -n "$user" ]; do
        # Ignore empty lines and comment lines starting with #
        [[ -z "$user" || "$user" =~ ^# ]] && continue
        
        # Check if user exists
        if id "$user" &>/dev/null; then
            # Add user to group
            usermod -aG "$target_group" "$user"
            echo "User '$user' has been added to group '$target_group'"
        else
            echo "User '$user' does not exist, skipping"
        fi
    done < "users.txt"
    
    echo "User addition to group operation completed!"
else
    echo "Error: File 'users.txt' does not exist"
    exit 1
fi
```

## V. Summary

Batch user management is a common task in Linux system administration. This article introduced various methods for batch creating users and setting passwords, from simple Shell loops to fully functional automated scripts, as well as related security best practices and other batch user management operations.

Which method to choose depends on specific needs and environment:

- For a small number of users, a simple Shell loop can meet the requirements
- For well-formatted user data, the `newusers` command is a good choice
- For complex user management needs, fully functional automated scripts provide maximum flexibility and security

Regardless of which method is used, security best practices should be followed to ensure password security and appropriate management of user permissions. Automated scripts not only improve work efficiency but also reduce human errors, making them an ideal choice for large-scale user management.

By mastering these batch user management techniques, system administrators can more efficiently complete daily management tasks and provide better service experience for users.