#!/bin/bash

# Define base directory based on the script's location
BASE_DIR="$(dirname "$0")"

# Define paths for terraform and ansible directories
TERRAFORM_DIR="$BASE_DIR/terraform"
ANSIBLE_DIR="$BASE_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.yml"

# Define hostnames and names for Ansible inventory
lxc_host_name="container-lxc-host"
manager_name="docker-mgr-01"
worker_names=("docker-wrk-01" "docker-wrk-02")

# Function to generate dynamic Ansible inventory file
generate_inventory() {
    cd "$TERRAFORM_DIR" || exit
    terraform apply -refresh-only
    floating_ip=$(terraform output -json floating_ip | jq -r '.')
    floating_ips=$(terraform output -json floating_ips | jq -r '.[]')
    private_ips=$(terraform output -json private_ips | jq -r '.[]')
    readarray -t floating_ips_array <<< "$floating_ips"
    readarray -t private_ips_array <<< "$private_ips"
    cd ..
    cat <<EOF > "$INVENTORY_FILE"
all:
  children:
    lxc-host:
      hosts:
        $lxc_host_name:
          ansible_host: ${floating_ip}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    manager:
      hosts:
        $manager_name:
          ansible_host: ${floating_ips_array[0]}
          private_ip: ${private_ips_array[0]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    workers:
      hosts:
EOF
    for i in "${!worker_names[@]}"; do
        cat <<EOF >> "$INVENTORY_FILE"
        ${worker_names[$i]}:
          ansible_host: ${floating_ips_array[$((i + 1))]}
          private_ip: ${private_ips_array[$((i + 1))]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
EOF
    done
    echo "Inventory file generated at $INVENTORY_FILE"
}

# Function to check server reachability and SSH readiness
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

# Option 1: Apply Terraform and run Ansible playbooks
apply_and_deploy() {
    cd "$TERRAFORM_DIR" || exit
    terraform init
    terraform apply -auto-approve
    cd ..
    generate_inventory
    check_server "$floating_ip"
    for ip in "${floating_ips_array[@]}"; do
        check_server "$ip"
    done
    playbooks=(
      "replace_authorized_keys.yml"
      "create_evaluator_user.yml"
      "install_lxc.yml"
      "setting_up_lxc_container.yml"
      "install_docker.yml"
      "deploy_monitoring_stack_single.yml"
      "initialize_docker_swarm.yml"
      "deploy_monitoring_stack_swarm.yml"
      "install_podman.yml"
      "deploy_report.yml"
      "stress_resources_cgroup.yml"
    )
    for playbook in "${playbooks[@]}"; do
        ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/$playbook"
    done
}

# Option 2: Refresh Terraform and regenerate inventory
refresh_inventory() {
    generate_inventory
    echo "Inventory refreshed successfully."
}


#Option 3: deploy report
deploy_report(){
      ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR"/deploy_report.yml
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
echo "3) Deploy Report"
echo "4) Destroy Terraform resources"
read -p "Enter your choice (1-4): " choice

case $choice in
    1) apply_and_deploy ;;
    2) refresh_inventory ;;
    3) deploy_report ;;
    4) destroy_resources ;;
    *) echo "Invalid option." ;;
esac
