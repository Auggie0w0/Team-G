#!/bin/bash

userCheck() {
  local NC='\033[0m'    # No Color
  local RED='\033[0;31m'

  local inputFile="allowedusers.txt"

  local normalUsers=()
  local adminUsers=()
  local unauthorizedUsers=()

  local systemUsers
  systemUsers=$(awk -F':' '($3 >= 1000 && $3 < 60000) {print $1}' /etc/passwd)

    if [[ ! -f "$inputFile" ]]; then
        echo "Error: Allowed users file '$inputFile' not found."
        exit 1
    fi

  # Loop through all normal users
  for user in $systemUsers; do
    if grep -qw "^${user}$" "$inputFile"; then
        # Determine if the user has admin privileges
        if groups "$user" | grep -qwE 'sudo|wheel'; then
            adminUsers+=("$user")
        else
            normalUsers+=("$user")
        fi
    else
        # Flag unauthorized users with a warning
        unauthorizedUsers+=("${RED}WARNING: USER: $user NOT IN allowedusers.txt${NC}")
    fi
  done

  # Normal Users
  echo -e "\nNormal Users:"
    if [[ ${#normalUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${normalUsers[@]}"; do
            echo "  - $user"
        done
    fi

  # Admin Users
 echo "==============="

    echo "Admin Users:"
    if [[ ${#adminUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${adminUsers[@]}"; do
            echo "  - $user"
        done
    fi

  # Unauthorized Users
    echo "==============="

    echo "Unauthorized Users:"
    if [[ ${#unauthorizedUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${unauthorizedUsers[@]}"; do
            echo -e "  - $user"
        done
    fi

  # Display management options
  echo -e "\nUser Management Options:"
  echo "1. Change user permissions (normal ↔ admin)"
  echo "2. Remove user"
  echo "3. Add user to group"
  echo "4. Remove user from group"
  echo "5. Manage root access"
  echo "6. Exit"

  read -p "Select an option (1-6): " choice

  case $choice in
    1)
      read -p "Enter username to modify: " username
      if id "$username" &>/dev/null; then
        if groups "$username" | grep -qwE 'sudo|wheel'; then
          # Remove from sudo group
          sudo gpasswd -d "$username" sudo
          echo "Removed admin privileges from $username"
        else
          # Add to sudo group
          sudo usermod -aG sudo "$username"
          echo "Granted admin privileges to $username"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    2)
      read -p "Enter username to remove: " username
      if id "$username" &>/dev/null; then
        sudo userdel -r "$username"
        echo "Removed user $username"
      else
        echo "User $username does not exist"
      fi
      ;;
    3)
      read -p "Enter username: " username
      read -p "Enter group name: " groupname
      if id "$username" &>/dev/null; then
        if getent group "$groupname" >/dev/null; then
          sudo usermod -aG "$groupname" "$username"
          echo "Added $username to group $groupname"
        else
          echo "Group $groupname does not exist"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    4)
      read -p "Enter username: " username
      read -p "Enter group name: " groupname
      if id "$username" &>/dev/null; then
        if getent group "$groupname" >/dev/null; then
          sudo gpasswd -d "$username" "$groupname"
          echo "Removed $username from group $groupname"
        else
          echo "Group $groupname does not exist"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    5)
      read -p "Enter username: " username
      read -p "Grant root access? (y/n): " grant
      if id "$username" &>/dev/null; then
        if [ "$grant" = "y" ]; then
          sudo usermod -aG sudo "$username"
          echo "Granted root access to $username"
        else
          sudo gpasswd -d "$username" sudo
          echo "Removed root access from $username"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    6)
      echo "Exiting user management"
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
}