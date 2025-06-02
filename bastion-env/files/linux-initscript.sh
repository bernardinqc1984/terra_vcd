#!/bin/bash

# Function to create users with ssh key

create_users() {
  local username=$1
  local group=$2
  local ssh_key=$3

  # Checked if users already exist
  if id "$username" &>/dev/null; then
     echo "The user $username already exist."
     return
  fi

  # Create the user
  useradd -m -s /bin/bash -g $group $username
  if [ $? -ne 0 ]; then
    echo "Failed to create the user $username."
    exit 1
  fi

  # configuration of the .ssh directory and authorized_keys file
  local home_dir="/home/$username"
  local ssh_dir="$home_dir/.ssh"
  local authorized_keys="$ssh_dir/authorized_keys"

  if [ ! -f $authorized_keys ]; then
    mkdir -p $ssh_dir
    echo $ssh_key > $authorized_keys
    chown -R $username:$group $ssh_dir
    chmod 700 $ssh_dir
    chmod 600 $authorized_keys
  fi

  # Adding sudo rights without password
  echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"
  chmod 0440 "/etc/sudoers.d/$username"

  echo "User $username created successfully."
}

# Check the variables
if [ "$1" = "precustomization" ]; then
  echo "Pre-customization script started........."
  echo "Pre-customization script completed........."

elif [ "$1" = "postcustomization" ]; then
  echo "Post-customization script started........."

  # Installation et enabling ssh service
  dnf install -y openssh-server
  systemctl enable sshd
  systemctl start sshd

# Create k8s group
  groupadd k8s || echo "The group k8s already exist."

# Users list with their ssh key
  declare -A users=(
    ["cirrus"]="ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAf26Toc0COQzC/R5wrR8xOcWqbJF0DCFIIepgOy+LzCOWXo3/XBsgx5q5dF0CWma0Mrk5VQWDcQlUcGK0y8sTSWQAgQhkiGvfczt+fUOIJUyiTyb+HopBNLwG7z/I7Bem4HNWcG9/GsoCNv4R/MSnHaS+N8S9rx14dENM50WYuNv37ow== cirrus"
    ["czogbelemou"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAoE8zKmJblNMyplKs75DJwfIf1PjuLjOxSFxV0LOAbiaiuyypi485EzXJALP+GD5wultiC4/wB2Rfv7e1OPJ2zNbdldwASFwrRwmslDOxsI6a8hnJaLdf5cu/kE6ZWIR2MOMfE+ISJ6K7EkVQ/d1dAJJoTM3KUKTgvrKdXZGKoTRveDICm+1e7Cka2CigfMBefDi4VkTksoH1rTL3EBi1MMyVppZLVw5wAykutbGesQzLl7FciTsBpw5JhW19BSTw/jv9GFdegbVxVE/3MVr/UEFlRmqEBN61YT58bMb0KuAFEaznyE3P5BrKjADtebwZJR3FrKeq2c2yx3cTvq0QKmJtA/94QtXC4mUzsLNhDjFB832jKqpTqLTM30ekGv/TNw3TgHASlpBCADz+pV6NRc/c478qX1+OLN2eVAmIiuvwdOFAwfqR0lZy5ot2YSIo+NlShvIclbGxH8FcDTVFX1ysipJ84AXQ3lSKEkhOtZ7judW4DjBspqjly8hqLEE= czogbelemou@Charless-MacBook-Pro.local"
    ["mcharette"]="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDZz3z1Z.................."
  )

# Loop to create the users
  for user in "$${!users[@]}"; do
    create_users $user k8s "$${users[$user]}"
  done

  echo "Post-customization script completed........."
else
  echo "Usage: $0 [precustomization|postcustomization]"
  exit 1
fi

exit 0
  