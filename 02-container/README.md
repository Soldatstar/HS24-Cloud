# 02 Container Project Setup

## Terraform Directory

The following commands have been run to plan and apply the infrastructure setup:

```bash
terraform plan
terraform apply
```

## TODO

- Combine current .tf scripts into one: As all 4 machines are identical, one script could be used
- Maybe define security Groups and other policies in terraform aswell, to simplify creation and deletion

## Ansible Directory

The Ansible playbooks should be executed by the user who created the instances, as the SSH key used is account-specific. After the first step, other users can access the machines as well.


###  Docker Swarm/Podman task

1. Replace the authorized SSH keys:
   
   ```bash
   ansible-playbook -i inventory.yml replace_authorized_keys.yml
   ```

2. Install Docker on the instances:

   ```bash
   ansible-playbook -i inventory.yml install-Docker.yml
   ```

3. Create an evaluation user:

   ```bash
   ansible-playbook -i inventory.yml create_evaluator_user.yml
   ```
   

## TODO

- write playbook to create and connect docker swarm
- write playbook to run monitoring stack on all nodes

- write playbook to add podman on host container-lxc-host
- add security groups

ssh-keygen -f "/home/viktor/.ssh/known_hosts" -R "86.119.30.54"
ssh-keygen -f "/home/viktor/.ssh/known_hosts" -R "86.119.31.182"
ssh-keygen -f "/home/viktor/.ssh/known_hosts" -R "86.119.30.159"



### LXC Script? (TODO)

1. Point 1: Installing LXC

```bash
ansible-playbook -i inventory.yml install_lxc.yml
```

### Docker.io Script? (TODO)    

### CGroup Script? (TODO)