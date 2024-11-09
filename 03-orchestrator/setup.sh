#!/bin/bash

# Define base directory based on the script's location
BASE_DIR="$(dirname "$0")"

# Define paths for terraform and ansible directories
TERRAFORM_DIR="$BASE_DIR/terraform"
ANSIBLE_DIR="$BASE_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.yml"

# Define hostnames and names for Ansible inventory
k8s_main_nodes=("k8smain01" "k8smain02" "k8sworker01")
k3s_nodes=("k3snode01" "k3snode02")

# Function to generate dynamic Ansible inventory file
generate_inventory() {
    cd "$TERRAFORM_DIR" || exit
    terraform apply -refresh-only
    floating_ips_k8s=$(terraform output -json floating_ips_k8s | jq -r '.[]')
    floating_ips_k3s=$(terraform output -json floating_ips_k3s | jq -r '.[]')
    private_ips_k8s=$(terraform output -json private_ips_k8s | jq -r '.[]')
    private_ips_k3s=$(terraform output -json private_ips_k3s | jq -r '.[]')

    readarray -t floating_ips_k8s_array <<< "$floating_ips_k8s"
    readarray -t private_ips_k8s_array <<< "$private_ips_k8s"
    readarray -t floating_ips_k3s_array <<< "$floating_ips_k3s"
    readarray -t private_ips_k3s_array <<< "$private_ips_k3s"

    cd ..

    cat <<EOF > "$INVENTORY_FILE"
all:
  children:
    k8s-main:
      hosts:
EOF
    for i in "${!k8s_main_nodes[@]}"; do
        cat <<EOF >> "$INVENTORY_FILE"
        ${k8s_main_nodes[$i]}:
          ansible_host: ${floating_ips_k8s_array[$i]}
          private_ip: ${private_ips_k8s_array[$i]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    done

    cat <<EOF >> "$INVENTORY_FILE"
    k3s-nodes:
      hosts:
EOF
    for i in "${!k3s_nodes[@]}"; do
        cat <<EOF >> "$INVENTORY_FILE"
        ${k3s_nodes[$i]}:
          ansible_host: ${floating_ips_k3s_array[$i]}
          private_ip: ${private_ips_k3s_array[$i]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    done

    echo "Inventory file generated at $INVENTORY_FILE"
}


apply_and_deploy() {
    cd "$TERRAFORM_DIR" || exit
    terraform init
    terraform apply -auto-approve
    cd ..
    generate_inventory

    # Check the floating IPs for K8s nodes
    for ip in "${floating_ips_k8s_array[@]}"; do
        check_server "$ip"
    done

    # Check the floating IPs for K3s nodes
    for ip in "${floating_ips_k3s_array[@]}"; do
        check_server "$ip"
    done

    playbooks=(
      "replace_authorized_keys.yml"
      "k3s_full_task.yml"
    )

    # Run each playbook
    for playbook in "${playbooks[@]}"; do
        ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/$playbook"
    done
}


check_server() {
    local ip="$1"
    local port=22
    while true; do
        if nc -z -w5 "$ip" "$port" &> /dev/null; then
            echo "Server $ip is reachable and SSH is ready."
            break
        else
            echo "Waiting for SSH on server $ip to be ready..."
        fi
        sleep 5
    done
}

apply_and_deploy
