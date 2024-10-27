#!/bin/bash

# Step 1: Initialize and apply Terraform in the /terraform directory
cd terraform
terraform init
terraform apply -auto-approve

# Step 2: Retrieve IPs from Terraform output
floating_ip=$(terraform output -json floating_ip | jq -r '.')
floating_ips=$(terraform output -json floating_ips | jq -r '.[]')
private_ips=$(terraform output -json private_ips | jq -r '.[]')

# Step 3: Define hostnames and associate them with IPs
# Assuming the order is consistent (mgr first, then workers)
lxc_host_name="container-lxc-host"
manager_name="docker-mgr-01"
worker_names=("docker-wrk-01" "docker-wrk-02")

# Convert IPs to arrays
readarray -t floating_ips_array <<< "$floating_ips"
readarray -t private_ips_array <<< "$private_ips"

# Step 4: Generate dynamic Ansible inventory file in /ansible directory
cd ../ansible/
cat <<EOF > inventory.yml
all:
  children:
    lxc-host:
      hosts:
        $lxc_host_name:
          ansible_host: ${floating_ip}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'  # Disable strict host key checking 
    manager:
      hosts:
        $manager_name:
          ansible_host: ${floating_ips_array[0]}
          private_ip: ${private_ips_array[0]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'  # Disable strict host key checking
    workers:
      hosts:
EOF

# Append worker information to the inventory
for i in "${!worker_names[@]}"; do
  cat <<EOF >> inventory.yml
        ${worker_names[$i]}:
          ansible_host: ${floating_ips_array[$((i + 1))]}
          private_ip: ${private_ips_array[$((i + 1))]}
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no'  # Disable strict host key checking
EOF
done

# Function to check if a server is reachable
check_server() {
    local ip="$1"
    until ping -c 1 "$ip" &> /dev/null; do
        echo "Waiting for server $ip to be reachable..."
        sleep 5  # Wait before trying again
    done
    echo "Server $ip is reachable."
}

# Step 5: Check reachability for each server
check_server "$floating_ip"
for ip in "${floating_ips_array[@]}"; do
    check_server "$ip"
done

# Wait for 20 seconds after all servers are checked
echo "Waiting for 60 seconds before proceeding..."
sleep 60

# Step 6: Run Ansible playbooks using the generated inventory in /ansible directory
playbooks=(
  "replace_authorized_keys.yml" 
  "create_evaluator_user.yml"
  "install_lxc.yml"
  "setting_up_lxc_container.yml" 
  "install_docker.yml"
  "deploy_monitoring_stack_single.yml"
  "stress_resources_cgroup.yml" 
  "initialize_docker_swarm.yml" 
  "deploy_monitoring_stack_swarm.yml"
  "install_podman.yml"
  "deploy_report.yml"
  )

for playbook in "${playbooks[@]}"; do
    ansible-playbook -i inventory.yml "$playbook"
done
