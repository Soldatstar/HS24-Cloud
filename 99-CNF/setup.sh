#!/bin/bash

# Define base directory based on the script's location
BASE_DIR="$(dirname "$0")"

# Define paths for terraform and ansible directories
TERRAFORM_DIR="$BASE_DIR/terraform"
ANSIBLE_DIR="$BASE_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.yml"

# Define hostnames and names for Ansible inventory
benchmarkNode01=("benchmarkNode01")

# Function to generate dynamic Ansible inventory file
generate_inventory() {
    cd "$TERRAFORM_DIR" || exit
    terraform apply -refresh-only
    floating_ips=$(terraform output -json floating_ips | jq -r '.[]')
    private_ips=$(terraform output -json private_ips | jq -r '.[]')

    readarray -t floating_ips_k8s_array <<< "$floating_ips"
    readarray -t private_ips_k8s_array <<< "$private_ips"

    cd ..

    cat <<EOF > "$INVENTORY_FILE"
all:
  children:
    k8s-main:
      hosts:
EOF
    for i in "${!benchmarkNode01[@]}"; do
        cat <<EOF >> "$INVENTORY_FILE"
        ${benchmarkNode01[$i]}:
          ansible_host: ${floating_ips_k8s_array[$i]}
          private_ip: ${private_ips_k8s_array[$i]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    done

    echo "Inventory file generated at $INVENTORY_FILE"
}

# Option 1: Apply Terraform and run Ansible playbooks
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

    playbooks=(
      "replace_authorized_keys.yml"
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

# Option 2: Refresh Terraform and regenerate inventory
refresh_inventory() {
    generate_inventory
    echo "Inventory refreshed successfully."
}

# Option 3: Deploy report
deploy_report() {
    ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/deploy_report.yml"
}

# Option 4: Destroy Terraform resources
destroy_resources() {
    cd "$TERRAFORM_DIR" || exit
    terraform destroy -auto-approve
    echo "Terraform resources destroyed."
}

# Main menu for selecting options
echo "Select an option:"
echo "1) Apply Terraform and deploy Ansible playbooks"
echo "2) Refresh inventory"
echo "3) Deploy report"
echo "4) Destroy Terraform resources"
read -p "Enter your choice (1-4): " choice

case $choice in
    1) apply_and_deploy ;;
    2) refresh_inventory ;;
    3) deploy_report ;;
    4) destroy_resources ;;
    *) echo "Invalid option." ;;
esac
